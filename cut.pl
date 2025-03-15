#!/usr/bin/perl
##
#   File : cut.pl
#   Date : 11/July/2010
#   Author : spjspj
#   Purpose : Roll your own text processor
##  

use strict;
use LWP::Simple;
use Math::Trig;
use POSIX qw(strftime);
use Time::Piece;
use Time::Seconds;
use DateTime;

my $PI = 3.14159265358979323;
my %all_json_fields;

sub read_json_values
{
    my $chunk = $_ [0];
    print ("Dealing with: $chunk\n");
    my $print_it = $_ [1];
    my %json_fields;
    my $last_json_header = "";
    my $number_of_array = 0;

    # Get the headers for this chunk
    $chunk =~ s/,/,\n/img;
    $chunk =~ s/[\{\}]/\n/img;

    while ($chunk =~ s/^(.*)\n//im)
    {
        my $json_field = $1;
        
        {
            if ($json_field =~ m/"([^"]+)":"([^"]+)"/)
            {
                $last_json_header = $1;
                $json_fields {$1} = $2;
                $all_json_fields {$1} = "";
                $number_of_array = 0;
            } 
            elsif ($json_field =~ m/"([^"]+)":(.*),/)
            {
                $last_json_header = $1;
                my $val = $2;
                $json_fields {$1} = "$val";
                $all_json_fields {$1} = "";
                $number_of_array = 0;
            }
            else
            {
                $number_of_array++;
                my $numbered_field = $last_json_header . "_" . $number_of_array;
                $json_field =~ s/\W*$//;
                $json_fields {$numbered_field} = $json_field;
                $all_json_fields {$numbered_field} = "";
            }
        }
    }

    my $k;
    foreach $k (sort (keys (%all_json_fields)))
    {
        if ($print_it)
        {
            print ("$json_fields{$k},");
        }
    }
    if ($print_it)
    {
        print ("\n");
    }
}

