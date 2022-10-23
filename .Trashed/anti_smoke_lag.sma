/*================================================================================
	
		******************************************
		********* [Anti Smoke Lag 2.0.0] *********
		******************************************
	
	----------------------
	-*- Licensing Info -*-
	----------------------
	
	Anti Smoke Lag
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
	
	This plugin protect the smoke "lag" bug on maps like de_dust2.
	If smoke-grenade stucking, depends or bounce infinitely,
	forcing to explode. Can remove smoke after explode if will
	stucking again, or can force to explode in air by cvars.
	
	--------------------
	-*- Requirements -*-
	--------------------
	
	* Game: Counter-Strike 1.6, Condition-Zero
	* Metamod: Version 1.19 or later
	* AMXX: Version 1.8.0 or later
	* Module: fakemeta, hamsandwich
	
	----------------
	-*- Commands -*-
	----------------
	
	-----
	
	---------------------
	-*- Configuration -*-
	---------------------
	
	asl_remove_smoke 1 // Remove smoke after explode (if stucking) [0-disabled]
	asl_explode_in_air 0 // Force smoke to explode in air [0-disabled]
	
	---------------
	-*- Credits -*-
	---------------
	
	-----
	
	-----------------
	-*- Changelog -*-
	-----------------
	
	* v1.0.0: (8th Apr 2011)
		- initial release
	
	* v1.0.1: (10th Apr 2011)
		- Delete: Remove smoke after explode (not needed, have tested) - was a fault
		
	* v2.0.0: (20th Apr 2011)
		- Added: only check smoke grenade
		- Added: 2 cvars
	
=================================================================================*/

#include <amxmodx>
#include <fakemeta>

#if AMXX_VERSION_NUM < 180
	#assert AMX Mod X v1.8.0 or later library required!
#endif

#include <hamsandwich>

/*================================================================================
 [Constants, Macros]
=================================================================================*/

new const PLUGIN_VERSION[] = "2.0.0"

new p_iRemoveSmoke
new p_iExplodeInAir

#define IsOnGround(%1) (pev(%1, pev_flags) & FL_ONGROUND)

/*================================================================================
 [Init]
=================================================================================*/

public plugin_init()
{
	register_plugin("Anti Smoke Lag", PLUGIN_VERSION, "schmurgel1983")
	
	RegisterHam(Ham_Think, "grenade", "fwd_ThinkGrenade")
	RegisterHam(Ham_Think, "grenade", "fwd_ThinkGrenade_Post", 1)
	
	register_forward(FM_SetModel, "fwd_SetModel")
	
	p_iRemoveSmoke = register_cvar("asl_remove_smoke", "1")
	p_iExplodeInAir = register_cvar("asl_explode_in_air", "0")
	
	register_cvar("anti_smoke_lag", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY)
	set_cvar_string("anti_smoke_lag", PLUGIN_VERSION)
}

/*================================================================================
 [Main Forwards]
=================================================================================*/

// Ham Grenade Think Forward
public fwd_ThinkGrenade(entity)
{
	// Invalid entity
	if (!pev_valid(entity)) return HAM_IGNORED;
	
	// Get damage time of grenade
	static Float:dmgtime, Float:current_time
	pev(entity, pev_dmgtime, dmgtime)
	current_time = get_gametime()
	
	// Check if it's time to go off
	if (dmgtime > current_time) return HAM_IGNORED;
	
	// Get check value from entity
	static check ; check = pev(entity, pev_flDuckTime)
	
	// Not smoke grenade
	if (check == -1) return HAM_IGNORED;
	
	// Grenade is flying
	if (!IsOnGround(entity))
	{
		// Explode in Air
		if (check == 0 && get_pcvar_num(p_iExplodeInAir))
		{
			// Fake on ground, smoke do explode
			set_pev(entity, pev_flags, FL_ONGROUND)
			
			// Set check value on entity
			set_pev(entity, pev_flDuckTime, check += 1)
		}
		
		// Is moving
		static Float:oldorigin[3] ; pev(entity, pev_oldorigin, oldorigin)
		static Float:origin[3] ; pev(entity, pev_origin, origin)
		if (get_distance_f(oldorigin, origin) > 1.0)
		{
			// Do nothing
			set_pev(entity, pev_oldorigin, origin)
			return HAM_IGNORED;
		}
		
		// Increase check by one
		check += 1
		
		// Grenade is stuck/depends in the air/wall
		if (check == 2 && !get_pcvar_num(p_iExplodeInAir))
		{
			// Fake on ground, smoke do explode
			set_pev(entity, pev_flags, FL_ONGROUND)
		}
		
		// Set check value on entity
		set_pev(entity, pev_flDuckTime, check)
	}
	
	return HAM_IGNORED;
}

public fwd_ThinkGrenade_Post(entity)
{
	// Invalid entity
	if (!pev_valid(entity)) return HAM_IGNORED;
	
	// Get damage time of grenade
	static Float:dmgtime, Float:current_time
	pev(entity, pev_dmgtime, dmgtime)
	current_time = get_gametime()
	
	// Check if it's time to go off
	if (dmgtime > current_time) return HAM_IGNORED;
	
	// Get check value from entity
	static check ; check = pev(entity, pev_flDuckTime)
	
	// Not smoke grenade
	if (check == -1) return HAM_IGNORED;
	
	// Remove smoke after explode (if stucking)
	if (check == 3 && get_pcvar_num(p_iRemoveSmoke))
	{
		engfunc(EngFunc_RemoveEntity, entity)
		return HAM_SUPERCEDE;
	}
	
	return HAM_IGNORED;
}

// Forward Set Model
public fwd_SetModel(entity, const model[])
{
	// We don't care
	if (strlen(model) < 8 || model[7] != 'w' || model[8] != '_') return
	
	// Get damage time of grenade
	static Float:dmgtime
	pev(entity, pev_dmgtime, dmgtime)
	
	// Grenade not yet thrown
	if (dmgtime == 0.0) return
	
	// He-Grenade or Flashbang
	if (model[9] == 'h' && model[10] == 'e' || model[9] == 'f' && model[10] == 'l')
	{
		// Set grenade type -1
		set_pev(entity, pev_flDuckTime, -1)
	}
	// Smoke Grenade
	else if (model[9] == 's' && model[10] == 'm')
	{
		// Set grenade type 0
		set_pev(entity, pev_flDuckTime, 0)
	}
}
