#!/usr/bin/perl
##
#   File : water_sort.pl
#   Date : 4/Feb/2024
#   Author : spjspj
#   Purpose : Work out pouring water game.. (Level 127 of water sort android game)
##

use strict;
use POSIX;
use LWP::Simple;
use Socket;
use File::Copy;

my %vial_colours;
my $vial_number = 0;
my $EMPTY = "empty";
my $INVALID_VIAL = -1;
my %colours;
my %colours_pairs;
my %all_states;

sub reset_vials
{
    my %as;
    %all_states = %as;
    # Vial number, level from bottom (1 being bottom), height
    $vial_number = 0;
    $vial_colours {"$vial_number,4"} = "pink";
    $vial_colours {"$vial_number,3"} = "green";
    $vial_colours {"$vial_number,2"} = "orange";
    $vial_colours {"$vial_number,1"} = "dblue";
    $vial_number ++;
    $vial_colours {"$vial_number,4"} = "green";
    $vial_colours {"$vial_number,3"} = "purple";
    $vial_colours {"$vial_number,2"} = "orange";
    $vial_colours {"$vial_number,1"} = "blue";
    $vial_number ++;
    $vial_colours {"$vial_number,4"} = "red";
    $vial_colours {"$vial_number,3"} = "yellow";
    $vial_colours {"$vial_number,2"} = "blue";
    $vial_colours {"$vial_number,1"} = "green";
    $vial_number ++;
    $vial_colours {"$vial_number,4"} = "yellow";
    $vial_colours {"$vial_number,3"} = "dblue";
    $vial_colours {"$vial_number,2"} = "blue";
    $vial_colours {"$vial_number,1"} = "gray";
    $vial_number ++;
    $vial_colours {"$vial_number,4"} = "orange";
    $vial_colours {"$vial_number,3"} = "blue";
    $vial_colours {"$vial_number,2"} = "purple";
    $vial_colours {"$vial_number,1"} = "pink";
    $vial_number ++;
    $vial_colours {"$vial_number,4"} = "dblue";
    $vial_colours {"$vial_number,3"} = "yellow";
    $vial_colours {"$vial_number,2"} = "purple";
    $vial_colours {"$vial_number,1"} = "green";
    $vial_number ++;
    $vial_colours {"$vial_number,4"} = "pink";
    $vial_colours {"$vial_number,3"} = "gray";
    $vial_colours {"$vial_number,2"} = "pink";
    $vial_colours {"$vial_number,1"} = "red";
    $vial_number ++;
    $vial_colours {"$vial_number,4"} = "purple";
    $vial_colours {"$vial_number,3"} = "yellow";
    $vial_colours {"$vial_number,2"} = "gray";
    $vial_colours {"$vial_number,1"} = "gray";
    $vial_number ++;
    $vial_colours {"$vial_number,4"} = "orange";
    $vial_colours {"$vial_number,3"} = "dblue";
    $vial_colours {"$vial_number,2"} = "red";
    $vial_colours {"$vial_number,1"} = "red";
    $vial_number ++;
    $vial_colours {"$vial_number,4"} = $EMPTY;
    $vial_colours {"$vial_number,3"} = $EMPTY;
    $vial_colours {"$vial_number,2"} = $EMPTY;
    $vial_colours {"$vial_number,1"} = $EMPTY;
    $vial_number ++;
    $vial_colours {"$vial_number,4"} = $EMPTY;
    $vial_colours {"$vial_number,3"} = $EMPTY;
    $vial_colours {"$vial_number,2"} = $EMPTY;
    $vial_colours {"$vial_number,1"} = $EMPTY;
    $vial_number ++;
}

sub find_colours
{
    my $c;
    foreach $c (values (%vial_colours))
    {
        $colours {$c} = 1;
    }

    my $c2;
    foreach $c (keys (%colours))
    {
        foreach $c2 (keys (%colours))
        {
            if ($c ne $c2)
            {
                if ($c eq $EMPTY) { next; }
                if ($c2 eq $EMPTY) { next; }
                if ($c < $c2)
                {
                    $colours_pairs {$c . " " . $c2} = 1;
                }
                else
                {
                    $colours_pairs {$c2 . " " . $c} = 1;
                }
            }
        }
    }
    #print (join ("\n", sort keys (%colours_pairs)));
}

