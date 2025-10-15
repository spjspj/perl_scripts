#!/usr/bin/perl
##
#   File : extract_text_for_checkbox.pl
#   Date : 11/October/2025
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
my $CHECKBOX = 4;
my $CHECKBOX_STR = "checkbox";
my $CHECKBOX_SIZE = 14;
my $TEXTBOX = 8;
my $TEXTBOX_STR = "textbox";
my $TEXTBOX_WIDTH = 50;
my $EXTEND_SIZE = 50;
my $BOLD_EXTEND_SIZE = 150;
my $MAX_DIST_FOR_WORDS = 20;
my $DO_DEBUG = 0;
my $BOLD_FONT_PT = 12;
my $PAGES_LIMIT = 4;
my $COARSENESS = 20;

my $msword_file;
my $msword_locations;
my %word_locations;
my %word_locations_used;
my %word_locations_used_by;
my %word_locations_page;
my %word_locations_x;
my %word_locations_y;
my %word_locations_style;
my %word_locations_closest_to_box;
my %box_locations;
my %box_locations_page;
my %box_locations_x;
my %box_locations_y;
my %box_locations_xy;
my %box_locations_type;
my %box_key_words_overall;
my %box_key_words_closest;
my %box_key_words_left;
my %box_key_words_right;
my %box_key_words_top;

my %closest_box_to_word;
my %closest_word_to_box;
my %closest_word_to_word;

sub get_abs
{
    my $v = $_ [0];
    if ($v < 0)
    {
        return -1 * $v;
    }
    return $v;
}

# Get box dimensions
sub get_box_dimensions
{
    my $bl = $_ [0];
    my $box_left;
    my $box_right;
    my $box_bottom;
    my $box_top;
    my $box_type = $box_locations_type {$bl};

    $box_left = $box_locations_x {$bl};
    $box_bottom = $box_locations_y {$bl};
    $box_top = $box_bottom + $CHECKBOX_SIZE;
    $box_right = $box_left + $TEXTBOX_WIDTH;
    if ($box_type == $CHECKBOX)
    {
        $box_right = $box_left + $CHECKBOX_SIZE;
    }

    return ($box_left, $box_right, $box_bottom, $box_top);
}

sub get_actual_word
{
    return $word_locations {$_[0]};
}

# Get word dimensions
sub get_word_dimensions
{
    my $wl = $_ [0];
    my $word_left;
    my $word_right;
    my $word_bottom;
    my $word_top;

    $word_left = $word_locations_x {$wl};
    $word_bottom = $word_locations_y {$wl};
    $word_top = $word_bottom - $CHECKBOX_SIZE; # TODO - work out heights blergh
    my $length_word = calculate_size ($wl);
    $word_right = $word_left + $length_word;

    return ($word_left, $word_right, $word_bottom, $word_top);
}

# Get closest box..
sub get_closest_box
{
    my $wl = $_ [0];
    
    my $word_left;
    my $word_right;
    my $word_bottom;
    my $word_top;
    ($word_left, $word_right, $word_bottom, $word_top) = get_word_dimensions ($wl);


    my $word_page = $word_locations_page {$wl};
    my $min_distance = 1000000;
    my $box_left;
    my $box_right;
    my $box_bottom;
    my $box_top;
    my $box_page;
    my $closest_box = "NOTABOX";
    my $bl;
    my $dist;

    foreach $bl (sort keys (%box_locations))
    {
        $box_page = $box_locations_page {$bl};

        if ($word_page == $box_page && $word_page < $PAGES_LIMIT)
        {
            ($box_left, $box_right, $box_bottom, $box_top) = get_box_dimensions ($bl);
            my $diff_x = $box_left - $word_left;
            my $diff_y = $box_bottom - $word_bottom;

            $dist = sqrt ($diff_x * $diff_x + $diff_y * $diff_y);
            if ($dist < $min_distance)
            {
                $min_distance = $dist;
                $closest_box = $bl;
            }
        }
    }
    $closest_box_to_word {$wl} = $closest_box;
    return $closest_box;
}

