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
//#pragma dynamic 32768 // 128kb

#include <amxmodx>
#include <fakemeta>

#include <dm_core>
#include <dm_ffa>
#include <dm_spawn>
#define LIBRARY_SCENARIOS "dm_scenarios"
#include <dm_scenarios>
#include <dm_colorchat>
#include <dm_log>

/* --------------------------------------------------------------------------- */

const MAX_MONEY = 999999;

/* --------------------------------------------------------------------------- */

new bool:g_bScenarios = false;
new bool:g_bBombScenario = false;
new g_iFreeForAllEnabled = 0;

new g_iMsgMoney = 0;
new bool:g_bRoundEnd = false;
new bool:g_bIntermission = false;
new bool:g_bHostageNotRescued = false;
new g_iHostageNotRescued = 0;
new g_iHostageNum = 0;

new g_iStartMoney = 0;
new g_iMaxMoney = 0;
new g_iFlashMoney = 0;

new bool:g_bRewardAnnounce = false;
new g_iRewardKillPlayer = 0;
new g_iRewardKillPlanter = 0;
new g_iRewardKillCarrier = 0;
new g_iRewardKillDefuser = 0;
new g_iRewardCTsWin = 0;
new g_iRewardTerrorsWin = 0;
new g_iRewardBombPlanted = 0;
new g_iRewardBombDefused = 0;
new g_iRewardBombDefusedTeam = 0;
new g_iRewardTargetBombed = 0;
new g_iRewardTargetSaved = 0;
new g_iRewardVipAssassinated = 0;
new g_iRewardVipAssassinatedTeam = 0;
new g_iRewardVipEscaped = 0;
new g_iRewardVipEscapedTeam = 0;
new g_iRewardVipNotEscaped = 0;
new g_iRewardHostageTouched = 0;
new g_iRewardHostageRescued = 0;
new g_iRewardHostageRescuedTeam = 0;
new g_iRewardHostageKilled = 0;
new g_iRewardHostagesNotRescued = 0;

new g_iTeamID[DM_MAX_PLAYERS+1] = { 0, ... };
new g_iMoney[DM_MAX_PLAYERS+1] = { 0, ... };

const FM_PDATA_SAFE = 2;
const OFFSET_MONEY = 115;

new bs_IsConnected = 0;
new bs_IsAlive = 0;
new bs_IsBot = 0;

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
	register_native("DM_GetStartMoney", "native_get_start_money");
	register_native("DM_GetUserMoney", "native_get_user_money");
	register_native("DM_SetUserMoney", "native_set_user_money");
	register_library("dm_rewards");
}

public DM_OnModStatus(status)
{
	register_plugin("DM: Rewards", DM_VERSION_STR_LONG, "schmurgel1983");
	
	if (status) state enabled;
	else state deactivated;
}

public plugin_precache() <deactivated> {}
public plugin_precache() <enabled>
{
	if (!DM_LoadConfiguration("dm_rewards.cfg", "DM_ReadRewards"))
	{
		state deactivated;
		return;
	}
}

public DM_ReadRewards(section[], key[], value[])
{
	if (equali(section, "rewards"))
	{
		if (equali(key, "start_money")) g_iStartMoney = clamp(str_to_num(value), 0, MAX_MONEY);
		else if (equali(key, "max_money")) g_iMaxMoney = clamp(str_to_num(value), 0, MAX_MONEY);
		else if (equali(key, "flash_money")) g_iFlashMoney = !!str_to_num(value);
		else if (equali(key, "reward_announce")) g_bRewardAnnounce = !!bool:str_to_num(value);
		else if (equali(key, "kill_player")) g_iRewardKillPlayer = str_to_num(value);
		else if (equali(key, "kill_planter")) g_iRewardKillPlanter = str_to_num(value);
		else if (equali(key, "kill_carrier")) g_iRewardKillCarrier = str_to_num(value);
		else if (equali(key, "kill_defuser")) g_iRewardKillDefuser = str_to_num(value);
		else if (equali(key, "cts_win")) g_iRewardCTsWin = str_to_num(value);
		else if (equali(key, "terrors_win")) g_iRewardTerrorsWin = str_to_num(value);
		else if (equali(key, "bomb_planted")) g_iRewardBombPlanted = str_to_num(value);
		else if (equali(key, "bomb_defused")) g_iRewardBombDefused = str_to_num(value);
		else if (equali(key, "bomb_defused_team")) g_iRewardBombDefusedTeam = str_to_num(value);
		else if (equali(key, "target_bombed")) g_iRewardTargetBombed = str_to_num(value);
		else if (equali(key, "target_saved")) g_iRewardTargetSaved = str_to_num(value);
		else if (equali(key, "vip_assassinated")) g_iRewardVipAssassinated = str_to_num(value);
		else if (equali(key, "vip_assassinated_team")) g_iRewardVipAssassinatedTeam = str_to_num(value);
		else if (equali(key, "vip_escaped")) g_iRewardVipEscaped = str_to_num(value);
		else if (equali(key, "vip_escaped_team")) g_iRewardVipEscapedTeam = str_to_num(value);
		else if (equali(key, "vip_not_escaped")) g_iRewardVipNotEscaped = str_to_num(value);
		else if (equali(key, "hostage_touched")) g_iRewardHostageTouched = str_to_num(value);
		else if (equali(key, "hostage_rescued")) g_iRewardHostageRescued = str_to_num(value);
		else if (equali(key, "hostage_rescued_team")) g_iRewardHostageRescuedTeam = str_to_num(value);
		else if (equali(key, "hostage_killed")) g_iRewardHostageKilled = str_to_num(value);
		else if (equali(key, "hostages_not_rescued")) g_iRewardHostagesNotRescued = str_to_num(value);
	}
}

