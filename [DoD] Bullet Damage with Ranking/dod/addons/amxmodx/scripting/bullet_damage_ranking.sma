/*================================================================================
	
		***********************************************************
		*********** [Bullet Damage with Ranking 1.3.0] ************
		***********************************************************
	
	----------------------
	-*- Licensing Info -*-
	----------------------
	
	Bullet Damage with Ranking
	by schmurgel1983(@msn.com)
	Copyright (C) 2009-2022 schmurgel1983, skhowl, gesalzen
	
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
	
	Display single, multiple, grenade or take Damage via Hud message.
	Can give a Chat announce, if you score a new weapon/personal record.
	The Chat command /bd show up a menu to configuration your bd.
	
	--------------------
	-*- Requirements -*-
	--------------------
	
	* Game: Day of Defeat 1.3
	* Metamod: Version 1.19 or later
	* AMXX: Version 1.8.0 or later
	* Module: fakemeta, hamsandwich
	
	----------------
	-*- Commands -*-
	----------------
	
	say: /bd - open bd menu
	con: bd_reset "argument" - look bd_reset.txt for all possible bd_reset commands!
	
	---------------------
	-*- Configuration -*-
	---------------------
	
	For a complete and in-depth cvar list, look at the bulletdamage.cfg file
	located in the amxmodx\configs directory.
	
	---------------
	-*- Credits -*-
	---------------
	
	* worldspawn: for few ideas - motd style, damage sorting, new command and bd_no_over_dmg ;)
	* Pneumatic: for the "bd_multi_dmg 2" idea
	* ConnorMcLeod: for Ham_TakeDamage forward idea
	* Alucard^: for the enable/disable (global) HUD-Damage idea
	* Hawk552: for optimization plugin
	
	-----------------
	-*- Changelog -*-
	-----------------
	
	* v1.0.0: (11th Apr 2010)
		- initial release
	
	* v1.0.1: (12th Apr 2010)
		- Fixed: record motd sytle (top15 from statsx.sma), HUD-Damage positions,
		   read/save/reset "top bullet damage", maybe kill over damage when enemy
		   are death (not work with sturmbots)
	
	* v1.0.2: (14th Apr 2010)
		- Fixed: blast weapon id bug (hand, stick, bazooka, pschreck, piat)
	
	* v1.1.0: (22th Apr 2010)
		- Added: Records now saved by Steam ID, only Steam authorized players can
		   made records
		- Fixed: Weapon Secondary Attack is again _Pre forward, Motd misstep when
		   it calls 2 times to fast, Finaly! Over damage when enemy are death
		   (work with sturmbots)
	
	* v1.1.1: (25th May 2010)
		- Fixed: Damage vars not reseting for non-steam players
		- Rewrite: the damage deal blast tasks, converting to, all in one task
	
	* v1.2.0: (6th Jul 2010)
		- Added: admin reset and hud flag cvar, admin show HUD-Damage, admin show
		   HUD-Damage when you hit the enemy and he is behind a wall,
		   lan server support
		- Rewrite: arc system and some stuff
		- Fixed: wrong counting of hits
		- Remove: ML 'BDwR_CHEAT' , bd_motd_method only Top15 style possible
	
	* v1.2.1: (29th Jul 2010)
		- Rewrite: code (clearing)
		- Fixed: authorized bug (thanks craigy09)
	
	* v1.3.0: (31th Jan 2011)
		- Added: Menu to configurate own player hud messages for
		   colors, position (x,y), flicker, holdtime, personal
		   records, all weapon records and admin menu
		- Fixed: damage not showing through glass and players
	
=================================================================================*/

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <xs>

#if AMXX_VERSION_NUM < 180
	#assert AMX Mod X v1.8.0 or later library required!
#endif

#include <hamsandwich>

/*================================================================================
 [Plugin Customization]
=================================================================================*/

// Save Records File
new const BD_RECORD_FILE[] = "bullet_damage_ranks"

// Firerate Time Multiply for Record Task
// 1.0 is normal | 2.0 is double
const Float:FIRERATE_MULTI = 1.5

/*================================================================================
 Customization ends here! Yes, that's it. Editing anything beyond
 here is not officially supported. Proceed at your own risk...
=================================================================================*/

/*================================================================================
 [Constants, Offsets, Macros]
=================================================================================*/

// Plugin Version
new const PLUGIN_VERSION[] = "1.3.0"

// DoD Weapon Constants
#define DODW_AMERKNIFE		1
#define DODW_GERKNIFE		2
#define DODW_COLT			3
#define DODW_LUGER			4
#define DODW_GARAND			5
#define DODW_SCOPED_KAR		6
#define DODW_THOMPSON		7
#define DODW_STG44			8
#define DODW_SPRINGFIELD	9
#define DODW_KAR			10
#define DODW_BAR			11
#define DODW_MP40			12
#define DODW_HANDGRENADE	13
#define DODW_STICKGRENADE	14
#define DODW_MG42			17
#define DODW_30_CAL			18
#define DODW_SPADE			19
#define DODW_M1_CARBINE		20
#define DODW_MG34			21
#define DODW_GREASEGUN		22
#define DODW_FG42			23
#define DODW_K43			24
#define DODW_ENFIELD		25
#define DODW_STEN			26
#define DODW_BREN			27
#define DODW_WEBLEY			28
#define DODW_BAZOOKA		29
#define DODW_PANZERSCHRECK	30
#define DODW_PIAT			31

// Config file sections
enum
{
	SECTION_NONE = 0,
	SECTION_HUD,
	SECTION_COLORS,
	SECTION_POSITIONS,
	SECTION_TIMES,
	MAX_SECTIONS
}

// Access flags
enum
{
	ACCESS_RESET = 0,
	ACCESS_HUD,
	MAX_ACCESS_FLAGS
}

// Task offsets
enum (+= 100)
{
	TASK_DAMAGE = 2000,
	TASK_DAMAGEBLAST,
	TASK_ATK2
}

// Color vars
enum
{
	COLOR_RED = 0,
	COLOR_GREEN,
	COLOR_BLUE,
	COLOR_STYLE,
	MAX_COLORS
}

// IDs inside tasks
#define ID_DAMAGE (taskid - TASK_DAMAGE)
#define ID_ATK2 (taskid - TASK_ATK2)

// few constants
const MOTD_MAX_WEAPONS = 29 // DODW_PIAT (31) - is_ignore_weapon_id (2)
const Float:POSI_TYPE_TRUE = 0.10
const Float:POSI_TYPE_FALSE = 0.01
const Float:TIME_TYPE_TRUE = 1.00
const Float:TIME_TYPE_FALSE = 0.10

// DoD Zoomed Constant
const DOD_ZOOMED = 0x14

// DoD Weapon PData Offsets (win32)
const OFFSET_WEAPONID = 91
const OFFSET_ZOOMTYPE = 364

// DoD Weapon CBase Offset (win32)
const OFFSET_WEAPONOWNER = 89

// Linux diff
const OFFSET_LINUX_WEAPONS = 4

// Weapon Names
new const WPN_NAMES[][] = {
	"", "Field Combat Knife", "Fairbairn Sykes Combat Knife", "Colt 1911 Pistol",
	"Luger '08 Pistol", "M1 Garand", "Scoped K98", "Thompson", "STG44", "Springfield",
	"K98", "BAR", "MP40", "Fragmentation Grenade", "Stick Grenade", "", "", "MG42",
	".30 caliber", "Field Spade", "M1 Carbine", "MG34", "Greasegun", "FG42", "K43",
	"Enfield", "Sten", "Bren", "Webley Revolver", "Bazooka", "Panzerschreck", "Piat"
}

// short Weapon Names
new const WPN_SHORTNAMES[][10] = {
	"", "amerknife", "gerknife", "colt", "luger", "garand", "scopedkar",
	"thompson", "mp44", "spring", "kar", "bar", "mp40", "handgren",
	"stickgren", "", "", "mg42", "30cal", "spade", "m1carbine",
	"mg34", "greasegun", "fg42", "k43", "enfield", "sten", "bren",
	"webley", "bazooka", "pschreck", "piat"
}

// Weapon entity Names
new const WPN_ENTNAMES[][] = {
	"", "weapon_amerknife", "weapon_gerknife", "weapon_colt", "weapon_luger",
	"weapon_garand", "weapon_scopedkar", "weapon_thompson", "weapon_mp44", "weapon_spring",
	"weapon_kar", "weapon_bar", "weapon_mp40", "weapon_mg42", "weapon_30cal",
	"weapon_spade", "weapon_m1carbine", "weapon_mg34", "weapon_greasegun", "weapon_fg42",
	"weapon_k43", "weapon_enfield", "weapon_sten", "weapon_bren", "weapon_webley"
}

// Weapon atk2 entity Names
new const WPN_ENTNAMESATK2[][] = {
	"", "weapon_garand", "weapon_kar", "weapon_k43"
}

// Weapon fastest firerate time
new const Float:WPN_FIRERATE[] = {
	0.1,	// --- (NOTHING)
	0.37,	// AMERKNIFE
	0.37,	// GERKNIFE
	0.12,	// COLT
	0.12,	// LUGER
	0.43,	// GARAND
	1.72,	// SCOPED_KAR
	0.11,	// THOMPSON
	0.11,	// STG44
	1.98,	// SPRINGFIELD
	1.7,	// KAR
	0.13,	// BAR
	0.11,	// MP40
	0.1,	// --- (HANDGRENADE)
	0.1,	// --- (STICKGRENADE)
	0.1,	// --- (STICKGRENADE_EX)
	0.1,	// --- (HANDGRENADE_EX)
	0.11,	// MG42
	0.11,	// 30_CAL
	0.37,	// SPADE
	0.11,	// M1_CARBINE
	0.11,	// MG34
	0.16,	// GREASEGUN
	0.11,	// FG42
	0.43,	// K43
	1.76,	// ENFIELD
	0.11,	// STEN
	0.13,	// BREN
	0.13,	// WEBLEY
	0.1,	// --- (BAZOOKA)
	0.1,	// --- (PANZERSCHRECK)
	0.1		// --- (PIAT)
}
const Float:ATK2_KAR = 0.86
const Float:ATK2_GARAND_K43 = 1.18
const Float:ZOOMED_FG42 = 0.33

// Menu keys
const KEYSMENU = MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_8|MENU_KEY_9|MENU_KEY_0

/*================================================================================
 [Global Variables]
=================================================================================*/

// Player vars
new g_iDamageDealt[33] // total damage
new g_iWeaponUse[33] // current weapon
new g_iWeaponEntity[33] // weapon entity
new g_iHits[33] // hits
new g_bAttack2Weapon[33] // weapon attack 2
new g_iPreHealth[33] // pre health
new g_iPostHealth[33] // post health
new g_iBlastDamageDealt[33] // blast total damage
new g_iBlastHits[33] // blast hits
new Float:g_flWallOrigin[33][33][3] // visible [owner][other][origin]
new g_iAuthorized[33] // authorized steam player
new g_bPreDeath[33] // pre death
new g_bWhileRecordTask[33] // while record task
new g_bBlastWallVisible[33] // Blast Damage is Visible

// Player Hud stuff
new g_iShowSingleHud[33] // show hud single damage message
new g_iShowMultipleHud[33] // show hud multi damage message
new g_iShowBlastHud[33] // show hud he damage message
new g_iShowTakeHud[33] // show hud take damage message
new g_iDynamicMenu[33] // what section u are in dynamic menu
new g_iMenuType[33] // Position type 0.01 or 0.1 and Time type 1.0 or 0.1

// Player Hud config stuff
new g_iSingleColor[33][MAX_COLORS] // single colors and style
new g_iMultipleColor[33][MAX_COLORS] // multi colors and style
new g_iBlastColor[33][MAX_COLORS] // he colors and style
new g_iTakeColor[33][MAX_COLORS] // take colors and style
new Float:g_flSinglePosition_X[33] // single X position message
new Float:g_flSinglePosition_Y[33] // single Y position message
new Float:g_flMultiplePosition_X[33] // multi X position message
new Float:g_flMultiplePosition_Y[33] // multi Y position message
new Float:g_flBlastPosition_X[33] // he X position message
new Float:g_flBlastPosition_Y[33] // he Y position message
new Float:g_flTakePosition_X[33] // take X position message
new Float:g_flTakePosition_Y[33] // take Y position message
new Float:g_flSingleTime[33] // single holdtime message
new Float:g_flMultipleTime[33] // multi holdtime message
new Float:g_flBlastTime[33] // he holdtime message
new Float:g_flTakeTime[33] // take holdtime message

// Game vars
new g_iMaxPlayers // max player counter
new g_HudSyncSingle, g_HudSyncMultiple, g_HudSyncBlast, g_HudSyncTake // message sync objects
new g_bMotdPrepair // flag for whenever a Motd prepairs

// Customization vars
new g_access_flag[MAX_ACCESS_FLAGS]

// CVAR pointers
new cvar_BulletDamage, cvar_HudDamageWall, cvar_SaveStatsPersonal,
cvar_ChatWeapon, cvar_ChatPersonal, cvar_MotdSort, cvar_AdminHudFlag,
cvar_AdminResetFlag, cvar_Single, cvar_Multiple, cvar_NoOverDamage,
cvar_BlastDamage, cvar_TakeDamage, cvar_MoreTime, cvar_HudDamage,
cvar_SaveStats, cvar_SvLan, cvar_FFA

// Record vars
new g_szDataDir[64] // file parth of data folder
new g_szRecordFile[128] // file parth of BD_RECORD_FILE
new g_iRecord[DODW_PIAT+1] // for sorting method
new g_szCachedNames[DODW_PIAT+1][32] // cached record names
new g_szCachedSteamIDs[DODW_PIAT+1][32] // cached record steam id's
new g_iCachedDamage[DODW_PIAT+1] // cached record damage
new g_iCachedHits[DODW_PIAT+1] // cached record hits
new g_iCachedResets[DODW_PIAT+1] // cached record resets

// Personal record vars
new g_iPersonalDamage[33][DODW_PIAT+1] // personal record damage
new g_iPersonalHits[33][DODW_PIAT+1] // personal record hits
new g_iPersonalResets[33][DODW_PIAT+1] // personal record resets

// Cached stuff for players
new g_bIsConnected[33] // whether player is connected
new g_bIsAlive[33] // whether player is alive
new g_szPlayerName[33][32] // player's name
new g_szSteamID[33][32] // player's Steam ID

// Macros
#define is_user_valid_connected(%1) (1 <= %1 <= g_iMaxPlayers && g_bIsConnected[%1])
#define is_ignore_weapon_id(%1) (%1 == 15 || %1 == 16)
#define user_has_flag(%1,%2) (get_user_flags(%1) & g_access_flag[%2])

/*================================================================================
 [Precache, Init and Cfg]
=================================================================================*/

public plugin_precache()
{
	// Tampering with the author and plugin name will violate copyrights
	// Register earlier to show up in plugins list properly after plugin disable/error at loading
	register_plugin("Bullet Damage with Ranking", PLUGIN_VERSION, "schmurgel1983")
}

