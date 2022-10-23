
#if defined _dm_rewards_included
  #endinput
#endif
#define _dm_rewards_included

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib dm_rewards
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib dm_rewards
	#endif
#else
	#pragma library dm_rewards
#endif


/*
* Get start money.
*
* @return				0 and higher on success, or -1 on failure.
*/
native DM_GetStartMoney();

/*
* Get user money.
*
* @param id				Player id.
* @return				0 and higher on success, or -1 on failure.
*/
native DM_GetUserMoney(const id);

/*
* Set user money.
*
* @param id				Player id.
* @param amount			New money amount.
* @param flash			Flash money.
* @return				1 on success, or 0 on failure.
*/
native DM_SetUserMoney(const id, const amount, const flash);

