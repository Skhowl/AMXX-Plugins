/*
	
	----------------------
	-*- Licensing Info -*-
	----------------------
	
	Copyright (C) 2012-2022 schmurgel1983, skhowl, gesalzen
	
	This program is free software: you can redistribute it and/or modify it
	under the terms of the GNU General Public License as published by the
	Free Software Foundation, either version 3 of the License, or (at your
	option) any later version.
	
	This program is distributed in the hope that it will be useful, but
	WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
	Public License for more details.
	
	You should have received a copy of the GNU General Public License along
	with this program. If not, see <http://www.gnu.org/licenses/>.
	
	In addition, as a special exception, the author gives permission to
	link the code of this program with the Half-Life Game Engine ("HL
	Engine") and Modified Game Libraries ("MODs") developed by Valve,
	L.L.C ("Valve"). You must obey the GNU General Public License in all
	respects for all of the code used other than the HL Engine and MODs
	from Valve. If you modify this file, you may extend this exception
	to your version of the file, but you are not obligated to do so. If
	you do not wish to do so, delete this exception statement from your
	version.
	
	No warranties of any kind. Use at your own risk.
	
*/

#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#include <dm_core>
#include <dm_spawn>
#include <dm_ffa>
#include <dm_items>
#include <dm_colorchat>

/* --------------------------------------------------------------------------- */

const FM_PDATA_SAFE = 2;

new dm_item_mask_recover = 0;

new g_iItemID = -1;
new g_iFreeForAllEnabled = 0;

new g_iTeamID[DM_MAX_PLAYERS+1] = 0;
new g_iHealth[DM_MAX_PLAYERS+1] = 0;

new bs_IsAlive = 0;
new bs_HaveItem = 0;

#define get_bitsum(%1,%2)   (%1 &   (1<<((%2-1)&31)))
#define add_bitsum(%1,%2)    %1 |=  (1<<((%2-1)&31))
#define del_bitsum(%1,%2)    %1 &= ~(1<<((%2-1)&31))

#if AMXX_VERSION_NUM < 183
new g_iMaxPlayers = 0;
#define is_user_valid_alive(%1) (1 <= %1 <= g_iMaxPlayers && get_bitsum(bs_IsAlive, %1))
#else
#define is_user_valid_alive(%1) (1 <= %1 <= MaxClients && get_bitsum(bs_IsAlive, %1))
#endif

/* --------------------------------------------------------------------------- */

#define ALPHA_FULLBLINDED 255

const m_flFlashedUntil = 514;
const m_flFlashedAt = 515;
const m_flFlashHoldTime = 516;
const m_flFlashDuration = 517;
const m_iFlashAlpha = 518;

/* --------------------------------------------------------------------------- */

new const item_name[] = { "mask_of_death" };
new const item_chat[] = { "mask" };
const item_teams = DM_TEAM_ANY;
const item_cost = 150;
const item_holdtime = 120;

/* --------------------------------------------------------------------------- */

public DM_OnModStatus(status)
{
	register_plugin("DM Item: Mask of Death", "1.0.0", "schmurgel1983");
	
	if (status) state enabled;
	else state deactivated;
}

public plugin_init() <deactivated> {}
public plugin_init() <enabled>
{
	g_iItemID = DM_RegisterItem(item_name, item_chat, item_teams, item_cost, item_holdtime, "Activate", "Deactivate");
	if (g_iItemID == -1)
	{
		state deactivated;
		return;
	}
	
	#if AMXX_VERSION_NUM < 183
	register_dictionary_colored("dm_items_additional.txt");
	#else
	register_dictionary("dm_items_additional.txt");
	#endif
	
	dm_item_mask_recover = register_cvar("dm_item_mask_recover", "0.3");
	
	RegisterHam(Ham_TakeDamage, "player", "fwd_TakeDamage_Post", true);
	
	register_message(get_user_msgid("TeamInfo"), "Msg_TeamInfo");
	register_message(get_user_msgid("Health"), "Msg_Health");
	
	#if AMXX_VERSION_NUM < 183
	g_iMaxPlayers = get_maxplayers();
	#endif
	
	g_iFreeForAllEnabled = DM_IsFreeForAllEnabled();
}

