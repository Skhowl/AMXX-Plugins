/*================================================================================
	
		****************************************
		********* [CSS Flashlight 2.0] *********
		****************************************
	
	----------------------
	-*- Licensing Info -*-
	----------------------
	
	CSS Flashlight
	by schmurgel1983(@msn.com)
	Copyright (C) 2011-2022 schmurgel1983, skhowl, gesalzen
	
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
	
	This plugin add a lightcone. Version 2 has a new cone model,
	old model drawn polys ~90, new model ~48, but its smooth and
	looks great. New cone model as animations like a player model.
	
	--------------------
	-*- Requirements -*-
	--------------------
	
	* Mods: Counter-Strike 1.6, Condition-Zero
	* Metamod: Version 1.19 or later
	* AMXX: Version 1.8.0 or later
	* Module: engine, fakemeta, hamsandwich
	
	----------------
	-*- Commands -*-
	----------------
	
	-----
	
	---------------------
	-*- Configuration -*-
	---------------------
	
	- none
	
	---------------
	-*- Credits -*-
	---------------
	
	.Dare Devil.: lightcone model (not used more)
	Hunter-Digital: lightcone base model (with non-animations)
	ot_207: for 4096 entity bitsum macro (not used more)
	ConnorMcLeod: J'ai toujours été signifié dans le collimateur, positive 
	and all who believe me, thanks.
	
	-----------------
	-*- Changelog -*-
	-----------------
	
	* v1.0:
		- initial release
	
	* v1.1:
		- Supports original game flashlight
		- Supports ConnorMcLeod CustomFlashLight
		- Supports Simon Logic Blinding Flashlight v0.2.3SL
		- Supports MeRcyLeZZ Zombie Plague Mod 4.3 flashlight
	
	* v2.0:
		- Added: better cone model
		- Re-write: for lower CPU usage
	
=================================================================================*/

#include <amxmodx>
#include <engine>
#include <fakemeta>

#if AMXX_VERSION_NUM < 180
	#assert AMX Mod X v1.8.0 or later library required!
#endif

#include <hamsandwich>

/*================================================================================
 [Zombie Plague 5.0 Includes]
=================================================================================*/

#include <cs_ham_bots_api>
#define LIBRARY_ZP50_CORE "zp50_core"
#include <zp50_core>
#define LIBRARY_FLASHLIGHT "zp50_flashlight"
#include <zp50_flashlight>
#define LIBRARY_CLASS_SURVIVOR "zp50_class_survivor"
#include <zp50_class_survivor>

/*================================================================================
 [Plugin Customization]
=================================================================================*/

// only for testing :)
//#define TEST_3RD

/*================================================================================
 [Constants, Offsets, Macros]
=================================================================================*/

new const PLUGIN_VERSION[] = "2.0 (zp50)"

#define FM_PDATA_SAFE 2

new const model_lightcone[] = "models/css_lightcone2.mdl"

#if defined TEST_3RD
new const model_3rd_person[] = "models/rpgrocket.mdl"
#endif

new bs_Flashlight, bs_IsAlive, bs_IsBot
new g_iLightConeIndex[33]

new Float:g_fLastFlashTime[33]
new g_iZombiePlague, cvar_iZpCustomFL, cvar_iZpShowAll
new bs_IsZombie, bs_IsSurvivor

#define add_bitsum(%1,%2) (%1 |= (1<<(%2-1)))
#define del_bitsum(%1,%2) (%1 &= ~(1<<(%2-1)))
#define get_bitsum(%1,%2) (%1 & (1<<(%2-1)))

/*================================================================================
 [Precache, Init]
=================================================================================*/

public plugin_precache()
{
	if (!LibraryExists(LIBRARY_ZP50_CORE, LibType_Library))
		return
	
	g_iZombiePlague = 1
	engfunc(EngFunc_PrecacheModel, model_lightcone)
	
	#if defined TEST_3RD
	engfunc(EngFunc_PrecacheModel, model_3rd_person)
	#endif
}

