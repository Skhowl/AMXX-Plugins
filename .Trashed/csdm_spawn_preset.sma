/**
 * csdm_spawn_preset.sma
 * Allows for Counter-Strike to be played as DeathMatch.

 * CSDM Spawn Method - Preset Spawning
 * by Freecode and BAILOPAN
 * (C)2003-2006 David "BAILOPAN" Anderson
 
 * CSDM Spawn Method - Team Spawning 1 & 2 v1.3
 * by schmurgel1983(@msn.com)
 * Copyright (C) 2009-2022 schmurgel1983, skhowl, gesalzen
 
 *  Give credit where due.
 *  Share the source - it sets you free
 *  http://www.opensource.org/
 *  http://www.gnu.org/
 */
 
// uncomment the line to have Debug Mode
//#define TEAM_PRESET_DEBUG
//#define TEAM_CLOSE_DEBUG

#define	MAX_SPAWNS	200

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <csdm>

//Tampering with the author and name lines will violate copyrights
new PLUGINNAME[] = "CSDM Mod"
new VERSION[] = CSDM_VERSION
new AUTHORS[] = "CSDM Team"

//Preset
new Float:g_SpawnVecs[MAX_SPAWNS][3];
new Float:g_SpawnAngles[MAX_SPAWNS][3];
new Float:g_SpawnVAngles[MAX_SPAWNS][3];
new g_TotalSpawns = 0;

//Team
const OFFSET_CSTEAMS = 114
const OFFSET_LINUX = 5
new g_maxplayers, g_hamczbots
new cvar_mindis, cvar_maxdis, cvar_botquota
new Float:g_mindis, Float:g_maxdis
enum
{
	FM_CS_TEAM_UNASSIGNED = 0,
	FM_CS_TEAM_T,
	FM_CS_TEAM_CT,
	FM_CS_TEAM_SPECTATOR
}
new g_isconnected[33]
new g_isalive[33]

public csdm_Init(const version[])
{
	if (version[0] == 0)
	{
		set_fail_state("CSDM failed to load.")
		return
	}
	
	csdm_addstyle("preset", "spawn_Preset")
	csdm_addstyle("teamclose", "spawn_Team")
	csdm_addstyle("teampreset", "spawn_Team_new")
}

public csdm_CfgInit()
{
	csdm_reg_cfg("settings", "read_cfg")
}

public plugin_init()
{
	register_plugin(PLUGINNAME,VERSION,AUTHORS)
	
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1)
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	
	register_forward(FM_ClientDisconnect, "fw_ClientDisconnect")
	
	cvar_mindis = register_cvar("csdm_mindis", "64.0")
	cvar_maxdis = register_cvar("csdm_maxdis", "512.0")
	cvar_botquota = get_cvar_pointer("bot_quota")
	
	register_cvar("CSDM_TeamSpawn_version", "1.3.2", FCVAR_SERVER|FCVAR_SPONLY)
	set_cvar_string("CSDM_TeamSpawn_version", "1.3.2")
	
	g_maxplayers = get_maxplayers()
}

public read_cfg(action, line[], section[])
{
	if (action == CFG_RELOAD)
	{
		readSpawns()
	}
}

