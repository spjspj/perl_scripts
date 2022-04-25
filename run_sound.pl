#!/usr/bin/perl
##
#   File : test_sounds.pl
#   Date : 23/10/2012
#   Author : spjspj
#   Purpose : Allow the recorder to just keep recording!
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
    print ("Running with: arecord -t wav --max-file-time 15 /home_monitor/Spool/AA.wav &\n");
    `arecord -t wav --max-file-time 15 /home_monitor/Spool/AA.wav &`;
}
