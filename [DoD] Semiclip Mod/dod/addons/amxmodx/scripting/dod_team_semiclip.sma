/*================================================================================
	
		*****************************************
		********* [Dod Semiclip Mod 2.0] ********
		*****************************************
	
	----------------------
	-*- Licensing Info -*-
	----------------------
	
	Dod Semiclip Mod
	by schmurgel1983(@msn.com)
	Copyright (C) 2010-2022 schmurgel1983, skhowl, gesalzen
	
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
	
	-------------------
	-*- Description -*-
	-------------------
	
	Added Team Semiclip, only for 1 team or both with enemie trespass or not.
	If team switching in mid-round so updating the team instandly, with unstuck feature.
	Knife trace to next enemy when you stay inside a teammate and aiming a enemy.
	
	--------------------
	-*- Requirements -*-
	--------------------
	
	* Game: Day of Defeat 1.3
	* Metamod: Version 1.18 or later
	* AMXX: Version 1.8.0 or later
	* Module: engine, fakemeta, hamsandwich
	
	----------------
	-*- Commands -*-
	----------------
	
	-----
	
	---------------------
	-*- Configuration -*-
	---------------------
	
	// General
	// -------
	semiclip 1 // [0-disabled / 1-enabled]
	semiclip_blockteam 0 // wich team has semiclip [0-both have / 1-Allies don't have / 2-Axis don't have / 3-both don't have]
	semiclip_enemies 0 // trespass enemies [0-disabled / 1-enabled]
	semiclip_unstuck 1 // Unstuck [0-disabled / 1-specified team / 2-random around own place]
	semiclip_unstuckdelay 0.1 // Unstuck delay in seconds (0.1 - 3.0) [0-instant]
	semiclip_button 0 // Button boost semiclip (this hijack blockteam) [0-disabled / 1-Allies / 2-Axis / 3-Both]
	semiclip_knife_trace 0 // Knife trace to next enemy when you stay inside a teammate and aiming a enemy [0-disabled / 1-enabled]
	semiclip_duration 0 // Specifies time to force this plugin only to works at the beginning of each round in seconds [0-disabled this option]
	
	// Render
	// ------
	semiclip_render 1 // Enable or disable all render/color functions. [0-disabled / 1-enabled]
	semiclip_rendermode 1 // Render mode (look amxconst.inc -> Render for set_user_rendering) [0-5] [0-disabled]
	semiclip_renderamt 1 // Render amount [0-255]
	semiclip_renderfx 19 // Render fx (look amxconst.inc -> Fx for set_user_rendering) [0-20] [0-disabled]
	semiclip_renderradius 250 // Render radius [??-4095] (?? = 200 - semiclip_renderfademin)
	semiclip_renderfade 0 // Render fade (this hijack semiclip_renderamt) [0-disabled / 1-enabled]
	semiclip_renderfademin 25 // Minimum render fade amount (stay very close or inside a player) [0-200]
	semiclip_renderfadespec 1 // Render fade for current spectating Player [0-disabled / 1-enabled]
	
	// Color
	// -----
	semiclip_color_admin_flag "b" // Admin color access flag (look user.ini, b - reservation)
	semiclip_color_admin_R 0 // Admin render color (red) [0-255]
	semiclip_color_admin_G 0 // Admin render color (green) [0-255]
	semiclip_color_admin_B 0 // Admin render color (blue) [0-255]
	semiclip_color_allies_R 0 // Allies render color (red) [0-255]
	semiclip_color_allies_G 200 // Allies render color (green) [0-255]
	semiclip_color_allies_B 0 // Allies render color (blue) [0-255]
	semiclip_color_axis_R 0 // Axis render color (red) [0-255]
	semiclip_color_axis_G 0 // Axis render color (green) [0-255]
	semiclip_color_axis_B 200 // Axis render color (blue) [0-255]
	
	---------------
	-*- Credits -*-
	---------------
	
	* SchlumPF*: Team Semiclip (main core)
	* joaquimandrade: Module: Semiclip (cvars)
	* ConnorMcLeod: show playersname (bugfix)
	* MeRcyLeZZ & VEN: Unstuck (function)
	* georgik57: for many suggestions 
	* Bugsy: for his bitsum macro's
	
	-----------------
	-*- Changelog -*-
	-----------------
	
	* v1.0:
		- initial release
	
	* v1.1:
		- Fixed: invisible player bones... like walls
	
	* v1.2:
		- faster! lower cpu!
	
	* v1.3:
		- Added: Day of Defeat support
		- Fixed: show playersname
	
	* v1.4:
		- Added: 2 new cvars for render mode & amt
		- made plugin 700% faster!
	
	* v1.5:
		- Added: automatic unstuck function for blockteam,
		   unstuck delay
	
	* v1.5.1:
		- Fixed: DoD 1.3 spawn classnames
	
	* v1.6:
		- Added: team_semiclip.cfg, no one block befor
		   zp_round_started, biohazard 2.0 support,
		   clip fade only in distance range
	
	* v1.6.1:
		- Added: spectator support
		- Fixed: trespass enemies dosen't work correctly
	
	* v1.6.2:
		- Fixed: small semiclip_blockteam "0" bug after
		   first zombie is chosen
	
	* v1.6.3:
		- Rewrite: Features - No one block before first
		   zombie is chosen
	
	* v1.7.0:
		- Added: semiclip fade
		- Fixed: v1.6.3 broke bot support
	
	* v1.8.0:
		- Added: new cvars for fade minimum, radius
		   current spectating player fade and +use
		   button to get semiclip only when holding
	
	* v1.8.1:
		- Fixed: plugin is now working as intended,
		   for all scripted of amxmodx plugin's like
		   kreedz bhop maps etc
	
	* v1.8.2:
		- Added: new cvars for render color and fx,
		   bitsum vars, knife trace to next enemy
		   when you stay inside a teammate and aiming a
		   enemy for CS and DoD
		- Rewrite: some stuff for optimization plugin,
		   lower cpu/memory usage
		- Fixed: cvar checking for zombie plague
		   and biohazard (plugin_init), TeamID on DoD
	
	* v1.8.3:
		- Added: new cvar for knife trace feature
		- Rewrite: unstuck feature only for cs,
		   push button check from prethink to cmdstart
		- Fixed: plugin is now working as intended
	
	* v1.8.4:
		- Added: new cvar semiclip_duration
		- Rewrite: semiclip_button, this hijack
		   semiclip_blockteam so make sure to use
		   them right
	
	* v1.8.5:
		- Rewrite: semiclip_unstuck, for use team
		   specified spawnpoints or teleport random
		   around own place
	
	* v1.8.6:
		- Added: blockteam option 3 (no one have
		   semiclip) to hijack this use semiclip_button
		- Rewrite: semiclip_unstuck, for use team
		   specified spawnpoints, csdm spawnpoints
		   or teleport random around own place
	
	* v1.8.7:
		- Added: cvars for team/admin color
	
	* v1.8.8:
		- Added: new cvar semiclip_render to enable or
		   disable all render/color functions, native
		   tsc_set_user_rendering for special rendering
		- Re-add: DoD PTeam message hook for TeamID,
		   unstuck feature for DoD
		- Change: color cvars now have the correct names
	
	* v2.0.0:
		- Added: runtime error support for subplugins
		- Rewrite: many functions
		- Fixed: some potential crashes due to accessing
		   uninitialized entity's private data, plugin
		   is now working as intended
		- Change: split plugin for his own game
	
=================================================================================*/

