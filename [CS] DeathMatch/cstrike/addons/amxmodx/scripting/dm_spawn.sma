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
#pragma dynamic 8192 // 32kb

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#include <dm_core>
#include <dm_ffa>
#include <dm_log>

#define LIBRARY_TSC "cs_team_semiclip"

/* --------------------------------------------------------------------------- */

const FM_PDATA_SAFE = 2;
const OFFSET_MENUCODE = 205;
const MENU_JOINCLASS = 3;

new bool:g_bEnabled = false;

new bool:g_bSpawnWaitBar = false;
new bool:g_bSpawnWaitBarFix = false;
new bool:g_bSpawnRadioMsg = false;

new Float:g_fSpawnWaitTime = 0.0;

new Float:g_fSpawnDynamicWaitTime = 0.0;
new g_iSpawnDynamicMinPlayers = 0;
new Float:g_fSpawnDynamicMinTime = 0.0;
new Float:g_fSpawnDynamicMaxTime = 0.0;
new Float:g_fCachedWaitTimes[DM_MAX_PLAYERS+1] = { 0.0, ... };

new Float:g_fHoldTime = 0.0;
new bool:g_bRoundEndProtect = false;
new g_iColorsTer[4] = { 0, ... };
new g_iColorsCT[4] = { 0, ... };
new g_iColorsFFA[4] = { 0, ... };

new g_iFwdSpawnPre = 0;
new g_iFwdSpawnPost = 0;
new g_iFwdKilledPre = 0;
new g_iFwdKilledPost = 0;
new g_iFwdRespawnAttempt = 0;
new g_iFwdProtection = 0;
new g_iFwdProtectionEnds = 0;
new g_iFwdDummyResult = 0;

new g_iTeamID[DM_MAX_PLAYERS+1] = { 0, ... };
new g_iMsgBarTime2 = 0;
#if AMXX_VERSION_NUM < 183
new g_iMaxPlayers = 0;
#endif
new bool:g_bIsTeamSemiclip = false;
new bool:g_bIsFreeForAllEnabled = false;
new bool:g_bFreezeTime = false;
new bool:g_bRoundEnd = false;

new g_szSpawnMode[32];
new Array:g_SpawnModeName = Invalid_Array;
new Array:g_SpawnModeID = Invalid_Array;
new g_iSpawnModeCount = 0;
new g_iForwardID = 0;

new bs_IsConnected = 0;
new bs_IsAlive = 0;
new bs_IsBot = 0;
new bs_IsProtected = 0;

#define get_bitsum(%1,%2)   (%1 &   (1<<((%2-1)&31)))
#define add_bitsum(%1,%2)    %1 |=  (1<<((%2-1)&31))
#define del_bitsum(%1,%2)    %1 &= ~(1<<((%2-1)&31))

enum _:TaskData
{
    Float:Tricky
}

enum (+= 50)
{
	TASK_RESPAWN = 500,
	TASK_PROTECTION,
	TASK_BARFIX
}
#define ID_RESPAWN    (taskid - TASK_RESPAWN)
#define ID_PROTECTION (taskid - TASK_PROTECTION)
#define ID_BARFIX     (taskid - TASK_BARFIX)

native tsc_set_user_rendering(id, special = 0, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16);

/* -Init---------------------------------------------------------------------- */

public plugin_natives()
{
	register_native("DM_RegisterSpawnMode", "native_register_mode");
	register_library("dm_spawn");
	
	set_module_filter("module_filter");
	set_native_filter("native_filter");
}
public module_filter(const module[])
{
	if (equal(module, LIBRARY_TSC))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}
public native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public DM_OnModStatus(status)
{
	register_plugin("DM: Spawn", DM_VERSION_STR_LONG, "schmurgel1983");
	
	if (status)
	{
		g_SpawnModeName = ArrayCreate(32, 1);
		g_SpawnModeID = ArrayCreate(1, 1);
		
		state enabled;
	}
	else state deactivated;
}