public plugin_init()
{
	register_plugin("[ZP] CSS Flashlight", PLUGIN_VERSION, "schmurgel1983")
	register_cvar("css_flashlight", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY)
	set_cvar_string("css_flashlight", PLUGIN_VERSION)
	
	if (!g_iZombiePlague)
		return
	
	RegisterHam(Ham_Spawn, "player", "fwd_PlayerSpawn_Post", 1)
	RegisterHamBots(Ham_Spawn, "fwd_PlayerSpawn_Post", 1)
	RegisterHam(Ham_Killed, "player", "fwd_PlayerKilled")
	RegisterHamBots(Ham_Killed, "fwd_PlayerKilled")
	
	register_message(get_user_msgid("Flashlight"), "message_flashlight")
	
	#if defined TEST_3RD
	register_clcmd("say 1st", "clcmd_1st")
	register_clcmd("say 3rd", "clcmd_3rd")
	#endif
	
	if (!LibraryExists(LIBRARY_FLASHLIGHT, LibType_Library))
		return
	
	register_impulse(100, "fwd_Impulse_100")
	
	cvar_iZpCustomFL = get_cvar_pointer("zp_flashlight_custom")
	cvar_iZpShowAll = get_cvar_pointer("zp_flashlight_show_all")
}

public plugin_natives()
{
	set_module_filter("module_filter")
	set_native_filter("native_filter")
}

public module_filter(const module[])
{
	if (equal(module, LIBRARY_ZP50_CORE) || equal(module, LIBRARY_FLASHLIGHT) || equal(module, LIBRARY_CLASS_SURVIVOR))
		return PLUGIN_HANDLED
	
	return PLUGIN_CONTINUE
}

public native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED
	
	return PLUGIN_CONTINUE
}

/*================================================================================
 [Zombie Plague Forwards]
=================================================================================*/

public zp_fw_core_infect_post(id, attacker)
{
	add_bitsum(bs_IsZombie, id);
	del_bitsum(bs_IsSurvivor, id);
	
	remove_task(id)
	
	del_bitsum(bs_Flashlight, id);
	set_cone_nodraw(id)
}

public zp_fw_core_cure_post(id, attacker)
{
	del_bitsum(bs_IsZombie, id);
	del_bitsum(bs_IsSurvivor, id);
	
	remove_task(id)
	
	if (LibraryExists(LIBRARY_CLASS_SURVIVOR, LibType_Library) && zp_class_survivor_get(id)) add_bitsum(bs_IsSurvivor, id);
	
	del_bitsum(bs_Flashlight, id);
	set_cone_nodraw(id)
	
	if (get_bitsum(bs_IsBot, id))
		set_lightcone(id)
}

/*================================================================================
 [Main Forwards]
=================================================================================*/

public fwd_Impulse_100(id)
{
	if (!get_bitsum(bs_IsAlive, id))
		return
	
	if (get_bitsum(bs_IsZombie, id) || get_bitsum(bs_IsSurvivor, id) || !get_pcvar_num(cvar_iZpCustomFL) || !get_pcvar_num(cvar_iZpShowAll))
		return
	
	if (zp_flashlight_get_charge(id) > 2 && get_gametime() - g_fLastFlashTime[id] > 1.2)
	{
		g_fLastFlashTime[id] = get_gametime()
		
		get_bitsum(bs_Flashlight, id) ? del_bitsum(bs_Flashlight, id) : add_bitsum(bs_Flashlight, id);
		
		set_lightcone(id)
	}
}

public fwd_PlayerSpawn_Post(id)
{
	if (!is_user_alive(id) || !fm_cs_get_user_team(id))
		return;
	
	add_bitsum(bs_IsAlive, id);
	
	remove_task(id)
	del_bitsum(bs_Flashlight, id);
	set_cone_nodraw(id)
	
	if (get_bitsum(bs_IsBot, id))
		set_lightcone(id)
	
	#if defined TEST_3RD
	clcmd_1st(id)
	client_print(id, print_chat, "Test: first persion view say ^"1st^" for third persion view ^"3rd^"")
	#endif
}

