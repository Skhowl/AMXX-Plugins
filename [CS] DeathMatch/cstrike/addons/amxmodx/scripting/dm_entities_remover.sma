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

new g_iFwdSpawn = 0;

new Trie:Entities = Invalid_Trie;

/* -Init---------------------------------------------------------------------- */

public DM_OnModStatus(status)
{
	register_plugin("DM: Entities Remover", DM_VERSION_STR_LONG, "schmurgel1983");
	
	if (status) state enabled;
	else state deactivated;
}

public plugin_precache() <deactivated> {}
public plugin_precache() <enabled>
{
	Entities = TrieCreate();
	
	if (!DM_LoadConfiguration("dm_entities_remover.cfg", "DM_ReadRemover"))
	{
		TrieDestroy(Entities);
		
		state deactivated;
		return;
	}
	
	g_iFwdSpawn = register_forward(FM_Spawn, "fwd_Spawn", false);
}

public DM_ReadRemover(section[], key[], value[])
{
	if (equali(section, "entities"))
	{
		TrieSetCell(Entities, key, true);
	}
}

public plugin_init() <deactivated> {}
public plugin_init() <enabled>
{
	unregister_forward(FM_Spawn, g_iFwdSpawn);
	
	TrieDestroy(Entities);
}

/* -Forwards------------------------------------------------------------------ */

public fwd_Spawn(entity)
{
	if (!pev_valid(entity))
		return FMRES_IGNORED;
	
	new classname[33];
	pev(entity, pev_classname, classname, charsmax(classname));
	
	if (TrieKeyExists(Entities, classname))
	{
		engfunc(EngFunc_RemoveEntity, entity);
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}
