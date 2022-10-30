/*
	----------------------
	-*- Licensing Info -*-
	----------------------
	
	Semiclip Mod: Entities fix
	by schmurgel1983(@msn.com)
	Copyright (C) 2014-2022 schmurgel1983, skhowl, gesalzen
	
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

#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>

/*================================================================================
 [Plugin Customization]
=================================================================================*/

#define MAX_PLAYERS		32	/* Server slots ¬ 32 */
#define MAX_ENT_ARRAY	128	/* Is for max 4096 entities (128*32=4096) ¬ 128 */

/*================================================================================
 Customization ends here! Yes, that's it. Editing anything beyond
 here is not officially supported. Proceed at your own risk...
=================================================================================*/

/*================================================================================
 [Global Variables]
=================================================================================*/

/* Server */
new g_iClientDisconnect,
	g_iStartFrame,
	g_iBlocked,
	g_iEntitySemiclip_End,
	g_iAbsBoxClashing,
	g_iFuncNum,
	g_iLastClashed

/* Trie */
new Trie:TrieFunctions = Invalid_Trie

/* Hamsandwich */
new HamHook:g_iHamFuncForwards[16] /* Max supported entity classes ¬ 16 */

/* Client */
new Float:g_flAbsMin[MAX_PLAYERS+1][3],
	Float:g_flAbsMax[MAX_PLAYERS+1][3],
	Float:g_flAbsMaxDucking[MAX_PLAYERS+1][3]

/* Bitsum */
new bs_IsAlive,
	bs_IsSolid,
	bs_IsAbsStored,
	bs_IsDucking

/* Bitsum array */
new bs_IgnoreEntity[MAX_ENT_ARRAY],
	bs_EntityNoDamage[MAX_ENT_ARRAY]

/*================================================================================
 [Amxx 1.8.3]
=================================================================================*/

#if AMXX_VERSION_NUM >= 183
#define g_iMaxPlayers	MaxClients
#else
new g_iMaxPlayers
#endif

/*================================================================================
 [Macros]
=================================================================================*/

#define get_bitsum(%1,%2)   (%1 &   (1<<((%2-1)&31)))
#define add_bitsum(%1,%2)    %1 |=  (1<<((%2-1)&31));
#define del_bitsum(%1,%2)    %1 &= ~(1<<((%2-1)&31));

#define get_bitsum_array(%1,%2)   (%1[(%2-1)/32] &   (1<<((%2-1)&31)))
#define add_bitsum_array(%1,%2)    %1[(%2-1)/32] |=  (1<<((%2-1)&31));

#define is_user_valid(%1)         (1 <= %1 <= g_iMaxPlayers)
#define is_user_valid_alive(%1)   (1 <= %1 <= g_iMaxPlayers && get_bitsum(bs_IsAlive, %1))

/*================================================================================
 [Natives, Init and Cfg]
=================================================================================*/

public plugin_natives()
{
	register_native("scm_load_ini_file", "fn_load_ini_file") /* for scm_entity_editor.amxx only */
}

public plugin_init()
{
	register_plugin("[SCM] Entities fix", "1.2.13", "schmurgel1983")
	
	new Float:flValue, iValue
	flValue = float(global_get(glb_maxEntities)) / 32
	iValue = floatround(flValue, floatround_ceil)
	
	if (iValue > MAX_ENT_ARRAY)
	{
		new szError[100]
		format(szError, charsmax(szError), "Error: MAX_ENT_ARRAY is to low! Increase it to: %d and re-compile sma!", iValue)
		set_fail_state(szError)
	}
	state entities
	
	register_event("HLTV", "EventRoundStart", "a", "1=0", "2=0")
	register_logevent("LogEventRoundStart", 2, "1=Round_Start")
	
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", true)
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled", false)
	
	g_iClientDisconnect = register_forward(FM_ClientDisconnect, "client_putinserver", false)
	g_iStartFrame = register_forward(FM_StartFrame, "fw_StartFrame", false)
	g_iBlocked = register_forward(FM_Blocked, "fw_Blocked", false)
	g_iEntitySemiclip_End = register_forward(FM_UpdateClientData, "fw_EntitySemiclip_End", false)
	g_iAbsBoxClashing = register_forward(FM_SetAbsBox, "fw_AbsBoxClashing", false)
	
	#if AMXX_VERSION_NUM <= 182
	g_iMaxPlayers = get_maxplayers()
	#endif
}

public plugin_cfg()
{
	set_task(0.75, "LoadSemiclipFileDelayed")
}

/*================================================================================
 [Pause, Unpause]
=================================================================================*/

public plugin_pause()
{
	unregister_forward(FM_ClientDisconnect, g_iClientDisconnect, false)
	unregister_forward(FM_StartFrame, g_iStartFrame, false)
	unregister_forward(FM_Blocked, g_iBlocked, false)
	unregister_forward(FM_UpdateClientData, g_iEntitySemiclip_End, false)
	unregister_forward(FM_SetAbsBox, g_iAbsBoxClashing, false)
}

