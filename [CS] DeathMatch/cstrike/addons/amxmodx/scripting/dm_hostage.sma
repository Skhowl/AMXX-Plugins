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
#include <dm_colorchat>

/* --------------------------------------------------------------------------- */

new bool:g_bCZero = false;
new g_iHostageNum = 0;
new g_iHostages[MAX_HOSTAGE_SUPPORT] = { 0, ... };
new g_iTeamID[DM_MAX_PLAYERS+1] = { 0, ... };

new bool:g_bTerrorBlocked = false;
new Float:g_fUseDistance = 0.0;
new bool:g_bNoHostageDamage = false;
new g_iResetTouch = 0;
new g_iHostageUnstuck = 0;
new g_iUnstuckType = 0;

const PEV_HOSTAGEFOLLOW = pev_iuser1;
const PEV_HOSTAGESTUCK = pev_iuser2;
const PEV_HOSTAGESPAWN = pev_vuser1;
const FM_PDATA_SAFE = 2;
const OFFSET_HOSTAGEFRISTTOUCH = 97;

new const Float:RANDOM_OWN_PLACE[][3] =
{
	{ -32.1,   0.0, 0.0 },
	{  32.1,   0.0, 0.0 },
	{   0.0, -32.1, 0.0 },
	{   0.0,  32.1, 0.0 },
	{ -32.1, -32.1, 0.0 },
	{ -32.1,  32.1, 0.0 },
	{  32.1,  32.1, 0.0 },
	{  32.1, -32.1, 0.0 }
};

#define fm_hostage_is_rescued(%1)	(pev(%1, pev_effects) == EF_NODRAW)
#define fm_hostage_is_waving(%1)	(pev(%1, pev_sequence) == 64)
#define fm_hostage_is_stuck(%1)		(pev(%1, pev_sequence) == 16)

#if AMXX_VERSION_NUM < 183
new g_iMaxPlayers = 0;
#define is_user_valid_connected(%1) (1 <= %1 <= g_iMaxPlayers && is_user_connected(%1))
#define is_user_valid_alive(%1)		(1 <= %1 <= g_iMaxPlayers && is_user_alive(%1))
#else
#define is_user_valid_connected(%1) (1 <= %1 <= MaxClients && is_user_connected(%1))
#define is_user_valid_alive(%1)		(1 <= %1 <= MaxClients && is_user_alive(%1))
#endif

/* -Init---------------------------------------------------------------------- */

public DM_OnModStatus(status)
{
	register_plugin("DM: Hostage", DM_VERSION_STR_LONG, "schmurgel1983");
	
	if (status) state enabled;
	else state deactivated;
}

public DM_OnMapConditions(bomb, vip, hosnum, hosid[]) <deactivated> {}
public DM_OnMapConditions(bomb, vip, hosnum, hosid[]) <enabled>
{
	if (!hosnum)
	{
		state deactivated;
		return;
	}
	
	g_iHostageNum = hosnum;
	for (new i = 0; i < hosnum; i++)
	{
		g_iHostages[i] = hosid[i];
	}
}

public plugin_init() <deactivated> {}
public plugin_init() <enabled>
{
	if (!DM_LoadConfiguration("dm_hostage.cfg", "DM_ReadHostage"))
	{
		state deactivated;
		return;
	}
	
	#if AMXX_VERSION_NUM < 183
	register_dictionary_colored("dm_hostage.txt");
	#else
	register_dictionary("dm_hostage.txt");
	#endif
	
	new szModName[6];
	get_modname(szModName, 5);
	if (equal(szModName, "czero"))
	{
		g_bCZero = true;
		
		RegisterHam(Ham_Use, "hostage_entity", "fwd_UseHostage", false);
		RegisterHam(Ham_Use, "hostage_entity", "fwd_UseHostage_Post", true);
		
		register_message(get_user_msgid("TeamInfo"), "Msg_TeamInfo");
		
		#if AMXX_VERSION_NUM < 183
		g_iMaxPlayers = get_maxplayers();
		#endif
	}
	
	register_logevent("LogEventRoundStart", 2, "1=Round_Start");
	
	if (g_bNoHostageDamage)
		RegisterHam(Ham_TakeDamage, "hostage_entity", "fwd_HostageTakeDamage");
}

public DM_ReadHostage(section[], key[], value[])
{
	if (equali(section, "hostage"))
	{
		if (equali(key, "terror_block_use")) g_bTerrorBlocked = !!bool:str_to_num(value);
		else if (equali(key, "max_use_distance")) g_fUseDistance = floatclamp(str_to_float(value), 45.0, 1016.0);
		else if (equali(key, "reset_touch")) g_iResetTouch = !!str_to_num(value);
		else if (equali(key, "unstuck_feature")) g_iHostageUnstuck = clamp(str_to_num(value), 0, 25);
		else if (equali(key, "unstuck_type")) g_iUnstuckType = !!str_to_num(value);
		else if (equali(key, "no_hostage_damage")) g_bNoHostageDamage = !!bool:str_to_num(value);
	}
}

