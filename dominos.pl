#!/usr/bin/perl
##
#   File : dominoes.pl
#   Date : 29/march/2020
#   Author : spjspj
#   Purpose : To write a simulator for dominoes
##

use strict;
use LWP::Simple;
use POSIX qw(strftime);

my %domino_layout;
my $max_row = 0;
my $max_col = 0;
my $first_step = 1;
my $INVALID_ANGLE = -999;
my $current_count;

sub cleanup_falling 
{
    my $count_of_standing = $_ [0];
    my $row = 0;
    my $col = 0;
    
    for ($row = 0; $row < $max_row; $row++)
    {
        for ($col = 0; $col < $max_col; $col++)
        {
            my $domino = get_domino ($row, $col);
            
            if ($domino->{empty} == 0)
            {
                if ($domino->{falling} == 1)
                {
                    $domino->{standing} = 0;
                    $domino->{falling} = 0;
                    $domino->{fallen} = 1;
                    print ("Cleaning up..:\n");
                    print_dom ($domino);
                    print ("Done cleaning up..:\n");
                }
            }
        }
    }
}

sub ok_to_hit
{
    my $domino = $_ [0];
    my $touched_domino = $_ [1];
    my $ok = 1;

    if ($touched_domino->{fallen} == 1)
    {
        $ok = 0;
    }
    if ($touched_domino->{empty} == 1)
    {
        $ok = 0;
    }
    if ($touched_domino->{current_count} =~ m/./ && ($touched_domino->{current_count} < $domino->{current_count} || $domino->{current_count} < $touched_domino->{current_count})) 
    {
        print ("Comparing $ok : (touched vs domino)=($touched_domino->{id} vs $domino->{id})\n");  
        print_dom ($touched_domino);
        print_dom ($domino);
        $ok = 0;
    }
    print ("Final Comparing $ok : (touched vs domino)=($touched_domino->{id} vs $domino->{id})\n");  
    print_dom ($touched_domino);
    print_dom ($domino);
    return $ok;
}

