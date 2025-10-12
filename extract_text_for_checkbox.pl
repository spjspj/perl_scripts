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

my $msword_file;
my $msword_locations;
my %word_locations;
my %word_locations_used;
my %word_locations_used_by;
my %word_locations_page;
my %word_locations_x;
my %word_locations_y;
my %word_locations_style;
my %box_locations;
my %box_locations_page;
my %box_locations_x;
my %box_locations_y;
my %box_locations_type;
my %box_key_words_overall;
my %box_key_words_left;
my %box_key_words_right;
my %box_key_words_top;

my %closest_box_to_word;
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

# Get closest box..
sub get_closest_box
{
    my $wl = $_ [0];
    my $word_x = $word_locations_x {$wl};
    my $word_y = $word_locations_y {$wl};
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

        if ($word_page == $box_page && $word_page < 3)
        {
            ($box_left, $box_right, $box_bottom, $box_top) = get_box_dimensions ($bl);
            my $diff_x = $box_left - $word_x;
            my $diff_y = $box_bottom - $word_y;

            $dist = sqrt ($diff_x * $diff_x + $diff_y * $diff_y);
            if ($dist < $min_distance)
            {
                $min_distance = $dist;
                $closest_box = $bl;
            }
        }
    }
    $closest_box_to_word {$wl} = $closest_box;

    if ($closest_box ne "NOTABOX")
    {
        if ($DO_DEBUG)
        {
            print ("gcb - $wl, $closest_box, $min_distance\n");
        }
    }
    return $closest_box;
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
                my $l = length ($word_locations {$index});
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

    my $text = $word_locations {$wl};
    my $l = length ($text);
    my $style = $word_locations_style {$wl};

    return $styles_sizes_per_character {$style} * $l;
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

# Set closest words..
sub set_closest_words
{
    my $page = $_ [0];
    my $wl;
    my $wl2;
    my $min_distance = 1000000;
    my $closest_word = "XXXXXX";
    my $dist;
    my $word_x;
    my $word_x2;
    my $word_y;
    my $word_y2;
    my $word_page;
    my $word_page2;

    foreach $wl (sort keys (%word_locations))
    {
        $min_distance = 1000000;
        $word_x = $word_locations_x {$wl};
        $word_y = $word_locations_y {$wl};
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
            $word_x2 = $word_locations_x {$wl2};
            $word_y2 = $word_locations_y {$wl2};

            my $diff_x = $word_x2 - $word_x;
            my $diff_y = $word_y2 - $word_y;

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
                print ("scw ($min_distance) $word_locations{$wl} --- $word_locations{$closest_word} -    $wl vs $closest_word\n");
            }
        }
        else
        {
            if ($DO_DEBUG)
            {
                print ("NO scw ($min_distance) $word_locations{$wl} --- $word_locations{$closest_word} -    $wl vs $closest_word ($length_word was calculated)\n");
            }
        }
    }
}

