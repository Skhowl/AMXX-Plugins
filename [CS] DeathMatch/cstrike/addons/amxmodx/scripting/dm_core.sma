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
#pragma dynamic 16384 // 64kb

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#include <dm_const>
#include <dm_log>

/* --------------------------------------------------------------------------- */

new g_iPluginID = 0;
new g_iEnabled = 0;

new g_iFwdSpawn = 0;
new g_iFwdSetClientKeyValue = 0;
new g_iFwdDummyResult = 0;

new g_iMaxHostageSupport = 0;
new iHostageNum = 0;
new iHostages[MAX_HOSTAGE_SUPPORT];

new g_szMapName[32];
new g_szMapPrefix[32];
new bool:g_bMapPrefixAvailable = false;

#define fm_find_ent_by_class(%1,%2) engfunc(EngFunc_FindEntityByString, %1, "classname", %2)

/* --------------------------------------------------------------------------- */

public plugin_natives()
{
	register_native("DM_LoadConfiguration", "native_register_config");
	register_library("dm_core");
}

public plugin_precache()
{
	g_iPluginID = register_plugin("DM: Core", DM_VERSION_STR_LONG, "schmurgel1983");
	register_cvar("dm_version", DM_VERSION_STRING, FCVAR_SERVER|FCVAR_SPONLY);
	set_cvar_string("dm_version", DM_VERSION_STRING);
	
	if (!ReadConfig() || !g_iEnabled)
	{
		state deactivated;
		DM_ExecuteModStatus();
		return;
	}
	state enabled;
	DM_ExecuteModStatus();
	
	g_iFwdSpawn = register_forward(FM_Spawn, "fwd_Spawn", false);
}

public plugin_init() <deactivated> {}
public plugin_init() <enabled>
{
	unregister_forward(FM_Spawn, g_iFwdSpawn);
	
	new iBombTarget = 0, iVipSafetyZone = 0;
	
	if (fm_find_ent_by_class(FM_NULLENT, "func_bomb_target") > 0)
		iBombTarget = 1;
	
	if (fm_find_ent_by_class(FM_NULLENT, "func_vip_safetyzone") > 0)
		iVipSafetyZone = 1;
	
	new pArray = PrepareArray(iHostages, MAX_HOSTAGE_SUPPORT);
	new ForwardID = CreateMultiForward("DM_OnMapConditions", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL, FP_ARRAY);
	if (!ForwardID || !ExecuteForward(ForwardID, g_iFwdDummyResult, iBombTarget, iVipSafetyZone, iHostageNum, pArray))
	{
		DM_Log(LOG_ERROR, "Can't create forward or not execute: DM_OnMapConditions");
		DM_LogPlugin(LOG_ERROR, g_iPluginID, "plugin_init", 1);
		return;
	}
	DestroyForward(ForwardID);
}

/* -from-ConnorMcLeod--------------------------------------------------------- */

public client_putinserver(id) <deactivated> {}
public client_putinserver(id) <enabled>
{
	if (!g_iFwdSetClientKeyValue && is_user_bot(id))
	{
		g_iFwdSetClientKeyValue = register_forward(FM_SetClientKeyValue, "fwd_SetClientKeyValue");
	}
}

public fwd_SetClientKeyValue(id, infobuffer[], key[], value[])
{
	if (value[0] == '1' && equal(key, "*bot"))
	{
		unregister_forward(FM_SetClientKeyValue, g_iFwdSetClientKeyValue);
		
		new ForwardID = CreateMultiForward("DM_OnCzBotHamRegisterable", ET_IGNORE, FP_CELL);
		if (!ForwardID || !ExecuteForward(ForwardID, g_iFwdDummyResult, id))
		{
			DM_Log(LOG_ERROR, "Can't create forward or not execute: DM_OnCzBotHamRegisterable");
			DM_LogPlugin(LOG_ERROR, g_iPluginID, "fwd_SetClientKeyValue", 2);
			g_iFwdSetClientKeyValue = 0;
			return;
		}
		DestroyForward(ForwardID);
	}
}

/* --------------------------------------------------------------------------- */

