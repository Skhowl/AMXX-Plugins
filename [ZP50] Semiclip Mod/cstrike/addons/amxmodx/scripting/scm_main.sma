/*================================================================================
	
		**********************************************
		********* [ZP50 Semiclip Mod 3.3.2] **********
		**********************************************
	
	----------------------
	-*- Licensing Info -*-
	----------------------
	
	ZP50 Semiclip Mod
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
	
=================================================================================*/

/*================================================================================
 [Plugin Customization]
=================================================================================*/

const Float:CVAR_INTERVAL  = 6.0		/* ? 6.0 */
const Float:SPEC_INTERVAL  = 0.2		/* ? 0.2 */
const Float:RANGE_INTERVAL = 0.1		/* It's like a 10 FPS server ? 0.1 */

#define MAX_PLAYERS     32	/* Server slots ? 32 */
#define MAX_REG_SPAWNS	24	/* Max cached regular spawns per team ? 24 */
#define MAX_CSDM_SPAWNS 60	/* CSDM 2.1.2 value if you have more increase it ? 60 */

/*================================================================================
 Customization ends here! Yes, that's it. Editing anything beyond
 here is not officially supported. Proceed at your own risk...
=================================================================================*/

/* Just a little bit extra, not too much */
#pragma dynamic 8192

#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>

/*================================================================================
 [Zombie Plague 5.0+ Includes]
=================================================================================*/

#define LIBRARY_BOTS_API "cs_ham_bots_api"
#include <cs_ham_bots_api>
#define LIBRARY_GAMEMODES "zp50_gamemodes"
#include <zp50_gamemodes>
#define LIBRARY_RANDOM_SPAWN "zp50_random_spawn"
#include <zp50_random_spawn>

/*================================================================================
 [TODO]
 
 nothing :)
 
=================================================================================*/

/*================================================================================
 [Constants, Offsets and Defines]
=================================================================================*/

new const PLUGIN_VERSION[]           = "3.3.2"
new const HUMAN_SPAWN_ENTITY_NAME[]  = "info_player_start"
new const ZOMBIE_SPAWN_ENTITY_NAME[] = "info_player_deathmatch"

#if AMXX_VERSION_NUM < 183
const Float:ANTI_BOOST_DISTANCE = 85.10 /* do not change this! ? 85.041169 */
#endif

const pev_spec_mode     = pev_iuser1
const pev_spec_target   = pev_iuser2

const m_hObserverTarget  = 447
const m_pPlayer          = 41
const linux_diff         = 5
const mac_diff           = 5	/* the same? (i don't have a mac pc or server) */
const linux_weapons_diff = 4
const mac_weapons_diff   = 4	/* the same? (i don't have a mac pc or server) */
const pdata_safe         = 2

const Ham:Ham_Player_SemiclipStart = Ham_Player_UpdateClientData	/* Ham_Player_UpdateClientData <|> Ham_Player_PreThink */
const Ham:Ham_Player_SemiclipEnd   = Ham_Item_ItemSlot				/* Ham_Item_ItemSlot <|> Ham_Player_PostThink */

enum (+= 35)
{
	TASK_SPECTATOR = 5000,
	TASK_RANGE,
	TASK_CVARS
}

/* tsc_set_user_rendering */
enum
{
	RENDER_MODE = 0,
	RENDER_AMT,
	RENDER_FX,
	MAX_RENDER
}

/* semiclip_color_* cvars */
enum
{
	COLOR_HUMAN = 0,
	COLOR_ZOMBIE,
	COLOR_ADMIN_HUMAN,
	COLOR_ADMIN_ZOMBIE,
	MAX_COLORS
}

/* Teams */
enum
{
	ZP_TEAM_UNASSIGNED = 0,
	ZP_TEAM_ZOMBIE,
	ZP_TEAM_HUMAN,
	ZP_TEAM_SPECTATOR
}

#define OUT_OF_RANGE -1

/*================================================================================
 [Global Variables]
=================================================================================*/

/* Cvar global */
new cvar_iSemiclip,
	cvar_iSemiclipUnstuck,
	cvar_szSemiclipColors[MAX_COLORS]

#if AMXX_VERSION_NUM < 183
new cvar_iSemiclipBlockTeam,
	cvar_iSemiclipEnemies,
	cvar_iSemiclipButton,
	cvar_iSemiclipButtonTrigger,
	cvar_iSemiclipButtonAntiBoost,
	cvar_iSemiclipButtonAntiStuck,
	cvar_iSemiclipUnstuckRender,
	cvar_iSemiclipKnifeTrace,
	cvar_iSemiclipRender,
	cvar_iSemiclipRender3rdPlugins,
	cvar_iSemiclipRenderFreeLook,
	cvar_iSemiclipNormalMode,
	cvar_iSemiclipNormalFx,
	cvar_iSemiclipNormalAmt,
	cvar_iSemiclipNormalSpec,
	cvar_iSemiclipFadeMode,
	cvar_iSemiclipFadeFx,
	cvar_iSemiclipFadeSpec,
	cvar_flSemiclipRadius,
	cvar_flSemiclipUnstuckDelay,
	cvar_flSemiclipFadeMin,
	cvar_flSemiclipFadeMax,
	cvar_szSemiclipColorFlag,
	cvar_iDisableInfection,
	cvar_iDisableMultiple,
	cvar_iDisableNemesis,
	cvar_iDisableSurvivor,
	cvar_iDisableSwarm,
	cvar_iDisablePlague,
	cvar_iDisableArmageddon
#else
new c_iDisableInfection,
	c_iDisableMultiple,
	c_iDisableNemesis,
	c_iDisableSurvivor,
	c_iDisableSwarm,
	c_iDisablePlague,
	c_iDisableArmageddon
#endif

/* Cvar cached */
new c_iSemiclip,
	c_iBlockTeam,
	c_iEnemies,
	c_iButton,
	c_iButtonTrigger,
	c_iButtonAntiBoost,
	c_iButtonAntiStuck,
	c_iUnstuck,
	c_iUnstuckRender,
	c_iKnifeTrace,
	c_iRender,
	c_i3rdPlugins,
	c_iFreeLook,
	c_iNormalMode,
	c_iNormalFx,
	c_iNormalAmt,
	c_iNormalSpec,
	c_iFadeMode,
	c_iFadeFx,
	c_iFadeSpec

new Float:c_flRadius,
	Float:c_flUnstuckDelay,
	Float:c_flFadeMin,
	Float:c_flFadeMax

new c_iColorFlag,
	c_iColors[MAX_COLORS][3]

/* Server global */
new bool:g_bGamemodes,
	bool:g_bDisableOnGamemode,
	bool:g_bZpRandomSpawn

new g_iAddToFullPack,
	g_iCmdStart,
	g_iTraceLine,
	g_iCvarEntity,
	g_iSpawnCountHuman,
	g_iSpawnCountZombie,
	g_iSpawnCountCSDM

new g_iInfection,
	g_iMultiple,
	g_iNemesis,
	g_iSurvivor,
	g_iSwarm,
	g_iPlague,
	g_iArmageddon

new Float:g_flSpawnsHuman[MAX_REG_SPAWNS][3],
	Float:g_flSpawnsZombie[MAX_REG_SPAWNS][3],
	Float:g_flSpawnsCSDM[MAX_CSDM_SPAWNS][3]

/* Client global */
new g_iTeam[MAX_PLAYERS+1],
	g_iRange[MAX_PLAYERS+1][MAX_PLAYERS+1],
	g_iSpectating[MAX_PLAYERS+1],
	g_iAntiBoost[MAX_PLAYERS+1][MAX_PLAYERS+1],
	g_iRender3rdPlugins[MAX_PLAYERS+1][MAX_RENDER],
	g_iRenderSpecial[MAX_PLAYERS+1][MAX_RENDER],
	g_iRenderSpecialColor[MAX_PLAYERS+1][MAX_RENDER]

new Float:g_flAbsMin[MAX_PLAYERS+1][3],
	Float:g_flAbsMax[MAX_PLAYERS+1][3]

/* Bitsum */
new bs_IsConnected,
	bs_IsAlive,
	bs_IsBot,
	bs_IsAdmin,
	bs_InSemiclip,
	bs_IsSolid,
	bs_InButton,
	bs_InAntiBoost,
	bs_WasInButton,
	bs_InKnifeSecAtk,
	bs_RenderSpecial,
	bs_IsDying

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

#define ID_SPECTATOR	(taskid - TASK_SPECTATOR)
#define ID_RANGE		(taskid - TASK_RANGE)

#define get_bitsum(%1,%2)   (%1 &   (1<<((%2-1)&31)))
#define add_bitsum(%1,%2)    %1 |=  (1<<((%2-1)&31))
#define del_bitsum(%1,%2)    %1 &= ~(1<<((%2-1)&31))

#define get_bitsum_array(%1,%2)   (%1[(%2-1)/32] &   (1<<((%2-1)&31)))
#define add_bitsum_array(%1,%2)    %1[(%2-1)/32] |=  (1<<((%2-1)&31))
#define del_bitsum_array(%1,%2)    %1[(%2-1)/32] &= ~(1<<((%2-1)&31))

