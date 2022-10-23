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
#include <cstrike>
#include <fakemeta>
#include <fun>
#include <hamsandwich>

#include <dm_core>
#include <dm_spawn>
#include <dm_scenarios>
#include <dm_colorchat>
#include <dm_log>

/* --------------------------------------------------------------------------- */

enum
{
	MENU_PRIMARY = 0,
	MENU_SECONDARY,
	MENU_ARMOR,
	MENU_GRENADES,
	MENU_SHOW,
	MENU_AUTOEQUIP,
	MENU_PREVIOUS,
	MENU_RANDOM,
	MENU_MAX
}

enum
{
	MENU_AUTO_ARMOR = 0,
	MENU_AUTO_HELMET,
	MENU_AUTO_GRENADES,
	MENU_AUTO_DEFUSEKIT,
	MENU_AUTO_NIGHTVISION,
	MENU_AUTO_BOT_KNIFE
}

enum
{
	MENU_GRENADE_HE = 0,
	MENU_GRENADE_FLASH,
	MENU_GRENADE_SMOKE
}

enum
{
	REMOVE_PRIMARY = 0,
	REMOVE_SECONDARY,
	REMOVE_GRENADES,
	REMOVE_BOMB,
	REMOVE_DEFUSEKIT,
	REMOVE_SHIELD
}

enum
{
	SILENCED_M4A1 = 0,
	SILENCED_USP,
	BURST_FAMAS,
	BURST_GLOCK18,
	NIGHTVISION,
	LASTWEAPON,
	MAX_ITEMSTATE
}

enum
{
	MES_BLOCK_WEAPON = 0,
	MES_BLOCK_ITEM,
	MES_BLOCK_AMMO
}

enum
{
	HIGHLIGHT_WEAPONS = 0,
	HIGHLIGHT_HE,
	HIGHLIGHT_BOMB,
	HIGHLIGHT_FLASH,
	HIGHLIGHT_SMOKE
}

/* --------------------------------------------------------------------------- */

new g_iPluginID = 0;

new g_iTeamID[DM_MAX_PLAYERS+1] = { 0, ... };
new g_iAutoEquip[DM_MAX_PLAYERS+1][MENU_MAX];
new g_iItemState[DM_MAX_PLAYERS+1][MAX_ITEMSTATE];

new bool:g_bBomb = false;
new bool:g_bVip = false;

new g_iFlashNum = 0;
new bool:g_bAmmoRefill = false;
new Float:g_fWeaponsStay = 0.0;

new bool:g_bBlockAmmoPickup = false;
new bool:g_bBlockWeapPickup = false;

new bs_IsAlive = 0;
new bs_IsBot = 0;
new bs_IsVip = 0;
new bs_IsSpawning = 0;
new bs_IsSpawned = 0;
new bs_MenuStatus = 0;
new bs_AutoItems = 0;
new bs_BotAutoItems = 0;
new bs_Grenades = 0;
new bs_RemoveItems = 0;
new bs_BlockMessages = 0;
new bs_Highlight = 0;

new bool:g_bSecMenuCreated = false;
new bool:g_bPrimMenuCreated = false;

new g_iWeaponUspID = -1;
new g_iWeaponGlock18ID = -1;

/* --------------------------------------------------------------------------- */

#define MAX_SECONDARY 6
#define MAX_PRIMARY 19
#define CSW_SHIELD 2
#define CSW_THIGHPACK 31

new Trie:SecValidWeapons = Invalid_Trie;
new Trie:PrimValidWeapons = Invalid_Trie;

new const SecondaryEntityNames[MAX_SECONDARY][] = { "weapon_p228", "weapon_elite", "weapon_fiveseven", 
"weapon_usp", "weapon_glock18", "weapon_deagle" };

new const PrimaryEntityNames[MAX_PRIMARY][] = { "weapon_shield", "weapon_scout", "weapon_xm1014", "weapon_mac10",
"weapon_aug", "weapon_ump45", "weapon_sg550", "weapon_galil", "weapon_famas", "weapon_awp", "weapon_mp5navy",
"weapon_m249", "weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_sg552", "weapon_ak47", "weapon_p90" };

new const WorldWeaponModel[][] = { "", "w_p228", "w_shield", "w_scout", "w_hegrenade", "w_xm1014",
"w_backpack", "w_mac10", "w_aug", "w_smokegrenade", "w_elite", "w_fiveseven", "w_ump45", "w_sg550",
"w_galil", "w_famas", "w_usp", "w_glock18", "w_awp", "w_mp5", "w_m249", "w_m3", "w_m4a1", "w_tmp",
"w_g3sg1", "w_flashbang", "w_deagle", "w_sg552", "w_ak47", "w_knife", "w_p90", "w_thighpack" };

/* --------------------------------------------------------------------------- */

new g_iMainMenuId = -1;
new g_cMainMenuId = 0;
new g_iArmorMenuId = -1;
new g_cArmorMenuId = 0;
new g_iNadeMenuId = -1;
new g_cNadeMenuId = 0;
new g_iVipMenuId = -1;

new g_iSecMenuId = -1;
new g_cSecMenuId = 0;
new g_szSecondary[MAX_SECONDARY][32];
new g_szRandomSecondary[MAX_SECONDARY][32];
new g_szSecWeaponDisplay[MAX_SECONDARY][33];
new g_iSecWeaponLimiter[MAX_SECONDARY][DM_TEAM_SPECTATOR];
new g_iSecWeaponLimit[MAX_SECONDARY][DM_TEAM_SPECTATOR];
new g_iSecondaryNum = 0;
new g_iRandomSecondaryNum = 0;

new g_iPrimMenuId = -1;
new g_cPrimMenuId = 0;
new g_szPrimary[MAX_PRIMARY][32];
new g_szRandomPrimary[MAX_PRIMARY][32];
new g_szPrimWeaponDisplay[MAX_PRIMARY][33];
new g_iPrimWeaponLimiter[MAX_PRIMARY][DM_TEAM_SPECTATOR];
new g_iPrimWeaponLimit[MAX_PRIMARY][DM_TEAM_SPECTATOR];
new g_iPrimaryNum = 0;
new g_iRandomPrimaryNum = 0;

new g_szBotsSecondary[MAX_SECONDARY][32];
new g_iBotsSecondaryNum = 0;

new g_szBotsPrimary[MAX_PRIMARY][32];
new g_iBotsPrimaryNum = 0;

/* --------------------------------------------------------------------------- */

const FM_PDATA_SAFE = 2;
const OFFSET_CSMENUCODE = 205;
const OFFSET_ACTIVE_ITEM = 373;
const PEV_ADDITIONAL_AMMO = pev_iuser1;

const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90);
const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE);
const GRENADES_WEAPONS_BIT_SUM = (1<<CSW_HEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_SMOKEGRENADE);

new const AMMOWEAPON[] = { 0, CSW_AWP, CSW_SCOUT, CSW_M249, CSW_AUG, CSW_XM1014, CSW_MAC10, CSW_FIVESEVEN,
CSW_DEAGLE, CSW_P228, CSW_ELITE, CSW_FLASHBANG, CSW_HEGRENADE, CSW_SMOKEGRENADE, CSW_C4 };

new const AMMOTYPE[][] = { "", "357sig", "", "762nato", "", "buckshot", "", "45acp",
"556nato", "", "9mm", "57mm", "45acp", "556nato", "556nato", "556nato", "45acp", "9mm",
"338magnum", "9mm", "556natobox", "buckshot", "556nato", "9mm", "762nato", "", "50ae",
"556nato", "762nato", "", "57mm" };

new const MAXBPAMMO[] = { -1, 52, -1, 90, 1, 32, 1, 100, 90, 1, 120, 100, 100, 90, 90, 90,
100, 120, 30, 120, 200, 32, 90, 120, 90, 2, 35, 90, 90, -1, 100 };

#define PRIMARY_ONLY	1
#define SECONDARY_ONLY	2
#define GRENADES_ONLY	3

#define get_bitsum(%1,%2)   (%1 &   (1<<((%2-1)&31)))
#define add_bitsum(%1,%2)    %1 |=  (1<<((%2-1)&31))
#define del_bitsum(%1,%2)    %1 &= ~(1<<((%2-1)&31))

#define fm_find_ent_by_class(%1,%2) engfunc(EngFunc_FindEntityByString, %1, "classname", %2)

/* -Init---------------------------------------------------------------------- */

public DM_OnModStatus(status)
{
	g_iPluginID = register_plugin("DM: Equip", DM_VERSION_STR_LONG, "schmurgel1983");
	
	if (status) state enabled;
	else state deactivated;
}

public DM_OnMapConditions(bomb, vip, hosnum, hosid[]) <deactivated> {}
public DM_OnMapConditions(bomb, vip, hosnum, hosid[]) <enabled>
{
	if (bomb) g_bBomb = true;
	if (vip) g_bVip = true;
}