DM_ExecuteModStatus()
{
	new ForwardID = CreateMultiForward("DM_OnModStatus", ET_IGNORE, FP_CELL);
	if (!ForwardID || !ExecuteForward(ForwardID, g_iFwdDummyResult, g_iEnabled))
	{
		DM_Log(LOG_ERROR, "Can't create forward or not execute: DM_OnModStatus");
		DM_LogPlugin(LOG_ERROR, g_iPluginID, "DM_ExecuteModStatus", 3);
		return;
	}
	DestroyForward(ForwardID);
}

public fwd_Spawn(entity)
{
	if (!pev_valid(entity))
		return FMRES_IGNORED;
	
	new classname[32];
	pev(entity, pev_classname, classname, charsmax(classname));
	
	if (equal(classname, "hostage_entity"))
	{
		if (g_iMaxHostageSupport == -1)
		{
			if (iHostageNum >= MAX_HOSTAGE_SUPPORT)
			{
				engfunc(EngFunc_RemoveEntity, entity);
				return FMRES_SUPERCEDE;
			}
			
			iHostages[iHostageNum] = entity;
			iHostageNum++;
		}
		else
		{
			if (iHostageNum >= g_iMaxHostageSupport)
			{
				engfunc(EngFunc_RemoveEntity, entity);
				return FMRES_SUPERCEDE;
			}
			
			iHostages[iHostageNum] = entity;
			iHostageNum++;
		}
	}
	return FMRES_IGNORED;
}

/* --------------------------------------------------------------------------- */

ReadConfig()
{
	get_mapname(g_szMapName, charsmax(g_szMapName));
	copy(g_szMapPrefix, charsmax(g_szMapPrefix), g_szMapName);
	
	new i;
	while (g_szMapPrefix[i] != '_' && g_szMapPrefix[i++] != '^0') { /* do nothing */ }
	if (g_szMapPrefix[i] == '_')
	{
		g_bMapPrefixAvailable = true;
		g_szMapPrefix[i] = '^0';
	}
	
	new ConfigDir[128], ConfigFile[128], ret;
	get_configsdir(ConfigDir, charsmax(ConfigDir));
	format(ConfigFile, charsmax(ConfigFile), "%s/deathmatch/dm_core.cfg", ConfigDir);
	
	if (file_exists(ConfigFile))
	{
		// Deathmatch Folder
		ret = ReadMainFile(ConfigFile, 1);
	}
	else
	{
		DM_Log(LOG_ERROR, "Main file ^"%s^" not present.", ConfigFile);
		DM_LogPlugin(LOG_ERROR, g_iPluginID, "ReadConfig", 4);
		return 0;
	}
	
	// Map Prefix
	if (g_bMapPrefixAvailable)
	{
		formatex(ConfigFile, charsmax(ConfigFile), "%s/maps/prefix_%s.dm_core.cfg", ConfigDir, g_szMapPrefix);
		if (file_exists(ConfigFile))
		{
			ReadMainFile(ConfigFile, 0);
		}
	}
	
	// Map
	formatex(ConfigFile, charsmax(ConfigFile), "%s/maps/%s.dm_core.cfg", ConfigDir, g_szMapName);
	if (file_exists(ConfigFile))
	{
		ReadMainFile(ConfigFile, 0);
	}
	
	return ret;
}

/* --------------------------------------------------------------------------- */

ReadMainFile(const path[], const mainfolder)
{
	new file = fopen(path, "rt");
	if (mainfolder && !file)
	{
		DM_Log(LOG_ERROR, "Can't open: %s", path);
		DM_LogPlugin(LOG_ERROR, g_iPluginID, "ReadMainFile", 5);
		return 0;
	}
	else if (!file)
	{
		DM_Log(LOG_INFO, "Can't open: %s", path);
		DM_LogPlugin(LOG_INFO, g_iPluginID, "ReadMainFile", 6);
		return 0;
	}
	
	new linedata[128], key[64], value[64];
	while (!feof(file))
	{
		fgets(file, linedata, charsmax(linedata));
		trim(linedata);
		
		if (!linedata[0] || linedata[0] == ';' || linedata[0] == '#' || linedata[0] == '/')
			continue;
		
		strtok(linedata, key, charsmax(key), value, charsmax(value), '=');
		trim(key);
		trim(value);
		
		if (equali(key, "enabled"))
		{
			g_iEnabled = !!str_to_num(value);
		}
		else if (equali(key, "max_hostage_support"))
		{
			g_iMaxHostageSupport = clamp(str_to_num(value), -1, MAX_HOSTAGE_SUPPORT);
		}
	}
	fclose(file);
	
	return 1;
}