sub next_step_in_simulation
{
    my $row = 0;
    my $col = 0;
    my $past_current_count = $current_count;

    for ($row = 0; $row < $max_row; $row++)
    {
        for ($col = 0; $col < $max_col; $col++)
        {
            my $domino = get_domino ($row, $col);
            $current_count = count_standing_dominoes ();
            if ($past_current_count != $current_count)
            {
                print (" Cleaning up 'cos $past_current_count > $current_count+5\n");
                #cleanup_falling ($past_current_count);
                $past_current_count = $current_count;
            }

            if ($domino->{empty} == 0)
            {
                print_dom ($domino);
            }

            if ($first_step)
            {
                if ($domino->{first})
                {
                    $domino->{standing} = 0;
                    $domino->{falling} = 0;
                    $domino->{falling_direction} = 270;
                    $domino->{fallen} = 1;
                    my $touched_domino = get_domino ($row + 1, $col);
                    if ($touched_domino->{empty} == 0)
                    {
                        $touched_domino->{standing} = 0;
                        $touched_domino->{falling} = 1;
                        $touched_domino->{current_count} = $current_count;
                        $touched_domino->{fallen} = 0;
                        set_falling_direction ($touched_domino, $domino, 0);
                    }
                }
            }
            else
            {
                if ($domino->{falling} == 1)
                {
                    print ("\n====================\nFalling!!\n");
                    print_dom ($domino);
                    print ("\n2nd Falling!!\n================\n");

                    if ($domino->{second_angle} == $INVALID_ANGLE)
                    {
                        if ($domino->{falling_direction} == 0)
                        {
                            my $touched_domino = get_domino ($row, $col + 1, 0);
                            if (ok_to_hit ($domino, $touched_domino))
                            {
                                print ("1stangle Hitting!!\n");
                                print_dom ($touched_domino);
                                print ("2nd 1stangle Hitting!!\n");
                                $touched_domino->{standing} = 0;
                                $touched_domino->{falling} = 1;
                                $touched_domino->{current_count} = $current_count;
                                $touched_domino->{fallen} = 0;
                                set_falling_direction ($touched_domino, $domino, 0);
                            }
                        }
                        elsif ($domino->{falling_direction} == 45)
                        {
                            my $touched_domino = get_domino ($row - 1, $col + 1, 45);
                            if (ok_to_hit ($domino, $touched_domino))
                            {
                                print ("1stangle Hitting!!\n");
                                print_dom ($touched_domino);
                                print ("2nd 1stangle Hitting!!\n");
                                $touched_domino->{standing} = 0;
                                $touched_domino->{falling} = 1;
                                $touched_domino->{current_count} = $current_count;
                                $touched_domino->{fallen} = 0;
                                set_falling_direction ($touched_domino, $domino, 0);
                            }
                        }
                        elsif ($domino->{falling_direction} == 90)
                        {
                            my $touched_domino = get_domino ($row - 1, $col, 90);
                            if (ok_to_hit ($domino, $touched_domino))
                            {
                                print ("1stangle Hitting!!\n");
                                print_dom ($touched_domino);
                                print ("2nd 1stangle Hitting!!\n");
                                $touched_domino->{standing} = 0;
                                $touched_domino->{falling} = 1;
                                $touched_domino->{current_count} = $current_count;
                                $touched_domino->{fallen} = 0;
                                set_falling_direction ($touched_domino, $domino, 0);
                            }
                        }
                        elsif ($domino->{falling_direction} == 135)
                        {
                            my $touched_domino = get_domino ($row - 1, $col - 1, 135);
                            if (ok_to_hit ($domino, $touched_domino))
                            {
                                print ("1stangle Hitting!!\n");
                                print_dom ($touched_domino);
                                print ("2nd 1stangle Hitting!!\n");
                                $touched_domino->{standing} = 0;
                                $touched_domino->{falling} = 1;
                                $touched_domino->{current_count} = $current_count;
                                $touched_domino->{fallen} = 0;
                                set_falling_direction ($touched_domino, $domino, 0);
                            }
                        }
                        elsif ($domino->{falling_direction} == 180)
                        {
                            my $touched_domino = get_domino ($row, $col - 1, 180);
                            if (ok_to_hit ($domino, $touched_domino))
                            {
                                print ("1stangle Hitting!!\n");
                                print_dom ($touched_domino);
                                print ("2nd 1stangle Hitting!!\n");
                                $touched_domino->{standing} = 0;
                                $touched_domino->{falling} = 1;
                                $touched_domino->{current_count} = $current_count;
                                $touched_domino->{fallen} = 0;
                                set_falling_direction ($touched_domino, $domino, 0);
                            }
                        }
                        elsif ($domino->{falling_direction} == 225)
                        {
                            my $touched_domino = get_domino ($row + 1, $col - 1, 225);
                            print ("CHECKING for 225 angle.. !!\n");
                            print_dom ($touched_domino);
                            print ("2nd 1stangle Hitting!!\n");
                            if (ok_to_hit ($domino, $touched_domino))
                            {
                                print ("1stangle Hitting!!\n");
                                print_dom ($touched_domino);
                                print ("2nd 1stangle Hitting!!\n");
                                $touched_domino->{standing} = 0;
                                $touched_domino->{falling} = 1;
                                $touched_domino->{current_count} = $current_count;
                                $touched_domino->{fallen} = 0;
                                set_falling_direction ($touched_domino, $domino, 0);
                            }
                        }
                        elsif ($domino->{falling_direction} == 270)
                        {
                            my $touched_domino = get_domino ($row + 1, $col, 270);
                            if (ok_to_hit ($domino, $touched_domino))
                            {
                                print ("1stangle Hitting!!\n");
                                print_dom ($touched_domino);
                                print ("2nd 1stangle Hitting!!\n");
                                $touched_domino->{standing} = 0;
                                $touched_domino->{falling} = 1;
                                $touched_domino->{current_count} = $current_count;
                                $touched_domino->{fallen} = 0;
                                set_falling_direction ($touched_domino, $domino, 0);
                            }
                        }
                        elsif ($domino->{falling_direction} == 315)
                        {
                            my $touched_domino = get_domino ($row + 1, $col + 1, 315);
                            if (ok_to_hit ($domino, $touched_domino))
                            {
                                print ("1stangle Hitting!!\n");
                                print_dom ($touched_domino);
                                print ("2nd 1stangle Hitting!!\n");
                                $touched_domino->{standing} = 0;
                                $touched_domino->{falling} = 1;
                                $touched_domino->{current_count} = $current_count;
                                $touched_domino->{fallen} = 0;
                                set_falling_direction ($touched_domino, $domino, 0);
                            }
                        }
                    }

                    if ($domino->{second_angle} != $INVALID_ANGLE)
                    {
                        print ("DUAL dominoes $domino->{angle}, $domino->{second_angle} from $domino->{id}");
                        
                        if ($domino->{angle} == 0)
                        {
                            my $touched_domino = get_domino ($row, $col + 1, 0);
                            if (ok_to_hit ($domino, $touched_domino))
                            {
                                print ("###11 angle ($row,$col) Hitting!!\n");
                                print_dom ($touched_domino);
                                print ("###11 2nd angle ($row,$col) Hitting!!\n");
                                $touched_domino->{standing} = 0;
                                $touched_domino->{falling} = 1;
                                $touched_domino->{current_count} = $current_count;
                                $touched_domino->{fallen} = 0;
                                set_falling_direction ($touched_domino, $domino, 1);
                            }
                        }
                        elsif ($domino->{angle} == 45)
                        {
                            my $touched_domino = get_domino ($row - 1, $col + 1, 45);
                            if (ok_to_hit ($domino, $touched_domino))
                            {
                                print ("###11 angle ($row,$col) Hitting!!\n");
                                print_dom ($touched_domino);
                                print ("###11 2nd angle ($row,$col) Hitting!!\n");
                                $touched_domino->{standing} = 0;
                                $touched_domino->{falling} = 1;
                                $touched_domino->{current_count} = $current_count;
                                $touched_domino->{fallen} = 0;
                                set_falling_direction ($touched_domino, $domino, 1);
                            }
                        }
                        elsif ($domino->{angle} == 90)
                        {
                            my $touched_domino = get_domino ($row - 1, $col, 90);
                            if (ok_to_hit ($domino, $touched_domino))
                            {
                                print ("###11 angle ($row,$col) Hitting!!\n");
                                print_dom ($touched_domino);
                                print ("###11 2nd angle ($row,$col) Hitting!!\n");
                                $touched_domino->{standing} = 0;
                                $touched_domino->{falling} = 1;
                                $touched_domino->{current_count} = $current_count;
                                $touched_domino->{fallen} = 0;
                                set_falling_direction ($touched_domino, $domino, 1);
                            }
                        }
                        elsif ($domino->{angle} == 135)
                        {
                            my $touched_domino = get_domino ($row - 1, $col - 1, 135);
                            if (ok_to_hit ($domino, $touched_domino))
                            {
                                print ("###11 angle ($row,$col) Hitting!!\n");
                                print_dom ($touched_domino);
                                print ("###11 2nd angle ($row,$col) Hitting!!\n");
                                $touched_domino->{standing} = 0;
                                $touched_domino->{falling} = 1;
                                $touched_domino->{current_count} = $current_count;
                                $touched_domino->{fallen} = 0;
                                set_falling_direction ($touched_domino, $domino, 1);
                            }
                        }
                        elsif ($domino->{angle} == 180)
                        {
                            my $touched_domino = get_domino ($row, $col - 1, 180);
                            if (ok_to_hit ($domino, $touched_domino))
                            {
                                print ("###11 angle ($row,$col) Hitting!!\n");
                                print_dom ($touched_domino);
                                print ("###11 2nd angle ($row,$col) Hitting!!\n");
                                $touched_domino->{standing} = 0;
                                $touched_domino->{falling} = 1;
                                $touched_domino->{current_count} = $current_count;
                                $touched_domino->{fallen} = 0;
                                set_falling_direction ($touched_domino, $domino, 1);
                            }
                        }
                        elsif ($domino->{angle} == 225)
                        {
                            my $touched_domino = get_domino ($row + 1, $col - 1, 225);
                            if (ok_to_hit ($domino, $touched_domino))
                            {
                                print ("###11 angle ($row,$col) Hitting!!\n");
                                print_dom ($touched_domino);
                                print ("###11 2nd angle ($row,$col) Hitting!!\n");
                                $touched_domino->{standing} = 0;
                                $touched_domino->{falling} = 1;
                                $touched_domino->{current_count} = $current_count;
                                $touched_domino->{fallen} = 0;
                                set_falling_direction ($touched_domino, $domino, 1);
                            }
                        }
                        elsif ($domino->{angle} == 270)
                        {
                            my $touched_domino = get_domino ($row + 1, $col, 270);
                            if (ok_to_hit ($domino, $touched_domino))
                            {
                                print ("###11 angle ($row,$col) Hitting!!\n");
                                print_dom ($touched_domino);
                                print ("###11 2nd angle ($row,$col) Hitting!!\n");
                                $touched_domino->{standing} = 0;
                                $touched_domino->{falling} = 1;
                                $touched_domino->{current_count} = $current_count;
                                $touched_domino->{fallen} = 0;
                                set_falling_direction ($touched_domino, $domino, 1);
                            }
                        }
                        elsif ($domino->{angle} == 315)
                        {
                            my $touched_domino = get_domino ($row + 1, $col + 1, 315);
                            if (ok_to_hit ($domino, $touched_domino))
                            {
                                print ("###11 angle ($row,$col) Hitting!!\n");
                                print_dom ($touched_domino);
                                print ("###11 2nd angle ($row,$col) Hitting!!\n");
                                $touched_domino->{standing} = 0;
                                $touched_domino->{falling} = 1;
                                $touched_domino->{current_count} = $current_count;
                                $touched_domino->{fallen} = 0;
                                set_falling_direction ($touched_domino, $domino, 1);
                            }
                        }

                        if ($domino->{second_angle} == 0)
                        {
                            my $touched_domino = get_domino ($row, $col + 1, 0);
                            if (ok_to_hit ($domino, $touched_domino))
                            {
                                print ("###22 angle ($row,$col) Hitting!!\n");
                                print_dom ($touched_domino);
                                print ("###22 2nd angle ($row,$col) Hitting!!\n");
                                $touched_domino->{standing} = 0;
                                $touched_domino->{falling} = 1;
                                $touched_domino->{current_count} = $current_count;
                                $touched_domino->{fallen} = 0;
                                set_falling_direction ($touched_domino, $domino, 1);
                            }
                        }
                        elsif ($domino->{second_angle} == 45)
                        {
                            my $touched_domino = get_domino ($row - 1, $col + 1, 45);
                            if (ok_to_hit ($domino, $touched_domino))
                            {
                                print ("###22 angle ($row,$col) Hitting!!\n");
                                print_dom ($touched_domino);
                                print ("###22 2nd angle ($row,$col) Hitting!!\n");
                                $touched_domino->{standing} = 0;
                                $touched_domino->{falling} = 1;
                                $touched_domino->{current_count} = $current_count;
                                $touched_domino->{fallen} = 0;
                                set_falling_direction ($touched_domino, $domino, 1);
                            }
                        }
                        elsif ($domino->{second_angle} == 90)
                        {
                            my $touched_domino = get_domino ($row - 1, $col, 90);
                            if (ok_to_hit ($domino, $touched_domino))
                            {
                                print ("###22 angle ($row,$col) Hitting!!\n");
                                print_dom ($touched_domino);
                                print ("###22 2nd angle ($row,$col) Hitting!!\n");
                                $touched_domino->{standing} = 0;
                                $touched_domino->{falling} = 1;
                                $touched_domino->{current_count} = $current_count;
                                $touched_domino->{fallen} = 0;
                                set_falling_direction ($touched_domino, $domino, 1);
                            }
                        }
                        elsif ($domino->{second_angle} == 135)
                        {
                            my $touched_domino = get_domino ($row - 1, $col - 1, 135);
                            if (ok_to_hit ($domino, $touched_domino))
                            {
                                print ("###22 angle ($row,$col) Hitting!!\n");
                                print_dom ($touched_domino);
                                print ("###22 2nd angle ($row,$col) Hitting!!\n");
                                $touched_domino->{standing} = 0;
                                $touched_domino->{falling} = 1;
                                $touched_domino->{current_count} = $current_count;
                                $touched_domino->{fallen} = 0;
                                set_falling_direction ($touched_domino, $domino, 1);
                            }
                        }
                        elsif ($domino->{second_angle} == 180)
                        {
                            my $touched_domino = get_domino ($row, $col - 1, 180);
                            if (ok_to_hit ($domino, $touched_domino))
                            {
                                print ("###22 angle ($row,$col) Hitting!!\n");
                                print_dom ($touched_domino);
                                print ("###22 2nd angle ($row,$col) Hitting!!\n");
                                $touched_domino->{standing} = 0;
                                $touched_domino->{falling} = 1;
                                $touched_domino->{current_count} = $current_count;
                                $touched_domino->{fallen} = 0;
                                set_falling_direction ($touched_domino, $domino, 1);
                            }
                        }
                        elsif ($domino->{second_angle} == 225)
                        {
                            my $touched_domino = get_domino ($row + 1, $col - 1, 225);
                            if (ok_to_hit ($domino, $touched_domino))
                            {
                                print ("###22 angle ($row,$col) Hitting!!\n");
                                print_dom ($touched_domino);
                                print ("###22 2nd angle ($row,$col) Hitting!!\n");
                                $touched_domino->{standing} = 0;
                                $touched_domino->{falling} = 1;
                                $touched_domino->{current_count} = $current_count;
                                $touched_domino->{fallen} = 0;
                                set_falling_direction ($touched_domino, $domino, 1);
                            }
                        }
                        elsif ($domino->{second_angle} == 270)
                        {
                            my $touched_domino = get_domino ($row + 1, $col, 270);
                            if (ok_to_hit ($domino, $touched_domino))
                            {
                                print ("###22 angle ($row,$col) Hitting!!\n");
                                print_dom ($touched_domino);
                                print ("###22 2nd angle ($row,$col) Hitting!!\n");
                                $touched_domino->{standing} = 0;
                                $touched_domino->{falling} = 1;
                                $touched_domino->{current_count} = $current_count;
                                $touched_domino->{fallen} = 0;
                                set_falling_direction ($touched_domino, $domino, 1);
                            }
                        }
                        elsif ($domino->{second_angle} == 315)
                        {
                            my $touched_domino = get_domino ($row + 1, $col + 1, 315);
                            if (ok_to_hit ($domino, $touched_domino))
                            {
                                print ("###22 angle ($row,$col) Hitting!!\n");
                                print_dom ($touched_domino);
                                print ("###22 2nd angle ($row,$col) Hitting!!\n");
                                $touched_domino->{standing} = 0;
                                $touched_domino->{falling} = 1;
                                $touched_domino->{current_count} = $current_count;
                                $touched_domino->{fallen} = 0;
                                set_falling_direction ($touched_domino, $domino, 1);
                            }
                        }
                    }
                    $domino->{standing} = 0;
                    $domino->{falling} = 0;
                    $domino->{fallen} = 1;
                    #cleanup_falling ();
                }
            }
        }
        #print_domino_field ();
    }
}

