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
#include <amxmisc>
#include <fakemeta>
#include <nvault>

#include <dm_core>
#include <dm_rewards>
#include <dm_colorchat>

/* --------------------------------------------------------------------------- */

const MAX_MONEY = 999999;

#define TASK_ANNOUNCE 555

/* --------------------------------------------------------------------------- */

new bool:g_bBankEnabled = false;
new bool:g_bBankRoundEnd = false;
new bool:g_bBankDonate = false;
new g_iBankLimit = 0;
new g_iBankSave = 365;

/* --------------------------------------------------------------------------- */

new g_iTeamID[DM_MAX_PLAYERS+1] = { 0, ... };

new amx_show_activity = 0;

new bool:g_bIntermission = false;

#if AMXX_VERSION_NUM < 183
new g_iMaxPlayers = 0;
#endif

new g_szDatabase[32] = "default";

new bs_IsConnected = 0;
new bs_IsBot = 0;

#define get_bitsum(%1,%2)   (%1 &   (1<<((%2-1)&31)))
#define add_bitsum(%1,%2)    %1 |=  (1<<((%2-1)&31))
#define del_bitsum(%1,%2)    %1 &= ~(1<<((%2-1)&31))

/* -Init---------------------------------------------------------------------- */

public DM_OnModStatus(status)
{
	register_plugin("DM: Bank nVault", DM_VERSION_STR_LONG, "schmurgel1983");
	
	if (status) state enabled;
	else state deactivated;
}

public plugin_init() <deactivated> {}
public plugin_init() <enabled>
{
	if (!DM_LoadConfiguration("dm_bank.cfg", "DM_ReadBank") || !g_bBankEnabled)
	{
		register_event("HLTV", "EventRoundStart", "a", "1=0", "2=0");
		register_logevent("EventRoundEnd", 2, "1=Round_End");
		
		state deactivated;
		return;
	}
	
	#if AMXX_VERSION_NUM < 183
	register_dictionary_colored("dm_bank.txt");
	#else
	register_dictionary("dm_bank.txt");
	#endif
	register_dictionary("admincmd.txt");
	
	register_event("HLTV", "EventRoundStart", "a", "1=0", "2=0");
	register_logevent("EventRoundEnd", 2, "1=Round_End");
	
	register_clcmd("say", "HandleSay");
	register_clcmd("say_team", "HandleSay");
	
	register_concmd("dm_bank_show", "ClientCmdBankShow", ADMIN_RCON);
	register_concmd("dm_bank_set", "ClientCmdBankSet", ADMIN_RCON, "<@All, @CT, @T, @Bots, name or #userid> <+ or ->amount");
	
	register_message(get_user_msgid("TeamInfo"), "Msg_TeamInfo");
	
	amx_show_activity = get_cvar_pointer("amx_show_activity");
	
	#if AMXX_VERSION_NUM < 183
	g_iMaxPlayers = get_maxplayers();
	#endif
}

public DM_ReadBank(section[], key[], value[])
{
	if (equali(section, "bank"))
	{
		if (equali(key, "enabled")) g_bBankEnabled = !!bool:str_to_num(value);
		else if (equali(key, "bank_limit")) g_iBankLimit = clamp(str_to_num(value), 0, MAX_MONEY);
		else if (equali(key, "bank_save_days")) g_iBankSave = clamp(str_to_num(value), 0, 365);
		else if (equali(key, "bank_save_roundend")) g_bBankRoundEnd = !!bool:str_to_num(value);
		else if (equali(key, "bank_allow_donate")) g_bBankDonate = !!bool:str_to_num(value);
	}
	else if (equali(section, "nvault"))
	{
		if (equali(key, "bank_db"))
		{
			copy(g_szDatabase, charsmax(g_szDatabase), value);
			remove_quotes(g_szDatabase);
		}
	}
}

public plugin_end() <deactivated> {}
public plugin_end() <enabled>
{
	new vault = INVALID_HANDLE;
	if (g_iBankSave && (vault = DB_Connect(g_szDatabase)) != INVALID_HANDLE)
	{
		nvault_prune(vault, 0, get_systime() - (g_iBankSave * 86400));
		DB_Close(vault);
	}
}