public plugin_cfg() <deactivated> {}
public plugin_cfg() <enabled>
{
	new i, hos, Float:origin[3];
	for (i = 0; i < g_iHostageNum; i++)
	{
		hos = g_iHostages[i];
		
		pev(hos, pev_origin, origin);
		set_pev(hos, PEV_HOSTAGESPAWN, origin);
	}
}

/* --------------------------------------------------------------------------- */

public DM_PlayerKilled_Post(victim, attacker) <deactivated> {}
public DM_PlayerKilled_Post(victim, attacker) <enabled>
{
	if (!g_bCZero) return;
	
	new index, hostage, following;
	for (index = 0; index < g_iHostageNum; index++)
	{
		hostage = g_iHostages[index];
		
		following = pev(hostage, PEV_HOSTAGEFOLLOW);
		if (following && following == victim)
		{
			remove_task(hostage);
			set_pev(hostage, PEV_HOSTAGEFOLLOW, 0);
			cs_set_hostage_touch(hostage, g_iResetTouch);
		}
	}
}

/* --------------------------------------------------------------------------- */

public fwd_UseHostage(entity, toucher, idactivator, use_type, Float:value)
{
	if (value == 1.0)
		return HAM_SUPERCEDE;
	
	if (!is_user_valid_connected(toucher) || fm_hostage_is_rescued(entity))
		return HAM_IGNORED;
	
	if ((g_fUseDistance > 45.0 && g_fUseDistance < 1016.0) && fm_entity_range(entity, toucher) > g_fUseDistance) // Czero
		return HAM_SUPERCEDE;
	
	if (g_iTeamID[toucher] == DM_TEAM_T)
		return (g_bTerrorBlocked) ? HAM_SUPERCEDE : HAM_IGNORED;
	
	new following = pev(entity, PEV_HOSTAGEFOLLOW);
	if (following && following != toucher)
	{
		#if AMXX_VERSION_NUM < 183
		dm_print_color(toucher, Red, "^4[DM-Hostage]^1 %L", toucher, "DM_HOSTAGE_STEAL");
		#else
		client_print_color(toucher, print_team_red, "^4[DM-Hostage]^1 %L", toucher, "DM_HOSTAGE_STEAL");
		#endif
		return HAM_SUPERCEDE;
	}
	else if (following && following == toucher)
	{
		remove_task(entity);
		set_pev(entity, PEV_HOSTAGEFOLLOW, 0);
	}
	else
	{
		set_task(0.1, "CheckHostageSequence", entity, _, _, "b");
		set_pev(entity, PEV_HOSTAGEFOLLOW, toucher);
	}
	
	return HAM_IGNORED;
}

public fwd_UseHostage_Post(entity, toucher, idactivator, use_type, Float:value)
{
	if (value == 1.0)
		return HAM_SUPERCEDE;
	
	if (!is_user_valid_connected(toucher) || fm_hostage_is_rescued(entity))
		return HAM_IGNORED;
	
	if (g_iTeamID[toucher] == DM_TEAM_T)
		return (g_bTerrorBlocked) ? HAM_SUPERCEDE : HAM_IGNORED;
	
	if (!pev(entity, PEV_HOSTAGEFOLLOW))
	{
		cs_set_hostage_touch(entity, g_iResetTouch);
		return HAM_IGNORED;
	}
	
	return HAM_IGNORED;
}

public fwd_HostageTakeDamage(victim, inflictor, attacker, Float:damage, damagebits)
{
	return HAM_SUPERCEDE;
}

/* --------------------------------------------------------------------------- */