public DM_OnMapConditions(bomb, vip, hosnum, hosid[]) <deactivated> {}
public DM_OnMapConditions(bomb, vip, hosnum, hosid[]) <enabled>
{
	g_bBombScenario = bool:bomb;
	g_iHostageNotRescued = g_iHostageNum = hosnum;
}

public plugin_init() <deactivated> {}
public plugin_init() <enabled>
{
	if (LibraryExists(LIBRARY_SCENARIOS, LibType_Library))
		g_bScenarios = true;
	
	#if AMXX_VERSION_NUM < 183
	register_dictionary_colored("dm_rewards.txt");
	#else
	register_dictionary("dm_rewards.txt");
	#endif
	
	register_event("HLTV", "EventRoundStart", "a", "1=0", "2=0");
	register_event("TextMsg", "EventRoundEnd", "a", "2=#Game_Commencing", "2=#Game_will_restart_in");
	register_logevent("EventRoundEnd", 2, "1=Round_End");
	register_event("ResetHUD", "EventResetHUD", "be");
	
	register_forward(FM_ClientDisconnect, "fwd_ClientDisconnect_Post", true);
	
	g_iMsgMoney = get_user_msgid("Money");
	register_message(get_user_msgid("TeamInfo"), "Msg_TeamInfo");
	register_message(g_iMsgMoney, "Msg_Money");
	
	#if AMXX_VERSION_NUM < 183
	g_iMaxPlayers = get_maxplayers();
	#endif
	
	g_iFreeForAllEnabled = DM_IsFreeForAllEnabled();
}

/* -Client-------------------------------------------------------------------- */

public client_putinserver(id) <deactivated> {}
public client_putinserver(id) <enabled>
{
	add_bitsum(bs_IsConnected, id);
	
	g_iMoney[id] = (g_iMaxMoney > 0) ? ((g_iStartMoney > g_iMaxMoney) ? g_iMaxMoney : g_iStartMoney) : g_iStartMoney;
	
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
	del_bitsum(bs_IsAlive, id);
	del_bitsum(bs_IsBot, id);
}

public fwd_ClientDisconnect_Post(id)
{
	del_bitsum(bs_IsConnected, id);
}

/* -Spawn--------------------------------------------------------------------- */

public DM_PlayerSpawn_Post(id, freezetime, roundend) <deactivated> {}
public DM_PlayerSpawn_Post(id, freezetime, roundend) <enabled>
{
	add_bitsum(bs_IsAlive, id);
	
	if (g_bIntermission) return;
	
	UpdateMoneyMessage(id);
}

public DM_PlayerKilled_Pre(victim, attacker) <deactivated> {}
public DM_PlayerKilled_Pre(victim, attacker) <enabled>
{
	del_bitsum(bs_IsAlive, victim);
}

