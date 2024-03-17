#!/usr/bin/perl
##
#   File : hearts.pl
#   Date : 16/Mar/2024
#   Author : spjspj
#   Purpose : Implement Hearts with bots!
#   Purpose : Requires having an Apache service setup (see conf file)
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

my $GAME = "Hearts";
my $GAME_URL = "hearts";
my $BCK = "back";
my $NUM_CARDS_IN_FULL_DECK = 52;
my $NUM_CARDS_TO_REMOVE = 8;
my $GAME_WON;
my $CURRENT_LOGIN_NAME = "";

my $ALL_SUITS_HDSC = "HDSC";
my $NON_HEART_SUITS_DSC = "DSC";
my $PATH = "d:\\perl_programs\\$GAME_URL";
my %rand_colors;

my $DEBUG = "";
my @player_names;
my @NEEDS_REFRESH;

my @deck;
my %player_cards;
my %player_won_cards;
my %player_score;

my %BANNED_NAMES;
my %PLAYER_IS_BOT;

my $whos_turn;
my $num_players_in_game = -1;
my @player_ips;
my $num_players_in_lobby = 0;

my $TOTAL_TRICKS = 13;
my $trick_number = 0;
my $must_lead_2c = 0;
my $hearts_broken = 0;
my $current_trick = "";
my $last_trick = "";
my $last_trick_led_by = "";
my $current_trick_card_count = 0;
my $current_trick_leading_card = "";
my $current_trick_led_by;
my $current_trick_suit = "";
my %current_trick_cards;

my $NOSUIT = "NOSUIT";
my $NOVALUE = "NOVALUE";

my $HEARTS = "H";
my $DIAMONDS = "D";
my $CLUBS = "C";
my $SPADES = "S";

my $last_trick_number = 0;
sub add_to_debug
{
    if ($trick_number > $last_trick_number)
    {
        #$DEBUG .= "<br>=====================================<br>\n";
        $last_trick_number = $trick_number;
    }
    $DEBUG .= "$trick_number (Trick=$current_trick: Who=$whos_turn) $_[0]<br>\n";
    print "$_[0]\n";
}

sub real_add_to_debug
{
    if ($trick_number > $last_trick_number)
    {
        $DEBUG .= "<br>=====================================<br>\n";
        $last_trick_number = $trick_number;
    }
    
    my $v = $_[0];
    $v =~ s/PLAY/&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;PLAY/;
    $v =~ s/has/&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;has/;
    $DEBUG .= "$trick_number (Trick=$current_trick: Who=$whos_turn) $v<br>\n";
    print "$_[0]\n";
}

sub reset_debug
{
    $DEBUG = "";
    add_to_debug ("reset debug");
}

sub game_won
{
    my $win_con = $_ [0];

    if ($GAME_WON == 0)
    {
        force_needs_refresh();
        $GAME_WON = $_ [0];
        add_to_debug (join ("<br>", @deck));
    }
}

sub get_game_won
{
    if ($GAME_WON == 0)
    {
        return "";
    }
    my $t = "Won..";
    return $t;
}

sub do_shuffle
{
    @deck = shuffle (@deck);
}

my $DO_DEBUG = 1;
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
    $msg_body =~ s/href="/href="\/$GAME_URL\//img;
    $msg_body =~ s/\/\//\//img;
    $msg_body =~ s/$GAME_URL.$GAME_URL/$GAME_URL/img;
    $msg_body =~ s/$GAME_URL.$GAME_URL/$GAME_URL/img;
    $msg_body =~ s/$GAME_URL.$GAME_URL/$GAME_URL/img;
    $msg_body =~ s/$GAME_URL.$GAME_URL/$GAME_URL/img;

    my $header;
    if ($redirect =~ m/^redirect/i)
    {
        $header = "HTTP/1.1 302 Moved\nLocation: \/$GAME_URL\/\nLast-Modified: $yyyymmddhhmmss\nConnection: close\nContent-Type: text/html; charset=UTF-8\nContent-Length: " . length ($msg_body) . "\n\n";
    }
    elsif ($redirect =~ m/^noredirect/i)
    {
        if ($CURRENT_LOGIN_NAME ne "")
        {
            $header = "HTTP/1.1 200 OK\nLast-Modified: $yyyymmddhhmmss\nConnection: close\nContent-Type: text/html\nSet-Cookie: newloginname=$CURRENT_LOGIN_NAME\nContent-Length: " . length ($msg_body) . "\n\n";
        }
        else
        {
            $header = "HTTP/1.1 200 OK\nLast-Modified: $yyyymmddhhmmss\nConnection: close\nContent-Type: text/html\nContent-Length: " . length ($msg_body) . "\n\n";
        }
    }

    $msg_body = $header . $msg_body;

    syswrite ($sock_ref, $msg_body);
}

sub old_bin_write_to_socket
{
    my $sock_ref = $_ [0];
    my $img = $_ [1];
    my $buffer;
    my $size = 0;

    if (-f $img)
    {
        $size = -s $img;
    }
    my $msg_body = "HTTP/2.0 200 OK\nDate: Mon, 20 May 2019 13:20:41 GMT\nConnection: close\nContent-type: image/jpeg\nContent-length: $size\n\n";
    syswrite ($sock_ref, $msg_body);

    open IMAGE, $img;
    binmode IMAGE;

    my $buffer;
    while (read (IMAGE, $buffer, 16384))
    {
        syswrite ($sock_ref, $buffer);
    }
}

