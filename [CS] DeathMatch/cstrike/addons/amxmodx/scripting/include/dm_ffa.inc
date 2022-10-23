
#if defined _dm_ffa_included
  #endinput
#endif
#define _dm_ffa_included

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib dm_ffa
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib dm_ffa
	#endif
#else
	#pragma library dm_ffa
#endif


/*
* Check if "Free for All" is enabled.
*
* @return				0 on disable, 1 on enable.
*/
native DM_IsFreeForAllEnabled();