sub count_standing_dominoes
{
    my $row;
    my $col;
    my $count = 0;
    for ($row = 0; $row < $max_row; $row++)
    {
        for ($col = 0; $col < $max_col; $col++)
        {
            my $domino = get_domino ($row, $col, 55555);
            if ($domino->{standing} == 1)
            {
                if ($domino->{empty} == 0)
                {
                    $count++;
                }
            }
        }
    }
    return $count;
}

sub get_incident_direction
{
    # The direction the first domino is falling
    my $first_direction = $_ [0];
    # The direction the second domino is standing
    my $standing_direction = $_ [1];
    $standing_direction = $standing_direction % 180;

    #print (">>> $first_direction vs $standing_direction\n");

    if ($first_direction == 0)
    {
        if ($standing_direction == 0) { return $INVALID_ANGLE; }
        if ($standing_direction == 45) { return 315; }
        if ($standing_direction == 90) { return 0; }
        if ($standing_direction == 135) { return 45; }
    }
    elsif ($first_direction == 45)
    {
        if ($standing_direction == 0) { return 90; }
        if ($standing_direction == 45) { return $INVALID_ANGLE; }
        if ($standing_direction == 90) { return 0; }
        if ($standing_direction == 135) { return 45; }
    }
    elsif ($first_direction == 90)
    {
        if ($standing_direction == 0) { return 90; }
        if ($standing_direction == 45) { return 135; }
        if ($standing_direction == 90) { return $INVALID_ANGLE; }
        if ($standing_direction == 135) { return 45; }
    }
    elsif ($first_direction == 135)
    {
        if ($standing_direction == 0) { return 90; }
        if ($standing_direction == 45) { return 135; }
        if ($standing_direction == 90) { return 180; }
        if ($standing_direction == 135) { return $INVALID_ANGLE; }
    }
    elsif ($first_direction == 180)
    {
        if ($standing_direction == 0) { return $INVALID_ANGLE; }
        if ($standing_direction == 45) { return 135; }
        if ($standing_direction == 90) { return 180; }
        if ($standing_direction == 135) { return 225; }
    }
    elsif ($first_direction == 225)
    {
        if ($standing_direction == 0) { return 270; }
        if ($standing_direction == 45) { return $INVALID_ANGLE; }
        if ($standing_direction == 90) { return 180; }
        if ($standing_direction == 135) { return 225; }
    }
    elsif ($first_direction == 270)
    {
        if ($standing_direction == 0) { return 270; }
        if ($standing_direction == 45) { return 315; }
        if ($standing_direction == 90) { return $INVALID_ANGLE; }
        if ($standing_direction == 135) { return 225; }
    }
    elsif ($first_direction == 315)
    {
        if ($standing_direction == 0) { return 270; }
        if ($standing_direction == 45) { return 315; }
        if ($standing_direction == 90) { return 0; }
        if ($standing_direction == 135) { return $INVALID_ANGLE; }
    }
    return $INVALID_ANGLE;
}