public plugin_init() <deactivated> {}
public plugin_init() <enabled>
{
	SecValidWeapons = TrieCreate();
	for (new i = 0; i < MAX_SECONDARY; i++)
	{
		TrieSetCell(SecValidWeapons, SecondaryEntityNames[i], true);
	}
	
	PrimValidWeapons = TrieCreate();
	for (new i = 0; i < MAX_PRIMARY; i++)
	{
		TrieSetCell(PrimValidWeapons, PrimaryEntityNames[i], true);
	}
	
	if (!DM_LoadConfiguration("dm_equip.cfg", "DM_ReadEquip"))
	{
		TrieDestroy(SecValidWeapons);
		TrieDestroy(PrimValidWeapons);
		
		state deactivated;
		return;
	}
	
	#if AMXX_VERSION_NUM < 183
	register_dictionary_colored("dm_equip.txt");
	#else
	register_dictionary("dm_equip.txt");
	#endif
	register_dictionary("common.txt");
	
	register_clcmd("say", "HandleSay");
	register_clcmd("say_team", "HandleSay");
	
	g_iMainMenuId = menu_create("DM: Main Menu", "MenuMainHandler", 0);
	g_cMainMenuId = menu_makecallback("CallbackMainHandler");
	menu_additem(g_iMainMenuId, "DM_EQUIP_NEW", "1", 0, g_cMainMenuId);
	menu_additem(g_iMainMenuId, "DM_EQUIP_RANDOM", "2", 0, g_cMainMenuId);
	menu_additem(g_iMainMenuId, "DM_EQUIP_PREVIOUS", "3", 0, g_cMainMenuId);
	menu_additem(g_iMainMenuId, "DM_EQUIP_AUTOMATIC", "4", 0, g_cMainMenuId);
	menu_setprop(g_iMainMenuId, MPROP_EXIT, MEXIT_NEVER);
	
	g_iArmorMenuId = menu_create("DM: Armor Menu", "MenuArmorHandler", 0);
	g_cArmorMenuId = menu_makecallback("CallbackArmorHandler");
	menu_additem(g_iArmorMenuId, "DM_EQUIP_ARMOR", "1", 0, g_cArmorMenuId);
	menu_additem(g_iArmorMenuId, "DM_EQUIP_HELM", "2", 0, g_cArmorMenuId);
	menu_additem(g_iArmorMenuId, "DM_EQUIP_NO_ARMOR", "3", 0, g_cArmorMenuId);
	menu_setprop(g_iArmorMenuId, MPROP_EXIT, MEXIT_NEVER);
	
	g_iNadeMenuId = menu_create("DM: Grenade Menu", "MenuNadeHandler", 0);
	g_cNadeMenuId = menu_makecallback("CallbackNadeHandler");
	menu_additem(g_iNadeMenuId, "DM_EQUIP_GRENS_ALL", "1", 0, g_cNadeMenuId);
	menu_additem(g_iNadeMenuId, "DM_EQUIP_GRENS_NO", "2", 0, g_cNadeMenuId);
	menu_setprop(g_iNadeMenuId, MPROP_EXIT, MEXIT_NEVER);
	
	// Vip weapon menu, vip can't use elite or fiveseven
	if (g_bVip)
	{
		g_iVipMenuId = menu_create("DM: Vip Menu", "MenuVipHandler", 0);
		menu_additem(g_iVipMenuId, "H&K USP .45 Tactical", "1", 0);
		menu_additem(g_iVipMenuId, "Glock 18 Select Fire", "2", 0);
		menu_additem(g_iVipMenuId, "Desert Eagle .50 AE", "3", 0);
		menu_additem(g_iVipMenuId, "SIG P228", "4", 0);
		menu_setprop(g_iVipMenuId, MPROP_EXIT, MEXIT_NEVER);
	}
	
	register_forward(FM_SetModel, "fwd_SetModel");
	
	RegisterHam(Ham_AddPlayerItem, "player", "fwd_AddPlayerItem", false);
	
	register_message(get_user_msgid("TeamInfo"), "Msg_TeamInfo");
	register_message(get_user_msgid("NVGToggle"), "Msg_NVGToggle");
	
	if (get_bitsum(bs_BlockMessages, MES_BLOCK_WEAPON)) register_message(get_user_msgid("WeapPickup"), "Msg_WeapPickup");
	if (get_bitsum(bs_BlockMessages, MES_BLOCK_ITEM)) register_message(get_user_msgid("ItemPickup"), "Msg_ItemPickup");
	if (get_bitsum(bs_BlockMessages, MES_BLOCK_AMMO)) register_message(get_user_msgid("AmmoPickup"), "Msg_AmmoPickup");
	
	if (g_bAmmoRefill)
	{
		register_event("AmmoX", "EventAmmoX", "be");
	}
}