/* --------------------------------------------------------------------------- */

#if AMXX_VERSION_NUM < 183
public client_disconnect(id) <deactivated> {}
public client_disconnect(id) <enabled>
#else
public client_disconnected(id, bool:drop, message[], maxlen) <deactivated> {}
public client_disconnected(id, bool:drop, message[], maxlen) <enabled>
#endif
{
	del_bitsum(bs_IsAlive, id);
	del_bitsum(bs_HaveItem, id);
	
	if (task_exists(id))
	{
		remove_task(id);
		fm_set_rendering(id);
	}
}

/* --------------------------------------------------------------------------- */

public DM_OnCzBotHamRegisterable(id) <deactivated> {}
public DM_OnCzBotHamRegisterable(id) <enabled>
{
	RegisterHamFromEntity(Ham_TakeDamage, id, "fwd_TakeDamage_Post", true);
}

/* --------------------------------------------------------------------------- */

public DM_PlayerSpawn_Pre(id, freezetime, roundend) <deactivated> {}
public DM_PlayerSpawn_Pre(id, freezetime, roundend) <enabled>
{
	g_iHealth[id] = 100;
}

public DM_PlayerSpawn_Post(id, freezetime, roundend) <deactivated> {}
public DM_PlayerSpawn_Post(id, freezetime, roundend) <enabled>
{
	add_bitsum(bs_IsAlive, id);
}

public DM_PlayerKilled_Pre(victim, attacker) <deactivated> {}
public DM_PlayerKilled_Pre(victim, attacker) <enabled>
{
	del_bitsum(bs_IsAlive, victim);
	
	if (task_exists(victim))
	{
		remove_task(victim);
		fm_set_rendering(victim);
	}
}

/* --------------------------------------------------------------------------- */

public fwd_TakeDamage_Post(victim, inflictor, attacker, Float:damage, damage_type)
{
	if (!is_user_valid_alive(attacker) || !get_bitsum(bs_HaveItem, attacker) || victim == attacker || (!g_iFreeForAllEnabled && g_iTeamID[victim] == g_iTeamID[attacker]))
		return;
	
	new Float:fDmgTake = float(pev(victim, pev_dmg_take));
	if (fDmgTake <= 0.0 || fDmgTake > damage)
		return;
	
	fDmgTake *= get_pcvar_float(dm_item_mask_recover);
	if (fDmgTake >= 1.0)
	{
		new iHealth = pev(attacker, pev_health);
		if (iHealth == g_iHealth[attacker])
			return;
		
		new iDmgTake = floatround(fDmgTake, floatround_floor);
		new iMasked = iHealth + iDmgTake;
		if (iMasked > g_iHealth[attacker]) set_pev(attacker, pev_health, float(g_iHealth[attacker]));
		else set_pev(attacker, pev_health, float(iMasked));
		
		
		// check if task not exists and dodging effect is not played
		if (!task_exists(attacker) && pev(attacker, pev_renderfx) != kRenderFxDistort)
		{
			fm_set_rendering(attacker, kRenderFxGlowShell, 0, min(2 * iDmgTake, 255), 0, kRenderNormal, 16);
			set_task(0.2, "RemoveGlowShell", attacker);
		}
		
		new iFlashPercent;
		if (!get_user_flashed(attacker, iFlashPercent) || iFlashPercent < 15)
		{
			static iMsgScreenFade;
			if (iMsgScreenFade || (iMsgScreenFade = get_user_msgid("ScreenFade")))
			{
				message_begin(MSG_ONE_UNRELIABLE, iMsgScreenFade, _, attacker);
				write_short(0x1000);
				write_short(0x0000);
				write_short(0x0000);
				write_byte(0);
				write_byte(255);
				write_byte(0);
				write_byte(iDmgTake);
				message_end();
			}
		}
	}
}