sub set_falling_direction
{
    my $touched_domino = $_ [0];
    my $domino = $_ [1];
    my $use_second_angle = $_ [2];

    if ($use_second_angle == 0)
    {
        my $new_falling_direction = get_incident_direction ($domino->{falling_direction}, $touched_domino->{angle});
        $touched_domino->{falling} = 1;
        print ("\n==***=====\nIn set falling direction (from get_incident_direction ($domino->{falling_direction}, $touched_domino->{angle})):\n"); 
        print_dom ($touched_domino);
        $touched_domino->{falling_direction} = $new_falling_direction;
        print_dom ($touched_domino);
        print ("\n==***=====\n\n"); 
        print_domino_field ();
    }
    elsif ($use_second_angle == 1 && $domino->{second_angle} >= 0)
    {
        my $new_falling_direction = get_incident_direction ($domino->{second_angle}, $touched_domino->{angle});
        $touched_domino->{falling} = 1;
        print ("\n==***=====\n##22 In set falling direction (from get_incident_direction ($domino->{falling_direction}, $touched_domino->{angle})):\n"); 
        print_dom ($touched_domino);
        $touched_domino->{falling_direction} = $new_falling_direction;
        print_dom ($touched_domino);
        print ("\n==***=====\n\n"); 
        print_domino_field ();
    }
}