public DM_ReadEquip(section[], key[], value[])
{
	if (equali(section, "equip"))
	{
		if (equali(key, "menus"))
		{
			if (containi(value, "p") != -1) add_bitsum(bs_MenuStatus, MENU_PRIMARY);
			if (containi(value, "s") != -1) add_bitsum(bs_MenuStatus, MENU_SECONDARY);
			if (containi(value, "a") != -1) add_bitsum(bs_MenuStatus, MENU_ARMOR);
			if (containi(value, "g") != -1) add_bitsum(bs_MenuStatus, MENU_GRENADES);
		}
		else if (equali(key, "autoitems"))
		{
			if (containi(value, "a") != -1)
			{
				del_bitsum(bs_MenuStatus, MENU_ARMOR);
				add_bitsum(bs_AutoItems, MENU_AUTO_ARMOR);
			}
			if (containi(value, "h") != -1)
			{
				del_bitsum(bs_MenuStatus, MENU_ARMOR);
				add_bitsum(bs_AutoItems, MENU_AUTO_HELMET);
			}
			if (containi(value, "g") != -1)
			{
				del_bitsum(bs_MenuStatus, MENU_GRENADES);
				add_bitsum(bs_AutoItems, MENU_AUTO_GRENADES);
			}
			if (containi(value, "d") != -1) if (g_bBomb) add_bitsum(bs_AutoItems, MENU_AUTO_DEFUSEKIT);
			if (containi(value, "n") != -1) add_bitsum(bs_AutoItems, MENU_AUTO_NIGHTVISION);
		}
		else if (equali(key, "grenades"))
		{
			if (containi(value, "h") != -1) add_bitsum(bs_Grenades, MENU_GRENADE_HE);
			if (containi(value, "f") != -1) add_bitsum(bs_Grenades, MENU_GRENADE_FLASH);
			if (containi(value, "s") != -1) add_bitsum(bs_Grenades, MENU_GRENADE_SMOKE);
		}
		else if (equali(key, "fnadesnum")) g_iFlashNum = clamp(str_to_num(value), 0, 2);
		else if (equali(key, "bpammo_refill")) g_bAmmoRefill = !!bool:str_to_num(value);
		else if (equali(key, "weapons_stay")) g_fWeaponsStay = floatclamp(str_to_float(value), 0.0, 30.0);
		else if (equali(key, "remove_weapons"))
		{
			if (containi(value, "p") != -1) add_bitsum(bs_RemoveItems, REMOVE_PRIMARY);
			if (containi(value, "s") != -1) add_bitsum(bs_RemoveItems, REMOVE_SECONDARY);
			if (containi(value, "g") != -1) add_bitsum(bs_RemoveItems, REMOVE_GRENADES);
			if (containi(value, "b") != -1) add_bitsum(bs_RemoveItems, REMOVE_BOMB);
			if (containi(value, "d") != -1) add_bitsum(bs_RemoveItems, REMOVE_DEFUSEKIT);
			if (containi(value, "h") != -1) add_bitsum(bs_RemoveItems, REMOVE_SHIELD);
		}
		else if (equali(key, "weapons_highlight"))
		{
			if (containi(value, "w") != -1) add_bitsum(bs_Highlight, HIGHLIGHT_WEAPONS);
			if (containi(value, "h") != -1) add_bitsum(bs_Highlight, HIGHLIGHT_HE);
			if (containi(value, "b") != -1) add_bitsum(bs_Highlight, HIGHLIGHT_BOMB);
			if (containi(value, "f") != -1) add_bitsum(bs_Highlight, HIGHLIGHT_FLASH);
			if (containi(value, "s") != -1) add_bitsum(bs_Highlight, HIGHLIGHT_SMOKE);
		}
		else if (equali(key, "block_messages"))
		{
			if (containi(value, "w") != -1) add_bitsum(bs_BlockMessages, MES_BLOCK_WEAPON);
			if (containi(value, "i") != -1) add_bitsum(bs_BlockMessages, MES_BLOCK_ITEM);
			if (containi(value, "a") != -1) add_bitsum(bs_BlockMessages, MES_BLOCK_AMMO);
		}
		else if (equali(key, "reset_guns"))
		{
			new i;
			
			// Players
			if (g_bSecMenuCreated)
			{
				g_bSecMenuCreated = false;
				menu_destroy(g_iSecMenuId);
				for (i = 0; i < g_iSecondaryNum; i++)
					g_szSecondary[i][0] = '^0';
				g_iSecondaryNum = 0;
			}
			
			for (i = 0; i < g_iRandomSecondaryNum; i++)
			{
				g_szRandomSecondary[i][0] = '^0';
			}
			g_iRandomSecondaryNum = 0;
			
			if (g_bPrimMenuCreated)
			{
				g_bPrimMenuCreated = false;
				menu_destroy(g_iPrimMenuId);
				for (i = 0; i < g_iPrimaryNum; i++)
					g_szPrimary[i][0] = '^0';
				g_iPrimaryNum = 0;
			}
			
			for (i = 0; i < g_iRandomPrimaryNum; i++)
			{
				g_szRandomPrimary[i][0] = '^0';
			}
			g_iRandomPrimaryNum = 0;
			
			// Bots
			bs_BotAutoItems = 0;
			
			for (i = 0; i < g_iBotsSecondaryNum; i++)
			{
				g_szBotsSecondary[i][0] = '^0';
			}
			g_iBotsSecondaryNum = 0;
			
			for (i = 0; i < g_iBotsPrimaryNum; i++)
			{
				g_szBotsPrimary[i][0] = '^0';
			}
			g_iBotsPrimaryNum = 0;
		}
	}
	else if (equali(section, "secondary"))
	{
		if (g_iSecondaryNum >= MAX_SECONDARY)
		{
			DM_Log(LOG_INFO, "Reaches %i/%i secondary weapons", g_iSecondaryNum, MAX_SECONDARY);
			DM_LogPlugin(LOG_INFO, g_iPluginID, "DM_ReadEquip", 1);
		}
		else
		{
			if (!g_bSecMenuCreated)
			{
				g_iSecMenuId = menu_create("DM: Secondary Weapons", "MenuSecHandler", 0);
				g_cSecMenuId = menu_makecallback("CallbackSecHandler");
				g_bSecMenuCreated = true;
			}
			
			new weapon[11], display[33], terlimit[3], ctlimit[3];
			parse(key, weapon, 10, display, 32, terlimit, 2, ctlimit, 2);
			
			strtolower(weapon);
			format(g_szSecondary[g_iSecondaryNum], 19, "weapon_%s", weapon);
			
			if (TrieKeyExists(SecValidWeapons, g_szSecondary[g_iSecondaryNum]))
			{
				if ((g_iWeaponUspID == -1) && equal(g_szSecondary[g_iSecondaryNum], "weapon_usp")) g_iWeaponUspID = g_iSecondaryNum;
				else if ((g_iWeaponGlock18ID == -1) && equal(g_szSecondary[g_iSecondaryNum], "weapon_glock18")) g_iWeaponGlock18ID = g_iSecondaryNum;
				
				TrieSetCell(SecValidWeapons, g_szSecondary[g_iSecondaryNum], g_iSecondaryNum);
				copy(g_szSecWeaponDisplay[g_iSecondaryNum], 32, display);
				g_iSecWeaponLimiter[g_iSecondaryNum][DM_TEAM_T] = clamp(str_to_num(terlimit), -1, 32);
				g_iSecWeaponLimiter[g_iSecondaryNum][DM_TEAM_CT] = clamp(str_to_num(ctlimit), -1, 32);
				
				new cmd[5];
				format(cmd, 4, "%d", g_iSecondaryNum);
				menu_additem(g_iSecMenuId, display, cmd, 0, g_cSecMenuId);
				
				g_iSecondaryNum++;
			}
			else
			{
				DM_Log(LOG_INFO, "Secondary weapon (%s) do not exist", weapon);
				DM_LogPlugin(LOG_INFO, g_iPluginID, "DM_ReadEquip", 2);
			}
		}
	}
	else if (equali(section, "primary"))
	{
		if (g_iPrimaryNum >= MAX_PRIMARY)
		{
			DM_Log(LOG_INFO, "Reaches %i/%i primary weapons", g_iPrimaryNum, MAX_PRIMARY);
			DM_LogPlugin(LOG_INFO, g_iPluginID, "DM_ReadEquip", 3);
		}
		else
		{
			if (!g_bPrimMenuCreated)
			{
				g_iPrimMenuId = menu_create("DM: Primary Weapons", "MenuPrimHandler", 0);
				g_cPrimMenuId = menu_makecallback("CallbackPrimHandler");
				g_bPrimMenuCreated = true;
			}
			
			new weapon[11], display[33], terlimit[3], ctlimit[3];
			parse(key, weapon, 10, display, 32, terlimit, 2, ctlimit, 2);
			
			strtolower(weapon);
			format(g_szPrimary[g_iPrimaryNum], 19, "weapon_%s", weapon);
			
			if (TrieKeyExists(PrimValidWeapons, g_szPrimary[g_iPrimaryNum]))
			{
				TrieSetCell(PrimValidWeapons, g_szPrimary[g_iPrimaryNum], g_iPrimaryNum);
				copy(g_szPrimWeaponDisplay[g_iPrimaryNum], 32, display);
				g_iPrimWeaponLimiter[g_iPrimaryNum][DM_TEAM_T] = clamp(str_to_num(terlimit), -1, 32);
				g_iPrimWeaponLimiter[g_iPrimaryNum][DM_TEAM_CT] = clamp(str_to_num(ctlimit), -1, 32);
				
				new cmd[5];
				format(cmd, 4, "%d", g_iPrimaryNum);
				menu_additem(g_iPrimMenuId, display, cmd, 0, g_cPrimMenuId);
				
				g_iPrimaryNum++;
			}
			else
			{
				DM_Log(LOG_INFO, "Primary weapon (%s) do not exist", weapon);
				DM_LogPlugin(LOG_INFO, g_iPluginID, "DM_ReadEquip", 4);
			}
		}
	}
	else if (equali(section, "random_secondary"))
	{
		if (g_iRandomSecondaryNum >= MAX_SECONDARY)
		{
			DM_Log(LOG_INFO, "Reaches %i/%i random secondary weapons", g_iRandomSecondaryNum, MAX_SECONDARY);
			DM_LogPlugin(LOG_INFO, g_iPluginID, "DM_ReadEquip", 5);
		}
		else
		{
			strtolower(key);
			format(g_szRandomSecondary[g_iRandomSecondaryNum], 31, "weapon_%s", key);
			
			if (TrieKeyExists(SecValidWeapons, g_szRandomSecondary[g_iRandomSecondaryNum]))
			{
				g_iRandomSecondaryNum++;
			}
			else
			{
				DM_Log(LOG_INFO, "Secondary weapon (%s) do not exist", key);
				DM_LogPlugin(LOG_INFO, g_iPluginID, "DM_ReadEquip", 6);
			}
		}
	}
	else if (equali(section, "random_primary"))
	{
		if (g_iRandomPrimaryNum >= MAX_PRIMARY)
		{
			DM_Log(LOG_INFO, "Reaches %i/%i random primary weapons", g_iRandomPrimaryNum, MAX_PRIMARY);
			DM_LogPlugin(LOG_INFO, g_iPluginID, "DM_ReadEquip", 7);
		}
		else
		{
			strtolower(key);
			format(g_szRandomPrimary[g_iRandomPrimaryNum], 31, "weapon_%s", key);
			
			if (TrieKeyExists(PrimValidWeapons, g_szRandomPrimary[g_iRandomPrimaryNum]))
			{
				g_iRandomPrimaryNum++;
			}
			else
			{
				DM_Log(LOG_INFO, "Primary weapon (%s) do not exist", key);
				DM_LogPlugin(LOG_INFO, g_iPluginID, "DM_ReadEquip", 8);
			}
		}
	}
	else if (equali(section, "bot_secondary"))
	{
		if (g_iBotsSecondaryNum >= MAX_SECONDARY)
		{
			DM_Log(LOG_INFO, "Reaches %i/%i bots secondary weapons", g_iBotsSecondaryNum, MAX_SECONDARY);
			DM_LogPlugin(LOG_INFO, g_iPluginID, "DM_ReadEquip", 9);
		}
		else
		{
			strtolower(key);
			format(g_szBotsSecondary[g_iBotsSecondaryNum], 31, "weapon_%s", key);
			
			if (TrieKeyExists(SecValidWeapons, g_szBotsSecondary[g_iBotsSecondaryNum]))
			{
				g_iBotsSecondaryNum++;
			}
			else
			{
				DM_Log(LOG_INFO, "Secondary weapon (%s) do not exist", key);
				DM_LogPlugin(LOG_INFO, g_iPluginID, "DM_ReadEquip", 10);
			}
		}
	}
	else if (equali(section, "bot_primary"))
	{
		if (g_iBotsPrimaryNum >= MAX_PRIMARY)
		{
			DM_Log(LOG_INFO, "Reaches %i/%i bots primary weapons", g_iBotsPrimaryNum, MAX_PRIMARY);
			DM_LogPlugin(LOG_INFO, g_iPluginID, "DM_ReadEquip", 11);
		}
		else
		{
			strtolower(key);
			format(g_szBotsPrimary[g_iBotsPrimaryNum], 31, "weapon_%s", key);
			
			if (TrieKeyExists(PrimValidWeapons, g_szBotsPrimary[g_iBotsPrimaryNum]))
			{
				g_iBotsPrimaryNum++;
			}
			else
			{
				DM_Log(LOG_INFO, "Primary weapon (%s) do not exist", key);
				DM_LogPlugin(LOG_INFO, g_iPluginID, "DM_ReadEquip", 12);
			}
		}
	}
	else if (equali(section, "bot_autoitems"))
	{
		strtolower(key);
		
		new item[12], type[2], enable;
		parse(key, item, 11, type, 1);
		
		enable = clamp(str_to_num(type), 0, 1);
		
		if (enable)
		{
			if (equali(item, "armor")) add_bitsum(bs_BotAutoItems, MENU_AUTO_ARMOR);
			else if (equali(item, "helmet")) add_bitsum(bs_BotAutoItems, MENU_AUTO_HELMET);
			else if (equali(item, "grenades")) add_bitsum(bs_BotAutoItems, MENU_AUTO_GRENADES);
			else if (equali(item, "defusekit")) if (g_bBomb) add_bitsum(bs_BotAutoItems, MENU_AUTO_DEFUSEKIT);
			else if (equali(item, "nightvision")) add_bitsum(bs_BotAutoItems, MENU_AUTO_NIGHTVISION);
			else if (equali(item, "knife")) add_bitsum(bs_BotAutoItems, MENU_AUTO_BOT_KNIFE);
		}
	}
}

public plugin_end() <deactivated> {}
public plugin_end() <enabled>
{
	TrieDestroy(SecValidWeapons);
	TrieDestroy(PrimValidWeapons);
}

/* --------------------------------------------------------------------------- */

public client_putinserver(id) <deactivated> {}
public client_putinserver(id) <enabled>
{
	set_cvars(id);
	
	if (is_user_bot(id))
		add_bitsum(bs_IsBot, id);
}

#if AMXX_VERSION_NUM < 183
public client_disconnect(id) <deactivated> {}
public client_disconnect(id) <enabled>
#else
public client_disconnected(id, bool:drop, message[], maxlen) <deactivated> {}
public client_disconnected(id, bool:drop, message[], maxlen) <enabled>
#endif
{
	set_cvars(id, 1);
}

set_cvars(id, disconnect = 0)
{
	if (disconnect && !get_bitsum(bs_IsBot, id) && !g_iAutoEquip[id][MENU_RANDOM])
	{
		RestoreWeaponLimit(id, true, true);
	}
	
	del_bitsum(bs_IsAlive, id);
	del_bitsum(bs_IsSpawning, id);
	del_bitsum(bs_IsSpawned, id);
	del_bitsum(bs_IsBot, id);
	del_bitsum(bs_IsVip, id);
	
	g_iAutoEquip[id][MENU_PRIMARY] = -1;
	g_iAutoEquip[id][MENU_SECONDARY] = -1;
	g_iAutoEquip[id][MENU_ARMOR] = -1;
	g_iAutoEquip[id][MENU_GRENADES] = -1;
	
	g_iAutoEquip[id][MENU_AUTOEQUIP] = 0;
	g_iAutoEquip[id][MENU_PREVIOUS] = 0;
	g_iAutoEquip[id][MENU_RANDOM] = 0;
	
	g_iAutoEquip[id][MENU_SHOW] = 1;
	
	for (new i = SILENCED_M4A1; i < MAX_ITEMSTATE; i++)
		g_iItemState[id][i] = 0;
}

/* --------------------------------------------------------------------------- */

public DM_OnCzBotHamRegisterable(id) <deactivated> {}
public DM_OnCzBotHamRegisterable(id) <enabled>
{
	RegisterHamFromEntity(Ham_AddPlayerItem, id, "fwd_AddPlayerItem", false);
}

/* --------------------------------------------------------------------------- */

public DM_PlayerSpawn_Pre(id)
{
	add_bitsum(bs_IsSpawning, id);
}

public DM_PlayerSpawn_Post(id, freezetime, roundend) <deactivated> {}
public DM_PlayerSpawn_Post(id, freezetime, roundend) <enabled>
{
	del_bitsum(bs_IsSpawning, id);
	add_bitsum(bs_IsSpawned, id);
	
	set_task(0.1, "WeaponDelayed", id);
}

