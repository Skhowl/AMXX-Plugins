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
#pragma dynamic 32768 // 128kb

#include <amxmodx>
#include <fakemeta>

#include <dm_core>
#include <dm_spawn>
#include <dm_scenarios>
#include <dm_rewards>
#include <dm_colorchat>
#include <dm_log>

/* --------------------------------------------------------------------------- */

const MAX_ITEMS_USED = 3;
const MAX_STATS_SAVED = 64;

/* --------------------------------------------------------------------------- */

#define TASK_ANNOUNCE 99999
#define TASK_HUD 65535 // if you have more as 2046 items, increase this value :)
#define ID_HUDMESSAGE (taskid - TASK_HUD)

#define HUD_RED 255
#define HUD_GREEN 255
#define HUD_BLUE 255
#define HUD_STATS_X 0.8
#define HUD_STATS_Y -1.0

/* --------------------------------------------------------------------------- */

new g_iPluginID = 0;

new g_iHudSyncItems = 0;
new g_iHudSyncStatus = 0;
new bool:g_bFreezeTime = false;
new bool:g_bRoundEnd = false;
new bool:g_bIntermission = false;

new bool:g_bEnabled = false;
new g_iHoldTimeSystem = 0;
new Float:g_fItemCostMultiplier = 1.0;
new g_iBotChance = 0;
new g_iShowPlayerItems = 0;

new g_iTeamID[DM_MAX_PLAYERS+1] = { 0, ... };
new g_iStatusFriendly[DM_MAX_PLAYERS+1] = { 0, ... };
new Trie:g_tItemChat = Invalid_Trie;
new g_szItemName[DM_MAX_PLAYERS+1][MAX_ITEMS_USED][32];
new g_iItemDuration[DM_MAX_PLAYERS+1][MAX_ITEMS_USED];
new g_iItemID[DM_MAX_PLAYERS+1][MAX_ITEMS_USED];
new g_iDatabaseSlot[DM_MAX_PLAYERS+1] = -1;

new db_szPlayerName[MAX_STATS_SAVED][32];
new db_iItemDuration[MAX_STATS_SAVED][MAX_ITEMS_USED];
new db_iItemID[MAX_STATS_SAVED][MAX_ITEMS_USED];
new db_iSlot;

const FM_PDATA_SAFE = 2;
const OFFSET_CSMENUCODE = 205;

const PEV_SPEC_TARGET = pev_iuser2;

new Array:g_aItemRealName = Invalid_Array;
new Array:g_aItemName = Invalid_Array;
new Array:g_aItemChat = Invalid_Array;
new Array:g_aItemTeams = Invalid_Array;
new Array:g_aItemCost = Invalid_Array;
new Array:g_aItemHoldTime = Invalid_Array;
new Array:g_aItemActivate = Invalid_Array;
new Array:g_aItemDeactivate = Invalid_Array;
new g_iItemCount = 0;

new Array:g_aItem2RealName = Invalid_Array;
new Array:g_aItem2Name = Invalid_Array;
new Array:g_aItem2Chat = Invalid_Array;
new Array:g_aItem2Teams = Invalid_Array;
new Array:g_aItem2Cost = Invalid_Array;
new Array:g_aItem2HoldTime = Invalid_Array;
new Array:g_aItemNew = Invalid_Array;

new const DM_TEAM_NAMES[][] = { "TERROR , CT", "TERROR", "CT", "TERROR , CT" };

// g_iHoldTimeSystem
enum
{
	SYSTEM_TIME = 0,
	SYSTEM_ROUND,
	SYSTEM_MAP
}

new bs_IsConnected = 0;
new bs_IsAlive = 0;
new bs_IsBot = 0;
new bs_HaveSavedStats = 0;

#define get_bitsum(%1,%2)   (%1 &   (1<<((%2-1)&31)))
#define add_bitsum(%1,%2)    %1 |=  (1<<((%2-1)&31))
#define del_bitsum(%1,%2)    %1 &= ~(1<<((%2-1)&31))

#if AMXX_VERSION_NUM < 183
new g_iMaxPlayers = 0;
#define is_user_valid_connected(%1) (1 <= %1 <= g_iMaxPlayers && get_bitsum(bs_IsConnected, %1))
#else
#define is_user_valid_connected(%1) (1 <= %1 <= MaxClients && get_bitsum(bs_IsConnected, %1))
#endif
#define is_valid_item_slot(%1)		(1 <= %1 <= MAX_ITEMS_USED)

/* -Init---------------------------------------------------------------------- */

public plugin_natives()
{
	register_native("DM_RegisterItem", "native_register_item");
	register_native("DM_GetItemUniqueId", "native_get_unique");
	register_native("DM_GetItemDisplayName", "native_get_display_name");
	register_native("DM_ForceBuyItem", "native_force_buyitem");
	register_library("dm_items");
}

public DM_OnModStatus(status)
{
	g_iPluginID = register_plugin("DM: Items", DM_VERSION_STR_LONG, "schmurgel1983");
	
	if (status) state enabled;
	else state deactivated;
}

public plugin_precache() <deactivated> {}
public plugin_precache() <enabled>
{
	if (!DM_LoadConfiguration("dm_items.cfg", "DM_ReadItems") || !g_bEnabled)
	{
		state deactivated;
		return;
	}
	
	g_tItemChat = TrieCreate();
	
	g_aItemRealName = ArrayCreate(32, 1);
	g_aItemName = ArrayCreate(32, 1);
	g_aItemChat = ArrayCreate(32, 1);
	g_aItemTeams = ArrayCreate(1, 1);
	g_aItemCost = ArrayCreate(1, 1);
	g_aItemHoldTime = ArrayCreate(1, 1);
	g_aItemActivate = ArrayCreate(1, 1);
	g_aItemDeactivate = ArrayCreate(1, 1);
	
	g_aItem2RealName = ArrayCreate(32, 1);
	g_aItem2Name = ArrayCreate(32, 1);
	g_aItem2Chat = ArrayCreate(32, 1);
	g_aItem2Teams = ArrayCreate(1, 1);
	g_aItem2Cost = ArrayCreate(1, 1);
	g_aItem2HoldTime = ArrayCreate(1, 1);
	g_aItemNew = ArrayCreate(1, 1);
	
	LoadItemFile();
}