public plugin_init()
{
	// Language files
	register_dictionary("bullet_damage_ranking.txt")
	
	// HAM Forwards "player"
	RegisterHam(Ham_Spawn, "player", "fwd_PlayerSpawn_Post", 1)
	RegisterHam(Ham_Killed, "player", "fwd_PlayerKilled")
	RegisterHam(Ham_TakeDamage, "player", "fwd_TakeDamage_Post", 1)
	RegisterHam(Ham_TraceAttack, "player", "fwd_TraceAttack")
	
	// HAM Forwards "entity"
	for (new i = 1; i < sizeof WPN_ENTNAMESATK2; i++)
		if (WPN_ENTNAMESATK2[i][0]) RegisterHam(Ham_Weapon_SecondaryAttack, WPN_ENTNAMESATK2[i], "fwd_Weapon_SecAtk")
	for (new i = 1; i < sizeof WPN_ENTNAMES; i++)
		if (WPN_ENTNAMES[i][0]) RegisterHam(Ham_Item_Deploy, WPN_ENTNAMES[i], "fwd_Item_Deploy_Post", 1)
	
	// Client Commands
	register_clcmd("say /bd", "clcmd_saymenu")
	register_clcmd("say_team /bd", "clcmd_saymenu")
	
	// Menus
	register_menu("Main Menu", KEYSMENU, "menu_main")
	register_menu("Config Menu", KEYSMENU, "menu_config")
	register_menu("Dynamic Menu Main", KEYSMENU, "menu_dynamic_main")
	register_menu("Dynamic Menu Color", KEYSMENU, "menu_dynamic_color")
	register_menu("Dynamic Menu Posi", KEYSMENU, "menu_dynamic_posi")
	register_menu("Dynamic Menu Time", KEYSMENU, "menu_dynamic_time")
	
	// Admin Commands
	register_concmd("bd_reset", "cmd_reset", _, "<argument> - Record Reset", 0)
	
	// Message hooks
	register_message(get_user_msgid("Health"), "message_Health")
	
	// CVARS - General Purpose
	cvar_BulletDamage = register_cvar("bd_on", "1")
	cvar_SaveStats = register_cvar("bd_save_stats", "1")
	cvar_SaveStatsPersonal = register_cvar("bd_save_stats_personal", "1")
	cvar_ChatWeapon = register_cvar("bd_chat_weapon", "1")
	cvar_ChatPersonal = register_cvar("bd_chat_personal", "1")
	cvar_MotdSort = register_cvar("bd_motd_sorting", "0")
	cvar_FFA = register_cvar("bd_ffa_dmg", "0")
	cvar_NoOverDamage = register_cvar("bd_no_over_dmg", "0")
	cvar_MoreTime = register_cvar("bd_more_time", "1.0")
	
	// CVARS - Admin
	cvar_AdminHudFlag = register_cvar("bd_hud_flag", "c")
	cvar_AdminResetFlag = register_cvar("bd_reset_flag", "g")
	
	// CVARS - HUD Messages
	cvar_HudDamage = register_cvar("bd_hud_dmg", "1")
	cvar_HudDamageWall = register_cvar("bd_hud_dmg_wall", "1")
	cvar_Single = register_cvar("bd_single_dmg", "1")
	cvar_Multiple = register_cvar("bd_multiple_dmg", "1")
	cvar_BlastDamage = register_cvar("bd_blast_dmg", "1")
	cvar_TakeDamage = register_cvar("bd_take_dmg", "1")
	
	// CVARS - Others
	cvar_SvLan = get_cvar_pointer("sv_lan")
	register_cvar("BDwR_version", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY)
	set_cvar_string("BDwR_version", PLUGIN_VERSION)
	
	// Create the HUD Sync Object
	g_HudSyncSingle = CreateHudSyncObj(1)
	g_HudSyncMultiple = CreateHudSyncObj(2)
	g_HudSyncBlast = CreateHudSyncObj(4)
	g_HudSyncTake = CreateHudSyncObj(3)
	
	// Get Max Players
	g_iMaxPlayers = get_maxplayers()
}

public plugin_cfg()
{
	// Get configs dir
	new configsdir[32], folder[128]
	get_configsdir(configsdir, charsmax(configsdir))
	
	// Execute config file (bulletdamage.cfg)
	server_cmd("exec %s/bulletdamage.cfg", configsdir)
	
	// Cache data dir
	get_datadir(g_szDataDir, charsmax(g_szDataDir))
	
	// Cache record file
	format(g_szRecordFile, charsmax(g_szRecordFile), "%s/%s.ini", g_szDataDir, BD_RECORD_FILE)
	
	// Read record file
	load_top()
	
	// check if folder bd_configs exists, if not create one
	format(folder, charsmax(folder), "%s/bd_configs", g_szDataDir)
	if (!dir_exists(folder)) mkdir(folder)
	
	// check if folder bd_records exists, if not create one
	format(folder, charsmax(folder), "%s/bd_records", g_szDataDir)
	if (!dir_exists(folder)) mkdir(folder)
	
	// Get Access Flags
	new szFlags[24]
	get_pcvar_string(cvar_AdminResetFlag, szFlags, charsmax(szFlags))
	g_access_flag[ACCESS_RESET] = read_flags(szFlags)
	get_pcvar_string(cvar_AdminHudFlag, szFlags, charsmax(szFlags))
	g_access_flag[ACCESS_HUD] = read_flags(szFlags)
}

public client_putinserver(id)
{
	// Player fully connected
	g_bIsConnected[id] = true
	
	// Player vars
	set_player_vars(id)
	
	// Cache player's name and authid
	get_user_info(id, "name", g_szPlayerName[id], charsmax(g_szPlayerName[]))
	get_user_authid(id, g_szSteamID[id], charsmax(g_szSteamID[]))
	
	// authorized?
	g_iAuthorized[id] = str_to_num(g_szSteamID[id][10])
	
	// do player stuff
	
	// Set a task to let Display Help
	set_task(30.0, "DisplayBulletDamageHelp", id)
	
	// Load personal top & hud config
	load_hud_vars(id)
	load_personal_top(id)
	check_resets(id)
	
	// Not authorized
	if (!g_iAuthorized[id]) return
	
	// Check if Player have Records
	new szSteam[32], save
	szSteam = g_szSteamID[id]
	
	for(new i = DODW_AMERKNIFE; i <= DODW_PIAT; i++)
	{
		// check steam id
		if(is_ignore_weapon_id(i) || !equali(szSteam, g_szCachedSteamIDs[i])) continue
		
		// Cache new name
		g_szCachedNames[i] = g_szPlayerName[id]
		save = true
	}
	// Save?
	if (save && get_pcvar_num(cvar_SaveStats))
		save_top()
}

public client_disconnect(id)
{
	// Player disconnected
	g_bIsConnected[id] = false
	
	// Remove Tasks
	remove_task(id)
	remove_task(id+TASK_DAMAGE)
	remove_task(id+TASK_DAMAGEBLAST)
	remove_task(id+TASK_ATK2)
	
	// Clear player vars
	set_player_vars(id)
}

public client_infochanged(id)
{
	// Cache player's name and authid
	get_user_info(id, "name", g_szPlayerName[id], charsmax(g_szPlayerName[]))
	get_user_authid(id, g_szSteamID[id], charsmax(g_szSteamID[]))
	
	// authorized?
	g_iAuthorized[id] = str_to_num(g_szSteamID[id][10])
	
	// Check if Player have Records
	if (g_iAuthorized[id])
	{
		// Check if Player have Records
		new szSteam[32], save
		szSteam = g_szSteamID[id]
		
		for (new i = DODW_AMERKNIFE; i <= DODW_PIAT; i++)
		{
			// check steam id
			if (is_ignore_weapon_id(i) || !equali(szSteam, g_szCachedSteamIDs[i])) continue
			
			// Cache new name
			g_szCachedNames[i] = g_szPlayerName[id]
			save = true
		}
		// Save?
		if (save && get_pcvar_num(cvar_SaveStats))
			save_top()
	}
	
	// Lan Server?
	if (get_pcvar_num(cvar_SvLan))
		g_iAuthorized[id] = 1
}

/*================================================================================
 [Main Forwards]
=================================================================================*/

public fwd_PlayerSpawn_Post(id)
{
	// not alive or not team
	if(!is_user_alive(id) || !get_user_team(id)) return
	
	// player spawned
	g_bPreDeath[id] = false
	g_bIsAlive[id] = true
}

public fwd_PlayerKilled(victim, attacker, shouldgib)
{
	// player killed
	g_bPreDeath[victim] = true
}

public fwd_TakeDamage_Post(victim, inflictor, attacker, Float:damage, damage_type)
{
	// Plugin off
	if (!get_pcvar_num(cvar_BulletDamage)) return HAM_IGNORED
	
	new dmg_take
	if ((dmg_take = floatround(damage)) <= 0) return HAM_IGNORED
	
	if (g_iShowTakeHud[victim] && get_pcvar_num(cvar_TakeDamage))
	{
		ClearSyncHud(victim, g_HudSyncTake)
		set_hudmessage(g_iTakeColor[victim][COLOR_RED], g_iTakeColor[victim][COLOR_GREEN], g_iTakeColor[victim][COLOR_BLUE], g_flTakePosition_X[victim], g_flTakePosition_Y[victim], g_iTakeColor[victim][COLOR_STYLE], 0.0, g_flTakeTime[victim], 1.0, 1.0, -1)
		ShowSyncHudMsg(victim, g_HudSyncTake, "%i", dmg_take)
	}
	
	// Allow to damage?
	if (!g_bIsAlive[victim] || !is_user_valid_connected(attacker) || victim == attacker || (!get_pcvar_num(cvar_FFA) && get_user_team(victim) == get_user_team(attacker))) return HAM_IGNORED
	
	// Victim is PreDeath
	if (g_bPreDeath[victim]) g_bIsAlive[victim] = false
	
	// Damage by blast weapons
	if (damage_type & DMG_BLAST)
	{
		// Valid blast damage?
		if (!pev_valid(inflictor)) return HAM_IGNORED
		
		static classname[11]
		pev(inflictor, pev_classname, classname, 10)
		
		// Check blast weaponid
		static weapon
		weapon = ClassNameToWeaponID(classname)
		if (!weapon) return HAM_IGNORED
		
		// Remove blast damage timer
		remove_task(attacker+TASK_DAMAGEBLAST)
		
		// NO over Damage?
		if (get_pcvar_num(cvar_NoOverDamage))
		{
			// Get post health
			g_iPostHealth[victim] = g_iPreHealth[victim] - dmg_take
			clamp(g_iPostHealth[victim], 0, 999999)
			
			// Damage higher as Health
			if (dmg_take > g_iPreHealth[victim] - g_iPostHealth[victim])
				dmg_take = g_iPreHealth[victim]
			
			// New pre health
			g_iPreHealth[victim] = g_iPostHealth[victim]
		}
		
		// Damage deal and Hits
		g_iBlastDamageDealt[attacker] += dmg_take
		g_iBlastHits[attacker]++
		
		// Blast wall damage visible?
		if(!g_bBlastWallVisible[attacker])
			g_bBlastWallVisible[attacker] = ExecuteHam(Ham_FVisible, attacker, victim)
		
		// store Parameters
		static param[2]
		param[0] = weapon
		param[1] = attacker
		
		// Set Task for multiple Damage
		set_task(WPN_FIRERATE[weapon], "damage_deal_blast", attacker+TASK_DAMAGEBLAST, param, 2)
		
		return HAM_IGNORED
	}
	
	// I will made a new Record!
	g_bWhileRecordTask[attacker] = true
	
	// Remove damage timer
	remove_task(attacker+TASK_DAMAGE)
	
	// NO over Damage?
	if (get_pcvar_num(cvar_NoOverDamage))
	{
		// Get post health
		g_iPostHealth[victim] = g_iPreHealth[victim] - dmg_take
		clamp(g_iPostHealth[victim], 0, 999999)
		
		// Damage higher as Health
		if (dmg_take > g_iPreHealth[victim] - g_iPostHealth[victim])
			dmg_take = g_iPreHealth[victim]
		
		// New pre health
		g_iPreHealth[victim] = g_iPostHealth[victim]
	}
	
	// Damage deal and Hits
	g_iDamageDealt[attacker] += dmg_take
	g_iHits[attacker]++
	
	// Valid entity
	if (pev_valid(g_iWeaponEntity[attacker]))
	{
		// Setup Timer
		static Float:timer
		switch(g_iWeaponUse[attacker])
		{
			case DODW_GARAND, DODW_K43:
			{
				if (g_bAttack2Weapon[attacker])
					timer = ATK2_GARAND_K43 * FIRERATE_MULTI
				else
					timer = WPN_FIRERATE[g_iWeaponUse[attacker]] * FIRERATE_MULTI
			}
			case DODW_KAR:
			{
				if (g_bAttack2Weapon[attacker])
					timer = ATK2_KAR * FIRERATE_MULTI
				else
					timer = WPN_FIRERATE[DODW_KAR] * FIRERATE_MULTI
			}
			case DODW_FG42:
			{
				if (fm_dod_get_user_zoom(attacker) == DOD_ZOOMED)
					timer = ZOOMED_FG42 * FIRERATE_MULTI
				else
					timer = WPN_FIRERATE[DODW_FG42] * FIRERATE_MULTI
			}
			default: timer = WPN_FIRERATE[g_iWeaponUse[attacker]] * FIRERATE_MULTI
		}
		
		// Set Task for multiple Damage
		set_task(timer+get_pcvar_float(cvar_MoreTime), "damage_deal", attacker+TASK_DAMAGE)
	}
	// Invalid entity, make single Damage
	else
		damage_deal(attacker+TASK_DAMAGE)
	
	// Static Hud Damage Wall
	static HudDamageWall, HudVisible
	HudDamageWall = get_pcvar_num(cvar_HudDamageWall)
	HudVisible = fm_is_visible(attacker, g_flWallOrigin[attacker][victim])
	
	// Display HUD damage?
	switch (get_pcvar_num(cvar_HudDamage))
	{
		case 2: // Admin
		{
			if (!user_has_flag(attacker, ACCESS_HUD) || (!HudDamageWall && !HudVisible)) return HAM_IGNORED
			
			// Display option
			if (g_iShowMultipleHud[attacker] && get_pcvar_num(cvar_Multiple))
			{
				ClearSyncHud(attacker, g_HudSyncMultiple)
				set_hudmessage(g_iMultipleColor[attacker][COLOR_RED], g_iMultipleColor[attacker][COLOR_GREEN], g_iMultipleColor[attacker][COLOR_BLUE], g_flMultiplePosition_X[attacker], g_flMultiplePosition_Y[attacker], g_iMultipleColor[attacker][COLOR_STYLE], 0.0, g_flMultipleTime[attacker], 1.0, 1.0, -1)
				ShowSyncHudMsg(attacker, g_HudSyncMultiple, "%i", g_iDamageDealt[attacker])
			}
			if (g_iShowSingleHud[attacker] && get_pcvar_num(cvar_Single))
			{
				ClearSyncHud(attacker, g_HudSyncSingle)
				set_hudmessage(g_iSingleColor[attacker][COLOR_RED], g_iSingleColor[attacker][COLOR_GREEN], g_iSingleColor[attacker][COLOR_BLUE], g_flSinglePosition_X[attacker], g_flSinglePosition_Y[attacker], g_iSingleColor[attacker][COLOR_STYLE], 0.0, g_flSingleTime[attacker], 1.0, 1.0, -1)
				ShowSyncHudMsg(attacker, g_HudSyncSingle, "%i", dmg_take)
			}
		}
		case 1: // Player
		{
			if ((HudDamageWall == 2 && !user_has_flag(attacker, ACCESS_HUD) && !HudVisible) || (!HudDamageWall && !HudVisible)) return HAM_IGNORED
			
			// Display option
			if (g_iShowMultipleHud[attacker] && get_pcvar_num(cvar_Multiple))
			{
				ClearSyncHud(attacker, g_HudSyncMultiple)
				set_hudmessage(g_iMultipleColor[attacker][COLOR_RED], g_iMultipleColor[attacker][COLOR_GREEN], g_iMultipleColor[attacker][COLOR_BLUE], g_flMultiplePosition_X[attacker], g_flMultiplePosition_Y[attacker], g_iMultipleColor[attacker][COLOR_STYLE], 0.0, g_flMultipleTime[attacker], 1.0, 1.0, -1)
				ShowSyncHudMsg(attacker, g_HudSyncMultiple, "%i", g_iDamageDealt[attacker])
			}
			if (g_iShowSingleHud[attacker] && get_pcvar_num(cvar_Single))
			{
				ClearSyncHud(attacker, g_HudSyncSingle)
				set_hudmessage(g_iSingleColor[attacker][COLOR_RED], g_iSingleColor[attacker][COLOR_GREEN], g_iSingleColor[attacker][COLOR_BLUE], g_flSinglePosition_X[attacker], g_flSinglePosition_Y[attacker], g_iSingleColor[attacker][COLOR_STYLE], 0.0, g_flSingleTime[attacker], 1.0, 1.0, -1)
				ShowSyncHudMsg(attacker, g_HudSyncSingle, "%i", dmg_take)
			}
		}
	}
	return HAM_IGNORED
}