public DM_PlayerKilled_Post(victim, attacker) <deactivated> {}
public DM_PlayerKilled_Post(victim, attacker) <enabled>
{
	if (victim == attacker || !is_user_valid_connected(attacker) || g_bIntermission)
		return;
	
	static bool:bTeamKill;
	bTeamKill = (!g_iFreeForAllEnabled && g_iTeamID[victim] == g_iTeamID[attacker]) ? true : false;
	
	if (g_bScenarios && g_bBombScenario)
	{
		if (g_bRoundEnd)
		{
			GiveReward(attacker, bTeamKill ? -g_iRewardKillPlayer : g_iRewardKillPlayer);
			return;
		}
		
		if (DM_UserIsPlanting(victim)) GiveReward(attacker, bTeamKill ? -g_iRewardKillPlanter : g_iRewardKillPlanter);
		else if (DM_UserIsCarrierBomb(victim)) GiveReward(attacker, bTeamKill ? -g_iRewardKillCarrier : g_iRewardKillCarrier);
		else if (DM_UserIsDefusing(victim)) GiveReward(attacker, bTeamKill ? -g_iRewardKillDefuser : g_iRewardKillDefuser);
		else GiveReward(attacker, bTeamKill ? -g_iRewardKillPlayer : g_iRewardKillPlayer);
	}
	else GiveReward(attacker, bTeamKill ? -g_iRewardKillPlayer : g_iRewardKillPlayer);
}

/* -Events-------------------------------------------------------------------- */

public EventRoundStart()
{
	g_bRoundEnd = false;
	
	g_bHostageNotRescued = false;
	g_iHostageNotRescued = g_iHostageNum;
}

public EventRoundEnd()
{
	g_bRoundEnd = true;
}

public EventResetHUD(id)
{
	UpdateMoneyMessage(id);
}

/* -Scenarios----------------------------------------------------------------- */

public DM_OnIntermission()
{
	g_bIntermission = true;
}

public DM_CTsWin() <deactivated> {}
public DM_CTsWin() <enabled>
{
	GiveRewardTeamCTs(g_iRewardCTsWin);
	
	if (g_bRewardAnnounce && g_iRewardCTsWin)
	{
		#if AMXX_VERSION_NUM < 183
		dm_print_color(0, Blue, "^4[DM-Rewards]^1 %L", LANG_SERVER, "DM_REWARD_TER_DEFEATED", g_iRewardCTsWin);
		#else
		client_print_color(0, print_team_blue, "^4[DM-Rewards]^1 %L", LANG_SERVER, "DM_REWARD_TER_DEFEATED", g_iRewardCTsWin);
		#endif
	}
}

public DM_TerroristsWin() <deactivated> {}
public DM_TerroristsWin() <enabled>
{
	GiveRewardTeamTerrors(g_iRewardTerrorsWin);
	
	if (g_bRewardAnnounce && g_iRewardTerrorsWin)
	{
		#if AMXX_VERSION_NUM < 183
		dm_print_color(0, Red, "^4[DM-Rewards]^1 %L", LANG_SERVER, "DM_REWARD_CT_DEFEATED", g_iRewardTerrorsWin);
		#else
		client_print_color(0, print_team_red, "^4[DM-Rewards]^1 %L", LANG_SERVER, "DM_REWARD_CT_DEFEATED", g_iRewardTerrorsWin);
		#endif
	}
}

public DM_BombPlanted(id, roundend) <deactivated> {}
public DM_BombPlanted(id, roundend) <enabled>
{
	if (!roundend)
	{
		GiveReward(id, g_iRewardBombPlanted);
		
		if (g_bRewardAnnounce && g_iRewardBombPlanted)
		{
			new name[32]; get_user_name(id, name, 31);
			#if AMXX_VERSION_NUM < 183
			dm_print_color(0, Red, "^4[DM-Rewards]^1 %L", LANG_SERVER, "DM_REWARD_BOMB_PLANTED", name, g_iRewardBombPlanted);
			#else
			client_print_color(0, print_team_red, "^4[DM-Rewards]^1 %L", LANG_SERVER, "DM_REWARD_BOMB_PLANTED", name, g_iRewardBombPlanted);
			#endif
		}
	}
}

public DM_BombDefused(id) <deactivated> {}
public DM_BombDefused(id) <enabled>
{
	GiveRewardTeamCTs(g_iRewardBombDefusedTeam, id, g_iRewardBombDefused);
	
	if (g_bRewardAnnounce && (g_iRewardBombDefusedTeam || g_iRewardBombDefused))
	{
		new name[32]; get_user_name(id, name, 31);
		#if AMXX_VERSION_NUM < 183
		dm_print_color(0, Blue, "^4[DM-Rewards]^1 %L", LANG_SERVER, "DM_REWARD_BOMB_DEFUSED", g_iRewardBombDefusedTeam, name, g_iRewardBombDefused);
		#else
		client_print_color(0, print_team_blue, "^4[DM-Rewards]^1 %L", LANG_SERVER, "DM_REWARD_BOMB_DEFUSED", g_iRewardBombDefusedTeam, name, g_iRewardBombDefused);
		#endif
	}
}

