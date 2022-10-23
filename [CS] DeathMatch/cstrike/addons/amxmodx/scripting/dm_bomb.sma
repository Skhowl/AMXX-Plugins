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
#include <dm_spawn>
#include <dm_scenarios>

/* --------------------------------------------------------------------------- */

const Float:CHECK_FREQUENCY = 5.0;

new const WORLD_BOMBMODEL[] = "models/w_backpack.mdl";

#define TASK_FINDBOMB 777

enum BombStatus
{
	Float:ORIGIN_X,
	Float:ORIGIN_Y,
	Float:ORIGIN_Z,
	Status:BOMB
}

enum Status
{
	BOMB_PICKEDUP = -1,
	BOMB_DROPPED,
	BOMB_PLANTED
}

new g_BombStatus[BombStatus];
new Float:g_flExplodeTime = 0.0;

/* --------------------------------------------------------------------------- */

new g_iTeamID[DM_MAX_PLAYERS+1] = { 0, ... };

new g_iMsgBarTime = 0;
#if AMXX_VERSION_NUM < 183
new g_iMaxPlayers = 0;
#endif
new bool:g_bRoundEnd = false;
new bool:g_bBlockRadio = false;
new g_iHandleHookBarTime = 0;

new bool:g_bC4NoDamage = false;
new bool:g_bCzBotFix = false;
new Float:g_fC4Timer = 0.0;
new bool:g_bC4RoundTimer = false;
new g_iC4withKit = 5;
new g_iC4withoutKit = 10;
new bool:g_bC4NotDisposable = false;
new bool:g_bC4FallStraightDown = false;
new bool:g_bStatusIcon = false;
new g_iIconFlashing = 0;
new g_iIconColor[3] = { 0, ... };
new g_szIcon[32];
new g_iTime = 0;
new g_iBomb = 0;
new g_iBombDropID = 0;
new g_iSetModel = 0;

new p_BotQuota = 0;

// Structure members.
const m_fBombState = 96; // grenade
const m_flDefuseCountDown = 99; // grenade
const m_fPlayerBombStatus = 193; // player
const m_fBombDefusing = 232; // player
const m_flProgressBarStartTime = 605; // player
const m_flProgressBarEndTime = 606; // player

// Memory flags - m_fBombState.
const BombState_StartDefusing = (1<<0);
const BombState_PlantedC4 = (1<<8);

// Memory flags - m_fPlayerBombStatus.
const PlayerStatus_CanPlantBomb = (1<<8);
const PlayerStatus_HasDefusekit = (1<<16);

// Memory flags - m_fBombDefusing.
const BombStatus_BeingDefusing = (1<<8);

const FM_PDATA_SAFE = 2;
const OFFSET_ACTIVE_ITEM = 373;

new bs_IsConnected = 0;
new bs_IsAlive = 0;
new bs_IsBot = 0;

#define get_bitsum(%1,%2)   (%1 &   (1<<((%2-1)&31)))
#define add_bitsum(%1,%2)    %1 |=  (1<<((%2-1)&31))
#define del_bitsum(%1,%2)    %1 &= ~(1<<((%2-1)&31))

#define IsPDataInit(%1)			(pev_valid(%1) == FM_PDATA_SAFE)
#define IsBombPlanted(%1)		(!!(get_pdata_int(%1, m_fBombState) & BombState_PlantedC4))
#define IsBombStartDefusing(%1)	(!!(get_pdata_int(%1, m_fBombState) & BombState_StartDefusing))
#define HasDefuseKit(%1)		(!!(get_pdata_int(%1, m_fPlayerBombStatus) & PlayerStatus_HasDefusekit))
#define IsBombDefusing(%1)		(!!(get_pdata_int(%1, m_fBombDefusing) & BombStatus_BeingDefusing))

#define fm_find_ent_by_class(%1,%2) engfunc(EngFunc_FindEntityByString, %1, "classname", %2)
#define write_coord_f(%1) engfunc(EngFunc_WriteCoord, %1)

new const Float:g_flNullVelocity[3] = { 0.0, ... };

/* -Init---------------------------------------------------------------------- */

public plugin_natives()
{
	register_native("DM_GetDefuseTime", "native_get_defuse_time");
	register_library("dm_bomb");
}

public DM_OnModStatus(status)
{
	register_plugin("DM: Bomb", DM_VERSION_STR_LONG, "schmurgel1983");
	
	if (status) state enabled;
	else state deactivated;
}