#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <xs>

#if AMXX_VERSION_NUM < 180
	#assert AMX Mod X v1.8.0 or later library required!
#endif

#include <hamsandwich>

/*================================================================================
 [Constants, Offsets, Macros]
=================================================================================*/

new const PLUGIN_VERSION[] = "2.0"

#define DODW_AMERKNIFE		1
#define DODW_GERKNIFE		2
#define DODW_SPADE			19

const MAX_RENDER_AMOUNT		= 255 // do not change this
const SEMI_RENDER_AMOUNT	= 200
const Float:SPEC_INTERVAL	= 0.2 // do not change this
const Float:RANGE_INTERVAL	= 0.1 // do not change this

const PEV_SPEC_TARGET = pev_iuser2

enum (+= 35)
{
	TASK_SPECTATOR = 3000,
	TASK_RANGE,
	TASK_DURATION
}
#define ID_SPECTATOR	(taskid - TASK_SPECTATOR)
#define ID_RANGE		(taskid - TASK_RANGE)

const OFFSET_WEAPONOWNER = 89
const OFFSET_WEAPONID = 91
const OFFSET_LINUX = 5
const OFFSET_LINUX_WEAPONS = 4
const PDATA_SAFE = 2

new const WEAPON_ENTITY_NAMES[][] = { "", "weapon_amerknife", "weapon_gerknife", "weapon_colt", "weapon_luger",
"weapon_garand", "weapon_scopedkar", "weapon_thompson", "weapon_mp44", "weapon_spring", "weapon_kar",
"weapon_bar", "weapon_mp40", "weapon_mg42", "weapon_30cal", "weapon_spade", "weapon_m1carbine", "weapon_mg34",
"weapon_greasegun", "weapon_fg42", "weapon_k43", "weapon_enfield", "weapon_sten", "weapon_bren", "weapon_webley" }

new const AXIS_SPAWN_ENTITY_NAME[] = "info_player_axis"
new const ALLIES_SPAWN_ENTITY_NAME[] = "info_player_allies"

new const Float:random_own_place[][3] =
{
	{ 0.0, 0.0, 0.0 },
	{ -32.5, 0.0, 0.0 },
	{ 32.5, 0.0, 0.0 },
	{ 0.0, -32.5, 0.0 },
	{ 0.0, 32.5, 0.0 },
	{ -32.5, -32.5, 0.0 },
	{ -32.5, 32.5, 0.0 },
	{ 32.5, 32.5, 0.0 },
	{ 32.5, -32.5, 0.0 }
}

/*================================================================================
 [Global Variables]
=================================================================================*/

new cvar_iSemiClipRenderRadius, cvar_iSemiClipEnemies, cvar_iSemiClipButton,
cvar_flSemiClipUnstuckDelay, cvar_iSemiClipBlockTeams, cvar_iSemiClipUnstuck,
cvar_iSemiClipRenderMode, cvar_iSemiClipRenderAmt, cvar_iSemiClipRenderFade,
cvar_iSemiClipRenderFadeMin, cvar_iSemiClipRenderFadeSpec, cvar_iSemiClip,
cvar_iSemiClipRenderFx, cvar_iSemiClipKnifeTrace, cvar_flSemiClipDuration,
cvar_iSemiClipColorAllies[3], cvar_iSemiClipColorAxis[3], cvar_iSemiClipRender,
cvar_iSemiClipColorAdmin[3], cvar_szSemiClipColorFlag

new g_iMaxPlayers, g_iAddToFullPack, g_iTraceLine, g_iCmdStart

new g_iSpawnCountAxis, Float:g_flSpawnsAxis[32][3],
g_iSpawnCountAllies, Float:g_flSpawnsAllies[32][3]

new g_iCachedSemiClip, g_iCachedEnemies, g_iCachedBlockTeams, g_iCachedUnstuck,
Float:g_flCachedUnstuckDelay, g_iCachedFadeMin, g_iCachedFadeSpec,
g_iCachedMode, g_iCachedRadius, g_iCachedAmt, g_iCachedFx, g_iCachedRender,
g_iCachedFade, g_iCachedButton, g_iCachedKnifeTrace, g_iCachedColorAllies[3],
g_iCachedColorAxis[3], g_iCachedColorAdmin[3], g_iCachedColorFlag

new bs_IsAlive, bs_IsConnected, bs_IsBot, bs_IsSolid, bs_InSemiClip, bs_InButton, bs_IsAdmin
new g_iTeam[33], g_iSpectating[33], g_iSpectatingTeam[33], g_iCurrentWeapon[33], g_iRange[33][33]

#define add_bitsum(%1,%2)	(%1 |= (1<<(%2-1)))
#define del_bitsum(%1,%2)	(%1 &= ~(1<<(%2-1)))
#define get_bitsum(%1,%2)	(%1 & (1<<(%2-1)))