public DM_TargetBombed(planter, defuser) <deactivated> {}
public DM_TargetBombed(planter, defuser) <enabled>
{
	GiveRewardTeamTerrors(g_iRewardTargetBombed);
	
	if (g_bRewardAnnounce && g_iRewardTargetBombed)
	{
		#if AMXX_VERSION_NUM < 183
		dm_print_color(0, Red, "^4[DM-Rewards]^1 %L", LANG_SERVER, "DM_REWARD_BOMBED", g_iRewardTargetBombed);
		#else
		client_print_color(0, print_team_red, "^4[DM-Rewards]^1 %L", LANG_SERVER, "DM_REWARD_BOMBED", g_iRewardTargetBombed);
		#endif
	}
}

public DM_TargetSaved() <deactivated> {}
public DM_TargetSaved() <enabled>
{
	GiveRewardTeamCTs(g_iRewardTargetSaved);
	
	if (g_bRewardAnnounce && g_iRewardTargetSaved)
	{
		#if AMXX_VERSION_NUM < 183
		dm_print_color(0, Blue, "^4[DM-Rewards]^1 %L", LANG_SERVER, "DM_REWARD_SAVED", g_iRewardTargetSaved);
		#else
		client_print_color(0, print_team_blue, "^4[DM-Rewards]^1 %L", LANG_SERVER, "DM_REWARD_SAVED", g_iRewardTargetSaved);
		#endif
	}
}

public DM_VipAssassinated(killer, vip) <deactivated> {}
public DM_VipAssassinated(killer, vip) <enabled>
{
	if (!killer || killer == vip)
		return;
	
	GiveRewardTeamTerrors(g_iRewardVipAssassinatedTeam, killer, g_iRewardVipAssassinated);
	
	if (g_bRewardAnnounce && (g_iRewardVipAssassinatedTeam || g_iRewardVipAssassinated))
	{
		new name[32]; get_user_name(killer, name, 31);
		#if AMXX_VERSION_NUM < 183
		dm_print_color(0, Red, "^4[DM-Rewards]^1 %L", LANG_SERVER, "DM_REWARD_VIP_DIED", g_iRewardVipAssassinatedTeam, name, g_iRewardVipAssassinated);
		#else
		client_print_color(0, print_team_red, "^4[DM-Rewards]^1 %L", LANG_SERVER, "DM_REWARD_VIP_DIED", g_iRewardVipAssassinatedTeam, name, g_iRewardVipAssassinated);
		#endif
	}
}

public DM_VipEscaped(id, freezetime, roundend) <deactivated> {}
public DM_VipEscaped(id, freezetime, roundend) <enabled>
{
	if (freezetime || roundend)
		return;
	
	GiveRewardTeamCTs(g_iRewardVipEscapedTeam, id, g_iRewardVipEscaped);
	
	if (g_bRewardAnnounce && (g_iRewardVipEscapedTeam || g_iRewardVipEscaped))
	{
		new name[32]; get_user_name(id, name, 31);
		#if AMXX_VERSION_NUM < 183
		dm_print_color(0, Blue, "^4[DM-Rewards]^1 %L", LANG_SERVER, "DM_REWARD_VIP_ESCAPED", g_iRewardVipEscapedTeam, name, g_iRewardVipEscaped);
		#else
		client_print_color(0, print_team_blue, "^4[DM-Rewards]^1 %L", LANG_SERVER, "DM_REWARD_VIP_ESCAPED", g_iRewardVipEscapedTeam, name, g_iRewardVipEscaped);
		#endif
	}
}

public DM_VipNotEscaped(id) <deactivated> {}
public DM_VipNotEscaped(id) <enabled>
{
	GiveRewardTeamTerrors(g_iRewardVipNotEscaped);
	
	if (g_bRewardAnnounce && g_iRewardVipNotEscaped)
	{
		#if AMXX_VERSION_NUM < 183
		dm_print_color(0, Red, "^4[DM-Rewards]^1 %L", LANG_SERVER, "DM_REWARD_VIP_NOT_ESCAPED", g_iRewardVipNotEscaped);
		#else
		client_print_color(0, print_team_red, "^4[DM-Rewards]^1 %L", LANG_SERVER, "DM_REWARD_VIP_NOT_ESCAPED", g_iRewardVipNotEscaped);
		#endif
	}
}

