#!/usr/bin/perl
##
#   File : nothanks.pl
#   Date : 19/Jun/2022
#   Author : spjspj
#   Purpose : Implement No Thanks! 
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

my %revealed_cards_imgs;
my $BCK = "back";
my $NUM_COUNTERS_AT_START_OF_GAME = 10;
my $GAME_WON = 0;
my $reason_for_game_end = "";
my $CURRENT_LOGIN_NAME = "";
my $SHOW_CARDS_MODE = 0;
my $IN_DEBUG_MODE = 0;

my $BAD_GUYS = -1;
my $GOOD_GUYS = 1;
my $PATH = "d:\\perl_programs\\nothanks";
my $nothanks = "<img id=\"xxx\" width=\"80\" height=\"131\" src=\"big_c.jpg\"><\/img>";
my $TORCH = "<img src=\"torch.jpg\"><\/img>";
my %rand_colors;

my $DEBUG = "";
my @player_names;
my @NEEDS_REFRESH;
my @NEEDS_ALERT;

my @deck;
my $cards_left_in_deck;
my $current_flipped_card;
my $current_number_of_counters;
my %player_counters;
my %player_cards;

my %already_shuffled;
my $needs_shuffle_but_before_next_card_picked = 0;
my %BANNED_NAMES;
my $RINGINGROOM_URL_LINK;
my %NOT_HIDDEN_INFO;

my $whos_turn;
my $pot_whos_turn;
my $num_players_in_game = -1;
my $NUM_EXPOSED_CARDS = 0;
my $num_cards_per_player = $NUM_COUNTERS_AT_START_OF_GAME;
my @player_ips;
my $num_players_in_lobby = 0;

sub add_to_debug
{
    $DEBUG .= "$_[0]<br>\n";
}

sub game_won
{
    my $win_con = $_ [0];

    if ($GAME_WON == 0)
    {
        force_needs_refresh();
        $GAME_WON = $_ [0];
        $reason_for_game_end = $_ [1];
        add_to_debug ("GAME WON: $reason_for_game_end");
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
    $msg_body =~ s/href="/href="\/nothanks\//img;
    $msg_body =~ s/\/\//\//img;
    $msg_body =~ s/nothanks.nothanks/nothanks/img;
    $msg_body =~ s/nothanks.nothanks/nothanks/img;
    $msg_body =~ s/nothanks.nothanks/nothanks/img;
    $msg_body =~ s/nothanks.nothanks/nothanks/img;

    my $header;
    if ($redirect =~ m/^redirect/i)
    {
        $header = "HTTP/1.1 302 Moved\nLocation: \/nothanks\/\nLast-Modified: $yyyymmddhhmmss\nConnection: close\nContent-Type: text/html; charset=UTF-8\nContent-Length: " . length ($msg_body) . "\n\n";
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
    #print ("\n===========\nWrite to socket: ", length ($msg_body), "! >>$msg_body<<\n==========\n");
    #add_to_debug ("\n===========\nWrite to socket: ", length ($msg_body), "! >>$msg_body<<\n==========\n");

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
    #print $msg_body, "\n";
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

    #if ($ips_slowed_down_for {$ip} < 10)
    {
         #Time::HiRes::sleep (0.1); #.1 seconds
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

    #if ($ips_slowed_down_for {$ip} < 10)
    {
         #Time::HiRes::sleep (0.1); #.1 seconds
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
        #print ("SIZE ($img) WAS $size\n");
    }
    #print ("222 SIZE ($img) WAS $size\n");
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
                #print ("$header!!\n");
                #print (" ---> Unable to read a character\n");
                return "resend";
            }
            $header .= $ch;
            my $h = $header;
            $h =~ s/(.)/",$1-" . ord ($1) . ";"/emg;
        }
    }

    #print "\n++++++++++++++++++++++\n", $header, "\n";
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

    my $x = get_player_id_from_name ($CURRENT_LOGIN_NAME);
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
    #add_to_debug ("Didn't find |$IP| in |" . join ("|", @player_ips));
    return -1;
}

sub flip_top_card
{
    if ($cards_left_in_deck > 0)
    {
        $current_flipped_card = $deck [0];
        $current_number_of_counters = 0;
    }
    else
    {
        return 0;
    }

    my $i = 1;
    my $index = 0;
    my @new_deck;
    while ($i < $cards_left_in_deck) 
    {
        $new_deck [$index] = $deck [$i];
        $i++;
        $index++;
    }
    @deck = @new_deck;
    return 1;
}