#define UTIL_Vector_Add(%1,%2,%3)	(%3[0] = %1[0] + %2[0], %3[1] = %1[1] + %2[1], %3[2] = %1[2] + %2[2])
#define TSC_Vector_MA(%1,%2,%3,%4)	(%4[0] = %2[0] * %3 + %1[0], %4[1] = %2[1] * %3 + %1[1])

#define is_user_valid(%1)			(1 <= %1 <= g_iMaxPlayers)
#define is_user_valid_connected(%1)	(1 <= %1 <= g_iMaxPlayers && get_bitsum(bs_IsConnected, %1))
#define is_user_valid_alive(%1)		(1 <= %1 <= g_iMaxPlayers && get_bitsum(bs_IsAlive, %1) && !get_bitsum(bs_IsDying, %1))
#define is_same_team(%1,%2)			(g_iTeam[%1] == g_iTeam[%2])

/*================================================================================
 [Natives, Init and Cfg]
=================================================================================*/

public plugin_natives()
{
	/* TODO: maybe more? */
	register_native("scm_get_user_rendering", "fn_get_user_rendering")
	register_native("scm_set_user_rendering", "fn_set_user_rendering")
	register_native("scm_get_user_semiclip", "fn_get_user_semiclip")
	register_native("scm_get_user_anti_boost", "fn_get_user_anti_boost")
	register_library("cs_semiclip_mod")
	
	set_module_filter("module_filter")
}
public module_filter(module[])
{
	if (equal(module, LIBRARY_BOTS_API) || equal(module, LIBRARY_GAMEMODES) || equal(module, LIBRARY_RANDOM_SPAWN))
		return PLUGIN_HANDLED
	
	return PLUGIN_CONTINUE
}

public plugin_init()
{
	/* Check mods and register plugin */
	CheckMods()
	
	register_event("HLTV", "EventRoundStart", "a", "1=0", "2=0")
	
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", true)
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled", false)
	RegisterHam(Ham_Player_SemiclipStart, "player", "fw_PlayerSemiclip_Start", true)
	RegisterHam(Ham_Player_SemiclipEnd, "player", "fw_PlayerSemiclip_End", false)
	
	RegisterHamBots(Ham_Spawn, "fw_PlayerSpawn_Post", true)
	RegisterHamBots(Ham_Killed, "fw_PlayerKilled", false)
	RegisterHamBots(Ham_Player_SemiclipStart, "fw_PlayerSemiclip_Start", true)
	RegisterHamBots(Ham_Player_SemiclipEnd, "fw_PlayerSemiclip_End", false)
	
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife", "fw_Knife_PrimaryAttack", false)
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "fw_Knife_SecondaryAttack", false)
	
	register_forward(FM_ClientDisconnect, "fw_ClientDisconnect", false)
	g_iAddToFullPack = register_forward(FM_AddToFullPack, "fw_AddToFullPack_Post", true)
	g_iCmdStart = register_forward(FM_CmdStart, "fw_CmdStart_Post", true)
	
	register_touch("player", "player", "fw_Touch")
	
	register_message(get_user_msgid("TeamInfo"), "MessageTeamInfo")
	register_message(get_user_msgid("ClCorpse"), "MessageClCorpse")
	
	#if AMXX_VERSION_NUM >= 183
	/* General */
	bind_pcvar_num(cvar_iSemiclip = create_cvar("semiclip", "1", _, _, true, 0.0, true, 1.0), c_iSemiclip)
	bind_pcvar_num(create_cvar("semiclip_block_team", "0", _, _, true, 0.0, true, 3.0), c_iBlockTeam)
	bind_pcvar_num(create_cvar("semiclip_enemies", "0", _, _, true, 0.0, true, 1.0), c_iEnemies)
	bind_pcvar_float(create_cvar("semiclip_radius", "250.0", _, _, true, 0.0, true, 65535.0), c_flRadius)
	
	/* Button */
	bind_pcvar_num(create_cvar("semiclip_button", "0", _, _, true, 0.0, true, 3.0), c_iButton)
	bind_pcvar_num(create_cvar("semiclip_button_trigger", "32", _, _, true, 0.0, true, 65535.0), c_iButtonTrigger)
	bind_pcvar_num(create_cvar("semiclip_button_anti_boost", "1", _, _, true, 0.0, true, 1.0), c_iButtonAntiBoost)
	bind_pcvar_num(create_cvar("semiclip_button_anti_stuck", "0", _, _, true, 0.0, true, 1.0), c_iButtonAntiStuck)
	
	/* Unstuck */
	bind_pcvar_num(cvar_iSemiclipUnstuck = create_cvar("semiclip_unstuck", "4", _, _, true, 0.0, true, 4.0), c_iUnstuck)
	bind_pcvar_num(create_cvar("semiclip_unstuck_render", "1", _, _, true, 0.0, true, 1.0), c_iUnstuckRender)
	bind_pcvar_float(create_cvar("semiclip_unstuck_delay", "0", _, _, true, 0.0, true, 65535.0), c_flUnstuckDelay)
	
	/* Gamemodes */
	bind_pcvar_num(create_cvar("semiclip_disable_on_infection", "0", _, _, true, 0.0, true, 1.0), c_iDisableInfection)
	bind_pcvar_num(create_cvar("semiclip_disable_on_multiple", "0", _, _, true, 0.0, true, 1.0), c_iDisableMultiple)
	bind_pcvar_num(create_cvar("semiclip_disable_on_nemesis", "0", _, _, true, 0.0, true, 1.0), c_iDisableNemesis)
	bind_pcvar_num(create_cvar("semiclip_disable_on_survivor", "0", _, _, true, 0.0, true, 1.0), c_iDisableSurvivor)
	bind_pcvar_num(create_cvar("semiclip_disable_on_swarm", "0", _, _, true, 0.0, true, 1.0), c_iDisableSwarm)
	bind_pcvar_num(create_cvar("semiclip_disable_on_plague", "0", _, _, true, 0.0, true, 1.0), c_iDisablePlague)
	bind_pcvar_num(create_cvar("semiclip_disable_on_armageddon", "0", _, _, true, 0.0, true, 1.0), c_iDisableArmageddon)
	
	/* Other */
	bind_pcvar_num(create_cvar("semiclip_knife_trace", "0", _, _, true, 0.0, true, 3.0), c_iKnifeTrace)
	
	/* Render */
	bind_pcvar_num(create_cvar("semiclip_render", "0", _, _, true, 0.0, true, 2.0), c_iRender)
	bind_pcvar_num(create_cvar("semiclip_render_3rd_plugins", "0", _, _, true, 0.0, true, 1.0), c_i3rdPlugins)
	bind_pcvar_num(create_cvar("semiclip_render_free_look", "1", _, _, true, 0.0, true, 1.0), c_iFreeLook)
	
	/* Normal */
	bind_pcvar_num(create_cvar("semiclip_normal_mode", "1", _, _, true, 0.0, true, 5.0), c_iNormalMode)
	bind_pcvar_num(create_cvar("semiclip_normal_fx", "19", _, _, true, 0.0, true, 20.0), c_iNormalFx)
	bind_pcvar_num(create_cvar("semiclip_normal_amt", "4", _, _, true, 0.0, true, 255.0), c_iNormalAmt)
	bind_pcvar_num(create_cvar("semiclip_normal_spec", "1", _, _, true, 0.0, true, 1.0), c_iNormalSpec)
	
	/* Fade */
	bind_pcvar_num(create_cvar("semiclip_fade_mode", "2", _, _, true, 0.0, true, 5.0), c_iFadeMode)
	bind_pcvar_num(create_cvar("semiclip_fade_fx", "0", _, _, true, 0.0, true, 20.0), c_iFadeFx)
	bind_pcvar_float(create_cvar("semiclip_fade_min", "130", _, _, true, 0.0, true, 255.0), c_flFadeMin)
	bind_pcvar_float(create_cvar("semiclip_fade_max", "225", _, _, true, 0.0, true, 255.0), c_flFadeMax)
	bind_pcvar_num(create_cvar("semiclip_fade_spec", "1", _, _, true, 0.0, true, 1.0), c_iFadeSpec)
	
	/* Color */
	hook_cvar_change(create_cvar("semiclip_color_admin_flag", "b"), "fw_ColorFlagChange")
	hook_cvar_change(cvar_szSemiclipColors[COLOR_ADMIN_ZOMBIE] = create_cvar("semiclip_color_admin_zombies", "255 63 63"), "fw_ColorChange")
	hook_cvar_change(cvar_szSemiclipColors[COLOR_ADMIN_HUMAN] = create_cvar("semiclip_color_admin_humans", "153 204 255"), "fw_ColorChange")
	hook_cvar_change(cvar_szSemiclipColors[COLOR_ZOMBIE] = create_cvar("semiclip_color_zombies", "255 63 63"), "fw_ColorChange")
	hook_cvar_change(cvar_szSemiclipColors[COLOR_HUMAN] = create_cvar("semiclip_color_humans", "153 204 255"), "fw_ColorChange")
	#else
	/* General */
	cvar_iSemiclip = register_cvar("semiclip", "1")
	cvar_iSemiclipBlockTeam = register_cvar("semiclip_block_team", "0")
	cvar_iSemiclipEnemies = register_cvar("semiclip_enemies", "0")
	cvar_flSemiclipRadius = register_cvar("semiclip_radius", "250.0")
	
	/* Button */
	cvar_iSemiclipButton = register_cvar("semiclip_button", "0")
	cvar_iSemiclipButtonTrigger = register_cvar("semiclip_button_trigger", "32")
	cvar_iSemiclipButtonAntiBoost = register_cvar("semiclip_button_anti_boost", "1")
	cvar_iSemiclipButtonAntiStuck = register_cvar("semiclip_button_anti_stuck", "0")
	
	/* Unstuck */
	cvar_iSemiclipUnstuck = register_cvar("semiclip_unstuck", "4")
	cvar_iSemiclipUnstuckRender = register_cvar("semiclip_unstuck_render", "1")
	cvar_flSemiclipUnstuckDelay = register_cvar("semiclip_unstuck_delay", "0")
	
	/* Gamemodes */
	cvar_iDisableInfection = register_cvar("semiclip_disable_on_infection", "0")
	cvar_iDisableMultiple = register_cvar("semiclip_disable_on_multiple", "0")
	cvar_iDisableNemesis = register_cvar("semiclip_disable_on_nemesis", "0")
	cvar_iDisableSurvivor = register_cvar("semiclip_disable_on_survivor", "0")
	cvar_iDisableSwarm = register_cvar("semiclip_disable_on_swarm", "0")
	cvar_iDisablePlague = register_cvar("semiclip_disable_on_plague", "0")
	cvar_iDisableArmageddon = register_cvar("semiclip_disable_on_armageddon", "0")
	
	/* Other */
	cvar_iSemiclipKnifeTrace = register_cvar("semiclip_knife_trace", "0")
	
	/* Render */
	cvar_iSemiclipRender = register_cvar("semiclip_render", "0")
	cvar_iSemiclipRender3rdPlugins = register_cvar("semiclip_render_3rd_plugins", "0")
	cvar_iSemiclipRenderFreeLook = register_cvar("semiclip_render_free_look", "1")
	
	/* Normal */
	cvar_iSemiclipNormalMode = register_cvar("semiclip_normal_mode", "1")
	cvar_iSemiclipNormalFx = register_cvar("semiclip_normal_fx", "19")
	cvar_iSemiclipNormalAmt = register_cvar("semiclip_normal_amt", "4")
	cvar_iSemiclipNormalSpec = register_cvar("semiclip_normal_spec", "1")
	
	/* Fade */
	cvar_iSemiclipFadeMode = register_cvar("semiclip_fade_mode", "2")
	cvar_iSemiclipFadeFx = register_cvar("semiclip_fade_fx", "0")
	cvar_flSemiclipFadeMin = register_cvar("semiclip_fade_min", "130")
	cvar_flSemiclipFadeMax = register_cvar("semiclip_fade_max", "225")
	cvar_iSemiclipFadeSpec = register_cvar("semiclip_fade_spec", "1")
	
	/* Color */
	cvar_szSemiclipColorFlag = register_cvar("semiclip_color_admin_flag", "b")
	cvar_szSemiclipColors[COLOR_ADMIN_ZOMBIE] = register_cvar("semiclip_color_admin_zombies", "255 63 63")
	cvar_szSemiclipColors[COLOR_ADMIN_HUMAN] = register_cvar("semiclip_color_admin_humans", "153 204 255")
	cvar_szSemiclipColors[COLOR_ZOMBIE] = register_cvar("semiclip_color_zombies", "255 63 63")
	cvar_szSemiclipColors[COLOR_HUMAN] = register_cvar("semiclip_color_humans", "153 204 255")
	
	g_iMaxPlayers = get_maxplayers()
	#endif
	
	register_cvar("Team_Semiclip_version", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY)
	set_cvar_string("Team_Semiclip_version", PLUGIN_VERSION)
	
	if (LibraryExists(LIBRARY_GAMEMODES, LibType_Library))
	{
		g_bGamemodes = true
		
		g_iInfection = zp_gamemodes_get_id("Infection Mode")
		g_iMultiple = zp_gamemodes_get_id("Multiple Infection Mode")
		g_iNemesis = zp_gamemodes_get_id("Nemesis Mode")
		g_iSurvivor = zp_gamemodes_get_id("Survivor Mode")
		g_iSwarm = zp_gamemodes_get_id("Swarm Mode")
		g_iPlague = zp_gamemodes_get_id("Plague Mode")
		g_iArmageddon = zp_gamemodes_get_id("Armageddon Mode")
	}
}

