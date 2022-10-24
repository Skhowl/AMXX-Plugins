/*================================================================================
	
		***********************************************************
		*********** [Bullet Damage with Ranking 3.0.2] ************
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
	
	* Game: Counter-Strike 1.6 or Condition Zero
	* Metamod: Version 1.19 or later
	* AMXX: Version 1.8.0 or later
	* Module: cstrike, fakemeta, hamsandwich
	
	----------------
	-*- Commands -*-
	----------------
	
	say: /bd - open bd menu
	con: bd_reset "argument" - look bd_reset.txt for all possible bd_reset commands!
	
	-------------------------------
	-*- CVARS and Customization -*-
	-------------------------------
	
	For a complete and in-depth cvar list, look at the bulletdamage.cfg file
	located in the amxmodx\configs directory.
	
	---------------
	-*- Credits -*-
	---------------
	
	* MeRcyLeZZ: for some useful stuff
	* worldspawn: for few ideas - motd style, damage sorting, new command and bd_no_over_dmg ;)
	* Pneumatic: for the bd_multi_dmg 2 idea
	* ConnorMcLeod: for Ham_TakeDamage forward idea (v2.2.0 -> HE-Grenade compatibility)
	* Alucard^: for the enable/disable (global) HUD-Damage idea
	* Hawk552: for approve and optimization plugin
	* GAARA54: for colored chat idea and Zombie Plague Advance 1.6 Compatibility request
	
	-----------------
	-*- Changelog -*-
	-----------------
	
	+ Added feature or noticeable improvement
	- Bug fix or something removed
	* Changed or Information
	! Important - Take note!
	
	* v1.1: (?)
	   + display multiple damage
	
	* v1.2: (?)
	   + new cvar bd_more_time
	   + announce (name, damage, weapon) in chat
	   + anti cheat (ARC) if u change your weapon in a long task like awp
	
	* v1.3: (21st Dec 2009)
	   + new cvar bd_chat
	   + new command /top
	   + save and load records
	   + motd to show the records in table style
	   * announce (name, damage, weapon and hits) in chat
	
	* v1.4: (22nd Dec 2009)
	   + new cvars bd_multi_dmg, bd_save_stats, bd_save_bots, bd_motd_method
	   + new motd sytle like top15 from statsx.sma
	   * chat command from /top to /bdtop
	
	* v1.5: (23rd Dec 2009)
	   + new cvars bd_color, bd_color_style, bd_color_holdtime, bd_motd_sorting
	   + new motd sorting method
	   * some stuff
	
	* v1.5.1: (24th Dec 2009)
	   * show_top
	
	* v2.0: (25th Jan 2010)
	   ! teammate attack protection (record cheat)
	   + new command to reset all records
	   * plugin name from achievement to ranking
	   * some stuff
	
	* v2.1: (16th Feb 2010)
	   + bd_multi_dmg 2 = display single & multiple damage together
	   * some stuff
	
	* v2.1.1: (17th Feb 2010)
	   + firerate time multiply for record task (look Plugin Customization section)
	   + full knife atk1 & atk2 compatible
	   * weapon firerate using fastest orginal rates
	   - query player zooming
	
	* v2.1.2: (2nd Mar 2010)
	   + multi language support
	
	* v2.1.3: (12th Mar 2010)
	   + cvar bd_no_over_dmg
	
	* v2.2.0: (30th Mar 2010)
	   + HE-Grenade compatibility
	   + HE-Grenade has now a own record task
	   * some stuff
	
	* v2.3.0: (30th Mar 2010)
	   + RC1 new client command to enable/disable HUD-Damage
	   + RC1 new cvar to enable/disable global HUD-Damage
	   * RC2 HE-Grenade HUD-Damage Sync Object
	   - RC3 /bdhud showing wrong chat info (enable/disable print)
	
	* v2.3.1: (3rd Apr 2010)
	   + more Customization
	   + bulletdamage.cfg file
	   * some stuff (lower CPU usage)
	   * admin console command bd_reset
	   - /bdtop not showing all weapons
	
	* v2.4.0: (5th Apr 2010)
	   + cvar bd_hud_dmg_wall
	   + show HUD-Damage when you hit the enemy and he is behind a wall
	   + cvar bd_ffa_dmg enable "free for all" damage for FFA servers
	   * damage stuff
	
	* v2.4.1: (7th Apr 2010)
	   + Shield support
	   - clear unusing stuff
	
	* v2.4.2: (18th Apr 2010)
	   * Knife attack 2 is now _Post not _Pre
	   * damage stuff (timers)
	   - fixing read/save/reset "top bullet damage"
	
	* v2.5.0: (23rd Apr 2010)
	   ! Knife attack 2 is again _Pre forward
	   + Zombie Plague 4.3 Compatibility
	   + records now saved by Steam ID, only steam authorized players can made records
	   * motd misstep, when it calls 2 times to fast
	
	* v2.5.1: (24th Apr 2010)
	   ! Damage vars not reseting for non-steam players
	
	* v2.5.2: (17th Jun 2010)
	   * ARC and some stuff
	   - wrong counting of hits, most by HE-Grenade (CZ)
	   - Remove ML 'BDwR_CHEAT'
	
	* v2.5.3: (26th Jun 2010)
	   ! new ARC system
	   + admin reset and hud flag cvar
	   + admin show HUD-Damage
	   + admin show HUD-Damage when you hit the enemy and he is behind a wall
	   + Lan Server support
	   - bd_motd_method only Top15 style possible
	
	* v2.5.4: (27th Jun 2010)
	   - HUD-Damage for HE-Grenade with the new cvars
	   - fix cvar combination bd_hud_dmg 1 and bd_hud_dmg_wall 2 not showing HUD-Damage for normal players
	   - Remove scripter query in fwd_TraceAttack (plugin test query)
	
	* v2.5.5: (3rd Jul 2010)
	   + Zombie Plague Advance 1.6 Compatibility
	   + colored chat
	   - Remove zp4.3 infect querys, not need more with the new ARC system
	
	* v2.5.6: (21st Jul 2010)
	   * clearing the code
	
	* v2.5.7: (29th Jul 2010)
	   ! fix authorized bug (thanks craigy09)
	
	* v2.5.8: (5th Sep 2010)
	   ! showing fault overpower damage on zombie servers
	
	* v2.5.9: (13th Sep 2010)
	   - damage not showing through glass and players
	
	* v3.0.0: (27th Jan 2011)
	   + Menu to configurate own player hud messages for 
	       + colors
		   + position (x,y)
		   + flicker
		   + holdtime
		   + personal records
		   + all weapon records
		   + admin menu
	
	* v3.0.1: (31st Jan 2011)
	   ! admin menu (bug found, by converting this plugin to DoD)
	
	* v3.0.2: (12th Jul 2012)
	   ! FPS drop with HUD Sync Objects
	   ! Unique crash on private data
	   - Records/configs not being saved on windows (hopefully)
	
	+ Added feature or noticeable improvement
	- Bug fix or something removed
	* Changed or Information
	! Important - Take note!
	
=================================================================================*/

#include <amxmodx>
#include <amxmisc>
#include <cstrike>
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

// uncomment the line to have Zombie Plague 4.3 Compatibility
//#define ZOMBIE_PLAGUE_MOD
// uncomment the line to have Zombie Plague Advance 1.6 Compatibility
//#define ZOMBIE_PLAGUE_ADVANCE_MOD

/*================================================================================
 Customization ends here! Yes, that's it. Editing anything beyond
 here is not officially supported. Proceed at your own risk...
=================================================================================*/

/*================================================================================
 [Constants, Offsets, Macros]
=================================================================================*/

// Plugin Version
new const PLUGIN_VERSION[] = "3.0.2"

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
	TASK_KNIFE,
	TASK_GRENADE
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
#define ID_KNIFE (taskid - TASK_KNIFE)
#define ID_GRENADE (taskid - TASK_GRENADE)