my %ips_slowed_down_for;
my %images;
sub newer_bin_write_to_socket
{
    my $sock_ref = $_ [0];
    my $img = $_ [1];
    my $ip = $_ [4];

    my $buffer;
    my $size = 0;

    if (-f $img)
    {
        $size = -s $img;
    }
    my $img_type = $img;
    $img_type =~ s/.*\.//;
    my $msg_body = "HTTP/2 304 Not Modified\nContent-type: image/$img_type\nConnection: close\nContent-length: $size\nExpires: Sat, 16 Aug 2025 06:46:59 GMT\nLast-modified: Fri, 14 Aug 2020 06:48:59 GMT\nCache-control: public, max-age=31536000\n\n";

    my $buffer;
    my $len;

    if (!defined ($images {$img}))
    {
        $msg_body = "HTTP/2 200 OK\nContent-type: image/$img_type\nConnection: close\nContent-length: $size\nExpires: Sat, 16 Aug 2025 06:46:59 GMT\nLast-modified: Fri, 14 Aug 2020 06:48:59 GMT\nCache-control: public, max-age=31536000\n\n";
        open IMAGE, $img;
        binmode IMAGE;
        while ($len = read (IMAGE, $buffer, 10000))
        {
            $images {$img} .= $buffer;
        }
        $images {$img} .= $buffer;
        close IMAGE;
    }

    $ips_slowed_down_for {$ip} ++;
    if ($ips_slowed_down_for {$ip} < 10)
    {
        $msg_body = "HTTP/2 200 OK\nContent-type: image/$img_type\nConnection: close\nContent-length: $size\nExpires: Sat, 16 Aug 2025 06:46:59 GMT\nLast-modified: Fri, 14 Aug 2020 06:48:59 GMT\nCache-control: public, max-age=31536000\n\n";
    }
    else
    {
        #$msg_body = "HTTP/2 304 Not Modified\nContent-type: image/$img_type\nConnection: close\nContent-length: $size\nExpires: Sat, 16 Aug 2025 06:46:59 GMT\nLast-modified: Fri, 14 Aug 2020 06:48:59 GMT\nCache-control: public, max-age=31536000\n\n";
        $msg_body = "HTTP/2 200 OK\nContent-type: image/$img_type\nConnection: close\nContent-length: $size\nExpires: Sat, 16 Aug 2025 06:46:59 GMT\nLast-modified: Fri, 14 Aug 2020 06:48:59 GMT\nCache-control: public, max-age=31536000\n\n";
    }
    syswrite ($sock_ref, $msg_body);

    if (defined ($images {$img}))
    {
        syswrite ($sock_ref, $images {$img});
    }
}

sub experimental_bin_write_to_socket
{
    my $sock_ref = $_ [0];
    my $img = $_ [1];
    my $ip = $_ [4];

    my $buffer;
    my $size = 0;

    if (-f $img)
    {
        $size = -s $img;
    }
    my $img_type = $img;
    $img_type =~ s/.*\.//;
    my $msg_body = "HTTP/2 200 OK\nContent-type: image/$img_type\nContent-length: $size\nPragma: no-cache\n\n";

    my $buffer;
    my $len;

    if (!defined ($images {$img}))
    {
        #$msg_body = "HTTP/2 200 OK\nContent-type: image/$img_type\nPragma: no-cache\n\n";
        open IMAGE, $img;
        binmode IMAGE;
        while ($len = read (IMAGE, $buffer, 10000))
        {
            $images {$img} .= $buffer;
        }
        $images {$img} .= $buffer;
        close IMAGE;
    }

    $ips_slowed_down_for {$ip} ++;
    if ($ips_slowed_down_for {$ip} < 10)
    {
        #$msg_body = "HTTP/2 200 OK\nContent-type: image/$img_type\nPragma: no-cache\n\n";
    }
    else
    {
        #$msg_body = "HTTP/2 200 OK\nContent-type: image/$img_type\nPragma: no-cache\n\n";
    }
    syswrite ($sock_ref, $msg_body);

    if (defined ($images {$img}))
    {
        syswrite ($sock_ref, $images {$img});
        #syswrite ($sock_ref, $images {$img});
    }
}

