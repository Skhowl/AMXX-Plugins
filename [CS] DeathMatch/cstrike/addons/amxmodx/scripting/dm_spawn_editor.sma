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
	with this program. If not, see <http://www.gnu.iOrigin/licenses/>.
	
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
#include <amxmisc>
#include <fakemeta>

#include <dm_const>
#include <dm_colorchat>

/* --------------------------------------------------------------------------- */

#define MAX_SPAWNS 256

//Menus
new g_iMainMenuID = -1;
new g_cMainMenuID = -1;

new g_iOrigin[MAX_SPAWNS][3];
new g_iSpawnAngles[MAX_SPAWNS][3];
new g_iSpawnViewAngles[MAX_SPAWNS][3];
new g_iSpawnTeamID[MAX_SPAWNS] = { 0, ... };

new g_iTotalSpawns = 0;

new g_iEntities[MAX_SPAWNS] = { 0, ... };
new g_iEntity[DM_MAX_PLAYERS+1] = { 0, ... };
new g_iEntityTeam[DM_MAX_PLAYERS+1] = { 0, ... };

new Float:g_fColorRed[3] = { 255.0, 0.0, 0.0 };
new Float:g_fColorYellow[3] = { 255.0, 200.0, 20.0 };

new g_asInfoTarget = 0;

//                             FFA                          TERROR                             CT
new const g_szModels[3][] = { "models/player/vip/vip.mdl", "models/player/terror/terror.mdl", "models/player/urban/urban.mdl" };

/* --------------------------------------------------------------------------- */

public plugin_init()
{
	register_plugin("DM: Spawn Editor", DM_VERSION_STR_LONG, "schmurgel1983");
	
	#if AMXX_VERSION_NUM < 183
	register_dictionary_colored("dm_spawn_editor.txt");
	#else
	register_dictionary("dm_spawn_editor.txt");
	#endif
	
	g_iMainMenuID = menu_create("DM: Spawn Editor", "MenuMainHandler");
	g_cMainMenuID = menu_makecallback("CallbackMainHandler");
	menu_additem(g_iMainMenuID, "DM_SPAWN_ADD", "1", 0, g_cMainMenuID);
	menu_additem(g_iMainMenuID, "DM_SPAWN_EDIT_MOVE", "2", 0, g_cMainMenuID);
	menu_additem(g_iMainMenuID, "DM_SPAWN_DEL_CLOSEST", "3", 0, g_cMainMenuID);
	menu_additem(g_iMainMenuID, "DM_SPAWN_REFRESH", "4", 0, g_cMainMenuID);
	menu_additem(g_iMainMenuID, "DM_SPAWN_ALL", "5", 0, g_cMainMenuID);
	menu_additem(g_iMainMenuID, "DM_SPAWN_SHOW", "6", 0, g_cMainMenuID);
	
	g_asInfoTarget = engfunc(EngFunc_AllocString, "info_target");
	
	ReadSpawns();
	
	register_concmd("dm_edit_spawns", "ConsoleCmdEditSpawns", ADMIN_MAP, "Spawn Editor");
	register_concmd("edit_spawns", "ConsoleCmdEditSpawns", ADMIN_MAP, "Spawn Editor");
}

/* -Console------------------------------------------------------------------- */

public ConsoleCmdEditSpawns(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
	{
		return PLUGIN_HANDLED;
	}
	
	menu_display(id, g_iMainMenuID);
	CreateEntity(-1);
	
	return PLUGIN_HANDLED;
}

/* --------------------------------------------------------------------------- */

