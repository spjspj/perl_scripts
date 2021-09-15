#!/usr/bin/perl
##
#   File : cthulhu.pl
#   Date : 12/Aug/2021
#   Author : spjspj
#   Purpose : Implement Don't mess with Cthulhu! (deluxe edition)
#   Purpose : Requires having an Apache service setup (see conf file)
#             Not providing the images for the game, but you will need the following ones:
#             _cthulhu.jpg rock.jpg rune.jpg necro.jpg private_eye.jpg mirage.jpg back.jpg insane.jpg paranoia.jpg prescient_vision.jpg torch.jpg cultist.jpg oberon.jpg
##

use strict;
use LWP::Simple;
use Socket;
use File::Copy;
use List::Util qw(shuffle);
use Time::HiRes;
use URI::Escape;
use POSIX qw(strftime);

$| = 1;

my $MIR = "MIRAGE";
my $RCK = "ROCK";
my $RRR = "RUNE";
my $NEC = "NECRO";
my $CTH = "CTHULHU";
my $INS = "INSANE";
my $TRCH = "torch";
my $PRIV = "private_eye";
my $EXPOSED = "exposed";
my $PARA = "paranoia";
my $PRESC = "prescient_vision";
my $SMALL_GAME = 3;
my $MED_GAME = 6;
my %COUNTS_OF_CARDS;
my %exposed_cards;
my %revealed_cards;
my %revealed_cards_imgs;
my $DONT_PASS_TORCH = 0;
my $NEXT_PICK_IS_PRESCIENT = 0;
my $BCK = "back";
my $NUM_CARDS_AT_START_OF_GAME = 5;
my $GAME_WON = 0;
my $reason_for_game_end = "";
my $CURRENT_CTHULHU_NAME = "";
my $SHOW_CARDS_MODE = 0;
my $IN_DEBUG_MODE = 0;

my $BAD_GUYS = -1;
my $GOOD_GUYS = 1;
my $CULTIST = "cultist";
my $OBERON = "oberon";
my $INVESTIGATOR = "investigator";
my $CTHULHU = "<img id=\"xxx\" width=\"80\" height=\"131\" src=\"_$CTH.jpg\"><\/img>";
my $ROCK = "<img id=\"xxx\" width=\"80\" height=\"131\" src=\"rock.jpg\"><\/img>";
my $RUNE = "<img id=\"xxx\" width=\"80\" height=\"131\" src=\"rune.jpg\"><\/img>";
my $NECRO = "<img id=\"xxx\" width=\"80\" height=\"131\" src=\"necro.jpg\"><\/img>";
my $PRIVATE_EYE = "<img id=\"xxx\" width=\"80\" height=\"131\" src=\"private_eye.jpg\"><\/img>";
my $MIRAGE = "<img id=\"xxx\" width=\"80\" height=\"131\" src=\"mirage.jpg\"><\/img>";
my $BACK = "<img id=\"xxx\" width=\"80\" height=\"131\" src=\"back.jpg\"><\/img>";
my $INSANE = "<img id=\"xxx\" width=\"80\" height=\"131\" src=\"insane.jpg\"><\/img>";
my $PARANOIA = "<img id=\"xxx\" width=\"80\" height=\"131\" src=\"paranoia.jpg\"><\/img>";
my $PRESCIENT_VISION = "<img id=\"xxx\" width=\"80\" height=\"131\" src=\"prescient_vision.jpg\"><\/img>";
my $TORCH = "<img src=\"torch.jpg\"><\/img>";
my $CULTIST_IMG = "<img width=\"120\" height=\"175\" src=\"$CULTIST.jpg\"></img>";
my $OBERON_IMG = "<img width=\"120\" height=\"175\" src=\"$OBERON.jpg\"></img>";
my $INVESTIGATOR_IMG = "<img width=\"120\" height=\"175\" src=\"$INVESTIGATOR.jpg\"></img>";
my $SMALL_CULTIST_IMG = "<img width=\"60\" height=\"83\" src=\"$CULTIST.jpg\"></img>";
my $SMALL_INVESTIGATOR_IMG = "<img width=\"60\" height=\"83\" src=\"$INVESTIGATOR.jpg\"></img>";
my $SMALL_CTHULHU = "<img width=\"60\" height=\"83\" src=\"_$CTH.jpg\"><\/img>";
my $SMALL_PRIVATE_EYE = "<img width=\"60\" height=\"83\" src=\"private_eye.jpg\"><\/img>";
my $SMALL_RUNE = "<img width=\"60\" height=\"83\" src=\"rune.jpg\"><\/img>";
my %rand_colors;
my %FACEUP_ORDER;

my $DEBUG = "";
my @player_names;
my @NEEDS_REFRESH;
my @NEEDS_ALERT;
my @player_cultist;
my @deck;
my %already_shuffled;
my $needs_shuffle_but_before_next_card_picked = 0;
my %BANNED_NAMES;
my %CHAT_MESSAGES;
my $ZOOM_URL_LINK = "No zoom link pasted into chat yet!";
my $ZOOM_URL_LINK_DATE;
my $RINGINGROOM_URL_LINK;
my $ZOOM_URL_LINK_set = 0;
my $RR_URL_LINK_set = 0;
my $NUM_CHAT_MESSAGES = 0;
my %NOT_HIDDEN_INFO;

my $who_has_torch;
my $pot_who_has_torch;
my $num_players_in_game = -1;
my $NUM_EXPOSED_CARDS = 0;
my $NECRO_PICKED = 0;
my $NUM_RUNES_PICKED = 0;
my $MIRAGE_PICKED = 0;
my $CHANGE_OF_ROUND = 0;
my $num_cards_per_player = $NUM_CARDS_AT_START_OF_GAME;
my @player_ips;
my $num_players_in_lobby = 0;

sub game_won
{
    my $win_con = $_ [0];

    if ($GAME_WON == 0)
    {
        force_needs_refresh();
        $GAME_WON = $_ [0];
        $reason_for_game_end = $_ [1];
    }
}

sub get_game_won
{
    if ($GAME_WON == 0)
    {
        return "";
    }
    my $i = 0;
    if ($GAME_WON == -1)
    {
        my %thes;
        $thes {1} = "wickedly";
        $thes {2} = "evilly";
        $thes {3} = "iniquitously";
        $thes {4} = "heinously";
        $thes {5} = "villainously";
        $thes {6} = "diabolically";
        $thes {7} = "diabolicly";
        $thes {8} = "fiendishly";
        $thes {9} = "viciously";
        $thes {10} = "murderously";
        $thes {11} = "barbarously";
        $thes {12} = "cruelly";
        $thes {13} = "blackly";
        $thes {14} = "darkly";
        $thes {15} = "rottenly";
        $thes {16} = "nefariously";
        $thes {17} = "vilely";
        $thes {18} = "foully";
        $thes {19} = "monstrously";
        $thes {20} = "shockingly";
        $thes {21} = "outrageously";
        $thes {22} = "atrociously";
        $thes {23} = "abominably";
        $thes {24} = "reprehensibly";
        $thes {25} = "despicably";
        $thes {26} = "execrably";
        $thes {27} = "corruptly";
        $thes {28} = "degenerately";
        $thes {29} = "reprobately";
        $thes {30} = "sordidly";
        $thes {31} = "depravedily";
        $thes {32} = "dissolutely";
        $thes {33} = "badly";
        $thes {34} = "basely";
        $thes {35} = "meanly";
        $thes {36} = "lowly";
        $thes {37} = "dishonourably";
        $thes {38} = "dishonestly";
        $thes {39} = "unscrupulously";
        $thes {40} = "unprincipledly";
        $thes {41} = "underhandly";
        $thes {42} = "roguishly";
        $thes {43} = "crookedly";
        $thes {44} = "lowly";
        $thes {45} = "stinkingly";
        $thes {46} = "dirtily";
        $thes {47} = "shadily";
        $thes {48} = "rascally";
        $thes {49} = "scoundrelly";
        $thes {50} = "beastly";
        $thes {51} = "malfeasantly";
        $thes {52} = "egregiously";
        $thes {53} = "flagitiously";
        $thes {54} = "immorally";
        $thes {55} = "dastardly";
        my $x = int (rand (55));

        my $t = "<font color=darkred size=+3>muhahaha, the evil forces of CTHULHU have carried the day! ($reason_for_game_end)<br>";
        $t .= "These were the evil cultists who " . $thes {$x} . " delivered on their dark lord's Jira ticket: ";

        while ($i < scalar @player_cultist)
        {
            if ($player_cultist [$i])
            {
                $t .= $player_names [$i] . "<br>";
            }
            $i++;
        }
        $t .= "<\/font>";
        return $t;
    }

    my $t = "<font color=lightblue size=+3>Good guys won! ($reason_for_game_end)<br>";
    $t .= "These were the heroes not releasing directly to production..: ";
    while ($i < scalar @player_cultist)
    {
        if (!$player_cultist [$i])
        {
            $t .= $player_names [$i] . "<br>";
        }
        $i++;
    }
    $t .= "<\/font>";
    return $t;
}

