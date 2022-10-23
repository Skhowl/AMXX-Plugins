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
#include <dm_items>
#include <dm_colorchat>

/* --------------------------------------------------------------------------- */

const FM_PDATA_SAFE = 2;
const OFFSET_PAINSHOCK = 108; // ConnorMcLeod

new dm_item_plaster_knockback = 0;

new g_iItemID = -1;

new bs_HaveItem = 0;

#define get_bitsum(%1,%2)   (%1 &   (1<<((%2-1)&31)))
#define add_bitsum(%1,%2)    %1 |=  (1<<((%2-1)&31))
#define del_bitsum(%1,%2)    %1 &= ~(1<<((%2-1)&31))

/* --------------------------------------------------------------------------- */

new const item_name[] = { "plaster_of_pain" };
new const item_chat[] = { "plaster" };
const item_teams = DM_TEAM_ANY;
const item_cost = 150;
const item_holdtime = 120;

/* --------------------------------------------------------------------------- */

public DM_OnModStatus(status)
{
	register_plugin("DM Item: Plaster of Pain", "1.0.0", "schmurgel1983");
	
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
	
	dm_item_plaster_knockback = register_cvar("dm_item_plaster_knockback", "0.15");
	
	RegisterHam(Ham_TakeDamage, "player", "fwd_TakeDamage", false);
	RegisterHam(Ham_TakeDamage, "player", "fwd_TakeDamage_Post", true);
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
	del_bitsum(bs_HaveItem, id);
}

/* --------------------------------------------------------------------------- */

public DM_OnCzBotHamRegisterable(id) <deactivated> {}
public DM_OnCzBotHamRegisterable(id) <enabled>
{
	RegisterHamFromEntity(Ham_TakeDamage, id, "fwd_TakeDamage", false);
	RegisterHamFromEntity(Ham_TakeDamage, id, "fwd_TakeDamage_Post", true);
}

/* --------------------------------------------------------------------------- */

new Float:g_fVelocity[DM_MAX_PLAYERS+1][3];

public fwd_TakeDamage(victim)
{
	if (!get_bitsum(bs_HaveItem, victim))
		return;
	
	pev(victim, pev_velocity, g_fVelocity[victim]);
}

public fwd_TakeDamage_Post(victim)
{
	if (!get_bitsum(bs_HaveItem, victim))
		return;
	
	if (!get_pcvar_float(dm_item_plaster_knockback))
	{
		set_pev(victim, pev_velocity, g_fVelocity[victim]);
	}
	else
	{
		#define DM_Vector_SMA(%0,%1,%2) (%2[0] = (%2[0] - %0[0]) * %1 + %0[0], %2[1] = (%2[1] - %0[1]) * %1 + %0[1], %2[2] = (%2[2] - %0[2]) * %1 + %0[2])
		
		static Float:fPush[3]; pev(victim, pev_velocity, fPush);
		DM_Vector_SMA(g_fVelocity[victim], get_pcvar_float(dm_item_plaster_knockback), fPush);
		set_pev(victim, pev_velocity, fPush);
	}
	
	DM_SetUserPainShock(victim, 1.0);
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
			dm_print_color(id, DontChange, "^4[%s]^1 You don't feel pain shock now!", name);
			#else
			client_print_color(id, print_team_default, "^4[%s]^1 You don't feel pain shock now!", name);
			#endif
		}
	}
	
	add_bitsum(bs_HaveItem, id);
}

public Deactivate(id)
{
	del_bitsum(bs_HaveItem, id);
}

/* --------------------------------------------------------------------------- */

stock DM_SetUserPainShock(const id, const Float:value)
{
	if (pev_valid(id) != FM_PDATA_SAFE)
		return false;
	
	set_pdata_float(id, OFFSET_PAINSHOCK, value);
	return true;
}