ReadSpawns()
{
	new szMapName[32], szConfigDir[32], szMapFile[256];
	
	get_mapname(szMapName, charsmax(szMapName));
	get_configsdir(szConfigDir, charsmax(szConfigDir));
	format(szMapFile, charsmax(szMapFile), "%s\csdm\%s.spawns.cfg", szConfigDir, szMapName);
	g_iTotalSpawns = 0;
	
	if (!file_exists(szMapFile))
	{
		return;
	}
	
	new file = fopen(szMapFile, "rt");
	if (!file)
	{
		return;
	}
	
	new szLine[128], szPosi[10][5];
	while (!feof(file))
	{
		if (g_iTotalSpawns >= MAX_SPAWNS)
			break;
		
		fgets(file, szLine, charsmax(szLine));
		trim(szLine);
		
		if (strlen(szLine) < 2 || szLine[0] == '[' || szLine[0] == ';' || szLine[0] == '#' || szLine[0] == '/')
			continue;
		
		parse(szLine, szPosi[0], charsmax(szPosi[]), szPosi[1], charsmax(szPosi[]), szPosi[2], charsmax(szPosi[]), szPosi[3], charsmax(szPosi[]), szPosi[4], charsmax(szPosi[]), szPosi[5], charsmax(szPosi[]), szPosi[6], charsmax(szPosi[]), szPosi[7], charsmax(szPosi[]), szPosi[8], charsmax(szPosi[]), szPosi[9], charsmax(szPosi[]));
		
		// Origin
		g_iOrigin[g_iTotalSpawns][0] = str_to_num(szPosi[0]);
		g_iOrigin[g_iTotalSpawns][1] = str_to_num(szPosi[1]);
		g_iOrigin[g_iTotalSpawns][2] = str_to_num(szPosi[2]);
		
		// Angles
		g_iSpawnAngles[g_iTotalSpawns][0] = str_to_num(szPosi[3]);
		g_iSpawnAngles[g_iTotalSpawns][1] = str_to_num(szPosi[4]);
		g_iSpawnAngles[g_iTotalSpawns][2] = str_to_num(szPosi[5]);
		
		// Team
		g_iSpawnTeamID[g_iTotalSpawns] = str_to_num(szPosi[6]);
		
		// V-Angles
		g_iSpawnViewAngles[g_iTotalSpawns][0] = str_to_num(szPosi[7]);
		g_iSpawnViewAngles[g_iTotalSpawns][1] = str_to_num(szPosi[8]);
		g_iSpawnViewAngles[g_iTotalSpawns][2] = str_to_num(szPosi[9]);
		
		g_iTotalSpawns++;
	}
	fclose(file);
}

/* --------------------------------------------------------------------------- */

public MenuMainHandler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		RemoveEntity(-1);
		return PLUGIN_HANDLED;
	}
	
	switch (item)
	{
		case 0:
		{
			new Float:fOrigin[3], iOrigin[3]; pev(id, pev_origin, fOrigin);
			new Float:fAngles[3], iAngles[3]; pev(id, pev_angles, fAngles);
			new Float:fViewAngels[3], iViewAngels[3]; pev(id, pev_v_angle, fViewAngels);
			
			FVecIVec(fOrigin, iOrigin);
			FVecIVec(fAngles, iAngles);
			FVecIVec(fViewAngels, iViewAngels);
			
			iOrigin[2] += 15;
			AddSpawn(iOrigin, iAngles, iViewAngels, g_iEntityTeam[id]);
			menu_display(id, menu);
		}
		case 1:
		{
			new Float:fOrigin[3], iOrigin[3]; pev(id, pev_origin, fOrigin);
			new Float:fAngles[3], iAngles[3]; pev(id, pev_angles, fAngles);
			new Float:fViewAngels[3], iViewAngels[3]; pev(id, pev_v_angle, fViewAngels);
			
			FVecIVec(fOrigin, iOrigin);
			FVecIVec(fAngles, iAngles);
			FVecIVec(fViewAngels, iViewAngels);
			
			iOrigin[2] += 15;
			EditSpawn(g_iEntity[id], iOrigin, iAngles, iViewAngels, g_iEntityTeam[id]);
			menu_display(id, menu);
		}
		case 2:
		{
			EntityUnglow(g_iEntity[id]);
			DeleteSpawn(g_iEntity[id]);
			g_iEntity[id] = GetClosestSpawn(id);
			menu_display(id, menu);
		}
		case 3:
		{
			EntityUnglow(g_iEntity[id]);
			g_iEntity[id] = GetClosestSpawn(id);
			EntityGlow(g_iEntity[id], g_fColorYellow);
			menu_display(id, menu);
		}
		case 4:
		{
			switch (g_iEntityTeam[id])
			{
				case 0: g_iEntityTeam[id] = 1; // ALL
				case 1: g_iEntityTeam[id] = 2; // Ter
				case 2: g_iEntityTeam[id] = 0; // CT
			}
			menu_display(id, menu);
		}
		case 5:
		{
			new Float:fOrigin[3], iOrigin[3];
			pev(id, pev_origin, fOrigin);
			
			FVecIVec(fOrigin, iOrigin);
			
			#if AMXX_VERSION_NUM < 183
			dm_print_color(id, Red, "^4[DM-Spawn-Editor]^1 %L", id, "DM_SPAWN_STATISTICS", g_iTotalSpawns + 1, iOrigin[0], iOrigin[1], iOrigin[2]);
			#else
			client_print_color(id, print_team_red, "^4[DM-Spawn-Editor]^1 %L", id, "DM_SPAWN_STATISTICS", g_iTotalSpawns + 1, iOrigin[0], iOrigin[1], iOrigin[2]);
			#endif
			
			menu_display(id, menu);
		}
	}
	
	return PLUGIN_HANDLED;
}