public plugin_unpause()
{
	g_iClientDisconnect = register_forward(FM_ClientDisconnect, "client_putinserver", false)
	g_iStartFrame = register_forward(FM_StartFrame, "fw_StartFrame", false)
	g_iBlocked = register_forward(FM_Blocked, "fw_Blocked", false)
	g_iEntitySemiclip_End = register_forward(FM_UpdateClientData, "fw_EntitySemiclip_End", false)
	g_iAbsBoxClashing = register_forward(FM_SetAbsBox, "fw_AbsBoxClashing", false)
	
	LoadSemiclipFile(false)
	
	bs_IsAlive = 0
	for (new id = 1; id <= g_iMaxPlayers; id++)
	{
		if (!is_user_connected(id))
			continue
		
		if (is_user_alive(id))
			add_bitsum(bs_IsAlive, id)
	}
}

/*================================================================================
 [Put in, Disconnect]
=================================================================================*/

/* Called on disconnect too. */
public client_putinserver(id)
{
	del_bitsum(bs_IsAlive, id)
}

/*================================================================================
 [Main Events]
=================================================================================*/

public EventRoundStart()
{
	for (new i; i < g_iFuncNum; i++)
		DisableHamForward(g_iHamFuncForwards[i])
}

public LogEventRoundStart()
{
	for (new i; i < g_iFuncNum; i++)
		EnableHamForward(g_iHamFuncForwards[i])
}

/*================================================================================
 [Main Forwards]
=================================================================================*/

public fw_StartFrame()
{
	bs_IsSolid      = 4294967295
	bs_IsAbsStored  = 0
	bs_IsDucking    = 0
	g_iLastClashed  = 0
}

public fw_PlayerSpawn_Post(id)
{
	if (!is_user_alive(id))
		return
	
	add_bitsum(bs_IsAlive, id)
}

public fw_PlayerKilled(id)
{
	del_bitsum(bs_IsAlive, id)
}

public fw_Blocked(iBlocked, iBlocker)
{
	if (get_bitsum_array(bs_IgnoreEntity, iBlocked) || !is_user_valid(iBlocker))
		return FMRES_IGNORED
	
	/* Entity damage handle. */
	return get_bitsum_array(bs_EntityNoDamage, iBlocked) ? FMRES_SUPERCEDE : FMRES_IGNORED
}

/*================================================================================
 [Entity movement]
=================================================================================*/

public fw_EntitySemiclip_Start(ent)
{
	if (get_bitsum_array(bs_IgnoreEntity, ent))
		return
	
	state entities
	SetupPlayers(true, ent)
}

public fw_EntitySemiclip_End(id) <entities>
{
	state players
	SetupPlayers(true, id)
}

public fw_EntitySemiclip_End(id) <players> { /* Do nothing */ }

public fw_AbsBoxClashing(id) <entities>
{
	if (!is_user_valid_alive(id))
		return
	
	if (g_iLastClashed && get_bitsum(bs_IsSolid, g_iLastClashed))
	{
		set_pev(g_iLastClashed, pev_solid, SOLID_NOT)
		del_bitsum(bs_IsSolid, g_iLastClashed)
	}
	
	if (!get_bitsum(bs_IsSolid, id))
	{
		if (pev(id, pev_flags) & FL_DUCKING)
		{
			static Float:fViewOfs[3]
			pev(id, pev_view_ofs, fViewOfs)
			pev(id, pev_maxs, g_flAbsMaxDucking[id])
			g_flAbsMaxDucking[id][2] = fViewOfs[2] + 3.0
			
			set_pev(id, pev_maxs, g_flAbsMaxDucking[id])
			add_bitsum(bs_IsDucking, id)
		}
		
		set_pev(id, pev_solid, SOLID_SLIDEBOX)
		add_bitsum(bs_IsSolid, id)
		g_iLastClashed = id
	}
}

public fw_AbsBoxClashing(id) <players>
{
	if (!is_user_valid_alive(id) || !get_bitsum(bs_IsDucking, id))
		return
	
	set_pev(id, pev_maxs, g_flAbsMaxDucking[id])
}

SetupPlayers(id, i) <entities>
{
	static Float:flEntityAbsMin[3], Float:flEntityAbsMax[3]
	pev(i, pev_absmin, flEntityAbsMin)
	pev(i, pev_absmax, flEntityAbsMax)
	
	for (id = 1; id <= g_iMaxPlayers; id++)
	{
		if (!get_bitsum(bs_IsAlive, id) || !get_bitsum(bs_IsSolid, id))
			continue
		
		if (!get_bitsum(bs_IsAbsStored, id))
		{
			pev(id, pev_absmin, g_flAbsMin[id])
			pev(id, pev_absmax, g_flAbsMax[id])
			add_bitsum(bs_IsAbsStored, id)
		}
		
		if (GetIntersects(g_flAbsMin[id], g_flAbsMax[id], flEntityAbsMin, flEntityAbsMax))
		{
			set_pev(id, pev_solid, SOLID_NOT)
			del_bitsum(bs_IsSolid, id)
		}
	}
}