sub do_shuffle
{
    @deck = shuffle (@deck);
}

my $DO_DEBUG = 0;
sub get_debug
{
    if ($DO_DEBUG)
    {
        return ("xxx $DEBUG yyy");
    }
    return "";
}

sub write_to_socket
{
    my $sock_ref = $_ [0];
    my $msg_body = $_ [1];
    my $form = $_ [2];
    my $redirect = $_ [3];
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime (time);
    my $yyyymmddhhmmss = sprintf "%.4d%.2d%.2d-%.2d%.2d%.2d", $year+1900, $mon+1, $mday, $hour,  $min, $sec;

    $msg_body = '<html><head><META HTTP-EQUIV="CACHE-CONTROL" CONTENT="NO-CACHE"><br></head><body>' . $form . $msg_body . get_debug() . "</body></html>";
    $msg_body =~ s/\n\n/\n/mig;
    $msg_body =~ s/\n\n/\n/mig;
    $msg_body =~ s/\n\n/\n/mig;
    $msg_body .= chr (13) . chr (10);
    #$msg_body =~ s/<img.*?src="(.*?)".*?>(.*?)<\/img>/$1 - $2/img;
    $msg_body =~ s/href="/href="\/forperl\//img;
    $msg_body =~ s/\/\//\//img;
    $msg_body =~ s/forperl.forperl/forperl/img;
    $msg_body =~ s/forperl.forperl/forperl/img;
    $msg_body =~ s/forperl.forperl/forperl/img;
    $msg_body =~ s/forperl.forperl/forperl/img;

    my $header;
    if ($redirect =~ m/^redirect/i)
    {
        $header = "HTTP/1.1 302 Moved\nLocation: \/forperl\/\nLast-Modified: $yyyymmddhhmmss\nConnection: close\nContent-Type: text/html; charset=UTF-8\nContent-Length: " . length ($msg_body) . "\n\n";
    }
    elsif ($redirect =~ m/^noredirect/i)
    {
        if ($CURRENT_CTHULHU_NAME ne "")
        {
            $header = "HTTP/1.1 200 OK\nLast-Modified: $yyyymmddhhmmss\nConnection: close\nContent-Type: text/html\nSet-Cookie: newcthulhuname=$CURRENT_CTHULHU_NAME\nContent-Length: " . length ($msg_body) . "\n\n";
        }
        else
        {
            $header = "HTTP/1.1 200 OK\nLast-Modified: $yyyymmddhhmmss\nConnection: close\nContent-Type: text/html\nContent-Length: " . length ($msg_body) . "\n\n";
        }
    }

    $msg_body = $header . $msg_body;

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
    my $min;
    my $max;
    my $msg_type;
    my $msg_body;
    my $msg_len;

    vec ($rin, fileno ($sock_ref), 1) = 1;

    while ((!(ord ($ch) == 13 and ord ($prev_ch) == 10)))
    {
        if (select ($rout=$rin, undef, undef, 200) == 1)
        {
            $prev_ch = $ch;
            if (sysread ($sock_ref, $ch, 1) < 1)
            {
                return "resend";
            }
            $header .= $ch;
            my $h = $header;
            $h =~ s/(.)/",$1-" . ord ($1) . ";"/emg;
        }
    }

    return $header;
}

sub get_player_IP
{
    my $id = $_ [0];
    if ($id < $num_players_in_game)
    {
        return $player_ips [$id];
    }
    return -1;
}

sub get_player_id
{
    my $IP = $_ [0];
    my $ip_find;
    my $i = 0;

    my $x = get_player_id_from_name ($CURRENT_CTHULHU_NAME);
    if ($x != -1)
    {
        return $x;
    }
    while ($i < $num_players_in_lobby)
    {
        if ($player_ips [$i] eq $IP)
        {
            return $i;
        }
        $i ++;
    }
    return -1;
}

sub setup_deck
{
    # Cards in deck currently..
    my $total_number_cards_in_deck = $COUNTS_OF_CARDS {$CTH} + $COUNTS_OF_CARDS {$NEC} + $COUNTS_OF_CARDS {$PRIV} + $COUNTS_OF_CARDS {$PARA} + $COUNTS_OF_CARDS {$PRESC} + $COUNTS_OF_CARDS {$MIR} + $COUNTS_OF_CARDS {$RRR} + $COUNTS_OF_CARDS {$RCK};
    my $offset = 0;
    my $i;
    my @new_deck;

    for ($i = 0; $i < $COUNTS_OF_CARDS {$CTH}; $i++)
    {
        $new_deck [$offset] = "$CTH";
        $offset++;
    }

    for ($i = 0; $i < $COUNTS_OF_CARDS {$NEC}; $i++)
    {
        $new_deck [$offset] = "$NEC";
        $offset++;
    }

    for ($i = 0; $i < $COUNTS_OF_CARDS {$PRIV}; $i++)
    {
        $new_deck [$offset] = "$PRIV";
        $offset++;
    }

    for ($i = 0; $i < $COUNTS_OF_CARDS {$PARA}; $i++)
    {
        $new_deck [$offset] = "$PARA";
        $offset++;
    }

    for ($i = 0; $i < $COUNTS_OF_CARDS {$PRESC}; $i++)
    {
        $new_deck [$offset] = "$PRESC";
        $offset++;
    }

    for ($i = 0; $i < $COUNTS_OF_CARDS {$MIR}; $i++)
    {
        $new_deck [$offset] = "$MIR";
        $offset++;
    }

    for ($i = 0; $i < $COUNTS_OF_CARDS {$RRR}; $i++)
    {
        $new_deck [$offset] = "$RRR";
        $offset++;
    }

    for ($i = 0; $i < $COUNTS_OF_CARDS {$RCK}; $i++)
    {
        $new_deck [$offset] = "$RCK";
        $offset++;
    }

    for ($i = 0; $i < $COUNTS_OF_CARDS {$INS}; $i++)
    {
        $new_deck [$offset] = "$INS";
        $offset++;
    }
    @deck = @new_deck;
    do_shuffle ();
}