/* -Client-------------------------------------------------------------------- */

public client_putinserver(id) <deactivated> {}
public client_putinserver(id) <enabled>
{
	add_bitsum(bs_IsConnected, id);
	
	if (is_user_bot(id))
		add_bitsum(bs_IsBot, id);
	
	if (g_bIntermission) return;
	
	new vault = INVALID_HANDLE;
	if ((vault = DB_Connect(g_szDatabase)) != INVALID_HANDLE)
	{
		DB_GetAllData(id, vault);
		DB_Close(vault);
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
	if (!g_bIntermission)
	{
		new vault = INVALID_HANDLE;
		if ((vault = DB_Connect(g_szDatabase)) != INVALID_HANDLE)
		{
			DB_SaveAllData(id, vault);
			DB_Close(vault);
		}
	}
	
	del_bitsum(bs_IsConnected, id);
	del_bitsum(bs_IsBot, id);
}

/* -Events-------------------------------------------------------------------- */

public EventRoundStart()
{
	remove_task(TASK_ANNOUNCE);
	set_task(5.0, "ShowBankAnnounce", TASK_ANNOUNCE);
}

public EventRoundEnd() <deactivated>
{
	remove_task(TASK_ANNOUNCE);
}
public EventRoundEnd() <enabled>
{
	remove_task(TASK_ANNOUNCE);
	
	if (!g_bBankRoundEnd || g_bIntermission)
		return;
	
	new vault = INVALID_HANDLE;
	if ((vault = DB_Connect(g_szDatabase)) != INVALID_HANDLE)
	{
		static id;
		#if AMXX_VERSION_NUM < 183
		for (id = 1; id <= g_iMaxPlayers; id++)
		#else
		for (id = 1; id <= MaxClients; id++)
		#endif
		{
			if (!get_bitsum(bs_IsConnected, id))
				continue;
			
			DB_SaveAllData(id, vault);
		}
		DB_Close(vault);
	}
}

public ShowBankAnnounce() <deactivated>
{
	#if AMXX_VERSION_NUM < 183
	dm_print_color(0, Red, "^4[DM-Bank]^1 %L", LANG_SERVER, "DM_BANK_DISABLED");
	#else
	client_print_color(0, print_team_red, "^4[DM-Bank]^1 %L", LANG_SERVER, "DM_BANK_DISABLED");
	#endif
}
public ShowBankAnnounce() <enabled>
{
	#if AMXX_VERSION_NUM < 183
	dm_print_color(0, Red, "^4[DM-Bank]^1 %L", LANG_SERVER, "DM_BANK_ENABLED");
	#else
	client_print_color(0, print_team_red, "^4[DM-Bank]^1 %L", LANG_SERVER, "DM_BANK_ENABLED");
	#endif
}

/* -Scenarios----------------------------------------------------------------- */

public DM_OnIntermission()
{
	g_bIntermission = true;
	
	new vault = INVALID_HANDLE;
	if ((vault = DB_Connect(g_szDatabase)) != INVALID_HANDLE)
	{
		static id;
		#if AMXX_VERSION_NUM < 183
		for (id = 1; id <= g_iMaxPlayers; id++)
		#else
		for (id = 1; id <= MaxClients; id++)
		#endif
		{
			if (!get_bitsum(bs_IsConnected, id))
				continue;
			
			DB_SaveAllData(id, vault);
		}
		DB_Close(vault);
	}
	else g_bIntermission = false;
}

/* -Cmd----------------------------------------------------------------------- */

public ClientCmdBankShow(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED;
	
	new szPlayerName[32], szPlayerMoney[11];
	formatex(szPlayerName, charsmax(szPlayerName), "%L", id, "DM_BANK_NAME");
	formatex(szPlayerMoney, charsmax(szPlayerMoney), "%L", id, "DM_BANK_MONEY");
	console_print(id, "%-23s %s", szPlayerName, szPlayerMoney);
	
	#if AMXX_VERSION_NUM < 183
	for (new i = 1; i <= g_iMaxPlayers; i++)
	#else
	for (new i = 1; i <= MaxClients; i++)
	#endif
	{
		if (!get_bitsum(bs_IsConnected, i))
			continue;
		
		get_user_name(i, szPlayerName, charsmax(szPlayerName));
		console_print(id, "%-23s %d", szPlayerName, DM_GetUserMoney(i));
	}
	
	return PLUGIN_HANDLED;
}

public ClientCmdBankSet(id, level, cid)
{
	if (!cmd_access(id, level, cid, 3) || g_bIntermission)
		return PLUGIN_HANDLED;
	
	static szTarget[32], iPlayer, szAmount[12], iAmount;
	read_argv(1, szTarget, charsmax(szTarget));
	
	if (szTarget[0] == '@')
	{
		static i;
		read_argv(2, szAmount, charsmax(szAmount));
		remove_quotes(szAmount);
		iAmount = str_to_num(szAmount);
		
		if (equali(szTarget[1], "All"))
		{
			#if AMXX_VERSION_NUM < 183
			for (i = 1; i <= g_iMaxPlayers; i++)
			#else
			for (i = 1; i <= MaxClients; i++)
			#endif
			{
				if (!get_bitsum(bs_IsConnected, i))
					continue;
				
				switch (szAmount[0])
				{
					case '+': DM_SetUserMoney(i, DM_GetUserMoney(i)+iAmount, 1);
					case '-': DM_SetUserMoney(i, DM_GetUserMoney(i)-(0-iAmount), 1);
					default: DM_SetUserMoney(i, iAmount, 1);
				}
			}
			
			if (amx_show_activity)
			{
				switch (get_pcvar_num(amx_show_activity))
				{
					case 2:
					{
						new szName[32];
						get_user_name(id, szName, 31);
						switch (szAmount[0])
						{
							#if AMXX_VERSION_NUM < 183
							case '+': dm_print_color(0, DontChange, "^4[DM-Bank]^1 %L^4 %s^1 : %L", LANG_SERVER, "DM_BANK_ADMIN", szName, LANG_SERVER, "DM_BANK_ALL_GIVE", iAmount);
							case '-': dm_print_color(0, DontChange, "^4[DM-Bank]^1 %L^4 %s^1 : %L", LANG_SERVER, "DM_BANK_ADMIN", szName, LANG_SERVER, "DM_BANK_ALL_REMOVE", iAmount);
							default: dm_print_color(0, DontChange, "^4[DM-Bank]^1 %L^4 %s^1 : %L", LANG_SERVER, "DM_BANK_ADMIN", szName, LANG_SERVER, "DM_BANK_ALL_SET", iAmount);
							#else
							case '+': client_print_color(0, print_team_default, "^4[DM-Bank]^1 %L^4 %s^1 : %L", LANG_SERVER, "DM_BANK_ADMIN", szName, LANG_SERVER, "DM_BANK_ALL_GIVE", iAmount);
							case '-': client_print_color(0, print_team_default, "^4[DM-Bank]^1 %L^4 %s^1 : %L", LANG_SERVER, "DM_BANK_ADMIN", szName, LANG_SERVER, "DM_BANK_ALL_REMOVE", iAmount);
							default: client_print_color(0, print_team_default, "^4[DM-Bank]^1 %L^4 %s^1 : %L", LANG_SERVER, "DM_BANK_ADMIN", szName, LANG_SERVER, "DM_BANK_ALL_SET", iAmount);
							#endif
						}
					}
					case 1:
					{
						switch (szAmount[0])
						{
							#if AMXX_VERSION_NUM < 183
							case '+': dm_print_color(0, DontChange, "^4[DM-Bank]^1 %L: %L", LANG_SERVER, "DM_BANK_ADMIN", LANG_SERVER, "DM_BANK_ALL_GIVE", iAmount);
							case '-': dm_print_color(0, DontChange, "^4[DM-Bank]^1 %L: %L", LANG_SERVER, "DM_BANK_ADMIN", LANG_SERVER, "DM_BANK_ALL_REMOVE", iAmount);
							default: dm_print_color(0, DontChange, "^4[DM-Bank]^1 %L: %L", LANG_SERVER, "DM_BANK_ADMIN", LANG_SERVER, "DM_BANK_ALL_SET", iAmount);
							#else
							case '+': client_print_color(0, print_team_default, "^4[DM-Bank]^1 %L: %L", LANG_SERVER, "DM_BANK_ADMIN", LANG_SERVER, "DM_BANK_ALL_GIVE", iAmount);
							case '-': client_print_color(0, print_team_default, "^4[DM-Bank]^1 %L: %L", LANG_SERVER, "DM_BANK_ADMIN", LANG_SERVER, "DM_BANK_ALL_REMOVE", iAmount);
							default: client_print_color(0, print_team_default, "^4[DM-Bank]^1 %L: %L", LANG_SERVER, "DM_BANK_ADMIN", LANG_SERVER, "DM_BANK_ALL_SET", iAmount);
							#endif
						}
					}
				}
			}
			return PLUGIN_HANDLED;
		}
		else if (equali(szTarget[1], "CT"))
		{
			#if AMXX_VERSION_NUM < 183
			for (i = 1; i <= g_iMaxPlayers; i++)
			#else
			for (i = 1; i <= MaxClients; i++)
			#endif
			{
				if (!get_bitsum(bs_IsConnected, i) || g_iTeamID[i] != DM_TEAM_CT)
					continue;
				
				switch (szAmount[0])
				{
					case '+': DM_SetUserMoney(i, DM_GetUserMoney(i)+iAmount, 1);
					case '-': DM_SetUserMoney(i, DM_GetUserMoney(i)-(0-iAmount), 1);
					default: DM_SetUserMoney(i, iAmount, 1);
				}
			}
			
			if (amx_show_activity)
			{
				switch (get_pcvar_num(amx_show_activity))
				{
					case 2:
					{
						new szName[32];
						get_user_name(id, szName, 31);
						switch (szAmount[0])
						{
							#if AMXX_VERSION_NUM < 183
							case '+': dm_print_color(0, Blue, "^4[DM-Bank]^1 %L^4 %s^1 : %L", LANG_SERVER, "DM_BANK_ADMIN", szName, LANG_SERVER, "DM_BANK_CT_GIVE", iAmount);
							case '-': dm_print_color(0, Blue, "^4[DM-Bank]^1 %L^4 %s^1 : %L", LANG_SERVER, "DM_BANK_ADMIN", szName, LANG_SERVER, "DM_BANK_CT_REMOVE", iAmount);
							default: dm_print_color(0, Blue, "^4[DM-Bank]^1 %L^4 %s^1 : %L", LANG_SERVER, "DM_BANK_ADMIN", szName, LANG_SERVER, "DM_BANK_CT_SET", iAmount);
							#else
							case '+': client_print_color(0, print_team_blue, "^4[DM-Bank]^1 %L^4 %s^1 : %L", LANG_SERVER, "DM_BANK_ADMIN", szName, LANG_SERVER, "DM_BANK_CT_GIVE", iAmount);
							case '-': client_print_color(0, print_team_blue, "^4[DM-Bank]^1 %L^4 %s^1 : %L", LANG_SERVER, "DM_BANK_ADMIN", szName, LANG_SERVER, "DM_BANK_CT_REMOVE", iAmount);
							default: client_print_color(0, print_team_blue, "^4[DM-Bank]^1 %L^4 %s^1 : %L", LANG_SERVER, "DM_BANK_ADMIN", szName, LANG_SERVER, "DM_BANK_CT_SET", iAmount);
							#endif
						}
					}
					case 1:
					{
						switch (szAmount[0])
						{
							#if AMXX_VERSION_NUM < 183
							case '+': dm_print_color(0, Blue, "^4[DM-Bank]^1 %L: %L", LANG_SERVER, "DM_BANK_ADMIN", LANG_SERVER, "DM_BANK_CT_GIVE", iAmount);
							case '-': dm_print_color(0, Blue, "^4[DM-Bank]^1 %L: %L", LANG_SERVER, "DM_BANK_ADMIN", LANG_SERVER, "DM_BANK_CT_REMOVE", iAmount);
							default: dm_print_color(0, Blue, "^4[DM-Bank]^1 %L: %L", LANG_SERVER, "DM_BANK_ADMIN", LANG_SERVER, "DM_BANK_CT_SET", iAmount);
							#else
							case '+': client_print_color(0, print_team_blue, "^4[DM-Bank]^1 %L: %L", LANG_SERVER, "DM_BANK_ADMIN", LANG_SERVER, "DM_BANK_CT_GIVE", iAmount);
							case '-': client_print_color(0, print_team_blue, "^4[DM-Bank]^1 %L: %L", LANG_SERVER, "DM_BANK_ADMIN", LANG_SERVER, "DM_BANK_CT_REMOVE", iAmount);
							default: client_print_color(0, print_team_blue, "^4[DM-Bank]^1 %L: %L", LANG_SERVER, "DM_BANK_ADMIN", LANG_SERVER, "DM_BANK_CT_SET", iAmount);
							#endif
						}
					}
				}
			}
			return PLUGIN_HANDLED;
		}
		else if (equali(szTarget[1], "T"))
		{
			#if AMXX_VERSION_NUM < 183
			for (i = 1; i <= g_iMaxPlayers; i++)
			#else
			for (i = 1; i <= MaxClients; i++)
			#endif
			{
				if (!get_bitsum(bs_IsConnected, i) || g_iTeamID[i] != DM_TEAM_T)
					continue;
				
				switch (szAmount[0])
				{
					case '+': DM_SetUserMoney(i, DM_GetUserMoney(i)+iAmount, 1);
					case '-': DM_SetUserMoney(i, DM_GetUserMoney(i)-(0-iAmount), 1);
					default: DM_SetUserMoney(i, iAmount, 1);
				}
			}
			
			if (amx_show_activity)
			{
				switch (get_pcvar_num(amx_show_activity))
				{
					case 2:
					{
						new szName[32];
						get_user_name(id, szName, 31);
						switch (szAmount[0])
						{
							#if AMXX_VERSION_NUM < 183
							case '+': dm_print_color(0, Red, "^4[DM-Bank]^1 %L^4 %s^1 : %L", LANG_SERVER, "DM_BANK_ADMIN", szName, LANG_SERVER, "DM_BANK_TER_GIVE", iAmount);
							case '-': dm_print_color(0, Red, "^4[DM-Bank]^1 %L^4 %s^1 : %L", LANG_SERVER, "DM_BANK_ADMIN", szName, LANG_SERVER, "DM_BANK_TER_REMOVE", iAmount);
							default: dm_print_color(0, Red, "^4[DM-Bank]^1 %L^4 %s^1 : %L", LANG_SERVER, "DM_BANK_ADMIN", szName, LANG_SERVER, "DM_BANK_TER_SET", iAmount);
							#else
							case '+': client_print_color(0, print_team_red, "^4[DM-Bank]^1 %L^4 %s^1 : %L", LANG_SERVER, "DM_BANK_ADMIN", szName, LANG_SERVER, "DM_BANK_TER_GIVE", iAmount);
							case '-': client_print_color(0, print_team_red, "^4[DM-Bank]^1 %L^4 %s^1 : %L", LANG_SERVER, "DM_BANK_ADMIN", szName, LANG_SERVER, "DM_BANK_TER_REMOVE", iAmount);
							default: client_print_color(0, print_team_red, "^4[DM-Bank]^1 %L^4 %s^1 : %L", LANG_SERVER, "DM_BANK_ADMIN", szName, LANG_SERVER, "DM_BANK_TER_SET", iAmount);
							#endif
						}
					}
					case 1:
					{
						switch (szAmount[0])
						{
							#if AMXX_VERSION_NUM < 183
							case '+': dm_print_color(0, Red, "^4[DM-Bank]^1 %L: %L", LANG_SERVER, "DM_BANK_ADMIN", LANG_SERVER, "DM_BANK_TER_GIVE", iAmount);
							case '-': dm_print_color(0, Red, "^4[DM-Bank]^1 %L: %L", LANG_SERVER, "DM_BANK_ADMIN", LANG_SERVER, "DM_BANK_TER_REMOVE", iAmount);
							default: dm_print_color(0, Red, "^4[DM-Bank]^1 %L: %L", LANG_SERVER, "DM_BANK_ADMIN", LANG_SERVER, "DM_BANK_TER_SET", iAmount);
							#else
							case '+': client_print_color(0, print_team_red, "^4[DM-Bank]^1 %L: %L", LANG_SERVER, "DM_BANK_ADMIN", LANG_SERVER, "DM_BANK_TER_GIVE", iAmount);
							case '-': client_print_color(0, print_team_red, "^4[DM-Bank]^1 %L: %L", LANG_SERVER, "DM_BANK_ADMIN", LANG_SERVER, "DM_BANK_TER_REMOVE", iAmount);
							default: client_print_color(0, print_team_red, "^4[DM-Bank]^1 %L: %L", LANG_SERVER, "DM_BANK_ADMIN", LANG_SERVER, "DM_BANK_TER_SET", iAmount);
							#endif
						}
					}
				}
			}
			return PLUGIN_HANDLED;
		}
		else if (equali(szTarget[1], "Bots"))
		{
			#if AMXX_VERSION_NUM < 183
			for (i = 1; i <= g_iMaxPlayers; i++)
			#else
			for (i = 1; i <= MaxClients; i++)
			#endif
			{
				if (!get_bitsum(bs_IsConnected, i) || !get_bitsum(bs_IsBot, i))
					continue;
				
				switch (szAmount[0])
				{
					case '+': DM_SetUserMoney(i, DM_GetUserMoney(i)+iAmount, 1);
					case '-': DM_SetUserMoney(i, DM_GetUserMoney(i)-(0-iAmount), 1);
					default: DM_SetUserMoney(i, iAmount, 1);
				}
			}
			return PLUGIN_HANDLED;
		}
	}
	
	iPlayer = cmd_target(id, szTarget, CMDTARGET_ALLOW_SELF);
	if (!iPlayer)
		return PLUGIN_HANDLED;
	
	read_argv(2, szAmount, charsmax(szAmount));
	remove_quotes(szAmount);
	iAmount = str_to_num(szAmount);
	
	switch (szAmount[0])
	{
		case '+': DM_SetUserMoney(iPlayer, DM_GetUserMoney(iPlayer)+iAmount, 1);
		case '-': DM_SetUserMoney(iPlayer, DM_GetUserMoney(iPlayer)-(0-iAmount), 1);
		default: DM_SetUserMoney(iPlayer, iAmount, 1);
	}
	
	if (amx_show_activity)
	{
		switch (get_pcvar_num(amx_show_activity))
		{
			case 2:
			{
				new szName[32];
				get_user_name(id, szName, 31);
				switch (szAmount[0])
				{
					#if AMXX_VERSION_NUM < 183
					case '+': dm_print_color(iPlayer, Red, "^4[DM-Bank]^1 %L^4 %s^1 : %L", iPlayer, "DM_BANK_ADMIN", szName, iPlayer, "DM_BANK_PERSONAL_GIVE", iAmount);
					case '-': dm_print_color(iPlayer, Red, "^4[DM-Bank]^1 %L^4 %s^1 : %L", iPlayer, "DM_BANK_ADMIN", szName, iPlayer, "DM_BANK_PERSONAL_REMOVE", iAmount);
					default: dm_print_color(iPlayer, Red, "^4[DM-Bank]^1 %L^4 %s^1 : %L", iPlayer, "DM_BANK_ADMIN", szName, iPlayer, "DM_BANK_PERSONAL_SET", iAmount);
					#else
					case '+': client_print_color(iPlayer, print_team_red, "^4[DM-Bank]^1 %L^4 %s^1 : %L", iPlayer, "DM_BANK_ADMIN", szName, iPlayer, "DM_BANK_PERSONAL_GIVE", iAmount);
					case '-': client_print_color(iPlayer, print_team_red, "^4[DM-Bank]^1 %L^4 %s^1 : %L", iPlayer, "DM_BANK_ADMIN", szName, iPlayer, "DM_BANK_PERSONAL_REMOVE", iAmount);
					default: client_print_color(iPlayer, print_team_red, "^4[DM-Bank]^1 %L^4 %s^1 : %L", iPlayer, "DM_BANK_ADMIN", szName, iPlayer, "DM_BANK_PERSONAL_SET", iAmount);
					#endif
				}
			}
			case 1:
			{
				switch (szAmount[0])
				{
					#if AMXX_VERSION_NUM < 183
					case '+': dm_print_color(iPlayer, Red, "^4[DM-Bank]^1 %L: %L", iPlayer, "DM_BANK_ADMIN", iPlayer, "DM_BANK_PERSONAL_GIVE", iAmount);
					case '-': dm_print_color(iPlayer, Red, "^4[DM-Bank]^1 %L: %L", iPlayer, "DM_BANK_ADMIN", iPlayer, "DM_BANK_PERSONAL_REMOVE", iAmount);
					default: dm_print_color(iPlayer, Red, "^4[DM-Bank]^1 %L: %L", iPlayer, "DM_BANK_ADMIN", iPlayer, "DM_BANK_PERSONAL_SET", iAmount);
					#else
					case '+': client_print_color(iPlayer, print_team_red, "^4[DM-Bank]^1 %L: %L", iPlayer, "DM_BANK_ADMIN", iPlayer, "DM_BANK_PERSONAL_GIVE", iAmount);
					case '-': client_print_color(iPlayer, print_team_red, "^4[DM-Bank]^1 %L: %L", iPlayer, "DM_BANK_ADMIN", iPlayer, "DM_BANK_PERSONAL_REMOVE", iAmount);
					default: client_print_color(iPlayer, print_team_red, "^4[DM-Bank]^1 %L: %L", iPlayer, "DM_BANK_ADMIN", iPlayer, "DM_BANK_PERSONAL_SET", iAmount);
					#endif
				}
			}
		}
	}
	
	return PLUGIN_HANDLED;
}

/* -DB------------------------------------------------------------------------ */

DB_Connect(const database[])
{
	if (!g_iBankSave || !g_iBankLimit)
		return INVALID_HANDLE;
	
	return nvault_open(database);
}

DB_Close(vault)
{
	if (vault == INVALID_HANDLE)
		return;
	
	nvault_close(vault);
	vault = INVALID_HANDLE;
}

DB_SaveAllData(const index, const vault)
{
	if (!index) return;
	
	new szAuth[36];
	if (get_bitsum(bs_IsBot, index)) get_user_name(index, szAuth, 35);
	else get_user_authid(index, szAuth, 35);
	
	if (containi(szAuth, "PENDING") != -1 /*|| containi(szAuth, "LAN") != -1 */|| containi(szAuth, "UNKNOWN") != -1)
		return;
	
	new iAmount = clamp(DM_GetUserMoney(index), -1, g_iBankLimit);
	if (iAmount >= 0)
	{
		new szAmount[12];
		format(szAmount, 11, "%d", iAmount);
		nvault_set(vault, szAuth, szAmount);
	}
}

DB_GetAllData(const index, const vault)
{
	if (!index) return;
	
	new szAuth[36];
	if (get_bitsum(bs_IsBot, index)) get_user_name(index, szAuth, 35);
	else get_user_authid(index, szAuth, 35);
	
	if (containi(szAuth, "PENDING") != -1 /*|| containi(szAuth, "LAN") != -1 */|| containi(szAuth, "UNKNOWN") != -1)
		return;
	
	new szAmount[12];
	nvault_get(vault, szAuth, szAmount, 11);
	
	if (!szAmount[0]) return;
	else DM_SetUserMoney(index, clamp(str_to_num(szAmount), 0, g_iBankLimit), 1);
}

/* -Say----------------------------------------------------------------------- */

public HandleSay(id)
{
	if (g_bIntermission)
		return PLUGIN_CONTINUE;
	
	new szText[61], szCommand[11], szTarget[33], szAmount[11];
	read_args(szText, 60);
	remove_quotes(szText);
	parse(szText, szCommand, 10, szTarget, 32, szAmount, 10);
	
	new iReturn = PLUGIN_CONTINUE;
	switch (szCommand[0])
	{
		case '!', '.': // Handled
		{
			format(szCommand, 10, szCommand[1]);
			iReturn = PLUGIN_HANDLED;
		}
		case '/', '@': // Continue
		{
			format(szCommand, 10, szCommand[1]);
		}
	}
	
	if (g_bBankDonate && equali(szCommand, "donate", 6))
	{
		DM_Donate(id, szTarget, str_to_num(szAmount));
		return iReturn;
	}
	
	return PLUGIN_CONTINUE;
}

/* -Misc---------------------------------------------------------------------- */

public DM_Donate(const iDonater, const szRecieverName[], const iAmount)
{
	if (!szRecieverName[0] || iAmount <= 0 || DM_GetUserMoney(iDonater) < iAmount)
	{
		#if AMXX_VERSION_NUM < 183
		dm_print_color(iDonater, DontChange, "^4[DM-Bank]^1 %L", iDonater, "DM_BANK_DONATE_USAGE");
		#else
		client_print_color(iDonater, print_team_default, "^4[DM-Bank]^1 %L", iDonater, "DM_BANK_DONATE_USAGE");
		#endif
		return;
	}
	
	new iReciever = cmd_target(iDonater, szRecieverName, CMDTARGET_NO_BOTS | CMDTARGET_ALLOW_SELF);
	if (!iReciever || iReciever == iDonater)
	{
		#if AMXX_VERSION_NUM < 183
		dm_print_color(iDonater, DontChange, "^4[DM-Bank]^1 %L", iDonater, "DM_BANK_DONATE_NOT_FOUND", szRecieverName);
		#else
		client_print_color(iDonater, print_team_default, "^4[DM-Bank]^1 %L", iDonater, "DM_BANK_DONATE_NOT_FOUND", szRecieverName);
		#endif
		return;
	}
	
	DM_SetUserMoney(iDonater, DM_GetUserMoney(iDonater)-iAmount, 1);
	DM_SetUserMoney(iReciever, DM_GetUserMoney(iReciever)+iAmount, 1);
	
	new szName[32];
	get_user_name(iDonater, szName, 31);
	#if AMXX_VERSION_NUM < 183
	dm_print_color(0, Red, "^4[DM-Bank]^3 %L", iDonater, "DM_BANK_DONATE_SUCCESS", szName, szRecieverName, iAmount);
	#else
	client_print_color(0, print_team_red, "^4[DM-Bank]^3 %L", iDonater, "DM_BANK_DONATE_SUCCESS", szName, szRecieverName, iAmount);
	#endif
}

/* -Message------------------------------------------------------------------- */

public Msg_TeamInfo(msg_id, msg_dest)
{
	if (msg_dest != MSG_ALL && msg_dest != MSG_BROADCAST)
		return;
	
	static id; id = get_msg_arg_int(1);
	static team[2]; get_msg_arg_string(2, team, charsmax(team));
	
	switch (team[0])
	{
		case 'S': g_iTeamID[id] = DM_TEAM_SPECTATOR;
		case 'C': g_iTeamID[id] = DM_TEAM_CT;
		case 'T': g_iTeamID[id] = DM_TEAM_T;
		default: g_iTeamID[id] = DM_TEAM_UNASSIGNED;
	}
}