public fwd_TraceAttack(victim, attacker, Float:damage, Float:direction[3], tracehandle, damage_type)
{
	// Plugin off
	if (!get_pcvar_num(cvar_BulletDamage)) return HAM_IGNORED
	
	// Allow to trace?
	if(!(damage_type & DMG_BULLET) || !is_user_valid_connected(attacker) || !g_bIsAlive[victim] || victim == attacker || (!get_pcvar_num(cvar_FFA) && get_user_team(victim) == get_user_team(attacker))) return HAM_IGNORED
	
	// get bullet impacting origin
	get_tr2(tracehandle, TR_vecEndPos, g_flWallOrigin[attacker][victim])
	
	return HAM_IGNORED
}

public fwd_Weapon_SecAtk(weapon_ent)
{
	// Plugin off
	if (!get_pcvar_num(cvar_BulletDamage)) return HAM_IGNORED
	
	// Get weapon's owner
	static owner
	owner = ham_dod_get_weapon_ent_owner(weapon_ent)
	
	// remove weapon atk2 task
	remove_task(owner+TASK_ATK2)
	
	// set weapon atk2
	g_bAttack2Weapon[owner] = true
	set_task(0.2, "reset_atk2", owner+TASK_ATK2)
	
	return HAM_IGNORED
}

public fwd_Item_Deploy_Post(weapon_ent)
{
	// Get weapon's owner
	static owner
	owner = ham_dod_get_weapon_ent_owner(weapon_ent)
	
	// Owner is PreDeath
	if (g_bPreDeath[owner]) return HAM_IGNORED
	
	// Check Cheating
	if (g_bWhileRecordTask[owner])
	{
		// Cheat detected
		remove_task(owner+TASK_DAMAGE)
		damage_deal(owner+TASK_DAMAGE)
	}
	
	// Store current weapon's id for reference
	g_iWeaponUse[owner] = fm_dod_get_weapon_id(weapon_ent)
	g_iWeaponEntity[owner] = weapon_ent
	
	return HAM_IGNORED
}

/*================================================================================
 [Client Commands]
=================================================================================*/

// Say "bd"
public clcmd_saymenu(id)
{
	if (get_pcvar_num(cvar_BulletDamage))
		show_menu_main(id) // show main menu
}

/*================================================================================
 [Admin Commands]
=================================================================================*/

public cmd_reset(id, level, cid)
{
	// Get Access
	if (!cmd_access(id, g_access_flag[ACCESS_RESET], cid, 2))
	{
		console_print(id, "[BD] %L.", id, "BD_NOT_ACCESS")
		return PLUGIN_HANDLED
	}
	
	// Retrieve string arguments
	new arg[13]
	read_argv(1, arg, charsmax(arg))
	
	// Switch string
	switch (arg[0])
	{
		case 'a':
		{
			switch(arg[1])
			{
				case 'l':
				{
					// Reset all records and give console confirmation
					reset_top(0, 1)
					console_print(id, "[BD] %L %L", id, "MENU_RESET_ALL", id, "MENU_RESET_RECORD")
					return PLUGIN_HANDLED
				}
				case 'm':
				{
					// Reset AMERKNIFE record and give console confirmation
					reset_top(DODW_AMERKNIFE)
					console_print(id, "[BD] %s %L", WPN_NAMES[DODW_AMERKNIFE], id, "MENU_RESET_RECORD")
					return PLUGIN_HANDLED
				}
			}
		}
		case 'b':
		{
			switch(arg[2])
			{
				case 'r':
				{
					// Reset BAR record and give console confirmation
					reset_top(DODW_BAR)
					console_print(id, "[BD] %s %L", WPN_NAMES[DODW_BAR], id, "MENU_RESET_RECORD")
					return PLUGIN_HANDLED
				}
				case 'z':
				{
					// Reset BAZOOKA record and give console confirmation
					reset_top(DODW_BAZOOKA)
					console_print(id, "[BD] %s %L", WPN_NAMES[DODW_BAZOOKA], id, "MENU_RESET_RECORD")
					return PLUGIN_HANDLED
				}
				case 'e':
				{
					// Reset BREN record and give console confirmation
					reset_top(DODW_BREN)
					console_print(id, "[BD] %s %L", WPN_NAMES[DODW_BREN], id, "MENU_RESET_RECORD")
					return PLUGIN_HANDLED
				}
			}
		}
		case 'c':
		{
			// Reset COLT record and give console confirmation
			reset_top(DODW_COLT)
			console_print(id, "[BD] %s %L", WPN_NAMES[DODW_COLT], id, "MENU_RESET_RECORD")
			return PLUGIN_HANDLED
		}
		case 'e':
		{
			// Reset ENFIELD record and give console confirmation
			reset_top(DODW_ENFIELD)
			console_print(id, "[BD] %s %L", WPN_NAMES[DODW_ENFIELD], id, "MENU_RESET_RECORD")
			return PLUGIN_HANDLED
		}
		case 'f':
		{
			// Reset FG42 record and give console confirmation
			reset_top(DODW_FG42)
			console_print(id, "[BD] %s %L", WPN_NAMES[DODW_FG42], id, "MENU_RESET_RECORD")
			return PLUGIN_HANDLED
		}
		case 'g':
		{
			switch(arg[1])
			{
				case 'a':
				{
					// Reset GARAND record and give console confirmation
					reset_top(DODW_GARAND)
					console_print(id, "[BD] %s %L", WPN_NAMES[DODW_GARAND], id, "MENU_RESET_RECORD")
					return PLUGIN_HANDLED
				}
				case 'e':
				{
					// Reset GERKNIFE record and give console confirmation
					reset_top(DODW_GERKNIFE)
					console_print(id, "[BD] %s %L", WPN_NAMES[DODW_GERKNIFE], id, "MENU_RESET_RECORD")
					return PLUGIN_HANDLED
				}
				case 'r':
				{
					// Reset GREASEGUN record and give console confirmation
					reset_top(DODW_GREASEGUN)
					console_print(id, "[BD] %s %L", WPN_NAMES[DODW_GREASEGUN], id, "MENU_RESET_RECORD")
					return PLUGIN_HANDLED
				}
			}
		}
		case 'h':
		{
			// Reset HANDGRENADE record and give console confirmation
			reset_top(DODW_HANDGRENADE)
			console_print(id, "[BD] %s %L", WPN_NAMES[DODW_HANDGRENADE], id, "MENU_RESET_RECORD")
			return PLUGIN_HANDLED
		}
		case 'k':
		{
			switch(arg[1])
			{
				case 'a':
				{
					// Reset KAR record and give console confirmation
					reset_top(DODW_KAR)
					console_print(id, "[BD] %s %L", WPN_NAMES[DODW_KAR], id, "MENU_RESET_RECORD")
					return PLUGIN_HANDLED
				}
				case '4':
				{
					// Reset K43 record and give console confirmation
					reset_top(DODW_K43)
					console_print(id, "[BD] %s %L", WPN_NAMES[DODW_K43], id, "MENU_RESET_RECORD")
					return PLUGIN_HANDLED
				}
			}
		}
		case 'l':
		{
			// Reset LUGER record and give console confirmation
			reset_top(DODW_LUGER)
			console_print(id, "[BD] %s %L", WPN_NAMES[DODW_LUGER], id, "MENU_RESET_RECORD")
			return PLUGIN_HANDLED
		}
		case 'm':
		{
			if(arg[1] == 'g' && arg[2] == '3')
			{
				// Reset MG34 record and give console confirmation
				reset_top(DODW_MG34)
				console_print(id, "[BD] %s %L", WPN_NAMES[DODW_MG34], id, "MENU_RESET_RECORD")
				return PLUGIN_HANDLED
			}
			else if(arg[1] == 'g' && arg[2] == '4')
			{
				// Reset MG42 record and give console confirmation
				reset_top(DODW_MG42)
				console_print(id, "[BD] %s %L", WPN_NAMES[DODW_MG42], id, "MENU_RESET_RECORD")
				return PLUGIN_HANDLED
			}
			else if(arg[1] == 'p' && arg[3] == '0')
			{
				// Reset MP40 record and give console confirmation
				reset_top(DODW_MP40)
				console_print(id, "[BD] %s %L", WPN_NAMES[DODW_MP40], id, "MENU_RESET_RECORD")
				return PLUGIN_HANDLED
			}
			else if(arg[1] == 'p' && arg[3] == '4')
			{
				// Reset STG44 record and give console confirmation
				reset_top(DODW_STG44)
				console_print(id, "[BD] %s %L", WPN_NAMES[DODW_STG44], id, "MENU_RESET_RECORD")
				return PLUGIN_HANDLED
			}
			else if(arg[1] == '1')
			{
				// Reset M1_CARBINE record and give console confirmation
				reset_top(DODW_M1_CARBINE)
				console_print(id, "[BD] %s %L", WPN_NAMES[DODW_M1_CARBINE], id, "MENU_RESET_RECORD")
				return PLUGIN_HANDLED
			}
		}
		case 'p':
		{
			switch(arg[1])
			{
				case 'i':
				{
					// Reset PIAT record and give console confirmation
					reset_top(DODW_PIAT)
					console_print(id, "[BD] %s %L", WPN_NAMES[DODW_PIAT], id, "MENU_RESET_RECORD")
					return PLUGIN_HANDLED
				}
				case 's', 'a':
				{
					// Reset PANZERSCHRECK record and give console confirmation
					reset_top(DODW_PANZERSCHRECK)
					console_print(id, "[BD] %s %L", WPN_NAMES[DODW_PANZERSCHRECK], id, "MENU_RESET_RECORD")
					return PLUGIN_HANDLED
				}
			}
		}
		case 's':
		{
			switch(arg[2])
			{
				case 'o':
				{
					// Reset SCOPED_KAR record and give console confirmation
					reset_top(DODW_SCOPED_KAR)
					console_print(id, "[BD] %s %L", WPN_NAMES[DODW_SCOPED_KAR], id, "MENU_RESET_RECORD")
					return PLUGIN_HANDLED
				}
				case 'a':
				{
					// Reset SPADE record and give console confirmation
					reset_top(DODW_SPADE)
					console_print(id, "[BD] %s %L", WPN_NAMES[DODW_SPADE], id, "MENU_RESET_RECORD")
					return PLUGIN_HANDLED
				}
				case 'r':
				{
					// Reset SPRINGFIELD record and give console confirmation
					reset_top(DODW_SPRINGFIELD)
					console_print(id, "[BD] %s %L", WPN_NAMES[DODW_SPRINGFIELD], id, "MENU_RESET_RECORD")
					return PLUGIN_HANDLED
				}
				case 'e':
				{
					// Reset STEN record and give console confirmation
					reset_top(DODW_STEN)
					console_print(id, "[BD] %s %L", WPN_NAMES[DODW_STEN], id, "MENU_RESET_RECORD")
					return PLUGIN_HANDLED
				}
				case 'i':
				{
					// Reset STICKGRENADE record and give console confirmation
					reset_top(DODW_STICKGRENADE)
					console_print(id, "[BD] %s %L", WPN_NAMES[DODW_STICKGRENADE], id, "MENU_RESET_RECORD")
					return PLUGIN_HANDLED
				}
			}
		}
		case 't':
		{
			// Reset THOMPSON record and give console confirmation
			reset_top(DODW_THOMPSON)
			console_print(id, "[BD] %s %L", WPN_NAMES[DODW_THOMPSON], id, "MENU_RESET_RECORD")
			return PLUGIN_HANDLED
		}
		case 'w':
		{
			// Reset WEBLEY record and give console confirmation
			reset_top(DODW_WEBLEY)
			console_print(id, "[BD] %s %L", WPN_NAMES[DODW_WEBLEY], id, "MENU_RESET_RECORD")
			return PLUGIN_HANDLED
		}
		case '3':
		{
			if(arg[1] == '0' && arg[2] == 'c')
			{
				// Reset 30_CAL record and give console confirmation
				reset_top(DODW_30_CAL)
				console_print(id, "[BD] %s %L", WPN_NAMES[DODW_30_CAL], id, "MENU_RESET_RECORD")
				return PLUGIN_HANDLED
			}
		}
	}
	
	// Retrieve integer arguments
	new weapon
	weapon = str_to_num(arg)
	
	// Switch integer
	if(!is_ignore_weapon_id(weapon) && weapon > 0 && weapon < 32)
	{
		// Reset "argument" record and give console confirmation
		reset_top(weapon)
		console_print(id, "[BD] %s %L", WPN_NAMES[weapon], id, "MENU_RESET_RECORD")
		return PLUGIN_HANDLED
	}
	else
	{
		// Error :(
		console_print(id, "[BD] %L", id, "MENU_RESET_UNKNOWN")
	}
	return PLUGIN_HANDLED
}

/*================================================================================
 [Menus]
=================================================================================*/

// Main Menu
show_menu_main(id)
{
	static menu[512], len
	len = 0
	
	// Title
	len += formatex(menu[len], charsmax(menu) - len, "\yBullet Damage^n^n")
	
	// 1. Hud Single Damage
	if (!get_pcvar_num(cvar_Single))
		len += formatex(menu[len], charsmax(menu) - len, "\d1. %L [%L]^n", id, "MENU_SINGLE", id, "MENU_OFF")
	else if (g_iShowSingleHud[id])
		len += formatex(menu[len], charsmax(menu) - len, "\r1.\w %L\y [%L]^n", id, "MENU_SINGLE", id, "MENU_ON")
	else
		len += formatex(menu[len], charsmax(menu) - len, "\r1.\w %L\y [\r%L\y]^n", id, "MENU_SINGLE", id, "MENU_OFF")
	
	// 2. Hud Multi Damage
	if (!get_pcvar_num(cvar_Multiple))
		len += formatex(menu[len], charsmax(menu) - len, "\d2. %L [%L]^n", id, "MENU_MULTI", id, "MENU_OFF")
	else if (g_iShowMultipleHud[id])
		len += formatex(menu[len], charsmax(menu) - len, "\r2.\w %L\y [%L]^n", id, "MENU_MULTI", id, "MENU_ON")
	else
		len += formatex(menu[len], charsmax(menu) - len, "\r2.\w %L\y [\r%L\y]^n", id, "MENU_MULTI", id, "MENU_OFF")
	
	// 3. Hud HE Damage
	if (!get_pcvar_num(cvar_BlastDamage))
		len += formatex(menu[len], charsmax(menu) - len, "\d3. %L [%L]^n", id, "MENU_GRENADE", id, "MENU_OFF")
	else if (g_iShowBlastHud[id])
		len += formatex(menu[len], charsmax(menu) - len, "\r3.\w %L\y [%L]^n", id, "MENU_GRENADE", id, "MENU_ON")
	else
		len += formatex(menu[len], charsmax(menu) - len, "\r3.\w %L\y [\r%L\y]^n", id, "MENU_GRENADE", id, "MENU_OFF")
	
	// 4. Hud Take Damage
	if (!get_pcvar_num(cvar_TakeDamage))
		len += formatex(menu[len], charsmax(menu) - len, "\d4. %L [%L]^n^n", id, "MENU_TAKE", id, "MENU_OFF")
	else if (g_iShowTakeHud[id])
		len += formatex(menu[len], charsmax(menu) - len, "\r4.\w %L\y [%L]^n^n", id, "MENU_TAKE", id, "MENU_ON")
	else
		len += formatex(menu[len], charsmax(menu) - len, "\r4.\w %L\y [\r%L\y]^n^n", id, "MENU_TAKE", id, "MENU_OFF")
	
	// 5. Configuration Menu
	len += formatex(menu[len], charsmax(menu) - len, "\r5.\w %L^n^n", id, "MENU_CONFIG_TITLE")
	
	// 6. Top Damage: Personal
	if (!get_pcvar_num(cvar_SaveStatsPersonal))
		len += formatex(menu[len], charsmax(menu) - len, "\d6. %L^n", id, "MENU_TOP_PER")
	else
		len += formatex(menu[len], charsmax(menu) - len, "\r6.\w %L^n", id, "MENU_TOP_PER")
	
	// 7. Top Damage: All
	if (!get_pcvar_num(cvar_SaveStats))
		len += formatex(menu[len], charsmax(menu) - len, "\d7. %L^n^n", id, "MENU_TOP_ALL")
	else
		len += formatex(menu[len], charsmax(menu) - len, "\r7.\w %L^n^n", id, "MENU_TOP_ALL")
	
	// 9. Admin Menu
	if (user_has_flag(id, ACCESS_RESET))
		len += formatex(menu[len], charsmax(menu) - len, "\r9.\w %L", id, "MENU_ADMIN_TITLE")
	else
		len += formatex(menu[len], charsmax(menu) - len, "\d9. %L", id, "MENU_ADMIN_TITLE")
	
	// 0. Exit
	len += formatex(menu[len], charsmax(menu) - len, "^n^n\r0.\w %L", id, "MENU_EXIT")
	
	show_menu(id, KEYSMENU, menu, -1, "Main Menu")
}