sub is_vial_only_one_full_colour
{
    my $x = $_ [0];
    my $color_1 = $vial_colours {"$x,1"};
    my $color_2 = $vial_colours {"$x,2"};
    my $color_3 = $vial_colours {"$x,3"};
    my $color_4 = $vial_colours {"$x,4"};

    if (
        ($color_1 eq $color_2 || $color_1 eq $EMPTY) &&
        ($color_2 eq $color_3 || $color_2 eq $EMPTY) &&
        ($color_3 eq $color_4 || $color_3 eq $EMPTY) &&
        ($color_3 eq $color_4 || $color_4 eq $EMPTY))
    {
        return 1;
    }
    return 0;
}

sub num_units_in_vial_empty
{
    my $x = $_ [0];
    my $color_1 = $vial_colours {"$x,1"};
    my $color_2 = $vial_colours {"$x,2"};
    my $color_3 = $vial_colours {"$x,3"};
    my $color_4 = $vial_colours {"$x,4"};

    if ($color_4 eq $EMPTY) { return 4; }
    if ($color_3 eq $EMPTY) { return 3; }
    if ($color_2 eq $EMPTY) { return 2; }
    if ($color_1 eq $EMPTY) { return 1; }
    return 0;
}

sub get_vial_with_color_at_top
{
    my $color = $_ [0];
    my $x = 0;
    while ($x < $vial_number)
    {
        my $color_at_top = get_color_at_top ($x);
        if ($color_at_top eq $color) { return $x; }
        $x++;
    }
    return $INVALID_VIAL;
}

sub get_color_at_top
{
    my $vial = $_ [0];
    if ($vial_colours {"$vial,4"} ne $EMPTY) { return $vial_colours {"$vial,4"}; }
    if ($vial_colours {"$vial,3"} ne $EMPTY) { return $vial_colours {"$vial,3"}; }
    if ($vial_colours {"$vial,2"} ne $EMPTY) { return $vial_colours {"$vial,2"}; }
    if ($vial_colours {"$vial,1"} ne $EMPTY) { return $vial_colours {"$vial,1"}; }
    return $EMPTY;
}

sub get_empty_slots_at_top
{
    my $vial = $_ [0];
    if ($vial_colours {"$vial,1"} eq $EMPTY) { return 4; }
    if ($vial_colours {"$vial,2"} eq $EMPTY) { return 3; }
    if ($vial_colours {"$vial,3"} eq $EMPTY) { return 2; }
    if ($vial_colours {"$vial,4"} eq $EMPTY) { return 1; }
    return 0;
}

sub finished
{
    my $x = 0;
    my $all_good = 1;
    while ($x < $vial_number)
    {
        my $vial_ok = is_vial_only_one_full_colour ($x);
        if (!$vial_ok)
        {
            print ($x, " bad :( ");
            $all_good = 0;
        }
        else
        {
            print ($x, " good! ");
        }
        $x++;
    }

    if ($all_good)
    {
        print ("\nFINISHED SUCCESSFULLY!");
    }
    else
    {
        print ("\nFINISHED FAILURE!");
    }
    return $all_good;
}

sub do_pour
{
    my $vial1 = $_ [0];   
    my $vial2 = $_ [1];   
    my $colour = $_ [2];   
    print ("Doing pour! $vial1,$vial2,$colour\n");

    if (get_color_at_top ($vial1) eq $colour && (get_color_at_top ($vial2) eq $colour || get_color_at_top ($vial2) eq $EMPTY))
    {
         while (get_color_at_top ($vial1) eq $colour)
         {
             my $one_unit_ok = 0;
             if ($vial_colours {"$vial2,1"} eq $EMPTY) { $vial_colours {"$vial2,1"} = $colour; $one_unit_ok = 1; }
             elsif ($vial_colours {"$vial2,2"} eq $EMPTY) { $vial_colours {"$vial2,2"} = $colour; $one_unit_ok = 1; }
             elsif ($vial_colours {"$vial2,3"} eq $EMPTY) { $vial_colours {"$vial2,3"} = $colour; $one_unit_ok = 1; }
             elsif ($vial_colours {"$vial2,4"} eq $EMPTY) { $vial_colours {"$vial2,4"} = $colour; $one_unit_ok = 1; }

             if ($one_unit_ok)
             {
                 if ($vial_colours {"$vial1,4"} eq $colour) { $vial_colours {"$vial1,4"} = $EMPTY; }
                 elsif ($vial_colours {"$vial1,3"} eq $colour) { $vial_colours {"$vial1,3"} = $EMPTY; }
                 elsif ($vial_colours {"$vial1,2"} eq $colour) { $vial_colours {"$vial1,2"} = $EMPTY; }
                 elsif ($vial_colours {"$vial1,1"} eq $colour) { $vial_colours {"$vial1,1"} = $EMPTY; }
             }
             
             if ($one_unit_ok)
             {
                 print ("DID THE POUR!\n");
             }
             else
             {
                 print ("DID NOT DO THE POUR! ($vial1, $vial2, $colour)\n");
                 return;
             }
         }
    }
    print ("FINISHED POUR! ($vial1, $vial2, $colour)\n");
}