readSpawns()
{
	//-617 2648 179 16 -22 0 0 -5 -22 0
	// Origin (x,y,z), Angles (x,y,z), vAngles(x,y,z), Team (0 = ALL) - ignore
	// :TODO: Implement team specific spawns
	
	new Map[32], config[32],  MapFile[64]
	
	get_mapname(Map, 31)
	get_configsdir(config, 31)
	format(MapFile, 63, "%s\csdm\%s.spawns.cfg", config, Map)
	g_TotalSpawns = 0;
	
	if (file_exists(MapFile)) 
	{
		new Data[124], len
		new line = 0
		new pos[12][8]
    		
		while(g_TotalSpawns < MAX_SPAWNS && (line = read_file(MapFile , line , Data , 123 , len) ) != 0 ) 
		{
			if (strlen(Data)<2 || Data[0] == '[')
				continue;

			parse(Data, pos[1], 7, pos[2], 7, pos[3], 7, pos[4], 7, pos[5], 7, pos[6], 7, pos[7], 7, pos[8], 7, pos[9], 7, pos[10], 7);
			
			// Origin
			g_SpawnVecs[g_TotalSpawns][0] = str_to_float(pos[1])
			g_SpawnVecs[g_TotalSpawns][1] = str_to_float(pos[2])
			g_SpawnVecs[g_TotalSpawns][2] = str_to_float(pos[3])
			
			//Angles
			g_SpawnAngles[g_TotalSpawns][0] = str_to_float(pos[4])
			g_SpawnAngles[g_TotalSpawns][1] = str_to_float(pos[5])
			g_SpawnAngles[g_TotalSpawns][2] = str_to_float(pos[6])
			
			//v-Angles
			g_SpawnVAngles[g_TotalSpawns][0] = str_to_float(pos[8])
			g_SpawnVAngles[g_TotalSpawns][1] = str_to_float(pos[9])
			g_SpawnVAngles[g_TotalSpawns][2] = str_to_float(pos[10])
			
			//Team - ignore - 7
			
			g_TotalSpawns++;
		}
		
		log_amx("Loaded %d spawn points for map %s.", g_TotalSpawns, Map)
	} else {
		log_amx("No spawn points file found (%s)", MapFile)
	}
	
	return 1;
}

public event_round_start()
{
	g_mindis = get_pcvar_float(cvar_mindis)
	g_maxdis = get_pcvar_float(cvar_maxdis)
}

public client_putinserver(id)
{
	g_isconnected[id] = true
	
	if (is_user_bot(id))
		if (!g_hamczbots && cvar_botquota)
			set_task(0.1, "register_ham_czbots", id)
}

public fw_ClientDisconnect(id)
{
	g_isconnected[id] = false
	g_isalive[id] = false
}

public register_ham_czbots(id)
{
	if (g_hamczbots || !g_isconnected[id] || !get_pcvar_num(cvar_botquota))
		return;
	
	RegisterHamFromEntity(Ham_Spawn, id, "fw_PlayerSpawn_Post", 1)
	RegisterHamFromEntity(Ham_Killed, id, "fw_PlayerKilled")
	
	g_hamczbots = true
	
	if (is_user_alive(id))
		fw_PlayerSpawn_Post(id)
}

public fw_PlayerSpawn_Post(id)
{
	if (!is_user_alive(id) || !fm_cs_get_user_team(id))
		return;
	
	g_isalive[id] = true
	
	#if defined TEAM_PRESET_DEBUG
	log_amx("%i: player spawned (start)", id)
	#endif
}

public fw_PlayerKilled(victim, attacker, shouldgib)
{
	g_isalive[victim] = false
	
	#if defined TEAM_PRESET_DEBUG
	log_amx("%i: player killed.", victim)
	#endif
}

public spawn_Preset(id, num)
{
	if (g_TotalSpawns < 2)
		return PLUGIN_CONTINUE
	
	new list[MAX_SPAWNS]
	new num = 0
	new final = -1
	new total=0
	new players[32], n, x = 0
	new Float:loc[32][3], locnum
	
	//cache locations
	get_players(players, num)
	for (new i=0; i<num; i++)
	{
		if (is_user_alive(players[i]) && players[i] != id)
		{
			pev(players[i], pev_origin, loc[locnum])
			locnum++
		}
	}
	
	num = 0
	while (num <= g_TotalSpawns)
	{
		//have we visited all the spawns yet?
		if (num == g_TotalSpawns)
			break;
		//get a random spawn
		n = random_num(0, g_TotalSpawns-1)
		//have we visited this spawn yet?
		if (!list[n])
		{
			//yes, set the flag to true, and inc the number of spawns we've visited
			list[n] = 1
			num++
		} 
		else 
		{
	        //this was a useless loop, so add to the infinite loop prevention counter
			total++;
			if (total > 100) // don't search forever
				break;
			continue;   //don't check again
		}

		new trace  = csdm_trace_hull(g_SpawnVecs[n], 1)
		
		if (trace)
			continue;
		
		if (locnum < 1)
		{
			final = n
			break
		}
		
		final = n
		for (x = 0; x < locnum; x++)
		{
			new Float:distance = get_distance_f(g_SpawnVecs[n], loc[x]);
			if (distance < 250.0)
			{
				//invalidate
				final = -1
				break;
			}
		}
		
		if (final != -1)
			break
	}
	
	if (final != -1)
	{
		new Float:mins[3], Float:maxs[3]
		pev(id, pev_mins, mins)
		pev(id, pev_maxs, maxs)
		engfunc(EngFunc_SetSize, id, mins, maxs)
		engfunc(EngFunc_SetOrigin, id, g_SpawnVecs[final])
		set_pev(id, pev_fixangle, 1)
		set_pev(id, pev_angles, g_SpawnAngles[final])
		set_pev(id, pev_v_angle, g_SpawnVAngles[final])
		set_pev(id, pev_fixangle, 1)
		
		return PLUGIN_HANDLED
	}

	return PLUGIN_CONTINUE
}