// Configuration Menu
show_menu_config(id)
{
	static menu[512], len
	len = 0
	
	// Title
	len += formatex(menu[len], charsmax(menu) - len, "\y%L^n^n", id, "MENU_CONFIG_TITLE")
	
	// 1. Single
	len += formatex(menu[len], charsmax(menu) - len, "\r1.\w %L %L^n", id, "MENU_SINGLE_TITLE", id, "MENU_MENU")
	
	// 2. Multiple
	len += formatex(menu[len], charsmax(menu) - len, "\r2.\w %L %L^n", id, "MENU_MULTI_TITLE", id, "MENU_MENU")
	
	// 3. Grenade
	len += formatex(menu[len], charsmax(menu) - len, "\r3.\w %L %L^n", id, "MENU_GRENADE_TITLE", id, "MENU_MENU")
	
	// 4. Take
	len += formatex(menu[len], charsmax(menu) - len, "\r4.\w %L %L^n^n", id, "MENU_TAKE_TITLE", id, "MENU_MENU")
	
	// 5. Save
	len += formatex(menu[len], charsmax(menu) - len, "\r5.\w %L", id, "MENU_SAVE_TITLE")
	
	// 0. Back / Exit
	len += formatex(menu[len], charsmax(menu) - len, "^n^n\r0.\w %L / %L", id, "MENU_BACK", id, "MENU_EXIT")
	
	show_menu(id, KEYSMENU, menu, -1, "Config Menu")
}

// Dynamic (single, multi, grenade & take)
show_menu_dynamic_main(id)
{
	static menu[512], len
	len = 0
	
	// Dynamic ?
	switch (g_iDynamicMenu[id])
	{
		case 0: // Single
		{
			// Title
			len += formatex(menu[len], charsmax(menu) - len, "\y%L %L^n^n", id, "MENU_SINGLE_TITLE", id, "MENU_MENU")
			
			// 1. Color
			len += formatex(menu[len], charsmax(menu) - len, "\r1.\w %L^n", id, "MENU_DYNAMIC_COLOR")
			
			// 2. Style
			if (g_iSingleColor[id][COLOR_STYLE])
				len += formatex(menu[len], charsmax(menu) - len, "\r2.\w %L\y [%L]^n", id, "MENU_DYNAMIC_STYLE", id, "MENU_ON")
			else
				len += formatex(menu[len], charsmax(menu) - len, "\r2.\w %L\y [%L]^n", id, "MENU_DYNAMIC_STYLE", id, "MENU_OFF")
			
			// 3. Position
			len += formatex(menu[len], charsmax(menu) - len, "\r3.\w %L^n", id, "MENU_DYNAMIC_POSI")
			
			// 4. Holdtime
			len += formatex(menu[len], charsmax(menu) - len, "\r4.\w %L\y [%.1f %L]^n^n", id, "MENU_DYNAMIC_TIME", g_flSingleTime[id], id, "MENU_SECONDS")
		}
		case 1: // Multi
		{
			// Title
			len += formatex(menu[len], charsmax(menu) - len, "\y%L %L^n^n", id, "MENU_MULTI_TITLE", id, "MENU_MENU")
			
			// 1. Color
			len += formatex(menu[len], charsmax(menu) - len, "\r1.\w %L^n", id, "MENU_DYNAMIC_COLOR")
			
			// 2. Style
			if (g_iMultipleColor[id][COLOR_STYLE])
				len += formatex(menu[len], charsmax(menu) - len, "\r2.\w %L\y [%L]^n", id, "MENU_DYNAMIC_STYLE", id, "MENU_ON")
			else
				len += formatex(menu[len], charsmax(menu) - len, "\r2.\w %L\y [%L]^n", id, "MENU_DYNAMIC_STYLE", id, "MENU_OFF")
			
			// 3. Position
			len += formatex(menu[len], charsmax(menu) - len, "\r3.\w %L^n", id, "MENU_DYNAMIC_POSI")
			
			// 4. Holdtime
			len += formatex(menu[len], charsmax(menu) - len, "\r4.\w %L\y [%.1f %L]^n^n", id, "MENU_DYNAMIC_TIME", g_flMultipleTime[id], id, "MENU_SECONDS")
		}
		case 2: // Grenade
		{
			// Title
			len += formatex(menu[len], charsmax(menu) - len, "\y%L %L^n^n", id, "MENU_GRENADE_TITLE", id, "MENU_MENU")
			
			// 1. Color
			len += formatex(menu[len], charsmax(menu) - len, "\r1.\w %L^n", id, "MENU_DYNAMIC_COLOR")
			
			// 2. Style
			if (g_iBlastColor[id][COLOR_STYLE])
				len += formatex(menu[len], charsmax(menu) - len, "\r2.\w %L\y [%L]^n", id, "MENU_DYNAMIC_STYLE", id, "MENU_ON")
			else
				len += formatex(menu[len], charsmax(menu) - len, "\r2.\w %L\y [%L]^n", id, "MENU_DYNAMIC_STYLE", id, "MENU_OFF")
			
			// 3. Position
			len += formatex(menu[len], charsmax(menu) - len, "\r3.\w %L^n", id, "MENU_DYNAMIC_POSI")
			
			// 4. Holdtime
			len += formatex(menu[len], charsmax(menu) - len, "\r4.\w %L\y [%.1f %L]^n^n", id, "MENU_DYNAMIC_TIME", g_flBlastTime[id], id, "MENU_SECONDS")
		}
		case 3: // Take
		{
			// Title
			len += formatex(menu[len], charsmax(menu) - len, "\y%L %L^n^n", id, "MENU_TAKE_TITLE", id, "MENU_MENU")
			
			// 1. Color
			len += formatex(menu[len], charsmax(menu) - len, "\r1.\w %L^n", id, "MENU_DYNAMIC_COLOR")
			
			// 2. Style
			if (g_iTakeColor[id][COLOR_STYLE])
				len += formatex(menu[len], charsmax(menu) - len, "\r2.\w %L\y [%L]^n", id, "MENU_DYNAMIC_STYLE", id, "MENU_ON")
			else
				len += formatex(menu[len], charsmax(menu) - len, "\r2.\w %L\y [%L]^n", id, "MENU_DYNAMIC_STYLE", id, "MENU_OFF")
			
			// 3. Position
			len += formatex(menu[len], charsmax(menu) - len, "\r3.\w %L^n", id, "MENU_DYNAMIC_POSI")
			
			// 4. Holdtime
			len += formatex(menu[len], charsmax(menu) - len, "\r4.\w %L\y [%.1f %L]^n^n", id, "MENU_DYNAMIC_TIME", g_flTakeTime[id], id, "MENU_SECONDS")
		}
	}
	
	// 5. Test
	len += formatex(menu[len], charsmax(menu) - len, "\r5.\w %L", id, "MENU_TEST_TITLE")
	
	// 0. Back / Exit
	len += formatex(menu[len], charsmax(menu) - len, "^n^n\r0.\w %L / %L", id, "MENU_BACK", id, "MENU_EXIT")
	
	show_menu(id, KEYSMENU, menu, -1, "Dynamic Menu Main")
}

// Dynamic Color (single, multi, grenade & take)
show_menu_dynamic_color(id)
{
	static menu[512], len
	len = 0
	
	// Dynamic ?
	switch (g_iDynamicMenu[id])
	{
		case 0: // Single
		{
			// Title
			len += formatex(menu[len], charsmax(menu) - len, "\y%L %L^n^n", id, "MENU_SINGLE_TITLE", id, "MENU_DYNAMIC_COLOR")
		}
		case 1: // Multi
		{
			// Title
			len += formatex(menu[len], charsmax(menu) - len, "\y%L %L^n^n", id, "MENU_MULTI_TITLE", id, "MENU_DYNAMIC_COLOR")
		}
		case 2: // Grenade
		{
			// Title
			len += formatex(menu[len], charsmax(menu) - len, "\y%L %L^n^n", id, "MENU_GRENADE_TITLE", id, "MENU_DYNAMIC_COLOR")
		}
		case 3: // Take
		{
			// Title
			len += formatex(menu[len], charsmax(menu) - len, "\y%L %L^n^n", id, "MENU_TAKE_TITLE", id, "MENU_DYNAMIC_COLOR")
		}
	}
	
	// 1. Red Color
	len += formatex(menu[len], charsmax(menu) - len, "\r1.\w %L^n", id, "MENU_COLOR_RED")
	
	// 2. Green Color
	len += formatex(menu[len], charsmax(menu) - len, "\r2.\w %L^n", id, "MENU_COLOR_GREEN")
	
	// 3. Blue Color
	len += formatex(menu[len], charsmax(menu) - len, "\r3.\w %L^n", id, "MENU_COLOR_BLUE")
	
	// 4. Yellow Color
	len += formatex(menu[len], charsmax(menu) - len, "\r4.\w %L^n", id, "MENU_COLOR_YELLOW")
	
	// 5. Cyan Color
	len += formatex(menu[len], charsmax(menu) - len, "\r5.\w %L^n", id, "MENU_COLOR_CYAN")
	
	// 6. White Color
	len += formatex(menu[len], charsmax(menu) - len, "\r6.\w %L", id, "MENU_COLOR_WHITE")
	
	// 0. Back / Exit
	len += formatex(menu[len], charsmax(menu) - len, "^n^n\r0.\w %L / %L", id, "MENU_BACK", id, "MENU_EXIT")
	
	show_menu(id, KEYSMENU, menu, -1, "Dynamic Menu Color")
}

// Dynamic Positions (single, multi, grenade & take)
show_menu_dynamic_posi(id)
{
	static menu[512], len
	len = 0
	
	// Dynamic ?
	switch (g_iDynamicMenu[id])
	{
		case 0: // Single
		{
			// Title
			len += formatex(menu[len], charsmax(menu) - len, "\y%L %L^n^n", id, "MENU_SINGLE_TITLE", id, "MENU_DYNAMIC_POSI")
			
			// Info
			len += formatex(menu[len], charsmax(menu) - len, "\y%L \w[X: %.2f - Y: %.2f]^n^n", id, "MENU_DYNAMIC_POSI", g_flSinglePosition_X[id], g_flSinglePosition_Y[id])
		}
		case 1: // Multi
		{
			// Title
			len += formatex(menu[len], charsmax(menu) - len, "\y%L %L^n^n", id, "MENU_MULTI_TITLE", id, "MENU_DYNAMIC_POSI")
			
			// Info
			len += formatex(menu[len], charsmax(menu) - len, "\y%L \w[X: %.2f - Y: %.2f]^n^n", id, "MENU_DYNAMIC_POSI", g_flMultiplePosition_X[id], g_flMultiplePosition_Y[id])
		}
		case 2: // Grenade
		{
			// Title
			len += formatex(menu[len], charsmax(menu) - len, "\y%L %L^n^n", id, "MENU_GRENADE_TITLE", id, "MENU_DYNAMIC_POSI")
			
			// Info
			len += formatex(menu[len], charsmax(menu) - len, "\y%L \w[X: %.2f - Y: %.2f]^n^n", id, "MENU_DYNAMIC_POSI", g_flBlastPosition_X[id], g_flBlastPosition_Y[id])
		}
		case 3: // Take
		{
			// Title
			len += formatex(menu[len], charsmax(menu) - len, "\y%L %L^n^n", id, "MENU_TAKE_TITLE", id, "MENU_DYNAMIC_POSI")
			
			// Info
			len += formatex(menu[len], charsmax(menu) - len, "\y%L \w[X: %.2f - Y: %.2f]^n^n", id, "MENU_DYNAMIC_POSI", g_flTakePosition_X[id], g_flTakePosition_Y[id])
		}
	}
	
	// 1. Up
	len += formatex(menu[len], charsmax(menu) - len, "\r1.\w %L^n", id, "MENU_POSI_UP")
	
	// 2. Down
	len += formatex(menu[len], charsmax(menu) - len, "\r2.\w %L^n", id, "MENU_POSI_DOWN")
	
	// 3. Right
	len += formatex(menu[len], charsmax(menu) - len, "\r3.\w %L^n", id, "MENU_POSI_RIGHT")
	
	// 4. Left
	len += formatex(menu[len], charsmax(menu) - len, "\r4.\w %L^n^n", id, "MENU_POSI_LEFT")
	
	// 5. Type
	len += formatex(menu[len], charsmax(menu) - len, "\r5.\w %L: \y[\w%s\y]", id, "MENU_POSI_TYPE", g_iMenuType[id] ? "0.1" : "0.01")
	
	// 0. Back / Exit
	len += formatex(menu[len], charsmax(menu) - len, "^n^n\r0.\w %L / %L", id, "MENU_BACK", id, "MENU_EXIT")
	
	show_menu(id, KEYSMENU, menu, -1, "Dynamic Menu Posi")
}