public Msg_TeamInfo(msg_id, msg_dest)
{
	if (msg_dest != MSG_ALL && msg_dest != MSG_BROADCAST)
		return;
	
	static id; id = get_msg_arg_int(1);
	static team[2]; get_msg_arg_string(2, team, charsmax(team));
	
	switch (team[0])
	{
		case 'S': g_iTeamID[id] = DM_TEAM_SPECTATOR;
		case 'C': g_iTeamID[id] = DM_TEAM_CT;
		case 'T': g_iTeamID[id] = DM_TEAM_T;
		default: g_iTeamID[id] = DM_TEAM_UNASSIGNED;
	}
}

public Msg_Health(msg_id, msg_dest, msg_entity)
{
	new iHealth = get_msg_arg_int(1);
	if (iHealth > g_iHealth[msg_entity])
	{
		g_iHealth[msg_entity] = iHealth;
	}
}

public RemoveGlowShell(id)
{
	if (!get_bitsum(bs_IsAlive, id))
		return;
	
	fm_set_rendering(id);
}

/* --------------------------------------------------------------------------- */

public Activate(id)
{
	if (!get_bitsum(bs_HaveItem, id))
	{
		static name[32];
		if (name[0] || DM_GetItemDisplayName(g_iItemID, name, 31))
		{
			#if AMXX_VERSION_NUM < 183
			dm_print_color(id, DontChange, "^4[%s]^1 You recover^4 %.2f%%^1 damage to health per shot!", name, get_pcvar_float(dm_item_mask_recover) * 100);
			#else
			client_print_color(id, print_team_default, "^4[%s]^1 You recover^4 %.2f%%^1 damage to health per shot!", name, get_pcvar_float(dm_item_mask_recover) * 100);
			#endif
		}
	}
	
	add_bitsum(bs_HaveItem, id);
}

public Deactivate(id)
{
	del_bitsum(bs_HaveItem, id);
}

/* --------------------------------------------------------------------------- */

stock fm_set_rendering(entity, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16)
{
	static Float:color[3];
	color[0] = float(r);
	color[1] = float(g);
	color[2] = float(b);
	
	set_pev(entity, pev_renderfx, fx);
	set_pev(entity, pev_rendercolor, color);
	set_pev(entity, pev_rendermode, render);
	set_pev(entity, pev_renderamt, float(amount));
}

stock get_user_flashed(id, &iPercent=0)
{
	if (pev_valid(id) != FM_PDATA_SAFE)
		return ALPHA_FULLBLINDED;
	
	new Float:flFlashedAt = get_pdata_float(id, m_flFlashedAt);
	
	if (!flFlashedAt)
	{
		return 0;
	}
	
	new Float:flGameTime = get_gametime();
	new Float:flTimeLeft = flGameTime - flFlashedAt;
	new Float:flFlashDuration = get_pdata_float(id, m_flFlashDuration);
	new Float:flFlashHoldTime = get_pdata_float(id, m_flFlashHoldTime);
	new Float:flTotalTime = flFlashHoldTime + flFlashDuration;
	
	if (flTimeLeft > flTotalTime)
	{
		return 0;
	}
	
	new iFlashAlpha = get_pdata_int(id, m_iFlashAlpha);
	
	if (iFlashAlpha == ALPHA_FULLBLINDED)
	{
		if (get_pdata_float(id, m_flFlashedUntil) - flGameTime > 0.0)
		{
			iPercent = 100;
		}
		else
		{
			iPercent = 100-floatround(((flGameTime - (flFlashedAt + flFlashHoldTime))*100.0)/flFlashDuration);
		}
	}
	else
	{
		iPercent = 100-floatround(((flGameTime - flFlashedAt)*100.0)/flTotalTime);
	}
	
	return iFlashAlpha;
}