public DM_HostageTouched(id, freezetime, roundend) <deactivated> {}
public DM_HostageTouched(id, freezetime, roundend) <enabled>
{
	if (freezetime || roundend)
		return;
	
	GiveReward(id, g_iRewardHostageTouched);
	
	if (g_bRewardAnnounce && g_iRewardHostageTouched)
	{
		new name[32]; get_user_name(id, name, 31);
		#if AMXX_VERSION_NUM < 183
		dm_print_color(0, Blue, "^4[DM-Rewards]^3 %L", LANG_SERVER, "DM_REWARD_TOUCHED", name, g_iRewardHostageTouched);
		#else
		client_print_color(0, print_team_blue, "^4[DM-Rewards]^3 %L", LANG_SERVER, "DM_REWARD_TOUCHED", name, g_iRewardHostageTouched);
		#endif
	}
}

public DM_HostageRescued(id, freezetime, roundend) <deactivated> {}
public DM_HostageRescued(id, freezetime, roundend) <enabled>
{
	g_iHostageNotRescued--;
	
	if ((id && freezetime) || (id && roundend) || g_bHostageNotRescued)
		return;
	
	GiveRewardTeamCTs(g_iRewardHostageRescuedTeam, id, g_iRewardHostageRescued);
	
	if (g_bRewardAnnounce && (g_iRewardHostageRescuedTeam || g_iRewardHostageRescued) && id)
	{
		new name[32]; get_user_name(id, name, 31);
		#if AMXX_VERSION_NUM < 183
		dm_print_color(0, Blue, "^4[DM-Rewards]^1 %L", LANG_SERVER, "DM_REWARD_RESCUED_ID", g_iRewardHostageRescuedTeam, name, g_iRewardHostageRescued);
		#else
		client_print_color(0, print_team_blue, "^4[DM-Rewards]^1 %L", LANG_SERVER, "DM_REWARD_RESCUED_ID", g_iRewardHostageRescuedTeam, name, g_iRewardHostageRescued);
		#endif
	}
	else if (g_bRewardAnnounce && g_iRewardHostageRescuedTeam && id == 0)
	{
		#if AMXX_VERSION_NUM < 183
		dm_print_color(0, Blue, "^4[DM-Rewards]^1 %L", LANG_SERVER, "DM_REWARD_RESCUED", g_iRewardHostageRescuedTeam);
		#else
		client_print_color(0, print_team_blue, "^4[DM-Rewards]^1 %L", LANG_SERVER, "DM_REWARD_RESCUED", g_iRewardHostageRescuedTeam);
		#endif
	}
}

public DM_HostageKilled(id, roundend) <deactivated> {}
public DM_HostageKilled(id, roundend) <enabled>
{
	if (!roundend)
	{
		g_iHostageNotRescued--;
		
		GiveReward(id, g_iRewardHostageKilled);
		
		if (g_bRewardAnnounce && g_iRewardHostageKilled != 0)
		{
			new name[32]; get_user_name(id, name, 31);
			#if AMXX_VERSION_NUM < 183
			dm_print_color(0, DontChange, "^4[DM-Rewards]^1 %L", LANG_SERVER, "DM_REWARD_KILLED", name, g_iRewardHostageKilled);
			#else
			client_print_color(0, print_team_default, "^4[DM-Rewards]^1 %L", LANG_SERVER, "DM_REWARD_KILLED", name, g_iRewardHostageKilled);
			#endif
		}
	}
}

public DM_HostagesNotRescued() <deactivated> {}
public DM_HostagesNotRescued() <enabled>
{
	g_bHostageNotRescued = true;
	
	GiveRewardTeamTerrors(g_iRewardHostagesNotRescued * g_iHostageNotRescued);
	
	if (g_bRewardAnnounce && g_iRewardHostagesNotRescued)
	{
		#if AMXX_VERSION_NUM < 183
		dm_print_color(0, Red, "^4[DM-Rewards]^3 %L", LANG_SERVER, "DM_REWARD_NOT_RESCUED", g_iHostageNotRescued, g_iRewardHostagesNotRescued * g_iHostageNotRescued);
		#else
		client_print_color(0, print_team_red, "^4[DM-Rewards]^3 %L", LANG_SERVER, "DM_REWARD_NOT_RESCUED", g_iHostageNotRescued, g_iRewardHostagesNotRescued * g_iHostageNotRescued);
		#endif
	}
}

