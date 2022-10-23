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

#include <dm_core>
#include <dm_bomb>
#include <dm_spawn>
#include <dm_log>

/* --------------------------------------------------------------------------- */

new bool:g_bFreezeTime = false;
new bool:g_bRoundEnd = false;
new bool:g_bVipEscaped = false;
new bool:g_bIntermission = false;

new g_iCarrier = 0;
new g_iPlanting = 0;
new g_iPlanter = 0;
new g_iDefuser = 0;
new g_iVip = 0;
new g_iVipKiller = 0;

new bs_IsAlive = 0;

enum
{
	FWD_INTERMISSION = 0,
	FWD_CTS_WIN,
	FWD_TERRORISTS_WIN,
	FWD_ROUND_DRAW,
	FWD_BOMB_SPAWNED,
	FWD_BOMB_PICKUP,
	FWD_BOMB_DROPPED,
	FWD_BOMB_PLANTED,
	FWD_BOMB_DEFUSED,
	FWD_TARGET_BOMBED,
	FWD_TARGET_SAVED,
	FWD_BECAME_VIP,
	FWD_VIP_ASSASSINATED,
	FWD_VIP_ESCAPED,
	FWD_VIP_NOT_ESCAPED,
	FWD_HOSTAGE_TOUCHED,
	FWD_HOSTAGE_RESCUED,
	FWD_HOSTAGE_KILLED,
	FWD_HOSTAGES_ALL_RESCUED,
	FWD_HOSTAGES_NOT_RESCUED,
	MAX_FORWARDS
}
new g_iFwdDummyResult = 0;
new g_iForwards[MAX_FORWARDS] = { 0, ... };

#define get_bitsum(%1,%2)   (%1 &   (1<<((%2-1)&31)))
#define add_bitsum(%1,%2)    %1 |=  (1<<((%2-1)&31))
#define del_bitsum(%1,%2)    %1 &= ~(1<<((%2-1)&31))

#if AMXX_VERSION_NUM < 183
new g_iMaxPlayers = 0;
#define is_user_valid(%1) (1 <= %1 <= g_iMaxPlayers)
#else
#define is_user_valid(%1) (1 <= %1 <= MaxClients)
#endif

/* --------------------------------------------------------------------------- */

public plugin_natives()
{
	register_native("DM_UserIsCarrierBomb", "native_is_carrier");
	register_native("DM_UserIsPlanting", "native_is_planting");
	register_native("DM_UserIsDefusing", "native_is_defusing");
	register_library("dm_scenarios");
}

public DM_OnModStatus(status)
{
	register_plugin("DM: Scenarios", DM_VERSION_STR_LONG, "schmurgel1983");
	
	if (status) state enabled;
	else state deactivated;
}

