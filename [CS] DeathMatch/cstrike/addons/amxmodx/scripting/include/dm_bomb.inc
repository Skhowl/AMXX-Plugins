
#if defined _dm_bomb_included
  #endinput
#endif
#define _dm_bomb_included

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib dm_bomb
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib dm_bomb
	#endif
#else
	#pragma library dm_bomb
#endif


/*
* Get CT bomb defuse time.
*
* @return				0 on failure.
*/
native DM_GetDefuseTime();