/* -Misc---------------------------------------------------------------------- */

GiveReward(id, amount)
{
	g_iMoney[id] = clamp(g_iMoney[id] += amount, 0, (g_iMaxMoney > 0) ? g_iMaxMoney : MAX_MONEY);
	UpdateMoneyMessage(id, g_iFlashMoney);
}

GiveRewardTeamCTs(amount, id = 0, extra = 0)
{
	static i;
	#if AMXX_VERSION_NUM < 183
	for (i = 1; i <= g_iMaxPlayers; i++)
	#else
	for (i = 1; i <= MaxClients; i++)
	#endif
	{
		if (!get_bitsum(bs_IsConnected, i) || g_iTeamID[i] != DM_TEAM_CT)
			continue;
		
		if (id == i) GiveReward(i, amount + extra);
		else GiveReward(i, amount);
	}
}

GiveRewardTeamTerrors(amount, id = 0, extra = 0)
{
	static i;
	#if AMXX_VERSION_NUM < 183
	for (i = 1; i <= g_iMaxPlayers; i++)
	#else
	for (i = 1; i <= MaxClients; i++)
	#endif
	{
		if (!get_bitsum(bs_IsConnected, i) || g_iTeamID[i] != DM_TEAM_T)
			continue;
		
		if (id == i) GiveReward(i, amount + extra);
		else GiveReward(i, amount);
	}
}

UpdateMoneyMessage(const id, flash = 0)
{
	if (!get_bitsum(bs_IsAlive, id) || get_bitsum(bs_IsBot, id))
		return;
	
	message_begin(MSG_ONE, g_iMsgMoney, _, id);
	write_long(g_iMoney[id]);
	write_byte(flash);
	message_end();
}

/* -Messages------------------------------------------------------------------ */

public Msg_TeamInfo(msg_id, msg_dest)
{
	if (msg_dest != MSG_ALL && msg_dest != MSG_BROADCAST)
		return;
	
	static team[2]; get_msg_arg_string(2, team, charsmax(team));
	
	switch (team[0])
	{
		case 'S': g_iTeamID[get_msg_arg_int(1)] = DM_TEAM_SPECTATOR;
		case 'C': g_iTeamID[get_msg_arg_int(1)] = DM_TEAM_CT;
		case 'T': g_iTeamID[get_msg_arg_int(1)] = DM_TEAM_T;
		default: g_iTeamID[get_msg_arg_int(1)] = DM_TEAM_UNASSIGNED;
	}
}

public Msg_Money(msg_id, msg_dest, msg_entity)
{
	fm_cs_set_user_money(msg_entity, 0);
	
	return PLUGIN_HANDLED;
}

/* -Native-------------------------------------------------------------------- */

/* native DM_GetStartMoney(); */
public native_get_start_money(plugin_id, num_params) <deactivated> return -1;
public native_get_start_money(plugin_id, num_params) <enabled>
{
	return g_iStartMoney;
}

/* native DM_GetUserMoney(const id); */
public native_get_user_money(plugin_id, num_params) <deactivated> return -1;
public native_get_user_money(plugin_id, num_params) <enabled>
{
	new id = get_param(1);
	
	if (!get_bitsum(bs_IsConnected, id))
	{
		DM_Log(LOG_INFO, "Invalid player (%d)", id);
		DM_LogPlugin(LOG_INFO, plugin_id, "DM_GetUserMoney", 1);
		return -1;
	}
	
	return g_iMoney[id];
}

/* native DM_SetUserMoney(const id, const amount, const flash); */
public native_set_user_money(plugin_id, num_params) <deactivated> return 0;
public native_set_user_money(plugin_id, num_params) <enabled>
{
	new id = get_param(1);
	
	if (!get_bitsum(bs_IsConnected, id))
	{
		DM_Log(LOG_INFO, "Invalid player (%d)", id);
		DM_LogPlugin(LOG_INFO, plugin_id, "DM_SetUserMoney", 2);
		return 0;
	}
	
	g_iMoney[id] = clamp(get_param(2), 0, (g_iMaxMoney > 0) ? g_iMaxMoney : MAX_MONEY);
	UpdateMoneyMessage(id, !!get_param(3));
	
	return 1;
}

/* -Stocks-------------------------------------------------------------------- */

stock fm_cs_set_user_money(id, value)
{
	if (pev_valid(id) != FM_PDATA_SAFE)
		return;
	
	set_pdata_int(id, OFFSET_MONEY, value);
}