public DM_OnMapConditions(bomb, vip, hosnum, hosid[]) <deactivated> {}
public DM_OnMapConditions(bomb, vip, hosnum, hosid[]) <enabled>
{
	if (bomb)
	{
		g_iForwards[FWD_BOMB_SPAWNED] = CreateMultiForward("DM_BombSpawned", ET_IGNORE, FP_CELL);
		g_iForwards[FWD_BOMB_PICKUP] = CreateMultiForward("DM_BombPickup", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL);
		g_iForwards[FWD_BOMB_DROPPED] = CreateMultiForward("DM_BombDropped", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL);
		g_iForwards[FWD_BOMB_PLANTED] = CreateMultiForward("DM_BombPlanted", ET_IGNORE, FP_CELL, FP_CELL);
		g_iForwards[FWD_BOMB_DEFUSED] = CreateMultiForward("DM_BombDefused", ET_IGNORE, FP_CELL);
		g_iForwards[FWD_TARGET_BOMBED] = CreateMultiForward("DM_TargetBombed", ET_IGNORE, FP_CELL, FP_CELL);
		g_iForwards[FWD_TARGET_SAVED] = CreateMultiForward("DM_TargetSaved", ET_IGNORE);
		
		register_logevent("EventBombSpawned", 3, "1=triggered", "2=Spawned_With_The_Bomb");
		register_logevent("EventBombPickup", 3, "1=triggered", "2=Got_The_Bomb");
		register_logevent("EventBombDropped", 3, "1=triggered", "2=Dropped_The_Bomb");
		register_logevent("EventBombPlanted", 3, "1=triggered", "2=Planted_The_Bomb");
		register_logevent("EventBombDefused", 6, "1=CT", "2=triggered", "3=Bomb_Defused");
		register_logevent("EventTargetBombed", 6, "1=TERRORIST", "2=triggered", "3=Target_Bombed");
		register_logevent("EventTargetSaved", 6, "1=CT", "2=triggered", "3=Target_Saved");
		
		register_event("BarTime", "EventBarTime", "be");
	}
	
	if (vip)
	{
		g_iForwards[FWD_BECAME_VIP] = CreateMultiForward("DM_BecameVip", ET_IGNORE, FP_CELL);
		g_iForwards[FWD_VIP_ASSASSINATED] = CreateMultiForward("DM_VipAssassinated", ET_IGNORE, FP_CELL, FP_CELL);
		g_iForwards[FWD_VIP_ESCAPED] = CreateMultiForward("DM_VipEscaped", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL);
		g_iForwards[FWD_VIP_NOT_ESCAPED] = CreateMultiForward("DM_VipNotEscaped", ET_IGNORE, FP_CELL);
		
		register_logevent("EventBecameVip", 3, "1=triggered", "2=Became_VIP");
		register_logevent("EventVipAssassinated", 6, "1=TERRORIST", "2=triggered", "3=VIP_Assassinated");
		register_logevent("EventVipEscaped", 3, "1=triggered", "2=Escaped_As_VIP");
		register_logevent("EventVipNotEscaped", 6, "1=TERRORIST", "2=triggered", "3=VIP_Not_Escaped");
	}
	
	if (hosnum)
	{
		g_iForwards[FWD_HOSTAGE_TOUCHED] = CreateMultiForward("DM_HostageTouched", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL);
		g_iForwards[FWD_HOSTAGE_RESCUED] = CreateMultiForward("DM_HostageRescued", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL);
		g_iForwards[FWD_HOSTAGE_KILLED] = CreateMultiForward("DM_HostageKilled", ET_IGNORE, FP_CELL, FP_CELL);
		g_iForwards[FWD_HOSTAGES_ALL_RESCUED] = CreateMultiForward("DM_HostagesAllRescued", ET_IGNORE, FP_CELL, FP_CELL);
		g_iForwards[FWD_HOSTAGES_NOT_RESCUED] = CreateMultiForward("DM_HostagesNotRescued", ET_IGNORE);
		
		register_event("SendAudio", "EventHostageRescuedAlone", "a", "2&%!MRAD_escaped");
		register_logevent("EventHostageTouched", 3, "1=triggered", "2=Touched_A_Hostage");
		register_logevent("EventHostageRescued", 3, "1=triggered", "2=Rescued_A_Hostage");
		register_logevent("EventHostageKilled", 3, "1=triggered", "2=Killed_A_Hostage");
		register_logevent("EventHostagesAllRescued", 6, "1=CT", "2=triggered", "3=All_Hostages_Rescued");
		register_logevent("EventHostagesNotRescued", 6, "1=TERRORIST", "2=triggered", "3=Hostages_Not_Rescued");
	}
}

/*	[SendAudio] msg_id 100, msg_dest 0 MSG_BROADCAST, msg_entity 0
	[SendAudio] 1 ARG_BYTE 0
	[SendAudio] 2 ARG_STRING "%!MRAD_escaped"
	[SendAudio] 3 ARG_SHORT 100
*/

