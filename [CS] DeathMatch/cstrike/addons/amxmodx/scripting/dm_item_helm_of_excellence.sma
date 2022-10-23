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

new g_iItemID = -1;

new bs_HaveItem = 0;

#define get_bitsum(%1,%2)   (%1 &   (1<<((%2-1)&31)))
#define add_bitsum(%1,%2)    %1 |=  (1<<((%2-1)&31))
#define del_bitsum(%1,%2)    %1 &= ~(1<<((%2-1)&31))

/* --------------------------------------------------------------------------- */

new const item_name[] = { "helm_of_excellence" };
new const item_chat[] = { "helm" };
const item_teams = DM_TEAM_ANY;
const item_cost = 100;
const item_holdtime = 90;

new const helm_sound[] = { "player/bhit_helmet-1.wav" };

#define write_coord_f(%1) engfunc(EngFunc_WriteCoord, %1)

/* --------------------------------------------------------------------------- */

public DM_OnModStatus(status)
{
	register_plugin("DM Item: Helm of Excellence", "1.0.0", "schmurgel1983");
	
	if (status) state enabled;
	else state deactivated;
}

public plugin_precache() <deactivated> {}
public plugin_precache() <enabled>
{
	g_iItemID = DM_RegisterItem(item_name, item_chat, item_teams, item_cost, item_holdtime, "Activate", "Deactivate");
	if (g_iItemID == -1)
	{
		state deactivated;
		return;
	}
	
	precache_sound(helm_sound);
}

public plugin_init() <deactivated> {}
public plugin_init() <enabled>
{
	#if AMXX_VERSION_NUM < 183
	register_dictionary_colored("dm_items_additional.txt");
	#else
	register_dictionary("dm_items_additional.txt");
	#endif
	
	RegisterHam(Ham_TraceAttack, "player", "fwd_TraceAttack", false);
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
	RegisterHamFromEntity(Ham_TraceAttack, id, "fwd_TraceAttack", false);
}

/* --------------------------------------------------------------------------- */

public fwd_TraceAttack(victim, attacker, Float:damage, Float:direction[3], tracehandle, damage_type)
{
	if (!(damage_type & DMG_BULLET) || !get_bitsum(bs_HaveItem, victim))
		return HAM_IGNORED;
	
	if (get_tr2(tracehandle, TR_iHitgroup) == HIT_HEAD)
	{
		new Float:Origin[3];
		get_tr2(tracehandle, TR_vecEndPos, Origin);
		
		engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, Origin, 0);
		write_byte(TE_SPARKS);
		write_coord_f(Origin[0]);
		write_coord_f(Origin[1]);
		write_coord_f(Origin[2]);
		message_end();
		
		emit_sound(victim, CHAN_BODY, helm_sound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		
		return HAM_SUPERCEDE;
	}
	
	return HAM_IGNORED;
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
			dm_print_color(id, DontChange, "^4[%s]^1 You are now headshot immune!", name);
			#else
			client_print_color(id, print_team_default, "^4[%s]^1 You are now headshot immune!", name);
			#endif
		}
	}
	
	add_bitsum(bs_HaveItem, id);
}

public Deactivate(id)
{
	del_bitsum(bs_HaveItem, id);
}