sub get_player_name
{
    my $ID = $_ [0];
    return $player_names [$ID];
}

sub set_who_has_torch
{
    $pot_who_has_torch = $_ [0];

    if ($DONT_PASS_TORCH <= 1 && $NEXT_PICK_IS_PRESCIENT <= 1)
    {
        $who_has_torch = $pot_who_has_torch;
    }

    if ($NEXT_PICK_IS_PRESCIENT == 1)
    {
        $NEXT_PICK_IS_PRESCIENT = 2;
    }

    if ($DONT_PASS_TORCH == 1)
    {
        $DONT_PASS_TORCH = 2;
    }
}

sub get_character
{
    my $IP = $_ [0];
    my $id = get_player_id ($IP);
    if ($player_cultist [$id] == 1)
    {
        return $CULTIST_IMG;
    }
    elsif ($player_cultist [$id] == 2)
    {
        return $OBERON_IMG;
    }
    return $INVESTIGATOR_IMG;
}

sub get_player_id_from_name
{
    my $this_name = $_ [0];
    my $id = 0;
    for ($id = 0; $id < scalar @player_names; $id++)
    {
        if ($this_name eq $player_names [$id])
        {
            return $id;
        }
    }
    return -1;
}

sub get_player_name_from_IP
{
    my $IP = $_ [0];
    my $id = get_player_id ($IP);
    return $player_names [$id];
}

sub add_new_user
{
    my $in = $_ [0];
    my $IP = $_ [1];

    my $this_name = "";
    if ($in =~ m/name=([\w][\w][\w][\w_]+)_*$/)
    {
        $this_name = $1;
        $this_name =~ s/\W/_/g;
        $this_name =~ s/_*$//g;
        $this_name =~ s/HTTP.*//g;
        $IP .= "_$this_name";
        if ($this_name !~ m/..../)
        {
            return "";
        }
    }
    else
    {
        return "";
    }

    my $ip_find;
    foreach $ip_find (@player_ips)
    {
        if ($ip_find eq $IP)
        {
            return "";
        }
    }

    my $name_find;
    foreach $name_find (@player_names)
    {
        if ($name_find eq $this_name)
        {
            return "";
        }
    }

    {
        $player_names [$num_players_in_lobby] = $this_name;
        $player_ips [$num_players_in_lobby] = $IP;
        $NEEDS_REFRESH [$num_players_in_lobby] = 1;
        $NEEDS_ALERT [$num_players_in_lobby] = 0;
        $num_players_in_lobby++;

        my $col = sprintf ("#%lX%1X%1X", int (rand (200) + 55), int (rand (200) + 55), int (rand (200) + 55));
        $rand_colors {$this_name} = $col;
        return "Welcome $this_name";
    }
}

sub boot_person
{
    my $person_to_boot = $_ [0];
    my $person_to_boot_id = get_player_id_from_name ($person_to_boot);

    if ($person_to_boot_id == -1)
    {
        return;
    }

    if (game_started () == 1)
    {
        return;
    }

    my @new_player_ips;
    my $len = scalar @player_ips;
    my @new_player_names;
    my $i = 0;
    my $new_i = 0;

    while ($i < $len)
    {
        if ($i == $person_to_boot_id)
        {
            $BANNED_NAMES {$player_names [$i]} = 1;
            $i++;
            $num_players_in_lobby--;
            next;
        }
        $new_player_names [$new_i] = $player_names [$i];
        $new_player_ips [$new_i] = $player_ips [$i];

        $i++;
        $new_i++;
    }

    if ($num_players_in_lobby < 0)
    {
        $num_players_in_lobby = 0;
    }
    @player_names = @new_player_names;
    @player_ips = @new_player_ips;
    return "";
}

sub who_has_card
{
    my $card_id = $_ [0];
    my $player_id = 0;
    my $c = 0;
    my $cards_in_hand = $num_cards_per_player;

    while ($c < scalar @deck)
    {
        if ($c == $card_id)
        {
            return $player_id;
        }
        if ($cards_in_hand > 1)
        {
            $cards_in_hand--;
        }
        else
        {
            $player_id ++;
            $cards_in_hand = $num_cards_per_player;
        }
        $c++;
    }
    return $player_id;
}

sub reduce_cards_by_1
{
    $num_cards_per_player --;
    if ($num_cards_per_player < 2)
    {
        game_won ($BAD_GUYS, "Too many rounds");
    }
}

sub force_needs_refresh
{
    my $i = 0;
    my $reason = $_ [0];
    print (" FORCING REFRESH Called from $reason\n");
    for ($i = 0; $i < $num_players_in_lobby; $i++)
    {
        $NEEDS_REFRESH [$i] = 1;
        print (" FORCING REFRESH FOR $i - " . get_player_name ($i));
    }
}

sub force_needs_refresh_trigger
{
    my $i = 0;
    my $reason = $_ [0];
    for ($i = 0; $i < $num_players_in_lobby; $i++)
    {
        $NEEDS_REFRESH [$i] = 1;
    }
}

sub get_needs_refresh
{
    my $i = 0;
    my $IP = $_ [0];
    my $id = get_player_id ($IP);

    if ($NEEDS_REFRESH [$id])
    {
        $NEEDS_REFRESH [$id] = 0;
        return 1;
    }
    return 0;
}

