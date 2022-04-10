#!/usr/bin/perl
##
#   File : snake.pl
#   Date : 15/Oct/2021
#   Author : spjspj
#   Purpose : Snake
##

use strict;
use vars;
use Win32::Console::ANSI qw/ Cursor /;
use Win32::Console::ANSI qw/ Title /;
use open qw( :std :encoding(UTF-8) );
use Term::ReadKey;
#use Win32::Console::ANSI;
#use Term::ANSIScreen qw/:color :cursor :screen/;
 
Title "Snake!";
`cls`;

binmode STDOUT, ":utf8";

my %snake_dirs;
my %snake_segments_i;
my %snake_segments_j;
my $snake_length = 5;
my $grow_to_snake_length = 5;
my $current_dir = 1;  # 0 = right, 1 = up, 2 = left, 3 = down
my $current_head_x = 0;
my $current_head_y = 0;
my $current_turns = 10000;
my $WIDTH = 80;
my $HEIGHT = 40;

sub init_snake
{
    $snake_length = 5;
    my $i = 0;
    my $start_x = 40;
    my $start_y = 20;
    
    while ($i < $snake_length)
    {
        $snake_dirs {$i} = $current_dir;
        $snake_segments_i {$i} = $start_x;
        $snake_segments_j {$i} = $start_y;
        $current_head_x = $snake_segments_i {$i};
        $current_head_y = $snake_segments_j {$i};
        $start_y--;
        $i++;
    }
}

sub print_border
{
    Cursor (1,1); print ("+\n");
    my $i = 1;
    my $j = 1;
    while ($i < $WIDTH)
    {
        $i ++;
        Cursor ($i, 1); print (";\n");
    }
    Cursor ($i, 1); print ("+\n");
    while ($j < $HEIGHT)
    {
        $j ++;
        Cursor ($i,$j); print ("|\n");
    }
    Cursor ($i,$j); print ("+\n");
    
    while ($i > 1)
    {
        $i --;
        Cursor ($i,$j); print ("=\n");
    }
    Cursor ($i,$j); print ("+\n");
    
    while ($j > 2)
    {
        $j --;
        Cursor ($i,$j); print ("|\n");
    }
}

sub clear_all
{
    `cls`;
    my $i = 1;
    my $j = 1;
    while ($i < 80)
    {
        $i ++;
        $j = 0;
        while ($j < 40)
        {
            $j ++;
            Cursor ($i,$j); print (" \n");
        }
    }
}

sub clear_snake
{
    my $i = 0;
    while ($i < 1) #$snake_length - 1)
    {
        Cursor ($snake_segments_i {$i}, $snake_segments_j {$i}); 
        print " \n";
        $i++;
    }
}

my $next_apple_i;
my $next_apple_j;
sub print_apple
{
    my $i = $next_apple_i;
    my $j = $next_apple_j;
    
    Cursor ($i,$j);
    print "\e[1;35m@\e[0m\n";
}

my $num_apples = -1;
sub set_apple_pos
{
    $next_apple_i = int (rand (76)) + 2;
    $next_apple_j = int (rand (36)) + 2;
    $num_apples++;
    print_apple ();
}

sub set_current_dir
{
    my $new_direction = $_ [0];
    if ($current_dir % 2 == 0 && $new_direction % 2 == 0)
    {
        return;
    }
    elsif ($current_dir % 2 == 1 && $new_direction % 2 == 1)
    {
        return;
    }

    $current_dir = $new_direction;
}

sub grow_snake
{
    $grow_to_snake_length += 5;
    $current_turns -= 1000; 
    if ($current_turns < 1000)
    {
        $current_turns = 1000; 
    }
}

sub move_snake
{
    my $i = 0;
    if ($snake_length == $grow_to_snake_length)
    {
        while ($i < $snake_length - 1)
        {
            $snake_dirs {$i} = $snake_dirs {$i+1};
            $snake_segments_i {$i} = $snake_segments_i {$i+1};
            $snake_segments_j {$i} = $snake_segments_j {$i+1};
            $i++;
        }
    }
 
    if ($snake_length < $grow_to_snake_length)
    {
        $snake_length++; 
    }
    $i = $snake_length - 1;

    $snake_dirs {$i} = $current_dir;
    if ($current_dir == 0)
    {
        $snake_segments_i {$i} = $snake_segments_i {$i-1}+1;
        $snake_segments_j {$i} = $snake_segments_j {$i-1};
    }
    elsif ($current_dir == 1)
    {
        $snake_segments_i {$i} = $snake_segments_i {$i-1};
        $snake_segments_j {$i} = $snake_segments_j {$i-1}-1;
    }
    elsif ($current_dir == 2)
    {
        $snake_segments_i {$i} = $snake_segments_i {$i-1}-1;
        $snake_segments_j {$i} = $snake_segments_j {$i-1};
    }
    elsif ($current_dir == 3)
    {
        $snake_segments_i {$i} = $snake_segments_i {$i-1};
        $snake_segments_j {$i} = $snake_segments_j {$i-1}+1;
    }


    if ($snake_segments_i {$i} <= 1 || $snake_segments_i {$i} > $WIDTH - 1)
    {
        print ("You died (head x was $snake_segments_i{$i}, apples eaten: $num_apples).\n");
        exit;
    }

    if ($snake_segments_j {$i} <= 1 || $snake_segments_j {$i} > $HEIGHT - 1)
    {
        print ("You died (head y was $snake_segments_j{$i}, apples eaten: $num_apples).\n");
        exit;
    }

    my $n;
    for ($n = 0; $n < $snake_length - 1; $n++)
    {
        if ($snake_segments_i {$i} == $snake_segments_i {$n} && $snake_segments_j {$i} == $snake_segments_j {$n})
        {
            print ("You bit yourself (apples eaten: $num_apples)..\n");
            exit;
        }
    }

    if ($snake_segments_i {$i} == $next_apple_i && $snake_segments_j {$i} == $next_apple_j)
    {
        set_apple_pos ();
        grow_snake (3);
    }
}

sub print_snake
{
    my $i = $snake_length - 2;

    while ($i < $snake_length - 1)
    {
        Cursor ($snake_segments_i {$i}, $snake_segments_j {$i}); 
        if ($snake_dirs {$i} == 0 || $snake_dirs {$i} == 2) 
        {
            print "\x{02D}\n";
        }
        
        if ($snake_dirs {$i} == 1 || $snake_dirs {$i} == 3) 
        {
            print "|\n";
        }
        $i++;
    }
}

clear_all ();
print_border ();

set_apple_pos ();
init_snake ();
print_snake ();

my $key;
my $count = 0;
while (1)
{
    while (not defined ($key = ReadKey(-1)))
    {
        $count++;
        if ($count > $current_turns)
        {
            clear_snake();
            move_snake ();
            print_snake ();
            $count = 0;
        }
    }
    if ($key eq "a") { if (set_current_dir (2)) { $count = 0; clear_snake (); move_snake (); print_snake (); } }
    if ($key eq "w") { if (set_current_dir (1)) { $count = 0; clear_snake (); move_snake (); print_snake (); } }
    if ($key eq "s") { if (set_current_dir (3)) { $count = 0; clear_snake (); move_snake (); print_snake (); } }
    if ($key eq "d") { if (set_current_dir (0)) { $count = 0; clear_snake (); move_snake (); print_snake (); } }
    if ($key eq "k") { grow_snake (); }
    if ($key eq "q") { exit; }
}
