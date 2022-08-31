#!/usr/bin/perl
##
#   File : del_zips.pl
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
    my $file;
    print ("Running $0 right now!\n");

    # Do sound testing for /home_monitor/pool/.wav
    my @record_now_file;
    opendir (DIR, "/home_monitor/Archive/");
    @record_now_file = grep { /.*zip/ } readdir (DIR);
    closedir DIR;

    $file = "";
    foreach $file (@record_now_file)
    {
        my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size, $atime,$mtime,$ctime,$blksize,$blocks) = stat ("/home_monitor/Archive/$file");

        my $delete_it = 0;
        if ($file =~ m/REALLY_LOUD/)
        {
            if (time - $mtime > 30 * 3600 * 24)
            {
                $delete_it = 4;
            }
        }
        elsif ($file =~ m/LOUD_MOD/)
        {
            if (time - $mtime > 4 * 3600 * 24)
            {
                $delete_it = 3;
            }
        }
        elsif ($file =~ m/LOUD/)
        {
            if (time - $mtime > 7 * 3600 * 24)
            {
                $delete_it = 2;
            }
        }
        else
        {
            if (time - $mtime > 1 * 3600 * 24)
            {
                $delete_it = 5;
            }
        }

        if ($delete_it)
        {
            print ("$delete_it rm $file ---- " .  (time - $mtime) . "\n");
            print ("rm /home_monitor/Archive/$file\n");
            `rm /home_monitor/Archive/$file`;
        }
    }
}