public plugin_init() <deactivated> {}
public plugin_init() <enabled>
{
	if (!DM_LoadConfiguration("dm_spawn.cfg", "DM_ReadSpawn"))
	{
		ArrayDestroy(g_SpawnModeName);
		ArrayDestroy(g_SpawnModeID);
		
		state deactivated;
		return;
	}
	
	g_iFwdSpawnPre = CreateMultiForward("DM_PlayerSpawn_Pre", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL);
	g_iFwdSpawnPost = CreateMultiForward("DM_PlayerSpawn_Post", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL);
	g_iFwdKilledPre = CreateMultiForward("DM_PlayerKilled_Pre", ET_IGNORE, FP_CELL, FP_CELL);
	g_iFwdKilledPost = CreateMultiForward("DM_PlayerKilled_Post", ET_IGNORE, FP_CELL, FP_CELL);
	g_iFwdRespawnAttempt = CreateMultiForward("DM_RespawnAttempt", ET_STOP, FP_CELL);
	g_iFwdProtection = CreateMultiForward("DM_SpawnProtection", ET_STOP, FP_CELL, FP_CELL, FP_CELL);
	g_iFwdProtectionEnds = CreateMultiForward("DM_SpawnProtectionEnds", ET_IGNORE, FP_CELL);
	
	RegisterHam(Ham_Spawn, "player", "fwd_PlayerSpawn_Pre", false);
	RegisterHam(Ham_Spawn, "player", "fwd_PlayerSpawn_Post", true);
	RegisterHam(Ham_Killed, "player", "fwd_PlayerKilled_Pre", false);
	RegisterHam(Ham_Killed, "player", "fwd_PlayerKilled_Post", true);
	
	register_forward(FM_CmdStart, "fwd_CmdStart", false);
	
	register_event("HLTV", "EventRoundStart", "a", "1=0", "2=0");
	register_event("TextMsg", "EventRoundEnd", "a", "2=#Game_Commencing", "2=#Game_will_restart_in");
	register_logevent("LogEventRoundStart", 2, "1=Round_Start");
	register_logevent("EventRoundEnd", 2, "1=Round_End");
	
	register_clcmd("say /spawn", "ClientCmdRespawn");
	register_clcmd("say spawn", "ClientCmdRespawn");
	register_clcmd("say /respawn", "ClientCmdRespawn");
	register_clcmd("say respawn", "ClientCmdRespawn");
	register_clcmd("say_team /spawn", "ClientCmdRespawn");
	register_clcmd("say_team spawn", "ClientCmdRespawn");
	register_clcmd("say_team /respawn", "ClientCmdRespawn");
	register_clcmd("say_team respawn", "ClientCmdRespawn");
	
	register_clcmd("joinclass", "ClientCmdJoinclass");
	register_clcmd("menuselect", "ClientCmdMenuSelect");
	
	g_iMsgBarTime2 = get_user_msgid("BarTime2");
	
	register_message(get_user_msgid("TeamInfo"), "Msg_TeamInfo");
}

