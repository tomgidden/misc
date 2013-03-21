#!/usr/bin/perl -w
# Copyright (C) 2007, Tom Gidden, <tom@gidden.net>
#
# Ref: http://gidden.net/tom/2006/08/04/x11-color-list-for-macosx/

use strict;
use Foundation;

# The file to read colours from:
my $input_fn = '/usr/X11R6/lib/X11/rgb.txt';

# The names of the colour lists to generate.
# If undef, they won't be created.
my $all_name = 'X11 Colors (all)';
my $unique_name = 'X11 Colors (uniques)';


# AppKit objects are not *directly* supported by PerlObjCBridge, but we
# can bridge the classes manually, which all works very nicely.

# Classes to bridge
my @classes = qw(NSColor NSColorList);

# Load AppKit
my $path = '/System/Library/Frameworks/AppKit.framework';
my $appkit = NSBundle->alloc->init->initWithPath_($path);
die "Couldn't init AppKit: $!" unless ($appkit);
die "Couldn't load AppKit: $!" unless ($appkit->load and $appkit->isLoaded);

# Create a perl class for each ObjC object, just by setting the class's
# parent to PerlObjCBridge.
for my $class (@classes) {
    no strict 'refs';
    @{$class.'::ISA'} = 'PerlObjCBridge';
}

# Open the input file.
die "Couldn't open $input_fn: $!" unless open(INPUT, $input_fn);

# Create colour lists.
my $cl1 = NSColorList->alloc()->initWithName_($all_name) if($all_name);
my $cl2 = NSColorList->alloc()->initWithName_($unique_name) if($unique_name);

# %loaded stores a flag for an RGB tuple if it's been loaded.  This
# %prevents duplicates being imported into $cl2
my %loaded;

# For each color:
while (<INPUT>) {

    # This regexp matches that of the rgb.txt file with X11, ie. one
    # colour per line, with three whitespace-separated integers from
    # 0-255, followed by more whitespace and then the name of the colour.
    # As the file may (and probably will) have comments, this skips any
    # non-matching lines.
    next unless(m/^\s*(\d+)\s+(\d+)\s+(\d+)\s+(.+)$/);

    # Create the colour object.  Not worrying too much about calibration or
    # colorspaces.  Device space takes R/G/B floats from 0.0 to 1.0, and
    # 1.0 for alpha (opacity). However, Mark H says this works:

    # http://gidden.net/tom/2006/08/04/x11-color-list-for-macosx/comment-page-1/#comment-37223
    my $c = NSColor->colorWithCalibratedRed_green_blue_alpha_(
#   my $c = NSColor->colorWithDeviceRed_green_blue_alpha_(
        $1/255,
        $2/255,
        $3/255,
        1.0);

    # Add that colour to the complete list.
    $cl1->setColor_forKey_($c, "$4") if($cl1);

    # Add it to the uniques list if the colour hasn't been added yet.
    $cl2->setColor_forKey_($c, "$4") unless(!$cl2 or $loaded{"$1,$2,$3"});

    # Register this colour as "loaded".
    $loaded{"$1,$2,$3"} = 1;
}

# And save the lists.  If 'undef' is given as the filename, a list is
# automatically saved using the NSColorList's name, and put in
# ~/Library/Colors.  Convenient.
$cl1->writeToFile_(undef) if($cl1);
$cl2->writeToFile_(undef) if($cl2);

# EOF
