#!/usr/bin/perl -w

use strict;

my $user_docks = {
	'^james$|^spencer$' => [
		':Safari.app',
		':System Preferences.app',
		':App Store.app',
		':BBEdit.app',
		':Activity Monitor.app',
		':Console.app',
		':Disk Utility.app',
		':Keychain Access.app',
		':Terminal.app',
		':Directory Utility.app',
		':Network Utility.app',
		':Network.prefPane',
		':StartupDisk.prefPane',
	],
	'^scholar$|^u\d{7}$' => [
		':Safari.app',
		':Firefox.app',
		':Google Chrome.app',
		':Adobe Photoshop CC 2017/Adobe Photoshop CC 2017.app',
		':Microsoft Excel.app',
		':Microsoft PowerPoint.app',
		':Microsoft Word.app',
		':AcqKnowledge.app',
		':ImageJ.app',
		':MATLAB_42012b.app',
		':~/Downloads/',
		':/App List/',
	],
};

my @default_remove = (
	"Launchpad",
	"Safari",
	"Mail",
	"Contacts",
	"Calendar",
	"Notes",
	"Reminders",
	"Maps",
	"Photos",
	"Messages",
	"FaceTime",
	"Pages",
	"Numbers",
	"Keynote",
	"iTunes",
	"iBooks",
	"App Store",
	"System Preferences",
	"Downloads",
);

my $dockutil = "/usr/local/bin/dockutil";

##########################################################################################
# Get the username from Parameter 4, if missing then Parameter 3, if missing then /dev/console
my $user = $ARGV[3];
if ( ! defined $user or $user eq '' ) {
	$user = $ARGV[2];
	if ( ! defined $user or $user eq '' ) {
		$user = `/usr/bin/stat /dev/console | awk '{print \$5}'`;
		chomp $user;
	}
}

my $pref_path = "/Users/$user/Library/Preferences/com.apple.dock.plist";
chdir( "/Users/$user" );

##########################################################################################
# Erase first?
my $options = $ARGV[4];
print "Options: $options\n";
if ( $options =~ /erase/ ) {
    system "/usr/bin/defaults write $pref_path persistent-apps -array";
    system "/usr/bin/defaults write $pref_path persistent-others -array";
    my @remove_me = `/usr/local/bin/dockutil --list $pref_path`;
    print `/usr/local/bin/plprint $pref_path`;
    for my $remove ( @remove_me ) {
        my @parts = split( '\t', $remove );
        print "$dockutil --no-restart --remove \"$parts[0]\" \"$pref_path\"\n";
        system "$dockutil --no-restart --remove \"$parts[0]\" \"$pref_path\"";
    }
}

##########################################################################################
# Get dock arguments
splice(@ARGV,0,5);
my @dock;

# Parse the data at the top of this file

for my $user_regex ( keys %$user_docks ) {
	if ( $user =~ /$user_regex/ ) {
		for my $item ( @{$user_docks->{$user_regex}} ) {
			my @parts = split( ':', $item );
			push @dock, [ $parts[0], $parts[1] ];
		}
	}	
}

# Parse the data in args and combine with the data at the top of this file

for my $arg ( @ARGV ) {
	print "'$arg'\n";
	my @args = split( ',', $arg );
	for my $item ( @args ) {
		my @parts = split( ':', $arg );
		if ( $user =~ /$parts[0]/ ) {
			push @dock, [ $parts[1], $parts[2] ];
		}	
	}	
}

# Add items to Dock
for my $path ( @dock ) {
    find_item( $path );
}
print `/usr/sbin/chown $user:staff \"$pref_path\"`;

sub find_item {
	my ( $args, $restart ) = @_;
	$restart ||= 0;
	my $extraparams = $$args[0];
	my $path = $$args[1];
	if ( $path !~ /^[\/~]/ ) {
		my @search_paths = (
		    '/Applications/',
		    '/Applications/Utilities/',
		    '/System/Library/CoreServices/',
		    '/System/Library/CoreServices/Applications/',
		    '/System/Library/PreferencePanes/',
		);
		for my $search ( @search_paths ) {
			if ( -e $search.$path ) {
				add_item( $search.$path, $extraparams, $restart );
				last;
			}
		}
	} else {
		add_item( $path, $extraparams, $restart );
	}
}

sub add_item {
	my ( $path, $extraparams, $restart ) = @_;
	my $restart_text = ( $restart ) ? '':'--no-restart ';
    my $display_folder = '';
    if ( $path =~ /\.prefPane$/ ) {
        $display_folder = '--type file ';
    } elsif ( $path =~ /\/$/ ) {
        $display_folder = ' --view automatic --type file ';
    }
	print "$dockutil $restart_text$display_folder$extraparams --add \"$path\" \"$pref_path\"\n";
	system "$dockutil $restart_text$display_folder$extraparams --add \"$path\" \"$pref_path\"";
}