public CallbackMainHandler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		return PLUGIN_CONTINUE;
	}
	
	static szMenuItem[128];
	switch (item)
	{
		case 0:
		{
			if (g_iTotalSpawns == MAX_SPAWNS)
			{
				formatex(szMenuItem, charsmax(szMenuItem), "%L", id, "DM_SPAWN_LIMIT");
				menu_item_setname(menu, item, szMenuItem);
				return ITEM_DISABLED;
			}
			else
			{
				formatex(szMenuItem, charsmax(szMenuItem), "%L", id, "DM_SPAWN_ADD");
				menu_item_setname(menu, item, szMenuItem);
				return ITEM_ENABLED;
			}
		}
		case 1:
		{
			if (g_iTotalSpawns < 1)
			{
				formatex(szMenuItem, charsmax(szMenuItem), "%L", id, "DM_SPAWN_EDIT_NONE");
				menu_item_setname(menu, item, szMenuItem );
				return ITEM_DISABLED;
			}
			else if (g_iEntity[id] == -1)
			{
				formatex(szMenuItem, charsmax(szMenuItem), "%L", id, "DM_SPAWN_EDIT_MARKED");
				menu_item_setname(menu, item, szMenuItem);
				return ITEM_DISABLED;
			}
			else
			{
				formatex(szMenuItem, charsmax(szMenuItem), "%L", id, "DM_SPAWN_EDIT_MOVE");
				menu_item_setname(menu, item, szMenuItem);
				return ITEM_ENABLED;
			}
		}
		case 2:
		{
			if (g_iTotalSpawns < 1)
			{
				formatex(szMenuItem, charsmax(szMenuItem), "%L", id, "DM_SPAWN_DEL_NONE");
				menu_item_setname(menu, item, szMenuItem);
				return ITEM_DISABLED;
			}
			else if (g_iEntity[id] == -1)
			{
				formatex(szMenuItem, charsmax(szMenuItem), "%L", id, "DM_SPAWN_DEL_MARKED");
				menu_item_setname(menu, item, szMenuItem);
				return ITEM_DISABLED;
			}
			else
			{
				new Float:fOrigin[3], iOrigin[3];
				pev(id, pev_origin, fOrigin);
				
				FVecIVec(fOrigin, iOrigin);
				if (get_distance(iOrigin, g_iOrigin[g_iEntity[id]]) > 200)
				{
					formatex(szMenuItem, charsmax(szMenuItem), "%L", id, "DM_SPAWN_DEL_AWAY");
					menu_item_setname(menu, item, szMenuItem);
					return ITEM_DISABLED;
				}
				else
				{
					formatex(szMenuItem, charsmax(szMenuItem), "%L", id, "DM_SPAWN_DEL_CLOSEST");
					menu_item_setname(menu, item, szMenuItem);
					return ITEM_ENABLED;
				}
			}
		}
		case 3:
		{
			formatex(szMenuItem, charsmax(szMenuItem), "%L", id, "DM_SPAWN_REFRESH");
			menu_item_setname(menu, item, szMenuItem);
			return ITEM_ENABLED;
		}
		case 4:
		{
			switch (g_iEntityTeam[id])
			{
				case 0: formatex(szMenuItem, charsmax(szMenuItem), "%L", id, "DM_SPAWN_ALL");
				case 1: formatex(szMenuItem, charsmax(szMenuItem), "%L", id, "DM_SPAWN_TER");
				case 2: formatex(szMenuItem, charsmax(szMenuItem), "%L", id, "DM_SPAWN_CT");
			}
			
			menu_item_setname(menu, item, szMenuItem);
			return ITEM_ENABLED;
		}
		case 5:
		{
			formatex(szMenuItem, charsmax(szMenuItem), "%L", id, "DM_SPAWN_SHOW");
			menu_item_setname(menu, item, szMenuItem);
			return ITEM_ENABLED;
		}
	}
	
	return PLUGIN_HANDLED;
}