public plugin_cfg()
{
	new szConfigDir[64]
	get_configsdir(szConfigDir, charsmax(szConfigDir))
	server_cmd("exec %s/scm/main.cfg", szConfigDir)
	
	CreateCvarEntityTask()
	set_task(0.50, "LoadSpawns")
}

/*================================================================================
 [Pause, Unpause]
=================================================================================*/

public plugin_pause()
{
	unregister_forward(FM_AddToFullPack, g_iAddToFullPack, true)
	unregister_forward(FM_CmdStart, g_iCmdStart, true)
	
	remove_task(TASK_CVARS)
	
	if (g_iCvarEntity && pev_valid(g_iCvarEntity))
		remove_entity(g_iCvarEntity)
	
	for (new id = 1; id <= g_iMaxPlayers; id++)
	{
		if (!get_bitsum(bs_IsAlive, id) || get_bitsum(bs_IsDying, id))
			goto Label_Disconnect
		
		if (!get_bitsum(bs_IsSolid, id))
		{
			set_pev(id, pev_solid, SOLID_SLIDEBOX)
			add_bitsum(bs_IsSolid, id)
		}
		
		if (is_player_stuck(id))
			DoRandomSpawn(id, 3)
		
		Label_Disconnect:
		fw_ClientDisconnect(id)
	}
}

public plugin_unpause()
{
	CacheCvars(TASK_CVARS)
	CreateCvarEntityTask()
	
	g_iAddToFullPack = register_forward(FM_AddToFullPack, "fw_AddToFullPack_Post", true)
	g_iCmdStart = register_forward(FM_CmdStart, "fw_CmdStart_Post", true)
	
	/* Zombie Plague 5.0 */
	if (g_bGamemodes)
	{
		if (g_bDisableOnGamemode)
		{
			g_bDisableOnGamemode = false
			
			set_pcvar_num(cvar_iSemiclip, 1)
			c_iSemiclip = 1
		}
		
		/* Game mode running? */
		new iCurrentGameMode = zp_gamemodes_get_current()
		if (iCurrentGameMode >= 0)
			zp_fw_gamemodes_start(iCurrentGameMode)
	}
	
	for (new id = 1; id <= g_iMaxPlayers; id++)
	{
		/* disconnected while pausing? */
		if (!is_user_connected(id))
			continue
		
		/* do all other staff */
		client_putinserver(id)
		g_iTeam[id] = zp_core_is_zombie(id) ? ZP_TEAM_ZOMBIE : ZP_TEAM_HUMAN
		g_iSpectating[id] = id
		
		if (is_user_alive(id))
		{
			remove_task(id+TASK_SPECTATOR)
			
			add_bitsum(bs_IsAlive, id)
			add_bitsum(bs_IsSolid, id)
		}
		else if (pev(id, pev_deadflag) == DEAD_DYING)
		{
			remove_task(id+TASK_SPECTATOR)
			
			add_bitsum(bs_IsAlive, id)
			add_bitsum(bs_IsDying, id)
		}
		else g_iTeam[id] = ZP_TEAM_SPECTATOR /* anything else is already set */
	}
}

/*================================================================================
 [Put in, Disconnect]
=================================================================================*/

public client_putinserver(id)
{
	add_bitsum(bs_IsConnected, id)
	SetUserCvars(id)
	
	if (is_user_bot(id))
	{
		add_bitsum(bs_IsBot, id)
		add_bitsum(bs_InButton, id)
	}
	else set_task(SPEC_INTERVAL, "SpectatorCheck", id+TASK_SPECTATOR, _, _, "b")
	
	set_task(RANGE_INTERVAL, "RangeCheck", id+TASK_RANGE, _, _, "b")
}

/*================================================================================
 [Main Events]
=================================================================================*/

public EventRoundStart()
{
	if (g_bGamemodes)
	{
		if (g_bDisableOnGamemode)
		{
			g_bDisableOnGamemode = false
			
			set_pcvar_num(cvar_iSemiclip, 1)
			#if AMXX_VERSION_NUM < 183
			c_iSemiclip = 1
			#endif
		}
	}
}

/*================================================================================
 [Zombie Plague Forwards]
=================================================================================*/

