/*================================================================================
	
		***********************************************
		************ [No Engine Knockback] ************
		***********************************************
	
	----------------------
	-*- Licensing Info -*-
	----------------------
	
	No Engine Knockback
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
	
	This plugin does not remove ZP knockback just the engine knockback.
	The cs/cz engine knockback is little but noticeable.
	
	---------------------
	-*- Configuration -*-
	---------------------
	
	zp_nek_nemesis 1 // Nemesis don't have engine knockback [0-disabled / 1-enabled]
	zp_nek_zombies 0 // Zombies don't have engine knockback [0-disabled / 1-enabled]
	
	--------------------
	-*- Requirements -*-
	--------------------
	
	* Mods: Counter-Strike 1.6 or Condition Zero
	* Metamod: Version 1.21p38 can be downloaded under: https://github.com/Bots-United/metamod-p/releases/tag/v1.21p38
	* AMXX: Version 1.8.2 can be downloaded under: https://www.amxmodx.org/downloads.php
	* Module: fakemeta, hamsandwich
	
=================================================================================*/

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

/*================================================================================
 [Zombie Plague 5.0 Includes]
=================================================================================*/

#include <cs_ham_bots_api>
#include <zp50_class_zombie>
#define LIBRARY_NEMESIS "zp50_class_nemesis"
#include <zp50_class_nemesis>

/*================================================================================
 [Constants, Offsets, Macros]
=================================================================================*/

// Plugin Version
new const PLUGIN_VERSION[] = "1.1.1 (zp50)"

/*================================================================================
 [Global Variables]
=================================================================================*/

// Player vars
new Float:g_flKnockbackPre[33][3] // velocity from your knockback position
new g_bEnabled[33] // disabled engine knockback is enable

// Cvar pointers
new cvar_Nemesis, cvar_Zombies

/*================================================================================
 [Precache and Init]
=================================================================================*/

public plugin_precache()
{
	register_plugin("[ZP50] Addon : No Engine Knockback", PLUGIN_VERSION, "schmurgel1983")
}

public plugin_init()
{
	// HAM Forwards
	RegisterHam(Ham_TakeDamage, "player", "fwd_TakeDamage", false)
	RegisterHamBots(Ham_TakeDamage, "fwd_TakeDamage", false)
	RegisterHam(Ham_TakeDamage, "player", "fwd_TakeDamage_Post", true)
	RegisterHamBots(Ham_TakeDamage, "fwd_TakeDamage_Post", true)
	
	cvar_Nemesis = register_cvar("zp_nek_nemesis", "1")
	cvar_Zombies = register_cvar("zp_nek_zombies", "0")
	
	register_cvar("NoEngineKnockback_version", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY)
	set_cvar_string("NoEngineKnockback_version", PLUGIN_VERSION)
}

public plugin_natives()
{
	set_module_filter("module_filter")
	set_native_filter("native_filter")
}

public module_filter(const module[])
{
	if (equal(module, LIBRARY_NEMESIS))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

/*================================================================================
 [Main Forwards]
=================================================================================*/

// Ham Take Damage Forward
public fwd_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
	if (!g_bEnabled[victim])
		return;
	
	// Get velocity befor engine knockback kicks in
	pev(victim, pev_velocity, g_flKnockbackPre[victim])
}

// Ham Take Damage Post Forward
public fwd_TakeDamage_Post(victim)
{
	if (!g_bEnabled[victim])
		return;
	
	// Restore velocity after engine knockback is added
	set_pev(victim, pev_velocity, g_flKnockbackPre[victim])
}

public zp_fw_core_cure_post(id)
	g_bEnabled[id] = 0;

public zp_fw_core_infect_post(id, attacker)
	g_bEnabled[id] = (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(id)) ? get_pcvar_num(cvar_Nemesis) : get_pcvar_num(cvar_Zombies);