public WeaponDelayed(id)
{
	if (!get_bitsum(bs_IsSpawned, id))
		return;
	
	if (!get_bitsum(bs_IsBot, id) && get_bitsum(bs_IsAlive, id))
	{
		if (get_bitsum(bs_IsVip, id))
		{
			StripVipSecondary(id);
			DM_CsMenuFix(id);
			menu_display(id, g_iVipMenuId);
		}
		else if (g_iAutoEquip[id][MENU_AUTOEQUIP])
		{
			new primary, secondary;
			
			if (!g_iAutoEquip[id][MENU_RANDOM])
			{
				new weapons[32], num_weapons, index, wpnid;
				get_user_weapons(id, weapons, num_weapons);
				
				for (index = 0; index < num_weapons; index++)
				{
					wpnid = weapons[index];
					
					if ((1<<wpnid) & SECONDARY_WEAPONS_BIT_SUM)
					{
						secondary = true;
						
						if ((wpnid == CSW_USP && g_iWeaponUspID != g_iAutoEquip[id][MENU_SECONDARY]) || (wpnid == CSW_GLOCK18 && g_iWeaponGlock18ID != g_iAutoEquip[id][MENU_SECONDARY]))
							secondary = false;
					}
					if ((1<<wpnid) & PRIMARY_WEAPONS_BIT_SUM) primary = true;
				}
				
				if (!secondary) MenuSecHandler(id, g_iSecMenuId, g_iAutoEquip[id][MENU_SECONDARY]);
				if (!primary) MenuPrimHandler(id, g_iPrimMenuId, g_iAutoEquip[id][MENU_PRIMARY]);
			}
			else
			{
				if (g_iRandomSecondaryNum > 0)
				{
					new s = random_num(0, g_iRandomSecondaryNum - 1);
					strip_weapons(id, SECONDARY_ONLY);
					DM_GiveItem(id, g_szRandomSecondary[s]);
					DM_GiveAmmo(id, get_weaponid(g_szRandomSecondary[s]));
				}
				
				if (g_iRandomPrimaryNum > 0)
				{
					new p = random_num(0, g_iRandomPrimaryNum - 1);
					if (!DM_DropShield(id)) strip_weapons(id, PRIMARY_ONLY);
					DM_GiveItem(id, g_szRandomPrimary[p]);
					DM_GiveAmmo(id, get_weaponid(g_szRandomPrimary[p]));
				}
			}
			
			if (get_bitsum(bs_MenuStatus, MENU_ARMOR))
			{
				MenuArmorHandler(id, g_iArmorMenuId, g_iAutoEquip[id][MENU_ARMOR]);
			}
			
			if (get_bitsum(bs_MenuStatus, MENU_GRENADES))
			{
				if (get_bitsum(bs_AutoItems, MENU_AUTO_ARMOR))
				{
					if (get_bitsum(bs_AutoItems, MENU_AUTO_HELMET)) cs_set_user_armor(id, 100, CsArmorType:CS_ARMOR_VESTHELM);
					else cs_set_user_armor(id, 100, CsArmorType:CS_ARMOR_KEVLAR);
				}
				
				MenuNadeHandler(id, g_iNadeMenuId, g_iAutoEquip[id][MENU_GRENADES]);
			}
			else
			{
				if (get_bitsum(bs_AutoItems, MENU_AUTO_ARMOR))
				{
					if (get_bitsum(bs_AutoItems, MENU_AUTO_HELMET)) cs_set_user_armor(id, 100, CsArmorType:CS_ARMOR_VESTHELM);
					else cs_set_user_armor(id, 100, CsArmorType:CS_ARMOR_KEVLAR);
				}
				
				if (get_bitsum(bs_AutoItems, MENU_AUTO_GRENADES))
				{
					GiveAutoGrenades(id, 1);
				}
				
				GiveEquipment(id);
			}
			
			g_iAutoEquip[id][MENU_SHOW] = 1;
		}
		else
		{
			g_iAutoEquip[id][MENU_AUTOEQUIP] = 0;
			g_iAutoEquip[id][MENU_PREVIOUS] = 0;
			
			DM_CsMenuFix(id);
			menu_display(id, g_iMainMenuId);
		}
		
		return;
	}
	
	add_bitsum(bs_IsAlive, id);
	
	if (get_bitsum(bs_IsVip, id))
	{
		if (get_bitsum(bs_IsBot, id))
		{
			StripVipSecondary(id);
			MenuVipHandler(id, g_iVipMenuId, random(4));
			
			/* Maybe crash Server!!!
			if (!get_bitsum(bs_BotAutoItems, MENU_AUTO_BOT_KNIFE))
				ham_strip_weapon(id, "weapon_knife");*/
		}
		else
		{
			StripVipSecondary(id);
			DM_CsMenuFix(id);
			menu_display(id, g_iVipMenuId);
		}
	}
	else if (get_bitsum(bs_IsBot, id))
	{
		if (g_iBotsSecondaryNum > 0)
		{
			new s = random_num(0, g_iBotsSecondaryNum - 1);
			strip_weapons(id, SECONDARY_ONLY);
			DM_GiveItem(id, g_szBotsSecondary[s]);
			DM_GiveAmmo(id, get_weaponid(g_szBotsSecondary[s]));
		}
		
		if (g_iBotsPrimaryNum > 0)
		{
			new p = random_num(0, g_iBotsPrimaryNum - 1);
			if (!DM_DropShield(id)) strip_weapons(id, PRIMARY_ONLY);
			DM_GiveItem(id, g_szBotsPrimary[p]);
			DM_GiveAmmo(id, get_weaponid(g_szBotsPrimary[p]));
		}
		
		if (!get_bitsum(bs_BotAutoItems, MENU_AUTO_BOT_KNIFE))
			ham_strip_weapon(id, "weapon_knife");
		
		if (get_bitsum(bs_BotAutoItems, MENU_AUTO_ARMOR))
		{
			if (get_bitsum(bs_BotAutoItems, MENU_AUTO_HELMET)) cs_set_user_armor(id, 100, CsArmorType:CS_ARMOR_VESTHELM);
			else cs_set_user_armor(id, 100, CsArmorType:CS_ARMOR_KEVLAR);
		}
		
		if (get_bitsum(bs_BotAutoItems, MENU_AUTO_GRENADES))
		{
			GiveAutoGrenades(id);
		}
		
		if (g_iTeamID[id] == DM_TEAM_CT && get_bitsum(bs_BotAutoItems, MENU_AUTO_DEFUSEKIT) && !cs_get_user_defuse(id))
		{
			cs_set_user_defuse(id);
		}
		
		if (get_bitsum(bs_BotAutoItems, MENU_AUTO_NIGHTVISION) && !cs_get_user_nvg(id))
		{
			cs_set_user_nvg(id);
		}
	}
	else if (g_iAutoEquip[id][MENU_AUTOEQUIP])
	{
		MenuMainHandler(id, g_iMainMenuId, 3);
		
		g_iAutoEquip[id][MENU_SHOW] = 1;
	}
	else
	{
		g_iAutoEquip[id][MENU_AUTOEQUIP] = 0;
		g_iAutoEquip[id][MENU_PREVIOUS] = 0;
		
		DM_CsMenuFix(id);
		menu_display(id, g_iMainMenuId);
	}
}

public DM_PlayerKilled_Pre(victim, attacker) <deactivated> {}
public DM_PlayerKilled_Pre(victim, attacker) <enabled>
{
	del_bitsum(bs_IsAlive, victim);
	del_bitsum(bs_IsSpawning, victim);
	del_bitsum(bs_IsSpawned, victim);
	
	new weapons[32], num_weapons, index, weaponid, weapon_ent;
	get_user_weapons(victim, weapons, num_weapons);
	
	for (index = 0; index < num_weapons; index++)
	{
		weaponid = weapons[index];
		
		switch (weaponid)
		{
			case CSW_M4A1:
			{
				weapon_ent = fm_find_ent_by_owner(-1, "weapon_m4a1", victim);
				if (weapon_ent)
				{
					g_iItemState[victim][SILENCED_M4A1] = cs_get_weapon_silen(weapon_ent);
				}
			}
			case CSW_USP:
			{
				weapon_ent = fm_find_ent_by_owner(-1, "weapon_usp", victim);
				if (weapon_ent)
				{
					g_iItemState[victim][SILENCED_USP] = cs_get_weapon_silen(weapon_ent);
				}
			}
			case CSW_FAMAS:
			{
				weapon_ent = fm_find_ent_by_owner(-1, "weapon_famas", victim);
				if (weapon_ent)
				{
					g_iItemState[victim][BURST_FAMAS] = cs_get_weapon_burst(weapon_ent);
				}
			}
			case CSW_GLOCK18:
			{
				weapon_ent = fm_find_ent_by_owner(-1, "weapon_glock18", victim);
				if (weapon_ent)
				{
					g_iItemState[victim][BURST_GLOCK18] = cs_get_weapon_burst(weapon_ent);
				}
			}
		}
	}
}

public DM_BecameVip(id) <deactivated> {}
public DM_BecameVip(id) <enabled>
{
	bs_IsVip = 0;
	add_bitsum(bs_IsVip, id);
}

/* --------------------------------------------------------------------------- */

public fwd_AddPlayerItem(id, weapon_ent)
{
	new extra_ammo = pev(weapon_ent, PEV_ADDITIONAL_AMMO);
	if (extra_ammo)
	{
		new weaponid = cs_get_weapon_id(weapon_ent);
		
		g_bBlockAmmoPickup = true;
		ExecuteHamB(Ham_GiveAmmo, id, extra_ammo, AMMOTYPE[weaponid], MAXBPAMMO[weaponid]);
		g_bBlockAmmoPickup = false;
		
		set_pev(weapon_ent, PEV_ADDITIONAL_AMMO, 0);
	}
	
	return HAM_IGNORED;
}