public DM_OnMapConditions(bomb, vip, hosnum, hosid[]) <deactivated> {}
public DM_OnMapConditions(bomb, vip, hosnum, hosid[]) <enabled>
{
	if (!bomb) state deactivated;
}

public plugin_init() <deactivated> {}
public plugin_init() <enabled>
{
	if (!DM_LoadConfiguration("dm_bomb.cfg", "DM_ReadBomb"))
	{
		state deactivated;
		return;
	}
	
	register_event("ResetHUD", "EventResetHUD", "be");
	register_event("HLTV", "EventRoundStart", "a", "1=0", "2=0");
	register_event("TextMsg", "EventRoundEnd", "a", "2=#Game_Commencing", "2=#Game_will_restart_in");
	register_logevent("EventRoundEnd", 2, "1=Round_End");
	
	if (g_bC4NotDisposable)
		register_clcmd("drop", "Cmd_C4NotDisposable");
	
	register_message(get_user_msgid("TeamInfo"), "Msg_TeamInfo");
	if (g_bC4RoundTimer)
		register_message(get_user_msgid("RoundTime"), "Msg_RoundTime");
	
	if (g_bCzBotFix)
	{
		register_message(get_user_msgid("TextMsg"), "Msg_TextMsg");
		register_message(get_user_msgid("SendAudio"), "Msg_SendAudio");
	}
	
	if (g_bC4NoDamage)
		RegisterHam(Ham_TakeDamage, "player", "fwd_PlayerTakeDamage", false);
	
	if (g_iC4withKit || g_iC4withoutKit)
	{
		RegisterHam(Ham_Use, "grenade", "fwd_GrenadeUse", false);
		RegisterHam(Ham_Use, "grenade", "fwd_GrenadeUse_Post", true);
		g_iMsgBarTime = get_user_msgid("BarTime");
	}
	
	#if AMXX_VERSION_NUM < 183
	g_iMaxPlayers = get_maxplayers();
	#endif
}

public DM_ReadBomb(section[], key[], value[])
{
	if (equali(section, "bomb"))
	{
		if (equali(key, "c4_no_damage")) g_bC4NoDamage = !!bool:str_to_num(value);
		else if (equali(key, "c4_timer_additional")) g_fC4Timer = floatclamp(str_to_float(value), 0.0, 90.0);
		else if (equali(key, "c4_countdown_as_round_timer")) g_bC4RoundTimer = !!bool:str_to_num(value);
		else if (equali(key, "c4_defuse_time_with_kit")) g_iC4withKit = clamp(str_to_num(value), 0, 30); // 30 is hardcoded is dm_scenarios (line 398)
		else if (equali(key, "c4_defuse_time_without_kit")) g_iC4withoutKit = clamp(str_to_num(value), 0, 30); // 30 is hardcoded is dm_scenarios (line 398)
		else if (equali(key, "c4_not_disposable")) g_bC4NotDisposable = !!bool:str_to_num(value);
		else if (equali(key, "c4_fall_straight_down_on_death")) g_bC4FallStraightDown = !!bool:str_to_num(value);
		else if (equali(key, "cz_bot_fix")) g_bCzBotFix = !!bool:str_to_num(value);
	}
	else if (equali(section, "icon"))
	{
		if (equali(key, "status_icon")) g_bStatusIcon = !!bool:str_to_num(value);
		else if (equali(key, "icon_flashing")) g_iIconFlashing = !!str_to_num(value);
		else if (equali(key, "icon_name"))
		{
			copy(g_szIcon, charsmax(g_szIcon), value);
			remove_quotes(g_szIcon);
		}
		else if (equali(key, "icon_color"))
		{
			remove_quotes(value);
			
			new red[4], green[4], blue[4];
			parse(value, red, 3, green, 3, blue, 3);
			
			g_iIconColor[0] = clamp(str_to_num(red), 0, 255);
			g_iIconColor[1] = clamp(str_to_num(green), 0, 255);
			g_iIconColor[2] = clamp(str_to_num(blue), 0, 255);
		}
	}
}

public plugin_cfg() <deactivated> {}
public plugin_cfg() <enabled>
{
	p_BotQuota = get_cvar_pointer("bot_quota");
}

/* -Client-------------------------------------------------------------------- */

public client_putinserver(id) <deactivated> {}
public client_putinserver(id) <enabled>
{
	add_bitsum(bs_IsConnected, id);
	
	if (is_user_bot(id))
	{
		add_bitsum(bs_IsBot, id);
	}
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
	del_bitsum(bs_IsAlive, id);
	del_bitsum(bs_IsBot, id);
}