ReadCustomFile(const Path[], const ForwardID, const PluginID, const MainFolder)
{
	new file = fopen(Path, "rt");
	if (MainFolder && !file)
	{
		DM_Log(LOG_ERROR, "Can't open: %s", Path);
		DM_LogPlugin(LOG_ERROR, PluginID, "DM_LoadConfiguration", 7);
		return 0;
	}
	else if (!file)
	{
		DM_Log(LOG_INFO, "Can't open: %s", Path);
		DM_LogPlugin(LOG_INFO, PluginID, "DM_LoadConfiguration", 8);
		return 0;
	}
	
	new linedata[160], section[32], key[64], value[64];
	while (!feof(file))
	{
		fgets(file, linedata, charsmax(linedata));
		trim(linedata);
		
		if (!linedata[0] || linedata[0] == ';' || linedata[0] == '#' || linedata[0] == '/')
			continue;
		
		if (linedata[0] == '[')
		{
			copyc(section, charsmax(section), linedata[1], ']');
			continue;
		}
		
		strtok(linedata, key, charsmax(key), value, charsmax(value), '=');
		trim(key);
		trim(value);
		
		if (!ExecuteForward(ForwardID, g_iFwdDummyResult, section, key, value))
		{
			DM_Log(LOG_INFO, "Can't execute: #%d <%s> <%s> <%s>", ForwardID, section, key, value);
			DM_LogPlugin(LOG_INFO, PluginID, "DM_LoadConfiguration", 9);
		}
	}
	fclose(file);
	
	return 1;
}

/* --------------------------------------------------------------------------- */

/* native DM_LoadConfiguration(const filename[], const callback[]); */
public native_register_config(plugin_id, num_params) <deactivated> return 0;
public native_register_config(plugin_id, num_params) <enabled>
{
	new ConfigPath[128], ConfigDir[96], PluginConfig[32];
	get_configsdir(ConfigDir, charsmax(ConfigDir));
	get_string(1, PluginConfig, charsmax(PluginConfig));
	format(ConfigPath, charsmax(ConfigPath), "%s/deathmatch/%s", ConfigDir, PluginConfig);
	
	if (!file_exists(ConfigPath))
	{
		DM_Log(LOG_ERROR, "Custom config file ^"%s^" not present.", ConfigPath);
		DM_LogPlugin(LOG_ERROR, plugin_id, "DM_LoadConfiguration", 10);
		return 0;
	}
	
	new PluginCallback[32], ForwardID, ret;
	get_string(2, PluginCallback, charsmax(PluginCallback));
	ForwardID = CreateOneForward(plugin_id, PluginCallback, FP_STRING, FP_STRING, FP_STRING);
	if (!ForwardID)
	{
		DM_Log(LOG_ERROR, "Can't create forward: %s", PluginCallback);
		DM_LogPlugin(LOG_ERROR, plugin_id, "DM_LoadConfiguration", 11);
		return 0;
	}
	
	// Deathmatch Folder
	ret = ReadCustomFile(ConfigPath, ForwardID, plugin_id, 1);
	
	// Map Prefix
	if (g_bMapPrefixAvailable)
	{
		formatex(ConfigPath, charsmax(ConfigPath), "%s/maps/prefix_%s.%s", ConfigDir, g_szMapPrefix, PluginConfig);
		if (file_exists(ConfigPath))
		{
			ReadCustomFile(ConfigPath, ForwardID, plugin_id, 0);
		}
	}
	
	// Map Folder
	formatex(ConfigPath, charsmax(ConfigPath), "%s/maps/%s.%s", ConfigDir, g_szMapName, PluginConfig);
	if (file_exists(ConfigPath))
	{
		ReadCustomFile(ConfigPath, ForwardID, plugin_id, 0);
	}
	
	DestroyForward(ForwardID);
	return ret;
}

/* --------------------------------------------------------------------------- */

stock get_configsdir(name[], len)
{
	return get_localinfo("amxx_configsdir", name, len);
}
