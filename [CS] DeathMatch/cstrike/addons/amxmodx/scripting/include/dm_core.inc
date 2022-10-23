
#if defined _dm_core_included
  #endinput
#endif
#define _dm_core_included

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib dm_core
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib dm_core
	#endif
#else
	#pragma library dm_core
#endif

#include <dm_const>


/* DM Teams */
#define DM_TEAM_UNASSIGNED	0
#define DM_TEAM_T			1
#define DM_TEAM_CT			2
#define DM_TEAM_SPECTATOR	3
#define DM_TEAM_ANY			4


/*
* Load custom cofiguration.
* Note: Can only used in plugin_precache or plugin_init.
*
* @param filename		Configuration filename.
* @param callback		The forward to call.
* @return				0 on failure, 1 on success.
*/
native DM_LoadConfiguration(const filename[], const callback[]);
/* Sample:
	DM_LoadConfiguration("spawn.cfg", "spawn_cfg_reading")
	
	public spawn_cfg_reading(section[], key[], value[])
	{
		// code
	}
*/


/*
* Called when dm_core send the mod status.
*
* @param status			DM mod status, 0 is disabled, 1 is enabled.
*/
forward DM_OnModStatus(status);

/*
* Called when dm_core send the map conditions.
*
* @param bomb			Map with bomb (de_).
* @param vip			Map with vip (as_).
* @param hosnum			Map with hostages, return num (cs_).
* @param hosid			Array that stores all hostage id's.
*/
forward DM_OnMapConditions(bomb, vip, hosnum, hosid[]);

/*
* Called when a CZ Bot is ready to register for hamsandwich.
*
* @param id				CZ Bot index.
*/
forward DM_OnCzBotHamRegisterable(id);

