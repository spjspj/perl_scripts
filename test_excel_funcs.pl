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

sub simple_parentheses_only_one_argument 
{
    my $field_val = $_ [0];
    my $func = $_ [1];
    if ($field_val =~ m/^$func\([^(\|]+\)/)
    {
        print ("Checked s1a ($field_val) and ok\n");
        return 1;
    }
    print ("Checked s1a ($field_val) and NOT ok\n");
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
        print ("Checked s3a for $field_val and ok\n");
        return 1;
    }
    print ("Checked s3a for $field_val and NOT ok\n");
    return 0;
}

sub simple_parentheses_many_arguments
{
    my $field_val = $_ [0];
    my $func = $_ [1];
    if ($field_val =~ m/^$func\(([^(\|]+\|){3,10}[^(\|]+\)/)
    {
        print ("Checked sMa for $field_val and ok\n");
        return 1;
    }
    print ("Checked sMa for $field_val and NOT ok\n");
    return 0;
}

my $count = 0;
my %each_element;
my $each_element_count = 0;

sub breakdown_excel
{
    my $excel_function = $_ [0];
    my $iteration = $_ [1];

    if ($iteration == 0)
    {
        $each_element_count = 0;
        my %new_each_element;
        %each_element = %new_each_element;
        print ("\n\n\nNEW_BREAKDOWN >>>>>>>>>=================$excel_function\n");
    }
    if ($iteration > 50)
    {
        print ("\n\n\n FAILED BREAKDOWN ($iteration) >>>>>>>>>=================$excel_function\n");
        return;
    }
    my $i = 0;
    while ($excel_function =~ s/("[^"]*")/xXSTRING$each_element_count/) 
    {
        $each_element {"xXSTRING$each_element_count"} = "$1<< xXSTRING$each_element_count";
        print (" >> Breakdown xXSTRING$each_element_count to >$1<\n");
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
        if (simple_parentheses_only_one_argument ($test, $func)) 
        {
            $excel_function =~ s/($func\([^\)]*\))/xXONE$each_element_count/; 
            $each_element {"xXONE$each_element_count"} = $1 . "<< xXONE$each_element_count";
            print (" >> Breakdown xXONE$each_element_count to >$1<\n");
            $each_element_count++;
            print (" Found 1sa func of $1 (Now $excel_function)\n");
        }
        elsif (simple_parentheses_only_two_arguments ($test, $func)) 
        {
            $excel_function =~ s/($func\([^\|\)]*\|.*?\))/xXTWO$each_element_count/; 
            $each_element {"xXTWO$each_element_count"} = $1 . "<< xXTWO$each_element_count";
            print (" >> Breakdown xXTWO$each_element_count to >$1<\n");
            $each_element_count++;
            print (" Found 2sa func of $1 (Now $excel_function)\n");
        }
        elsif (simple_parentheses_only_three_arguments ($test, $func)) 
        {
            $excel_function =~ s/($func\([^\|\)]*\|[^\|\)]*\|.*?\))/xXTHREE$each_element_count/; 
            $each_element {"xXTHREE$each_element_count"} = $1 . "<< xXTHREE$each_element_count";
            print (" >> Breakdown xXTHREE$each_element_count to >$1<\n");
            $each_element_count++;
            print (" Found 3sa func of $1 (Now $excel_function)\n");
        }
        elsif (simple_parentheses_many_arguments($test, $func)) 
        {
            $excel_function =~ s/($func\([^\|\)]*\|[^\|\)]*\|.*?\))/xXMANY$each_element_count/; 
            $each_element {"xXMANY$each_element_count"} = $1 . "<< xXMANY$each_element_count";
            print (" >> Breakdown xXMANY$each_element_count to >$1<\n");
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
        return breakdown_excel ($excel_function, $iteration + 1);
    }
    $excel_function =~ s/^=//;
    print ("\nSUCCESS -- Finally -- >$excel_function<\n");
    $each_element {"ZZMAX"} = $excel_function;
    return $excel_function;
}

