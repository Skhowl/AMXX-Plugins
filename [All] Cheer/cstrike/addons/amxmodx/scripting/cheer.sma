/*================================================================================
	
		**************************************
		*********** [Cheer 1.3.1] ************
		**************************************
	
	----------------------
	-*- Licensing Info -*-
	----------------------
	
	Cheer
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
	
	This plugin adds sounds on the unused cheer command from cs and cz.
	Standard button in your config is 'j' to use the cheer command.
	For all mods (games).
	
	--------------------
	-*- Requirements -*-
	--------------------
	
	* Game: All
	* Metamod: Version 1.19 or later
	* AMXX: Version 1.8.0 or later
	* Module: hamsandwich
	
	-------------
	-*- CVARS -*-
	-------------
	
	cheer_announce 1 // Give a chat announce each round to notice that plugin is exists.
	cheer_show_cooldown 1 // Print center the cooldown time if a player pressing the cheer command while he has cooldown.
	cheer_cooldown 15.0 // Time between cheer uses.
	
	-----------------
	-*- Changelog -*-
	-----------------
	
	* v1.0.0: (7th Mar 2011)
	   - initial release
	
	* v1.1.0: (8th Mar 2011)
	   - Added: external file cheer.ini
	
	* v1.1.0: (13th May 2011)
	   - RC2: fixes some minor things (suggested by Nextra)
	
	* v1.2.0: (16th Nov 2011)
	   - Change: HLTV not used by all hl games, used hamsandwich
	
	* v1.3.0: (16th Nov 2011)
	   - Added: map and map prefix support
	   - Change: many code
	
	* v1.3.1: (16th Nov 2011)
	   - Added: multi language support
	
=================================================================================*/

#include <amxmodx>
#include <hamsandwich>

new const PLUGIN_VERSION[] = "1.3.1"

new Float:g_fNextCheer[33]

new cvar_iAnnouce, cvar_iShowCoolDown, cvar_fCoolDown

new g_iArraySize

new Array:g_szCheerSound
new Trie:g_szCheerSoundTrie

/*================================================================================
 [Precache and Init]
=================================================================================*/

public plugin_precache()
{
	register_plugin("Cheer", PLUGIN_VERSION, "schmurgel1983")
	
	register_dictionary("cheer.txt")
	
	g_szCheerSound = ArrayCreate(64, 1)
	g_szCheerSoundTrie = TrieCreate()
	
	load_cheer()
	
	TrieDestroy(g_szCheerSoundTrie)
	
	new sound[64]
	g_iArraySize = ArraySize(g_szCheerSound)
	
	for (new i = 0; i < g_iArraySize; i++)
	{
		formatex(sound, charsmax(sound), "sound/%a", ArrayGetStringHandle(g_szCheerSound, i))
		
		if (!file_exists(sound))
		{
			log_amx("%L", LANG_SERVER, "CHEER_NOT_PRESENT", sound)
			ArrayDeleteItem(g_szCheerSound, i--)
			g_iArraySize -= 1
		}
		else precache_sound(sound[6]);
	}
}

public plugin_init()
{
	RegisterHam(Ham_Spawn, "player", "fwd_PlayerSpawn_Post", 1)
	
	register_clcmd("cheer", "clcmd_cheer")
	
	cvar_iAnnouce = register_cvar("cheer_announce", "1")
	cvar_iShowCoolDown = register_cvar("cheer_show_cooldown", "1")
	cvar_fCoolDown = register_cvar("cheer_cooldown", "15.0")
	
	register_cvar("cheer_version", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY)
	set_cvar_string("cheer_version", PLUGIN_VERSION)
}

/*================================================================================
 [Main Forwards]
=================================================================================*/

public fwd_PlayerSpawn_Post(id)
{
	if (!is_user_alive(id))
		return
	
	if (get_pcvar_num(cvar_iAnnouce))
	{
		remove_task(id)
		set_task(3.0, "cheer_announce", id)
	}
	
	g_fNextCheer[id] = get_gametime()
}

public client_disconnect(id)
	g_fNextCheer[id] = get_gametime()

/*================================================================================
 [Client Commands]
=================================================================================*/

public clcmd_cheer(id)
{
	if (!is_user_alive(id) || g_iArraySize <= 0)
		return PLUGIN_HANDLED
	
	new Float:time = get_gametime()
	
	if (g_fNextCheer[id] > time)
	{
		if (get_pcvar_num(cvar_iShowCoolDown))
			client_print(id, print_center, "%L", id, "CHEER_NEXT", g_fNextCheer[id] - time)
		
		return PLUGIN_HANDLED
	}
	
	static sound[64]
	ArrayGetString(g_szCheerSound, random_num(0, g_iArraySize - 1), sound, charsmax(sound))
	emit_sound(id, CHAN_VOICE, sound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	g_fNextCheer[id] = time + get_pcvar_float(cvar_fCoolDown)
	
	return PLUGIN_HANDLED
}

/*================================================================================
 [Other Functions]
=================================================================================*/

public cheer_announce(id)
{
	if (is_user_connected(id))
		client_print(id, print_chat, "[CHEER] %L", id, "CHEER_ANNOUNCE")
}

load_cheer()
{
	new path[64]
	get_configsdir(path, charsmax(path))
	format(path, charsmax(path), "%s/cheer.ini", path)
	
	if (!file_exists(path))
	{
		new error[100]
		formatex(error, charsmax(error), "%L", LANG_SERVER, "CHEER_LOAD", path)
		set_fail_state(error)
		return
	}
	
	new file = fopen(path, "rt")
	if (!file)
	{
		new error[100]
		formatex(error, charsmax(error), "%L", LANG_SERVER, "CHEER_OPEN", path)
		set_fail_state(error)
		return
	}
	
	new linedata[1024], key[32], value[992], mapname[32]
	get_mapname(mapname, charsmax(mapname))
	
	while (!feof(file))
	{
		fgets(file, linedata, charsmax(linedata))
		trim(linedata)
		
		if (!linedata[0] || linedata[0] == ';' || linedata[0] == '#') continue
		
		strtok(linedata, key, charsmax(key), value, charsmax(value), '=')
		trim(key), trim(value);
		
		if (equali(key, "ALL") || equali(key, mapname, strlen(key)) || equali(key, mapname))
		{
			while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
			{
				trim(key), trim(value);
				
				if (!TrieKeyExists(g_szCheerSoundTrie, key))
				{
					ArrayPushString(g_szCheerSound, key)
					TrieSetCell(g_szCheerSoundTrie, key, 1)
				}
			}
		}
	}
	fclose(file)
}

/*================================================================================
 [Stocks]
=================================================================================*/

stock get_configsdir(name[], len)
{
	return get_localinfo("amxx_configsdir", name, len);
}