sub pick_card
{
    my $in = $_ [0];
    my $IP = $_ [1];
    my $id = get_player_id ($IP);
    my $n = get_player_name ($id);
    if ($id != $who_has_torch)
    {
        return ("");
    }

    my $card_picked = "";
    my $DONT_EXPOSE_THIS_CARD = 0;

    if ($in =~ m/pick_card_(\d+)/)
    {
        $card_picked = $1;
        my $name_of_card_picked = $deck [$card_picked];
        $needs_shuffle_but_before_next_card_picked = 0;

        if ($NEXT_PICK_IS_PRESCIENT == 2)
        {
            $NEXT_PICK_IS_PRESCIENT = 0;
            $NOT_HIDDEN_INFO {"$card_picked faceup"} = 1;
            force_needs_refresh ();
            return;
        }

        if ($name_of_card_picked =~ m/.*ROCK.*/)
        {
            decrease_count ($RCK);
        }
        if ($name_of_card_picked =~ m/.*CTHU.*/)
        {
            decrease_count ($CTH);
            if ($num_players_in_game > $SMALL_GAME && $NECRO_PICKED)
            {
                game_won ($BAD_GUYS, "CTHULHU has arrived ($num_players_in_game necro was picked)");
            }

            if ($num_players_in_game <= $SMALL_GAME)
            {
                game_won ($BAD_GUYS, "CTHULHU has arrived ($num_players_in_game no necro needed)");
            }

            # All bad guys will know each other now - shuffle CTHULHU back in..
            if ($num_players_in_game > $SMALL_GAME && !$NECRO_PICKED)
            {
                # All bad guys know all bad guys..
                my $i = 0;
                my $j = 0;
                $DONT_EXPOSE_THIS_CARD = 1;
                for ($i = 0; $i < $num_players_in_game; $i++)
                {
                    for ($j = 0; $j < $num_players_in_game; $j++)
                    {
                        if ($player_cultist [$i] == 1 && $player_cultist [$j] == 1 && $i != $j)
                        {
                            $NOT_HIDDEN_INFO {"$i knows $j"} = 1;
                        }
                    }
                }

                # Put CTHULHU aside to be shuffled in later..
                increase_count ($CTH);
                my %new_exposed_cards;
                my $remove_cthulhu = 1;
                my $new_c = 0;
                my $c = 0;
                foreach $c (sort { $a <=> $b } keys %exposed_cards)
                {
                    my $str = uc($exposed_cards {$c});

                    if ($str =~ m/.*CTHULHU.*/img)
                    {
                        if ($remove_cthulhu)
                        {
                            $revealed_cards {$str . "_$c"}++;
                            $revealed_cards_imgs {$SMALL_CTHULHU}++;
                            $remove_cthulhu = 0;
                        }
                        else
                        {
                            $new_exposed_cards {$new_c} = $exposed_cards {$c};
                            $new_c ++;
                        }
                    }
                    else
                    {
                        $new_exposed_cards {$new_c} = $exposed_cards {$c};
                        $new_c ++;
                    }
                }
                %exposed_cards = %new_exposed_cards;
            }
        }
        if ($name_of_card_picked =~ m/.*INSANE.*/)
        {
            decrease_count ($INS);
        }
        if ($name_of_card_picked =~ m/.*RUNE.*/)
        {
            decrease_count ($RRR);
            $NUM_RUNES_PICKED ++;
            if ($num_players_in_game <= $SMALL_GAME && $NUM_RUNES_PICKED == ($num_players_in_game))
            {
                game_won ($GOOD_GUYS, "All runestones picked prior to cthulhu!");
            }
            if ($num_players_in_game > $SMALL_GAME && $NECRO_PICKED && $NUM_RUNES_PICKED == ($num_players_in_game - 1))
            {
                game_won ($GOOD_GUYS, "All rune stones and necro picked!");
            }
            if ($num_players_in_game > $SMALL_GAME && $MIRAGE_PICKED && !$NECRO_PICKED && $NUM_RUNES_PICKED == ($num_players_in_game - 1))
            {
                game_won ($BAD_GUYS, "Necro didn't come out first");
            }
        }
        if ($name_of_card_picked =~ m/.*NEC.*/)
        {
            decrease_count ($NEC);
            $NECRO_PICKED = 1;
            if ($MIRAGE_PICKED && $NUM_RUNES_PICKED == ($num_players_in_game - 1))
            {
                game_won ($BAD_GUYS, "All runestones picked and mirage already used");
            }
        }
        if ($name_of_card_picked =~ m/.*PRIV.*/im)
        {
            my $id_who_has_card = who_has_card ($card_picked);
            $NOT_HIDDEN_INFO {"$id knows $id_who_has_card"} = ($player_cultist [$id_who_has_card] >= 1);

            # Put PRIVATE_EYE aside to be shuffled in later..
            my %new_exposed_cards;
            my $remove_priv = 1;
            my $new_c = 0;
            my $c = 0;
            $DONT_EXPOSE_THIS_CARD = 1;
            foreach $c (sort { $a <=> $b } keys %exposed_cards)
            {
                my $str = uc($exposed_cards {$c});

                if ($str =~ m/.*PRIV.*/img)
                {
                    if ($remove_priv)
                    {
                        $revealed_cards {$str . "_$c"}++;
                        $revealed_cards_imgs {$SMALL_PRIVATE_EYE}++;
                        $remove_priv = 0;
                    }
                    else
                    {
                        $new_exposed_cards {$new_c} = $exposed_cards {$c};
                        $new_c ++;
                    }
                }
                else
                {
                    $new_exposed_cards {$new_c} = $exposed_cards {$c};
                    $new_c ++;
                }
            }
            %exposed_cards = %new_exposed_cards;
        }
        if ($name_of_card_picked =~ m/.*PARA.*/im)
        {
            decrease_count ($PARA);
            $DONT_PASS_TORCH = 1;
        }
        if ($name_of_card_picked =~ m/.*PRESC.*/im)
        {
            decrease_count ($PRESC);
            $NEXT_PICK_IS_PRESCIENT = 1;
        }
        if ($name_of_card_picked =~ m/.*MIR.*/)
        {
            decrease_count ($MIR);
            $MIRAGE_PICKED = 1;
            if ($NUM_RUNES_PICKED > 0)
            {
                # Put one RUNE back for shuffling in
                increase_count ($RRR);
                $NUM_RUNES_PICKED --;
                $NUM_EXPOSED_CARDS --;
                my %new_exposed_cards;
                my $remove_this_rune = 1;
                my $new_c = 0;
                my $c = 0;
                foreach $c (sort { $a <=> $b } keys %exposed_cards)
                {
                    my $str = uc($exposed_cards {$c});

                    if ($str =~ m/.*RUNE.*/)
                    {
                        if ($remove_this_rune)
                        {
                            $revealed_cards {$str . "_$c"}++;
                            $revealed_cards_imgs {$SMALL_RUNE}++;
                            $remove_this_rune = 0;
                        }
                        else
                        {
                            $new_exposed_cards {$new_c} = $exposed_cards {$c};
                            $new_c ++;
                        }
                    }
                    else
                    {
                        $new_exposed_cards {$new_c} = $exposed_cards {$c};
                        $new_c ++;
                    }
                }
                %exposed_cards = %new_exposed_cards;
            }
        }
    }

    force_needs_refresh ();

    # Update who picked card
    set_who_has_torch (who_has_card ($card_picked));

    $deck [$card_picked] .= "exposed";
    if ($deck [$card_picked] =~ m/.*PRIV.*/img)
    {
        $revealed_cards {$deck [$card_picked] . "_$card_picked"}++;
        $revealed_cards_imgs {$SMALL_PRIVATE_EYE}++;
    }
    elsif ($deck [$card_picked] =~ m/.*CTH.*/img && $DONT_EXPOSE_THIS_CARD)
    {
        $revealed_cards {$deck [$card_picked] . "_$card_picked"}++;
        $revealed_cards_imgs {$SMALL_CTHULHU}++;
    }
    else
    {
        $exposed_cards {$NUM_EXPOSED_CARDS} = $deck [$card_picked];
        $NUM_EXPOSED_CARDS ++;
    }

    # Shuffle the deck and farm out cards..
    if (start_of_new_round ())
    {
        $CHANGE_OF_ROUND = 1;
        $IP =~ s/(\d)$1$//;
        my %NEW_FACEUP_ORDER;
        %FACEUP_ORDER = %NEW_FACEUP_ORDER;

        # Setup the deck..
        setup_deck ();

        # Force a pass on the final card if necessary
        $DONT_PASS_TORCH = 0;

        my $knowledge;
        my %new_NOT_HIDDEN_INFO;
        foreach $knowledge (sort keys (%NOT_HIDDEN_INFO))
        {
            if ($knowledge !~ m/.*faceup.*/img)
            {
                $new_NOT_HIDDEN_INFO {$knowledge} = $NOT_HIDDEN_INFO {$knowledge};
            }
        }
        %NOT_HIDDEN_INFO = %new_NOT_HIDDEN_INFO;

        set_who_has_torch ($pot_who_has_torch);
        reduce_cards_by_1();
    }
}

sub decrease_count
{
    my $key = $_[0];
    $COUNTS_OF_CARDS {$key} --;
}

sub increase_count
{
    my $key = $_[0];
    $COUNTS_OF_CARDS {$key} ++;
}

