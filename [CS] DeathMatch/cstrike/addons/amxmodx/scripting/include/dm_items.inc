
#if defined _dm_items_included
  #endinput
#endif
#define _dm_items_included

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib dm_items
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib dm_items
	#endif
#else
	#pragma library dm_items
#endif


/*
* Register item.
* Note: Can only used in plugin_precache & plugin_init.
*
* @param itemname		Item name.
* @param team			Which team can use it. (DM_TEAM_ANY = for both)
* @param cost			Item cost.
* @param holdtime		Holdtime in seconds. (180 = 3 minutes)
* @param c_activate		The forward to call for activate this item.
* @param c_deactivate	The forward to call for deactivate this item.
* @return				Unique item id, or -1 on failure.
*/
native DM_RegisterItem(const itemname[], const chatcmd[], const team, const cost, const holdtime, const c_activate[], const c_deactivate[]);

/*
* Get item unique id.
*
* @param item			Real item name.
* @return				Unique item id, or -1 on failure.
*/
native DM_GetItemUniqueId(const item[]);

/*
* Get item display name.
*
* @param itemid			Unique item id.
* @param name			Store display name.
* @param len			Maximum length.
* @return				1 on success, or 0 on failure.
*/
native DM_GetItemDisplayName(const itemid, name[], const len);

/*
* Force a player to buy a item.
*
* @param id				Player id.
* @param itemid			Unique item id.
* @return				1 on success, or 0 on failure.
*/
native DM_ForceBuyItem(const id, const itemid);

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