sub recreate_excel
{
    my $str;
    my $k;
    foreach $k (sort keys (%each_element))
    {
        my $str = $each_element {$k}; 
        print (" >>> $str\n");
        $str =~ s/<< .*//;
        while ($str =~ m/(xX[A-Z]+\d+)/)
        {
            my $k2 = $1;
            my $str2 = $each_element{$k2};
            $str2 =~ s/<< .*//;
            $str =~ s/$k2/$str2/; 
        }
        $each_element {$k} = $str; 
        print "Done: $k -- $str\n";
    }
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
                print ("    concat 11: $field_val\n");
                $field_val =~ s/CONCATENATE\(([^\|]+?)\|([^\|]+?)\)/"$1" . "$2"/;
                $field_val =~ s/""/"/g;
                $field_val =~ s/""/"/g;
            }
            elsif ($field_val =~ m/CONCATENATE\(\s*\|([^\|]+?)\)/)
            {
                print ("    concat 01: $field_val\n");
                $field_val =~ s/CONCATENATE\(\s*\|([^\|]+?)\)/"$1"/;
                $field_val =~ s/""/"/g;
                $field_val =~ s/""/"/g;
            }
            elsif ($field_val =~ m/CONCATENATE\(([^\|]+?)\|\s*\)/)
            {
                print ("    concat 10: $field_val\n");
                $field_val =~ s/CONCATENATE\(([^\|]+?)\|\s*\)/"$1"/;
                $field_val =~ s/""/"/g;
                $field_val =~ s/""/"/g;
            }
            elsif ($field_val =~ m/CONCATENATE\(\s*\|\s*\)/)
            {
                print ("    concat 00: $field_val\n");
                $field_val =~ s/CONCATENATE\(\s*\|\s*\)//;
                $field_val =~ s/""/"/g;
                $field_val =~ s/""/"/g;
            }
            print ("    concat fail: $field_val\n");
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