public DM_ReadSpawn(section[], key[], value[])
{
	if (equali(section, "spawn"))
	{
		if (equali(key, "enabled")) g_bEnabled = !!bool:str_to_num(value);
		else if (equali(key, "spawn_mode")) copy(g_szSpawnMode, charsmax(g_szSpawnMode), value);
		else if (equali(key, "spawn_wait_bar")) g_bSpawnWaitBar = !!bool:str_to_num(value);
		else if (equali(key, "spawn_wait_bar_fix")) g_bSpawnWaitBarFix = !!bool:str_to_num(value);
		else if (equali(key, "spawn_radio_msg")) g_bSpawnRadioMsg = !!bool:str_to_num(value);
	}
	else if (equali(section, "normal"))
	{
		if (equali(key, "spawn_wait_time")) g_fSpawnWaitTime = floatclamp(str_to_float(value), 0.0, 15.0);
	}
	else if (equali(section, "dynamic"))
	{
		if (equali(key, "spawn_dynamic_wait_time")) g_fSpawnDynamicWaitTime = floatclamp(str_to_float(value), 0.0, 15.0);
		else if (equali(key, "spawn_dynamic_min_players"))
		{
			#if AMXX_VERSION_NUM < 183
			g_iMaxPlayers = get_maxplayers();
			g_iSpawnDynamicMinPlayers = clamp(str_to_num(value), 0, g_iMaxPlayers);
			#else
			g_iSpawnDynamicMinPlayers = clamp(str_to_num(value), 0, MaxClients);
			#endif
		}
		else if (equali(key, "spawn_dynamic_min_time")) g_fSpawnDynamicMinTime = floatclamp(str_to_float(value), g_fSpawnDynamicWaitTime + 0.1, 15.0);
		else if (equali(key, "spawn_dynamic_max_time")) g_fSpawnDynamicMaxTime = floatclamp(str_to_float(value), g_fSpawnDynamicMinTime + 0.1, 45.0);
	}
	else if (equali(section, "protection"))
	{
		if (equali(key, "holdtime")) g_fHoldTime = floatclamp(str_to_float(value), 0.0, 10.0);
		else if (equali(key, "roundend")) g_bRoundEndProtect = !!bool:str_to_num(value);
	}
	else if (equali(section, "colors"))
	{
		if (equali(key, "terrors"))
		{
			remove_quotes(value);
			
			new red[4], green[4], blue[4], alpha[4];
			parse(value, red, 3, green, 3, blue, 3, alpha, 3);
			
			g_iColorsTer[0] = clamp(str_to_num(red), 0, 255);
			g_iColorsTer[1] = clamp(str_to_num(green), 0, 255);
			g_iColorsTer[2] = clamp(str_to_num(blue), 0, 255);
			g_iColorsTer[3] = clamp(str_to_num(alpha), 0, 255);
		}
		else if (equali(key, "cts"))
		{
			remove_quotes(value);
			
			new red[4], green[4], blue[4], alpha[4];
			parse(value, red, 3, green, 3, blue, 3, alpha, 3);
			
			g_iColorsCT[0] = clamp(str_to_num(red), 0, 255);
			g_iColorsCT[1] = clamp(str_to_num(green), 0, 255);
			g_iColorsCT[2] = clamp(str_to_num(blue), 0, 255);
			g_iColorsCT[3] = clamp(str_to_num(alpha), 0, 255);
		}
		else if (equali(key, "ffa"))
		{
			remove_quotes(value);
			
			new red[4], green[4], blue[4], alpha[4];
			parse(value, red, 3, green, 3, blue, 3, alpha, 3);
			
			g_iColorsFFA[0] = clamp(str_to_num(red), 0, 255);
			g_iColorsFFA[1] = clamp(str_to_num(green), 0, 255);
			g_iColorsFFA[2] = clamp(str_to_num(blue), 0, 255);
			g_iColorsFFA[3] = clamp(str_to_num(alpha), 0, 255);
		}
	}
}