/* --------------------------------------------------------------------------- */

AddSpawn(iOrigin[3], iAngles[3], iViewAngels[3], iTeam)
{
	new szMapName[32], szConfigDir[32], szMapFile[256];
	
	get_mapname(szMapName, charsmax(szMapName));
	get_configsdir(szConfigDir, charsmax(szConfigDir));
	format(szMapFile, charsmax(szMapFile), "%s\csdm\%s.spawns.cfg", szConfigDir, szMapName);
	
	new szLine[128];
	format(szLine, charsmax(szLine), "%d %d %d %d %d %d %d %d %d %d", iOrigin[0], iOrigin[1], iOrigin[2], iAngles[0], iAngles[1], iAngles[2], iTeam, iViewAngels[0], iViewAngels[1], iViewAngels[2]);
	write_file(szMapFile, szLine, -1);
	
	// iOrigin
	g_iOrigin[g_iTotalSpawns][0] = iOrigin[0];
	g_iOrigin[g_iTotalSpawns][1] = iOrigin[1];
	g_iOrigin[g_iTotalSpawns][2] = iOrigin[2];
	
	// Angles
	g_iSpawnAngles[g_iTotalSpawns][0] = iAngles[0];
	g_iSpawnAngles[g_iTotalSpawns][1] = iAngles[1];
	g_iSpawnAngles[g_iTotalSpawns][2] = iAngles[2];
	
	// Teams
	g_iSpawnTeamID[g_iTotalSpawns] = iTeam;
	
	// v-Angles
	g_iSpawnViewAngles[g_iTotalSpawns][0] = iViewAngels[0];
	g_iSpawnViewAngles[g_iTotalSpawns][1] = iViewAngels[1];
	g_iSpawnViewAngles[g_iTotalSpawns][2] = iViewAngels[2];
	
	CreateEntity(g_iTotalSpawns);
	g_iTotalSpawns++;
}

