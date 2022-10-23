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

const SNIPER_BITSUM = (1<<CSW_SCOUT)|(1<<CSW_SG550)|(1<<CSW_AWP)|(1<<CSW_G3SG1);

new g_iTeamID[DM_MAX_PLAYERS+1] = { 0, ... };
new Float:g_fDeathOrigin[DM_MAX_PLAYERS+1][3];

#if AMXX_VERSION_NUM < 183
new g_iMaxPlayers = 0;
#endif
new cvar_fRange = 0;
new cvar_iSniper = 0;
new cvar_iDeathSpawn = 0;

new bs_IsAlive = 0;
new bs_IsFoundSpawn = 0;
new bs_IsDeathDucking = 0;

#define get_bitsum(%1,%2)   (%1 &   (1<<((%2-1)&31)))
#define add_bitsum(%1,%2)    %1 |=  (1<<((%2-1)&31))
#define del_bitsum(%1,%2)    %1 &= ~(1<<((%2-1)&31))

/* -Init---------------------------------------------------------------------- */

public DM_OnModStatus(status)
{
	register_plugin("DM: Spawn Team Close 2", DM_VERSION_STR_LONG, "schmurgel1983");
	
	if (status) state enabled;
	else state deactivated;
}

public plugin_init() <deactivated> {}
public plugin_init() <enabled>
{
	if (DM_IsFreeForAllEnabled() || !DM_RegisterSpawnMode("team_close2", "DM_Spawn_TeamClose2"))
	{
		state deactivated;
		return;
	}
	
	cvar_fRange = register_cvar("dm_team_close2_range", "64.0");
	cvar_iSniper = register_cvar("dm_team_close2_sniper", "1");
	cvar_iDeathSpawn = register_cvar("dm_team_close2_death_spawn", "1");
	
	register_message(get_user_msgid("TeamInfo"), "Msg_TeamInfo");
	
	#if AMXX_VERSION_NUM < 183
	g_iMaxPlayers =  get_maxplayers();
	#endif
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
	
	// Death spawn
	pev(victim, pev_origin, g_fDeathOrigin[victim]);
	if (pev(victim, pev_flags) & FL_DUCKING) add_bitsum(bs_IsDeathDucking, victim);
	else del_bitsum(bs_IsDeathDucking, victim);
}

/* --------------------------------------------------------------------------- */