// few constants
const FM_PDATA_SAFE = 2
const MOTD_MAX_WEAPONS = 26 // CSW_P90 (30) - is_ignore_weapon_id (4)
const DMG_HEGRENADE = (1<<24)
const Float:POSI_TYPE_TRUE = 0.10
const Float:POSI_TYPE_FALSE = 0.01
const Float:TIME_TYPE_TRUE = 1.00
const Float:TIME_TYPE_FALSE = 0.10

// CS Weapon CBase Offset (win32)
const OFFSET_WEAPONOWNER = 41

// Linux diff
const OFFSET_LINUX_WEAPONS = 4

// Weapon Names
new const WPN_NAMES[][] = {
	"", "228 Compact", "", "Schmidt Scout", "HE Grenade", "Leone YG1265 Auto Shotgun", "", "Ingram MAC-10",
	"Bullpup", "", ".40 Dual Elites", "ES Five-Seven", "KM UMP45", "Krieg 550 Commando",
	"IDF Defender", "Clarion 5.56", "KM .45 Tactical", "9x19mm Sidearm", "Magnum Sniper Rifle", "KM Sub-Machine Gun",
	"M249", "Leone 12 Gauge Super", "Maverick M4A1 Carbine", "Schmidt Machine Pistol", "D3/AU1", "", "Night Hawk .50C",
	"Krieg 552", "CV-47", "Knife", "ES C90"
}

// short Weapon Names
new const WPN_SHORTNAMES[][7] = {
	"", "p228", "", "scout", "hegren", "xm1014", "", "mac10",
	"aug", "", "elites", "fn57", "ump45", "sg550",
	"galil", "famas", "usp", "glock", "awp", "mp5",
	"m249",	"m3", "m4a1", "tmp", "g3sg1", "", "deagle",
	"sg552", "ak47", "knife", "p90"
}

// Weapon entity names
new const WPN_ENTNAMES[][] = {
	"", "weapon_p228", "", "weapon_scout", "", "weapon_xm1014", "", "weapon_mac10",	"weapon_aug",
	"", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550", "weapon_galil",
	"weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
	"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "", "weapon_deagle", "weapon_sg552",
	"weapon_ak47", "weapon_knife", "weapon_p90"
}

// Weapon fastest firerate time
new const Float:WPN_FIRERATE[] = {
	0.1,	// --- (NOTHING)
	0.16,	// P228
	0.1,	// --- (NOTHING)
	1.26,	// SCOUT
	0.1,	// HEGRENADE
	0.25,	// XM1014
	0.1,	// --- (C4)
	0.08,	// MAC10
	0.09,	// AUG
	0.1,	// --- (SMOKEGRENADE)
	0.1,	// ELITE
	0.16,	// FIVESEVEN
	0.11,	// UMP45
	0.25,	// SG550
	0.09,	// GALIL
	0.09,	// FAMAS
	0.15,	// USP
	0.16,	// GLOCK18
	1.46,	// AWP
	0.08,	// MP5NAVY
	0.11,	// M249
	0.88,	// M3
	0.09,	// M4A1
	0.08,	// TMP
	0.25,	// G3SG1
	0.1,	// --- (FLASHBANG)
	0.23,	// DEAGLE
	0.09,	// SG552
	0.1,	// AK47
	0.41,	// KNIFE
	0.07	// P90
}
const Float:ZOOMED_AUG_SG552 = 0.14
const Float:BURST_FAMAS = 0.41
const Float:BURST_GLOCK18 = 0.5
const Float:ATK2_KNIFE = 1.11

// Menu keys
const KEYSMENU = MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_8|MENU_KEY_9|MENU_KEY_0

/*================================================================================
 [Zombie Plague Advance Compatibility Checking]
=================================================================================*/

// try include "zombie_plague_advance.inc"
#if defined ZOMBIE_PLAGUE_ADVANCE_MOD

#tryinclude <zombie_plague_advance>

	#if !defined _zombie_plague_advance_included
		#assert zombie_plague_advance.inc library required!
	#endif
#endif

/*================================================================================
 [Zombie Plague Compatibility Checking]
=================================================================================*/

// try include "zombieplague.inc"
#if defined ZOMBIE_PLAGUE_MOD
	#if !defined _zombie_plague_advance_included
		
		#tryinclude <zombieplague>
		
		#if !defined _zombieplague_included
			#assert zombieplague.inc library required!
		#endif
	#endif
#endif

/*================================================================================
 [Global Variables]
=================================================================================*/

// Player vars
new g_iDamageDealt[33] // total damage
new g_iWeaponUse[33] // current weapon
new g_iWeaponEntity[33] // weapon entity
new g_iHits[33] // hits
new g_bAttack2Knife[33] // knife attack2 (stab)
new g_iPreHealth[33] // pre health
new g_iPostHealth[33] // post health
new g_iGrenadeDamageDealt[33] // HE total damage
new g_iGrenadeHits[33] // HE hits
new Float:g_flWallOrigin[33][33][3] // visible [owner][other][origin]
new g_iAuthorized[33] // authorized steam player
new g_bWhileRecordTask[33] // while record task
new g_bGrenadeWallVisible[33] // HE grenade damage is visible

// Player Hud stuff
new g_iShowSingleHud[33] // show hud single damage message
new g_iShowMultipleHud[33] // show hud multi damage message
new g_iShowGrenadeHud[33] // show hud he damage message
new g_iShowTakeHud[33] // show hud take damage message
new g_iDynamicMenu[33] // what section u are in dynamic menu
new g_iMenuType[33] // Position type 0.01 or 0.1 and Time type 1.0 or 0.1

// Player Hud config stuff
new g_iSingleColor[33][MAX_COLORS] // single colors and style
new g_iMultipleColor[33][MAX_COLORS] // multi colors and style
new g_iGrenadeColor[33][MAX_COLORS] // he colors and style
new g_iTakeColor[33][MAX_COLORS] // take colors and style
new Float:g_flSinglePosition_X[33] // single X position message
new Float:g_flSinglePosition_Y[33] // single Y position message
new Float:g_flMultiplePosition_X[33] // multi X position message
new Float:g_flMultiplePosition_Y[33] // multi Y position message
new Float:g_flGrenadePosition_X[33] // he X position message
new Float:g_flGrenadePosition_Y[33] // he Y position message
new Float:g_flTakePosition_X[33] // take X position message
new Float:g_flTakePosition_Y[33] // take Y position message
new Float:g_flSingleTime[33] // single holdtime message
new Float:g_flMultipleTime[33] // multi holdtime message
new Float:g_flGrenadeTime[33] // he holdtime message
new Float:g_flTakeTime[33] // take holdtime message

// Game vars
new g_iMaxPlayers // max player counter
new g_HudSyncSingle, g_HudSyncMultiple, g_HudSyncGrenade, g_HudSyncTake // message sync objects
new g_bHamCzBots // whether ham forwards are registered for CZ bots
new g_bMotdPrepair // flag for whenever a Motd prepairs

// Message IDs vars
new g_msgSayText

// Access vars
new g_access_flag[MAX_ACCESS_FLAGS]

// CVAR pointers
new cvar_BulletDamage, cvar_HudDamageWall, cvar_SaveStatsPersonal,
cvar_ChatWeapon, cvar_ChatPersonal, cvar_MotdSort, cvar_AdminHudFlag,
cvar_AdminResetFlag, cvar_Single, cvar_Multiple, cvar_NoOverDamage,
cvar_GrenadeDamage, cvar_TakeDamage, cvar_MoreTime, cvar_HudDamage,
cvar_SaveStats, cvar_SvLan, cvar_BotQuota, cvar_FFA, cvar_SaveBots

// Zombie Plague Compatibility
#if defined _zombieplague_included || defined _zombie_plague_advance_included

// CVAR pointers
new cvar_zpNemesisDamage, cvar_zpSurvivorDamage

#endif

// Zombie Plague Advance Compatibility
#if defined _zombie_plague_advance_included

// CVAR pointers
new cvar_zpAssassinDamage, cvar_zpSniperDamage

#endif