#define is_user_valid_alive(%1)		(1 <= %1 <= g_iMaxPlayers && get_bitsum(bs_IsAlive, %1))
#define is_same_team(%1,%2)			(g_iTeam[%1] == g_iTeam[%2])

// tsc_set_user_rendering
enum
{
	SPECIAL_MODE = 0,
	SPECIAL_AMT,
	SPECIAL_FX,
	MAX_SPECIAL
}
new bs_IsSpecial
new g_iRenderSpecial[33][MAX_SPECIAL]
new g_iRenderSpecialColor[33][MAX_SPECIAL]

/*================================================================================
 [Natives, Init and Cfg]
=================================================================================*/

public plugin_natives()
{
	register_native("scm_set_user_rendering", "native_set_rendering", 1)
}

public plugin_init()
{
	register_plugin("DoD Semiclip Mod", PLUGIN_VERSION, "schmurgel1983")
	
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	
	RegisterHam(Ham_Spawn, "player", "fwd_PlayerSpawn_Post", 1)
	RegisterHam(Ham_Killed, "player", "fwd_PlayerKilled")
	RegisterHam(Ham_Player_PreThink, "player", "fwd_Player_PreThink_Post", 1)
	RegisterHam(Ham_Player_PostThink, "player", "fwd_Player_PostThink")
	
	g_iAddToFullPack = register_forward(FM_AddToFullPack, "fwd_AddToFullPack_Post", 1)
	g_iTraceLine = register_forward(FM_TraceLine, "fwd_TraceLine_Post", 1)
	g_iCmdStart = register_forward(FM_CmdStart, "fwd_CmdStart")
	
	register_message(get_user_msgid("PTeam"), "message_PTeam")
	for (new i = 1; i < sizeof WEAPON_ENTITY_NAMES; i++)
		if (WEAPON_ENTITY_NAMES[i][0]) RegisterHam(Ham_Item_Deploy, WEAPON_ENTITY_NAMES[i], "fwd_Item_Deploy_Post", 1)
	
	cvar_iSemiClip = register_cvar("semiclip", "1")
	cvar_iSemiClipBlockTeams = register_cvar("semiclip_blockteam", "0")
	cvar_iSemiClipEnemies = register_cvar("semiclip_enemies", "0")
	cvar_iSemiClipUnstuck = register_cvar("semiclip_unstuck", "1")
	cvar_flSemiClipUnstuckDelay = register_cvar("semiclip_unstuckdelay", "0.1")
	cvar_iSemiClipButton = register_cvar("semiclip_button", "0")
	cvar_iSemiClipKnifeTrace = register_cvar("semiclip_knife_trace", "0")
	cvar_flSemiClipDuration = register_cvar("semiclip_duration", "0")
	
	cvar_iSemiClipRender = register_cvar("semiclip_render", "1")
	cvar_iSemiClipRenderMode = register_cvar("semiclip_rendermode", "1")
	cvar_iSemiClipRenderAmt = register_cvar("semiclip_renderamt", "1")
	cvar_iSemiClipRenderFx = register_cvar("semiclip_renderfx", "19")
	cvar_iSemiClipRenderRadius = register_cvar("semiclip_renderradius", "250")
	cvar_iSemiClipRenderFade = register_cvar("semiclip_renderfade", "0")
	cvar_iSemiClipRenderFadeMin = register_cvar("semiclip_renderfademin", "25")
	cvar_iSemiClipRenderFadeSpec = register_cvar("semiclip_renderfadespec", "1")
	
	cvar_szSemiClipColorFlag = register_cvar("semiclip_color_admin_flag", "b")
	cvar_iSemiClipColorAdmin[0] = register_cvar("semiclip_color_admin_R", "0")
	cvar_iSemiClipColorAdmin[1] = register_cvar("semiclip_color_admin_G", "0")
	cvar_iSemiClipColorAdmin[2] = register_cvar("semiclip_color_admin_B", "200")
	cvar_iSemiClipColorAllies[0] = register_cvar("semiclip_color_allies_R", "0")
	cvar_iSemiClipColorAllies[1] = register_cvar("semiclip_color_allies_G", "200")
	cvar_iSemiClipColorAllies[2] = register_cvar("semiclip_color_allies_B", "0")
	cvar_iSemiClipColorAxis[0] = register_cvar("semiclip_color_axis_R", "200")
	cvar_iSemiClipColorAxis[1] = register_cvar("semiclip_color_axis_G", "0")
	cvar_iSemiClipColorAxis[2] = register_cvar("semiclip_color_axis_B", "0")
	
	register_cvar("DoD_Semiclip_Mod_version", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY)
	set_cvar_string("DoD_Semiclip_Mod_version", PLUGIN_VERSION)
	
	g_iMaxPlayers = get_maxplayers()
}

public plugin_cfg()
{
	new configsdir[32]
	get_configsdir(configsdir, charsmax(configsdir))
	server_cmd("exec %s/scm/main.cfg", configsdir)
	
	new ent
	ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	
	if (pev_valid(ent))
	{
		register_think("ent_cache_cvars", "cache_cvars_think")
		
		set_pev(ent, pev_classname, "ent_cache_cvars")
		set_pev(ent, pev_nextthink, get_gametime() + 1.0)
	}
	else
	{
		set_task(1.0, "cache_cvars")
		set_task(12.0, "cache_cvars", _, _, _, "b")
	}
	
	set_task(1.5, "load_spawns")
}

public plugin_pause()
{
	unregister_forward(FM_AddToFullPack, g_iAddToFullPack, 1)
	unregister_forward(FM_TraceLine, g_iTraceLine, 1)
	unregister_forward(FM_CmdStart, g_iCmdStart)
	
	static id
	for (id = 1; id <= g_iMaxPlayers; id++)
	{
		if (!get_bitsum(bs_IsConnected, id) || !get_bitsum(bs_IsAlive, id)) continue
		
		if (get_bitsum(bs_InSemiClip, id))
		{
			set_pev(id, pev_solid, SOLID_SLIDEBOX)
			del_bitsum(bs_InSemiClip, id);
		}
	}
}

public plugin_unpause()
{
	g_iAddToFullPack = register_forward(FM_AddToFullPack, "fwd_AddToFullPack_Post", 1)
	g_iTraceLine = register_forward(FM_TraceLine, "fwd_TraceLine_Post", 1)
	g_iCmdStart = register_forward(FM_CmdStart, "fwd_CmdStart")
}

