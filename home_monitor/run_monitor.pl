#!/usr/bin/perl
##
#   File : run_sound.pl
#   Author : spjspj
##

use strict;
my $file_name;
my $search1;
my $search2;
my $search3;
my $search4;

# Main
{
    `killall arecord`;
    print ("Recording sound\n");
    # Scheduled task to run
    print ("Running with: arecord -t wav --max-file-time 20 /home_monitor/Spool/AA.wav &\n");
    `arecord -t wav --max-file-time 20 /home_monitor/Spool/AA.wav &`;
}
