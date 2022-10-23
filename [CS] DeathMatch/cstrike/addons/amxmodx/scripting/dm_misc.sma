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

#include <dm_core>

/* --------------------------------------------------------------------------- */

const FM_PDATA_SAFE = 2;
const OFFSET_MONEY = 115;
const OFFSET_JOININGSTATE = 125;
const FORBID_CHANGETEAM = (1<<8);

new bool:g_bBlockBuyCmds = false;
new bool:g_bRemoveMoney = false;
new bool:g_bRemoveTimer = false;
new bool:g_bRemoveRadar = false;
new bool:g_bAutoClass = false;
new bool:g_bAllowTeamChange = false;
new bool:g_bRemoveCorpse = false;

new g_iMsgHideWeapon = 0;
new g_iMsgCrosshair = 0;

new bs_HideWeapon = 0;
new bs_RemoveObjectives = 0;

new g_iFwdSpawn = 0;

enum
{
	REMOVE_TIMER = 4, /* do not change this (default value: 4) */
	REMOVE_MONEY
}

enum
{
	REMOVE_AS = 0,
	REMOVE_BUY,
	REMOVE_CS,
	REMOVE_DE
}

#define MAX_BUY_CMDS 60

new const BuyCmds[MAX_BUY_CMDS][] = { "buy", "buyammo1", "buyammo2", "buyequip", "cl_autobuy", "cl_rebuy", "cl_setautobuy",
"cl_setrebuy", "usp", "glock", "deagle", "p228", "elites", "fn57", "m3", "xm1014", "mp5", "tmp", "p90", "mac10", "ump45",
"ak47", "galil", "famas", "sg552", "m4a1", "aug", "scout", "awp", "g3sg1", "sg550", "m249", "vest", "vesthelm", "flash",
"hegren", "sgren", "defuser", "nvgs", "shield", "primammo", "secammo", "km45", "9x19mm", "nighthawk", "228compact",
"fiveseven", "12gauge", "autoshotgun", "smg", "mp", "c90", "cv47", "defender", "clarion", "krieg552", "bullpup", "magnum",
"d3au1", "krieg550" };

#define get_bitsum(%1,%2)   (%1 &   (1<<((%2-1)&31)))
#define add_bitsum(%1,%2)    %1 |=  (1<<((%2-1)&31))
#define del_bitsum(%1,%2)    %1 &= ~(1<<((%2-1)&31))

/* -Init---------------------------------------------------------------------- */

public DM_OnModStatus(status)
{
	register_plugin("DM: Misc", DM_VERSION_STR_LONG, "schmurgel1983");
	
	if (status) state enabled;
	else state deactivated;
}

public plugin_precache() <deactivated> {}
public plugin_precache() <enabled>
{
	if (!DM_LoadConfiguration("dm_misc.cfg", "DM_ReadMisc"))
	{
		state deactivated;
		return;
	}
	
	if (bs_RemoveObjectives)
	{
		if (get_bitsum(bs_RemoveObjectives, REMOVE_BUY))
		{
			new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "func_buyzone"));
			if (pev_valid(ent))
			{
				//set_pev(ent, pev_mins, {0.1,0.1,0.1});
				//set_pev(ent, pev_maxs, {0.1,0.1,0.1});
				dllfunc(DLLFunc_Spawn, ent);
				set_pev(ent, pev_solid, SOLID_NOT);
			}
		}
		g_iFwdSpawn = register_forward(FM_Spawn, "fwd_Spawn", false);
	}
}

public DM_ReadMisc(section[], key[], value[])
{
	if (equali(section, "misc"))
	{
		if (equali(key, "remove_objectives"))
		{
			if (containi(value, "a") != -1) add_bitsum(bs_RemoveObjectives, REMOVE_AS);  // as_ maps
			if (containi(value, "b") != -1) add_bitsum(bs_RemoveObjectives, REMOVE_BUY); // buyzones
			if (containi(value, "c") != -1) add_bitsum(bs_RemoveObjectives, REMOVE_CS);  // cs_ maps
			if (containi(value, "d") != -1) add_bitsum(bs_RemoveObjectives, REMOVE_DE);  // de_ maps
		}
		else if (equali(key, "block_all_buy_cmds")) g_bBlockBuyCmds = !!bool:str_to_num(value);
		else if (equali(key, "remove_money")) g_bRemoveMoney = !!bool:str_to_num(value);
		else if (equali(key, "remove_hud_timer")) g_bRemoveTimer = !!bool:str_to_num(value);
		else if (equali(key, "remove_radar")) g_bRemoveRadar = !!bool:str_to_num(value);
		else if (equali(key, "auto_joinclass")) g_bAutoClass = !!bool:str_to_num(value);
		else if (equali(key, "anti_only_1_team_change")) g_bAllowTeamChange = !!bool:str_to_num(value);
		else if (equali(key, "remove_all_corpse")) g_bRemoveCorpse = !!bool:str_to_num(value);
	}
}

