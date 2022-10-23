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
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>

#include <dm_core>
#include <dm_spawn>
#include <dm_items>
#include <dm_colorchat>

/* --------------------------------------------------------------------------- */

new g_iItemID = -1;

const FM_PDATA_SAFE = 2;
const OFFSET_LINUX_WEAPONS = 4;

const OFFSET_WEAPONOWNER = 41;
const m_flNextPrimaryAttack = 46;
const m_flNextSecondaryAttack = 47;

const OFFSET_ACTIVE_ITEM = 373;

new const MAXCLIP[] = { -1, 13, -1, 10, -1, 7, -1, 30, 30, -1, 30, 20, 25,
30, 35, 25, 12, 20, 10, 30, 100, 8, 30, 30, 20, -1, 7, 30, 30, -1, 50 };

new const WEAPONENTNAMES[][] = { "weapon_p228", "weapon_scout", "weapon_xm1014",
"weapon_mac10", "weapon_aug", "weapon_elite", "weapon_fiveseven", "weapon_ump45",
"weapon_sg550", "weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18",
"weapon_awp", "weapon_mp5navy", "weapon_m249", "weapon_m3", "weapon_m4a1",
"weapon_tmp", "weapon_g3sg1", "weapon_deagle", "weapon_sg552", "weapon_ak47",
"weapon_p90" };

new bs_IsAlive = 0;
new bs_HaveItem = 0;

#define get_bitsum(%1,%2)   (%1 &   (1<<((%2-1)&31)))
#define add_bitsum(%1,%2)    %1 |=  (1<<((%2-1)&31))
#define del_bitsum(%1,%2)    %1 &= ~(1<<((%2-1)&31))

#if AMXX_VERSION_NUM < 183
new g_iMaxPlayers = 0;
#define is_user_valid_alive(%1) (1 <= %1 <= g_iMaxPlayers && get_bitsum(bs_IsAlive, %1))
#else
#define is_user_valid_alive(%1) (1 <= %1 <= MaxClients && get_bitsum(bs_IsAlive, %1))
#endif

/* --------------------------------------------------------------------------- */

new const item_name[] = { "no_reload" };
new const item_chat[] = { "noreload" };
const item_teams = DM_TEAM_ANY;
const item_cost = 150;
const item_holdtime = 180;

/* --------------------------------------------------------------------------- */

public DM_OnModStatus(status)
{
	register_plugin("DM Item: No Reload!", "1.0.0", "schmurgel1983");
	
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
	
	register_message(get_user_msgid("CurWeapon"), "MessageCurWeapon");
	
	for (new i = 0; i < sizeof WEAPONENTNAMES; i++)
		RegisterHam(Ham_Weapon_Reload, WEAPONENTNAMES[i], "fwd_WeaponReload");
	
	#if AMXX_VERSION_NUM < 183
	g_iMaxPlayers = get_maxplayers();
	#endif
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

public fwd_WeaponReload(entity)
{
	static owner;
	owner = fm_cs_get_weapon_ent_owner(entity);
	
	if (!is_user_valid_alive(owner) || !get_bitsum(bs_HaveItem, owner))
		return HAM_IGNORED;
	
	static name[32];
	if (name[0] || DM_GetItemDisplayName(g_iItemID, name, 31))
	{
		#if AMXX_VERSION_NUM < 183
		dm_print_color(owner, DontChange, "^4[%s]^1 You don't need to reload!", name);
		#else
		client_print_color(owner, print_team_default, "^4[%s]^1 You don't need to reload!", name);
		#endif
	}
	
	set_pdata_float(entity, m_flNextPrimaryAttack, 0.5, OFFSET_LINUX_WEAPONS);
	set_pdata_float(entity, m_flNextSecondaryAttack, 0.5, OFFSET_LINUX_WEAPONS);
	
	return HAM_SUPERCEDE;
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
			dm_print_color(id, DontChange, "^4[%s]^1 You don't need to reload!", name);
			#else
			client_print_color(id, print_team_default, "^4[%s]^1 You don't need to reload!", name);
			#endif
		}
	}
	
	add_bitsum(bs_HaveItem, id);
}

public Deactivate(id)
{
	del_bitsum(bs_HaveItem, id);
	
	new weapons[32], num_weapons, index, weaponid;
	get_user_weapons(id, weapons, num_weapons);
	
	for (index = 0; index < num_weapons; index++)
	{
		weaponid = weapons[index];
		if (MAXCLIP[weaponid] == -1)
			continue;
		
		new wname[32];
		get_weaponname(weaponid, wname, 31);
		
		new weapon_ent = fm_find_ent_by_owner(FM_NULLENT, wname, id);
		if (!pev_valid(weapon_ent))
			continue;
		
		cs_set_weapon_ammo(weapon_ent, MAXCLIP[weaponid]);
	}
}

/* --------------------------------------------------------------------------- */

public MessageCurWeapon(msg_id, msg_dest, msg_entity)
{
	if (!is_user_valid_alive(msg_entity) || !get_bitsum(bs_HaveItem, msg_entity) || get_msg_arg_int(1) != 1)
		return;
	
	new weapon = get_msg_arg_int(2);
	if (MAXCLIP[weapon] == -1)
		return;
	
	if (get_msg_arg_int(3) < 2)
	{
		new weapon_ent = fm_cs_get_current_weapon_ent(msg_entity);
		if (pev_valid(weapon_ent))
			cs_set_weapon_ammo(weapon_ent, MAXCLIP[weapon]);
	}
	
	set_msg_arg_int(3, ARG_BYTE, MAXCLIP[weapon]);
}

/* --------------------------------------------------------------------------- */

stock fm_find_ent_by_owner(entity, const classname[], owner)
{
	while ((entity = engfunc(EngFunc_FindEntityByString, entity, "classname", classname)) && pev(entity, pev_owner) != owner)
	{ /* keep looping */ }
	
	return entity;
}

stock fm_cs_get_current_weapon_ent(id)
{
	if (pev_valid(id) != FM_PDATA_SAFE)
		return -1;
	
	return get_pdata_cbase(id, OFFSET_ACTIVE_ITEM);
}

stock fm_cs_get_weapon_ent_owner(ent)
{
	if (pev_valid(ent) != FM_PDATA_SAFE)
		return -1;
	
	return get_pdata_cbase(ent, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS);
}