public fwd_PlayerKilled(victim, attacker, shouldgib)
{
	del_bitsum(bs_IsAlive, victim);
	
	remove_task(victim)
	del_bitsum(bs_Flashlight, victim);
	del_bitsum(bs_IsZombie, victim);
	del_bitsum(bs_IsSurvivor, victim);
	set_cone_nodraw(victim)
}

public client_putinserver(id)
{
	if (!is_user_bot(id))
		return
	
	add_bitsum(bs_IsBot, id);
}

public client_disconnect(id)
{
	del_bitsum(bs_IsAlive, id);
	del_bitsum(bs_IsBot, id);
	
	remove_task(id)
	del_bitsum(bs_Flashlight, id);
	del_bitsum(bs_IsZombie, id);
	del_bitsum(bs_IsSurvivor, id);
	
	if (pev_valid(g_iLightConeIndex[id]))
		engfunc(EngFunc_RemoveEntity, g_iLightConeIndex[id])
	g_iLightConeIndex[id] = 0
}

/*================================================================================
 [Client Commands]
=================================================================================*/

#if defined TEST_3RD
public clcmd_1st(id)
{
	if (!get_bitsum(bs_IsAlive, id))
		return
	
	set_view(id, CAMERA_NONE)
}

public clcmd_3rd(id)
{
	if (!get_bitsum(bs_IsAlive, id))
		return
	
	set_view(id, CAMERA_3RDPERSON)
}
#endif

/*================================================================================
 [Message Hooks]
=================================================================================*/

public message_flashlight(msg_id, msg_dest, msg_entity)
{
	get_msg_arg_int(1) ? add_bitsum(bs_Flashlight, msg_entity) : del_bitsum(bs_Flashlight, msg_entity);
	
	set_lightcone(msg_entity)
}

/*================================================================================
 [Cone Logic]
=================================================================================*/

set_lightcone(id)
{
	if (get_bitsum(bs_IsSurvivor, id))
		return
	
	remove_task(id)
	
	if (get_bitsum(bs_Flashlight, id) || get_bitsum(bs_IsBot, id))
	{
		set_task(0.2, "zp_have_battery", id, _, _, "b")
		
		if (!g_iLightConeIndex[id])
		{
			static info
			if (!info) info = engfunc(EngFunc_AllocString, "info_target")
			
			new iEntity = g_iLightConeIndex[id] = engfunc(EngFunc_CreateNamedEntity, info)
			
			if (pev_valid(iEntity))
			{
				engfunc(EngFunc_SetModel, iEntity, model_lightcone)
				set_pev(iEntity, pev_effects, 0)
				set_pev(iEntity, pev_owner, id)
				set_pev(iEntity, pev_movetype, MOVETYPE_FOLLOW)
				set_pev(iEntity, pev_aiment, id)
			}
		}
		else set_pev(g_iLightConeIndex[id], pev_effects, 0);
	}
	else set_cone_nodraw(id);
}

/*================================================================================
 [Other Functions and Tasks]
=================================================================================*/

public zp_have_battery(id)
{
	if (!zp_flashlight_get_charge(id))
	{
		remove_task(id)
		del_bitsum(bs_Flashlight, id);
		set_cone_nodraw(id)
	}
}

set_cone_nodraw(id)
{
	if (g_iLightConeIndex[id])
		set_pev(g_iLightConeIndex[id], pev_effects, EF_NODRAW)
}

/*================================================================================
 [Stocks]
=================================================================================*/

stock fm_cs_get_user_team(id)
{
	return (pev_valid(id) == FM_PDATA_SAFE) ? get_pdata_int(id, 114, 5) : 0;
}