/* -Core---------------------------------------------------------------------- */

public DM_OnCzBotHamRegisterable(id) <deactivated> {}
public DM_OnCzBotHamRegisterable(id) <enabled>
{
	if (g_bC4NoDamage)
		RegisterHamFromEntity(Ham_TakeDamage, id, "fwd_PlayerTakeDamage", false);
}

/* -Spawn--------------------------------------------------------------------- */

public DM_PlayerSpawn_Post(id, freezetime, roundend) <deactivated> {}
public DM_PlayerSpawn_Post(id, freezetime, roundend) <enabled>
{
	add_bitsum(bs_IsAlive, id);
	
	if (!g_bCzBotFix || get_bitsum(bs_IsBot, id) || (p_BotQuota && !get_pcvar_num(p_BotQuota)))
		return;
	
	if (g_BombStatus[BOMB] == Status:BOMB_PLANTED && g_iTeamID[id] == DM_TEAM_CT)
	{
		g_bBlockRadio = true;
		engclient_cmd(id, "enemyspot");
		g_bBlockRadio = false;
	}
}

public DM_PlayerKilled_Pre(victim, attacker) <deactivated> {}
public DM_PlayerKilled_Pre(victim, attacker) <enabled>
{
	del_bitsum(bs_IsAlive, victim);
	
	if (get_bitsum(bs_IsBot, victim))
		return;
	
	SetStatusIcon(victim, 0);
}

/* -Scenarios----------------------------------------------------------------- */

public DM_BombPickup(id, freezetime, roundend) <deactivated> {}
public DM_BombPickup(id, freezetime, roundend) <enabled>
{
	g_BombStatus[BOMB] = _:BOMB_PICKEDUP;
	
	g_iBomb = 0;
}

public DM_BombDropped(id, freezetime, roundend) <deactivated> {}
public DM_BombDropped(id, freezetime, roundend) <enabled>
{
	g_BombStatus[BOMB] = _:BOMB_DROPPED;
	
	g_iBombDropID = id;
	pev(id, pev_origin, g_BombStatus);
	
	g_iSetModel = register_forward(FM_SetModel, "fwd_SetModel");
}

public DM_BombPlanted(id, roundend) <deactivated> {}
public DM_BombPlanted(id, roundend) <enabled>
{
	if (roundend) return;
	
	remove_task(TASK_FINDBOMB);
	g_BombStatus[BOMB] = _:BOMB_PLANTED;
	
	#if AMXX_VERSION_NUM < 183
	for (new id = 1; id <= g_iMaxPlayers; id++)
	#else
	for (new id = 1; id <= MaxClients; id++)
	#endif
	{
		if (!get_bitsum(bs_IsAlive, id) || get_bitsum(bs_IsBot, id))
			continue;
		
		SetStatusIcon(id, 1 + g_iIconFlashing);
	}
	
	if (g_bC4RoundTimer)
		SetRoundTime();
}

/* -Forwards------------------------------------------------------------------ */

public fwd_SetModel(entity, const model[])
{
	// We don't care
	if (!equal(model, WORLD_BOMBMODEL))
		return;
	
	unregister_forward(FM_SetModel, g_iSetModel);
	
	g_iBomb = entity;
	if (g_bC4FallStraightDown && !get_bitsum(bs_IsAlive, g_iBombDropID))
	{
		set_pev(entity, pev_origin, g_BombStatus);
		set_pev(entity, pev_velocity, g_flNullVelocity);
	}
}