sub get_num_cultists
{
    my $num_cultists = 3;
    if ($num_players_in_game <= $SMALL_GAME)
    {
        $num_cultists = int (rand (10));
        if ($num_cultists > 7)
        {
            $num_cultists = 2;
        }
        elsif ($num_cultists >= 2)
        {
            $num_cultists = 1;
        }
        else
        {
            $num_cultists = 0;
        }
    }
    elsif ($num_players_in_game <= $MED_GAME)
    {
        $num_cultists = int (rand (2) + 1);
        my $extra_cultist = int (rand ($num_players_in_game) + 1);
        if ($extra_cultist >= $SMALL_GAME)
        {
            $num_cultists++;
        }

        if ($num_cultists == 0)
        {
            $num_cultists = 1;
        }
        if ($num_cultists >= 3)
        {
            $num_cultists = 2;
        }
    }
    return $num_cultists;
}

sub new_game
{
    if ($num_players_in_game != -1)
    {
        return debug_game ();
    }
    if ($num_players_in_lobby == 0)
    {
        return debug_game ();
    }

    $num_players_in_game = $num_players_in_lobby;
    set_who_has_torch (int (rand ($num_players_in_game)));
    $NECRO_PICKED = 0;
    $NUM_RUNES_PICKED = 0;
    $MIRAGE_PICKED = 0;
    $GAME_WON = 0;
    $NUM_EXPOSED_CARDS = 0;
    $CHANGE_OF_ROUND = 0;


    my $num_cultists = get_num_cultists ();

    my $i;
    for ($i = 0; $i < $num_players_in_game; $i++)
    {
        $player_cultist [$i] = 0;
    }

    # May or may not be an oberon in the game..
    my $is_oberon = int (rand (4));

    for ($i = 0; $i < $num_cultists; $i++)
    {
        my $cultist = int (rand ($num_players_in_game+1));
        if ($player_cultist [$cultist] == 0)
        {
            $player_cultist [$cultist] = 1;
            if ($i == $is_oberon)
            {
                $player_cultist [$cultist] = 2;
            }
        }
        else
        {
            $i--;
        }
    }

    # Setup counts for cards in deck
    $COUNTS_OF_CARDS {$CTH} = 1;
    $COUNTS_OF_CARDS {$NEC} = 1;
    $COUNTS_OF_CARDS {$MIR} = 1;
    $COUNTS_OF_CARDS {$PRIV} = 1;
    $COUNTS_OF_CARDS {$PARA} = 1;
    $COUNTS_OF_CARDS {$PRESC} = 1;
    $COUNTS_OF_CARDS {$INS} = 1;
    $COUNTS_OF_CARDS {$RRR} = $num_players_in_game - 1;
    $COUNTS_OF_CARDS {$RCK} = 5 * $num_players_in_game - 7 - ($num_players_in_game - 1);

    if ($num_players_in_game <= $SMALL_GAME)
    {
        $COUNTS_OF_CARDS {$NEC} = 0;
        $COUNTS_OF_CARDS {$RRR} ++;
    }

    # Testing..
    if ($IN_DEBUG_MODE)
    {
        $COUNTS_OF_CARDS {$CTH} = 1;
        $COUNTS_OF_CARDS {$NEC} = 0;
        $COUNTS_OF_CARDS {$MIR} = 1;
        $COUNTS_OF_CARDS {$PRIV} = 1;
        $COUNTS_OF_CARDS {$INS} = 1;
        $COUNTS_OF_CARDS {$RRR} = 2;
        $COUNTS_OF_CARDS {$RCK} = 4;
    }

    # Setup the deck..
    setup_deck ();

    $num_cards_per_player = $NUM_CARDS_AT_START_OF_GAME;
    force_needs_refresh();
    my %new_already_shuffled;
    %already_shuffled = %new_already_shuffled;
    $needs_shuffle_but_before_next_card_picked = 0;
    $DONT_PASS_TORCH = 0;
    $NEXT_PICK_IS_PRESCIENT = 0;
    return;
}

sub reset_game
{
    $num_players_in_game = -1;
    $NECRO_PICKED = 0;
    $NUM_RUNES_PICKED = 0;
    $MIRAGE_PICKED = 0;
    $GAME_WON = 0;
    $NUM_EXPOSED_CARDS = 0;
    $CHANGE_OF_ROUND = 0;
    $reason_for_game_end = "";
    my %no_exposure;
    %exposed_cards = %no_exposure;
    my %no_revealed_cards;
    %revealed_cards = %no_revealed_cards;
    my %no_revealed_cards_strs;
    %revealed_cards_imgs = %no_revealed_cards_strs;
    $DONT_PASS_TORCH = 0;
    $NEXT_PICK_IS_PRESCIENT = 0;
    my @new_deck;
    @deck = @new_deck;
    my $out = "Game reset <a href=\"\/\">Lobby or Game window<\/a>";
    force_needs_refresh();
    my %new_already_shuffled;
    %already_shuffled = %new_already_shuffled;
    my %new_NOT_HIDDEN_INFO;
    %NOT_HIDDEN_INFO = %new_NOT_HIDDEN_INFO;
    $needs_shuffle_but_before_next_card_picked = 0;
    return $out;
}

sub in_game
{
    my $id = get_player_id_from_name ($CURRENT_CTHULHU_NAME);
    if ($id >= 0 && $id < $num_players_in_game)
    {
        return 1;
    }
    return 0;
}

sub player_row
{
    my $id = $_ [0];
    my $IP = $_ [1];
    my $this_player_id = get_player_id_from_name ($CURRENT_CTHULHU_NAME);

    my $known_to_user = -1;
    my $hidden_identity = "";
    if (defined ($NOT_HIDDEN_INFO {"$this_player_id knows $id"}))
    {
        $known_to_user = $NOT_HIDDEN_INFO {"$this_player_id knows $id"};
        $hidden_identity = $SMALL_INVESTIGATOR_IMG;
        if ($known_to_user)
        {
            $hidden_identity = $SMALL_CULTIST_IMG;
        }
    }

    my $torch_cell = "<td></td>";
    if ($id == $who_has_torch)
    {
        $torch_cell = "<td>$TORCH</td>";
    }
    my $name_cell = "<td><font size=+1 color=darkgreen>" . get_player_name ($id) . "</font>$hidden_identity</td>";
    if ($id == $this_player_id)
    {
        $name_cell = "<td>**<font size=+2 color=darkblue>" . get_player_name ($id) . "</font>**</td>";
    }

    my $start_bit = "";
    if ($id % 2 == 0)
    {
        $start_bit = "<tr>";
    }
    my $final_bit = "";
    if ($id % 2 == 1)
    {
        $final_bit = "</tr>";
    }
    my $out;
    $out .= "$start_bit$name_cell$torch_cell<td>" . get_facedown_hand ($IP, $id) . "</td>$final_bit\n";

    my $make_pickable = $this_player_id == $who_has_torch && $id != $this_player_id;
    if ($NEXT_PICK_IS_PRESCIENT == 2)
    {
        $make_pickable = $this_player_id == $who_has_torch;
    }

    if ($make_pickable)
    {
        $out =~ s/<img id=.card_(\d+)/<a href="\/pick_card_$1"><img id="card_$1/g;
        $out =~ s/<\/img>/<\/img><\/a>/g;
    }
    return $out;
}

sub get_board
{
    my $IP = $_ [0];
    my $id = get_player_id ($IP);
    if (!in_game ($IP))
    {
        return " NO BOARD TO SEE..";
    }

    my $out = "Facedown cards:<br>";
    $out .= player_row (0, $IP);
    if ($num_players_in_game >= 2) { $out .= player_row (1, $IP); }
    if ($num_players_in_game >= 3) { $out .= player_row (2, $IP); }
    if ($num_players_in_game >= 4) { $out .= player_row (3, $IP); }
    if ($num_players_in_game >= 5) { $out .= player_row (4, $IP); }
    if ($num_players_in_game >= 6) { $out .= player_row (5, $IP); }
    if ($num_players_in_game >= 7) { $out .= player_row (6, $IP); }
    if ($num_players_in_game >= 8) { $out .= player_row (7, $IP); }
    if ($num_players_in_game >= 9) { $out .= player_row (8, $IP); }
    $out .= "</tr></table>";
    $out =~ s/<\/tr><\/tr>/<\/tr>/img;

    return $out;
}

