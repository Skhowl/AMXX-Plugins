/*================================================================================
	
		***********************************************************
		*********** [Zombie Plague Brute Mother 1.1.0] ************
		***********************************************************
	
	----------------------
	-*- Licensing Info -*-
	----------------------
	
	Zombie Plague Brute Mother
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
	
	This Zombie class can heal another Zombies by holding use button (+use).
	You can not heal yourself, but you get ammo packs if enough heals counted.
	CZ bots are all time healing, bots are stupit and don't press +use.
	
	---------------------
	-*- Configuration -*-
	---------------------
	
	zp_mother_interval 0.2 // interval of healing
	zp_mother_amount 10 // heal amount
	zp_mother_range 128 // heal range in cs units
	zp_mother_counter 200 // healed players befor get 1 ammo pack
	
	--------------------
	-*- Requirements -*-
	--------------------
	
	* Game: Counter-Strike 1.6 or Condition Zero
	* Metamod: Version 1.19 or later
	* AMXX: Version 1.8.0 or later
	* Module: fakemeta, hamsandwich
	
	-----------------
	-*- Changelog -*-
	-----------------
	
	* v1.0.0:
	   - Initial release Privat (15th Aug 2010)
	   - Initial release Alliedmodders (3rd Feb 2011)
	
	* v1.1.0:
	   - Added: support CSO In-Game Theme 5.4 or higher
	
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
new const PLUGIN_VERSION[] = "1.1.0"

// Brute Mother
new const zclass_name[] = { "Brute Mother" }
new const zclass_info[] = { "=Balanced= Heal (hold +use)" }
new const zclass_model[] = { "zombie_source" }
new const zclass_clawmodel[] = { "v_knife_zombie.mdl" }
const zclass_health = 1800
const zclass_speed = 190
const Float:zclass_gravity = 1.00
const Float:zclass_knockback = 1.00

/*================================================================================
 [Global Variables]
=================================================================================*/

// Player vars
new g_bZombie[33] // whether player is zombie
new g_bMother[33] // whether player is brute mother
new g_bHealing[33] // whether player is healing
new g_bInRange[33][33] // whether zombie is in range
new Float:g_flMaxHealth[33] // zombie's max health
new g_iHealCounter[33] // brute mother heal counter

// Game vars
new g_iMotherIndex // index from the class
new g_iMaxPlayers // max player counter
new g_bHamCzBots // whether ham forwards are registered for CZ bots

// Cvar pointers
new cvar_Interval, cvar_Amount, cvar_Range, cvar_Counter

// Healing Color
new g_iColor[3] = { 0 , 150 , 0 }

// Player stuff
new g_bIsAlive[33] // whether player is alive
new g_bIsBot[33] // whether player is bot

// Macro
#define is_user_valid_alive(%1)	(1 <= %1 <= g_iMaxPlayers && g_bIsAlive[%1])

/*================================================================================
 [Precache and Init]
=================================================================================*/

public plugin_precache()
{
	register_plugin("[ZP] Class : Brute Mother", PLUGIN_VERSION, "schmurgel1983")
	
	g_iMotherIndex = zp_register_zombie_class(zclass_name, zclass_info, zclass_model, zclass_clawmodel, zclass_health, zclass_speed, zclass_gravity, zclass_knockback)
}

public plugin_init()
{
	register_event("SendAudio", "event_end_round", "a", "2&%!MRAD_terwin", "2&%!MRAD_ctwin", "2&%!MRAD_rounddraw")
	register_event("TextMsg", "event_end_round", "a", "2=#Game_Commencing", "2=#Game_will_restart_in")
	
	RegisterHam(Ham_Spawn, "player", "fwd_PlayerSpawn_Post", 1)
	RegisterHam(Ham_Killed, "player", "fwd_PlayerKilled_Post", 1)
	
	register_forward(FM_PlayerPreThink, "fwd_PlayerPreThink")
	register_forward(FM_AddToFullPack, "fwd_AddToFullPack_Post", 1)
	
	cvar_Interval = register_cvar("zp_mother_interval", "0.2")
	cvar_Amount = register_cvar("zp_mother_amount", "10")
	cvar_Range = register_cvar("zp_mother_range", "128")
	cvar_Counter = register_cvar("zp_mother_counter", "200")
	
	register_cvar("Brute_Mother_version", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY)
	set_cvar_string("Brute_Mother_version", PLUGIN_VERSION)
	
	g_iMaxPlayers = get_maxplayers()
}

public client_putinserver(id)
{
	remove_task(id)
	set_cvars(id)
	
	if (is_user_bot(id))
	{
		g_bIsBot[id] = true
		
		if (!g_bHamCzBots)
			set_task(0.1, "register_ham_czbots", id)
	}
}