// Dynamic Holdtime (single, multi, grenade & take)
show_menu_dynamic_time(id)
{
	static menu[512], len
	len = 0
	
	// Dynamic ?
	switch (g_iDynamicMenu[id])
	{
		case 0: // Single
		{
			// Title
			len += formatex(menu[len], charsmax(menu) - len, "\y%L %L^n^n", id, "MENU_SINGLE_TITLE", id, "MENU_DYNAMIC_TIME")
			
			// Info
			len += formatex(menu[len], charsmax(menu) - len, "\y%L \w[%.1f %L]^n^n", id, "MENU_DYNAMIC_TIME", g_flSingleTime[id], id, "MENU_SECONDS")
		}
		case 1: // Multi
		{
			// Title
			len += formatex(menu[len], charsmax(menu) - len, "\y%L %L^n^n", id, "MENU_MULTI_TITLE", id, "MENU_DYNAMIC_TIME")
			
			// Info
			len += formatex(menu[len], charsmax(menu) - len, "\y%L \w[%.1f %L]^n^n", id, "MENU_DYNAMIC_TIME", g_flMultipleTime[id], id, "MENU_SECONDS")
		}
		case 2: // Grenade
		{
			// Title
			len += formatex(menu[len], charsmax(menu) - len, "\y%L %L^n^n", id, "MENU_GRENADE_TITLE", id, "MENU_DYNAMIC_TIME")
			
			// Info
			len += formatex(menu[len], charsmax(menu) - len, "\y%L \w[%.1f %L]^n^n", id, "MENU_DYNAMIC_TIME", g_flBlastTime[id], id, "MENU_SECONDS")
		}
		case 3: // Take
		{
			// Title
			len += formatex(menu[len], charsmax(menu) - len, "\y%L %L^n^n", id, "MENU_TAKE_TITLE", id, "MENU_DYNAMIC_TIME")
			
			// Info
			len += formatex(menu[len], charsmax(menu) - len, "\y%L \w[%.1f %L]^n^n", id, "MENU_DYNAMIC_TIME", g_flTakeTime[id], id, "MENU_SECONDS")
		}
	}
	
	// 1. Increase
	len += formatex(menu[len], charsmax(menu) - len, "\r1.\w %L^n", id, "MENU_TIME_UP")
	
	// 2. Decrease
	len += formatex(menu[len], charsmax(menu) - len, "\r2.\w %L^n^n", id, "MENU_TIME_DOWN")
	
	// 3. Type
	len += formatex(menu[len], charsmax(menu) - len, "\r3.\w %L: \y[\w%s\y]^n^n", id, "MENU_POSI_TYPE", g_iMenuType[id] ? "1.0" : "0.1")
	
	// 4. Test
	len += formatex(menu[len], charsmax(menu) - len, "\r4.\w %L", id, "MENU_TEST_TITLE")
	
	// 0. Back / Exit
	len += formatex(menu[len], charsmax(menu) - len, "^n^n\r0.\w %L / %L", id, "MENU_BACK", id, "MENU_EXIT")
	
	show_menu(id, KEYSMENU, menu, -1, "Dynamic Menu Time")
}

// Player List Menu
show_menu_player_list(id)
{
	static menuid, menu[128], player, buffer[2]
	
	// Title
	formatex(menu, charsmax(menu), "\y%L\r", id, "MENU_TOP_PER")
	
	// Create Menu
	menuid = menu_create(menu, "menu_player_list")
	
	// Player List
	for (player = 1; player <= g_iMaxPlayers; player++)
	{
		// Skip if not connected
		if (!g_bIsConnected[player]) continue
		
		// Format text depending on the action to take
		formatex(menu, charsmax(menu), "%s", g_szPlayerName[player])
		
		// Add player
		buffer[0] = player
		buffer[1] = 0
		menu_additem(menuid, menu, buffer)
	}
	
	// Back - Next - Exit
	formatex(menu, charsmax(menu), "%L", id, "MENU_BACK")
	menu_setprop(menuid, MPROP_BACKNAME, menu)
	formatex(menu, charsmax(menu), "%L", id, "MENU_NEXT")
	menu_setprop(menuid, MPROP_NEXTNAME, menu)
	formatex(menu, charsmax(menu), "%L", id, "MENU_EXIT")
	menu_setprop(menuid, MPROP_EXITNAME, menu)
	
	menu_display(id, menuid)
}

// Admin Menu
show_menu_admin(id)
{
	static menuid, menu[128], weapon, buffer[2]
	
	// Title
	formatex(menu, charsmax(menu), "\y%L\r", id, "MENU_ADMIN_TITLE")
	
	// Create Menu
	menuid = menu_create(menu, "menu_weapon_list")
	
	// Weapon List
	for (weapon = 0; weapon <= DODW_PIAT; weapon++)
	{
		// Skip if ignore weapon
		if (is_ignore_weapon_id(weapon)) continue
		
		// Format text depending on the action to take
		if (weapon == 0)
			formatex(menu, charsmax(menu), "%L", id, "MENU_RESET_ALL")
		else
			formatex(menu, charsmax(menu), "%s", WPN_NAMES[weapon])
		
		// Add player
		buffer[0] = weapon
		buffer[1] = 0
		menu_additem(menuid, menu, buffer)
	}
	
	// Back - Next - Exit
	formatex(menu, charsmax(menu), "%L", id, "MENU_BACK")
	menu_setprop(menuid, MPROP_BACKNAME, menu)
	formatex(menu, charsmax(menu), "%L", id, "MENU_NEXT")
	menu_setprop(menuid, MPROP_NEXTNAME, menu)
	formatex(menu, charsmax(menu), "%L", id, "MENU_EXIT")
	menu_setprop(menuid, MPROP_EXITNAME, menu)
	
	menu_display(id, menuid)
}

// Show Top Damage (all)
public show_top_all(id)
{
	// Not Connected (bugfix)
	if (!g_bIsConnected[id] || g_bMotdPrepair) return
	
	// Prepair motd starts
	g_bMotdPrepair = true
	
	static buffer[2048], len
	len = format(buffer, charsmax(buffer), "<body bgcolor=#000000><font color=#FFB000><pre>")
	len += format(buffer[len], charsmax(buffer) - len, "%10s %-22.22s %6s %4s %5s^n", "Weapon", "Nick", "Damage", "Hits", "Yours")
	
	if (get_pcvar_num(cvar_MotdSort))
	{
		// most damage sorting methode
		for (new j = DODW_AMERKNIFE; j <= DODW_PIAT; j++)
			g_iRecord[j] = g_iCachedDamage[j]
		
		new record
		for (new i = DODW_AMERKNIFE; i <= MOTD_MAX_WEAPONS; i++)
		{
			record = get_record()
			
			if (record)
				len += format(buffer[len], charsmax(buffer) - len, "%10s %-22.22s %6i %4i %5s^n",
				WPN_SHORTNAMES[record], g_szCachedNames[record], g_iCachedDamage[record], g_iCachedHits[record],
				(equali(g_szPlayerName[id], g_szCachedNames[record])) ? " *" : "")
		}
	}
	else
	{
		for (new i = DODW_AMERKNIFE; i <= DODW_PIAT; i++)
		{
			if (is_ignore_weapon_id(i)) continue
			
			len += format(buffer[len], charsmax(buffer) - len, "%10s %-22.22s %6i %4i %5s^n",
			WPN_SHORTNAMES[i], g_szCachedNames[i], g_iCachedDamage[i], g_iCachedHits[i],
			(equali(g_szPlayerName[id], g_szCachedNames[i])) ? " *" : "")
		}
	}
	
	// Show motd
	new motd[64]
	formatex(motd[0], charsmax(motd), "%L", id, "MENU_TOP_ALL")
	show_motd(id, buffer, motd)
	
	// Prepair motd ends (bugfix)
	g_bMotdPrepair = false
}

// Show Top Damage (personal)
public show_top_personal(id, other)
{
	// Not Connected (bugfix)
	if (!g_bIsConnected[id] || !g_bIsConnected[other] || g_bMotdPrepair) return
	
	// Prepair motd starts
	g_bMotdPrepair = true
	
	static buffer[2048], len
	len = format(buffer, charsmax(buffer), "<body bgcolor=#000000><font color=#FFB000><pre>")
	len += format(buffer[len], charsmax(buffer) - len, "%10s %6s %4s %5s^n", "Weapon", "Damage", "Hits", "Top")
	
	if (get_pcvar_num(cvar_MotdSort))
	{
		// most damage sorting methode
		for (new j = DODW_AMERKNIFE; j <= DODW_PIAT; j++)
			g_iRecord[j] = g_iPersonalDamage[other][j]
		
		new record
		for (new i = DODW_AMERKNIFE; i <= MOTD_MAX_WEAPONS; i++)
		{
			record = get_record()
			
			if (record)
				len += format(buffer[len], charsmax(buffer) - len, "%10s %6i %4i %5s^n",
				WPN_SHORTNAMES[record], g_iPersonalDamage[other][record], g_iPersonalHits[other][record],
				(g_iPersonalDamage[other][record] == g_iCachedDamage[record]) ? " *" : "")
		}
	}
	else
	{
		for (new i = DODW_AMERKNIFE; i <= DODW_PIAT; i++)
		{
			if (is_ignore_weapon_id(i)) continue
			
			len += format(buffer[len], charsmax(buffer) - len, "%10s %6i %4i %5s^n",
				WPN_SHORTNAMES[i], g_iPersonalDamage[other][i], g_iPersonalHits[other][i],
				(g_iPersonalDamage[other][i] == g_iCachedDamage[i]) ? " *" : "")
		}
	}
	
	// Show motd
	new motd[96]
	formatex(motd[0], charsmax(motd), "%L (%s)", id, "MENU_TOP_PER", g_szPlayerName[other])
	show_motd(id, buffer, motd)
	
	// Prepair motd ends (bugfix)
	g_bMotdPrepair = false
}

/*================================================================================
 [Menu Handlers]
=================================================================================*/

// Main Menu
public menu_main(id, key)
{
	switch (key)
	{
		case 0: // Hud Single Damage
		{
			if (get_pcvar_num(cvar_Single))
				g_iShowSingleHud[id] = !(g_iShowSingleHud[id])
			
			show_menu_main(id)
		}
		case 1: // Hud Multi Damage
		{
			if (get_pcvar_num(cvar_Multiple))
				g_iShowMultipleHud[id] = !(g_iShowMultipleHud[id])
			
			show_menu_main(id)
		}
		case 2: // Hud Grenade Damage
		{
			if (get_pcvar_num(cvar_BlastDamage))
				g_iShowBlastHud[id] = !(g_iShowBlastHud[id])
			
			show_menu_main(id)
		}
		case 3: // Hud Take Damage
		{
			if (get_pcvar_num(cvar_TakeDamage))
				g_iShowTakeHud[id] = !(g_iShowTakeHud[id])
			
			show_menu_main(id)
		}
		case 4: // Configuration Menu
		{
			g_iMenuType[id] = 0
			show_menu_config(id)
		}
		case 5: // Top Damage: Personal
		{
			if (get_pcvar_num(cvar_SaveStatsPersonal))
				show_menu_player_list(id)
			else
				show_menu_main(id)
		}
		case 6: // Top Damage: All
		{
			if (get_pcvar_num(cvar_SaveStats))
				show_top_all(id)
			
			show_menu_main(id)
		}
		case 7: // nothing
		{
			show_menu_main(id)
		}
		case 8: // Admin Menu
		{
			// Check if player has the required access
			if (user_has_flag(id, ACCESS_RESET))
				show_menu_admin(id)
			else
				client_print(id, print_chat, "[BD] %L", id, "BD_NOT_ACCESS")
		}
	}
	return PLUGIN_HANDLED
}

// Config Menu
public menu_config(id, key)
{
	g_iDynamicMenu[id] = key
	
	switch (key)
	{
		case 0,1,2,3: // Single, Multi, Grenade, Take
		{
			test_hud_vars(id)
			show_menu_dynamic_main(id)
		}
		case 4: // Save
		{
			save_hud_vars(id)
			show_menu_config(id)
			client_print(id, print_chat, "[BD] %L", id, "MENU_SAVED")
		}
		case 9: // Back / Exit
		{
			show_menu_main(id)
		}
		default: show_menu_config(id)
	}
	return PLUGIN_HANDLED
}

// Dynamic Menu Main
public menu_dynamic_main(id, key)
{
	switch (key)
	{
		case 0: // Color
		{
			test_hud_vars(id)
			show_menu_dynamic_color(id)
		}
		case 1: // Style
		{
			switch (g_iDynamicMenu[id])
			{
				case 0: g_iSingleColor[id][COLOR_STYLE] = !(g_iSingleColor[id][COLOR_STYLE]) // Single
				case 1: g_iMultipleColor[id][COLOR_STYLE] = !(g_iMultipleColor[id][COLOR_STYLE]) // Multi
				case 2: g_iBlastColor[id][COLOR_STYLE] = !(g_iBlastColor[id][COLOR_STYLE]) // Grenade
				case 3: g_iTakeColor[id][COLOR_STYLE] = !(g_iTakeColor[id][COLOR_STYLE]) // Take
			}
			test_hud_vars(id)
			show_menu_dynamic_main(id)
		}
		case 2: // Position
		{
			test_hud_vars(id)
			show_menu_dynamic_posi(id)
		}
		case 3: // Holdtime
		{
			test_hud_vars(id)
			show_menu_dynamic_time(id)
		}
		case 4: // Test
		{
			test_hud_vars(id)
			show_menu_dynamic_main(id)
		}
		case 9: // Back / Exit
		{
			show_menu_config(id)
		}
		default: show_menu_dynamic_main(id)
	}
	return PLUGIN_HANDLED
}

// Dynamic Menu Color
public menu_dynamic_color(id, key)
{
	switch (key)
	{
		case 0: // Red
		{
			switch (g_iDynamicMenu[id])
			{
				case 0: // Single
				{
					g_iSingleColor[id][COLOR_RED] = 200
					g_iSingleColor[id][COLOR_GREEN] = g_iSingleColor[id][COLOR_BLUE] = 0
				}
				case 1: // Multi
				{
					g_iMultipleColor[id][COLOR_RED] = 200
					g_iMultipleColor[id][COLOR_GREEN] = g_iMultipleColor[id][COLOR_BLUE] = 0
				}
				case 2: // Grenade
				{
					g_iBlastColor[id][COLOR_RED] = 200
					g_iBlastColor[id][COLOR_GREEN] = g_iBlastColor[id][COLOR_BLUE] = 0
				}
				case 3: // Take
				{
					g_iTakeColor[id][COLOR_RED] = 200
					g_iTakeColor[id][COLOR_GREEN] = g_iTakeColor[id][COLOR_BLUE] = 0
				}
			}
			test_hud_vars(id)
			show_menu_dynamic_color(id)
		}
		case 1: // Green
		{
			switch (g_iDynamicMenu[id])
			{
				case 0: // Single
				{
					g_iSingleColor[id][COLOR_RED] = g_iSingleColor[id][COLOR_BLUE] = 0
					g_iSingleColor[id][COLOR_GREEN] = 200
				}
				case 1: // Multi
				{
					g_iMultipleColor[id][COLOR_RED] = g_iMultipleColor[id][COLOR_BLUE] = 0
					g_iMultipleColor[id][COLOR_GREEN] = 200
				}
				case 2: // Grenade
				{
					g_iBlastColor[id][COLOR_RED] = g_iBlastColor[id][COLOR_BLUE] = 0
					g_iBlastColor[id][COLOR_GREEN] = 200
				}
				case 3: // Take
				{
					g_iTakeColor[id][COLOR_RED] = g_iTakeColor[id][COLOR_BLUE] = 0
					g_iTakeColor[id][COLOR_GREEN] = 200
				}
			}
			test_hud_vars(id)
			show_menu_dynamic_color(id)
		}
		case 2: // Blue
		{
			switch (g_iDynamicMenu[id])
			{
				case 0: // Single
				{
					g_iSingleColor[id][COLOR_RED] = g_iSingleColor[id][COLOR_GREEN] = 0
					g_iSingleColor[id][COLOR_BLUE] = 200
				}
				case 1: // Multi
				{
					g_iMultipleColor[id][COLOR_RED] = g_iMultipleColor[id][COLOR_GREEN] = 0
					g_iMultipleColor[id][COLOR_BLUE] = 200
				}
				case 2: // Grenade
				{
					g_iBlastColor[id][COLOR_RED] = g_iBlastColor[id][COLOR_GREEN] = 0
					g_iBlastColor[id][COLOR_BLUE] = 200
				}
				case 3: // Take
				{
					g_iTakeColor[id][COLOR_RED] = g_iTakeColor[id][COLOR_GREEN] = 0
					g_iTakeColor[id][COLOR_BLUE] = 200
				}
			}
			test_hud_vars(id)
			show_menu_dynamic_color(id)
		}
		case 3: // Yellow
		{
			switch (g_iDynamicMenu[id])
			{
				case 0: // Single
				{
					g_iSingleColor[id][COLOR_RED] = g_iSingleColor[id][COLOR_GREEN] = 200
					g_iSingleColor[id][COLOR_BLUE] = 0
				}
				case 1: // Multi
				{
					g_iMultipleColor[id][COLOR_RED] = g_iMultipleColor[id][COLOR_GREEN] = 200
					g_iMultipleColor[id][COLOR_BLUE] = 0
				}
				case 2: // Grenade
				{
					g_iBlastColor[id][COLOR_RED] = g_iBlastColor[id][COLOR_GREEN] = 200
					g_iBlastColor[id][COLOR_BLUE] = 0
				}
				case 3: // Take
				{
					g_iTakeColor[id][COLOR_RED] = g_iTakeColor[id][COLOR_GREEN] = 200
					g_iTakeColor[id][COLOR_BLUE] = 0
				}
			}
			test_hud_vars(id)
			show_menu_dynamic_color(id)
		}
		case 4: // Cyan
		{
			switch (g_iDynamicMenu[id])
			{
				case 0: // Single
				{
					g_iSingleColor[id][COLOR_RED] = 0
					g_iSingleColor[id][COLOR_GREEN] = g_iSingleColor[id][COLOR_BLUE] = 200
				}
				case 1: // Multi
				{
					g_iMultipleColor[id][COLOR_RED] = 0
					g_iMultipleColor[id][COLOR_GREEN] = g_iMultipleColor[id][COLOR_BLUE] = 200
				}
				case 2: // Grenade
				{
					g_iBlastColor[id][COLOR_RED] = 0
					g_iBlastColor[id][COLOR_GREEN] = g_iBlastColor[id][COLOR_BLUE] = 200
				}
				case 3: // Take
				{
					g_iTakeColor[id][COLOR_RED] = 0
					g_iTakeColor[id][COLOR_GREEN] = g_iTakeColor[id][COLOR_BLUE] = 200
				}
			}
			test_hud_vars(id)
			show_menu_dynamic_color(id)
		}
		case 5: // White
		{
			switch (g_iDynamicMenu[id])
			{
				case 0: g_iSingleColor[id][COLOR_RED] = g_iSingleColor[id][COLOR_GREEN] = g_iSingleColor[id][COLOR_BLUE] = 200 // Single
				case 1: g_iMultipleColor[id][COLOR_RED] = g_iMultipleColor[id][COLOR_GREEN] = g_iMultipleColor[id][COLOR_BLUE] = 200 // Multi
				case 2: g_iBlastColor[id][COLOR_RED] = g_iBlastColor[id][COLOR_GREEN] = g_iBlastColor[id][COLOR_BLUE] = 200 // Grenade
				case 3: g_iTakeColor[id][COLOR_RED] = g_iTakeColor[id][COLOR_GREEN] = g_iTakeColor[id][COLOR_BLUE] = 200 // Take
			}
			test_hud_vars(id)
			show_menu_dynamic_color(id)
		}
		case 9: // Back / Exit
		{
			show_menu_dynamic_main(id)
		}
		default: show_menu_dynamic_color(id)
	}
	return PLUGIN_HANDLED
}

