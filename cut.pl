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

# Main
{
    if (scalar (@ARGV) == 0 || (scalar (@ARGV) > 2 && scalar (@ARGV) < 4))
    {
        print ("Usage: cut.pl <file> <term> <helper> <operation>!\n");
        print (" .   File can be - list, STDIN, or an actual file\n");
        print (" .   Term can be - a regex you're looking for\n");
        print (" .   Operation can be - grep, filegrep, count, size, strip_http, matrix_flip(for converting ringing touches!), oneupcount, allupcount, oneup, wget\n");
        print (" .   Helper is dependent on the operation you're doing.  A number for grep will go +/- that amount \n");
        print ("   cut.pl bob.txt dave 5 grep\n");
        print ("   cut.pl all_java2.java TOKEN_STARTS_HERE TOKEN_ENDS_HERE grep_between\n");
        print ("   cut.pl full_text.txt keys 0 filegrep\n");
        print ("   cut.pl pbm_72.txt 0 0 ringing\n");
        print ("   dir /a:-d /b /s | find /I \"epub\" | cut.pl stdin 0 0 make_cp_bat\n");
        print ("   dir /a:-d /b /s | find /I /V \".git\" | cut.pl stdin 0 0 nobinary | cut.pl stdin 0  0 make_code_bat > bob.bat\n");
        print ("   dir /a:-d /b /s | cut.pl stdin 0 0 nobinary | cut.pl stdin 0  0 make_code_bat > bob.bat\n");
        print ("   dir /a:-d /b /s | cut.pl stdin 0 0 nobinary | cut.pl stdin 0  0 size | sort\n");
        print ("   dir /a:-d /b /s | cut.pl stdin 0  0 size | sort\n");
        print ("   cut.pl git_diff 0  0 sortn\n");
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
        print ("   cut.pl stdin \";;;\" \"1,2,3,4\" fields\n");
        print ("   cut.pl bob.txt 0 0 matrix_flip\n");
        print ("   cut.pl all_java14.java \"Penny Dreadful\" \"c:\\\\xmage\" egrep | cut.pl stdin \"Penny\" -1 grep\n");
        print ("   cut.pl all_xml10.xml \"Penny\" \"c:\\\\xmage\" egrep | cut.pl stdin \"Penny\" -1 grep\n");
        print ("   cut.pl bob.txt 0 0 condense   (Used for making similar lines in files smaller..)\n");
        print ("   cut.pl bob.txt 0 0 str_condense   (Used for making similar lines in files smaller..)\n");
        print ("   cut.pl stdin \"http://bob.com/a=XXX.id\" 1000 oneupcount   \n");
        print ("   cut.pl stdin \"XXX, YYY, ZZZ\" \"255,0,10,25\" allupcount   \n");
        print ("   type xyz.txt | cut.pl stdin '' 1000 oneup\n");
        print ("   cut.pl stdin \"http://bob.com/a=XXX.id\" 1000 oneupbinary   \n");
        print ("   cut.pl stdin \"http://www.comlaw.gov.au/Details/XXX\" 1000 wget\n");
        print ("   cut.pl stdin \"http://gatherer.wizards.com/Pages/Card/Details.aspx?multiverseid=XXX\"  5274 oneupcount\n");
        print ("   cut.pl stdin \"http://gatherer.wizards.com/Pages/Card/Details.aspx?multiverseid=XXX'  5274 wget\n");
        print ("   cut.pl  modern_bluesa \";;;\" \"0,7\" fields | cut.pl stdin \";;;\" 3 wordcombos\n");
        print ("   cut.pl  modern_bluesa \";;;\" \"0,7\" fields | cut.pl stdin 0 0 uniquewords\n");
        print ("   cut.pl  modern_bluesa \";;;\" \"0,2\" images_html\n");
        print ("   cut.pl d:/D_Downloads/ip_info.html 0 0 one_url_per_line\n");
        print ("   cut.pl  stdin start_ _end letters\n");
        print ("   cut.pl  file banner hashmod word2word\n");
        print ("   cut.pl all_java21.java  thing_to_search xxxxxx egrep | cut.pl stdin thing_to_search -1 grep    rem for search_in_output..\n");
        print ("   cut.pl all_java.java  \"thing_to_search\" 0 search_in_output\n");
        print ("   echo \"1\" | cut.pl stdin 0 0 sinewave\n");
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
        exit 0;
    }

    my $file;
    my $term;
    my $helper;
    my $operation;
    my %json_headers;
    my $last_line;
    
    my $ot_ringing;
    my $tf_ringing;
    my $fs_ringing;
    my $se_ringing;
    my $nt_ringing;

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
            open PROC, "cut.pl $file $term $helper $operation |";
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
            $l =~ s/XXX/$i/;
            print ("$l\n");
        }
        exit;
    }
    
    if ($operation eq "allupcount")
    {
        my $i = 0;
        my $num_to_do = 0;
        my $start_x = "aa";
        my $start_y = "aa";
        my $start_z = "aa";

        if ($helper =~ m/^(\d+),(\d+),(\d+)/)
        {
            $num_to_do = $1;
            $start_x = $2;
        }

        if ($helper =~ m/^(\d+),(\d+),(\d+)/)
        {
            $num_to_do = $1;
            $start_x = $2;
            $start_y = $3;
        }

        if ($helper =~ m/^(\d+),(\d+),(\d+),(\d+)/)
        {
            $num_to_do = $1;
            $start_x = $2;
            $start_y = $3;
            $start_z = $4;
        }

        for ($i = 0; $i < $helper; $i ++)
        {
            my $l = $term;
            if ($start_x ne "aa")
            {
                $l =~ s/XXX/$start_x/;
                $start_x++;
            }
            if ($start_y ne "aa")
            {
                $l =~ s/YYY/$start_y/;
                $start_y++;
            }
            if ($start_z ne "aa")
            {
                $l =~ s/ZZZ/$start_z/;
                $start_z++;
            }
            print ("$l\n");
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
    if ($operation eq "make_code_bat")
    {
        print ("\@echo off\n");
    }
    



    my %ulines;
    my $ulines_count = 0;
    my $oneup = 0;
    my @cut_on_term;
    my $saw_helper_cut_on_term = 0;
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

                print $url, "\n\n\n\n\n", "=================\n", $content, "============\n";
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

        if ($operation eq "sinewave")
        {
            my $x = 40;
            my $y = 40;
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
        
        if ($operation eq "sortn")
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

            if ($line =~ m/\.(ap_|mp3|bmp|db|dll|lnk|star|class|dat|exe|vlw|json|js|map|gif|gz|ico|index|jar|jpg|pack|pdf|png|swp|swo|tab|ttf|7z|zip|dex|apk|bin|war|net|tsv|log|ai|Help|md|vs|gs|fs|mf)$/img)
            {
                next;
            }
            if ($line !~ m/\.(ap_|mp3|bmp|db|dll|lnk|star|class|dat|exe|vlw|json|js|map|gif|gz|ico|index|jar|jpg|pack|pdf|png|swp|swo|tab|ttf|7z|zip|dex|apk|bin|war)$/img) 
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
            if ($line =~ m/(Jan(uary|)|Feb(ruary|)|Mar(ch|)|Apr(il|)|May|Jun(e|)|Jul(y|)|Aug(ust|)|Sep(tember|t|)|Oct(ober|)|Nov(ember|)|Dec(ember|)) *(\d{1,2}),{0,1} *(\d{2,4})/im)
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
                $line =~ s/(Jan(uary|)|Feb(ruary|)|Mar(ch|)|Apr(il|)|May|Jun(e|)|Jul(y|)|Aug(ust|)|Sep(tember|t|)|Oct(ober|)|Nov(ember|)|Dec(ember|)) *(\d{1,2}),{0,1} *(\d{2,4})/$yyyymmdd/im;
            }

            if ($line =~ m/\d{1,2} (Jan(uary|)|Feb(ruary|)|Mar(ch|)|Apr(il|)|May|Jun(e|)|Jul(y|)|Aug(ust|)|Sep(tember|t|)|Oct(ober|)|Nov(ember|)|Dec(ember|)) \d{2,4}/im)
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
                $line =~ s/\d{1,2} (Jan(uary|)|Feb(ruary|)|Mar(ch|)|Apr(il|)|May|Jun(e|)|Jul(y|)|Aug(ust|)|Sep(tember|t|)|Oct(ober|)|Nov(ember|)|Dec(ember|)) \d{2,4}/$yyyymmdd/im;
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
        foreach $key (sort keys (%transpose_chars)) 
        {
            print ("$key $transpose_chars{$key},");
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
        foreach $line (sort { $ulines{$a} <=> $ulines{$b} } keys %ulines)
        {
            print  ("$ulines{$line} ==== $line\n");
        }
        print  ("$ulines_count\n");
    }
    
    if ($operation eq "sortn")
    {
        my $line;
        foreach $line (sort {$a <=> $b} keys %ulines)
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