public plugin_cfg() <deactivated> {}
public plugin_cfg() <enabled>
{
	new index, SpawnModeName[32];
	for (index = 0; index < g_iSpawnModeCount; index++)
	{
		ArrayGetString(g_SpawnModeName, index, SpawnModeName, charsmax(SpawnModeName));
		if (equali(g_szSpawnMode, SpawnModeName))
		{
			g_iForwardID = ArrayGetCell(g_SpawnModeID, index);
			break;
		}
	}
	
	#if AMXX_VERSION_NUM < 183
	if (!g_iSpawnDynamicMinPlayers || g_iSpawnDynamicMinPlayers >= g_iMaxPlayers)
	#else
	if (!g_iSpawnDynamicMinPlayers || g_iSpawnDynamicMinPlayers >= MaxClients)
	#endif
	{
		for (index = 0; index < sizeof(g_fCachedWaitTimes); index++)
		{
			g_fCachedWaitTimes[index] = g_fSpawnWaitTime;
		}
	}
	else
	{
		for (index = 0; index < sizeof(g_fCachedWaitTimes); index++)
		{
			if (index > g_iSpawnDynamicMinPlayers)
			{
				#if AMXX_VERSION_NUM < 183
				g_fCachedWaitTimes[index] = g_fSpawnDynamicMinTime + ((g_fSpawnDynamicMaxTime - g_fSpawnDynamicMinTime) / (g_iMaxPlayers - g_iSpawnDynamicMinPlayers) * (index - g_iSpawnDynamicMinPlayers));
				#else
				g_fCachedWaitTimes[index] = g_fSpawnDynamicMinTime + ((g_fSpawnDynamicMaxTime - g_fSpawnDynamicMinTime) / (MaxClients - g_iSpawnDynamicMinPlayers) * (index - g_iSpawnDynamicMinPlayers));
				#endif
			}
			else if (index == g_iSpawnDynamicMinPlayers)
			{
				g_fCachedWaitTimes[index] = g_fSpawnDynamicMinTime;
			}
			else
			{
				g_fCachedWaitTimes[index] = g_fSpawnDynamicWaitTime;
			}
		}
	}
	
	// Cache FFA
	g_bIsFreeForAllEnabled = bool:DM_IsFreeForAllEnabled();
	
	new ConfigDir[48];
	get_configsdir(ConfigDir, charsmax(ConfigDir));
	
	// Execute additional config file (dm_spawn_additional.cfg)
	server_cmd("exec %s/deathmatch/dm_spawn_additional.cfg", ConfigDir);
	
	// Check and cache Team Semiclip
	g_bIsTeamSemiclip = bool:LibraryExists(LIBRARY_TSC, LibType_Library);
	if (g_bIsTeamSemiclip)
	{
		new iTscPluginID = is_plugin_loaded("cs_team_semiclip.amxx", true);
		if (iTscPluginID != -1)
		{
			new szIgnore[2], szStatus[12];
			get_plugin(iTscPluginID, szIgnore, 1, szIgnore, 1, szIgnore, 1, szIgnore, 1, szStatus, 11);
			
			if (equal(szStatus, "running"))
				return;
		}
		g_bIsTeamSemiclip = false;
	}
}

public plugin_end() <deactivated> {}
public plugin_end() <enabled>
{
	ArrayDestroy(g_SpawnModeName);
	ArrayDestroy(g_SpawnModeID);
}

/* --------------------------------------------------------------------------- */

public client_connect(id) <deactivated> {}
public client_connect(id) <enabled>
{
	del_bitsum(bs_IsConnected, id);
	del_bitsum(bs_IsAlive, id);
	del_bitsum(bs_IsBot, id);
	del_bitsum(bs_IsProtected, id);
}

public client_putinserver(id) <deactivated> {}
public client_putinserver(id) <enabled>
{
	add_bitsum(bs_IsConnected, id);
	
	if (!is_user_bot(id))
		return;
	
	add_bitsum(bs_IsBot, id);
	set_task(2.5, "RespawnPlayerTask", id+TASK_RESPAWN);
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
	del_bitsum(bs_IsProtected, id);
	
	remove_task(id+TASK_RESPAWN);
	remove_task(id+TASK_BARFIX);
	remove_task(id+TASK_PROTECTION);
}

/* --------------------------------------------------------------------------- */

public DM_OnCzBotHamRegisterable(id) <deactivated> {}
public DM_OnCzBotHamRegisterable(id) <enabled>
{
	RegisterHamFromEntity(Ham_Spawn, id, "fwd_PlayerSpawn_Pre", false);
	RegisterHamFromEntity(Ham_Spawn, id, "fwd_PlayerSpawn_Post", true);
	RegisterHamFromEntity(Ham_Killed, id, "fwd_PlayerKilled_Pre", false);
	RegisterHamFromEntity(Ham_Killed, id, "fwd_PlayerKilled_Post", true);
}

public fwd_PlayerSpawn_Pre(id)
{
	ExecuteForward(g_iFwdSpawnPre, g_iFwdDummyResult, id, g_bFreezeTime, g_bRoundEnd);
}