public plugin_init() <deactivated> {}
public plugin_init() <enabled>
{
	if (g_iFwdSpawn) unregister_forward(FM_Spawn, g_iFwdSpawn);
	if (g_bRemoveTimer) add_bitsum(bs_HideWeapon, REMOVE_TIMER);
	if (g_bRemoveMoney) add_bitsum(bs_HideWeapon, REMOVE_MONEY);
	
	if (bs_HideWeapon)
	{
		register_event("ResetHUD", "EventResetHUD", "be");
		
		g_iMsgHideWeapon = get_user_msgid("HideWeapon");
		g_iMsgCrosshair = get_user_msgid("Crosshair");
		
		if (g_bRemoveTimer)
		{
			register_message(get_user_msgid("RoundTime"), "Msg_RoundTime");
		}
		
		if (g_bRemoveMoney)
		{
			register_message(get_user_msgid("TextMsg"), "Msg_TextMsg");
			register_message(get_user_msgid("Money"), "Msg_Money");
		}
	}
	
	if (g_bRemoveRadar)
		register_message(get_user_msgid("Radar"), "Msg_Radar");
	
	if (g_bBlockBuyCmds)
	{
		// VGUI
		register_menucmd(register_menuid("#Buy", 1), 511, "BuyCommandBlock");
		register_menucmd(register_menuid("#CT_BuyItem", 1), 511, "BuyCommandBlock");
		register_menucmd(register_menuid("#T_BuyItem", 1), 511, "BuyCommandBlock");
		register_menucmd(register_menuid("#DCT_BuyItem", 1), 511, "BuyCommandBlock");
		register_menucmd(register_menuid("#DT_BuyItem", 1), 511, "BuyCommandBlock");
		register_menucmd(register_menuid("#CT_BuyPistol", 1), 511, "BuyCommandBlock");
		register_menucmd(register_menuid("#T_BuyPistol", 1), 511, "BuyCommandBlock");
		register_menucmd(register_menuid("#AS_BuyShotgun", 1), 511, "BuyCommandBlock");
		register_menucmd(register_menuid("#BuyShotgun", 1), 511, "BuyCommandBlock");
		register_menucmd(register_menuid("#CT_BuySubMachineGun", 1), 511, "BuyCommandBlock");
		register_menucmd(register_menuid("#T_BuySubMachineGun", 1), 511, "BuyCommandBlock");
		register_menucmd(register_menuid("#AS_CT_BuySubMachineGun", 1), 511, "BuyCommandBlock");
		register_menucmd(register_menuid("#AS_T_BuySubMachineGun", 1), 511, "BuyCommandBlock");
		register_menucmd(register_menuid("#T_BuyRifle", 1), 511, "BuyCommandBlock");
		register_menucmd(register_menuid("#CT_BuyRifle", 1), 511, "BuyCommandBlock");
		register_menucmd(register_menuid("#AS_T_BuyRifle", 1), 511, "BuyCommandBlock");
		register_menucmd(register_menuid("#AS_CT_BuyRifle", 1), 511, "BuyCommandBlock");
		register_menucmd(register_menuid("#AS_T_BuyMachineGun", 1), 511, "BuyCommandBlock");
		register_menucmd(register_menuid("#BuyMachineGun", 1), 511, "BuyCommandBlock");
		register_menucmd(register_menuid("Buy", 1), 511, "BuyCommandBlock");
		register_menucmd(register_menuid("BuyPistol", 1), 511, "BuyCommandBlock");
		register_menucmd(register_menuid("BuyShotgun", 1), 511, "BuyCommandBlock");
		register_menucmd(register_menuid("BuySub", 1), 511, "BuyCommandBlock");
		register_menucmd(register_menuid("BuyRifle", 1), 511, "BuyCommandBlock");
		register_menucmd(register_menuid("BuyMachine", 1), 511, "BuyCommandBlock");
		register_menucmd(register_menuid("BuyItem", 1), 511, "BuyCommandBlock");
		
		// Old Style
		register_menucmd(-28, 511, "BuyCommandBlock");
		register_menucmd(-29, 511, "BuyCommandBlock");
		register_menucmd(-30, 511, "BuyCommandBlock");
		register_menucmd(-31, 511, "BuyCommandBlock");
		register_menucmd(-32, 511, "BuyCommandBlock");
		register_menucmd(-33, 511, "BuyCommandBlock");
		register_menucmd(-34, 511, "BuyCommandBlock");
		
		// Console
		for (new i = 0; i < MAX_BUY_CMDS; i++)
			register_clcmd(BuyCmds[i], "BuyCommandBlock");
	}
	
	if (g_bAutoClass)
	{
		register_event("ShowMenu", "EventMenu", "b", "4&CT_Select", "4&Terrorist_Select");
		register_event("VGUIMenu", "EventMenu", "b", "1=26", "1=27");
		
		register_message(get_user_msgid("VGUIMenu"), "Msg_VGUIMenu");
	}
	
	if (g_bAllowTeamChange)
		register_clcmd("chooseteam", "ClientCmdChangeteam");
	
	if (g_bRemoveCorpse)
		register_message(get_user_msgid("ClCorpse"), "Msg_ClCorpse");
}