public client_putinserver(id)
{
	add_bitsum(bs_IsConnected, id);
	set_cvars(id)
	
	set_task(RANGE_INTERVAL, "range_check", id+TASK_RANGE, _, _, "b")
	
	if (is_user_bot(id))
	{
		add_bitsum(bs_IsBot, id);
		add_bitsum(bs_InButton, id);
	}
	else
	{
		set_task(SPEC_INTERVAL, "spec_check", id+TASK_SPECTATOR, _, _, "b")
	}
}

public client_disconnect(id)
{
	del_bitsum(bs_IsConnected, id);
	set_cvars(id)
	remove_task(id+TASK_RANGE)
	remove_task(id+TASK_SPECTATOR)
}

/*================================================================================
 [Main Events]
=================================================================================*/

public event_round_start()
{
	remove_task(TASK_DURATION)
	
	if (get_pcvar_float(cvar_flSemiClipDuration) > 0.0)
	{
		set_pcvar_num(cvar_iSemiClip, 1)
		g_iCachedSemiClip = 1
		
		set_task(get_pcvar_float(cvar_flSemiClipDuration), "duration_disable_plugin", TASK_DURATION)
	}
}

/*================================================================================
 [Main Forwards]
=================================================================================*/

public fwd_PlayerSpawn_Post(id)
{
	if (!is_user_alive(id) || !g_iTeam[id])
		return
	
	add_bitsum(bs_IsAlive, id);
	remove_task(id+TASK_SPECTATOR)
	g_iTeam[id] = pev(id, pev_team)
}

public fwd_PlayerKilled(id)
{
	del_bitsum(bs_IsAlive, id);
	del_bitsum(bs_InSemiClip, id);
	g_iTeam[id] = 3
	
	if (!get_bitsum(bs_IsBot, id))
		set_task(SPEC_INTERVAL, "spec_check", id+TASK_SPECTATOR, _, _, "b")
}

public fwd_Player_PreThink_Post(id)
{
	if (!g_iCachedSemiClip || !get_bitsum(bs_IsAlive, id))
		return FMRES_IGNORED
	
	static i
	for (i = 1; i <= g_iMaxPlayers; i++)
	{
		if (!get_bitsum(bs_IsConnected, i) || !get_bitsum(bs_IsAlive, i)) continue
		
		if (!get_bitsum(bs_InSemiClip, i)) add_bitsum(bs_IsSolid, i);
		else del_bitsum(bs_IsSolid, i);
	}
	
	if (get_bitsum(bs_IsSolid, id))
		for (i = 1; i <= g_iMaxPlayers; i++)
		{
			if (!get_bitsum(bs_IsConnected, i) || !get_bitsum(bs_IsAlive, i) || !get_bitsum(bs_IsSolid, i)) continue
			if (g_iRange[id][i] == MAX_RENDER_AMOUNT || i == id) continue
			
			switch (g_iCachedButton)
			{
				case 3: // BOTH
				{
					if (get_bitsum(bs_InButton, id))
					{
						if (!g_iCachedEnemies && !is_same_team(i, id)) continue
					}
					else if (query_enemies(id, i)) continue
				}
				case 1, 2: // AXIS or ALLIES
				{
					if (get_bitsum(bs_InButton, id) && g_iCachedButton == g_iTeam[id] && g_iCachedButton == g_iTeam[i])
					{
						if (g_iCachedEnemies && !is_same_team(i, id)) continue
					}
					else if (query_enemies(id, i)) continue
				}
				default: if (query_enemies(id, i)) continue;
			}
			
			set_pev(i, pev_solid, SOLID_NOT)
			add_bitsum(bs_InSemiClip, i);
		}
	
	return FMRES_IGNORED
}

public fwd_Player_PostThink(id)
{
	if (!g_iCachedSemiClip || !get_bitsum(bs_IsAlive, id))
		return FMRES_IGNORED
	
	static i
	for (i = 1; i <= g_iMaxPlayers; i++)
	{
		if (!get_bitsum(bs_IsConnected, i) || !get_bitsum(bs_IsAlive, i)) continue
		
		if (get_bitsum(bs_InSemiClip, i))
		{
			set_pev(i, pev_solid, SOLID_SLIDEBOX)
			del_bitsum(bs_InSemiClip, i);
		}
	}
	
	return FMRES_IGNORED
}

