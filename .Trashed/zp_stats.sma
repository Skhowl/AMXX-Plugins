/*================================================================================
	
		****************************************************
		*********** [Zombie Plague Stats 1.0.0] ************
		****************************************************
	
	----------------------
	-*- Licensing Info -*-
	----------------------
	
	Zombie Plague Stats
	by schmurgel1983(@msn.com)
	Copyright (C) 2008-2022 schmurgel1983, skhowl, gesalzen
	
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
	
	Show stats like csstats with zombies/human remaining.
	Give all 5 seconds a info about the HP from nemesis, survivor or both.
	
	--------------------
	-*- Requirements -*-
	--------------------
	
	* Game: Counter-Strike 1.6 or Condition-Zero
	* Metamod: Version 1.19 or later
	* AMXX: Version 1.8.0 or later
	* Module: fakemeta, hamsandwich
	
	-----------------
	-*- Changelog -*-
	-----------------
	
* v1.0.0:
   - Initial release Privat (30th Aug 2008)
   - Initial release Alliedmodders (2nd Feb 2011)
	
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

/*================================================================================
 [Global Variables]
=================================================================================*/

// Game vars
new g_iMaxPlayers // max player counter
new g_HudSync, g_HudSync2 // message sync objects
new g_bNemesis // Nemesis round
new g_bSurvivor // Survivor round
new g_bHamCzBots // whether ham forwards are registered for CZ bots

/*================================================================================
 [Init]
=================================================================================*/

public plugin_init()
{
	register_plugin("Zombie Plague Stats", PLUGIN_VERSION, "schmurgel1983")
	
	RegisterHam(Ham_Killed, "player", "Ham_Killed_Post", 1)
	
	register_event("TextMsg", "event_end_round", "a", "2=#Game_Commencing", "2=#Game_will_restart_in")
	register_event("SendAudio", "event_end_round", "a", "2&%!MRAD_terwin", "2&%!MRAD_ctwin", "2&%!MRAD_rounddraw")
	
	g_iMaxPlayers = get_maxplayers()
	
	g_HudSync = CreateHudSyncObj()
	g_HudSync2 = CreateHudSyncObj()
}

public client_putinserver(id)
{
	if (is_user_bot(id) && !g_bHamCzBots)
		set_task(0.1, "register_ham_czbots", id)
}

/*================================================================================
 [Main Forwards]
=================================================================================*/

public zp_round_started(mode, player)
{
	switch (mode)
	{
		case MODE_NEMESIS: g_bNemesis = true;
		case MODE_SURVIVOR: g_bSurvivor = true;
	}
	
	display_nem_surv_hp()
	display_enemy_remaining()
	
	remove_task(48365)
	set_task(5.0, "display_nem_surv_hp", 48365, "", 0, "b")
}

public event_end_round()
{
	remove_task(48365)
	g_bNemesis = g_bSurvivor = false
}

public Ham_Killed_Post(victim, attacker, gib)
{
	display_enemy_remaining()
}

public zp_user_humanized_post(id, survivor)
{
	display_enemy_remaining()
}

public zp_user_infected_post(id, infector, nemesis)
{
	display_enemy_remaining()
}

/*================================================================================
 [Other Functions]
=================================================================================*/

public register_ham_czbots(id)
{
	if (g_bHamCzBots || !is_user_bot(id) || !is_user_connected(id)) return
	
	RegisterHamFromEntity(Ham_Killed, id, "Ham_Killed_Post", 1)
	
	g_bHamCzBots = true
}

public display_nem_surv_hp()
{
	static nemesis, survivor
	nemesis = zp_get_nemesis_count()
	survivor = zp_get_survivor_count()
	
	if (!nemesis && !survivor) return
	
	if (nemesis && survivor)
	{
		new message[512], name[32], pos
		
		for (new i = 1; i <= g_iMaxPlayers; i++)
		{
			if (!is_user_connected(i) || !is_user_alive(i)) continue
			
			get_user_name(i, name, 31)
			if (zp_get_user_nemesis(i))
				pos += format(message[pos], 511, "Nemesis: %s has %d HP left.^n", name, pev(i, pev_health))
			else if (zp_get_user_survivor(i))
				pos += format(message[pos], 511, "Survivor: %s has %d HP left.^n", name, pev(i, pev_health))
		}
		
		set_hudmessage(0, 175, 0, 0.05, 0.20, 2, 0.01, 3.0, 0.01, 0.75, 1)
		ShowSyncHudMsg(0, g_HudSync2, "%s", message)
		return
	}
	else if (nemesis)
	{
		new message[512], name[32], pos
		
		for (new i = 1; i <= g_iMaxPlayers; i++)
		{
			if (!is_user_connected(i) || !is_user_alive(i) || !zp_get_user_nemesis(i)) continue
			
			get_user_name(i, name, 31)
			pos += format(message[pos], 511, "Nemesis: %s has %d HP left.^n", name, pev(i, pev_health))
		
		}
		set_hudmessage(175, 0, 0, 0.05, 0.20, 2, 0.01, 3.0, 0.01, 0.75, 1)
		ShowSyncHudMsg(0, g_HudSync2, "%s", message)
		return
	}
	else if (survivor)
	{
		new message[512], name[32], pos
		
		for (new i = 1; i <= g_iMaxPlayers; i++)
		{
			if (!is_user_connected(i) || !is_user_alive(i) || !zp_get_user_survivor(i)) continue
			
			get_user_name(i, name, 31)
			pos += format(message[pos], 511, "Survivor: %s has %d HP left.^n", name, pev(i, pev_health))
		
		}
		set_hudmessage(0, 0, 175, 0.05, 0.20, 2, 0.01, 3.0, 0.01, 0.75, 1)
		ShowSyncHudMsg(0, g_HudSync2, "%s", message)
		return
	}
}

public display_enemy_remaining()
{
	if (g_bNemesis || g_bSurvivor) return
	
	for (new i = 1; i <= g_iMaxPlayers; i++)
	{
		if (!is_user_connected(i)) continue
		if (!is_user_alive(i)) continue
		
		static message[128], zombie_count, human_count
		human_count = zp_get_human_count()
		zombie_count = zp_get_zombie_count()
		
		if (!zp_get_user_zombie(i) && zombie_count)
		{
			set_hudmessage(175, 175, 175, 0.05, 0.625, 2, 0.02, 3.0, 0.01, 0.3, 2)

			format(message, 127, "%d Zombie%s Remaining...", zombie_count, (zombie_count == 1) ? "" : "s")
			ShowSyncHudMsg(i, g_HudSync, "%s", message)
		}
		else if (zp_get_user_zombie(i) && human_count)
		{
			set_hudmessage(175, 175, 175, 0.05, 0.625, 2, 0.02, 3.0, 0.01, 0.3, 2)

			format(message, 127, "%d Human%s Remaining...", human_count, (human_count == 1) ? "" : "s")
			ShowSyncHudMsg(i, g_HudSync, "%s", message)
		}
	}
}
