
#if defined _dm_log_included
  #endinput
#endif
#define _dm_log_included

enum
{
	LOG_ERROR = 0,
	LOG_INFO,
	LOG_ADMIN
}

/**
 * This is used to log DM-specific errors into a
 * location where it is separate from other messages.
 **/
stock DM_Log(type, message_fmt[], any:...)
{
	static message[256], filename[32], date[16];
	vformat(message, charsmax(message), message_fmt, 3);
	format_time(date, charsmax(date), "%Y%m%d");
	switch(type)
	{
		case LOG_INFO: formatex(filename, charsmax(filename), "DM_INFO_%s.log", date);
		case LOG_ADMIN: formatex(filename, charsmax(filename), "DM_ADMIN_%s.log", date);
		default: formatex(filename, charsmax(filename), "DM_ERROR_%s.log", date);
	}
	log_to_file(filename, "%s", message);
}

/**
 * This is used to log DM-specific plugin information
 * into a location where it is separate from other messages.
 * Optional with plugin trace, line or number.
 **/
stock DM_LogPlugin(type, plugin_id, on_error[], trace = -1)
{
	static plugin[32], message[256], filename[32], date[16];
	get_plugin(plugin_id, plugin, charsmax(plugin));
	format(message, charsmax(message), "%s -> %s (%d)", plugin, on_error, (trace >= 0) ? trace : -1);
	format_time(date, charsmax(date), "%Y%m%d");
	switch(type)
	{
		case LOG_INFO: formatex(filename, charsmax(filename), "DM_INFO_%s.log", date);
		case LOG_ADMIN: formatex(filename, charsmax(filename), "DM_ADMIN_%s.log", date);
		default: formatex(filename, charsmax(filename), "DM_ERROR_%s.log", date);
	}
	log_to_file(filename, "[PLUGIN] %s", message);
}