// Dynamic Menu Positions
public menu_dynamic_posi(id, key)
{
	static Float:type
	if (g_iMenuType[id])
		type = POSI_TYPE_TRUE
	else
		type = POSI_TYPE_FALSE
	
	switch (key)
	{
		case 0: // Up
		{
			switch (g_iDynamicMenu[id])
			{
				case 0: // Single
				{
					if (g_flSinglePosition_Y[id] <= -1.0)
						g_flSinglePosition_Y[id] = 1.0 - type
					else if (g_flSinglePosition_Y[id] < 0.01)
						g_flSinglePosition_Y[id] = -1.0
					else if (g_flSinglePosition_Y[id] - type <= 0.0)
						g_flSinglePosition_Y[id] = 0.0
					else
						g_flSinglePosition_Y[id] -= type
				}
				case 1: // Multi
				{
					if (g_flMultiplePosition_Y[id] <= -1.0)
						g_flMultiplePosition_Y[id] = 1.0 - type
					else if (g_flMultiplePosition_Y[id] < 0.01)
						g_flMultiplePosition_Y[id] = -1.0
					else if (g_flMultiplePosition_Y[id] - type <= 0.0)
						g_flMultiplePosition_Y[id] = 0.0
					else
						g_flMultiplePosition_Y[id] -= type
				}
				case 2: // Grenade
				{
					if (g_flBlastPosition_Y[id] <= -1.0)
						g_flBlastPosition_Y[id] = 1.0 - type
					else if (g_flBlastPosition_Y[id] < 0.01)
						g_flBlastPosition_Y[id] = -1.0
					else if (g_flBlastPosition_Y[id] - type <= 0.0)
						g_flBlastPosition_Y[id] = 0.0
					else
						g_flBlastPosition_Y[id] -= type
				}
				case 3: // Take
				{
					if (g_flTakePosition_Y[id] <= -1.0)
						g_flTakePosition_Y[id] = 1.0 - type
					else if (g_flTakePosition_Y[id] < 0.01)
						g_flTakePosition_Y[id] = -1.0
					else if (g_flTakePosition_Y[id] - type <= 0.0)
						g_flTakePosition_Y[id] = 0.0
					else
						g_flTakePosition_Y[id] -= type
				}
			}
			test_hud_vars(id)
			show_menu_dynamic_posi(id)
		}
		case 1: // Down
		{
			switch (g_iDynamicMenu[id])
			{
				case 0: // Single
				{
					if (g_flSinglePosition_Y[id] > 0.99)
						g_flSinglePosition_Y[id] = -1.0
					else if (g_flSinglePosition_Y[id] <= -1.0)
						g_flSinglePosition_Y[id] = 0.0 + type
					else if (g_flSinglePosition_Y[id] + type >= 1.0)
						g_flSinglePosition_Y[id] = 1.0
					else
						g_flSinglePosition_Y[id] += type
				}
				case 1: // Multi
				{
					if (g_flMultiplePosition_Y[id] > 0.99)
						g_flMultiplePosition_Y[id] = -1.0
					else if (g_flMultiplePosition_Y[id] <= -1.0)
						g_flMultiplePosition_Y[id] = 0.0 + type
					else if (g_flMultiplePosition_Y[id] + type >= 1.0)
						g_flMultiplePosition_Y[id] = 1.0
					else
						g_flMultiplePosition_Y[id] += type
				}
				case 2: // Grenade
				{
					if (g_flBlastPosition_Y[id] > 0.99)
						g_flBlastPosition_Y[id] = -1.0
					else if (g_flBlastPosition_Y[id] <= -1.0)
						g_flBlastPosition_Y[id] = 0.0 + type
					else if (g_flBlastPosition_Y[id] + type >= 1.0)
						g_flBlastPosition_Y[id] = 1.0
					else
						g_flBlastPosition_Y[id] += type
				}
				case 3: // Take
				{
					if (g_flTakePosition_Y[id] > 0.99)
						g_flTakePosition_Y[id] = -1.0
					else if (g_flTakePosition_Y[id] <= -1.0)
						g_flTakePosition_Y[id] = 0.0 + type
					else if (g_flTakePosition_Y[id] + type >= 1.0)
						g_flTakePosition_Y[id] = 1.0
					else
						g_flTakePosition_Y[id] += type
				}
			}
			test_hud_vars(id)
			show_menu_dynamic_posi(id)
		}
		case 2: // Right
		{
			switch (g_iDynamicMenu[id])
			{
				case 0: // Single
				{
					if (g_flSinglePosition_X[id] > 0.99)
						g_flSinglePosition_X[id] = -1.0
					else if (g_flSinglePosition_X[id] <= -1.0)
						g_flSinglePosition_X[id] = 0.0 + type
					else if (g_flSinglePosition_X[id] + type >= 1.0)
						g_flSinglePosition_X[id] = 1.0
					else
						g_flSinglePosition_X[id] += type
				}
				case 1: // Multi
				{
					if (g_flMultiplePosition_X[id] > 0.99)
						g_flMultiplePosition_X[id] = -1.0
					else if (g_flMultiplePosition_X[id] <= -1.0)
						g_flMultiplePosition_X[id] = 0.0 + type
					else if (g_flMultiplePosition_X[id] + type >= 1.0)
						g_flMultiplePosition_X[id] = 1.0
					else
						g_flMultiplePosition_X[id] += type
				}
				case 2: // Grenade
				{
					if (g_flBlastPosition_X[id] > 0.99)
						g_flBlastPosition_X[id] = -1.0
					else if (g_flBlastPosition_X[id] <= -1.0)
						g_flBlastPosition_X[id] = 0.0 + type
					else if (g_flBlastPosition_X[id] + type >= 1.0)
						g_flBlastPosition_X[id] = 1.0
					else
						g_flBlastPosition_X[id] += type
				}
				case 3: // Take
				{
					if (g_flTakePosition_X[id] > 0.99)
						g_flTakePosition_X[id] = -1.0
					else if (g_flTakePosition_X[id] <= -1.0)
						g_flTakePosition_X[id] = 0.0 + type
					else if (g_flTakePosition_X[id] + type >= 1.0)
						g_flTakePosition_X[id] = 1.0
					else
						g_flTakePosition_X[id] += type
				}
			}
			test_hud_vars(id)
			show_menu_dynamic_posi(id)
		}
		case 3: // Left
		{
			switch (g_iDynamicMenu[id])
			{
				case 0: // Single
				{
					if (g_flSinglePosition_X[id] <= -1.0)
						g_flSinglePosition_X[id] = 1.0 - type
					else if (g_flSinglePosition_X[id] < 0.01)
						g_flSinglePosition_X[id] = -1.0
					else if (g_flSinglePosition_X[id] - type <= 0.0)
						g_flSinglePosition_X[id] = 0.0
					else
						g_flSinglePosition_X[id] -= type
				}
				case 1: // Multi
				{
					if (g_flMultiplePosition_X[id] <= -1.0)
						g_flMultiplePosition_X[id] = 1.0 - type
					else if (g_flMultiplePosition_X[id] < 0.01)
						g_flMultiplePosition_X[id] = -1.0
					else if (g_flMultiplePosition_X[id] - type <= 0.0)
						g_flMultiplePosition_X[id] = 0.0
					else
						g_flMultiplePosition_X[id] -= type
				}
				case 2: // Grenade
				{
					if (g_flBlastPosition_X[id] <= -1.0)
						g_flBlastPosition_X[id] = 1.0 - type
					else if (g_flBlastPosition_X[id] < 0.01)
						g_flBlastPosition_X[id] = -1.0
					else if (g_flBlastPosition_X[id] - type <= 0.0)
						g_flBlastPosition_X[id] = 0.0
					else
						g_flBlastPosition_X[id] -= type
				}
				case 3: // Take
				{
					if (g_flTakePosition_X[id] <= -1.0)
						g_flTakePosition_X[id] = 1.0 - type
					else if (g_flTakePosition_X[id] < 0.01)
						g_flTakePosition_X[id] = -1.0
					else if (g_flTakePosition_X[id] - type <= 0.0)
						g_flTakePosition_X[id] = 0.0
					else
						g_flTakePosition_X[id] -= type
				}
			}
			test_hud_vars(id)
			show_menu_dynamic_posi(id)
		}
		case 4: // Type
		{
			g_iMenuType[id] = !(g_iMenuType[id])
			show_menu_dynamic_posi(id)
		}
		case 9: // Back / Exit
		{
			show_menu_dynamic_main(id)
		}
		default: show_menu_dynamic_posi(id)
	}
	return PLUGIN_HANDLED
}

// Dynamic Menu Positions
public menu_dynamic_time(id, key)
{
	static Float:type
	if (g_iMenuType[id])
		type = TIME_TYPE_TRUE
	else
		type = TIME_TYPE_FALSE
	
	switch (key)
	{
		case 0: // Increase
		{
			switch (g_iDynamicMenu[id])
			{
				case 0: // Single
				{
					if (g_flSingleTime[id] + type >= 15.0)
						g_flSingleTime[id] = 15.0
					else
						g_flSingleTime[id] += type
				}
				case 1: // Multi
				{
					if (g_flMultipleTime[id] + type >= 15.0)
						g_flMultipleTime[id] = 15.0
					else
						g_flMultipleTime[id] += type
				}
				case 2: // Grenade
				{
					if (g_flBlastTime[id] + type >= 15.0)
						g_flBlastTime[id] = 15.0
					else
						g_flBlastTime[id] += type
				}
				case 3: // Take
				{
					if (g_flTakeTime[id] + type >= 15.0)
						g_flTakeTime[id] = 15.0
					else
						g_flTakeTime[id] += type
				}
			}
			show_menu_dynamic_time(id)
		}
		case 1: // Decrease
		{
			switch (g_iDynamicMenu[id])
			{
				case 0: // Single
				{
					if (g_flSingleTime[id] - type <= 0.1)
						g_flSingleTime[id] = 0.1
					else
						g_flSingleTime[id] -= type
				}
				case 1: // Multi
				{
					if (g_flMultipleTime[id] - type <= 0.1)
						g_flMultipleTime[id] = 0.1
					else
						g_flMultipleTime[id] -= type
				}
				case 2: // Grenade
				{
					if (g_flBlastTime[id] - type <= 0.1)
						g_flBlastTime[id] = 0.1
					else
						g_flBlastTime[id] -= type
				}
				case 3: // Take
				{
					if (g_flTakeTime[id] - type <= 0.1)
						g_flTakeTime[id] = 0.1
					else
						g_flTakeTime[id] -= type
				}
			}
			show_menu_dynamic_time(id)
		}
		case 2: // Type
		{
			g_iMenuType[id] = !(g_iMenuType[id])
			show_menu_dynamic_time(id)
		}
		case 3: // Test
		{
			test_hud_vars(id)
			show_menu_dynamic_time(id)
		}
		case 9: // Back / Exit
		{
			show_menu_dynamic_main(id)
		}
		default: show_menu_dynamic_time(id)
	}
	return PLUGIN_HANDLED
}

// Player List Menu
public menu_player_list(id, menuid, item)
{
	// Menu was closed
	if (item == MENU_EXIT)
	{
		menu_destroy(menuid)
		show_menu_main(id)
		return PLUGIN_HANDLED
	}
	
	// Retrieve player id
	static buffer[2], dummy, playerid
	menu_item_getinfo(menuid, item, dummy, buffer, charsmax(buffer), _, _, dummy)
	playerid = buffer[0]
	
	// Perform action on player
	
	// Make sure it's still connected
	if (g_bIsConnected[playerid])
		show_top_personal(id, playerid)
	
	menu_destroy(menuid)
	show_menu_player_list(id)
	return PLUGIN_HANDLED
}

public menu_weapon_list(id, menuid, item)
{
	// Menu was closed
	if (item == MENU_EXIT)
	{
		menu_destroy(menuid)
		show_menu_main(id)
		return PLUGIN_HANDLED
	}
	
	// Retrieve player id
	static buffer[2], dummy, weapon
	menu_item_getinfo(menuid, item, dummy, buffer, charsmax(buffer), _, _, dummy)
	weapon = buffer[0]
	
	// Perform action on weapon
	if (weapon == 0)
	{
		reset_top(0, 1)
		client_print(id, print_chat, "[BD] %L %L", id, "MENU_RESET_ALL", id, "MENU_RESET_RECORD")
	}
	else
	{
		reset_top(weapon)
		client_print(id, print_chat, "[BD] %s %L", WPN_NAMES[weapon], id, "MENU_RESET_RECORD")
	}
	
	menu_destroy(menuid)
	show_menu_admin(id)
	return PLUGIN_HANDLED
}

/*================================================================================
 [Other Functions and Tasks]
=================================================================================*/

public reset_atk2(taskid)
{
	// Not Connected
	if (!g_bIsConnected[ID_ATK2]) return
	
	// reset weapon atk2 var
	g_bAttack2Weapon[ID_ATK2] = false
}