public plugin_init() <deactivated> {}
public plugin_init() <enabled>
{
	register_event("HLTV", "EventRoundStart", "a", "1=0", "2=0");
	register_logevent("LogEventRoundStart", 2, "1=Round_Start");
	register_event("30", "EventIntermission", "a");
	
	g_iForwards[FWD_INTERMISSION] = CreateMultiForward("DM_OnIntermission", ET_IGNORE);
	g_iForwards[FWD_CTS_WIN] = CreateMultiForward("DM_CTsWin", ET_IGNORE);
	g_iForwards[FWD_TERRORISTS_WIN] = CreateMultiForward("DM_TerroristsWin", ET_IGNORE);
	g_iForwards[FWD_ROUND_DRAW] = CreateMultiForward("DM_RoundDraw", ET_IGNORE);
	
	register_logevent("EventCTsWin", 6, "1=CT", "2=triggered", "3=CTs_Win");
	register_logevent("EventTerroristsWin", 6, "1=TERRORIST", "2=triggered", "3=Terrorists_Win");
	register_logevent("EventRoundDraw", 2, "1=Round_Draw");
	
	#if AMXX_VERSION_NUM < 183
	g_iMaxPlayers = get_maxplayers();
	#endif
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
	
	if (g_iPlanting == id)
	{
		remove_task(id);
		g_iPlanting = 0;
	}
	else if (g_iPlanter == id)
	{
		g_iPlanter = 0;
	}
	else if (g_iDefuser == id)
	{
		remove_task(id);
		g_iDefuser = 0;
	}
	else if (g_iVip == id)
	{
		g_iVip = 0;
	}
}

/* --------------------------------------------------------------------------- */

public EventRoundStart()
{
	g_bFreezeTime = true;
	g_bRoundEnd = false;
	g_bVipEscaped = false;
	
	g_iCarrier = 0;
	g_iPlanter = 0;
	g_iDefuser = 0;
}

public LogEventRoundStart()
{
	g_bFreezeTime = false;
}

public EventIntermission()
{
	g_bIntermission = true;
	ExecuteForward(g_iForwards[FWD_INTERMISSION], g_iFwdDummyResult);
}

/* --------------------------------------------------------------------------- */

public DM_PlayerSpawn_Pre(id, freezetime, roundend) <deactivated> {}
public DM_PlayerSpawn_Pre(id, freezetime, roundend) <enabled>
{
	if (id == g_iCarrier)
		g_iCarrier = 0;
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
	
	// DM_VipAssassinated
	if (is_user_valid(attacker) && victim == g_iVip)
	{
		// killed by player or self
		g_iVipKiller = attacker;
	}
	else if (!is_user_valid(attacker) && victim == g_iVip)
	{
		// killed by non-player
		g_iVipKiller = 0;
	}
}

/* --------------------------------------------------------------------------- */

public EventCTsWin()
{
	if (g_bIntermission) return;
	
	g_bRoundEnd = true;
	ExecuteForward(g_iForwards[FWD_CTS_WIN], g_iFwdDummyResult);
}

public EventTerroristsWin()
{
	if (g_bIntermission) return;
	
	g_bRoundEnd = true;
	ExecuteForward(g_iForwards[FWD_TERRORISTS_WIN], g_iFwdDummyResult);
}

public EventRoundDraw()
{
	if (g_bIntermission) return;
	
	g_bRoundEnd = true;
	ExecuteForward(g_iForwards[FWD_ROUND_DRAW], g_iFwdDummyResult);
}

/* --------------------------------------------------------------------------- */

public EventBombSpawned()
{
	if (g_bIntermission) return;
	
	g_iCarrier = get_loguser_id();
	ExecuteForward(g_iForwards[FWD_BOMB_SPAWNED], g_iFwdDummyResult, g_iCarrier);
}

public EventBombPickup()
{
	if (g_bIntermission) return;
	
	g_iCarrier = get_loguser_id();
	ExecuteForward(g_iForwards[FWD_BOMB_PICKUP], g_iFwdDummyResult, g_iCarrier, g_bFreezeTime, g_bRoundEnd);
}