public zp_fw_gamemodes_start(gamemode)
{
	#if AMXX_VERSION_NUM >= 183
	if (gamemode == g_iInfection && c_iDisableInfection) goto Label_DisableSemiclip
	else if (gamemode == g_iMultiple && c_iDisableMultiple) goto Label_DisableSemiclip
	else if (gamemode == g_iNemesis && c_iDisableNemesis) goto Label_DisableSemiclip
	else if (gamemode == g_iSurvivor && c_iDisableSurvivor) goto Label_DisableSemiclip
	else if (gamemode == g_iSwarm && c_iDisableSwarm) goto Label_DisableSemiclip
	else if (gamemode == g_iPlague && c_iDisablePlague) goto Label_DisableSemiclip
	else if (gamemode == g_iArmageddon && c_iDisableArmageddon) goto Label_DisableSemiclip
	#else
	if (gamemode == g_iInfection && get_pcvar_num(cvar_iDisableInfection)) goto Label_DisableSemiclip
	else if (gamemode == g_iMultiple && get_pcvar_num(cvar_iDisableMultiple)) goto Label_DisableSemiclip
	else if (gamemode == g_iNemesis && get_pcvar_num(cvar_iDisableNemesis)) goto Label_DisableSemiclip
	else if (gamemode == g_iSurvivor && get_pcvar_num(cvar_iDisableSurvivor)) goto Label_DisableSemiclip
	else if (gamemode == g_iSwarm && get_pcvar_num(cvar_iDisableSwarm)) goto Label_DisableSemiclip
	else if (gamemode == g_iPlague && get_pcvar_num(cvar_iDisablePlague)) goto Label_DisableSemiclip
	else if (gamemode == g_iArmageddon && get_pcvar_num(cvar_iDisableArmageddon)) goto Label_DisableSemiclip
	#endif
	else return
	
	Label_DisableSemiclip:
	g_bDisableOnGamemode = true
	set_pcvar_num(cvar_iSemiclip, 0)
	c_iSemiclip = 0
	
	for (new id = 1; id <= g_iMaxPlayers; id++)
	{
		if (!get_bitsum(bs_IsAlive, id) || get_bitsum(bs_IsDying, id))
			continue
		
		if (!get_bitsum(bs_IsSolid, id))
		{
			set_pev(id, pev_solid, SOLID_SLIDEBOX)
			add_bitsum(bs_IsSolid, id)
		}
		
		if (is_player_stuck(id))
			DoRandomSpawn(id, (c_iUnstuck == 4) ? 3 : c_iUnstuck)
	}
}

public zp_fw_core_cure(id)
{
	g_iTeam[id] = ZP_TEAM_HUMAN
	g_iSpectating[id] = id
	
	if (TeamInfoUnstuck(id))
	{
		if (c_flUnstuckDelay >= 0.1) set_task(c_flUnstuckDelay, "RandomSpawnDelay", id)
		else DoRandomSpawn(id, c_iUnstuck)
	}
}

public zp_fw_core_infect(id)
{
	g_iTeam[id] = ZP_TEAM_ZOMBIE
	g_iSpectating[id] = id
	
	if (TeamInfoUnstuck(id))
	{
		if (c_flUnstuckDelay >= 0.1) set_task(c_flUnstuckDelay, "RandomSpawnDelay", id)
		else DoRandomSpawn(id, c_iUnstuck)
	}
}

/*================================================================================
 [Main Forwards]
=================================================================================*/

public fw_PlayerSpawn_Post(id)
{
	if (!is_user_alive(id) || !g_iTeam[id])
		return
	
	remove_task(id+TASK_SPECTATOR)
	
	add_bitsum(bs_IsAlive, id)
	del_bitsum(bs_IsDying, id)
	del_bitsum(bs_InSemiclip, id)
	add_bitsum(bs_IsSolid, id)
}

public fw_PlayerKilled(id)
{
	add_bitsum(bs_IsDying, id)
	del_bitsum(bs_InSemiclip, id)
	del_bitsum(bs_IsSolid, id)
}

public fw_PlayerSemiclip_Start(id)
{
	if (!c_iSemiclip || !get_bitsum(bs_IsAlive, id) || get_bitsum(bs_IsDying, id))
		return
	
	del_bitsum(bs_InSemiclip, id)
	
	static i
	for (i = 1; i <= g_iMaxPlayers; i++)
	{
		if (!get_bitsum(bs_IsSolid, i) || i == id || !AllowSemiclip(id, i))
			continue
		
		set_pev(i, pev_solid, SOLID_NOT)
		del_bitsum(bs_IsSolid, i)
		add_bitsum(bs_InSemiclip, id)
	}
}

public fw_PlayerSemiclip_End(id)
{
	if (!c_iSemiclip || !get_bitsum(bs_IsAlive, id) || get_bitsum(bs_IsDying, id))
		return
	
	if (c_i3rdPlugins)
	{
		g_iRender3rdPlugins[id][RENDER_AMT]  = pev(id, pev_renderamt)
		g_iRender3rdPlugins[id][RENDER_FX]   = pev(id, pev_renderfx)
		g_iRender3rdPlugins[id][RENDER_MODE] = pev(id, pev_rendermode)
	}
	
	static i
	for (i = 1; i <= g_iMaxPlayers; i++)
	{
		if (!get_bitsum(bs_IsAlive, i) || get_bitsum(bs_IsDying, i) || get_bitsum(bs_IsSolid, i))
			continue
		
		set_pev(i, pev_solid, SOLID_SLIDEBOX)
		add_bitsum(bs_IsSolid, i)
	}
}

/* Slash - 48.0 */
public fw_Knife_PrimaryAttack(ent)
{
	if (!c_iSemiclip || !c_iKnifeTrace)
		return
	
	static iOwner
	iOwner = ham_cs_get_weapon_ent_owner(ent)
	
	if (!is_user_valid_alive(iOwner) || (c_iKnifeTrace != 3 && g_iTeam[iOwner] != c_iKnifeTrace))
		return
	
	if (!g_iTraceLine)
		g_iTraceLine = register_forward(FM_TraceLine, "fw_TraceLine_Post", true)
}

/* Stab - 32.0 */
public fw_Knife_SecondaryAttack(ent)
{
	if (!c_iSemiclip || !c_iKnifeTrace)
		return
	
	static iOwner
	iOwner = ham_cs_get_weapon_ent_owner(ent)
	
	if (!is_user_valid_alive(iOwner) || (c_iKnifeTrace != 3 && g_iTeam[iOwner] != c_iKnifeTrace))
		return
	
	if (!g_iTraceLine)
	{
		add_bitsum(bs_InKnifeSecAtk, iOwner)
		g_iTraceLine = register_forward(FM_TraceLine, "fw_TraceLine_Post", true)
	}
}

public fw_TraceLine_Post(Float:vStart[3], Float:vEnd[3], iNoMonsters, id, iTrace)
{
	if (!is_user_valid_alive(id))
		return
	
	static Float:flFraction
	get_tr2(iTrace, TR_flFraction, flFraction)
	
	if (flFraction >= 1.0)
		goto Label_Unregister
	
	static pHit
	pHit = get_tr2(iTrace, TR_pHit)
	
	if (!is_user_valid_alive(pHit) || !is_same_team(id, pHit))
		goto Label_Unregister
	
	static bs_RestoreSolid
	pev(id, pev_absmin, g_flAbsMin[id])
	pev(id, pev_absmax, g_flAbsMax[id])
	
	for (pHit = 1; pHit <= g_iMaxPlayers; pHit++)
	{
		if (!get_bitsum(bs_IsAlive, pHit) || get_bitsum(bs_IsDying, pHit) || !get_bitsum(bs_IsSolid, pHit) || !is_same_team(id, pHit))
			continue
		
		pev(pHit, pev_absmin, g_flAbsMin[pHit])
		pev(pHit, pev_absmax, g_flAbsMax[pHit])
		
		if (GetIntersects(g_flAbsMin[id], g_flAbsMax[id], g_flAbsMin[pHit], g_flAbsMax[pHit]))
		{
			set_pev(pHit, pev_solid, SOLID_NOT)
			del_bitsum(bs_IsSolid, pHit)
			add_bitsum(bs_RestoreSolid, pHit)
		}
	}
	
	static Float:flLine[3]
	velocity_by_aim(id, get_bitsum(bs_InKnifeSecAtk, id) ? 48 : 64, flLine)
	UTIL_Vector_Add(flLine, vStart, vEnd)
	
	engfunc(EngFunc_TraceLine, vStart, vEnd, iNoMonsters, id, 0)
	
	pHit = get_tr2(0, TR_pHit)
	
	if (!is_user_valid_alive(pHit))
		goto Label_Unregister
	
	static Float:flBuffer[3]
	set_tr2(iTrace, TR_AllSolid, get_tr2(0, TR_AllSolid))
	set_tr2(iTrace, TR_StartSolid, get_tr2(0, TR_StartSolid))
	set_tr2(iTrace, TR_InOpen, get_tr2(0, TR_InOpen))
	set_tr2(iTrace, TR_InWater, get_tr2(0, TR_InWater))
	get_tr2(0, TR_flFraction, flFraction); set_tr2(iTrace, TR_flFraction, flFraction)
	get_tr2(0, TR_vecEndPos, flBuffer); set_tr2(iTrace, TR_vecEndPos, flBuffer)
	get_tr2(0, TR_flPlaneDist, flFraction); set_tr2(iTrace, TR_flPlaneDist, flFraction)
	get_tr2(0, TR_vecPlaneNormal, flBuffer); set_tr2(iTrace, TR_vecPlaneNormal, flBuffer)
	set_tr2(iTrace, TR_pHit, pHit)
	set_tr2(iTrace, TR_iHitgroup, get_tr2(0, TR_iHitgroup))
	
	Label_Unregister:
	unregister_forward(FM_TraceLine, g_iTraceLine, true)
	g_iTraceLine = 0
	del_bitsum(bs_InKnifeSecAtk, id)
	
	if (bs_RestoreSolid)
		for (pHit = 1; pHit <= g_iMaxPlayers; pHit++)
		{
			if (!get_bitsum(bs_RestoreSolid, pHit))
				continue
			
			set_pev(pHit, pev_solid, SOLID_SLIDEBOX)
			add_bitsum(bs_IsSolid, pHit)
			del_bitsum(bs_RestoreSolid, pHit)
		}
}