sub get_facedown_hand
{
    my $IP = $_ [0];
    my $id = $_ [1];
    if (!in_game ($IP))
    {
        return "";
    }

    my $c = 0;
    my $hand = "";

    while ($c < $num_cards_per_player)
    {
        if ($deck [$id * $num_cards_per_player + $c] !~ m/$EXPOSED/im)
        {
            my $actual_deck_id = $id * $num_cards_per_player + $c;

            if (!defined ($NOT_HIDDEN_INFO {"$actual_deck_id faceup"}))
            {
                my $b = $BACK;
                $b =~ s/xxx/card_$actual_deck_id/;
                $hand .= $b;
                if ($SHOW_CARDS_MODE)
                {
                    $hand .= "(" . $deck [$actual_deck_id] . ")";
                }
            }
            elsif (defined ($NOT_HIDDEN_INFO {"$actual_deck_id faceup"}))
            {

                my $h = get_faceup_image ($actual_deck_id);
                $h =~ s/xxx/card_$actual_deck_id/;
                $hand .= $h;
            }
        }

        $c++;
    }
    return $hand;
}

sub get_exposed
{
    my $IP = $_ [0];
    if (!in_game ($IP))
    {
        return "";
    }
    my $c = 0;
    my $cardstr = join (",", sort values(%exposed_cards));
    $cardstr =~ s/exposed//img;
    my $revealed_cardstr = join (",", sort keys(%revealed_cards));
    my $revealed_cardstr_imgs = join (",", sort keys(%revealed_cards_imgs));
    $revealed_cardstr =~ s/exposed//img;
    my $exposed = "<br>These cards have been turned up: $cardstr. These cards been revealed this round but put aside: $revealed_cardstr_imgs.<br>";

    my $c;
    my $num = 0;
    my $list_of_cards;
    foreach $c (sort { $a <=> $b } keys %exposed_cards)
    {
        my $str = uc($exposed_cards {$c});
        $list_of_cards .= $str . ",";

        if ($str =~ m/.*ROCK.*/)
        {
            $exposed .= $ROCK;
        }
        if ($str =~ m/.*CTHU.*/)
        {
            $exposed .= $CTHULHU;
        }
        if ($str =~ m/.*RUNE.*/)
        {
            $exposed .= $RUNE;
        }
        if ($str =~ m/.*NEC.*/)
        {
            $exposed .= $NECRO;
        }
        if ($str =~ m/.*PRIV.*EYE.*/img)
        {
            $exposed .= $PRIVATE_EYE;
        }
        if ($str =~ m/.*PRES.*VIS.*/img)
        {
            $exposed .= $PRESCIENT_VISION;
        }
         if ($str =~ m/.*PARANOIA.*/img)
        {
            $exposed .= $PARANOIA ;
        }

        if ($str =~ m/.*MIR.*/)
        {
            $exposed .= $MIRAGE;
        }
        if ($str =~ m/.*INS.*/img)
        {
            $exposed .= $INSANE;
        }

        $num++;
        if (($num % $num_players_in_game) == 0 && $num > 0)
        {
            $exposed .= "<br>";
        }
    }
    $exposed =~ s/80/100/img;
    $exposed =~ s/131/157/img;
    return $exposed;
}

sub get_faceup_image
{
    my $id = $_ [0];
    if ($deck [$id] =~ m/$RCK/im)
    {
        return $ROCK;
    }
    if ($deck [$id] =~ m/$CTH/im)
    {
        return $CTHULHU;
    }
    if ($deck [$id] =~ m/$RRR/im)
    {
        return $RUNE;
    }
    if ($deck [$id] =~ m/$NEC/im)
    {
        return $NECRO;
    }
    if ($deck [$id] =~ m/$PRIV/im)
    {
        return $PRIVATE_EYE;
    }
    if ($deck [$id] =~ m/$PARA/im)
    {
        return $PARANOIA;
    }
    if ($deck [$id] =~ m/$PRESC/im)
    {
        return $PRESCIENT_VISION;
    }

    if ($deck [$id] =~ m/$MIR/im)
    {
        return $MIRAGE;
    }
    if ($deck [$id] =~ m/$INS/im)
    {
        return $INSANE;
    }
}

