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

#include <dm_core>
#include <dm_spawn>
#include <dm_ffa>
#include <dm_colorchat>

/* --------------------------------------------------------------------------- */

const FM_PDATA_SAFE = 2;
const OFFSET_CSTEAMS = 114;
const OFFSET_INTERNALMODEL = 126;

/* --------------------------------------------------------------------------- */

new const g_szTeamNames[][] = 
{
	"UNASSIGNED",
	"TERRORIST",
	"CT",
	"SPECTATOR"
};

enum
{
	CT_URBAN = 1,
	T_TERROR,
	T_LEET,
	T_ARCTIC,
	CT_GSG9,
	CT_GIGN,
	CT_SAS,
	T_GUERILLA,
	CT_VIP,
	T_MILITIA,
	CT_SPETSNAZ
}

new const g_iModels[][] = {
	{T_TERROR, CT_URBAN},
	{T_LEET, CT_GSG9},
	{T_ARCTIC, CT_SAS},
	{T_GUERILLA, CT_GIGN},
	{T_MILITIA, CT_SPETSNAZ}
};

new const g_szModels[][] = {
	"", "urban", "terror", "leet", "arctic", "gsg9", "gign",
	"sas", "guerilla", "vip", "militia", "spetsnaz"
};

/* --------------------------------------------------------------------------- */

new g_iMaxAppearances = 4;

new g_iTeamID[DM_MAX_PLAYERS+1] = { 0, ... };

new g_iTeamInfo = 0;
new g_iCounter = 0;
new bool:g_bForceCheck = false;
new Float:g_fNextAnnounce = 0.0;

new p_LimitTeams = 0;
new p_AutoTeamBalance = 0;

new bool:g_bTeamBalance = false;
new bool:g_bAdminImmunity = false;
new g_iImmunityFlag = 0;
new g_iDeathFrequence = 0;

/* -Init---------------------------------------------------------------------- */

public DM_OnModStatus(status)
{
	register_plugin("DM: Teambalancer", DM_VERSION_STR_LONG, "schmurgel1983");
	
	if (status) state enabled;
	else state deactivated;
}

/* --------------------------------------------------------------------------- */

public plugin_init() <deactivated> {}
public plugin_init() <enabled>
{
	if (!DM_LoadConfiguration("dm_teambalancer.cfg", "DM_ReadBalancer") || !g_bTeamBalance)
	{
		state deactivated;
		return;
	}
	
	#if AMXX_VERSION_NUM < 183
	register_dictionary_colored("dm_teambalancer.txt");
	#else
	register_dictionary("dm_teambalancer.txt");
	#endif
	
	p_LimitTeams = get_cvar_pointer("mp_limitteams");
	p_AutoTeamBalance = get_cvar_pointer("mp_autoteambalance");
	
	new szModName[6];
	get_modname(szModName, charsmax(szModName));
	if (equal(szModName, "czero"))
	{
		g_iMaxAppearances = 5;
	}
	
	g_iTeamInfo = get_user_msgid("TeamInfo");
	register_message(g_iTeamInfo, "Msg_TeamInfo");
}

public DM_ReadBalancer(section[], key[], value[])
{
	if (equali(section, "balancer"))
	{
		if (equali(key, "enable")) g_bTeamBalance = !!bool:str_to_num(value);
		else if (equali(key, "admins_immunity")) g_bAdminImmunity = !!bool:str_to_num(value);
		else if (equali(key, "immunity_flag"))
		{
			new szFlags[24];
			copy(szFlags, charsmax(szFlags), value);
			g_iImmunityFlag = read_flags(szFlags);
		}
		else if (equali(key, "death_frequence")) g_iDeathFrequence = clamp(str_to_num(value), 1, 10);
	}
}

/* --------------------------------------------------------------------------- */