public DM_ReadItems(section[], key[], value[])
{
	if (equali(section, "items"))
	{
		if (equali(key, "enabled")) g_bEnabled = !!bool:str_to_num(value);
		else if (equali(key, "hold_time_system")) g_iHoldTimeSystem = clamp(str_to_num(value), SYSTEM_TIME, SYSTEM_MAP);
		else if (equali(key, "item_cost_multiplier")) g_fItemCostMultiplier = floatclamp(str_to_float(value), 0.0, 999999.0);
		else if (equali(key, "bot_buy_item_chance")) g_iBotChance = clamp(str_to_num(value), 0, 100);
		else if (equali(key, "show_player_items")) g_iShowPlayerItems = clamp(str_to_num(value), 0, 2);
	}
}

public plugin_init() <deactivated> {}
public plugin_init() <enabled>
{
	#if AMXX_VERSION_NUM < 183
	register_dictionary_colored("dm_items.txt");
	#else
	register_dictionary("dm_items.txt");
	#endif
	register_dictionary("common.txt");
	
	register_event("HLTV", "EventRoundStart", "a", "1=0", "2=0");
	register_event("TextMsg", "EventRoundEnd", "a", "2=#Game_Commencing", "2=#Game_will_restart_in");
	register_logevent("LogEventRoundStart", 2, "1=Round_Start");
	register_logevent("EventRoundEnd", 2, "1=Round_End");
	
	register_clcmd("say", "HandleSay");
	register_clcmd("say_team", "HandleSay");
	
	register_message(get_user_msgid("TeamInfo"), "Msg_TeamInfo");
	if (g_iShowPlayerItems > 0)
	{
		register_message(get_user_msgid("StatusValue"), "Msg_StatusValue");
		g_iHudSyncStatus = CreateHudSyncObj();
		
		set_task(5.0, "delayed_cvars", _, _, _, "a", 4);
	}
	
	g_iHudSyncItems = CreateHudSyncObj();
	
	#if AMXX_VERSION_NUM < 183
	g_iMaxPlayers = get_maxplayers();
	db_iSlot = g_iMaxPlayers + 1;
	#else
	db_iSlot = MaxClients + 1;
	#endif
}

public plugin_cfg() <deactivated> {}
public plugin_cfg() <enabled>
{
	SaveItemFile();
	
	new ConfigDir[48];
	get_configsdir(ConfigDir, charsmax(ConfigDir));
	
	// Execute additional config file (dm_items_additional.cfg)
	server_cmd("exec %s/deathmatch/dm_items_additional.cfg", ConfigDir);
}

public plugin_end() <deactivated> {}
public plugin_end() <enabled>
{
	TrieDestroy(g_tItemChat);
	DestroyArrays(1, 0);
}

public delayed_cvars()
{
	server_cmd("mp_playerid 2");
}

/* -Client-------------------------------------------------------------------- */

public client_putinserver(id) <deactivated> {}
public client_putinserver(id) <enabled>
{
	add_bitsum(bs_IsConnected, id);
	
	for (new index = 0; index < MAX_ITEMS_USED; index++)
	{
		g_szItemName[id][index][0] = 0;
		g_iItemDuration[id][index] = -1;
		g_iItemID[id][index] = -1;
	}
	DM_LoadStats(id);
	
	if (is_user_bot(id))
	{
		add_bitsum(bs_IsBot, id);
	}
	else
	{
		set_task(1.0, "ShowHudMessage", id+TASK_HUD, _, _, "b");
	}
}

#if AMXX_VERSION_NUM < 183
public client_disconnect(id) <deactivated> {}
public client_disconnect(id) <enabled>
#else
public client_disconnected(id, bool:drop, message[], maxlen) <deactivated> {}
public client_disconnected(id, bool:drop, message[], maxlen) <enabled>
#endif
{
	del_bitsum(bs_IsConnected, id);
	del_bitsum(bs_IsAlive, id);
	del_bitsum(bs_IsBot, id);
	del_bitsum(bs_HaveSavedStats, id);
	
	remove_task(id+TASK_HUD);
	
	DM_SaveStats(id);
	g_iDatabaseSlot[id] = -1;
	
	for (new index = 0; index < MAX_ITEMS_USED; index++)
	{
		if (g_iItemID[id][index] == -1) continue;
		if (g_iHoldTimeSystem == SYSTEM_TIME) remove_task(id + g_iItemID[id][index]*32);
		
		g_szItemName[id][index][0] = 0;
		g_iItemDuration[id][index] = -1;
		g_iItemID[id][index] = -1;
	}
}

/* -Spawn--------------------------------------------------------------------- */

public DM_PlayerSpawn_Post(id, freezetime, roundend) <deactivated> {}
public DM_PlayerSpawn_Post(id, freezetime, roundend) <enabled>
{
	add_bitsum(bs_IsAlive, id);
	
	if (g_bRoundEnd || g_bIntermission)
		return;
	
	if (get_bitsum(bs_HaveSavedStats, id))
		DM_RestoreStats(id);
	
	if (g_iItemCount && get_bitsum(bs_IsBot, id) && random_num(1, 100) <= g_iBotChance)
		BuyItem(id, random(g_iItemCount));
}

public DM_PlayerKilled_Pre(victim, attacker) <deactivated> {}
public DM_PlayerKilled_Pre(victim, attacker) <enabled>
{
	del_bitsum(bs_IsAlive, victim);
}

/* -Events-------------------------------------------------------------------- */