# Get closest word to a given box..
sub get_closest_word_to_box
{
    my $bl = $_ [0];
    my $try_harder = $_ [1];
    my $min_distance = 1000000;
    my $box_left;
    my $box_right;
    my $box_bottom;
    my $box_top;
    my $word_left;
    my $word_right;
    my $word_bottom;
    my $word_top;
    my $closest_word = -1;
    my $dist;
    my $wl;
    my $box_page = $box_locations_page {$bl};
    ($box_left, $box_right, $box_bottom, $box_top) = get_box_dimensions ($bl);
    #print "$try_harder ($box_left, $box_right, $box_bottom, $box_top) -- >>$box_page, $bl<<\n";

    foreach $wl (sort keys (%word_locations))
    {
        my $word_page = $word_locations_page {$wl};
        ($word_left, $word_right, $word_bottom, $word_top) = get_word_dimensions ($wl);

        if ($word_page == $box_page && $word_page < $PAGES_LIMIT)
        {
            my $diff_x = $box_left - $word_left;
            my $diff_y = $box_bottom - $word_bottom;

            $dist = sqrt ($diff_x * $diff_x + $diff_y * $diff_y);
            if ($dist < $min_distance && ((!$try_harder && $word_bottom == $box_bottom) || $try_harder))
            {
                $min_distance = $dist;
                $closest_word = $wl;
            }
        }
    }

    if ($closest_word > -1)
    {
        $word_locations_closest_to_box {$closest_word} = $bl;
        $closest_word_to_box {$bl} = $closest_word;
        if ($DO_DEBUG)
        {
            print (" $box_page :: closest_word_to_box - box=$bl, word=($wl, $closest_word - " . get_actual_word ($closest_word) . "), $min_distance\n");
        }
    }
    elsif ($try_harder == 0)
    {
        # Try harder..
        if ($DO_DEBUG)
        {
            print (" (trying harder) $box_page :: closest_word_to_box - box=$bl, word=($wl, $closest_word - " . get_actual_word ($closest_word) . "), $min_distance\n");
        }
        get_closest_word_to_box ($bl, $try_harder+1);
    }
}

my %styles_sizes_per_character;
my %styles_sizes_per_character_seen;
my %styles_sizes_per_character_total;
sub set_multiples_for_style
{
    my $index = 1;

    while (defined ($word_locations {$index}) && defined ($word_locations {$index+1}))
    {
        my $y = $word_locations_y {$index};
        my $y2 = $word_locations_y {$index+1};

        if ($y == $y2)
        {
            my $style = $word_locations_style {$index};
            my $style2 = $word_locations_style {$index+1};

            if ($style eq $style2)
            {
                my $x = $word_locations_x {$index};
                my $x2 = $word_locations_x {$index+1};

                my $diff = get_abs ($x2 - $x);
                my $l = length (get_actual_word ($index));
                my $avg_per_char = $diff / $l;
                $styles_sizes_per_character_seen {$style} ++;
                $styles_sizes_per_character_total {$style} += $avg_per_char;
            }
        }
        $index++;
    }

    my $s;
    foreach $s (keys %styles_sizes_per_character_seen)
    {
        $styles_sizes_per_character {$s} = $styles_sizes_per_character_total {$s} / $styles_sizes_per_character_seen {$s};
        if ($DO_DEBUG)
        {
            print ("$s - $styles_sizes_per_character{$s}\n");
        }
    }
}

sub calculate_size
{
    my $wl = $_ [0];

    my $text = get_actual_word ($wl);
    my $l = length ($text);
    my $style = $word_locations_style {$wl};

    if (defined ($styles_sizes_per_character {$style}))
    {
        return $styles_sizes_per_character {$style} * $l;
    }
    return 9 * $l;
}

sub is_bold_style
{
    my $wl = $_ [0];
    my $style = $word_locations_style {$wl};

    if ($style =~ m/bold/img || $style =~ m/heading/img || $style =~ m/Italic/img || $style =~ m/Underlined/img)
    {
        return 1;
    }

    my $size = 0;
    if ($style =~ m/(\d+)pt/i)
    {
        $size = $1;
        if ($size > $BOLD_FONT_PT)
        {
            return 1;
        }
    }
    return 0;
}