public fwd_PlayerSpawn_Post(id)
{
	if (!is_user_alive(id) || !g_iTeamID[id])
		return;
	
	remove_task(id+TASK_RESPAWN);
	remove_task(id+TASK_BARFIX);
	
	PrepareRespawn(id);
	RemoveProtection(id+TASK_PROTECTION);
	
	add_bitsum(bs_IsAlive, id);
	
	if (g_bEnabled && g_bSpawnRadioMsg && !g_bFreezeTime && !g_bRoundEnd && !get_bitsum(bs_IsBot, id))
	{
		if (g_iTeamID[id] == DM_TEAM_T) client_cmd(id, "spk radio/letsgo");
		else client_cmd(id, "spk radio/locknload");
	}
	
	ExecuteForward(g_iFwdSpawnPost, g_iFwdDummyResult, id, g_bFreezeTime, g_bRoundEnd);
	
	// Custom Spawn Plugin
	if (g_bEnabled && (g_iForwardID > 0))
	{
		ExecuteForward(g_iForwardID, g_iFwdDummyResult, id, g_bFreezeTime, g_bRoundEnd);
	}
	
	// Spawn Protection
	ExecuteForward(g_iFwdProtection, g_iFwdDummyResult, id, g_bFreezeTime, g_bRoundEnd);
	if (g_iFwdDummyResult >= PLUGIN_HANDLED)
		return;
	
	if (g_fHoldTime > 0.0)
	{
		set_pev(id, pev_takedamage, DAMAGE_NO);
		add_bitsum(bs_IsProtected, id);
		
		if (g_bIsFreeForAllEnabled)
		{
			if (g_bIsTeamSemiclip) tsc_set_user_rendering(id, 1, kRenderFxGlowShell, g_iColorsFFA[0], g_iColorsFFA[1], g_iColorsFFA[2], kRenderNormal, g_iColorsFFA[3]);
			fm_set_rendering(id, kRenderFxGlowShell, g_iColorsFFA[0], g_iColorsFFA[1], g_iColorsFFA[2], kRenderNormal, g_iColorsFFA[3]);
		}
		else
		{
			if (g_iTeamID[id] == DM_TEAM_T)
			{
				if (g_bIsTeamSemiclip) tsc_set_user_rendering(id, 1, kRenderFxGlowShell, g_iColorsTer[0], g_iColorsTer[1], g_iColorsTer[2], kRenderNormal, g_iColorsTer[3]);
				fm_set_rendering(id, kRenderFxGlowShell, g_iColorsTer[0], g_iColorsTer[1], g_iColorsTer[2], kRenderNormal, g_iColorsTer[3]);
			}
			else
			{
				if (g_bIsTeamSemiclip) tsc_set_user_rendering(id, 1, kRenderFxGlowShell, g_iColorsCT[0], g_iColorsCT[1], g_iColorsCT[2], kRenderNormal, g_iColorsCT[3]);
				fm_set_rendering(id, kRenderFxGlowShell, g_iColorsCT[0], g_iColorsCT[1], g_iColorsCT[2], kRenderNormal, g_iColorsCT[3]);
			}
		}
		
		if (g_bRoundEnd && g_bRoundEndProtect)
			return;
		
		set_task(g_fHoldTime, "RemoveProtection", id+TASK_PROTECTION);
	}
}

public fwd_PlayerKilled_Pre(victim, attacker, shouldgib)
{
	del_bitsum(bs_IsAlive, victim);
	
	ExecuteForward(g_iFwdKilledPre, g_iFwdDummyResult, victim, attacker);
	
	if (get_bitsum(bs_IsProtected, victim))
	{
		RemoveProtection(victim+TASK_PROTECTION);
	}
}

public fwd_PlayerKilled_Post(victim, attacker, shouldgib)
{
	ExecuteForward(g_iFwdKilledPost, g_iFwdDummyResult, victim, attacker);
	
	RespawnPlayer(victim);
}