public fw_ClientDisconnect(id)
{
	del_bitsum(bs_IsConnected, id)
	SetUserCvars(id)
	
	remove_task(id+TASK_RANGE)
	remove_task(id+TASK_SPECTATOR)
}

public fw_AddToFullPack_Post(es_handle, e, ent, host, flags, player, pSet)
{
	if (!c_iSemiclip || !player || host == ent)
		return
	
	if (g_iTeam[host] == ZP_TEAM_SPECTATOR)
	{
		if (!c_iRender || get_bitsum(bs_IsBot, host) || !get_bitsum(bs_IsAlive, ent))
			return
		
		static iHost
		iHost = g_iSpectating[host]
		
		if (!iHost || !get_bitsum(bs_IsAlive, iHost) || g_iRange[iHost][ent] == OUT_OF_RANGE || !AllowSemiclip(iHost, ent))
			return
		
		if (!c_iUnstuckRender && c_iUnstuck == 4 && !c_iEnemies && !is_same_team(ent, iHost))
			return
		
		if (c_i3rdPlugins && (g_iRender3rdPlugins[ent][RENDER_AMT] || g_iRender3rdPlugins[ent][RENDER_FX] || g_iRender3rdPlugins[ent][RENDER_MODE]))
			return
		
		switch (c_iRender)
		{
			case 2: /* Fade */
			{
				if (!c_iFadeSpec && iHost == ent)
					return
				
				if (get_bitsum(bs_RenderSpecial, ent)) goto Label_Special
				else
				{
					set_es(es_handle, ES_RenderMode, c_iFadeMode)
					set_es(es_handle, ES_RenderFx, c_iFadeFx)
				}
			}
			case 1: /* Normal */
			{
				if (!c_iNormalSpec && iHost == ent)
					return
				
				if (get_bitsum(bs_RenderSpecial, ent)) goto Label_Special
				else
				{
					set_es(es_handle, ES_RenderMode, c_iNormalMode)
					set_es(es_handle, ES_RenderFx, c_iNormalFx)
				}
			}
		}
		
		set_es(es_handle, ES_RenderAmt, g_iRange[iHost][ent])
		switch (g_iTeam[ent])
		{
			case 1: get_bitsum(bs_IsAdmin, ent) ? set_es(es_handle, ES_RenderColor, c_iColors[COLOR_ADMIN_ZOMBIE]) : set_es(es_handle, ES_RenderColor, c_iColors[COLOR_ZOMBIE])
			case 2: get_bitsum(bs_IsAdmin, ent) ? set_es(es_handle, ES_RenderColor, c_iColors[COLOR_ADMIN_HUMAN]) : set_es(es_handle, ES_RenderColor, c_iColors[COLOR_HUMAN])
		}
		return
	}
	
	if (!get_bitsum(bs_IsAlive, host) || !get_bitsum(bs_IsAlive, ent) || !AllowSemiclip(host, ent))
		return
	
	set_es(es_handle, ES_Solid, SOLID_NOT)
	
	if (!c_iRender || g_iRange[host][ent] == OUT_OF_RANGE || (!c_iUnstuckRender && c_iUnstuck == 4 && !c_iEnemies && !is_same_team(ent, host)))
		return
	
	if (c_i3rdPlugins && (g_iRender3rdPlugins[ent][RENDER_AMT] || g_iRender3rdPlugins[ent][RENDER_FX] || g_iRender3rdPlugins[ent][RENDER_MODE]))
		return
	
	switch (c_iRender)
	{
		case 2: /* Fade */
		{
			if (get_bitsum(bs_RenderSpecial, ent)) goto Label_Special
			else
			{
				set_es(es_handle, ES_RenderMode, c_iFadeMode)
				set_es(es_handle, ES_RenderFx, c_iFadeFx)
			}
		}
		case 1: /* Normal */
		{
			if (get_bitsum(bs_RenderSpecial, ent)) goto Label_Special
			else
			{
				set_es(es_handle, ES_RenderMode, c_iNormalMode)
				set_es(es_handle, ES_RenderFx, c_iNormalFx)
			}
		}
		case -1: /* For special render */
		{
			Label_Special:
			set_es(es_handle, ES_RenderMode, g_iRenderSpecial[ent][RENDER_MODE])
			set_es(es_handle, ES_RenderFx, g_iRenderSpecial[ent][RENDER_FX])
			set_es(es_handle, ES_RenderAmt, g_iRenderSpecial[ent][RENDER_AMT])
			set_es(es_handle, ES_RenderColor, g_iRenderSpecialColor[ent])
			return
		}
		default: return /* Disabled */
	}
	
	set_es(es_handle, ES_RenderAmt, g_iRange[host][ent])
	switch (g_iTeam[ent])
	{
		case 1: get_bitsum(bs_IsAdmin, ent) ? set_es(es_handle, ES_RenderColor, c_iColors[COLOR_ADMIN_ZOMBIE]) : set_es(es_handle, ES_RenderColor, c_iColors[COLOR_ZOMBIE])
		case 2: get_bitsum(bs_IsAdmin, ent) ? set_es(es_handle, ES_RenderColor, c_iColors[COLOR_ADMIN_HUMAN]) : set_es(es_handle, ES_RenderColor, c_iColors[COLOR_HUMAN])
	}
}

public fw_CmdStart_Post(id, handle)
{
	if (!c_iSemiclip || !c_iButton || !get_bitsum(bs_IsAlive, id) || get_bitsum(bs_IsDying, id) || get_bitsum(bs_IsBot, id) || get_bitsum(bs_InAntiBoost, id))
		return
	
	if (get_uc(handle, UC_Buttons) & c_iButtonTrigger)
	{
		add_bitsum(bs_InButton, id)
	}
	else
	{
		if (get_bitsum(bs_InButton, id))
			add_bitsum(bs_WasInButton, id)
		
		del_bitsum(bs_InButton, id)
		
		if (c_iButtonAntiBoost && get_bitsum(bs_WasInButton, id))
			RangeCheck(id+TASK_RANGE)
	}
}

public fw_Touch(iTouched, iToucher)
{
	if (!c_iSemiclip || !c_iButton || (!c_iButtonAntiBoost && !c_iButtonAntiStuck) || !is_user_valid_alive(iTouched) || !is_user_valid_alive(iToucher))
		return
	
	/* Anti boosting */
	switch (c_iButton)
	{
		case 3: /* BOTH */
		{
			if ((get_bitsum(bs_InButton, iTouched) || get_bitsum(bs_WasInButton, iTouched)) && !g_iAntiBoost[iTouched][iToucher])
			{
				if (!c_iEnemies && !is_same_team(iToucher, iTouched))
					return
				
				Label_Stuck_or_Boosting:
				if (c_iButtonAntiStuck && (!is_player_stuck(iTouched) || !is_player_stuck(iToucher)))
					if (!c_iButtonAntiBoost) return
				
				SetBoosting(iTouched, iToucher, true)
			}
		}
		case 1, 2: /* CT or TERROR */
		{
			if ((get_bitsum(bs_InButton, iTouched) || get_bitsum(bs_WasInButton, iTouched)) && !g_iAntiBoost[iTouched][iToucher] && c_iButton == g_iTeam[iTouched] && c_iButton == g_iTeam[iToucher])
			{
				if (c_iEnemies && !is_same_team(iToucher, iTouched))
					return
				
				goto Label_Stuck_or_Boosting
			}
		}
	}
}

#if AMXX_VERSION_NUM >= 183
public fw_ColorFlagChange(pcvar, const old_value[], const new_value[])
{
	c_iColorFlag = read_flags(new_value)
}

public fw_ColorChange(pcvar, const old_value[], const new_value[])
{
	static i, szRed[4], szGreen[4], szBlue[4]
	for (i = COLOR_HUMAN; i < MAX_COLORS; i++)
	{
		if (cvar_szSemiclipColors[i] == pcvar)
		{
			parse(new_value, szRed, charsmax(szRed), szGreen, charsmax(szGreen), szBlue, charsmax(szBlue))
			c_iColors[i][0] = clamp(str_to_num(szRed), 0, 255)
			c_iColors[i][1] = clamp(str_to_num(szGreen), 0, 255)
			c_iColors[i][2] = clamp(str_to_num(szBlue), 0, 255)
			break
		}
	}
}
#endif

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

