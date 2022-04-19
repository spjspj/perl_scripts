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
#my $current_turns = 10000;
my $current_turns = 3000;
my $WIDTH = 60;
my $HEIGHT = 40;
my $info_str = "";

sub init_snake
{
    $snake_length = 5;
    my $i = 0;
    my $start_x = $WIDTH / 2;
    my $start_y = $HEIGHT / 2;
    
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
        #print " \n";
        print "\e[1;34m.\e[0m\n";
        $i++;
    }
}

my $next_apple_i = -1;
my $next_apple_j = -1;
sub print_apple
{
    my $i = $next_apple_i;
    my $j = $next_apple_j;
    
    Cursor ($i,$j);
    print "\e[1;35m@\e[0m\n";
}

sub outside_snake_or_border
{
    my $check_x = $_ [0];
    my $check_y = $_ [1];
    my $i = 0;
    while ($i < $snake_length - 1)
    {
        if ($snake_segments_i {$i} == $check_x && $snake_segments_j {$i} == $check_y) 
        {
            return 0;
        }
        $i++;
    }

    if ($check_x <= 1 || $check_x > $WIDTH - 1)
    {
        return 0;
    }

    if ($check_y <= 1 || $check_y > $HEIGHT - 1)
    {
        return 0;
    }

    return 1;
}

sub quadrant
{
    my $ai = $_ [0];
    my $aj = $_ [1];
    my $quadrant = 0;

    if ($ai < $WIDTH / 2)
    {
        if ($aj < $HEIGHT / 2)
        {
            $quadrant = 1;
        }
        else
        {
            $quadrant = 2;
        }
    }
    else
    {
        if ($aj < $HEIGHT / 2)
        {
            $quadrant = 0;
        }
        else
        {
            $quadrant = 3;
        }
    }
    return $quadrant;
}

