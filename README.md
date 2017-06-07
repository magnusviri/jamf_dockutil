# Jamf Scripts

## jamf_dockutil

Use this with JAMF.

Parameter 4: Username (leave blank to use param 3)

Parameter 5: Opts: erase

Parameter 6-11: username regex:params:<path|name.app>

Format is:
	'username regex' => [
		'options:AppName.app',
	]

When a user logs in, the name is matched to the username regex.  If it matches, it uses
that dock.

The options are passed straight to dockutil.