public fwd_CmdStart(id, uc_handle, seed)
{
	if (g_bRoundEnd || g_bFreezeTime || !get_bitsum(bs_IsAlive, id) || !get_bitsum(bs_IsProtected, id))
		return FMRES_IGNORED;
	
	static buttons; buttons = get_uc(uc_handle, UC_Buttons);
	
	if (buttons & IN_ATTACK || buttons & IN_ATTACK2)
	{
		RemoveProtection(id+TASK_PROTECTION);
		ExecuteForward(g_iFwdProtectionEnds, g_iFwdDummyResult, id);
	}
	
	return FMRES_IGNORED;
}

/* --------------------------------------------------------------------------- */

public EventRoundStart()
{
	g_bFreezeTime = true;
	g_bRoundEnd = false;
}

public EventRoundEnd()
{
	g_bRoundEnd = true;
	
	static id;
	#if AMXX_VERSION_NUM < 183
	for (id = 1; id <= g_iMaxPlayers; id++)
	#else
	for (id = 1; id <= MaxClients; id++)
	#endif
	{
		if (!get_bitsum(bs_IsConnected, id))
			continue;
		
		if (!get_bitsum(bs_IsAlive, id))
		{
			PrepareRespawn(id);
			remove_task(id+TASK_RESPAWN);
		}
	}
	
	if (!g_bRoundEndProtect)
		return;
	
	#if AMXX_VERSION_NUM < 183
	for (id = 1; id <= g_iMaxPlayers; id++)
	#else
	for (id = 1; id <= MaxClients; id++)
	#endif
	{
		if (!get_bitsum(bs_IsConnected, id))
			continue;
		
		remove_task(id+TASK_PROTECTION);
		
		set_pev(id, pev_takedamage, DAMAGE_NO);
		add_bitsum(bs_IsProtected, id);
		
		if (g_bIsFreeForAllEnabled)
		{
			if (g_bIsTeamSemiclip) tsc_set_user_rendering(id, 1, kRenderFxGlowShell, g_iColorsFFA[0], g_iColorsFFA[1], g_iColorsFFA[2], kRenderNormal, g_iColorsFFA[3]);
			fm_set_rendering(id, kRenderFxGlowShell, g_iColorsFFA[0], g_iColorsFFA[1], g_iColorsFFA[2], kRenderNormal, g_iColorsFFA[3]);
		}
		else
		{
			if (g_iTeamID[id] == DM_TEAM_T)
			{
				if (g_bIsTeamSemiclip) tsc_set_user_rendering(id, 1, kRenderFxGlowShell, g_iColorsTer[0], g_iColorsTer[1], g_iColorsTer[2], kRenderNormal, g_iColorsTer[3]);
				fm_set_rendering(id, kRenderFxGlowShell, g_iColorsTer[0], g_iColorsTer[1], g_iColorsTer[2], kRenderNormal, g_iColorsTer[3]);
			}
			else
			{
				if (g_bIsTeamSemiclip) tsc_set_user_rendering(id, 1, kRenderFxGlowShell, g_iColorsCT[0], g_iColorsCT[1], g_iColorsCT[2], kRenderNormal, g_iColorsCT[3]);
				fm_set_rendering(id, kRenderFxGlowShell, g_iColorsCT[0], g_iColorsCT[1], g_iColorsCT[2], kRenderNormal, g_iColorsCT[3]);
			}
		}
	}
}

public LogEventRoundStart()
{
	g_bFreezeTime = false;
}

/* --------------------------------------------------------------------------- */

public ClientCmdRespawn(id)
{
	if (get_bitsum(bs_IsAlive, id) || g_iTeamID[id] == DM_TEAM_UNASSIGNED || g_iTeamID[id] == DM_TEAM_SPECTATOR)
		return;
	
	RespawnPlayer(id);
}

public ClientCmdJoinclass(id)
{
	RespawnPlayer(id);
}