// Record vars
new g_szDataDir[64] // file parth of data folder
new g_szRecordFile[128] // file parth of BD_RECORD_FILE
new g_iRecord[CSW_P90+1] // for sorting method
new g_szCachedNames[CSW_P90+1][32] // cached record names
new g_szCachedSteamIDs[CSW_P90+1][32] // cached record steam id's
new g_iCachedDamage[CSW_P90+1] // cached record damage
new g_iCachedHits[CSW_P90+1] // cached record hits
new g_iCachedResets[CSW_P90+1] // cached record resets

// Personal record vars
new g_iPersonalDamage[33][CSW_P90+1] // personal record damage
new g_iPersonalHits[33][CSW_P90+1] // personal record hits
new g_iPersonalResets[33][CSW_P90+1] // personal record resets

// Cached stuff for players
new g_bIsConnected[33] // whether player is connected
new g_bIsBot[33] // whether player is a bot
new g_szPlayerName[33][32] // player's name
new g_szSteamID[33][32] // player's Steam ID

// Macros
#define is_user_valid_connected(%1) (1 <= %1 <= g_iMaxPlayers && g_bIsConnected[%1])
#define is_ignore_weapon_id(%1) (%1 == 2 || %1 == 6 || %1 == 9 || %1 == 25)
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
	RegisterHam(Ham_TakeDamage, "player", "fwd_TakeDamage_Post", 1)
	RegisterHam(Ham_TraceAttack, "player", "fwd_TraceAttack")
	
	// HAM Forwards "entity"
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "fwd_Knife_SecAtk")
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
	
	// Message IDs
	g_msgSayText = get_user_msgid("SayText")
	
	// Message hooks
	register_message(get_user_msgid("Damage"), "message_damage")
	register_message(get_user_msgid("Health"), "message_health")
	
	// CVARS - General Purpose
	cvar_BulletDamage = register_cvar("bd_on", "1")
	cvar_SaveBots = register_cvar("bd_save_bots", "1")
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
	cvar_GrenadeDamage = register_cvar("bd_grenade_dmg", "1")
	cvar_TakeDamage = register_cvar("bd_take_dmg", "1")
	
	// Zombie Plague Compatibility
	#if defined _zombieplague_included || defined _zombie_plague_advance_included
	
	// CVARS - Zombie Plague
	cvar_zpNemesisDamage = register_cvar("bd_nem_dmg_record", "0")
	cvar_zpSurvivorDamage = register_cvar("bd_surv_dmg_record", "0")
	
	#endif
	
	// Zombie Plague Advance Compatibility
	#if defined _zombie_plague_advance_included
	
	// CVARS - Zombie Plague Advance
	cvar_zpAssassinDamage = register_cvar("bd_assa_dmg_record", "0")
	cvar_zpSniperDamage = register_cvar("bd_snip_dmg_record", "0")
	
	#endif
	
	// CVARS - Others
	cvar_SvLan = get_cvar_pointer("sv_lan")
	cvar_BotQuota = get_cvar_pointer("bot_quota")
	register_cvar("BDwR_version", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY)
	set_cvar_string("BDwR_version", PLUGIN_VERSION)
	
	// Create the HUD Sync Object
	g_HudSyncSingle = CreateHudSyncObj()
	g_HudSyncMultiple = CreateHudSyncObj()
	g_HudSyncGrenade = CreateHudSyncObj()
	g_HudSyncTake = CreateHudSyncObj()
	
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
	
	// Cached bot stuff
	if (is_user_bot(id))
	{
		// Set bot flag
		g_bIsBot[id] = true
		
		// Bots are always Authorized
		g_iAuthorized[id] = 1
		
		// Load personal top & hud standard
		set_hud_vars(id)
		load_personal_top(id)
		check_resets(id)
		
		// CZ bots seem to use a different "classtype" for player entities
		// (or something like that) which needs to be hooked separately
		if (!g_bHamCzBots && cvar_BotQuota)
		{
			// Set a task to let the private data initialize
			set_task(0.1, "register_ham_czbots", id)
		}
	}
	else
	{
		// Set a task to let Display Help
		set_task(20.0, "DisplayBulletDamageHelp", id)
		
		// Load personal top & hud config
		load_hud_vars(id)
		load_personal_top(id)
		check_resets(id)
		
		// Not authorized
		if (!g_iAuthorized[id]) return
		
		// Check if Player have Records
		new szSteam[32], save
		szSteam = g_szSteamID[id]
		
		for (new i = CSW_P228; i <= CSW_P90; i++)
		{
			// check steam id
			if (is_ignore_weapon_id(i) || !equali(szSteam, g_szCachedSteamIDs[i])) continue
			
			// Cache new name
			replace_all(g_szPlayerName[id], charsmax(g_szPlayerName[]), "^^", "_")
			g_szCachedNames[i] = g_szPlayerName[id]
			save = true
		}
		// Save?
		if (save && get_pcvar_num(cvar_SaveStats))
			save_top()
	}
}

public client_disconnect(id)
{
	// Player disconnected
	g_bIsConnected[id] = false
	
	// Remove Tasks
	remove_task(id)
	remove_task(id+TASK_DAMAGE)
	remove_task(id+TASK_KNIFE)
	remove_task(id+TASK_GRENADE)
	
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
		
		for (new i = CSW_P228; i <= CSW_P90; i++)
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
	
	// Bots are always Authorized or Lan Server?
	if (g_bIsBot[id] || get_pcvar_num(cvar_SvLan))
		g_iAuthorized[id] = 1
}

/*================================================================================
 [Main Forwards]
=================================================================================*/