EditSpawn(ent, iOrigin[3], iAngles[3], iViewAngels[3], iTeam)
{
	new szMapName[32], szConfigDir[32], szMapFile[256];
	
	get_mapname(szMapName, charsmax(szMapName));
	get_configsdir(szConfigDir, charsmax(szConfigDir));
	format(szMapFile, charsmax(szMapFile), "%s\csdm\%s.spawns.cfg", szConfigDir, szMapName);
	
	if (file_exists(szMapFile))
	{
		new szData[128], iLength, szLine = 0, szPosi[10][5], iCurOrigin[3], szNewSpawn[128];
		
		while ((szLine = read_file(szMapFile, szLine, szData, charsmax(szData), iLength)) != 0) 
		{
			if (strlen(szData) < 2 || szData[0] == '[' || szData[0] == ';' || szData[0] == '#' || szData[0] == '/')
				continue;
			
			parse(szData, szPosi[0], charsmax(szPosi[]), szPosi[1], charsmax(szPosi[]), szPosi[2], charsmax(szPosi[]), szPosi[3], charsmax(szPosi[]), szPosi[4], charsmax(szPosi[]), szPosi[5], charsmax(szPosi[]), szPosi[6], charsmax(szPosi[]), szPosi[7], charsmax(szPosi[]), szPosi[8], charsmax(szPosi[]), szPosi[9], charsmax(szPosi[]));
			iCurOrigin[0] = str_to_num(szPosi[0]);
			iCurOrigin[1] = str_to_num(szPosi[1]);
			iCurOrigin[2] = str_to_num(szPosi[2]);
			
			if ((g_iOrigin[ent][0] == iCurOrigin[0]) && (g_iOrigin[ent][1] == iCurOrigin[1]) && ((g_iOrigin[ent][2] - iCurOrigin[2]) <= 15))
			{
				format(szNewSpawn, charsmax(szNewSpawn), "%d %d %d %d %d %d %d %d %d %d", iOrigin[0], iOrigin[1], iOrigin[2], iAngles[0], iAngles[1], iAngles[2], iTeam, iViewAngels[0], iViewAngels[1], iViewAngels[2]);
				write_file(szMapFile, szNewSpawn, szLine-1);
				
				RemoveEntity(ent);
				
				g_iOrigin[ent][0] = iOrigin[0];
				g_iOrigin[ent][1] = iOrigin[1];
				g_iOrigin[ent][2] = iOrigin[2];
				
				g_iSpawnAngles[ent][0] = iAngles[0];
				g_iSpawnAngles[ent][1] = iAngles[1];
				g_iSpawnAngles[ent][2] = iAngles[2];
				
				g_iSpawnTeamID[ent] = iTeam;
				
				g_iSpawnViewAngles[ent][0] = iViewAngels[0];
				g_iSpawnViewAngles[ent][1] = iViewAngels[1];
				g_iSpawnViewAngles[ent][2] = iViewAngels[2];
				
				CreateEntity(ent);
				EntityGlow(ent, g_fColorRed);
				
				break;
			}
		}
	}
}
	
DeleteSpawn(ent)
{
	new szMapName[32], szConfigDir[32], szMapFile[256];
	
	get_mapname(szMapName, charsmax(szMapName));
	get_configsdir(szConfigDir, charsmax(szConfigDir));
	format(szMapFile, charsmax(szMapFile), "%s\csdm\%s.spawns.cfg", szConfigDir, szMapName);
	
	if (file_exists(szMapFile))
	{
		new szData[128], iLength, szLine = 0, szPosi[3][5], iCurOrigin[3];
		
		while ((szLine = read_file(szMapFile, szLine, szData, charsmax(szData), iLength)) != 0) 
		{
			if (strlen(szData) < 2 || szData[0] == '[' || szData[0] == ';' || szData[0] == '#' || szData[0] == '/')
				continue;
			
			parse(szData, szPosi[0], charsmax(szPosi[]), szPosi[1], charsmax(szPosi[]), szPosi[2], charsmax(szPosi[]));
			iCurOrigin[0] = str_to_num(szPosi[0]);
			iCurOrigin[1] = str_to_num(szPosi[1]);
			iCurOrigin[2] = str_to_num(szPosi[2]);
			
			if ((g_iOrigin[ent][0] == iCurOrigin[0]) && (g_iOrigin[ent][1] == iCurOrigin[1]) && (g_iOrigin[ent][2] - iCurOrigin[2]) <= 15)
			{
				write_file(szMapFile, "", szLine-1);
				
				RemoveEntity(-1);
				ReadSpawns();
				CreateEntity(-1);
				
				break;
			}
		}
	}
}

GetClosestSpawn(id)
{
	new Float:fOrigin[3], iOrigin[3], iLastDistance = 99999, iClosestSpawn;
	
	pev(id, pev_origin, fOrigin);
	FVecIVec(fOrigin, iOrigin);
	
	for (new i = 0; i < g_iTotalSpawns; i++)
	{
		new iDistance = get_distance(iOrigin, g_iOrigin[i]);
		
		if (iDistance < iLastDistance)
		{
			iLastDistance = iDistance;
			iClosestSpawn = i;
		}
	}
	return iClosestSpawn;
}