public fwd_SetModel(entity, const model[])
{
	if (strlen(model) < 8 || model[7] != 'w' || model[8] != '_')
		return;
	
	new weaponid = cs_world_weapon_name_to_id(model);
	if (!weaponid)
		return;
	
	if ((get_bitsum(bs_RemoveItems, REMOVE_PRIMARY) && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM))
	|| (get_bitsum(bs_RemoveItems, REMOVE_SECONDARY) && ((1<<weaponid) & SECONDARY_WEAPONS_BIT_SUM))
	|| (get_bitsum(bs_RemoveItems, REMOVE_GRENADES) && ((1<<weaponid) & GRENADES_WEAPONS_BIT_SUM)))
	{
		dllfunc(DLLFunc_Think, entity);
		return;
	}
	else if (get_bitsum(bs_RemoveItems, REMOVE_BOMB) && weaponid == CSW_C4)
	{
		dllfunc(DLLFunc_Think, entity);
		return;
	}
	else if (get_bitsum(bs_RemoveItems, REMOVE_DEFUSEKIT) && weaponid == CSW_THIGHPACK)
	{
		set_pev(entity, pev_solid, SOLID_NOT);
		set_pev(entity, pev_effects, EF_NODRAW);
		set_task(0.1, "remove_thighpack", entity);
		return;
	}
	else if (get_bitsum(bs_RemoveItems, REMOVE_SHIELD) && weaponid == CSW_SHIELD)
	{
		set_pev(entity, pev_solid, SOLID_NOT);
		set_pev(entity, pev_effects, EF_NODRAW);
		set_task(0.1, "remove_shield", entity);
		return;
	}
	else if (g_fWeaponsStay > 0.0)
	{
		HighlightWeapons(entity, weaponid, 1);
	}
	else
	{
		HighlightWeapons(entity, weaponid, 0);
	}
}

/* --------------------------------------------------------------------------- */

public EventAmmoX(id)
{
	if (!get_bitsum(bs_IsAlive, id))
		return;
	
	new type = read_data(1);
	if (type >= sizeof AMMOWEAPON)
		return;
	
	new weapon = AMMOWEAPON[type];
	if (MAXBPAMMO[weapon] <= 2)
		return;
	
	new amount = read_data(2);
	if (amount < MAXBPAMMO[weapon])
	{
		new args[1];
		args[0] = weapon;
		set_task(0.1, "refill_bpammo", id, args, sizeof args);
	}
}

public refill_bpammo(const args[], id)
{
	if (!get_bitsum(bs_IsAlive, id))
		return;
	
	DM_GiveAmmo(id, args[0]);
}

/* --------------------------------------------------------------------------- */

HighlightWeapons(entity, weaponid, remove)
{
	static Float:dmgtime;
	pev(entity, pev_dmgtime, dmgtime);
	
	switch (weaponid)
	{
		case CSW_C4:
		{
			if (get_bitsum(bs_Highlight, HIGHLIGHT_BOMB))
				fm_set_rendering(entity, kRenderFxGlowShell, 192, 148, 32);
		}
		case CSW_HEGRENADE:
		{
			if (dmgtime == 0.0)
			{
				if (get_bitsum(bs_Highlight, HIGHLIGHT_HE))
					fm_set_rendering(entity, kRenderFxGlowShell, 200, 0, 0);
				
				if (remove)
					set_pev(entity, pev_nextthink, get_gametime() + g_fWeaponsStay);
			}
		}
		case CSW_FLASHBANG:
		{
			if (dmgtime == 0.0)
			{
				if (get_bitsum(bs_Highlight, HIGHLIGHT_FLASH))
					fm_set_rendering(entity, kRenderFxGlowShell, 0, 0, 200);
				
				if (remove)
					set_pev(entity, pev_nextthink, get_gametime() + g_fWeaponsStay);
			}
		}
		case CSW_SMOKEGRENADE:
		{
			if (dmgtime == 0.0)
			{
				if (get_bitsum(bs_Highlight, HIGHLIGHT_SMOKE))
					fm_set_rendering(entity, kRenderFxGlowShell, 0, 200, 0);
				
				if (remove)
					set_pev(entity, pev_nextthink, get_gametime() + g_fWeaponsStay);
			}
		}
		case CSW_THIGHPACK:
		{
			if (get_bitsum(bs_Highlight, HIGHLIGHT_WEAPONS))
				fm_set_rendering(entity, kRenderFxGlowShell, 200, 200, 200);
			
			if (remove)
				set_task(g_fWeaponsStay, "remove_thighpack", entity);
		}
		case CSW_SHIELD:
		{
			if (get_bitsum(bs_Highlight, HIGHLIGHT_WEAPONS))
				fm_set_rendering(entity, kRenderFxGlowShell, 200, 200, 200);
			
			if (remove)
				set_task(g_fWeaponsStay, "remove_shield", entity);
		}
		default:
		{
			if (get_bitsum(bs_Highlight, HIGHLIGHT_WEAPONS))
				fm_set_rendering(entity, kRenderFxGlowShell, 200, 200, 200);
			
			if (remove)
				set_pev(entity, pev_nextthink, get_gametime() + g_fWeaponsStay);
		}
	}
}

public remove_shield(entity)
{
	if (!pev_valid(entity))
		return;
	
	dllfunc(DLLFunc_Think, entity);
}

public remove_thighpack(entity)
{
	if (!pev_valid(entity))
		return;
	
	engfunc(EngFunc_RemoveEntity, entity);
}

/* --------------------------------------------------------------------------- */

