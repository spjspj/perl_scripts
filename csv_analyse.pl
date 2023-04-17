#!/usr/bin/perl
##
#   File : csv_analyse.pl
#   Date : 12/Apr/2023
#   Author : spjspj
#   Purpose : Analyse CSV data ingested..
##

use strict;
use POSIX;
use LWP::Simple;
use Socket;
use File::Copy;
use Math::Trig;

my %csv_data;
my $csv_block;
my %meta_data;
my %calculated_data;
my %col_roundings;
my $max_field_num = 0;
my $max_rows = 0;
my %col_types;
my $show_formulas = 0;

#####
sub write_to_socket
{
    my $sock_ref = $_ [0];
    my $msg_body = $_ [1];
    my $form = $_ [2];
    my $redirect = $_ [3];
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    my $yyyymmddhhmmss = sprintf "%.4d%.2d%.2d-%.2d%.2d%.2d", $year+1900, $mon+1, $mday, $hour,  $min, $sec;
    print $yyyymmddhhmmss, "\n";

    $msg_body = $msg_body;

    my $header;
    if ($redirect =~ m/^redirect/i)
    {
        $header = "HTTP/1.1 301 Moved\nLocation: /csv_analyse/\nLast-Modified: $yyyymmddhhmmss\nConnection: close\nContent-Type: text/html; charset=UTF-8\nContent-Length: " . length ($msg_body) . "\n\n";
    }
    elsif ($redirect =~ m/^noredirect/i)
    {
        $header = "HTTP/1.1 200 OK\nLast-Modified: $yyyymmddhhmmss\nConnection: close\nContent-Type: text/html; charset=UTF-8\nContent-Length: " . length ($msg_body) . "\n\n";
    }

    $msg_body =~ s/\n\n/\n/mig;
    $msg_body =~ s/\n\n/\n/mig;
    $msg_body =~ s/\n\n/\n/mig;
    $msg_body = $header . $msg_body;
    $msg_body =~ s/\.png/\.npg/;
    $msg_body =~ s/img/mgi/;
    $msg_body .= chr(13) . chr(10) . "0";
    print ("\n===========\nWrite to socket: ", length($msg_body), " characters!\n==========\n");
    syswrite ($sock_ref, $msg_body);
}

sub read_from_socket
{
    my $sock_ref = $_ [0];
    my $ch = "";
    my $prev_ch = "";
    my $header = "";
    my $rin = "";
    my $rout;
    my $isPost = 0;
    my $done_expected_content_len = 0;
    my $expected_content_len = 0;
    my $old_expected_content_len = 0;
    my $seen_content_len = -2;
    my $content = "";

    vec ($rin, fileno ($sock_ref), 1) = 1;

    # Read the message header
    while (((!(ord ($ch) == 13 and ord ($prev_ch) == 10)) && !$isPost) || ($isPost && $seen_content_len < $expected_content_len))
    {
        if (select ($rout=$rin, undef, undef, 200) == 1)
        {
            $prev_ch = $ch;
            if (sysread ($sock_ref, $ch, 1) < 1)
            {
                return "resend";
            }

            $header .= $ch;
            if (!$isPost && $header =~ m/POST/img)
            {
                $isPost = 1;
            }
        }
        
        if ($seen_content_len >= -1)
        {
            $seen_content_len ++;
            $content .= $ch;
        }
        if (ord ($ch) == 13 and ord ($prev_ch) == 10)
        {
            $seen_content_len = -1;
        }

        if ($isPost == 1 && $done_expected_content_len == 0)
        {
            if ($header =~ m/Content.Length: (\d+)/im)
            {
                $expected_content_len = $1; 
                if ($old_expected_content_len < $expected_content_len)
                {
                    $old_expected_content_len = $expected_content_len;
                }
                else
                {
                    $done_expected_content_len = 1;
                }
            }
        }
        
        #if ($isPost && $done_expected_content_len )
        #{
        #    #print ("$done_expected_content_len ($expected_content_len vs $seen_content_len )SO FAR IN POST: >$header<\n");
        #}
    }
    return $header;
}

my %field_letters;
$field_letters {"A"} = 0;
$field_letters {"B"} = 1;
$field_letters {"C"} = 2;
$field_letters {"D"} = 3;
$field_letters {"E"} = 4;
$field_letters {"F"} = 5;
$field_letters {"G"} = 6;
$field_letters {"H"} = 7;
$field_letters {"I"} = 8;
$field_letters {"J"} = 9;
$field_letters {"K"} = 10;
$field_letters {"L"} = 11;
$field_letters {"M"} = 12;
$field_letters {"N"} = 13;
$field_letters {"O"} = 14;
$field_letters {"P"} = 15;
$field_letters {"Q"} = 16;
$field_letters {"R"} = 17;
$field_letters {"S"} = 18;
$field_letters {"T"} = 19;
$field_letters {"U"} = 20;
$field_letters {"V"} = 21;
$field_letters {"W"} = 22;
$field_letters {"X"} = 23;
$field_letters {"Y"} = 24;
$field_letters {"Z"} = 25;

$field_letters {0} = "A";
$field_letters {1} = "B";
$field_letters {2} = "C";
$field_letters {3} = "D";
$field_letters {4} = "E";
$field_letters {5} = "F";
$field_letters {6} = "G";
$field_letters {7} = "H";
$field_letters {8} = "I";
$field_letters {9} = "J";
$field_letters {10} = "K";
$field_letters {11} = "L";
$field_letters {12} = "M";
$field_letters {13} = "N";
$field_letters {14} = "O";
$field_letters {15} = "P";
$field_letters {16} = "Q";
$field_letters {17} = "R";
$field_letters {18} = "S";
$field_letters {19} = "T";
$field_letters {20} = "U";
$field_letters {21} = "V";
$field_letters {22} = "W";
$field_letters {23} = "X";
$field_letters {24} = "Y";
$field_letters {25} = "Z";

sub get_field_num_from_field_letter
{
    my $letter = $_ [0];
    return ($field_letters {$letter});
}

sub get_field_letter_from_field_num
{
    my $num = $_ [0];
    return ($field_letters {$num});
}

sub get_next_field_letter 
{
    my $letter = $_ [0];
    my $num = get_field_num_from_field_letter ($letter);
    return ($field_letters {$num + 1});
}