public ClientCmdMenuSelect(id)
{
	if (cs_get_user_menu(id) == MENU_JOINCLASS)
	{
		RespawnPlayer(id);
	}
}

/* --------------------------------------------------------------------------- */

PrepareRespawn(id)
{
	// Enable?
	if (!g_bEnabled || get_bitsum(bs_IsBot, id))
		return;
	
	remove_task(id+TASK_BARFIX);
	if (task_exists(id+TASK_RESPAWN) && g_bSpawnWaitBar)
	{
		message_begin(MSG_ONE_UNRELIABLE, g_iMsgBarTime2, _, id);
		write_short(0);
		write_short(0);
		message_end();
	}
}

ShowRespawnBar(id, const Float:timer)
{
	if (g_bSpawnWaitBar && !get_bitsum(bs_IsBot, id))
	{
		static iRoundedSeconds, iStartPercent;
		iRoundedSeconds = floatround(timer, floatround_ceil);
		iStartPercent = floatround((1.0-(timer / iRoundedSeconds))*100);
		
		message_begin(MSG_ONE_UNRELIABLE, g_iMsgBarTime2, _, id);
		write_short(iRoundedSeconds);
		write_short(iStartPercent);
		message_end();
	}
}

public RespawnBarFix(const szArgs[], taskid)
{
	if (g_bSpawnWaitBar)
	{
		if (!get_bitsum(bs_IsConnected, ID_BARFIX) || get_bitsum(bs_IsAlive, ID_BARFIX) || g_iTeamID[ID_BARFIX] == DM_TEAM_UNASSIGNED || g_iTeamID[ID_BARFIX] == DM_TEAM_SPECTATOR)
			return;
		
		static Float:flTimer, iRoundedSeconds, iStartPercent;
		flTimer = szArgs[Tricky];
		iRoundedSeconds = floatround(flTimer, floatround_ceil);
		iStartPercent = floatround((1.0-(flTimer / iRoundedSeconds))*100);
		
		message_begin(MSG_ONE_UNRELIABLE, g_iMsgBarTime2, _, ID_BARFIX);
		write_short(iRoundedSeconds);
		write_short(iStartPercent);
		message_end();
	}
}

RespawnPlayer(id)
{
	remove_task(id+TASK_RESPAWN);
	remove_task(id+TASK_BARFIX);
	
	// Enable?
	if (!g_bEnabled || g_bRoundEnd)
		return false;
	
	// Respawn attempt?
	ExecuteForward(g_iFwdRespawnAttempt, g_iFwdDummyResult, id);
	if (g_iFwdDummyResult >= PLUGIN_HANDLED)
		return false;
	
	static iCurPlayers; iCurPlayers = GetPlayingPlayers();
	if (g_fCachedWaitTimes[iCurPlayers] >= 0.5)
	{
		ShowRespawnBar(id, g_fCachedWaitTimes[iCurPlayers]);
		set_task(g_fCachedWaitTimes[iCurPlayers], "RespawnPlayerTask", id+TASK_RESPAWN);
		
		if (g_bSpawnWaitBarFix && !get_bitsum(bs_IsBot, id))
		{
			static szArgs[TaskData], Float:flNewTimer;
			flNewTimer = g_fCachedWaitTimes[iCurPlayers] - 0.3;
			szArgs[Tricky] = _:flNewTimer;
			
			set_task(0.25, "RespawnBarFix", id+TASK_BARFIX, szArgs, TaskData);
		}
	}
	else if (g_fCachedWaitTimes[iCurPlayers] < 0.1)
	{
		set_pev(id, pev_deadflag, DEAD_RESPAWNABLE);
		if (get_bitsum(bs_IsBot, id)) dllfunc(DLLFunc_Spawn, id);
	}
	else
	{
		set_task(g_fCachedWaitTimes[iCurPlayers], "RespawnPlayerTask", id+TASK_RESPAWN);
	}
	
	return true;
}