SetupPlayers(id, i) <players>
{
	#pragma unused i
	for (id = 1; id <= g_iMaxPlayers; id++)
	{
		if (!get_bitsum(bs_IsAlive, id) || get_bitsum(bs_IsSolid, id))
			continue
		
		set_pev(id, pev_solid, SOLID_SLIDEBOX)
	}
}

GetIntersects(Float:flAbsMin[3], Float:flAbsMax[3], Float:flAbsMin2[3], Float:flAbsMax2[3])
{
	if (flAbsMin[0] > flAbsMax2[0] || flAbsMin[1] > flAbsMax2[1] || flAbsMin[2] > flAbsMax2[2] || flAbsMax[0] < flAbsMin2[0] || flAbsMax[1] < flAbsMin2[1] || flAbsMax[2] < flAbsMin2[2])
	{
		return 0
	}
	return 1
}

/*================================================================================
 [Other Functions and Tasks]
=================================================================================*/

public LoadSemiclipFileDelayed()
{
	LoadSemiclipFile(false)
}

public LoadSemiclipFile(bool:bNative)
{
	new szFilePath[96], szMapName[32]
	
	get_configsdir(szFilePath, charsmax(szFilePath))
	get_mapname(szMapName, charsmax(szMapName))
	format(szFilePath, charsmax(szFilePath), "%s/scm/entities/%s.ini", szFilePath, szMapName)
	
	if (!file_exists(szFilePath))
		return
	
	/* Disable ham forwards */
	for (new i = 0; i < g_iFuncNum; i++)
		DisableHamForward(g_iHamFuncForwards[i])
	
	/* Reset bitsum arrays */
	arrayset(bs_IgnoreEntity, 0, MAX_ENT_ARRAY)
	arrayset(bs_EntityNoDamage, 0, MAX_ENT_ARRAY)
	
	/* Create Trie */
	if (TrieFunctions == Invalid_Trie)
		TrieFunctions = TrieCreate()
	
	new iFile
	if ((iFile = fopen(szFilePath, "rt")) != 0)
	{
		if (TrieFunctions != Invalid_Trie)
		{
			new szLineData[64], szData[4][32]
			while (!feof(iFile))
			{
				fgets(iFile, szLineData, charsmax(szLineData))
				replace(szLineData, charsmax(szLineData), "^n", "")
				
				if (!szLineData[0] || szLineData[0] == '/' || szLineData[0] == ';' || szLineData[0] == '#')
					continue
				
				/* func *model semiclip damage */
				parse(szLineData, szData[0], charsmax(szData[]), szData[1], 7, szData[2], 7, szData[3], 7)
				
				/* Get Entity Index */
				new iEntity = find_ent_by_model(0, szData[0], szData[1])
				
				/* Entity not found */
				if (!iEntity)
					continue
				
				/* Ignore entity */
				if (equali(szData[2], "ignore", 6))
				{
					add_bitsum_array(bs_IgnoreEntity, iEntity)
					continue
				}
				
				/* Register HamForward */
				if (!TrieKeyExists(TrieFunctions, szData[0]))
				{
					g_iHamFuncForwards[g_iFuncNum] = RegisterHam(Ham_SetObjectCollisionBox, szData[0], "fw_EntitySemiclip_Start", true)
					TrieSetCell(TrieFunctions, szData[0], g_iFuncNum)
					g_iFuncNum++
				}
				else
				{
					new iValue
					if (TrieGetCell(TrieFunctions, szData[0], iValue))
					{
						EnableHamForward(g_iHamFuncForwards[iValue])
					}
					else
					{
						abort(bNative ? AMX_ERR_NATIVE : AMX_ERR_NONE, "[SCM: Entity Movement] Can't Re-enable %s (%d).", szData[0], iValue)
					}
				}
				
				/* Entity damage */
				if (equali(szData[3], "disable", 7))
				{
					add_bitsum_array(bs_EntityNoDamage, iEntity)
				}
			}
			fclose(iFile)
		}
		else
		{
			fclose(iFile)
			abort(bNative ? AMX_ERR_NATIVE : AMX_ERR_NONE, "[SCM: Entity Movement] Failed to create Trie:Variable.")
		}
	}
	else
	{
		abort(bNative ? AMX_ERR_NATIVE : AMX_ERR_NONE, "[SCM: Entity Movement] Failed to open ^"%s^" file.", szFilePath)
	}
}

/*================================================================================
 [Custom Natives]
=================================================================================*/

/* scm_load_ini_file() */
public fn_load_ini_file(plugin_id, num_params)
{
	if (is_plugin_loaded("scm_entity_editor.amxx", true) != plugin_id)
	{
		log_error(AMX_ERR_NATIVE, "[SCM: Entity Movement] Plugin has no access permission for scm_load_ini_file.")
		return 0
	}
	
	LoadSemiclipFile(true)
	return 1
}

/*================================================================================
 [Stocks]
=================================================================================*/

/* amxmisc.inc */
stock get_configsdir(name[], len)
{
	return get_localinfo("amxx_configsdir", name, len)
}