sub do_mod_expansion
{
    my $field_val = $_ [0];
    if ($field_val =~ m/((MOD)\(.*)/)
    {
        my $to_check = $1;
        my $func = $2;
        if (simple_parentheses_only_two_arguments ($to_check, "$func"))
        {
            $field_val =~ s/$func\((.+)\|(.+)\)/($1)%($2)/;
            return $field_val; 
        }
    }
    return $field_val; 
}

sub do_max_expansion
{
    my $field_val = $_ [0];
    if ($field_val =~ m/((MAX)\(.*)/)
    {
        my $to_check = $1;
        my $func = $2;
        if (simple_parentheses_only_two_arguments ($to_check, "$func"))
        {
            $field_val =~ s/$func\((.+)\|(.+)\)/($1 > $2 ? $1 | $2)/;
            return $field_val; 
        }
    }
    return $field_val; 
}

sub do_min_expansion
{
    my $field_val = $_ [0];
    if ($field_val =~ m/((MAX)\(.*)/)
    {
        my $to_check = $1;
        my $func = $2;
        if (simple_parentheses_only_two_arguments ($to_check, "$func"))
        {
            $field_val =~ s/$func\((.+)\|(.+)\)/($1 <= $2 ? $1 | $2)/;
            return $field_val; 
        }
    }
    return $field_val; 
}

sub do_left_expansion
{
    my $field_val = $_ [0];
    if ($field_val =~ m/((LEFT)\(.*)/)
    {
        my $to_check = $1;
        my $func = $2;
        if (simple_parentheses_only_two_arguments ($to_check, "$func"))
        {
            $field_val =~ s/$func\((.+)\|(.+)\)/substr ($1, 0, $2)/;
            return $field_val; 
        }
    }
    return $field_val; 
}

sub do_right_expansion
{
    my $field_val = $_ [0];
    if ($field_val =~ m/((LEFT)\(.*)/)
    {
        my $to_check = $1;
        my $func = $2;
        if (simple_parentheses_only_two_arguments ($to_check, "$func"))
        {
            $field_val =~ s/$func\((.+)\|(.+)\)/substr ($1, $2)/;
            return $field_val; 
        }
    }
    return $field_val; 
}

sub do_textjoin_expansion
{
    my $field_val = $_ [0];
    my $orig_field_val = $_ [0];
    if ($field_val =~ m/((TEXTJOIN)\(.*)/)
    {
        my $to_check = $1;
        my $func = $2;
        if (simple_parentheses_only_three_arguments ($to_check, "$func"))
        {
            $field_val =~ m/$func\(([^|]+)\|([^|]*?)\|([^|]*?)\)/;
            my $delimiter = $1;
            my $cond = $2;
            my $text = $3;
            if ($cond eq "TRUE")
            {
                $field_val =~ s/$func\(([^|]+)\|([^|]*?)\|([^|]*?)\)/"$3"/g;
            }
            print ("\n MY text_join was >>$field_val<< from ($orig_field_val)");
            return $field_val; 
        }
        if (simple_parentheses_many_arguments ($to_check, "$func"))
        {
            my $new_str = "\"\"";
            $field_val =~ s/$func\(([^|]+)\|([^|]*?)\|//;
            my $delimiter = $1;
            my $cond = $2;
            while ($field_val =~ s/^([^\(\|]+)\|//)
            {
                my $text = $1;
                $new_str = "$new_str . $delimiter . $text";
            }
            if ($field_val =~ s/^([^\(\|]+)\)//)
            {
                my $text = $1;
                $new_str = "$new_str . $delimiter . $text";
            }
            $new_str = "($new_str)";
            print ("\n MY text_join was >>$new_str<< from ($orig_field_val)");
        }
    }
    return $field_val; 
}

sub do_len_expansion 
{
    my $field_val = $_ [0];
    if ($field_val =~ m/((LEN)\(.*)/)
    {
        my $to_check = $1;
        my $func = $2;
        if (simple_parentheses_only_one_argument ($to_check, "$func"))
        {
            $field_val =~ s/$func\((.+)\)/length($1)/;
            return $field_val; 
        }
    }
    return $field_val; 
}

sub do_if_expansion
{
    my $field_val = $_ [0];
    if ($field_val =~ m/((IF)\(.*)/)
    {
        my $to_check = $1;
        print ("IF CONDITION do_if_expansion starting on >>$field_val<< start\n");
        #if (simple_parentheses_only_three_arguments ($to_check, "IF"))
        {
            $field_val =~ m/IF\(([^|]+)\|([^|]*?)\|([^|]*?)\)/;
            my $condition = $1;
            my $true_bit = $2;
            my $false_bit = $3;
            $condition =~ s/([^=]+)=([^=]+)/$1==$2/g;
            $field_val =~ s/IF\(([^|]+)\|([^|]*?)\|([^|]*?)\)/($condition ? $true_bit : $false_bit)/;
        }
    }
    print ("IF DONE CONDITION do_if_expansion finished with >>$field_val<<\n");
    return $field_val; 
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

sub is_number
{
    my $field = $_ [0];
    return ($field =~ m/^\d+($|\.\d+)$/ || $field =~ m/^-\d+($|\.\d+)$/ || $field =~ m/^\+\d+($|\.\d+)$/)
}

sub get_field_value
{
    my $row_num = $_ [0];
    my $col_letter = $_ [1];
    my $for_display = $_ [2];
    if ($col_letter eq "A")
    {
        return $row_num;
    }
    if ($col_letter eq "B")
    {
        return "$row_num.25";
    }
    return "zzz";
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

sub fix_up_field_vals
{
    my $s = $_ [0];
    $s =~ s/A(\d+)/$1/img;
    $s =~ s/B(\d+)/15.$1/img;
    $s =~ s/C(\d+)/0.$1/img;
    $s =~ s/([D-Z])(\d+)/ZZZ/img;
    return $s;
}

sub perl_expansions
{
    my $str = $_ [0];
    print ("\nMY PERL EXPANSION for $str was ... ");

    if ($str =~ m/SUM\(/)
    {
        $str = do_sum_expansion ($str);
    }
    if ($str =~ m/CONCATENATE\(/)
    {
        $str = do_concat_expansion ($str);
    }
    if ($str =~ m/POWER\(/)
    {
        $str = do_power_expansion ($str);
    }
    if ($str =~ m/MOD\(/)
    {
        $str = do_mod_expansion ($str);
    }
    if ($str =~ m/MAX\(/)
    {
        $str = do_max_expansion ($str);
    }
    if ($str =~ m/MIN\(/)
    {
        $str = do_min_expansion ($str);
    }
    if ($str =~ m/LEFT\(/)
    {
        $str = do_left_expansion ($str);
    }
    if ($str =~ m/RIGHT\(/)
    {
        $str = do_right_expansion ($str);
    }
    if ($str =~ m/TEXTJOIN\(/)
    {
        print (" !! TEXTJOIN !! ($str) doing ... ");
        $str = do_textjoin_expansion ($str);
    }
    if ($str =~ m/IF\(/)
    {
        $str = do_if_expansion ($str);
    }
    
    # General cleanup..
    $str =~ s/"xXSTRING(\d+)"/xXSTRING$1/img;
    print ("$str\n");
    return $str;
}

sub recreate_perl
{
    my $str;
    my $k;
    print (" MAKING PERL FUNC:\n");
    foreach $k (sort keys (%each_element))
    {
        my $str = $each_element {$k}; 
        print (" $k >> STARTED WITH >$str< (for $k)\n");
        $str = perl_expansions ($str);
        $each_element {$k} = $str; 
        print (" $k >> FINISHED ON >$str< (for $k)\n");
    }

    foreach $k (sort keys (%each_element))
    {
        my $str = $each_element {$k}; 
        print (" $k >> 22STARTED WITH >$str< (for $k)\n");
        $str =~ s/<< .*//;
        while ($str =~ m/(xX[A-Z]+\d+)/)
        {
            my $k2 = $1;
            my $str2 = $each_element{$k2};
            $str2 =~ s/<< .*//;
            $str =~ s/$k2/$str2/; 
            print ("     .. modding Perl replace >$k2< for >$str2<\n");
            print ("   modded Perl >>> $str (for $k)\n");
        }
        print ("   done modding Perl >>> $str (for $k)\n");
        print (" $k >> 22FINISHED ON >$str< (for $k)\n");

        $str = perl_expansions ($str);
        print (" $k >> 33FINISHED ON >$str< (for $k)\n");

        $str = fix_up_field_vals ($str);
        print (" 44FINISHED ON >$str< (for $k)\n");
        $each_element {$k} = $str; 
        my $xx;

        # Print a value into a variable as read from STDOUT that eval prints out
        my $output;
        open (my $outputFH, '>', \$output) or die;
        my $oldFH = select $outputFH;
        eval ("print ($str);");
        select $oldFH;
        close $outputFH;

        if ($k =~ m/xXSTRING/)
        {
            $output = $str;
        }
  
        print "INTERIM OUTPUT ($k) FROM PERL was >>$output<<  from evaluating >$str<)!\n";
        if ($k eq "ZZMAX")
        {
            print "FINAL OUTPUT FROM PERL was >>$output<<  from evaluating >$str<)!\n";
        }
        #$each_element {$k} = $output;
    }
}

my $count = 0;
my $each_element_count = 0;
my %new_each_element;
my %each_element = %new_each_element;

$count = 0; breakdown_excel ("=IF(MOD(A3|100)=1|\"JANUARY\"|IF(MOD(A3|100)=2|\"FEB\"|\"HHHH\"))", 0); recreate_perl ();
$count = 0; breakdown_excel ("=SUM(A1:B12)", 0); recreate_perl ();
$count = 0; breakdown_excel ("=A2+A3+A4"); recreate_perl ();
$count = 0; breakdown_excel ("=IF(A8+0.31/2>10|\"BBB\"|CONCATENATE(C8|\"A\"))"); recreate_perl ();
$count = 0; breakdown_excel ("=IF(A8+0.31/2>10|\"BBB\"|CONCATENATE(C8|\"B\"))"); recreate_perl ();
$count = 0; breakdown_excel ("=IF(A8+0.31/2>10|10|A8+0.31/2)"); recreate_perl ();
$count = 0; breakdown_excel ("=IF(MOD(A8|100)=1|\"JANUARY\"| IF(MOD(A8|100)=2|\"FEB\"| IF(MOD(A8|100)=3|\"MAR\"| IF(MOD(A8|100)=4|\"APR\"| IF(MOD(A8|100)=5|\"MAY\"| IF(MOD(A8|100)=6|\"JUN\"| IF(MOD(A8|100)=7|\"JUL\"| IF(MOD(A8|100)=8|\"AUG\"| IF(MOD(A8|100)=9|\"SEP\"| IF(MOD(A8|100)=10|\"OCT\"| IF(MOD(A8|100)=11|\"NOV\"| IF(MOD(A8|100)=12|\"DEC\"|\"HHHH\"))))))))))))"); recreate_perl ();

#$count = 0; breakdown_excel ("=POWER(SUM(A8:B8)|SUM(A1:B8))"); recreate_perl ();
#$count = 0; breakdown_excel ("=SUM(A4:B11)"); recreate_perl ();
#$count = 0; breakdown_excel ("=IF(MaxProjectionMonths>COLUMN(D7)-COLUMN(B7)|DATE(YEAR(D7)|MONTH(D7)+1|DAY(D7))|\"\")", 0); recreate_perl ();
#$count = 0; breakdown_excel ("=IF(OR(B12=\"\"|LEFT(B12|3)=A12|Q7=\"\")|\"\"|IF(TRIM(B12)=\"Starting balance\"|IF(Q7=ProjectionStart|VLOOKUP(D12|IF(C12=\"Assets\"|Assets|Liabilities)|4|FALSE)|P18)|IF(TRIM(B12)=\"Revenues\"|SUMIF(_ProjRevenues!C4:C53|A12|_ProjRevenues!S4:S53)|IF(TRIM(B12)=\"Expenses\"|SUMIF(_ProjExpenses!C4:C53|A12|_ProjExpenses!S4:S53)|IF(TRIM(B12)=\"Transfers In\"|SUMIF(_ProjTransfers!D4:D53|A12|_ProjTransfers!V4:V53)|IF(TRIM(B12)=\"Transfers Out\"|-1*SUMIF(_ProjTransfers!C4:C53|A12|_ProjTransfers!V4:V53)|IF(TRIM(B12)=\"Interest\"|(IF(Q6=\"\"|0|Q6)+InterestProportion*(Q7+Q8+Q9+Q11))*((1+VLOOKUP(D12|IF(C12=\"Assets\"|Assets|Liabilities)|5|FALSE))^(1/12)-1)|IF(TRIM(B12)=\"Ending balance\"|SUM(Q5:Q11)|\"undefined\"))))))))", 0); recreate_perl ();
#$count = 0; breakdown_excel ("=LET(myName|[\@Name]|TEXTJOIN(\" \"|TRUE|RIGHT(myName|LEN(myName)-FIND(\"| \"|myName)-1)|LEFT(myName|FIND(\"| \"|myName)-1)))"); recreate_perl ();

#CHAR
#COLUMN
#DATE
#DAY
#FIND
#IF done
#LEFT
#LEN done
#LET
#MAX done
#MIN done
#MOD done
#MONTH
#OR
#RIGHT
#SUM done
#SUMIF
#TEXT
#TEXTJOIN
#TRIM
#VLOOKUP
#YEAR
