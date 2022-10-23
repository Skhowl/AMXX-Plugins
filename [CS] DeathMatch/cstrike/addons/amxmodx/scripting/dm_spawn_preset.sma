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
#include <dm_spawn>
#include <dm_ffa>

#define MAX_SPAWNS 256

/* --------------------------------------------------------------------------- */

new g_iTeamID[DM_MAX_PLAYERS+1] = { 0, ... };

new Float:g_fOrigin[MAX_SPAWNS][3];
new Float:g_fSpawnAngles[MAX_SPAWNS][3];
new Float:g_fSpawnViewAngles[MAX_SPAWNS][3];
new g_iSpawnTeamID[MAX_SPAWNS] = { 0, ... };
new g_iTotalSpawns = 0;

#if AMXX_VERSION_NUM < 183
new g_iMaxPlayers = 0;
#endif

new bs_IsAlive = 0;

#define get_bitsum(%1,%2)   (%1 &   (1<<((%2-1)&31)))
#define add_bitsum(%1,%2)    %1 |=  (1<<((%2-1)&31))
#define del_bitsum(%1,%2)    %1 &= ~(1<<((%2-1)&31))

/* -Init---------------------------------------------------------------------- */

public DM_OnModStatus(status)
{
	register_plugin("DM: Spawn Preset", DM_VERSION_STR_LONG, "schmurgel1983");
	
	if (status) state enabled;
	else state deactivated;
}

public plugin_init() <deactivated> {}
public plugin_init() <enabled>
{
	if (!DM_RegisterSpawnMode("preset", "DM_Spawn_Preset"))
	{
		state deactivated;
		return;
	}
	
	LoadSpawns();
	
	register_message(get_user_msgid("TeamInfo"), "Msg_TeamInfo");
	
	#if AMXX_VERSION_NUM < 183
	g_iMaxPlayers =  get_maxplayers();
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
}

/* --------------------------------------------------------------------------- */

public DM_Spawn_Preset(id, freezetime, roundend)
{
	if (g_iTotalSpawns < 2 || !get_bitsum(bs_IsAlive, id))
		return;
	
	new players[32], num, n, i, x, ffa;
	new Float:loc[32][3], locnum;
	
	// get_players(players, num, "a") // dosen't work all time (1.8.2.dev.hg24)
	#if AMXX_VERSION_NUM < 183
	for (i = 1; i <= g_iMaxPlayers; i++)
	#else
	for (i = 1; i <= MaxClients; i++)
	#endif
	{
		if (get_bitsum(bs_IsAlive, i))
		{
			players[num] = i;
			num++;
		}
	}
	
	for (i = 0; i < num; i++)
	{
		if (players[i] != id)
		{
			pev(players[i], pev_origin, loc[locnum]);
			locnum++;
		}
	}
	
	n = random_num(0, g_iTotalSpawns - 1);
	ffa = DM_IsFreeForAllEnabled();
	
	for (i = n + 1; /*no condition*/; i++)
	{
		if (i >= g_iTotalSpawns) i = 0;
		
		if (!ffa && g_iSpawnTeamID[i] > DM_TEAM_UNASSIGNED && g_iTeamID[id] != g_iSpawnTeamID[i])
		{
			if (i == n) break;
			else continue;
		}
		
		for (x = 0; x < locnum; x++)
		{
			if (get_distance_f(g_fOrigin[i], loc[x]) < 250.0)
			{
				if (i == n) break;
				else continue;
			}
		}
		
		if (is_hull_vacant(g_fOrigin[i], HULL_HUMAN))
		{
			engfunc(EngFunc_SetOrigin, id, g_fOrigin[i]);
			set_pev(id, pev_angles, g_fSpawnAngles[i]);
			set_pev(id, pev_v_angle, g_fSpawnViewAngles[i]);
			set_pev(id, pev_fixangle, 1);
			
			break;
		}
		
		if (i == n) break;
	}
}

/* --------------------------------------------------------------------------- */

LoadSpawns()
{
	new map[32], path[64];
	get_mapname(map, charsmax(map));
	get_configsdir(path, charsmax(path));
	format(path, charsmax(path), "%s\csdm\%s.spawns.cfg", path, map);
	g_iTotalSpawns = 0;
	
	if (!file_exists(path))
	{
		return;
	}
	
	new file = fopen(path, "rt");
	if (!file)
	{
		log_amx("Cannot open spawn points file: %s", path);
		return;
	}
	
	new linedata[128], pos[10][13];
	while (!feof(file))
	{
		if (g_iTotalSpawns >= MAX_SPAWNS)
			break;
		
		fgets(file, linedata, charsmax(linedata));
		trim(linedata);
		
		if (strlen(linedata) < 2 || linedata[0] == '[' || linedata[0] == ';' || linedata[0] == '#' || linedata[0] == '/')
			continue;
		
		parse(linedata, pos[0], 12, pos[1], 12, pos[2], 12, pos[3], 12, pos[4], 12, pos[5], 12, pos[6], 12, pos[7], 12, pos[8], 12, pos[9], 12);
		
		// Origin
		g_fOrigin[g_iTotalSpawns][0] = str_to_float(pos[0]);
		g_fOrigin[g_iTotalSpawns][1] = str_to_float(pos[1]);
		g_fOrigin[g_iTotalSpawns][2] = str_to_float(pos[2]);
		
		// Angles
		g_fSpawnAngles[g_iTotalSpawns][0] = str_to_float(pos[3]);
		g_fSpawnAngles[g_iTotalSpawns][1] = str_to_float(pos[4]);
		g_fSpawnAngles[g_iTotalSpawns][2] = str_to_float(pos[5]);
		
		// Team
		g_iSpawnTeamID[g_iTotalSpawns] = str_to_num(pos[6]);
		
		// V-Angles
		g_fSpawnViewAngles[g_iTotalSpawns][0] = str_to_float(pos[7]);
		g_fSpawnViewAngles[g_iTotalSpawns][1] = str_to_float(pos[8]);
		g_fSpawnViewAngles[g_iTotalSpawns][2] = str_to_float(pos[9]);
		
		g_iTotalSpawns++;
	}
	fclose(file);
	
	//log_amx("Loaded %d spawn points for map %s.", g_iTotalSpawns, map)
}

/* --------------------------------------------------------------------------- */

public Msg_TeamInfo(msg_id, msg_dest)
{
	if (msg_dest != MSG_ALL && msg_dest != MSG_BROADCAST)
		return;
	
	static id, team[2];
	id = get_msg_arg_int(1);
	get_msg_arg_string(2, team, charsmax(team));
	
	switch (team[0])
	{
		case 'S': g_iTeamID[id] = DM_TEAM_SPECTATOR;
		case 'C': g_iTeamID[id] = DM_TEAM_CT;
		case 'T': g_iTeamID[id] = DM_TEAM_T;
		default: g_iTeamID[id] = DM_TEAM_UNASSIGNED;
	}
}

/* --------------------------------------------------------------------------- */

stock get_configsdir(name[], len)
{
	return get_localinfo("amxx_configsdir", name, len);
}

stock is_hull_vacant(Float:origin[3], hull)
{
	engfunc(EngFunc_TraceHull, origin, origin, 0, hull, 0, 0);
	
	if (!get_tr2(0, TR_StartSolid) && !get_tr2(0, TR_AllSolid) && get_tr2(0, TR_InOpen))
		return true;
	
	return false;
}