CheckMods()
{
	new szModName[8]
	get_modname(szModName, charsmax(szModName))
	if (equal(szModName, "cstrike") || equal(szModName, "czero")) register_plugin("[ZP50] Team Semiclip", PLUGIN_VERSION, "schmurgel1983")
	else
	{
		register_plugin("[??] Team Semiclip", PLUGIN_VERSION, "schmurgel1983")
		set_fail_state("Error: This plugin is for cstrike and czero only!")
	}
}

CreateCvarEntityTask()
{
	g_iCvarEntity = create_entity("info_target")
	if (pev_valid(g_iCvarEntity))
	{
		register_think("TSC_CvarEntity", "CacheCvars")
		
		set_pev(g_iCvarEntity, pev_classname, "TSC_CvarEntity")
		set_pev(g_iCvarEntity, pev_nextthink, get_gametime() + 0.25)
	}
	else
	{
		set_task(0.25, "CacheCvars", TASK_CVARS)
		set_task(CVAR_INTERVAL, "CacheCvars", TASK_CVARS, _, _, "b")
	}
}

public CacheCvars(entity)
{
	#if AMXX_VERSION_NUM < 183
	c_iSemiclip = !!get_pcvar_num(cvar_iSemiclip)
	c_iBlockTeam = clamp(get_pcvar_num(cvar_iSemiclipBlockTeam), 0, 3)
	c_iEnemies = !!get_pcvar_num(cvar_iSemiclipEnemies)
	c_flRadius = floatclamp(get_pcvar_float(cvar_flSemiclipRadius), 0.0, 65535.0)
	
	c_iButton = clamp(get_pcvar_num(cvar_iSemiclipButton), 0, 3)
	c_iButtonTrigger = clamp(get_pcvar_num(cvar_iSemiclipButtonTrigger), 1, 65535)
	c_iButtonAntiBoost = !!get_pcvar_num(cvar_iSemiclipButtonAntiBoost)
	c_iButtonAntiStuck = !!get_pcvar_num(cvar_iSemiclipButtonAntiStuck)
	
	c_iUnstuck = clamp(get_pcvar_num(cvar_iSemiclipUnstuck), 0, 4)
	c_iUnstuckRender = !!get_pcvar_num(cvar_iSemiclipUnstuckRender)
	c_flUnstuckDelay = floatclamp(get_pcvar_float(cvar_flSemiclipUnstuckDelay), 0.0, 65535.0)
	
	c_iKnifeTrace = clamp(get_pcvar_num(cvar_iSemiclipKnifeTrace), 0, 3)
	
	c_iRender = clamp(get_pcvar_num(cvar_iSemiclipRender), 0, 2)
	c_i3rdPlugins = !!get_pcvar_num(cvar_iSemiclipRender3rdPlugins)
	c_iFreeLook = !!get_pcvar_num(cvar_iSemiclipRenderFreeLook)
	
	c_iNormalMode = clamp(get_pcvar_num(cvar_iSemiclipNormalMode), 0, 5)
	c_iNormalFx = clamp(get_pcvar_num(cvar_iSemiclipNormalFx), 0, 20)
	c_iNormalAmt = clamp(get_pcvar_num(cvar_iSemiclipNormalAmt), 0, 255)
	c_iNormalSpec = !!get_pcvar_num(cvar_iSemiclipNormalSpec)
	
	c_iFadeMode = clamp(get_pcvar_num(cvar_iSemiclipFadeMode), 0, 5)
	c_iFadeFx = clamp(get_pcvar_num(cvar_iSemiclipFadeFx), 0, 20)
	c_flFadeMin = floatclamp(get_pcvar_float(cvar_flSemiclipFadeMin), 0.0, 255.0)
	c_flFadeMax = floatclamp(get_pcvar_float(cvar_flSemiclipFadeMax), 0.0, 255.0)
	c_iFadeSpec = !!get_pcvar_num(cvar_iSemiclipFadeSpec)
	
	new szFlags[24]
	get_pcvar_string(cvar_szSemiclipColorFlag, szFlags, charsmax(szFlags))	
	c_iColorFlag = read_flags(szFlags)
	
	new szColors[12], szRed[4], szGreen[4], szBlue[4]
	for (new i = COLOR_HUMAN; i < MAX_COLORS; i++)
	{
		get_pcvar_string(cvar_szSemiclipColors[i], szColors, charsmax(szColors))
		parse(szColors, szRed, charsmax(szRed), szGreen, charsmax(szGreen), szBlue, charsmax(szBlue))
		c_iColors[i][0] = clamp(str_to_num(szRed), 0, 255)
		c_iColors[i][1] = clamp(str_to_num(szGreen), 0, 255)
		c_iColors[i][2] = clamp(str_to_num(szBlue), 0, 255)
	}
	#endif
	
	for (new i = 1; i <= g_iMaxPlayers; i++)
	{
		if (!get_bitsum(bs_IsConnected, i))
			continue
		
		/* amx_reloadadmins ? */
		if (get_user_flags(i) & c_iColorFlag) add_bitsum(bs_IsAdmin, i)
		else del_bitsum(bs_IsAdmin, i)
	}
	
	/* No CSDM spawns found */
	if (!g_bZpRandomSpawn && !g_iSpawnCountCSDM && c_iUnstuck == 2)
	{
		set_pcvar_num(cvar_iSemiclipUnstuck, 1)
		#if AMXX_VERSION_NUM < 183
		c_iUnstuck = 1
		#endif
	}
	
	if (entity != TASK_CVARS)
	{
		if (!pev_valid(entity)) set_task(CVAR_INTERVAL, "CacheCvars", TASK_CVARS, _, _, "b")
		else set_pev(entity, pev_nextthink, get_gametime() + CVAR_INTERVAL)
	}
}

public LoadSpawns()
{
	/* Check if Zombie Plague 5.0 is not running */
	if (!LibraryExists("zp50_core", LibType_Library))
	{
		plugin_pause()
		set_fail_state("Error: This plugin is for Zombie Plague 5.0+ only")
	}
	
	/* Zombie Plague 5.0 is running, check and cache ZP 5.0.7 random spawn */
	g_bZpRandomSpawn = bool:LibraryExists(LIBRARY_RANDOM_SPAWN, LibType_Library)
	if (g_bZpRandomSpawn)
	{
		new iPluginId = is_plugin_loaded("zp50_random_spawn.amxx", true)
		if (iPluginId != -1)
		{
			new szIgnore[2], szStatus[9]
			get_plugin(iPluginId, szIgnore, 1, szIgnore, 1, szIgnore, 1, szIgnore, 1, szStatus, charsmax(szStatus))
			
			/* Good: running, debug, profile
			   Bad : paused, bad load, stopped, locked, error */
			if (equal(szStatus, "running") || equal(szStatus, "debug") || equal(szStatus, "profile"))
				return
		}
		g_bZpRandomSpawn = false
	}
	
	/* ZP 5.0.7 random spawn is not running */
	new szConfigDir[32], szMapName[32], szFilePath[100], szLineData[64]
	
	get_configsdir(szConfigDir, charsmax(szConfigDir))
	get_mapname(szMapName, charsmax(szMapName))
	formatex(szFilePath, charsmax(szFilePath), "%s/csdm/%s.spawns.cfg", szConfigDir, szMapName)
	
	if (file_exists(szFilePath))
	{
		new iFile
		if ((iFile = fopen(szFilePath, "rt")) != 0)
		{
			new szDataCSDM[10][6]
			while (!feof(iFile))
			{
				fgets(iFile, szLineData, charsmax(szLineData))
				
				if (!szLineData[0] || str_count(szLineData,' ') < 2)
					continue
				
				parse(szLineData, szDataCSDM[0], 5, szDataCSDM[1], 5, szDataCSDM[2], 5, szDataCSDM[3], 5, szDataCSDM[4], 5, szDataCSDM[5], 5, szDataCSDM[6], 5, szDataCSDM[7], 5, szDataCSDM[8], 5, szDataCSDM[9], 5)
				
				g_flSpawnsCSDM[g_iSpawnCountCSDM][0] = floatstr(szDataCSDM[0])
				g_flSpawnsCSDM[g_iSpawnCountCSDM][1] = floatstr(szDataCSDM[1])
				g_flSpawnsCSDM[g_iSpawnCountCSDM][2] = floatstr(szDataCSDM[2])
				
				if (++g_iSpawnCountCSDM >= MAX_CSDM_SPAWNS)
					break
			}
			fclose(iFile)
			
			goto Label_Collect
		}
	}
	
	if (c_iUnstuck == 2)
	{
		set_pcvar_num(cvar_iSemiclipUnstuck, 1)
		#if AMXX_VERSION_NUM < 183
		c_iUnstuck = 1
		#endif
	}
	
	Label_Collect:
	/* HUMANS */
	new iEnt = -1
	while ((iEnt = find_ent_by_class(iEnt, HUMAN_SPAWN_ENTITY_NAME)) != 0)
	{
		new Float:flOrigin[3]
		pev(iEnt, pev_origin, flOrigin)
		g_flSpawnsHuman[g_iSpawnCountHuman][0] = flOrigin[0]
		g_flSpawnsHuman[g_iSpawnCountHuman][1] = flOrigin[1]
		g_flSpawnsHuman[g_iSpawnCountHuman][2] = flOrigin[2]
		
		if (++g_iSpawnCountHuman >= sizeof g_flSpawnsHuman)
			break
	}
	
	/* ZOMBIES */
	iEnt = -1
	while ((iEnt = find_ent_by_class(iEnt, ZOMBIE_SPAWN_ENTITY_NAME)) != 0)
	{
		new Float:flOrigin[3]
		pev(iEnt, pev_origin, flOrigin)
		g_flSpawnsZombie[g_iSpawnCountZombie][0] = flOrigin[0]
		g_flSpawnsZombie[g_iSpawnCountZombie][1] = flOrigin[1]
		g_flSpawnsZombie[g_iSpawnCountZombie][2] = flOrigin[2]
		
		if (++g_iSpawnCountZombie >= sizeof g_flSpawnsZombie)
			break
	}
}

