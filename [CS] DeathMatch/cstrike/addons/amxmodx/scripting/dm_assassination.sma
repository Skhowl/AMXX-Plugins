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
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>

#include <dm_core>
#include <dm_scenarios>

/* --------------------------------------------------------------------------- */

const OFFSET_PAINSHOCK = 108; // ConnorMcLeod

new const armor_sound[] = { "player/bhit_kevlar-1.wav" };
new const helm_sound[] = { "player/bhit_helmet-1.wav" };
new const shield_sound[] = { "weapons/ric_metal-1.wav" };

new g_iTeamID[DM_MAX_PLAYERS+1] = { 0, ... };

new g_iVipArmorCalc = -1;
new g_iVipArmorEffect = 1;

new bs_IsConnected = 0;
new bs_IsVip = 0;

#define get_bitsum(%1,%2)   (%1 &   (1<<((%2-1)&31)))
#define add_bitsum(%1,%2)    %1 |=  (1<<((%2-1)&31))
#define del_bitsum(%1,%2)    %1 &= ~(1<<((%2-1)&31))

#if AMXX_VERSION_NUM < 183
new g_iMaxPlayers = 0;
#define is_user_valid_connected(%1) (1 <= %1 <= g_iMaxPlayers && get_bitsum(bs_IsConnected, %1))
#else
#define is_user_valid_connected(%1) (1 <= %1 <= MaxClients && get_bitsum(bs_IsConnected, %1))
#endif

/* -Init---------------------------------------------------------------------- */

public DM_OnModStatus(status)
{
	register_plugin("DM: Assassination", DM_VERSION_STR_LONG, "schmurgel1983");
	
	if (status) state enabled;
	else state deactivated;
}

public plugin_precache() <deactivated> {}
public plugin_precache() <enabled>
{
	precache_sound(armor_sound);
	precache_sound(helm_sound);
	precache_sound(shield_sound);
}

public DM_OnMapConditions(bomb, vip, hosnum, hosid[]) <deactivated> {}
public DM_OnMapConditions(bomb, vip, hosnum, hosid[]) <enabled>
{
	if (!vip) state deactivated;
}

public plugin_init() <deactivated> {}
public plugin_init() <enabled>
{
	if (!DM_LoadConfiguration("dm_assassination.cfg", "DM_ReadAssassination") || g_iVipArmorCalc == -1)
	{
		state deactivated;
		return;
	}
	
	RegisterHam(Ham_TraceAttack, "player", "fwd_TraceAttack", false);
	
	register_message(get_user_msgid("TeamInfo"), "Msg_TeamInfo");
	
	#if AMXX_VERSION_NUM < 183
	g_iMaxPlayers = get_maxplayers();
	#endif
}

public DM_ReadAssassination(section[], key[], value[])
{
	if (equali(section, "assassination"))
	{
		if (equali(key, "vip_armor_calc")) g_iVipArmorCalc = clamp(str_to_num(value), -1, 128);
		else if (equali(key, "vip_armor_effect")) g_iVipArmorEffect = !!str_to_num(value);
	}
}

/* -Client-------------------------------------------------------------------- */

public client_putinserver(id) <deactivated> {}
public client_putinserver(id) <enabled>
{
	add_bitsum(bs_IsConnected, id);
}

#if AMXX_VERSION_NUM < 183
public client_disconnect(id) <deactivated> {}
public client_disconnect(id) <enabled>
#else
public client_disconnected(id, bool:drop, message[], maxlen) <deactivated> {}
public client_disconnected(id, bool:drop, message[], maxlen) <enabled>
#endif
{
	del_bitsum(bs_IsConnected, id);
}

/* -Core---------------------------------------------------------------------- */

public DM_OnCzBotHamRegisterable(id) <deactivated> {}
public DM_OnCzBotHamRegisterable(id) <enabled>
{
	RegisterHamFromEntity(Ham_TraceAttack, id, "fwd_TraceAttack", false);
}

/* -Scenarios----------------------------------------------------------------- */

public DM_BecameVip(id) <deactivated> {}
public DM_BecameVip(id) <enabled>
{
	bs_IsVip = 0;
	add_bitsum(bs_IsVip, id);
}

/* -Forwards------------------------------------------------------------------ */

public fwd_TraceAttack(victim, attacker, Float:damage, Float:direction[3], tracehandle, damage_type)
{
	if (get_bitsum(bs_IsVip, victim))
	{
		if (!is_user_valid_connected(attacker) || g_iTeamID[attacker] == DM_TEAM_CT)
			return HAM_SUPERCEDE;
		
		static Float:flArmor;
		pev(victim, pev_armorvalue, flArmor);
		
		if (flArmor > 0.0)
		{
			if (g_iVipArmorEffect)
			{
				new Float:flOrigin[3], Origin[3];
				get_tr2(tracehandle, TR_vecEndPos, flOrigin);
				
				Origin[0] = floatround(flOrigin[0]);
				Origin[1] = floatround(flOrigin[1]);
				Origin[2] = floatround(flOrigin[2]);
				
				message_begin(MSG_PVS, SVC_TEMPENTITY, Origin);
				write_byte(TE_SPARKS);
				write_coord(Origin[0]);
				write_coord(Origin[1]);
				write_coord(Origin[2]);
				message_end();
				
				emit_sound(victim, CHAN_BODY, shield_sound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			}
			else
			{
				if (get_tr2(tracehandle, TR_iHitgroup) == HIT_HEAD) emit_sound(victim, CHAN_BODY, helm_sound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
				else emit_sound(victim, CHAN_BODY, armor_sound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			}
			
			static Float:flDamage;
			if (g_iVipArmorCalc == 0) flDamage = damage / dm_get_players(DM_TEAM_T);
			else flDamage = damage / g_iVipArmorCalc;
			
			if (flArmor - flDamage > 0.01) set_pev(victim, pev_armorvalue, flArmor - flDamage);
			else cs_set_user_armor(victim, 0, CS_ARMOR_NONE);
			
			set_pdata_float(victim, OFFSET_PAINSHOCK, 0.5);
			return HAM_SUPERCEDE;
		}
	}
	
	return HAM_IGNORED;
}

/* -Misc---------------------------------------------------------------------- */

dm_get_players(const team)
{
	static id, count;
	count = 0;
	#if AMXX_VERSION_NUM < 183
	for (id = 1; id <= g_iMaxPlayers; id++)
	#else
	for (id = 1; id <= MaxClients; id++)
	#endif
	{
		if (!get_bitsum(bs_IsConnected, id) || g_iTeamID[id] != team)
			continue;
		
		count++;
	}
	
	return count;
}

/* -Messages------------------------------------------------------------------ */

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