public EventRoundStart()
{
	g_bFreezeTime = true;
	g_bRoundEnd = false;
	
	if (g_iHoldTimeSystem == SYSTEM_ROUND)
	{
		static id, index, itemid, DummyResult;
		
		#if AMXX_VERSION_NUM < 183
		for (id = 1; id <= g_iMaxPlayers; id++)
		#else
		for (id = 1; id <= MaxClients; id++)
		#endif
		{
			if (!get_bitsum(bs_IsConnected, id))
				continue;
			
			for (index = 0; index < MAX_ITEMS_USED; index++)
			{
				itemid = g_iItemID[id][index];
				if (itemid == -1)
					continue;
				
				ExecuteForward(ArrayGetCell(g_aItemDeactivate, itemid), DummyResult, id);
				
				g_szItemName[id][index][0] = 0;
				g_iItemDuration[id][index] = -1;
				g_iItemID[id][index] = -1;
			}
		}
	}
	
	remove_task(TASK_ANNOUNCE);
	set_task(2.0, "ShowItemAnnounce", TASK_ANNOUNCE);
}

public EventRoundEnd()
{
	g_bRoundEnd = true;
	
	remove_task(TASK_ANNOUNCE);
}

public LogEventRoundStart()
{
	g_bFreezeTime = false;
}

/* -Scenarios----------------------------------------------------------------- */

public DM_OnIntermission()
{
	g_bIntermission = true;
}

/* -Say----------------------------------------------------------------------- */

public HandleSay(id)
{
	if (g_iTeamID[id] == DM_TEAM_UNASSIGNED || g_iTeamID[id] == DM_TEAM_SPECTATOR)
		return PLUGIN_CONTINUE;
	
	new szText[70], szCommand[33], szTimes[33];
	read_args(szText, 69);
	remove_quotes(szText);
	parse(szText, szCommand, 32, szTimes, 32);
	
	new iReturn = PLUGIN_CONTINUE;
	switch (szCommand[0])
	{
		case '!', '.': // Handled
		{
			format(szCommand, 32, szCommand[1]);
			iReturn = PLUGIN_HANDLED;
		}
		case '/', '@': // Continue
		{
			format(szCommand, 32, szCommand[1]);
		}
	}
	
	if (equali(szCommand, "shop") || equali(szCommand, "item", 4)/* || equali(szCommand, "items")*/)
	{
		ShowShopMenu(id);
		return iReturn;
	}
	
	if (equali(szCommand, "delete") || equali(szCommand, "clear") || equali(szCommand, "erase"))
	{
		new index;
		if (TrieKeyExists(g_tItemChat, szTimes) && TrieGetCell(g_tItemChat, szTimes, index))
		{
			new i, itemid;
			for (i = 0; i < MAX_ITEMS_USED; i++)
			{
				itemid = g_iItemID[id][i];
				if (index != itemid)
					continue;
				
				if (g_iHoldTimeSystem == SYSTEM_TIME)
				{
					if (task_exists(id + itemid*32) && remove_task(id + itemid*32))
					{
						new DummyResult;
						ExecuteForward(ArrayGetCell(g_aItemDeactivate, itemid), DummyResult, id);
						
						g_szItemName[id][i][0] = 0;
						g_iItemDuration[id][i] = -1;
						g_iItemID[id][i] = -1;
					}
					else
					{
						DM_Log(LOG_ERROR, "Task not exists or removed (%d + %d*32)", id, itemid);
						DM_LogPlugin(LOG_ERROR, g_iPluginID, "HandleSay", 1);
					}
				}
				else
				{
					new DummyResult;
					ExecuteForward(ArrayGetCell(g_aItemDeactivate, itemid), DummyResult, id);
					
					g_szItemName[id][i][0] = 0;
					g_iItemDuration[id][i] = -1;
					g_iItemID[id][i] = -1;
				}
				
				return iReturn;
			}
		}
		
		index = str_to_num(szTimes);
		if (is_valid_item_slot(index))
		{
			index -= 1;
			new itemid = g_iItemID[id][index];
			if (itemid == -1)
			{
				#if AMXX_VERSION_NUM < 183
				dm_print_color(id, DontChange, "^4[DM-Shop]^1 %L", id, "DM_ITEM_EMPTY", index + 1);
				#else
				client_print_color(id, print_team_default, "^4[DM-Shop]^1 %L", id, "DM_ITEM_EMPTY", index + 1);
				#endif
				return iReturn;
			}
			
			if (g_iHoldTimeSystem == SYSTEM_TIME)
			{
				if (task_exists(id + itemid*32) && remove_task(id + itemid*32))
				{
					new DummyResult;
					ExecuteForward(ArrayGetCell(g_aItemDeactivate, itemid), DummyResult, id);
					
					g_szItemName[id][index][0] = 0;
					g_iItemDuration[id][index] = -1;
					g_iItemID[id][index] = -1;
				}
				else
				{
					DM_Log(LOG_ERROR, "Task not exists or removed (%d + %d*32)", id, itemid);
					DM_LogPlugin(LOG_ERROR, g_iPluginID, "HandleSay", 2);
				}
			}
			else
			{
				new DummyResult;
				ExecuteForward(ArrayGetCell(g_aItemDeactivate, itemid), DummyResult, id);
				
				g_szItemName[id][index][0] = 0;
				g_iItemDuration[id][index] = -1;
				g_iItemID[id][index] = -1;
			}
			
			return iReturn;
		}
		else
		{
			#if AMXX_VERSION_NUM < 183
			dm_print_color(id, DontChange, "^4[DM-Shop]^1 %L", id, "DM_ITEM_DELETE_USAGE");
			#else
			client_print_color(id, print_team_default, "^4[DM-Shop]^1 %L", id, "DM_ITEM_DELETE_USAGE");
			#endif
		}
		
		return iReturn;
	}
	
	if (TrieKeyExists(g_tItemChat, szCommand))
	{
		static index;
		if (TrieGetCell(g_tItemChat, szCommand, index))
		{
			new iTimes = clamp(str_to_num(szTimes), 1, 10);
			BuyItem(id, index, iTimes);
		}
		
		return iReturn;
	}
	
	return PLUGIN_CONTINUE;
}

/* -Misc---------------------------------------------------------------------- */