public RandomSpawnDelay(id)
{
	DoRandomSpawn(id, c_iUnstuck)
}

/* credits to MeRcyLeZZ */
DoRandomSpawn(id, type)
{
	if (!c_iUnstuck || !get_bitsum(bs_IsAlive, id) || get_bitsum(bs_IsDying, id))
		return
	
	static iHull, iSpawnPoint, i
	iHull = (pev(id, pev_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN
	
	switch (type)
	{
		case 1: /* Specified team */
		{
			switch (g_iTeam[id])
			{
				case ZP_TEAM_ZOMBIE: /* ZOMBIES */
				{
					if (g_bZpRandomSpawn && zp_random_spawn_do(id, 0))
						return
					
					if (!g_iSpawnCountZombie)
						return
					
					iSpawnPoint = random_num(0, g_iSpawnCountZombie - 1)
					
					for (i = iSpawnPoint + 1; /*no condition*/; i++)
					{
						if (i >= g_iSpawnCountZombie)
							i = 0
						
						if (is_hull_vacant(g_flSpawnsZombie[i], iHull))
						{
							engfunc(EngFunc_SetOrigin, id, g_flSpawnsZombie[i])
							break
						}
						
						if (i == iSpawnPoint)
							break
					}
				}
				case ZP_TEAM_HUMAN: /* HUMANS */
				{
					if (g_bZpRandomSpawn && zp_random_spawn_do(id, 0))
						return
					
					if (!g_iSpawnCountHuman)
						return
					
					iSpawnPoint = random_num(0, g_iSpawnCountHuman - 1)
					
					for (i = iSpawnPoint + 1; /*no condition*/; i++)
					{
						if (i >= g_iSpawnCountHuman)
							i = 0
						
						if (is_hull_vacant(g_flSpawnsHuman[i], iHull))
						{
							engfunc(EngFunc_SetOrigin, id, g_flSpawnsHuman[i])
							break
						}
						
						if (i == iSpawnPoint)
							break
					}
				}
			}
		}
		case 2: /* CSDM */
		{
			if (g_bZpRandomSpawn && zp_random_spawn_do(id, 1))
				return
			
			if (!g_iSpawnCountCSDM)
				return
			
			iSpawnPoint = random_num(0, g_iSpawnCountCSDM - 1)
			
			for (i = iSpawnPoint + 1; /*no condition*/; i++)
			{
				if (i >= g_iSpawnCountCSDM)
					i = 0
				
				if (is_hull_vacant(g_flSpawnsCSDM[i], iHull))
				{
					engfunc(EngFunc_SetOrigin, id, g_flSpawnsCSDM[i])
					break
				}
				
				if (i == iSpawnPoint)
					break
			}
		}
		case 3: /* Random around own place */
		{
			static const Float:RANDOM_OWN_PLACE[][3] =
			{
				{ -96.5,   0.0, 0.0 },
				{  96.5,   0.0, 0.0 },
				{   0.0, -96.5, 0.0 },
				{   0.0,  96.5, 0.0 },
				{ -96.5, -96.5, 0.0 },
				{ -96.5,  96.5, 0.0 },
				{  96.5,  96.5, 0.0 },
				{  96.5, -96.5, 0.0 }
			}
			
			new Float:flOrigin[3], Float:flOriginFinal[3], iSize
			pev(id, pev_origin, flOrigin)
			iSize = sizeof(RANDOM_OWN_PLACE)
			
			iSpawnPoint = random_num(0, iSize - 1)
			
			for (i = iSpawnPoint + 1; /*no condition*/; i++)
			{
				if (i >= iSize)
					i = 0
				
				flOriginFinal[0] = flOrigin[0] + RANDOM_OWN_PLACE[i][0]
				flOriginFinal[1] = flOrigin[1] + RANDOM_OWN_PLACE[i][1]
				flOriginFinal[2] = flOrigin[2]
				
				engfunc(EngFunc_TraceLine, flOrigin, flOriginFinal, IGNORE_MONSTERS, id, 0)
				
				new Float:flFraction
				get_tr2(0, TR_flFraction, flFraction)
				if (flFraction < 1.0)
				{
					new Float:vTraceEnd[3], Float:vNormal[3]
					get_tr2(0, TR_vecEndPos, vTraceEnd)
					get_tr2(0, TR_vecPlaneNormal, vNormal)
					
					TSC_Vector_MA(vTraceEnd, vNormal, 32.5, flOriginFinal)
				}
				flOriginFinal[2] -= 35.0
				
				new iZ = 0
				do
				{
					if (is_hull_vacant(flOriginFinal, iHull))
					{
						i = iSpawnPoint
						engfunc(EngFunc_SetOrigin, id, flOriginFinal)
						break
					}
					
					flOriginFinal[2] += 40.0
				}
				while (++iZ <= 2)
				
				if (i == iSpawnPoint)
					break
			}
		}
		case 4: /* Trespass */
		{
			new iNum, iPlayer, iPlayers[32]
			iNum = find_sphere_class(id, "player", 102.0, iPlayers, g_iMaxPlayers)
			
			for (--iNum; iNum >= 0; iNum--)
			{
				iPlayer = iPlayers[iNum]
				
				if (id == iPlayer || g_iAntiBoost[id][iPlayer])
					continue
				
				SetBoosting(id, iPlayer, true)
			}
		}
	}
}

public RangeCheck(taskid)
{
	if (!c_iSemiclip)
		return
	
	static id
	for (id = 1; id <= g_iMaxPlayers; id++)
	{
		if (!get_bitsum(bs_IsAlive, id)|| ID_RANGE == id)
			continue
		
		g_iRange[ID_RANGE][id] = CalculateAmount(ID_RANGE, id)
		
		if (c_iUnstuck != 4 && !c_iButtonAntiBoost)
			continue
		
		#if AMXX_VERSION_NUM >= 183
		if (g_iAntiBoost[ID_RANGE][id] && !entity_intersects(ID_RANGE, id))
		#else
		if (g_iAntiBoost[ID_RANGE][id] && entity_range(ID_RANGE, id) > ANTI_BOOST_DISTANCE)
		#endif
		{
			SetBoosting(ID_RANGE, id, false)
		}
	}
	del_bitsum(bs_WasInButton, ID_RANGE)
}

SetBoosting(iBooster, iOther, bool:Set)
{
	if (Set)
	{
		add_bitsum(bs_InAntiBoost, iBooster)
		add_bitsum(bs_InButton, iBooster)
		g_iAntiBoost[iBooster][iOther] = 1
		
		add_bitsum(bs_InAntiBoost, iOther)
		add_bitsum(bs_InButton, iOther)
		g_iAntiBoost[iOther][iBooster] = 1
	}
	else
	{
		g_iAntiBoost[iBooster][iOther] = 0
		
		for (iOther = 1; iOther <= g_iMaxPlayers; iOther++)
		{
			if (!g_iAntiBoost[iBooster][iOther])
				continue
			
			Set = true
			break
		}
		
		if (!Set) del_bitsum(bs_InAntiBoost, iBooster)
	}
}

public SpectatorCheck(taskid)
{
	if (!c_iSemiclip || get_bitsum(bs_IsAlive, ID_SPECTATOR) || get_bitsum(bs_IsDying, ID_SPECTATOR))
		return
	
	static iTarget
	iTarget = pev(ID_SPECTATOR, pev_spec_target)
	
	if (c_iFreeLook && !is_user_valid(iTarget)) goto Label_FreeLook
	else
	{
		Label_SetTarget:
		g_iSpectating[ID_SPECTATOR] = iTarget
		return
	}
	
	Label_FreeLook:
	if (pev(ID_SPECTATOR, pev_spec_mode) != 3)
		return
	
	iTarget = fm_cs_get_free_look_target(ID_SPECTATOR)
	
	if (is_user_valid(iTarget))
		goto Label_SetTarget
}

CalculateAmount(host, ent)
{
	/* Fade */
	if (c_iRender == 2)
	{
		static Float:flRange
		flRange = entity_range(host, ent)
		
		if (flRange > c_flRadius)
			return OUT_OF_RANGE
		
		static Float:flAmount
		flAmount = flRange / (c_flRadius / (c_flFadeMax - c_flFadeMin))
		
		return floatround((flAmount >= 0.0) ? flAmount + c_flFadeMin : floatabs(flAmount - c_flFadeMax))
	}
	
	return (entity_range(host, ent) <= c_flRadius) ? c_iNormalAmt : OUT_OF_RANGE
}

AllowSemiclip(host, ent)
{
	if (g_iAntiBoost[host][ent])
		return 1
	
	switch (c_iButton)
	{
		case 3: /* BOTH */
		{
			if (get_bitsum(bs_InButton, host))
			{
				if (!c_iEnemies && !is_same_team(ent, host))
					return 0
			}
			else if (QueryEnemies(host, ent))
				return 0
		}
		case 1, 2: /* HUMANS or ZOMBIES */
		{
			if (get_bitsum(bs_InButton, host) && c_iButton == g_iTeam[host] && c_iButton == g_iTeam[ent])
			{
				if (c_iEnemies && !is_same_team(ent, host))
					return 0
			}
			else if (QueryEnemies(host, ent))
				return 0
		}
		default:
		{
			if (QueryEnemies(host, ent))
				return 0
		}
	}
	return 1
}

QueryEnemies(host, ent)
{
	if (c_iBlockTeam == 3)
		return 1
	
	switch (c_iEnemies)
	{
		case 1: if (c_iBlockTeam == g_iTeam[ent] && is_same_team(ent, host)) return 1
		case 0: if (!is_same_team(ent, host) || c_iBlockTeam == g_iTeam[ent]) return 1
	}
	
	return 0
}

TeamInfoUnstuck(id)
{
	if (!c_iUnstuck || !get_bitsum(bs_IsAlive, id) || get_bitsum(bs_IsDying, id) || !is_player_stuck(id))
		return 0
	
	if (c_iUnstuck == 4)
		return 1
	
	static i
	for (i = 1; i <= g_iMaxPlayers; i++)
	{
		if (!get_bitsum(bs_IsAlive, i) || get_bitsum(bs_IsDying, i) || i == id || g_iRange[id][i] == OUT_OF_RANGE || !is_player_stuck(i))
			continue
		
		if (c_iButton)
		{
			if (c_iEnemies)
			{
				if (!get_bitsum(bs_InButton, id) && c_iButton == g_iTeam[i])
					return 1
				
				return 0
			}
			
			return !is_same_team(id, i)
		}
		
		if (QueryEnemies(id, i))
			return 1
	}
	
	return 0
}

SetUserCvars(id)
{
	del_bitsum(bs_IsAlive, id)
	del_bitsum(bs_IsDying, id)
	del_bitsum(bs_IsBot, id)
	del_bitsum(bs_InSemiclip, id)
	del_bitsum(bs_IsSolid, id)
	del_bitsum(bs_InKnifeSecAtk, id)
	g_iTeam[id] = ZP_TEAM_UNASSIGNED
	
	del_bitsum(bs_RenderSpecial, id)
	
	arrayset(g_iAntiBoost[id], 0, MAX_PLAYERS+1)
	arrayset(g_iRange[id], OUT_OF_RANGE, MAX_PLAYERS+1)
}

/*================================================================================
 [Message Hooks]
=================================================================================*/

public MessageTeamInfo(msg_id, msg_dest)
{
	if (msg_dest != MSG_ALL && msg_dest != MSG_BROADCAST)
		return
	
	static id, szTeam[2]
	id = get_msg_arg_int(1)
	get_msg_arg_string(2, szTeam, charsmax(szTeam))
	
	if (szTeam[0] == 'S')
	{
		if (get_bitsum(bs_IsDying, id))
		{
			del_bitsum(bs_IsAlive, id)
			del_bitsum(bs_IsDying, id)
			
			if (!get_bitsum(bs_IsBot, id))
				set_task(SPEC_INTERVAL, "SpectatorCheck", id+TASK_SPECTATOR, _, _, "b")
		}
		
		g_iSpectating[id] = id
		g_iTeam[id] = ZP_TEAM_SPECTATOR
	}
}

public MessageClCorpse(msg_id, msg_dest)
{
	if (msg_dest != MSG_ALL && msg_dest != MSG_BROADCAST)
		return
	
	static id
	id = get_msg_arg_int(12)
	
	if (get_bitsum(bs_IsDying, id))
	{
		del_bitsum(bs_IsAlive, id)
		del_bitsum(bs_IsDying, id)
		g_iTeam[id] = ZP_TEAM_SPECTATOR
		
		if (!get_bitsum(bs_IsBot, id))
			set_task(SPEC_INTERVAL, "SpectatorCheck", id+TASK_SPECTATOR, _, _, "b")
	}
}

/*================================================================================
 [Custom Natives]
=================================================================================*/

/* tsc_get_user_rendering(id) */
public fn_get_user_rendering(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_valid_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[Team Semiclip] Player is not in game (%d)", id)
		return -1
	}
	
	return get_bitsum(bs_RenderSpecial, id) ? 1 : 0
}

/* tsc_set_user_rendering(id, special = 0, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16) */
public fn_set_user_rendering(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_valid_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[Team Semiclip] Player is not in game (%d)", id)
		return -1
	}
	
	switch (get_param(2))
	{
		case 0:
		{
			del_bitsum(bs_RenderSpecial, id)
			
			return 1
		}
		case 1:
		{
			add_bitsum(bs_RenderSpecial, id)
			
			g_iRenderSpecial[id][RENDER_FX] = clamp(get_param(3), 0, 20)
			
			g_iRenderSpecialColor[id][0] = clamp(get_param(4), 0, 255)
			g_iRenderSpecialColor[id][1] = clamp(get_param(5), 0, 255)
			g_iRenderSpecialColor[id][2] = clamp(get_param(6), 0, 255)
			
			g_iRenderSpecial[id][RENDER_MODE] = clamp(get_param(7), 0, 5)
			g_iRenderSpecial[id][RENDER_AMT] = clamp(get_param(8), 0, 255)
			
			return 1
		}
	}
	
	return 0
}