public fwd_AddToFullPack_Post(es_handle, e, ent, host, flags, player, pSet)
{
	if (!g_iCachedSemiClip || !player) return FMRES_IGNORED
	
	if (g_iTeam[host] == 3)
	{
		if (!g_iCachedRender || get_bitsum(bs_IsBot, host) || !get_bitsum(bs_IsAlive, g_iSpectating[host]) || !get_bitsum(bs_IsAlive, ent)) return FMRES_IGNORED
		if (g_iRange[g_iSpectating[host]][ent] == MAX_RENDER_AMOUNT) return FMRES_IGNORED
		if (!g_iCachedFadeSpec && g_iSpectating[host] == ent) return FMRES_IGNORED
		
		switch (g_iCachedButton)
		{
			case 3: // BOTH
			{
				if (get_bitsum(bs_InButton, g_iSpectating[host]))
				{
					if (!g_iCachedEnemies && !is_same_team(ent, g_iSpectating[host])) return FMRES_IGNORED
				}
				else if (query_enemies(g_iSpectating[host], ent)) return FMRES_IGNORED
			}
			case 1, 2: // AXIS or ALLIES
			{
				if (get_bitsum(bs_InButton, g_iSpectating[host]) && g_iCachedButton == g_iTeam[g_iSpectating[host]] && g_iCachedButton == g_iTeam[ent])
				{
					if (g_iCachedEnemies && !is_same_team(ent, g_iSpectating[host])) return FMRES_IGNORED
				}
				else if (query_enemies(g_iSpectating[host], ent)) return FMRES_IGNORED
			}
			default: if (query_enemies(g_iSpectating[host], ent)) return FMRES_IGNORED;
		}
		
		if (get_bitsum(bs_IsSpecial, ent))
		{
			set_es(es_handle, ES_RenderMode, g_iRenderSpecial[ent][SPECIAL_MODE])
			set_es(es_handle, ES_RenderAmt, g_iRenderSpecial[ent][SPECIAL_AMT])
			set_es(es_handle, ES_RenderFx, g_iRenderSpecial[ent][SPECIAL_FX])
			set_es(es_handle, ES_RenderColor, g_iRenderSpecialColor[ent])
		}
		else
		{
			set_es(es_handle, ES_RenderMode, g_iCachedMode)
			set_es(es_handle, ES_RenderAmt, g_iRange[g_iSpectating[host]][ent])
			set_es(es_handle, ES_RenderFx, g_iCachedFx)
			switch (g_iTeam[ent])
			{
				case 1: get_bitsum(bs_IsAdmin, ent) ? set_es(es_handle, ES_RenderColor, g_iCachedColorAdmin) : set_es(es_handle, ES_RenderColor, g_iCachedColorAllies);
				case 2: get_bitsum(bs_IsAdmin, ent) ? set_es(es_handle, ES_RenderColor, g_iCachedColorAdmin) : set_es(es_handle, ES_RenderColor, g_iCachedColorAxis);
			}
		}
		
		return FMRES_IGNORED
	}
	
	if (!get_bitsum(bs_IsAlive, host) || !get_bitsum(bs_IsAlive, ent) || !get_bitsum(bs_IsSolid, host) || !get_bitsum(bs_IsSolid, ent)) return FMRES_IGNORED
	if (g_iRange[host][ent] == MAX_RENDER_AMOUNT) return FMRES_IGNORED
	
	switch (g_iCachedButton)
	{
		case 3: // BOTH
		{
			if (get_bitsum(bs_InButton, host))
			{
				if (!g_iCachedEnemies && !is_same_team(ent, host)) return FMRES_IGNORED
			}
			else if (query_enemies(host, ent)) return FMRES_IGNORED
		}
		case 1, 2: // AXIS or ALLIES
		{
			if (get_bitsum(bs_InButton, host) && g_iCachedButton == g_iTeam[host] && g_iCachedButton == g_iTeam[ent])
			{
				if (g_iCachedEnemies && !is_same_team(ent, host)) return FMRES_IGNORED
			}
			else if (query_enemies(host, ent)) return FMRES_IGNORED
		}
		default: if (query_enemies(host, ent)) return FMRES_IGNORED;
	}
	
	set_es(es_handle, ES_Solid, SOLID_NOT)
	
	if (!g_iCachedRender) return FMRES_IGNORED
	
	if (get_bitsum(bs_IsSpecial, ent))
	{
		set_es(es_handle, ES_RenderMode, g_iRenderSpecial[ent][SPECIAL_MODE])
		set_es(es_handle, ES_RenderAmt, g_iRenderSpecial[ent][SPECIAL_AMT])
		set_es(es_handle, ES_RenderFx, g_iRenderSpecial[ent][SPECIAL_FX])
		set_es(es_handle, ES_RenderColor, g_iRenderSpecialColor[ent])
	}
	else
	{
		set_es(es_handle, ES_RenderMode, g_iCachedMode)
		set_es(es_handle, ES_RenderAmt, g_iRange[host][ent])
		set_es(es_handle, ES_RenderFx, g_iCachedFx)
		switch (g_iTeam[ent])
		{
			case 1: get_bitsum(bs_IsAdmin, ent) ? set_es(es_handle, ES_RenderColor, g_iCachedColorAdmin) : set_es(es_handle, ES_RenderColor, g_iCachedColorAllies);
			case 2: get_bitsum(bs_IsAdmin, ent) ? set_es(es_handle, ES_RenderColor, g_iCachedColorAdmin) : set_es(es_handle, ES_RenderColor, g_iCachedColorAxis);
		}
	}
	
	return FMRES_IGNORED
}

public fwd_TraceLine_Post(Float:vStart[3], Float:vEnd[3], noMonsters, id, trace)
{
	if (!g_iCachedSemiClip || !g_iCachedKnifeTrace || !is_user_valid_alive(id))
		return FMRES_IGNORED
	
	switch (g_iCurrentWeapon[id])
	{
		case DODW_AMERKNIFE, DODW_GERKNIFE, DODW_SPADE: { /* lets trace */ }
		default: return FMRES_IGNORED;
	}
	
	new Float:flFraction
	get_tr2(trace, TR_flFraction, flFraction)
	if (flFraction >= 1.0)
		return FMRES_IGNORED
	
	new pHit = get_tr2(trace, TR_pHit)
	if (!is_user_valid_alive(pHit) || !is_same_team(id, pHit) || entity_range(id, pHit) > 48.0)
		return FMRES_IGNORED
	
	new	Float:start[3], Float:view_ofs[3], Float:direction[3], Float:tlStart[3], Float:tlEnd[3]
	
	pev(id, pev_origin, start)
	pev(id, pev_view_ofs, view_ofs)
	xs_vec_add(start, view_ofs, start)
	
	velocity_by_aim(id, 22, direction)
	xs_vec_add(direction, start, tlStart)
	velocity_by_aim(id, 48, direction)
	xs_vec_add(direction, start, tlEnd)
	
	engfunc(EngFunc_TraceLine, tlStart, tlEnd, noMonsters|DONT_IGNORE_MONSTERS, pHit, 0)
	
	new tHit = get_tr2(0, TR_pHit)
	if (!is_user_valid_alive(tHit) || is_same_team(id, tHit))
		return FMRES_IGNORED
	
	set_tr2(trace, TR_AllSolid, get_tr2(0, TR_AllSolid))
	set_tr2(trace, TR_StartSolid, get_tr2(0, TR_StartSolid))
	set_tr2(trace, TR_InOpen, get_tr2(0, TR_InOpen))
	set_tr2(trace, TR_InWater, get_tr2(0, TR_InWater))
	set_tr2(trace, TR_iHitgroup, get_tr2(0, TR_iHitgroup))
	set_tr2(trace, TR_pHit, tHit)
	
	return FMRES_IGNORED
}