public ShowItemAnnounce()
{
	#if AMXX_VERSION_NUM < 183
	dm_print_color(0, Red, "^4[DM-Shop]^1 %L", LANG_SERVER, "DM_ITEM_CHAT");
	dm_print_color(0, DontChange, "^4[DM-Shop]^1 %L", LANG_SERVER, "DM_ITEM_DELETE_USAGE");
	#else
	client_print_color(0, print_team_red, "^4[DM-Shop]^1 %L", LANG_SERVER, "DM_ITEM_CHAT");
	client_print_color(0, print_team_default, "^4[DM-Shop]^1 %L", LANG_SERVER, "DM_ITEM_DELETE_USAGE");
	#endif
}

DestroyArrays(pack1, pack2)
{
	if (pack1)
	{
		ArrayDestroy(g_aItemRealName);
		ArrayDestroy(g_aItemName);
		ArrayDestroy(g_aItemChat);
		ArrayDestroy(g_aItemTeams);
		ArrayDestroy(g_aItemCost);
		ArrayDestroy(g_aItemHoldTime);
		ArrayDestroy(g_aItemActivate);
		ArrayDestroy(g_aItemDeactivate);
	}
	
	if (pack2)
	{
		ArrayDestroy(g_aItem2RealName);
		ArrayDestroy(g_aItem2Name);
		ArrayDestroy(g_aItem2Chat);
		ArrayDestroy(g_aItem2Teams);
		ArrayDestroy(g_aItem2Cost);
		ArrayDestroy(g_aItem2HoldTime);
		ArrayDestroy(g_aItemNew);
	}
}

/* -Menu---------------------------------------------------------------------- */

ShowShopMenu(id)
{
	if (!get_bitsum(bs_IsConnected, id) || g_iTeamID[id] == DM_TEAM_UNASSIGNED || g_iTeamID[id] == DM_TEAM_SPECTATOR)
		return;
	
	static menuid, menu[128], item, team, holdtime, buffer[32];
	
	switch (g_iHoldTimeSystem) // (Cost and duration are subject to change, at any time.)
	{
		case SYSTEM_ROUND: formatex(menu, charsmax(menu), "DM: Shop Menu \r%L^n\w%L\r", id, "DM_ITEM_SUBJECT", id, "DM_ITEM_ROUND");
		case SYSTEM_MAP: formatex(menu, charsmax(menu), "DM: Shop Menu \r%L^n\w%L\r", id, "DM_ITEM_SUBJECT", id, "DM_ITEM_MAP");
		default: formatex(menu, charsmax(menu), "DM: Shop Menu \r%L^n\w%L\r", id, "DM_ITEM_SUBJECT", id, "DM_ITEM_TIME");
	}
	menuid = menu_create(menu, "HandleShopMenu");
	
	for (item = 0; item < g_iItemCount; item++)
	{
		team = ArrayGetCell(g_aItemTeams, item);
		if ((g_iTeamID[id] == DM_TEAM_T && !(team & DM_TEAM_T)) || (g_iTeamID[id] == DM_TEAM_CT && !(team & DM_TEAM_CT)))
			continue;
		
		ArrayGetString(g_aItemName, item, buffer, charsmax(buffer));
		if (g_iHoldTimeSystem == SYSTEM_TIME)
		{
			holdtime = ArrayGetCell(g_aItemHoldTime, item);
			formatex(menu, charsmax(menu), "\y%d:%02d $%d \w%s", (holdtime / 60), (holdtime % 60), floatround(float(ArrayGetCell(g_aItemCost, item)) * g_fItemCostMultiplier), buffer);
		}
		else formatex(menu, charsmax(menu), "\y$%d \w%s", floatround(float(ArrayGetCell(g_aItemCost, item)) * g_fItemCostMultiplier), buffer);
		
		buffer[0] = item;
		buffer[1] = 0;
		menu_additem(menuid, menu, buffer);
	}
	
	if (menu_items(menuid) <= 0)
	{
		#if AMXX_VERSION_NUM < 183
		dm_print_color(id, DontChange, "^4[DM-Shop]^1 %L", id, "DM_ITEM_NO_ITEM_TEAM");
		#else
		client_print_color(id, print_team_default, "^4[DM-Shop]^1 %L", id, "DM_ITEM_NO_ITEM_TEAM");
		#endif
		menu_destroy(menuid);
		return;
	}
	
	formatex(menu, charsmax(menu), "%L", id, "BACK");
	menu_setprop(menuid, MPROP_BACKNAME, menu);
	formatex(menu, charsmax(menu), "%L", id, "MORE");
	menu_setprop(menuid, MPROP_NEXTNAME, menu);
	formatex(menu, charsmax(menu), "%L", id, "EXIT");
	menu_setprop(menuid, MPROP_EXITNAME, menu);
	
	if (pev_valid(id) == FM_PDATA_SAFE)
		set_pdata_int(id, OFFSET_CSMENUCODE, 0);
	
	menu_display(id, menuid);
}

public HandleShopMenu(id, menuid, item)
{
	if (!get_bitsum(bs_IsConnected, id) || item == MENU_EXIT)
	{
		menu_destroy(menuid);
		return PLUGIN_HANDLED;
	}
	
	static buffer[2], dummy, itemid;
	menu_item_getinfo(menuid, item, dummy, buffer, charsmax(buffer), .callback=dummy);
	itemid = buffer[0];
	
	BuyItem(id, itemid);
	menu_destroy(menuid);
	/* ShowShopMenu(id) */
	return PLUGIN_HANDLED;
}

/* --------------------------------------------------------------------------- */

