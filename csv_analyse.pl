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
        my $line = $1;
        chomp $line;
        if ($line =~ m/^$/)
        {
            next;
        }
        $col_letter = "A";
        while ($line =~ m/./ && $line =~ s/^([^;\t]*)([;\t]|$)//)
        {
            my $field = $1;
            $csv_data {"$col_letter" . "$line_num"} = $field;
            print (">>$col_letter$line_num === $field  ($line left)\n");
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
    while ($block =~ s/^([^;\t]*)([;\t]|$)// && $block =~ m/./)
    {
        my $field = $1;
        $csv_data {"$line_num.$col_letter"} = $field;
        print (">> last $col_letter$line_num === $field  ($block left)\n");
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
    my $orig_field_id = $_ [1]; 

    $field_val =~ s/:[A-Z]+\d+/:/;
    $field_val =~ s/[A-Z]+\d+://;
    $field_val =~ s/$orig_field_id//;
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

sub is_number
{
    my $field = $_ [0];
    return ($field =~ m/^\d+($|\.\d+)$/ || $field =~ m/^-\d+($|\.\d+)$/ || $field =~ m/^\+\d+($|\.\d+)$/)
}

sub excel_to_perl_calculation
{
    # Egs:  =IF(A1<10|SUM(B2:B10)|100-MAX(10|B11))
    # Egs:  =IF(A2+0.31/2>10|10|A2+0.31/2)
    # Egs:  =IF(A2+0.31/2>10|BBB|concatenate(B2|"A"))

    my $field_val = $_ [0];
    my $field_id = $_ [1];
    print ("\nDOING  ---- excel_to_perl_calculation for >>$field_val<<\n");
    $field_val =~ s/PI\(\)/3.14159265358979323/img;
    $field_val =~ s/([^=]+)=([^=]+)/$1==$2/g;
    my $finished = 1;

    if ($field_val =~ m/SUM\(/)
    {
        $field_val = do_sum_expansion ($field_val);
    }
    if ($field_val =~ m/CONCATENATE\(/)
    {
        $field_val = do_concat_expansion ($field_val);
    }
    if ($field_val =~ m/POWER\(/)
    {
        $field_val = do_power_expansion ($field_val);
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
    print ("NOW finished: $field_id = {$field_val}\n");
    return $field_val;
}

sub do_power_expansion
{
    my $field_val = $_ [0];
    if ($field_val =~ m/((POWER)\(.*)/)
    {
        my $to_check = $1;
        my $func = $2;
        if (simple_parentheses_only_two_arguments ($to_check, "$func"))
        {
            $field_val =~ s/$func\((.+)\|(.+)\)/($1)**($2)/;
            return $field_val; 
        }
    }
    return $field_val; 
}

sub do_concat_expansion
{
    my $field_val = $_ [0];
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
            $field_val =~ s/CONCATENATE\(([^\|]+?)|(.+?)\)/$1 . CONCATENATE($2)/;
        }
        return $field_val;
    }
    return $field_val; 
}

sub do_sum_expansion
{
    my $field_val = $_ [0];

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
                my $cv = get_field_value ($j, get_field_letter_from_field_num ($i), 0); 
                if (is_number ($cv))
                {
                    $sum_str .= "$cv+";
                }
                else
                {
                    $sum_str .= get_field_letter_from_field_num ($i) . "$j+";   
                }
                $j++;
            }
            $j = $first_num; 
            $i++;
        }
        $sum_str =~ s/\+$//;
        $sum_str .= "";
        return $sum_str;
    }
    return $field_val;
}

sub calc_field_value
{
    my $field_val = $_ [0]; 
    my $row_num = $_ [1]; 
    my $col_letter = $_ [2]; 
    my $next_field_id = has_field_id ($field_val, "$col_letter$row_num");

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
        $next_field_id = has_field_id ($field_val, "$col_letter$row_num");
    }

    if ($field_val =~ s/^=//)
    {
        my $orig_field_val = $field_val;
        my $fv = excel_to_perl_calculation ($field_val, "$col_letter$row_num");

        my $next_field_id = has_field_id ("=" . $fv, "$col_letter$row_num");
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

### EXPERIMENTAL
sub exp_simple_parentheses_only_one_argument 
{
    my $field_val = $_ [0];
    my $func = $_ [1];
    if ($field_val =~ m/^$func\([^(\|]+\)/)
    {
        #print ("Checked s1a ($field_val) and ok\n");
        return 1;
    }
    #print ("Checked s1a ($field_val) and NOT ok\n");
    return 0;
}

sub exp_simple_parentheses_only_two_arguments
{
    my $field_val = $_ [0];
    my $func = $_ [1];
    if ($field_val =~ m/^$func\([^(\|]*\|[^(\|]*?\)/)
    {
        #print ("Checked s2a and ok\n");
        return 1;
    }
    #print ("Checked s2a for $field_val and NOT ok\n");
    return 0;
}

sub exp_simple_parentheses_only_three_arguments
{
    my $field_val = $_ [0];
    my $func = $_ [1];
    if ($field_val =~ m/^$func\([^(\|]+\|/)
    {
        #print ("Checked s3a for $field_val aaa\n");
    }
    if ($field_val =~ m/^$func\([^(\|]+\|[^(\|]+\|/)
    {
        #print ("Checked s3a for $field_val bbb\n");
    }
    if ($field_val =~ m/^$func\([^(\|]+\|[^(\|]+\|[^(\|]+\)/)
    {
        #print ("Checked s3a for $field_val ccc\n");
    }
    if ($field_val =~ m/^$func\([^(\|]+\|[^(\|]+\|[^(\|]+\)/)
    {
        #print ("Checked s3a for $field_val and ok\n");
        return 1;
    }
    #print ("Checked s3a for $field_val and NOT ok\n");
    return 0;
}

sub exp_simple_parentheses_many_arguments
{
    my $field_val = $_ [0];
    my $func = $_ [1];
    if ($field_val =~ m/^$func\(([^(\|]+\|){3,10}[^(\|]+\)/)
    {
        #print ("Checked sMa for $field_val and ok\n");
        return 1;
    }
    #print ("Checked sMa for $field_val and NOT ok\n");
    return 0;
}

my $count = 0;
my %each_element;
my $each_element_count = 0;

sub breakdown_excel
{
    my $excel_function = $_ [0];
    print (">>>>>>>>>=================$excel_function\n");
    my $i = 0;
    while ($excel_function =~ s/"([^"]*)"/xxSTRING$each_element_count/) 
    {
        $each_element {"xxSTRING$each_element_count"} = $1 . "<<xxSTRING$each_element_count";
        $each_element_count++;
        $i++;
    }
    
    $count ++;
    if ($count > 500) { print (">>>>>>>>>========GIVING UP =========$excel_function\n"); return "giving up"; }
    while ($excel_function =~ m/(([A-Z]+)\(.*)/) 
    {
        my $test = $1;
        my $func = $2;
        #$test =~ s/\.XYZ\./(/;
        print (" CHECKING >$func< for >$test<\n");
        if (exp_simple_parentheses_only_one_argument ($test, $func)) 
        {
            $excel_function =~ s/($func\([^\)]*\))/xxONE$each_element_count/; 
            $each_element {"xxONE$each_element_count"} = $1 . "<<xxONE$each_element_count";
            $each_element_count++;
            print (" Found 1sa func of $1 (Now $excel_function)\n");
        }
        elsif (exp_simple_parentheses_only_two_arguments ($test, $func)) 
        {
            $excel_function =~ s/($func\([^\|\)]*\|.*?\))/xxTWO$each_element_count/; 
            $each_element {"xxTWO$each_element_count"} = $1 . "<<xxTWO$each_element_count";
            $each_element_count++;
            print (" Found 2sa func of $1 (Now $excel_function)\n");
        }
        elsif (exp_simple_parentheses_only_three_arguments ($test, $func)) 
        {
            $excel_function =~ s/($func\([^\|\)]*\|[^\|\)]*\|.*?\))/xxTHREE$each_element_count/; 
            $each_element {"xxTHREE$each_element_count"} = $1 . "<<xxTHREE$each_element_count";
            $each_element_count++;
            print (" Found 3sa func of $1 (Now $excel_function)\n");
        }
        elsif (exp_simple_parentheses_many_arguments($test, $func)) 
        {
            $excel_function =~ s/($func\([^\|\)]*\|[^\|\)]*\|.*?\))/xxMANY$each_element_count/; 
            $each_element {"xxMANY$each_element_count"} = $1 . "<<xxMANY$each_element_count";
            $each_element_count++;
            print (" Found MANYsa func of $1 (Now $excel_function)\n");
        }
        else
        {
            $excel_function =~ s/$func\(/$func.XYZ./;
            print (" Do later !! (Now $excel_function)\n");
        }
    }
    if ($excel_function =~ m/\.XYZ\./)
    {
        $excel_function =~ s/\.XYZ\./(/g;
        return breakdown_excel ($excel_function);
    }
    $each_element {"ZZMAX"} = $excel_function;
    return $excel_function;
}

sub recreate_excel
{
    my $str;
    my $k;
    my $v;
    foreach $k (sort keys (%each_element))
    {
        $v = $each_element {$k};
        print ("recreate - checking >$v<\n");
        if ($v =~ m/^SUM\(/)
        {
            $v = do_sum_expansion ($v);
            print ("DID $k SUM - $v\n");
            $each_element {$k} = $v;
        }
        elsif ($v =~ m/^CONCATENATE\(/)
        {
            $v = do_concat_expansion ($v);
            print ("DID $k CONCAT - $v\n");
            $each_element {$k} = $v;
        }
        elsif ($v =~ m/^POWER\(/)
        {
            $v = do_power_expansion ($v);
            print ("DID $k POWER - $v\n");
            $each_element {$k} = $v;
        }
    }

    foreach $k (sort keys (%each_element))
    {
        if ($k ne "ZZMAX")
        {
            next;
        }
        my $str = $each_element {$k}; 
        print " mmm doing: $k -- >$str<\n";

        $str =~ s/<<xx.*//;
        print " mmm2 doing: $k -- >$str<\n";
        while ($str =~ m/(xx[A-Z]+\d+)/)
        {
            my $k2 = $1;
            my $str2 = $each_element{$k2};
            print " zzz doing: $k -- >$str< for ($k2) $str\n";
            $str2 =~ s/<<xx.*//;

            $str =~ s/$k2/$str2/; 
        }
        $each_element {$k} = $str; 
        if ($k =~ m/ZZMAX/)
        {
            print "Done: $k -- >$str<\n";
            return $str;
        }
        print " not Done yet: $k -- $str\n";
    }
}
### END EXPERIMENTAL

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
                my %new_each_element;
                %each_element = %new_each_element;
                $count = 0;
                $each_element_count = 0;
                breakdown_excel ($csv_data {$field_id});
                my $v = recreate_excel ();
                my $some_val = calc_field_value ($v, $row_num, $col_letter);
                $calc_val = calc_field_value ($csv_data {$field_id}, $row_num, $col_letter);
                print ("RECREATED calc_val $some_val <<< read\n");
                print ("NOT RECREATED calc_val $calc_val <<< read\n");
                if ($some_val ne $calc_val)
                {
                    if ($calc_val eq "")
                    {
                         $calc_val = $some_val;
                    }
                }
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
            if (!defined ($csv_data {$field_id . "_perl"}))
            {
                return $csv_data {$field_id};
            }
            return ($csv_data {$field_id . "_perl"});
        }
        elsif ($for_display == 1 && $show_formulas == 1 && $calc_val =~ m/^[-,\$\d\.]+$/ && $calc_val =~ m/^.+\..+$/)
        {
            if (!defined ($csv_data {$field_id . "_calc"}))
            {
                return $csv_data {$field_id};
            }
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

    $graph_html .= "<html>\n";
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

    process_csv_data ("BOB;BOB;CALCULATION;STR_CALCULATION;sadf;asdf;asdf;asdfasdf
0.26;0.26;4.25076923;AAA;;;;
0.26;0.26;=IF(C2+0.31/2>10|10|C2+0.31/2);=IF(C2+0.31/2>10|\"BBB\"|CONCATENATE(D2|\"A\"));;;;
0.26;0.26;=IF(C3+0.31/2>10|10|C3+0.31/2);=IF(C3+0.31/2>10|\"BBB\"|CONCATENATE(D3|\"B\"));=IF(F3+0.31/2>10|10|F3+0.31/2);=IF(G3+0.31/2>10|10|G3+0.31/2);=IF(H3+0.31/2>10|10|H3+0.31/2);=IF(I3+0.31/2>10|10|I3+0.31/2)
=SUM(A2:A4);=SUM(B2:B4);=IF(C4+0.31/2>10|10|C4+0.31/2);=IF(C4+0.31/2>10|\"BBB\"|CONCATENATE(D4|\"B\"));=IF(E4+0.31/2>10|10|E4+0.31/2);=IF(F4+0.31/2>10|10|F4+0.31/2);=IF(G4+0.31/2>10|10|G4+0.31/2);=IF(H4+0.31/2>10|10|H4+0.31/2)
=A2+A3+A4;=B2+B3+B4;=IF(C5+0.31/2>10|10|C5+0.31/2);=IF(C5+0.31/2>10|\"BBB\"|CONCATENATE(D5|\"B\"));=IF(E5+0.31/2>10|10|E5+0.31/2);=IF(F5+0.31/2>10|10|F5+0.31/2);=IF(G5+0.31/2>10|10|G5+0.31/2);=IF(H5+0.31/2>10|10|H5+0.31/2)
;;=IF(C6+0.31/2>10|10|C6+0.31/2);=IF(C6+0.31/2>10|\"BBB\"|CONCATENATE(D6|\"B\"));=IF(E6+0.31/2>10|10|E6+0.31/2);=IF(F6+0.31/2>10|10|F6+0.31/2);=IF(G6+0.31/2>10|10|G6+0.31/2);=IF(H6+0.31/2>10|10|H6+0.31/2)
=POWER(SUM(A2:B4)|SUM(A2:A4));;=IF(C7+0.31/2>10|10|C7+0.31/2);=IF(C7+0.31/2>10|\"BBB\"|CONCATENATE(D7|\"B\"));=IF(E7+0.31/2>10|10|E7+0.31/2);=IF(F7+0.31/2>10|10|F7+0.31/2);=IF(G7+0.31/2>10|10|G7+0.31/2);=IF(H7+0.31/2>10|10|H7+0.31/2)
;;=IF(C8+0.31/2>10|10|C8+0.31/2);=IF(C8+0.31/2>10|\"BBB\"|CONCATENATE(D8|\"B\"));=IF(E8+0.31/2>10|10|E8+0.31/2);=IF(F8+0.31/2>10|10|F8+0.31/2);=IF(G8+0.31/2>10|10|G8+0.31/2);=IF(H8+0.31/2>10|10|H8+0.31/2)
;;=IF(C9+0.31/2>10|10|C9+0.31/2);=IF(C9+0.31/2>10|\"BBB\"|CONCATENATE(D9|\"B\"));=IF(E9+0.31/2>10|10|E9+0.31/2);=IF(F9+0.31/2>10|10|F9+0.31/2);=IF(G9+0.31/2>10|10|G9+0.31/2);=IF(H9+0.31/2>10|10|H9+0.31/2)
;;=IF(C10+0.31/2>10|10|C10+0.31/2);=IF(C10+0.31/2>10|\"BBB\"|CONCATENATE(D10|\"B\"));=IF(E10+0.31/2>10|10|E10+0.31/2);=IF(F10+0.31/2>10|10|F10+0.31/2);=IF(G10+0.31/2>10|10|G10+0.31/2);=IF(H10+0.31/2>10|10|H10+0.31/2)
;;=IF(C11+0.31/2>10|10|C11+0.31/2);=IF(C11+0.31/2>10|\"BBB\"|CONCATENATE(D11|\"B\"));;;;=SUM(E4:H11)
");
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
        my $html_text = "<html>\n";
        $html_text .= "<head>\n";
        $html_text .= "  <meta charset='UTF-8'>\n";
        $html_text .= "  <title>Analyse CSV</title>\n";
        $html_text .= "  <meta name=\"robots\" content=\"noindex\">\n";
        $html_text .= "  <link rel=\"icon\" href=\"favicon.ico\">\n";
        $html_text .= "  <style id=\"INLINE_PEN_STYLESHEET_ID\">\n";
        $html_text .= "    .field_div\n";
        $html_text .= "    { text-align: center; margin-bottom: 10px; background-color: gainsboro; }\n";
        $html_text .= "    .field_div .field_border\n";
        $html_text .= "    { border: 1px solid black; padding: 2px; white-space: nowrap; border-radius: 3px; display: inline; display: inline-block; }\n";
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
        $html_text .= "<div id=\"fieldID\" class=\"field_div\"><div class=\"field_border\"></div></div>";
        $html_text .= "<table width=100%><tr>\n";
        
        $html_text .= "<td><form action=\"/csv_analyse/search\">
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
        $html_text .= "<div class=\"table-wrap\"><table id=\"table\" class=\"sortable\">\n";
                
        $html_text .= "<thead>\n";
        #$html_text .= "<br><textarea style=\"font-family:courier-new;size=-3;white-space:pre-wrap\"\">QQQ</textarea><br>";
        $html_text .= "QQQ";
        
        $html_text .= "<tr>\n";
        $html_text .= "<th class=\"no-sort\"><div id=\"field\"/>&#9698;</th>";

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
                            $col_letter = get_next_field_letter ($col_letter); 
                            $row .= " <td id='$col_letter$row_num'>$this_group</td>\n";
                            my $g_price = "GPRICE_$this_group";
                            $col_letter = get_next_field_letter ($col_letter); 
                            $row .= " <td id='$col_letter$row_num'>$g_price</td> </tr>\n";

                            if (!defined ($group_colours {$this_group}))
                            {
                                $group_colours {$this_group} = $group_colours {$group_count};
                                $group_count++;
                            }
                            $row =~ s/(<td[^>]+>)/$1<font color=$group_colours{$this_group}>/img;
                            $row =~ s/<\/td>/<\/font><\/td>/img;

                            # Leave first td alone..
                            $row =~ s/(<td[^>]+>)<font color=$group_colours{$this_group}>/$1/im;
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
                                $col_letter = get_next_field_letter ($col_letter); 
                                $row .= " <td id='$col_letter$row_num'>$this_group</td>\n";
                                my $g_price = "GPRICE_$this_group";
                                $col_letter = get_next_field_letter ($col_letter); 
                                $row .= " <td id='$col_letter$row_num'>$g_price</td> </tr>\n";
                                
                                if (!defined ($group_colours {$this_group}))
                                {
                                    $group_colours {$this_group} = $group_colours {$group_count};
                                    $group_count++;
                                }
                                $row =~ s/(<td[^>]+>)/$1<font color=$group_colours{$this_group}>/img;
                                $row =~ s/<\/td>/<\/font><\/td>/img;
                                # Leave first td alone..
                                $row =~ s/(<td[^>]+>)<font color=$group_colours{$this_group}>/$1/im;
                                $row =~ s/<\/font><\/td>/<\/td>/im;
                            }
                            else
                            {
                                $old_col_letter = get_next_field_letter ($old_col_letter); 
                                $row .= "<td id='$old_col_letter$old_row_num'><font size=-3>No group</font></td>\n";
                                $old_col_letter = get_next_field_letter ($old_col_letter); 
                                $row .= "<td id='$old_col_letter$old_row_num'><font size=-3>No group Total</font></td></tr>\n";
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
                                $col_letter = get_next_field_letter ($col_letter); 
                                $row .= " <td id='$col_letter$row_num'>$this_group</td>\n";
                                my $g_price = "GPRICE_$this_group";
                                $col_letter = get_next_field_letter ($col_letter); 
                                $row .= " <td id='$col_letter$row_num'>$g_price</td> </tr>\n";
                                if (!defined ($group_colours {$this_group}))
                                {
                                    $group_colours {$this_group} = $group_colours {$group_count};
                                    $group_count++;
                                }
                                $row =~ s/(<td[^>]+>)/$1<font color=$group_colours{$this_group}>/img;
                                $row =~ s/<\/td>/<\/font><\/td>/img;

                                # Leave first td alone..
                                $row =~ s/(<td[^>]+>)<font color=$group_colours{$this_group}>/$1/im;
                                $row =~ s/<\/font><\/td>/<\/td>/im;
                            }
                        }
                    }
                    else
                    {
                        $old_col_letter = get_next_field_letter ($old_col_letter); 
                        $row .= "<td id='$old_col_letter$old_row_num'><font size=-3>No group</font></td>\n";
                        $old_col_letter = get_next_field_letter ($old_col_letter); 
                        $row .= "<td id='$old_col_letter$old_row_num'><font size=-3>No group Total</font></td></tr>\n";
                    }

                    if (($row =~ m/$search/im || $search eq "") && $force_row >= 0)
                    {
                        $overall_count++;
                        $html_text .= "$row ";
                    }

                    $row = "<tr><td><font size=-1>Row:$old_row_num</font></td><td id='$col_letter$row_num'>$field</td>\n";
                    $old_row_num = $row_num;
                }
                else
                {
                    $row .= "<td id='$col_letter$row_num'>$field</td>\n";
                }
                $x++;
                $old_col_letter = $col_letter;
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
                        $old_col_letter = get_next_field_letter ($old_col_letter); 
                        $row .= "<td id='$old_col_letter$old_row_num'><font size=-3>No group</font></td>\n";
                        $old_col_letter = get_next_field_letter ($old_col_letter); 
                        $row .= "<td id='$old_col_letter$old_row_num'><font size=-3>No group Total</font></td></tr>\n";
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
                        $old_col_letter = get_next_field_letter ($old_col_letter); 
                        $row .= "<td id='$old_col_letter$old_row_num'><font size=-3>No group</font></td>\n";
                        $old_col_letter = get_next_field_letter ($old_col_letter); 
                        $row .= "<td id='$old_col_letter$old_row_num'><font size=-3>No group Total</font></td></tr>\n";
                    }
                }
            }
            else
            {
                $old_col_letter = get_next_field_letter ($old_col_letter); 
                $row .= "<td id='$old_col_letter$old_row_num'><font size=-3>No group</font></td>\n";
                $old_col_letter = get_next_field_letter ($old_col_letter); 
                $row .= "<td id='$old_col_letter$old_row_num'><font size=-3>No group Total</font></td></tr>\n";
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
        
        $html_text .= "<script>\n";
        $html_text .= "let currentElem = null;\n";
        $html_text .= "table.onmouseover = function(event) {\n";
        $html_text .= "  if (currentElem) return;\n";
        $html_text .= "  let target = event.target.closest('td');\n";
        $html_text .= "  if (!target) return;\n";
        $html_text .= "  if (!table.contains(target)) return;\n";
        $html_text .= "  currentElem = target;\n";
        $html_text .= "  onEnter(currentElem);\n";
        $html_text .= "};\n";
        $html_text .= "table.onmouseout = function(event) {\n";
        $html_text .= "  if (!currentElem) return;\n";
        $html_text .= "  let relatedTarget = event.relatedTarget;\n";
        $html_text .= "  while (relatedTarget) {\n";
        $html_text .= "    if (relatedTarget == currentElem) return;\n";
        $html_text .= "    relatedTarget = relatedTarget.parentNode;\n";
        $html_text .= "  }\n";
        $html_text .= "  onLeave(currentElem);\n";
        $html_text .= "  currentElem = null;\n";
        $html_text .= "};\n";
        $html_text .= "function fade(element, duration)\n";
        $html_text .= "{\n";
        $html_text .= "    var start = new Date;\n";
        $html_text .= "    (function next() \n";
        $html_text .= "    {\n";
        $html_text .= "        var time = new Date - start;\n";
        $html_text .= "        if (time < duration)\n";
        $html_text .= "        {\n";
        $html_text .= "            element.style.opacity = 1 - time / duration;\n";
        $html_text .= "            requestAnimationFrame(next);\n";
        $html_text .= "        }\n";
        $html_text .= "        else\n";
        $html_text .= "        {\n";
        $html_text .= "            element.style.opacity = '0';\n";
        $html_text .= "        }\n";
        $html_text .= "    }) ();\n";
        $html_text .= "}\n";
        $html_text .= "function onEnter(elem)\n";
        $html_text .= "{\n";
        $html_text .= "    elem.style.background = 'skyblue';\n";
        $html_text .= "    var re = /([A-Z]+\\d+)/g;\n";
        $html_text .= "    var re_range = /([A-Z]+)(\\d+):([A-Z]+)(\\d+)/g\n";
        $html_text .= "    var s = currentElem.innerText;\n";
        $html_text .= "    var col = 'AliceBlue';\n";
        $html_text .= "    m = re_range.exec(s);\n";
        $html_text .= "    if (m)\n";
        $html_text .= "    {\n";
        $html_text .= "        var i = parseInt (m[2]);\n";
        $html_text .= "        var j = parseInt (m[4]);\n";
        $html_text .= "        var w = m[1];\n";
        $html_text .= "        var z = m[3];\n";
        $html_text .= "        while (i <= j)\n";
        $html_text .= "        {\n";
        $html_text .= "            w = m[1];\n";
        $html_text .= "            while (w <= z)\n";
        $html_text .= "            {\n";
        $html_text .= "                if (document.getElementById(w + '' + i) != null)\n";
        $html_text .= "                {\n";
        $html_text .= "                    document.getElementById(w + '' + i).style.background = col;\n";
        $html_text .= "                }\n";
        $html_text .= "                w = String.fromCharCode(w.charCodeAt(0) + 1);\n";
        $html_text .= "            }\n";
        $html_text .= "            i += 1;\n";
        $html_text .= "        }\n";
        $html_text .= "    }\n";
        $html_text .= "    var m;\n";
        $html_text .= "    var col = 'mediumpurple';\n";
        $html_text .= "    do {\n";
        $html_text .= "        m = re.exec(s);\n";
        $html_text .= "        if (m) {\n";
        $html_text .= "            if (document.getElementById(m[0]) != null) {\n";
        $html_text .= "                document.getElementById(m[0]).style.background = col;\n";
        $html_text .= "                console.log(m[0]);\n";
        $html_text .= "            }\n";
        $html_text .= "            if (col == 'mediumpurple') { col = 'bisque'; } \n";
        $html_text .= "            else if (col == 'bisque') { col = 'mediumaquamarine'; } \n";
        $html_text .= "            else if (col == 'mediumaquamarine') { col = 'dodgerblue'; } \n";
        $html_text .= "        }\n";
        $html_text .= "    } while (m);\n";
        $html_text .= "        \n";
        $html_text .= "    fieldID.innerHTML = '<div class=\"field_border\"><span style=\"font-family: Arial; font-size: 11\">' + `\${currentElem.id}` + '</span></div>';\n";
        $html_text .= "    var rect = elem.getBoundingClientRect();\n";
        $html_text .= "    var rect2 = fieldID.getBoundingClientRect();\n";
        $html_text .= "    fieldID.style.position = \"absolute\";\n";
        $html_text .= "    fieldID.style.top = rect.bottom - (rect2.height);\n";
        $html_text .= "    fieldID.style.left = rect.right - (rect2.width);\n";
        $html_text .= "    fade (fieldID, 1500);\n";
        $html_text .= "}\n";
        $html_text .= "function onLeave(elem) \n";
        $html_text .= "{\n";
        $html_text .= "    elem.style.background = '';\n";
        $html_text .= "    var re = /([A-Z]+\\d+)/g;\n";
        $html_text .= "    var re_range = /([A-Z]+)(\\d+):([A-Z]+)(\\d+)/g\n";
        $html_text .= "    var col = 'AliceBlue';\n";
        $html_text .= "    var s = currentElem.innerText;\n";
        $html_text .= "    m = re_range.exec(s);\n";
        $html_text .= "    if (m)\n";
        $html_text .= "    {\n";
        $html_text .= "        var i = parseInt (m[2]);\n";
        $html_text .= "        var j = parseInt (m[4]);\n";
        $html_text .= "        var w = m[1];\n";
        $html_text .= "        var z = m[3];\n";
        $html_text .= "        while (i <= j)\n";
        $html_text .= "        {\n";
        $html_text .= "            w = m[1];\n";
        $html_text .= "            while (w <= z)\n";
        $html_text .= "            {\n";
        $html_text .= "                if (document.getElementById(w + '' + i) != null)\n";
        $html_text .= "                {\n";
        $html_text .= "                    document.getElementById(w + '' + i).style.background = '';\n";
        $html_text .= "                }\n";
        $html_text .= "                w = String.fromCharCode(w.charCodeAt(0) + 1);\n";
        $html_text .= "            }\n";
        $html_text .= "            i += 1;\n";
        $html_text .= "        }\n";
        $html_text .= "    }\n";
        $html_text .= "            console.log(s);\n";
        $html_text .= "    var m;\n";
        $html_text .= "    do {\n";
        $html_text .= "        m = re.exec(s);\n";
        $html_text .= "        if (m) {\n";
        $html_text .= "            if (document.getElementById(m[0]) != null) {\n";
        $html_text .= "                document.getElementById(m[0]).style.background = '';\n";
        $html_text .= "                console.log(m[0]);\n";
        $html_text .= "            }\n";
        $html_text .= "        }\n";
        $html_text .= "    } while (m);\n";
        $html_text .= "    fieldID.innerHTML = '<div class=\"field_border\"><span style=\"font-family: Arial; font-size: 11\">' + `\${currentElem.id}` + '</span></div>';\n";
        $html_text .= "    var rect = elem.getBoundingClientRect();\n";
        $html_text .= "    var rect2 = fieldID.getBoundingClientRect();\n";
        $html_text .= "    fieldID.style.position = \"absolute\";\n";
        $html_text .= "    fieldID.style.top = rect.bottom - (rect2.height);\n";
        $html_text .= "    fieldID.style.left = rect.right - (rect2.width);\n";
        $html_text .= "}\n";
        $html_text .= "</script>\n";
        $html_text .= "</body>\n";
        $html_text .= "</html>\n";

        write_to_socket (\*CLIENT, $html_text, "", "noredirect");
        $have_to_write_to_socket = 0;
        print ("============================================================\n");
    }
}