public DM_PlayerKilled_Post(victim, attacker) <deactivated> {}
public DM_PlayerKilled_Post(victim, attacker) <enabled>
{
	if ((++g_iCounter < g_iDeathFrequence && !g_bForceCheck) || !get_pcvar_num(p_AutoTeamBalance) || (g_bAdminImmunity && get_user_flags(victim) & g_iImmunityFlag) || cs_get_user_vip(victim))
		return;
	
	if (!(DM_TEAM_T <= g_iTeamID[victim] <= DM_TEAM_CT))
		return;
	
	new iTerrorists, iCts;
	new iPlayers[32], iNum;
	get_players(iPlayers, iNum, "h");
	for (--iNum; iNum >= 0; iNum--)
	{
		switch (g_iTeamID[iPlayers[iNum]])
		{
			case DM_TEAM_T: iTerrorists++;
			case DM_TEAM_CT: iCts++;
		}
	}
	
	new iLimit = max(get_pcvar_num(p_LimitTeams), 1);
	
	new iDiff = abs(iCts - iTerrorists);
	if (iDiff < 2 || iDiff <= iLimit)
	{
		g_bForceCheck = false;
		return;
	}
	
	if (iCts > iTerrorists)
	{
		if (g_iTeamID[victim] == DM_TEAM_CT)
		{
			if (SetUserTeam(victim, DM_TEAM_T))
			{
				#if AMXX_VERSION_NUM < 183
				dm_print_color(victim, Red, "^4[DM-TeamBalancer]^1 %L", victim, "DM_BALANCER_YOU_TER");
				#else
				client_print_color(victim, print_team_red, "^4[DM-TeamBalancer]^1 %L", victim, "DM_BALANCER_YOU_TER");
				#endif
				
				set_hudmessage(255, 255, 255, -1.0, 0.40, 0, 0.5, 6.0, 0.0, 0.1, -1);
				show_hudmessage(victim, "You have been switched to team TERRORIST.");
				iDiff -= 2;
			}
		}
		
		if (iDiff > 1 && iDiff > iLimit)
		{
			new Float:fCurrentTime = get_gametime();
			
			if (g_fNextAnnounce < fCurrentTime)
			{
				#if AMXX_VERSION_NUM < 183
				dm_print_color(0, Red, "^4[DM-TeamBalancer]^1 %L", LANG_SERVER, "DM_BALANCER_DYING_TER");
				#else
				client_print_color(0, print_team_red, "^4[DM-TeamBalancer]^1 %L", LANG_SERVER, "DM_BALANCER_DYING_TER");
				#endif
				g_fNextAnnounce = fCurrentTime + 5.0;
			}
			g_bForceCheck = true;
			
			return;
		}
	}
	else
	{
		if (g_iTeamID[victim] == DM_TEAM_T)
		{
			if (SetUserTeam(victim, DM_TEAM_CT))
			{
				#if AMXX_VERSION_NUM < 183
				dm_print_color(victim, Blue, "^4[DM-TeamBalancer]^1 %L", victim, "DM_BALANCER_YOU_CT");
				#else
				client_print_color(victim, print_team_blue, "^4[DM-TeamBalancer]^1 %L", victim, "DM_BALANCER_YOU_CT");
				#endif
				
				set_hudmessage(255, 255, 255, -1.0, 0.40, 0, 0.5, 6.0, 0.0, 0.1, -1);
				show_hudmessage(victim, "You have been switched to team CT.");
				iDiff -= 2;
			}
		}
		
		if (iDiff > 1 && iDiff > iLimit)
		{
			new Float:fCurrentTime = get_gametime();
			
			if (g_fNextAnnounce < fCurrentTime)
			{
				#if AMXX_VERSION_NUM < 183
				dm_print_color(0, Blue, "^4[DM-TeamBalancer]^1 %L", LANG_SERVER, "DM_BALANCER_DYING_CT");
				#else
				client_print_color(0, print_team_blue, "^4[DM-TeamBalancer]^1 %L", LANG_SERVER, "DM_BALANCER_DYING_CT");
				#endif
				g_fNextAnnounce = fCurrentTime + 5.0;
			}
			g_bForceCheck = true;
			
			return;
		}
	}
	
	g_iCounter = 0;
	g_bForceCheck = false;
	g_fNextAnnounce = get_gametime();
}

/* --------------------------------------------------------------------------- */

SetUserTeam(id, iTeam)
{
	if (pev_valid(id) != FM_PDATA_SAFE)
		return 0;
	
	set_pdata_int(id, OFFSET_CSTEAMS, iTeam);
	
	if (!DM_IsFreeForAllEnabled())
	{
		new iNewModel = g_iModels[iTeam-1][random(g_iMaxAppearances)];
		
		set_pdata_int(id, OFFSET_INTERNALMODEL, iNewModel);
		
		set_user_info(id, "model", g_szModels[iNewModel]);
	}
	
	emessage_begin(MSG_ALL, g_iTeamInfo);
	ewrite_byte(id);
	ewrite_string(g_szTeamNames[iTeam]);
	emessage_end();
	
	return 1;
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
}