public DM_Spawn_TeamClose2(id, freezetime, roundend)
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
	}
	
	if (!num)
	{
		// Death spawn
		if (get_pcvar_num(cvar_iDeathSpawn) && g_fDeathOrigin[id][0] != 0.0 && g_fDeathOrigin[id][1] != 0.0 && g_fDeathOrigin[id][2] != 0.0)
		{
			if (!is_hull_vacant(g_fDeathOrigin[id], get_bitsum(bs_IsDeathDucking, id) ? HULL_HEAD : HULL_HUMAN))
				return;
			
			if (get_bitsum(bs_IsDeathDucking, id)) set_pev(id, pev_flags, pev(id, pev_flags) | FL_DUCKING);
			engfunc(EngFunc_SetOrigin, id, g_fDeathOrigin[id]);
			set_pev(id, pev_fixangle, 1);
		}
		return;
	}
	
	static Float:range; range = floatclamp(get_pcvar_float(cvar_fRange), 36.0, 256.0);
	static sniper; sniper = !!get_pcvar_num(cvar_iSniper);
	
	del_bitsum(bs_IsFoundSpawn, id);
	
	new Float:distance[32];
	DM_GetDistance(id, players, num, distance);
	
	for (i = 0; i < num; i++)
	{
		#define DM_DISTANCE 99999.0
		
		new Float:fClosestDistance = DM_DISTANCE, iClosestID, iMateIndex;
		for (new iMate = 0; iMate < num; iMate++)
		{
			if (distance[iMate] < fClosestDistance)
			{
				fClosestDistance = distance[iMate];
				iClosestID = players[iMate];
				iMateIndex = iMate;
			}
		}
		
		// Check if sniper
		if (!sniper && (pev(iClosestID, pev_weapons) & SNIPER_BITSUM))
		{
			distance[iMateIndex] = DM_DISTANCE;
			continue;
		}
		
		// Get some data
		static Float:Origin[3], Float:Angles[3], Float:V_Angle[3], iDucking;
		pev(iClosestID, pev_origin, Origin);
		pev(iClosestID, pev_angles, Angles);
		pev(iClosestID, pev_v_angle, V_Angle);
		iDucking = (pev(iClosestID, pev_flags) & FL_DUCKING);
		
		#define DM_Vector_Copy(%0,%1) (%1[0] = %0[0], %1[1] = %0[1], %1[2] = %0[2])
		
		// Get forward vector
		static Float:Vec_V_Angle[3], Float:Vec_Forward[3];
		DM_Vector_Copy(V_Angle, Vec_V_Angle);
		engfunc(EngFunc_MakeVectors, Vec_V_Angle);
		global_get(glb_v_forward, Vec_V_Angle);
		DM_Vector_Copy(Vec_V_Angle, Vec_Forward);
		
		#define DM_Vector_MA(%0,%1,%2,%3) (%3[0] = %1[0] * %2 + %0[0], %3[1] = %1[1] * %2 + %0[1], %3[2] = %0[2] - 60.0)
		
		// 1 spawn
		static Float:Vec_Calculator[3];
		DM_Vector_MA(Origin, Vec_Forward, -range, Vec_Calculator);
		if (DM_DoSpawning(id, Origin, Vec_Calculator, Angles, V_Angle, iDucking))
			break;
		
		// Get right vector
		static Float:Vec_Right[3];
		DM_Vector_Copy(V_Angle, Vec_V_Angle);
		engfunc(EngFunc_MakeVectors, Vec_V_Angle);
		global_get(glb_v_right, Vec_V_Angle);
		DM_Vector_Copy(Vec_V_Angle, Vec_Right);
		
		#define DM_Vector_MAMA(%0,%1,%2,%3,%4,%5) (%5[0] = %1[0] * (%2) + %3[0] * (%4) + %0[0], %5[1] = %1[1] * (%2) + %3[1] * (%4) + %0[1], %5[2] = %0[2] - 60.0)
		
		// 2 spawn
		DM_Vector_MAMA(Origin, Vec_Forward, -range, Vec_Right, range, Vec_Calculator);
		if (DM_DoSpawning(id, Origin, Vec_Calculator, Angles, V_Angle, iDucking))
			break;
		
		// 3 spawn
		DM_Vector_MAMA(Origin, Vec_Forward, -range, Vec_Right, -range, Vec_Calculator);
		if (DM_DoSpawning(id, Origin, Vec_Calculator, Angles, V_Angle, iDucking))
			break;
		
		// 4 spawn
		DM_Vector_MAMA(Origin, Vec_Forward, -range*2, Vec_Right, range/2, Vec_Calculator);
		if (DM_DoSpawning(id, Origin, Vec_Calculator, Angles, V_Angle, iDucking))
			break;
		
		// 5 spawn
		DM_Vector_MAMA(Origin, Vec_Forward, -range*2, Vec_Right, -range/2, Vec_Calculator);
		if (DM_DoSpawning(id, Origin, Vec_Calculator, Angles, V_Angle, iDucking))
			break;
		
		// 6 spawn
		DM_Vector_MAMA(Origin, Vec_Forward, -range*2, Vec_Right, range/2 + range, Vec_Calculator);
		if (DM_DoSpawning(id, Origin, Vec_Calculator, Angles, V_Angle, iDucking))
			break;
		
		// 7 spawn
		DM_Vector_MAMA(Origin, Vec_Forward, -range*2, Vec_Right, -range/2 - range, Vec_Calculator);
		if (DM_DoSpawning(id, Origin, Vec_Calculator, Angles, V_Angle, iDucking))
			break;
		
		// mate already checked
		distance[iMateIndex] = DM_DISTANCE;
	}
	
	// Death spawn
	if (!get_bitsum(bs_IsFoundSpawn, id) && get_pcvar_num(cvar_iDeathSpawn) && g_fDeathOrigin[id][0] != 0.0 && g_fDeathOrigin[id][1] != 0.0 && g_fDeathOrigin[id][2] != 0.0)
	{
		if (!is_hull_vacant(g_fDeathOrigin[id], get_bitsum(bs_IsDeathDucking, id) ? HULL_HEAD : HULL_HUMAN))
			return;
		
		if (get_bitsum(bs_IsDeathDucking, id)) set_pev(id, pev_flags, pev(id, pev_flags) | FL_DUCKING);
		engfunc(EngFunc_SetOrigin, id, g_fDeathOrigin[id]);
		set_pev(id, pev_fixangle, 1);
	}
}

DM_GetDistance(const id, const players[], const num, Float:distance[])
{
	static i, Float:Origin[3];
	for (i = 0; i < num; i++)
	{
		pev(players[i], pev_origin, Origin);
		distance[i] = get_distance_f(g_fDeathOrigin[id], Origin);
	}
	return true;
}

DM_DoSpawning(id, const Float:Start[3], Float:End[3], const Float:Angles[3], const Float:V_Angle[3], const Ducking)
{
	new do_z = -3;
	do
	{
		if (dm_is_visible(id, Start, End) && is_hull_vacant(End, Ducking ? HULL_HEAD : HULL_HUMAN))
		{
			if (Ducking) set_pev(id, pev_flags, pev(id, pev_flags) | FL_DUCKING);
			engfunc(EngFunc_SetOrigin, id, End);
			set_pev(id, pev_angles, Angles);
			set_pev(id, pev_v_angle, V_Angle);
			set_pev(id, pev_fixangle, 1);
			
			add_bitsum(bs_IsFoundSpawn, id);
			
			return true;
		}
		do_z++;
		End[2] += 20.0;
	}
	while (do_z <= 3);
	
	return false;
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

stock bool:dm_is_visible(index, const Float:start[3], const Float:end[3])
{
	engfunc(EngFunc_TraceLine, start, end, IGNORE_MONSTERS, index, 0);
	
	static Float:fraction;
	get_tr2(0, TR_flFraction, fraction);
	if (fraction == 1.0)
		return true;
	
	return false;
}

stock is_hull_vacant(const Float:origin[3], const hull)
{
	engfunc(EngFunc_TraceHull, origin, origin, 0, hull, 0, 0);
	
	if (!get_tr2(0, TR_StartSolid) && !get_tr2(0, TR_AllSolid) && get_tr2(0, TR_InOpen))
		return true;
	
	return false;
}