public spawn_Team(id, num)
{
	#if defined TEAM_CLOSE_DEBUG
	log_amx("%i: starting spawn_Team_new  num %i", id, num)
	#endif
	
	if (num == 1 || !g_isalive[id])
		return PLUGIN_CONTINUE
	
	new bool:not_found_team, teamid, Float:final_origin[3], players[32], num
	not_found_team = true
	
	switch (fm_cs_get_user_team(id))
	{
		case FM_CS_TEAM_T:
		{
			get_players(players, num, "ae", "TERRORIST")
			
			if (num < 2)
			{
				return PLUGIN_CONTINUE
			}
		}
		case FM_CS_TEAM_CT:
		{
			get_players(players, num, "ae", "CT")
			
			if (num < 2)
			{
				return PLUGIN_CONTINUE
			}
		}
	}
	
	for(new tests = 0; tests < g_maxplayers; tests++)
	{
		if(!not_found_team)
		{
			#if defined TEAM_CLOSE_DEBUG
			log_amx("%i: teammate %i origin %f %f %f", id, teamid, final_origin[0], final_origin[1], final_origin[2])
			#endif
			
			break;
		}
		
		while ((teamid = players[random_num(0, num-1)]) == id) { }
		
		#if defined TEAM_CLOSE_DEBUG
		log_amx("%i: found teammate %i", id, teamid)
		#endif
		
		new Float:team_origin[3]
		pev(teamid, pev_origin, team_origin)
		
		#if defined TEAM_CLOSE_DEBUG
		log_amx("%i: teammate %i origin %f %f %f", id, teamid, team_origin[0], team_origin[1], team_origin[2])
		#endif
		
		switch(random(8))
		{
			case 0:
			{
				final_origin[0] = team_origin[0] - 32.5
				final_origin[1] = team_origin[1]
			}
			case 1:
			{
				final_origin[0] = team_origin[0] + 32.5
				final_origin[1] = team_origin[1]
			}
			case 2:
			{
				final_origin[0] = team_origin[0]
				final_origin[1] = team_origin[1] - 32.5
			}
			case 3:
			{
				final_origin[0] = team_origin[0]
				final_origin[1] = team_origin[1] + 32.5
			}
			case 4:
			{
				final_origin[0] = team_origin[0] - 32.5
				final_origin[1] = team_origin[1] - 32.5
			}
			case 5:
			{
				final_origin[0] = team_origin[0] - 32.5
				final_origin[1] = team_origin[1] + 32.5
			}
			case 6:
			{
				final_origin[0] = team_origin[0] + 32.5
				final_origin[1] = team_origin[1] + 32.5
			}
			case 7:
			{
				final_origin[0] = team_origin[0] + 32.5
				final_origin[1] = team_origin[1] - 32.5
			}
		}
		final_origin[2] = team_origin[2]
		
		new z
		while ((not_found_team = player_will_stuck(id, final_origin)) == true)
		{
			if (z >= 4)
				break;
			
			final_origin[2] = team_origin[2] + (++z*20)
		}
	}
	
	if(!not_found_team)
	{
		new ang[3], vang[3]
		pev(teamid, pev_angles, ang)
		pev(teamid, pev_v_angle, vang)
		
		engfunc(EngFunc_SetOrigin, id, final_origin)
		set_pev(id, pev_angles, ang)
		set_pev(id, pev_v_angle, vang)
		set_pev(id, pev_fixangle, 1)
		
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}

public spawn_Team_new(id, num)
{
	#if defined TEAM_PRESET_DEBUG
	log_amx("%i: starting spawn_Team_new  num %i", id, num)
	#endif
	
	if (g_TotalSpawns < 2 || num == 1 || !g_isalive[id])
		return PLUGIN_CONTINUE
	
	new players[32], num, inum, teammate, found_spawn, oldmate[32], n
	
	switch (fm_cs_get_user_team(id))
	{
		case FM_CS_TEAM_T:
		{
			get_players(players, num, "ae", "TERRORIST")
			
			if (num < 2)
			{
				set_task(0.1, "delayed_spawn", id)
				#if defined TEAM_PRESET_DEBUG
				log_amx("%i: to low Tnum %i, starting delayed spawn.", id, num)
				#endif
				
				return PLUGIN_CONTINUE
			}
		}
		case FM_CS_TEAM_CT:
		{
			get_players(players, num, "ae", "CT")
			
			if (num < 2)
			{
				set_task(0.1, "delayed_spawn", id)
				#if defined TEAM_PRESET_DEBUG
				log_amx("i: to low CTnum %i, starting delayed spawn.", id, num)
				#endif
				
				return PLUGIN_CONTINUE
			}
		}
	}
	
	for (new check = 1; check < num; check++)
	{
		if (found_spawn)
			break;
		
		n = random_num(0, num-1)
		while (players[n] == id || oldmate[n] != 0)
		{
			n = random_num(0, num-1)
		}
		oldmate[n] = teammate = players[n]
		
		#if defined TEAM_PRESET_DEBUG
		for (new i = 0; i < 32; i++)
			if (oldmate[i] != 0)
				log_amx("%i: check %i, teammate %i, oldmate %i", id, check, teammate, oldmate[i])
		#endif
		
		new Float:origin[3]
		pev(teammate, pev_origin, origin)
		
		for (inum = 0; inum < g_TotalSpawns; inum++)
		{
			if (player_will_stuck(id, g_SpawnVecs[inum]))
				continue;
			
			new Float:distance
			distance = get_distance_f(origin, g_SpawnVecs[inum])
			if (g_mindis <= distance <= g_maxdis)
			{
				found_spawn = 1
				break;
			}
		}
	}
	
	if (found_spawn)
	{
		engfunc(EngFunc_SetOrigin, id, g_SpawnVecs[inum])
		set_pev(id, pev_angles, g_SpawnAngles[inum])
		set_pev(id, pev_v_angle, g_SpawnVAngles[inum])
		set_pev(id, pev_fixangle, 1)
		#if defined TEAM_PRESET_DEBUG
		log_amx("%i: found valid spawnpoint, inum %i, teammate %i", id, inum, teammate)
		#endif
		
		return PLUGIN_HANDLED
	}
	else
	{
		set_task(0.1, "delayed_spawn", id)
		#if defined TEAM_PRESET_DEBUG
		log_amx("%i: invalid spawnpoint, inum %i, teammate %i", id, inum, teammate)
		#endif
		
		return PLUGIN_CONTINUE
	}
	return PLUGIN_CONTINUE
}

public delayed_spawn(id)
{
	#if defined TEAM_PRESET_DEBUG
	log_amx("%i: set delayed_spawn (end)", id)
	#endif
	
	if (g_isalive[id])
		spawn_Preset(id, 0)
}

stock bool:player_will_stuck(id, Float:origin[3])
{
	engfunc(EngFunc_TraceHull, origin, origin, 0, HULL_HUMAN, id, 0)
	
	if (get_tr2(0, TR_StartSolid) || get_tr2(0, TR_AllSolid) || !get_tr2(0, TR_InOpen))
		return true;
	
	return false;
}

stock fm_cs_get_user_team(id)
{
	return get_pdata_int(id, OFFSET_CSTEAMS, OFFSET_LINUX);
}