sub bin_write_to_socket
{
    my $sock_ref = $_ [0];
    my $img = $_ [1];
    my $buffer;
    my $size = 0;

    if (-f $img)
    {
        $size = -s $img;
    }
    my $img_type = $img;
    $img_type =~ s/.*\.//;
    my $msg_body = "HTTP/2 304 Not Modified\ncontent-type: image/$img_type\nConnection: close\ncontent-length: $size\nexpires: Sat, 16 Aug 2025 06:46:59 GMT\nlast-modified: Fri, 14 Aug 2020 06:48:59 GMT\ncache-control: public, max-age=31536000\n\n";

    my $buffer;
    my $len;

    if (!defined ($images {$img}))
    {
        $msg_body = "HTTP/2 200 OK\ncontent-type: image/$img_type\nConnection: close\ncontent-length: $size\nexpires: Sat, 16 Aug 2025 06:46:59 GMT\nlast-modified: Fri, 14 Aug 2020 06:48:59 GMT\ncache-control: public, max-age=31536000\n\n";
        open IMAGE, $img;
        binmode IMAGE;
        while ($len = read (IMAGE, $buffer, 10000))
        {
            $images {$img} .= $buffer;
        }
        $images {$img} .= $buffer;
        close IMAGE;
    }
    $msg_body = "HTTP/2 200 OK\ncontent-type: image/$img_type\nConnection: close\ncontent-length: $size\nexpires: Sat, 16 Aug 2025 06:46:59 GMT\nlast-modified: Fri, 14 Aug 2020 06:48:59 GMT\ncache-control: public, max-age=31536000\n\n";
    syswrite ($sock_ref, $msg_body);

    if (defined ($images {$img}))
    {
        syswrite ($sock_ref, $images {$img});
    }
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

    # Read the message header
    while ((!(ord ($ch) == 13 and ord ($prev_ch) == 10)))
    {
        if (select ($rout=$rin, undef, undef, 200) == 1)
        {
            $prev_ch = $ch;
            # There is at least one byte ready to be read..
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

    my $x = get_player_id_from_name ($CURRENT_LOGIN_NAME, "aaa");
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
    my $total_number_cards_in_deck = $NUM_CARDS_IN_FULL_DECK;
    my %banned_cards;

    my $index = 0;
    my $str = "";
    my @new_deck;
    $new_deck [$index] = "2C"; $index++;
    $new_deck [$index] = "2D"; $index++;
    $new_deck [$index] = "2H"; $index++;
    $new_deck [$index] = "2S"; $index++;
    $new_deck [$index] = "3C"; $index++;
    $new_deck [$index] = "3D"; $index++;
    $new_deck [$index] = "3H"; $index++;
    $new_deck [$index] = "3S"; $index++;
    $new_deck [$index] = "4C"; $index++;
    $new_deck [$index] = "4D"; $index++;
    $new_deck [$index] = "4H"; $index++;
    $new_deck [$index] = "4S"; $index++;
    $new_deck [$index] = "5C"; $index++;
    $new_deck [$index] = "5D"; $index++;
    $new_deck [$index] = "5H"; $index++;
    $new_deck [$index] = "5S"; $index++;
    $new_deck [$index] = "6C"; $index++;
    $new_deck [$index] = "6D"; $index++;
    $new_deck [$index] = "6H"; $index++;
    $new_deck [$index] = "6S"; $index++;
    $new_deck [$index] = "7C"; $index++;
    $new_deck [$index] = "7D"; $index++;
    $new_deck [$index] = "7H"; $index++;
    $new_deck [$index] = "7S"; $index++;
    $new_deck [$index] = "8C"; $index++;
    $new_deck [$index] = "8D"; $index++;
    $new_deck [$index] = "8H"; $index++;
    $new_deck [$index] = "8S"; $index++;
    $new_deck [$index] = "9C"; $index++;
    $new_deck [$index] = "9D"; $index++;
    $new_deck [$index] = "9H"; $index++;
    $new_deck [$index] = "9S"; $index++;
    $new_deck [$index] = "10C"; $index++;
    $new_deck [$index] = "10D"; $index++;
    $new_deck [$index] = "10H"; $index++;
    $new_deck [$index] = "10S"; $index++;
    $new_deck [$index] = "JC"; $index++;
    $new_deck [$index] = "JD"; $index++;
    $new_deck [$index] = "JH"; $index++;
    $new_deck [$index] = "JS"; $index++;
    $new_deck [$index] = "QC"; $index++;
    $new_deck [$index] = "QD"; $index++;
    $new_deck [$index] = "QH"; $index++;
    $new_deck [$index] = "QS"; $index++;
    $new_deck [$index] = "KC"; $index++;
    $new_deck [$index] = "KD"; $index++;
    $new_deck [$index] = "KH"; $index++;
    $new_deck [$index] = "KS"; $index++;
    $new_deck [$index] = "AC"; $index++;
    $new_deck [$index] = "AD"; $index++;
    $new_deck [$index] = "AH"; $index++;
    $new_deck [$index] = "AS"; $index++;

    @deck = @new_deck;
    do_shuffle ();
    add_to_debug (join (",", @deck));
}

sub deal_deck
{
    $player_cards {0} = "";
    $player_cards {1} = "";
    $player_cards {2} = "";
    $player_cards {3} = "";

    $player_won_cards {0} = "";
    $player_won_cards {1} = "";
    $player_won_cards {2} = "";
    $player_won_cards {3} = "";

    my $cn = 0;
    while ($cn < $NUM_CARDS_IN_FULL_DECK)
    {
        $player_cards {$cn % 4} .= $deck [$cn] . ",";
        $cn++;
    }
}

sub get_player_name
{
    my $ID = $_ [0];
    return $player_names [$ID];
}

sub set_whos_turn
{
    my $initial = $_ [0];
    my $wt = $_ [1];

    # Player with 2C goes first..
    if ($initial)
    {
        if ($player_cards {0} =~ m/2C/) { $whos_turn = 0; }
        elsif ($player_cards {1} =~ m/2C/) { $whos_turn = 1; }
        elsif ($player_cards {2} =~ m/2C/) { $whos_turn = 2; }
        elsif ($player_cards {3} =~ m/2C/) { $whos_turn = 3; }
    }
    else 
    {
        $whos_turn = $wt;   
    }
    add_to_debug ("Setting who goes to $whos_turn\n");
}

sub get_player_id_from_name
{
    my $this_name = $_ [0];
    my $degg = $_ [1];
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

sub is_bot
{
    my $name = $_ [0];
    my $id = $_ [1];
    my $from = $_ [2];

    if ($name eq "")
    {
        $name = $player_names [$id];
    }

    if (defined ($PLAYER_IS_BOT {$name}) && ($PLAYER_IS_BOT {$name} == 1))
    {
        return 1;
    }
    return 0;
}

sub get_card_suit
{
    my $check_card = $_ [0];
    $check_card =~ s/,$//;
    $check_card =~ s/ $//;

    my $check_card_suit = 0;
    my $suit = "";
    if ($check_card =~ m/([$ALL_SUITS_HDSC])$/)
    {
        $suit = $1;
        return $suit;
    }

    add_to_debug ("Invalid Suit: >>$check_card<<");
    return $NOSUIT;
}

sub get_card_value
{
    my $check_card = $_ [0];

    if ($check_card =~ m/^([1-9]|10)/) { return $1; }
    if ($check_card =~ m/^J/)          { return 11; }
    if ($check_card =~ m/^Q/)          { return 12; }
    if ($check_card =~ m/^K/)          { return 13; }
    if ($check_card =~ m/^A/)          { return 14; }
    return $NOVALUE;
}

sub is_valid_card
{
    my $check_card = $_ [0];
    my $suit = get_card_suit ($check_card);
    my $card_val = get_card_value ($check_card);

    if (!($card_val ne $NOVALUE && $suit ne $NOSUIT))
    {
        add_to_debug ("INVALID CARD $check_card had suit of $suit and $card_val\n");
    }

    return $card_val ne $NOVALUE && $suit ne $NOSUIT;
}

sub beat_trick
{
    my $current_winning_card = $_ [0];
    my $this_card = $_ [1];

    if (get_card_suit ($current_winning_card) eq get_card_suit ($this_card))
    {
        if (get_card_value ($current_winning_card) < get_card_value ($this_card))
        {
            return 1;
        }
    }
    return 0;
}

sub play_card
{
    my $wt = $_ [0];
    my $card_played = $_ [1];
    my $cards = $player_cards {$wt};
    add_to_debug ("PLAY CARD ($wt) heartsborked=$hearts_broken ($current_trick_card_count)- card_played=$card_played; $wt player has $cards\n");

    if (!is_valid_card ($card_played))
    {
        add_to_debug ("INVALID CARD ($wt) - $card_played\n");
        return;
    }
    my $suit = get_card_suit ($card_played);

    if ($must_lead_2c && $cards !~ m/2C,/)
    {
        add_to_debug ("DOES NOT HAVE VALID 2C CARD ($wt) - $suit\n");
        return;
    }

    if ($must_lead_2c && $cards =~ m/2C,/)
    {
        $trick_number++;
        $current_trick_leading_card = $card_played;
        $current_trick_suit = get_card_suit ($current_trick_leading_card);
        $must_lead_2c = 0;
        $player_cards {$wt} =~ s/2C,//;
        $current_trick = "2C,";
        $current_trick_cards {$wt} = "2C,";
        add_to_debug ("ADDed TO current_trick $current_trick -- ($current_trick_card_count) >>$current_trick_cards{$wt}--$wt<<\n");
        $current_trick_led_by = $wt;
        $current_trick_card_count = 1; 
    }
    elsif ($cards =~ m/$card_played,/ && $current_trick_suit eq "")
    {
        $trick_number++;
        $current_trick_leading_card = $card_played;
        $current_trick_suit = get_card_suit ($current_trick_leading_card);
        $current_trick = "$card_played,";
        $current_trick_card_count = 1; 
        $player_cards {$wt} =~ s/$card_played,//;
        $current_trick_cards {$wt} = "$card_played,";
        $current_trick_led_by = $wt;
        add_to_debug ("ADDed TO current_trick $current_trick -- ($current_trick_card_count) >>$current_trick_cards{$wt}--$wt<<\n");
    }
    elsif ($cards =~ m/$card_played,/ && $current_trick_suit eq $suit)
    {
        $current_trick .= "$card_played,";
        $current_trick_card_count++;
        $player_cards {$wt} =~ s/$card_played,//;
        $current_trick_cards {$wt} = "$card_played,";
        add_to_debug ("ADDed TO current_trick $current_trick -- ($current_trick_card_count) >>$current_trick_cards{$wt}--$wt<<\n");
    }
    elsif ($cards =~ m/$card_played,/ && $current_trick_suit ne $suit)
    {
        $current_trick .= "$card_played,";
        $current_trick_card_count++;
        $player_cards {$wt} =~ s/$card_played,//;
        $current_trick_cards {$wt} = "$card_played,";
        add_to_debug ("ADDed TO current_trick (broke suit) $current_trick -- ($current_trick_card_count) >>$current_trick_cards{$wt}--$wt<<\n");
    }

    if (!$hearts_broken && get_card_suit ($card_played) eq $HEARTS)
    {
        $hearts_broken = 1;
    }

    if ($current_trick_card_count >= 4)
    {
        # Check who won the trick!
        my $current_winning_player = $current_trick_led_by;
        my $current_winning_card = $current_trick_leading_card;

        my $i = 0;
        for ($i = 0; $i < 4; $i++)
        {
            if (beat_trick ($current_winning_card, $current_trick_cards {$i}))
            {
                $current_winning_card = $current_trick_cards {$i};
                $current_winning_player = $i;
            }
        }
        $last_trick = "$current_trick_cards{0},$current_trick_cards{1},$current_trick_cards{2},$current_trick_cards{3},";
        $last_trick =~ s/,,/,/g;
        $last_trick_led_by = $current_trick_led_by;

        add_to_debug ("Player $current_winning_player won based on $current_trick_cards{0},$current_trick_cards{1},$current_trick_cards{2},$current_trick_cards{3}\n");
        $player_won_cards {$current_winning_player} .= ",$current_trick_cards{0},$current_trick_cards{1},$current_trick_cards{2},$current_trick_cards{3},";
        $player_won_cards {$current_winning_player} =~ s/,,/,/g;
        add_to_debug ("Player $current_winning_player has won based on <<< ($player_won_cards{$current_winning_player}) >>> $current_trick_cards{0},$current_trick_cards{1},$current_trick_cards{2},$current_trick_cards{3}\n");
        add_to_debug ("RESET Current_trick $current_trick back to blank -- ($current_trick_card_count)\n");
        $current_trick = "";
        $current_trick_card_count = 0;
        $current_trick_suit = "";
        set_whos_turn (0, $current_winning_player);
        handle_turn ();
        force_needs_refresh ();
    }
    else
    {
        set_next_turn ();
    }
}

sub player_has_suit
{
    my $wt = $_ [0];
    my $suit = $_ [1];
    my $cards = $player_cards {$wt}; 
    if ($cards =~ m/$suit,/)
    {
        return 1;
    }
    return 0;
}

sub player_has_card
{
    my $wt = $_ [0];
    my $card = $_ [1];
    my $cards = $player_cards {$wt}; 
    if ($cards =~ m/(^|,)$card,/)
    {
        return 1;
    }
    return 0;
}

sub get_first_card_of_suit
{
    my $wt = $_ [0];
    my $suit = $_ [1];
    my $cards = $player_cards {$wt}; 

    if ($cards =~ m/^([^,]+?$suit),/)
    {
        return $1;
    }
    if ($cards =~ m/,([^,]+?$suit),/)
    {
        return $1;
    }
    return "";
}

sub get_lowest_card
{
    my $wt = $_ [0];
    my $cards = $player_cards {$wt}; 
    my $lowest_card_val = 15;
    my $lowest_card;
    
    my $temp_cards = $cards;
    my $found_lowest_card = 0;

    if (!$hearts_broken && !(player_has_suit ($wt, $SPADES) || player_has_suit ($wt, $CLUBS) || player_has_suit ($wt, $DIAMONDS)))
    {
        $hearts_broken = 1;
    }

    while ($temp_cards =~ s/^([^,]+[$ALL_SUITS_HDSC]),//)
    {
        my $card = $1;
        my $this_card_val = get_card_value ($card); 
        my $this_card_suit = get_card_suit ($card); 
        if (!$hearts_broken && $this_card_suit eq $HEARTS)
        {
            next;
        }
        if ($lowest_card_val > $this_card_val)
        {
            $lowest_card_val = $this_card_val; 
            $lowest_card = $card;
            $found_lowest_card = 1;
        }
    }

    add_to_debug (" Lowest card is $lowest_card (for $wt with $cards and hearts_broken = $hearts_broken)..\n");
    return $lowest_card;
}

sub get_highest_card
{
    my $wt = $_ [0];
    my $cards = $player_cards {$wt}; 
    my $highest_card_val = -1;
    my $highest_card;
    
    my $temp_cards = $cards;

    while ($temp_cards =~ s/^([^,]+[$ALL_SUITS_HDSC]),//)
    {
        my $card = $1;
        my $this_card_val = get_card_value ($card); 
        my $this_card_suit = get_card_suit ($card); 
        #add_to_debug (" Testing $this_card_val from $card vs $highest_card_val (with $temp_cards temp)\n");
        if ($highest_card_val < $this_card_val)
        {
            $highest_card_val = $this_card_val; 
            $highest_card = $card;
        }
    }

    add_to_debug (" highest card is $highest_card (for $wt with $cards and hearts_broken = $hearts_broken)..\n");
    return $highest_card;
}

sub handle_bot_next_go
{
    my $wt = $_ [0];

    add_to_debug ("Handle bot $wt..\n");
    if ($must_lead_2c)
    {
        add_to_debug ("BOT LEAD 2C ($wt) -- $player_cards{$wt}..\n");
        if ($player_cards {$wt} =~ m/2C,/)
        {
            play_card ($wt, "2C");
            #add_to_debug ("MUST LEAD 2C ($wt) ccc..\n");
        }
    }
    else
    {
        add_to_debug ("BOT LEAD anything ($wt) -- $player_cards{$wt}..\n");
        if ($current_trick_suit eq "")
        {
            add_to_debug ("BOT LEAD anything ($wt) -- $player_cards{$wt} no current suit!\n");
            my $card = get_lowest_card ($wt);
            play_card ($wt, $card);
        }
        elsif (player_has_suit ($wt, $current_trick_suit))
        {
            add_to_debug ("BOT PLAYs of suit $current_trick_suit ($wt) -- $player_cards{$wt}!\n");
            play_card ($wt, get_first_card_of_suit ($wt, $current_trick_suit));
            #add_to_debug ("MUST FOLLOW ($wt, $current_trick_suit) = 0 ccc..\n");
        }
        else
        {
            add_to_debug ("BOT PLAYs anything ($wt) -- $player_cards{$wt} no current suit!\n");
            my $card = get_highest_card ($wt);
            play_card ($wt, $card);
        }
    }
}

sub handle_turn
{
    my $is_bot = is_bot ("", $whos_turn);
    if ($is_bot)
    {
        handle_bot_next_go ($whos_turn);
    }
}

sub set_next_turn
{
    add_to_debug ("Setting who goes from $whos_turn to " . ($whos_turn + 1));
    $whos_turn++;
    if ($whos_turn >= $num_players_in_game)
    {
        $whos_turn = 0;
    }
    handle_turn ();
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
    my $is_bot = $_ [2];

    my $this_name = "";
    if ($in =~ m/name=([\w][\w][\w][\w_ ]+)$/)
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
    print ("IN ADDING $this_name!!!\n");
    foreach $name_find (@player_names)
    {
        if ($name_find eq $this_name)
        {
            return "";
        }
    }

    print (" OK IN ADDING $this_name!!!\n");
    {
        $player_names [$num_players_in_lobby] = $this_name;
        $player_ips [$num_players_in_lobby] = $IP;
        $NEEDS_REFRESH [$num_players_in_lobby] = 1;
        $num_players_in_lobby++;
        add_to_debug ("ADDING NEW_USER ($this_name)..\n");

        my $col = sprintf ("#%lX%1X%1X", int (rand (200) + 55), int (rand (200) + 55), int (rand (200) + 55));
        $rand_colors {$this_name} = $col;
        $PLAYER_IS_BOT {$this_name} = 0;
        if ($is_bot)
        {
            $PLAYER_IS_BOT {$this_name} = 1;
        }
        return "Welcome $this_name";
    }
}

sub boot_person
{
    my $person_to_boot = $_ [0];
    my $person_to_boot_id = get_player_id_from_name ($person_to_boot, "bbbb");

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

    add_to_debug ("BOOT_PERSON $i, $len boot_person $person_to_boot ");
    while ($i < $len)
    {
        add_to_debug ("BOOT_PERSON in $i, $len boot_person $person_to_boot ");
        if ($i == $person_to_boot_id)
        {
            add_to_debug ("Booting this person BOOT_PERSON found in $i, $len boot_person $person_to_boot add $player_names[$i] to banned..");
            $BANNED_NAMES {$player_names [$i]} = 1;
            $i++;
            $num_players_in_lobby--;
            next;
        }
        add_to_debug ("Not booting this person BOOT_PERSON found in $new_i, $i, $len boot_person $person_to_boot ");
        $new_player_names [$new_i] = $player_names [$i];
        $new_player_ips [$new_i] = $player_ips [$i];

        $i++;
        $new_i++;
    }

    if ($num_players_in_lobby < 0)
    {
        $num_players_in_lobby = 0;
    }
    add_to_debug ("Before BOOT_PERSON ($person_to_boot) had names of: " . join (",", sort (@player_names)));
    add_to_debug ("Before BOOT_PERSON ($person_to_boot) had ips of: " . join (",", sort (@player_ips)));
    @player_names = @new_player_names;
    @player_ips = @new_player_ips;
    add_to_debug ("After BOOT_PERSON ($person_to_boot) had names of: " . join (",", sort (@player_names)));
    add_to_debug ("After BOOT_PERSON ($person_to_boot) had ips of: " . join (",", sort (@player_ips)));
    return "";
}

sub force_needs_refresh
{
    my $i = 0;
    for ($i = 0; $i < $num_players_in_lobby; $i++)
    {
        $NEEDS_REFRESH [$i] = 1;
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

sub new_game
{
    reset_debug ();
    $must_lead_2c  = 1;
    $trick_number = 0;
    $hearts_broken = 0;
    $current_trick = "";
    $last_trick = "";
    $current_trick_card_count = 0;
    $current_trick_leading_card = "";
    $current_trick_led_by = -1;
    $current_trick_suit = "";
    my %new_current_trick_cards;
    %current_trick_cards = %new_current_trick_cards;
    add_to_debug ("WTF - current_trick_cards reset\n");

    add_to_debug ("MUST LEAD 2C aaa..\n");
    if ($num_players_in_game != -1)
    {
        return debug_game ();
    }
    if ($num_players_in_lobby == 0)
    {
        return debug_game ();
    }
    if ($num_players_in_game > 4)
    {
        $num_players_in_game = 4;
    }

    if ($num_players_in_lobby < 4) { add_new_user ("name=Billy Bob Jr", "192.185.155.150", 1); }
    if ($num_players_in_lobby < 4) { add_new_user ("name=Gaius Julius Caesar", "192.185.155.150", 1); }
    if ($num_players_in_lobby < 4) { add_new_user ("name=Richard Feynman", "192.185.155.150", 1); }
    $num_players_in_game = $num_players_in_lobby;

    $GAME_WON = 0;

    # Setup the deck..
    add_to_debug ("Setup deck1\n");
    setup_deck ();
    $player_score {0} = 0;
    $player_score {1} = 0;
    $player_score {2} = 0;
    $player_score {3} = 0;
    deal_deck ();
    set_whos_turn (1, -1);

    add_to_debug ("Initial $whos_turn was set\n");
    my $is_bot = is_bot ("", $whos_turn);
    if ($is_bot)
    {
        add_to_debug ("Initial $whos_turn is a bot! handle_bot_next_go\n");
        handle_bot_next_go ($whos_turn);
    }

    $current_trick_suit = $CLUBS;
    
    force_needs_refresh();
    return;
}

sub reset_game
{
    $num_players_in_game = -1;
    $GAME_WON = 0;
    my @new_deck;
    @deck = @new_deck;
    my $out = "$GAME Game reset <a href=\"\/\">Lobby or Game window<\/a>";
    force_needs_refresh();

    add_to_debug ("Setup deck2\n");
    setup_deck ();
    $player_score {0} = 0;
    $player_score {1} = 0;
    $player_score {2} = 0;
    $player_score {3} = 0;
    deal_deck ();
    $must_lead_2c  = 1;
    $current_trick_card_count = 0;
    return $out;
}

sub in_game
{
    my $id = get_player_id_from_name ($CURRENT_LOGIN_NAME, "ccc");
    if ($id >= 0 && $id < $num_players_in_game)
    {
        return 1;
    }
    return 0;
}

sub is_card_valid_for_trick
{
    my $card = $_ [0];
    my $player_num = $_ [1];

    if (!is_valid_card ($card))
    {
        return 0;
    }
    my $suit = get_card_suit ($card);

    if ($must_lead_2c)
    {
        if ($card eq "2C")
        {
            return 1;
        }
    }
    else
    {
        if ($current_trick_suit eq "" && $hearts_broken)
        {
            #add_to_debug ("is_card_valid_for_trick aa $card $player_num >$current_trick_suit< ");
            return 1;
        }

        if ($current_trick_suit eq "" && !$hearts_broken && $suit ne $HEARTS)
        {
            #add_to_debug ("is_card_valid_for_trick bb $card $player_num >$current_trick_suit< ");
            return 1;
        }

        if ($current_trick_suit eq $suit)
        {
            #add_to_debug ("is_card_valid_for_trick cc $card $player_num >$current_trick_suit< ");
            return 1;
        }

        if (get_first_card_of_suit ($player_num, $current_trick_suit) eq "")
        {
            return 1;
        }

        if ($trick_number == 0 && ($suit eq $HEARTS || $card eq "QS"))
        {
            return 0;
        }
    }
    #add_to_debug ("  >>> NOT is_card_valid_for_trick $card $player_num >$current_trick_suit< ");
    return 0;
}

sub get_images_from_cards
{
    my $cards = $_ [0];
    my $id = $_ [1];
    my $full_size = $_ [2];
    my $known_to_user = $_ [3];
    my $sort_cards = $_ [4];
    my $make_urls = $_ [5];

    $cards =~ s/^,*//;
    my %cards;
    while ($cards =~ s/^(\w+),//)
    {
        my $c = $1;
        my $adder = 100;
        if ($c =~ m/C/) { $adder = 100; }
        if ($c =~ m/S/) { $adder = 200; }
        if ($c =~ m/D/) { $adder = 300; }
        if ($c =~ m/H/) { $adder = 400; }

        if ($c =~ m/(\d+)/) { $adder += $1; }
        if ($c =~ m/J/) { $adder += 11; }
        if ($c =~ m/Q/) { $adder += 12; }
        if ($c =~ m/K/) { $adder += 13; }
        if ($c =~ m/A/) { $adder += 14; }

        if (!$sort_cards)
        {
            $adder = 0;
        }

        if ($known_to_user)
        {
            my $is_valid_card = is_card_valid_for_trick ($c, $id);
            my $a_pre = "";
            my $a_post = "";
            if ($is_valid_card && $make_urls)
            {
                $a_pre = "<a href=\"chosen_card_$id.$c\">";
                $a_post = "<\/a>";
            }
            
            if ($full_size)
            {
                $cards {"$adder$c"} = $a_pre . "<img width=\"60\" height=\"86\" src=\"hearts/card$c.jpg\"><\/img>" . $a_post;
            }
            else
            {
                $cards {"$adder$c"} = $a_pre . "<img width=\"30\" height=\"43\" src=\"hearts/card$c.jpg\"><\/img>" . $a_post;
            }
        }
        else
        {
            if ($full_size)
            {
                $cards {"$adder$c"} = "<img width=\"60\" height=\"86\" src=\"hearts/$BCK.jpg\"><\/img>";
            }
            else
            {
                $cards {"$adder$c"} = "<img width=\"30\" height=\"43\" src=\"hearts/$BCK.jpg\"><\/img>";
            }
        }
    }

    my $actual_card_cell = "<td>";
    my $k;
    for $k (sort (keys %cards))
    {
        $actual_card_cell .= $cards {$k};
    }
    return $actual_card_cell;
}

sub player_row
{
    my $id = $_ [0];
    my $IP = $_ [1];
    my $this_player_id = get_player_id_from_name ($CURRENT_LOGIN_NAME, "ddd");

    my $known_to_user = 0;
    my $who_has_card_cell = "<td></td>";

    my $this_players_turn = "";
    if ($id == $whos_turn)
    {
        $this_players_turn = " #This turn#";
    }
    
    my $name_cell = "<td><font size= color=darkgreen>" . get_player_name ($id) . "(" . $player_score {$id} . " Score) $this_players_turn</font></td>";
    if ($id == $this_player_id)
    {
        $name_cell = "<td>**<font size=+1 color=darkblue>" . get_player_name ($id) . "**</font> (" . $player_score {$id} . " Score) $this_players_turn</td>";
        $known_to_user = 1;
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

    my $cards = $player_cards {$id};
    my $score = $player_score {$id};
    my $cards_in_hand_cell = get_images_from_cards ($cards, $id, 0, $known_to_user, 1, $known_to_user);
    $cards_in_hand_cell .= " (Score = $score)";
    $cards_in_hand_cell .= "</td>";

    $out .= "$start_bit$name_cell$cards_in_hand_cell$who_has_card_cell<td>" . "</td>$final_bit\n";

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

    my $out;
    $out .= player_row (0, $IP);
    $out .= player_row (1, $IP);
    $out .= player_row (2, $IP);
    $out .= player_row (3, $IP);
    $out .= "</tr></table>";
    if ($last_trick =~ m/...../)
    {
        $out .= "Last Trick:&nbsp;" . get_images_from_cards ($last_trick, $id, 0, 1, 0, 0) . " Led by: " . get_player_name ($last_trick_led_by) . "<br>";
    }

    $out .= get_images_from_cards ($current_trick, $id, 1, 1, 0, 0);
    $out =~ s/<\/tr><\/tr>/<\/tr>/img;
    return $out;
}

sub get_faceup_image
{
    my $id = $_ [0];
}

sub print_game_state
{
    my $IP = $_ [0];
    if (in_game ($IP) == 0)
    {
        return "";
    }

    my $out = "You are in the $GAME game! (Total players=$num_players_in_game)<br>";

    if (get_game_won () ne "")
    {
        $out .= get_game_won ();
    }

    $out .= "<style>table.blueTable { border: 1px solid #1C6EA4; background-color: #ABE6EE; width: 100%; text-align: left; border-collapse: collapse; }\n table.blueTable td, table.blueTable th { border: 1px solid #AAAAAA; padding: 3px 2px; }\n table.blueTable tbody td { font-size: 13px; }\n table.blueTable tr:nth-child(even)\n { background: #D0E4F5; }\n table.blueTable tfoot td { font-size: 14px; }\n table.blueTable tfoot .links { text-align: right; }\n\n<br></style>\n";
    $out .= "\n<table class=blueTable>\n";

    my $id = get_player_id ($IP);
    if ($id == $whos_turn)
    {
        $out .= "<b>YOUR TURN!!</b>";
        if ($player_score {$id} > 0)
        {
            $out .= "&nbsp;&nbsp;";
        }
        $out .= "&nbsp;&nbsp;<br>";
    }

    $out .= get_board ($IP) . "<br>";

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
    $txt .= "            client.get('/$GAME_URL/needs_refresh', function(response) {\n";
    $txt .= "                    var str = response;\n";
    $txt .= "                    var match = str.match(/.*NEEDS_REFRESH.*/i);\n";
    $txt .= "                    numseconds = 2;\n";
    $txt .= "                    if (match != null && match.length > 0) {";
    $txt .= "                        location.reload();" . "\n\n";
    $txt .= "                    }";
    #$txt .= "                    document.getElementById('countdown').innerHTML = response;" . "\n\n";
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
    $txt .= "    setCookie(\"newloginname\", \"" . $CURRENT_LOGIN_NAME . "\", 0.05);\n";
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
    $txt .= "<a href=\"\/$GAME_URL\/force_refresh\">Force Refresh<\/a><br>";
    return $txt;
}

sub debug_game
{
    return "";
}

sub get_game_state
{
    my $IP = $_ [0];

    my $out .= "<h1>Welcome to \"$GAME!\", <font color=" . $rand_colors {$CURRENT_LOGIN_NAME} . ">$CURRENT_LOGIN_NAME</font> </h1><br><br>&nbsp;There are $num_players_in_lobby players logged in.<br>";
    $out .= "Player names are:<br>" . join ("<br>", @player_names); # . "<br>IPs:<br>" . join ("<br>", @player_ips);
    $out .= "<br><br><font size=-2>You can boot players here whilst the game is not started:</font><br>";
    print ("Get game state\n");

    my $n;
    my %pns;
    foreach $n (sort @player_names)
    {
        $out .= "&nbsp;&nbsp;&nbsp;<font size=-2><a href=\"boot_person?name=$n\">Boot $n</a></font><br>";
        $pns {$n} = 1;
    }

    if (scalar keys (%BANNED_NAMES) > 0)
    {
        $out .= "<br><font size=-2>These players are already banned (use a new user name if you're affected :) ) |" . join (",", sort keys (%BANNED_NAMES)) . "|</font><br>";
    }

    my $id = get_player_id_from_name ($CURRENT_LOGIN_NAME, "fff");
    if ($id == -1)
    {
        #$out .= "Looked for $IP and didn't find it..<br>";
        $out .= "<font color=green size=+2>Join with your user name here:</font><br><br>";
        $out .= "
            <form action=\"/$GAME_URL/new_user\">
            <label for=\"fname\">User name:</label><br>
            <input type=\"text\" id=\"fname\" name=\"fname\" value=\"xyz\"><br>
            <input type=\"submit\" value=\"Join Now!!\">
            </form>";
        #$out .= "<a href=\"quick_start\">Begin Quick Debug<\/a><br>";
        my $next_num = $num_players_in_lobby +1;
        while (defined ($pns {"User$next_num"}) || defined ($BANNED_NAMES {"User$next_num"}))
        {
            $next_num++;
        }
        $out =~ s/xyz/User$next_num/img;
    }
    else
    {
        $out .= "<font size=+1 color=red>Welcome to \"$GAME!\", " . get_player_name ($id) . "<br><\/font>";
        if (in_game ($IP))
        {
            $out = print_game_state ($IP);
            $out .= "<br>Trick $trick_number, led by " . get_player_name ($current_trick_led_by). "\n";
            
            if ($trick_number == 13)
            {
                $out .= "<br>Player " . get_player_name (0) . " won<br>"; $out .= get_images_from_cards ($player_won_cards {0}, $id, 1, 1, 1, 0);
                $out .= "<br>Player " . get_player_name (1) . " won<br>"; $out .= get_images_from_cards ($player_won_cards {1}, $id, 1, 1, 1, 0);
                $out .= "<br>Player " . get_player_name (2) . " won<br>"; $out .= get_images_from_cards ($player_won_cards {2}, $id, 1, 1, 1, 0);
                $out .= "<br>Player " . get_player_name (3) . " won<br>"; $out .= get_images_from_cards ($player_won_cards {3}, $id, 1, 1, 1, 0);
            }
            $out .= "Reset the game here: <a href=\"reset_game\">Reset<\/a><br><br><br>";
        }
        elsif (!game_started ())
        {
            if ($num_players_in_lobby >= 2)
            {
                $out .= "<a href=\"new_game\">Start new game!<\/a>";
                $out .= "</font>";
            }
            else
            {
                $out .= "<a href=\"new_game\">Start new game!<\/a>";
                $out .= "</font>";
            }
        }
        else
        {
            $out .= "Game has already started!<br><br>";
            $out .= "*Reset and Restart* the game here: <a href=\"reset_game\">Reset<\/a><br><br><br>";
            $out .= print_game_state ($IP);
        }
    }

    my $do_refresh = 1;
    if ($id == $whos_turn)
    {
        $do_refresh = 0;
    }
    $out .= get_refresh_code ($do_refresh, $id, $whos_turn);
    print ("DONE Get game state\n");
    return $out;
}

sub chosen_card 
{
    my $id = $_ [0];
    my $card = $_ [1];
    my $IP = $_ [2];

    if ($id != $whos_turn)
    {
        add_to_debug ("CHOSEN CARD: failed as $id is not $whos_turn.  Tried $card<<\n");
        return ("");
    }

    if (!player_has_card ($id, $card))
    {
        add_to_debug ("CHOSEN CARD: failed as $id is not $whos_turn.  Doesn't have $card<<\n");
        return ("");
    }

    add_to_debug ("CHOSEN CARD: success as $id is $whos_turn.  Does have $card<<\n");
    return play_card ($id, $card);
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
    my $port = 2718;
    my $trusted_client;
    my $data_from_client;
    $|=1;

    print ("example: $PATH\\$GAME_URL.pl 1 1 0 1 1 \"each opponent\" \".*\" 0 5\n\n");

    socket (SERVER, PF_INET, SOCK_STREAM, $proto) or die "Failed to create a socket: $!";
    setsockopt (SERVER, SOL_SOCKET, SO_REUSEADDR, 1) or die "setsocketopt: $!";

    # bind to a port, then listen
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
        print $txt;

        $CURRENT_LOGIN_NAME = "";
        if ($txt =~ m/^Cookie.*?newloginname=(\w\w\w[\w_]+).*?(;|$)/im)
        {
            $CURRENT_LOGIN_NAME = $1;
        }

        if ($txt =~ m/fname=(\w\w\w[\w_]+) HTTP/im)
        {
            $CURRENT_LOGIN_NAME = $1;
        }

        if (defined $BANNED_NAMES {$CURRENT_LOGIN_NAME})
        {
            add_to_debug ("BANNING $CURRENT_LOGIN_NAME atm");
            $CURRENT_LOGIN_NAME = "";
        }

        $CURRENT_LOGIN_NAME =~ s/^(...........).*/$1/img;

        if ($CURRENT_LOGIN_NAME ne "" && get_player_id_from_name ($CURRENT_LOGIN_NAME, "ggg") == -1)
        {
            add_new_user ("name=$CURRENT_LOGIN_NAME", $client_addr);
            write_to_socket (\*CLIENT, get_game_state($client_addr), "", "noredirect");
            next;
        }

        if ($txt =~ m/.*need.*refresh.*/m)
        {
            if (get_needs_refresh ($client_addr))
            {
                write_to_socket (\*CLIENT, "NEEDS_REFRESH", "", "noredirect");
                next;
            }
            write_to_socket (\*CLIENT, "FINE_FOR_NOW", "", "noredirect");
            next;
        }

        if ($txt =~ m/.*force.*refresh.*/m)
        {
            force_needs_refresh ();
        }

        if ($txt =~ m/.*favico.*/m)
        {
            my $size = -s ("d:/perl_programs/$GAME_URL/_hearts.jpg");
            print (">>>>> size = $size\n");
            my $h = "HTTP/1.1 200 OK\nLast-Modified: 20150202020202\nConnection: close\nContent-Type: image/jpeg\nContent-Length: $size\n\n";
            print "===============\n", $h, "\n^^^^^^^^^^^^^^^^^^^\n";
            syswrite (\*CLIENT, $h);
            copy "d:/perl_programs/$GAME_URL/_hearts.jpg", \*CLIENT;
            next;
        }

        if ($txt =~ m/GET[^\n]*?new_user/mi)
        {
            add_to_debug ("REAL INSTANCE OF calling New_User: $txt with $client_addr<br>");
            my $ret = add_new_user ($txt, $client_addr);
            if ($ret =~ m/^Welcome/)
            {
                write_to_socket (\*CLIENT, "Welcome!!<a href=\"\/\">Lobby or Game window<\/a>", "", "noredirect");
                next;
            }
            write_to_socket (\*CLIENT, "Welcome!!<a href=\"\/\">Lobby or Game window<\/a>", "", "noredirect");
            next;
        }

        if ($txt =~ m/.*chosen_card_([0-3])\.([^ ]+).*/mi)
        {
            my $player_num = $1;
            my $card = $2;
            chosen_card ($player_num, $card, $client_addr);
            my $page = get_game_state($client_addr);
            write_to_socket (\*CLIENT, "$page", "", "redirect");
            print ("\n\n\n\n\n\n$page\n\n");
            next;
        }

        # HTTP
        if ($txt =~ m/.*boot.*person.*name=(\w\w\w[\w_]+)/mi)
        {
            my $person_to_boot = $1;
            boot_person ($person_to_boot);
            write_to_socket (\*CLIENT, "$person_to_boot was booted <a href=\"\/DONEDASBOOT\">Lobby or Game window<\/a>", "", "redirect");
            next;
        }

        # HTTP
        if ($txt =~ m/GET.*new_game.*/m)
        {
            new_game ();
            write_to_socket (\*CLIENT, get_game_state($client_addr), "", "redirect");
            next;
        }

        if ($txt =~ m/.*reset.*game.*/m)
        {
            write_to_socket (\*CLIENT, reset_game (), "", "redirect");
            next;
        }

        $txt =~ s/$GAME_URL.*$GAME_URL/$GAME_URL/img;

        print ("2- - - - - - -\n");
        write_to_socket (\*CLIENT, get_game_state($client_addr), "", "noredirect");

        print ("============================================================\n");
    }
}
