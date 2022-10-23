
#if defined _dm_scenarios_included
  #endinput
#endif
#define _dm_scenarios_included

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib dm_scenarios
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib dm_scenarios
	#endif
#else
	#pragma library dm_scenarios
#endif


/*
* User carrier the bomb?
*
* @param id			User Index.
* @return			0 on false, 1 on true.
*/
native DM_UserIsCarrierBomb(const id);

/*
* User planting the bomb?
*
* @param id			User Index.
* @return			0 on false, 1 on true.
*/
native DM_UserIsPlanting(const id);

/*
* User defusing the bomb?
*
* @param id			User Index.
* @return			0 on false, 1 on true.
*/
native DM_UserIsDefusing(const id);


/**
 * On regular map ending when intermission called.
 */
forward DM_OnIntermission();


/**
 * Called when a team win without any bomb,
 * hostage or vip flags.
 */
forward DM_CTsWin();
forward DM_TerroristsWin();
forward DM_RoundDraw();


/**
 * Called when a player spawned with the bomb.
 *
 * @param id			Player index.
 */
forward DM_BombSpawned(id);

/**
 * Called when a player pickup the bomb.
 *
 * @param id			Player index.
 * @param freezetime	Pickup in freezetime.
 * @param roundend		Pickup in round end.
 */
forward DM_BombPickup(id, freezetime, roundend);

/**
 * Called when a player dropped the bomb.
 *
 * @param id			Player index.
 * @param freezetime	Dropped in freezetime.
 * @param roundend		Dropped in round end.
 */
forward DM_BombDropped(id, freezetime, roundend);

/**
 * Called when a player planted the bomb.
 *
 * @param id			Player index.
 * @param roundend		Planted in round end.
 */
forward DM_BombPlanted(id, roundend);

/**
 * Called when a player defused the bomb.
 *
 * @param id			Player index.
 */
forward DM_BombDefused(id);

/**
 * Called when the target is bombed.
 *
 * @param planter		Planter index.
 * @param defuser		Defuser index.
 */
forward DM_TargetBombed(planter, defuser);

/**
 * Called when the target is saved.
 */
forward DM_TargetSaved();


/**
 * Called when a player became vip.
 *
 * @param id			Player index.
 */
forward DM_BecameVip(id);

/**
 * Called when vip is killed by enemy,
 * teammate or himself (killer = vip).
 * Killed by World or trigger_hurt return 0.
 *
 * @param killer		Killer index.
 * @param vip			VIP index.
 */
forward DM_VipAssassinated(killer, vip);

/**
 * Called when a player escaped as vip.
 *
 * @param id			Player index.
 * @param freezetime	Escaped in freezetime.
 * @param roundend		Escaped in round end.
 */
forward DM_VipEscaped(id, freezetime, roundend);

/**
 * Called when a player not escaped as vip.
 *
 * @param id			Player index.
 */
forward DM_VipNotEscaped(id);


/**
 * Called when a player touched a hostage.
 *
 * @param id			Player index.
 * @param freezetime	Touched in freezetime.
 * @param roundend		Touched in round end.
 */
forward DM_HostageTouched(id, freezetime, roundend);

/**
 * Called when a player rescued a hostage.
 *
 * @param id			Player index.
 * @param freezetime	Rescued in freezetime.
 * @param roundend		Rescued in round end.
 */
forward DM_HostageRescued(id, freezetime, roundend);

/**
 * Called when a player killed a hostage.
 *
 * @param id			Player index.
 * @param roundend		Killed in round end.
 */
forward DM_HostageKilled(id, roundend);

/**
 * Called when CTs rescued all hostages.
 *
 * @param freezetime	All rescued in freezetime.
 * @param roundend		All rescued in round end.
 */
forward DM_HostagesAllRescued(freezetime, roundend);

/**
 * Called when CTs not rescued all hostages (none or few).
 */
forward DM_HostagesNotRescued();

