#!/usr/bin/perl
##
#   File : abadice.pl
#   Date : 19/Jun/2022
#   Author : spjspj & psjpsj
#   Purpose : Implement Abadice!
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

my $GAME_WON = 0;
my $GAME_STARTED = 0;
my $GAME_WAITING_FOR_CHOOSE = 0;
my $GAME_WAITING_FOR_NEXT_TURN = 0;
my $reason_for_game_end = "";
my $CURRENT_LOGIN_NAME = "";
my $PATH = "d:\\perl_programs\\abadice";
my %rand_colors;
my @player_names;
my @NEEDS_REFRESH;
my $current_number_of_counters;
my %already_shuffled;
my %BANNED_NAMES;
my $whos_turn;
my $num_players_in_game = -1;
my @player_ips;
my $num_players_in_lobby = 0;
my @beads;
my $number_beads = 10;
my $number_wires = 5;
my $size_dice = 10;
my $NUMBER_TIMES_FOR_DRAW = 10;
my $player = "";
my $player_num = 1;
my $times_move_beads_has_failed = 0;
my $roll = 14;
my $rolled = "";
my @old_beads;
my $old_roll;
my $factors = "";
my %factors_for_dice;

#-================================
sub prime
{
    my $number = shift;
    my $d = 2;
    my $sqrt = sqrt $number;
    while (1)
    {
        if ($number%$d == 0)
        {
            return 0;
        }
        if ($d < $sqrt)
        {
            $d++;
        }
        else
        {
            return 1;
        }
    }
}

sub num_pair_factors
{
    my $number = shift;
    my $i = 2;
    my %new_hash;
    %factors_for_dice = %new_hash;

    my $total_pair_factors = 1;
    $factors = "1&$number, ";
    $factors_for_dice {0} = "1";

    if ($number > $number_beads)
    {
        my %new_hash2;
        %factors_for_dice = %new_hash2;
        $factors = "";
        $total_pair_factors = 0;
    }

    for ($i = 2; $i <= 5; $i++)
    {
        if ($number % $i == 0)
        {
            $factors .= "$i&" . $number / $i . ", ";
            $factors_for_dice {$total_pair_factors} = $i;
            $total_pair_factors ++;
        }
    }
    $factors =~ s/, $//;
    return ($total_pair_factors, $factors);
}

sub old_print_wire
{
    my $number = $_ [0];
    my $line_number = $_ [1];
    my $str = "---";
    my $i;
    for ($i = 0; $i < $number; $i++)
    {
        $str = "-" . $str . "*";
    }
    my $str2;
    for ($i = 0; $i < $number_beads - $number; $i++)
    {
        $str2 = "*" . $str2 . "-";
    }
    if ($line_number <= 4)
    {
        return "P: " . $str2 . $str . "<br>";
    }
    else
    {
        return "D: " . $str2 . $str . "<br>";
    }
    return "bbbb $number, $line_number aaaa";
}

sub print_wire
{
    my $number = $_ [0];
    my $line_number = $_ [1];
    return "<img width=\"506\" src=\"images\/" . (10 - $number) . "_beads.png\"\/><br>";
}

sub print_wires
{
    my $id = get_player_id_from_name ($CURRENT_LOGIN_NAME, "fff");
    my $info; 
   
    if ($id == 0)
    {
        $info .= "<font color=blue size=+2>" . get_player_name (0) . "</font><br>";
        for (my $j = 0; $j < $number_wires; $j++)
        {
            $info .= print_wire ($beads [$j], $j);
        }
        
        if ($num_players_in_game > 1)
        {
            $info .= get_player_name (1) . "<br>";
            for (my $j = $number_wires; $j < $number_wires * 2; $j++)
            {
                $info .= print_wire ($beads [$j], $j);
            }
        }
    }
    elsif ($id == 1)
    {
        if ($num_players_in_game > 1)
        {
            $info .= "<font color=blue size=+2>" . get_player_name (1) . "</font><br>";
            for (my $j = $number_wires; $j < $number_wires * 2; $j++)
            {
                $info .= print_wire ($beads [$j], $j);
            }
        }
        $info .= get_player_name (0) . "<br>";
        for (my $j = 0; $j < $number_wires; $j++)
        {
            $info .= print_wire ($beads [$j], $j);
        }
    }

    my $do_refresh = 1;
    if ($id == $whos_turn)
    {
        $do_refresh = 0;
    }
    $info .= get_refresh_code ($do_refresh, $id, $whos_turn);
    $info .= $rolled;
    return $info;
}

