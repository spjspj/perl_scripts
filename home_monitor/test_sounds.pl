#!/usr/bin/perl
##
#   File : test_sound.pl
#   Author : spjspj
##

use strict;
my $file_name;
my $search1;
my $search2;
my $search3;
my $search4;

# Quiescent RMS - amplitude
my $q_max_amplitude = 0.04;

my $rms_amplitude_seen_min = 1.0;
my $sound_file_num = 0;
my $zip_file_num = 0;

sub rename_new_sound
{
    my $existing_file = $_ [0];
    my $d = `date '+%Y%m%d%H%M%S'`;
    chomp $d;

    my $sub = "rns_" . $d;
    $sub =~ s/\W/_/g;
    $sub =~ s/__/_/g;
    $sub =~ s/__/_/g;
    $sub =~ s/__/_/g;
    $sub .= "_$sound_file_num.wav";
    $sound_file_num++;
    print ("Rename: mv $existing_file /home_monitor/Spool/$sub\n");
    `mv "$existing_file" "/home_monitor/Spool/$sub"`;
    print ("DONE Rename: mv $existing_file /home_monitor/Spool/$sub\n");
    return "/home_monitor/Spool/$sub";
}

sub zip_sounds
{
    my $d = `date '+%Y%m%d%H%M%S'`;
    chomp $d;
    my $c = `ls -1 /home_monitor/Archive/*wav | wc -l`;
    chomp $c;

    if ($c < 50)
    {
        print ("Am seeing not enough $c .wav files!\n");
        return;
    }

    print ("Am seeing enough $c .wav files!\n");

    my $sub = "linux_sounds_" . $d;
    $sub =~ s/\W/_/g;
    $sub =~ s/__/_/g;
    $sub =~ s/__/_/g;
    $sub =~ s/__/_/g;
    $sub .= ".zip";
    print ("Rename: Making zip file of $sub\n");
    `zip /home_monitor/Archive/REALLY_LOUD_$sub /home_monitor/Archive/*REALLY_LOUD.wav`;
    `rm -f /home_monitor/Archive/*REALLY_LOUD.wav`;
    `zip /home_monitor/Archive/LOUD_$sub /home_monitor/Archive/*LOUD.wav`;
    `rm -f /home_monitor/Archive/*LOUD.wav`;
    `zip /home_monitor/Archive/LOUD_MOD_$sub /home_monitor/Archive/*LOUD_MOD.wav`;
    `rm -f /home_monitor/Archive/*LOUD_MOD.wav`;
    `zip /home_monitor/Archive/$sub /home_monitor/Archive/*.wav`;
    `rm -f /home_monitor/Archive/*.wav`;
}

my $num_times = 0;
sub test_sound
{
    my $sub = $_ [0];

    ##### Distorts it too much..
    ## Clean (?) the signal..
    ## sox UNFILTERED.wav FILTERED.wav noisered noise.prof 0.21
    #my $sub1 = $sub;
    #$sub1 =~ s/rns/filt_rns/;
    #print ("Doing : sox $sub $sub1 noisered /home_monitor/Spool/noise.prof 0.21\n");
    #`sox $sub $sub1 noisered /home_monitor/Spool/noise.prof 0.21`;
    #
    ## sox FILTERED.wav SHORT_FILTERED.wav silence -l 1 0.3 1% -1 1.0 1%
    #my $sub2 = $sub1;
    #$sub2 =~ s/filt/short_filt/;
    #print ("Doing : sox $sub1 $sub2 silence -l 1 0.3 1% -1 1.0 1%\n");
    #`sox $sub1 $sub2 silence -l 1 0.3 1% -1 1.0 1%`;
    #`rm $sub1`;
    #`rm $sub`;
    #$sub = $sub2;

    my $test_str = "sox $sub -n stat 2>&1 |";

    my $max_amplitude = -500;

    open PROC, $test_str;
    while (<PROC>)
    {
        chomp;
        if ($_ =~ m/RMS.*amplitude.*?(\d+\.\d+)/i)
        {
            $max_amplitude = $1;
        }

    }
    close PROC;

    $num_times++;
    if ($num_times > 100)
    {
        $num_times = 0;
    }

    my $arch_dir = "/home_monitor/Archive/";

    if ($max_amplitude >= $q_max_amplitude)
    {
        my $new_sub = $sub;
        my $new_sub2 = $new_sub;
        $new_sub =~ s/.*\///;
        $new_sub2 =~ s/.*\///;
        $new_sub = "/home_monitor/Spool/$new_sub.rmsa.$max_amplitude";
        my $arch_file = "$arch_dir$new_sub2";

        $arch_file = "$arch_file.RMSA.$max_amplitude";


        if ($max_amplitude >= 0.10)
        {
            print ("mv $sub $new_sub.REALLY_LOUD.wav\n");
            `cp $sub $arch_file.REALLY_LOUD.wav`;
            `mv $sub $new_sub.REALLY_LOUD.wav`;
            return 1;
        }
        elsif ($max_amplitude >= 0.07)
        {
            print ("mv $sub $new_sub.LOUD.wav\n");
            `cp $sub $arch_file.LOUD.wav`;
            `mv $sub $new_sub.LOUD.wav`;
            return 1;
        }
        elsif ($max_amplitude >= 0.02)
        {
            print ("mv $sub $new_sub.LOUD_MOD.wav\n");
            `cp $sub $arch_file.LOUD_MOD.wav`;
            `mv $sub $new_sub.LOUD_MOD.wav`;
            return 1;
        }
        else
        {
            print ("mv $sub $new_sub.wav\n");
            `cp $sub $arch_file.wav`;
            `rm $sub`;
            return 1;
        }
    }
    else
    {
        print ("NoKeep:$sub (Rms_amp=$max_amplitude v $q_max_amplitude)\n");
        `rm $sub`;
        return 0;
    }
}

# Main
{
    my $file;
    print ("Running $0 right now!\n");

    while (1)
    {
        {
            # Do sound testing for /home_monitor/pool/.wav
            my @record_now_file;
            opendir (DIR, "/home_monitor/Spool/");
            @record_now_file = grep { /AA.*wav/ } readdir (DIR);
            closedir DIR;

            $file = "";
            foreach $file (@record_now_file)
            {
                print ("\n\n--------------------->> Looking at $file now\n");
                my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size, $atime,$mtime,$ctime,$blksize,$blocks) = stat ("/home_monitor/Spool/$file");

                if (time - $mtime > 5)
                {
                    print  ($mtime, " -- $file\n");
                    # Keep and/or delete!
                    $file = "/home_monitor/Spool/$file";
                    $file = rename_new_sound ($file);
                    test_sound ($file);
                }
            }
            sleep (1);
        }

        zip_sounds ();
        sleep (15);
    }
}
