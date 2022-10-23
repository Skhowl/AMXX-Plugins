/*================================================================================
	
		*************************************************************
		*********** [Zombie Plague Burning Zombie 1.0.0] ************
		*************************************************************
	
	----------------------
	-*- Licensing Info -*-
	----------------------
	
	Zombie Plague Burning Zombie
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
	
	Zombie are all time burning, but this is his special ability.
	If u get in water u become zombie madness, but a cooldown is
	controlled u don't made a madness spam. If the zombie is in
	water and have cooldown on madness, he gets damage. After a
	frost grenade get madness too.
	
	---------------------
	-*- Configuration -*-
	---------------------
	
	zp_burning_cooldown 15.0 // Cooldown befor you get next madness (in water)
	zp_burning_water_dmg 5 // water damage (every 0.2 secs)
	
	--------------------
	-*- Requirements -*-
	--------------------
	
	* Mods: Counter-Strike 1.6 or Condition Zero
	* Metamod: Version 1.19 or later
	* AMXX: Version 1.8.0 or later
	* Module: fakemeta, hamsandwich
	
	-----------------
	-*- Changelog -*-
	-----------------
	
	* v1.0.0:
	   - Initial release Privat (30th Jul 2010)
	   - Initial release Alliedmodders (4th Feb 2011)
	
=================================================================================*/

#include <amxmodx>
#include <fakemeta>

#if AMXX_VERSION_NUM < 180
	#assert AMX Mod X v1.8.0 or later library required!
#endif

#include <hamsandwich>

/*================================================================================
 [Zombie Plague Checking]
=================================================================================*/

// try include "zombie_plague.inc"

#tryinclude <zombieplague>

#if !defined _zombieplague_included
	#assert zombieplague.inc library required!
#endif

/*================================================================================
 [Constants, Offsets, Macros]
=================================================================================*/

// Plugin Version
new const PLUGIN_VERSION[] = "1.0.0"

// Burning Zombie
new const zclass_name[] = { "Burning Zombie" }
new const zclass_info[] = { "HP- Jump+ Knockback++" }
new const zclass_model[] = { "zombie_source" }
new const zclass_clawmodel[] = { "v_knife_zombie.mdl" }
const zclass_health = 1500
const zclass_speed = 190
const Float:zclass_gravity = 0.80
const Float:zclass_knockback = 1.75

new const sprite_flame[] = { "sprites/flame.spr" }

const ZP_MADNESS_ID = 2
const TASK_MADNESS = 4529

#define ID_MADNESS (taskid - TASK_MADNESS)
#define is_InWater(%1) (%1 & FL_INWATER)

/*================================================================================
 [Global Variables]
=================================================================================*/

// Player vars
new g_bBurning[33]
new g_bMadness[33]
new Float:g_flLastMadness[33]

// Game vars
new g_iBurningIndex
new g_iMadnessCounter
new g_iMaxPlayers

// Message IDs vars
new g_msgSayText

// Sprites
new g_iFlame

// Cvar pointers
new cvar_zpMadnessDuration, cvar_Cooldown, cvar_zpMadnessCounter,
cvar_WaterDamage

/*================================================================================
 [Precache and Init]
=================================================================================*/

public plugin_precache()
{
	register_plugin("[ZP] Class : Burning Zombie", PLUGIN_VERSION, "schmurgel1983")
	
	g_iBurningIndex = zp_register_zombie_class(zclass_name, zclass_info, zclass_model, zclass_clawmodel, zclass_health, zclass_speed, zclass_gravity, zclass_knockback)
	
	g_iFlame = engfunc(EngFunc_PrecacheModel, sprite_flame)
}

