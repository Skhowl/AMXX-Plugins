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

#include <dm_core>
#include <dm_spawn>
#include <dm_ffa>

/* --------------------------------------------------------------------------- */

#define MAX_TESTS 8
#define MAX_SPAWNS 64

const SNIPER_BITSUM = (1<<CSW_SCOUT)|(1<<CSW_SG550)|(1<<CSW_AWP)|(1<<CSW_G3SG1);

/* --------------------------------------------------------------------------- */

new g_iTeamID[DM_MAX_PLAYERS+1] = { 0, ... };

new Float:g_fDeathOrigin[DM_MAX_PLAYERS+1][3];
new Float:g_fDeathAngles[DM_MAX_PLAYERS+1][3];
new Float:g_fDeathViewAngels[DM_MAX_PLAYERS+1][3];

new Float:g_fBombOrigin[3];

new Float:g_fOrigin[MAX_SPAWNS][3];
new Float:g_fSpawnAngles[MAX_SPAWNS][3];
new Float:g_fSpawnViewAngles[MAX_SPAWNS][3];
new g_iSpawnTeamID[MAX_SPAWNS];
new g_iTotalSpawns = 0;

#if AMXX_VERSION_NUM < 183
new g_iMaxPlayers = 0;
#endif
new bool:g_bBombPlanted = false;
new cvar_iType = 0;
new cvar_fDistance = 0;
new cvar_fMin = 0;
new cvar_fMax = 0;
new cvar_iFixMinMax = 0;
new cvar_iSniper = 0;
new cvar_iDeathSpawn = 0;
new cvar_iBombSpawn = 0;

new bs_IsAlive = 0;
new bs_IsFoundSpawn = 0;
new bs_IsDeathDucking = 0;

#define get_bitsum(%1,%2)   (%1 &   (1<<((%2-1)&31)))
#define add_bitsum(%1,%2)    %1 |=  (1<<((%2-1)&31))
#define del_bitsum(%1,%2)    %1 &= ~(1<<((%2-1)&31))

enum (*=2)
{
	DeathSpawn_NoneTeammates = 1,	//  +1 = 1
	DeathSpawn_NoTeammateOnBomb_T,	//  +2 = 3
	DeathSpawn_NoTeammateOnBomb_CT,	//  +4 = 7
	DeathSpawn_SkippedSnipers,		//  +8 = 15
	DeathSpawn_SkippedDistance,		// +16 = 31
	DeathSpawn_SpawnOnPreset,		// +32 = 63
	DeathSpawn_Died					// +64 = 127
}

new g_iCachedType = 0;
new Float:g_fCachedDistance = 0.0;
new Float:g_fCachedMin = 0.0;
new Float:g_fCachedMax = 0.0;
new g_iCachedFixMinMax = 0;
new g_iCachedSniper = 0;
new g_iCachedDeathSpawn = 0;
new g_iCachedBombSpawn = 0;

#define DeathSpawnHasFlag(%1)	(g_iCachedDeathSpawn & %1)

/* -Init---------------------------------------------------------------------- */

public DM_OnModStatus(status)
{
	register_plugin("DM: Spawn Team Close", DM_VERSION_STR_LONG, "schmurgel1983");
	
	if (status) state enabled;
	else state deactivated;
}

public plugin_init() <deactivated> {}
public plugin_init() <enabled>
{
	if (DM_IsFreeForAllEnabled() || !DM_RegisterSpawnMode("team_close", "DM_Spawn_TeamClose"))
	{
		state deactivated;
		return;
	}
	
	cvar_iType = register_cvar("dm_team_close_type", "0");
	cvar_fDistance = register_cvar("dm_team_close_distance", "1024");
	cvar_fMin = register_cvar("dm_team_close_min", "64");
	cvar_fMax = register_cvar("dm_team_close_max", "256");
	cvar_iFixMinMax = register_cvar("dm_team_close_fix_min_max", "1");
	cvar_iSniper = register_cvar("dm_team_close_sniper", "0");
	cvar_iDeathSpawn = register_cvar("dm_team_close_death_spawn", "0");
	cvar_iBombSpawn = register_cvar("dm_team_close_bomb_spawn", "0");
	
	register_event("HLTV", "EventRoundStart", "a", "1=0", "2=0");
	
	register_message(get_user_msgid("TeamInfo"), "Msg_TeamInfo");
	
	#if AMXX_VERSION_NUM < 183
	g_iMaxPlayers =  get_maxplayers();
	#endif
}