my %all_wordle;
my %wordle_matches;
my %wordle_matches_full;
sub find_matches
{
    my $input = $_ [0];
    my $num_misses = $_ [1];
    my $term = $_ [2];
    my $level = $_ [3];
    my $max_level = $_ [4];
    my $orig_word = $_ [5];
    my @chars;
    my $i = 0;

    if ($level > $max_level)
    {
        return;
    }

    while ($input =~ s/^(.)//)
    {
        $chars [$i] = lc($1);
        $i++;
    }

    my $k;
    my $orig_k;
    foreach $k (keys (%all_wordle))
    {
        my $i = 0;
        my $count = 0;
        $orig_k = $k;

        while ($k =~ s/^(.)//)
        {
            my $ch = $1;
            if ($chars [$i] eq lc($ch))
            {
                $count++;
            }
            $i++;
        }

        if ($count == 5 - $num_misses)
        {
            if ($term eq "term")
            {
                if (lc($orig_k) eq $orig_word) { next; }
                if ($wordle_matches {$orig_k} <= 1)
                {
                    $wordle_matches {$orig_k} += 2;
                }
                print (" $level $orig_k\n");
                find_matches ($orig_k, 1, $term, $level+1, $max_level, $orig_word);
                $wordle_matches_full {$orig_k} .= ", $orig_k";
            }
            elsif ($term eq "helper")
            {
                if (lc($orig_k) eq $orig_word) { next; }
                if ($wordle_matches {$orig_k} == 2 || $wordle_matches {$orig_k} == 0)
                {
                    $wordle_matches {$orig_k} += 1;
                }
                if ($level < 3)
                {
                    print (" $level $orig_k\n");
                }
                find_matches ($orig_k, 1, $term, $level+1, $max_level, $orig_word);
                $wordle_matches_full {$orig_k} .= ", $orig_k";
            }
        }
        if ($wordle_matches {$orig_k} == 3)
        {
            print ("$level SUPER DUPER $orig_k ($wordle_matches_full{$orig_k})\n");$wordle_matches {$orig_k} += 0.1;
        }
        else
        {
            #print ("\n");
        }
    }
}

my $max_size;
sub test_url
{
    my $url = $_ [0];
    my $new_url = $_ [0];
    my $number = $_ [1];

    if ($number ne "")
    {
        $new_url =~ s/sty_\d*\./sty_$number./;
    }
    my $content = get $new_url;
    print ("Download :$new_url: got " .  length ($content) . "\n");

    if (length ($content) > 0)
    {
        if (length ($content) > $max_size)
        {
            $max_size = length ($content);
            return $new_url;
        }
    }
    print "No bigger size than $url found..\n";
    return $url;
}

my $min_size;
sub test_url_min
{
    my $url = $_ [0];
    my $new_url = $_ [0];
    my $number = $_ [1];

    if ($number ne "")
    {
        $new_url =~ s/sty_\d*\./sty_$number./;
    }
    my $content = get $new_url;

    if (length ($content) > 0)
    {
        print ("Download :$new_url: got " .  length ($content) . "\n");
        if (length ($content) < $min_size)
        {
            $min_size = length ($content);
            return $new_url;
        }
    }
    print (" zero byte Download :$new_url: got " .  length ($content) . "\n");
    return $url;
}

sub get_next_json_chunk
{
    my $line = $_ [0];
    my $json_chunk = "";
    $line =~ s/\\n//img;

    my $level = 0;
    my %ret_values;

    while ($line =~ s/^[^{]//i)
    {
    }

    if ($line !~ s/^{//i)
    {
        $ret_values {json_chunk} = "";
        $ret_values {line} = "";
        return %ret_values; 
    }

    my $keep_going = 1;
    while ($keep_going)
    {
        while ($line =~ s/^([^\{\}])//i)
        {
            $json_chunk .= $1;
        }

        if ($line =~ m/^}/ && $level == 0)
        {
            $json_chunk .= "}";
            $ret_values {json_chunk} = $json_chunk;
            $ret_values {line} = $line;
            return %ret_values;
        }

        if ($line =~ s/^{//)
        {
            $json_chunk .= "{";
            $level++;
        }
        
        if ($line =~ s/^}//)
        {
            $json_chunk .= "}";
            $level--;
        }

        $keep_going = 0;
        if ($line =~ m/^./)
        {
            $keep_going = 1;
        }
    }
}

sub print_month
{
    my $year = $_ [0];
    my $month = $_ [1];

    my $month_string = "";
    my $dt = DateTime->new(year => $year, month => $month, day => 1);
    my $day_str = " Su Mo Tu We Th Fr Sa";

    my $current_month = $dt->month_name;
    my $len_mon = length ($current_month);
    my $len_day = length ($day_str);
    my $padding = $len_day - $len_mon;
    my $x = 0;
    while ($x < $padding)
    {
        if ($x < 4)
        {
            $current_month = " $current_month";
        }
        else
        {
            $current_month = "$current_month ";
        }
        $x++;
    }

    $month_string .= "$current_month\n$day_str\n";

    my $dt = DateTime->new(year => $year, month => $month, day => 1);
    my $current_dow = $dt->day_of_week;
    if ($current_dow == 7)
    {
        $current_dow = 0;
    }
    my $i = 0;
    while ($i < $current_dow) 
    {
        $month_string .= "   ";
        $i++;
    }
    $month_string .= "  1";
    $i++;

    my $total_days_in_month;
    if ($month == 1) { $total_days_in_month = 31; }

    if ($month == 2)
    {
        $total_days_in_month = 28; 
        if ($year % 400 == 0) { $total_days_in_month = 29; }
        if ($year % 100 == 0) { $total_days_in_month = 28; }
        if ($year % 4 == 0) { $total_days_in_month = 29; }
    }

    if ($month == 3) { $total_days_in_month = 31; }
    if ($month == 4) { $total_days_in_month = 30; }
    if ($month == 5) { $total_days_in_month = 31; }
    if ($month == 6) { $total_days_in_month = 30; }
    if ($month == 7) { $total_days_in_month = 31; }
    if ($month == 8) { $total_days_in_month = 31; }
    if ($month == 9) { $total_days_in_month = 30; }
    if ($month == 10) { $total_days_in_month = 31; }
    if ($month == 11) { $total_days_in_month = 30; }
    if ($month == 12) { $total_days_in_month = 31; }

    my $day = 2;
    my $done = 0;
    while ($day < 10) 
    {
        while ($i < 7 && !$done) 
        {
            if ($day < 10) 
            {
                $month_string .= "  $day";
                $day++;
                $i++;
            }
            else
            {
                $done = 1;
            }
        }

        if (!$done)
        {
            $month_string .= "\n";
            $i = 0;
        }
    }
    
    while ($day <= $total_days_in_month) 
    {
        while ($i < 7) 
        {
            if ($day <= $total_days_in_month) 
            {
                $month_string .= " ";
                $month_string .= "$day";
            }
            else
            {
                $month_string .= "   ";
            }
            $day++;
            $i++;
        }

        if ($day <= $total_days_in_month) 
        {
            $month_string .= "\n";
        }
        $i = 0;
    }

    return $month_string . "\n";
}

my $thursday_is_payday;
sub print_month_w_payday
{
    my $year = $_ [0];
    my $month = $_ [1];
    my $public_hols_1 = $_ [2];
    my $public_hols_2 = $_ [3];
    my $public_hols_3 = $_ [4];
    my $public_hols_4 = $_ [5];

    my $month_string = "";
    my $dt = DateTime->new(year => $year, month => $month, day => 1);
    my $day_str = " Su Mo Tu We Th Fr Sa";

    my $current_month = $dt->month_name;
    my $len_mon = length ($current_month);
    my $len_day = length ($day_str);
    my $padding = $len_day - $len_mon;
    my $x = 0;
    while ($x < $padding)
    {
        if ($x < 4)
        {
            $current_month = " $current_month";
        }
        else
        {
            $current_month = "$current_month ";
        }
        $x++;
    }

    $month_string .= "$current_month\n$day_str\n";

    my $dt = DateTime->new(year => $year, month => $month, day => 1);
    my $current_dow = $dt->day_of_week;
    if ($current_dow == 7)
    {
        $current_dow = 0;
    }
    my $i = 0;
    while ($i < $current_dow) 
    {
        $month_string .= "   ";
        $i++;
    }

    my $total_days_in_month;
    if ($month == 1) { $total_days_in_month = 31; }

    if ($month == 2)
    {
        $total_days_in_month = 28; 
        if ($year % 400 == 0) { $total_days_in_month = 29; }
        elsif ($year % 100 == 0) { $total_days_in_month = 28; }
        elsif ($year % 4 == 0) { $total_days_in_month = 29; }
    }

    if ($month == 3) { $total_days_in_month = 31; }
    if ($month == 4) { $total_days_in_month = 30; }
    if ($month == 5) { $total_days_in_month = 31; }
    if ($month == 6) { $total_days_in_month = 30; }
    if ($month == 7) { $total_days_in_month = 31; }
    if ($month == 8) { $total_days_in_month = 31; }
    if ($month == 9) { $total_days_in_month = 30; }
    if ($month == 10) { $total_days_in_month = 31; }
    if ($month == 11) { $total_days_in_month = 30; }
    if ($month == 12) { $total_days_in_month = 31; }

    my $day = 1;
    my $done = 0;
    my $extra_space = " ";
    while ($day <= $total_days_in_month) 
    {
        while ($i < 7) 
        {
            if ($day <= $total_days_in_month) 
            {
                if ($i == 4)
                {
                    if ($thursday_is_payday)
                    {
                        $month_string .= "$extra_space*$day";
                        $thursday_is_payday = 0;
                    }
                    elsif ($thursday_is_payday == 0)
                    {
                        $month_string .= " $extra_space$day";
                        $thursday_is_payday = 1;
                    }
                }
                else
                {
                    $month_string .= " $extra_space$day";
                }
            }
            else
            {
                $month_string .= "   ";
            }
            $day++;
            if ($day >= 10)
            {
                $extra_space = "";
            }
            $i++;
        }

        if ($day <= $total_days_in_month) 
        {
            $month_string .= "\n";
        }
        $i = 0;
    }

    $month_string =~ s/ $public_hols_1 /#$public_hols_1 /img; 
    $month_string =~ s/ $public_hols_2 /#$public_hols_2 /img; 
    $month_string =~ s/ $public_hols_3 /#$public_hols_3 /img; 
    $month_string =~ s/ $public_hols_4 /#$public_hols_4 /img; 
    return $month_string . "\n";
}

sub add_school_holidays
{
    my $month_str = $_ [0];
    my $school_hols_start = $_ [1];
    my $school_hols_end = $_ [2];

    my $i;
    for ($i = $school_hols_start; $i <= $school_hols_end; $i++) 
    {
        $month_str =~ s/ $i([^0-9])/!$i$1/img;
        $month_str =~ s/ $i\n/!$i\n/img;
        #print ("$month_str... for $i\n");
    }
    return $month_str;
}

sub add_my_school_holidays
{
    my $month_str = $_ [0];
    my $school_hols_start = $_ [1];
    my $school_hols_end = $_ [2];

    my $i;
    for ($i = $school_hols_start; $i <= $school_hols_end; $i++) 
    {
        $month_str =~ s/ $i([^0-9])/=$i$1/img;
        $month_str =~ s/ $i\n/=$i\n/img;
        #print ("$month_str... for $i\n");
    }
    return $month_str;
}

sub possible_school_holidays
{
    my $month_str = $_ [0];
    my $school_hols_start = $_ [1];
    my $school_hols_end = $_ [2];

    my $i;
    for ($i = $school_hols_start; $i <= $school_hols_end; $i++) 
    {
        $month_str =~ s/ $i([^0-9])/"$i$1/img;
        $month_str =~ s/ $i\n/"$i\n/img;
        #print ("$month_str... for $i\n");
    }
    return $month_str;
}

sub print_months
{
    my $month1 = $_ [0];
    my $month2 = $_ [1];
    my $month3 = $_ [2];
    my $is_first = $_ [3];

    if ($is_first == 1)
    {
        print ('<html> <head> <style> .cn { font-family: "Lucida Console", "Courier New", monospace; } </style> </head> <body> <p class="cn">');
        print ("<br>\n");
    }
    while ($month1 =~ s/^(.*)\n//)
    {
        print $1 . "  ..  ";
        if ($month2 =~ s/^(.*)\n//)
        {
            print $1 . "  ..  ";
            if ($month3 =~ s/^(.*)\n//)
            {
                print $1 . "<br>\n";
            }
        }
    }
    print "<br>\n";
    if ($is_first == -1)
    {
        print ('</p></body></html>');
    }
}

sub print_months_html
{
    my $month1 = $_ [0];
    my $month2 = $_ [1];
    my $month3 = $_ [2];
    my $is_first = $_ [3];

    $month1 =~ s/ /&nbsp;/img;
    $month2 =~ s/ /&nbsp;/img;
    $month3 =~ s/ /&nbsp;/img;
    #$month1 =~ s/ /x/img;
    #$month2 =~ s/ /x/img;
    #$month3 =~ s/ /x/img;
    if ($is_first > 0)
    {
        print ('<html> <head> <style> .cn { font-family: "Lucida Console", "Courier New", monospace; } </style> </head> <body> <p class="cn">');
        print ("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;$is_first<br>\n");
    }
    while ($month1 =~ s/^(.*)\n//)
    {
        my $line = $1 . "..";
        $line =~ s/\*([\d]+)/&nbsp;<code style="background-color:powderblue;color:olivedrab">$1<\/code>/img;
        $line =~ s/#([\d]+)/&nbsp;<code style="background-color:sandybrown;color:darkslateblue">$1<\/code>/img;
        $line =~ s/!([\d]+)/&nbsp;<code style="background-color:MediumVioletRed;color:lightpurple">$1<\/code>/img;
        $line =~ s/=([\d]+)/&nbsp;<code style="background-color:purple;color:cyan">$1<\/code>/img;
        $line =~ s/"([\d]+)/&nbsp;<code style="background-color:darkblue;color:darkorange">$1<\/code>/img;
        print $line . " xxxx ";

        if ($month2 =~ s/^(.*)\n//)
        {
            my $line = $1 . "..";
            $line =~ s/\*([\d]+)/&nbsp;<code style="background-color:powderblue;color:olivedrab">$1<\/code>/img;
            $line =~ s/#([\d]+)/&nbsp;<code style="background-color:sandybrown;color:darkslateblue">$1<\/code>/img;
            $line =~ s/!([\d]+)/&nbsp;<code style="background-color:MediumVioletRed;color:lightpurple">$1<\/code>/img;
            $line =~ s/=([\d]+)/&nbsp;<code style="background-color:purple;color:cyan">$1<\/code>/img;
            $line =~ s/"([\d]+)/&nbsp;<code style="background-color:darkblue;color:darkorange">$1<\/code>/img;
            print $line . " yyyy ";

            if ($month3 =~ s/^(.*)\n//)
            {
                my $line = $1 . "<br>\n";
                $line =~ s/\*([\d]+)/&nbsp;<code style="background-color:powderblue;color:olivedrab">$1<\/code>/img;
                $line =~ s/#([\d]+)/&nbsp;<code style="background-color:sandybrown;color:darkslateblue">$1<\/code>/img;
                $line =~ s/!([\d]+)/&nbsp;<code style="background-color:MediumVioletRed;color:lightpurple">$1<\/code>/img;
                $line =~ s/=([\d]+)/&nbsp;<code style="background-color:purple;color:cyan">$1<\/code>/img;
                $line =~ s/"([\d]+)/&nbsp;<code style="background-color:darkblue;color:darkorange">$1<\/code>/img;
                print $line . " zzzz ";
            }
        }
    }
    print "<br>\n";
    if ($is_first == -1)
    {
        print ('</p></body></html>');
    }
}

sub work_out_ringing_positions
{
    my $chunk = $_ [0];

    # 2/3 position..
    if ($chunk =~ m/^.(\d)(\d).*?\n$1..$2/img)
    {
        return "two3pos^";
    }
    if ($chunk =~ m/^(\d).(\d).*?\n.$1.$2/img)
    {
        return "course ^";
    }
    if ($chunk =~ m/^(\d)..*(\d)\n.$1.*$2.\n/img)
    {
        return "scissor^";
    }
    if ($chunk =~ m/^....(\d)(\d).*?\n...$1..$2/img)
    {
        return "5-6 pos^";
    }
}

my $allup_x = 0;
my $allup_y = 0;
my $allup_z = 0;

sub do_d3_replace
{
    my $d3_lines = $_ [0];

    while ($d3_lines =~ s/([ABCDEFGHIJ])0/$1A/g) {}
    while ($d3_lines =~ s/([ABCDEFGHIJ])1/$1B/g) {}
    while ($d3_lines =~ s/([ABCDEFGHIJ])2/$1C/g) {}
    while ($d3_lines =~ s/([ABCDEFGHIJ])3/$1D/g) {}
    while ($d3_lines =~ s/([ABCDEFGHIJ])4/$1E/g) {}
    while ($d3_lines =~ s/([ABCDEFGHIJ])5/$1F/g) {}
    while ($d3_lines =~ s/([ABCDEFGHIJ])6/$1G/g) {}
    while ($d3_lines =~ s/([ABCDEFGHIJ])7/$1H/g) {}
    while ($d3_lines =~ s/([ABCDEFGHIJ])8/$1I/g) {}
    while ($d3_lines =~ s/([ABCDEFGHIJ])9/$1J/g) {}

    while ($d3_lines =~ s/0([ABCDEFGHIJ])/A$1/g) {}
    while ($d3_lines =~ s/1([ABCDEFGHIJ])/B$1/g) {}
    while ($d3_lines =~ s/2([ABCDEFGHIJ])/C$1/g) {}
    while ($d3_lines =~ s/3([ABCDEFGHIJ])/D$1/g) {}
    while ($d3_lines =~ s/4([ABCDEFGHIJ])/E$1/g) {}
    while ($d3_lines =~ s/5([ABCDEFGHIJ])/F$1/g) {}
    while ($d3_lines =~ s/6([ABCDEFGHIJ])/G$1/g) {}
    while ($d3_lines =~ s/7([ABCDEFGHIJ])/H$1/g) {}
    while ($d3_lines =~ s/8([ABCDEFGHIJ])/I$1/g) {}
    while ($d3_lines =~ s/9([ABCDEFGHIJ])/J$1/g) {}

    return $d3_lines;
}

# Main
{
    if (scalar (@ARGV) == 0 || (scalar (@ARGV) > 2 && scalar (@ARGV) < 4))
    {
        print ("xxxxxxUsage: cut.pl <file> <term> <helper> <operation>!\n");
        print (" .   File can be - list, STDIN, or an actual file\n");
        print (" .   Term can be - a regex you're looking for\n");
        print (" .   Operation can be - grep, filegrep, count, size, head, tail, strip_http, matrix_flip(for converting ringing touches!), oneupcount, allupcount, oneup, wget\n");
        print (" .   Helper is dependent on the operation you're doing.  A number for grep will go +/- that amount \n");
        print ("   cut.pl bob.txt dave 5 grep\n");
        print ("   cut.pl all_java2.java TOKEN_STARTS_HERE TOKEN_ENDS_HERE grep_between\n");
        print ("   cut.pl full_text.txt keys 0 filegrep\n");
        print ("   cut.pl d:\\xmage_decks\\jumpstart_cube_decks\\jumpstart_packs_202503.txt d:\\xmage_decks\\jumpstart_cube_decks\\jumpstart_202503.dck 0 fixjumpstart\n");
        print ("   cut.pl pbm_72.txt 0 0 ringing\n");
        print ("   dir /a:-d /b /s | find /I \"epub\" | cut.pl stdin 0 0 make_cp_bat\n");
        print ("   dir /a:-d /b /s | find /I /V \".git\" | cut.pl stdin 0 0 nobinary | cut.pl stdin 0  0 make_code_bat > bob.bat\n");
        print ("   dir /a:-d /b /s | cut.pl stdin 0 0 nobinary | cut.pl stdin 0  0 make_code_bat > bob.bat\n");
        print ("   dir /a:-d /b /s | cut.pl stdin 0 0 nobinary | cut.pl stdin 0  0 size | sort\n");
        print ("   dir /a:-d /b /s | cut.pl stdin 0  0 size | sort\n");
        print ("   cut.pl git_diff 0  0 sortn\n");
        print ("   cut.pl git_diff 0  reverse sortn\n");
        print ("   dir /a:-d /b /s | cut.pl stdin 0  0 size | sort\n");
        print ("   dir /a:-d /b /s | cut.pl stdin 0 0 nobinary | cut.pl list example  0 grep\n");
        print ("   dir /a:-d /b /s *.java | cut.pl stdin 0  0 make_code_bat > bob.bat\n");
        print ("   dir /a:-d /b /s *.xml | cut.pl stdin 0  0 make_code_bat > bob_xml.bat\n");
        print ("   cut.pl d:\\perl_programs output.*txt  7 age_dir | cut.pl list . 0 grep\n");
        print ("   cut.pl bob.txt 0 0 uniquelines \n");
        print ("   cut.pl bob.txt 0 0 countlines\n");
        print ("   dir /a:-d /b /s | cut.pl stdin 0 0 nobinary | cut.pl list 0  0 countlines\n");
        print ("   cut.pl bob.txt 0 0 numlines\n");
        print ("   dir /a:-d /b /s | cut.pl stdin 0 0 nobinary | cut.pl list 0  0 numlines | sort /n\n");
        print ("   cut.pl file 0 0 strip_http\n");
        print ("   cut.pl file 0 0 strip_html\n");
        print ("   cut.pl stdin \";;;\" \"1,2,3,4\" fields\n");
        print ("   cut.pl bob.txt 0 0 matrix_flip\n");
        print ("   cut.pl all_java14.java \"Penny Dreadful\" \"c:\\\\xmage\" egrep | cut.pl stdin \"Penny\" -1 grep\n");
        print ("   cut.pl all_xml10.xml \"Penny\" \"c:\\\\xmage\" egrep | cut.pl stdin \"Penny\" -1 grep\n");
        print ("   cut.pl bob.txt 0 0 condense   (Used for making similar lines in files smaller..)\n");
        print ("   cut.pl bob.txt 0 0 str_condense   (Used for making similar lines in files smaller..)\n");
        print ("   cut.pl stdin \"http://bob.com/a=XXX.id\" 1000 oneupcount   \n");
        print ("   echo \"1\" | cut.pl stdin \"20240101\" 7 weekcount\n");
        print ("   cut.pl stdin \"XXX, YYY, ZZZ\" \"255,0,10,25\" allupcount   \n");
        print ("   type xyz.txt | cut.pl stdin '' 1000 oneup\n");
        print ("   cut.pl all_java9.java 0 0 get_strings > _all_strings5.txt\n");
        print ("   cut.pl stdin \"http://bob.com/a=XXX.id\" 1000 oneupbinary\n");
        print ("   cut.pl stdin \"http://bob.com/a=XXXXXXXXXXXXXXXXXXXXXX.id\" 1000 zerofilledbinary\n");
        print ("   cut.pl stdin \"http://www.comlaw.gov.au/Details/XXX\" 1000 wget\n");
        print ("   cut.pl stdin \"http://gatherer.wizards.com/Pages/Card/Details.aspx?multiverseid=XXX\"  5274 oneupcount\n");
        print ("   cut.pl stdin \"http://gatherer.wizards.com/Pages/Card/Details.aspx?multiverseid=XXX'  5274 wget\n");
        print ("   cut.pl stdin \"https://www.theadvocate.com.au/story/7672889/could-i-have-had-covid-and-not-realised-it/'  1 wget\n");
        print ("   cut.pl  modern_bluesa \";;;\" \"0,7\" fields | cut.pl stdin \";;;\" 3 wordcombos\n");
        print ("   cut.pl  modern_bluesa \";;;\" \"0,7\" fields | cut.pl stdin 0 0 uniquewords\n");
        print ("   cut.pl  modern_bluesa \";;;\" \"0,2\" images_html\n");
        print ("   cut.pl d:/D_Downloads/ip_info.html 0 0 one_url_per_line\n");
        print ("   cut.pl  stdin start_ _end letters\n");
        print ("   cut.pl  file banner hashmod word2word\n");
        print ("   cut.pl all_java21.java  thing_to_search xxxxxx egrep | cut.pl stdin thing_to_search -1 grep    rem for search_in_output..\n");
        print ("   echo \"1\" | cut.pl stdin 0 0 git\n");
        print ("   echo \"1\" | cut.pl stdin colorizing 0 gitgrep\n");
        print ("   echo \"1\" | cut.pl stdin knack grate flipple\n");
        print ("   cut.pl pj_d3_advent_code.txt  0 0 d3_code\n");
        print ("   cut.pl all_java.java  \"thing_to_search\" 0 search_in_output\n");
        print ("   cut.pl all_java.java  \"thing_to_search\" 0 edit_files\n");
        print ("   echo \"1\" | cut.pl stdin 0 0 sinewave\n");
        print ("   echo \"1\" | cut.pl stdin 2024 1 calendar_pay\n");
        print ("   echo \"1\" | cut.pl stdin 2025 0 calendar_pay\n");
        print ("   echo \"1\" | cut.pl stdin 2026 1 calendar_pay\n");
        print ("   echo \"1\" | cut.pl stdin 2027 0 calendar_pay\n");
        print ("   echo \"1\" | cut.pl stdin 2028 1 calendar_pay\n");
        print ("   echo \"1\" | cut.pl stdin 0 0 palindrome\n");
        print ("   echo \"1\" | cut.pl stdin 0 0 water\n");
        print ("   echo \"1\" | cut.pl stdin 0  0 find_and_copy_missing # looks for missing.txt in directory..\n");
        print ("   cut.pl xyz.json 0 0 json_to_csv\n");
        print ("   cut.pl xyz.json 0 0 fix_json_field\n");
        print ("  SHORTCUTS:\n");
        print ("   cut.pl code\n");
        print ("   cut.pl all_java4.java search_term (will do a search_in_output)\n");
        print ('   echo ""   | cut.pl stdin "http://www.slightlymagic.net/forum/viewtopic.php?f=70&t=4554&start=30" 0 wget');
        print ("\n");
        print ("   cut.pl all_java.java \"\\\+\\\+\\\+\\\+\" \"extends token\" cut_on_first_display_with_second\n\n");
        print ("\n");
        print ('\necho "" | cut.pl stdin "http://www.slightlymagic.net/forum/viewtopic.php?f=70&t=14062&start=XXX" 400 oneupcount | cut.pl stdin "XXX" 400 wget\n');
        print ("\n");
        print ('dir /a:-d /b /s *.jar | cut.pl stdin "^" "7z l -r \""  replace | cut.pl stdin "$" "\"" replace > d:\temp\xyz.bat');
        print ("\n");
        print ('echo "1" | cut.pl stdin "http://gatherer.wizards.com/Handlers/Image.ashx?multiverseid=16431&type=card" "6ED/Phantasmal Terrain.full.jpg" wget_image');
        print ("\n");
        print ('echo "1" | cut.pl stdin "Bob Smith" 0 get_ringer_details');
        print ("\n");
        print ('echo "1" | cut.pl stdin "http://mtgoclientdepot.onlinegaming.wizards.com/Graphics/Cards/Pics/134052_typ_reg_sty_010.jpg" "2XM\Mana Crypt.jpg" wget_image');
        print ("\n");
        print ('echo "1" | cut.pl stdin 1 "HermanCainAward" get_reddit\n');
        print ("\n");
        print ('echo "1" | cut.pl stdin "gwub,rgwu,yrgw,ybwg,uywr" "1100,1200,1120,1120,1200" master_mind');
        print ("\n");
        print ('echo "1" | cut.pl stdin "ryry,ugug,ggww,wgrg,ugyw" "1000,2200,1200,1120,1120" master_mind');
        print ("\n");
        print ('echo "1" | cut.pl stdin "1,2,3,4,5" "stuff?" replace_maths');
        print ("\n");
        exit 0;
    }

    my $file;
    my $term;
    my $helper;
    my $operation;
    my %json_headers;
    my $last_line;
    my %output_fields;
    
    my $ot_ringing;
    my $tf_ringing;
    my $fs_ringing;
    my $se_ringing;
    my $nt_ringing;
    my $first_d3_line;
    my $d3_line_length;
    my $d3_lines;
    my $d3_p2_equation;

    my %calls;
    my $slopes;
    my $call_number = 0;

    if (scalar (@ARGV) == 1)
    {
        my $shortcut = $ARGV [0];
        if ($shortcut =~ m/code/i)
        {
            print ("Running make_code_bat. Run bob.bat!\n");
            print ("dir /a:-d /b /s | cut.pl stdin 0 0 nobinary | cut.pl stdin 0  0 make_code_bat > bob.bat\n");
            `dir /a:-d /b /s | cut.pl stdin 0 0 nobinary | cut.pl stdin 0  0 make_code_bat > bob.bat`;
            exit;
        }
    }
    elsif (scalar (@ARGV) == 2)
    {
        my $file = $ARGV [0];
        my $term = $ARGV [1];
        if ($file =~ m/all/i)
        {
            print ("Running search_in_output!\n");
            print ("   cut.pl $file  \"$term\" 0 search_in_output\n");
            `cut.pl $file  \"$term\" 0 search_in_output`;
            exit;
        }
    }
    else
    {
        $file = $ARGV [0];
        $term = $ARGV [1];
        $helper = $ARGV [2];
        $operation = $ARGV [3];
        #print "Starting incoming operators: $0 >$file< >$term< >$helper< >$operation<\n";
    }

    my %combos;
    my %all_combos;
    my %dedup_line_hash;
    my $in_between_lines = 0;

    # For search_in_output
    my $last_file = "";
    my $print_last_file = 0;

    if ($file eq "list" && $operation ne "size")
    {
        while (<STDIN>)
        {
            chomp $_;
            my $file = $_;
            my $found_output = 0;
            #print "cut.pl $file $term $helper $operation |\n";
            open PROC, "cut.pl $file $term $helper $operation |";
            print "Running: cut.pl $file $term $helper $operation |\n";
            while (<PROC>)
            {
                if ($found_output == 0)
                {
                    print ("\n\n==================\nProcessing file: $file\n");
                    $found_output = 1;
                }
                print ($_);
            }
            if ($found_output > 0)
            {
                print ("\n******************xx\n");
            }
            close PROC;
        }
       
        exit;
    }

    if ($file eq "stdin")
    {
        open FILE, "-";
    }
    elsif ($operation eq "strip_http")
    {
        open FILE, "$file";
        binmode (FILE);
    }
    elsif ($operation ne "age_dir")
    {
        open FILE, "$file";
    }
    elsif ($operation ne "find_in_all")
    {
        $operation = "grep";
        $term = "($term|\+\+\+\+)";
        open FILE, "$file";
    }

    my $current_file = '';
    my $dot_current_file = '';
    my $in_file = 0;
    my $num_files = 0;

    # size functions!
    my $total_size = 0;

    # OldGrep functions!
    my %grep_past_lines;
    my $grep_past_lines_index  = 1;
    my $grep_forward_lines = -1;

    # Grep variables:
    # Before and or after!
    my $before = 0;
    my $before_index = 0;
    my $after = 0;
    my $orig_after = 0;
    my $after_index = 0;
    my @before_lines;
    my @after_lines;

    # Grep variables:
    # Check before all the time (from first line), but only checkafter after the first line is matched!
    my $use_before = 0;
    my $use_after = 0;
    my $num_lines_after = 0;

            if ($helper =~ m/^\d+$/)
            {
                $before = $helper;
                $use_before = 1;
                if ($helper eq "0")
                {
                    $use_before = 0;
                }
                $after = 0;
                $use_after = 1;
                $orig_after = $helper;
            }
            elsif ($helper =~ m/^-\d+/)
            {
                $before = -1 * $helper;
                $use_before = 1;
            }
            elsif ($helper =~ m/^\+\d+/)
            {
                $after = 0;
                $orig_after = $helper;
                $use_after = 1;
            }

    # Count functions!
    my $count = 1;
    my $seen_http = 0;
    my $lines_http = 0;
    my %matrix_flip;
    my $matrix_row = 0;
    my $matrix_col = 0;
    my $max_matrix_col = 0;
    my $condense_begin = 1;
    my $condense_line = "";
    my $condense_start = "";
    my $condense_regex = "";
    my $condense_count = 0;
    my $line_number = 0;
    my %transpose_chars;

    if ($operation eq "oneupcount")
    {
        my $i = 0;
        for ($i = 0; $i < $helper; $i ++)
        {
            my $l = $term;
            $l =~ s/XXX/$i/img;
            print ("$l\n");
        }
        exit;
    }

    if ($operation eq "weekcount")
    {
        my $i = 0;
        my $now = time();
        my $yyyymmdd;
        for ($i = 0; $i < 100; $i ++)
        {
            $yyyymmdd = strftime "%Y%m%d", localtime($now - $i*$helper * 24*3600);
            print ("$yyyymmdd\n");
        }

        $now = $now - $i * $helper * 24*3600;

        for ($i = 0; $i < 500; $i++)
        {
            $yyyymmdd = strftime "%Y%m%d", localtime($now + $i*$helper * 24*3600);
            print ("$yyyymmdd\n");
        }
        exit;
    }
    
    if ($operation eq "do_circle")
    {
        my $x = 50;
        for (my $i = 0; $i < $x; $i++)
        {
            my $rads = $PI / $x * $i;
            my $x_pos = cos($rads) * 0.5;
            my $y_pos = sin($rads) * 0.5;
            $x_pos =~ s/\.(\d\d\d)\d.*/.$1f/;
            $y_pos =~ s/\.(\d\d\d)\d.*/.$1f/;
            print ("$x_pos, $y_pos, 0f,\n");
        }
        exit;
    }
    
    if ($operation eq "oneupbinary")
    {
        my $i = 0;
        for ($i = 0; $i < $helper; $i ++)
        {
            my $l = $term;
            my $val = sprintf ("%b", $i);
            $l =~ s/XXX/$val/;
            print $l, "\n";
        }
        exit;
    }
    
    if ($operation eq "zerofilledbinary")
    {
        my $i = 0;
        for ($i = 0; $i < $helper; $i ++)
        {
            my $l = $term;
            my $val = sprintf ("%b", $i);
            my $ll = length ($val);
            $l =~ s/(X+)X{$ll}/$1$val/;
            $l =~ s/X/0/g;
            print $l, "\n";
        }
        exit;
    }

    if ($operation eq "wget_seed")
    {
        my $i;
        for ($i = 10; $i < $helper + 10; $i++)
        {
            my $url = $term;
            $url = "http://gatherer.wizards.com/Pages/Card/Details.aspx?action=random";
            my $content = get $url;
            $content =~ s/\s\s/ /gim;
            $content =~ s/\s\s/ /gim;
            $content =~ s/\n//gim;
            $content =~ s/.*multiverseid=(\d+).*/$1/gim;

            print "$content\n";
        }
    }

    my %kkks;
    if ($operation eq "filegrep")
    {
        open KEYS, "$term";
        while (<KEYS>)
        {
            chomp;
            $kkks {"^$_"} = 1;
        }
    }

    if ($operation eq "fixjumpstart")
    {
        print "type $file\n";
        print "type $term\n";
        my $actual_decks = `type $file`;
        my $updated_cards = `type $term`;
        #print $updated_cards;
        my %cards;

        while ($updated_cards =~ s/^(.*?)\n//m)
        {
            my $card = $1;
            #print "   ----> $card\n";
            if ($card =~ m/1 [\[]*(.*?)[ :](.*?)[\]]* (.*) *$/)
            {
                my $cn = $3;
                my $set = $1;
                my $number = $2;
                $number =~ s/\*//img;
                #print ("$cn ==> $set $number\n");
                $cards {$cn} = "$set $number";
            }
        }

        while ($actual_decks =~ s/^(.*?)\n//m)
        {
            my $card = $1;
            $card =~ s/ *$//;
            if ($card =~ m/1 [\[]*(.*?)[ :](.*?)[\]]* (.*) *$/)
            {
                my $cn = $3;
                my $set = $1;
                my $number = $2;
                $number =~ s/\*//img;
                if ("$set $number" ne $cards{$cn} && $cn ne "Plains" && $cn ne "Island" && $cn ne "Swamp" && $cn ne "Mountain" && $cn ne "Forest")
                {
                    #print (" >>$cn<< ==> '$set $number' vs '$cards{$cn}'\n");
                    my $old = "$set $number";
                    my $new = $cards {$cn};
                    $card =~ s/$old/$new/;
                }
            }
            print $card, "\n";
        }
        #while ($actual_decks = `type $file`;
    }

    if ($operation eq "flipple")
    {
        open WORDLE, "d:\\perl_programs\\wordle_words.txt";
        while (<WORDLE>)
        {
            chomp;
            $all_wordle {$_} = 1;
        }

        print ("Term $term:\n=======================\n");
        find_matches ($term, 1, "term", 1, 3, lc($term));
        print ("Helper $helper:\n=======================\n");
        find_matches ($helper, 1, "helper", 1, 3, lc($helper));
    }

    if ($operation eq "make_code_bat")
    {
        print ("\@echo off\n");
    }

    if ($operation eq "get_ringer_details")
    {
        # example "curl https://bb.ringingworld.co.uk/search.php?ringer=Bob+Smith"
        my $name = $term;
        $name =~ s/ /\+/g; 
        my $curl_command = "D:\\perl_programs\\curl.exe \"https://bb.ringingworld.co.uk/search.php?ringer=$name\"";
        print $curl_command, "\n";
        my $content = `$curl_command`;
        $content =~ s/<a href=.*?view.php.id=(\d+).*?>/<>performance = $1\n<>/img;
        $content =~ s/</\n</img;
        $content =~ s/<[^>]+>/<>/img;
        $content =~ s/^<>\n//img;
        $content =~ s/<>(Sunday|Monday|Tuesday|Wednesday|Thursday|Friday|Saturday).*/mehdate/img;
        my %qpeals;
        my %peals;
        my %places;
        my $total_peals = 0;
        my $total_qpeals = 0;

        $peals {"maximus"} = 0;
        $peals {"cinques"} = 0;
        $peals {"royal"} = 0;
        $peals {"caters"} = 0;
        $peals {"major"} = 0;
        $peals {"triples"} = 0;
        $peals {"minor"} = 0;
        $peals {"doubles"} = 0;
        
        $qpeals {"maximus"} = 0;
        $qpeals {"cinques"} = 0;
        $qpeals {"royal"} = 0;
        $qpeals {"caters"} = 0;
        $qpeals {"major"} = 0;
        $qpeals {"triples"} = 0;
        $qpeals {"minor"} = 0;
        $qpeals {"doubles"} = 0;

        # NAME;EMAIL;PHONENUM;TotalPeals;TotalQPs;P12;P11;P10;P9;P8;P7;P6;P5;QP12;QP11;QP10;QP9;QP8;QP7;QP6;QP5;Place;SecondPlace
        while ($content =~ s/<>[56789]\d\d\d (.*)//)
        {
            my $method = $1;
            $peals {"info:" . $method} ++;
            $total_peals++;
            if ($method =~ m/maximus/im) { $peals {"maximus"}++; }
            if ($method =~ m/cinques/im) { $peals {"cinques"}++; }
            if ($method =~ m/royal/im) { $peals {"royal"}++; }
            if ($method =~ m/caters/im) { $peals {"caters"}++; }
            if ($method =~ m/major/im) { $peals {"major"}++; }
            if ($method =~ m/triples/im) { $peals {"triples"}++; }
            if ($method =~ m/minor/im) { $peals {"minor"}++; }
            if ($method =~ m/doubles/im) { $peals {"doubles"}++; }
        }
        while ($content =~ s/<>[1234]\d\d\d (.*)//)
        {
            my $method = $1;
            $qpeals {"info:" . $method} ++;
            $total_qpeals++;
            
            if ($method =~ m/maximus/im) { $qpeals {"maximus"}++; }
            if ($method =~ m/cinques/im) { $qpeals {"cinques"}++; }
            if ($method =~ m/royal/im) { $qpeals {"royal"}++; }
            if ($method =~ m/caters/im) { $qpeals {"caters"}++; }
            if ($method =~ m/major/im) { $qpeals {"major"}++; }
            if ($method =~ m/triples/im) { $qpeals {"triples"}++; }
            if ($method =~ m/minor/im) { $qpeals {"minor"}++; }
            if ($method =~ m/doubles/im) { $qpeals {"doubles"}++; }
        }
        while ($content =~ s/<>(.*(Australia|United Kingdom|United States|Singapore|South Africa|Canada|New Zealand|NSW|New South Wales|Victoria|South Australia|Queensland|Capital Territory|Western Australia|Tasmania|Northern Territory))//)
        {
            $places {$1} ++;
            print (">>> working out places >$1< ($places{$1})\n");
        }

        my $peal;
        my $ptext = "important:Total of $total_peals peals\n";
        foreach $peal (sort keys (%peals))
        {
            if ($peals {$peal} > 0)
            {
                $ptext .= $peal . ": $peals{$peal}\n";
            }
        }
        my $qpeal;
        my $qptext = "important:Total of $total_qpeals quarter peals\n";
        foreach $qpeal (sort keys (%qpeals))
        {
            if ($qpeals {$qpeal} > 0)
            {
                $qptext .= $qpeal . ": $qpeals{$qpeal}\n";
            }
        }
        my $places;
        my $number_one_place = -15;
        my $number_two_place = -15;
        my $place;
        my $common_place = "";
        my $second_common_place = "";
        foreach $place (sort keys (%places))
        {
            if ($places {$place} > $number_two_place && $places {$place} <= $number_one_place)
            {
                $number_two_place = $places {$place};
                $second_common_place = $place . "($number_two_place)";
            }
            if ($places {$place} > $number_one_place)
            {
                print (">> $number_one_place, will be surpassed by $places{$place} > $second_common_place\n");
                print ("> NEW: $common_place\n");
                $number_two_place = $number_one_place;
                $second_common_place = $common_place;

                $number_one_place = $places {$place};
                $common_place = $place . "($number_one_place)";
            }
            $places .= "$place\n";
        }

        print ("important:Ringer: $term\nPeals: $ptext\nQPs: $qptext\nPlaces: $places\nimportant:End for ringer: $term");
        print ("\nHEADER CSV format: NAME;EMAIL;PHONENUM;TotalPeals;TotalQPs;P12;P11;P10;P9;P8;P7;P6;P5;QP12;QP11;QP10;QP9;QP8;QP7;QP6;QP5;Place;SecondPlace\n");
        print ("\nFULL CSV format: $term;EMAILhere;PHONENUMhere;$total_peals;$total_qpeals;maximus:$peals{maximus};cinques:$peals{cinques};royal:$peals{royal};caters:$peals{caters};major:$peals{major};triples:$peals{triples};minor:$peals{minor};doubles:$peals{doubles};maximus:$qpeals{maximus};cinques:$qpeals{cinques};royal:$qpeals{royal};caters:$qpeals{caters};major:$qpeals{major};triples:$qpeals{triples};minor:$qpeals{minor};doubles:$qpeals{doubles};$common_place;$second_common_place\n");
        print ("\nCSV format: $term;EMAILhere;PHONENUMhere;$total_peals;$total_qpeals;$peals{maximus};$peals{cinques};$peals{royal};$peals{caters};$peals{major};$peals{triples};$peals{minor};$peals{doubles};$qpeals{maximus};$qpeals{cinques};$qpeals{royal};$qpeals{caters};$qpeals{major};$qpeals{triples};$qpeals{minor};$qpeals{doubles};$common_place;$second_common_place\n");
        print ("\nALTERNATE CSV format: TotalPeals;TotalQPs;NAME;EMAIL;PHONENUM;TotalPeals;TotalQPs;P12;P11;P10;P9;P8;P7;P6;P5;QP12;QP11;QP10;QP9;QP8;QP7;QP6;QP5;Place;SecondPlace\n");
        print ("\nALT CSV format: $total_peals;$total_qpeals;$term;EMAILhere;PHONENUMhere;$total_peals;$total_qpeals;$peals{maximus};$peals{cinques};$peals{royal};$peals{caters};$peals{major};$peals{triples};$peals{minor};$peals{doubles};$qpeals{maximus};$qpeals{cinques};$qpeals{royal};$qpeals{caters};$qpeals{major};$qpeals{triples};$qpeals{minor};$qpeals{doubles};$common_place;$second_common_place\n");
    }

    if ($operation eq "get_ringer_details_who_rung_with")
    {
        # example "curl https://bb.ringingworld.co.uk/search.php?ringer=Bob+Smith"
        # >> Example https://bb.ringingworld.co.uk/view.php?id=1334940
        my $name = $term;
        $name =~ s/ /\+/g; 
        my $file_name = $name;
        $file_name =~ s/\W//img;
        my $curl_command = "D:\\perl_programs\\curl.exe \"https://bb.ringingworld.co.uk/search.php?ringer=$name\" > $file_name.html";
        my $read_from_curl_command = "type $file_name.html";
        if (!(-f "$file_name.html"))
        {
            `$curl_command`;
            print "\n\n\n\nRunning:\n" . $curl_command, "\n";
        }
        my $content = `$read_from_curl_command`;
        #my $content = `type sj.html`;
        $content =~ s/</\n</img;
        $content =~ s|view.php|\nhttps://bb.ringingworld.co.uk/view.php|img;
        $content =~ s/https/\nhttps/img;
        $content =~ s/(https.*?id=\d+)/\n$1\n/img;
        #$content =~ s/^[^h].*?\n//img;
        # >> Example https://bb.ringingworld.co.uk/view.php?id=1334940
        #print $content;
        my %people_rung_with;

        while ($content =~ s/(https.*?id=\d+)//)
        {
            my $url = $1;
            print ("Performance: $url\n");   
            my $peformance_curl_command = "D:\\perl_programs\\curl.exe \"$url\"";
            my $peformance_content = `$peformance_curl_command`;
            $peformance_content =~ s/ringer persona/\nperson/img;
            while ($peformance_content =~ s/person">(.*?)<.*?\n//)
            {
                my $person = $1;
                print ("$url --- $person\n");
                $people_rung_with {$person} ++;
            }
        }

        print (">>>>>>>>>>>>>>>\n");
        my $k;
        foreach $k (sort (keys (%people_rung_with)))
        {
            print ("$k -- $people_rung_with{$k}\n");
        }
        print (">>>>>>>>>>>>>>>\n");
    }
    
    my %ulines;
    my $ulines_count = 0;
    my $oneup = 0;
    my @cut_on_term;
    my $saw_helper_cut_on_term = 0;

    my $latest_file_name;
    my %strings_in_files;
    my %files_to_strings;
    my %count_of_files_to_strings;

    my $transpose_biggest_line = 0;
    my $transpose_biggest_col = 0;
    
    while (<FILE>)
    {
        chomp $_;
        my $line = $_;
        $line_number++;

        if ($operation eq "grepold")
        {
            if ($line !~ m/$term/i && $grep_forward_lines < 0)
            {
                $grep_past_lines {$grep_past_lines_index} = $line;
                $grep_past_lines_index ++;
                if ($grep_past_lines_index > $helper)
                {
                    $grep_past_lines_index = 1;
                }
            }
            elsif ($line =~ m/$term/i)
            {
                my $i = $grep_past_lines_index;
                if (defined ($grep_past_lines {$i}))
                {
                    print $grep_past_lines {$i}, " --- 22222\n";
                }

                $i++;
                if ($i > $helper) { $i = 1; }

                while ($i != $grep_past_lines_index)
                {
                    if (defined ($grep_past_lines {$i}))
                    {
                        print $grep_past_lines {$i}, " --- 33333\n";
                    }
                    $i ++;
                    if ($i > $helper) { $i = 1; }
                }
                print "\n", $line, "\n";
                my %new_hash;
                %grep_past_lines = %new_hash;
                $grep_past_lines_index = 1;
                $grep_forward_lines = $helper + 1;
            }
           
            if ($grep_forward_lines <= $helper && $grep_forward_lines > 0)
            {
                print $line, "  --- 44444\n";
            }
            $grep_forward_lines--;
            if ($grep_forward_lines == 0)
            {
                print "\n";
            }
        }

        if ($operation eq "wget")
        {
            my $i;
            {
                my $url = $term;
                $url =~ s/XXX/$line/;
                print ("Looking at :$url:\n");
                my $content = get $url;
                die "Couldn't get $url" unless defined $content;
                $content =~ s/\s\s/ /gim;
                $content =~ s/\s\s/ /gim;
                $content =~ s/\n//gim;

                print $url, "\n\n\n\n\n", "=========>> $line <<========\n", $content, "============\n";
            }
        }
        
        if ($operation eq "mtgfcurl" && $term =~ m/https:\/\//)
        {
                my $url = $term;
                print ("==============================\n");
                print ("Looking at :$url:\n");
                my $curl_command = "D:\\perl_programs\\curl.exe -L -H \"user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.182 Safari/537.36\"  \"$term\"";
                my $content = `$curl_command`;
                $content =~ s/\s\s/ /gim;
                $content =~ s/\s\s/ /gim;
                $content =~ s/\n//gim;
                $content =~ s/-//gim;
                $helper =~ s/-//gim;
                print "\nChecking for >>$helper<<\n";
                #print ">>>> Content $content\n";
                if ($content =~ m/(.............................................$helper..................................)/img)
                {
                    print "Found (for $helper for $term) -- $1\n";
                }
        }
        if ($operation eq "curl" && $term =~ m/https:\/\//)
        {
            my $i;
            {
                my $url = $term;
                print ("Looking at :$url:\n");
                my $curl_command = "D:\\perl_programs\\curl.exe -L -H \"user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.182 Safari/537.36\"  \"$term\"";
                print $curl_command;
                my $content = `$curl_command`;
                $content =~ s/\s\s/ /gim;
                $content =~ s/\s\s/ /gim;

                print $url, "\n\n\n\n\n", "=========>> $term <<========\n", $content, "======>> $curl_command <<======\n";
            }
        }
        elsif ($operation eq "curl")
        {
            my $i;
            {
                my $url = $term;
                $url =~ s/XXX/$line/;
                print ("Looking at :$url:\n");
                my $curl_command = "D:\\perl_programs\\curl.exe -L -H \"user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.182 Safari/537.36\"  \"$line\"";
                print $curl_command;
                my $content = `$curl_command`;
                $content =~ s/\s\s/ /gim;
                $content =~ s/\s\s/ /gim;
                $content =~ s/\n//gim;
                $content =~ s/People who viewed.*//gim;
                $content =~ s/(address|price|latitude|longitude|locality)/\n$1/gim;

                print $url, "\n\n\n\n\n", "=========>> $line <<========\n", $content, "======>> $curl_command <<======\n";
            }
        }

        if ($operation eq "wget_image_test" || $operation eq "wget_image_test_max" || $operation eq "wget_image_test_force")
        {
            my $i;
            {
                # Force to get maximum..
                if ($operation eq "wget_image_test_force")
                {
                    `del "$helper"`;
                }

                if (-f "$helper")
                {
                    $max_size = -s "$helper";
                    print ("Max size for $helper is set to $max_size\n");
                    if ($max_size > 25000) 
                    {
                        print ("Probably biggest already..\n");
                        exit;
                    }
                }

                {
                    my $url = $term;
                    my $new_url = "";
                    my $content;

                    $new_url = test_url ($url, "");
                    $new_url = test_url ($new_url, "001");
                    $new_url = test_url ($new_url, "010");
                    $new_url = test_url ($new_url, "013");
                    $new_url = test_url ($new_url, "020");
                    $new_url = test_url ($new_url, "030");
                    $new_url = test_url ($new_url, "035");
                    $new_url = test_url ($new_url, "040");
                    $new_url = test_url ($new_url, "050");
                    print ("Final URL: $new_url\n");
                    $content = get $new_url;

                    if (length ($content) == 0)
                    {
                        $new_url =~ s/typ_.*/typ_flip_sty_013.jpg/;
                        $new_url = test_url ($new_url, "013");
                        $content = get $new_url;
                        print ("flip? $new_url, " . length ($content) . "\n");
                    }
                    print ("222222 flip? $new_url, " . length ($content) . "\n");

                    if (length ($content) == 0)
                    {
                        $new_url =~ s/typ_.*/typ_planeswk_sty_030.jpg/;
                        $new_url = test_url ($new_url, "030");
                        $new_url = test_url ($new_url, "040");
                        $content = get $new_url;
                    }

                    if (length ($content) == 0)
                    {
                        print ("ZERO SIZE for $helper\n");
                        exit;
                    }

                    print ("Save in $helper\n");
                    open OUTPUT, "> " . $helper or die "No dice!";
                    binmode (OUTPUT);
                    print OUTPUT $content;
                    close OUTPUT;
                    print $url, " >>> ", $helper, "\n";
                }
                #{
                #    print ("Found $helper existed already..\n");
                #}
            }
        }

        if ($operation eq "get_reddit")
        {
            my $now = time ();
            my $pull = 0;
            my $starttime = $now;
            my $content;

            for ($starttime = $now; $starttime > $now - ($term * 24 * 3600); $starttime -= 24 * 3600)
            {
                my $endtime = $starttime + 10800;  
                my $url = "http://api.pushshift.io/reddit/search/submission/?subreddit=$helper&sort=asc&size=100&filter=id,author,full_link,link_flair_text,created_utc,is_robot_indexable&before=$endtime&after=$starttime";
                my $content = get $url;
                my $orig_content = $content;
                $content =~ s/\n//img;
                $content =~ s/\{/\n\{/img;
                $content =~ s/  / /img;
                $content =~ s/  / /img;
                $content =~ s/  / /img;
                $content =~ s/  / /img;
                $content =~ s/  / /img;
                my $yyyymmdd = strftime "%Y%m%d %H", localtime($starttime);
                print "\n......$yyyymmdd ($url)\n";
                my $ln = 0;
                while ($content =~ s/^(.*?)\n//m)
                {
                    my $line = $1;
                    $ln++;
                    print ("..........$ln  --- $line\n");
                }
                $ln++;
                print ("..........$ln  --- $content\n");
                $ln --;
                $ln --;
                print ("$yyyymmdd found $ln entries\n");

            }
        }

        if ($operation eq "wget_image_test_min")
        {
            my $i;
            {
                if (-s "$helper" == 0)
                {
                    `del "$helper"`;
                }

                if (!(-f "$helper"))
                {
                    my $url = $term;
                    my $new_url = "";
                    my $content;
                    $min_size = 5000000000;

                    $new_url = test_url_min ($url, "");
                    $new_url = test_url_min ($new_url, "001");
                    $new_url = test_url_min ($new_url, "010");
                    $new_url = test_url_min ($new_url, "013");
                    $new_url = test_url_min ($new_url, "020");
                    $new_url = test_url_min ($new_url, "030");
                    $new_url = test_url_min ($new_url, "035");
                    $new_url = test_url_min ($new_url, "040");
                    $new_url = test_url_min ($new_url, "050");
                    print ("Final URL: $new_url\n");
                    $content = get $new_url;

                    if (length ($content) == 0)
                    {
                        $new_url =~ s/typ_.*/typ_flip_sty_013.jpg/;
                        $new_url = test_url ($new_url, "013");
                        $content = get $new_url;
                        print ("flip? $new_url, " . length ($content) . "\n");
                    }
                     print ("222222 flip? $new_url, " . length ($content) . "\n");

                    if (length ($content) == 0)
                    {
                        $new_url =~ s/typ_.*/typ_planeswk_sty_030.jpg/;
                        $new_url = test_url ($new_url, "030");
                        $new_url = test_url ($new_url, "040");
                        $content = get $new_url;
                    }

                    print ("Save in $helper\n");
                    open OUTPUT, "> " . $helper or die "No dice!";
                    binmode (OUTPUT);
                    print OUTPUT $content;
                    close OUTPUT;
                    print $url, " >>> ", $helper, "\n";

                    $content = get $new_url;
                    #if (length ($content) == 0)
                    {
                        # typ_flip_sty_013.jpg
                        # typ_planeswk_sty_030.jpg
                        # typ_planeswk_sty_040.jpg
                        # typ_emblem_sty_040.jpg << don't care..
                        # typ_planeswk_artclip.png << don't care..
                        # typ_reg_sty_001.jpg *
                        # typ_reg_sty_010.jpg *
                        # typ_reg_sty_020.jpg *
                        # typ_reg_sty_030.jpg *
                        # typ_reg_sty_035.jpg *
                        # typ_reg_sty_050.jpg *
                        # typ_reg_sty_artclip.png << don't care..
                        # typ_van_sty_040.jpg << don't care..
                        $new_url =~ s/typ_.*/typ_flip_sty_013.jpg/;
                        $new_url = test_url_min ($new_url, "013");
                        $new_url =~ s/typ_.*/typ_planeswk_sty_030.jpg/;
                        $new_url = test_url_min ($new_url, "030");
                        $new_url = test_url_min ($new_url, "040");
                        $content = get $new_url;
                    }
                    if (length ($content) == 0)
                    {
                        print ("ZERO SIZE for $helper\n");
                        exit;
                    }
                    print ("Save in $helper\n");
                    open OUTPUT, "> " . $helper or die "No dice!";
                    binmode (OUTPUT);
                    print OUTPUT $content;
                    close OUTPUT;
                    print $url, " >>> ", $helper, "\n";
                }
                else
                {
                    print ("Found $helper existed already..\n");
                }
            }
        }

        if ($operation eq "find_and_copy_missing")
        {
            my $file = $helper;
            $file =~ s/^.*\\//;
            my $missing = `type missing.txt`;
            my %missing;
            while ($missing =~ s/^(.*?)\n//)
            {
                my $i = $1;
                my $orig_i = $1;
                $i =~ s/.*\\//;
                $missing {$i} .= $orig_i . "xxx";
            }
            my $input = `dir /a /b /s`;
            my %input;
            my %input_stripped;
            while ($input =~ s/^(.*?)\n//)
            {
                my $i = $1;
                my $orig_i = $1;
                $i =~ s/.*\\(.*)\\([^\\]+)$/$1\\$2/;
                $input {$i} = 1;
                $i =~ s/.*\\//;
                $input_stripped {$i} .= $orig_i . "xxx";
            }

            my $k;
            foreach $k (sort (keys (%missing)))
            {
                if (exists ($input_stripped {$k}))    
                {
                    my $d = $missing {$k};
                    my $arg1 = $input_stripped{$k};
                    my $arg2 = $missing{$k};
                    while ($arg1 =~ s/^(.*?)xxx//)
                    {
                        my $a1 = $1;
                        while ($arg2 =~ s/^(.*?)xxx//)
                        {
                            my $a2 = $1;
                            print ("mkdir \"$d\";\ncopy \"$a1\" \"d:\\xmage_images\\FACE\\$a2\"\n");
                        }
                    }
                }
                else
                {
                    print ("rem NO Match - $k\n");
                }
            }
        }

        if ($operation eq "wget_image")
        {
            my $i;
            {
                if (-s "$helper" == 0)
                {
                    `del "$helper"`;
                }

                if (!(-f "$helper"))
                {
                    my $url = $term;
                    my $content = get $url;

                    print ("Save in $helper\n");
                    open OUTPUT, "> " . $helper or die "No dice!";
                    binmode (OUTPUT);
                    print OUTPUT $content;
                    close OUTPUT;
                    print $url, " >>> ", $helper, "\n";
                }
                else
                {
                    print ("Found $helper existed already..\n");
                }
            }
        }

        if ($operation eq "grep")
        {
            if ($line !~ m/$term/i && $use_after && $after > 0)
            {
                print ($line, "\n");
                $after--;
                if ($after == 0)
                {
                    print ("aaa===================\n");
                }
            }

            if ($line !~ m/$term/i && $use_before)
            {
                $before_lines [$before_index] = $line;
                $before_index ++;
                if ($before_index >= $before)
                {
                    $before_index = 0;
                }
            }
            
            if ($line =~ m/$term/i)
            {
                if ($use_before)
                {
                    my $b = $before_index;
                    my $ok_once = 1;

                    while ($b != $before_index || $ok_once)
                    {
                        if (defined ($before_lines [$b]))
                        {
                            print ($before_lines [$b], "\n");#.($b, .$before. $before_index, $ok_once).\n");
                        }
                        $ok_once = 0;
                        if ($b >= $before - 1)
                        {
                            $b = -1;
                        }
                        $b++;
                    }
                    my @new_array;
                    @before_lines = @new_array;
                }
                print ("$line\n");
                if ($use_after)
                {
                     $after = $orig_after;
                }
            }
        }

        if ($operation eq "head")
        {
            if ($line_number <= 10 && $term == 0)
            {
                print $line, "\n";
            }
            elsif ($line_number <= $term)
            {
                print $line, "\n";
            }
            else 
            {
                exit;
            }
        }

        if ($operation eq "solve_for_principal_and_interest" || $operation =~ m/^solve_for_princ/)
        {
            # Formula - MonthlyPayment = (Principal * MonthlyRate * ((1+MonthlyRate)^(NumMonths))/((1+MonthlyRate)^(NumMonths) - 1))
            my $pr = $term;
            if ($helper =~ m/^([\dY]+),([\d+\.]+),\?\?$/)
            {
                # pr=Principal, nm=Number Months, ir=MonthlyInterest, re=Repayments 
                # Solve for re, have (pr,nm,ir)
                my $nm = $1;
                my $ir = $2;
                if ($nm =~ m/^(\d+)Y/)
                {
                    $nm *= 12;
                    $ir /= 12;
                }
                print ("Working out: ($pr * $ir * ((1+$ir)^($nm))/((1+$ir)^($nm) - 1))\n");
                my $repayment = $pr * $ir * ((1+$ir)^($nm))/((1+$ir)^($nm) - 1);
                print "Monthly = $repayment\n";
                exit;
            }
            elsif ($helper =~ m/^([\dY]+),??,([\d+\.]+)$/)
            {
                #cut.pl stdin pr nm,ir,re solve_for_princ
                # Solve for ir, have (pr,nm,re)
                #  re = (pr * ir * (((1+ir)^nm)/((1+ir)^nm - 1)))
                #  B/A = (pr * ir / re)
                my $nm = $1;
                my $re = $2;
                my $ir = 55;
                if ($nm =~ m/^(\d+)Y/)
                {
                    $nm *= 12;
                }
                my $val = $pr * $ir / $re;
                # $val = ((1+$ir)^$nm)/((1+$ir)^$nm - 1)
                # $val = (C/(C - 1)
                # C*$val - $val = C
                #print ("C*$val - $val = C --> C is ((1+ir)^$nm\n";
                exit;
            }
            else
            {
                print ("Bad input.  Need something like:\necho \"0\" | $0 stdin 500000 25,0.0543,?? solve_for_princ\n");
                print ("\nor\necho \"0\" | $0 stdin 500000 25Y,0.0543,?? solve_for_princ\n");
                #cut.pl stdin pr nm,ir,re solve_for_princ
            }
        }

        if ($operation eq "allupcount")
        {
            my $i = 0;
            my $num_to_do = 0;

            my $l = $line;
            $l =~ s/XXX/$allup_x/img;
            $allup_x++;
            $l =~ s/YYY/$allup_y/img;
            $allup_y++;
            $l =~ s/ZZZ/$allup_z/img;
            $allup_z++;
            print ("$l\n");
        }

        if ($operation eq "edh_lands")
        {
            my $orig_wubrg = "wubrgwubrg";
            #wub ubr brg rgw gwu
            my $wubrg = $orig_wubrg;
            my $orig_full_txt = " lands <a href='edh_filter_notw_notu_notb_notr_notg_'>";
            my $full_txt = $orig_full_txt;

            my $i = 0;
            my $j = 0;
            my %combos;
            while ($i < 10)
            {
                my $j = $i;
                while ($j < 10)
                {
                    if ($j > $i + 2)
                    {
                        $j++;
                        next;
                    }
                    my $k = $j;
                    while ($k < 10)
                    {
                        if ($k > $j + 2)
                        {
                            $k++;
                            next;
                        }
                        if ($k - $j > $j - $i)
                        {
                            $k++;
                            next;
                        }
                        if ($k - $j < $j - $i && $k != $j)
                        {
                            $k++;
                            next;
                        }

                        $wubrg = $orig_wubrg;
                        $wubrg =~ m/^.{$i}(.)/;
                        my $col_one = $1;
                        $wubrg =~ m/^.{$j}(.)/;
                        my $col_two = $1;
                        $wubrg =~ m/^.{$k}(.)/;
                        my $col_three = $1;
                        $wubrg =~ s/$col_one//;
                        $wubrg =~ s/$col_two//;
                        $wubrg =~ s/$col_three//;
                        $full_txt = $orig_full_txt;
                        $full_txt =~ s/not$col_one\_//img;
                        $full_txt =~ s/not$col_two\_//img;
                        $full_txt =~ s/not$col_three\_//img;

                        $wubrg = "$col_one$col_two$col_three";
                        my $this_full_txt = $full_txt;
                        while ($this_full_txt =~ s/_not([wubrg])//im)
                        {
                            my $remove_colour = $1;
                            $wubrg =~ s/$remove_colour//img; 
                        }

                        my $this_wubrg = $wubrg;
                        while ($this_wubrg =~ s/^(...)//im)
                        {
                            my $str = $1;
                            $wubrg =~ s/$str(.*)$str/$str$1/img;
                        }
                        $this_wubrg = $wubrg;
                        while ($this_wubrg =~ s/^(..)//im)
                        {
                            my $str = $1;
                            $wubrg =~ s/$str(.*)$str/$str$1/img;
                        }
                        $this_wubrg = $wubrg;
                        while ($this_wubrg =~ s/^(.)//im)
                        {
                            my $str = $1;
                            $wubrg =~ s/$str(.*)$str/$str$1/img;
                        }

                        $full_txt =~ s/_'/'/g;

                        if (not defined ($combos {"$wubrg $full_txt$wubrg<\/a><br>"}))
                        {
                            $combos {"$wubrg $full_txt$wubrg<\/a><br>"} = 1;
                            print ("$col_one, $col_two, $col_three >> $wubrg $full_txt$wubrg<\/a><br>\n");
                        }
                        $k++;
                    }
                    $j++;
                }
                $i++;
            }
            
            $i = 0;
            $j = 0;
            $orig_wubrg = "wubrg";
            while ($i < 5)
            {
                $wubrg = $orig_wubrg;
                $wubrg =~ m/^.{$i}(.)/;
                my $col_one = $1;
                $wubrg =~ s/$col_one//;
                $full_txt = $orig_full_txt;
                $full_txt =~ s/not$col_one\_//img;
                $full_txt =~ s/_'/'/g;

                $wubrg = "not $col_one";
                my $this_full_txt = $full_txt;
                while ($this_full_txt =~ s/_not([wubrg])//im)
                {
                    my $remove_colour = $1;
                    $wubrg =~ s/$remove_colour//img; 
                }

                print ("$wubrg $full_txt$wubrg<\/a><br>\n");
                $i++;
            }
        }

        if ($operation eq "get_strings")
        {
            if ($line =~ m/\/\//i)
            {
                next;
            }

            if ($line =~ m/xxxx/i)
            {
                print ("$line\n");
                $latest_file_name = $line;
                if ($line =~ m/test/img)
                {
                    $latest_file_name = "";
                }
                if ($line =~ m/html xx/img)
                {
                    $latest_file_name = "";
                }
            }
            elsif ($latest_file_name =~ m/../) 
            {
                my $orig_line = $line;
                while ($line =~ s/"([^"]{2,70})"[^"]*$//i)
                {
                    my $str = $1;
                    print ("String: $str\n");
                    print ("     >> Original line: $orig_line\n");
                    $strings_in_files {$latest_file_name} .= ",String:$str";
                    my $short_file_name = $latest_file_name;
                    $short_file_name =~ s/.*\\//;
                    $files_to_strings {$str} .= ",File:$short_file_name";
                    $count_of_files_to_strings {$str}++;
                }
            }
        }

        if ($operation eq "oneup")
        {
            if ($line =~ m/XXX/img)
            {
                $line =~ s/XXX/$oneup/img;
                $oneup++;
            }
            print ("$line\n");
        }

        if ($operation eq "transpose")
        {
            my $col_number = 0;
            while ($line =~ s/^(.)//)
            {
                $col_number++;
                $transpose_chars {"$line_number,$col_number"} = $1;

                if ($line_number > $transpose_biggest_line)
                {
                    $transpose_biggest_line = $line_number;
                }

                if ($col_number > $transpose_biggest_col)
                {
                    $transpose_biggest_col = $col_number;
                }
            }
        }

        if ($operation eq "egrep")
        {
            if ($line =~ m/$term/i)
            {
                print ("$line\n");
            }
            elsif ($line =~ m/$helper/i)
            {
                print ("$line\n");
            }
        }
        
        if ($operation eq "email_takeout")
        {
            # Remove base64 stuff..
            $line =~ s/([A-Za-z=0-9\+\/]{55}) ([A-Za-z=0-9\+\/]{55})/$1$2/img;
            $line =~ s/([A-Za-z=0-9\+\/]{55}) ([A-Za-z=0-9\+\/]{45})/$1$2/img;
            $line =~ s/([A-Za-z=0-9\+\/]{55}) ([A-Za-z=0-9\+\/]{35})/$1$2/img;
            $line =~ s/([A-Za-z=0-9\+\/]{55}) ([A-Za-z=0-9\+\/]{25})/$1$2/img;
            $line =~ s/([A-Za-z=0-9\+\/]{55}) ([A-Za-z=0-9\+\/]{20})/$1$2/img;
            $line =~ s/([A-Za-z=0-9\+\/]{55}[A-Za-z=0-9\+\/]+)/<base64removed>/img;
            print $line, "\n";
        }
        
        if ($operation eq "do_dates")
        {
            my $orig_line = $line;
            $line = $orig_line;

            my $full_year = "20\\d\\d|19\\d\\d";
            my $short_year = "[^0-9][0123]\\d[^0-9]";
            my $year = "($full_year|$short_year)";

            my $short_month = "Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sept|Oct|Nov|Dec";
            my $long_month = "January|February|March|April|May|June|July|August|September|October|November|December";
            my $month = "(0\\d|1[012]|$short_month|$long_month)";
            my $day = "([012]\\d|3[012])";
            my $nd = "[^0-9:]";

            my $test1 = "$year$month$day";
            my $test2 = "$year$nd$month$nd$day";
            my $test3 = "$day$month$year";
            my $test4 = "$day$nd$month$nd$year";
            my $test5 = "$month$year";
            #my $test6 = "$day$month";
            my $test7 = "$month$nd$year";
            #my $test8 = "$day$nd$month";

            #print ("test1 :: $test1\n");
            #print ("test2 :: $test2\n");
            #print ("test3 :: $test3\n");
            #print ("test4 :: $test4\n");
            #print ("test5 :: $test5\n");
            #print ("test6 :: $test6\n");
            #print ("test7 :: $test7\n");
            #print ("test8 :: $test8\n");

            my %dates;
            
            while ($line =~ s/($test1)//) { $dates {$1} = 1; ; } $line = $orig_line;
            while ($line =~ s/($test2)//) { $dates {$1} = 1; ; } $line = $orig_line;
            while ($line =~ s/($test3)//) { my $ymd = "$4$3$2"; $dates {$ymd} = 1; ; } $line = $orig_line;
            while ($line =~ s/($test4)//) { my $ymd = "$4$3$2"; $dates {$ymd} = 1; ; } $line = $orig_line;
            #while ($line =~ s/($test5)//) { $dates {$1} = 1; } $line = $orig_line;
            #while ($line =~ s/($test6)//) { $dates {$1} = 1; } $line = $orig_line;
            #while ($line =~ s/($test7)//) { $dates {$1} = 1; } $line = $orig_line;
            #while ($line =~ s/($test8)//) { $dates {$1} = 1; }

            my $d;
            my %dates2;
            
            my $d_count = 0;
            $orig_line =~ m/^Date: (\d+)-(\d+)-(\d+)/;
            my $latest_date = "$1$2$3";
            
            foreach $d (sort keys (%dates))
            {
                $d =~ s/January/01/img;
                $d =~ s/February/02/img;
                $d =~ s/March/03/img;
                $d =~ s/April/04/img;
                $d =~ s/May/05/img;
                $d =~ s/June/06/img;
                $d =~ s/July/07/img;
                $d =~ s/August/08/img;
                $d =~ s/September/09/img;
                $d =~ s/October/10/img;
                $d =~ s/November/11/img;
                $d =~ s/December/12/img;

                $d =~ s/Jan/01/img;
                $d =~ s/Feb/02/img;
                $d =~ s/Mar/03/img;
                $d =~ s/Apr/04/img;
                $d =~ s/May/05/img;
                $d =~ s/Jun/06/img;
                $d =~ s/Jul/07/img;
                $d =~ s/Aug/08/img;
                $d =~ s/Sep/09/img;
                $d =~ s/Oct/10/img;
                $d =~ s/Nov/11/img;
                $d =~ s/Dec/12/img;

                #if ($d !~ m/(.)$1$1$1/)
                {
                    #print $d, "\n";
                    $d =~ s/\W//g;
                    if ($d eq $latest_date)
                    {
                        $dates2 {$d . "****"} = 1;
                    }
                    $dates2 {$d} = 1;
                    $d_count++;
                }
            }

            if ($d_count > 1)
            {
                print ("\n======================\n$orig_line :::\n");
                foreach $d (sort keys (%dates2))
                {
                    print (" $d -- ");
                    if ($d > $latest_date)
                    {
                        print ("  BAD!!!");
                    }
                    print ("\n");
                }
                print "\n";
            }

        }
        
        if ($operation eq "git")
        {
            print ("Git information:\n");
            my $top = `git rev-parse --show-toplevel`;
            chomp $top;
            print "\n===================\n";
            print $top;
            print "git fetch\ngit pull\n";
            print "git log --pretty=oneline\n";
            my $version = $term;
            if ($term == 0) { $version = 1; }
            print "git diff HEAD~$version..HEAD\n";
            print "git diff HEAD HEAD~$version --name-only\n";
            my $diff_list = `git diff HEAD HEAD~$version --name-only`;
            chomp $diff_list;
            $diff_list .= "\n";
            my $patches;
            while ($diff_list =~ s/^(.*?)\n//m)
            {
                print ("git diff HEAD HEAD~$version $top\/$1\n");
                $patches .= "git log -p --follow $top\/$1\n";
            }
            print "\n$patches\n";
            print "\nAlso can call:\n";
            print ("   echo \"1\" | cut.pl stdin colorizing 0 gitgrep\n");
            print (" >> spjones\@jollah MINGW64 /c/xmage_clean_2024<<\n");
            print (" \$ git clone https://github.com/spjspj/mage.git\n");
        }
        
        my %gitgrep;
        if ($operation eq "gitgrep")
        {
            print ("Git Grep:\n");
            print "git grep $term";
            my $top = `git rev-parse --show-toplevel`;
            chomp $top;
            print "\n===================\n";
            print $top, "\n\n";
            #%gitgrep;
            my $ggrep = `git grep $term`;
            chomp $ggrep;
            $ggrep .= "\n";
            while ($ggrep =~ s/^(.*?):(.*?)\n//m)
            {
                my $f = "$top\/$1";
                if (!defined ($gitgrep {$f}))
                {
                    $gitgrep {$f} = 1;
                    print ("git log -p --follow $top\/$1\n");
                    print ("   gvim $top\/$1\n");
                }
            }
            my $dir = `dir /a /b /s | find /I \"$term\"`;
            $dir =~ s/^/  gvim /mg; 
            print "\n==========\nFound the following files:\n$dir\n";
        }

        # Line  : 1;; ;;1;;1;; ;
        # Line  : 1;;1;; ;; ;;1;
        # reset : ------------;
        # Output: 1;;1;;1;;1;;1;

        
        if ($operation eq "git")
        {
            print ("Git information:\n");
            my $top = `git rev-parse --show-toplevel`;
            chomp $top;
            print "\n===================\n";
            print $top;
            print "git fetch\ngit pull\n";
            print "git log --pretty=oneline\n";
            my $version = $term;
            if ($term == 0) { $version = 1; }
            print "git diff HEAD~$version..HEAD\n";
            print "git diff HEAD HEAD~$version --name-only\n";
            my $diff_list = `git diff HEAD HEAD~$version --name-only`;
            chomp $diff_list;
            $diff_list .= "\n";
            my $patches;
            while ($diff_list =~ s/^(.*?)\n//m)
            {
                print ("git diff HEAD HEAD~$version $top\/$1\n");
                $patches .= "git log -p --follow $top\/$1\n";
            }
            print "\n$patches\n";
            print "\nAlso can call:\n";
            print ("   echo \"1\" | cut.pl stdin colorizing 0 gitgrep\n");
            print (" >> spjones\@jollah MINGW64 /c/xmage_clean_2024<<\n");
            print (" \$ git clone https://github.com/spjspj/mage.git\n");
        }
        
        my %gitgrep;
        if ($operation eq "gitgrep")
        {
            print ("Git Grep:\n");
            print "git grep $term";
            my $top = `git rev-parse --show-toplevel`;
            chomp $top;
            print "\n===================\n";
            print $top, "\n\n";
            #%gitgrep;
            my $ggrep = `git grep $term`;
            chomp $ggrep;
            $ggrep .= "\n";
            while ($ggrep =~ s/^(.*?):(.*?)\n//m)
            {
                my $f = "$top\/$1";
                if (!defined ($gitgrep {$f}))
                {
                    $gitgrep {$f} = 1;
                    print ("git log -p --follow $top\/$1\n");
                    print ("   gvim $top\/$1\n");
                }
            }
            my $dir = `dir /a /b /s | find /I \"$term\"`;
            $dir =~ s/^/  gvim /mg; 
            print "\n==========\nFound the following files:\n$dir\n";
        }

        # Line  : 1;; ;;1;;1;; ;
        # Line  : 1;;1;; ;; ;;1;
        # reset : ------------;
        # Output: 1;;1;;1;;1;;1;

        if ($operation eq "collapse_fields")
        {
            if ($line =~ m/----------/)
            {
                my $key;
                my $output_line;
                foreach $key (sort { $a <=> $b } (keys (%output_fields)))
                {
                    $output_line .= $output_fields {$key} . ";";
                }
                $output_line =~ s/\s//img;
                print $output_line, "\n";
                my %new_output_fields;
                %output_fields = %new_output_fields;
            }

            my $taline = $line;
            my $field_num = 0;
            while ($taline =~ s/^([^;]+?)(;|$)//)
            {
                $output_fields {$field_num} .= $1;
                $field_num++;
            }
        }

        if ($operation eq "d3_code" || $operation eq "d3_code_p2")
        {
            if ($first_d3_line eq "")
            {
                $first_d3_line = $line;
                $d3_line_length = length ($first_d3_line);
            }
            $d3_lines .= $line;
        }

        if ($operation eq "mtg_history_line")
        {
            my $ok_name_fields = 0;
            my $ok_already_fields = 0;
            my $ok_date_fields = 0;
            my $ok_price_fields = 0;
            my $ok_type_fields = 0;
            my $ok_color_fields = 0;
            my $ok_trade_fields = 0;
            my $traded = "";
            my $price = "";
            my $org_line = $line;

            my $name = "";
            my $already = "";
            my $date = "";
            my $price = "";
            my $type = "";
            my $color = "";
            my $trade = "";

            while ($line =~ s/^([^;]+);//im)
            {
                my $field = $1;
                if ($ok_name_fields == 0)
                {
                    $ok_name_fields++;
                    $name = $field;
                }

                if ($field =~ m/already/) { $ok_already_fields++; $already = $field; }
                if ($field =~ m/^\$/) { $ok_price_fields++; $price = $field; $price = $field; }
                if ($field =~ m/^20\d\d\d\d\d\d/) { $ok_date_fields++; $date = $field; }
                if ($field =~ m/^[aceispl]$/img) { $ok_type_fields++; $type = $field; }
                if ($field =~ m/^(white|blue|black|red|green|colorless|multicolored)$/img) { $ok_color_fields++; $color = $field; }
                if ($field =~ m/^(akikambara|cardkingdom|channelfireball|pack|endgames|georgetrade|magichothub|mattdecuretrade|plentyofgames|pucatrade|ronin|scottmunrotrade|starcitygames|tradegamescapital|tradegeorge|whitehorse)/img) { $ok_trade_fields++; $traded = $field; $trade = $field; }
            }

            if ($org_line =~ m/want/img) { print ("$org_line\n"); next; }

            #if ($ok_name_fields == 1) { print (" -- ok_name_fields "); }
            #if ($ok_already_fields == 1) { print (" -- ok_already_fields "); }
            #if ($ok_date_fields == 1) { print (" -- ok_date_fields "); }
            #if ($ok_price_fields == 1) { print (" -- ok_price_fields "); }
            #if ($ok_type_fields == 1) { print (" -- ok_type_fields "); }
            #if ($ok_color_fields == 1) { print (" -- ok_color_fields "); }
            #if ($ok_trade_fields == 1) { print (" -- ok_trade_fields "); }

            print ("$name;$already;$type;$date;$trade;$color;$price;proposed;");
            if ($ok_name_fields != 1) { print (" -- NOT ok_name_fields "); }
            if ($ok_already_fields != 1) { print (" -- NOT ok_already_fields "); }
            if ($traded =~ m/whitehorse|george|endgames|pack|gamescap/img)
            {
                $ok_price_fields = 1; 
            }
            if ($price =~ m/\$\d\d\./)
            {
                #print (" -- NOT ok - super high price --- $price ")
            }
            if ($ok_price_fields != 1) { print (" -- NOT ok_price_fields --- $traded "); }
            if ($ok_date_fields != 1) { print (" -- NOT ok_date_fields "); }
            if ($ok_type_fields != 1) { print (" -- NOT ok_type_fields "); }
            if ($ok_color_fields != 1) { print (" -- NOT ok_color_fields "); }
            if ($ok_trade_fields != 1) { print (" -- NOT ok_trade_fields "); }
            print "\n";
        }
        
        if ($operation eq "search_in_output")
        {
             `del c:\\tmp\\.intermediate.sw*`;
             `del c:\\tmp\\.intermediate2.sw*`;
             `del c:\\tmp\\intermediate`;
             `del c:\\tmp\\intermediate2`;
             $term =~ s/"//g;
             
             print "Now doing: $0 $file \"$term\" xxxxxx egrep > c:\\tmp\\intermediate\n";
             my $egrep = `$0 $file \"$term\" xxxxxx egrep > c:\\tmp\\intermediate`;
             print "Now doing: $0 c:\\tmp\\intermediate \"$term\" -1 grep > c:\\tmp\\intermediate2\n";
             my $grep = `$0 c:\\tmp\\intermediate \"$term\" -1 grep > c:\\tmp\\intermediate2`;
             print ("To see the results:\n");
             print ("type c:\\tmp\\intermediate2\n");
             my $output = `type c:\\tmp\\intermediate2`;
             print $output, "\n";
             `gvim c:\\tmp\\intermediate2`;
             exit;
        }
        
        if ($operation eq "edit_files")
        {
             $term =~ s/"//g;
             print "Now doing: $0 $file \"$term\" xxxxxx egrep > c:\\tmp\\intermediate\n";
             my $egrep = `$0 $file \"$term\" xxxxxx egrep > c:\\tmp\\intermediate`;
             print "Now doing: $0 c:\\tmp\\intermediate \"$term\" -1 grep > c:\\tmp\\intermediate2\n";
             `$0 c:\\tmp\\intermediate \"$term\" -1 grep > c:\\tmp\\intermediate2`;
             `$0 c:\\tmp\\intermediate2 \"xxxx\" -1 grep > c:\\tmp\\intermediate3`;
             open FILES, "c:\\tmp\\intermediate3";
             my $files = "";

             while (<FILES>)
             {
                 chomp;
                 my $line = $_;
                 if ($line =~ m/xxxx/)
                 {
                     $line =~ s/xxx.*/"/;
                     $line =~ s/" /"/img;
                     $line =~ s/ "/"/img;
                     $files .= $line . " ";
                 }
             }
             close FILES;

             open OUTPUT, "> c:\\tmp\\edit_files.bat";
             print OUTPUT "gvim $files";
             close OUTPUT;
             print "\n\ngvim $files";
             `c:\\tmp\\edit_files.bat`;
             exit;
        }

        if ($operation eq "sinewave")
        {
            my $x = 15;
            my $y = 15;
            my $counter = 0;
            print ("counter,counter2,counter3,i.float,j.float,actual_x.float,actual_y.float,dist_from_center.float,sin_value.float,thedate.datetime,circle,grid.color,counter...counter2;;;thedate.datetime\n");
            my $the_date = "2021-08-26T05:51:";
            for (my $i = 0; $i < 2 * $x; $i++)
            {
                for (my $j = 0; $j < 2 * $y; $j++)
                {
                    my $actual_x = $i / $x * $PI; 
                    my $actual_y = $j / $y * $PI; 
                    my $dist_from_center = $actual_x * $actual_x + $actual_y * $actual_y;
                    $dist_from_center = sqrt ($dist_from_center);

                    if ($dist_from_center > 0)
                    {
                        my $sin_value = sin($dist_from_center) * 100; 
                        my $final_date = $counter;
                        if ($final_date !~ m/\d\d\d\d\d/)
                        {
                            $final_date = "0000" . $final_date;
                        }
                        $final_date =~ s/.*(\d\d)(\d\d\d)$/$1.$2/;
                        $final_date .= "[UTC]";

                        my $circle = 0.0;
                        if ($dist_from_center =~ m/\.[56789]/)
                        {
                            $circle = 1.0;
                        }

                        my $grid = "Blueberry";
                        if (($actual_x =~ m/[02468]\./) || ($actual_y =~ m/[02468]\./))
                        {
                            $grid = "Banana";
                            $circle = 1.0;
                        }

                        if ($j != $y * 2 - 1)
                        {
                            print ("$counter," . ($counter+1) . "," . ($counter + 2*$x) . ",$i,$j," . ($actual_x * 100) . "," . ($actual_y * 100) . ",$dist_from_center,$sin_value,$the_date$final_date,$circle,$grid,\n");
                        }
                    }
                    $counter ++;
                }
            }
        }

        if ($operation eq "palindrome")
        {
            my $p = 0;
            my $i = 0;
            for ($i = 0; $i < 10000; $i++)
            {
                if ($i =~ m/^(.)(.)(.)(.)$/)
                {
                    if ($i =~ m/^$4$3$2$1$/)
                    {
                        print ("$i\n");
                        if ($i % 99 == 0)
                        {
                            print (" **** divisible by 99\n");
                            $p++;
                        }
                    }
                }
            }
            print ("\n$p palindromes\n");
            exit;
        }
        
        if ($operation eq "sinewave_excel")
        {
            my $x = 100;
            my $y = 100;
            my $counter = 0;
            my $xs = " ,";
            for (my $i = 0; $i < 2 * $x; $i++)
            {
                my $actual_x2 = $i / $x * $PI; 
                $xs .= $actual_x2 . ",";  
            }

            print ("\n SLDKFJSLDFJLSDFJLSKDFJKLSJDF\n$xs\n");
            for (my $i = 0; $i < 2 * $x; $i++)
            {
                my $actual_x2 = $i / $x * $PI; 
                print ("$actual_x2,");
                for (my $j = 0; $j < 2 * $y; $j++)
                {
                    my $actual_x = $i / $x * $PI; 
                    my $actual_y = $j / $y * $PI; 
                    my $dist_from_center = $actual_x * $actual_x + $actual_y * $actual_y;
                    $dist_from_center = sqrt ($dist_from_center);
                    if ($dist_from_center > 0)
                    {
                        my $sin_value = sin($dist_from_center); 
                        $sin_value =~ s/\.(\d\d\d\d\d).*/.$1/;
                        print ("$sin_value,");
                    }
                    $counter ++;
                }
                print ("\n");
            }
        }
        
        if ($operation eq "water")
        {
            my $x = 12;
            my $y = 12;
            my $counter = 0;
            print ("counter.integer,i.float,j.float,actual_x.float,actual_y.float,dist_from_center.float,sin_value.float,iteration.integer,currentiteration.integer,circle,counter...counter2\n");
            my $iteration = 0;
            my $total_iterations = 10;

            for ($iteration = 0; $iteration < $total_iterations; $iteration++)
            {
                for (my $i = -2 * $x; $i < 2 * $x; $i++)
                {
                    for (my $j = -2 * $y; $j < 2 * $y; $j++)
                    {
                        my $actual_x = $i / $x * $PI; 
                        my $actual_y = $j / $y * $PI; 
                        my $dist_from_center = $actual_x * $actual_x + $actual_y * $actual_y;
                        $dist_from_center = sqrt ($dist_from_center);

                        if ($dist_from_center > 0)
                        {
                            my $sin_value = sin($dist_from_center + $iteration / $total_iterations * 4 * $PI) * 100; 

                            print ("$counter,$i,$j," . ($actual_x * 100) . "," . ($actual_y * 100) . ",$dist_from_center,$sin_value,$iteration,0,0,\n");
                        }
                        $counter ++;
                    }
                }
            }
        }
        
        
        # Working out a way to draw the ellipse of the earth
        # Needs the aphelion and perihelion..
        if ($operation eq "ellipse")
        {
            my $perihelion = $term;
            my $aphelion = $helper;
            my $full_distance = sqrt ($perihelion * $perihelion + $aphelion * $aphelion);
            my $focii1 = abs(($perihelion - $aphelion) / 2);
            my $focii2 = -$focii1; 

            my $major_axis = $aphelion + $focii1;
            $major_axis = 5;
            
            my $hypot = $full_distance / 2;
            my $angle = acos($focii1 / $hypot);
            my $minor_axis = sin($angle) * $hypot;
            $minor_axis = 3;
            my $PI = $PI;

            my $total_circum = 2 * $PI * sqrt (($minor_axis * $minor_axis + $major_axis * $major_axis) / 2);
            my $next_segment = 0;

            for (my $i = 0; $i < 17; $i++)
            {
                my $f = 1;
                $next_segment += $total_circum / 10; 
            }
            print ("Major = $major_axis, minor = $minor_axis, total_circum= $total_circum\n");
        }
        
        if ($operation eq "json_to_csv")
        {
            my $orig_line = $line;
            
            if ($line =~ m/..../)
            {
                my %ret_values = get_next_json_chunk($line);
                $line = $ret_values{line};
                my $json_chunk = $ret_values {json_chunk};
                read_json_values ($json_chunk, 0);
            }
            
            my $line = $orig_line;
            print (join (",", sort (keys (%all_json_fields))), "\n");
            
            while ($line =~ m/..../)
            {
                my %ret_values = get_next_json_chunk($line);
                $line = $ret_values{line};
                my $json_chunk = $ret_values {json_chunk};
                read_json_values ($json_chunk, 1);
            }         
        }
        
        if ($operation =~ m/^search/img)
        {
            if ($line =~ m/(\+\+\+\+\+\+|xxxxxxxxx)/i)
            {
                $print_last_file = 1;
                $last_file = $line;
            }
            if ($line =~ m/$term/i)
            {
                if ($print_last_file == 1)
                {
                    print ("\n$last_file\n");
                    $print_last_file = 0;
                }
                print ("$line\n");
            }
            elsif ($helper !~ m/^\d+$/ && $line =~ m/$helper/i)
            {
                if ($print_last_file == 1)
                {
                    print ("\n$last_file\n");
                    $print_last_file = 0;
                }
                print ("$line\n");
            }
        }
        
        if ($operation eq "word2word")
        {
            if ($line =~ m/$term/img)  
            {
                # Keep the same case but then change it
                while ($line =~ m/.*?($term).*/im)  
                {
                    my $instance = $1;
                    # 3 Cases (UPPER, Upper, upper)
                    if ($instance =~ m/^[A-Z][a-z_1-9]*$/)
                    {
                        $helper =~ m/^(.)(.+)/;
                        my $replace_with = uc($1) . lc($2);
                        $line =~ s/(.*?)($term)/$1$replace_with/im;
                    }
                    elsif ($instance =~ m/^[A-Z1-9_]+$/)
                    {
                        my $replace_with = uc($helper);
                        $line =~ s/(.*?)($term)/$1$replace_with/im;
                    }
                    elsif ($instance =~ m/^[a-z1-9_]+$/)
                    {
                        my $replace_with = lc($helper);
                        $line =~ s/(.*?)($term)/$1$replace_with/im;
                    }
                    else
                    {
                        my $replace_with = $helper;
                        $line =~ s/(.*?)($term)/$1$replace_with/im;
                    }
                }
            }
            print ($line, "\n");
        }

        if ($operation eq "hrep_between")
        {
            if ($line =~ m/$term/i)
            {
                print ("\n===================================================================\n");
                print ($line, "\n");
                $in_between_lines = 1;
            }
            if ($line !~ m/$helper/i && $in_between_lines)
            {
                print ($line, "\n");
            }
            if ($line =~ m/$helper/i && $in_between_lines)
            {
                print ($line, "\n");
                $in_between_lines = 0;
            }
        }

        if ($operation eq "filegrep")
        {
            my $k;
            my $print = 1;
            foreach $k (keys (%kkks))
            {
                if ($line =~ m/$k/ && $print)
                {
                    $print = 0;
                    print ($line, "\n");
                }
            }
        }

        if ($operation eq "size")
        {
            if (-f $line)
            {
                my $sizer = -s $line;
                my $zzz = "                             $sizer";
                $zzz =~ s/.*(........................)$/$1/;
                print ($zzz, " --- $line\n");
                $total_size += $sizer;
            }
        }

        if ($operation eq "count")
        {
            print ("$count - $line\n");
            $count++;
        }

        if ($operation eq "strip_http")
        {
            # Has to work on a file..
            if ($line =~ m/.*HTTP/)
            {
                $seen_http = 1;
                print ("SEEN HTTP\n");
            }

            $lines_http ++;

            if ($seen_http && $line eq "")
            {
                $seen_http = 2;
            }
        }

        if ($operation eq "strip_html")
        {
            #$line =~ s/<[^>]+>/ /img;
            #$line =~ s/^(.{100}[^ ]+)(.*)/$1\n$2/img;
            #$line =~ s/^ \n//img;

            $line =~ s/\W/ /img;
            $line =~ s/^(.{100}[^ ]+)(.*)/$1\n$2/img;
            $line =~ s/^ \n//img;
            print $line, "\n";
        }
        
        if ($operation eq "ringing")
        {
            $line =~ s/\s//img;

            # Do hand bell pairs..
            my $new_line = $line;
            $new_line =~ s/[^0-9]//img;
 
            if ($new_line =~ m/^[1-9]+$/)
            {
                my $ot = $new_line;
                my $tf = $new_line;
                my $fs = $new_line;
                my $se = $new_line;
                my $nt = $new_line;
                my $SEP = "     "; 

                $ot =~ s/[^12]/./img;
                $tf =~ s/[^34]/./img;
                $fs =~ s/[^56]/./img;
                $se =~ s/[^78]/./img;
                $nt =~ s/[^9A]/./img;
                
                $new_line =~ m/^(....)/;
                my $single_bit = $1;
                $new_line =~ m/^(.)(.)(.)(.)/;
                my $bob_bit = "$1$3$2$4";

                my $old_call_number = $call_number;
                if ($last_line =~ m/^$single_bit/) { print ("  -- SINGLE\n"); $calls {$call_number} = "Single"; $call_number++; }
                elsif ($last_line =~ m/^$bob_bit/) { print ("  -- BOB\n"); $calls {$call_number} = "Bob"; $call_number++; }
                elsif (($line =~ m/^1/) && ($last_line =~ m/^1/)) { print ("  -- PLAIN\n"); $calls {$call_number} = "Plain"; $call_number++; }

                if ($old_call_number != $call_number)
                {
                    print (work_out_ringing_positions ($ot_ringing), "$SEP");
                    print (work_out_ringing_positions ($tf_ringing), "$SEP");
                    print (work_out_ringing_positions ($fs_ringing), "$SEP");
                    print (work_out_ringing_positions ($se_ringing), "$SEP");
                    print (work_out_ringing_positions ($nt_ringing), "$SEP");
                    print ("\n");

                    $ot_ringing = "";
                    $tf_ringing = "";
                    $fs_ringing = "";
                    $se_ringing = "";
                    $nt_ringing = "";
                }
                
                $ot_ringing .= $ot . "\n";
                $tf_ringing .= $tf . "\n";
                $fs_ringing .= $fs . "\n";
                $se_ringing .= $se . "\n";
                $nt_ringing .= $nt . "\n";

                if ($ot =~ m/[12]/) { print ($ot , "$SEP"); }
                if ($tf =~ m/[34]/) { print ($tf , "$SEP"); }
                if ($fs =~ m/[56]/) { print ($fs , "$SEP"); }
                if ($se =~ m/[78]/) { print ($se , "$SEP"); }
                if ($nt =~ m/[9A]/) { print ($nt , "$SEP"); }
                print ("$new_line ");

                my $copy_line;
                my $copy_last_line;
                my $x;
                $copy_line = $new_line . " ";
                $copy_last_line = $last_line . " ";

                while ($copy_line =~ s/^(.)(.)//)
                {
                    # Example 1:
                    # 12345
                    # ||\/||
                    # 12435
                    # Example 2:
                    # 12435
                    # |\/\/
                    # 14253
                    # Example 3:
                    # 12435
                    # \/\/|
                    # 21345
                    # 12435879
                    # \/\/\/\/
                    # 21348597
                    my $bn = $1;
                    my $bn2 = $2;

                    if ($copy_last_line =~ m/^$bn$bn2/)
                    {
                        print ("||");
                    }
                    elsif ($copy_last_line =~ m/^$bn2$bn/)
                    {
                        print ("\\\/");
                    }
                    elsif ($copy_last_line =~ m/^.$bn2/)
                    {
                        print ("\/|");
                    }
                    elsif ($copy_last_line =~ m/^$bn./)
                    {
                        print ("|\\");
                    }
                    else
                    {
                        print ("\/\\");
                    }
                    $copy_last_line =~ s/^..//;
                }
                
                print ("\n");
                $last_line = $new_line;
            }
        }

        if ($operation eq "replace")
        {
            my $orig_line = $line;
            $helper =~ s/\\n/zyzyz/img;
            #$line =~ s/$term/$helper/gi;
            eval("\$orig_line =~ s/$term/$helper/gi;");
            $orig_line =~ s/zyzyz/\n/img;
            #$line =~ s/$term/$helper/gi;
            print ("$orig_line\n");
        }

        if ($operation eq "dedup_line")
        {
            $line =~ m/::(.*)::/;
            my $user = $1;
            my $new_line;
            $line =~ s/.*://;
            while ($line =~ s/,([^,]*),/,/im)
            {
                $new_line .= "\n$user:$1\n";
                if (not defined ($dedup_line_hash {"$user:$1"}))
                {
                    $dedup_line_hash {"$user:$1"} = 1;
                    $dedup_line_hash {$user} ++;
                }
            }
            print ("$new_line\n");
        }

        if ($operation eq "matrix_flip")
        {
            my @chars = split //, $line;
            $matrix_col = 0;
            my $char;

            foreach $char (@chars)
            {
                $matrix_flip {"$matrix_row,$matrix_col"} = $char;
                $matrix_col ++;
                if ($max_matrix_col < $matrix_col)
                {
                    $max_matrix_col = $matrix_col;
                }
            }
            $matrix_row ++;
        }

        if ($operation eq "replace_maths")
        {
            my $equation = $term;
            my $orig_equation = $term;

            my $i = 0;
            while ($equation =~ s/,//)
            {
                $i++;
            }
            my $j = 0;
            my $operations = "";
            my $num_operations = 1;
            while ($j < $i)
            {
                $j++;
                $operations .= "0";
                $num_operations *= 4;
            }
            print ("Found $i operations to do.. ($operations)\n");
            if ($i > 7)
            {
                print ("Too many operations..\n");
            }

            my $num = 0;
            my $a;
            my $b;
            my $c;
            my $d;
            my $e;
            my $f;
            my $g;

            my %equations;
            for ($a = 0; $a < 4; $a++)
            {
                my $equation = $orig_equation;
                if ($a == 0) { $equation =~ s/,/+/; }
                if ($a == 1) { $equation =~ s/,/-/; }
                if ($a == 2) { $equation =~ s/,/\//; }
                if ($a == 3) { $equation =~ s/,/*/; }
                my $a_equation = $equation;

                for ($b = 0; $b < 4; $b++)
                {
                    $equation = $a_equation;
                    if ($b == 0) { $equation =~ s/,/+/; }
                    if ($b == 1) { $equation =~ s/,/-/; }
                    if ($b == 2) { $equation =~ s/,/\//; }
                    if ($b == 3) { $equation =~ s/,/*/; }
                    my $b_equation = $equation;
                    for ($c = 0; $c < 4; $c++)
                    {
                        $equation = $b_equation;
                        if ($c == 0) { $equation =~ s/,/+/; }
                        if ($c == 1) { $equation =~ s/,/-/; }
                        if ($c == 2) { $equation =~ s/,/\//; }
                        if ($c == 3) { $equation =~ s/,/*/; }
                        my $c_equation = $equation;
                        for ($d = 0; $d < 4; $d++)
                        {
                            $equation = $c_equation;
                            if ($d == 0) { $equation =~ s/,/+/; }
                            if ($d == 1) { $equation =~ s/,/-/; }
                            if ($d == 2) { $equation =~ s/,/\//; }
                            if ($d == 3) { $equation =~ s/,/*/; }
                            my $d_equation = $equation;
                            for ($e = 0; $e < 4; $e++)
                            {
                                $equation = $d_equation;
                                if ($e == 0) { $equation =~ s/,/+/; }
                                if ($e == 1) { $equation =~ s/,/-/; }
                                if ($e == 2) { $equation =~ s/,/\//; }
                                if ($e == 3) { $equation =~ s/,/*/; }
                                my $e_equation = $equation;
                                for ($f = 0; $f < 4; $f++)
                                {
                                    $equation = $e_equation;
                                    if ($f == 0) { $equation =~ s/,/+/; }
                                    if ($f == 1) { $equation =~ s/,/-/; }
                                    if ($f == 2) { $equation =~ s/,/\//; }
                                    if ($f == 3) { $equation =~ s/,/*/; }
                                    my $f_equation = $equation;
                                    for ($g = 0; $g < 4; $g++)
                                    {
                                        $equation = $f_equation;
                                        if ($g == 0) { $equation =~ s/,/+/; }
                                        if ($g == 1) { $equation =~ s/,/-/; }
                                        if ($g == 2) { $equation =~ s/,/\//; }
                                        if ($g == 3) { $equation =~ s/,/*/; }
                                        $equations {"=" . $equation} = 1;
                                        $equation =~ s/(\d+)\+(\d+)/($1+$2)/;
                                        $equations {"=" . $equation} = 1;
                                        $equation =~ s/[()]//img;
                                        $equation =~ s/(\d+)-(\d+)/($1-$2)/;
                                        $equations {"=" . $equation} = 1;
                                        $equation =~ s/[()]//img;
                                    }
                                    $equations {"=" . $equation} = 1; $equation =~ s/(\d+)\+(\d+)/($1+$2)/; $equations {"=" . $equation} = 1; $equation =~ s/[()]//img; $equation =~ s/(\d+)-(\d+)/($1-$2)/; $equations {"=" . $equation} = 1; $equation =~ s/[()]//img;
                                }
                                $equations {"=" . $equation} = 1; $equation =~ s/(\d+)\+(\d+)/($1+$2)/; $equations {"=" . $equation} = 1; $equation =~ s/[()]//img; $equation =~ s/(\d+)-(\d+)/($1-$2)/; $equations {"=" . $equation} = 1; $equation =~ s/[()]//img;
                            }
                            $equations {"=" . $equation} = 1; $equation =~ s/(\d+)\+(\d+)/($1+$2)/; $equations {"=" . $equation} = 1; $equation =~ s/[()]//img; $equation =~ s/(\d+)-(\d+)/($1-$2)/; $equations {"=" . $equation} = 1; $equation =~ s/[()]//img;
                        }
                        $equations {"=" . $equation} = 1; $equation =~ s/(\d+)\+(\d+)/($1+$2)/; $equations {"=" . $equation} = 1; $equation =~ s/[()]//img; $equation =~ s/(\d+)-(\d+)/($1-$2)/; $equations {"=" . $equation} = 1; $equation =~ s/[()]//img;
                    }
                    $equations {"=" . $equation} = 1; $equation =~ s/(\d+)\+(\d+)/($1+$2)/; $equations {"=" . $equation} = 1; $equation =~ s/[()]//img; $equation =~ s/(\d+)-(\d+)/($1-$2)/; $equations {"=" . $equation} = 1; $equation =~ s/[()]//img;
                }
                $equations {"=" . $equation} = 1; $equation =~ s/(\d+)\+(\d+)/($1+$2)/; $equations {"=" . $equation} = 1; $equation =~ s/[()]//img; $equation =~ s/(\d+)-(\d+)/($1-$2)/; $equations {"=" . $equation} = 1; $equation =~ s/[()]//img;
            }

            print join ("\n", sort keys(%equations));
            
            $term =~ s/^(\d+),(.*)/$2,$1/;
            open PROC, "echo '1' | cut.pl $file $term $helper $operation |";
            print "Running: cut.pl $file $term $helper $operation |\n";
            my $found_output = 0;
            while (<PROC>)
            {
                if ($found_output == 0)
                {
                    print ("\n\n==================\nProcessing file: $file\n");
                    $found_output = 1;
                }
                print ($_);
            }
            if ($found_output > 0)
            {
                print ("\n******************xx\n");
            }
            close PROC;

            exit;
        }

        if ($operation eq "str_condense")
        {
            if ($line =~ m/(.)(\1{3,})/)
            {
                $line =~ s/(.)(\1{3,})/sprintf ("$1!%d#", length ($2));/eg;
            }
            print $line, "\n";
        }

        if ($operation eq "condense")
        {
            if ($condense_begin == 1)
            {
                $condense_begin = 0;
                $condense_line = $line;
                $condense_start = $line;
                $condense_start =~ s/^(.{10,25}).*/$1/;
                $condense_start =~ s/\W/./g; 
                $condense_count = 0;
            }
            else
            {
                if ($line =~ $condense_start)
                {
                    $condense_count++;
                }
                else
                {
                    if ($condense_count > 1) 
                    {
                        $condense_line .= " {+similar=$condense_count}"; 
                    }
                    print $condense_line, "\n";

                    $condense_line = $line;
                    if ($condense_line !~ m/......./)
                    {
                        $condense_begin = 1;
                    }
                    else
                    {
                        $condense_start = $line;
                        $condense_start =~ s/^(.{10,25}).*/$1/;
                        $condense_start =~ s/\W/./g; 
                        $condense_count = 0;
                    }
                }
            }
        }

        if ($operation eq "fields")
        {
            #$line = "BBB$term$line$term";
            my @fs = split /$term/, $line;
            my @shows = split /,/, "$helper,";
            my $s;
            foreach $s (@shows)
            {
                if ($s eq "Rest") 
                {
                    print $line;
                }
                elsif ($s eq "NewLine") 
                {
                    print "\n";
                }
                else
                {
                    print $fs [$s], "$term";
                }
            }
            print "\n";
        }
        
        if ($operation eq "sort" || $operation eq "sortn")
        {
            $ulines {$line} = 1;
            $ulines_count ++;
        }

        if ($operation eq "wordcombos")
        {
            my @fs = split /$term/, $line;

            # The first one is key, the rest need to be made into something
            my $current_key = $fs [0];
            my $current_val = $fs [1];
            
            $current_val =~ s/ /XXX/g;
            $current_val =~ s/\W//g;
            $current_val =~ s/XXX*/ /g;

            my @words = split / /, uc ($current_val);

            my $w;
            my $ws;
            for ($w = 0; $w < scalar (@words); $w++) 
            {
                my $x;
                $ws = $words [$w];
                for ($x = $w + 1; $x < $w + $helper; $x++)
                {
                    $ws .= "," . $words [$x];
                }
                #$ws .= ";;;" . $current_key;
                $combos {$ws} ++;
                $all_combos {$ws} .= ";;;" . $current_key;
            }

        }

        if ($operation eq "uniquewords")
        {
            $line .= " ";
            my @words = split / /, uc ($line);

            my $w;
            my $ws;
            for ($w = 0; $w < scalar (@words); $w++) 
            {
                $combos {$words [$w]} ++;
            }
        }

        if ($operation eq "cut_on_first_display_with_second")
        {
            if ($line =~ m/$helper/img) # cut_on_term
            {
                if ($saw_helper_cut_on_term) 
                {
                    print join ("\n", @cut_on_term);
                }
                else
                {
                    #print ("\nNothing in this segment!!\n");
                }
                $saw_helper_cut_on_term = 0; 
                my @new_array;
                @cut_on_term = @new_array;
            }
            push @cut_on_term, $line;
            if ($line =~ m/$term/img)
            {
                $saw_helper_cut_on_term = 1; 
            }
        }
         
        if ($operation eq "images_html")
        {
            my @fs = split /$term/, $line;
            my @shows = split /,/, "$helper,";
            my $s;
            {
                # <img src='http://gatherer.wizards.com/Handlers/Image.ashx?multiverseid=220251&type=card'/>
                if ($fs[$shows[0]] =~ m/\*/)
                {
                    my $id = $fs[$shows[0]];
                    $id =~ s/\*//g;
                    $id =~ s/ //g;
                    my $x = "<img src='http://gatherer.wizards.com/Handlers/Image.ashx?multiverseid=XXX&type=card'/>";
                    $x =~ s/XXX/$id/;
                    print "$fs[$shows[1]]<br>$x";
                    print "\n";
                }
            }
        }
        
        if ($operation eq "one_url_per_line")
        {
            my $url = $line;
            $url =~ s/.*(http(.+?))[">].*/$1/;
            
            my $content = get $url;
            $content =~ s/\s\s/ /gim;
            $content =~ s/\s\s/ /gim;
            $content =~ s/\n//gim;

            print "$url ---> $content\n";
        }

        if ($operation eq "make_code_bat")
        {
            if ($line !~ m/all_/mg) 
            {
                print ("echo \" $line xxxxxxx\"\n");
                print ("type \"$line\"\n");
            }
        }

        if ($operation eq "make_cp_bat")
        {
            my $new_file = $line;
            $new_file =~ s/^.*\\//;
            $new_file =~ s/\./xxx/img;
            $new_file =~ s/[\W]/_/img;
            $new_file =~ s/__/_/img;
            $new_file =~ s/__/_/img;
            $new_file =~ s/__/_/img;
            $new_file =~ s/__/_/img;
            $new_file =~ s/xxx/./img;
            $line =~ s/(.*)/copy "\1" "$new_file"/;
            print ("$line\n");
        }

        if ($operation eq "nobinary")
        {
            if ($line !~ m/\..{0,4}$/img) 
            {
                next;
            }

            if ($line =~ m/\.(ap_|idx|mp3|bmp|db|dll|lnk|star|class|dat|exe|vlw|json|js|map|gif|gz|ico|index|jar|jpg|pack|pdf|png|swp|swo|tab|ttf|7z|zip|dex|apk|bin|war|net|tsv|log|ai|Help|md|vs|gs|fs|mf)$/img)
            {
                next;
            }
            if ($line !~ m/\.(ap_|mp3|bmp|db|dll|lnk|star|class|dat|exe|vlw|json|js|map|gif|gz|ico|index|jar|jpg|pack|pdf|png|swp|swo|tab|ttf|7z|zip|dex|apk|bin|war)$/img) 
            {
                print ("$line\n");
            }
        }
        
        if ($operation eq "calendarxxx")
        {
            my $month1_string = print_month ($term, 1);
            my $month2_string = print_month ($term, 2);
            my $month3_string = print_month ($term, 3);
            print ("           $term\n");
            print_months ($month1_string, $month2_string, $month3_string);
            $month1_string = print_month ($term, 4);
            $month2_string = print_month ($term, 5);
            $month3_string = print_month ($term, 6);
            print_months ($month1_string, $month2_string, $month3_string);
            $month1_string = print_month ($term, 7);
            $month2_string = print_month ($term, 8);
            $month3_string = print_month ($term, 9);
            print_months ($month1_string, $month2_string, $month3_string);
            $month1_string = print_month ($term, 10);
            $month2_string = print_month ($term, 11);
            $month3_string = print_month ($term, 12);
            print_months ($month1_string, $month2_string, $month3_string);
        }
        
        if ($operation eq "calendar")
        {
            my $month1_string = print_month ($term, 1);
            my $month2_string = print_month ($term, 2);
               $month2_string = add_school_holidays ($month2_string, 18, 18);
               $month2_string = add_school_holidays ($month2_string, 25, 25);
            my $month3_string = print_month ($term, 3);
               $month3_string = add_school_holidays ($month3_string, 4, 4);
               $month3_string = add_school_holidays ($month3_string, 11, 11);
               $month3_string = add_school_holidays ($month3_string, 18, 18);
               $month3_string = add_school_holidays ($month3_string, 25, 25);
            print ("           $term\n");
            print_months ($month1_string, $month2_string, $month3_string);
            $month1_string = print_month ($term, 4);
            $month2_string = print_month ($term, 5);
            $month3_string = print_month ($term, 6);
            print_months ($month1_string, $month2_string, $month3_string);
            $month1_string = print_month ($term, 7);
            $month2_string = print_month ($term, 8);
            $month3_string = print_month ($term, 9);
            print_months ($month1_string, $month2_string, $month3_string);
            $month1_string = print_month ($term, 10);
            $month2_string = print_month ($term, 11);
            $month3_string = print_month ($term, 12);
            print_months ($month1_string, $month2_string, $month3_string);
        }
        
        if ($operation eq "calendar_pay")
        {
            $thursday_is_payday = 555;
            my $month1_string = print_month_w_payday ($term, 1, 2, 27, "Z", "Z", "Z", "Z"); 
               $month1_string = add_school_holidays ($month1_string, 1, 31);
            my $month2_string = print_month_w_payday ($term, 2, "Z", "Z", "Z", "Z"); 
               $month2_string = add_school_holidays ($month2_string, 1, 4);
            my $month3_string = print_month_w_payday ($term, 3, 10, "Z", "Z", "Z", "Z");
            print_months_html ($month1_string, $month2_string, $month3_string, $term);
            $month1_string = print_month_w_payday ($term, 4, 18, 19, 20, 21, 25, "Z", "Z");
               $month1_string = add_school_holidays ($month1_string, 12, 29);
            $month2_string = print_month_w_payday ($term, 5, "Z", "Z", "Z", "Z", "Z");
            $month3_string = print_month_w_payday ($term, 6, 2, 9, "Z", "Z", "Z");
            print_months_html ($month1_string, $month2_string, $month3_string, 0);
            $month1_string = print_month_w_payday ($term, 7, "Z", "Z", "Z", "Z");
               $month1_string = add_school_holidays ($month1_string, 5, 20);
            $month2_string = print_month_w_payday ($term, 8, "Z", "Z", "Z", "Z");
            $month3_string = print_month_w_payday ($term, 9, "Z", "Z", "Z", "Z");
               $month3_string = add_school_holidays ($month3_string, 27, 30);
            print_months_html ($month1_string, $month2_string, $month3_string, 0);
            $month1_string = print_month_w_payday ($term, 10, 6, "Z", "Z", "Z", "Z");
               $month1_string = add_school_holidays ($month1_string, 1, 13);
            $month2_string = print_month_w_payday ($term, 11, "Z", "Z", "Z", "Z");
            $month3_string = print_month_w_payday ($term, 12, 25, 26, "Z", "Z", "Z", "Z");
               $month3_string = add_school_holidays ($month3_string, 16, 31);
            print_months_html ($month1_string, $month2_string, $month3_string, -1);
        }
        
        if ($operation eq "calendar_payxxx")
        {
            $thursday_is_payday = $helper;
            my $month1_string = print_month_w_payday ($term, 1, 3, 26, "Z", "Z", "Z", "Z"); $month1_string = add_school_holidays ($month1_string, 1, 31);
            my $month2_string = print_month_w_payday ($term, 2, "Z", "Z", "Z", "Z"); 
            my $month3_string = print_month_w_payday ($term, 3, 14, "Z", "Z", "Z", "Z");
            print_months_html ($month1_string, $month2_string, $month3_string, $term);
            #$month1_string = print_month_w_payday ($term, 4, 15, 18, 25, "Z", "Z", "Z", "Z"); $month1_string = possible_school_holidays ($month1_string, 6, 25);
            $month1_string = print_month_w_payday ($term, 4, 15, 18, 25, "Z", "Z", "Z", "Z"); $month1_string = add_school_holidays ($month1_string, 9, 25);
            $month2_string = print_month_w_payday ($term, 5, 30, "Z", "Z", "Z", "Z");
            $month3_string = print_month_w_payday ($term, 6, 13, "Z", "Z", "Z", "Z");
            print_months_html ($month1_string, $month2_string, $month3_string, 0);
            $month1_string = print_month_w_payday ($term, 7, "Z", "Z", "Z", "Z"); $month1_string = add_school_holidays ($month1_string, 2, 17);
            $month2_string = print_month_w_payday ($term, 8, "Z", "Z", "Z", "Z");
            $month3_string = print_month_w_payday ($term, 9, "Z", "Z", "Z", "Z"); $month3_string = add_school_holidays ($month3_string, 24, 30);
            print_months_html ($month1_string, $month2_string, $month3_string, 0);
            $month1_string = print_month_w_payday ($term, 10, 3, "Z", "Z", "Z", "Z"); $month1_string = add_school_holidays ($month1_string, 1, 9);
            $month2_string = print_month_w_payday ($term, 11, "Z", "Z", "Z", "Z");
            $month3_string = print_month_w_payday ($term, 12, 25, 26, 27, "Z", "Z", "Z"); $month3_string = add_school_holidays ($month3_string, 17, 31);
            print_months_html ($month1_string, $month2_string, $month3_string, -1);
        }
        
        if ($operation eq "binary")
        {
            if ($line !~ m/\..{0,4}$/img) 
            {
                next;
            }

            my $is_bin = 0;
            if ($line =~ m/\.(ap_|mp3|bmp|db|dll|lnk|star|class|dat|exe|vlw|json|js|map|gif|gz|ico|index|jar|jpg|pack|pdf|png|swp|swo|tab|ttf|7z|zip|dex|apk|bin|war|net|tsv|log|ai|Help|md|vs|gs|fs|mf)$/img)
            {
                $is_bin = 1;
            }

            if ($line =~ m/\.(ap_|mp3|bmp|db|dll|lnk|star|class|dat|exe|vlw|json|js|map|gif|gz|ico|index|jar|jpg|pack|pdf|png|swp|swo|tab|ttf|7z|zip|dex|apk|bin|war)$/img) 
            {
                $is_bin = 1;
            }

            if ($is_bin) 
            {
                print ("$line\n");
            }
        }

        if ($operation eq "fix_json_field")
        {
            # Assumes input similar to {"id":"B14E","time":1585657709530,"device":"9C65F921EFED","rank":2,"CQI0":9,"CQI1":8,"subbands":9,"loc":[-7178833,4218827]},
            # Gives output similar to id,time,device,rank,cqio,cqi1,subbands,loc1,loc2
            #                         B14E,1585657709530,9C65F921EFED,2,9,8,9,[-7178833,4218827]
            # Gives output similar to {"id":"B14E","time":1585657709530,"device":"9C65F921EFED","rank":2,"CQI0":9,"CQI1":8,"subbands":9,"loc":[-7178833,4218827]},
            # Gives output similar to {"id":"B14E","time":1585657709530,"device":"9C65F921EFED","rank":2,"CQI0":9,"CQI1":8,"subbands":9,"loc":[-7178833,4218827]},
            print $line_number, ",";
            my $line_out = "$line_number";
            $line =~ s/["\[\]\{\}]//img;
            while ($line =~ s/^([^,]*?),//)
            {
                 my $field = $1;
                 $field =~ s/^.*?://;
                 $line_out .= "," . $field;
            }
            print "$line_out\n";
        }

        if ($operation eq "add_line_no")
        {
            $line = $line_number . ",$line";
            print $line, "\n";
        }
        
        if ($operation eq "fix_date")
        {
            my $orig_line = $line;
            #print ("Checking against >>$orig_line<<\n");
            if ($line =~ m/^(Jan(uary|)|Feb(ruary|)|Mar(ch|)|Apr(il|)|May|Jun(e|)|Jul(y|)|Aug(ust|)|Sep(tember|t|)|Oct(ober|)|Nov(ember|)|Dec(ember|)) *(\d{1,2}),{0,1} *(\d{2,4})/im)
            {
                my $year = $14;
                my $oth = $2;
                my $day = $13;
                my $month = uc($1);
                #my $yyyymmdd2 = "yyy=$year,mmm=$month,ddd=$day,ooo=$oth,ooo2=2$oth2,6$oth6,7$oth7,8$oth8,9$oth9,10$oth10,11$oth11,12$oth12,13$oth13,14$oth14,15$oth15,16$oth16,17$oth17,18$oth18,19$oth19,20$oth20,21$oth21,22$oth22,23$oth23,yyy";

                if ($year =~ m/^\d\d$/)
                {
                    $year = "20$year";
                }

                if ($day =~ m/^\d$/)
                {
                    $day = "0$day";
                }

                if ($month eq "JAN") { $month = "01"; }
                if ($month eq "FEB") { $month = "02"; }
                if ($month eq "MAR") { $month = "03"; }
                if ($month eq "APR") { $month = "04"; }
                if ($month eq "MAY") { $month = "05"; }
                if ($month eq "JUN") { $month = "06"; }
                if ($month eq "JUL") { $month = "07"; }
                if ($month eq "AUG") { $month = "08"; }
                if ($month eq "SEP") { $month = "09"; }
                if ($month eq "OCT") { $month = "10"; }
                if ($month eq "NOV") { $month = "11"; }
                if ($month eq "DEC") { $month = "12"; }

                my $yyyymmdd = "$year-$month-$day";
                if ($helper !~ m/^0$/)
                {
                    $yyyymmdd .= "$helper";
                }
                $line =~ s/^(Jan(uary|)|Feb(ruary|)|Mar(ch|)|Apr(il|)|May|Jun(e|)|Jul(y|)|Aug(ust|)|Sep(tember|t|)|Oct(ober|)|Nov(ember|)|Dec(ember|)) *(\d{1,2}),{0,1} *(\d{2,4})/$yyyymmdd/im;
            }

            if ($line =~ m/^(\d{1,2}) (Jan(uary|)|Feb(ruary|)|Mar(ch|)|Apr(il|)|May|Jun(e|)|Jul(y|)|Aug(ust|)|Sep(tember|t|)|Oct(ober|)|Nov(ember|)|Dec(ember|)) (\d{2,4})/im)
            {
                my $year = $14;
                my $day = $1;
                my $month = uc($2);

                if ($year =~ m/^\d\d$/)
                {
                    $year = "20$year";
                }
                if ($day =~ m/^\d$/)
                {
                    $day = "0$day";
                }
                if ($month eq "JAN") { $month = "01"; }
                if ($month eq "FEB") { $month = "02"; }
                if ($month eq "MAR") { $month = "03"; }
                if ($month eq "APR") { $month = "04"; }
                if ($month eq "MAY") { $month = "05"; }
                if ($month eq "JUN") { $month = "06"; }
                if ($month eq "JUL") { $month = "07"; }
                if ($month eq "AUG") { $month = "08"; }
                if ($month eq "SEP") { $month = "09"; }
                if ($month eq "OCT") { $month = "10"; }
                if ($month eq "NOV") { $month = "11"; }
                if ($month eq "DEC") { $month = "12"; }

                my $yyyymmdd = "$year-$month-$day";
                if ($helper !~ m/^0$/)
                {
                    $yyyymmdd .= "$helper";
                }
                $line =~ s/^\d{1,2} (Jan(uary|)|Feb(ruary|)|Mar(ch|)|Apr(il|)|May|Jun(e|)|Jul(y|)|Aug(ust|)|Sep(tember|t|)|Oct(ober|)|Nov(ember|)|Dec(ember|)) \d{2,4}/$yyyymmdd/im;
            }

            print "$line\n";
        }

        if ($operation eq "uniquelines")
        {
            if (!defined ($ulines {$line}))
            {
                $ulines {$line} = 1;
                $ulines_count ++;
                print $line, "\n";
            }
        }

        if ($operation eq "countlines")
        {
            $ulines {$line} ++;
            $ulines_count ++;
        }
        
        if ($operation eq "numlines")
        {
            $ulines_count ++;
        }
    }

    if ($operation eq "transpose")
    {
        my $key;
        my @transpose_array;

        my $blank_line = "";
        my $i;
        my $j;
        for ($j = 0; $j < $transpose_biggest_line; $j++)
        {
            $blank_line .= " ";
        }

        my $i;
        my $j;
        for ($i = 0; $i < $transpose_biggest_col; $i++)
        {
            $transpose_array [$i] = $blank_line;
        }

        foreach $key (sort keys (%transpose_chars)) 
        {
            if ($key =~ m/(\d*),(\d*)/)
            {
                my $i = $1;
                my $chars = $1 - 1;
                my $j = $2;
                my $lines = $j - 1;
                my $da_line = $transpose_array [$lines];
                $da_line =~ s/^(.{$chars})./$1$transpose_chars{$key}/;
                $transpose_array [$lines] = $da_line;
            }
        }

        for ($i = 0; $i < $transpose_biggest_col; $i++)
        {
            my $da_line = $transpose_array [$i];
            print ($da_line, "\n");
        }
    }

    if ($operation eq "age_dir2")
    {
        opendir DIR, $file or die "cannot open dir $file: $!";
        print $file, "\n";
        my $nextFile;
        foreach $nextFile (grep {-f && ($helper > -M)} readdir DIR) 
        {
            if ($nextFile =~ m/$term/)
            {
                print "type $nextFile\n";
            }
        }
    }

    if ($operation eq "age_dir")
    {
        my $i;
        my $cmd = "type ";
        my $next_term = $term;

        for ($i = 0; $i < $helper; $i++) 
        {
            $next_term = $term;
            my $now = time();
            my $yyyymmdd = strftime "%Y%m%d", localtime($now - $i * 24*3600);
            $next_term =~ s/YYYYMMDD/$yyyymmdd/;
            $cmd .= " $next_term ";
        }
        print $cmd;
    }

    if ($operation eq "matrix_flip")
    {
        my $i;
        my $j;
        {
            for ($i = 0; $i < $max_matrix_col; $i++)
            {
                for ($j = 0; $j < $matrix_row; $j++)
                {
                    print ($matrix_flip {"$j,$i"});
                }
                print ("\n");
            }
        }
    }

    if ($operation eq "size")
    {
        print ($total_size, " --- Cumulative total\n");
    }

    close FILE;

    if ($operation eq "strip_http")
    {
        if ($seen_http == 2)
        {
            `tail +$lines_http > /tmp/_cut_file; chmod 777 /tmp/_cut_file`;
            `mv /tmp/_cut_file $file`;
        }
    }

    if ($operation eq "condense")
    {
        if ($condense_count > 1) 
        {
            $condense_line .= " {+similar=$condense_count}"; 
        }
        print $condense_line, "\n";
    }

    if ($operation eq "wordcombos")
    {
        my $v;
        my @keys = keys (%combos);
        my @new_keys;
        my $v = 0;
        my $k;

        foreach $k (@keys)
        {
            if ($k =~ m/,,/) { next; }
            #if ($k !~ m/WHENEVER/) { next; }
            #if ($combos {$k} > 10)
            {
                #push @new_keys, $combos {$k}; # . " ---- " . $k . ",,," . $all_combos {$k};
                push @new_keys, $k;
            }
            $v ++;
        }

        my @jjs = sort @new_keys;
        foreach $k (sort @jjs)
        {
            print $k, "\n";
        }
    }

    if ($operation eq "dedup_line")
    {
        my $k;
        for $k (sort keys (%dedup_line_hash))
        {
            if ($k !~ m/.*:.*/)
            {
                print ("$k ---> $dedup_line_hash{$k}\n");
            }
            if ($k =~ m/(.*):(.*)\s*$/)
            {
                if ($dedup_line_hash{$1} > 7)
                {
                    print ("/h $2\n");
                }
            }
        }
    }

    if ($operation eq "uniquewords")
    {
        my $v;
        my @keys = keys (%combos);
        my @new_keys;
        my $v = 0;
        my $k;

        my $i = 0;
        foreach $k (@keys)
        {
            $i ++;
            print $combos {$k}, ";  $k\n";
        }
    }

    if ($operation eq "countlines")
    {
        my $line;
        #foreach $line (sort {$a <=> $b} values %ulines)
        foreach $line (sort { $a <=> $b } keys (%ulines))
        {
            print  ("$ulines{$line} ==== $line\n");
        }
        print  ("$ulines_count\n");
    }
    
    if ($operation eq "sortn")
    {
        my $line;
        my @lines = sort {$a <=> $b} (keys (%ulines));

        if ($helper eq "reverse")
        {
            @lines = reverse sort {$a <=> $b} (keys (%ulines));
        }
        foreach $line (@lines)
        {
            print  ("$line\n");
        }
        print  ("\nTotal lines found were: $ulines_count\n");
    }
    
    if ($operation eq "sort")
    {
        my $line;
        my @lines = sort (keys (%ulines));

        if ($helper eq "reverse")
        {
            @lines = reverse sort (keys (%ulines));
        }
        foreach $line (@lines)
        {
            print  ("$line\n");
        }
        print  ("\nTotal lines found were: $ulines_count\n");
    }
    
    if ($operation eq "numlines")
    {
        my $line;
        #foreach $line (sort {$a <=> $b} values %ulines)
        print  ("$ulines_count --- $file\n");
    }

    if ($operation eq "get_strings")
    {
        my $k;
        #foreach $k (sort keys (%strings_in_files))
        #{
        #    print "File=$k -- $strings_in_files{$k}\n";
        #}
        foreach $k (sort keys (%files_to_strings))
        {
            if ($count_of_files_to_strings {$k} > 1)
            {
                print "Term seen " . $count_of_files_to_strings {$k} . " times =>$k< -- $files_to_strings{$k}\n";
            }
        }
    }
    
    if ($operation eq "odd")
    {
        my $line;
        $line = "hello old son";
        my $new = $line =~ s/(.)(?{ if ("$1" eq "o") {chr(415)} else {$1} })/$^R/gr;
        print ($new);
    }

    if ($operation eq "letters")
    {
        #open PROC, "cut.pl $file $term $helper $operation |";
        my %as;
        $as {"A"} = 1;
        $as {"B"} = 1;
        $as {"C"} = 1;
        $as {"D"} = 1;
        $as {"E"} = 1;
        $as {"F"} = 1;
        $as {"G"} = 1;
        $as {"H"} = 1;
        $as {"I"} = 1;
        $as {"J"} = 1;
        $as {"K"} = 1;
        $as {"L"} = 1;
        $as {"M"} = 1;
        $as {"N"} = 1;
        $as {"O"} = 1;
        $as {"P"} = 1;
        $as {"Q"} = 1;
        $as {"R"} = 1;
        $as {"S"} = 1;
        $as {"T"} = 1;
        $as {"U"} = 1;
        $as {"V"} = 1;
        $as {"W"} = 1;
        $as {"X"} = 1;
        $as {"Y"} = 1;
        $as {"Z"} = 1;

        my $k;
        foreach $k (sort keys (%as))
        {
            my $k2;
            foreach $k2 (sort keys (%as))
            {
                print "$term$k$k2$helper\n";   
            }
        }
    }

    if ($operation eq "master_mind")
    {
        my %mm;
        my %num_cols_in_mm;

        my %colors;
        $colors {"W"} = 1;
        $colors {"U"} = 1;
        $colors {"B"} = 1;
        $colors {"R"} = 1;
        $colors {"G"} = 1;
        $colors {"Y"} = 1;
        my $orig_helper = $helper;

        my $c = 0;
        my $c1;
        my $c2;
        my $c3;
        my $c4;
        foreach $c1 (sort (keys (%colors)))
        {
            foreach $c2 (sort (keys (%colors)))
            {
                foreach $c3 (sort (keys (%colors)))
                {
                    foreach $c4 (sort (keys (%colors)))
                    {
                        $c++;
                        my $code = "$c1$c2$c3$c4";
                        my $code2 = "$c1$c2$c3$c4";
                        $mm {$code} = 1;

                        my $num_same = 0;
                        if ($c1 eq $c2) { $num_same++; }
                        if ($c1 eq $c3) { $num_same++; }
                        if ($c1 eq $c4) { $num_same++; }
                        if ($c2 eq $c3 && $c2 ne $c1) { $num_same++; }
                        if ($c2 eq $c4 && $c2 ne $c1) { $num_same++; }
                        if ($c3 eq $c4 && $c3 ne $c1 && $c3 ne $c2) { $num_same++; }

                        my $num_cols = 4 - $num_same;
                        $num_cols_in_mm {$code} = $num_cols;
                    }
                }
            }
        }

        my $num_eliminated = 0;
        $term = uc ($term);
        while ($term =~ s/^([WUBRGY][WUBRGY][WUBRGY][WUBRGY])(,|$)//)
        {
            my $guess_orig = $1;
            my $guess = $1;
            my %cols_in_guess;
            my $cols_in_guess_re = "[";
            my $number_cols_in_guess = 0;
            my $number_correct_cols_in_guess = 0;

            while ($guess =~ s/^([WUBRGY])//i)
            {
                my $col = $1;
                if (!defined ($cols_in_guess {$col}))
                {
                    $number_cols_in_guess ++;
                    $cols_in_guess_re .= $col;
                }
                $cols_in_guess {$col}++;
            }

            $cols_in_guess_re .= "]";
            my $real_helper = $helper;
            if ($orig_helper =~ m/^([WUBRGY])([WUBRGY])([WUBRGY])([WUBRGY])/i)
            {
                $real_helper = "0000";

                my $sac_helper = $orig_helper;
                my $sac_guess = $guess_orig;
                my $left_over_answer = "";
                my $left_over_guess = "";
                while ($sac_helper =~ s/^(.)//)
                {
                    my $c = $1;
                    if ($sac_guess =~ m/^$c/i)
                    {
                        $real_helper =~ s/0/2/;
                    }
                    else
                    {
                        $left_over_answer .= "$c";
                        $sac_guess =~ m/^(.)/;
                        $left_over_guess .= "$1";
                    }

                    $sac_guess =~ s/^.//;
                }

                if ($left_over_answer =~ m/W/i && $left_over_guess =~ m/W/i) { $real_helper =~ s/0/1/; }
                if ($left_over_answer =~ m/U/i && $left_over_guess =~ m/U/i) { $real_helper =~ s/0/1/; }
                if ($left_over_answer =~ m/B/i && $left_over_guess =~ m/B/i) { $real_helper =~ s/0/1/; }
                if ($left_over_answer =~ m/R/i && $left_over_guess =~ m/R/i) { $real_helper =~ s/0/1/; }
                if ($left_over_answer =~ m/G/i && $left_over_guess =~ m/G/i) { $real_helper =~ s/0/1/; }
                if ($left_over_answer =~ m/Y/i && $left_over_guess =~ m/Y/i) { $real_helper =~ s/0/1/; }
                print ("  <<<<< $real_helper for $helper ($left_over_answer) vs guess of leftoverguess=$left_over_guess vs guessorig=$guess_orig\n");
                $helper = $real_helper;
            }

            print ("  after <<<<< $helper for $helper vs $guess_orig\n");

            if ($helper =~ s/^([012][012][012][012])(,|$)//)
            {
                #print (" ==============================\n Comparing $1 vs $guess_orig\n");
                my $guess_result = $1;
                my $guess_result_orig = $1;
                my $num_absolutely_correct = 0;
                my $num_half_correct = 0;
                my $num_incorrect = 4;
                #print ("$guess_orig => $guess_result\n");

                while ($guess_result =~ s/1//)
                {
                    $num_half_correct ++;
                    $number_correct_cols_in_guess ++;
                    $num_incorrect --;

                    if ($cols_in_guess {"W"} > 1) { $cols_in_guess {"W"} --; }
                    elsif ($cols_in_guess {"U"} > 1) { $cols_in_guess {"U"} --; }
                    elsif ($cols_in_guess {"B"} > 1) { $cols_in_guess {"B"} --; }
                    elsif ($cols_in_guess {"R"} > 1) { $cols_in_guess {"R"} --; }
                    elsif ($cols_in_guess {"G"} > 1) { $cols_in_guess {"G"} --; }
                    elsif ($cols_in_guess {"Y"} > 1) { $cols_in_guess {"Y"} --; }
                    elsif ($cols_in_guess {"W"} == 1) { $cols_in_guess {"W"} --; }
                    elsif ($cols_in_guess {"U"} == 1) { $cols_in_guess {"U"} --; }
                    elsif ($cols_in_guess {"B"} == 1) { $cols_in_guess {"B"} --; }
                    elsif ($cols_in_guess {"R"} == 1) { $cols_in_guess {"R"} --; }
                    elsif ($cols_in_guess {"G"} == 1) { $cols_in_guess {"G"} --; }
                    elsif ($cols_in_guess {"Y"} == 1) { $cols_in_guess {"Y"} --; }
                }

                while ($guess_result =~ s/2//)
                {
                    $num_absolutely_correct ++;
                    $number_correct_cols_in_guess ++;
                    $num_incorrect --;

                    if ($cols_in_guess {"W"} > 1) { $cols_in_guess {"W"} --; }
                    elsif ($cols_in_guess {"U"} > 1) { $cols_in_guess {"U"} --; }
                    elsif ($cols_in_guess {"B"} > 1) { $cols_in_guess {"B"} --; }
                    elsif ($cols_in_guess {"R"} > 1) { $cols_in_guess {"R"} --; }
                    elsif ($cols_in_guess {"G"} > 1) { $cols_in_guess {"G"} --; }
                    elsif ($cols_in_guess {"Y"} > 1) { $cols_in_guess {"Y"} --; }
                    elsif ($cols_in_guess {"W"} == 1) { $cols_in_guess {"W"} --; }
                    elsif ($cols_in_guess {"U"} == 1) { $cols_in_guess {"U"} --; }
                    elsif ($cols_in_guess {"B"} == 1) { $cols_in_guess {"B"} --; }
                    elsif ($cols_in_guess {"R"} == 1) { $cols_in_guess {"R"} --; }
                    elsif ($cols_in_guess {"G"} == 1) { $cols_in_guess {"G"} --; }
                    elsif ($cols_in_guess {"Y"} == 1) { $cols_in_guess {"Y"} --; }
                }

                my $col;
                foreach $col (sort (keys (%cols_in_guess)))
                {
                    #print ("$col => $cols_in_guess{$col}\n");
                }

                my $min_number_cols_correct_in_guess = 4;
                $min_number_cols_correct_in_guess -= $cols_in_guess {"W"};
                $min_number_cols_correct_in_guess -= $cols_in_guess {"U"};
                $min_number_cols_correct_in_guess -= $cols_in_guess {"B"};
                $min_number_cols_correct_in_guess -= $cols_in_guess {"R"};
                $min_number_cols_correct_in_guess -= $cols_in_guess {"G"};
                $min_number_cols_correct_in_guess -= $cols_in_guess {"Y"};
                #print (" xxxx  min_number_cols_correct_in_guess  = $min_number_cols_correct_in_guess\n");

                my $all_correct;
                if ($min_number_cols_correct_in_guess == 4)
                {
                    $all_correct = "^[$guess_orig][$guess_orig][$guess_orig][$guess_orig]\$";
                }

                if ($num_absolutely_correct == 4)
                {
                    print ("Solution was: $guess_orig\n");
                    exit;
                }
                else
                {
                    if ($mm {$guess_orig} == 1)
                    {
                        print (" yyy Eliminate $guess_orig\n");
                        $num_eliminated ++;
                        $mm {$guess_orig} = 0;
                    }
                }

                if ($num_incorrect == 4)
                {
                    my $code;
                    foreach $code (sort (keys (%mm)))
                    {
                        if ($code =~ m/$cols_in_guess_re/)
                        {
                            if ($mm {$code} == 1)
                            {
                                $num_eliminated ++;
                                print ("## $code has no matching colours [$cols_in_guess_re]\n");
                            }
                            $mm {$code} = 0;
                        }
                    }
                }

                my $partial_count = 0;
                my $check_partial;
                while ($partial_count + $num_incorrect < 4)
                {
                    # check what must exist in solution
                    $check_partial .= $cols_in_guess_re . ".*";
                    $partial_count++;
                }

                print ("Partial count = $partial_count -- $check_partial -- $min_number_cols_correct_in_guess\n");
                if ($partial_count > 0)
                {
                    my $code;
                    foreach $code (sort (keys (%mm)))
                    {
                        if ($mm {$code} == 1 && $min_number_cols_correct_in_guess > $num_cols_in_mm {$code} && $min_number_cols_correct_in_guess < 4)
                        {
                            $num_eliminated ++;
                            print ("## $code too few colors so elimimate it [$num_cols_in_mm{$code} vs $min_number_cols_correct_in_guess]\n");
                            #$mm {$code} = 0;
                            #$num_eliminated ++;
                        }

                        if ($mm {$code} == 1 && $min_number_cols_correct_in_guess == 4)
                        {
                            if ($code !~ m/$all_correct/img)
                            {
                                $num_eliminated ++;
                                print ("## all right but code ($code) doesn't match $all_correct\n");
                                $mm {$code} = 0;
                            }
                        }

                        if ($mm {$code} == 1 && !($code =~ m/$check_partial/))
                        {
                            $num_eliminated ++;
                            print ("## $code partial elimimate [$check_partial] for $partial_count\n");
                            $mm {$code} = 0;
                        }

                    }
                }

                # all greys!
                if ($num_absolutely_correct == 0 && $num_half_correct > 0)
                {
                    my $code;
                    $guess_orig =~ m/(.)(.)(.)(.)/;

                    my $a = $1;
                    my $b = $2;
                    my $c = $3;
                    my $d = $4;

                    my $wrong_1 = "$a...";
                    my $wrong_2 = ".$b..";
                    my $wrong_3 = "..$c.";
                    my $wrong_4 = "...$d";

                    foreach $code (sort (keys (%mm)))
                    {
                        if ($code =~ m/$wrong_1/ || $code =~ m/$wrong_2/ || $code =~ m/$wrong_3/ || $code =~ m/$wrong_4/)
                        {
                            if ($mm {$code} == 1)
                            {
                                $num_eliminated ++;
                                print (" >>> Wrong bead in position ($code) vs $guess_orig\n");
                            }
                            $mm {$code} = 0;
                        }
                    }
                }
                
                # more than 1 partially correct
                if ($num_half_correct > 1)
                {
                    my $code;
                    $guess_orig =~ m/(.)(.)(.)(.)/;

                    my $a = $1;
                    my $b = $2;
                    my $c = $3;
                    my $d = $4;

                    my $right_1 = "($a.*$b|$a.*$c|$a.*$d|$b.*$c|$b.*$d|$c.*$d)";
                    my $right_2 = "($b.*$a|$c.*$a|$d.*$a|$c.*$b|$d.*$b|$d.*$c)";

                    foreach $code (sort (keys (%mm)))
                    {
                        if (!($code =~ m/$right_1/ || $code =~ m/$right_2/))
                        {
                            if ($mm {$code} == 1)
                            {
                                $num_eliminated ++;
                                print (" >>> Multi Partial elim ($code) vs $guess_orig\n");
                            }
                            $mm {$code} = 0;
                        }
                    }
                }
                
                # more than 2 partially correct
                if ($num_half_correct > 2)
                {
                    my $code;
                    $guess_orig =~ m/(.)(.)(.)(.)/;

                    my $a = $1;
                    my $b = $2;
                    my $c = $3;
                    my $d = $4;

                    my $right_1 = "($a.*$b.*$c|$a.*$b.*$d|$a.*$c.*$b|$a.*$c.*$d|$a.*$d.*$b|$a.*$d.*$c|$b.*$a.*$c|$b.*$a.*$d|$b.*$c.*$a|$b.*$c.*$d|$b.*$d.*$a|$b.*$d.*$c|$c.*$a.*$b|$c.*$a.*$d|$c.*$b.*$a|$c.*$b.*$d|$c.*$d.*$a|$c.*$d.*$b|$d.*$a.*$b|$d.*$a.*$c|$d.*$b.*$a|$d.*$b.*$c|$d.*$c.*$a|$d.*$c.*$b)";

                    foreach $code (sort (keys (%mm)))
                    {
                        if (!($code =~ m/$right_1/))
                        {
                            if ($mm {$code} == 1)
                            {
                                $num_eliminated ++;
                                print (" >>> Tri Partial elim ($code) vs $guess_orig\n");
                            }
                            $mm {$code} = 0;
                        }
                    }
                }

                if ($num_absolutely_correct == 1 && $num_half_correct == 0)
                {
                    my $code;
                    $guess_orig =~ m/(.)(.)(.)(.)/;

                    my $a = $1;
                    my $b = $2;
                    my $c = $3;
                    my $d = $4;

                    my $wrong_1a = "$a" . "[$b$c$d]..";
                    my $wrong_1b = "$a" . ".[$b$c$d].";
                    my $wrong_1c = "$a" . "..[$b$c$d]";

                    my $wrong_2a = "[$a$c$d]$b" . "..";
                    my $wrong_2b = ".$b" . "[$a$c$d].";
                    my $wrong_2c = ".$b" . ".[$a$c$d]";

                    my $wrong_3a = "[$a$b$d].$c" . ".";
                    my $wrong_3b = ".[$a$b$d]$c" . ".";
                    my $wrong_3c = "..$c" . "[$a$b$d]";

                    my $wrong_4a = "[$a$b$c].." . "$d";
                    my $wrong_4b = ".[$a$b$c]." . "$d";
                    my $wrong_4c = "..[$a$b$c]" . "$d";

                    foreach $code (sort (keys (%mm)))
                    {
                        if ($code =~ m/$wrong_1a/ || $code =~ m/$wrong_1b/ || $code =~ m/$wrong_1c/ || 
                            $code =~ m/$wrong_2a/ || $code =~ m/$wrong_2b/ || $code =~ m/$wrong_2c/ || 
                            $code =~ m/$wrong_3a/ || $code =~ m/$wrong_3b/ || $code =~ m/$wrong_3c/ || 
                            $code =~ m/$wrong_4a/ || $code =~ m/$wrong_4b/ || $code =~ m/$wrong_4c/)
                        {
                            if ($mm {$code} == 1)
                            {
                                print (">> Single elim $code\n");
                                $num_eliminated ++;
                            }
                            $mm {$code} = 0;
                        }
                    }
                }
                
                if ($num_absolutely_correct == 0 && $num_half_correct == 1)
                {
                    my $code;
                    $guess_orig =~ m/(.)(.)(.)(.)/;

                    my $a = $1;
                    my $b = $2;
                    my $c = $3;
                    my $d = $4;

                    my $wrong_1 = "($a.*$b|$a.*$c|$a.*$d|$b.*$c|$b.*$d|$c.*$d)";
                    my $wrong_2 = "($b.*$a|$c.*$a|$d.*$a|$c.*$b|$d.*$b|$d.*$c)";

                    foreach $code (sort (keys (%mm)))
                    {
                        if ($code =~ m/$wrong_1/ || $code =~ m/$wrong_2/)
                        {
                            if ($mm {$code} == 1)
                            {
                                print (">> Single elim partial $code\n");
                                $num_eliminated ++;
                            }
                            $mm {$code} = 0;
                        }
                    }
                }
                
                if ($num_absolutely_correct == 2 && $num_half_correct == 2)
                {
                    my $code;
                    $guess_orig =~ m/(.)(.)(.)(.)/;

                    my $a = $1;
                    my $b = $2;
                    my $c = $3;
                    my $d = $4;

                    my $right_1 = "$a$b$d$c";
                    my $right_2 = "$a$c$b$d";
                    my $right_3 = "$a$d$c$b";
                    my $right_4 = "$b$a$c$d";
                    my $right_5 = "$c$b$a$d";
                    my $right_6 = "$d$b$c$a";

                    foreach $code (sort (keys (%mm)))
                    {
                        if (!($code =~ m/$right_1/ || $code =~ m/$right_2/ || $code =~ m/$right_3/ || $code =~ m/$right_4/ || $code =~ m/$right_5/ || $code =~ m/$right_6/))
                        {
                            if ($mm {$code} == 1)
                            {
                                $num_eliminated ++;
                            }
                            $mm {$code} = 0;
                        }
                    }
                }

                # some blacks!
                if ($num_absolutely_correct >= 1)
                {
                    my $code;
                    my $right_1 = $guess_orig; $right_1 =~ s/...$/.../;
                    my $right_2 = $guess_orig; $right_2 =~ s/^././;  $right_2 =~ s/..$/../;
                    my $right_3 = $guess_orig; $right_3 =~ s/^../../ ;$right_3 =~ s/.$/./;
                    my $right_4 = $guess_orig; $right_4 =~ s/^.../.../;

                    foreach $code (sort (keys (%mm)))
                    {
                        if (!($code =~ m/$right_1/ || $code =~ m/$right_2/ || $code =~ m/$right_3/ || $code =~ m/$right_4/))
                        {
                            if ($mm {$code} == 1)
                            {
                                $num_eliminated ++;
                                print (" >>> Has to have a given bead in position ($code) vs $guess_orig\n");
                            }
                            $mm {$code} = 0;
                        }

                    }
                }

                if ($num_absolutely_correct >= 2)
                {
                    my $code;
                    my $right_1 = $guess_orig; $right_1 =~ s/^(.)(.)../$1$2../;
                    my $right_2 = $guess_orig; $right_2 =~ s/^(.).(.)./$1.$2./;
                    my $right_3 = $guess_orig; $right_3 =~ s/^(.)..(.)/$1..$2/;
                    my $right_4 = $guess_orig; $right_4 =~ s/^.(.).(.)/.$1.$2/;
                    my $right_5 = $guess_orig; $right_5 =~ s/^.(.)(.)./.$1$2./;
                    my $right_6 = $guess_orig; $right_6 =~ s/^..(.)(.)/..$1$2/;

                    foreach $code (sort (keys (%mm)))
                    {
                        if (!($code =~ m/$right_1/ || $code =~ m/$right_2/ || $code =~ m/$right_3/ || $code =~ m/$right_4/ || $code =~ m/$right_5/ || $code =~ m/$right_6/))
                        {
                            if ($mm {$code} == 1)
                            {
                                $num_eliminated ++;
                                print (" >>> multi Has to have a given bead in position ($code) vs $guess_orig\n");
                            }
                            $mm {$code} = 0;
                        }

                    }
                }

                if ($num_absolutely_correct >= 3)
                {
                    my $code;
                    my $right_1 = $guess_orig; $right_1 =~ s/^(.)(.)(.)./$1$2$3./;
                    my $right_2 = $guess_orig; $right_2 =~ s/^(.)(.).(.)/$1$2.$3/;
                    my $right_3 = $guess_orig; $right_3 =~ s/^(.).(.)(.)/$1.$2$3/;
                    my $right_4 = $guess_orig; $right_4 =~ s/^.(.)(.)(.)/.$1$2$3/;

                    foreach $code (sort (keys (%mm)))
                    {
                        if (!($code =~ m/$right_1/ || $code =~ m/$right_2/ || $code =~ m/$right_3/ || $code =~ m/$right_4/))
                        {
                            if ($mm {$code} == 1)
                            {
                                $num_eliminated ++;
                                print (" >>> trimulti Has to have a given bead in position ($code) vs $guess_orig\n");
                            }
                            $mm {$code} = 0;
                        }

                    }
                }

                my $left_over = 0;
                my $code;
                foreach $code (sort (keys (%mm)))
                {
                    $left_over += $mm {$code};
                }

                #print ("Checked: $check_partial - $num_eliminated were eliminated (vs $left_over remaining)\n");
            }
        }

        my $code;
        foreach $code (sort (keys (%mm)))
        {
            if ($mm {$code} == 1)
            {
                print ("Possible solution = $code\n");
            }
        }
    }

    if ($operation eq "master_mind_code")
    {
        my $next_guess;
        for (my $i = 0; $i < 4; $i++)
        {
            my $n = int (rand (6));
            if ($n == 0) { $next_guess .= "W"; }
            if ($n == 1) { $next_guess .= "U"; }
            if ($n == 2) { $next_guess .= "B"; }
            if ($n == 3) { $next_guess .= "R"; }
            if ($n == 4) { $next_guess .= "G"; }
            if ($n == 5) { $next_guess .= "Y"; }
        }
        print ("\nCode= $next_guess\n");
    }




    if ($operation eq "d3_code")
    {
        print (">>>>$first_d3_line\n");
        print (">>>>$d3_line_length\n");
        my $orig_d3_lines = $d3_lines;
        while ($d3_lines =~ s/[^\.0123456789ABCDEFGHIJ](.{138,140})0/z$1A/) { }
        while ($d3_lines =~ s/[^\.0123456789ABCDEFGHIJ](.{138,140})1/z$1B/) { }
        while ($d3_lines =~ s/[^\.0123456789ABCDEFGHIJ](.{138,140})2/z$1C/) { }
        while ($d3_lines =~ s/[^\.0123456789ABCDEFGHIJ](.{138,140})3/z$1D/) { }
        while ($d3_lines =~ s/[^\.0123456789ABCDEFGHIJ](.{138,140})4/z$1E/) { }
        while ($d3_lines =~ s/[^\.0123456789ABCDEFGHIJ](.{138,140})5/z$1F/) { }
        while ($d3_lines =~ s/[^\.0123456789ABCDEFGHIJ](.{138,140})6/z$1G/) { }
        while ($d3_lines =~ s/[^\.0123456789ABCDEFGHIJ](.{138,140})7/z$1H/) { }
        while ($d3_lines =~ s/[^\.0123456789ABCDEFGHIJ](.{138,140})8/z$1I/) { }
        while ($d3_lines =~ s/[^\.0123456789ABCDEFGHIJ](.{138,140})9/z$1J/) { }

        #while ($d3_lines =~ s/(\d)(.{138,140})[^\.0123456789z]/$1$2z/) { }
        while ($d3_lines =~ s/0(.{138,140})[^\.0123456789ABCDEFGHIJ]/A$1z/) { }
        while ($d3_lines =~ s/1(.{138,140})[^\.0123456789ABCDEFGHIJ]/B$1z/) { }
        while ($d3_lines =~ s/2(.{138,140})[^\.0123456789ABCDEFGHIJ]/C$1z/) { }
        while ($d3_lines =~ s/3(.{138,140})[^\.0123456789ABCDEFGHIJ]/D$1z/) { }
        while ($d3_lines =~ s/4(.{138,140})[^\.0123456789ABCDEFGHIJ]/E$1z/) { }
        while ($d3_lines =~ s/5(.{138,140})[^\.0123456789ABCDEFGHIJ]/F$1z/) { }
        while ($d3_lines =~ s/6(.{138,140})[^\.0123456789ABCDEFGHIJ]/G$1z/) { }
        while ($d3_lines =~ s/7(.{138,140})[^\.0123456789ABCDEFGHIJ]/H$1z/) { }
        while ($d3_lines =~ s/8(.{138,140})[^\.0123456789ABCDEFGHIJ]/I$1z/) { }
        while ($d3_lines =~ s/9(.{138,140})[^\.0123456789ABCDEFGHIJ]/J$1z/) { }

        #while ($d3_lines =~ s/(\d)[^\.0123456789z]/$1z/) { }
        while ($d3_lines =~ s/0[^\.0123456789ABCDEFGHIJ]/Az/) { }
        while ($d3_lines =~ s/1[^\.0123456789ABCDEFGHIJ]/Bz/) { }
        while ($d3_lines =~ s/2[^\.0123456789ABCDEFGHIJ]/Cz/) { }
        while ($d3_lines =~ s/3[^\.0123456789ABCDEFGHIJ]/Dz/) { }
        while ($d3_lines =~ s/4[^\.0123456789ABCDEFGHIJ]/Ez/) { }
        while ($d3_lines =~ s/5[^\.0123456789ABCDEFGHIJ]/Fz/) { }
        while ($d3_lines =~ s/6[^\.0123456789ABCDEFGHIJ]/Gz/) { }
        while ($d3_lines =~ s/7[^\.0123456789ABCDEFGHIJ]/Hz/) { }
        while ($d3_lines =~ s/8[^\.0123456789ABCDEFGHIJ]/Iz/) { }
        while ($d3_lines =~ s/9[^\.0123456789ABCDEFGHIJ]/Jz/) { }

        while ($d3_lines =~ s/[^\.0123456789ABCDEFGHIJ]0/zA/) { }
        while ($d3_lines =~ s/[^\.0123456789ABCDEFGHIJ]1/zB/) { }
        while ($d3_lines =~ s/[^\.0123456789ABCDEFGHIJ]2/zC/) { }
        while ($d3_lines =~ s/[^\.0123456789ABCDEFGHIJ]3/zD/) { }
        while ($d3_lines =~ s/[^\.0123456789ABCDEFGHIJ]4/zE/) { }
        while ($d3_lines =~ s/[^\.0123456789ABCDEFGHIJ]5/zF/) { }
        while ($d3_lines =~ s/[^\.0123456789ABCDEFGHIJ]6/zG/) { }
        while ($d3_lines =~ s/[^\.0123456789ABCDEFGHIJ]7/zH/) { }
        while ($d3_lines =~ s/[^\.0123456789ABCDEFGHIJ]8/zI/) { }
        while ($d3_lines =~ s/[^\.0123456789ABCDEFGHIJ]9/zJ/) { }

        $d3_lines = do_d3_replace ($d3_lines);
        $d3_lines = do_d3_replace ($d3_lines);
        $d3_lines = do_d3_replace ($d3_lines);
        $d3_lines = do_d3_replace ($d3_lines);

        my $equation_d3_lines = $d3_lines; 
        $equation_d3_lines =~ s/[^ABCDEFGHIJ]+/ + /g;
        $equation_d3_lines =~ s/A/0/g;
        $equation_d3_lines =~ s/B/1/g;
        $equation_d3_lines =~ s/C/2/g;
        $equation_d3_lines =~ s/D/3/g;
        $equation_d3_lines =~ s/E/4/g;
        $equation_d3_lines =~ s/F/5/g;
        $equation_d3_lines =~ s/G/6/g;
        $equation_d3_lines =~ s/H/7/g;
        $equation_d3_lines =~ s/I/8/g;
        $equation_d3_lines =~ s/J/9/g;
        $equation_d3_lines .= " + 0";
        $equation_d3_lines =~ s/ //g;
        $equation_d3_lines =~ s/\+\+/+/g;
        print $equation_d3_lines, "\n=";
        print (eval ($equation_d3_lines));

        while ($d3_lines =~ s/^(.{140})//)
        {
            #print $1, "\n";
        }
        print "\n=======================\n";
        while ($orig_d3_lines =~ s/^(.{140})//)
        {
            #print $1, "\n";
        }
    }

    if ($operation eq "d3_code_p2")
    {
        print (">>>>$first_d3_line\n");
        print (">>>>$d3_line_length\n");

        my $orig_d3_lines = $d3_lines;

        while ($d3_lines =~ s/\*(.{138,140})0/z$1A/) { }
        while ($d3_lines =~ s/\*(.{138,140})1/z$1B/) { }
        while ($d3_lines =~ s/\*(.{138,140})2/z$1C/) { }
        while ($d3_lines =~ s/\*(.{138,140})3/z$1D/) { }
        while ($d3_lines =~ s/\*(.{138,140})4/z$1E/) { }
        while ($d3_lines =~ s/\*(.{138,140})5/z$1F/) { }
        while ($d3_lines =~ s/\*(.{138,140})6/z$1G/) { }
        while ($d3_lines =~ s/\*(.{138,140})7/z$1H/) { }
        while ($d3_lines =~ s/\*(.{138,140})8/z$1I/) { }
        while ($d3_lines =~ s/\*(.{138,140})9/z$1J/) { }

        #while ($d3_lines =~ s/(\d)(.{138,140})\*/$1$2z/) { }
        while ($d3_lines =~ s/0(.{138,140})\*/A$1z/) { }
        while ($d3_lines =~ s/1(.{138,140})\*/B$1z/) { }
        while ($d3_lines =~ s/2(.{138,140})\*/C$1z/) { }
        while ($d3_lines =~ s/3(.{138,140})\*/D$1z/) { }
        while ($d3_lines =~ s/4(.{138,140})\*/E$1z/) { }
        while ($d3_lines =~ s/5(.{138,140})\*/F$1z/) { }
        while ($d3_lines =~ s/6(.{138,140})\*/G$1z/) { }
        while ($d3_lines =~ s/7(.{138,140})\*/H$1z/) { }
        while ($d3_lines =~ s/8(.{138,140})\*/I$1z/) { }
        while ($d3_lines =~ s/9(.{138,140})\*/J$1z/) { }

        #while ($d3_lines =~ s/(\d)\*/$1z/) { }
        while ($d3_lines =~ s/0\*/Az/) { }
        while ($d3_lines =~ s/1\*/Bz/) { }
        while ($d3_lines =~ s/2\*/Cz/) { }
        while ($d3_lines =~ s/3\*/Dz/) { }
        while ($d3_lines =~ s/4\*/Ez/) { }
        while ($d3_lines =~ s/5\*/Fz/) { }
        while ($d3_lines =~ s/6\*/Gz/) { }
        while ($d3_lines =~ s/7\*/Hz/) { }
        while ($d3_lines =~ s/8\*/Iz/) { }
        while ($d3_lines =~ s/9\*/Jz/) { }

        while ($d3_lines =~ s/\*0/zA/) { }
        while ($d3_lines =~ s/\*1/zB/) { }
        while ($d3_lines =~ s/\*2/zC/) { }
        while ($d3_lines =~ s/\*3/zD/) { }
        while ($d3_lines =~ s/\*4/zE/) { }
        while ($d3_lines =~ s/\*5/zF/) { }
        while ($d3_lines =~ s/\*6/zG/) { }
        while ($d3_lines =~ s/\*7/zH/) { }
        while ($d3_lines =~ s/\*8/zI/) { }
        while ($d3_lines =~ s/\*9/zJ/) { }

        $d3_lines = do_d3_replace ($d3_lines);
        $d3_lines = do_d3_replace ($d3_lines);
        $d3_lines = do_d3_replace ($d3_lines);
        $d3_lines = do_d3_replace ($d3_lines);

        # SECOND PASS!!
        while ($d3_lines =~ s/z(.{138,140})0/Z$1A/) { }
        while ($d3_lines =~ s/z(.{138,140})1/Z$1B/) { }
        while ($d3_lines =~ s/z(.{138,140})2/Z$1C/) { }
        while ($d3_lines =~ s/z(.{138,140})3/Z$1D/) { }
        while ($d3_lines =~ s/z(.{138,140})4/Z$1E/) { }
        while ($d3_lines =~ s/z(.{138,140})5/Z$1F/) { }
        while ($d3_lines =~ s/z(.{138,140})6/Z$1G/) { }
        while ($d3_lines =~ s/z(.{138,140})7/Z$1H/) { }
        while ($d3_lines =~ s/z(.{138,140})8/Z$1I/) { }
        while ($d3_lines =~ s/z(.{138,140})9/Z$1J/) { }

        #while ($d3_lines =~ s/(\d)(.{138,140})z/$1$2Z/) { }
        while ($d3_lines =~ s/0(.{138,140})z/A$1Z/) { }
        while ($d3_lines =~ s/1(.{138,140})z/B$1Z/) { }
        while ($d3_lines =~ s/2(.{138,140})z/C$1Z/) { }
        while ($d3_lines =~ s/3(.{138,140})z/D$1Z/) { }
        while ($d3_lines =~ s/4(.{138,140})z/E$1Z/) { }
        while ($d3_lines =~ s/5(.{138,140})z/F$1Z/) { }
        while ($d3_lines =~ s/6(.{138,140})z/G$1Z/) { }
        while ($d3_lines =~ s/7(.{138,140})z/H$1Z/) { }
        while ($d3_lines =~ s/8(.{138,140})z/I$1Z/) { }
        while ($d3_lines =~ s/9(.{138,140})z/J$1Z/) { }

        #while ($d3_lines =~ s/(\d)z/$1Z/) { }
        while ($d3_lines =~ s/0z/AZ/) { }
        while ($d3_lines =~ s/1z/BZ/) { }
        while ($d3_lines =~ s/2z/CZ/) { }
        while ($d3_lines =~ s/3z/DZ/) { }
        while ($d3_lines =~ s/4z/EZ/) { }
        while ($d3_lines =~ s/5z/FZ/) { }
        while ($d3_lines =~ s/6z/GZ/) { }
        while ($d3_lines =~ s/7z/HZ/) { }
        while ($d3_lines =~ s/8z/IZ/) { }
        while ($d3_lines =~ s/9z/JZ/) { }

        while ($d3_lines =~ s/z0/ZA/) { }
        while ($d3_lines =~ s/z1/ZB/) { }
        while ($d3_lines =~ s/z2/ZC/) { }
        while ($d3_lines =~ s/z3/ZD/) { }
        while ($d3_lines =~ s/z4/ZE/) { }
        while ($d3_lines =~ s/z5/ZF/) { }
        while ($d3_lines =~ s/z6/ZG/) { }
        while ($d3_lines =~ s/z7/ZH/) { }
        while ($d3_lines =~ s/z8/ZI/) { }
        while ($d3_lines =~ s/z9/ZJ/) { }

        $d3_lines = do_d3_replace ($d3_lines);
        $d3_lines = do_d3_replace ($d3_lines);
        $d3_lines = do_d3_replace ($d3_lines);
        $d3_lines = do_d3_replace ($d3_lines);

        my $equation_d3_lines = $d3_lines; 
        $equation_d3_lines =~ s/[^ABCDEFGHIJZ]+/ + /g;
        $equation_d3_lines =~ s/A/0/g;
        $equation_d3_lines =~ s/B/1/g;
        $equation_d3_lines =~ s/C/2/g;
        $equation_d3_lines =~ s/D/3/g;
        $equation_d3_lines =~ s/E/4/g;
        $equation_d3_lines =~ s/F/5/g;
        $equation_d3_lines =~ s/G/6/g;
        $equation_d3_lines =~ s/H/7/g;
        $equation_d3_lines =~ s/I/8/g;
        $equation_d3_lines =~ s/J/9/g;
        $equation_d3_lines .= " + 0";
        $equation_d3_lines =~ s/ //g;
        $equation_d3_lines =~ s/\+\+/+/g;
        print $equation_d3_lines, "\n=";
        print (eval ($equation_d3_lines));

        while ($d3_lines =~ s/(.......)(.{133})(...)Z(...)(.{133})(.......)/$1$2$3Y$4$5$6/)
        {
            print "\n==================\n$1\n$3*$4\n$6\n";
            my $top_row = $1;
            my $mid_row = "$3*$4";
            my $bot_row = "$6";

            $top_row =~ s/^(....\.)../$1../;
            $top_row =~ s/^..(\.....)/..$1/;
            $mid_row =~ s/^(....\.)../$1../;
            $mid_row =~ s/^..(\.....)/..$1/;
            $bot_row =~ s/^(....\.)../$1../;
            $bot_row =~ s/^..(\.....)/..$1/;

            $top_row =~ s/^(.....)\../$1../;
            $top_row =~ s/^.\.(.....)/..$1/;
            $bot_row =~ s/^(.....)\../$1../;
            $bot_row =~ s/^.\.(.....)/..$1/;
            $mid_row =~ s/^(.....)\../$1../;
            $mid_row =~ s/^.\.(.....)/..$1/;

            #my $x = "$1$3$4$6";
            my $x = "$top_row$mid_row$bot_row";
            print $x, "\n";
            $x =~ s/[^ABCDEFGHIJ]+/ /g;
            
            $x =~ s/[0-9]//g;
            $x =~ s/A/0/g;
            $x =~ s/B/1/g;
            $x =~ s/C/2/g;
            $x =~ s/D/3/g;
            $x =~ s/E/4/g;
            $x =~ s/F/5/g;
            $x =~ s/G/6/g;
            $x =~ s/H/7/g;
            $x =~ s/I/8/g;
            $x =~ s/J/9/g;
            $x =~ s/([0-9]) ([0-9])/$1 * $2/g;
            $x =~ s/([0-9]{3})([0-9]{3})/$1 * $2/g;
            $d3_p2_equation .= "$x + ";
            print $x, "\n";
        }
        $d3_p2_equation .= " 0";

        while ($d3_lines =~ s/^(.{140})//)
        {
            print $1, "\n";
        }
        print "\n=======================\n";
        while ($orig_d3_lines =~ s/^(.{140})//)
        {
            print $1, "\n";
        }
        print ($d3_p2_equation, "\n ==>> ");
        print (eval ($d3_p2_equation));
    }
    
    my $x = 0;
    my $xyz_string;

    while ($x < $call_number)
    {
        my $y = $calls{$x};
        $y =~ s/^(.).*/$1,/;
        $xyz_string .= $y;
        $x ++;
    }
    $xyz_string =~ s/,$/./g;
    $xyz_string =~ s/B/-/img;
    $xyz_string =~ s/B/-/img;
    print $xyz_string;
}