public client_disconnected(id)
{
	remove_task(id)
	set_cvars(id)
	g_bIsBot[id] = false
}

/*================================================================================
 [Main Forwards]
=================================================================================*/

public event_end_round()
{
	for (new id = 1; id <= g_iMaxPlayers; id++)
	{
		remove_task(id)
		set_cvars(id)
	}
}

public fwd_PlayerSpawn_Post(id)
{
	if (!is_user_alive(id) || !get_user_team(id)) return
	
	g_bIsAlive[id] = true
}

public fwd_PlayerKilled_Post(victim, attacker, gib)
{
	g_bIsAlive[victim] = false
	remove_task(victim)
	set_cvars(victim)
}

public fwd_PlayerPreThink(id)
{
	if (!g_bMother[id] || !g_bIsAlive[id] || g_bIsBot[id]) return
	
	g_bHealing[id] = (pev(id, pev_button) & IN_USE) ? true : false;
}

public fwd_AddToFullPack_Post(es_handle, e, ent, host, flags, player, pSet)
{
	if (!player || !g_bZombie[host] || !g_bZombie[ent]) return FMRES_IGNORED
	
	if (g_bHealing[host] && g_bInRange[host][ent] || g_bHealing[ent])
	{
		set_es(es_handle, ES_RenderFx, kRenderFxGlowShell)
		set_es(es_handle, ES_RenderColor, g_iColor)
		set_es(es_handle, ES_RenderAmt, 5)
		
		return FMRES_IGNORED
	}
	return FMRES_IGNORED
}

public zp_user_infected_post(id, infector, nemesis)
{
	remove_task(id)
	set_cvars(id)
	
	g_bZombie[id] = true
	pev(id, pev_health, g_flMaxHealth[id])
	
	if (nemesis) return
	
	if (zp_get_user_zombie_class(id) == g_iMotherIndex)
	{
		g_bMother[id] = true
		set_task(get_pcvar_float(cvar_Interval), "Mother_Heal", id, _, _, "b")
		
		if (g_bIsBot[id])
			g_bHealing[id] = true
	}
}

public zp_user_humanized_post(id)
{
	remove_task(id)
	set_cvars(id)
}

// Support CSO In-Game Theme 5.4 or higher
//forward zp_cso_theme_evohp_lvlup(iInfector, iEvoHp)
public zp_cso_theme_evohp_lvlup(iInfector, iEvoHp)
{
	new Float:health = float(iEvoHp)
	
	if (health > g_flMaxHealth[iInfector])
		g_flMaxHealth[iInfector] = health
}

/*================================================================================
 [Other Functions]
=================================================================================*/

public register_ham_czbots(id)
{
	if (g_bHamCzBots || !is_user_bot(id) || !is_user_connected(id)) return
	
	RegisterHamFromEntity(Ham_Spawn, id, "fwd_PlayerSpawn_Post", 1)
	RegisterHamFromEntity(Ham_Killed, id, "fwd_PlayerKilled_Post", 1)
	
	g_bHamCzBots = true
}

set_cvars(id)
{
	g_bZombie[id] = g_bMother[id] = g_bHealing[id] = false
	g_iHealCounter[id] = 0
}

public Mother_Heal(id)
{
	if (!g_bHealing[id]) return
	
	static Float:originF[3]
	pev(id, pev_origin, originF)
	
	for (new i = 1; i <= g_iMaxPlayers; i++)
		g_bInRange[id][i] = false
	
	static Float:range, Float:amount, victim
	range = get_pcvar_float(cvar_Range)
	amount = get_pcvar_float(cvar_Amount)
	victim = -1
	
	while ((victim = engfunc(EngFunc_FindEntityInSphere, victim, originF, range)) != 0)
	{
		if (!is_user_valid_alive(victim) || !g_bZombie[victim] || victim == id) continue
		
		g_bInRange[id][victim] = true
		
		new Float:currentHP
		pev(victim, pev_health, currentHP)		
		if (currentHP + amount < g_flMaxHealth[victim])
		{
			set_pev(victim, pev_health, currentHP + amount)
			g_iHealCounter[id]++
		}
		else
			set_pev(victim, pev_health, g_flMaxHealth[victim])
	}
	
	while (g_iHealCounter[id] > get_pcvar_num(cvar_Counter))
	{
		static origin[3]
		get_user_origin(id, origin)
		
		message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
		write_byte(TE_IMPLOSION) // TE id
		write_coord(origin[0]) // x
		write_coord(origin[1]) // y
		write_coord(origin[2]) // z
		write_byte(128) // radius
		write_byte(20) // count
		write_byte(3) // duration
		message_end()
		
		zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id) + 1)
		
		g_iHealCounter[id] -= get_pcvar_num(cvar_Counter)
	}
}