sub move_beads
{
    my $beads_to_move = $_ [0];
    my $wires_affected = $_ [1];
    my $player = $_ [2];
    my $wires_affected_so_far = 0;

    my $add_wires = $number_wires * $player;

    my @old_beads;
    for (my $i = 0; $i < $number_wires * 2; $i++)
    {
        $old_beads [$i] = $beads [$i];
    }

    for (my $x = 0 + $add_wires; $x < $number_wires + $add_wires && $wires_affected_so_far < $wires_affected; $x++)
    {
        if ($beads [$x] >= $beads_to_move)
        {
            $beads [$x] -= $beads_to_move;
            $wires_affected_so_far ++;
        }
    }

    $rolled .= "<font size=-2>MOVE BEADS for $beads_to_move for $player on $wires_affected</font><br>";
    if ($wires_affected != $wires_affected_so_far)
    {
        # Can't do the full number of beads
        for (my $i = 0; $i < $number_wires * 2; $i++)
        {
            $beads [$i] = $old_beads [$i];
        }
    }

    return $wires_affected == $wires_affected_so_far;
}

sub has_someone_won
{
    my $player1_won = 1;
    for (my $x = 0; $x < $number_wires; $x++)
    {
        if ($beads [$x] != 0)
        {
            $player1_won = 0;
        }
    }
    if ($player1_won == 1)
    {
        return get_player_name (0) . " won!!!";
    }

    my $player2_won = 1;
    for (my $x = $number_wires; $x < $number_wires*2; $x++)
    {
        if ($beads [$x] != 0)
        {
            $player2_won = 0;
        }
    }
    if ($player2_won == 1)
    {
        return get_player_name (1) . " won!!!";
    }

    return "";
}

for (my $i = 0; $i < $number_wires; $i++)
{
    push @beads, $number_beads;
}

for (my $i = 0; $i < $number_wires; $i++)
{
    push @beads, $number_beads;
}
#-================================

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
    if ($GAME_WON == 1)
    {
        $GAME_STARTED = 0;
    }
    my $t = "Won..";
    return $t;
}