# Set closest words to boxes..
sub set_closest_words_to_boxes
{
    my $bl;
    foreach $bl (sort { $a <=> $b } keys (%box_locations))
    {
        get_closest_word_to_box ($bl, 0);
    }
}

# Set closest words..
sub set_closest_words
{
    my $page = $_ [0];
    my $wl;
    my $wl2;
    my $min_distance = 1000000;
    my $closest_word = "XXXXXX";
    my $dist;
    my $word_page;
    my $word_page2;

    my $word_left;
    my $word_right;
    my $word_bottom;
    my $word_top;
    my $word_left2;
    my $word_right2;
    my $word_bottom2;
    my $word_top2;

    foreach $wl (sort keys (%word_locations))
    {
        $min_distance = 1000000;
        ($word_left, $word_right, $word_bottom, $word_top) = get_word_dimensions ($wl);
        $word_page = $word_locations_page {$wl};

        if ($word_page != $page)
        {
            next;
        }

        #if (defined ($closest_word_to_word {$wl}))
        #{
        #    next;
        #}

        foreach $wl2 (sort keys (%word_locations))
        {
            if ($wl2 < $wl) { next; }
            $word_page2 = $word_locations_page {$wl2};
            if ($word_page2 != $word_page)
            {
                next;
            }
            ($word_left2, $word_right2, $word_bottom2, $word_top2) = get_word_dimensions ($wl2);

            my $diff_x = $word_left - $word_left2;
            my $diff_y = $word_bottom - $word_bottom2;

            if ($diff_y == 0)
            {
                $dist = sqrt ($diff_x * $diff_x + $diff_y * $diff_y);
                if ($dist > 0 && $dist < $min_distance && $wl2 > $wl)
                {
                    $closest_word = $wl2;
                    $min_distance = $dist;
                }
            }
        }

        my $length_word = calculate_size ($wl);
        if ($min_distance < $MAX_DIST_FOR_WORDS + $length_word)
        {
            $closest_word_to_word {$wl} = $closest_word;
            if ($DO_DEBUG)
            {
                print ("scw ($min_distance) " . get_actual_word ($wl) . " --- " . get_actual_word ($closest_word) . " -    $wl vs $closest_word\n");
            }
        }
        else
        {
            if ($DO_DEBUG)
            {
                print ("NO scw ($min_distance) " . get_actual_word ($wl) . " --- " . get_actual_word ($closest_word) . " -    $wl vs $closest_word($length_word was calculated)\n");
            }
        }
    }
}

# Set closest words..
sub set_closest_words_based_on_index
{
    my $index = 1;
    my $word_left;
    my $word_right;
    my $word_bottom;
    my $word_top;
    my $word_left2;
    my $word_right2;
    my $word_bottom2;
    my $word_top2;

    while (defined ($word_locations {$index}) && defined ($word_locations {$index+1}))
    {
        my $y = $word_locations_y {$index};
        my $y2 = $word_locations_y {$index+1};

        if ($y == $y2)
        {
            my $style = $word_locations_style {$index};
            my $style2 = $word_locations_style {$index+1};

            if ($style eq $style2)
            {
                # Check not too far away..
                ($word_left, $word_right, $word_bottom, $word_top) = get_word_dimensions ($index);
                ($word_left2, $word_right2, $word_bottom2, $word_top2) = get_word_dimensions ($index+1);

                my $length_word = calculate_size ($index) * 1.25;
                if ($word_left + $length_word > $word_left2)
                {
                    # Same height in document, and adjacent in terms of word number index, and (loosely) close by..
                    $closest_word_to_word {$index} = $index+1;
                    if ($DO_DEBUG)
                    {
                        print ("scw adjacent: " . get_actual_word ($index) . " --- " . get_actual_word ($index+1) . " ($index >> and " . ($index+1) . "\n");
                    }
                }
            }
        }
        $index++;
    }
    
    # Paragraph checking for adjacent words that are on the next line
    $index = 1;
    while (defined ($word_locations {$index}) && defined ($word_locations {$index+1}))
    {
        my $y = $word_locations_y {$index};
        my $y2 = $word_locations_y {$index+1};

        if ($y != $y2)
        {
            my $style = $word_locations_style {$index};
            my $style2 = $word_locations_style {$index+1};

            if ($style eq $style2)
            {
                if (!defined ($closest_word_to_word {$index}))
                {
                    # Check on next line??
                    ($word_left, $word_right, $word_bottom, $word_top) = get_word_dimensions ($index);
                    ($word_left2, $word_right2, $word_bottom2, $word_top2) = get_word_dimensions ($index+1);

                    if ($word_left2 <= $word_left && get_abs ($word_bottom - $word_bottom2) < $EXTEND_SIZE && get_abs ($word_bottom - $word_bottom2) > 0)
                    {
                        # Different lines but same style and next word
                        if (!defined ($word_locations_closest_to_box {$index+1}))
                        {
                            $closest_word_to_word {$index} = $index+1;
                            if ($DO_DEBUG)
                            {
                                print ("scw paragraph: " . get_actual_word ($index) . " --- " . get_actual_word ($index+1) . " ($index >> and " . ($index+1) . "\n");
                            }
                        }
                        else
                        {
                            if ($DO_DEBUG)
                            {
                                print ("NO scw paragraph (close to box): " . get_actual_word ($index) . " --- " . get_actual_word ($index+1) . " ($index >> and " . ($index+1) . "\n");
                            }
                        }
                    }
                }
            }
        }
        $index++;
    }
}