/* --------------------------------------------------------------------------- */

CreateEntity(ent)
{
	new iEnt;

	if (ent < 0)
	{
		for (new i = 0; i < g_iTotalSpawns; i++)
		{
			iEnt = engfunc(EngFunc_CreateNamedEntity, g_asInfoTarget);
			set_pev(iEnt, pev_classname, "view_spawn");
			engfunc(EngFunc_SetModel, iEnt, g_szModels[g_iSpawnTeamID[i]]);
			set_pev(iEnt, pev_solid, SOLID_SLIDEBOX);
			set_pev(iEnt, pev_movetype, MOVETYPE_NOCLIP);
			set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) & FL_ONGROUND);
			set_pev(iEnt, pev_sequence, 1);
			
			if (g_iEntities[i])
			{
				engfunc(EngFunc_RemoveEntity, g_iEntities[i]);
			}
			
			g_iEntities[i] = iEnt;
			EntityUnglow(i);
		}
	}
	else
	{
		iEnt = engfunc(EngFunc_CreateNamedEntity, g_asInfoTarget);
		set_pev(iEnt, pev_classname, "view_spawn");
		engfunc(EngFunc_SetModel, iEnt, g_szModels[g_iSpawnTeamID[ent]]);
		set_pev(iEnt, pev_solid, SOLID_SLIDEBOX);
		set_pev(iEnt, pev_movetype, MOVETYPE_NOCLIP);
		set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) & FL_ONGROUND);
		set_pev(iEnt, pev_sequence, 1);
		
		if (g_iEntities[ent])
		{
			engfunc(EngFunc_RemoveEntity, g_iEntities[ent]);
		}
		
		g_iEntities[ent] = iEnt;
		EntityUnglow(ent);
	}
}

RemoveEntity(ent)
{
	if (ent < 0)
	{
		for (new i = 0; i < g_iTotalSpawns; i++)
		{
			if (pev_valid(g_iEntities[i]))
			{
				engfunc(EngFunc_RemoveEntity, g_iEntities[i]);
				g_iEntities[i] = 0;
			}
		}
	}
	else
	{
		engfunc(EngFunc_RemoveEntity, g_iEntities[ent]);
		g_iEntities[ent] = 0;
	}
}

/* --------------------------------------------------------------------------- */

EntityGlow(ent, Float:color[3])
{
	new iEnt = g_iEntities[ent];
	
	if (iEnt)
	{
		SetEntityPosition(ent);
		
		set_pev(iEnt, pev_renderfx, kRenderFxGlowShell);
		set_pev(iEnt, pev_renderamt, 127.0);
		set_pev(iEnt, pev_rendermode, kRenderTransAlpha);
		set_pev(iEnt, pev_rendercolor, color);
	}
}

EntityUnglow(ent)
{
	new iEnt = g_iEntities[ent];
	
	if (iEnt)
	{
		SetEntityPosition(ent);
		
		set_pev(iEnt, pev_renderfx, kRenderFxNone);
		set_pev(iEnt, pev_renderamt, 255.0);
		set_pev(iEnt, pev_rendermode, kRenderTransAlpha);
	}
}

/* --------------------------------------------------------------------------- */

SetEntityPosition(ent)
{
	new iEnt = g_iEntities[ent];
	
	new Float:fOrigin[3];
	IVecFVec(g_iOrigin[ent], fOrigin);
	set_pev(iEnt, pev_origin, fOrigin);
	
	new Float:fAngles[3];
	IVecFVec(g_iSpawnAngles[ent], fAngles);
	set_pev(iEnt, pev_angles, fAngles);
	
	new Float:fViewAngles[3];
	IVecFVec(g_iSpawnViewAngles[ent], fViewAngles);
	set_pev(iEnt, pev_v_angle, fViewAngles);
	
	set_pev(iEnt, pev_fixangle, 1);
}