public damage_deal(taskid)
{
	// Not Connected
	if (!g_bIsConnected[ID_DAMAGE]) return
	
	// Record trial finished!
	g_bWhileRecordTask[ID_DAMAGE] = false
	
	// non-steam player...
	if(!g_iAuthorized[ID_DAMAGE])
	{
		reset_record_vars(ID_DAMAGE)
		return
	}
	
	// Using weapon
	static weapon
	weapon = g_iWeaponUse[ID_DAMAGE]
	
	// Made a new Personal record
	if (g_iDamageDealt[ID_DAMAGE] > g_iPersonalDamage[ID_DAMAGE][weapon])
	{
		// Set players name, damage done and hits to cached records
		g_iPersonalDamage[ID_DAMAGE][weapon] = clamp(g_iDamageDealt[ID_DAMAGE], 1, 999999)
		g_iPersonalHits[ID_DAMAGE][weapon] = clamp(g_iHits[ID_DAMAGE], 1, 9999)
		g_iPersonalResets[ID_DAMAGE][weapon] = g_iCachedResets[weapon]
		
		// Display new Record in Chat
		if (get_pcvar_num(cvar_ChatPersonal))
			client_print(ID_DAMAGE, print_chat, "[BD] %L", ID_DAMAGE, "BD_PERSONAL_RECORD", g_iPersonalDamage[ID_DAMAGE][weapon], WPN_NAMES[weapon], g_iPersonalHits[ID_DAMAGE][weapon])
		
		// Save new Record
		if (get_pcvar_num(cvar_SaveStatsPersonal))
			save_personal_top(ID_DAMAGE)
	}
	
	// Made a new Record
	if (g_iDamageDealt[ID_DAMAGE] > g_iCachedDamage[weapon])
	{
		// Set players name, damage done and hits to cached records
		g_szCachedNames[weapon] = g_szPlayerName[ID_DAMAGE]
		g_szCachedSteamIDs[weapon] = g_szSteamID[ID_DAMAGE]
		g_iCachedDamage[weapon] = clamp(g_iDamageDealt[ID_DAMAGE], 1, 999999)
		g_iCachedHits[weapon] = clamp(g_iHits[ID_DAMAGE], 1, 9999)
		
		// Display new Record in Chat
		if (get_pcvar_num(cvar_ChatWeapon))
			client_print(0, print_chat, "[BD] %L", LANG_PLAYER, "BD_RECORD", g_szCachedNames[weapon], g_iCachedDamage[weapon], WPN_NAMES[weapon], g_iCachedHits[weapon])
		
		// Save new Record
		if (get_pcvar_num(cvar_SaveStats))
			save_top()
	}
	
	// Clear Player vars
	reset_record_vars(ID_DAMAGE)
}

public damage_deal_blast(param[2])
{
	// param[0] = weapon
	// param[1] = client
	new id = param[1]
	
	// Not Connected
	if(!g_bIsConnected[id]) return
	
	// Display HUD damage?
	show_blast_damage(id)
	
	// Enable Record?
	if (!g_iAuthorized[id])
	{
		reset_record_vars(id, 1)
		return
	}
	
	// Using weapon
	static weapon
	weapon = param[0]
	
	// Made a new Personal record
	if (g_iBlastDamageDealt[id] > g_iPersonalDamage[id][weapon])
	{
		// Set players name, damage done and hits to cached records
		g_iPersonalDamage[id][weapon] = clamp(g_iBlastDamageDealt[id], 1, 999999)
		g_iPersonalHits[id][weapon] = clamp(g_iBlastHits[id], 1, 9999)
		g_iPersonalResets[id][weapon] = g_iCachedResets[weapon]
		
		// Display new Record in Chat
		if (get_pcvar_num(cvar_ChatPersonal))
			client_print(id, print_chat, "[BD] %L", id, "BD_PERSONAL_RECORD", g_iPersonalDamage[id][weapon], WPN_NAMES[weapon], g_iPersonalHits[id][weapon])
		
		// Save new Record
		if (get_pcvar_num(cvar_SaveStatsPersonal))
			save_personal_top(id)
	}
	
	// Made a new Record
	if (g_iBlastDamageDealt[id] > g_iCachedDamage[weapon])
	{
		// Set players name, damage done and hits to cached records
		g_szCachedNames[weapon] = g_szPlayerName[id]
		g_szCachedSteamIDs[weapon] = g_szSteamID[id]
		g_iCachedDamage[weapon] = clamp(g_iBlastDamageDealt[id], 1, 999999)
		g_iCachedHits[weapon] = clamp(g_iBlastHits[id], 1, 9999)
		
		// Display new Record in Chat
		if (get_pcvar_num(cvar_ChatWeapon))
			client_print(0, print_chat, "[BD] %L", LANG_PLAYER, "BD_RECORD", g_szCachedNames[CSW_HEGRENADE], g_iCachedDamage[CSW_HEGRENADE], WPN_NAMES[CSW_HEGRENADE], g_iCachedHits[CSW_HEGRENADE])
		
		// Save new Record
		if (get_pcvar_num(cvar_SaveStats))
			save_top()
	}
	
	// Clear Player vars
	reset_record_vars(id, 1)
}

get_record()
{
	new dmg = 0, j = 0
	
	for(new i = DODW_AMERKNIFE; i <= DODW_PIAT; i++)
	{
		if(is_ignore_weapon_id(i)) continue
		
		if(g_iRecord[i] >= dmg)
		{
			dmg = g_iRecord[i]
			j = i
		}
	}
	g_iRecord[j] = -1
	
	return j;
}

load_top()
{
	// File not present
	if (!file_exists(g_szRecordFile))
	{
		save_top()
		return
	}
	
	// Set up some vars to hold parsing info
	new linedata[44], key[12], value[32], section
	
	// Open config file for reading
	new file = fopen(g_szRecordFile, "rt")
	
	while (file && !feof(file))
	{
		// Read one line at a time
		fgets(file, linedata, charsmax(linedata))
		
		// Replace newlines with a null character to prevent headaches
		replace(linedata, charsmax(linedata), "^n", "")
		
		// Blank line or comment
		if (!linedata[0] || linedata[0] == ';') continue
		
		// New section starting
		if (linedata[0] == '[')
		{
			section++
			continue
		}
		
		// Is ignore Weapon
		if (is_ignore_weapon_id(section))
			section++
		
		// Get key and value(s)
		strtok(linedata, key, charsmax(key), value, charsmax(value), '=')
		
		// Trim spaces
		trim(key)
		trim(value)
		
		if (equal(key, "NAME"))
			g_szCachedNames[section] = value
		else if (equal(key, "STEAM ID"))
			g_szCachedSteamIDs[section] = value
		else if (equal(key, "DAMAGE"))
			g_iCachedDamage[section] = str_to_num(value)
		else if (equal(key, "HITS"))
			g_iCachedHits[section] = str_to_num(value)
		else if (equal(key, "RESETS"))
			g_iCachedResets[section] = str_to_num(value)
	}
	if (file) fclose(file)
}

load_personal_top(id)
{
	// Get config file
	new szPersonalRecord[128]
	if (get_pcvar_num(cvar_SvLan))
		format(szPersonalRecord, charsmax(szPersonalRecord), "%s/bd_records/%s.ini", g_szDataDir, g_szPlayerName[id])
	else
		format(szPersonalRecord, charsmax(szPersonalRecord), "%s/bd_records/%s.ini", g_szDataDir, g_szSteamID[id])
	
	// File not present
	if (!file_exists(szPersonalRecord))
	{
		for (new i = DODW_AMERKNIFE; i <= DODW_PIAT; i++)
		{
			g_iPersonalDamage[id][i] = g_iPersonalHits[id][i] = 0
			g_iPersonalResets[id][i] = g_iCachedResets[i]
		}
		return
	}
	
	// Set up some vars to hold parsing info
	new linedata[24], key[12], value[12], section
	
	// Open config file for reading
	new file = fopen(szPersonalRecord, "rt")
	
	while (file && !feof(file))
	{
		// Read one line at a time
		fgets(file, linedata, charsmax(linedata))
		
		// Replace newlines with a null character to prevent headaches
		replace(linedata, charsmax(linedata), "^n", "")
		
		// Blank line or comment
		if (!linedata[0] || linedata[0] == ';') continue
		
		// New section starting
		if (linedata[0] == '[')
		{
			section++
			continue
		}
		
		// Is ignore Weapon
		if (is_ignore_weapon_id(section))
			section++
		
		// Get key and value(s)
		strtok(linedata, key, charsmax(key), value, charsmax(value), '=')
		
		// Trim spaces
		trim(key)
		trim(value)
		
		if (equal(key, "DAMAGE"))
			g_iPersonalDamage[id][section] = str_to_num(value)
		else if (equal(key, "HITS"))
			g_iPersonalHits[id][section] = str_to_num(value)
		else if (equal(key, "RESETS"))
			g_iPersonalResets[id][section] = str_to_num(value)
	}
	if (file) fclose(file)
}

save_top()
{
	// Record file exists, delete it!
	if (file_exists(g_szRecordFile)) delete_file(g_szRecordFile)
	
	// Open not exists config file for appending data (this create a new one)
	new file = fopen(g_szRecordFile, "at"), buffer[512]
	
	// Add any configuration from the player
	for (new section = DODW_AMERKNIFE; section <= DODW_PIAT; section++)
	{
		if (is_ignore_weapon_id(section)) continue
		
		// Add section name
		format(buffer, charsmax(buffer), "[%s]", WPN_NAMES[section])
		fputs(file, buffer)
		
		// Add record
		format(buffer, charsmax(buffer), "^nNAME = %s^nSTEAM ID = %s^nDAMAGE = %i^nHITS = %i^nRESETS = %i^n^n",
		g_szCachedNames[section], g_szCachedSteamIDs[section], g_iCachedDamage[section], g_iCachedHits[section], g_iCachedResets[section])
		fputs(file, buffer)
	}
	fclose(file)
}

save_personal_top(id)
{
	// Get config file
	new szPersonalRecord[128]
	if (get_pcvar_num(cvar_SvLan))
		format(szPersonalRecord, charsmax(szPersonalRecord), "%s/bd_records/%s.ini", g_szDataDir, g_szPlayerName[id])
	else
		format(szPersonalRecord, charsmax(szPersonalRecord), "%s/bd_records/%s.ini", g_szDataDir, g_szSteamID[id])
	
	// config file exists, delete it!
	if (file_exists(szPersonalRecord)) delete_file(szPersonalRecord)
	
	// Open not exists config file for appending data (this create a new one)
	new file = fopen(szPersonalRecord, "at"), buffer[512]
	
	// Add any configuration from the player
	for (new section = DODW_AMERKNIFE; section <= DODW_PIAT; section++)
	{
		if (is_ignore_weapon_id(section)) continue
		
		// Add section name
		format(buffer, charsmax(buffer), "[%s]", WPN_NAMES[section])
		fputs(file, buffer)
		
		// Add record
		format(buffer, charsmax(buffer), "^nDAMAGE = %i^nHITS = %i^nRESETS = %i^n^n",
		g_iPersonalDamage[id][section], g_iPersonalHits[id][section], g_iPersonalResets[id][section])
		fputs(file, buffer)
	}
	fclose(file)
}

reset_top(resetweapon = 0, resetall = 0)
{
	// Reset one cached Records
	if (resetweapon)
	{
		// Reset cache
		g_szCachedSteamIDs[resetweapon] = ""
		g_szCachedNames[resetweapon] = ""
		g_iCachedDamage[resetweapon] = g_iCachedHits[resetweapon] = 0
		g_iCachedResets[resetweapon]++
	}
	// Reset all cached Records
	else if (resetall)
	{
		for (new i = DODW_AMERKNIFE; i <= DODW_PIAT; i++)
		{
			g_szCachedSteamIDs[i] = ""
			g_szCachedNames[i] = ""
			g_iCachedDamage[i] = g_iCachedHits[i] = 0
			g_iCachedResets[i]++
		}
	}
	save_top()
	check_resets()
}

check_resets(target = 0)
{
	if (target)
	{
		for (new i = DODW_AMERKNIFE; i <= DODW_PIAT; i++)
		{
			if (g_iPersonalResets[target][i] >= g_iCachedResets[i]) continue
			
			g_iPersonalDamage[target][i] = g_iPersonalHits[target][i] = 0
			g_iPersonalResets[target][i] = g_iCachedResets[i]
		}
		save_personal_top(target)
	}
	else
	{
		static player
		for (player = 1; player <= g_iMaxPlayers; player++)
		{
			// Not connected
			if (!g_bIsConnected[player]) continue
			
			for (new i = DODW_AMERKNIFE; i <= DODW_PIAT; i++)
			{
				if (g_iPersonalResets[player][i] >= g_iCachedResets[i]) continue
				
				g_iPersonalDamage[player][i] = g_iPersonalHits[player][i] = 0
				g_iPersonalResets[player][i] = g_iCachedResets[i]
			}
			save_personal_top(player)
		}
	}
}

public DisplayBulletDamageHelp(id)
{
	// Plugin enable and it's still connected
	if (!get_pcvar_num(cvar_BulletDamage) || !g_bIsConnected[id]) return
	
	client_print(id, print_chat, "[BD] %L", id, "BD_INFO")
}

set_player_vars(id)
{
	g_iAuthorized[id] = g_iMenuType[id] = 0
	g_iDamageDealt[id] = g_iBlastDamageDealt[id] = 0
	g_iWeaponUse[id] = g_iWeaponEntity[id] = 0
	g_iHits[id] = g_iBlastHits[id] = 0
	g_iPreHealth[id] = g_iPostHealth[id] = 0
	g_bAttack2Weapon[id] = g_bWhileRecordTask[id] = g_bBlastWallVisible[id] = false
}