public RespawnPlayerTask(taskid)
{
	if (!get_bitsum(bs_IsConnected, ID_RESPAWN) || get_bitsum(bs_IsAlive, ID_RESPAWN) || g_iTeamID[ID_RESPAWN] == DM_TEAM_UNASSIGNED || g_iTeamID[ID_RESPAWN] == DM_TEAM_SPECTATOR)
		return;
	
	//set_pev(ID_RESPAWN, pev_deadflag, DEAD_RESPAWNABLE);
	//set_pev(ID_RESPAWN, pev_health, 1.0);
	ExecuteHamB(Ham_CS_RoundRespawn, ID_RESPAWN);
}

GetPlayingPlayers()
{
	new iPlayers;
	
	#if AMXX_VERSION_NUM < 183
	for (new id = 1; id <= g_iMaxPlayers; id++)
	#else
	for (new id = 1; id <= MaxClients; id++)
	#endif
	{
		if (!get_bitsum(bs_IsConnected, id) || g_iTeamID[id] == DM_TEAM_UNASSIGNED || g_iTeamID[id] == DM_TEAM_SPECTATOR)
			continue;
		
		iPlayers++;
	}
	return iPlayers;
}

public RemoveProtection(taskid)
{
	if (!get_bitsum(bs_IsConnected, ID_PROTECTION))
		return;
	
	remove_task(taskid);
	
	if (g_bIsTeamSemiclip) tsc_set_user_rendering(ID_PROTECTION);
	fm_set_rendering(ID_PROTECTION, kRenderFxNone, 0, 0, 0, kRenderNormal, 0);
	set_pev(ID_PROTECTION, pev_takedamage, DAMAGE_AIM);
	del_bitsum(bs_IsProtected, ID_PROTECTION);
}

/* --------------------------------------------------------------------------- */

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
	
	PrepareRespawn(id);
}

/* -Native-------------------------------------------------------------------- */

/* native DM_RegisterSpawnMode(const modename[], const callback[]); */
public native_register_mode(plugin_id, num_params) <deactivated> return 0;
public native_register_mode(plugin_id, num_params) <enabled>
{
	new SpawnMode[32];
	get_string(1, SpawnMode, charsmax(SpawnMode));
	
	if (strlen(SpawnMode) < 1)
	{
		DM_Log(LOG_ERROR, "Can't register spawn mode with an empty name.");
		DM_LogPlugin(LOG_ERROR, plugin_id, "DM_RegisterSpawnMode", 1);
		return 0;
	}
	
	new index, SpawnModeName[32];
	for (index = 0; index < g_iSpawnModeCount; index++)
	{
		ArrayGetString(g_SpawnModeName, index, SpawnModeName, charsmax(SpawnModeName));
		if (equali(SpawnMode, SpawnModeName))
		{
			DM_Log(LOG_ERROR, "Spawn mode already registered (%s).", SpawnMode);
			DM_LogPlugin(LOG_ERROR, plugin_id, "DM_RegisterSpawnMode", 2);
			return 0;
		}
	}
	
	new PluginCallback[64], ForwardID;
	get_string(2, PluginCallback, charsmax(PluginCallback));
	ForwardID = CreateOneForward(plugin_id, PluginCallback, FP_CELL, FP_CELL, FP_CELL);
	
	if (ForwardID <= 0)
	{
		DM_Log(LOG_ERROR, "Can't create %s forward.", PluginCallback);
		DM_LogPlugin(LOG_ERROR, plugin_id, "DM_RegisterSpawnMode", 3);
		return 0;
	}
	
	ArrayPushString(g_SpawnModeName, SpawnMode);
	ArrayPushCell(g_SpawnModeID, ForwardID);
	g_iSpawnModeCount++;
	
	return 1;
}

/* --------------------------------------------------------------------------- */

stock get_configsdir(name[], len)
{
	return get_localinfo("amxx_configsdir", name, len);
}

stock cs_get_user_menu(id)
{
	if (pev_valid(id) != FM_PDATA_SAFE)
		return 0;
	
	return get_pdata_int(id, OFFSET_MENUCODE);
}

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