sub print_dom
{
    my $dom = $_ [0];
    #print ("INFO FOR domino $dom->{id}=id,$dom->{current_count}=current_count, $dom->{second_angle}=second_angle,$dom->{first}=first, $dom->{angle}=angle, $dom->{standing}=standing, $dom->{falling}=falling, $dom->{falling_direction}=falling_direction, $dom->{second_falling_direction}=second_falling_direction, $dom->{fallen}=fallen, $dom->{empty}=empty, $dom->{row}=row, $dom->{col}=col, $dom->{single}=single, $dom->{second_angle}=second_angle\n");
}

sub get_domino
{
    my $row = $_ [0];
    my $col = $_ [1];
    my $angle_from = $_ [2];

    if (exists ($domino_layout {"$row,$col"}))
    {
        my $dom = $domino_layout {"$row,$col"};
        if ($dom->{id} == 240)
        {
            #print_dom ($dom);;
        }
        
        if ($dom->{second_angle} > -1)
        {
            #print ("Found domino: $dom->{id} which was $row,$col and had $dom->{second_angle} of second_angle and is falling?$dom->{falling} fallen?$dom->{fallen}\n");
        }
        return $domino_layout {"$row,$col"};
    }
    my %empty_domino;
    $empty_domino {empty} = 1;
    return \%empty_domino;
}