sub get_faceup_hand
{
    my $IP = $_ [0];
    my $id = get_player_id ($IP);
    if (!in_game ($IP))
    {
        return "";
    }
    my $c = 0;
    my $hand = "";

    my @rand_ord;
    while ($c < $num_cards_per_player)
    {
        $rand_ord [$c] = $c;
        $c++;
    }
    @rand_ord = shuffle (@rand_ord);
    if (!defined ($FACEUP_ORDER {$id}))
    {
        $FACEUP_ORDER {$id} = join (",", @rand_ord);
    }
    else
    {
        my $rand_ord = $FACEUP_ORDER {$id};
        my $i = 0;
        while ($rand_ord =~ s/^(\d+),//)
        {
            $rand_ord [$i] = $1;
            $i++;
        }
    }

    $c = 0;
    my $c2;
    while ($c < $num_cards_per_player)
    {
        $c2 = $rand_ord [$c];
        if ($deck [$id * $num_cards_per_player + $c2] =~ m/$EXPOSED/im)
        {
            $c++;
            next;
        }
        $hand .= get_faceup_image ($id * $num_cards_per_player + $c2);
        $c++;
    }
    return $hand;
}

sub start_of_new_round
{
   if (($NUM_EXPOSED_CARDS % $num_players_in_game) == 0 && $NUM_EXPOSED_CARDS > 0 && (!defined ($already_shuffled {$NUM_EXPOSED_CARDS})))
    {
        $already_shuffled {$NUM_EXPOSED_CARDS} = 1;
        $needs_shuffle_but_before_next_card_picked = 1;
        return 1;
    }

    if ($needs_shuffle_but_before_next_card_picked)
    {
        return 1;
    }
    return 0;
}

sub print_game_state
{
    my $IP = $_ [0];
    if (in_game ($IP) == 0)
    {
        return "";
    }

    my $out = "You are in the game! (Total players=$num_players_in_game)<br>";

    if (get_game_won () ne "")
    {
        $out .= get_game_won ();
    }

    $out .= "<style>table.blueTable { border: 1px solid #1C6EA4; background-color: #ABE6EE; width: 100%; text-align: left; border-collapse: collapse; }\n table.blueTable td, table.blueTable th { border: 1px solid #AAAAAA; padding: 3px 2px; }\n table.blueTable tbody td { font-size: 13px; }\n table.blueTable tr:nth-child(even)\n { background: #D0E4F5; }\n table.blueTable tfoot td { font-size: 14px; }\n table.blueTable tfoot .links { text-align: right; }\n\n<br></style>\n";
    $out .= "\n<table class=blueTable>\n";
    $out .= get_character ($IP) . get_faceup_hand ($IP) . "<br>";

    if (start_of_new_round ())
    {
        $out .= "<br><font size=+2 color=darkblue> Cards were shuffled/redealt as $NUM_EXPOSED_CARDS got turned up.<br>Stop and say what you have in order from " . get_player_name ($who_has_torch) . " </font>\n";
        my %no_revealed_cards;
        %revealed_cards = %no_revealed_cards;
        my %no_revealed_cards_imgs;
        %revealed_cards_imgs = %no_revealed_cards_imgs;
        if ($CHANGE_OF_ROUND == 0)
        {
            $CHANGE_OF_ROUND = 1;
            force_needs_refresh_trigger ("PRINT_GAME_STATE");
        }
    }

    my $id = get_player_id ($IP);
    if ($id == $who_has_torch)
    {
        $out .= "";
    }

    $out .= get_exposed ($IP) . "<br>";
    $out .= get_board ($IP) . "<br>";

    if (start_of_new_round () && $id == $who_has_torch)
    {
        $out .= "<script>alert (\"You are now at the start of the next round as $NUM_EXPOSED_CARDS cards were turned up.  Stop and go around and say what your new hands are!\"); <\/script>\n";
    }
    return $out;
}

sub game_started
{
    return $num_players_in_game > -1;
}

sub get_refresh_code
{
    my $do_refresh = $_ [0];
    my $bb = $_ [1];
    my $bb2 = $_ [2];
    my $name = get_player_name ($bb);
    my $txt = "";

    if (!game_started ())
    {
        $do_refresh = 1;
    }

    $txt .= "<div id='countdown'></div>" . "\n";
    $txt .= "<script>" . "\n";
    $txt .= "var HttpClient = function() {\n";
    $txt .= "   this.get = function(aUrl, aCallback) {\n";
    $txt .= "       var anHttpRequest = new XMLHttpRequest();\n";
    $txt .= "       anHttpRequest.onreadystatechange = function() { \n";
    $txt .= "           if (anHttpRequest.readyState == 3 && anHttpRequest.status == 200)\n";
    $txt .= "               aCallback(anHttpRequest.responseText);\n";
    $txt .= "       }\n";
    $txt .= "       anHttpRequest.open( \"GET\", aUrl, true );            \n";
    $txt .= "       anHttpRequest.send( null );\n";
    $txt .= "   }\n";
    $txt .= "}\n";
    $txt .= "    var doRefresh = " . $do_refresh . ";\n";
    $txt .= "    var numseconds = 2;" . "\n";
    $txt .= "    function countdownTimer() {" . "\n";
    $txt .= "        if (numseconds > 0)" . "\n";
    $txt .= "        {" . "\n";
    $txt .= "            if (doRefresh)" . "\n";
    $txt .= "            {" . "\n";
    $txt .= "                numseconds --;" . "\n";
    $txt .= "            }" . "\n";
    $txt .= "        }" . "\n";
    $txt .= "        else" . "\n";
    $txt .= "        {" . "\n";
    $txt .= "            var client = new HttpClient();\n";
    $txt .= "            numseconds = 2;\n";
    $txt .= "            client.get('/forperl/needs_refresh', function(response) {\n";
    $txt .= "                    var str = response;\n";
    $txt .= "                    var match = str.match(/.*NEEDS_REFRESH.*/i);\n";
    $txt .= "                    numseconds = 2;\n";
    $txt .= "                    if (match != null && match.length > 0) {";
    $txt .= "                        location.reload();" . "\n\n";
    $txt .= "                    }";
    $txt .= "            });\n";
    $txt .= "        }" . "\n";
    $txt .= "        document.getElementById('countdown').innerHTML = '<font color=white>Refreshing page in:' + numseconds + '</font>';" . "\n";
    $txt .= "    }" . "\n";
    $txt .= "    countdownTimer();" . "\n";
    $txt .= "    setInterval(countdownTimer, 1000);" . "\n";
    $txt .= "    function setCookie(cname, cvalue, exdays) {\n";
    $txt .= "      const d = new Date();\n";
    $txt .= "      d.setTime(d.getTime() + (exdays * 24 * 60 * 60 * 1000));\n";
    $txt .= "      let expires = \"expires=\"+d.toUTCString();\n";
    $txt .= "      document.cookie = cname + \"=\" + cvalue + \";\" + expires + \";path=\/\";\n";
    $txt .= "    }\n";
    $txt .= "    setCookie(\"newcthulhuname\", \"" . $CURRENT_CTHULHU_NAME . "\", 0.05);\n";
    $txt .= "    function getCookie(cname) {\n";
    $txt .= "      let name = cname + \"=\";\n";
    $txt .= "      let decodedCookie = decodeURIComponent(document.cookie);\n";
    $txt .= "      let ca = decodedCookie.split(';');\n";
    $txt .= "      for(let i = 0; i < ca.length; i++) {\n";
    $txt .= "        let c = ca[i];\n";
    $txt .= "        while (c.charAt(0) == ' ') {\n";
    $txt .= "          c = c.substring(1);\n";
    $txt .= "        }\n";
    $txt .= "        if (c.indexOf(name) == 0) {\n";
    $txt .= "          return c.substring(name.length, c.length);\n";
    $txt .= "        }\n";
    $txt .= "      }\n";
    $txt .= "      return \"\";\n";
    $txt .= "    }\n";
    $txt .= "<\/script>" . "\n";
    $txt .= "<a href=\"\/forperl\/force_refresh\">Force Refresh<\/a><br>";

    return $txt;
}

sub get_chat_code
{
    my $out = "<form action=\"/forperl/add_chat_message\"><input size=80 type=\"text\" id=\"msg\" name=\"msg\" value=\"Put a message in here for chat\"><br><input type=\"submit\" value=\"Send Message!!\"></form>";
    $out .= "&nbsp;Precanned chat messages: <font size=-1><a href=\"/forperl/add_chat_message_msg=I have passed the torch\">Torch</a>";
    $out .= "&nbsp;&nbsp;<a href=\"/forperl/add_chat_message_msg=I have the torch\">Have the torch</a>";
    $out .= "&nbsp;&nbsp;<a href=\"/forperl/add_chat_message_msg=All rocks..\">Rocks</a>";
    $out .= "&nbsp;&nbsp;<a href=\"/forperl/add_chat_message_msg=Insane\">Insane</a>";
    $out .= "&nbsp;&nbsp;<a href=\"/forperl/add_chat_message_msg=Private eye\">Private eye</a>";
    $out .= "&nbsp;&nbsp;<a href=\"/forperl/add_chat_message_msg=Don't come to me\">Don't pick me!</a>";
    $out .= "&nbsp;&nbsp;<a href=\"/forperl/add_chat_message_msg=I have 3 runestones and no bad stuff\">...</a></font>";
    $out .= "<table>\n";

    my $i = $NUM_CHAT_MESSAGES - 1;
    my $total = 0;
    while ($total < 10 && defined ($CHAT_MESSAGES {$i}))
    {
        my $u = $CHAT_MESSAGES{$i};
        $u =~ s/^(.*)&nbsp;--.*/$1/;
        my $col = $rand_colors {$u};
        $out .= "<tr bgcolor=\"$col\"><td><font size=-1>$CHAT_MESSAGES{$i}</font></td></tr>\n";
        $i--;
        $total++;
    }
    $out .= "</table>\n";
    return $out;
}

sub add_chat_message
{
    my $msg = $_ [0];

    if ($CURRENT_CTHULHU_NAME =~ m/\w\w\w[\w_]+/)
    {
        my $orig_msg = $msg;
        $msg =~ s/%2F/\//img;
        $msg =~ s/%3A/:/img;
        $msg =~ s/%3F/?/img;
        $msg =~ s/%3D/=/img;
        force_needs_refresh ();

        $msg =~ s/%20/ /img;
        $msg =~ s/\+/ /img;
        $CHAT_MESSAGES {$NUM_CHAT_MESSAGES} = $CURRENT_CTHULHU_NAME . "&nbsp;--&nbsp;$msg";
        $NUM_CHAT_MESSAGES++;
    }
}

sub debug_game
{
    if (game_started () == 0)
    {
        return "Game not started <a href=\"\/\">Lobby or game window<\/a>";
    }
    my $out = print (join (",", @player_cultist));
    $out .= " <<>> ";
    $out .= join ("<br>", @deck);
    $out .= "<br>Game started! <a href=\"\/\">Lobby or game window<\/a>";
    return $out;
}

sub get_game_state
{
    my $IP = $_ [0];

    my $out .= "<h1>Welcome to Cthulhu, <font color=" . $rand_colors {$CURRENT_CTHULHU_NAME} . ">$CURRENT_CTHULHU_NAME</font> </h1><br><br>&nbsp;There are $num_players_in_lobby players logged in.<br>";
    $out .= "Player names are:<br>" . join ("<br>", @player_names);
    $out .= "<br><br><font size=-2>You can boot players here whilst the game is not started:</font><br>";

    my $n;
    foreach $n (sort @player_names)
    {
        $out .= "&nbsp;&nbsp;&nbsp;<font size=-2><a href=\"boot_person?name=$n\">Boot $n</a></font><br>";
    }

    if (scalar keys (%BANNED_NAMES) > 0)
    {
        $out .= "<br><font size=-2>These players are already banned (use a new user name if you're affected :) ) |" . join (",", sort keys (%BANNED_NAMES)) . "|</font><br>";
    }

    my $id = get_player_id_from_name ($CURRENT_CTHULHU_NAME);
    if ($id == -1)
    {
        $out .= "<font color=green size=+2>Join with a new game here:</font><br><br>";
        $out .= "
            <form action=\"/forperl/new_user\">
            <label for=\"fname\">User name:</label><br>
            <input type=\"text\" id=\"fname\" name=\"fname\" value=\"xyz\"><br>
            <input type=\"submit\" value=\"Join Now!!\">
            </form>";
        my $next_num = $num_players_in_lobby +1;
        $out =~ s/xyz/User$next_num/img;
    }
    else
    {
        $out .= "<font size=+1 color=red>Welcome to Cthulhu, " . get_player_name ($id) . "<br><\/font>";
        if (in_game ($IP))
        {
            $out = print_game_state ($IP);
            $out .= "Reset the game here: <a href=\"reset_game\">Reset<\/a><br><br><br>";
        }
        elsif (!game_started ())
        {
            $out .= "<a href=\"new_game\">Start new game!<\/a>";
        }
        else
        {
            $out .= "Game has already started!<br><br>";
            $out .= "*Reset and Restart* the game here: <a href=\"reset_game\">Reset<\/a><br><br><br>";
        }
    }

    my $do_refresh = 1;
    if ($id == $who_has_torch)
    {
        $do_refresh = 0;
    }
    $out .= get_refresh_code ($do_refresh, $id, $who_has_torch);
    $out .= get_chat_code ();
    $out .= "</td></tr></table>";
    return $out;
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
    my $port = 6728;
    my $trusted_client;
    my $data_from_client;
    $|=1;

    socket (SERVER, PF_INET, SOCK_STREAM, $proto) or die "Failed to create a socket: $!";
    setsockopt (SERVER, SOL_SOCKET, SO_REUSEADDR, 1) or die "setsocketopt: $!";

    # Bind to a port, then listen
    bind (SERVER, sockaddr_in ($port, INADDR_ANY)) or die "Can't bind to port $port! \n";
    listen (SERVER, 10) or die "listen: $!";
    print ("Listening on port: $port\n");
    my $count;
    my $not_seen_full = 1;

    print ("========================\n");

    while ($paddr = accept (CLIENT, SERVER))
    {
        print ("\n\nNEW============================================================\n");
        print ("- - - - - - -\n");

        ($client_port, $iaddr) = sockaddr_in ($paddr);
        $client_addr = inet_ntoa ($iaddr);
        $client_addr =~ s/\W//img;

        my $lat;
        my $long;
        my $txt = read_from_socket (\*CLIENT);

        $CURRENT_CTHULHU_NAME = "";
        if ($txt =~ m/^Cookie.*?newCTHULHUNAME=(\w\w\w[\w_]+).*?(;|$)/im)
        {
            $CURRENT_CTHULHU_NAME = $1;
        }

        if ($txt =~ m/fname=(\w\w\w[\w_]+) HTTP/im)
        {
            $CURRENT_CTHULHU_NAME = $1;
        }

        if (defined $BANNED_NAMES {$CURRENT_CTHULHU_NAME})
        {
            $CURRENT_CTHULHU_NAME = "";
        }

        $CURRENT_CTHULHU_NAME =~ s/^(...........).*/$1/img;

        if ($CURRENT_CTHULHU_NAME ne "" && get_player_id_from_name ($CURRENT_CTHULHU_NAME) == -1)
        {
            add_new_user ("name=$CURRENT_CTHULHU_NAME", $client_addr);
            write_to_socket (\*CLIENT, get_game_state($client_addr), "", "noredirect");
            next;
        }

        if ($txt =~ m/.*need.*refresh.*/m)
        {
            if (get_needs_refresh ($client_addr))
            {
                write_to_socket (\*CLIENT, "NEEDS_REFRESH", "", "noredirect");
                print ("$client_addr << needs_refresh!!\n");
                next;
            }
            write_to_socket (\*CLIENT, "FINE_FOR_NOW", "", "noredirect");
            next;
        }

        if ($txt =~ m/.*force.*refresh.*/m)
        {
            force_needs_refresh ();
        }

        if ($txt =~ m/GET[^\n]*?new_user/mi)
        {
            my $ret = add_new_user ($txt, $client_addr);
            if ($ret =~ m/^Welcome/)
            {
                write_to_socket (\*CLIENT, "Welcome!!<a href=\"\/\">Lobby or Game window<\/a>", "", "noredirect");
                next;
            }
            write_to_socket (\*CLIENT, "Welcome!!<a href=\"\/\">Lobby or Game window<\/a>", "", "noredirect");
            next;
        }

        if ($txt =~ m/.*pick.*card.*/mi)
        {
            pick_card ("$txt", $client_addr);
            my $page = get_game_state($client_addr);
            write_to_socket (\*CLIENT, "$page", "", "redirect");
            print ("\n\n\n\n\n\n$page\n\n");
            next;
        }

        if ($txt =~ m/.*boot.*person.*name=(\w\w\w[\w_]+)/mi)
        {
            my $person_to_boot = $1;
            boot_person ($person_to_boot);
            write_to_socket (\*CLIENT, "$person_to_boot was booted <a href=\"\/DONEDASBOOT\">Lobby or Game window<\/a>", "", "redirect");
            next;
        }

        if ($txt =~ m/GET.*new_game.*/m)
        {
            new_game ();
        }

        if ($txt =~ m/.*reset.*game.*/m)
        {
            write_to_socket (\*CLIENT, reset_game (), "", "redirect");
            next;
        }

        if ($txt =~ m/.*add_chat_message.msg=(....+).HTTP/im)
        {
            write_to_socket (\*CLIENT, add_chat_message ($1), "", "redirect");
            next;
        }

        print ("Read -> $txt\n");
        $txt =~ s/forperl.*forperl/forperl/img;

        print ("2- - - - - - -\n");
        write_to_socket (\*CLIENT, get_game_state($client_addr), "", "noredirect");

        print ("============================================================\n");
    }
}
