/*
	
	----------------------
	-*- Licensing Info -*-
	----------------------
	
	Copyright (C) 2012-2022 schmurgel1983, skhowl, gesalzen
	
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
	
*/

#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#include <dm_core>
#include <dm_spawn>
#include <dm_items>
#include <dm_colorchat>

/* --------------------------------------------------------------------------- */

// Hack to be able to use Ham_Player_ResetMaxSpeed (by joaquimandrade)
new Ham:Ham_Player_ResetMaxSpeed = Ham_Item_PreFrame;

new dm_item_boots_speed = 0;

new g_iItemID = -1;

new bool:g_bFreezeTime = false;

new bs_IsAlive = 0;
new bs_HaveItem = 0;

#define get_bitsum(%1,%2)   (%1 &   (1<<((%2-1)&31)))
#define add_bitsum(%1,%2)    %1 |=  (1<<((%2-1)&31))
#define del_bitsum(%1,%2)    %1 &= ~(1<<((%2-1)&31))

/* --------------------------------------------------------------------------- */

new const item_name[] = { "boots_of_speed" };
new const item_chat[] = { "boots" };
const item_teams = DM_TEAM_ANY;
const item_cost = 100;
const item_holdtime = 180;

/* --------------------------------------------------------------------------- */

public DM_OnModStatus(status)
{
	register_plugin("DM Item: Boots of Speed", "1.0.0", "schmurgel1983");
	
	if (status) state enabled;
	else state deactivated;
}

public plugin_init() <deactivated> {}
public plugin_init() <enabled>
{
	g_iItemID = DM_RegisterItem(item_name, item_chat, item_teams, item_cost, item_holdtime, "Activate", "Deactivate");
	if (g_iItemID == -1)
	{
		state deactivated;
		return;
	}
	
	#if AMXX_VERSION_NUM < 183
	register_dictionary_colored("dm_items_additional.txt");
	#else
	register_dictionary("dm_items_additional.txt");
	#endif
	
	register_event("HLTV", "EventRoundStart", "a", "1=0", "2=0");
	register_logevent("LogEventRoundStart", 2, "1=Round_Start");
	
	dm_item_boots_speed = register_cvar("dm_item_boots_speed", "1.2");
	
	RegisterHam(Ham_Player_ResetMaxSpeed, "player", "fwd_ResetMaxSpeed_Post", true);
}

/* --------------------------------------------------------------------------- */

#if AMXX_VERSION_NUM < 183
public client_disconnect(id) <deactivated> {}
public client_disconnect(id) <enabled>
#else
public client_disconnected(id, bool:drop, message[], maxlen) <deactivated> {}
public client_disconnected(id, bool:drop, message[], maxlen) <enabled>
#endif
{
	del_bitsum(bs_IsAlive, id);
	del_bitsum(bs_HaveItem, id);
}

/* --------------------------------------------------------------------------- */

public DM_OnCzBotHamRegisterable(id) <deactivated> {}
public DM_OnCzBotHamRegisterable(id) <enabled>
{
	RegisterHamFromEntity(Ham_Player_ResetMaxSpeed, id, "fwd_ResetMaxSpeed_Post", true);
}

/* --------------------------------------------------------------------------- */

public DM_PlayerSpawn_Post(id, freezetime, roundend) <deactivated> {}
public DM_PlayerSpawn_Post(id, freezetime, roundend) <enabled>
{
	add_bitsum(bs_IsAlive, id);
}

public DM_PlayerKilled_Pre(victim, attacker) <deactivated> {}
public DM_PlayerKilled_Pre(victim, attacker) <enabled>
{
	del_bitsum(bs_IsAlive, victim);
}

/* --------------------------------------------------------------------------- */

public EventRoundStart()
{
	g_bFreezeTime = true;
}

public LogEventRoundStart()
{
	g_bFreezeTime = false;
}

/* --------------------------------------------------------------------------- */

public fwd_ResetMaxSpeed_Post(id)
{
	if (g_bFreezeTime || !get_bitsum(bs_IsAlive, id) || !get_bitsum(bs_HaveItem, id))
		return;
	
	set_pev(id, pev_maxspeed, pev(id, pev_maxspeed) * get_pcvar_float(dm_item_boots_speed));
}

/* --------------------------------------------------------------------------- */

public Activate(id)
{
	if (!get_bitsum(bs_HaveItem, id))
	{
		static name[32];
		if (name[0] || DM_GetItemDisplayName(g_iItemID, name, 31))
		{
			#if AMXX_VERSION_NUM < 183
			dm_print_color(id, DontChange, "^4[%s]^1 You run now^4 %d%%^1 faster!", name, floatround(get_pcvar_float(dm_item_boots_speed) * 100) - 100);
			#else
			client_print_color(id, print_team_default, "^4[%s]^1 You run now^4 %d%%^1 faster!", name, floatround(get_pcvar_float(dm_item_boots_speed) * 100) - 100);
			#endif
		}
		
		add_bitsum(bs_HaveItem, id);
		fwd_ResetMaxSpeed_Post(id);
	}
}

public Deactivate(id)
{
	del_bitsum(bs_HaveItem, id);
	set_pev(id, pev_maxspeed, pev(id, pev_maxspeed) / get_pcvar_float(dm_item_boots_speed));
}