my $num_apples = -1;
sub set_apple_pos
{
    my $q = quadrant ($next_apple_i, $next_apple_j);
    $next_apple_i = int (rand ($WIDTH)) + 2;
    $next_apple_j = int (rand ($HEIGHT)) + 2;
    my $q2 = quadrant ($next_apple_i, $next_apple_j);

    while ($q == $q2)
    {
        $next_apple_i = int (rand ($WIDTH)) + 2;
        $next_apple_j = int (rand ($HEIGHT)) + 2;
        $q2 = quadrant ($next_apple_i, $next_apple_j);
    }

    if (!outside_snake_or_border ($next_apple_i, $next_apple_j))
    {
        set_apple_pos ();
    }
    
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

sub do_exit
{
    Cursor (0,100);
    print ("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n");
    print ("You died (head x was $current_head_x, $current_head_y, apples eaten: $num_apples).\n");
    print ($info_str);
    open BOB, "> ./snake_analysis.txt";
    print BOB $info_str;
    close BOB;
    exit;
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
        do_exit ();
    }

    if ($snake_segments_j {$i} <= 1 || $snake_segments_j {$i} > $HEIGHT - 1)
    {
        do_exit ();
    }

    my $n;
    for ($n = 0; $n < $snake_length - 1; $n++)
    {
        if ($snake_segments_i {$i} == $snake_segments_i {$n} && $snake_segments_j {$i} == $snake_segments_j {$n})
        {
            do_exit ();
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
    my $i = $snake_length - 4;

    while ($i <= $snake_length - 2)
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
    Cursor ($snake_segments_i {$i}, $snake_segments_j {$i}); 
    print "o\n";
}

sub print_snake_positions
{
    my $i = 0;
    my $str = "";

    while ($i <= $snake_length - 1)
    {
        $str .= "$i,$snake_segments_i{$i},$snake_segments_j{$i},d=$snake_dirs{$i}\n";
        $i++;
    }
    return $str;
}

my $LAYERS_MAX = 4;
my $project_str;
sub project
{
    my $project_x = $_ [0];
    my $project_y = $_ [1];
    my $project_direction = $_ [2];
    my $layer_deep = $_ [3];
    my $str_offset = $_ [4];
    $project_str .= "$str_offset:$layer_deep:..do project: $project_x,$project_y,$project_direction(d),$layer_deep\n";

    my $is_0_ok = 1;
    my $is_1_ok = 1;
    my $is_2_ok = 1;
    my $is_3_ok = 1;
    my $num_directions_ok = 0;
 
    my $next_head_x = $project_x;
    my $next_head_y = $project_y;

    # 0 direction (right)
    $next_head_x = $project_x + 1;
    $next_head_y = $project_y;
    $is_0_ok = outside_snake_or_border ($next_head_x, $next_head_y);
    if ($project_direction == 2) { $is_0_ok = 0; $project_str .= "$str_offset:$layer_deep: ... ($project_direction vs looking at 0) Opposite of projected direction\n"; }
    if ($is_0_ok)
    {
        $project_str .= "$str_offset:$layer_deep: ... R ($project_direction): Would not ($next_head_x,$next_head_y) hit wall/self - $is_0_ok\n";
        $num_directions_ok++;
        if ($layer_deep == $LAYERS_MAX)
        {
            $project_str .= "$str_offset:$layer_deep:..... $project_x,$project_y,$project_direction(d),$layer_deep << $next_head_x,$next_head_y numdirectionsok=return $num_directions_ok\n";
        }
        else
        {
            return (project ($next_head_x, $next_head_y, 0, $layer_deep + 1, $str_offset . ">"));
        }
    }
    $project_str .= "$str_offset:$layer_deep: ... here0\n";

    # 1 direction (up)
    $next_head_x = $project_x;
    $next_head_y = $project_y - 1;
    $is_1_ok = outside_snake_or_border ($next_head_x, $next_head_y);
    if ($project_direction == 3) { $is_1_ok = 0; $project_str .= "$str_offset:$layer_deep: ... ($project_direction vs looking at 1) Opposite of projected direction\n"; }
    if ($is_1_ok)
    {
        $project_str .= "$str_offset:$layer_deep: ... U ($project_direction): Would not ($next_head_x,$next_head_y) hit wall/self - $is_1_ok\n";
        $num_directions_ok++;
        if ($layer_deep == $LAYERS_MAX)
        {
            $project_str .= "$str_offset:$layer_deep:..... $project_x,$project_y,$project_direction(d),$layer_deep << $next_head_x,$next_head_y numdirectionsok=return $num_directions_ok\n";
        }
        else
        {
            return (project ($next_head_x, $next_head_y, 1, $layer_deep + 1, $str_offset . ">"));
        }
    }
    $project_str .= "$str_offset:$layer_deep: ... here1\n";

    # 2 direction (left)
    $next_head_x = $project_x - 1;
    $next_head_y = $project_y;
    $is_2_ok = outside_snake_or_border ($next_head_x, $next_head_y);
    if ($project_direction == 0) { $is_2_ok = 0; $project_str .= "$str_offset:$layer_deep: ... ($project_direction vs looking at 2) Opposite of projected direction\n"; }
    if ($is_2_ok)
    {
        $project_str .= "$str_offset:$layer_deep: ... L ($project_direction): Would not ($next_head_x,$next_head_y) hit wall/self - $is_2_ok\n";
        $num_directions_ok++;
        if ($layer_deep == $LAYERS_MAX)
        {
            $project_str .= "$str_offset:$layer_deep:..... $project_x,$project_y,$project_direction(d),$layer_deep << $next_head_x,$next_head_y numdirectionsok=return $num_directions_ok\n";
        }
        else
        {
            return (project ($next_head_x, $next_head_y, 2, $layer_deep + 1, $str_offset . ">"));
        }
    }
    $project_str .= "$str_offset:$layer_deep: ... here2\n";

    # 3 direction (down)
    $next_head_x = $project_x;
    $next_head_y = $project_y + 1;
    $is_3_ok = outside_snake_or_border ($next_head_x, $next_head_y);
    if ($project_direction == 1) { $is_3_ok = 0; $project_str .= "$str_offset:$layer_deep: ... ($project_direction vs looking at 3) Opposite of projected direction\n"; }
    if ($is_3_ok)
    {
        $project_str .= "$str_offset:$layer_deep: ... D ($project_direction): Would not ($next_head_x,$next_head_y) hit wall/self - $is_3_ok\n";
        $num_directions_ok++;
        if ($layer_deep == $LAYERS_MAX)
        {
            $project_str .= "$str_offset:$layer_deep:..... $project_x,$project_y,$project_direction(d),$layer_deep << $next_head_x,$next_head_y numdirectionsok=return $num_directions_ok\n";
        }
        else
        {
            return (project ($next_head_x, $next_head_y, 3, $layer_deep + 1, $str_offset . ">"));
        }
    }
    $project_str .= "$str_offset:$layer_deep: ... here3\n";

    $project_str .= "$str_offset:$layer_deep:.finish. $project_x,$project_y,$project_direction(d),$layer_deep << $next_head_x,$next_head_y returning $num_directions_ok\n";
    return ($num_directions_ok);
}

my $doing_project = 0;
sub do_project
{
    $current_head_x = $snake_segments_i {$snake_length - 1};
    $current_head_y = $snake_segments_j {$snake_length - 1};
    $doing_project ++;

    my $str = "$current_head_x, $current_head_y:\n";
    $project_str = ""; $str .= "Direction right: \n";
    project ($current_head_x, $current_head_y, 0, 0, "$doing_project..");
    $str .= $project_str;
    $project_str = ""; $str .= "Direction up: \n";
    project ($current_head_x, $current_head_y, 1, 0, "$doing_project..");
    $str .= $project_str;
    $project_str = ""; $str .= "Direction left: \n";
    project ($current_head_x, $current_head_y, 2, 0, "$doing_project..");
    $str .= $project_str;
    $project_str = ""; $str .= "Direction down: \n";
    project ($current_head_x, $current_head_y, 3, 0, "$doing_project..");
    $str .= $project_str;
    return $str;
}

sub get_apple_dist_w_dir
{
    my $current_head_x = $_ [0];
    my $current_head_y = $_ [1];
    my $dist = $_ [2];

    my $hx = $current_head_x; 
    my $hy = $current_head_y; 

    if ($dist == 0) { $hx ++; } # L
    if ($dist == 1) { $hy --; } # U
    if ($dist == 2) { $hx --; } # R
    if ($dist == 3) { $hy ++; } # D

    return (abs ($next_apple_i - $hx) + abs ($next_apple_j - $hy));
}

sub auto_direction
{
    $current_head_x = $snake_segments_i {$snake_length - 1};
    $current_head_y = $snake_segments_j {$snake_length - 1};

    my $next_head_x = $snake_segments_i {$snake_length - 1};
    my $next_head_y = $snake_segments_j {$snake_length - 1};

    my $is_0_ok = 1;
    my $is_1_ok = 1;
    my $is_2_ok = 1;
    my $is_3_ok = 1;
    my $orig_current_dir = $current_dir;
    my $actual_next_x;
    my $actual_next_y;

    # 0 direction (right)
    $next_head_x = $snake_segments_i {$snake_length - 1} + 1;
    $next_head_y = $snake_segments_j {$snake_length - 1};
    $is_0_ok = outside_snake_or_border ($next_head_x, $next_head_y);
    if ($orig_current_dir == 2) { $is_0_ok = 0; }
    if ($orig_current_dir == 0) { $actual_next_x = $next_head_x; $actual_next_y = $next_head_y; }
    if ($is_0_ok) # && abs ($next_head_x - $next_apple_i) < abs ($current_head_x - $next_apple_i))
    {
        # right..
        if (project ($next_head_x, $next_head_y, 0, 0, ">") < 1)
        {
            $is_0_ok = 0;
        }
    }

    # 1 direction (up)
    $next_head_x = $snake_segments_i {$snake_length - 1};
    $next_head_y = $snake_segments_j {$snake_length - 1} - 1;
    $is_1_ok = outside_snake_or_border ($next_head_x, $next_head_y);
    if ($orig_current_dir == 3) { $is_1_ok = 0; }
    if ($orig_current_dir == 1) { $actual_next_x = $next_head_x; $actual_next_y = $next_head_y; }
    if ($is_1_ok) # && abs ($next_head_y - $next_apple_j) < abs ($current_head_y - $next_apple_j))
    {
        # up..
        if (project ($next_head_x, $next_head_y, 1, 0, ">") < 1)
        {
            $is_1_ok = 0;
        }
    }

    # 2 direction (left)
    $next_head_x = $snake_segments_i {$snake_length - 1} - 1;
    $next_head_y = $snake_segments_j {$snake_length - 1};
    $is_2_ok = outside_snake_or_border ($next_head_x, $next_head_y);
    if ($orig_current_dir == 0) { $is_2_ok = 0; }
    if ($orig_current_dir == 2) { $actual_next_x = $next_head_x; $actual_next_y = $next_head_y; }
    if ($is_2_ok) # && abs ($next_head_x - $next_apple_i) < abs ($current_head_x - $next_apple_i))
    {
        # left..
        if (project ($next_head_x, $next_head_y, 2, 0, ">") < 1)
        {
            $is_2_ok = 0;
        }
    }

    # 3 direction (down)
    $next_head_x = $snake_segments_i {$snake_length - 1};
    $next_head_y = $snake_segments_j {$snake_length - 1} + 1;
    $is_3_ok = outside_snake_or_border ($next_head_x, $next_head_y);
    if ($orig_current_dir == 1) { $is_3_ok = 0; }
    if ($orig_current_dir == 3) { $actual_next_x = $next_head_x; $actual_next_y = $next_head_y; }
    if ($is_3_ok) # && abs ($next_head_y - $next_apple_j) < abs ($current_head_y - $next_apple_j))
    {
        # down..
        if (project ($next_head_x, $next_head_y, 3, 0, ">") < 1)
        {
            $is_3_ok = 0;
        }
    }


    my $should_change = 0;
    if (abs ($actual_next_x - $next_apple_i) + abs ($actual_next_y - $next_apple_j) > abs ($current_head_x - $next_apple_i) + abs ($current_head_y - $next_apple_j))
    {
        $should_change = 1;
    }

    $info_str .= " ## $num_apples $is_0_ok,$is_1_ok,$is_2_ok,$is_3_ok (" . $snake_segments_i {$snake_length - 1} . ", " . $snake_segments_j {$snake_length - 1} . ", $snake_length)\n";
    my $done_change = 0;
    if ($should_change)
    {
        my $best = -1;
        my $dist = 100000;
        $info_str .= "   .... $should_change\n";
        if ($is_0_ok && get_apple_dist_w_dir ($current_head_x, $current_head_y, 0) < get_apple_dist_w_dir ($current_head_x, $current_head_y, $orig_current_dir))
        {
            $dist = get_apple_dist_w_dir ($current_head_x, $current_head_y, 0);
            $best = 0;
        }
        if ($is_1_ok && get_apple_dist_w_dir ($current_head_x, $current_head_y, 1) < get_apple_dist_w_dir ($current_head_x, $current_head_y, $orig_current_dir) 
            && $dist > get_apple_dist_w_dir ($current_head_x, $current_head_y, $orig_current_dir))
        {
            $dist = get_apple_dist_w_dir ($current_head_x, $current_head_y, 1);
            $best = 1;
        }
        if ($is_2_ok && get_apple_dist_w_dir ($current_head_x, $current_head_y, 2) < get_apple_dist_w_dir ($current_head_x, $current_head_y, $orig_current_dir) 
            && $dist > get_apple_dist_w_dir ($current_head_x, $current_head_y, $orig_current_dir))
        {
            $dist = get_apple_dist_w_dir ($current_head_x, $current_head_y, 2);
            $best = 2;
        }
        if ($is_3_ok && get_apple_dist_w_dir ($current_head_x, $current_head_y, 3) < get_apple_dist_w_dir ($current_head_x, $current_head_y, $orig_current_dir) 
            && $dist > get_apple_dist_w_dir ($current_head_x, $current_head_y, $orig_current_dir))
        {
            $dist = get_apple_dist_w_dir ($current_head_x, $current_head_y, 3);
            $best = 3;
        }
        if ($best > 0)
        {
            $done_change = 1;
            set_current_dir ($best);
        }
    }

    # Maybe have to turn!!
    if ($is_0_ok + $is_1_ok + $is_2_ok + $is_3_ok == 2 && $done_change == 0)
    {
        if    ($is_0_ok && $orig_current_dir % 2 == 1) { set_current_dir (0); $info_str .= "Right\n"; }
        elsif ($is_1_ok && $orig_current_dir % 2 == 0) { set_current_dir (1); $info_str .= "Up\n"; }
        elsif ($is_2_ok && $orig_current_dir % 2 == 1) { set_current_dir (2); $info_str .= "Left\n"; }
        elsif ($is_3_ok && $orig_current_dir % 2 == 0) { set_current_dir (3); $info_str .= "Down\n"; }
    }
    # Have to turn!!
    elsif ($is_0_ok + $is_1_ok + $is_2_ok + $is_3_ok == 1)
    {
           if ($is_0_ok) { set_current_dir (0); $info_str .= "must do Right\n"; }
        elsif ($is_1_ok) { set_current_dir (1); $info_str .= "must do Up\n"; }
        elsif ($is_2_ok) { set_current_dir (2); $info_str .= "must do Left\n"; }
        elsif ($is_3_ok) { set_current_dir (3); $info_str .= "must do Down\n"; }
    }

 

    if ($is_0_ok + $is_1_ok + $is_2_ok + $is_3_ok <= 1)
    {
        #$info_str .= do_project ();
    }
    
    if ($is_0_ok + $is_1_ok + $is_2_ok + $is_3_ok == 0)
    {
        $info_str .= print_snake_positions ();
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
            auto_direction ();
            move_snake ();
            print_snake ();
            $count = 0;
        }
    }
    if ($key eq "a") { if (set_current_dir (2)) { $count = 0; clear_snake (); move_snake (); print_snake (); } $info_str .= "##User pressed here\n"; }
    if ($key eq "w") { if (set_current_dir (1)) { $count = 0; clear_snake (); move_snake (); print_snake (); } $info_str .= "##User pressed here\n"; }
    if ($key eq "s") { if (set_current_dir (3)) { $count = 0; clear_snake (); move_snake (); print_snake (); } $info_str .= "##User pressed here\n"; }
    if ($key eq "d") { if (set_current_dir (0)) { $count = 0; clear_snake (); move_snake (); print_snake (); } $info_str .= "##User pressed here\n"; }
    if ($key eq "k") { grow_snake (); }
    if ($key eq "m") { $info_str .= "##User pressed here\n"; $info_str .= do_project ();}
    if ($key eq "q") { do_exit (); }
}