public EventBombDropped()
{
	if (g_bIntermission) return;
	
	ExecuteForward(g_iForwards[FWD_BOMB_DROPPED], g_iFwdDummyResult, g_iCarrier, g_bFreezeTime, g_bRoundEnd);
	
	if (get_bitsum(bs_IsAlive, g_iCarrier))
		g_iCarrier = 0;
}

public EventBombPlanted()
{
	if (g_bIntermission) return;
	
	g_iCarrier = 0;
	ExecuteForward(g_iForwards[FWD_BOMB_PLANTED], g_iFwdDummyResult, g_iPlanter, g_bRoundEnd);
	
	remove_task(g_iPlanting);
	g_iPlanting = 0;
}

public EventBombDefused()
{
	if (g_bIntermission) return;
	
	g_bRoundEnd = true;
	ExecuteForward(g_iForwards[FWD_BOMB_DEFUSED], g_iFwdDummyResult, g_iDefuser);
	
	remove_task(g_iDefuser);
	g_iDefuser = 0;
}

public EventTargetBombed()
{
	if (g_bIntermission) return;
	
	g_bRoundEnd = true;
	ExecuteForward(g_iForwards[FWD_TARGET_BOMBED], g_iFwdDummyResult, g_iPlanter, g_iDefuser);
}

public EventTargetSaved()
{
	if (g_bIntermission) return;
	
	g_bRoundEnd = true;
	ExecuteForward(g_iForwards[FWD_TARGET_SAVED], g_iFwdDummyResult);
}

public EventBarTime(id)
{
	new iTimer;
	if (LibraryExists("dm_bomb", LibType_Library))
	{
		iTimer = DM_GetDefuseTime();
		if (!iTimer) iTimer = read_data(1);
	}
	else iTimer = read_data(1);
	
	switch (iTimer)
	{
		/*case 3: // Planting
		{
			g_iPlanter = id;
			g_iPlanting = id;
			
			remove_task(id);
			set_task(0.2 + float(iTimer), "RemovePlanting", id);
		}
		case 5, 10: // Defusing
		{
			g_iDefuser = id;
			
			remove_task(id);
			set_task(0.2 + float(iTimer), "RemoveDefusing", id);
		}*/
		case 1..30: // Planting/Defusing
		{
			// Terror
			if (pev(id, pev_weapons) & (1<<CSW_C4))
			{
				g_iPlanter = id;
				g_iPlanting = id;
				
				remove_task(id);
				set_task(0.2 + float(iTimer), "RemovePlanting", id);
			}
			// CT
			else
			{
				g_iDefuser = id;
				
				remove_task(id);
				set_task(0.2 + float(iTimer), "RemoveDefusing", id);
			}
		}
		default: // Stop Planting/Defusing
		{
			if (g_iDefuser == id) g_iDefuser = 0;
			else g_iPlanting = 0;
			remove_task(id);
		}
	}
}

public RemovePlanting(id)
{
	if (g_iPlanting == id)
		g_iPlanting = 0;
}

public RemoveDefusing(id)
{
	if (g_iDefuser == id)
		g_iDefuser = 0;
}

/* --------------------------------------------------------------------------- */

public EventBecameVip()
{
	if (g_bIntermission) return;
	
	g_iVip = get_loguser_id();
	ExecuteForward(g_iForwards[FWD_BECAME_VIP], g_iFwdDummyResult, g_iVip);
}

public EventVipAssassinated()
{
	if (g_bIntermission) return;
	
	g_bRoundEnd = true;
	ExecuteForward(g_iForwards[FWD_VIP_ASSASSINATED], g_iFwdDummyResult, g_iVipKiller, g_iVip);
}

public EventVipEscaped()
{
	if (g_bVipEscaped || g_bIntermission)
		return;
	
	g_bVipEscaped = true;
	ExecuteForward(g_iForwards[FWD_VIP_ESCAPED], g_iFwdDummyResult, g_iVip, g_bFreezeTime, g_bRoundEnd);
	g_bRoundEnd = true;
}

