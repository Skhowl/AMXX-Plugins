
#if defined _dm_spawn_included
  #endinput
#endif
#define _dm_spawn_included

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib dm_spawn
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib dm_spawn
	#endif
#else
	#pragma library dm_spawn
#endif


/*
* Register spawn mode.
* Note: Can only used in plugin_init.
*
* @param modename		Spawn mode name.
* @param callback		The forward to call.
* @return				0 on failure, 1 on success.
*/
native DM_RegisterSpawnMode(const modename[], const callback[]);
/* Sample:
	DM_RegisterSpawnMode("team_close", "DM_Spawn_TeamClose")
	
	public DM_Spawn_TeamClose(id, freezetime, roundend)
	{
		// code
	}
*/


/**
 * Called when a player spawns.
 * Ham Pre/Post with bot support.
 *
 * @param id			Player index.
 * @param freezetime	Spawn in freezetime.
 * @param roundend		Spawn in round end.
 */
forward DM_PlayerSpawn_Pre(id, freezetime, roundend);
forward DM_PlayerSpawn_Post(id, freezetime, roundend);

/**
 * Called when a player is killed.
 * Ham Pre/Post with bot support.
 *
 * @param victim		Victim index.
 * @param attacker		Attacker index.
 */
forward DM_PlayerKilled_Pre(victim, attacker);
forward DM_PlayerKilled_Post(victim, attacker);

/**
 * Called when a player is getting to respawning.
 * You can block it by returning PLUGIN_HANDLED.
 *
 * @param id			Player index.
 */
forward DM_RespawnAttempt(id);

/**
 * Called when a player is getting spawn protection.
 * You can block it by returning PLUGIN_HANDLED.
 *
 * @param id			Player index.
 * @param freezetime	Protection in freezetime.
 * @param roundend		Protection in round end.
 */
forward DM_SpawnProtection(id, freezetime, roundend);

/**
 * Called when a player's spawn protection ends.
 *
 * @param id			Player index.
 */
forward DM_SpawnProtectionEnds(id);