BuyItem(id, itemid, count = 1)
{
	if (!get_bitsum(bs_IsConnected, id) || g_iTeamID[id] == DM_TEAM_UNASSIGNED || g_iTeamID[id] == DM_TEAM_SPECTATOR)
		return 0;
	
	static team;
	team = ArrayGetCell(g_aItemTeams, itemid);
	if ((g_iTeamID[id] == DM_TEAM_T && !(team & DM_TEAM_T)) || (g_iTeamID[id] == DM_TEAM_CT && !(team & DM_TEAM_CT)))
	{
		#if AMXX_VERSION_NUM < 183
		dm_print_color(id, DontChange, "^4[DM-Shop]^1 %L", id, "DM_ITEM_IS_NOT_TEAM");
		#else
		client_print_color(id, print_team_default, "^4[DM-Shop]^1 %L", id, "DM_ITEM_IS_NOT_TEAM");
		#endif
		return 0;
	}
	
	if (g_iHoldTimeSystem != SYSTEM_TIME)
	{
		count = 1;
	}
	
	static cost;
	cost = floatround(float(ArrayGetCell(g_aItemCost, itemid) * count) * g_fItemCostMultiplier);
	if (DM_GetUserMoney(id) < cost)
	{
		#if AMXX_VERSION_NUM < 183
		dm_print_color(id, DontChange, "^4[DM-Shop]^1 %L", id, "DM_ITEM_NO_MONEY");
		#else
		client_print_color(id, print_team_default, "^4[DM-Shop]^1 %L", id, "DM_ITEM_NO_MONEY");
		#endif
		return 0;
	}
	
	new szItemName[32], bool:item = false, bool:old_item = false;
	ArrayGetString(g_aItemName, itemid, szItemName, charsmax(szItemName));
	
	// check old items
	new index = -1;
	while (++index < MAX_ITEMS_USED)
	{
		if (equal(g_szItemName[id][index], szItemName))
		{
			item = old_item = true;
			break;
		}
	}
	
	// check if new item
	if (!old_item)
	{
		index = -1;
		while (++index < MAX_ITEMS_USED)
		{
			if (!g_szItemName[id][index][0])
			{
				item = true;
				break;
			}
		}
	}
	
	if (!item)
	{
		#if AMXX_VERSION_NUM < 183
		dm_print_color(id, DontChange, "^4[DM-Shop]^1 %L", id, "DM_ITEM_LIMIT");
		#else
		client_print_color(id, print_team_default, "^4[DM-Shop]^1 %L", id, "DM_ITEM_LIMIT");
		#endif
		return 0;
	}
	
	if (g_iHoldTimeSystem != SYSTEM_TIME && old_item)
	{
		#if AMXX_VERSION_NUM < 183
		dm_print_color(id, DontChange, "^4[DM-Shop]^1 %L", id, "DM_ITEM_ALREADY", szItemName);
		#else
		client_print_color(id, print_team_default, "^4[DM-Shop]^1 %L", id, "DM_ITEM_ALREADY", szItemName);
		#endif
		return 1;
	}
	
	DM_SetUserMoney(id, DM_GetUserMoney(id) - cost, 1);
	
	copy(g_szItemName[id][index], charsmax(g_szItemName[][]), szItemName);
	g_iItemDuration[id][index] += ArrayGetCell(g_aItemHoldTime, itemid) * count + count;
	g_iItemID[id][index] = itemid;
	
	static DummyResult;
	ExecuteForward(ArrayGetCell(g_aItemActivate, itemid), DummyResult, id);
	
	if (g_iHoldTimeSystem == SYSTEM_TIME)
	{
		#if AMXX_VERSION_NUM < 183
		dm_print_color(id, DontChange, "^4[DM-Shop]^1 %L", id, "DM_ITEM_SEVERAL");
		#else
		client_print_color(id, print_team_default, "^4[DM-Shop]^1 %L", id, "DM_ITEM_SEVERAL");
		#endif
		
		static args[2];
		args[0] = id;
		args[1] = index;
		
		if (!task_exists(id + itemid*32))
			set_task(1.0, "ItemHoldTime", id + itemid*32, args, sizeof args, "b");
	}
	
	return 1;
}

DM_SaveStats(id)
{
	new szName[32]; get_user_name(id, szName, charsmax(szName));
	
	static index;
	if (db_szPlayerName[id][0] && !equal(szName, db_szPlayerName[id]))
	{
		if (db_iSlot >= MAX_STATS_SAVED)
		{
			#if AMXX_VERSION_NUM < 183
			db_iSlot = g_iMaxPlayers + 1;
			#else
			db_iSlot = MaxClients + 1;
			#endif
		}
		
		copy(db_szPlayerName[db_iSlot], charsmax(db_szPlayerName[]), db_szPlayerName[id]);
		for (index = 0; index < MAX_ITEMS_USED; index++)
		{
			db_iItemDuration[db_iSlot][index] = db_iItemDuration[id][index];
			db_iItemID[db_iSlot][index] = db_iItemID[id][index];
		}
		db_iSlot++;
	}
	
	copy(db_szPlayerName[id], charsmax(db_szPlayerName[]), szName);
	for (index = 0; index < MAX_ITEMS_USED; index++)
	{
		db_iItemDuration[id][index] = g_iItemDuration[id][index];
		db_iItemID[id][index] = g_iItemID[id][index];
	}
}

DM_LoadStats(id)
{
	new szName[32]; get_user_name(id, szName, charsmax(szName));
	
	for (new i = 0; i < MAX_STATS_SAVED; i++)
	{
		if (equal(szName, db_szPlayerName[i]))
		{
			// Bingo!
			add_bitsum(bs_HaveSavedStats, id);
			g_iDatabaseSlot[id] = i;
			return;
		}
	}
}

DM_RestoreStats(id)
{
	if (!get_bitsum(bs_IsConnected, id))
		return;
	
	del_bitsum(bs_HaveSavedStats, id);
	
	for (new index = 0; index < MAX_ITEMS_USED; index++)
	{
		RestoreItem(id, db_iItemID[g_iDatabaseSlot[id]][index], db_iItemDuration[g_iDatabaseSlot[id]][index], index);
	}
	g_iDatabaseSlot[id] = -1;
}

RestoreItem(id, itemid, duration, index)
{
	if (!get_bitsum(bs_IsConnected, id) || itemid == -1 || duration == -1)
		return;
	
	static team;
	team = ArrayGetCell(g_aItemTeams, itemid);
	if ((g_iTeamID[id] == DM_TEAM_T && !(team & DM_TEAM_T)) || (g_iTeamID[id] == DM_TEAM_CT && !(team & DM_TEAM_CT)))
		return;
	
	new szItemName[32];
	ArrayGetString(g_aItemName, itemid, szItemName, charsmax(szItemName));
	copy(g_szItemName[id][index], charsmax(g_szItemName[][]), szItemName);
	g_iItemDuration[id][index] = duration;
	g_iItemID[id][index] = itemid;
	
	static DummyResult;
	ExecuteForward(ArrayGetCell(g_aItemActivate, itemid), DummyResult, id);
	
	if (g_iHoldTimeSystem == SYSTEM_TIME)
	{
		static args[2]; args[0] = id; args[1] = index;
		
		if (!task_exists(id + itemid*32))
			set_task(1.0, "ItemHoldTime", id + itemid*32, args, sizeof args, "b");
	}
}