public EventVipNotEscaped()
{
	if (g_bIntermission) return;
	
	g_bRoundEnd = true;
	ExecuteForward(g_iForwards[FWD_VIP_NOT_ESCAPED], g_iFwdDummyResult, g_iVip);
}

/* --------------------------------------------------------------------------- */

public EventHostageTouched()
{
	if (g_bIntermission) return;
	
	ExecuteForward(g_iForwards[FWD_HOSTAGE_TOUCHED], g_iFwdDummyResult, get_loguser_id(), g_bFreezeTime, g_bRoundEnd);
}

public EventHostageRescuedAlone()
{
	if (g_bIntermission) return;
	
	ExecuteForward(g_iForwards[FWD_HOSTAGE_RESCUED], g_iFwdDummyResult, 0, g_bFreezeTime, g_bRoundEnd);
}

public EventHostageRescued()
{
	if (g_bIntermission) return;
	
	ExecuteForward(g_iForwards[FWD_HOSTAGE_RESCUED], g_iFwdDummyResult, get_loguser_id(), g_bFreezeTime, g_bRoundEnd);
}

public EventHostageKilled()
{
	if (g_bIntermission) return;
	
	ExecuteForward(g_iForwards[FWD_HOSTAGE_KILLED], g_iFwdDummyResult, get_loguser_id(), g_bRoundEnd);
}

public EventHostagesAllRescued()
{
	if (g_bIntermission) return;
	
	ExecuteForward(g_iForwards[FWD_HOSTAGES_ALL_RESCUED], g_iFwdDummyResult, g_bFreezeTime, g_bRoundEnd);
	g_bRoundEnd = true;
}

public EventHostagesNotRescued()
{
	if (g_bIntermission) return;
	
	g_bRoundEnd = true;
	ExecuteForward(g_iForwards[FWD_HOSTAGES_NOT_RESCUED], g_iFwdDummyResult);
}

/* --------------------------------------------------------------------------- */

/* native DM_UserIsCarrierBomb(const id); */
public native_is_carrier(plugin_id, num_params) <deactivated> return 0;
public native_is_carrier(plugin_id, num_params) <enabled>
{
	new id = get_param(1);
	
	if (!is_user_valid(id) || !is_user_connected(id))
	{
		DM_Log(LOG_INFO, "Invalid player (%d)", id);
		DM_LogPlugin(LOG_INFO, plugin_id, "DM_UserIsCarrierBomb", 1);
		return 0;
	}
	
	return (g_iCarrier == id) ? 1 : 0;
}

/* native DM_UserIsPlanting(const id); */
public native_is_planting(plugin_id, num_params) <deactivated> return 0;
public native_is_planting(plugin_id, num_params) <enabled>
{
	new id = get_param(1);
	
	if (!is_user_valid(id) || !is_user_connected(id))
	{
		DM_Log(LOG_INFO, "Invalid player (%d)", id);
		DM_LogPlugin(LOG_INFO, plugin_id, "DM_UserIsPlanting", 2);
		return 0;
	}
	
	return (g_iPlanting == id) ? 1 : 0;
}

/* native DM_UserIsDefusing(const id); */
public native_is_defusing(plugin_id, num_params) <deactivated> return 0;
public native_is_defusing(plugin_id, num_params) <enabled>
{
	new id = get_param(1);
	
	if (!is_user_valid(id) || !is_user_connected(id))
	{
		DM_Log(LOG_INFO, "Invalid player (%d)", id);
		DM_LogPlugin(LOG_INFO, plugin_id, "DM_UserIsDefusing", 3);
		return 0;
	}
	
	return (g_iDefuser == id) ? 1 : 0;
}

/* --------------------------------------------------------------------------- */

stock get_loguser_id()
{
	static loguser[80], name[32];
	read_logargv(0, loguser, 79);
	parse_loguser(loguser, name, 31);
	
	return get_user_index(name);
}
