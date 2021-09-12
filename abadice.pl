#!/usr/bin/perl
##
#   File:: abadice.pl
#   Date:: 11/7/2016
#   Author:: spjspj & psjpsj
#   Purpose:: Implement our game :)
##

use strict;

# Main
my @beads;
my $number_beads = 10;
my $number_wires = 5;
my $size_dice = 20;
my $NUMBER_TIMES_FOR_DRAW = 10;

sub prime
{
    my $number = shift;
    my $d = 2;
    my $sqrt = sqrt $number;
    while (1)
    {
        if ($number%$d == 0)
        {
            return 0;
        }
        if ($d < $sqrt)
        {
            $d++;
        }
        else
        {
            return 1;
        }
    }
}

my $factors = "";
my %factors_for_dice;
sub num_pair_factors
{
    my $number = shift;
    my $i = 2;
    my %new_hash;
    %factors_for_dice = %new_hash;

    my $total_pair_factors = 1;
    $factors = "1&$number, ";
    $factors_for_dice {0} = "1";

    if ($number > $number_beads)
    {
        my %new_hash2;
        %factors_for_dice = %new_hash2;
        $factors = "";
        $total_pair_factors = 0;
    }
    
    for ($i = 2; $i <= 5; $i++)
    {
        if ($number % $i == 0)
        {
            $factors .= "$i&" . $number / $i . ", ";
            $factors_for_dice {$total_pair_factors} = $i;
            $total_pair_factors ++;
        }
    }
    $factors =~ s/, $//;
    return ($total_pair_factors, $factors);
}

sub print_wire
{
    my $number = $_ [0];
    my $line_number = $_ [1];
    my $str = "---";
    my $i;
    for ($i = 0; $i < $number; $i++)
    {
        $str = "-" . $str . "*";
    }
    my $str2;
    for ($i = 0; $i < $number_beads - $number; $i++)
    {
        $str2 = "*" . $str2 . "-";
    }
    if ($line_number <= 4) 
    {
        print ("Player1: " . $str2 . $str, "\n");
    }
    else
    {
        print ("Player2: " . $str2 . $str, "\n");
    }
}

sub print_wires
{
    for (my $j = 0; $j < scalar (@beads); $j++)
    {
        print_wire ($beads [$j], $j);
    }
}

sub move_beads
{
    my $beads_to_move = $_ [0];
    my $wires_affected = $_ [1];
    my $player = $_ [2];
    my $wires_affected_so_far = 0;

    my $add_wires = 0;
    if ($player == 2)
    {
        $add_wires = $number_wires;
    }

    my @old_beads;
    for (my $i = 0; $i < $number_wires * 2; $i++)
    {
        $old_beads [$i] = $beads [$i];
    }

    for (my $x = 0 + $add_wires; $x < $number_wires + $add_wires && $wires_affected_so_far < $wires_affected; $x++)
    {
        if ($beads [$x] >= $beads_to_move)
        {
            $beads [$x] -= $beads_to_move;
            $wires_affected_so_far ++;
        }
    }

    if ($wires_affected != $wires_affected_so_far) 
    {
        # Can't do the full number of beads
        for (my $i = 0; $i < $number_wires * 2; $i++)
        {
            $beads [$i] = $old_beads [$i];
        }
    }

    return $wires_affected == $wires_affected_so_far; 
}

sub has_someone_won
{
    my $player1_won = 1;
    for (my $x = 0; $x < $number_wires; $x++)
    {
        if ($beads [$x] != 0)
        {
            $player1_won = 0;
        }
    }
    if ($player1_won == 1)
    {
        return "Player1 won!!!";
    }

    my $player2_won = 1;
    for (my $x = $number_wires; $x < $number_wires*2; $x++)
    {
        if ($beads [$x] != 0)
        {
            $player2_won = 0;
        }
    }
    if ($player2_won == 1)
    {
        return "Player2 won!!!";
    }

    return "";
}

for (my $i = 0; $i < $number_wires; $i++)
{
    push @beads, $number_beads;
}