public ItemHoldTime(const args[], taskid)
{
	new id = args[0];
	if (!get_bitsum(bs_IsAlive, id) || g_bFreezeTime || g_bRoundEnd)
		return;
	
	new index = args[1];
	if (g_iItemDuration[id][index] < 1)
	{
		if (remove_task(taskid))
		{
			new DummyResult;
			ExecuteForward(ArrayGetCell(g_aItemDeactivate, g_iItemID[id][index]), DummyResult, id);
			
			g_szItemName[id][index][0] = 0;
			g_iItemDuration[id][index] = -1;
			g_iItemID[id][index] = -1;
		}
		else
		{
			DM_Log(LOG_ERROR, "Task not removed (%d + %d*32) (%d = %d)", id, g_iItemID[id][index], id + g_iItemID[id][index]*32, taskid);
			DM_LogPlugin(LOG_ERROR, g_iPluginID, "ItemHoldTime", 3);
		}
		
		return;
	}
	
	g_iItemDuration[id][index]--;
}

public ShowHudMessage(taskid)
{
	new player = ID_HUDMESSAGE;
	
	if (g_iTeamID[player] == DM_TEAM_UNASSIGNED)
		return;
	
	if (!get_bitsum(bs_IsAlive, player) && g_iTeamID[player] == DM_TEAM_SPECTATOR)
	{
		player = pev(player, PEV_SPEC_TARGET);
		
		if (!player || !get_bitsum(bs_IsConnected, player))
			return;
	}
	
	new HudMessage[256], length;
	length += formatex(HudMessage, charsmax(HudMessage), "%L:  $%d", player, "DM_ITEM_HUD_ACTIVE", DM_GetUserMoney(player));
	
	static index, holdtime;
	for (index = 0; index < MAX_ITEMS_USED; index++)
	{
		holdtime = g_iItemDuration[player][index];
		if (holdtime < 0)
		{
			if (g_iHoldTimeSystem == SYSTEM_TIME) length += formatex(HudMessage[length], charsmax(HudMessage) - length, "^n%d. 0:00 - %L", index+1, player, "DM_ITEM_HUD_EMPTY");
			else length += formatex(HudMessage[length], charsmax(HudMessage) - length, "^n%d. %L", index+1, player, "DM_ITEM_HUD_EMPTY");
		}
		else
		{
			if (g_iHoldTimeSystem == SYSTEM_TIME) length += formatex(HudMessage[length], charsmax(HudMessage) - length, "^n%d. %d:%02d - %s", index+1, (holdtime / 60), (holdtime % 60), g_szItemName[player][index]);
			else length += formatex(HudMessage[length], charsmax(HudMessage) - length, "^n%d. %s", index+1, g_szItemName[player][index]);
		}
	}
	
	set_hudmessage(HUD_RED, HUD_GREEN, HUD_BLUE, HUD_STATS_X, HUD_STATS_Y, 0, 6.0, 1.1, 0.0, 0.1, -1);
	if (player != ID_HUDMESSAGE) ShowSyncHudMsg(ID_HUDMESSAGE, g_iHudSyncItems, "%s", HudMessage);
	else ShowSyncHudMsg(player, g_iHudSyncItems, "%s", HudMessage);
	
}

/* --------------------------------------------------------------------------- */

LoadItemFile()
{
	new ConfigDir[128], ConfigFile[128];
	get_configsdir(ConfigDir, charsmax(ConfigDir));
	format(ConfigFile, charsmax(ConfigFile), "%s/deathmatch/dm_items.ini", ConfigDir);
	
	if (!file_exists(ConfigFile))
	{
		new error[100];
		formatex(error, charsmax(error), "Item file ^"%s^" not present.", ConfigFile);
		set_fail_state(error);
		return;
	}
	
	new File = fopen(ConfigFile, "rt");
	if (!File)
	{
		new error[100];
		formatex(error, charsmax(error), "Can't open item file: %s", ConfigFile);
		set_fail_state(error);
		return;
	}
	
	new linedata[1024], key[64], value[960], teams;
	while (!feof(File))
	{
		fgets(File, linedata, charsmax(linedata));
		
		replace(linedata, charsmax(linedata), "^n", "");
		
		if (!linedata[0] || linedata[0] == ';') continue;
		
		if (linedata[0] == '[')
		{
			copyc(linedata, charsmax(linedata), linedata[1], ']');
			
			ArrayPushString(g_aItem2RealName, linedata);
			continue;
		}
		
		strtok(linedata, key, charsmax(key), value, charsmax(value), '=');
		trim(key);
		trim(value);
		
		if (equal(key, "NAME")) ArrayPushString(g_aItem2Name, value);
		else if (equal(key, "CHAT")) ArrayPushString(g_aItem2Chat, value);
		else if (equal(key, "TEAMS"))
		{
			teams = 0;
			
			while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
			{
				trim(key);
				trim(value);
				
				if (equal(key, DM_TEAM_NAMES[DM_TEAM_T]))
					teams |= DM_TEAM_T;
				else if (equal(key, DM_TEAM_NAMES[DM_TEAM_CT]))
					teams |= DM_TEAM_CT;
			}
			
			ArrayPushCell(g_aItem2Teams, teams);
		}
		else if (equal(key, "COST"))
			ArrayPushCell(g_aItem2Cost, str_to_num(value));
		else if (equal(key, "HOLD TIME"))
			ArrayPushCell(g_aItem2HoldTime, str_to_num(value));
	}
	fclose(File);
}