public Cmd_C4NotDisposable(id)
{
	if (!get_bitsum(bs_IsAlive, id) || get_bitsum(bs_IsBot, id))
		return PLUGIN_CONTINUE;
	
	if (ham_cs_get_current_weapon_id(id) == CSW_C4)
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public fwd_PlayerTakeDamage(victim, inflictor, attacker, Float:damage, damagebits)
{
	if (damagebits & DMG_BLAST)
		return HAM_SUPERCEDE;
	
	return FMRES_IGNORED;
}

public fwd_GrenadeUse(const grenade, const caller, const activator, const useType, const Float:value)
{
	if (IsPDataInit(grenade) && IsBombPlanted(grenade) && g_iTeamID[activator] == DM_TEAM_CT && !IsBombStartDefusing(grenade))
	{
		g_iHandleHookBarTime = register_message(g_iMsgBarTime, "Msg_BarTime");
	}
}

public fwd_GrenadeUse_Post(const grenade, const caller, const activator, const useType, const Float:value)
{
	if (g_iHandleHookBarTime && IsPDataInit(grenade) && IsPDataInit(activator))
	{
		new Float:flTime = get_gametime();
		
		set_pdata_float(activator, m_flProgressBarStartTime, flTime);
		set_pdata_float(activator, m_flProgressBarEndTime, flTime + g_iTime);
		set_pdata_float(grenade, m_flDefuseCountDown, flTime + g_iTime);
		
		unregister_message(g_iHandleHookBarTime, g_iMsgBarTime);
		g_iHandleHookBarTime = 0;
		g_iTime = 0;
	}
}

/* -Events-------------------------------------------------------------------- */

public EventResetHUD(id)
{
	if (!get_bitsum(bs_IsBot, id))
		set_task(0.2, "SetRadarBombDot", id);
}

public EventRoundStart()
{
	g_bRoundEnd = false;
	g_iBomb = 0;
	
	remove_task(TASK_FINDBOMB);
	set_task(CHECK_FREQUENCY, "FindBombTask", TASK_FINDBOMB, _, _, "b");
}

public EventRoundEnd()
{
	g_bRoundEnd = true;
	remove_task(TASK_FINDBOMB);
	g_BombStatus[BOMB] = _:BOMB_PICKEDUP;
	
	#if AMXX_VERSION_NUM < 183
	for (new id = 1; id <= g_iMaxPlayers; id++)
	#else
	for (new id = 1; id <= MaxClients; id++)
	#endif
	{
		if (!get_bitsum(bs_IsConnected, id) || get_bitsum(bs_IsBot, id))
			continue;
		
		SetStatusIcon(id, 0);
	}
}

/* -Tasks--------------------------------------------------------------------- */

public FindBombTask(taskid)
{
	if (g_iBomb && pev_valid(g_iBomb))
	{
		pev(g_iBomb, pev_origin, g_BombStatus);
		g_BombStatus[BOMB] = _:BOMB_DROPPED;
		
		// damn man, never remove the f***ing bomb! (thanks valve)
		// info: when bomb dropped, game set next think to 5 min for remove bomb...
		set_pev(g_iBomb, pev_nextthink, get_gametime() + 9999.0);
		
		return;
	}
	
	new id, players[32], num;
	
	#if AMXX_VERSION_NUM < 183
	for (id = 1; id <= g_iMaxPlayers; id++)
	#else
	for (id = 1; id <= MaxClients; id++)
	#endif
	{
		if (get_bitsum(bs_IsAlive, id) && g_iTeamID[id] == DM_TEAM_T)
		{
			players[num] = id;
			num++;
		}
	}
	
	if (num == 0) return;
	
	for (id = 0; id < num; id++)
	{
		if (pev(players[id], pev_weapons) & (1<<CSW_C4))
		{
			g_BombStatus[BOMB] = _:BOMB_PICKEDUP;
			
			return;
		}
	}
	
	remove_task(taskid);
}

/* -Misc---------------------------------------------------------------------- */

public SetRadarBombDot(id)
{
	if (!get_bitsum(bs_IsAlive, id) || g_bRoundEnd)
		return;
	
	if (g_BombStatus[BOMB] == Status:BOMB_PLANTED)
	{
		SetStatusIcon(id, 1 + g_iIconFlashing);
	}
	else if (g_iTeamID[id] == DM_TEAM_T)
	{
		if (g_BombStatus[BOMB] == Status:BOMB_PICKEDUP)
		{
			static iMsgBombPickup;
			if (iMsgBombPickup || (iMsgBombPickup = get_user_msgid("BombPickup")))
			{
				message_begin(MSG_ONE, iMsgBombPickup, _, id);
				message_end();
			}
		}
		else if (g_BombStatus[BOMB] == Status:BOMB_DROPPED)
		{
			static iMsgBombDrop;
			if (iMsgBombDrop || (iMsgBombDrop = get_user_msgid("BombDrop")))
			{
				message_begin(MSG_ONE, iMsgBombDrop, _, id);
				write_coord_f(g_BombStatus[ORIGIN_X]);
				write_coord_f(g_BombStatus[ORIGIN_Y]);
				write_coord_f(g_BombStatus[ORIGIN_Z]);
				write_byte(1);
				message_end();
			}
		}
	}
}

SetStatusIcon(index, action)
{
	if (!g_bStatusIcon)
		return;
	
	static iMsgStatusIcon;
	if (iMsgStatusIcon || (iMsgStatusIcon = get_user_msgid("StatusIcon")))
	{
		message_begin(MSG_ONE, iMsgStatusIcon, _, index);
		write_byte(action);
		write_string(g_szIcon);
		write_byte(g_iIconColor[0]);
		write_byte(g_iIconColor[1]);
		write_byte(g_iIconColor[2]);
		message_end();
	}
}

SetRoundTime()
{
	new entity = FM_NULLENT;
	const OFFSET_C4_EXPLODE_TIME = 100;
	
	while ((entity = fm_find_ent_by_class(entity, "grenade")))
	{
		if (get_pdata_int(entity, 96, 5) & (1<<8))
		{
			if (g_fC4Timer > 0.0)
			{
				g_flExplodeTime = get_pdata_float(entity, OFFSET_C4_EXPLODE_TIME, 5) + g_fC4Timer;
				set_pdata_float(entity, OFFSET_C4_EXPLODE_TIME, g_flExplodeTime, 5);
			}
			else g_flExplodeTime = get_pdata_float(entity, OFFSET_C4_EXPLODE_TIME, 5);
		}
	}
	
	static iMsgShowTimer;
	if (iMsgShowTimer || (iMsgShowTimer = get_user_msgid("ShowTimer")))
	{
		message_begin(MSG_ALL, iMsgShowTimer);
		message_end();
	}
	
	static iMsgRoundTime;
	if (iMsgRoundTime || (iMsgRoundTime = get_user_msgid("RoundTime")))
	{
		message_begin(MSG_ALL, iMsgRoundTime);
		write_short(floatround(g_flExplodeTime - get_gametime()));
		message_end();
	}
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
	if (!g_bBlockRadio)
		return PLUGIN_CONTINUE;
	
	if (get_msg_args() == 5 && get_msg_argtype(5) == ARG_STRING) // CS
	{
		new value[21];
		get_msg_arg_string(5, value, 20);
		
		if (equal(value, "#Enemy_spotted"))
			return PLUGIN_HANDLED;
	}
	else if (get_msg_args() == 6 && get_msg_argtype(6) == ARG_STRING) // CZ
	{
		new value[21];
		get_msg_arg_string(6, value, 20);
		
		if (equal(value, "#Enemy_spotted"))
			return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public Msg_SendAudio()
{
	if (!g_bBlockRadio)
		return PLUGIN_CONTINUE;
	
	if (get_msg_args() == 3 && get_msg_argtype(2) == ARG_STRING)
	{
		new value[17];
		get_msg_arg_string(2, value, 16);
		
		if (equal(value, "%!MRAD_ENEMYSPOT"))
			return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

/*
* floatround_round 5.4 = 5
* floatround_round 5.6 = 6
* floatround_floor 5.4 = 5
* floatround_floor 5.6 = 5
* floatround_ceil 5.4 = 6
* floatround_ceil 5.6 = 6
* floatround_tozero 5.4 = 5
* floatround_tozero 5.6 = 5
*/

public Msg_RoundTime(msg_id, msg_dest, msg_entity)
{
	if (msg_dest != MSG_ONE)
		return;
	
	if (g_BombStatus[BOMB] == Status:BOMB_PLANTED)
	{
		set_msg_arg_int(1, ARG_SHORT, floatround(g_flExplodeTime - get_gametime()));
	}
}

public Msg_BarTime(msg_id, msg_dest, msg_entity)
{
	if (IsPDataInit(msg_entity) && IsBombDefusing(msg_entity))
	{
		set_msg_arg_int(1, ARG_SHORT, g_iTime = HasDefuseKit(msg_entity) ? (g_iC4withKit ? g_iC4withKit : 5) : (g_iC4withoutKit ? g_iC4withoutKit : 10));
	}
}

/* -Native-------------------------------------------------------------------- */

/* native DM_GetDefuseTime(); */
public native_get_defuse_time(plugin_id, num_params) <deactivated> return 0;
public native_get_defuse_time(plugin_id, num_params) <enabled>
{
	return g_iTime;
}

/* -Stocks-------------------------------------------------------------------- */

stock ham_cs_get_current_weapon_id(id)
{
	if (pev_valid(id) != FM_PDATA_SAFE)
		return -1;
	
	new entity = get_pdata_cbase(id, OFFSET_ACTIVE_ITEM);
	
	return pev_valid(entity) ? cs_get_weapon_id(entity) : -1;
}