public plugin_cfg() <deactivated> {}
public plugin_cfg() <enabled>
{
	EventRoundStart();
	
	if (DeathSpawnHasFlag(DeathSpawn_SpawnOnPreset))
	{
		new map[32], path[64];
		get_mapname(map, charsmax(map));
		get_configsdir(path, charsmax(path));
		format(path, charsmax(path), "%s\csdm\%s.spawns.cfg", path, map);
		
		if (!file_exists(path))
		{
			goto DM_NoSpawnFile;
		}
		
		new file = fopen(path, "rt");
		if (!file)
		{
			log_amx("Cannot open spawn points file: %s", path);
			goto DM_NoSpawnFile;
		}
		
		new linedata[128], pos[10][13];
		while (!feof(file))
		{
			if (g_iTotalSpawns >= MAX_SPAWNS)
			{
				log_amx("Total spawns (%d) reached.", MAX_SPAWNS);
				break;
			}
			
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
		
		// Label
		DM_NoSpawnFile:
		
		if (!g_iTotalSpawns)
		{
			set_pcvar_num(cvar_iDeathSpawn, get_pcvar_num(cvar_iDeathSpawn) - DeathSpawn_SpawnOnPreset);
			g_iCachedDeathSpawn -= DeathSpawn_SpawnOnPreset;
		}
	}
}

/* --------------------------------------------------------------------------- */

public client_putinserver(id) <deactivated> {}
public client_putinserver(id) <enabled>
{
	g_fDeathOrigin[id][0] = g_fDeathOrigin[id][1] = g_fDeathOrigin[id][2] = 0.0;
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
	
	pev(victim, pev_origin, g_fDeathOrigin[victim]);
	
	// Death spawn
	if (g_iCachedDeathSpawn)
	{
		if (pev(victim, pev_flags) & FL_DUCKING) add_bitsum(bs_IsDeathDucking, victim);
		else del_bitsum(bs_IsDeathDucking, victim);
		
		pev(victim, pev_angles, g_fDeathAngles[victim]);
		pev(victim, pev_v_angle, g_fDeathViewAngels[victim]);
	}
}

/* --------------------------------------------------------------------------- */

public DM_BombPlanted(id, roundend) <deactivated> {}
public DM_BombPlanted(id, roundend) <enabled>
{
	if (g_iCachedBombSpawn) pev(id, pev_origin, g_fBombOrigin);
	
	g_bBombPlanted = true;
}

/* -Events-------------------------------------------------------------------- */

public EventRoundStart()
{
	g_iCachedType = clamp(get_pcvar_num(cvar_iType), 0, 2);
	g_fCachedDistance = floatclamp(get_pcvar_float(cvar_fDistance), 0.0, 8192.0);
	g_fCachedMax = floatclamp(get_pcvar_float(cvar_fMax), 32.5, 8192.0);
	g_fCachedMin = floatclamp(get_pcvar_float(cvar_fMin), 32.5, g_fCachedMax);
	g_iCachedFixMinMax = !!get_pcvar_num(cvar_iFixMinMax);
	g_iCachedSniper = !!get_pcvar_num(cvar_iSniper);
	g_iCachedDeathSpawn = clamp(get_pcvar_num(cvar_iDeathSpawn), 0, 127); // look line: 84
	g_iCachedBombSpawn = !!get_pcvar_num(cvar_iBombSpawn);
	
	g_bBombPlanted = false;
}

/* --------------------------------------------------------------------------- */

public DM_Spawn_TeamClose(id, freezetime, roundend)
{
	if (freezetime || roundend || !get_bitsum(bs_IsAlive, id))
		return;
	
	new players[32], num, i;
	
	switch (g_iTeamID[id])
	{
		case 1:
		{
			#if AMXX_VERSION_NUM < 183
			for (i = 1; i <= g_iMaxPlayers; i++)
			#else
			for (i = 1; i <= MaxClients; i++)
			#endif
			{
				if (i == id) continue;
				if (get_bitsum(bs_IsAlive, i) && g_iTeamID[i] == DM_TEAM_T)
				{
					players[num] = i;
					num++;
				}
			}
		}
		case 2:
		{
			#if AMXX_VERSION_NUM < 183
			for (i = 1; i <= g_iMaxPlayers; i++)
			#else
			for (i = 1; i <= MaxClients; i++)
			#endif
			{
				if (i == id) continue;
				if (get_bitsum(bs_IsAlive, i) && g_iTeamID[i] == DM_TEAM_CT)
				{
					players[num] = i;
					num++;
				}
			}
		}
		default: return;
	}
	
	del_bitsum(bs_IsFoundSpawn, id);
	
	// Team is death
	if (!num)
	{
		// Death spawn
		if (!g_bBombPlanted)
		{
			if (!DeathSpawnHasFlag(DeathSpawn_NoneTeammates))
				goto DM_NoTeammatesRequired;
		}
		else
		{
			switch (g_iTeamID[id])
			{
				case DM_TEAM_T:
				{
					if (!DeathSpawnHasFlag(DeathSpawn_NoTeammateOnBomb_T))
						goto DM_NoTeammatesRequired;
				}
				case DM_TEAM_CT:
				{
					if (!DeathSpawnHasFlag(DeathSpawn_NoTeammateOnBomb_CT))
						goto DM_NoTeammatesRequired;
				}
				default: return;
			}
		}
		
		if (g_fDeathOrigin[id][0] != 0.0 && g_fDeathOrigin[id][1] != 0.0 && g_fDeathOrigin[id][2] != 0.0)
		{
			if (!is_hull_vacant(g_fDeathOrigin[id], get_bitsum(bs_IsDeathDucking, id) ? HULL_HEAD : HULL_HUMAN))
				goto DM_NoTeammatesRequired;
			
			if (get_bitsum(bs_IsDeathDucking, id)) set_pev(id, pev_flags, pev(id, pev_flags) | FL_DUCKING);
			engfunc(EngFunc_SetOrigin, id, g_fDeathOrigin[id]);
			set_pev(id, pev_angles, g_fDeathAngles[id]);
			set_pev(id, pev_v_angle, g_fDeathViewAngels[id]);
			set_pev(id, pev_fixangle, 1);
		}
		
		return;
	}
	
	new Float:fDistance[32];
	DM_GetUserDistance(id, players, num, fDistance);
	
	new iTeamID, iDucking, iTest, iZ;
	new Float:fRandomOrigin[2], Float:fFinalOrigin[3], Float:fTeamOrigin[3], bSkipped[DM_MAX_PLAYERS+1];
	
	#define DM_DISTANCE 99999.0
	#define DM_DISTANCE_NULL 0.0
	#define DM_Vector_Copy(%0,%1) (%1[0] = %0[0], %1[1] = %0[1], %1[2] = %0[2])
	
	switch (g_iCachedType)
	{
		case 0: // Random
		{
			new iNum = random(num);
			
			for (i = iNum + 1; /* no condition */; i++)
			{
				if (i >= num) i = 0;
				iTeamID = players[i];
				
				// Check sniper
				if (!g_iCachedSniper && (pev(iTeamID, pev_weapons) & SNIPER_BITSUM))
				{
					if (DeathSpawnHasFlag(DeathSpawn_SkippedSnipers)) bSkipped[iTeamID] = true;
					
					if (i == iNum) break;
					else continue;
				}
				
				// Check distance
				if (g_fCachedDistance > 32.5 && fDistance[i] > g_fCachedDistance)
				{
					if (DeathSpawnHasFlag(DeathSpawn_SkippedDistance)) bSkipped[iTeamID] = true;
					
					if (i == iNum) break;
					else continue;
				}
				
				pev(iTeamID, pev_origin, fTeamOrigin);
				iDucking = (pev(iTeamID, pev_flags) & FL_DUCKING);
				
				for (iTest = 0; iTest < MAX_TESTS; iTest++)
				{
					fRandomOrigin[0] = random(2) ? random_float(g_fCachedMin, g_fCachedMax) : random_float(-g_fCachedMin, -g_fCachedMax);
					fRandomOrigin[1] = random(2) ? random_float(g_fCachedMin, g_fCachedMax) : random_float(-g_fCachedMin, -g_fCachedMax);
					
					if (g_iCachedFixMinMax)
					{
						fFinalOrigin[0] = fTeamOrigin[0] + fRandomOrigin[0];
						fFinalOrigin[1] = fTeamOrigin[1] + fRandomOrigin[1];
						fFinalOrigin[2] = fTeamOrigin[2];
						
						engfunc(EngFunc_TraceLine, fTeamOrigin, fFinalOrigin, IGNORE_MONSTERS, id, 0);
						
						static Float:fraction;
						get_tr2(0, TR_flFraction, fraction);
						if (fraction < 1.0)
						{
							static Float:vTraceEnd[3], Float:vNormal[3];
							get_tr2(0, TR_vecEndPos, vTraceEnd);
							get_tr2(0, TR_vecPlaneNormal, vNormal);
							
							#define DM_Vector_MA(%0,%1,%2,%3) (%3[0] = %1[0] * %2 + %0[0], %3[1] = %1[1] * %2 + %0[1])
							
							DM_Vector_MA(vTraceEnd, vNormal, 32.5, fFinalOrigin);
						}
					}
					else
					{
						fFinalOrigin[0] = fTeamOrigin[0] + fRandomOrigin[0];
						fFinalOrigin[1] = fTeamOrigin[1] + fRandomOrigin[1];
						fFinalOrigin[2] = fTeamOrigin[2];
					}
					
					iZ = 0;
					do
					{
						if (dm_is_visible(id, fTeamOrigin, fFinalOrigin) && is_hull_vacant(fFinalOrigin, iDucking ? HULL_HEAD : HULL_HUMAN))
						{
							new Float:fAngle[3], Float:fViewAngle[3];
							pev(iTeamID, pev_angles, fAngle);
							pev(iTeamID, pev_v_angle, fViewAngle);
							
							if (iDucking) set_pev(id, pev_flags, pev(id, pev_flags) | FL_DUCKING);
							engfunc(EngFunc_SetOrigin, id, fFinalOrigin);
							set_pev(id, pev_angles, fAngle);
							set_pev(id, pev_v_angle, fViewAngle);
							set_pev(id, pev_fixangle, 1);
							
							add_bitsum(bs_IsFoundSpawn, id);
							
							i = iNum;
							iTest = MAX_TESTS;
							break;
						}
						fFinalOrigin[2] = fTeamOrigin[2] + (++iZ*20);
					}
					while (iZ < 4);
				}
				
				if (i == iNum) break;
			}
		}
		default: // closest & furthest
		{
			new iMateIndex, iMate;
			for (i = 0; i < num; i++)
			{
				switch (g_iCachedType)
				{
					case 1: // closest
					{
						new Float:fClosestDistance = DM_DISTANCE;
						for (iMate = 0; iMate < num; iMate++)
						{
							if (fDistance[iMate] < fClosestDistance)
							{
								fClosestDistance = fDistance[iMate];
								iTeamID = players[iMate];
								iMateIndex = iMate;
							}
						}
					}
					case 2: // furthest
					{
						new Float:fFurthestDistance = DM_DISTANCE_NULL;
						for (iMate = 0; iMate < num; iMate++)
						{
							if (fDistance[iMate] > fFurthestDistance)
							{
								fFurthestDistance = fDistance[iMate];
								iTeamID = players[iMate];
								iMateIndex = iMate;
							}
						}
					}
				}
				
				// Check sniper
				if (!g_iCachedSniper && (pev(iTeamID, pev_weapons) & SNIPER_BITSUM))
				{
					if (DeathSpawnHasFlag(DeathSpawn_SkippedSnipers)) bSkipped[iTeamID] = true;
					
					switch (g_iCachedType)
					{
						case 1: fDistance[iMateIndex] = DM_DISTANCE; // closest
						case 2: fDistance[iMateIndex] = DM_DISTANCE_NULL; // furthest
					}
					continue;
				}
				
				// Check distance
				if (g_fCachedDistance > 32.5 && fDistance[iMateIndex] > g_fCachedDistance)
				{
					if (DeathSpawnHasFlag(DeathSpawn_SkippedDistance)) bSkipped[iTeamID] = true;
					
					switch (g_iCachedType)
					{
						case 1: fDistance[iMateIndex] = DM_DISTANCE; // closest
						case 2: fDistance[iMateIndex] = DM_DISTANCE_NULL; // furthest
					}
					continue;
				}
				
				pev(iTeamID, pev_origin, fTeamOrigin);
				iDucking = (pev(iTeamID, pev_flags) & FL_DUCKING);
				
				for (iTest = 0; iTest < MAX_TESTS; iTest++)
				{
					fRandomOrigin[0] = random(2) ? random_float(g_fCachedMin, g_fCachedMax) : random_float(-g_fCachedMin, -g_fCachedMax);
					fRandomOrigin[1] = random(2) ? random_float(g_fCachedMin, g_fCachedMax) : random_float(-g_fCachedMin, -g_fCachedMax);
					
					if (g_iCachedFixMinMax)
					{
						fFinalOrigin[0] = fTeamOrigin[0] + fRandomOrigin[0];
						fFinalOrigin[1] = fTeamOrigin[1] + fRandomOrigin[1];
						fFinalOrigin[2] = fTeamOrigin[2];
						
						engfunc(EngFunc_TraceLine, fTeamOrigin, fFinalOrigin, IGNORE_MONSTERS, id, 0);
						
						static Float:fraction;
						get_tr2(0, TR_flFraction, fraction);
						if (fraction < 1.0)
						{
							static Float:vTraceEnd[3], Float:vNormal[3];
							get_tr2(0, TR_vecEndPos, vTraceEnd);
							get_tr2(0, TR_vecPlaneNormal, vNormal);
							
							#define DM_Vector_MA(%0,%1,%2,%3) (%3[0] = %1[0] * %2 + %0[0], %3[1] = %1[1] * %2 + %0[1])
							
							DM_Vector_MA(vTraceEnd, vNormal, 32.5, fFinalOrigin);
						}
					}
					else
					{
						fFinalOrigin[0] = fTeamOrigin[0] + fRandomOrigin[0];
						fFinalOrigin[1] = fTeamOrigin[1] + fRandomOrigin[1];
						fFinalOrigin[2] = fTeamOrigin[2];
					}
					
					iZ = 0;
					do
					{
						if (dm_is_visible(id, fTeamOrigin, fFinalOrigin) && is_hull_vacant(fFinalOrigin, iDucking ? HULL_HEAD : HULL_HUMAN))
						{
							new Float:fAngle[3], Float:fViewAngle[3];
							pev(iTeamID, pev_angles, fAngle);
							pev(iTeamID, pev_v_angle, fViewAngle);
							
							if (iDucking) set_pev(id, pev_flags, pev(id, pev_flags) | FL_DUCKING);
							engfunc(EngFunc_SetOrigin, id, fFinalOrigin);
							set_pev(id, pev_angles, fAngle);
							set_pev(id, pev_v_angle, fViewAngle);
							set_pev(id, pev_fixangle, 1);
							
							add_bitsum(bs_IsFoundSpawn, id);
							
							i = num;
							iTest = MAX_TESTS;
							break;
						}
						fFinalOrigin[2] = fTeamOrigin[2] + (++iZ*20);
					}
					while (iZ < 4);
				}
				
				// mate already checked
				switch (g_iCachedType)
				{
					case 1: fDistance[iMateIndex] = DM_DISTANCE; // closest
					case 2: fDistance[iMateIndex] = DM_DISTANCE_NULL; // furthest
				}
			}
		}
	}
	
	// Check skipped players
	if (g_iCachedDeathSpawn && !get_bitsum(bs_IsFoundSpawn, id))
	{
		new iNum = random(num);
		
		for (i = iNum + 1; /* no condition */; i++)
		{
			if (i >= num) i = 0;
			iTeamID = players[i];
			
			// Not skipped
			if (!bSkipped[iTeamID])
			{
				if (i == iNum) break;
				else continue;
			}
			
			pev(iTeamID, pev_origin, fTeamOrigin);
			iDucking = (pev(iTeamID, pev_flags) & FL_DUCKING);
			
			for (iTest = 0; iTest < MAX_TESTS; iTest++)
			{
				fRandomOrigin[0] = random(2) ? random_float(g_fCachedMin, g_fCachedMax) : random_float(-g_fCachedMin, -g_fCachedMax);
				fRandomOrigin[1] = random(2) ? random_float(g_fCachedMin, g_fCachedMax) : random_float(-g_fCachedMin, -g_fCachedMax);
				
				if (g_iCachedFixMinMax)
				{
					fFinalOrigin[0] = fTeamOrigin[0] + fRandomOrigin[0];
					fFinalOrigin[1] = fTeamOrigin[1] + fRandomOrigin[1];
					fFinalOrigin[2] = fTeamOrigin[2];
					
					engfunc(EngFunc_TraceLine, fTeamOrigin, fFinalOrigin, IGNORE_MONSTERS, id, 0);
					
					static Float:fraction;
					get_tr2(0, TR_flFraction, fraction);
					if (fraction < 1.0)
					{
						static Float:vTraceEnd[3], Float:vNormal[3];
						get_tr2(0, TR_vecEndPos, vTraceEnd);
						get_tr2(0, TR_vecPlaneNormal, vNormal);
						
						#define DM_Vector_MA(%0,%1,%2,%3) (%3[0] = %1[0] * %2 + %0[0], %3[1] = %1[1] * %2 + %0[1])
						
						DM_Vector_MA(vTraceEnd, vNormal, 32.5, fFinalOrigin);
					}
				}
				else
				{
					fFinalOrigin[0] = fTeamOrigin[0] + fRandomOrigin[0];
					fFinalOrigin[1] = fTeamOrigin[1] + fRandomOrigin[1];
					fFinalOrigin[2] = fTeamOrigin[2];
				}
				
				iZ = 0;
				do
				{
					if (dm_is_visible(id, fTeamOrigin, fFinalOrigin) && is_hull_vacant(fFinalOrigin, iDucking ? HULL_HEAD : HULL_HUMAN))
					{
						new Float:fAngle[3], Float:fViewAngle[3];
						pev(iTeamID, pev_angles, fAngle);
						pev(iTeamID, pev_v_angle, fViewAngle);
						
						if (iDucking) set_pev(id, pev_flags, pev(id, pev_flags) | FL_DUCKING);
						engfunc(EngFunc_SetOrigin, id, fFinalOrigin);
						set_pev(id, pev_angles, fAngle);
						set_pev(id, pev_v_angle, fViewAngle);
						set_pev(id, pev_fixangle, 1);
						
						add_bitsum(bs_IsFoundSpawn, id);
						
						i = iNum;
						iTest = MAX_TESTS;
						break;
					}
					fFinalOrigin[2] = fTeamOrigin[2] + (++iZ*20);
				}
				while (iZ < 4);
			}
			
			if (i == iNum) break;
		}
	}
	
	// Label
	DM_NoTeammatesRequired:
	
	// Spawn on Preset's
	if (DeathSpawnHasFlag(DeathSpawn_SpawnOnPreset) && !get_bitsum(bs_IsFoundSpawn, id))
	{
		new Float:fSpawnDistance[MAX_SPAWNS];
		DM_GetSpawnDistance(id, g_iTotalSpawns, fSpawnDistance);
		
		new iSpawnIndex, iSpawn;
		for (i = 0; i < g_iTotalSpawns; i++)
		{
			new Float:fClosestDistance = DM_DISTANCE;
			for (iSpawn = 0; iSpawn < g_iTotalSpawns; iSpawn++)
			{
				if (fSpawnDistance[iSpawn] < fClosestDistance)
				{
					fClosestDistance = fSpawnDistance[iSpawn];
					iSpawnIndex = iSpawn;
				}
			}
			
			if (is_hull_vacant(g_fOrigin[iSpawnIndex], HULL_HUMAN))
			{
				engfunc(EngFunc_SetOrigin, id, g_fOrigin[iSpawnIndex]);
				set_pev(id, pev_angles, g_fSpawnAngles[iSpawnIndex]);
				set_pev(id, pev_v_angle, g_fSpawnViewAngles[iSpawnIndex]);
				set_pev(id, pev_fixangle, 1);
				
				add_bitsum(bs_IsFoundSpawn, id);
				
				break;
			}
			
			// Spawn already checked
			fSpawnDistance[iSpawnIndex] = DM_DISTANCE;
		}
	}
	
	// Death spawn
	if (num && DeathSpawnHasFlag(DeathSpawn_Died) && !get_bitsum(bs_IsFoundSpawn, id))
	{
		if (g_fDeathOrigin[id][0] != 0.0 && g_fDeathOrigin[id][1] != 0.0 && g_fDeathOrigin[id][2] != 0.0)
		{
			if (!is_hull_vacant(g_fDeathOrigin[id], get_bitsum(bs_IsDeathDucking, id) ? HULL_HEAD : HULL_HUMAN))
				return;
			
			if (get_bitsum(bs_IsDeathDucking, id)) set_pev(id, pev_flags, pev(id, pev_flags) | FL_DUCKING);
			engfunc(EngFunc_SetOrigin, id, g_fDeathOrigin[id]);
			set_pev(id, pev_angles, g_fDeathAngles[id]);
			set_pev(id, pev_v_angle, g_fDeathViewAngels[id]);
			set_pev(id, pev_fixangle, 1);
		}
	}
}

DM_GetUserDistance(const id, const players[], const num, Float:fDistance[])
{
	static i, Float:Origin[3];
	
	if (g_iCachedBombSpawn && g_bBombPlanted)
	{
		for (i = 0; i < num; i++)
		{
			pev(players[i], pev_origin, Origin);
			fDistance[i] = get_distance_f(g_fBombOrigin, Origin);
		}
	}
	else
	{
		for (i = 0; i < num; i++)
		{
			pev(players[i], pev_origin, Origin);
			fDistance[i] = get_distance_f(g_fDeathOrigin[id], Origin);
		}
	}
	return true;
}

DM_GetSpawnDistance(const id, const num, Float:fSpawnDistance[])
{
	static i;
	for (i = 0; i < num; i++)
	{
		fSpawnDistance[i] = get_distance_f(g_fDeathOrigin[id], g_fOrigin[i]);
	}
	return true;
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

stock bool:dm_is_visible(const index, const Float:start[3], const Float:end[3])
{
	if (g_iCachedFixMinMax)
		return true;
	
	engfunc(EngFunc_TraceLine, start, end, IGNORE_MONSTERS, index, 0);
	
	static Float:fraction;
	get_tr2(0, TR_flFraction, fraction);
	if (fraction == 1.0)
		return true;
	
	return false;
}

stock bool:is_hull_vacant(const Float:origin[3], const hull)
{
	engfunc(EngFunc_TraceHull, origin, origin, 0, hull, 0, 0);
	
	if (!get_tr2(0, TR_StartSolid) && !get_tr2(0, TR_AllSolid) && get_tr2(0, TR_InOpen))
		return true;
	
	return false;
}
