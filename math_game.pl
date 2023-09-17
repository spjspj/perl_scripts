#!/usr/bin/perl
##
#   File : math_game.pl
#   Date : 18/Sept/2023
#   Author : spjspj
#   Purpose : Work out a way to recreate the NYT game that was canned in August 2023
##

use strict;
use POSIX;
use LWP::Simple;
use Socket;
use File::Copy;

# Main
{
    my $num_terms = int (rand (3)) + 3;
    print ($num_terms , " is number of terms\n");
    my %nums;
    $nums {0} = int (rand (10)) + 1;
    $nums {1} = int (rand (10)) + 1;
    $nums {2} = int (rand (10)) + 1;
    $nums {3} = int (rand (25)) + 1;
    $nums {4} = int (rand (25)) + 1;
    $nums {5} = int (rand (50)) + 1;

    my %used_terms;
    $used_terms {0} = 0;
    $used_terms {1} = 0;
    $used_terms {2} = 0;
    $used_terms {3} = 0;
    $used_terms {4} = 0;
    $used_terms {5} = 0;
    $used_terms {6} = 0;
    my $equation;

    for (my $i = 0; $i < $num_terms - 1; $i++)
    {
        my $number = int (rand (6));
        while ($used_terms {$number} == 1)
        {
            $number = int (rand (6));
        }
        $used_terms {$number} = 1;
        $equation .= $nums {$number};

        my $operator = int (rand (7));
        my $sign;
        if ($operator < 2) { $sign = "+"; }
        elsif ($operator < 4) { $sign = "-"; }
        elsif ($operator < 6) { $sign = "*"; }
        else { $sign = "/"; }
        $equation .= $sign;
    }

    my $number = int (rand (6));
    while ($used_terms {$number} == 1)
    {
        $number = int (rand (6));
    }
    $used_terms {$number} = 1;
    $equation .= $nums {$number};
    
    print ("ANSWER GIVEN:\n");
    print (join (",", values (%nums))), "\n";
    print "\n";
    print ($equation, "\n");
    my $eq = eval ($equation);
    print ("Answer is: ", $eq, "\n");

    print ("\n\n\n\n\n\n\n\n\nNO ANSWER GIVEN:\n");
    print (join (",", values (%nums))), "\n";
    print "\n";
    #print ($equation, "\n");
    my $eq = eval ($equation);
    print ("Answer is: ", $eq, "\n");
}