SaveItemFile()
{
	new ConfigDir[128], ConfigFile[128];
	get_configsdir(ConfigDir, charsmax(ConfigDir));
	format(ConfigFile, charsmax(ConfigFile), "%s/deathmatch/dm_items.ini", ConfigDir);
	
	new File = fopen(ConfigFile, "at");
	if (!File)
		return;
	
	new index, Buffer[512];
	new size = ArraySize(g_aItemName);
	
	for (index = 0; index < size; index++)
	{
		if (ArrayGetCell(g_aItemNew, index))
		{
			ArrayGetString(g_aItemRealName, index, Buffer, charsmax(Buffer));
			format(Buffer, charsmax(Buffer), "^n[%s]", Buffer);
			fputs(File, Buffer);
			
			ArrayGetString(g_aItemName, index, Buffer, charsmax(Buffer));
			format(Buffer, charsmax(Buffer), "^nNAME = %s", Buffer);
			fputs(File, Buffer);
			
			ArrayGetString(g_aItemChat, index, Buffer, charsmax(Buffer));
			format(Buffer, charsmax(Buffer), "^nCHAT = %s", Buffer);
			fputs(File, Buffer);
			
			formatex(Buffer, charsmax(Buffer), "^nTEAMS = %s", DM_TEAM_NAMES[ArrayGetCell(g_aItemTeams, index)]);
			fputs(File, Buffer);
			
			formatex(Buffer, charsmax(Buffer), "^nCOST = %d", ArrayGetCell(g_aItemCost, index));
			fputs(File, Buffer);
			
			formatex(Buffer, charsmax(Buffer), "^nHOLD TIME = %d^n", ArrayGetCell(g_aItemHoldTime, index));
			fputs(File, Buffer);
		}
	}
	fclose(File);
	
	DestroyArrays(0, 1);
}

DM_ShowPlayerItems(const id, const aimed)
{
	if (!get_bitsum(bs_IsAlive, id) || !get_bitsum(bs_IsAlive, aimed) || get_bitsum(bs_IsBot, id))
		return;
	
	static szMessage[512], szName[32], index;
	
	new iRed = 0, iBlue = 0, iPos = 0;
	if (g_iTeamID[aimed] == 1) iRed = 255;
	else iBlue = 255;
	
	get_user_name(aimed, szName, 31);
	iPos += format(szMessage[iPos], 511, "%L: %s^n", id, "DM_ITEM_HUD_NAME", szName);
	
	for (index = 0; index < MAX_ITEMS_USED; index++)
	{
		if (!g_szItemName[aimed][index][0])
			continue;
		
		iPos += format(szMessage[iPos], 511, "%s^n", g_szItemName[aimed][index]);
	}
	
	set_hudmessage(iRed, 50, iBlue, -1.0, 0.70, 1, 0.01, 3.0, 0.01, 0.01, -1);
	ShowSyncHudMsg(id, g_iHudSyncStatus, szMessage);
}

/*DM_HideStatus(const id)
{
	ClearSyncHud(id, g_iHudSyncStatus);
}*/

/* -Messages------------------------------------------------------------------ */

public Msg_TeamInfo(msg_id, msg_dest)
{
	if (msg_dest != MSG_ALL && msg_dest != MSG_BROADCAST)
		return;
	
	static team[2]; get_msg_arg_string(2, team, charsmax(team));
	
	switch (team[0])
	{
		case 'S': g_iTeamID[get_msg_arg_int(1)] = DM_TEAM_SPECTATOR;
		case 'C': g_iTeamID[get_msg_arg_int(1)] = DM_TEAM_CT;
		case 'T': g_iTeamID[get_msg_arg_int(1)] = DM_TEAM_T;
		default: g_iTeamID[get_msg_arg_int(1)] = DM_TEAM_UNASSIGNED;
	}
}

public Msg_StatusValue(msg_id, msg_dest, msg_entity)
{
	if (msg_dest != MSG_ONE)
		return;
	
	switch (get_msg_arg_int(1))
	{
		case 1: // Friendly
		{
			g_iStatusFriendly[msg_entity] = get_msg_arg_int(2);
			/*
			if (!g_iStatusFriendly[msg_entity])
				DM_HideStatus(msg_entity);*/
		}
		case 2: // EntityID
		{
			new iEntityID = get_msg_arg_int(2);
			if (!is_user_valid_connected(iEntityID))
				return;
			
			switch (g_iShowPlayerItems)
			{
				case 2: // Show All
				{
					DM_ShowPlayerItems(msg_entity, iEntityID);
				}
				case 1: // Show Friendly
				{
					if (g_iStatusFriendly[msg_entity] != 1)
						return;
					
					DM_ShowPlayerItems(msg_entity, iEntityID);
				}
			}
		}
	}
}

/* -Native-------------------------------------------------------------------- */