my $pair;
sub find_next_pour
{
    my $this_pair = $_ [0];
    my $c1;
    my $c2;
    $this_pair =~ m/^(.*) (.*)/;
    $c1 = $1;
    $c2 = $2;

    my $vial1 = get_vial_with_color_at_top ($c1);
    my $vial_1_goes_to = get_vial_with_color_at_top ($EMPTY);
    do_pour ($vial1, $vial_1_goes_to, $c1);

    my $vial2 = get_vial_with_color_at_top ($c2);
    my $vial_2_goes_to = get_vial_with_color_at_top ($EMPTY);
    do_pour ($vial2, $vial_2_goes_to, $c2);
}

sub any_next_pour
{
    my $x = 0;
    my $skip_n = $_ [0];

    while ($x < $vial_number)
    {
        my $color_at_top = get_color_at_top ($x);
        if ($color_at_top eq $EMPTY)
        {
            $x++;
            next;
        }

        my $x2 = 0;
        while ($x2 < $vial_number)
        {
            if ($x2 == $x) { $x2++; next; }
            my $color_at_top2 = get_color_at_top ($x2);
            if ($color_at_top eq $color_at_top2 && get_empty_slots_at_top ($x2) > 0)
            {
                print "\n\n($skip_n) Next pour $x, $x2, $color_at_top";
                if ($skip_n == 0)
                {
                    return "$x, $x2, $color_at_top";
                }
                else
                {
                    $skip_n --;
                }
            }
            if ($color_at_top2 eq $EMPTY)
            {
                print "\n\n($skip_n) Next pour $x, $x2, $color_at_top";
                if ($skip_n == 0)
                {
                    return "$x, $x2, $color_at_top";
                }
                else
                {
                    $skip_n --;
                }

            }
            $x2++;
        }
        $x++;
    }
    return 0;
}

sub print_vials
{
    my $x;
    my $string;
    my $quarter = 4;
    my $state;

    for ($x = 0; $x < $vial_number; $x++)
    {
        my $col = "$x         ";
        $col =~ s/^(.....).*/$1/;
        $col =~ s/^(.....).*/$1/;
        $string .= "|$col|  ";
    }
    print $string, "\n";
    $state .= $string;
    $string = "";

    for ($quarter = 4; $quarter > 0; $quarter--)
    {
        for ($x = 0; $x < $vial_number; $x++)
        {
            my $col = $vial_colours{"$x,$quarter"} . "      ";
            $col =~ s/^(.....).*/$1/;
            $col =~ s/^(.....).*/$1/;
            $string .= "|$col|  ";
        }
        print $string, " ($x)\n";
        $state .= $string;
        $string = "";
    }
    $state =~ s/\W//img;
    $state =~ s/\W//img;
    if ($all_states {$state} == 1)
    {
        print ("LOOPING!!\n");
        return 1;
    }
    $all_states {$state} = 1;
    return 0;
}

# Main
{
    reset_vials ();
    find_colours ();
    my $number_pours = 0;
    foreach $pair (sort keys (%colours_pairs))
    {
        print ("\n========================\nNEW PAIR $pair\n========================\nNext round!\n");   
        reset_vials ();
        $number_pours = 0;
        find_next_pour ($pair);
        print_vials ();
        my $any_pour = any_next_pour ();
        while ($any_pour =~ m/^(\d+), (\d+), (.+)/ && $number_pours < 100)
        {
            my $vial1 = $1;
            my $vial2 = $2;
            my $col = $3;
            print ("\n .... \nAny pour - $vial1, $vial2, $col\n");   
            do_pour ($vial1, $vial2, $col);
            my $looping = print_vials ();
            $any_pour = any_next_pour ($looping);
            print ("\n Found next any pour - $any_pour\n");
            $number_pours ++;
        }
        finished ();
    }
}