for (my $i = 0; $i < $number_wires; $i++)
{
    push @beads, $number_beads;
}

my $player = "Player1";
my $player_num = 1;

my $who_goes_first = int (rand (20));
if ($who_goes_first >= 10)
{
    $player = "Player2";
    $player_num = 2;
}

my $times_move_beads_has_failed = 0;

my @old_beads;
my $old_roll;

while (1)
{
    my $roll = int (rand ($size_dice)) + 1;

    print ("\n--------\nPlayer $player, you rolled: " . $roll);

    if ($times_move_beads_has_failed == $NUMBER_TIMES_FOR_DRAW)
    {
        print ("\n\n\nGame Over!\nThe game was a draw!\n");
        exit;
    }

    # Check if prime?
    if (prime ($roll) && $roll > $number_beads)
    {
        print (".  You rolled a prime greater than $number_beads - haha!! You can't do anything :)\n");
        $times_move_beads_has_failed++;
    }
    else
    {
        my $won = has_someone_won ();
        if ($won =~ m/^./)
        {
            print ("\n\n\nGame Over!\n");
            print ($won);
            exit;
        }

REASK_USER:
        print (".  What do you want to do ($times_move_beads_has_failed failed moves)? :\n");
        my ($num_pair_factors, $factors) = num_pair_factors ($roll);
        print ("You have " . $num_pair_factors . " ($factors) options to choose from: ");


        if ($num_pair_factors > 1)
        {
            my $cmd = <STDIN>;
            chomp $cmd;
            my $m = $cmd - 1;

            if (defined ($factors_for_dice {$m}))
            {
                my $m = $cmd - 1;
                print ("You chose factor $factors_for_dice{$m}\n"); 
                my $asked_if_sure = 0;
                my $chose_correctly = 0;

                while (!$asked_if_sure)
                {
                    print ("  Are you sure? (Y,n): "); 

                    my $cmd = <STDIN>;
                    chomp $cmd;
                    if ($cmd =~ m/n/img)
                    {
                        $asked_if_sure = 1;
                        $chose_correctly = 0;
                    }
                    elsif ($cmd =~ m/y/img || $cmd =~ m/^$/img)
                    {
                        $asked_if_sure = 1;
                        $chose_correctly = 1;
                    }
                    else
                    {
                        $asked_if_sure = 0;
                        $chose_correctly = 0;
                    }
                }
                if ($chose_correctly == 0)
                {
                    goto REASK_USER;
                }

                my $m = $cmd - 1;
                if (move_beads ($roll / $factors_for_dice{$m}, $factors_for_dice{$m},  $player_num))
                {
                    $times_move_beads_has_failed = 0;
                }
                else
                {
                    $times_move_beads_has_failed++;
                }
            }

            while (!defined ($factors_for_dice {$m}))
            {
                print ("(Wrong choice!!) You have " . $num_pair_factors . " ($factors) options to choose from: ");
                $cmd = <STDIN>;
                chomp $cmd;
                $m = $cmd - 1;
                if (defined ($factors_for_dice {$m}))
                {
                    print ("You chose factor $factors_for_dice{$m}\n"); 
                }
            }
            print_wires ();
        }
        elsif ($num_pair_factors == 1)
        {
            $factors =~ m/^(\d+)&(\d+)$/;   
            my $num_wires = $1;
            my $actual_beads = $2;

            if (move_beads ($actual_beads, $num_wires, $player_num))
            {
                $times_move_beads_has_failed = 0;
                print ("You moved $actual_beads beads on $num_wires wire/s successfully!!\n");
                print_wires ();
            }
            else
            {
                $times_move_beads_has_failed++;
            }
        }
    }

    if ($player eq "Player1")
    {
        $player = "Player2";
        $player_num = 2;
    }
    elsif ($player eq "Player2")
    {
        $player = "Player1";
        $player_num = 1;
    }

    # Undo stuff
    $old_roll = $roll;
    for (my $i = 0; $i < $number_wires * 2; $i++)
    {
        $old_beads [$i] = $beads [$i];
    }
}