sub process_csv_data
{
    my $block = $_ [0];
    $csv_block = $block;
    print (">>>$csv_block<<<\n");
    my %new_csv_data;
    %csv_data = %new_csv_data;
    my %new_col_types;
    %col_types = %new_col_types;
    $max_field_num = 0;
    $max_rows = 0;

    my $line_num = 1;
    my $col_letter = "A";
    while ($block =~ s/^(.*?)\n//im)
    {
        chomp;
        my $line = $1;
        if ($line =~ m/^$/)
        {
            next;
        }
        $col_letter = "A";
        while ($line =~ s/^([^;\t]+?)(;|\t|$)//)
        {
            my $field = $1;
            $csv_data {"$col_letter" . "$line_num"} = $field;
            $col_letter = get_next_field_letter ($col_letter);
            
            if ($max_field_num < get_field_num_from_field_letter ($col_letter))
            {
                $max_field_num = get_field_num_from_field_letter ($col_letter);
            }
        }
        $line_num++;
        $max_rows++;
    }
    
    $col_letter = "A";
    while ($block =~ s/^([^;]+?)(;|$)//)
    {
        my $field = $1;
        $csv_data {"$line_num.$col_letter"} = $field;
        $col_letter = get_next_field_letter ($col_letter);
        if ($max_field_num < get_field_num_from_field_letter ($col_letter))
        {
            $max_field_num = get_field_num_from_field_letter ($col_letter);
        }
    }
    $max_rows++;
    $show_formulas = 0;
}

sub add_price
{
    my $initial_price = $_ [0];
    my $field = $_ [1];

    $field =~ s/[\$,]//img;

    if ($field =~ m/^-(\d+)($|\.\d+)$/)
    {
        my $whole = $1;
        my $decimal = $2;
        $decimal =~ s/\.//;
        $decimal =~ s/^(\d\d)(\d+)/$1.$2/;
        $initial_price += -1 * ($whole*100 + $decimal);
    }
    elsif ($field =~ m/^(\d+)($|\.\d+)$/)
    {
        my $whole = $1;
        my $decimal = $2;
        $decimal =~ s/\.//;
        $decimal =~ s/^(\d\d)(\d+)/$1.$2/;
        $initial_price += $whole*100 + $decimal;
    }
    return $initial_price;
}

sub get_col_type
{
    my $col_letter = $_ [0];
    if ($col_letter =~ m/^\d+$/)
    {
        $col_letter =  get_field_letter_from_field_num ($col_letter);
    }
    return ($col_types {$col_letter});
}

sub set_col_type
{
    my $col_letter = $_ [0];
    my $col_type = $_ [1];
    $col_types {$col_letter} = $col_type;
}

sub get_col_header
{
    my $col_letter = $_ [0];
    if ($col_letter =~ m/^\d+$/)
    {
        $col_letter =  get_field_letter_from_field_num ($col_letter);
    }
    return ($csv_data {"$col_letter" . "1"});
}

sub get_col_name_of_number_type_col
{
    my $i = 0;
    for ($i = 0; $i < $max_field_num; $i++)
    {
        if (get_col_type ($i) eq "NUMBER" || get_col_type ($i) eq "PRICE")
        {
            my $ch = get_col_header ($i);
            if ($ch =~ m/.../)
            {
                return "%23" . get_col_header ($i);
            }
        }
    }
    return "%23NUM_COL";
}

sub get_num_of_col_header
{
    my $col_name = $_ [0];
    my $i = 0;
    for ($i = 0; $i < $max_field_num; $i++)
    {
        if (get_col_header ($i) eq $col_name)
        {
            return $i;
        }
    }
    return -1;
}

sub get_field_from_col_header
{
    my $row_num = $_ [0];
    my $col_name = $_ [1];

    my $col = get_num_of_col_header ($col_name);
    if ($col > -1)
    {
        return get_field_value ($row_num, $col, 0);
    }
    return "";
}

sub has_field_id
{
    my $field_val = $_ [0]; 
    $field_val =~ s/:[A-Z]+\d+/:/;
    $field_val =~ s/[A-Z]+\d+://;
    print ("    Is there a field id in $field_val ??? >>");
    if ($field_val =~ m/^=.*([A-Z]+\d+)/)
    {
        my $field_id = $1;
        print ("    yes $field_id\n");
        return $field_id;
    }
    print ("    no\n");
    return "";
}

sub get_row_num
{
    my $field_id = $_ [0];
    if ($field_id =~ m/(\d+)$/)
    {
        return $1;
    }
}

sub get_col_letter
{
    my $field_id = $_ [0];
    if ($field_id =~ m/^([A-Z]+)/)
    {
        return $1;
    }
}

sub simple_parentheses_only_one_argument 
{
    my $field_val = $_ [0];
    my $func = $_ [1];
    if ($field_val =~ m/^$func\([^(\|]+\)/)
    {
        return 1;
    }
    return 0;
}

sub simple_parentheses_only_two_arguments
{
    my $field_val = $_ [0];
    my $func = $_ [1];
    if ($field_val =~ m/^$func\([^(\|]*\|[^(\|]*?\)/)
    {
        print ("Checked s2a and ok\n");
        return 1;
    }
    print ("Checked s2a for $field_val and NOT ok\n");
    return 0;
}

sub simple_parentheses_only_three_arguments
{
    my $field_val = $_ [0];
    my $func = $_ [1];
    if ($field_val =~ m/^$func\([^(\|]+\|/)
    {
        print ("Checked s3a for $field_val aaa\n");
    }
    if ($field_val =~ m/^$func\([^(\|]+\|[^(\|]+\|/)
    {
        print ("Checked s3a for $field_val bbb\n");
    }
    if ($field_val =~ m/^$func\([^(\|]+\|[^(\|]+\|[^(\|]+\)/)
    {
        print ("Checked s3a for $field_val ccc\n");
    }
    if ($field_val =~ m/^$func\([^(\|]+\|[^(\|]+\|[^(\|]+\)/)
    {
        return 1;
    }
    return 0;
}

sub excel_to_perl_calculation
{
    # Egs:  =IF(A1<10|SUM(B2:B10)|100-MAX(10|B11))
    # Egs:  =IF(A2+0.31/2>10|10|A2+0.31/2)
    # Egs:  =IF(A2+0.31/2>10|BBB|concatenate(B2|"A"))

    my $field_val = $_ [0];
    my $field_id = $_ [1];
    print ("\nDOING  ---- excel_to_perl_calculation for $field_val\n");
    $field_val =~ s/PI\(\)/3.14159265358979323/img;
    $field_val =~ s/([^=]+)=([^=]+)/$1==$2/g;
    my $finished = 1;

    if ($field_val =~ m/((POWER)\(.*)/)
    {
        my $to_check = $1;
        my $func = $2;
        if (simple_parentheses_only_two_arguments ($to_check, "$func"))
        {
            $field_val =~ s/$func\((.+)\|(.+)\)/($1)**($2)/;
        }
        else
        {
            print ("aa Not finished: $field_val\n");
            $finished = 0;
        }
    }
    if ($field_val =~ m/(.*)(SUM\(([A-Z])(\d+):([A-Z])(\d+))/)
    {
        my $first_bit = $1; 
        my $overall = $2; 
        my $first_col = $3; 
        my $first_num = $4; 
        my $second_col = $5; 
        my $second_num = $6; 


        my $fc_num = get_field_num_from_field_letter ($first_col);
        my $sc_num = get_field_num_from_field_letter ($second_col);
        print (" >> Summing ($field_val) >> $fc_num.$first_num  to  $sc_num.$second_num\n");
        my $sum_str = "";
        my $i = $fc_num; 
        my $j = $first_num; 
        while ($i <= $sc_num)
        {
            print ("  in $i\n");
            print ("$i $sc_num > $sum_str\n");
            while ($j <= $second_num)
            {
                print ("  in $j\n");
                $sum_str .= get_field_letter_from_field_num ($i) . "$j+";
                $j++;
            }
            $j = $first_num; 
            $i++;
        }
        $sum_str =~ s/\+$//;
        $sum_str .= "";
        $field_val = $first_bit . $sum_str;
        print (" SUM DONE > $sum_str (now $field_val)\n");
        $finished = 0;
    }
    if ($field_val =~ m/(CONCATENATE\(.*)/)
    {
        my $to_check = $1;
        if (simple_parentheses_only_two_arguments ($to_check, "CONCATENATE"))
        {
            if ($field_val =~ m/CONCATENATE\(([^\|]+?)\|([^\|]+?)\)/)
            {
                print ("concat 11: $field_val\n");
                $field_val =~ s/CONCATENATE\(([^\|]+?)\|([^\|]+?)\)/"$1" . "$2"/;
                $field_val =~ s/""/"/g;
                $field_val =~ s/""/"/g;
            }
            elsif ($field_val =~ m/CONCATENATE\(\s*\|([^\|]+?)\)/)
            {
                print ("concat 01: $field_val\n");
                $field_val =~ s/CONCATENATE\(\s*\|([^\|]+?)\)/"$1"/;
                $field_val =~ s/""/"/g;
                $field_val =~ s/""/"/g;
            }
            elsif ($field_val =~ m/CONCATENATE\(([^\|]+?)\|\s*\)/)
            {
                print ("concat 10: $field_val\n");
                $field_val =~ s/CONCATENATE\(([^\|]+?)\|\s*\)/"$1"/;
                $field_val =~ s/""/"/g;
                $field_val =~ s/""/"/g;
            }
            elsif ($field_val =~ m/CONCATENATE\(\s*\|\s*\)/)
            {
                print ("concat 00: $field_val\n");
                $field_val =~ s/CONCATENATE\(\s*\|\s*\)//;
                $field_val =~ s/""/"/g;
                $field_val =~ s/""/"/g;
            }
            print ("concat fail: $field_val\n");
        }
        else 
        {
            print ("bb Not finished: $field_val\n");
            $finished = 0;
            $field_val =~ s/CONCATENATE\(([^\|]+?)|(.+?)\)/$1 . CONCATENATE($2)/;
        }
    }
    if ($field_val =~ m/(IF\(.*)/)
    {
        my $to_check = $1;
        if (simple_parentheses_only_three_arguments ($to_check, "IF"))
        {
            $field_val =~ s/IF\(([^|]+)\|([^|]*?)\|([^|]*?)\)/($1 ? $2 : $3)/;
        }
        else 
        {
            print ("cc Not finished: $field_val\n");
            $finished = 0;
        }
    }

    if (!$finished)
    {
        print ("Not finished: $field_val\n");
        return excel_to_perl_calculation ($field_val, $field_id);
    }
    $csv_data {$field_id . "_perl"} = $field_val;
    return $field_val;
}

sub calc_field_value
{
    my $field_val = $_ [0]; 
    my $row_num = $_ [1]; 
    my $col_letter = $_ [2]; 
    my $next_field_id = has_field_id ($field_val);

    if ($show_formulas)
    {
        return $field_val;
    }

    while ($next_field_id ne "")
    {
        if ($next_field_id eq "$col_letter$row_num") { return "ERROR (self-ref)"; } 
        my $rn = get_row_num ($next_field_id);
        my $cl = get_col_letter ($next_field_id);
        my $that_field_val = get_field_value ($rn, $cl, 0);
        print ("\nBEFORE:$field_val ... changing $next_field_id for $that_field_val\n");
        $field_val =~ s/$next_field_id/$that_field_val/; 
        print ("\nAFTER:$field_val ... changing $next_field_id for $that_field_val\n");
        $next_field_id = has_field_id ($field_val);
    }

    if ($field_val =~ s/^=//)
    {
        my $orig_field_val = $field_val;
        my $fv = excel_to_perl_calculation ($field_val, "$col_letter$row_num");

        my $next_field_id = has_field_id ("=" . $fv);
        if ($next_field_id ne "")
        {
            return calc_field_value ("=" . $fv);
        }
        print ("\nDOING CALCULATIONS: $col_letter$row_num evaluating >>$fv<<\n");
        my $valid_calc = eval { $fv };
        if (!defined ($valid_calc))
        {
            $fv = lc($fv);
            my $valid_calc = eval { $fv };
            if (!defined ($valid_calc))
            {
                return "ERROR ($fv invalid)";
            }
            my $valid_calc2 = eval { $valid_calc };
            
            if (!defined ($valid_calc2))
            {
                return "ERROR ($fv invalid)";
            }
            return $valid_calc;
        }
        $field_val = eval ($fv);
    }
    return $field_val;
}

sub set_field_value
{
    my $row_num = $_ [0];
    my $col_letter = $_ [1];
    my $new_val = $_ [2];

    if ($col_letter =~ m/^\d+$/)
    {
        $col_letter =  get_field_letter_from_field_num ($col_letter);
    }
    my $str = "$col_letter" . $row_num;
    if (defined ($csv_data {$str}))
    {
        $csv_data {$str} = $new_val;
    }
}

sub get_field_value
{
    my $row_num = $_ [0];
    my $col_letter = $_ [1];
    my $for_display = $_ [2];
    if ($col_letter =~ m/^\d+$/)
    {
        $col_letter =  get_field_letter_from_field_num ($col_letter);
    }
    my $field_id = "$col_letter" . $row_num;
    if (defined ($csv_data {$field_id}))
    {
        my $field_val = $csv_data {$field_id};
        my $calc_val = "";
        if (!defined ($calculated_data {$field_id}))
        {
            if ($csv_data {$field_id} =~ m/^=/)
            {
                $calc_val = calc_field_value ($csv_data {$field_id}, $row_num, $col_letter);
            }
            else
            {
                $calc_val = $field_val;
            }
            $calculated_data {$field_id} = $calc_val;
        }
        $calc_val = $calculated_data {$field_id};
        if ($for_display == 1 && $show_formulas == 0 && $calc_val =~ m/^[-,\$\d\.]+$/ && $calc_val =~ m/^.+\..+$/)
        {
            my $c = sprintf("%.2f", $calc_val);
            return ($c);
        }
        elsif ($for_display == 1 && $show_formulas == 2)
        {
            return ($csv_data {$field_id . "_perl"});
        }
        elsif ($for_display == 1 && $show_formulas == 1 && $calc_val =~ m/^[-,\$\d\.]+$/ && $calc_val =~ m/^.+\..+$/)
        {
            return ($csv_data {$field_id . "_calc"});
        }
        return ($calc_val);
    }
    return ("");
}

sub get_graph_html
{
    my $graph_html = "";
    my $col = $_ [0];
    my $col_name = $_ [1];

    # graph_counts
    my $graph_counts = 0;
    if ($col == -1)
    {
        $graph_counts = 1;
    }

    # graph_totals
    my $graph_totals = 0;
    if ($col == -2)
    {
        $graph_totals = 1;
    }

    $graph_html .= "<!DOCTYPE html>\n";
    $graph_html .= "<html lang=\"en\">\n";
    $graph_html .= "<head>\n";
    $graph_html .= "<meta charset=\"UTF-8\">\n";
    $graph_html .= "<title>Graph Data</title>\n";
    $graph_html .= "<link rel=\"stylesheet\" href=\"https://cdnjs.cloudflare.com/ajax/libs/normalize/5.0.0/normalize.min.css\">\n";
    $graph_html .= "<link rel='stylesheet' href='https://fonts.googleapis.com/css?family=Khand'>\n";
    $graph_html .= "    <style>\n";
    $graph_html .= "        * {\n";
    $graph_html .= "        box-sizing: border-box;\n";
    $graph_html .= "        padding: 0;\n";
    $graph_html .= "        margin: 0;\n";
    $graph_html .= "        }\n";
    $graph_html .= "        body {\n";
    $graph_html .= "        margin: 50px auto;\n";
    $graph_html .= "        font-family: \"Khand\";\n";
    $graph_html .= "        font-size: 1.2em;\n";
    $graph_html .= "        text-align: center;\n";
    $graph_html .= "        }\n";
    $graph_html .= "        ul {\n";
    $graph_html .= "        padding-top: 20px;\n";
    $graph_html .= "        display: flex;\n";
    $graph_html .= "        gap: 2rem;\n";
    $graph_html .= "        }\n";
    $graph_html .= "        li {\n";
    $graph_html .= "        margin: 0.5rem 0;\n";
    $graph_html .= "        }\n";
    $graph_html .= "        legend {\n";
    $graph_html .= "        margin: 0 auto;\n";
    $graph_html .= "        }\n";
    $graph_html .= "    </style>\n";
    $graph_html .= "<style> table { border-collapse: collapse; } table.center { margin-left: auto; margin-right: auto; } td, th { border: 1px solid #dddddd; text-align: left; padding: 8px; } tr:nth-child(even) { background-color: #efefef; } </style>\n";
    $graph_html .= "<script>\n";
    $graph_html .= "if (document.location.search.match (/type=embed/gi)) {\n";
    $graph_html .= "    window.parent.postMessage (\"resize\", \"*\");\n";
    $graph_html .= "}\n";
    $graph_html .= "</script>\n";
    $graph_html .= "</head>\n";
    $graph_html .= "<body translate=\"no\" >\n";
    $graph_html .= "<h1>Graph for column $col_name</h1><br>\n";
    $graph_html .= "<canvas id=\"graph_canvas\" style=\"background: white;\"></canvas>\n";
    $graph_html .= "<legend for=\"graph_canvas\"></legend>\n";
    $graph_html .= "<script id=\"rendered-js\" >\n";
    $graph_html .= "var canvas = document.getElementById (\"graph_canvas\");\n";
    $graph_html .= "canvas.width = 1200;\n";
    $graph_html .= "canvas.height = 600;\n";
    $graph_html .= "var ctx = canvas.getContext (\"2d\");\n";
    $graph_html .= "var min_gridy;\n";
    $graph_html .= "var max_gridy;\n";
    $graph_html .= "var barSize;\n";
    $graph_html .= "function drawActualLine (ctx, startX, startY, endX, endY, color) {\n";
    $graph_html .= "    ctx.save ();\n";
    $graph_html .= "    ctx.strokeStyle = color;\n";
    $graph_html .= "    ctx.beginPath ();\n";
    $graph_html .= "    ctx.moveTo (startX, startY);\n";
    $graph_html .= "    ctx.lineTo (endX, endY);\n";
    $graph_html .= "    ctx.stroke ();\n";
    $graph_html .= "    ctx.restore ();\n";
    $graph_html .= "}\n";
    $graph_html .= "function drawLine (ctx, startX, startY, endX, endY, color, options, canvas) {\n";
    $graph_html .= "    startX += options.padding;\n";
    $graph_html .= "    startY += canvas.height - options.padding;\n";
    $graph_html .= "    endX += options.padding + 2;\n";
    $graph_html .= "    endY += canvas.height - options.padding;\n";
    $graph_html .= "    ctx.save ();\n";
    $graph_html .= "    ctx.strokeStyle = color;\n";
    $graph_html .= "    ctx.beginPath ();\n";
    $graph_html .= "    ctx.moveTo (startX, startY);\n";
    $graph_html .= "    ctx.lineTo (endX, endY);\n";
    $graph_html .= "    ctx.stroke ();\n";
    $graph_html .= "    ctx.restore ();\n";
    $graph_html .= "}\n";
    $graph_html .= "function drawSquare (ctx, startX, startY, width, color, options, canvas) \n";
    $graph_html .= "{\n";
    $graph_html .= "    ctx.save ();\n";
    $graph_html .= "    ctx.fillStyle = color;\n";
    $graph_html .= "    ctx.fillRect (startX, startY, width, width);\n";
    $graph_html .= "    ctx.restore ();\n";
    $graph_html .= "}\n";
    $graph_html .= "function drawBar (ctx, upperLeftCornerX, upperLeftCornerY, width, height, color)\n";
    $graph_html .= "{\n";
    $graph_html .= "    ctx.save ();\n";
    $graph_html .= "    ctx.fillStyle = color;\n";
    $graph_html .= "    ctx.fillRect (upperLeftCornerX, upperLeftCornerY, width, height);\n";
    $graph_html .= "    ctx.restore ();\n";
    $graph_html .= "}\n";
    $graph_html .= "class BarChart \n";
    $graph_html .= "{\n";
    $graph_html .= "    constructor (options) {\n";
    $graph_html .= "        this.options = options;\n";
    $graph_html .= "        this.canvas = options.canvas;\n";
    $graph_html .= "        this.ctx = this.canvas.getContext (\"2d\");\n";
    $graph_html .= "        this.titleOptions = options.titleOptions;\n";
    $graph_html .= "        this.minValue = Math.min (...Object.values (this.options.data));\n";
    $graph_html .= "        this.maxValue = Math.max (...Object.values (this.options.data));\n";
    $graph_html .= "        this.maxValue += 1;\n";
    $graph_html .= "        this.multiplier = (options.canvas.height - options.padding * 2) / this.maxValue;\n";
    $graph_html .= "    }\n";
    $graph_html .= "    drawGridLines () {\n";
    $graph_html .= "        var canvasActualHeight = this.canvas.height - this.options.padding * 2;\n";
    $graph_html .= "        var canvasActualWidth = this.canvas.width - this.options.padding * 2;\n";
    $graph_html .= "        var gridValue = this.minValue;\n";
    $graph_html .= "        max_gridy = 0;\n";
    $graph_html .= "        min_gridy = 10000000000;\n";
    $graph_html .= "        this.grid_jump = (this.maxValue - this.minValue) / 10;\n";
    $graph_html .= "        while (gridValue <= this.maxValue) {\n";
    $graph_html .= "            var gridY = canvasActualHeight * (1 - gridValue / this.maxValue) + this.options.padding;\n";
    $graph_html .= "            if (max_gridy < gridY) { max_gridy  = gridY; }\n";
    $graph_html .= "            if (min_gridy > gridY) { min_gridy  = gridY; }\n";
    $graph_html .= "            drawActualLine (this.ctx, 0, gridY, this.canvas.width, gridY, this.options.gridColor);\n";
    $graph_html .= "            // Writing grid markers\n";
    $graph_html .= "            this.ctx.save ();\n";
    $graph_html .= "            this.ctx.fillStyle = \"black\";\n";
    $graph_html .= "            this.ctx.textBaseline = \"bottom\";\n";
    $graph_html .= "            this.ctx.font = \"bold 10px Arial\";\n";
    $graph_html .= "            this.ctx.fillText (gridValue, 0, gridY - 5);\n";
    $graph_html .= "            this.ctx.restore ();\n";
    $graph_html .= "            gridValue += this.grid_jump;\n";
    $graph_html .= "        }\n";
    $graph_html .= "        min_gridy = canvasActualHeight * (1 - gridValue / this.maxValue) + this.options.padding;\n";
    $graph_html .= "        drawActualLine (this.ctx, 25, min_gridy, 25, max_gridy, \"red\");\n";
    $graph_html .= "    }\n";
    $graph_html .= "    getBar = function(x, y) {\n";
    $graph_html .= "        var canvasActualHeight = this.canvas.height - this.options.padding * 2;\n";
    $graph_html .= "        var canvasActualWidth = this.canvas.width - this.options.padding * 2;\n";
    $graph_html .= "        var barIndex = 0;\n";
    $graph_html .= "        var numberOfBars = Object.keys (this.options.data).length;\n";
    $graph_html .= "        barSize = canvasActualWidth / numberOfBars;\n";
    $graph_html .= "        var values = Object.values (this.options.data);\n";
    $graph_html .= "        \n";
    $graph_html .= "        for (let thekey of Object.keys (this.options.data)) {\n";
    $graph_html .= "            if (x > this.options.padding + barIndex * barSize && x < this.options.padding + (barIndex+1) * barSize)\n";
    $graph_html .= "            {\n";
    $graph_html .= "                return thekey;\n";
    $graph_html .= "            }\n";
    $graph_html .= "            barIndex++;\n";
    $graph_html .= "        }\n";
    $graph_html .= "        return \"\";\n";
    $graph_html .= "    }\n";
    $graph_html .= "    getKey = function(searchVal) {\n";
    $graph_html .= "        var barIndex = 0;\n";
    $graph_html .= "        for (let thekey of Object.keys (this.options.data)) {\n";
    $graph_html .= "            if (thekey == searchVal)\n";
    $graph_html .= "            {\n";
    $graph_html .= "                return barIndex;\n";
    $graph_html .= "            }\n";
    $graph_html .= "            barIndex++;\n";
    $graph_html .= "        }\n";
    $graph_html .= "        return 0;\n";
    $graph_html .= "    }\n";
    $graph_html .= "    getBarValue = function(x, y) {\n";
    $graph_html .= "        var canvasActualHeight = this.canvas.height - this.options.padding * 2;\n";
    $graph_html .= "        var canvasActualWidth = this.canvas.width - this.options.padding * 2;\n";
    $graph_html .= "        var barIndex = 0;\n";
    $graph_html .= "        var numberOfBars = Object.keys (this.options.data).length;\n";
    $graph_html .= "        barSize = canvasActualWidth / numberOfBars;\n";
    $graph_html .= "        var values = Object.values (this.options.data);\n";
    $graph_html .= "        \n";
    $graph_html .= "        for (let thekey of Object.keys (this.options.data)) {\n";
    $graph_html .= "            if (x > this.options.padding + barIndex * barSize && x < this.options.padding + (barIndex+1) * barSize)\n";
    $graph_html .= "            {\n";
    $graph_html .= "                var reg = /.*\\((.+)\\)/;\n";
    $graph_html .= "                if (thekey.match(reg))\n";
    $graph_html .= "                {\n";
    $graph_html .= "                    return thekey.match(reg);\n";
    $graph_html .= "                }\n";
    $graph_html .= "                return thekey;\n";
    $graph_html .= "            }\n";
    $graph_html .= "            barIndex++;\n";
    $graph_html .= "        }\n";
    $graph_html .= "        return \"\";\n";
    $graph_html .= "    }\n";
    $graph_html .= "    drawBars () {\n";
    $graph_html .= "        var canvasActualHeight = this.canvas.height - this.options.padding * 2;\n";
    $graph_html .= "        var canvasActualWidth = this.canvas.width - this.options.padding * 2;\n";
    $graph_html .= "        var barIndex = 0;\n";
    $graph_html .= "        var numberOfBars = Object.keys (this.options.data).length;\n";
    $graph_html .= "        barSize = canvasActualWidth / numberOfBars;\n";
    $graph_html .= "        var values = Object.values (this.options.data);\n";
    $graph_html .= "        var oldBarHeight = 0;\n";
    $graph_html .= "        var barHeight = 0;\n";
    $graph_html .= "        for (let val of values) {\n";
    $graph_html .= "            oldBarHeight = barHeight;\n";
    $graph_html .= "            barHeight = Math.round (canvasActualHeight * val / this.maxValue);\n";
    $graph_html .= "            drawLine (this.ctx, (-0.5 + barIndex) * barSize,  -1*oldBarHeight , (0.5+barIndex) * barSize, -1*barHeight , \"skyblue\", this.options, this.canvas);\n";
    $graph_html .= "            barIndex++;\n";
    $graph_html .= "        }\n";
    $graph_html .= "    }\n";
    $graph_html .= "    drawLabel () {\n";
    $graph_html .= "        this.ctx.save ();\n";
    $graph_html .= "        this.ctx.textBaseline = \"bottom\";\n";
    $graph_html .= "        this.ctx.textAlign = this.titleOptions.align;\n";
    $graph_html .= "        this.ctx.fillStyle = this.titleOptions.fill;\n";
    $graph_html .= "        this.ctx.font = \`\${this.titleOptions.font.weight} \${this.titleOptions.font.size} \${this.titleOptions.font.family}`;\n";
    $graph_html .= "        let xPos = this.canvas.width / 2;\n";
    $graph_html .= "        if (this.titleOptions.align == \"left\") {\n";
    $graph_html .= "            xPos = 10;\n";
    $graph_html .= "        }\n";
    $graph_html .= "        if (this.titleOptions.align == \"right\") {\n";
    $graph_html .= "            xPos = this.canvas.width - 10;\n";
    $graph_html .= "        }\n";
    $graph_html .= "        this.ctx.fillText (this.options.seriesName, xPos, this.canvas.height);\n";
    $graph_html .= "        this.ctx.restore ();\n";
    $graph_html .= "    }\n";
    $graph_html .= "    draw () {\n";
    $graph_html .= "        this.drawGridLines ();\n";
    $graph_html .= "        this.drawBars ();\n";
    $graph_html .= "        this.drawLabel ();\n";
    $graph_html .= "    }\n";
    $graph_html .= "}\n";
    $graph_html .= "var myBarchart = new BarChart (\n";
    $graph_html .= "    {\n";
    $graph_html .= "        canvas: canvas,\n";
    $graph_html .= "        seriesName: \"Cell Values\",\n";
    $graph_html .= "        padding: 50,\n";
    $graph_html .= "        gridStep: 10,\n";
    $graph_html .= "        gridColor: \"lightgrey\",\n";

    $graph_html .= "        data: {";
    my $i;
    if ($graph_counts == 0 && $graph_totals == 0)
    {
        for ($i = 2; $i < $max_rows; $i++)
        {
            my $x = get_field_value ($i, $col, 1);
            $x =~ s/^$/0/;
            $x =~ s/,//g;
            $x =~ s/\$//g;
            $x =~ s/^ *$/0/g;
            $graph_html .= "\"Row $i,Col $col ($x)\":$x,";
        }
    }
    elsif ($graph_counts == 1 || $graph_totals == 1)
    {
        my $k;
        foreach $k (sort keys (%meta_data))
        {
            if ($k =~ m/_count/ && $graph_counts)
            {
                my $x = $meta_data {$k};
                $x =~ s/^$/0/;
                $x =~ s/,//g;
                $x =~ s/\$//g;
                $x =~ s/[^0-9\.]//g;
                $x =~ s/^ *$/0/g;
                $graph_html .= "\"Group $k ($x)\":$x,";
            }
            elsif ($k =~ m/_total/ && $graph_totals)
            {
                my $x = $meta_data {$k};
                $x =~ s/^$/0/;
                $x =~ s/,//g;
                $x =~ s/\$//g;
                $x =~ s/[^0-9\.]//g;
                $x =~ s/^ *$/0/g;
                $graph_html .= "\"Group $k ($x)\":$x,";
            }
        }
    }
    $graph_html .= "\"DONE\": 0 },\n";

    # Print colors line
    $graph_html .= "        colors: [";
    for ($i = 1; $i < $max_rows; $i++)
    {
        $graph_html .= "\"\#fbfbab\",";
    }
    $graph_html .= "],\n";

    $graph_html .= "        titleOptions: { align: \"center\", fill: \"black\", font: { weight: \"bold\", size: \"18px\", family: \"Lato\" } } \n";
    $graph_html .= "    }\n";
    $graph_html .= ");\n";
    $graph_html .= "myBarchart.draw ();\n";
    $graph_html .= "</script>\n";
    $graph_html .= "<canvas id=\"canvas_info\" style=\"background: skyblue;\"></canvas>\n";
    $graph_html .= "<script>\n";
    $graph_html .= "var canvas_info = document.getElementById(\"canvas_info\");\n";
    $graph_html .= "canvas_info.width = 900;\n";
    $graph_html .= "canvas_info.height = 100;\n";
    $graph_html .= "var graph_canvas = document.getElementById(\"graph_canvas\");\n";
    $graph_html .= "var ctx = canvas_info.getContext(\"2d\");\n";
    $graph_html .= "var graph_ctx = graph_canvas.getContext(\"2d\");\n";
    $graph_html .= "ctx.font = \"bold 20px Arial\";\n";
    $graph_html .= "var cw = graph_canvas.width;\n";
    $graph_html .= "var ch = graph_canvas.height;\n";
    $graph_html .= "function reOffset() {\n";
    $graph_html .= "  var BB = graph_canvas.getBoundingClientRect();\n";
    $graph_html .= "  offsetX = BB.left;\n";
    $graph_html .= "  offsetY = BB.top;\n";
    $graph_html .= "}\n";
    $graph_html .= "var offsetX, offsetY;\n";
    $graph_html .= "reOffset();\n";
    $graph_html .= "window.onscroll = function (e) {\n";
    $graph_html .= "  reOffset();\n";
    $graph_html .= "};\n";
    $graph_html .= "window.onresize = function (e) {\n";
    $graph_html .= "  reOffset();\n";
    $graph_html .= "};\n";
    $graph_html .= "graph_canvas.addEventListener(\"mousemove\", handleMouseMove, false);\n";
    $graph_html .= "var oldmouseX;\n";
    $graph_html .= "var oldY;\n";
    $graph_html .= "function handleMouseMove(e) {\n";
    $graph_html .= "    e.preventDefault();\n";
    $graph_html .= "    e.stopPropagation();\n";
    $graph_html .= "    mouseX = parseInt(e.clientX - offsetX);\n";
    $graph_html .= "    mouseY = parseInt(e.clientY - offsetY);\n";
    $graph_html .= "    ctx.clearRect(0, 0, cw, ch);\n";
    $graph_html .= "    var bar = myBarchart.getBar (mouseX, mouseY);\n";
    $graph_html .= "    ctx.fillText(bar, 50, 50);\n";
    $graph_html .= "    graph_ctx.clearRect(0, 0, 55, 55);\n";
    $graph_html .= "    var barVal = myBarchart.getBarValue (mouseX, mouseY);\n";
    $graph_html .= "    drawSquare (graph_ctx, oldmouseX, oldY, 10, \"white\", null, null); \n";
    $graph_html .= "    drawSquare (graph_ctx, mouseX, graph_canvas.height - 50 - myBarchart.multiplier *barVal[1], 5, \"darkorange\", null, null); \n";
    $graph_html .= "    oldmouseX = mouseX;\n";
    $graph_html .= "    oldY = graph_canvas.height - 50 - myBarchart.multiplier *barVal[1];\n";
    $graph_html .= "    myBarchart.draw ();\n";
    $graph_html .= "}\n";
    $graph_html .= "</script>\n";
    $graph_html .= "</table>\n";
    $graph_html .= "</body>\n";
    $graph_html .= "</html>\n";
    return $graph_html;
}

# Main
{
    my $paddr;
    my $proto = "TCP";
    my $iaddr;
    my $client_port;
    my $client_addr;
    my $pid;
    my $SERVER;
    my $port = 3867;
    my $trusted_client;
    my $data_from_client;
    $|=1;

    socket (SERVER, PF_INET, SOCK_STREAM, $proto) or die "Failed to create a socket: $!";
    setsockopt (SERVER, SOL_SOCKET, SO_REUSEADDR, 1) or die "setsocketopt: $!";

    # bind to a port, then listen
    bind (SERVER, sockaddr_in ($port, INADDR_ANY)) or die "Can't bind to port $port! \n";

    listen (SERVER, 10) or die "listen: $!";
    print ("Listening on port: $port\n");
    my $count;
    my $not_seen_full = 1;

    #process_csv_data ("Tot_Month;Add_Month;Daily_Int;Date;MonDays;Int_Month;Tot_Mon2;I_F_calc;Mon_Interest; =3640;0;=0.042/365;20230430;30;=POWER(1+C2|E2);=A2*F2;=IF(E2=30|G15-E3|E2);0; =G2;10;=0.042/365;20230531;31;=POWER(1+C3|E3);=(G2+B3)*F3;=IF(E3=30|G15-E3|E2);=G3-G2-B3; =G3;10;=0.042/365;20230630;30;=POWER(1+C4|E4);=(G3+B4)*F4;=IF(E4=30|G15-E3|E2);=G4-G3-B4; =G4;10;=0.042/365;20230731;31;=POWER(1+C5|E5);=(G4+B5)*F5;=IF(E5=30|G15-E3|E2);=G5-G4-B5; =G5;10;=0.042/365;20230831;31;=POWER(1+C6|E6);=(G5+B6)*F6;=IF(E6=30|G15-E3|E2);=G6-G5-B6; =G6;10;=0.042/365;20230930;30;=POWER(1+C7|E7);=(G6+B7)*F7;=IF(E7=30|G15-E3|E2);=G7-G6-B7; =G7;10;=0.042/365;20231031;31;=POWER(1+C8|E8);=(G7+B8)*F8;=IF(E8=30|G15-E3|E2);=G8-G7-B8; =G8;10;=0.042/365;20231130;30;=POWER(1+C9|E9);=(G8+B9)*F9;=IF(E9=30|G15-E3|E2);=G9-G8-B9; =G9;10;=0.042/365;20231231;31;=POWER(1+C10|E10);=(G9+B10)*F10;=IF(E10=30|G15-E3|E2);=G10-G9-B10; =G10;10;=0.042/365;20240131;31;=POWER(1+C11|E11);=(G10+B11)*F11;=IF(E11=30|G15-E3|E2);=G11-G10-B11; =G11;10;=0.042/365;20240228;28;=POWER(1+C12|E12);=(G11+B12)*F12;=IF(E12=30|G15-E3|E2);=G12-G11-B12; =G12;10;=0.042/365;20240331;31;=POWER(1+C13|E13);=(G12+B13)*F13;=IF(E13=30|G15-E3|E2);=G13-G12-B13; =G13;10;=0.042/365;20240430;30;=POWER(1+C14|E14);=(G13+B14)*F14;=IF(E14=30|G15-E3|E2);=G14-G13-B14; =G14;10;=0.042/365;20240531;31;=POWER(1+C15|E15);=(G14+B15)*F15;=IF(E15=30|G15-E3|E2);=G15-G14-B15;");
    #process_csv_data ("Col1;Col2;col3;col4;col5; 1541;=A2*A3;=B2/A3;=POWER(A2|4);=IF(B2=30|B2-B2|B2); 1251253;=A3*A4;=B3/A4;=POWER(A3|4);=IF(B3=30|B3-B3|B3); =A3-A2;=A4*#REF!;=B4/#REF!;=POWER(A4|4);=IF(B4=30|B4-B4|B4);");
    #process_csv_data ("col A;col B;col E; ; ; ; ;col H;col I;col J;col L; ;col M;col N; ; ; ; ; ; ; ;SCOTT; ; ; ; ; ; ; ; ; ; ; ; ; ;1/2 YEAR;CUMULATIVE; ; ; ; ; ; ; ; ; ; ;AGE;ABM ADDITION;ABM;% OF Final Average Salary; ;DIVIDOR; ; ; ; ; ; ; ;18.5; ; ; ; ; ; ; ; ; ; ; ; ;19; ; ; ; ; ; ; ; ; ; ; ; ;19.5; ; ; ; ; ; ; ; ; ; ; ; ;20; ; ; ; ; ; ; ; ; ; ; ; ;20.5; ; ; ; ; ; ; ; ; ; ; ; ;21; ; ; ; ; ; ; ; ; ; ; ; ;21.5; ; ; ; ; ; ; ; ; ; ; ; ;22; ; ; ; ; ; ; ; ; ; ; ; ;22.5; ; ; ; ; ; ; ; ; ; ; ; ;23; ; ; ; ; ; ; ; ; ; ; ; ;23.5; ; ; ; ; ; ; ; ; ; ; ; ;24; ; ; ; ; ; ; ; ; ; ; ; ;24.5; ; ; ; ; ; ; ; ; ; ;Current Salary; ;25; ; ; ; ; ;Years of service.  ; ;5% contribution rate; ;2003; ; ;25.5;0.105;0.105; ; ; ;=H19-25.5 ; ;5% contribution rate; ;=E19+0.5; ; ;26;0.105;0.21; ; ; ;=H20-25.5 ; ;10% contribution rate; ;=E20+0.5; ; ;26.5;0.13;0.34; ; ; ;=H21-25.5 ; ;10% contribution rate; ;=E21+0.5; ; ;27;0.13;0.47; ; ; ;=H22-25.5 ; ;10% contribution rate; ;=E22+0.5; ; ;27.5;0.13;0.6; ; ; ;=H23-25.5 ; ;10% contribution rate; ;=E23+0.5; ; ;28;0.13;0.73; ; ; ;=H24-25.5 ; ;10% contribution rate; ;=E24+0.5; ; ;28.5;0.13;0.86; ; ; ;=H25-25.5 ; ;10% contribution rate; ;=E25+0.5; ; ;29;0.13;0.99; ; ; ;=H26-25.5 ; ;10% contribution rate; ;=E26+0.5; ; ;29.5;0.13;1.12; ; ; ;=H27-25.5 ; ;10% contribution rate; ;=E27+0.5; ; ;30;0.13;1.25; ; ; ;=H28-25.5 ; ;10% contribution rate; ;=E28+0.5; ; ;30.5;0.13;1.38; ; ; ;=H29-25.5 ; ;10% contribution rate; ;=E29+0.5; ; ;31;0.13;1.51; ; ; ;=H30-25.5 ; ;10% contribution rate; ;=E30+0.5; ; ;31.5;0.13;1.64; ; ; ;=H31-25.5 ; ;10% contribution rate; ;=E31+0.5; ; ;32;0.13;1.77; ; ; ;=H32-25.5 ; ;10% contribution rate; ;=E32+0.5; ; ;32.5;0.13;1.9; ; ; ;=H33-25.5 ; ;10% contribution rate; ;=E33+0.5; ; ;33;0.13;2.03; ; ; ;=H34-25.5 ; ;10% contribution rate; ;=E34+0.5; ; ;33.5;0.13;2.16; ; ; ;=H35-25.5 ; ;10% contribution rate; ;=E35+0.5; ; ;34;0.13;2.29; ; ; ;=H36-25.5 ; ;10% contribution rate; ;=E36+0.5; ; ;34.5;0.13;2.42; ; ; ;=H37-25.5 ; ;10% contribution rate; ;=E37+0.5; ; ;35;0.13;2.55; ; ; ;=H38-25.5 ; ;10% contribution rate; ;=E38+0.5; ; ;35.5;0.13;2.68; ; ; ;=H39-25.5 ; ;10% contribution rate; ;=E39+0.5; ; ;36;0.155;2.835; ; ; ;=H40-25.5 ; ;10% contribution rate; ;=E40+0.5; ; ;36.5;0.155;2.99; ; ; ;=H41-25.5 ; ;10% contribution rate; ;=E41+0.5; ; ;37;0.155;3.145; ; ; ;=H42-25.5 ; ;10% contribution rate; ;=E42+0.5; ; ;37.5;0.155;3.3; ; ; ;=H43-25.5 ; ;10% contribution rate; ;=E43+0.5; ; ;38;0.155;3.455; ; ; ;=H44-25.5 ; ;10% contribution rate; ;=E44+0.5; ; ;38.5;0.155;3.61; ; ; ;=H45-25.5 ; ;10% contribution rate; ;=E45+0.5; ; ;39;0.155;3.765; ; ; ;=H46-25.5 ; ;10% contribution rate; ;=E46+0.5; ; ;39.5;0.155;3.92; ; ; ;=H47-25.5 43646;(based on PSS pdf);10% contribution rate; ;=E47+0.5; ; ;40;0.155;4.075; ; ; ;=H48-25.5 4.25076923; ;10% contribution rate; ;=E48+0.5; ; ;40.5;0.155;4.23; ; ; ;=H49-25.5 =A49+0.31/2; ;10% contribution rate; ;=E49+0.5; ; ;41;0.155;4.385; ; ; ;=H50-25.5 =A50+0.31/2; ;10% contribution rate; ;=E50+0.5; ; ;41.5;0.155;4.54; ; ; ;=H51-25.5 =A51+0.31/2; ;10% contribution rate; ;=E51+0.5; ; ;42;0.155;4.695; ; ; ;=H52-25.5 =A52+0.31/2; ;10% contribution rate; ;=E52+0.5; ;FAS;42.5;0.155;4.85; ; ; ;=H53-25.5 =A53+0.31/2; ;10% contribution rate; ;=E53+0.5;131107; ;43;0.155;5.005; ; ; ;=H54-25.5 =A54+0.31/2; ;10% contribution rate; ;=E54+0.5;=(F56+F54)/2; ;43.5;0.155;5.16; ; ; ;=H55-25.5 =A55+0.31/2; ;10% contribution rate; ;=E55+0.5;133729; ;44;0.155;5.315; ; ; ;=H56-25.5 =A56+0.31/2; ;10% contribution rate; ;=E56+0.5;=(F58+F56)/2; ;44.5;0.155;5.47; ; ; ;=H57-25.5 =A57+0.31/2; ;10% contribution rate; ;=E57+0.5;136404;=(F58+F56+F54)/3;45;0.155;5.625; ; ; ;=H58-25.5 =A58+0.31/2; ;10% contribution rate; ;=E58+0.5;=(F60+F58)/2; ;45.5;0.155;5.78; ; ; ;=H59-25.5 =A59+0.31/2; ;10% contribution rate; ;=E59+0.5;=(F58/1.1)*1.3;=(F60+F58+F56)/3;46;0.155;5.935; ; ; ;=H60-25.5 =A60+0.31/2; ;10% contribution rate; ;=E60+0.5;161204.727272727; ;46.5;0.155;6.09; ; ; ;=H61-25.5 =A61+0.31/2; ;10% contribution rate; ;=E61+0.5;161204.727272727;=(F62+F60+F58)/3;47;0.155;6.245; ; ; ;=H62-25.5 =A62+0.31/2; ;10% contribution rate; ;=E62+0.5;161204.727272727; ;47.5;0.155;6.4; ; ; ;=H63-25.5 =A63+0.31/2; ;10% contribution rate; ;=E63+0.5;161204.727272727;=(F64+F62+F60)/3;48;0.155;6.555; ; ; ;=H64-25.5 =A64+0.31/2; ;10% contribution rate; ;=E64+0.5;161204.727272727; ;48.5;0.155;6.71; ; ; ;=H65-25.5 =A65+0.31/2; ;10% contribution rate; ;=E65+0.5;161204.727272727;=(F66+F64+F62)/3;49;0.155;6.865; ; ; ;=H66-25.5 =A66+0.31/2; ;10% contribution rate; ;=E66+0.5;161204.727272727; ;49.5;0.155;7.02; ; ; ;=H67-25.5 =A67+0.31/2; ;10% contribution rate; ;=E67+0.5;161204.727272727;=(F68+F66+F64)/3;50;0.155;7.175; ; ; ;=H68-25.5 =A68+0.31/2; ;10% contribution rate; ;=E68+0.5;161204.727272727; ;50.5;0.155;7.33; ; ; ;=H69-25.5 =A69+0.31/2; ;10% contribution rate; ;=E69+0.5;161204.727272727;=(F70+F68+F66)/3;51;0.155;7.485; ; ; ;=H70-25.5 =A70+0.31/2; ;10% contribution rate; ;=E70+0.5;161204.727272727; ;51.5;0.155;7.64; ; ; ;=H71-25.5 =A71+0.31/2; ;10% contribution rate; ;=E71+0.5;161204.727272727;=(F72+F70+F68)/3;52;0.155;7.795; ; ; ;=H72-25.5 =A72+0.31/2; ;10% contribution rate; ;=E72+0.5;161204.727272727; ;52.5;0.155;7.95; ; ; ;=H73-25.5 =A73+0.31/2; ;10% contribution rate; ;=E73+0.5;161204.727272727;=(F74+F72+F70)/3;53;0.155;8.105; ; ; ;=H74-25.5 =A74+0.31/2; ;10% contribution rate; ;=E74+0.5;161204.727272727; ;53.5;0.155;8.26; ; ; ;=H75-25.5 =A75+0.31/2; ;10% contribution rate; ;=E75+0.5;161204.727272727;=(F76+F74+F72)/3;54;0.155;8.415; ; ; ;=H76-25.5 =A76+0.31/2; ;10% contribution rate; ;=E76+0.5;161204.727272727; ;54.5;0.155;8.57; ; ; ;=H77-25.5 =A77+0.31/2;=A78/M78;10% contribution rate; ;=E77+0.5;161204.727272727;=(F78+F76+F74)/3;55;0.155;8.725;=J78/M78;=J78*G78/M78;=11+(60-H78)/5;Can Retire =A78+0.31/2;=A79/M79;10% contribution rate; ;=E78+0.5;161204.727272727;=(F79+F77+F75)/3;55.5;0.155;8.88;=J79/M79;=J79*G79/M79;=11+(60-H79)/5;Can Retire =A79+0.31/2;=A80/M80;10% contribution rate; ;=E79+0.5;161204.727272727;=(F80+F78+F76)/3;56;0.155;9.035;=J80/M80;=J80*G80/M80;=11+(60-H80)/5;Can Retire =A80+0.31/2;=A81/M81;10% contribution rate; ;=E80+0.5;161204.727272727;=(F81+F79+F77)/3;56.5;0.155;9.19;=J81/M81;=J81*G81/M81;=11+(60-H81)/5;Can Retire =A81+0.31/2;=A82/M82;10% contribution rate; ;=E81+0.5;161204.727272727;=(F82+F80+F78)/3;57;0.155;9.345;=J82/M82;=J82*G82/M82;=11+(60-H82)/5;Can Retire =A82+0.31/2;=A83/M83;10% contribution rate; ;=E82+0.5;161204.727272727;=(F83+F81+F79)/3;57.5;0.155;9.5;=J83/M83;=J83*G83/M83;=11+(60-H83)/5;Can Retire =A83+0.31/2;=A84/M84;10% contribution rate; ;=E83+0.5;161204.727272727;=(F84+F82+F80)/3;58;0.155;9.655;=J84/M84;=J84*G84/M84;=11+(60-H84)/5;Can Retire =A84+0.31/2;=A85/M85;10% contribution rate; ;=E84+0.5;161204.727272727;=(F85+F83+F81)/3;58.5;0.155;9.81;=J85/M85;=J85*G85/M85;=11+(60-H85)/5;Can Retire =A85+0.31/2;=A86/M86;10% contribution rate; ;=E85+0.5;161204.727272727;=(F86+F84+F82)/3;59;0.155;9.965;=J86/M86;=J86*G86/M86;=11+(60-H86)/5;Can Retire =10;=A87/M87;10% contribution rate; ;=E86+0.5;161204.727272727;=(F87+F85+F83)/3;59.5;0.155;10;=J87/M87;=J87*G87/M87;=11+(60-H87)/5;Can Retire =10;=A88/M88;0%contribution; ; ;161204.727272727;=(F88+F86+F84)/3;60;0;10;=J88/M88;=J88*G88/M88;=11+(60-H88)/5;Can Retire ; ;0%contribution; ; ;161204.727272727; ;=H88+0.5;0;10;=J89/M89;=J89*G89/M89;=11+(60-H89)/5;Can Retire ; ;0%contribution; ; ;161204.727272727; ;=H89+0.5;0;10;=J90/M90;=J90*G90/M90;=11+(60-H90)/5;Can Retire ; ;0%contribution; ; ;161204.727272727; ;=H90+0.5;0;10;=J91/M91;=J91*G91/M91;=11+(60-H91)/5;Can Retire ; ;0%contribution; ; ;161204.727272727; ;=H91+0.5;0;10;=J92/M92;=J92*G92/M92;=11+(60-H92)/5;Can Retire ; ;0%contribution; ; ;161204.727272727; ;=H92+0.5;0;10;=J93/M93;=J93*G93/M93;=11+(60-H93)/5;Can Retire ; ;0%contribution; ; ;161204.727272727; ;=H93+0.5;0;10;=J94/M94;=J94*G94/M94;=11+(60-H94)/5;Can Retire ; ;0%contribution; ; ;161204.727272727; ;=H94+0.5;0;10;=J95/M95;=J95*G95/M95;=11+(60-H95)/5;Can Retire ; ;0%contribution; ; ;161204.727272727; ;=H95+0.5;0;10;=J96/M96;=J96*G96/M96;=11+(60-H96)/5;Can Retire ; ;0%contribution; ; ;161204.727272727; ;=H96+0.5;0;10;=J97/M97;=J97*G97/M97;=11+(60-H97)/5;Can Retire ; ;0%contribution; ; ;161204.727272727; ;=H97+0.5;0;10;=J98/M98;=J98*G98/M98;=11+(60-H98)/5;Can Retire ; ;0%contribution; ; ;161204.727272727; ;=H98+0.5;0;10;=J99/M99;=J99*G99/M99;=11+(60-H99)/5;Can Retire ; ;0%contribution; ; ;161204.727272727; ;=H99+0.5;0;10;=J100/M100;=J100*G100/M100;=11+(60-H100)/5;");
    #process_csv_data ("Col1;Col2;col3;col4;col5; 5.5;=A2*A3;=B2/A3;=POWER(A2|4);=IF(B2=30|B2-B2|B2); 12;=A3*A4;=B3/A4;=POWER(A3|4);=IF(B3=30|B3-B3|B3); =A3-A2;=A4/B4;=POWER(A4|4);=IF(B4=30|B4-B4|B4);");
    process_csv_data ("Tot_Month;Add_Month;Daily_Interest;Date;Days_in_Month;Interest_for_Month;Total_for_Month;Monthly_Interest;SUM;
=3640;0;=0.042/365;20230430;30;=POWER(1+C2|E2);=A2*F2;0;SUM;
=G2;10;=0.042/365;20230531;31;=POWER(1+C3|E3);=(G2+B3)*F3;=G3-G2-B3;SUM;
=G3;10;=0.042/365;20230630;30;=POWER(1+C4|E4);=(G3+B4)*F4;=G4-G3-B4;SUM;
=G4;10;=0.042/365;20230731;31;=POWER(1+C5|E5);=(G4+B5)*F5;=G5-G4-B5;SUM;
=G5;10;=0.042/365;20230831;31;=POWER(1+C6|E6);=(G5+B6)*F6;=G6-G5-B6;SUM;
=G6;10;=0.042/365;20230930;30;=POWER(1+C7|E7);=(G6+B7)*F7;=G7-G6-B7;=SUM(A2:A4);
=G7;10;=0.042/365;20231031;31;=POWER(1+C8|E8);=(G7+B8)*F8;=G8-G7-B8;SUM;
=G8;10;=0.042/365;20231130;30;=POWER(1+C9|E9);=(G8+B9)*F9;=G9-G8-B9;SUM;
=G9;10;=0.042/365;20231231;31;=POWER(1+C10|E10);=(G9+B10)*F10;=G10-G9-B10;SUM;
=G10;10;=0.042/365;20240131;31;=POWER(1+C11|E11);=(G10+B11)*F11;=G11-G10-B11;SUM;
=G11;10;=0.042/365;20240228;28;=POWER(1+C12|E12);=(G11+B12)*F12;=G12-G11-B12;SUM;
=G12;10;=0.042/365;20240331;31;=POWER(1+C13|E13);=(G12+B13)*F13;=G13-G12-B13;SUM;
=G13;10;=0.042/365;20240430;30;=POWER(1+C14|E14);=(G13+B14)*F14;=G14-G13-B14;SUM;
=G14;10;=0.042/365;20240531;31;=POWER(1+C15|E15);=(G14+B15)*F15;=G15-G14-B15;SUM;
=G15;10;=0.042/365;20240630;30;=POWER(1+C16|E16);=(G15+B16)*F16;=G16-G15-B16;SUM;
=G16;10;=0.042/365;20240731;31;=POWER(1+C17|E17);=(G16+B17)*F17;=G17-G16-B17;SUM;
=G17;10;=0.042/365;20240831;31;=POWER(1+C18|E18);=(G17+B18)*F18;=G18-G17-B18;SUM;
=G18;10;=0.042/365;20240930;30;=POWER(1+C19|E19);=(G18+B19)*F19;=G19-G18-B19;SUM;
=G19;10;=0.042/365;20241031;31;=POWER(1+C20|E20);=(G19+B20)*F20;=G20-G19-B20;SUM;
=G20;10;=0.042/365;20241130;30;=POWER(1+C21|E21);=(G20+B21)*F21;=G21-G20-B21;SUM;
=G21;10;=0.042/365;20241231;31;=POWER(1+C22|E22);=(G21+B22)*F22;=G22-G21-B22;SUM;
=G22;10;=0.042/365;20250131;31;=POWER(1+C23|E23);=(G22+B23)*F23;=G23-G22-B23;SUM;
=G23;10;=0.042/365;20250228;28;=POWER(1+C24|E24);=(G23+B24)*F24;=G24-G23-B24;SUM;
=G24;10;=0.042/365;20250331;31;=POWER(1+C25|E25);=(G24+B25)*F25;=G25-G24-B25;SUM;
=G25;10;=0.042/365;20250430;30;=POWER(1+C26|E26);=(G25+B26)*F26;=G26-G25-B26;SUM;
=G26;10;=0.042/365;20250531;31;=POWER(1+C27|E27);=(G26+B27)*F27;=G27-G26-B27;SUM;
=G27;10;=0.042/365;20250630;30;=POWER(1+C28|E28);=(G27+B28)*F28;=G28-G27-B28;SUM;
=G28;10;=0.042/365;20250731;31;=POWER(1+C29|E29);=(G28+B29)*F29;=G29-G28-B29;SUM;
=G29;10;=0.042/365;20250831;31;=POWER(1+C30|E30);=(G29+B30)*F30;=G30-G29-B30;SUM;
=G30;10;=0.042/365;20250930;30;=POWER(1+C31|E31);=(G30+B31)*F31;=G31-G30-B31;SUM;
=G31;10;=0.042/365;20251031;31;=POWER(1+C32|E32);=(G31+B32)*F32;=G32-G31-B32;SUM;
=G32;10;=0.042/365;20251130;30;=POWER(1+C33|E33);=(G32+B33)*F33;=G33-G32-B33;SUM;
=G33;10;=0.042/365;20251231;31;=POWER(1+C34|E34);=(G33+B34)*F34;=G34-G33-B34;SUM;
=G34;10;=0.042/365;20260131;31;=POWER(1+C35|E35);=(G34+B35)*F35;=G35-G34-B35;SUM;
=G35;10;=0.042/365;20260228;28;=POWER(1+C36|E36);=(G35+B36)*F36;=G36-G35-B36;SUM;
=G36;10;=0.042/365;20260331;31;=POWER(1+C37|E37);=(G36+B37)*F37;=G37-G36-B37;SUM;
=G37;10;=0.042/365;20260430;30;=POWER(1+C38|E38);=(G37+B38)*F38;=G38-G37-B38;SUM;
=G38;10;=0.042/365;20260531;31;=POWER(1+C39|E39);=(G38+B39)*F39;=G39-G38-B39;SUM;
=G39;10;=0.042/365;20260630;30;=POWER(1+C40|E40);=(G39+B40)*F40;=G40-G39-B40;SUM;
=G40;10;=0.042/365;20260731;31;=POWER(1+C41|E41);=(G40+B41)*F41;=G41-G40-B41;SUM;
=G41;10;=0.042/365;20260831;31;=POWER(1+C42|E42);=(G41+B42)*F42;=G42-G41-B42;SUM;
=G42;10;=0.042/365;20260930;30;=POWER(1+C43|E43);=(G42+B43)*F43;=G43-G42-B43;SUM;
=G43;10;=0.042/365;20261031;31;=POWER(1+C44|E44);=(G43+B44)*F44;=G44-G43-B44;SUM;
=G44;10;=0.042/365;20261130;30;=POWER(1+C45|E45);=(G44+B45)*F45;=G45-G44-B45;SUM;
=G45;10;=0.042/365;20261231;31;=POWER(1+C46|E46);=(G45+B46)*F46;=G46-G45-B46;SUM;
=G46;10;=0.042/365;20270131;31;=POWER(1+C47|E47);=(G46+B47)*F47;=G47-G46-B47;SUM;
=G47;10;=0.042/365;20270228;28;=POWER(1+C48|E48);=(G47+B48)*F48;=G48-G47-B48;SUM;
=G48;10;=0.042/365;20270331;31;=POWER(1+C49|E49);=(G48+B49)*F49;=G49-G48-B49;SUM;
=G49;10;=0.042/365;20270430;30;=POWER(1+C50|E50);=(G49+B50)*F50;=G50-G49-B50;SUM;
=G50;10;=0.042/365;20270531;31;=POWER(1+C51|E51);=(G50+B51)*F51;=G51-G50-B51;SUM;
=G51;10;=0.042/365;20270630;30;=POWER(1+C52|E52);=(G51+B52)*F52;=G52-G51-B52;SUM;
=G52;10;=0.042/365;20270731;31;=POWER(1+C53|E53);=(G52+B53)*F53;=G53-G52-B53;SUM;
=G53;10;=0.042/365;20270831;31;=POWER(1+C54|E54);=(G53+B54)*F54;=G54-G53-B54;SUM;
=G54;10;=0.042/365;20270930;30;=POWER(1+C55|E55);=(G54+B55)*F55;=G55-G54-B55;SUM;
=G55;10;=0.042/365;20271031;31;=POWER(1+C56|E56);=(G55+B56)*F56;=G56-G55-B56;SUM;
=G56;10;=0.042/365;20271130;30;=POWER(1+C57|E57);=(G56+B57)*F57;=G57-G56-B57;SUM;
=G57;10;=0.042/365;20271231;31;=POWER(1+C58|E58);=(G57+B58)*F58;=G58-G57-B58;SUM;
=G58;10;=0.042/365;20280131;31;=POWER(1+C59|E59);=(G58+B59)*F59;=G59-G58-B59;SUM;
=G59;10;=0.042/365;20280228;28;=POWER(1+C60|E60);=(G59+B60)*F60;=G60-G59-B60;SUM;
=G60;10;=0.042/365;20280331;31;=POWER(1+C61|E61);=(G60+B61)*F61;=G61-G60-B61;SUM;
=G61;10;=0.042/365;20280430;30;=POWER(1+C62|E62);=(G61+B62)*F62;=G62-G61-B62;SUM;
=G62;10;=0.042/365;20280531;31;=POWER(1+C63|E63);=(G62+B63)*F63;=G63-G62-B63;SUM;
=G63;10;=0.042/365;20280630;30;=POWER(1+C64|E64);=(G63+B64)*F64;=G64-G63-B64;SUM;
=G64;10;=0.042/365;20280731;31;=POWER(1+C65|E65);=(G64+B65)*F65;=G65-G64-B65;SUM;
=G65;10;=0.042/365;20280831;31;=POWER(1+C66|E66);=(G65+B66)*F66;=G66-G65-B66;SUM;
=G66;10;=0.042/365;20280930;30;=POWER(1+C67|E67);=(G66+B67)*F67;=G67-G66-B67;SUM;
=G67;10;=0.042/365;20281031;31;=POWER(1+C68|E68);=(G67+B68)*F68;=G68-G67-B68;SUM;
=G68;10;=0.042/365;20281130;30;=POWER(1+C69|E69);=(G68+B69)*F69;=G69-G68-B69;SUM;
=G69;10;=0.042/365;20281231;31;=POWER(1+C70|E70);=(G69+B70)*F70;=G70-G69-B70;SUM;
=G70;10;=0.042/365;20290131;31;=POWER(1+C71|E71);=(G70+B71)*F71;=G71-G70-B71;SUM;
=G71;10;=0.042/365;20290228;28;=POWER(1+C72|E72);=(G71+B72)*F72;=G72-G71-B72;SUM;
=G72;10;=0.042/365;20290331;31;=POWER(1+C73|E73);=(G72+B73)*F73;=G73-G72-B73;SUM;
=G73;10;=0.042/365;20290430;30;=POWER(1+C74|E74);=(G73+B74)*F74;=G74-G73-B74;SUM;
=G74;10;=0.042/365;20290531;31;=POWER(1+C75|E75);=(G74+B75)*F75;=G75-G74-B75;SUM;
=G75;10;=0.042/365;20290630;30;=POWER(1+C76|E76);=(G75+B76)*F76;=G76-G75-B76;SUM;
=G76;10;=0.042/365;20290731;31;=POWER(1+C77|E77);=(G76+B77)*F77;=G77-G76-B77;SUM;
=G77;10;=0.042/365;20290831;31;=POWER(1+C78|E78);=(G77+B78)*F78;=G78-G77-B78;SUM;
=G78;10;=0.042/365;20290930;30;=POWER(1+C79|E79);=(G78+B79)*F79;=G79-G78-B79;SUM;
=G79;10;=0.042/365;20291031;31;=POWER(1+C80|E80);=(G79+B80)*F80;=G80-G79-B80;SUM;
=G80;10;=0.042/365;20291130;30;=POWER(1+C81|E81);=(G80+B81)*F81;=G81-G80-B81;SUM;
=G81;10;=0.042/365;20291231;31;=POWER(1+C82|E82);=(G81+B82)*F82;=G82-G81-B82;SUM;
=G82;10;=0.042/365;20300131;31;=POWER(1+C83|E83);=(G82+B83)*F83;=G83-G82-B83;SUM;");

    while ($paddr = accept (CLIENT, SERVER))
    {
        print ("\n\nNEW============================================================\n");
        print ("New connection\n");
        ($client_port, $iaddr) = sockaddr_in ($paddr);
        $client_addr = inet_ntoa ($iaddr);
        print ("\n$client_addr\n");

        my $lat;
        my $long;
        my $txt = read_from_socket (\*CLIENT);
        print ("Raw data was $txt\n");
        $txt =~ s/csv_data\/csv_data/csv_data\//img;
        $txt =~ s/csv_data\/csv_data/csv_data\//img;
        $txt =~ s/csv_data\/csv_data/csv_data\//img;
        my $get_group_info = 0;
        if ($txt =~ m/GET.*\.group_info/)
        {
            $get_group_info = 1;
            $txt =~ s/\.group_info//;
        }
        $txt =~ m/GET (.*) HTTP/;
        my $original_url = $1;

        if ($txt =~ m/.*favico.*/m)
        {
            my $size = -s ("d:/perl_programs/aaa.jpg");
            print (">>>>> size = $size\n");
            my $h = "HTTP/1.1 200 OK\nLast-Modified: 20150202020202\nConnection: close\nContent-Type: image/jpeg\nContent-Length: $size\n\n";
            print "===============\n", $h, "\n^^^^^^^^^^^^^^^^^^^\n";
            syswrite (\*CLIENT, $h);
            copy "d:/perl_programs/aaa.jpg", \*CLIENT;
            next;
        }
        
        if ($txt =~ m/GET.*update_csv.*/m)
        {
            $txt =~ m/(........update_csv.......)/im;
            my $matching_text = $1;
            my $html_text = "<html> <head> <META HTTP-EQUIV=\"CACHE-CONTROL\" CONTENT=\"NO-CACHE\"> <br> <META HTTP-EQUIV=\"EXPIRES\" CONTENT=\"Mon, 22 Jul 2094 11:12:01 GMT\"> </head> <body> <h1>Refresh CSV </h1> <br> 
<form action=\"updated_csv\" id=\"newcsv\" name=\"newcsv\" method=\"post\">
<textarea id=\"newcsv\" class=\"text\" cols=\"86\" rows =\"20\" form=\"newcsv\" name=\"newcsv\">$csv_block</textarea>
<input type=\"submit\" value=\"New CSV\" class=\"submitButton\">
</form>
</body> </html>";
            write_to_socket (\*CLIENT, $html_text, "", "noredirect");
            next;
        }
        
        if ($txt =~ m/GET.*toggle_calculate_off.*HTTP/m)
        {
            $show_formulas = 1;
        }
        if ($txt =~ m/GET.*toggle_calculate_on.*HTTP/m)
        {
            $show_formulas = 0;
        }
        if ($txt =~ m/GET.*toggle_perl_on.*HTTP/m)
        {
            $show_formulas = 2;
            my %new_csv_data;
            my $fi;
            foreach $fi (sort keys (%csv_data))
            {
                #if (!($fi =~ m/_perl/))
                {
                    $new_csv_data {$fi} = $csv_data {$fi};
                }
                #else
                #{
                #    $new_csv_data {$fi} = "perl";
                #}
            }
            %csv_data = %new_csv_data;
        }

        if ($txt =~ m/GET.*dograph_(\d+)/m)
        {
            my $col = $1;
            my $graph_html = get_graph_html ($1, get_col_header ($1));
            write_to_socket (\*CLIENT, $graph_html, "", "noredirect");
            next;
        }

        if ($txt =~ m/GET.*dograph_group_counts/m)
        {
            my $col = $1;
            my $graph_html = get_graph_html (-1, "graph_counts");
            write_to_socket (\*CLIENT, $graph_html, "", "noredirect");
            next;
        }
        
        if ($txt =~ m/GET.*dograph_group_totals/m)
        {
            my $col = $1;
            my $graph_html = get_graph_html (-2, "graph_totals");
            write_to_socket (\*CLIENT, $graph_html, "", "noredirect");
            next;
        }
        
        print ("2- - - - - - -\n");
        my $have_to_write_to_socket = 1;

        chomp ($txt);
        my $original_get = $txt;

        $txt =~ s/\+/ /mg;
        $txt =~ s/.*filter\?//;
        $txt =~ s/.*stats\?//;
        $txt =~ s/ http.*//i;
        $txt =~ s/%21/!/g;
        $txt =~ s/%22/"/g;
        $txt =~ s/%23/#/g;
        $txt =~ s/%24/\$/g;
        $txt =~ s/%25/%/g;
        $txt =~ s/%26/&/g;
        $txt =~ s/%27/'/g;
        $txt =~ s/%28/(/g;
        $txt =~ s/%29/)/g;
        $txt =~ s/%2A/*/g;
        $txt =~ s/%2B/+/g;
        $txt =~ s/%2C/,/g;
        $txt =~ s/%2D/-/g;
        $txt =~ s/%2E/./g;
        $txt =~ s/%2F/\//g;
        $txt =~ s/%3A/:/g;
        $txt =~ s/%3B/;/g;
        $txt =~ s/%3C/</g;
        $txt =~ s/%3D/=/g;
        $txt =~ s/%3E/>/g;
        $txt =~ s/%3F/?/g;
        $txt =~ s/%40/@/g;
        $txt =~ s/%5B/[/g;
        $txt =~ s/%5C/\\/g;
        $txt =~ s/%5D/]/g;
        $txt =~ s/%5E/\^/g;
        $txt =~ s/%5F/_/g;
        $txt =~ s/%60/`/g;
        $txt =~ s/%7B/{/g;
        $txt =~ s/%7C/|/g;
        $txt =~ s/%7D/}/g;
        $txt =~ s/%7E/~/g;
        $txt =~ s/%09/;/g;

        if ($txt =~ m/POST.*updated_csv.*/i)
        {
            my $csv_data = $txt;
            my $new_csv_data = "";
            my $discard_header = 1;

            while ($csv_data =~ s/^(.*?)(\n|$)//im && $discard_header >= 0)
            {
                my $line = $1;
                if ($line =~ m/^$/ || $line =~ m/^
$/)
                {
                    $discard_header --;
                }

                if (!$discard_header)
                {
                    $new_csv_data .= "$line\n";
                }
            }

            $new_csv_data =~ s/^
$//img;
            $new_csv_data =~ s/^\n$//img;
            $new_csv_data =~ s/^\n$//img;
            $new_csv_data =~ s/^.*newcsv=//img;
            $new_csv_data =~ s/%0D%0A/\n/img;
            $new_csv_data =~ s/..$//im;
            process_csv_data ($new_csv_data); 
        }

        my $search = ".*";
        if ($txt =~ m/searchstr=(.*)/im)
        {
            $search = "$1";
        }
        
        my $group = ".*";
        if ($txt =~ m/groupstr=(.*)/im)
        {
            $group = "$1";
        }
        
        my $dual_group = ".*";
        if ($txt =~ m/dualgroup=(.*)/im)
        {
            $dual_group = "$1";
        }

        my @strs = split /&/, $txt;
        #print join (',,,', @strs);

        # Sortable table with cards in it..
        my $html_text = "<!DOCTYPE html>\n";
        $html_text .= "<html lang='en' class=''>\n";
        $html_text .= "<head>\n";
        $html_text .= "  <meta charset='UTF-8'>\n";
        $html_text .= "  <title>Analyse CSV</title>\n";
        $html_text .= "  <meta name=\"robots\" content=\"noindex\">\n";
        $html_text .= "  <link rel=\"icon\" href=\"favicon.ico\">\n";
        $html_text .= "  <style id=\"INLINE_PEN_STYLESHEET_ID\">\n";
        $html_text .= "    .sr-only {\n";
        $html_text .= "  position: absolute;\n";
        $html_text .= "  top: -30em;\n";
        $html_text .= "}\n";
        $html_text .= "table.sortable td,\n";
        $html_text .= "table.sortable th {\n";
        $html_text .= "  padding: 0.125em 0.25em;\n";
        $html_text .= "}\n";
        $html_text .= "table.sortable th {\n";
        $html_text .= "  font-weight: bold;\n";
        $html_text .= "  border-bottom: thin solid #888;\n";
        $html_text .= "  position: relative;\n";
        $html_text .= "}\n";
        $html_text .= "table.sortable th.no-sort {\n";
        $html_text .= "  padding-top: 0.35em;\n";
        $html_text .= "}\n";
        $html_text .= "table.sortable th:nth-child(n+2) {\n";
        $html_text .= "  width: 10em;\n";
        $html_text .= "}\n";
        $html_text .= "table.sortable td:nth-child(-n+1) {\n";
        $html_text .= "  border: 2px solid papayawhip;\n";
        $html_text .= "  background-color: paleturquoise;\n";
        $html_text .= "  font-weight: bold;\n";
        $html_text .= "}\n";
        $html_text .= "table.sortable th button {\n";
        $html_text .= "  position: absolute;\n";
        $html_text .= "  padding: 4px;\n";
        $html_text .= "  margin: 1px;\n";
        $html_text .= "  font-size: 100%;\n";
        $html_text .= "  font-weight: bold;\n";
        $html_text .= "  background: transparent;\n";
        $html_text .= "  border: none;\n";
        $html_text .= "  display: inline;\n";
        $html_text .= "  right: 0;\n";
        $html_text .= "  left: 0;\n";
        $html_text .= "  top: 0;\n";
        $html_text .= "  bottom: 0;\n";
        $html_text .= "  width: 100%;\n";
        $html_text .= "  text-align: left;\n";
        $html_text .= "  outline: none;\n";
        $html_text .= "  cursor: pointer;\n";
        $html_text .= "}\n";
        $html_text .= "table.sortable th button span {\n";
        $html_text .= "  position: absolute;\n";
        $html_text .= "  right: 4px;\n";
        $html_text .= "}\n";
        $html_text .= "table.sortable th[aria-sort=\"descending\"] span::after {\n";
        $html_text .= "  content: ' \\25BC';\n";
        $html_text .= "  color: currentcolor;\n";
        $html_text .= "  font-size: 100%;\n";
        $html_text .= "  top: 0;\n";
        $html_text .= "}\n";
        $html_text .= "table.sortable th[aria-sort=\"ascending\"] span::after {\n";
        $html_text .= "  content: ' \\25B2';\n";
        $html_text .= "  color: currentcolor;\n";
        $html_text .= "  font-size: 100%;\n";
        $html_text .= "  top: 0;\n";
        $html_text .= "}\n";
        $html_text .= "table.show-unsorted-icon th:not([aria-sort]) button span::after {\n";
        $html_text .= "  content: ' \\2662';\n";
        $html_text .= "  color: currentcolor;\n";
        $html_text .= "  font-size: 100%;\n";
        $html_text .= "  position: relative;\n";
        $html_text .= "  top: -3px;\n";
        $html_text .= "  left: -4px;\n";
        $html_text .= "}\n";
        $html_text .= "table.sortable td.num {\n";
        $html_text .= "  text-align: right;\n";
        $html_text .= "}\n";
        $html_text .= "table.sortable td.price {\n";
        $html_text .= "  text-align: right;\n";
        $html_text .= "}\n";
        $html_text .= "table.sortable tbody tr:nth-child(odd) {\n";
        $html_text .= "  background-color: #ddd;\n";
        $html_text .= "}\n";
        $html_text .= "table.sortable th button:focus,\n";
        $html_text .= "table.sortable th button:hover {\n";
        $html_text .= "  padding: 2px;\n";
        $html_text .= "  border: 2px solid currentcolor;\n";
        $html_text .= "  background-color: #e5f4ff;\n";
        $html_text .= "}\n";
        $html_text .= "table.sortable th button:focus span,\n";
        $html_text .= "table.sortable th button:hover span {\n";
        $html_text .= "  right: 2px;\n";
        $html_text .= "}\n";
        $html_text .= "table.sortable th:not([aria-sort]) button:focus span::after,\n";
        $html_text .= "table.sortable th:not([aria-sort]) button:hover span::after {\n";
        $html_text .= "  content: ' \\2662';\n";
        $html_text .= "  color: currentcolor;\n";
        $html_text .= "  font-size: 100%;\n";
        $html_text .= "  top: 0;\n";
        $html_text .= "}\n";
        $html_text .= "</style>\n";
        $html_text .= "</head>\n";
        $html_text .= "<body>\n";
        $html_text .= "<script>\n";
        $html_text .= "var xyz = 'bbb';";
        $html_text .= "xyz = xyz.replace (/b/, 'x');";
        $html_text .= "</script>\n";
        $html_text .= "<table width=100%><tr><td>\n";
        
        $html_text .= "<form action=\"/csv_analyse/search\">
                <label for=\"searchstr\">Search:</label><br>
                <input type=\"text\" id=\"searchstr\" name=\"searchstr\" value=\"$search\">
                <input type=\"submit\" value=\"Search\">
                </form></td><td>";

        my $example = get_field_value (2, "C", 1);
        $example = "20[23]\\d";
        $example = "\"/csv_analyse/groupby?groupstr=($example)" . get_col_name_of_number_type_col () . "\"";
        $html_text .= "<form action=\"/csv_analyse/groupby\">
                <label for=\"groupstr\">Group by <font size=-2><a href=$example>Example</a></font></label><br>
                <input type=\"text\" id=\"groupstr\" name=\"groupstr\" value=\"$group\">
                <input type=\"submit\" value=\"Group By\">
                </form></td><td>";
                
        my $f1 = get_field_value (2, "D", 1);
        $f1 =~ s/\W/./img;
        $f1 =~ s/^(...)..*$/$1../img;
        my $f2 = get_field_value (2, "E", 1);
        $f2 =~ s/\W/./img;
        $f2 =~ s/^(...)..*$/$1../img;
        my $dual_example = "(20[123]\\d).*($f2)";

        $dual_example = "\"/csv_analyse/dualgroupby?dualgroup=$dual_example" . get_col_name_of_number_type_col () . "\"";
        $html_text .= "<form action=\"/csv_analyse/dualgroupby\">
                <label for=\"dualgroup\">Dual groups <font size=-2><a href=$dual_example>Example</a></font></label><br>
                <input type=\"text\" id=\"dualgroup\" name=\"dualgroup\" value=\"$dual_group\">
                <input type=\"submit\" value=\"Dual Group By\">
                </form></td>";
                
        $html_text .= "<td><form action=\"/csv_analyse/update_csv\">
                <label>Update CSV:</label><br>
                <input type=\"submit\" value=\"Update CSV\">
                </form></td>";
                
        if ($show_formulas == 0)
        {
            $html_text .= "<td><form action=\"/csv_analyse/toggle_calculate_off\">
                <label>Toggle Formulas:</label><br>
                <input type=\"submit\" value=\"Show Formulas\"></form><a href=\"/csv_analyse/toggle_perl_on\">Display Perl</a>
                </tr></table>";
        }
        else
        {
            $html_text .= "<td><form action=\"/csv_analyse/toggle_calculate_on\">
                <label>Toggle Formulas:</label><br>
                <input type=\"submit\" value=\"Calculate Cells\"></form><a href=\"/csv_analyse/toggle_perl_on\">Display Perl</a>
                </tr></table>";
        }

        my %groups;
        my $group_count = 0;
        my %group_colours;
        $group_colours {0} = "burntorange"; $group_colours {1} = "blue"; $group_colours {2} = "green"; $group_colours {3} = "darkred"; $group_colours {4} = "mediumaquamarine"; $group_colours {5} = "black"; $group_colours {6} = "darkyellow"; $group_colours {7} = "red"; $group_colours {8} = "skyblue"; $group_colours {9} = "royalblue";
        $group_colours {11} = "blueviolet"; $group_colours {12} = "darkblue"; $group_colours {13} = "darkcyan"; $group_colours {14} = "darkgoldenrod"; $group_colours {15} = "darkgray"; $group_colours {16} = "darkgreen"; $group_colours {17} = "darkgrey"; $group_colours {18} = "darkkhaki"; $group_colours {19} = "darkmagenta"; $group_colours {20} = "darkolivegreen";
        $group_colours {21} = "darkorange"; $group_colours {22} = "darkorchid"; $group_colours {23} = "darksalmon"; $group_colours {24} = "darkseagreen"; $group_colours {25} = "darkslateblue"; $group_colours {26} = "darkslategray"; $group_colours {27} = "darkslategrey"; $group_colours {28} = "darkturquoise"; $group_colours {29} = "deeppink"; $group_colours {30} = "deepskyblue";
        $group_colours {31} = "midnightblue"; $group_colours {32} = "mediumpurple"; $group_colours {33} = "dodgerblue"; $group_colours {34} = "firebrick"; $group_colours {35} = "forestgreen"; $group_colours {36} = "fuchsia"; $group_colours {37} = "slateblue"; $group_colours {38} = "slategray"; $group_colours {39} = "slategrey"; $group_colours {40} = "gainsboro";
        $group_colours {41} = "gold"; $group_colours {42} = "goldenrod"; $group_colours {43} = "gray"; $group_colours {44} = "saddlebrown"; $group_colours {45} = "grey"; $group_colours {46} = "sandybrown"; $group_colours {47} = "hotpink"; $group_colours {48} = "indianred"; $group_colours {49} = "indigo"; $group_colours {50} = "ivory";
        $group_colours {51} = "khaki"; $group_colours {52} = "lavender"; $group_colours {53} = "lavenderblush"; $group_colours {54} = "lawngreen"; $group_colours {55} = "lemonchiffon"; $group_colours {56} = "lime"; $group_colours {57} = "limegreen"; $group_colours {58} = "linen"; $group_colours {59} = "magenta"; $group_colours {60} = "maroon";
        $group_colours {61} = "mediumaquamarine"; $group_colours {62} = "mediumblue"; $group_colours {63} = "mediumorchid"; $group_colours {64} = "dimgrey"; $group_colours {65} = "mediumseagreen"; $group_colours {66} = "mediumslateblue"; $group_colours {67} = "mediumspringgreen"; $group_colours {68} = "mediumturquoise"; $group_colours {69} = "mediumvioletred"; $group_colours {70} = "dimgray";
        $group_colours {71} = "mintcream"; $group_colours {72} = "mistyrose"; $group_colours {73} = "moccasin"; $group_colours {74} = "navy"; $group_colours {75} = "oldlace"; $group_colours {76} = "olive"; $group_colours {77} = "olivedrab"; $group_colours {78} = "orange"; $group_colours {79} = "orangered"; $group_colours {80} = "orchid";
        $group_colours {81} = "palegoldenrod"; $group_colours {82} = "palegreen"; $group_colours {83} = "paleturquoise"; $group_colours {84} = "palevioletred"; $group_colours {85} = "papayawhip"; $group_colours {86} = "peachpuff"; $group_colours {87} = "peru"; $group_colours {88} = "pink"; $group_colours {89} = "plum"; $group_colours {90} = "powderblue";
        $group_colours {91} = "rebeccapurple"; $group_colours {92} = "rosybrown"; $group_colours {93} = "greenyellow"; $group_colours {94} = "salmon"; $group_colours {95} = "honeydew"; $group_colours {96} = "seagreen"; $group_colours {97} = "seashell"; $group_colours {98} = "sienna"; $group_colours {99} = "springgreen"; $group_colours {100} = "steelblue";
        $group_colours {101} = "tan"; $group_colours {102} = "teal"; $group_colours {103} = "thistle"; $group_colours {104} = "tomato"; $group_colours {105} = "turquoise"; $group_colours {106} = "violet"; $group_colours {107} = "wheat"; $group_colours {108} = "yellow"; $group_colours {109} = "yellowgreen"; $group_colours {110} = "AliceBlue";
        $group_colours {111} = "aqua"; $group_colours {112} = "aquamarine"; $group_colours {113} = "azure"; $group_colours {114} = "beige"; $group_colours {115} = "bisque"; $group_colours {116} = "purple"; $group_colours {117} = "blanchedalmond"; $group_colours {119} = "brown"; $group_colours {120} = "cadetblue"; $group_colours {121} = "chartreuse";
        $group_colours {122} = "chocolate"; $group_colours {123} = "coral"; $group_colours {124} = "cornflowerblue"; $group_colours {125} = "cornsilk"; $group_colours {126} = "crimson"; $group_colours {127} = "cyan"; $group_colours {128} = "navajowhite"; $group_colours {129} = "lightblue"; $group_colours {130} = "lightcoral"; $group_colours {131} = "lightcyan";
        $group_colours {132} = "lightgoldenrodyellow"; $group_colours {133} = "lightgray"; $group_colours {134} = "lightgreen"; $group_colours {135} = "lightgrey"; $group_colours {136} = "lightpink"; $group_colours {137} = "lightsalmon"; $group_colours {138} = "lightseagreen"; $group_colours {139} = "lightskyblue"; $group_colours {140} = "lightslategray"; $group_colours {141} = "lightslategrey";
        $group_colours {142} = "lightsteelblue"; $group_colours {143} = "lightyellow"; $group_colours {144} = "snow"; $group_colours {145} = "white"; $group_colours {146} = "whitesmoke"; $group_colours {147} = "antiquewhite"; $group_colours {148} = "floralwhite"; $group_colours {149} = "ghostwhite";

        $html_text .= "<script>\n";
        $html_text .= "'use strict';\n";
        $html_text .= "class SortableTable { constructor(tableNode) { this.tableNode = tableNode; this.columnHeaders = tableNode.querySelectorAll('thead th'); this.sortColumns = []; for (var i = 0; i < this.columnHeaders.length; i++) { var ch = this.columnHeaders[i]; var buttonNode = ch.querySelector('button'); if (buttonNode) { this.sortColumns.push(i); buttonNode.setAttribute('data-column-index', i); buttonNode.addEventListener('click', this.handleClick.bind(this)); } } this.optionCheckbox = document.querySelector( 'input[type=\"checkbox\"][value=\"show-unsorted-icon\"]'); if (this.optionCheckbox) { this.optionCheckbox.addEventListener( 'change', this.handleOptionChange.bind(this)); if (this.optionCheckbox.checked) { this.tableNode.classList.add('show-unsorted-icon'); } } } setColumnHeaderSort(columnIndex) { if (typeof columnIndex === 'string') { columnIndex = parseInt(columnIndex); } for (var i = 0; i < this.columnHeaders.length; i++) { var ch = this.columnHeaders[i]; var buttonNode = ch.querySelector('button'); if (i === columnIndex) { var value = ch.getAttribute('aria-sort'); if (value === 'descending') { ch.setAttribute('aria-sort', 'ascending'); this.sortColumn( columnIndex, 'ascending', ch.classList.contains('td.num'), ch.classList.contains('td.price')); } else { ch.setAttribute('aria-sort', 'descending'); this.sortColumn( columnIndex, 'descending', ch.classList.contains('td.num'), ch.classList.contains('td.price')); } } else { if (ch.hasAttribute('aria-sort') && buttonNode) { ch.removeAttribute('aria-sort'); } } } } sortColumn(columnIndex, sortValue, isNumber, isPrice) { function compareValues(a, b) { if (sortValue === 'ascending') { if (a.value === b.value) { return 0; } else { if (isNumber) { return a.value - b.value; } else if (isPrice) { var aval = a.value; aval = aval.replace (/\\W/g, ''); var bval = b.value; bval = bval.replace (/\\W/g, '');  return aval - bval < 0 ? -1 : 1; } else { return a.value < b.value ? -1 : 1; } } } else { if (a.value === b.value) { return 0; } else { if (isNumber) { return b.value - a.value; } else if (isPrice) { var aval = a.value; aval = aval.replace (/\\W/g, ''); var bval = b.value; bval = bval.replace (/\\W/g, '');  return aval - bval < 0 ? 1 : -1; } else { return a.value > b.value ? -1 : 1; } } } } if (typeof isNumber !== 'boolean') { isNumber = false; } var tbodyNode = this.tableNode.querySelector('tbody'); var rowNodes = []; var dataCells = []; var rowNode = tbodyNode.firstElementChild; var index = 0; while (rowNode) { rowNodes.push(rowNode); var rowCells = rowNode.querySelectorAll('th, td'); var dataCell = rowCells[columnIndex]; var data = {}; data.index = index; data.value = dataCell.textContent.toLowerCase().trim(); if (isNumber) { data.value = parseFloat(data.value); } dataCells.push(data); rowNode = rowNode.nextElementSibling; index += 1; } dataCells.sort(compareValues); while (tbodyNode.firstChild) { tbodyNode.removeChild(tbodyNode.lastChild); } for (var i = 0; i < dataCells.length; i += 1) { rowNode = rowNodes[dataCells[i].index]; rowNode.childNodes[0].innerHTML='<font size=\"-1\">Row:'+(i+1)+'</font>'; tbodyNode.appendChild(rowNodes[dataCells[i].index]); } }  handleClick(event) { var tgt = event.currentTarget; this.setColumnHeaderSort(tgt.getAttribute('data-column-index')); } handleOptionChange(event) { var tgt = event.currentTarget; if (tgt.checked) { this.tableNode.classList.add('show-unsorted-icon'); } else { this.tableNode.classList.remove('show-unsorted-icon'); } } }\n";
        $html_text .= "window.addEventListener('load', function () { var sortableTables = document.querySelectorAll('table.sortable'); for (var i = 0; i < sortableTables.length; i++) { new SortableTable(sortableTables[i]); } });\n";
        $html_text .= "</script>\n";
        $html_text .= "<div class=\"table-wrap\"><table class=\"sortable\">\n";
                
        $html_text .= "<thead>\n";
        #$html_text .= "<br><textarea style=\"font-family:courier-new;size=-3;white-space:pre-wrap\"\">QQQ</textarea><br>";
        $html_text .= "QQQ";
        
        $html_text .= "<tr>\n";
        $html_text .= "<th class=\"no-sort\">&#9698;</th>";

        my $x;
        for ($x = 0; $x < $max_field_num; $x++)
        {
            $html_text .= "<th XYZ$x> <button><font size=-1>" . get_col_header ($x) . " " . get_field_letter_from_field_num ($x) . "<span aria-hidden=\"true\"></span> </font></button> </th> \n";
        }
        $html_text .= "<th> <button><font size=-1>Group<span aria-hidden=\"true\"></span> </font></button> </th> \n";
        $html_text .= "<th> <button><font size=-1>Group_Total<span aria-hidden=\"true\"></span> </font></button> </th> \n";
        $html_text .= "<th class=\"no-sort\">*</th>";
        $html_text .= "</tr>\n";
        $html_text .= "</thead>\n";
        $html_text .= "<tbody><font size=-2>\n";

        my $checked = "";

        my $card;
        my $deck;
        my $overall_count = 0;
        my %group_prices;
        my %group_counts;
                
        my $only_one_group = 1;
        my $first_group_only = 0;
        my $dual_groups = 0;
        my $group2 = "";
        my $chosen_col = "";
        if ($group =~ s/#(.*)//)
        {
            $chosen_col = "$1";
            print ("WOOT $chosen_col\n");
        }
        
        if ($dual_group =~ s/#(.*)//)
        {
            $chosen_col = "$1";
            print ("dual WOOT $chosen_col\n");
        }

        my $overall_match = $group;
        if ($group =~ m/\((.*)\).*\((.*)\)/)
        {
            $only_one_group = 0;
            $first_group_only = 1;
            $dual_groups = 0;
            $group = "$1";
            $group2 = "$2";
        }
        
        if ($dual_group =~ m/\((.*)\).*\((.*)\)/)
        {
            $only_one_group = 0;
            $first_group_only = 0;
            $dual_groups = 1;
            $group = "$1";
            $group2 = "$2";
            $overall_match = $dual_group;
        }

        my $use_regex = 0;
        my %new_meta_data;
        my %new_calculated_data;
        my $valid_regex = eval { qr/$overall_match/ };
        if (defined ($valid_regex))
        {
            %meta_data = %new_meta_data;
            %calculated_data = %new_calculated_data;
            $use_regex = 1;
        }

        my $row_num = 1;
        my $col_letter = "A";
        my $old_row_num = 2;
        my $old_col_letter = "A";
        my $field_id = 0;
        my $row = "<tr><td><font size=-1>Row:$row_num</font></td>";
        my $fake_row;
        my $x = 0;
        my $y = 0;

        my %col_calculations;
        my $pot_group_price = "";

        #foreach $field_id (sort {$a <=> $b} keys (%csv_data))
        while ($row_num < $max_rows)
        {
            my $x = 0;
            $col_letter = "A";
            while ($x < $max_field_num)
            {
                if ($row_num eq "1") { $old_row_num = 2; $x++; $col_letter = get_next_field_letter ($col_letter); next; }
                $field_id = "$col_letter" . $row_num;
                print ("\n=============GETTING field of $col_letter$row_num: -- got:"); 
                my $field = get_field_value ($row_num, $col_letter, 1);

                if (!defined ($col_types {$col_letter}))
                {
                    if ($field =~ m/^\s*$/)
                    {
                        
                    }
                    elsif ($field =~ m/^\d\d\d\d\d\d\d\d$/ || $field =~ m/^\d\d\d\d[\/]\d\d[\/]\d\d$/ || $field =~ m/^\d\d\d\d[\/]\d\d[\/]\d$/ || $field =~ m/^\d\d\d\d[\/]\d[\/]\d\d$/ || $field =~ m/^\d\d\d\d[\/]\d[\/]\d$/ || $field =~ m/^\d\d[\/]\d\d[\/]\d\d$/ || $field =~ m/^\d\d[\/]\d\d[\/]\d$/ || $field =~ m/^\d\d[\/]\d[\/]\d\d$/ || $field =~ m/^\d\d[\/]\d[\/]\d$/ || $field =~ m/^\d\d[\/]\d\d[\/]\d\d$/ || $field =~ m/^\d[\/]\d\d[\/]\d\d$/ || $field =~ m/^\d\d[\/]\d[\/]\d\d$/ || $field =~ m/^\d[\/]\d[\/]\d\d$/ || $field =~ m/^\d\d[\/]\d\d[\/]\d\d\d\d$/ || $field =~ m/^\d[\/]\d\d[\/]\d\d\d\d$/ || $field =~ m/^\d\d[\/]\d[\/]\d\d\d\d$/ || $field =~ m/^\d[\/]\d[\/]\d\d\d\d$/)
                    {
                        set_col_type ($col_letter, "DATE");
                        if ($field =~ m/^\d\d\d\d[\/]\d\d[\/]\d\d$/)
                        {
                            $field =~ m/^(\d\d\d\d)[\/](\d\d)[\/](\d\d)$/;
                            print ("$field_id for $field -- ");
                            set_field_value ($row_num, $col_letter, "$1" . "$2" . "0$3");
                            print ("now is $csv_data{$field_id}\n");
                        }
                        elsif ($field =~ m/^\d\d\d\d[\/]\d\d[\/]\d$/)
                        {
                            $field =~ m/^(\d\d\d\d)[\/](\d\d)[\/](\d)$/;
                            print ("$field_id for $field -- ");
                            set_field_value ($row_num, $col_letter, "$1" . "$2" . "0$3");
                            print ("now is $csv_data{$field_id}\n");
                        }
                        elsif ($field =~ m/^\d\d\d\d[\/]\d[\/]\d\d$/)
                        {
                            $field =~ m/^(\d\d\d\d)[\/](\d)[\/](\d\d)$/;
                            print ("$field_id for $field -- ");
                            set_field_value ($row_num, $col_letter, "$1" . "0$2" . "$3");
                            print ("now is $csv_data{$field_id}\n");
                        }
                        elsif ($field =~ m/^\d\d[\/]\d\d[\/]\d\d\d\d$/)
                        {
                            $field =~ m/^(\d\d)[\/](\d\d)[\/](\d\d\d\d)$/;
                            print ("$field_id for $field -- ");
                            set_field_value ($row_num, $col_letter, "$3" . "$2" . "$1");
                            print ("now is $csv_data{$field_id}\n");
                        }
                        elsif ($field =~ m/^\d[\/]\d\d[\/]\d\d\d\d$/)
                        {
                            $field =~ m/^(\d)[\/](\d\d)[\/](\d\d\d\d)$/;
                            print ("$field_id for $field -- ");
                            set_field_value ($row_num, $col_letter, "$3" . "$2" . "0$1");
                            print ("now is $csv_data{$field_id}\n");
                        }
                        elsif ($field =~ m/^\d\d[\/]\d[\/]\d\d\d\d$/)
                        {
                            $field =~ m/^(\d\d)[\/](\d)[\/](\d\d\d\d)$/;
                            print ("$field_id for $field -- ");
                            set_field_value ($row_num, $col_letter, "$3" . "0$2" . "$1");
                            print ("now is $csv_data{$field_id}\n");
                        }
                        elsif ($field =~ m/^\d[\/]\d[\/]\d\d\d\d$/)
                        {
                            $field =~ m/^(\d)[\/](\d)[\/](\d\d\d\d)$/;
                            print ("$field_id for $field -- ");
                            set_field_value ($row_num, $col_letter, "$3" . "0$2" . "0$1");
                            print ("now is $csv_data{$field_id}\n");
                        }
                    }
                    elsif ($field =~ m/^\d+($|\.\d+)$/ || $field =~ m/^-\d+($|\.\d+)$/)
                    {
                        set_col_type ($col_letter, "NUMBER");
                        $col_calculations {$col_letter} = $field;
                        print ("$col_letter is now number 'cos >>$field<<\n");
                    }
                    elsif ($field =~ m/^(-|)\$(\d*[\d,])+($|\.\d+)$/)
                    {
                        set_col_type ($col_letter, "PRICE");
                        $col_calculations {$col_letter} = add_price ($col_calculations {$col_letter}, $field);
                        print ("$col_letter is now price 'cos >>$field<<\n");
                    }
                    else
                    {
                        print ("$col_letter is now general 'cos >>$field<<\n");
                        set_col_type ($col_letter, "GENERAL");
                    }
                }
                elsif ($col_types {$col_letter} ne "GENERAL")
                {
                    if ($field =~ m/^\s*$/)
                    {
                        
                    }
                    elsif ($field =~ m/^\d\d\d\d\d\d\d\d$/ || $field =~ m/^\d\d\d\d[\/]\d\d[\/]\d\d$/ || $field =~ m/^\d\d\d\d[\/]\d\d[\/]\d$/ || $field =~ m/^\d\d\d\d[\/]\d[\/]\d\d$/ || $field =~ m/^\d\d\d\d[\/]\d[\/]\d$/ || $field =~ m/^\d\d[\/]\d\d[\/]\d\d$/ || $field =~ m/^\d\d[\/]\d\d[\/]\d$/ || $field =~ m/^\d\d[\/]\d[\/]\d\d$/ || $field =~ m/^\d\d[\/]\d[\/]\d$/ || $field =~ m/^\d\d[\/]\d\d[\/]\d\d$/ || $field =~ m/^\d[\/]\d\d[\/]\d\d$/ || $field =~ m/^\d\d[\/]\d[\/]\d\d$/ || $field =~ m/^\d[\/]\d[\/]\d\d$/ || $field =~ m/^\d\d[\/]\d\d[\/]\d\d\d\d$/ || $field =~ m/^\d[\/]\d\d[\/]\d\d\d\d$/ || $field =~ m/^\d\d[\/]\d[\/]\d\d\d\d$/ || $field =~ m/^\d[\/]\d[\/]\d\d\d\d$/)
                    {
                        if ($col_types {$col_letter} ne "DATE")
                        {
                            print ("$col_letter is now general (was date) 'cos >>$field<<\n");
                            set_col_type ($col_letter, "GENERAL");
                        }
                        else
                        {
                            if ($field =~ m/^\d\d\d\d[\/]\d\d[\/]\d\d$/)
                            {
                                $field =~ m/^(\d\d\d\d)[\/](\d\d)[\/](\d\d)$/;
                                print ("$field_id for $field -- ");
                                set_field_value ($row_num, $col_letter, "$1" . "$2" . "0$3");
                                print ("now is $csv_data{$field_id}\n");
                            }
                            elsif ($field =~ m/^\d\d\d\d[\/]\d\d[\/]\d$/)
                            {
                                $field =~ m/^(\d\d\d\d)[\/](\d\d)[\/](\d)$/;
                                print ("$field_id for $field -- ");
                                set_field_value ($row_num, $col_letter, "$1" . "$2" . "0$3");
                                print ("now is $csv_data{$field_id}\n");
                            }
                            elsif ($field =~ m/^\d\d\d\d[\/]\d[\/]\d\d$/)
                            {
                                $field =~ m/^(\d\d\d\d)[\/](\d)[\/](\d\d)$/;
                                print ("$field_id for $field -- ");
                                set_field_value ($row_num, $col_letter, "$1" . "0$2" . "$3");
                                print ("now is $csv_data{$field_id}\n");
                            }
                            elsif ($field =~ m/^\d\d[\/]\d\d[\/]\d\d\d\d$/)
                            {
                                $field =~ m/^(\d\d)[\/](\d\d)[\/](\d\d\d\d)$/;
                                print ("$field_id for $field -- ");
                                set_field_value ($row_num, $col_letter, "$3" . "$2" . "$1");
                                print ("now is $csv_data{$field_id}\n");
                            }
                            elsif ($field =~ m/^\d[\/]\d\d[\/]\d\d\d\d$/)
                            {
                                $field =~ m/^(\d)[\/](\d\d)[\/](\d\d\d\d)$/;
                                print ("$field_id for $field -- ");
                                set_field_value ($row_num, $col_letter, "$3" . "$2" . "0$1");
                                print ("now is $csv_data{$field_id}\n");
                            }
                            elsif ($field =~ m/^\d\d[\/]\d[\/]\d\d\d\d$/)
                            {
                                $field =~ m/^(\d\d)[\/](\d)[\/](\d\d\d\d)$/;
                                print ("$field_id for $field -- ");
                                set_field_value ($row_num, $col_letter, "$3" . "0$2" . "$1");
                                print ("now is $csv_data{$field_id}\n");
                            }
                            elsif ($field =~ m/^\d[\/]\d[\/]\d\d\d\d$/)
                            {
                                $field =~ m/^(\d)[\/](\d)[\/](\d\d\d\d)$/;
                                print ("$field_id for $field -- ");
                                set_field_value ($row_num, $col_letter, "$3" . "0$2" . "0$1");
                                print ("now is $csv_data{$field_id}\n");
                            }
                        }
                    }
                    elsif ($field =~ m/^\d+($|\.\d+)$/ || $field =~ m/^-\d+($|\.\d+)$/)
                    {
                        if ($col_types {$col_letter} eq "PRICE")
                        {
                            print ("$col_letter is now number (was price) 'cos >>$field<<\n");
                            set_col_type ($col_letter, "NUMBER");
                        }
                        else
                        {
                            $col_calculations {$col_letter} += $field;
                        }
                    }
                    elsif ($field =~ m/^(-|)\$(\d*[\d,])+($|\.\d+)$/)
                    {
                        if ($col_types {$col_letter} eq "PRICE")
                        {
                            $col_calculations {$col_letter} = add_price ($col_calculations {$col_letter}, $field);
                        }
                        elsif ($col_types {$col_letter} ne "NUMBER")
                        {
                            print ("$col_letter is now general (was NUMBER) 'cos >>$field<<\n");
                            set_col_type ($col_letter, "GENERAL");
                        }
                    }
                    else
                    {
                        print ("$col_letter is now general 'cos >>$field<<\n");
                        set_col_type ($col_letter, "GENERAL");
                    }
                }

                print ("\n=============GETTING field of $col_letter$row_num: -- got "); 
                $field = get_field_value ($row_num, $col_letter, 1);
                print (">>>>>$field<<<<<:\n"); 
                if ($row_num > $old_row_num)
                {
                    # Add row to table if matched 
                    $fake_row = $row;
                    $fake_row =~ s/<[^>]*>//img;
                    $fake_row =~ s/\n//img;
                    my $force_row = 0;
                    if ($dual_groups)
                    {
                        print ("DUAL- checking $overall_match vs $fake_row\n");
                        $force_row = -1;
                    }
                    
                    if ($use_regex && $fake_row =~ m/$overall_match/im && $overall_match ne ".*" && $overall_match ne "") 
                    {
                        $force_row = 1;
                        if ($only_one_group == 1 && $fake_row =~ m/($group)/im) 
                        {
                            my $this_group = $1;
                            $row .= " <td>$this_group</td>\n";
                            my $g_price = "GPRICE_$this_group";
                            $row .= " <td>$g_price</td> </tr>\n";

                            if (!defined ($group_colours {$this_group}))
                            {
                                $group_colours {$this_group} = $group_colours {$group_count};
                                $group_count++;
                            }
                            $row =~ s/<td>/<td><font color=$group_colours{$this_group}>/img;
                            $row =~ s/<\/td>/<\/font><\/td>/img;

                            # Leave first td alone..
                            $row =~ s/<td><font color=$group_colours{$this_group}>/<td>/im;
                            $row =~ s/<\/font><\/td>/<\/td>/im;
                            $group_counts {$this_group}++;

                            $pot_group_price = get_field_value ($old_row_num, get_num_of_col_header ($chosen_col), 0);
                            $group_prices {$this_group} = add_price ($group_prices {$this_group}, $pot_group_price);
                            $group_prices {$this_group . "_calc"} .= "+$pot_group_price ($old_row_num,$chosen_col)";
                        }
                        elsif ($first_group_only && $fake_row =~ m/$overall_match/im && ($fake_row =~ m/($group)/mg))
                        {
                            my $this_group = $1;
                            if ($fake_row =~ m/($group2)/mg)
                            {
                                $group_counts {$this_group}++;
                                $pot_group_price = get_field_value ($old_row_num, get_num_of_col_header ($chosen_col), 0);
                                $group_prices {$this_group} = add_price ($group_prices {$this_group}, $pot_group_price);
                                $group_prices {$this_group . "_calc"} .= "+$pot_group_price ($old_row_num,$chosen_col)";
                                $row .= " <td>$this_group</td>\n";
                                my $g_price = "GPRICE_$this_group";
                                $row .= " <td>$g_price</td> </tr>\n";
                                
                                if (!defined ($group_colours {$this_group}))
                                {
                                    $group_colours {$this_group} = $group_colours {$group_count};
                                    $group_count++;
                                }
                                $row =~ s/<td>/<td><font color=$group_colours{$this_group}>/img;
                                $row =~ s/<\/td>/<\/font><\/td>/img;
                                # Leave first td alone..
                                $row =~ s/<td><font color=$group_colours{$this_group}>/<td>/im;
                                $row =~ s/<\/font><\/td>/<\/td>/im;
                            }
                            else
                            {
                                $row .= "<td><font size=-3>No group ($row_num A)</font></td>\n";
                                $row .= "<td><font size=-3>No group Total</font></td></tr>\n";
                            }
                        }
                        elsif ($dual_groups && $fake_row =~ m/($overall_match)/im)
                        {
                            $fake_row =~ m/($group)/im;
                            print ("DUAL $fake_row\n");
                            my $this_group = $1;
                            if ($fake_row =~ m/($group2)/im)
                            {
                                $this_group .= " " . $1;
                                $group_counts {$this_group}++;
                                $pot_group_price = get_field_value ($old_row_num, get_num_of_col_header ($chosen_col), 0);
                                $group_prices {$this_group} = add_price ($group_prices {$this_group}, $pot_group_price);
                                $group_prices {$this_group . "_calc"} .= "+$pot_group_price ($old_row_num,$chosen_col)";
                                $row .= " <td>$this_group</td>\n";
                                my $g_price = "GPRICE_$this_group";
                                $row .= " <td>$g_price</td> </tr>\n";
                                if (!defined ($group_colours {$this_group}))
                                {
                                    $group_colours {$this_group} = $group_colours {$group_count};
                                    $group_count++;
                                }
                                $row =~ s/<td>/<td><font color=$group_colours{$this_group}>/img;
                                $row =~ s/<\/td>/<\/font><\/td>/img;

                                # Leave first td alone..
                                $row =~ s/<td><font color=$group_colours{$this_group}>/<td>/im;
                                $row =~ s/<\/font><\/td>/<\/td>/im;
                            }
                        }
                    }
                    else
                    {
                        $row .= "<td><font size=-3>No group</font></td>\n";
                        $row .= "<td><font size=-3>No group Total</font></td></tr>\n";
                    }

                    if (($row =~ m/$search/im || $search eq "") && $force_row >= 0)
                    {
                        $overall_count++;
                        $html_text .= "$row ";
                    }

                    $row = "<tr><td><font size=-1>Row:$old_row_num</font></td><td>$field</td>\n";
                    $old_row_num = $row_num;
                }
                else
                {
                    $row .= "<td>$field</td>\n";
                }
                $x++;
                $col_letter = get_next_field_letter ($col_letter); 
            }
            $row_num++;
        }
        
        # Handle last row..
        {
            # Add row to table if matched 
            $fake_row = $row;
            $fake_row =~ s/<[^>]*>//img;
            my $force_row = 0;
            if ($dual_groups)
            {
                $force_row = -1;
            }

            if ($use_regex && $fake_row =~ m/$overall_match/im && $overall_match ne ".*" && $overall_match ne "") 
            {
                $force_row = 1;
                if ($only_one_group == 1 && $fake_row =~ m/($group)/im) 
                {
                    my $this_group = $1;
                    $group_counts {$this_group}++;
                    $row .= " <td>$this_group</td>\n";
                    my $g_price = "GPRICE_$this_group";
                    $row .= " <td>$g_price</td> </tr>\n";
                }
                elsif ($first_group_only && $fake_row =~ m/$overall_match/im && ($fake_row =~ m/($group)/mg))
                {
                    my $this_group = $1;
                    if ($fake_row =~ m/($group2)/mg)
                    {
                        $group_counts {$this_group}++;
                        $row .= " <td>$this_group</td>\n";
                        my $g_price = "GPRICE_$this_group";
                        $row .= " <td>$g_price</td> </tr>\n";
                    }
                    else
                    {
                        $row .= "<td><font size=-3>No group</font></td>\n";
                        $row .= "<td><font size=-3>No group Total</font></td></tr>\n";
                    }
                }
                elsif ($dual_groups && $fake_row =~ m/($group)/im)
                {
                    my $this_group = $1;
                    if ($fake_row =~ m/($group2)/im)
                    {
                        $this_group .= " " . $1;
                        $group_counts {$this_group}++;
                        $row .= " <td>$this_group</td>\n";
                        my $g_price = "GPRICE_$this_group";
                        $row .= " <td>$g_price</td> </tr>\n";
                    }
                    else
                    {
                        $row .= "<td><font size=-3>No group</font></td>\n";
                        $row .= "<td><font size=-3>No group Total</font></td></tr>\n";
                    }
                }
            }
            else
            {
                $row .= "<td><font size=-3>No group</font></td>\n";
                $row .= "<td><font size=-3>No group Total</font></td></tr>\n";
            }

            if (($row =~ m/$search/im || $search eq "") && $force_row >= 0)
            {
                $overall_count++;
                $html_text .= "$row ";
            }
        }

        $html_text .= "</font></tbody>\n";
        $html_text .= "</table></div>\n";
        if ($use_regex != 1) { $overall_count .= "&nbsp;&nbsp;<font color=red>NB: Error with regex $overall_match</font>"; }
        $html_text =~ s/YYY/$overall_count/mg;

        my $group_block;
        
        for ($x = 0; $x < $max_field_num; $x++)
        {
            if (get_col_type ($x) eq "PRICE" || get_col_type ($x) eq "NUMBER")
            {
                $group_block .= "<button onclick=\"location.href='dograph_$x'\">Graph " . get_col_header ($x) . "</button>";

                my $str = "class=td.price";
                $html_text =~ s/XYZ$x/$str/;
            }
            else
            {
                $html_text =~ s/XYZ$x//;
            }
        }

        if (($only_one_group || $first_group_only || $dual_groups) && $use_regex)
        {
            $group_block .= "<button onclick=\"location.href='dograph_group_counts'\">Graph group counts</button>";
            $group_block .= "<button onclick=\"location.href='dograph_group_totals'\">Graph group totals</button>";
        }
        
        $group_block .= "<br>";

        if ($group =~ m/.../)
        {
            my $g;
            my $total_g_count;
            my $total_g_price;
            
            foreach $g (sort keys (%group_counts))
            {
                my $g_price = $group_prices {$g};
                my $g_count = $group_counts {$g};
                my $g_calc = $group_prices {$g. "_calc"};
                if ($g_price =~ m/\./)
                {
                    $g_price = $g_price / 100;
                }
                else
                {
                    $g_price =~ s/(\d\d)$/.$1/;
                }
                
                my $replace_g_price = "GPRICE_$g";
                $html_text =~ s/$replace_g_price/$g_price/img;

                if ($g_count != 1)
                {
                    $group_block .= "<font color=$group_colours{$g}>Group $g had $g_count rows (total was $g_price)</font><br>";
                }
                else
                {
                    $group_block .= "<font color=$group_colours{$g}>Group $g had $g_count row (total was $g_price)</font><br>";
                }

                if ($get_group_info)
                {
                    my $g_calc = $group_prices {$g. "_calc"};
                    $group_block .= "<font color=$group_colours{$g}>Group $g had calculation of $g_calc</font><br>";
                }

                $total_g_count += $g_count;
                $total_g_price += $g_price;

                $meta_data {$g . "_total"} = $g_price;
                $meta_data {$g . "_count"} = $g_count;
            }
            $group_block .= "Total group row count: $total_g_count"; 
        }

        my $c;
        foreach $c (sort keys (%col_types))
        {
            if ($col_types{$c} eq "PRICE")
            {
                $col_calculations{$c} = $col_calculations{$c} / 100;
            }
        
            if ($get_group_info)
            {
                $group_block .= "<br> TODO - let edit here! Column $c (" . get_col_header ($c) . "): $col_types{$c} ($col_calculations{$c}) Rounding digits:($col_roundings{$c})"; 
            }
        }

        if ($get_group_info)
        {
            my $col = $1;
            $group_block = "<a href=\"/csv_analyse$original_url\">Return to Sheet view</a><br>$group_block";
            write_to_socket (\*CLIENT, $group_block, "", "noredirect");
            next;
        }

        my $g_url = "No group info to view<br>";
        if ($group_count == 1)
        {
            $g_url = "<a href=\"/csv_analyse$original_url.group_info\">View group information</a><br>";
        }
        elsif ($group_count > 1)
        {
            $g_url = "<a href=\"/csv_analyse$original_url.group_info\">View all $group_count groups</a><br>";
        }
        $group_block =~ s/<br>/\n/img;
        $group_block =~ s/^((.*\n){0,7})(.*)\n/$1\nrest truncated../m;
        $group_block = "$g_url<font size=-1>$1$2</font>";
                                    
        $group_block =~ s/\n/<br>/img;
        $group_block = "<div style=\"-webkit-mask-image:linear-gradient(to bottom, black 0%, transparent 100%);mask-image:linear-gradient(to bottom, black 0%, transparent 100%);background-color: skyblue\">" .
                       $group_block . 
                       "</div>";
        $html_text =~ s/QQQ/$group_block/im;
        $html_text =~ s/QQQ//im;
        
        my $c = get_col_name_of_number_type_col ();
        $html_text =~ s/%23NUM_COL/$c/im;
        $html_text =~ s/%23NUM_COL/$c/im;

        $html_text .= "<br>$deck";
        $html_text .= "</body>\n";
        $html_text .= "</html>\n";

        write_to_socket (\*CLIENT, $html_text, "", "noredirect");
        $have_to_write_to_socket = 0;
        print ("============================================================\n");
    }
}