sub write_to_socket
{
    my $sock_ref = $_ [0];
    my $msg_body = $_ [1];
    my $form = $_ [2];
    my $redirect = $_ [3];
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime (time);
    my $yyyymmddhhmmss = sprintf "%.4d%.2d%.2d-%.2d%.2d%.2d", $year+1900, $mon+1, $mday, $hour,  $min, $sec;

    $msg_body = '<html><head><META HTTP-EQUIV="CACHE-CONTROL" CONTENT="NO-CACHE"><br></head><body>' . $form . $msg_body . "</body></html>";
    $msg_body =~ s/\n\n/\n/mig;
    $msg_body =~ s/\n\n/\n/mig;
    $msg_body =~ s/\n\n/\n/mig;
    $msg_body .= chr (13) . chr (10);
    #$msg_body =~ s/<img.*?src="(.*?)".*?>(.*?)<\/img>/$1 - $2/img;
    $msg_body =~ s/href="/href="\/abadice\//img;
    $msg_body =~ s/\/\//\//img;
    $msg_body =~ s/abadice.abadice/abadice/img;
    $msg_body =~ s/abadice.abadice/abadice/img;
    $msg_body =~ s/abadice.abadice/abadice/img;
    $msg_body =~ s/abadice.abadice/abadice/img;

    my $header;
    if ($redirect =~ m/^redirect/i)
    {
        $header = "HTTP/1.1 302 Moved\nLocation: \/abadice\/\nLast-Modified: $yyyymmddhhmmss\nConnection: close\nContent-Type: text/html; charset=UTF-8\nContent-Length: " . length ($msg_body) . "\n\n";
    }
    elsif ($redirect =~ m/^noredirect/i)
    {
        $msg_body .= "<br>Your name is - $CURRENT_LOGIN_NAME<br>";
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

sub get_player_name
{
    my $ID = $_ [0];
    return $player_names [$ID];
}


sub set_next_turn
{
    $whos_turn++;
    if ($whos_turn >= $num_players_in_game) 
    {
        $whos_turn = 0;
    }
    $roll = int (rand ($size_dice)) + 1;
    $rolled .= "<font size=-2>Just rolled a $roll for $whos_turn " . get_player_name ($whos_turn) . "</font><br>";
    $GAME_WAITING_FOR_NEXT_TURN = 0;
    force_needs_refresh ();
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

        my $col = sprintf ("#%lX%1X%1X", int (rand (200) + 55), int (rand (200) + 55), int (rand (200) + 55));
        $rand_colors {$this_name} = $col;
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

    if (get_game_started () == 1)
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
    my $level = $_ [0];
    $rolled = "";
    $num_players_in_game = $num_players_in_lobby;
    $whos_turn = int (rand ($num_players_in_game)); 
    set_next_turn ();
    $player = get_player_name ($whos_turn);

    $GAME_WON = 0;
    $GAME_STARTED = 1;
    $GAME_WAITING_FOR_CHOOSE = 0;
    $GAME_WAITING_FOR_NEXT_TURN = 0;
    print ("STARTING GAME!!! $GAME_STARTED\n");

    force_needs_refresh ();
    
    my @new_beads;
    @beads = @new_beads;
    for (my $i = 0; $i < $number_wires; $i++)
    {
        push @beads, $number_beads;
    }

    for (my $i = 0; $i < $number_wires; $i++)
    {
        push @beads, $number_beads;
    }

    $times_move_beads_has_failed = 0;
    if ($level eq "easy") { $size_dice = 10; }
    if ($level eq "medium") { $size_dice = 15; }
    if ($level eq "hard") { $size_dice = 20; }
}

sub reset_game
{
    $GAME_WON = 0;
    $GAME_STARTED = 0;
    $GAME_WAITING_FOR_CHOOSE = 0;
    $GAME_WAITING_FOR_NEXT_TURN = 0;
    $reason_for_game_end = "";
    $CURRENT_LOGIN_NAME = "";
    $current_number_of_counters;
    %already_shuffled;
    %BANNED_NAMES;
    $whos_turn;
    $num_players_in_game = -1;
    my @new_beads;
    @beads = @new_beads;
    $number_beads = 10;
    $number_wires = 5;
    $size_dice = 10;
    $NUMBER_TIMES_FOR_DRAW = 10;
    $player = "";
    $times_move_beads_has_failed = 0;
    @old_beads;
    $factors = "";
    $rolled = "";
    %factors_for_dice;
}

sub in_game
{
    if (!get_game_started ())
    {
        return 0;
    }
    my $id = get_player_id_from_name ($CURRENT_LOGIN_NAME, "ccc");
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
    my $this_player_id = get_player_id_from_name ($CURRENT_LOGIN_NAME, "ddd");

    my $known_to_user = -1;

    my $who_has_card_cell = "<td></td>";
    if ($id == $whos_turn)
    {
    }
    my $name_cell = "<td><font size=+1 color=darkgreen>" . get_player_name ($id) . "</font></td>";

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

    my $actual_card_cell = "";
    $actual_card_cell .= "</td>";

    $out .= "$start_bit$name_cell$actual_card_cell$who_has_card_cell<td>" . "</td>$final_bit\n";

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

    return $out;
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
        $out .= "&nbsp;&nbsp;<a href=\"takecard.$current_number_of_counters.html\">Take this card!</a><br>";
    }

    $out .= get_board ($IP) . "<br>";

    return $out;
}

sub get_game_started
{
    return $GAME_STARTED;
}

sub get_refresh_code
{
    my $do_refresh = $_ [0];
    my $bb = $_ [1];
    my $bb2 = $_ [2];
    my $name = get_player_name ($bb);
    my $txt = "";

    if (!get_game_started ())
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
    $txt .= "            client.get('/abadice/needs_refresh', function(response) {\n";
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
    $txt .= "<a href=\"\/abadice\/force_refresh\">Force Refresh<\/a> or reset the game here: <a href=\"reset_game\">Reset<\/a><br><br><br>";
    return $txt;
}

sub get_game_state
{
    my $IP = $_ [0];

    my $out .= "<h1>Welcome to \"Abacus Dice!\", <font color=" . $rand_colors {$CURRENT_LOGIN_NAME} . ">$CURRENT_LOGIN_NAME</font> </h1><br><br>&nbsp;There are $num_players_in_lobby players logged in.<br>";
    $out .= "Player names are:<br>" . join ("<br>", @player_names); # . "<br>IPs:<br>" . join ("<br>", @player_ips);
    $out .= "<br><br><font size=-2>You can boot players here whilst the game is not started:</font><br>";

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
            <form action=\"/abadice/new_user\">
            <label for=\"fname\">User name:</label><br>
            <input type=\"text\" id=\"fname\" name=\"fname\" value=\"xyz\"><br>
            <input type=\"submit\" value=\"Join Now!!\">
            </form>";
        my $next_num = $num_players_in_lobby +1;
        while (defined ($pns {"User$next_num"}) || defined ($BANNED_NAMES {"User$next_num"}))
        {
            $next_num++;
        }
        $out =~ s/xyz/User$next_num/img;
    }
    else
    {
        $out .= "<font size=+1 color=red>Welcome to \"Abadice!\", " . get_player_name ($id) . "<br><\/font>";
        if (in_game ($IP))
        {
            $out = print_game_state ($IP);
            $out .= "Reset the game here: <a href=\"reset_game\">Reset<\/a><br><br><br>";
        }
        elsif (!get_game_started ())
        {
            if ($num_players_in_lobby >= 1)
            {
                $out .= "<a href=\"\/reset_game\">Reset<\/a> or start a new game here <a href=\"\/new_game_easy\">easy game<\/a>, <a href=\"\/new_game_medium\">medium game<\/a> or <a href=\"\/new_game_hard\">hard game<\/a>";
            }
            else
            {
                $out .= "Need 1 or 2 players to play Abadice! (The 'Start' URL will be here when there are enough players!)";
            }
        }
        else
        {
            $out .= "Game has already started!<br><br>";
            $out .= "*Reset and Restart* the game here: <a href=\"reset_game\">Reset<\/a><br><br><br>";
            $out .= print_game_state ($IP);
        }
    }

#    {
#        $out .= "<font size=+1 color=red>Welcome to \"Abacus Dice!\", " . get_player_name ($id) . "<br><\/font>";
#
#        if (get_game_started () == 0)
#        {
#            $out .= "<font size=+1 color=red>Game hasn't started. Start a new game here <a href=\"\/new_game\">create new game<\/a><br><\/font>";
#            return $out;
#        }
#        if (in_game ($IP))
#        {
#            $out = print_game_state ($IP);
#        }
#        else
#        {
#            $out .= print_game_state ($IP);
#            $out .= "Your name is: " . get_player_name ($id) . " and there is $num_players_in_game currently and your ID = $id<br>";
#        }
#    }

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
    my $port = 6967;
    my $trusted_client;
    my $data_from_client;
    $|=1;

    print ("example: $PATH\\abadice.pl 1 1 0 1 1 \"each opponent\" \".*\" 0 5\n\n");

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
            $CURRENT_LOGIN_NAME = "";
        }

        $CURRENT_LOGIN_NAME =~ s/^(...........).*/$1/img;

        if ($CURRENT_LOGIN_NAME ne "" && get_player_id_from_name ($CURRENT_LOGIN_NAME, "ggg") == -1)
        {
            add_new_user ("name=$CURRENT_LOGIN_NAME", $client_addr);
            
            my $xyz = get_game_state($client_addr);
            print "\n\n\n>>>>>>$xyz<<<<<<<<<<<\n";
            write_to_socket (\*CLIENT, get_game_state($client_addr), "", "noredirect");
            next;
        }

        if ($CURRENT_LOGIN_NAME eq "")
        {
            write_to_socket (\*CLIENT, get_game_state($client_addr), "", "noredirect");
            next;
        }

        # HTTP
        print (">>> $txt!!\n");
        if ($txt =~ m/GET.*new_game.*(easy|medium|hard)/m)
        {
            my $level = $1;
            new_game ($level);
            write_to_socket (\*CLIENT, get_game_state($client_addr), "", "redirect");
            next;
        }

        if ($txt =~ m/.*reset.*game.*/m)
        {
            reset_game ();
            write_to_socket (\*CLIENT, get_game_state($client_addr), "", "redirect");
            next;
        }

        if (!get_game_started ())
        {
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
            my $size = -s ("d:/perl_programs/abadice/_abadice.jpg");
            print (">>>>> size = $size\n");
            my $h = "HTTP/1.1 200 OK\nLast-Modified: 20150202020202\nConnection: close\nContent-Type: image/jpeg\nContent-Length: $size\n\n";
            print "===============\n", $h, "\n^^^^^^^^^^^^^^^^^^^\n";
            syswrite (\*CLIENT, $h);
            copy "d:/perl_programs/abadice/_abadice.jpg", \*CLIENT;
            next;
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

        # HTTP
        if ($txt =~ m/.*boot.*person.*name=(\w\w\w[\w_]+)/mi)
        {
            my $person_to_boot = $1;
            boot_person ($person_to_boot);
            write_to_socket (\*CLIENT, "$person_to_boot was booted <a href=\"\/DONEDASBOOT\">Lobby or Game window<\/a>", "", "redirect");
            next;
        }

        # HTTP
        if ($txt =~ m/.*boot.*person.*name=(\w\w\w[\w_]+)/mi)
        {
            my $person_to_boot = $1;
            boot_person ($person_to_boot);
            print ("\n--------\nPlayer $player, you rolled: " . $roll);
            write_to_socket (\*CLIENT, "$person_to_boot was booted <a href=\"\/DONEDASBOOT\">Lobby or Game window<\/a>", "", "redirect");
            next;
        }

        if ($txt =~ m/.*choose_(\d+)_(\d+)/mi)
        {
            my $wires_affected = $1;
            my $beads_to_move = $2;
            if (move_beads ($beads_to_move, $wires_affected,  $whos_turn))
            {
                $times_move_beads_has_failed = 0;
            }
            else
            {
                $times_move_beads_has_failed++;
            }
            
            my $info .= "$player rolled ($roll) and moved $beads_to_move on $wires_affected wires.<br>";
            $info .= "<a href=\"next_turn\/\">Proceed to new roll!</a><br>";
            $info .= print_wires ();
            write_to_socket (\*CLIENT, "$info", "", "redirect");
            print "$player rolled ($roll) and moved $beads_to_move on $wires_affected wires.<br>\n";
            $GAME_WAITING_FOR_NEXT_TURN = 1;
            $GAME_WAITING_FOR_CHOOSE = 0;
            next;
        }

        my $this_player_id = get_player_id_from_name ($CURRENT_LOGIN_NAME, "ddd");
        my $this_players_go = $this_player_id == $whos_turn;
        if ($GAME_WAITING_FOR_CHOOSE && $this_players_go)
        {
            print ("IN HERE -- aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\n");
        }
        
        if ($txt =~ m/.*next_turn.*/mi && !$GAME_WAITING_FOR_NEXT_TURN)
        {
            print ("Cancelling $txt (due to $GAME_WAITING_FOR_NEXT_TURN)\n");
            
            my $info .= "Cancelling next turn";
            $info .= print_wires ();
            write_to_socket (\*CLIENT, "$info", "", "redirect");
            next;
        }

        if ($GAME_WAITING_FOR_NEXT_TURN)
        {
            print ("Not Cancelling $txt (due to $GAME_WAITING_FOR_NEXT_TURN)\n");

            #if ($txt =~ m/.*next_turn.*/mi)
            {
                $GAME_WAITING_FOR_NEXT_TURN = 0;
                set_next_turn ();
            }

            my $info .= "Going to next turn";
            $info .= "<a href=\"next_turn\/\">Proceed to new roll!</a><br>";
            $info .= print_wires ();
            write_to_socket (\*CLIENT, "$info", "", "redirect");
            next;
        }

        $txt =~ s/abadice.*abadice/abadice/img;

        print ("2- - - - - - -\n");

        if ($times_move_beads_has_failed == $NUMBER_TIMES_FOR_DRAW)
        {
            game_won ("Noone won!!<br>");
            my $info = "Game Over! Noone won..<br><a href=\"\/reset_game\">Reset<\/a> or start a new game here <a href=\"\/new_game_easy\">easy game<\/a>, <a href=\"\/new_game_medium\">medium game<\/a> or <a href=\"\/new_game_hard\">hard game<\/a><br>";
            $info .= print_wires ();
            write_to_socket (\*CLIENT, $info, "", "noredirect");
            next;
        }

        # Check if prime?
        if (prime ($roll) && $roll > $number_beads)
        {
            $times_move_beads_has_failed++;
            my $info .= "$player rolled a prime ($roll) greater than $number_beads - haha!! You can't do anything :)<br>$player moved no beads successfully!<br>";
            $info .= "<a href=\"next_turn\/\">Proceed to new roll!</a><br>";
            $info .= print_wires ();
            $GAME_WAITING_FOR_NEXT_TURN = 1;
            write_to_socket (\*CLIENT, "$info", "", "redirect");
            next;
        }
        else
        {
            my $won = has_someone_won ();
            if ($won =~ m/^./)
            {
                game_won ($won);
                my $info = "Game Over! $won..<br><a href=\"\/reset_game\">Reset<\/a> or start a new game here <a href=\"\/new_game_easy\">easy game<\/a>, <a href=\"\/new_game_medium\">medium game<\/a> or <a href=\"\/new_game_hard\">hard game<\/a><br>";
                $info .= print_wires ();
                write_to_socket (\*CLIENT, 
                , "", "noredirect");
                write_to_socket (\*CLIENT, $info, "", "noredirect");
                next;
            }

            my ($num_pair_factors, $factors) = num_pair_factors ($roll);

            if (!$this_players_go)
            {
                my $info .= "Waiting for " . get_player_name ($whos_turn) . " (I am $CURRENT_LOGIN_NAME) to have their go!<br>";
                $info .= print_wires ();
                write_to_socket (\*CLIENT, "$info", "", "noredirect");
                next;
            }

            my $info = "$CURRENT_LOGIN_NAME, what do you want to do ($times_move_beads_has_failed failed moves)? :<br>";
            $info .= "$CURRENT_LOGIN_NAME, you have " . $num_pair_factors . " ($factors) options as you rolled a $roll to choose from: ";

            if ($num_pair_factors > 1)
            {
                my $choices = "";
                while ($factors =~ s/^(\d+)&(\d+)(,|$) *//)
                {
                    my $num_lines = $1;
                    my $num_beads = $2;
                    $choices .= "<a href=\"choose_$num_lines" . "_$num_beads\">Number of lines: $num_lines, Number of beads: $num_beads<\/a>  ; ";
                    $GAME_WAITING_FOR_CHOOSE = 1;
                }

                $info .= "<br>$choices<br>";
                $info .= print_wires ();
                write_to_socket (\*CLIENT, "$info", "", "noredirect");
                next;
            }
            elsif ($num_pair_factors == 1)
            {
                # examples:
                # 2&7
                # 1&9
                $factors =~ m/^(\d+)&(\d+)$/;
                my $num_wires = $1;
                my $actual_beads = $2;

                if (move_beads ($actual_beads, $num_wires, $whos_turn))
                {
                    $times_move_beads_has_failed = 0;
                    $info .= "$player moved $actual_beads beads on $num_wires wire/s successfully due to $roll being rolled..!!<br>";
                    $info .= "<a href=\"\/\">OK</a><br>";
                    $info .= print_wires ();
                    $GAME_WAITING_FOR_NEXT_TURN = 1;
                    write_to_socket (\*CLIENT, "$info", "", "noredirect");
                    next;
                }
                else
                {
                    $times_move_beads_has_failed++;
                    $info .= "$player moved no beads due to $roll being rolled..<br>";
                    $info .= "<a href=\"next_turn\/\">Proceed to new roll!</a><br>";
                    $info .= print_wires ();
                    $GAME_WAITING_FOR_NEXT_TURN = 1;
                    write_to_socket (\*CLIENT, "$info", "", "noredirect");
                    next;
                }
            }
            elsif ($num_pair_factors == 0)
            {
                $times_move_beads_has_failed++;
                $info .= "$player moved no beads successfully!!<br>";
                $info .= "<a href=\"next_turn\/\">Proceed to new roll!</a><br>";
                $info .= print_wires ();
                $GAME_WAITING_FOR_NEXT_TURN = 1;
                write_to_socket (\*CLIENT, "$info", "", "redirect");
                next;
            }
        }

        my $info = "Not sure how you get here..";
        $info .= print_wires ();
        write_to_socket (\*CLIENT, "$info", "", "redirect");
        set_next_turn ();
        next;
    }
}