sub is_later_word
{
    my $wl = $_ [0];
    if (defined ($closest_word_to_word {$wl}) && $wl < $closest_word_to_word {$wl})
    {
        return 1;
    }
    return 0;
}

sub get_later_word
{
    my $wl = $_ [0];

    if (defined ($closest_word_to_word {$wl}) && $wl < $closest_word_to_word {$wl})
    {
        return $closest_word_to_word {$wl};
    }
    return "";
}

sub is_early_word
{
    my $wl = $_ [0];
    my $a;
    foreach $a (keys (%closest_word_to_word))
    {
        if ($closest_word_to_word {$a} == $wl)
        {
            if (defined ($word_locations_closest_to_box {$wl}))
            {
                next;
            }

            if ($a < $wl)
            {
                return $a;
            }
        }
    }

    return "";
}

sub get_early_word
{
    my $wl = $_ [0];

    my $a;
    foreach $a (keys (%closest_word_to_word))
    {
        if ($closest_word_to_word {$a} == $wl)
        {
            if ($a < $wl)
            {
                return $a;
            }
        }
    }

    return "";
}

sub get_earliest_word
{
    my $wl = $_ [0];
    my $orig_wl = $_ [0];
    my $min_id = $wl;
    my $found_earliest = 0;

    while (is_early_word ($wl) && !$found_earliest)
    {
        $wl = get_early_word ($wl);
        if ($min_id > $wl && $wl =~ m/\d/)
        {
            $min_id = $wl;
        }
        else
        {
            $found_earliest = 1;
        }
    }
    return $min_id;
}

sub get_word_chains
{
    # Do chain of words..
    my $count = 0;
    my $wl = $_ [0];
    $wl = get_earliest_word ($wl);
    my $chain_wl = $wl;
    my %seen_words;
    my $keep_going = 1;

    my $this_line_box = $word_locations_closest_to_box {$wl} . " ";

    $seen_words {$chain_wl} = 1;
    while (is_later_word ($chain_wl) && $keep_going)
    {
        $chain_wl = get_later_word ($chain_wl);

        my $close_to_box = $word_locations_closest_to_box {$chain_wl} . " ";
        if ($close_to_box ne $this_line_box && $close_to_box =~ m/../)
        {
            # Try and stop chains using other checkboxes labels!
            $keep_going = 0;
            next;
        }

        if (!defined ($seen_words {$chain_wl}))
        {
            $seen_words {$chain_wl} = 1;
        }
        else
        {
            $seen_words {$chain_wl} = 1;
            $keep_going = 0;
        }
    }
    return "," . join (",", sort keys (%seen_words));
}