sub print_domino_field
{
    my $row;
    my $col;
    my $count = 0;
    my $num_doms = 0;
    print ("==============================\n");
#    print ("0 2 4 6 8 0 2 4 6 8 0 2 4 6 8 0 2 4 6 8 0\n");
#    for ($row = 0; $row < $max_row; $row++)
#    {
#        for ($col = 0; $col < $max_col; $col++)
#        {
#            $num_doms ++;
#            my $domino = get_domino ($row, $col);
#            if ($domino->{empty} == 1)
#            {
#                print (".");
#            }
#            elsif ($domino->{standing} == 1)
#            {
#                print ("S");
#            }
#            elsif ($domino->{falling} == 1)
#            {
#                print ("F");
#            }
#            elsif ($domino->{fallen} == 1)
#            {
#                print ("*");
#            }
#        }
#        print ("  (Total doms = $num_doms)\n");
#    }

#    print ("+++++++++++++++\n");
    for ($row = 0; $row < $max_row; $row++)
    {
        for ($col = 0; $col < $max_col; $col++)
        {
            my $domino = get_domino ($row, $col);
            if ($domino->{empty} == 1)
            {
                print (".");
            }
            else
            {
                if ($domino->{falling} == 1)
                {
                    print ("F");
                }
                elsif ($domino->{fallen} == 1)
                {
                    print ("*");
                }
                else
                {
                    if ($domino->{angle} == 0)
                    {
                        print ("-");
                    }
                    elsif ($domino->{angle} == 45)
                    {
                        print ("/");
                    }
                    elsif ($domino->{angle} == 90)
                    {
                        print ("|");
                    }
                    elsif ($domino->{angle} == 135)
                    {
                        print ("\\");
                    }

                    if ($domino->{second_angle} == 45)
                    {
                        print ("/");
                    }
                    elsif ($domino->{second_angle} == 135)
                    {
                        print ("\\");
                    }
                    elsif ($domino->{second_angle} == 215)
                    {
                        print ("\\");
                    }
                    elsif ($domino->{second_angle} == 315)
                    {
                        print ("\\");
                    }
                }
            }
        }
        print ("\n");
    }

    print ("==============================\n");
}

