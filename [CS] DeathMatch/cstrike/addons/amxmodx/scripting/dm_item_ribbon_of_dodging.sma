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
#include <dm_items>
#include <dm_ffa>
#include <dm_colorchat>

/* --------------------------------------------------------------------------- */

const FM_PDATA_SAFE = 2;

new dm_item_ribbon_dodging_chance = 0;

new g_iItemID = -1;
new g_iFreeForAllEnabled = 0;

new g_iTeamID[DM_MAX_PLAYERS+1] = 0;

new bs_IsAlive = 0;
new bs_HaveItem = 0;

#define DMG_BULLET (1<<1) // Shot

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

new const item_name[] = { "ribbon_of_dodging" };
new const item_chat[] = { "ribbon" };
const item_teams = DM_TEAM_ANY;
const item_cost = 100;
const item_holdtime = 90;

/* --------------------------------------------------------------------------- */

public DM_OnModStatus(status)
{
	register_plugin("DM Item: Ribbon of Dodging", "1.0.0", "schmurgel1983");
	
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
	
	dm_item_ribbon_dodging_chance = register_cvar("dm_item_ribbon_dodging_chance", "10");
	
	RegisterHam(Ham_TraceAttack, "player", "fwd_TraceAttack", false);
	
	register_message(get_user_msgid("TeamInfo"), "Msg_TeamInfo");
	
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
	RegisterHamFromEntity(Ham_TraceAttack, id, "fwd_TraceAttack", false);
}

/* --------------------------------------------------------------------------- */

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

public fwd_TraceAttack(victim, attacker, Float:damage, Float:direction[3], tracehandle, damage_type)
{
	if (!get_bitsum(bs_HaveItem, victim) || victim == attacker || !(damage_type & DMG_BULLET) || !is_user_valid_alive(attacker) || (!g_iFreeForAllEnabled && g_iTeamID[victim] == g_iTeamID[attacker]))
		return HAM_IGNORED;
	
	if (random_num(1, 100) <= get_pcvar_num(dm_item_ribbon_dodging_chance) || task_exists(victim))
	{
		// check if task not exists and mask effect is not played
		if (!task_exists(victim) && pev(victim, pev_renderfx) != kRenderFxGlowShell)
		{
			fm_set_rendering(victim, kRenderFxDistort, 0, 0, 0, kRenderTransTexture, 90);
			set_task(0.2, "RemoveDistort", victim);
		}
		
		new iFlashPercent;
		if (!get_user_flashed(victim, iFlashPercent) || iFlashPercent < 15)
		{
			static iMsgScreenFade;
			if (iMsgScreenFade || (iMsgScreenFade = get_user_msgid("ScreenFade")))
			{
				message_begin(MSG_ONE_UNRELIABLE, iMsgScreenFade, _, victim);
				write_short(0x1000);
				write_short(0x0000);
				write_short(0x0000);
				write_byte(0);
				write_byte(0);
				write_byte(255);
				write_byte(64);
				message_end();
			}
		}
		return HAM_SUPERCEDE;
	}
	
	return HAM_IGNORED;
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

public RemoveDistort(id)
{
	if (!get_bitsum(bs_IsAlive, id))
		return;
	
	if (pev(id, pev_renderfx) != kRenderFxGlowShell)
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
			dm_print_color(id, DontChange, "^4[%s]^1 You have a chance of^4 %d%%^1 to dodging a shot!", name, get_pcvar_num(dm_item_ribbon_dodging_chance));
			#else
			client_print_color(id, print_team_default, "^4[%s]^1 You have a chance of^4 %d%%^1 to dodging a shot!", name, get_pcvar_num(dm_item_ribbon_dodging_chance));
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