/* tsc_get_user_semiclip(id) */
public fn_get_user_semiclip(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_valid_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[Team Semiclip] Player is not in game (%d)", id)
		return -1
	}
	
	return get_bitsum(bs_InSemiclip, id) ? 1 : 0
}

/* tsc_get_user_anti_boost(id, other = 0) */
public fn_get_user_anti_boost(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_valid_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[Team Semiclip] Player is not in game (%d)", id)
		return -1
	}
	
	new other = get_param(2)
	
	if (other == 0) return get_bitsum(bs_InAntiBoost, id) ? 1 : 0
	else if (!is_user_valid_connected(other))
	{
		log_error(AMX_ERR_NATIVE, "[Team Semiclip] Other player is not in game (%d)", other)
		return -1
	}
	
	return g_iAntiBoost[id][other]
}

/*================================================================================
 [Stocks]
=================================================================================*/

/* credits to VEN */
stock is_player_stuck(id)
{
	static Float:originF[3]
	pev(id, pev_origin, originF)
	
	engfunc(EngFunc_TraceHull, originF, originF, 0, (pev(id, pev_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN, id, 0)
	
	if (get_tr2(0, TR_StartSolid) || get_tr2(0, TR_AllSolid) || !get_tr2(0, TR_InOpen))
		return true
	
	return false
}

/* credits to VEN */
stock is_hull_vacant(Float:origin[3], hull)
{
	engfunc(EngFunc_TraceHull, origin, origin, DONT_IGNORE_MONSTERS, hull, 0, 0)
	
	if (!get_tr2(0, TR_StartSolid) && !get_tr2(0, TR_AllSolid) && get_tr2(0, TR_InOpen))
		return true
	
	return false
}

/* Stock by (probably) Twilight Suzuka -counts number of chars in a string */
stock str_count(str[], searchchar)
{
	new count, i, len = strlen(str)
	
	for (i = 0; i <= len; i++)
	{
		if (str[i] == searchchar)
			count++
	}
	
	return count
}

/* credits to MeRcyLeZZ */
stock ham_cs_get_weapon_ent_owner(ent)
{
	#if AMXX_VERSION_NUM >= 182
	return (pev_valid(ent) == pdata_safe) ? get_pdata_cbase(ent, m_pPlayer, linux_weapons_diff, mac_weapons_diff) : 0
	#else
	return (pev_valid(ent) == pdata_safe) ? get_pdata_cbase(ent, m_pPlayer, linux_weapons_diff) : 0
	#endif
}

/* credits to me */
stock fm_cs_get_free_look_target(id)
{
	#if AMXX_VERSION_NUM >= 182
	return (pev_valid(id) == pdata_safe) ? get_pdata_int(id, m_hObserverTarget, linux_diff, mac_diff) : 0
	#else
	return (pev_valid(id) == pdata_safe) ? get_pdata_int(id, m_hObserverTarget, linux_diff) : 0
	#endif
}

/* amxmisc.inc */
stock get_configsdir(name[], len)
{
	return get_localinfo("amxx_configsdir", name, len)
}