sub setup_deck
{
    # Cards in deck currently..
    my $total_number_cards_in_deck = 35 - 3 + 1 - 9;
    my %banned_cards;

    my $i;
    for ($i = 0; $i < 9; $i++)
    {
        my $banned = int (rand (32)) + 3;
        if (!defined ($banned_cards {$banned}))
        {
            $banned_cards {$banned} = 1;
        }
        else
        {
            $i --;
        }
    }

    my $index = 0;
    my $str = "";
    my @new_deck;
    for ($i = 3; $i <= 35 ; $i++)
    {
        if (!defined ($banned_cards {$i}))
        {
            $new_deck [$index] = $i;
            $index++;
            $str .= "$i,";
        }
    }

    @deck = @new_deck;
    $cards_left_in_deck = $total_number_cards_in_deck;
    do_shuffle ();
    flip_top_card ();
    
    add_to_debug ("Setup deck with: $str");
    add_to_debug ("Ignoring these cards: " . join (",", sort (keys %banned_cards)));
    add_to_debug (join (",", @deck));
}

sub get_player_name
{
    my $ID = $_ [0];
    return $player_names [$ID];
}

sub set_whos_turn
{
    $pot_whos_turn = $_ [0];
}

sub set_next_turn
{
    $whos_turn++;
    print ("Whos turn?$whos_turn $num_players_in_game players is next turn...\n");
    if ($whos_turn >= $num_players_in_game) 
    {
        $whos_turn = 0;
    }
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
            #add_to_debug (" ... 777 Already user logged in with that name ($name_find)..\n");
            return "";
        }
    }

    {
        add_to_debug ("ADDING NEW_USER ($this_name)..\n");
        $player_names [$num_players_in_lobby] = $this_name;
        $player_ips [$num_players_in_lobby] = $IP;
        add_to_debug ("ADDING NEW_USER Player IPS:" . join ("<br>", @player_ips));
        add_to_debug ("ADDING NEW_USER Player Names:" . join ("<br>", @player_names));
        $NEEDS_REFRESH [$num_players_in_lobby] = 1;
        $NEEDS_ALERT [$num_players_in_lobby] = 0;
        $num_players_in_lobby++;
        add_to_debug ("ADDING NEW_USER ($this_name)..\n");


        my $col = sprintf ("#%lX%1X%1X", int (rand (200) + 55), int (rand (200) + 55), int (rand (200) + 55));
        $rand_colors {$this_name} = $col;
        add_to_debug ("RAND COLOR - $this_name = $rand_colors{$this_name} ($col)\n");
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
    add_to_debug (" IN FORCING REFRESH\n");
    for ($i = 0; $i < $num_players_in_lobby; $i++)
    {
        $NEEDS_REFRESH [$i] = 1;
        add_to_debug (" FORCING REFRESH FOR $i - " . get_player_name ($i));
    }
    add_to_debug (" DONE FORCING REFRESH");
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

sub pass_card 
{
    my $in = $_ [0];
    my $IP = $_ [1];
    my $id = get_player_id ($IP);
    my $n = get_player_name ($id);
    if ($id != $whos_turn)
    {
        return ("");
    }

    if ($in =~ m/pass.*card\.(\d+)\.(\d+)/)
    {
        my $card_taken = $1;
        my $num_tokens = $2;
        $player_counters {$id} --;
        $current_number_of_counters++;
        set_next_turn ();
    }

    force_needs_refresh ();
}

sub take_card
{
    my $in = $_ [0];
    my $IP = $_ [1];
    my $id = get_player_id ($IP);
    my $n = get_player_name ($id);
    if ($id != $whos_turn)
    {
        return ("");
    }

    if ($in =~ m/take.*card\.(\d+)\.(\d+)/)
    {
        my $card_taken = $1;
        my $num_tokens = $2;
        my $name_of_card_picked = $deck [$card_taken];
        print ("TOOK name_of_card_picked=$name_of_card_picked by $id!!!\n"); 
        add_to_debug ("KNOWS $name_of_card_picked\n");
        $needs_shuffle_but_before_next_card_picked = 0;
        $player_cards {$id} .= "$card_taken,";
        $player_counters {$id} += $num_tokens;
        flip_top_card ();
    }

    force_needs_refresh ();
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
    set_whos_turn (int (rand ($num_players_in_game)));
    $GAME_WON = 0;
    $NUM_EXPOSED_CARDS = 0;

    # Setup the deck..
    setup_deck ();

    $player_counters {0} = 10;
    $player_counters {1} = 10;
    $player_counters {2} = 10;
    $player_counters {3} = 10;
    $player_counters {4} = 10;
    $player_counters {5} = 10;
    $player_counters {6} = 10;
    $player_counters {7} = 10;
    $player_counters {8} = 10;
    $player_counters {9} = 10;
    $player_cards {0} = "";
    $player_cards {1} = "";
    $player_cards {2} = "";
    $player_cards {3} = "";
    $player_cards {4} = "";
    $player_cards {5} = "";
    $player_cards {6} = "";
    $player_cards {7} = "";
    $player_cards {8} = "";
    $player_cards {9} = "";

    $num_cards_per_player = $NUM_COUNTERS_AT_START_OF_GAME;
    force_needs_refresh();
    my %new_already_shuffled;
    %already_shuffled = %new_already_shuffled;
    $needs_shuffle_but_before_next_card_picked = 0;
    return;
}

sub reset_game
{
    $num_players_in_game = -1;
    $GAME_WON = 0;
    $NUM_EXPOSED_CARDS = 0;
    $reason_for_game_end = "";
    my @new_deck;
    @deck = @new_deck;
    my $out = "Game reset <a href=\"\/\">Lobby or Game window<\/a>";
    force_needs_refresh();
    my %new_already_shuffled;
    %already_shuffled = %new_already_shuffled;
    my %new_NOT_HIDDEN_INFO;
    %NOT_HIDDEN_INFO = %new_NOT_HIDDEN_INFO;
    $needs_shuffle_but_before_next_card_picked = 0;
    
    $player_counters {0} = 10;
    $player_counters {1} = 10;
    $player_counters {2} = 10;
    $player_counters {3} = 10;
    $player_counters {4} = 10;
    $player_counters {5} = 10;
    $player_counters {6} = 10;
    $player_counters {7} = 10;
    $player_counters {8} = 10;
    $player_counters {9} = 10;
    $player_cards {0} = "";
    $player_cards {1} = "";
    $player_cards {2} = "";
    $player_cards {3} = "";
    $player_cards {4} = "";
    $player_cards {5} = "";
    $player_cards {6} = "";
    $player_cards {7} = "";
    $player_cards {8} = "";
    $player_cards {9} = "";


    return $out;
}

sub in_game
{
    my $id = get_player_id_from_name ($CURRENT_LOGIN_NAME);
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
    my $this_player_id = get_player_id_from_name ($CURRENT_LOGIN_NAME);

    my $known_to_user = -1;

    my $torch_cell = "<td></td>";
    if ($id == $whos_turn)
    {
        $torch_cell = "<td>$TORCH</td>";
    }
    my $name_cell = "<td><font size=+1 color=darkgreen>" . get_player_name ($id) . "</font></td>";
    if ($id == $this_player_id)
    {
        $name_cell = "<td>**<font size=+2 color=darkblue>" . get_player_name ($id) . "</font> (" . $player_counters {$id} . " Counters)**</td>";
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
    my %cards;
    while ($cards =~ s/^(\d+),//)
    {
        my $c = $1;
        $cards {$c} = "<img width=\"30\" height=\"43\" src=\"card$1.jpg\"><\/img>";
    }
    my $k;
    my $score = 0;
    my $total_cards = 0;
    for $k (sort {$a <=> $b} (keys %cards))
    {
        $score += $k;
        $total_cards ++;
        if (exists ($cards {$k - 1}))
        {
            $cards {$k} = "<img width=\"12\" height=\"43\" src=\"half_card.jpg\"><\/img>";
            $score -= $k;
        }
    }
    
    my $actual_card_cell = "<td>";
    for $k (sort {$a <=> $b} (keys %cards))
    {
        $actual_card_cell .= $cards {$k};
    }
    $actual_card_cell .= " (Score = $score - Total cards = $total_cards)</td>";

    $out .= "$start_bit$name_cell$actual_card_cell$torch_cell<td>" . "</td>$final_bit\n";

    my $make_pickable = $this_player_id == $whos_turn && $id != $this_player_id;

    if ($make_pickable)
    {
        $out =~ s/<img id=.card_(\d+)/<a href="\/take_card_$1"><img id="card_$1/g;
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

    my $out = "Current card:<br>";
    $out .= player_row (0, $IP);
    if ($num_players_in_game >= 2) { $out .= player_row (1, $IP); }
    if ($num_players_in_game >= 3) { $out .= player_row (2, $IP); }
    if ($num_players_in_game >= 4) { $out .= player_row (3, $IP); }
    if ($num_players_in_game >= 5) { $out .= player_row (4, $IP); }
    if ($num_players_in_game >= 6) { $out .= player_row (5, $IP); }
    if ($num_players_in_game >= 7) { $out .= player_row (6, $IP); }
    $out .= "</tr></table>";
    $out =~ s/<\/tr><\/tr>/<\/tr>/img;

    #$out .= $DEBUG;
    return $out;
}

sub get_faceup_image
{
    my $id = $_ [0];
}

sub get_faceup_elements
{
    return "<img src=\"card$current_flipped_card.jpg\"><\/img>&nbsp;&nbsp;&nbsp;(Card currently has $current_number_of_counters X <img width=\"30\" height=\"30\" src=\"counter.jpg\">) ";
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

    my $id = get_player_id ($IP);
    if ($id == $whos_turn)
    {
        $out .= "<b>YOUR TURN!!</b>";
        if ($player_counters {$id} > 0)
        {
            $out .= "&nbsp;&nbsp;<a href=\"passcard.$current_flipped_card." . ($current_number_of_counters + 1) . ".html\">Put a counter on and pass to the right (You have " . $player_counters {$id} . " counters left)";
        }
        $out .= "&nbsp;&nbsp;<a href=\"takecard.$current_flipped_card.$current_number_of_counters.html\">Take this card!</a><br>";
    }

    $out .= get_board ($IP) . "<br>";
    $out .= get_faceup_elements ($IP) . "<br>";

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
    $txt .= "            client.get('/nothanks/needs_refresh', function(response) {\n";
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
    $txt .= "<a href=\"\/nothanks\/force_refresh\">Force Refresh<\/a><br>";
    return $txt;
}

sub debug_game
{
    return "";
}

sub get_game_state
{
    my $IP = $_ [0];

    my $out .= "<h1>Welcome to \"No Thanks!\", <font color=" . $rand_colors {$CURRENT_LOGIN_NAME} . ">$CURRENT_LOGIN_NAME</font> </h1><br><br>&nbsp;There are $num_players_in_lobby players logged in.<br>";
    $out .= "Player names are:<br>" . join ("<br>", @player_names); # . "<br>IPs:<br>" . join ("<br>", @player_ips);
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

    my $id = get_player_id_from_name ($CURRENT_LOGIN_NAME);
    if ($id == -1)
    {
        #$out .= "Looked for $IP and didn't find it..<br>";
        $out .= "<font color=green size=+2>Join with your user name here:</font><br><br>";
        $out .= "
            <form action=\"/nothanks/new_user\">
            <label for=\"fname\">User name:</label><br>
            <input type=\"text\" id=\"fname\" name=\"fname\" value=\"xyz\"><br>
            <input type=\"submit\" value=\"Join Now!!\">
            </form>";
        #$out .= "<a href=\"quick_start\">Begin Quick Debug<\/a><br>";
        my $next_num = $num_players_in_lobby +1;
        $out =~ s/xyz/User$next_num/img;
    }
    else
    {
        $out .= "<font size=+1 color=red>Welcome to \"No Thanks!\", " . get_player_name ($id) . "<br><\/font>";
        if (in_game ($IP))
        {
            #add_to_debug ("doing PRINT_GAME_STATE : Player=$id $IP was in_game");
            $out = print_game_state ($IP);
            $out .= "Reset the game here: <a href=\"reset_game\">Reset<\/a><br><br><br>";
        }
        elsif (!game_started ())
        {
            #add_to_debug ("Game not started");
            $out .= "<a href=\"new_game\">Start new game!<\/a>";
        }
        else
        {
            #add_to_debug ("Game started without you in it..");
            $out .= "Game has already started!<br><br>";
            $out .= "*Reset and Restart* the game here: <a href=\"reset_game\">Reset<\/a><br><br><br>";
        }
    }

    my $do_refresh = 1;
    if ($id == $whos_turn)
    {
        $do_refresh = 0;
    }
    $out .= get_refresh_code ($do_refresh, $id, $whos_turn);
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
    my $port = 3967;
    my $trusted_client;
    my $data_from_client;
    $|=1;

    print ("example: $PATH\\nothanks.pl 1 1 0 1 1 \"each opponent\" \".*\" 0 5\n\n");

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

        if ($CURRENT_LOGIN_NAME ne "" && get_player_id_from_name ($CURRENT_LOGIN_NAME) == -1)
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

        if ($txt =~ m/.*favico.*/m)
        {
            my $size = -s ("d:/perl_programs/nothanks/_nothanks.jpg");
            print (">>>>> size = $size\n");
            my $h = "HTTP/1.1 200 OK\nLast-Modified: 20150202020202\nConnection: close\nContent-Type: image/jpeg\nContent-Length: $size\n\n";
            print "===============\n", $h, "\n^^^^^^^^^^^^^^^^^^^\n";
            syswrite (\*CLIENT, $h);
            copy "d:/perl_programs/nothanks/_nothanks.jpg", \*CLIENT;
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

        if ($txt =~ m/.*take.*card.*/mi)
        {
            take_card ("$txt", $client_addr);
            my $page = get_game_state($client_addr);
            write_to_socket (\*CLIENT, "$page", "", "redirect");
            print ("\n\n\n\n\n\n$page\n\n");
            next;
        }
        
        if ($txt =~ m/.*pass.*card.*/mi)
        {
            pass_card ("$txt", $client_addr);
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

        $txt =~ s/nothanks.*nothanks/nothanks/img;

        print ("2- - - - - - -\n");
        write_to_socket (\*CLIENT, get_game_state($client_addr), "", "noredirect");

        print ("============================================================\n");
    }
}
