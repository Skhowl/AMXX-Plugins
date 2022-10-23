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

/* --------------------------------------------------------------------------- */

const FM_PDATA_SAFE = 2;
const OFFSET_TK = 127;
const DMG_HEGRENADE = (1<<24);
const Float:FL_TEAMATTACK_MULTIPLY = 2.8572;

new g_iTeamID[DM_MAX_PLAYERS+1] = { 0, ... };

new bool:g_bEnabledFFA = false;
new bool:g_bRemoveMsg = false;
new bool:g_bFragsFix = false;
new bool:g_bPreventKick = false;
new bool:g_bAllSameModel = false;
new g_szModel[32] = "vip";


new Float:g_fModelsTargetTime = 0.0;

new bs_IsConnected = 0;

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

public plugin_natives()
{
	register_native("DM_IsFreeForAllEnabled", "native_is_ffa_enabled");
	register_library("dm_ffa");
}

public DM_OnModStatus(status)
{
	register_plugin("DM: FFA", DM_VERSION_STR_LONG, "schmurgel1983");
	
	if (status) state enabled;
	else state deactivated;
}

public plugin_precache() <deactivated> {}
public plugin_precache() <enabled>
{
	if (!DM_LoadConfiguration("dm_ffa.cfg", "DM_ReadFFA") || !g_bEnabledFFA)
	{
		state deactivated;
		return;
	}
	
	if (!g_bAllSameModel)
		return;
	
	new buffer[96];
	format(buffer, charsmax(buffer), "models/player/%s/%s.mdl", g_szModel, g_szModel);
	
	if (file_exists(buffer))
	{
		engfunc(EngFunc_PrecacheModel, buffer);
	}
	else
	{
		format(buffer, charsmax(buffer), "models/player/vip/vip.mdl");
		engfunc(EngFunc_PrecacheModel, buffer);
	}
}

public DM_ReadFFA(section[], key[], value[])
{
	if (equali(section, "ffa"))
	{
		if (equali(key, "enabled")) g_bEnabledFFA = !!bool:str_to_num(value);
		else if (equali(key, "remove_ta_tk_msg")) g_bRemoveMsg = !!bool:str_to_num(value);
		else if (equali(key, "tk_frags_fix")) g_bFragsFix = !!bool:str_to_num(value);
		else if (equali(key, "prevent_tk_kick")) g_bPreventKick = !!bool:str_to_num(value);
	}
	else if (equali(section, "model"))
	{
		if (equali(key, "all_same_model")) g_bAllSameModel = !!bool:str_to_num(value);
		else if (equali(key, "model"))
		{
			copy(g_szModel, charsmax(g_szModel), value);
			remove_quotes(g_szModel);
		}
	}
}

public plugin_init() <deactivated> {}
public plugin_init() <enabled>
{
	RegisterHam(Ham_TakeDamage, "player", "fwd_TakeDamage", false);
	
	if (g_bAllSameModel)
	{
		register_forward(FM_SetClientKeyValue, "fwd_SetClientKeyValue");
	}
	
	register_message(get_user_msgid("TeamInfo"), "Msg_TeamInfo");
	if (g_bRemoveMsg)
	{
		register_message(get_user_msgid("TextMsg"), "Msg_TextMsg");
	}
	
	#if AMXX_VERSION_NUM < 183
	g_iMaxPlayers = get_maxplayers();
	#endif
	
	set_task(5.0, "delayed_cvars", _, _, _, "a", 4);
}

public delayed_cvars()
{
	server_cmd("mp_tkpunish 0");
	server_cmd("mp_friendlyfire 1");
	server_cmd("mp_playerid 2");
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
	RegisterHamFromEntity(Ham_TakeDamage, id, "fwd_TakeDamage", false);
}

/* -Spawn--------------------------------------------------------------------- */

public DM_PlayerSpawn_Post(id, freezetime, roundend) <deactivated> {}
public DM_PlayerSpawn_Post(id, freezetime, roundend) <enabled>
{
	if (!g_bAllSameModel)
		return;
	
	static currentmodel[32], already_has_model;
	already_has_model = false;
	
	fm_cs_get_user_model(id, currentmodel, charsmax(currentmodel));
	if (equal(currentmodel, g_szModel))
		already_has_model = true;
	
	if (!already_has_model)
		fm_user_model_update(id);
}

public DM_PlayerKilled_Pre(victim, attacker) <deactivated> {}
public DM_PlayerKilled_Pre(victim, attacker) <enabled>
{
	if (!g_bFragsFix || !is_user_valid_connected(attacker) || victim == attacker)
		return;
	
	if (g_iTeamID[victim] == g_iTeamID[attacker])
	{
		dm_cs_set_user_tked(attacker);
	}
}

/* -Forwards------------------------------------------------------------------ */

public fwd_TakeDamage(victim, inflictor, attacker, Float:damage, damagebits)
{
	if (!is_user_valid_connected(attacker) || victim == attacker || damagebits & DMG_HEGRENADE)
		return HAM_IGNORED;
	
	if (g_iTeamID[victim] == g_iTeamID[attacker])
	{
		SetHamParamFloat(4, damage*FL_TEAMATTACK_MULTIPLY);
	}
	
	return HAM_IGNORED;
}

public fwd_SetClientKeyValue(id, const infobuffer[], const key[])
{
	if (key[0] == 'm' && key[1] == 'o' && key[2] == 'd' && key[3] == 'e' && key[4] == 'l')
		return FMRES_SUPERCEDE;
	
	return FMRES_IGNORED;
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

public Msg_TextMsg()
{
	if (get_msg_args() < 2 || get_msg_argtype(2) != ARG_STRING)
		return PLUGIN_CONTINUE;
	
	static textmsg[22];
	get_msg_arg_string(2, textmsg, charsmax(textmsg));
	if (equal(textmsg, "#Game_teammate_attack") || equal(textmsg, "#Killed_Teammate"))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

/* -Misc---------------------------------------------------------------------- */

dm_cs_set_user_tked(id)
{
	set_pev(id, pev_frags, float(pev(id, pev_frags) + 2));
	
	if (g_bPreventKick)
	{
		if (pev_valid(id) != FM_PDATA_SAFE)
			return;
		
		set_pdata_int(id, OFFSET_TK, -1);
	}
}

public fm_user_model_update(id)
{
	static Float:current_time;
	current_time = get_gametime();
	
	if (current_time - g_fModelsTargetTime >= 0.25)
	{
		fm_cs_set_user_model(id);
		g_fModelsTargetTime = current_time;
	}
	else
	{
		remove_task(id);
		set_task((g_fModelsTargetTime + 0.25) - current_time, "fm_cs_set_user_model", id);
		g_fModelsTargetTime = g_fModelsTargetTime + 0.25;
	}
}

/* -Native-------------------------------------------------------------------- */

/* native DM_IsFreeForAllEnabled(); */
public native_is_ffa_enabled(plugin_id, num_params)
{
	return g_bEnabledFFA;
}

/* -Stocks-------------------------------------------------------------------- */

public fm_cs_set_user_model(id)
{
	set_user_info(id, "model", g_szModel);
}

stock fm_cs_get_user_model(player, model[], len)
{
	get_user_info(player, "model", model, len);
}