public fwd_CmdStart(id, handle)
{
	if (!g_iCachedSemiClip || !g_iCachedButton || !get_bitsum(bs_IsAlive, id) || get_bitsum(bs_IsBot, id))
		return
	
	(get_uc(handle, UC_Buttons) & IN_USE) ? add_bitsum(bs_InButton, id) : del_bitsum(bs_InButton, id);
}

public fwd_Item_Deploy_Post(ent)
{
	static owner ; owner = ham_dod_get_weapon_ent_owner(ent)
	
	if (!is_user_valid_alive(owner))
		return HAM_IGNORED
	
	g_iCurrentWeapon[owner] = fm_dod_get_weapon_id(ent)
	
	return HAM_IGNORED
}

/*================================================================================
 [Other Functions and Tasks]
=================================================================================*/

public cache_cvars()
{
	g_iCachedSemiClip = !!get_pcvar_num(cvar_iSemiClip)
	g_iCachedEnemies = !!get_pcvar_num(cvar_iSemiClipEnemies)
	g_iCachedBlockTeams = clamp(get_pcvar_num(cvar_iSemiClipBlockTeams), 0, 3)
	g_iCachedUnstuck = clamp(get_pcvar_num(cvar_iSemiClipUnstuck), 0, 2)
	g_flCachedUnstuckDelay = floatclamp(get_pcvar_float(cvar_flSemiClipUnstuckDelay), 0.0, 3.0)
	g_iCachedButton = clamp(get_pcvar_num(cvar_iSemiClipButton), 0, 3)
	g_iCachedKnifeTrace = !!get_pcvar_num(cvar_iSemiClipKnifeTrace)
	
	g_iCachedRender = !!get_pcvar_num(cvar_iSemiClipRender)
	g_iCachedMode = clamp(get_pcvar_num(cvar_iSemiClipRenderMode), 0, 5)
	g_iCachedAmt = clamp(get_pcvar_num(cvar_iSemiClipRenderAmt), 0, 255)
	g_iCachedFx = clamp(get_pcvar_num(cvar_iSemiClipRenderFx), 0, 20)
	g_iCachedFade = !!get_pcvar_num(cvar_iSemiClipRenderFade)
	g_iCachedFadeMin = clamp(get_pcvar_num(cvar_iSemiClipRenderFadeMin), 0, SEMI_RENDER_AMOUNT)
	g_iCachedFadeSpec = !!get_pcvar_num(cvar_iSemiClipRenderFadeSpec)
	g_iCachedRadius = clamp(get_pcvar_num(cvar_iSemiClipRenderRadius), SEMI_RENDER_AMOUNT - g_iCachedFadeMin, 4095)
	
	static szFlags[24] ; get_pcvar_string(cvar_szSemiClipColorFlag, szFlags, charsmax(szFlags))	
	g_iCachedColorFlag = read_flags(szFlags)
	g_iCachedColorAllies[0] = clamp(get_pcvar_num(cvar_iSemiClipColorAllies[0]), 0, 255)
	g_iCachedColorAllies[1] = clamp(get_pcvar_num(cvar_iSemiClipColorAllies[1]), 0, 255)
	g_iCachedColorAllies[2] = clamp(get_pcvar_num(cvar_iSemiClipColorAllies[2]), 0, 255)
	g_iCachedColorAxis[0] = clamp(get_pcvar_num(cvar_iSemiClipColorAxis[0]), 0, 255)
	g_iCachedColorAxis[1] = clamp(get_pcvar_num(cvar_iSemiClipColorAxis[1]), 0, 255)
	g_iCachedColorAxis[2] = clamp(get_pcvar_num(cvar_iSemiClipColorAxis[2]), 0, 255)
	g_iCachedColorAdmin[0] = clamp(get_pcvar_num(cvar_iSemiClipColorAdmin[0]), 0, 255)
	g_iCachedColorAdmin[1] = clamp(get_pcvar_num(cvar_iSemiClipColorAdmin[1]), 0, 255)
	g_iCachedColorAdmin[2] = clamp(get_pcvar_num(cvar_iSemiClipColorAdmin[2]), 0, 255)
	
	static id
	for (id = 1; id <= g_iMaxPlayers; id++)
	{
		if (!get_bitsum(bs_IsConnected, id)) continue
		
		(get_user_flags(id) & g_iCachedColorFlag) ? add_bitsum(bs_IsAdmin, id) : del_bitsum(bs_IsAdmin, id);
	}
}

public cache_cvars_think(ent)
{
	if (!pev_valid(ent)) return;
	
	g_iCachedSemiClip = !!get_pcvar_num(cvar_iSemiClip)
	g_iCachedEnemies = !!get_pcvar_num(cvar_iSemiClipEnemies)
	g_iCachedBlockTeams = clamp(get_pcvar_num(cvar_iSemiClipBlockTeams), 0, 3)
	g_iCachedUnstuck = clamp(get_pcvar_num(cvar_iSemiClipUnstuck), 0, 2)
	g_flCachedUnstuckDelay = floatclamp(get_pcvar_float(cvar_flSemiClipUnstuckDelay), 0.0, 3.0)
	g_iCachedButton = clamp(get_pcvar_num(cvar_iSemiClipButton), 0, 3)
	g_iCachedKnifeTrace = !!get_pcvar_num(cvar_iSemiClipKnifeTrace)
	
	g_iCachedRender = !!get_pcvar_num(cvar_iSemiClipRender)
	g_iCachedMode = clamp(get_pcvar_num(cvar_iSemiClipRenderMode), 0, 5)
	g_iCachedAmt = clamp(get_pcvar_num(cvar_iSemiClipRenderAmt), 0, 255)
	g_iCachedFx = clamp(get_pcvar_num(cvar_iSemiClipRenderFx), 0, 20)
	g_iCachedFade = !!get_pcvar_num(cvar_iSemiClipRenderFade)
	g_iCachedFadeMin = clamp(get_pcvar_num(cvar_iSemiClipRenderFadeMin), 0, SEMI_RENDER_AMOUNT)
	g_iCachedFadeSpec = !!get_pcvar_num(cvar_iSemiClipRenderFadeSpec)
	g_iCachedRadius = clamp(get_pcvar_num(cvar_iSemiClipRenderRadius), SEMI_RENDER_AMOUNT - g_iCachedFadeMin, 4095)
	
	static szFlags[24] ; get_pcvar_string(cvar_szSemiClipColorFlag, szFlags, charsmax(szFlags))	
	g_iCachedColorFlag = read_flags(szFlags)
	g_iCachedColorAllies[0] = clamp(get_pcvar_num(cvar_iSemiClipColorAllies[0]), 0, 255)
	g_iCachedColorAllies[1] = clamp(get_pcvar_num(cvar_iSemiClipColorAllies[1]), 0, 255)
	g_iCachedColorAllies[2] = clamp(get_pcvar_num(cvar_iSemiClipColorAllies[2]), 0, 255)
	g_iCachedColorAxis[0] = clamp(get_pcvar_num(cvar_iSemiClipColorAxis[0]), 0, 255)
	g_iCachedColorAxis[1] = clamp(get_pcvar_num(cvar_iSemiClipColorAxis[1]), 0, 255)
	g_iCachedColorAxis[2] = clamp(get_pcvar_num(cvar_iSemiClipColorAxis[2]), 0, 255)
	g_iCachedColorAdmin[0] = clamp(get_pcvar_num(cvar_iSemiClipColorAdmin[0]), 0, 255)
	g_iCachedColorAdmin[1] = clamp(get_pcvar_num(cvar_iSemiClipColorAdmin[1]), 0, 255)
	g_iCachedColorAdmin[2] = clamp(get_pcvar_num(cvar_iSemiClipColorAdmin[2]), 0, 255)
	
	static id
	for (id = 1; id <= g_iMaxPlayers; id++)
	{
		if (!get_bitsum(bs_IsConnected, id)) continue
		
		(get_user_flags(id) & g_iCachedColorFlag) ? add_bitsum(bs_IsAdmin, id) : del_bitsum(bs_IsAdmin, id);
	}
	
	set_pev(ent, pev_nextthink, get_gametime() + 12.0)
}