# Set closest words..
sub set_closest_words_based_on_index
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
                # Check not too far away..
                my $word_x = $word_locations_x {$index};
                my $word_x2 = $word_locations_x {$index+1};
                my $length_word = calculate_size ($index) * 1.25;

                my $blah = $word_x + $length_word;
                if ($word_x + $length_word > $word_x2)
                {
                    # Same height in document, and adjacent in terms of word number index, and (loosely) close by..
                    $closest_word_to_word {$index} = $index+1;
                    if ($DO_DEBUG)
                    {
                        print ("scw adjacent: $word_locations{$index} --- " . $word_locations{$index+1} . " ($index >> and " . ($index+1) . "\n");
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
                    my $word_y = $word_locations_y {$index};
                    my $word_y2 = $word_locations_y {$index+1};
                    my $word_x = $word_locations_x {$index};
                    my $word_x2 = $word_locations_x {$index+1};

                    if ($word_x2 <= $word_x && get_abs ($word_y - $word_y2) < $EXTEND_SIZE && get_abs ($word_y - $word_y2) > 0)
                    {
                        # Different lines but same style and next word
                        $closest_word_to_word {$index} = $index+1;
                        if ($DO_DEBUG)
                        {
                            print ("scw paragraph: $word_locations{$index} --- " . $word_locations{$index+1} . " ($index >> and " . ($index+1) . "\n");
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
    if ($DO_DEBUG)
    {
        print ("glw -- $wl\n");
    }

    if (defined ($closest_word_to_word {$wl}) && $wl < $closest_word_to_word {$wl})
    {
        if ($DO_DEBUG)
        {
            print ("glw -- $wl == $closest_word_to_word{$wl}\n");
        }
        return $closest_word_to_word {$wl};
    }
    return "";
}

sub is_early_word
{
    my $wl = $_ [0];
    if ($DO_DEBUG)
    {
        print ("ecw -- $wl\n");
    }

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

sub get_early_word
{
    my $wl = $_ [0];
    if ($DO_DEBUG)
    {
        print ("ecw -- $wl\n");
    }

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

    $seen_words {$chain_wl} = 1;
    while (is_later_word ($chain_wl) && $keep_going)
    {
        $chain_wl = get_later_word ($chain_wl);
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
        $str .= "$word_locations{$k} ";
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

    my $word_x = $word_locations_x {$wl};
    my $word_y = $word_locations_y {$wl};
    my $size = calculate_size ($wl);
    my $word_right_x = $word_x + $size;

    my ($box_left, $box_right, $box_bottom, $box_top) = get_box_dimensions ($bl);

    if (!($word_y > $box_top - $height_above_box && $word_y <= $box_top))
    {
        return 0;
    }

    if ($DO_DEBUG)
    {
        print ("  $height_above_box -- $word_locations{$wl} - in big top BOX($box_left, $box_right, $box_bottom, $box_top);WORD($word_x, $word_right_x, $word_y);");
    }

    if ($word_x <= $box_left && $word_right_x >= $box_left) { return 1; }
    if ($word_x > $box_left && $word_x <= $box_right) { return 1; }
    if ($word_x > $box_left && $word_x > $box_right) { return 0; }
    return 0;
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

    my $msword_locations;

    $msword_locations = `type $msword_file`;
    chomp $msword_locations;

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

            $box_locations {$index} = "$index,$box_type";
            $box_locations_page {$index} = "$page_number";
            $box_locations_x {$index} = $left;
            $box_locations_y {$index} = $top;

            # Assume it's a textbox..
            $box_locations_type {$index} = $TEXTBOX;
            if (lc ($box_type) eq $CHECKBOX_STR)
            {
                $box_locations_type {$index} = $CHECKBOX;
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
            $word_locations {$index} = "$word";
            $word_locations_used {$index} = 0;
            $word_locations_used_by {$index} = "";
            $word_locations_page {$index} = "$page_number";
            $word_locations_x {$index} = "$left";
            $word_locations_y {$index} = "$top";
            $word_locations_style {$index} = "$style";
            if ($DO_DEBUG)
            {
                print ("   initial read ($index)=$word , $page_number, ($left,$top)\n");
            }
        }
    }

    set_multiples_for_style ();
    set_closest_words (1);
    set_closest_words_based_on_index (1);

    # Test chains..
    if ($DO_DEBUG)
    {
        # Do chain of words..
        my $words = get_word_chains (245);
        print ($words, "\n==================\n");
        $words = get_word_chains (246);
        print ($words, "\n==================\n");
        $words = get_word_chains (247);
        print ($words, "\n==================\n");
        $words = get_word_chains (248);
        print ($words, "\n==================\n");
        $words = get_word_chains (363);
        print ($words, "\n==================\n");
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
    my $word_x;
    my $word_y;

    foreach $bl (sort keys (%box_locations))
    {
        $box_page = $box_locations_page {$bl};
        $box_type = $box_locations_type {$bl};

        ($box_left, $box_right, $box_bottom, $box_top) = get_box_dimensions ($bl);

        my $wl;
        foreach $wl (sort keys (%word_locations))
        {
            $word_page = $word_locations_page {$wl};
            $word_x = $word_locations_x {$wl};
            $word_y = $word_locations_y {$wl};
            if ($word_page == $box_page && $word_page < 3)
            {
                $word_x = $word_locations_x {$wl};
                $word_y = $word_locations_y {$wl};

                # In Left box and not checkbox..
                if ($word_x < $box_left && $word_x > $box_left - $EXTEND_SIZE && $word_y <= $box_top && $word_y >= $box_bottom && $box_type == $TEXTBOX)
                {
                    # Do chain of words..
                    my $wcs = get_word_chains ($wl);
                    $box_key_words_left {$bl} .= "(LEFT).|$wcs|,";
                    $box_key_words_overall {$bl} .= "(LEFT).|$wcs|,";
                }

                # In Right box..
                if ($word_x > $box_right && $word_x < $box_right + $EXTEND_SIZE && $word_y <= $box_top && $word_y >= $box_bottom)
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
            $word_x = $word_locations_x {$wl};
            $word_y = $word_locations_y {$wl};
            if ($word_page == $box_page && $word_page < 3)
            {
                $word_x = $word_locations_x {$wl};
                $word_y = $word_locations_y {$wl};

                # In TOP box..
                my $got_nuthin = !defined ($box_key_words {$bl});

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
    print ("Field;Page;X;Y;SurroundingText_Left;SurroundingText_Right;SurroundingText_Top;MSWordID\n");
    foreach $bkw (sort keys (%box_key_words_overall))
    {
        my $box_page = $box_locations_page {$bkw};
        my $box_x = $box_locations_x {$bkw};
        my $box_y = $box_locations_y {$bkw};
        my $box_type = $box_locations_type {$bkw};
        if ($box_type == $CHECKBOX)
        {
            my $final_kws_left = get_key_words ($box_key_words_left{$bkw});
            my $final_kws_right = get_key_words ($box_key_words_right{$bkw});
            my $final_kws_top = get_key_words ($box_key_words_top{$bkw});
            print ("Checkbox;$box_page;$box_x;$box_y;$final_kws_left;$final_kws_right;$final_kws_top;$bkw\n");
        }
        elsif ($box_type == $TEXTBOX)
        {
            my $final_kws_left = get_key_words ($box_key_words_left{$bkw});
            my $final_kws_right = get_key_words ($box_key_words_right{$bkw});
            my $final_kws_top = get_key_words ($box_key_words_top{$bkw});
            print ("Textbox;$box_page;$box_x;$box_y;$final_kws_left;$final_kws_right;$final_kws_top;$bkw\n");
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
                    print "    Page $word_page Closest box is $box for $str $wl $word_locations{$wl} match\n";
                }
            }
            else
            {
                if ($DO_DEBUG)
                {
                    print ("Page $word_page Closest box is $box for $wl $word_locations{$wl} --- used by >>$word_locations_used_by{$wl}<<  ");
                    print " NO MATCH!!\n";
                }
            }
        }
    }
}