public HandleSay(id)
{
	new message[192];
	read_args(message, 191);
	remove_quotes(message);
	
	if (strlen(message) > 6 && (equali(message, "guns", 4) || equali(message[1], "guns", 4)))
	{
		new iReturn = PLUGIN_CONTINUE;
		if (message[0] == '!') iReturn = PLUGIN_HANDLED;
		
		if (g_iAutoEquip[id][MENU_RANDOM])
			return iReturn;
		
		new cmd[192], GunHasChanged;
		while (strlen(message))
		{
			strtok(message, cmd, charsmax(cmd), message, charsmax(message), ' ');
			strtolower(cmd), trim(cmd);
			
			if (strlen(cmd) < 12)
			{
				new buffer[20];
				format(buffer, charsmax(buffer), "weapon_%s", cmd);
				
				if (TrieKeyExists(PrimValidWeapons, buffer))
				{
					new value;
					if (TrieGetCell(PrimValidWeapons, buffer, value) && g_iAutoEquip[id][MENU_PRIMARY] != value && AllowWeaponLimit(id, value, 1, 1))
					{
						GunHasChanged = true;
						RestoreWeaponLimit(id, true, false);
						g_iPrimWeaponLimit[value][g_iTeamID[id]]++;
						g_iAutoEquip[id][MENU_PRIMARY] = value;
					}
				}
				else if (TrieKeyExists(SecValidWeapons, buffer))
				{
					new value;
					if (TrieGetCell(SecValidWeapons, buffer, value) && g_iAutoEquip[id][MENU_SECONDARY] != value && AllowWeaponLimit(id, value, 0, 1))
					{
						GunHasChanged = true;
						RestoreWeaponLimit(id, false, true);
						g_iSecWeaponLimit[value][g_iTeamID[id]]++;
						g_iAutoEquip[id][MENU_SECONDARY] = value;
					}
				}
				else if (equali(cmd, "armor")) g_iAutoEquip[id][MENU_ARMOR] = 0;
				else if (equali(cmd, "helmet")) g_iAutoEquip[id][MENU_ARMOR] = 1;
				else if (equali(cmd, "noarmor")) g_iAutoEquip[id][MENU_ARMOR] = 2;
				else if (equali(cmd, "grens")) g_iAutoEquip[id][MENU_GRENADES] = 0;
				else if (equali(cmd, "nades")) g_iAutoEquip[id][MENU_GRENADES] = 0;
				else if (equali(cmd, "grenades")) g_iAutoEquip[id][MENU_GRENADES] = 0;
				else if (equali(cmd, "nogrens")) g_iAutoEquip[id][MENU_GRENADES] = 1;
				else if (equali(cmd, "nonades")) g_iAutoEquip[id][MENU_GRENADES] = 1;
				else if (equali(cmd, "nogrenades")) g_iAutoEquip[id][MENU_GRENADES] = 1;
			}
		}
		
		if (GunHasChanged && g_iAutoEquip[id][MENU_AUTOEQUIP] && g_iAutoEquip[id][MENU_SHOW])
		{
			g_iAutoEquip[id][MENU_SHOW] = 0;
			
			MenuSecHandler(id, g_iSecMenuId, g_iAutoEquip[id][MENU_SECONDARY]);
			MenuPrimHandler(id, g_iPrimMenuId, g_iAutoEquip[id][MENU_PRIMARY]);
		}
		
		return iReturn;
	}
	else if (equali(message, "guns") || equali(message, "/guns") || equali(message, "!guns"))
	{
		if (g_iAutoEquip[id][MENU_AUTOEQUIP])
		{
			g_iAutoEquip[id][MENU_AUTOEQUIP] = 0;
			g_iAutoEquip[id][MENU_PREVIOUS] = 0;
			
			#if AMXX_VERSION_NUM < 183
			dm_print_color(id, DontChange, "^4[DM-Equip]^1 %L", id, "DM_EQUIP_ENABLE");
			#else
			client_print_color(id, print_team_default, "^4[DM-Equip]^1 %L", id, "DM_EQUIP_ENABLE");
			#endif
			
			if (g_iAutoEquip[id][MENU_SHOW])
			{
				DM_CsMenuFix(id);
				menu_display(id, g_iMainMenuId);
			}
		}
		else
		{
			#if AMXX_VERSION_NUM < 183
			dm_print_color(id, DontChange, "^4[DM-Equip]^1 %L", id, "DM_EQUIP_ALREADY");
			#else
			client_print_color(id, print_team_default, "^4[DM-Equip]^1 %L", id, "DM_EQUIP_ALREADY");
			#endif
		}
		
		if (message[0] == '!')
			return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

/* --------------------------------------------------------------------------- */

DM_CsMenuFix(id)
{
	if (pev_valid(id) != FM_PDATA_SAFE)
		return false;
	
	set_pdata_int(id, OFFSET_CSMENUCODE, 0);
	return true;
}

public CallbackMainHandler(id, menu, item)
{
	if (item < 0 || !get_bitsum(bs_IsAlive, id))
	{
		return PLUGIN_CONTINUE;
	}
	
	static szMenuItem[128];
	switch (item)
	{
		case 0:
		{
			formatex(szMenuItem, charsmax(szMenuItem), "%L", id, "DM_EQUIP_NEW");
			menu_item_setname(menu, item, szMenuItem);
			return ITEM_ENABLED;
		}
		case 1:
		{
			formatex(szMenuItem, charsmax(szMenuItem), "%L", id, "DM_EQUIP_RANDOM");
			menu_item_setname(menu, item, szMenuItem);
			return (!g_iRandomSecondaryNum || !g_iRandomPrimaryNum) ? ITEM_DISABLED : ITEM_ENABLED;
		}
		case 2:
		{
			formatex(szMenuItem, charsmax(szMenuItem), "%L", id, "DM_EQUIP_PREVIOUS");
			menu_item_setname(menu, item, szMenuItem);
			return ITEM_ENABLED;
		}
		case 3:
		{
			formatex(szMenuItem, charsmax(szMenuItem), "%L", id, "DM_EQUIP_AUTOMATIC");
			menu_item_setname(menu, item, szMenuItem);
			return ITEM_ENABLED;
		}
	}
	
	return PLUGIN_HANDLED;
}

public MenuMainHandler(id, menu, item)
{
	if (item < 0 || !get_bitsum(bs_IsAlive, id))
		return PLUGIN_CONTINUE;
	
	switch (item)
	{
		case 0: // New Weapons
		{
			if (g_iAutoEquip[id][MENU_RANDOM]) g_iAutoEquip[id][MENU_RANDOM] = 0;
			else RestoreWeaponLimit(id, true, true);
			
			if (get_bitsum(bs_MenuStatus, MENU_SECONDARY))
			{
				DM_CsMenuFix(id);
				menu_display(id, g_iSecMenuId);
			}
			else if (get_bitsum(bs_MenuStatus, MENU_PRIMARY))
			{
				DM_CsMenuFix(id);
				menu_display(id, g_iPrimMenuId);
			}
			else
			{
				CheckGiveEquipment(id);
			}
		}
		case 1: // Random Weapons
		{
			if (!g_iAutoEquip[id][MENU_RANDOM])
			{
				RestoreWeaponLimit(id, true, true);
				g_iAutoEquip[id][MENU_RANDOM] = 1;
			}
			
			if (g_iRandomSecondaryNum > 0)
			{
				new s = random_num(0, g_iRandomSecondaryNum - 1);
				strip_weapons(id, SECONDARY_ONLY);
				DM_GiveItem(id, g_szRandomSecondary[s]);
				DM_GiveAmmo(id, get_weaponid(g_szRandomSecondary[s]));
			}
			
			if (g_iRandomPrimaryNum > 0)
			{
				new p = random_num(0, g_iRandomPrimaryNum - 1);
				if (!DM_DropShield(id)) strip_weapons(id, PRIMARY_ONLY);
				DM_GiveItem(id, g_szRandomPrimary[p]);
				DM_GiveAmmo(id, get_weaponid(g_szRandomPrimary[p]));
			}
			
			CheckGiveEquipment(id);
		}
		case 2: // Previous Setup
		{
			g_iAutoEquip[id][MENU_PREVIOUS] = 1;
			
			if (g_iAutoEquip[id][MENU_RANDOM])
			{
				if (g_iRandomSecondaryNum > 0)
				{
					new s = random_num(0, g_iRandomSecondaryNum - 1);
					strip_weapons(id, SECONDARY_ONLY);
					DM_GiveItem(id, g_szRandomSecondary[s]);
					DM_GiveAmmo(id, get_weaponid(g_szRandomSecondary[s]));
				}
				
				if (g_iRandomPrimaryNum > 0)
				{
					new p = random_num(0, g_iRandomPrimaryNum - 1);
					if (!DM_DropShield(id)) strip_weapons(id, PRIMARY_ONLY);
					DM_GiveItem(id, g_szRandomPrimary[p]);
					DM_GiveAmmo(id, get_weaponid(g_szRandomPrimary[p]));
				}
			}
			else
			{
				MenuSecHandler(id, g_iSecMenuId, g_iAutoEquip[id][MENU_SECONDARY]);
				MenuPrimHandler(id, g_iPrimMenuId, g_iAutoEquip[id][MENU_PRIMARY]);
			}
			
			if (get_bitsum(bs_MenuStatus, MENU_ARMOR))
			{
				MenuArmorHandler(id, g_iArmorMenuId, g_iAutoEquip[id][MENU_ARMOR]);
			}
			
			if (get_bitsum(bs_MenuStatus, MENU_GRENADES))
			{
				if (get_bitsum(bs_AutoItems, MENU_AUTO_ARMOR))
				{
					if (get_bitsum(bs_AutoItems, MENU_AUTO_HELMET)) cs_set_user_armor(id, 100, CsArmorType:CS_ARMOR_VESTHELM);
					else cs_set_user_armor(id, 100, CsArmorType:CS_ARMOR_KEVLAR);
				}
				
				MenuNadeHandler(id, g_iNadeMenuId, g_iAutoEquip[id][MENU_GRENADES]);
			}
			else
			{
				if (get_bitsum(bs_AutoItems, MENU_AUTO_ARMOR))
				{
					if (get_bitsum(bs_AutoItems, MENU_AUTO_HELMET)) cs_set_user_armor(id, 100, CsArmorType:CS_ARMOR_VESTHELM);
					else cs_set_user_armor(id, 100, CsArmorType:CS_ARMOR_KEVLAR);
				}
				
				if (get_bitsum(bs_AutoItems, MENU_AUTO_GRENADES))
				{
					GiveAutoGrenades(id);
				}
				
				GiveEquipment(id);
			}
		}
		case 3: // Automatic - Don't show menu again
		{
			if (!g_iAutoEquip[id][MENU_AUTOEQUIP])
			{
				g_iAutoEquip[id][MENU_AUTOEQUIP] = 1;
				#if AMXX_VERSION_NUM < 183
				dm_print_color(id, Red, "^4[DM-Equip]^1 %L", id, "DM_EQUIP_AUTO");
				#else
				client_print_color(id, print_team_red, "^4[DM-Equip]^1 %L", id, "DM_EQUIP_AUTO");
				#endif
			}
			g_iAutoEquip[id][MENU_SHOW] = 0;
			
			if (g_iAutoEquip[id][MENU_RANDOM])
			{
				if (g_iRandomSecondaryNum > 0)
				{
					new s = random_num(0, g_iRandomSecondaryNum - 1);
					strip_weapons(id, SECONDARY_ONLY);
					DM_GiveItem(id, g_szRandomSecondary[s]);
					DM_GiveAmmo(id, get_weaponid(g_szRandomSecondary[s]));
				}
				
				if (g_iRandomPrimaryNum > 0)
				{
					new p = random_num(0, g_iRandomPrimaryNum - 1);
					if (!DM_DropShield(id)) strip_weapons(id, PRIMARY_ONLY);
					DM_GiveItem(id, g_szRandomPrimary[p]);
					DM_GiveAmmo(id, get_weaponid(g_szRandomPrimary[p]));
				}
			}
			else
			{
				MenuSecHandler(id, g_iSecMenuId, g_iAutoEquip[id][MENU_SECONDARY]);
				MenuPrimHandler(id, g_iPrimMenuId, g_iAutoEquip[id][MENU_PRIMARY]);
			}
			
			if (get_bitsum(bs_MenuStatus, MENU_ARMOR))
			{
				MenuArmorHandler(id, g_iArmorMenuId, g_iAutoEquip[id][MENU_ARMOR]);
			}
			
			if (get_bitsum(bs_MenuStatus, MENU_GRENADES))
			{
				if (get_bitsum(bs_AutoItems, MENU_AUTO_ARMOR))
				{
					if (get_bitsum(bs_AutoItems, MENU_AUTO_HELMET)) cs_set_user_armor(id, 100, CsArmorType:CS_ARMOR_VESTHELM);
					else cs_set_user_armor(id, 100, CsArmorType:CS_ARMOR_KEVLAR);
				}
				
				MenuNadeHandler(id, g_iNadeMenuId, g_iAutoEquip[id][MENU_GRENADES]);
			}
			else
			{
				if (get_bitsum(bs_AutoItems, MENU_AUTO_ARMOR))
				{
					if (get_bitsum(bs_AutoItems, MENU_AUTO_HELMET)) cs_set_user_armor(id, 100, CsArmorType:CS_ARMOR_VESTHELM);
					else cs_set_user_armor(id, 100, CsArmorType:CS_ARMOR_KEVLAR);
				}
				
				if (get_bitsum(bs_AutoItems, MENU_AUTO_GRENADES))
				{
					GiveAutoGrenades(id);
				}
				
				GiveEquipment(id);
			}
		}
	}
	
	return PLUGIN_HANDLED;
}

public CallbackSecHandler(id, menu, item)
{
	if (item < 0 || item >= g_iSecondaryNum)
		return PLUGIN_CONTINUE;
	
	new iTeam = g_iTeamID[id];
	new limit = g_iSecWeaponLimiter[item][iTeam];
	new szItem[33];
	
	if (limit == -1)
	{
		format(szItem, charsmax(szItem), "%s", g_szSecWeaponDisplay[item]);
		menu_item_setname(menu, item, szItem);
		return ITEM_ENABLED;
	}
	else if (limit == 0)
	{
		format(szItem, charsmax(szItem), "%s [disabled]", g_szSecWeaponDisplay[item]);
		menu_item_setname(menu, item, szItem);
		return ITEM_DISABLED;
	}
	else if (g_iSecWeaponLimit[item][iTeam] < limit)
	{
		format(szItem, charsmax(szItem), "%s [%d/%d]", g_szSecWeaponDisplay[item], g_iSecWeaponLimit[item][iTeam], limit);
		menu_item_setname(menu, item, szItem);
		return ITEM_ENABLED;
	}
	else if (g_iSecWeaponLimit[item][iTeam] >= limit)
	{
		format(szItem, charsmax(szItem), "%s [%d/%d]", g_szSecWeaponDisplay[item], g_iSecWeaponLimit[item][iTeam], limit);
		menu_item_setname(menu, item, szItem);
		return ITEM_DISABLED;
	}
	
	return PLUGIN_HANDLED;
}

public MenuSecHandler(id, menu, item)
{
	if (!get_bitsum(bs_IsAlive, id))
	{
		return PLUGIN_CONTINUE;
	}
	else if (item == MENU_EXIT)
	{
		DM_CsMenuFix(id);
		menu_display(id, g_iPrimMenuId);
		return PLUGIN_HANDLED;
	}
	else if (item < 0 || item >= g_iSecondaryNum)
		return PLUGIN_CONTINUE;
	
	if (!g_iAutoEquip[id][MENU_RANDOM])
	{
		if (!AllowWeaponLimit(id, item, 0, 0))
		{
			#if AMXX_VERSION_NUM < 183
			dm_print_color(id, DontChange, "^4[DM-Equip]^1 %L", id, "DM_EQUIP_LIMIT", g_szSecWeaponDisplay[item]);
			#else
			client_print_color(id, print_team_default, "^4[DM-Equip]^1 %L", id, "DM_EQUIP_LIMIT", g_szSecWeaponDisplay[item]);
			#endif
			
			DM_CsMenuFix(id);
			menu_display(id, g_iSecMenuId);
			return PLUGIN_HANDLED;
		}
		
		if (g_iAutoEquip[id][MENU_SECONDARY] != item)
			g_iSecWeaponLimit[item][g_iTeamID[id]]++;
	}
	
	strip_weapons(id, SECONDARY_ONLY);
	DM_GiveItem(id, g_szSecondary[item]);
	new weaponid = get_weaponid(g_szSecondary[item]);
	DM_GiveAmmo(id, weaponid);
	
	new weapon_ent;
	switch (weaponid)
	{
		case CSW_USP:
		{
			if (g_iItemState[id][SILENCED_USP])
			{
				weapon_ent = fm_find_ent_by_owner(-1, "weapon_usp", id);
				if (weapon_ent)
				{
					cs_set_weapon_silen(weapon_ent, 1, 0);
				}
			}
		}
		case CSW_GLOCK18:
		{
			if (g_iItemState[id][BURST_GLOCK18])
			{
				weapon_ent = fm_find_ent_by_owner(-1, "weapon_glock18", id);
				if (weapon_ent)
				{
					cs_set_weapon_burst(weapon_ent);
				}
			}
		}
	}
	
	// Menu
	if (get_bitsum(bs_IsVip, id) || g_iAutoEquip[id][MENU_AUTOEQUIP] || g_iAutoEquip[id][MENU_RANDOM] || g_iAutoEquip[id][MENU_PREVIOUS])
		return PLUGIN_HANDLED;
	
	g_iAutoEquip[id][MENU_SECONDARY] = item;
	
	if (get_bitsum(bs_MenuStatus, MENU_PRIMARY))
	{
		DM_CsMenuFix(id);
		menu_display(id, g_iPrimMenuId);
	}
	else
	{
		CheckGiveEquipment(id);
	}
	
	return PLUGIN_HANDLED;
}

public CallbackPrimHandler(id, menu, item)
{
	if (item < 0 || item >= g_iPrimaryNum)
		return PLUGIN_CONTINUE;
	
	new iTeam = g_iTeamID[id];
	new limit = g_iPrimWeaponLimiter[item][iTeam];
	new szItem[33];
	
	if (limit == -1)
	{
		format(szItem, charsmax(szItem), "%s", g_szPrimWeaponDisplay[item]);
		menu_item_setname(menu, item, szItem);
		return ITEM_ENABLED;
	}
	else if (limit == 0)
	{
		format(szItem, charsmax(szItem), "%s [disabled]", g_szPrimWeaponDisplay[item]);
		menu_item_setname(menu, item, szItem);
		return ITEM_DISABLED;
	}
	else if (g_iPrimWeaponLimit[item][iTeam] < limit)
	{
		format(szItem, charsmax(szItem), "%s [%d/%d]", g_szPrimWeaponDisplay[item], g_iPrimWeaponLimit[item][iTeam], limit);
		menu_item_setname(menu, item, szItem);
		return ITEM_ENABLED;
	}
	else if (g_iPrimWeaponLimit[item][iTeam] >= limit)
	{
		format(szItem, charsmax(szItem), "%s [%d/%d]", g_szPrimWeaponDisplay[item], g_iPrimWeaponLimit[item][iTeam], limit);
		menu_item_setname(menu, item, szItem);
		return ITEM_DISABLED;
	}
	
	return PLUGIN_HANDLED;
}

public MenuPrimHandler(id, menu, item)
{
	if (!get_bitsum(bs_IsAlive, id))
	{
		return PLUGIN_CONTINUE;
	}
	else if (item == MENU_EXIT)
	{
		CheckGiveEquipment(id);
		return PLUGIN_HANDLED;
	}
	else if (item < 0 || item >= g_iPrimaryNum)
		return PLUGIN_CONTINUE;
	
	if (!g_iAutoEquip[id][MENU_RANDOM])
	{
		if (!AllowWeaponLimit(id, item, 1, 0))
		{
			#if AMXX_VERSION_NUM < 183
			dm_print_color(id, DontChange, "^4[DM-Equip]^1 %L", id, "DM_EQUIP_LIMIT", g_szPrimWeaponDisplay[item]);
			#else
			client_print_color(id, print_team_default, "^4[DM-Equip]^1 %L", id, "DM_EQUIP_LIMIT", g_szPrimWeaponDisplay[item]);
			#endif
			
			DM_CsMenuFix(id);
			menu_display(id, g_iPrimMenuId);
			return PLUGIN_HANDLED;
		}
		
		if (!g_iAutoEquip[id][MENU_RANDOM] && g_iAutoEquip[id][MENU_PRIMARY] != item)
			g_iPrimWeaponLimit[item][g_iTeamID[id]]++;
	}
	
	if (!DM_DropShield(id)) strip_weapons(id, PRIMARY_ONLY);
	DM_GiveItem(id, g_szPrimary[item]);
	new weaponid = get_weaponid(g_szPrimary[item]);
	DM_GiveAmmo(id, weaponid);
	
	new weapon_ent;
	switch (weaponid)
	{
		case CSW_M4A1:
		{
			if (g_iItemState[id][SILENCED_M4A1])
			{
				weapon_ent = fm_find_ent_by_owner(-1, "weapon_m4a1", id);
				if (weapon_ent)
				{
					cs_set_weapon_silen(weapon_ent, 1, 0);
				}
			}
		}
		case CSW_FAMAS:
		{
			if (g_iItemState[id][BURST_FAMAS])
			{
				weapon_ent = fm_find_ent_by_owner(-1, "weapon_famas", id);
				if (weapon_ent)
				{
					cs_set_weapon_burst(weapon_ent);
				}
			}
		}
	}
	
	// Menu
	if (g_iAutoEquip[id][MENU_AUTOEQUIP] || g_iAutoEquip[id][MENU_RANDOM] || g_iAutoEquip[id][MENU_PREVIOUS])
		return PLUGIN_HANDLED;
	
	g_iAutoEquip[id][MENU_PRIMARY] = item;
	
	CheckGiveEquipment(id);
	
	return PLUGIN_HANDLED;
}

public CallbackArmorHandler(id, menu, item)
{
	if (item < 0 || !get_bitsum(bs_IsAlive, id))
	{
		return PLUGIN_CONTINUE;
	}
	
	static szMenuItem[128];
	switch (item)
	{
		case 0:
		{
			formatex(szMenuItem, charsmax(szMenuItem), "%L", id, "DM_EQUIP_ARMOR");
			menu_item_setname(menu, item, szMenuItem);
			return ITEM_ENABLED;
		}
		case 1:
		{
			formatex(szMenuItem, charsmax(szMenuItem), "%L + %L", id, "DM_EQUIP_ARMOR", id, "DM_EQUIP_HELM");
			menu_item_setname(menu, item, szMenuItem);
			return ITEM_ENABLED;
		}
		case 2:
		{
			formatex(szMenuItem, charsmax(szMenuItem), "%L %L", id, "NO", id, "DM_EQUIP_ARMOR");
			menu_item_setname(menu, item, szMenuItem);
			return ITEM_ENABLED;
		}
	}
	
	return PLUGIN_HANDLED;
}

public CallbackNadeHandler(id, menu, item)
{
	if (item < 0 || !get_bitsum(bs_IsAlive, id))
	{
		return PLUGIN_CONTINUE;
	}
	
	static szMenuItem[128];
	switch (item)
	{
		case 0:
		{
			formatex(szMenuItem, charsmax(szMenuItem), "%L", id, "DM_EQUIP_GRENS_ALL");
			menu_item_setname(menu, item, szMenuItem);
			return ITEM_ENABLED;
		}
		case 1:
		{
			formatex(szMenuItem, charsmax(szMenuItem), "%L", id, "DM_EQUIP_GRENS_NO");
			menu_item_setname(menu, item, szMenuItem);
			return ITEM_ENABLED;
		}
	}
	
	return PLUGIN_HANDLED;
}

public MenuArmorHandler(id, menu, item)
{
	if (item < 0 || !get_bitsum(bs_IsAlive, id))
		return PLUGIN_CONTINUE;
	
	switch (item)
	{
		case 0: cs_set_user_armor(id, 100, CsArmorType:CS_ARMOR_KEVLAR);
		case 1: cs_set_user_armor(id, 100, CsArmorType:CS_ARMOR_VESTHELM);
	}
	
	g_iAutoEquip[id][MENU_ARMOR] = item;
	
	// Menu
	if (g_iAutoEquip[id][MENU_AUTOEQUIP] || g_iAutoEquip[id][MENU_PREVIOUS])
		return PLUGIN_HANDLED;
	
	if (get_bitsum(bs_MenuStatus, MENU_GRENADES))
	{
		DM_CsMenuFix(id);
		menu_display(id, g_iNadeMenuId);
	}
	else
	{
		if (get_bitsum(bs_AutoItems, MENU_AUTO_GRENADES))
		{
			GiveAutoGrenades(id);
		}
		
		GiveEquipment(id);
	}
	
	return PLUGIN_HANDLED;
}

public MenuNadeHandler(id, menu, item)
{
	if (item < 0 || !get_bitsum(bs_IsAlive, id))
		return PLUGIN_CONTINUE;
	
	g_iAutoEquip[id][MENU_GRENADES] = item;
	
	if (item == 0)
	{
		GiveAutoGrenades(id);
	}
	
	GiveEquipment(id);
	
	return PLUGIN_HANDLED;
}

public MenuVipHandler(id, menu, item)
{
	if (item < 0 || !get_bitsum(bs_IsAlive, id))
		return PLUGIN_CONTINUE;
	
	switch (item)
	{
		case 1: // Glock18
		{
			DM_GiveItem(id, "weapon_glock18");
			DM_GiveAmmo(id, CSW_GLOCK18);
		}
		case 2: // Deagle
		{
			DM_GiveItem(id, "weapon_deagle");
			DM_GiveAmmo(id, CSW_DEAGLE);
		}
		case 3: // P228
		{
			DM_GiveItem(id, "weapon_p228");
			DM_GiveAmmo(id, CSW_P228);
		}
		default: // Usp
		{
			DM_GiveItem(id, "weapon_usp");
			DM_GiveAmmo(id, CSW_USP);
		}
	}
	
	return PLUGIN_HANDLED;
}

DM_GiveItem(id, name[])
{
	g_bBlockWeapPickup = true;
	give_item(id, name);
	g_bBlockWeapPickup = false;
	
	return true;
}

DM_GiveAmmo(id, weaponid)
{
	g_bBlockAmmoPickup = true;
	ExecuteHamB(Ham_GiveAmmo, id, MAXBPAMMO[weaponid], AMMOTYPE[weaponid], MAXBPAMMO[weaponid]);
	g_bBlockAmmoPickup = false;
	
	return true;
}

CheckGiveEquipment(id)
{
	if (get_bitsum(bs_MenuStatus, MENU_ARMOR))
	{
		DM_CsMenuFix(id);
		menu_display(id, g_iArmorMenuId);
	}
	else if (get_bitsum(bs_MenuStatus, MENU_GRENADES))
	{
		if (get_bitsum(bs_AutoItems, MENU_AUTO_ARMOR))
		{
			if (get_bitsum(bs_AutoItems, MENU_AUTO_HELMET)) cs_set_user_armor(id, 100, CsArmorType:CS_ARMOR_VESTHELM);
			else cs_set_user_armor(id, 100, CsArmorType:CS_ARMOR_KEVLAR);
		}
		
		DM_CsMenuFix(id);
		menu_display(id, g_iNadeMenuId);
	}
	else
	{
		if (get_bitsum(bs_AutoItems, MENU_AUTO_ARMOR))
		{
			if (get_bitsum(bs_AutoItems, MENU_AUTO_HELMET)) cs_set_user_armor(id, 100, CsArmorType:CS_ARMOR_VESTHELM);
			else cs_set_user_armor(id, 100, CsArmorType:CS_ARMOR_KEVLAR);
		}
		
		if (get_bitsum(bs_AutoItems, MENU_AUTO_GRENADES))
		{
			GiveAutoGrenades(id);
		}
		
		GiveEquipment(id);
	}
}

GiveAutoGrenades(id, strip = 1)
{
	if (strip) strip_weapons(id, GRENADES_ONLY);
	
	if (get_bitsum(bs_Grenades, MENU_GRENADE_HE))
	{
		DM_GiveItem(id, "weapon_hegrenade");
	}
	if (get_bitsum(bs_Grenades, MENU_GRENADE_FLASH) && g_iFlashNum)
	{
		DM_GiveItem(id, "weapon_flashbang"); // 1
		
		if (g_iFlashNum == 2)
		{
			DM_GiveItem(id, "weapon_flashbang"); // 2
		}
	}
	if (get_bitsum(bs_Grenades, MENU_GRENADE_SMOKE))
	{
		DM_GiveItem(id, "weapon_smokegrenade");
	}
}

GiveEquipment(id)
{
	if (g_iTeamID[id] == DM_TEAM_CT && get_bitsum(bs_AutoItems, MENU_AUTO_DEFUSEKIT) && !cs_get_user_defuse(id))
	{
		cs_set_user_defuse(id);
	}
	if (get_bitsum(bs_AutoItems, MENU_AUTO_NIGHTVISION))
	{
		if (!cs_get_user_nvg(id))
			cs_set_user_nvg(id);
		
		if (g_iItemState[id][NIGHTVISION])
			engclient_cmd(id, "nightvision");
	}
}

StripVipSecondary(id)
{
	new weapons[32], wname[32], num_weapons, index, wpnid;
	get_user_weapons(id, weapons, num_weapons);
	
	for (index = 0; index < num_weapons; index++)
	{
		wpnid = weapons[index];
		
		if ((1<<wpnid) & SECONDARY_WEAPONS_BIT_SUM)
		{
			get_weaponname(wpnid, wname, charsmax(wname));
			ham_strip_weapon(id, wname);
		}
	}
	
	return true;
}

AllowWeaponLimit(id, item, type, say)
{
	if (type) // prim
	{
		new iTeam = g_iTeamID[id];
		new limit = g_iPrimWeaponLimiter[item][iTeam];
		
		if (limit == -1)
		{
			return true;
		}
		else if (limit == 0)
		{
			return false;
		}
		else if (g_iPrimWeaponLimit[item][iTeam] < limit)
		{
			return true;
		}
		else if (!say && g_iPrimWeaponLimit[item][iTeam] > limit)
		{
			return false;
		}
		else if (say && g_iPrimWeaponLimit[item][iTeam] >= limit)
		{
			return false;
		}
	}
	else // sec
	{
		new iTeam = g_iTeamID[id];
		new limit = g_iSecWeaponLimiter[item][iTeam];
		
		if (limit == -1)
		{
			return true;
		}
		else if (limit == 0)
		{
			return false;
		}
		else if (g_iSecWeaponLimit[item][iTeam] < limit)
		{
			return true;
		}
		else if (!say && g_iSecWeaponLimit[item][iTeam] > limit)
		{
			return false;
		}
		else if (say && g_iSecWeaponLimit[item][iTeam] >= limit)
		{
			return false;
		}
	}
	
	return true;
}

RestoreWeaponLimit(id, bool:primary, bool:secondary)
{
	new item;
	
	if (primary)
	{
		item = g_iAutoEquip[id][MENU_PRIMARY];
		if (item != -1)
		{
			g_iPrimWeaponLimit[item][g_iTeamID[id]]--;
			g_iAutoEquip[id][MENU_PRIMARY] = -1;
		}
	}
	
	if (secondary)
	{
		item = g_iAutoEquip[id][MENU_SECONDARY];
		if (item != -1)
		{
			g_iSecWeaponLimit[item][g_iTeamID[id]]--;
			g_iAutoEquip[id][MENU_SECONDARY] = -1;
		}
	}
	
	return true;
}

/* --------------------------------------------------------------------------- */

public Msg_TeamInfo(msg_id, msg_dest)
{
	if (msg_dest != MSG_ALL && msg_dest != MSG_BROADCAST)
		return;
	
	static id; id = get_msg_arg_int(1);
	static szTeam[2]; get_msg_arg_string(2, szTeam, 1);
	static iTeam;
	
	switch (szTeam[0])
	{
		case 'S': iTeam = DM_TEAM_SPECTATOR;
		case 'C': iTeam = DM_TEAM_CT;
		case 'T': iTeam = DM_TEAM_T;
		default: iTeam = DM_TEAM_UNASSIGNED;
	}
	
	if (iTeam != g_iTeamID[id] && !get_bitsum(bs_IsBot, id) && !g_iAutoEquip[id][MENU_RANDOM])
	{
		RestoreWeaponLimit(id, true, true);
		
		g_iAutoEquip[id][MENU_AUTOEQUIP] = 0;
		g_iAutoEquip[id][MENU_PREVIOUS] = 0;
		g_iAutoEquip[id][MENU_SHOW] = 1;
	}
	g_iTeamID[id] = iTeam;
}

public Msg_NVGToggle(msg_id, msg_dest, msg_entity)
{
	if (msg_dest != MSG_ONE || !get_bitsum(bs_IsAlive, msg_entity))
		return;
	
	g_iItemState[msg_entity][NIGHTVISION] = get_msg_arg_int(1);
}

public Msg_WeapPickup(msg_id, msg_dest, msg_entity)
{
	if (g_bBlockWeapPickup || get_bitsum(bs_IsSpawning, msg_entity))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public Msg_ItemPickup(msg_id, msg_dest, msg_entity)
{
	return PLUGIN_HANDLED;
}

public Msg_AmmoPickup(msg_id, msg_dest, msg_entity)
{
	if (g_bBlockAmmoPickup || get_bitsum(bs_IsSpawning, msg_entity))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

/* --------------------------------------------------------------------------- */

DM_DropShield(id)
{
	if (cs_get_user_shield(id))
	{
		engclient_cmd(id, "drop", "weapon_shield");
		return true;
	}
	return false;
}

stock strip_weapons(id, stripwhat)
{
	new weapons[32], num_weapons, index, weaponid;
	get_user_weapons(id, weapons, num_weapons);
	
	for (index = 0; index < num_weapons; index++)
	{
		weaponid = weapons[index];
		
		if ((stripwhat == PRIMARY_ONLY && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM))
		|| (stripwhat == SECONDARY_ONLY && ((1<<weaponid) & SECONDARY_WEAPONS_BIT_SUM))
		|| (stripwhat == GRENADES_ONLY && ((1<<weaponid) & GRENADES_WEAPONS_BIT_SUM)))
		{
			new wname[32];
			get_weaponname(weaponid, wname, charsmax(wname));
			
			ham_strip_weapon(id, wname);
			cs_set_user_bpammo(id, weaponid, 0);
		}
	}
	
	return true;
}

stock ham_strip_weapon(index, const weapon[])
{
	new weaponid = get_weaponid(weapon);
	if (!weaponid)
		return false;
	
	new weapon_ent = fm_find_ent_by_owner(-1, weapon, index);
	if (!weapon_ent)
		return false;
	
	new current_weapon_ent = ham_cs_get_current_weapon_ent(index);
	new current_weapon = pev_valid(current_weapon_ent) ? cs_get_weapon_id(current_weapon_ent) : -1;
	if (current_weapon == weaponid)
		ExecuteHamB(Ham_Weapon_RetireWeapon, weapon_ent);
	
	if (!ExecuteHamB(Ham_RemovePlayerItem, index, weapon_ent))
		return false;
	
	ExecuteHamB(Ham_Item_Kill, weapon_ent);
	set_pev(index, pev_weapons, pev(index, pev_weapons) & ~(1<<weaponid));
	return true;
}

stock fm_find_ent_by_owner(entity, const classname[], owner)
{
	while ((entity = engfunc(EngFunc_FindEntityByString, entity, "classname", classname)) && pev(entity, pev_owner) != owner)
	{ /* keep looping */ }
	
	return entity;
}

stock ham_cs_get_current_weapon_ent(id)
{
	if (pev_valid(id) != FM_PDATA_SAFE)
		return -1;
	
	return get_pdata_cbase(id, OFFSET_ACTIVE_ITEM);
}

stock cs_world_weapon_name_to_id(const w_model[])
{
	static i;
	for (i = 1; i < sizeof WorldWeaponModel; i++)
	{
		if (containi(w_model, WorldWeaponModel[i]) != -1)
			return i;
	}
	
	return 0;
}

stock fm_set_rendering(entity, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16)
{
	static Float:color[3];
	color[0] = float(r);
	color[1] = float(g);
	color[2] = float(b);
	
	set_pev(entity, pev_renderfx, fx);
	set_pev(entity, pev_rendercolor, color);
	set_pev(entity, pev_rendermode, render);
	set_pev(entity, pev_renderamt, float(amount));
	
	return true;
}