public load_spawns()
{
	dod_collect_spawns_ents()
}

public random_spawn_delay(id)
{
	do_random_spawn(id, g_iCachedUnstuck)
}

// credits to MeRcyLeZZ
do_random_spawn(id, mode)
{
	if (!get_bitsum(bs_IsConnected, id) || !get_bitsum(bs_IsAlive, id))
		return
	
	static hull, sp_index, i
	hull = (pev(id, pev_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN
	
	switch (mode)
	{
		case 1: // Specified team
		{
			switch (g_iTeam[id])
			{
				case 1: // ALLIES
				{
					if (!g_iSpawnCountAllies)
						return
					
					sp_index = random_num(0, g_iSpawnCountAllies - 1)
					for (i = sp_index + 1; /*no condition*/; i++)
					{
						if (i >= g_iSpawnCountAllies) i = 0
						
						if (is_hull_vacant(g_flSpawnsAllies[i], hull))
						{
							engfunc(EngFunc_SetOrigin, id, g_flSpawnsAllies[i])
							break
						}
						
						if (i == sp_index)
							break
					}
				}
				case 2: // AXIS
				{
					if (!g_iSpawnCountAxis)
						return
					
					sp_index = random_num(0, g_iSpawnCountAxis - 1)
					for (i = sp_index + 1; /*no condition*/; i++)
					{
						if (i >= g_iSpawnCountAxis) i = 0
						
						if (is_hull_vacant(g_flSpawnsAxis[i], hull))
						{
							engfunc(EngFunc_SetOrigin, id, g_flSpawnsAxis[i])
							break
						}
						
						if (i == sp_index)
							break
					}
				}
			}
		}
		case 2: // Random around own place
		{
			new Float:origin[3], Float:new_origin[3], Float:final[3]
			pev(id, pev_origin, origin)
			
			for (new test = 0; test < sizeof random_own_place; test++)
			{
				final[0] = new_origin[0] = (origin[0] + random_own_place[test][0])
				final[1] = new_origin[1] = (origin[1] + random_own_place[test][1])
				final[2] = new_origin[2] = (origin[2] + random_own_place[test][2])
				
				new z = 0
				do
				{
					if (is_hull_vacant(final, hull))
					{
						test = sizeof random_own_place
						engfunc(EngFunc_SetOrigin, id, final)
						break
					}
					
					final[2] = new_origin[2] + (++z*20)
				}
				while (z < 5)
			}
		}
	}
}

// credits to MeRcyLeZZ (I rewritten it.)
dod_collect_spawns_ents()
{
	// AXIS
	new ent = -1
	
	while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", AXIS_SPAWN_ENTITY_NAME)) != 0)
	{
		new Float:originF[3]
		pev(ent, pev_origin, originF)
		g_flSpawnsAxis[g_iSpawnCountAxis][0] = originF[0]
		g_flSpawnsAxis[g_iSpawnCountAxis][1] = originF[1]
		g_flSpawnsAxis[g_iSpawnCountAxis][2] = originF[2]
		
		g_iSpawnCountAxis++
		if (g_iSpawnCountAxis >= sizeof g_flSpawnsAxis) break
	}
	
	// ALLIES
	ent = -1
	
	while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", ALLIES_SPAWN_ENTITY_NAME)) != 0)
	{
		new Float:originF[3]
		pev(ent, pev_origin, originF)
		g_flSpawnsAllies[g_iSpawnCountAllies][0] = originF[0]
		g_flSpawnsAllies[g_iSpawnCountAllies][1] = originF[1]
		g_flSpawnsAllies[g_iSpawnCountAllies][2] = originF[2]
		
		g_iSpawnCountAllies++
		if (g_iSpawnCountAllies >= sizeof g_flSpawnsAllies) break
	}
}

public range_check(taskid)
{
	if (!g_iCachedSemiClip)
		return
	
	static id
	for (id = 1; id <= g_iMaxPlayers; id++)
	{
		if (!get_bitsum(bs_IsConnected, id) || !get_bitsum(bs_IsAlive, id)) continue
		
		g_iRange[ID_RANGE][id] = calc_fade(ID_RANGE, id, g_iCachedFade)
	}
}

public spec_check(taskid)
{
	if (!g_iCachedSemiClip || get_bitsum(bs_IsAlive, ID_SPECTATOR))
		return
	
	static spec
	spec = pev(ID_SPECTATOR, PEV_SPEC_TARGET)
	
	if (get_bitsum(bs_IsAlive, spec))
	{
		g_iSpectating[ID_SPECTATOR] = spec
		g_iSpectatingTeam[ID_SPECTATOR] = g_iTeam[spec]
	}
}

public duration_disable_plugin()
{
	set_pcvar_num(cvar_iSemiClip, 0)
	g_iCachedSemiClip = 0
	
	for (new id = 1; id <= g_iMaxPlayers; id++)
	{
		if (!get_bitsum(bs_IsConnected, id) || !get_bitsum(bs_IsAlive, id)) continue
		
		if (get_bitsum(bs_InSemiClip, id))
		{
			set_pev(id, pev_solid, SOLID_SLIDEBOX)
			del_bitsum(bs_InSemiClip, id);
		}
		
		if (g_iCachedUnstuck && is_player_stuck(id))
			do_random_spawn(id, g_iCachedUnstuck)
	}
}

calc_fade(host, ent, mode)
{
	if (mode)
	{
		if (g_iCachedFadeMin > g_iCachedRadius)
			return MAX_RENDER_AMOUNT;
		
		static range ; range = floatround(entity_range(host, ent))
		
		if (range >= g_iCachedRadius)
			return MAX_RENDER_AMOUNT;
		
		static amount
		amount = SEMI_RENDER_AMOUNT - g_iCachedFadeMin
		amount = g_iCachedRadius / amount
		amount = range / amount + g_iCachedFadeMin
		
		return amount;
	}
	else
	{
		static range ; range = floatround(entity_range(host, ent))
		
		if (range < g_iCachedRadius)
			return g_iCachedAmt;
	}
	
	return MAX_RENDER_AMOUNT;
}

query_enemies(host, ent)
{
	if (g_iCachedBlockTeams == 3) return 1;
	
	switch (g_iCachedEnemies)
	{
		case 0: if (!is_same_team(ent, host) || g_iCachedBlockTeams == g_iTeam[ent]) return 1;
		case 1: if (g_iCachedBlockTeams == g_iTeam[ent] && is_same_team(ent, host)) return 1;
	}
	
	return 0;
}

set_cvars(id)
{
	del_bitsum(bs_IsAlive, id);
	del_bitsum(bs_IsBot, id);
	del_bitsum(bs_IsSolid, id);
	del_bitsum(bs_InSemiClip, id);
	del_bitsum(bs_IsSpecial, id);
	g_iTeam[id] = 0
}

/*================================================================================
 [Message Hooks]
=================================================================================*/

/*
	PTeam:
	read_data(1)	byte	EventEntity
	read_data(2)	byte	TeamIndex
*/
public message_PTeam(msg_id, msg_dest)
{
	if (msg_dest != MSG_ALL)
		return
	
	static id
	id = get_msg_arg_int(1)
	g_iTeam[id] = get_msg_arg_int(2) // 0 - UNASSIGNED | 1 - ALLIES | 2 - AXIS | 3 - SPECTATOR
	
	if (g_iCachedUnstuck && get_bitsum(bs_IsAlive, id) && g_iCachedBlockTeams == g_iTeam[id])
	{
		if (!is_player_stuck(id))
			return
		
		if (g_flCachedUnstuckDelay > 0.0)
			set_task(g_flCachedUnstuckDelay, "random_spawn_delay", id)
		else
			do_random_spawn(id, g_iCachedUnstuck)
	}
}

/*================================================================================
 [Custom Natives]
=================================================================================*/

// tsc_set_rendering(id, special = 0, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16)
public native_set_rendering(id, special, fx, r, g, b, render, amount)
{
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[Team Semiclip] Player is not in game (%d)", id)
		return 0;
	}
	
	switch (special)
	{
		case 0:
		{
			del_bitsum(bs_IsSpecial, id);
			
			return 1;
		}
		case 1:
		{
			add_bitsum(bs_IsSpecial, id);
			
			g_iRenderSpecial[id][SPECIAL_MODE] = clamp(render, 0, 5)
			g_iRenderSpecial[id][SPECIAL_AMT] = clamp(amount, 0, 255)
			g_iRenderSpecial[id][SPECIAL_FX] = clamp(fx, 0, 20)
			
			g_iRenderSpecialColor[id][0] = clamp(r, 0, 255)
			g_iRenderSpecialColor[id][1] = clamp(g, 0, 255)
			g_iRenderSpecialColor[id][2] = clamp(b, 0, 255)
			
			return 1;
		}
	}
	
	return 0;
}

/*================================================================================
 [Stocks]
=================================================================================*/

// credits to VEN
stock is_player_stuck(id)
{
	static Float:originF[3]
	pev(id, pev_origin, originF)
	
	engfunc(EngFunc_TraceHull, originF, originF, 0, (pev(id, pev_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN, id, 0)
	
	if (get_tr2(0, TR_StartSolid) || get_tr2(0, TR_AllSolid) || !get_tr2(0, TR_InOpen))
		return true;
	
	return false;
}

// credits to VEN
stock is_hull_vacant(Float:origin[3], hull)
{
	engfunc(EngFunc_TraceHull, origin, origin, 0, hull, 0, 0)
	
	if (!get_tr2(0, TR_StartSolid) && !get_tr2(0, TR_AllSolid) && get_tr2(0, TR_InOpen))
		return true;
	
	return false;
}

// Stock by (probably) Twilight Suzuka -counts number of chars in a string
stock str_count(str[], searchchar)
{
	new count, i, len = strlen(str)
	
	for (i = 0; i <= len; i++)
	{
		if (str[i] == searchchar)
			count++
	}
	
	return count;
}

// credits to me :D
stock fm_dod_get_weapon_id(ent)
{
	if (pev_valid(ent) != PDATA_SAFE)
		return 0;
	
	return get_pdata_int(ent, OFFSET_WEAPONID, OFFSET_LINUX_WEAPONS);
}

// credits to me :D
stock ham_dod_get_weapon_ent_owner(ent)
{
	if (pev_valid(ent) != PDATA_SAFE)
		return 0;
	
	return get_pdata_cbase(ent, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS);
}

// amxmisc.inc
stock get_configsdir(name[], len)
{
	return get_localinfo("amxx_configsdir", name, len);
}