/* -Forwards------------------------------------------------------------------ */

public fwd_Spawn(entity)
{
	if (!pev_valid(entity))
		return FMRES_IGNORED;
	
	new classname[32];
	pev(entity, pev_classname, classname, charsmax(classname));
	
	if ((equal(classname, "func_vip_safetyzone") && get_bitsum(bs_RemoveObjectives, REMOVE_AS))
	|| (equal(classname, "func_buyzone") && get_bitsum(bs_RemoveObjectives, REMOVE_BUY))
	|| (equal(classname, "hostage_entity") && get_bitsum(bs_RemoveObjectives, REMOVE_CS))
	|| (equal(classname, "func_bomb_target") && get_bitsum(bs_RemoveObjectives, REMOVE_DE)))
	{
		engfunc(EngFunc_RemoveEntity, entity);
		//forward_return(FMV_CELL, 0);
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}

/* -Cmd----------------------------------------------------------------------- */

public ClientCmdChangeteam(id)
{
	if (pev_valid(id) != FM_PDATA_SAFE)
		return;
	
	new flags = get_pdata_int(id, OFFSET_JOININGSTATE);
	if (g_bAllowTeamChange && (flags & FORBID_CHANGETEAM))
	{
		set_pdata_int(id, OFFSET_JOININGSTATE, (flags & ~FORBID_CHANGETEAM));
	}
}

public BuyCommandBlock(id)
{
	return PLUGIN_HANDLED;
}

public EventMenu(id)
{
	set_task(0.1, "DelayJoinclass", id);
}

public EventResetHUD(id)
{
	if (bs_HideWeapon && !is_user_bot(id))
	{
		set_task(0.1, "HideHUD", id);
	}
}

/* -Tasks--------------------------------------------------------------------- */

public HideHUD(id)
{
	if (!is_user_alive(id))
		return;
	
	message_begin(MSG_ONE, g_iMsgHideWeapon, _, id);
	write_byte(bs_HideWeapon);
	message_end();
	
	message_begin(MSG_ONE, g_iMsgCrosshair, _, id);
	write_byte(0);
	message_end();
}

public DelayJoinclass(id)
{
	if (!is_user_connected(id))
		return;
	
	engclient_cmd(id, "joinclass", "6");
}

/* -Messages------------------------------------------------------------------ */

public Msg_RoundTime(msg_id, msg_dest, msg_entity)
{
	return PLUGIN_HANDLED;
}

public Msg_TextMsg()
{
	if (get_msg_args() < 2 || get_msg_argtype(2) != ARG_STRING)
		return PLUGIN_CONTINUE;
	
	static textmsg[22];
	get_msg_arg_string(2, textmsg, charsmax(textmsg));
	if (equal(textmsg, "#Not_Enough_Money") || equal(textmsg, "#Alias_Not_Avail"))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public Msg_Money(msg_id, msg_dest, msg_entity)
{
	fm_cs_set_user_money(msg_entity, 0);
	
	return PLUGIN_HANDLED;
}

public Msg_Radar()
{
	return PLUGIN_HANDLED;
}

public Msg_VGUIMenu(msg_id, msg_dest, msg_entity)
{
	if (msg_dest != MSG_ONE || get_msg_arg_int(1) == 2)
		return PLUGIN_CONTINUE;
	
	return PLUGIN_HANDLED;
}

public Msg_ClCorpse(msg_id, msg_dest, msg_entity)
{
	return PLUGIN_HANDLED;
}

/* -Stocks-------------------------------------------------------------------- */

stock fm_cs_set_user_money(id, value)
{
	if (pev_valid(id) != FM_PDATA_SAFE)
		return;
	
	set_pdata_int(id, OFFSET_MONEY, value);
}