# Main
{
    my $file = "";
    my $row = 0;
    my $col = 0;
    my $STEP_COUNTER = 0;

    $file = $ARGV [0];
    $file = "./dominoes.txt";
    $file = $ARGV [0];
    my $ID = 0;

    open FILE, "$file";
    while (<FILE>)
    {
        chomp $_;
        my $line = $_;
        while ($line =~ s/^(.)//)
        {
            my %domino;
            my $char = $1;
            $domino{id} = $ID;
            $domino{first} = 0;
            $domino{angle} = 0;
            $domino{standing} = 1;
            $domino{falling} = 0;
            $domino{falling_direction} = 0;
            $domino{second_falling_direction} = $INVALID_ANGLE;
            $domino{fallen} = 0;
            $domino{empty} = 1;
            $domino{row} = $row;
            $domino{col} = $col;
            $domino{single} = 1;
            $domino{second_angle} = $INVALID_ANGLE;

            if ($char ne " ")
            {
                $domino{empty} = 0;
            }

            if ($char =~ m/^\*$/)
            {
                $domino{first} = 1;
            }

            if ($char =~ m/^\-$/)
            {
                $domino{angle} = 0;
            }

            if ($char =~ m/^\/$/)
            {
                $domino{angle} = 45;
            }

            if ($char =~ m/^\|$/)
            {
                $domino{angle} = 90;
            }

            if ($char =~ m/^\\$/)
            {
                $domino{angle} = 135;
            }

            if ($char =~ m/^[\^>v<]$/)
            {
                $domino{single} = 0;
                if ($char =~ m/^[\^]$/)
                {
                    $domino{angle} = 45;
                    $domino{second_angle} = 135;
                    print ("FOUND second_angle $domino{id} for 135\n");
                }
                if ($char =~ m/^>$/)
                {
                    $domino{angle} = 45;
                    $domino{second_angle} = 315;
                    print ("FOUND second_angle $domino{id} for 315\n");
                }
                if ($char =~ m/^v$/)
                {
                    $domino{angle} = 225;
                    $domino{second_angle} = 315;
                    print ("FOUND second_angle $domino{id} for 315\n");
                }
                if ($char =~ m/^<$/)
                {
                    $domino{angle} = 135;
                    $domino{second_angle} = 225;
                    print ("FOUND second_angle $domino{id} for 225\n");
                }
            }

            $domino_layout{"$row,$col"} = \%domino;

            #print ("$row,$col >> $domino{angle} (empty=$domino{empty})\n");
            $col++;
            if ($max_col < $col)
            {
                $max_col = $col;
            }

            if ($ID == 240)
            {
                #print_dom (\%domino);
            }

            $ID++;
        }

        $row++;
        if ($max_row < $row)
        {
            $max_row = $row;
        }
        $col = 0;
    }

    my $test_condition = 1;
    my $previous_dominoes_standing = 0;
    my $dominoes_standing = 0;

    my $past_count = count_standing_dominoes ();
    print ("Step counter: $STEP_COUNTER - saw $past_count dominoes standing\n");
    while ($test_condition)
    {
        print_domino_field ();
        next_step_in_simulation ();
        $current_count = count_standing_dominoes ();
        if ($current_count == $past_count)
        {
            $test_condition = 0;
        }
        $past_count = $current_count;
        $first_step = 0;
        $STEP_COUNTER ++;
        print ("Step counter: $STEP_COUNTER - saw $current_count dominoes standing ($current_count vs $past_count)\n");
    }
}