load_hud_vars(id)
{
	// Cache record file
	new szPersonalConfig[128]
	if (get_pcvar_num(cvar_SvLan))
		format(szPersonalConfig, charsmax(szPersonalConfig), "%s/bd_configs/%s.ini", g_szDataDir, g_szPlayerName[id])
	else
		format(szPersonalConfig, charsmax(szPersonalConfig), "%s/bd_configs/%s.ini", g_szDataDir, g_szSteamID[id])
	
	// File not present or Bot
	if (!file_exists(szPersonalConfig))
	{
		set_hud_vars(id)
		return
	}
	
	// Set up some vars to hold parsing info
	new linedata[1024], key[64], value[960], section
	
	// Open config file for reading
	new file = fopen(szPersonalConfig, "rt")
	
	while (file && !feof(file))
	{
		// Read one line at a time
		fgets(file, linedata, charsmax(linedata))
		
		// Replace newlines with a null character to prevent headaches
		replace(linedata, charsmax(linedata), "^n", "")
		
		// Blank line or comment
		if (!linedata[0] || linedata[0] == ';') continue
		
		// New section starting
		if (linedata[0] == '[')
		{
			section++
			continue
		}
		
		// Get key and value(s)
		strtok(linedata, key, charsmax(key), value, charsmax(value), '=')
		
		// Trim spaces
		trim(key)
		trim(value)
		
		switch (section)
		{
			case SECTION_HUD:
			{
				if (equal(key, "SINGLE"))
					g_iShowSingleHud[id] = str_to_num(value)
				else if (equal(key, "MULTIPLE"))
					g_iShowMultipleHud[id] = str_to_num(value)
				else if (equal(key, "GRENADE"))
					g_iShowBlastHud[id] = str_to_num(value)
				else if (equal(key, "TAKE"))
					g_iShowTakeHud[id] = str_to_num(value)
			}
			case SECTION_COLORS:
			{
				if (equal(key, "SINGLE RED"))
					g_iSingleColor[id][COLOR_RED] = str_to_num(value)
				else if (equal(key, "SINGLE GREEN"))
					g_iSingleColor[id][COLOR_GREEN] = str_to_num(value)
				else if (equal(key, "SINGLE BLUE"))
					g_iSingleColor[id][COLOR_BLUE] = str_to_num(value)
				else if (equal(key, "SINGLE STYLE"))
					g_iSingleColor[id][COLOR_STYLE] = str_to_num(value)
				else if (equal(key, "MULTIPLE RED"))
					g_iMultipleColor[id][COLOR_RED] = str_to_num(value)
				else if (equal(key, "MULTIPLE GREEN"))
					g_iMultipleColor[id][COLOR_GREEN] = str_to_num(value)
				else if (equal(key, "MULTIPLE BLUE"))
					g_iMultipleColor[id][COLOR_BLUE] = str_to_num(value)
				else if (equal(key, "MULTIPLE STYLE"))
					g_iMultipleColor[id][COLOR_STYLE] = str_to_num(value)
				else if (equal(key, "GRENADE RED"))
					g_iBlastColor[id][COLOR_RED] = str_to_num(value)
				else if (equal(key, "GRENADE GREEN"))
					g_iBlastColor[id][COLOR_GREEN] = str_to_num(value)
				else if (equal(key, "GRENADE BLUE"))
					g_iBlastColor[id][COLOR_BLUE] = str_to_num(value)
				else if (equal(key, "GRENADE STYLE"))
					g_iBlastColor[id][COLOR_STYLE] = str_to_num(value)
				else if (equal(key, "TAKE RED"))
					g_iTakeColor[id][COLOR_RED] = str_to_num(value)
				else if (equal(key, "TAKE GREEN"))
					g_iTakeColor[id][COLOR_GREEN] = str_to_num(value)
				else if (equal(key, "TAKE BLUE"))
					g_iTakeColor[id][COLOR_BLUE] = str_to_num(value)
				else if (equal(key, "TAKE STYLE"))
					g_iTakeColor[id][COLOR_STYLE] = str_to_num(value)
			}
			case SECTION_POSITIONS:
			{
				if (equal(key, "SINGLE X"))
					g_flSinglePosition_X[id] = str_to_float(value)
				else if (equal(key, "SINGLE Y"))
					g_flSinglePosition_Y[id] = str_to_float(value)
				else if (equal(key, "MULTIPLE X"))
					g_flMultiplePosition_X[id] = str_to_float(value)
				else if (equal(key, "MULTIPLE Y"))
					g_flMultiplePosition_Y[id] = str_to_float(value)
				else if (equal(key, "GRENADE X"))
					g_flBlastPosition_X[id] = str_to_float(value)
				else if (equal(key, "GRENADE Y"))
					g_flBlastPosition_Y[id] = str_to_float(value)
				else if (equal(key, "TAKE X"))
					g_flTakePosition_X[id] = str_to_float(value)
				else if (equal(key, "TAKE Y"))
					g_flTakePosition_Y[id] = str_to_float(value)
			}
			case SECTION_TIMES:
			{
				if (equal(key, "SINGLE"))
					g_flSingleTime[id] = str_to_float(value)
				else if (equal(key, "MULTIPLE"))
					g_flMultipleTime[id] = str_to_float(value)
				else if (equal(key, "GRENADE"))
					g_flBlastTime[id] = str_to_float(value)
				else if (equal(key, "TAKE"))
					g_flTakeTime[id] = str_to_float(value)
			}
		}
	}
	if (file) fclose(file)
}

save_hud_vars(id)
{
	// Get config file
	new szPersonalConfig[128]
	if (get_pcvar_num(cvar_SvLan))
		format(szPersonalConfig, charsmax(szPersonalConfig), "%s/bd_configs/%s.ini", g_szDataDir, g_szPlayerName[id])
	else
		format(szPersonalConfig, charsmax(szPersonalConfig), "%s/bd_configs/%s.ini", g_szDataDir, g_szSteamID[id])
	
	// config file exists, delete it!
	if (file_exists(szPersonalConfig)) delete_file(szPersonalConfig)
	
	// Open not exists config file for appending data (this create a new one)
	new file = fopen(szPersonalConfig, "at"), buffer[512]
	
	// Add any configuration from the player
	for (new section = SECTION_HUD; section < MAX_SECTIONS; section++)
	{
		switch (section)
		{
			case SECTION_HUD:
			{
				// Add section name
				format(buffer, charsmax(buffer), "[HUD]")
				fputs(file, buffer)
				
				// Add hud config
				format(buffer, charsmax(buffer), "^nSINGLE = %i^nMULTIPLE = %i^nGRENADE = %i^nTAKE = %i",
				g_iShowSingleHud[id], g_iShowMultipleHud[id], g_iShowBlastHud[id], g_iShowTakeHud[id])
				fputs(file, buffer)
			}
			case SECTION_COLORS:
			{
				// Add section name
				format(buffer, charsmax(buffer), "^n^n[COLORS]")
				fputs(file, buffer)
				
				// Add single
				format(buffer, charsmax(buffer), "^nSINGLE RED = %i^nSINGLE GREEN = %i^nSINGLE BLUE = %i^nSINGLE STYLE = %i",
				g_iSingleColor[id][COLOR_RED], g_iSingleColor[id][COLOR_GREEN], g_iSingleColor[id][COLOR_BLUE], g_iSingleColor[id][COLOR_STYLE])
				fputs(file, buffer)
				
				// Add multi
				format(buffer, charsmax(buffer), "^nMULTIPLE RED = %i^nMULTIPLE GREEN = %i^nMULTIPLE BLUE = %i^nMULTIPLE STYLE = %i",
				g_iMultipleColor[id][COLOR_RED], g_iMultipleColor[id][COLOR_GREEN], g_iMultipleColor[id][COLOR_BLUE], g_iMultipleColor[id][COLOR_STYLE])
				fputs(file, buffer)
				
				// Add he
				format(buffer, charsmax(buffer), "^nGRENADE RED = %i^nGRENADE GREEN = %i^nGRENADE BLUE = %i^nGRENADE STYLE = %i",
				g_iBlastColor[id][COLOR_RED], g_iBlastColor[id][COLOR_GREEN], g_iBlastColor[id][COLOR_BLUE], g_iBlastColor[id][COLOR_STYLE])
				fputs(file, buffer)
				
				// Add take
				format(buffer, charsmax(buffer), "^nTAKE RED = %i^nTAKE GREEN = %i^nTAKE BLUE = %i^nTAKE STYLE = %i",
				g_iTakeColor[id][COLOR_RED], g_iTakeColor[id][COLOR_GREEN], g_iTakeColor[id][COLOR_BLUE], g_iTakeColor[id][COLOR_STYLE])
				fputs(file, buffer)
			}
			case SECTION_POSITIONS:
			{
				// Add section name
				format(buffer, charsmax(buffer), "^n^n[POSITIONS]")
				fputs(file, buffer)
				
				// Add single
				format(buffer, charsmax(buffer), "^nSINGLE X = %.2f^nSINGLE Y = %.2f",
				g_flSinglePosition_X[id], g_flSinglePosition_Y[id])
				fputs(file, buffer)
				
				// Add multi
				format(buffer, charsmax(buffer), "^nMULTIPLE X = %.2f^nMULTIPLE Y = %.2f",
				g_flMultiplePosition_X[id], g_flMultiplePosition_Y[id])
				fputs(file, buffer)
				
				// Add he
				format(buffer, charsmax(buffer), "^nGRENADE X = %.2f^nGRENADE Y = %.2f",
				g_flBlastPosition_X[id], g_flBlastPosition_Y[id])
				fputs(file, buffer)
				
				// Add take
				format(buffer, charsmax(buffer), "^nTAKE X = %.2f^nTAKE Y = %.2f",
				g_flTakePosition_X[id], g_flTakePosition_Y[id])
				fputs(file, buffer)
			}
			case SECTION_TIMES:
			{
				// Add section name
				format(buffer, charsmax(buffer), "^n^n[TIMERS]")
				fputs(file, buffer)
				
				// Add time config
				format(buffer, charsmax(buffer), "^nSINGLE = %.2f^nMULTIPLE = %.2f^nGRENADE = %.2f^nTAKE = %.2f",
				g_flSingleTime[id], g_flMultipleTime[id], g_flBlastTime[id], g_flTakeTime[id])
				fputs(file, buffer)
			}
		}
	}
	fclose(file)
}

test_hud_vars(id)
{
	ClearSyncHud(id, g_HudSyncTake)
	set_hudmessage(g_iTakeColor[id][COLOR_RED], g_iTakeColor[id][COLOR_GREEN], g_iTakeColor[id][COLOR_BLUE], g_flTakePosition_X[id], g_flTakePosition_Y[id], g_iTakeColor[id][COLOR_STYLE], 0.0, g_flTakeTime[id], 1.0, 1.0, -1)
	ShowSyncHudMsg(id, g_HudSyncTake, "%L", id, "MENU_TAKE_TITLE")
	
	ClearSyncHud(id, g_HudSyncSingle)
	set_hudmessage(g_iSingleColor[id][COLOR_RED], g_iSingleColor[id][COLOR_GREEN], g_iSingleColor[id][COLOR_BLUE], g_flSinglePosition_X[id], g_flSinglePosition_Y[id], g_iSingleColor[id][COLOR_STYLE], 0.0, g_flSingleTime[id], 1.0, 1.0, -1)
	ShowSyncHudMsg(id, g_HudSyncSingle, "%L", id, "MENU_SINGLE_TITLE")
	
	ClearSyncHud(id, g_HudSyncMultiple)
	set_hudmessage(g_iMultipleColor[id][COLOR_RED], g_iMultipleColor[id][COLOR_GREEN], g_iMultipleColor[id][COLOR_BLUE], g_flMultiplePosition_X[id], g_flMultiplePosition_Y[id], g_iMultipleColor[id][COLOR_STYLE], 0.0, g_flMultipleTime[id], 1.0, 1.0, -1)
	ShowSyncHudMsg(id, g_HudSyncMultiple, "%L", id, "MENU_MULTI_TITLE")
	
	ClearSyncHud(id, g_HudSyncBlast)
	set_hudmessage(g_iBlastColor[id][COLOR_RED], g_iBlastColor[id][COLOR_GREEN], g_iBlastColor[id][COLOR_BLUE], g_flBlastPosition_X[id], g_flBlastPosition_Y[id], g_iBlastColor[id][COLOR_STYLE], 0.0, g_flBlastTime[id], 1.0, 1.0, -1)
	ShowSyncHudMsg(id, g_HudSyncBlast, "%L", id, "MENU_GRENADE_TITLE")
}

set_hud_vars(id)
{
	g_iShowSingleHud[id] = g_iShowMultipleHud[id] = g_iShowBlastHud[id] = g_iShowTakeHud[id] = 0
	
	g_iSingleColor[id][COLOR_RED] = g_iMultipleColor[id][COLOR_RED] = 0
	g_iSingleColor[id][COLOR_GREEN] = g_iMultipleColor[id][COLOR_GREEN] = 200
	g_iBlastColor[id][COLOR_RED] = g_iTakeColor[id][COLOR_RED] = 200
	g_iBlastColor[id][COLOR_GREEN] = g_iTakeColor[id][COLOR_GREEN] = 0
	g_iSingleColor[id][COLOR_BLUE] = g_iMultipleColor[id][COLOR_BLUE] = g_iBlastColor[id][COLOR_BLUE] = g_iTakeColor[id][COLOR_BLUE] = 0
	
	g_flSinglePosition_X[id] = g_flMultiplePosition_X[id] = g_flBlastPosition_X[id] = g_flTakePosition_Y[id] = -1.0
	g_flSinglePosition_Y[id] = 0.58
	g_flMultiplePosition_Y[id] = 0.38
	g_flBlastPosition_Y[id] = 0.65
	g_flTakePosition_X[id] = 0.40
	
	g_flSingleTime[id] = g_flMultipleTime[id] = g_flBlastTime[id] = g_flTakeTime[id] = 2.5
}

reset_record_vars(id, grenade = 0)
{
	if (grenade)
	{
		g_iBlastDamageDealt[id] = g_iBlastHits[id] = 0
		g_bBlastWallVisible[id] = false
	}
	else
		g_iDamageDealt[id] = g_iHits[id] = 0
}

show_blast_damage(id)
{
	// Enable grenade damage?
	if (!get_pcvar_num(cvar_BlastDamage)) return
	
	// Static Hud Damage Wall num
	static HudDamageWall
	HudDamageWall = get_pcvar_num(cvar_HudDamageWall)
	
	switch (get_pcvar_num(cvar_HudDamage))
	{
		case 2: // Admin
		{
			if (!g_iShowBlastHud[id] || !user_has_flag(id, ACCESS_HUD) || (!HudDamageWall && !g_bBlastWallVisible[id])) return
			
			ClearSyncHud(id, g_HudSyncBlast)
			set_hudmessage(g_iBlastColor[id][COLOR_RED], g_iBlastColor[id][COLOR_GREEN], g_iBlastColor[id][COLOR_BLUE], g_flBlastPosition_X[id], g_flBlastPosition_Y[id], g_iBlastColor[id][COLOR_STYLE], 0.0, g_flBlastTime[id],  1.0, 1.0, -1)
			ShowSyncHudMsg(id, g_HudSyncBlast, "%i", g_iBlastDamageDealt[id])
		}
		case 1: // Player
		{
			if (!g_iShowBlastHud[id] || (HudDamageWall == 2 && !user_has_flag(id, ACCESS_HUD) && !g_bBlastWallVisible[id]) || (!HudDamageWall && !g_bBlastWallVisible[id])) return
			
			ClearSyncHud(id, g_HudSyncBlast)
			set_hudmessage(g_iBlastColor[id][COLOR_RED], g_iBlastColor[id][COLOR_GREEN], g_iBlastColor[id][COLOR_BLUE], g_flBlastPosition_X[id], g_flBlastPosition_Y[id], g_iBlastColor[id][COLOR_STYLE], 0.0, g_flBlastTime[id],  1.0, 1.0, -1)
			ShowSyncHudMsg(id, g_HudSyncBlast, "%i", g_iBlastDamageDealt[id])
		}
	}
}

/*================================================================================
 [Message Hooks]
=================================================================================*/

public message_Health(msg_id, msg_dest, msg_entity)
{
	// Get player's health
	static health
	health = get_msg_arg_int(1)
	
	if(health > 0)
		g_iPreHealth[msg_entity] = health
}

/*================================================================================
 [Stocks]
=================================================================================*/

stock ham_dod_get_weapon_ent_owner(entity)
{
	return get_pdata_cbase(entity, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS);
}

stock fm_dod_get_weapon_id(entity)
{
	return get_pdata_int(entity, OFFSET_WEAPONID, OFFSET_LINUX_WEAPONS);
}

stock fm_dod_get_user_zoom(index)
{
	return get_pdata_int(index, OFFSET_ZOOMTYPE);
}

stock ClassNameToWeaponID(const name[])
{
	if (name[0] == 'g' && name[4] == 'a' && name[5] == 'd' && name[6] == 'e' && name[7] == '2')
		return DODW_STICKGRENADE;
	
	if (name[0] == 'g' && name[3] == 'n' && name[4] == 'a' && name[5] == 'd' && name[6] == 'e')
		return DODW_HANDGRENADE;
	
	if (name[0] == 's' && name[5] == '_' && name[6] == 'b' && name[7] == 'a' && name[8] == 'z')
		return DODW_BAZOOKA;
	
	if (name[0] == 's' && name[5] == '_' && name[6] == 'p' && name[7] == 's' && name[8] == 'c')
		return DODW_PANZERSCHRECK;
	
	if (name[0] == 's' && name[5] == '_' && name[6] == 'p' && name[7] == 'i' && name[8] == 'a')
		return DODW_PIAT;
	
	return 0;
}

stock bool:fm_is_visible(index, const Float:point[3])
{
	static Float:start[3], Float:view_ofs[3]
	
	pev(index, pev_origin, start)
	pev(index, pev_view_ofs, view_ofs)
	xs_vec_add(start, view_ofs, start)
	
	engfunc(EngFunc_TraceLine, start, point, IGNORE_GLASS|IGNORE_MONSTERS, index, 0)
	
	static Float:fraction
	get_tr2(0, TR_flFraction, fraction)
	if (fraction == 1.0)
		return true;
	
	return false;
}