public LogEventRoundStart()
{
	if (g_bCZero)
	{
		new index, hostage;
		for (index = 0; index < g_iHostageNum; index++)
		{
			hostage = g_iHostages[index];
			
			remove_task(hostage);
			set_pev(hostage, PEV_HOSTAGEFOLLOW, 0);
			cs_set_hostage_touch(hostage, 0);
			
			set_pev(hostage, PEV_HOSTAGESTUCK, 0);
		}
	}
	
	static iMsgShowTimer;
	if (iMsgShowTimer || (iMsgShowTimer = get_user_msgid("ShowTimer")))
	{
		message_begin(MSG_ALL, iMsgShowTimer);
		message_end();
	}
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

/* --------------------------------------------------------------------------- */

// Is not the best but work!
public CheckHostageSequence(entity)
{
	// Entity not valid or Hostage is rescued
	if (!pev_valid(entity) || fm_hostage_is_rescued(entity))
	{
		remove_task(entity);
		return;
	}
	
	// Hostage is stucking?
	if (g_iHostageUnstuck && fm_hostage_is_stuck(entity))
	{
		static Float:oldorigin[3], Float:origin[3];
		pev(entity, pev_oldorigin, oldorigin);
		pev(entity, pev_origin, origin);
		
		// Is moving
		if (get_distance_f(oldorigin, origin) > 5.0)
		{
			// Do nothing
			set_pev(entity, pev_oldorigin, origin);
			set_pev(entity, PEV_HOSTAGESTUCK, 0);
			return;
		}
		
		// Unstuck?
		if (pev(entity, PEV_HOSTAGESTUCK) >= g_iHostageUnstuck)
		{
			if (!g_iUnstuckType)
			{
				pev(entity, PEV_HOSTAGESPAWN, origin);
				set_pev(entity, pev_origin, origin);
				
				set_pev(entity, PEV_HOSTAGESTUCK, 0);
				
				#if AMXX_VERSION_NUM < 183
				dm_print_color(0, DontChange, "^4[DM-Hostage]^1 %L", LANG_SERVER, "DM_HOSTAGE_SPAWNPOINT");
				#else
				client_print_color(0, print_team_default, "^4[DM-Hostage]^1 %L", LANG_SERVER, "DM_HOSTAGE_SPAWNPOINT");
				#endif
			}
			else
			{
				static Float:origin_z, Float:final[3], iSize, i, sp_index, following;
				iSize = sizeof(RANDOM_OWN_PLACE);
				following = pev(entity, PEV_HOSTAGEFOLLOW);
				
				if (is_user_valid_alive(following)) pev(following, pev_origin, origin);
				else pev(entity, pev_origin, origin);
				
				sp_index = random_num(0, iSize - 1);
				
				for (i = sp_index + 1; /*no condition*/; i++)
				{
					if (i >= iSize)
						i = 0;
					
					final[0] = origin[0] + RANDOM_OWN_PLACE[i][0];
					final[1] = origin[1] + RANDOM_OWN_PLACE[i][1];
					final[2] = origin_z = origin[2] + RANDOM_OWN_PLACE[i][2] - 35.0;
					
					new z = 0;
					do
					{
						if (is_hull_vacant(final))
						{
							i = sp_index;
							set_pev(entity, pev_velocity, { 0.0, 0.0, 0.0 });
							set_pev(entity, pev_origin, final);
							engfunc(EngFunc_DropToFloor, entity);
							
							#if AMXX_VERSION_NUM < 183
							if (!following) dm_print_color(0, DontChange, "^4[DM-Hostage]^1 %L", LANG_SERVER, "DM_HOSTAGE_UNSTUCK");
							else dm_print_color(0, DontChange, "^4[DM-Hostage]^1 %L", LANG_SERVER, "DM_HOSTAGE_FOLLLOW");
							#else
							if (!following) client_print_color(0, print_team_default, "^4[DM-Hostage]^1 %L", LANG_SERVER, "DM_HOSTAGE_UNSTUCK");
							else client_print_color(0, print_team_default, "^4[DM-Hostage]^1 %L", LANG_SERVER, "DM_HOSTAGE_FOLLLOW");
							#endif
							
							break;
						}
						
						final[2] = origin_z + (++z * 40.0);
					}
					while (z < 3);
					
					if (i == sp_index)
						break;
				}
			}
		}
		// Increase checks.
		else set_pev(entity, PEV_HOSTAGESTUCK, pev(entity, PEV_HOSTAGESTUCK) + 1);
	}
	
	// Hostage is waving
	if (fm_hostage_is_waving(entity))
	{
		remove_task(entity);
		set_pev(entity, PEV_HOSTAGEFOLLOW, 0);
		cs_set_hostage_touch(entity, g_iResetTouch);
	}
}

/* --------------------------------------------------------------------------- */

/* credits to VEN */
stock is_hull_vacant(Float:origin[3])
{
	engfunc(EngFunc_TraceHull, origin, origin, 0, HULL_HUMAN, 0, 0);
	
	if (!get_tr2(0, TR_StartSolid) && !get_tr2(0, TR_AllSolid) && get_tr2(0, TR_InOpen))
		return true;
	
	return false;
}

stock cs_set_hostage_touch(entity, touched)
{
	if (pev_valid(entity) != FM_PDATA_SAFE)
		return false;
	
	set_pdata_int(entity, OFFSET_HOSTAGEFRISTTOUCH, touched);
	return true;
}

stock Float:fm_entity_range(ent1, ent2)
{
	new Float:origin1[3], Float:origin2[3];
	pev(ent1, pev_origin, origin1);
	pev(ent2, pev_origin, origin2);
	
	return get_distance_f(origin1, origin2);
}