/* native DM_RegisterItem(const itemname[], const chatcmd[], const team, const cost, const holdtime, const c_activate[], const c_deactivate[]); */
public native_register_item(plugin_id, num_params) <deactivated> return -1;
public native_register_item(plugin_id, num_params) <enabled>
{
	new Item[32];
	get_string(1, Item, charsmax(Item));
	if (strlen(Item) < 1)
	{
		DM_Log(LOG_ERROR, "Can't register item with an empty name.");
		DM_LogPlugin(LOG_ERROR, plugin_id, "DM_RegisterItem", 4);
		return -1;
	}
	
	new index, szBuffer[32];
	for (index = 0; index < g_iItemCount; index++)
	{
		ArrayGetString(g_aItemRealName, index, szBuffer, charsmax(szBuffer));
		if (equali(Item, szBuffer))
		{
			DM_Log(LOG_ERROR, "Item already registered (%s)", Item);
			DM_LogPlugin(LOG_ERROR, plugin_id, "DM_RegisterItem", 5);
			return -1;
		}
	}
	
	new ChatCmd[32];
	get_string(2, ChatCmd, charsmax(ChatCmd));
	if (strlen(ChatCmd) < 1)
	{
		DM_Log(LOG_ERROR, "Can't register chat command with an empty name.");
		DM_LogPlugin(LOG_ERROR, plugin_id, "DM_RegisterItem", 6);
		return -1;
	}
	
	for (index = 0; index < g_iItemCount; index++)
	{
		ArrayGetString(g_aItemChat, index, szBuffer, charsmax(szBuffer));
		if (equali(ChatCmd, szBuffer))
		{
			DM_Log(LOG_ERROR, "Chat command already registered (%s)", ChatCmd);
			DM_LogPlugin(LOG_ERROR, plugin_id, "DM_RegisterItem", 7);
			return -1;
		}
	}
	
	get_string(6, szBuffer, charsmax(szBuffer));
	new Activate = CreateOneForward(plugin_id, szBuffer, FP_CELL);
	if (Activate <= 0)
	{
		DM_Log(LOG_ERROR, "Can't create activate %s forward.", szBuffer);
		DM_LogPlugin(LOG_ERROR, plugin_id, "DM_RegisterItem", 8);
		return -1;
	}
	
	get_string(7, szBuffer, charsmax(szBuffer));
	new Deactivate = CreateOneForward(plugin_id, szBuffer, FP_CELL);
	if (Deactivate <= 0)
	{
		DM_Log(LOG_ERROR, "Can't create deactivate %s forward.", szBuffer);
		DM_LogPlugin(LOG_ERROR, plugin_id, "DM_RegisterItem", 9);
		return -1;
	}
	
	new Teams = get_param(3);
	if (Teams == DM_TEAM_ANY)
		Teams = (DM_TEAM_T|DM_TEAM_CT);
	
	ArrayPushString(g_aItemRealName, Item);
	ArrayPushString(g_aItemName, Item);
	ArrayPushString(g_aItemChat, ChatCmd);
	ArrayPushCell(g_aItemTeams, Teams);
	ArrayPushCell(g_aItemCost, get_param(4));
	ArrayPushCell(g_aItemHoldTime, get_param(5));
	ArrayPushCell(g_aItemActivate, Activate);
	ArrayPushCell(g_aItemDeactivate, Deactivate);
	ArrayPushCell(g_aItemNew, 1);
	
	new Size = ArraySize(g_aItem2RealName);
	for (index = 0; index < Size; index++)
	{
		ArrayGetString(g_aItem2RealName, index, szBuffer, charsmax(szBuffer));
		
		if (!equal(Item, szBuffer))
			continue;
		
		ArraySetCell(g_aItemNew, g_iItemCount, 0);
		
		ArrayGetString(g_aItem2Name, index, szBuffer, charsmax(szBuffer));
		ArraySetString(g_aItemName, g_iItemCount, szBuffer);
		
		ArrayGetString(g_aItem2Chat, index, szBuffer, charsmax(szBuffer));
		ArraySetString(g_aItemChat, g_iItemCount, szBuffer);
		TrieSetCell(g_tItemChat, szBuffer, g_iItemCount);
		
		szBuffer[0] = ArrayGetCell(g_aItem2Teams, index);
		ArraySetCell(g_aItemTeams, g_iItemCount, szBuffer[0]);
		
		szBuffer[0] = ArrayGetCell(g_aItem2Cost, index);
		ArraySetCell(g_aItemCost, g_iItemCount, szBuffer[0]);
		
		szBuffer[0] = ArrayGetCell(g_aItem2HoldTime, index);
		ArraySetCell(g_aItemHoldTime, g_iItemCount, szBuffer[0]);
	}
	g_iItemCount++;
	
	return g_iItemCount-1;
}

/* native DM_GetItemUniqueId(const item[]); */
public native_get_unique(plugin_id, num_params) <deactivated> return -1;
public native_get_unique(plugin_id, num_params) <enabled>
{
	new Item[32];
	get_string(1, Item, charsmax(Item));
	
	if (strlen(Item) < 1)
	{
		DM_Log(LOG_INFO, "Can't search item with an empty name.");
		DM_LogPlugin(LOG_INFO, plugin_id, "DM_GetItemUniqueId", 10);
		return -1;
	}
	
	new index, ItemName[32];
	for (index = 0; index < g_iItemCount; index++)
	{
		ArrayGetString(g_aItemRealName, index, ItemName, charsmax(ItemName));
		if (equali(Item, ItemName))
			return index;
	}
	
	return -1;
}

/* native DM_GetItemDisplayName(const itemid, name[], const len); */
public native_get_display_name(plugin_id, num_params) <deactivated> return 0;
public native_get_display_name(plugin_id, num_params) <enabled>
{
	new itemid = get_param(1);
	
	if (itemid < 0 || itemid >= g_iItemCount)
	{
		DM_Log(LOG_INFO, "Invalid item id (%d)", itemid);
		DM_LogPlugin(LOG_INFO, plugin_id, "DM_GetItemDisplayName", 11);
		return 0;
	}
	
	new ItemName[32];
	ArrayGetString(g_aItemName, itemid, ItemName, charsmax(ItemName));
	set_string(2, ItemName, get_param(3));
	
	return 1;
}

/* native DM_ForceBuyItem(const id, const itemid); */
public native_force_buyitem(plugin_id, num_params) <deactivated> return 0;
public native_force_buyitem(plugin_id, num_params) <enabled>
{
	new id = get_param(1);
	
	if (!get_bitsum(bs_IsConnected, id) || g_iTeamID[id] == DM_TEAM_UNASSIGNED)
	{
		DM_Log(LOG_INFO, "Invalid player (%d)", id);
		DM_LogPlugin(LOG_INFO, plugin_id, "DM_ForceBuyItem", 12);
		return 0;
	}
	
	new itemid = get_param(2);
	
	if (itemid < 0 || itemid >= g_iItemCount)
	{
		DM_Log(LOG_INFO, "Invalid item id (%d)", itemid);
		DM_LogPlugin(LOG_INFO, plugin_id, "DM_ForceBuyItem", 13);
		return 0;
	}
	
	return BuyItem(id, itemid);
}

/* -Stocks-------------------------------------------------------------------- */

stock get_configsdir(name[], len)
{
	return get_localinfo("amxx_configsdir", name, len);
}