public plugin_init()
{
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	register_event("DeathMsg", "event_player_death", "a")
	
	g_msgSayText = get_user_msgid("SayText")
	
	cvar_Cooldown = register_cvar("zp_burning_cooldown", "15.0")
	cvar_WaterDamage = register_cvar("zp_burning_water_dmg", "5")
	
	cvar_zpMadnessDuration = get_cvar_pointer("zp_extra_madness_duration")
	cvar_zpMadnessCounter = get_cvar_pointer("zp_extra_madness_limit")
	register_cvar("Burning_Zombie_version", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY)
	set_cvar_string("Burning_Zombie_version", PLUGIN_VERSION)
	
	g_iMaxPlayers = get_maxplayers()
}

public client_putinserver(id) reset_cvars(id)

public client_disconnected(id) reset_cvars(id)

/*================================================================================
 [Main Forwards]
=================================================================================*/

public event_round_start()
{
	g_iMadnessCounter = 0
	
	for (new id = 1; id <= g_iMaxPlayers; id++)
		reset_cvars(id)
}

public event_player_death() reset_cvars(read_data(2))

public zp_user_infected_post(id, infector, nemesis)
{
	if (zp_get_user_zombie_class(id) == g_iBurningIndex && !nemesis)
	{
		g_bBurning[id] = true
		g_flLastMadness[id] = get_gametime()
		set_task(0.2, "burning_flame", id, _, _, "b")
	}
}

public zp_user_humanized_post(id, survivor) reset_cvars(id)

public zp_user_unfrozen(id)
{
	if (!g_bBurning[id] || g_bMadness[id] || !is_user_alive(id)) return
	
	if (set_user_madness(id))
		colored_print(id, "^x04[Burning Zombie]^x01 You were frozen and now fall into madness.")
}

/*================================================================================
 [Other Functions]
=================================================================================*/

reset_cvars(id)
{
	remove_task(id)
	remove_task(id+TASK_MADNESS)
	
	g_bBurning[id] = false
	g_bMadness[id] = false
	g_flLastMadness[id] = get_gametime()
}

bool:set_user_madness(id)
{
	if (g_iMadnessCounter < get_pcvar_num(cvar_zpMadnessCounter) && zp_force_buy_extra_item(id, ZP_MADNESS_ID, 1))
	{
		g_iMadnessCounter++
		
		g_bMadness[id] = true
		g_flLastMadness[id] = get_gametime() + get_pcvar_float(cvar_Cooldown)
		
		set_task(0.1+get_pcvar_float(cvar_zpMadnessDuration), "ending_madness", id+TASK_MADNESS)
		
		return true;
	}
	return false;
}

public burning_flame(id)
{
	if (!g_bBurning[id] || !is_user_alive(id))
	{
		reset_cvars(id)
		return
	}
	
	static origin[3]
	get_user_origin(id, origin)
	
	message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
	write_byte(TE_SPRITE) // TE id
	write_coord(origin[0]+random_num(-5, 5)) // x
	write_coord(origin[1]+random_num(-5, 5)) // y
	write_coord(origin[2]+10) // z
	write_short(g_iFlame) // sprite
	write_byte(5) // scale
	write_byte(200) // brightness
	message_end()
	
	if (g_bMadness[id]) return
	
	if (is_InWater(pev(id, pev_flags)))
	{
		fm_set_user_health(id, pev(id, pev_health) - get_pcvar_float(cvar_WaterDamage))
		
		if (get_gametime() < g_flLastMadness[id]) return
		
		if (set_user_madness(id))
			colored_print(id, "^x04[Burning Zombie]^x01 You were in water and now fall into madness.")
	}
}

public ending_madness(taskid)
{
	g_bMadness[ID_MADNESS] = false
}

colored_print(target, const message[], any:...)
{
	static buffer[512]
	vformat(buffer, charsmax(buffer), message, 3)
	
	message_begin(MSG_ONE, g_msgSayText, _, target)
	write_byte(target)
	write_string(buffer)
	message_end()
}

/*================================================================================
 [Stocks]
=================================================================================*/

stock fm_set_user_health(id, Float:health)
{
	(health > 0.0) ? set_pev(id, pev_health, health) : dllfunc(DLLFunc_ClientKill, id);
}