public fwd_TakeDamage_Post(victim, inflictor, attacker, Float:damage, damage_type)
{
	if (!get_pcvar_num(cvar_BulletDamage)) return HAM_IGNORED
	
	new dmg_take
	if ((dmg_take = pev(victim, pev_dmg_take)) <= 0) return HAM_IGNORED
	
	if (g_iShowTakeHud[victim] && get_pcvar_num(cvar_TakeDamage))
	{
		ClearSyncHud(victim, g_HudSyncTake)
		set_hudmessage(g_iTakeColor[victim][COLOR_RED], g_iTakeColor[victim][COLOR_GREEN], g_iTakeColor[victim][COLOR_BLUE], g_flTakePosition_X[victim], g_flTakePosition_Y[victim], g_iTakeColor[victim][COLOR_STYLE], 0.0, g_flTakeTime[victim], 1.0, 1.0, -1)
		ShowSyncHudMsg(victim, g_HudSyncTake, "%i", dmg_take)
	}
	
	if (!is_user_valid_connected(attacker) || victim == attacker || (!get_pcvar_num(cvar_FFA) && cs_get_user_team(victim) == cs_get_user_team(attacker)) || (!get_pcvar_num(cvar_SaveBots) && g_bIsBot[attacker])) return HAM_IGNORED
	
	// Damage by HE grenade
	if (damage_type & DMG_HEGRENADE)
	{
		// Remove HE Damage Timer
		remove_task(attacker+TASK_GRENADE)
		
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
		g_iGrenadeDamageDealt[attacker] += dmg_take
		g_iGrenadeHits[attacker]++
		
		// HE-Grenade Wall Damage visible?
		if (!g_bGrenadeWallVisible[attacker])
			g_bGrenadeWallVisible[attacker] = ExecuteHam(Ham_FVisible, attacker, victim)
		
		// Set Task for multiple Damage
		set_task(WPN_FIRERATE[CSW_HEGRENADE], "damage_deal_he", attacker+TASK_GRENADE)
		
		return HAM_IGNORED
	}
	
	// I will made a new Record! (bugfix)
	g_bWhileRecordTask[attacker] = true
	
	// Remove Damage Timer
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
		switch (g_iWeaponUse[attacker])
		{
			case CSW_KNIFE:
			{
				if (g_bAttack2Knife[attacker])
					timer = ATK2_KNIFE * FIRERATE_MULTI
				else
					timer = WPN_FIRERATE[CSW_KNIFE] * FIRERATE_MULTI
			}
			case CSW_AUG, CSW_SG552:
			{
				if (cs_get_user_zoom(attacker) == 4)
					timer = ZOOMED_AUG_SG552 * FIRERATE_MULTI
				else
					timer = WPN_FIRERATE[g_iWeaponUse[attacker]] * FIRERATE_MULTI
			}
			case CSW_FAMAS:
			{
				if (cs_get_weapon_burst(g_iWeaponEntity[attacker]))
					timer = BURST_FAMAS * FIRERATE_MULTI
				else
					timer = WPN_FIRERATE[CSW_FAMAS] * FIRERATE_MULTI
			}
			case CSW_GLOCK18:
			{
				if (cs_get_weapon_burst(g_iWeaponEntity[attacker]))
					timer = BURST_GLOCK18 * FIRERATE_MULTI
				else
					timer = WPN_FIRERATE[CSW_GLOCK18] * FIRERATE_MULTI
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
	if (!(damage_type & DMG_BULLET) || !is_user_valid_connected(attacker) || victim == attacker || (!get_pcvar_num(cvar_FFA) && cs_get_user_team(victim) == cs_get_user_team(attacker))) return HAM_IGNORED
	
	// get bullet impacting origin
	get_tr2(tracehandle, TR_vecEndPos, g_flWallOrigin[attacker][victim])
	
	return HAM_IGNORED
}

public fwd_Knife_SecAtk(weapon_ent)
{
	// Plugin off
	if (!get_pcvar_num(cvar_BulletDamage)) return HAM_IGNORED
	
	// Get weapon's owner
	static owner
	owner = ham_cs_get_weapon_ent_owner(weapon_ent)
	
	// Owner not safe, bots can made records?
	if (!owner || !get_pcvar_num(cvar_SaveBots) && g_bIsBot[owner]) return HAM_IGNORED
	
	// remove knife atk2 task
	remove_task(owner+TASK_KNIFE)
	
	// set knife atk2
	g_bAttack2Knife[owner] = true
	set_task(0.2, "reset_atk2_knife", owner+TASK_KNIFE)
	
	return HAM_IGNORED
}

public fwd_Item_Deploy_Post(weapon_ent)
{
	// Get weapon's owner
	static owner
	owner = ham_cs_get_weapon_ent_owner(weapon_ent)
	
	// Check Cheating (bugfix)
	if (g_bWhileRecordTask[owner])
	{
		// Cheat detected
		remove_task(owner+TASK_DAMAGE)
		damage_deal(owner+TASK_DAMAGE)
	}
	
	// Store current weapon's id for reference
	g_iWeaponUse[owner] = cs_get_weapon_id(weapon_ent)
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
	new arg[6]
	read_argv(1, arg, charsmax(arg))
	
	// Switch string
	switch (arg[0])
	{
		case 'a':
		{
			switch (arg[1])
			{
				case 'l':
				{
					// Reset all records and give console confirmation
					reset_top(0, 1)
					console_print(id, "[BD] %L %L", id, "MENU_RESET_ALL", id, "MENU_RESET_RECORD")
					return PLUGIN_HANDLED
				}
				case 'k':
				{
					// Reset AK47 record and give console confirmation
					reset_top(CSW_AK47)
					console_print(id, "[BD] %s %L", WPN_NAMES[CSW_AK47], id, "MENU_RESET_RECORD")
					return PLUGIN_HANDLED
				}
				case 'u':
				{
					// Reset AUG record and give console confirmation
					reset_top(CSW_AUG)
					console_print(id, "[BD] %s %L", WPN_NAMES[CSW_AUG], id, "MENU_RESET_RECORD")
					return PLUGIN_HANDLED
				}
				case 'w':
				{
					// Reset AWP record and give console confirmation
					reset_top(CSW_AWP)
					console_print(id, "[BD] %s %L", WPN_NAMES[CSW_AWP], id, "MENU_RESET_RECORD")
					return PLUGIN_HANDLED
				}
			}
		}
		case 'd':
		{
			// Reset DEAGLE record and give console confirmation
			reset_top(CSW_DEAGLE)
			console_print(id, "[BD] %s %L", WPN_NAMES[CSW_DEAGLE], id, "MENU_RESET_RECORD")
			return PLUGIN_HANDLED
		}
		case 'e':
		{
			// Reset ELITE record and give console confirmation
			reset_top(CSW_ELITE)
			console_print(id, "[BD] %s %L", WPN_NAMES[CSW_ELITE], id, "MENU_RESET_RECORD")
			return PLUGIN_HANDLED
		}
		case 'f':
		{
			switch (arg[1])
			{
				case 'a':
				{
					// Reset FAMAS record and give console confirmation
					reset_top(CSW_FAMAS)
					console_print(id, "[BD] %s %L", WPN_NAMES[CSW_FAMAS], id, "MENU_RESET_RECORD")
					return PLUGIN_HANDLED
				}
				case 'i':
				{
					// Reset FIVESEVEN record and give console confirmation
					reset_top(CSW_FIVESEVEN)
					console_print(id, "[BD] %s %L", WPN_NAMES[CSW_FIVESEVEN], id, "MENU_RESET_RECORD")
					return PLUGIN_HANDLED
				}
			}
		}
		case 'g':
		{
			switch (arg[1])
			{
				case '3':
				{
					// Reset G3SG1 record and give console confirmation
					reset_top(CSW_G3SG1)
					console_print(id, "[BD] %s %L", WPN_NAMES[CSW_G3SG1], id, "MENU_RESET_RECORD")
					return PLUGIN_HANDLED
				}
				case 'a':
				{
					// Reset GALIL record and give console confirmation
					reset_top(CSW_GALIL)
					console_print(id, "[BD] %s %L", WPN_NAMES[CSW_GALIL], id, "MENU_RESET_RECORD")
					return PLUGIN_HANDLED
				}
				case 'l':
				{
					// Reset GLOCK18 record and give console confirmation
					reset_top(CSW_GLOCK18)
					console_print(id, "[BD] %s %L", WPN_NAMES[CSW_GLOCK18], id, "MENU_RESET_RECORD")
					return PLUGIN_HANDLED
				}
			}
		}
		case 'h':
		{
			// Reset HEGRENADE record and give console confirmation
			reset_top(CSW_HEGRENADE)
			console_print(id, "[BD] %s %L", WPN_NAMES[CSW_HEGRENADE], id, "MENU_RESET_RECORD")
			return PLUGIN_HANDLED
		}
		case 'k':
		{
			// Reset KNIFE record and give console confirmation
			reset_top(CSW_KNIFE)
			console_print(id, "[BD] %s %L", WPN_NAMES[CSW_KNIFE], id, "MENU_RESET_RECORD")
			return PLUGIN_HANDLED
		}
		case 'm':
		{
			switch (arg[1])
			{
				case '2':
				{
					// Reset M249 record and give console confirmation
					reset_top(CSW_M249)
					console_print(id, "[BD] %s %L", WPN_NAMES[CSW_M249], id, "MENU_RESET_RECORD")
					return PLUGIN_HANDLED
				}
				case '3':
				{
					// Reset M3 record and give console confirmation
					reset_top(CSW_M3)
					console_print(id, "[BD] %s %L", WPN_NAMES[CSW_M3], id, "MENU_RESET_RECORD")
					return PLUGIN_HANDLED
				}
				case '4':
				{
					// Reset M4A1 record and give console confirmation
					reset_top(CSW_M4A1)
					console_print(id, "[BD] %s %L", WPN_NAMES[CSW_M4A1], id, "MENU_RESET_RECORD")
					return PLUGIN_HANDLED
				}
				case 'a':
				{
					// Reset MAC10 record and give console confirmation
					reset_top(CSW_MAC10)
					console_print(id, "[BD] %s %L", WPN_NAMES[CSW_MAC10], id, "MENU_RESET_RECORD")
					return PLUGIN_HANDLED
				}
				case 'p':
				{
					// Reset MP5NAVY record and give console confirmation
					reset_top(CSW_MP5NAVY)
					console_print(id, "[BD] %s %L", WPN_NAMES[CSW_MP5NAVY], id, "MENU_RESET_RECORD")
					return PLUGIN_HANDLED
				}
			}
		}
		case 'p':
		{
			switch (arg[1])
			{
				case '2':
				{
					// Reset P228 record and give console confirmation
					reset_top(CSW_P228)
					console_print(id, "[BD] %s %L", WPN_NAMES[CSW_P228], id, "MENU_RESET_RECORD")
					return PLUGIN_HANDLED
				}
				case '9':
				{
					// Reset P90 record and give console confirmation
					reset_top(CSW_P90)
					console_print(id, "[BD] %s %L", WPN_NAMES[CSW_P90], id, "MENU_RESET_RECORD")
					return PLUGIN_HANDLED
				}
			}
		}
		case 's':
		{
			if (arg[1] == 'c')
			{
				// Reset SCOUT record and give console confirmation
				reset_top(CSW_SCOUT)
				console_print(id, "[BD] %s %L", WPN_NAMES[CSW_SCOUT], id, "MENU_RESET_RECORD")
				return PLUGIN_HANDLED
			}
			else if (arg[4] == '0')
			{
				// Reset SG550 record and give console confirmation
				reset_top(CSW_SG550)
				console_print(id, "[BD] %s %L", WPN_NAMES[CSW_SG550], id, "MENU_RESET_RECORD")
				return PLUGIN_HANDLED
			}
			else if (arg[4] == '2')
			{
				// Reset SG552 record and give console confirmation
				reset_top(CSW_SG552)
				console_print(id, "[BD] %s %L", WPN_NAMES[CSW_SG552], id, "MENU_RESET_RECORD")
				return PLUGIN_HANDLED
			}
		}
		case 't':
		{
			// Reset TMP record and give console confirmation
			reset_top(CSW_TMP)
			console_print(id, "[BD] %s %L", WPN_NAMES[CSW_TMP], id, "MENU_RESET_RECORD")
			return PLUGIN_HANDLED
		}
		case 'u':
		{
			switch (arg[1])
			{
				case 's':
				{
					// Reset USP record and give console confirmation
					reset_top(CSW_USP)
					console_print(id, "[BD] %s %L", WPN_NAMES[CSW_USP], id, "MENU_RESET_RECORD")
					return PLUGIN_HANDLED
				}
				case 'm':
				{
					// Reset UMP45 record and give console confirmation
					reset_top(CSW_UMP45)
					console_print(id, "[BD] %s %L", WPN_NAMES[CSW_UMP45], id, "MENU_RESET_RECORD")
					return PLUGIN_HANDLED
				}
			}
		}
		case 'x':
		{
			// Reset XM1014 record and give console confirmation
			reset_top(CSW_XM1014)
			console_print(id, "[BD] %s %L", WPN_NAMES[CSW_XM1014], id, "MENU_RESET_RECORD")
			return PLUGIN_HANDLED
		}
	}
	
	// Retrieve integer arguments
	new weapon
	weapon = str_to_num(arg)
	
	// Switch integer
	if (!is_ignore_weapon_id(weapon) && weapon > 0 && weapon < 31)
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
	if (!get_pcvar_num(cvar_GrenadeDamage))
		len += formatex(menu[len], charsmax(menu) - len, "\d3. %L [%L]^n", id, "MENU_GRENADE", id, "MENU_OFF")
	else if (g_iShowGrenadeHud[id])
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
			if (g_iGrenadeColor[id][COLOR_STYLE])
				len += formatex(menu[len], charsmax(menu) - len, "\r2.\w %L\y [%L]^n", id, "MENU_DYNAMIC_STYLE", id, "MENU_ON")
			else
				len += formatex(menu[len], charsmax(menu) - len, "\r2.\w %L\y [%L]^n", id, "MENU_DYNAMIC_STYLE", id, "MENU_OFF")
			
			// 3. Position
			len += formatex(menu[len], charsmax(menu) - len, "\r3.\w %L^n", id, "MENU_DYNAMIC_POSI")
			
			// 4. Holdtime
			len += formatex(menu[len], charsmax(menu) - len, "\r4.\w %L\y [%.1f %L]^n^n", id, "MENU_DYNAMIC_TIME", g_flGrenadeTime[id], id, "MENU_SECONDS")
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
			len += formatex(menu[len], charsmax(menu) - len, "\y%L \w[X: %.2f - Y: %.2f]^n^n", id, "MENU_DYNAMIC_POSI", g_flGrenadePosition_X[id], g_flGrenadePosition_Y[id])
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
			len += formatex(menu[len], charsmax(menu) - len, "\y%L \w[%.1f %L]^n^n", id, "MENU_DYNAMIC_TIME", g_flGrenadeTime[id], id, "MENU_SECONDS")
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
	for (weapon = 0; weapon <= CSW_P90; weapon++)
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
	len += format(buffer[len], charsmax(buffer) - len, "%7s %-22.22s %6s %4s %5s^n", "Weapon", "Nick", "Damage", "Hits", "Yours")
	
	if (get_pcvar_num(cvar_MotdSort))
	{
		// most damage sorting methode
		for (new j = CSW_P228; j <= CSW_P90; j++)
			g_iRecord[j] = g_iCachedDamage[j]
		
		new record
		for (new i = CSW_P228; i <= MOTD_MAX_WEAPONS; i++)
		{
			record = get_record()
			
			if (record)
				len += format(buffer[len], charsmax(buffer) - len, "%7s %-22.22s %6i %4i %5s^n",
				WPN_SHORTNAMES[record], g_szCachedNames[record], g_iCachedDamage[record], g_iCachedHits[record],
				(equali(g_szPlayerName[id], g_szCachedNames[record])) ? " *" : "")
		}
	}
	else
	{
		for (new i = CSW_P228; i <= CSW_P90; i++)
		{
			if (is_ignore_weapon_id(i)) continue
			
			len += format(buffer[len], charsmax(buffer) - len, "%7s %-22.22s %6i %4i %5s^n",
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
	len += format(buffer[len], charsmax(buffer) - len, "%7s %6s %4s %5s^n", "Weapon", "Damage", "Hits", "Top")
	
	if (get_pcvar_num(cvar_MotdSort))
	{
		// most damage sorting methode
		for (new j = CSW_P228; j <= CSW_P90; j++)
			g_iRecord[j] = g_iPersonalDamage[other][j]
		
		new record
		for (new i = CSW_P228; i <= MOTD_MAX_WEAPONS; i++)
		{
			record = get_record()
			
			if (record)
				len += format(buffer[len], charsmax(buffer) - len, "%7s %6i %4i %5s^n",
				WPN_SHORTNAMES[record], g_iPersonalDamage[other][record], g_iPersonalHits[other][record],
				(g_iPersonalDamage[other][record] == g_iCachedDamage[record]) ? " *" : "")
		}
	}
	else
	{
		for (new i = CSW_P228; i <= CSW_P90; i++)
		{
			if (is_ignore_weapon_id(i)) continue
			
			len += format(buffer[len], charsmax(buffer) - len, "%7s %6i %4i %5s^n",
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
			if (get_pcvar_num(cvar_GrenadeDamage))
				g_iShowGrenadeHud[id] = !(g_iShowGrenadeHud[id])
			
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
				colored_print(id, "^x04[BD]^x01 %L", id, "BD_NOT_ACCESS")
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
			colored_print(id, "^x04[BD]^x01 %L", id, "MENU_SAVED")
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
				case 2: g_iGrenadeColor[id][COLOR_STYLE] = !(g_iGrenadeColor[id][COLOR_STYLE]) // Grenade
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
					g_iGrenadeColor[id][COLOR_RED] = 200
					g_iGrenadeColor[id][COLOR_GREEN] = g_iGrenadeColor[id][COLOR_BLUE] = 0
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
					g_iGrenadeColor[id][COLOR_RED] = g_iGrenadeColor[id][COLOR_BLUE] = 0
					g_iGrenadeColor[id][COLOR_GREEN] = 200
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
					g_iGrenadeColor[id][COLOR_RED] = g_iGrenadeColor[id][COLOR_GREEN] = 0
					g_iGrenadeColor[id][COLOR_BLUE] = 200
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
					g_iGrenadeColor[id][COLOR_RED] = g_iGrenadeColor[id][COLOR_GREEN] = 200
					g_iGrenadeColor[id][COLOR_BLUE] = 0
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
					g_iGrenadeColor[id][COLOR_RED] = 0
					g_iGrenadeColor[id][COLOR_GREEN] = g_iGrenadeColor[id][COLOR_BLUE] = 200
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
				case 2: g_iGrenadeColor[id][COLOR_RED] = g_iGrenadeColor[id][COLOR_GREEN] = g_iGrenadeColor[id][COLOR_BLUE] = 200 // Grenade
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
					if (g_flGrenadePosition_Y[id] <= -1.0)
						g_flGrenadePosition_Y[id] = 1.0 - type
					else if (g_flGrenadePosition_Y[id] < 0.01)
						g_flGrenadePosition_Y[id] = -1.0
					else if (g_flGrenadePosition_Y[id] - type <= 0.0)
						g_flGrenadePosition_Y[id] = 0.0
					else
						g_flGrenadePosition_Y[id] -= type
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
					if (g_flGrenadePosition_Y[id] > 0.99)
						g_flGrenadePosition_Y[id] = -1.0
					else if (g_flGrenadePosition_Y[id] <= -1.0)
						g_flGrenadePosition_Y[id] = 0.0 + type
					else if (g_flGrenadePosition_Y[id] + type >= 1.0)
						g_flGrenadePosition_Y[id] = 1.0
					else
						g_flGrenadePosition_Y[id] += type
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
					if (g_flGrenadePosition_X[id] > 0.99)
						g_flGrenadePosition_X[id] = -1.0
					else if (g_flGrenadePosition_X[id] <= -1.0)
						g_flGrenadePosition_X[id] = 0.0 + type
					else if (g_flGrenadePosition_X[id] + type >= 1.0)
						g_flGrenadePosition_X[id] = 1.0
					else
						g_flGrenadePosition_X[id] += type
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
					if (g_flGrenadePosition_X[id] <= -1.0)
						g_flGrenadePosition_X[id] = 1.0 - type
					else if (g_flGrenadePosition_X[id] < 0.01)
						g_flGrenadePosition_X[id] = -1.0
					else if (g_flGrenadePosition_X[id] - type <= 0.0)
						g_flGrenadePosition_X[id] = 0.0
					else
						g_flGrenadePosition_X[id] -= type
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
					if (g_flGrenadeTime[id] + type >= 15.0)
						g_flGrenadeTime[id] = 15.0
					else
						g_flGrenadeTime[id] += type
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
					if (g_flGrenadeTime[id] - type <= 0.1)
						g_flGrenadeTime[id] = 0.1
					else
						g_flGrenadeTime[id] -= type
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
		colored_print(id, "^x04[BD]^x01 %L %L", id, "MENU_RESET_ALL", id, "MENU_RESET_RECORD")
	}
	else
	{
		reset_top(weapon)
		colored_print(id, "^x04[BD]^x01 %s %L", WPN_NAMES[weapon], id, "MENU_RESET_RECORD")
	}
	
	menu_destroy(menuid)
	show_menu_admin(id)
	return PLUGIN_HANDLED
}

/*================================================================================
 [Other Functions and Tasks]
=================================================================================*/

public reset_atk2_knife(taskid)
{
	// Not Connected
	if (!g_bIsConnected[ID_KNIFE]) return
	
	// reset knife atk2 var
	g_bAttack2Knife[ID_KNIFE] = false
}

public damage_deal(taskid)
{
	// Not Connected
	if (!g_bIsConnected[ID_DAMAGE]) return
	
	// Record trial finished!
	g_bWhileRecordTask[ID_DAMAGE] = false
	
	// non-steam player...
	if (!g_iAuthorized[ID_DAMAGE])
	{
		reset_record_vars(ID_DAMAGE)
		return
	}
	
	// Zombie Plague Compatibility
	#if defined _zombieplague_included || defined _zombie_plague_advance_included
	
	if (!get_pcvar_num(cvar_zpNemesisDamage) && zp_get_user_nemesis(ID_DAMAGE) || !get_pcvar_num(cvar_zpSurvivorDamage) && zp_get_user_survivor(ID_DAMAGE))
	{
		reset_record_vars(ID_DAMAGE)
		return
	}
	
	#endif
	
	// Zombie Plague Advance Compatibility
	#if defined _zombie_plague_advance_included
	
	if (!get_pcvar_num(cvar_zpAssassinDamage) && zp_get_user_assassin(ID_DAMAGE) || !get_pcvar_num(cvar_zpSniperDamage) && zp_get_user_sniper(ID_DAMAGE))
	{
		reset_record_vars(ID_DAMAGE)
		return
	}
	
	#endif
	
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
			colored_print(ID_DAMAGE, "^x04[BD]^x01 %L", ID_DAMAGE, "BD_PERSONAL_RECORD", g_iPersonalDamage[ID_DAMAGE][weapon], WPN_NAMES[weapon], g_iPersonalHits[ID_DAMAGE][weapon])
		
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
			colored_print(0, "^x04[BD]^x01 %L", LANG_PLAYER, "BD_RECORD", g_szCachedNames[weapon], g_iCachedDamage[weapon], WPN_NAMES[weapon], g_iCachedHits[weapon])
		
		// Save new Record
		if (get_pcvar_num(cvar_SaveStats))
			save_top()
	}
	
	// Clear record Player vars
	reset_record_vars(ID_DAMAGE)
}

public damage_deal_he(taskid)
{
	// Not Connected
	if (!g_bIsConnected[ID_GRENADE]) return
	
	// Display HUD damage?
	show_grenade_damage(ID_GRENADE)
	
	// Not Authorized
	if (!g_iAuthorized[ID_GRENADE])
	{
		reset_record_vars(ID_GRENADE, 1)
		return
	}
	
	// Zombie Plague Compatibility
	#if defined _zombieplague_included || defined _zombie_plague_advance_included
	
	if (!get_pcvar_num(cvar_zpNemesisDamage) && zp_get_user_nemesis(ID_GRENADE) || !get_pcvar_num(cvar_zpSurvivorDamage) && zp_get_user_survivor(ID_GRENADE))
	{
		reset_record_vars(ID_GRENADE, 1)
		return
	}
	
	#endif
	
	// Zombie Plague Advance Compatibility
	#if defined _zombie_plague_advance_included
	
	if (!get_pcvar_num(cvar_zpAssassinDamage) && zp_get_user_assassin(ID_GRENADE) || !get_pcvar_num(cvar_zpSniperDamage) && zp_get_user_sniper(ID_GRENADE))
	{
		reset_record_vars(ID_GRENADE, 1)
		return
	}
	
	#endif
	
	// Made a new Personal record
	if (g_iDamageDealt[ID_GRENADE] > g_iPersonalDamage[ID_GRENADE][CSW_HEGRENADE])
	{
		// Set players name, damage done and hits to cached records
		g_iPersonalDamage[ID_GRENADE][CSW_HEGRENADE] = clamp(g_iGrenadeDamageDealt[ID_GRENADE], 1, 999999)
		g_iPersonalHits[ID_GRENADE][CSW_HEGRENADE] = clamp(g_iGrenadeHits[ID_GRENADE], 1, 9999)
		g_iPersonalResets[ID_GRENADE][CSW_HEGRENADE] = g_iCachedResets[CSW_HEGRENADE]
		
		// Display new Record in Chat
		if (get_pcvar_num(cvar_ChatPersonal))
			colored_print(ID_GRENADE, "^x04[BD]^x01 %L", ID_GRENADE, "BD_PERSONAL_RECORD", g_iPersonalDamage[ID_GRENADE][CSW_HEGRENADE], WPN_NAMES[CSW_HEGRENADE], g_iPersonalHits[ID_GRENADE][CSW_HEGRENADE])
		
		// Save new Record
		if (get_pcvar_num(cvar_SaveStatsPersonal))
			save_personal_top(ID_GRENADE)
	}
	
	// Made a new Record
	if (g_iGrenadeDamageDealt[ID_GRENADE] > g_iCachedDamage[CSW_HEGRENADE])
	{
		// Set players name, damage done and hits to cached records
		g_szCachedNames[CSW_HEGRENADE] = g_szPlayerName[ID_GRENADE]
		g_szCachedSteamIDs[CSW_HEGRENADE] = g_szSteamID[ID_GRENADE]
		g_iCachedDamage[CSW_HEGRENADE] = clamp(g_iGrenadeDamageDealt[ID_GRENADE], 1, 999999)
		g_iCachedHits[CSW_HEGRENADE] = clamp(g_iGrenadeHits[ID_GRENADE], 1, 9999)
		
		// Display new Record in Chat
		if (get_pcvar_num(cvar_ChatWeapon))
			colored_print(0, "^x04[BD]^x01 %L", LANG_PLAYER, "BD_RECORD", g_szCachedNames[CSW_HEGRENADE], g_iCachedDamage[CSW_HEGRENADE], WPN_NAMES[CSW_HEGRENADE], g_iCachedHits[CSW_HEGRENADE])
		
		// Save new Record
		if (get_pcvar_num(cvar_SaveStats))
			save_top()
	}
	
	// Clear Player vars
	reset_record_vars(ID_GRENADE, 1)
}

public register_ham_czbots(id)
{
	// Make sure it's a CZ bot and it's still connected
	if (g_bHamCzBots || !g_bIsConnected[id] || !get_pcvar_num(cvar_BotQuota)) return
	
	RegisterHamFromEntity(Ham_TakeDamage, id, "fwd_TakeDamage_Post", 1)
	RegisterHamFromEntity(Ham_TraceAttack, id, "fwd_TraceAttack")
	
	// Ham forwards for CZ bots succesfully registered
	g_bHamCzBots = true
}

get_record()
{
	new dmg = 0, j = 0
	
	for (new i = CSW_P228; i <= CSW_P90; i++)
	{
		if (is_ignore_weapon_id(i)) continue
		
		if (g_iRecord[i] >= dmg)
		{
			dmg = g_iRecord[i]
			j = i
		}
	}
	g_iRecord[j] = -1
	
	return j;
}

replace_windows_letters(const id, Name[], const len)
{
	copy(Name, len, g_szPlayerName[id])
	replace_all(Name, len, "\", "_")
	replace_all(Name, len, "/", "_")
	replace_all(Name, len, ":", "_")
	replace_all(Name, len, "*", "_")
	replace_all(Name, len, "?", "_")
	replace_all(Name, len, "^"", "_")
	replace_all(Name, len, "<", "_")
	replace_all(Name, len, ">", "_")
	replace_all(Name, len, "|", "_")
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
	
	// file not open
	if (!file) return
	
	while (!feof(file))
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
	fclose(file)
}

/* is_linux_server() */

load_personal_top(id)
{
	// Get config file
	// Not allowed letters (windows)         \ / : * ? " < > |
	// STEAM_0:X:XXXXXX
	new szPersonalRecord[128]
	if (get_pcvar_num(cvar_SvLan) || g_bIsBot[id])
	{
		new Name[32]
		replace_windows_letters(id, Name, charsmax(Name))
		format(szPersonalRecord, charsmax(szPersonalRecord), "%s/bd_records/%s.ini", g_szDataDir, Name)
	}
	else
	{
		format(szPersonalRecord, charsmax(szPersonalRecord), "%s/bd_records/%s.ini", g_szDataDir, g_szSteamID[id])
		replace_all(szPersonalRecord, charsmax(szPersonalRecord), ":", "_")
	}
	
	// File not present
	if (!file_exists(szPersonalRecord))
	{
		for (new i = CSW_P228; i <= CSW_P90; i++)
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
	
	// file not open
	if (!file) return
	
	while (!feof(file))
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
	fclose(file)
}

save_top()
{
	// Record file exists, delete it!
	if (file_exists(g_szRecordFile)) delete_file(g_szRecordFile)
	
	// Open not exists config file for appending data (this create a new one)
	new file = fopen(g_szRecordFile, "wt"), buffer[512]
	
	// file not open
	if (!file) return
	
	// Add any configuration from the player
	for (new section = CSW_P228; section <= CSW_P90; section++)
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
	// Not allowed letters (windows)         \ / : * ? " < > |
	// STEAM_0:X:XXXXXX
	new szPersonalRecord[128]
	if (get_pcvar_num(cvar_SvLan) || g_bIsBot[id])
	{
		new Name[32]
		replace_windows_letters(id, Name, charsmax(Name))
		format(szPersonalRecord, charsmax(szPersonalRecord), "%s/bd_records/%s.ini", g_szDataDir, Name)
	}
	else
	{
		format(szPersonalRecord, charsmax(szPersonalRecord), "%s/bd_records/%s.ini", g_szDataDir, g_szSteamID[id])
		replace_all(szPersonalRecord, charsmax(szPersonalRecord), ":", "_")
	}
	
	// config file exists, delete it!
	if (file_exists(szPersonalRecord)) delete_file(szPersonalRecord)
	
	// Open not exists config file for appending data (this create a new one)
	new file = fopen(szPersonalRecord, "wt"), buffer[512]
	
	// file not open
	if (!file) return
	
	// Add any configuration from the player
	for (new section = CSW_P228; section <= CSW_P90; section++)
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
		for (new i = CSW_P228; i <= CSW_P90; i++)
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
		for (new i = CSW_P228; i <= CSW_P90; i++)
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
			
			for (new i = CSW_P228; i <= CSW_P90; i++)
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
	
	colored_print(id, "^x04[BD]^x01 %L", id, "BD_INFO")
}

set_player_vars(id)
{
	g_iAuthorized[id] = g_iMenuType[id] = 0
	g_iDamageDealt[id] = g_iGrenadeDamageDealt[id] = 0
	g_iWeaponUse[id] = g_iWeaponEntity[id] = 0
	g_iHits[id] = g_iGrenadeHits[id] = 0
	g_iPreHealth[id] = g_iPostHealth[id] = 0
	g_bAttack2Knife[id] = g_bWhileRecordTask[id] = g_bGrenadeWallVisible[id] = g_bIsBot[id] = false
}

load_hud_vars(id)
{
	// Cache record file
	// Not allowed letters (windows)         \ / : * ? " < > |
	// STEAM_0:X:XXXXXX
	new szPersonalConfig[128]
	if (get_pcvar_num(cvar_SvLan))
	{
		new Name[32]
		replace_windows_letters(id, Name, charsmax(Name))
		format(szPersonalConfig, charsmax(szPersonalConfig), "%s/bd_configs/%s.ini", g_szDataDir, Name)
	}
	else
	{
		format(szPersonalConfig, charsmax(szPersonalConfig), "%s/bd_configs/%s.ini", g_szDataDir, g_szSteamID[id])
		replace_all(szPersonalConfig, charsmax(szPersonalConfig), ":", "_")
	}
	
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
	
	// file not open
	if (!file) return
	
	while (!feof(file))
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
					g_iShowGrenadeHud[id] = str_to_num(value)
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
					g_iGrenadeColor[id][COLOR_RED] = str_to_num(value)
				else if (equal(key, "GRENADE GREEN"))
					g_iGrenadeColor[id][COLOR_GREEN] = str_to_num(value)
				else if (equal(key, "GRENADE BLUE"))
					g_iGrenadeColor[id][COLOR_BLUE] = str_to_num(value)
				else if (equal(key, "GRENADE STYLE"))
					g_iGrenadeColor[id][COLOR_STYLE] = str_to_num(value)
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
					g_flGrenadePosition_X[id] = str_to_float(value)
				else if (equal(key, "GRENADE Y"))
					g_flGrenadePosition_Y[id] = str_to_float(value)
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
					g_flGrenadeTime[id] = str_to_float(value)
				else if (equal(key, "TAKE"))
					g_flTakeTime[id] = str_to_float(value)
			}
		}
	}
	fclose(file)
}

save_hud_vars(id)
{
	// Get config file
	// Not allowed letters (windows)         \ / : * ? " < > |
	// STEAM_0:X:XXXXXX
	new szPersonalConfig[128]
	if (get_pcvar_num(cvar_SvLan))
	{
		new Name[32]
		replace_windows_letters(id, Name, charsmax(Name))
		format(szPersonalConfig, charsmax(szPersonalConfig), "%s/bd_configs/%s.ini", g_szDataDir, Name)
	}
	else
	{
		format(szPersonalConfig, charsmax(szPersonalConfig), "%s/bd_configs/%s.ini", g_szDataDir, g_szSteamID[id])
		replace_all(szPersonalConfig, charsmax(szPersonalConfig), ":", "_")
	}
	
	// config file exists, delete it!
	if (file_exists(szPersonalConfig)) delete_file(szPersonalConfig)
	
	// Open not exists config file for appending data (this create a new one)
	new file = fopen(szPersonalConfig, "wt"), buffer[512]
	
	// file not open
	if (!file) return
	
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
				g_iShowSingleHud[id], g_iShowMultipleHud[id], g_iShowGrenadeHud[id], g_iShowTakeHud[id])
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
				g_iGrenadeColor[id][COLOR_RED], g_iGrenadeColor[id][COLOR_GREEN], g_iGrenadeColor[id][COLOR_BLUE], g_iGrenadeColor[id][COLOR_STYLE])
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
				g_flGrenadePosition_X[id], g_flGrenadePosition_Y[id])
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
				g_flSingleTime[id], g_flMultipleTime[id], g_flGrenadeTime[id], g_flTakeTime[id])
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
	
	ClearSyncHud(id, g_HudSyncGrenade)
	set_hudmessage(g_iGrenadeColor[id][COLOR_RED], g_iGrenadeColor[id][COLOR_GREEN], g_iGrenadeColor[id][COLOR_BLUE], g_flGrenadePosition_X[id], g_flGrenadePosition_Y[id], g_iGrenadeColor[id][COLOR_STYLE], 0.0, g_flGrenadeTime[id], 1.0, 1.0, -1)
	ShowSyncHudMsg(id, g_HudSyncGrenade, "%L", id, "MENU_GRENADE_TITLE")
}

set_hud_vars(id)
{
	g_iShowSingleHud[id] = 1
	g_iShowMultipleHud[id] = 1
	g_iShowGrenadeHud[id] = 1
	g_iShowTakeHud[id] = 1
	
	g_iSingleColor[id][COLOR_RED] = 0
	g_iMultipleColor[id][COLOR_RED] = 0
	g_iGrenadeColor[id][COLOR_RED] = 200
	g_iTakeColor[id][COLOR_RED] = 200
	g_iSingleColor[id][COLOR_GREEN] = 200
	g_iMultipleColor[id][COLOR_GREEN] = 200
	g_iGrenadeColor[id][COLOR_GREEN] = 0
	g_iTakeColor[id][COLOR_GREEN] = 0
	g_iSingleColor[id][COLOR_BLUE] = 0
	g_iMultipleColor[id][COLOR_BLUE] = 0
	g_iGrenadeColor[id][COLOR_BLUE] = 0
	g_iTakeColor[id][COLOR_BLUE] = 0
	
	g_flMultiplePosition_X[id] = 0.30
	g_flMultiplePosition_Y[id] = 0.35
	g_flSinglePosition_X[id] = 0.30
	g_flSinglePosition_Y[id] = 0.45
	g_flTakePosition_X[id] = 0.30
	g_flTakePosition_Y[id] = 0.55
	g_flGrenadePosition_X[id] = 0.30
	g_flGrenadePosition_Y[id] = 0.65
	
	g_flSingleTime[id] = 2.50
	g_flMultipleTime[id] = 2.50
	g_flGrenadeTime[id] = 2.50
	g_flTakeTime[id] = 2.50
}

reset_record_vars(id, grenade = 0)
{
	if (grenade)
	{
		g_iGrenadeDamageDealt[id] = g_iGrenadeHits[id] = 0
		g_bGrenadeWallVisible[id] = false
	}
	else
		g_iDamageDealt[id] = g_iHits[id] = 0
}

show_grenade_damage(id)
{
	// Enable grenade damage?
	if (!get_pcvar_num(cvar_GrenadeDamage)) return
	
	// Static Hud Damage Wall num
	static HudDamageWall
	HudDamageWall = get_pcvar_num(cvar_HudDamageWall)
	
	switch (get_pcvar_num(cvar_HudDamage))
	{
		case 2: // Admin
		{
			if (!g_iShowGrenadeHud[id] || !user_has_flag(id, ACCESS_HUD) || (!HudDamageWall && !g_bGrenadeWallVisible[id])) return
			
			ClearSyncHud(id, g_HudSyncGrenade)
			set_hudmessage(g_iGrenadeColor[id][COLOR_RED], g_iGrenadeColor[id][COLOR_GREEN], g_iGrenadeColor[id][COLOR_BLUE], g_flGrenadePosition_X[id], g_flGrenadePosition_Y[id], g_iGrenadeColor[id][COLOR_STYLE], 0.0, g_flGrenadeTime[id],  1.0, 1.0, -1)
			ShowSyncHudMsg(id, g_HudSyncGrenade, "%i", g_iGrenadeDamageDealt[id])
		}
		case 1: // Player
		{
			if (!g_iShowGrenadeHud[id] || (HudDamageWall == 2 && !user_has_flag(id, ACCESS_HUD) && !g_bGrenadeWallVisible[id]) || (!HudDamageWall && !g_bGrenadeWallVisible[id])) return
			
			ClearSyncHud(id, g_HudSyncGrenade)
			set_hudmessage(g_iGrenadeColor[id][COLOR_RED], g_iGrenadeColor[id][COLOR_GREEN], g_iGrenadeColor[id][COLOR_BLUE], g_flGrenadePosition_X[id], g_flGrenadePosition_Y[id], g_iGrenadeColor[id][COLOR_STYLE], 0.0, g_flGrenadeTime[id],  1.0, 1.0, -1)
			ShowSyncHudMsg(id, g_HudSyncGrenade, "%i", g_iGrenadeDamageDealt[id])
		}
	}
}

/*================================================================================
 [Message Hooks]
=================================================================================*/

public message_damage(msg_id, msg_dest, msg_entity)
{
	// set damage take (bugfix)
	set_pev(msg_entity, pev_dmg_take, 0.0)
}

public message_health(msg_id, msg_dest, msg_entity)
{
	// Get player's health
	static health
	health = get_msg_arg_int(1)
	
	if (health > 0)
		g_iPreHealth[msg_entity] = health
}

colored_print(target, const message[], any:...)
{
	static buffer[512], i, argscount
	argscount = numargs()
	
	// Send to everyone
	if (!target)
	{
		static player
		for (player = 1; player <= g_iMaxPlayers; player++)
		{
			// Not connected
			if (!g_bIsConnected[player]) continue
			
			// Remember changed arguments
			static changed[5], changedcount // [5] = max LANG_PLAYER occurencies
			changedcount = 0
			
			// Replace LANG_PLAYER with player id
			for (i = 2; i < argscount; i++)
			{
				if (getarg(i) == LANG_PLAYER)
				{
					setarg(i, 0, player)
					changed[changedcount] = i
					changedcount++
				}
			}
			
			// Format message for player
			vformat(buffer, charsmax(buffer), message, 3)
			
			// Send it
			message_begin(MSG_ONE_UNRELIABLE, g_msgSayText, _, player)
			write_byte(player)
			write_string(buffer)
			message_end()
			
			// Replace back player id's with LANG_PLAYER
			for (i = 0; i < changedcount; i++)
				setarg(changed[i], 0, LANG_PLAYER)
		}
	}
	// Send to specific target
	else
	{
		// Format message for player
		vformat(buffer, charsmax(buffer), message, 3)
		
		// Send it
		message_begin(MSG_ONE, g_msgSayText, _, target)
		write_byte(target)
		write_string(buffer)
		message_end()
	}
}

/*================================================================================
 [Stocks]
=================================================================================*/

stock ham_cs_get_weapon_ent_owner(ent)
{
	if (pev_valid(ent) != FM_PDATA_SAFE)
		return 0;
	
	return get_pdata_cbase(ent, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS);
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
