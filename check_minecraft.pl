#!/usr/bin/perl
##
#   File:: check_minecraft.pl
#   Date:: 28/01/2022
#   Author:: spjspj
#   Purpose:: Look for and kill a process..
##

use strict;
use POSIX qw(strftime);
use Time::HiRes qw( usleep );
use Term::ReadKey;
my $TASK_OF_INTEREST = "TASKTOKILL";
my $NUM_TIMES_OK = 6;
my $SLEEP_FOR = 5000000;

# Main
my $time = 3600*24 - 5;
my $original_time = time;
my $original_time = time;

sub after_ten_pm
{
    my $time = $_ [0];
    my $description = $_ [1];
    my $in_24h_time = $_ [2];

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time);
    my $am_pm = "AM";

    if ($in_24h_time)
    {
        $am_pm = "";
    }
    else
    {
        if ($hour >= 13)
        {
            $am_pm = "PM";
        }
    }

    my $date = sprintf ("%04d%02d%02d %02d:%02d:%02d", $year+1900,$mon+1,$mday, $hour,$min,$sec);
    print ("\n\n\n$description\n$date $am_pm\n");

    if ($hour > 21 || $hour < 7)
    {
        return 1;
    }
    return 0;
}

my $SECONDS_PER_MINUTE = 60;
my $MINUTES_PER_HOUR = 60;
my $HOURS_PER_DAY = 24;
my $DAYS_PER_WEEK = 7;
my $SECONDS_PER_HOUR = $SECONDS_PER_MINUTE * $MINUTES_PER_HOUR;
my $SECONDS_PER_DAY =  $SECONDS_PER_HOUR * $HOURS_PER_DAY;
my $SECONDS_PER_WEEK = $SECONDS_PER_DAY * $DAYS_PER_WEEK;

sub check_time
{
    my $num_seconds = $_ [0];
    my $num_hours;
    my $num_mins;
    my $num_secs;


    $num_hours = $num_seconds / 3600;
    $num_hours =~ s/\.\d+//;
    $num_mins = ($num_seconds - $num_hours * 3600) / 60;
    $num_secs = $num_seconds % 60;

    my $time = sprintf ("%02d:%02d:%02d", $num_hours, $num_mins, $num_secs);
    print ("The timer is:\n");
    print ($time, "\n");
    #my $now_string = strftime "%a %b %e %H:%M:%S %Y", localtime;

    if (after_ten_pm (time, "Current time:", 0))
    {
        print ("After ten pm!\n");
        return 1;
    }
    return 0;
}

my $old_day = "";
sub new_day
{
    my $time = $_ [0];
    my $description = $_ [1];
    my $in_24h_time = $_ [2];

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time);
    my $am_pm = "AM";

    my $new_day = sprintf ("%04d%02d%02d", $year+1900,$mon+1,$mday);

    if ($old_day eq "")
    {
        $old_day = $new_day;
        return 0;
    }

    if ($old_day ne $new_day)
    {
        $old_day = $new_day;
        return 1;
    }
    return 0;
}

my %tasks_seen;
sub kill_process
{
    my $key = $_ [0];
    print ("Have to kill $key\n");
    print ("taskkill /F /IM \"$key\"\n");
    my $out = `taskkill /F /IM "$key"`;
    print ("Output of running it is: $out\n");
    $tasks_seen{$key} = 0;
}

# MAIN
while (1)
{
    system("cls");
    $time = time - $original_time;
    if ($time >= 24*3600)
    {
        $time = 0;
    }
    my $tasks = `tasklist`;
    $tasks =~ s/    /,/gim;
    $tasks =~ s/,.*//gim;
    
    my %uniq_tasks;

    if (new_day ())
    {
        my %new_tasks_seen;
        %tasks_seen = %new_tasks_seen;
    }

    while ($tasks =~ s/^(.*$)\n//m)
    {
        my $task = $1;
        if (!defined ($uniq_tasks {$task}))
        {
            $uniq_tasks {$task} = 1;
            $tasks_seen {$task} = 1 + $tasks_seen {$task};
            if ($task =~ m/.*$TASK_OF_INTEREST.*/img)
            {
                print $task, "\n";
            }
        }
    }

    my $key;
    foreach $key (sort keys (%tasks_seen))
    {
        if ($key =~ m/.*$TASK_OF_INTEREST.*/img)
        {
            print ("\n$key --> $tasks_seen{$key}\n");
            if ($tasks_seen{$key} > $NUM_TIMES_OK)
            {
                kill_process ($key);
            }
            elsif ($tasks_seen{$key} > 1)
            {
                if (check_time ())
                {
                    kill_process ($key);
                    $tasks_seen{$key} = 0;
                }
                else
                {
                    print ("Don't have to kill $key\n");
                }
            }
        }
    }
    print "\nDONE!\n";

    usleep ($SLEEP_FOR);
}

#    if (defined ($char = ReadKey(-1)))
#    {
#        $char = lc ($char);
#        if ($char eq "q")
#        {
#            print ("Will now quit\n");
#            exit;
#        }
#        elsif ($char eq "s" && $stopped == 0)
#        {
#            print ("Will now stop the timer!\n");
#            $stopped = 1;
#        }
#        elsif ($char eq "s" && $stopped == 1)
#        {
#            print ("Will now start the timer!\n");
#            $original_time = time;
#            $stopped = 0;
#        }
#    }