sub get_key_words
{
    my $final_kws = $_ [0];
    my %final_kws_hash;
    while ($final_kws =~ s/(\d+)//)
    {
        $final_kws_hash {$1} = 1;
    }

    my $k;
    my $str;
    foreach $k (sort { $a <=> $b } keys %final_kws_hash)
    {
        $str .= get_actual_word ($k) . " ";
    }
    #$str =~ s/ $//;

    #if ($str =~ m/.{50}/)
    #{
    #    $str =~ s/  / /mg;
    #    $str =~ s/ [^ ] / /mg;
    #    $str =~ s/  / /mg;
    #    $str =~ s/ [^ ][^ ] / /mg;
    #    $str =~ s/  / /mg;
    #    $str =~ s/ [^ ][^ ][^ ] / /mg;
        $str =~ s/  / /mg;
    #}
    return $str;
}

sub does_top_ray_intersect
{
    my $wl = $_ [0]; # Word index..
    my $bl = $_ [1]; # Box index..
    my $height_above_box = $_ [2]; # Box ray extension..

    my $word_left;
    my $word_right;
    my $word_bottom;
    my $word_top;
    ($word_left, $word_right, $word_bottom, $word_top) = get_word_dimensions ($wl);
    
    my $box_left;
    my $box_right;
    my $box_bottom;
    my $box_top;
    my ($box_left, $box_right, $box_bottom, $box_top) = get_box_dimensions ($bl);

    if (!($word_bottom > $box_top - $height_above_box && $word_bottom <= $box_top))
    {
        return 0;
    }

    if ($DO_DEBUG)
    {
        #print ("  $height_above_box -- " . get_actual_word ($wl) . " - in big top BOX($box_left, $box_right, $box_bottom, $box_top);WORD($word_left, $word_right, $word_bottom);");
    }

    if ($word_left <= $box_left && $word_right >= $box_left) { return 1; }
    if ($word_left > $box_left && $word_left <= $box_right) { return 1; }
    if ($word_left > $box_left && $word_left > $box_right) { return 0; }
    return 0;
}

sub read_data
{
    my $msword_locations;

    $msword_locations = `type $msword_file`;
    chomp $msword_locations;

    # Read in file and construct hashes
    while ($msword_locations =~ s/^(.*)\n//g)
    {
        my $line = $1;
        if ($line =~ m/^Field(\d+?);(.*?);(.*?);(.*?);(.*?);(.*?)$/)
        {
            my $index = $1;
            my $word = $2; # Blank..
            my $page_number = $3;
            my $left = $4;
            my $top = $5;
            my $box_type = $6; # Checkbox or Textbox..

            if ($page_number < $PAGES_LIMIT)
            {
                my $qq = "$left,$top";
                if (!defined ($box_locations_xy {$qq}))
                {

                    $box_locations {$index} = "$index,$box_type";
                    $box_locations_page {$index} = "$page_number";
                    $box_locations_x {$index} = $left;
                    $box_locations_y {$index} = $top;
                    $box_locations_xy {$qq} = $index;

                    # Assume it's a textbox..
                    $box_locations_type {$index} = $TEXTBOX;
                    if (lc ($box_type) eq $CHECKBOX_STR)
                    {
                        $box_locations_type {$index} = $CHECKBOX;
                    }
                }
                else
                {
                    print ("WARN: Matching box locations found... $box_locations_xy{$qq} $left,$top field ($index)... " . $box_locations_xy{$qq} . " ....$left,$top...\n");
                }
            }
        }
        elsif ($line =~ m/^(.*?);(.*?);(.*?);(.*?);(.*?);(.*?)$/)
        {
            my $index = $1;
            my $word = $2;
            my $page_number = $3;
            my $left = $4;
            my $top = $5;
            my $style = $6;

            if ($page_number < $PAGES_LIMIT)
            {
                $word_locations {$index} = "$word";
                $word_locations_used {$index} = 0;
                $word_locations_used_by {$index} = "";
                $word_locations_page {$index} = "$page_number";
                $word_locations_x {$index} = "$left";
                $word_locations_y {$index} = "$top";
                $word_locations_style {$index} = "$style";
            }
        }
    }
}

sub round_to
{
    my $input = $_ [0];
    my $round_to = $_ [1];
    return int (($input / $round_to) + 0.5) * $round_to;
}

# Main
{
    if (scalar (@ARGV) == 1)
    {
        $msword_file = $ARGV [0];
    }
    else
    {
        print ("\n$0 fco_template_4_words_new.txt\nRun like that dumbass\n");
        exit;
    }

    read_data ();
    set_multiples_for_style ();
    set_closest_words_to_boxes (1);
    set_closest_words (1);
    set_closest_words_based_on_index (1);

    # Test chains..
    if ($DO_DEBUG)
    {
        # Do chain of words..
        my $words;
        my $keywords;

        $words = get_word_chains (245);
        print ($words, "\n==================\n");
        $keywords = get_key_words ($words);
        print ($keywords, "\n==================\n");
        $words = get_word_chains (55);
        $keywords = get_key_words ($words);
        print ($keywords, "\n==================\n");
        $words = get_word_chains (53);
        $keywords = get_key_words ($words);
        print ($keywords, "\n==================\n");
        $words = get_word_chains (246);
        print ($words, "\n==================\n");
        $words = get_word_chains (247);
        print ($words, "\n==================\n");
        $words = get_word_chains (248);
        print ($words, "\n==================\n");
        $words = get_word_chains (363);
        $keywords = get_key_words ($words);
        print ($words, " -- $keywords\n==================\n");
        $words = get_word_chains (228);
        $keywords = get_key_words ($words);
        print ($words, " -- $keywords\n==================\n");
    }

    # For each box, project left, right or top (not bottom) to see what significant words are in that ray
    #          ......
    #          ......
    #          ......
    # .........+----+..........
    # .........|    |..........
    # .........+----+..........
    #
    # Aka in any of the '.' regions for a given checkbox etc
    # For top, get significant (aka bold type text) at a higher projection
    #
    my $bl;
    my $box_page;
    my $box_type; # 0 = checkbox, 1 = textbox..
    my $box_left;
    my $box_right;
    my $box_bottom;
    my $box_top;

    my $word_page;
    my $word_left;
    my $word_right;
    my $word_bottom;
    my $word_top;
    my $word_left;
    my $word_bottom;

    foreach $bl (sort keys (%box_locations))
    {
        $box_page = $box_locations_page {$bl};
        $box_type = $box_locations_type {$bl};

        ($box_left, $box_right, $box_bottom, $box_top) = get_box_dimensions ($bl);

        # Closest word to box
        if (defined ($closest_word_to_box {$bl})) 
        {
            my $closest_word = $closest_word_to_box {$bl};
            # Do chain of words..
            my $wcs = get_word_chains ($closest_word);
            $box_key_words_closest {$bl} .= "(CLOSEST).|$wcs|,";
            $box_key_words_overall {$bl} .= "(CLOSEST).|$wcs|,";
        }

        my $wl;
        foreach $wl (sort keys (%word_locations))
        {
            $word_page = $word_locations_page {$wl};
            $word_left = $word_locations_x {$wl};
            $word_bottom = $word_locations_y {$wl};
            if ($word_page == $box_page && $word_page < $PAGES_LIMIT)
            {
                $word_left = $word_locations_x {$wl};
                $word_bottom = $word_locations_y {$wl};

                
                # In Left box and not checkbox..
                if ($word_left < $box_left && $word_left > $box_left - $EXTEND_SIZE && $word_bottom <= $box_top && $word_bottom >= $box_bottom && $box_type == $TEXTBOX)
                {
                    # Do chain of words..
                    my $wcs = get_word_chains ($wl);
                    $box_key_words_left {$bl} .= "(LEFT).|$wcs|,";
                    $box_key_words_overall {$bl} .= "(LEFT).|$wcs|,";
                }

                # In Right box..
                if ($word_left > $box_right && $word_left < $box_right + $EXTEND_SIZE && $word_bottom <= $box_top && $word_bottom >= $box_bottom)
                {
                    # Do chain of words..
                    my $wcs = get_word_chains ($wl);
                    $box_key_words_right {$bl} .= "(RGHT).|$wcs|,";
                    $box_key_words_overall {$bl} .= "(RGHT).|$wcs|,";
                }
            }
        }

        foreach $wl (sort keys (%word_locations))
        {
            $word_page = $word_locations_page {$wl};
            $word_left = $word_locations_x {$wl};
            $word_bottom = $word_locations_y {$wl};
            if ($word_page == $box_page && $word_page < $PAGES_LIMIT)
            {
                $word_left = $word_locations_x {$wl};
                $word_bottom = $word_locations_y {$wl};

                # In TOP box..
                my $got_nuthin = !defined ($box_key_words_overall {$bl});

                my $in_top = does_top_ray_intersect ($wl, $bl, $EXTEND_SIZE);

                if ($in_top)
                {
                    # Do chain of words..
                    my $wcs = get_word_chains ($wl);
                    $box_key_words_top {$bl} .= "(TOP).|$wcs|,";
                    $box_key_words_overall {$bl} .= "(TOP).|$wcs|,";
                }

                my $is_bold_style = is_bold_style ($wl);
                if ($is_bold_style)
                {
                    $in_top = does_top_ray_intersect ($wl, $bl, $BOLD_EXTEND_SIZE);
                    if ($in_top)
                    {
                        # Do chain of words..
                        my $wcs = get_word_chains ($wl);
                        $box_key_words_top {$bl} .= "(BTOP).|$wcs|,";
                        $box_key_words_overall {$bl} .= "(BTOP).|$wcs|,";
                    }
                }
            }
        }
    }

    my $bkw;
    my %box_xs;
    my %box_ys;
    
    foreach $bkw (sort { $a <=> $b } keys (%box_key_words_overall))
    {
        my $box_x = $box_locations_x {$bkw};
        my $box_y = $box_locations_y {$bkw};
        $box_xs {$box_x} = 1;
        $box_ys {$box_y} = 1;
    }
    
    my $wl;
    foreach $wl (sort keys (%word_locations))
    {
        if (is_bold_style ($wl))
        {
            my ($word_left, $word_right, $word_bottom, $word_top) = get_word_dimensions ($wl);
            $box_xs {$word_left} = 1;
            $box_ys {$word_bottom} = 1;
        }
    }
    
    my $bx;
    my %box_cols;
    my $col = 0;
    my $smallest_x_diff = +55555;
    my $last_x;
    foreach $bx (sort { $a <=> $b } keys (%box_xs))
    {
        if (get_abs ($last_x - $bx) < $smallest_x_diff)
        {
            $smallest_x_diff = get_abs ($last_x - $bx);
        }
        $last_x = $bx;
        $bx = round_to ($bx, $COARSENESS);
        if (!defined ($box_cols {$bx}))
        {
            $box_cols {$bx} = $col;
            $col++;
        }
    }
    
    my $by;
    my %box_rows;
    my $row = 0;
    foreach $by (sort { $a <=> $b } keys (%box_ys))
    {
        $by = round_to ($by, $COARSENESS);
        if (!defined ($box_rows {$by}))
        {
            $box_rows {$by} = $row;
            $row++;
        }
    }

    # Overall positioning
    my $page_number = 0;
    for ($page_number = 1; $page_number < $PAGES_LIMIT; $page_number++) 
    {
        my %op;

        print ("Page;Col;Row;MSWordID;Field;Page;X;Y;SurroundingText_Closest;SurroundingText_Left;SurroundingText_Right;SurroundingText_Top\n");
        my $things_in_page = 0;
        foreach $bkw (sort { $a <=> $b } keys (%box_key_words_overall))
        {
            my $box_page = $box_locations_page {$bkw};
            if ($box_page != $page_number)
            {
                next;
            }
            my $box_x = $box_locations_x {$bkw};
            my $box_y = $box_locations_y {$bkw};

            my $box_type = $box_locations_type {$bkw};
            my $type = "T";
            if ($box_type == $CHECKBOX)
            {
                $type = "C";
            }
            my $final_kws_closest = get_key_words ($box_key_words_closest{$bkw});
            my $final_kws_left = get_key_words ($box_key_words_left{$bkw});
            my $final_kws_right = get_key_words ($box_key_words_right{$bkw});
            my $final_kws_top = get_key_words ($box_key_words_top{$bkw});

            my $round_box_x = round_to ($box_x, $COARSENESS);
            my $round_box_y = round_to ($box_y, $COARSENESS);
            my $col = $box_rows {$round_box_y};
            my $row = $box_cols {$round_box_x};
            #print ("$box_page;$col;$row;$bkw;$type;$box_page;$box_x;$box_y;>>>$final_kws_closest<<<;$final_kws_left;$final_kws_right;$final_kws_top\n");
            if (!defined ($op {"$row,$col"}))
            {
                $things_in_page++;
                $op {"$row,$col"} = "$type,$bkw,$final_kws_closest";
            }
            else
            {
                my $other_bkw = $op {"$row,$col"};
                $other_bkw =~ s/^.*,(\d+),.*/$1/;
                my $bbx_x = $box_locations_x {$other_bkw};
                my $bbx_y = $box_locations_y {$other_bkw};
                print ("ERROR $box_page (box = $bkw, $type) - ROW,COL box $row,$col DOUBLE HIT $round_box_x, $round_box_y (from $box_x, $box_y) compared to:" . $op {"$row,$col"} . " ($bbx_x,$bbx_y)\n");
                $op {"$row,$col"} .= "<br>DUPLICATE BOX: $type,$bkw,$final_kws_closest";
            }
        }
        
        foreach $wl (sort keys (%word_locations))
        {
            my $word_page = $word_locations_page {$wl};
            if ($word_page != $page_number)
            {
                next;
            }
            if (is_bold_style ($wl))
            {
                my ($word_left, $word_right, $word_bottom, $word_top) = get_word_dimensions ($wl);
                $word_left = round_to ($word_left, $COARSENESS);
                $word_bottom = round_to ($word_bottom, $COARSENESS);
                my $col = $box_rows {$word_bottom};
                my $row = $box_cols {$word_left};
                #$op {"$row,$col"} = "<b>" . get_actual_word ($wl) . $word_locations_style {$wl} . "</b>";

                my $ewl = get_earliest_word ($wl);
                if ($ewl == $wl)
                {
                    my $words = get_word_chains ($wl);
                    my $keywords = get_key_words ($words);

                    #$op {"$row,$col"} = "<b>" . get_actual_word ($wl) . "</b>";
                    if (!defined ($op {"$row,$col"}))
                    {
                        $things_in_page++;
                        $op {"$row,$col"} = "<b>" . $keywords . "</b>";
                    }
                    else
                    {
                        print ("WARN $word_page ($keywords) - ROW,COL word $row,$col DOUBLE HIT $word_left, $word_bottom\n");
                        $op {"$row,$col"} .= "<br>Duplication Hit: <b>" . $keywords . "</b>";
                    }
                }
            }
        }

        print "\n";
        print "\n";
        print "\n";
        print "\n";
        print "\n";
        print (";Page $page_number;Things in page = $things_in_page;\n");
        my $r;
        my $c;
        for ($r = 0; $r < $row; $r++)
        {
            for ($c = 0; $c < $col; $c++)
            {
                print ($op {"$c,$r"} . ";");
            }
            print "\n";
        }
    }

    my $wl;
    foreach $wl (sort keys (%word_locations))
    {
        my $box = get_closest_box ($wl);
        my $word_page = $word_locations_page {$wl};

        if ($word_locations_used_by{$wl} ne "")
        {

            my $str = ",$word_locations_used_by{$wl},";
            if ($str =~ m/,$box,/)
            {
                if ($DO_DEBUG)
                {
                    print "    Page $word_page Closest box is $box for $str $wl " . get_actual_word ($wl) . " match\n";
                }
            }
            else
            {
                if ($DO_DEBUG)
                {
                    print "    Page $word_page Closest box is $box for $str $wl " . get_actual_word ($wl) . " match\n";
                    print " NO MATCH!!\n";
                }
            }
        }
    }
}
