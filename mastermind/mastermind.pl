#!/usr/bin/perl
##
#   File : mastermind.pl
#   Date : 25/Jan/2025
#   Author : spjspj
#   Purpose : Implement Mastermind
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
my $GAME_TYPE = "";
my $GAME_STARTED = 0;
my $GAME_WAITING_FOR_CHOOSE = 0;
my $GAME_WAITING_FOR_NEXT_TURN = 0;
my $reason_for_game_end = "";
my $CURRENT_LOGIN_NAME = "";
my %rand_colors;
my @player_names;
my @NEEDS_REFRESH;
my %BANNED_NAMES;
my $whos_turn;
my $num_players_in_game = -1;
my @player_ips;
my $num_players_in_lobby = 0;
my $NUMBER_TIMES_FOR_DRAW = 10;
my $player = "";
my $player_num = 1;
my $CURRENT_CODE = "WUBRGY";
my %CURRENT_GUESSES;
my $CURRENT_GUESSES_NUM = 0;
my $human_choices = "";
my $hard_bot_answers = "";

my $GAME_TYPE_HARD = "hard";
my $GAME_TYPE_BOT = "bot";
my $GAME_TYPE_HUMAN = "human";
my $games_block = "<a href=\"#\" onclick=\"confirmReset(event)\">Reset</a> 
or start a new game: <a href=\"/mastermind/new_game\">new game<\/a>, 
<a href=\"/mastermind/new_hard_game\">new hard game<\/a>, 
or <a href=\"/mastermind/new_bot_game\">play against bot<\/a>";
my $center_games_block = "<center><a href=\"#\" onclick=\"confirmReset(event)\">Reset<\/a> 
or start a new game: <a href=\"#\" onclick=\"confirmNewGameEasy(event)\">new game<\/a>, 
<a href=\"#\" onclick=\"confirmNewGameHard(event)\">new hard game<\/a>, 
or <a href=\"#\" onclick=\"confirmNewGameBot(event)\">play against bot<\/a></center>
    <div id=\"confirm_reset_box\">
        <p>Are you sure you want to reset?</p>
        <button class=\"confirm_reset_btn\" onclick=\"resetGame(true)\">Yes</button>
        <button class=\"confirm_reset_btn\" onclick=\"resetGame(false)\">No</button>
    </div>
    <div id=\"confirm_newgame_box\">
        <p>Are you sure you want to create a new easy game?</p>
        <button class=\"confirm_reset_btn\" onclick=\"newEasyGame(true)\">Yes</button>
        <button class=\"confirm_reset_btn\" onclick=\"newEasyGame(false)\">No</button>
    </div>
    <div id=\"confirm_newhardgame_box\">
        <p>Are you sure you want to create a new hard game?</p>
        <button class=\"confirm_reset_btn\" onclick=\"newHardGame(true)\">Yes</button>
        <button class=\"confirm_reset_btn\" onclick=\"newHardGame(false)\">No</button>
    </div>
    <div id=\"confirm_newbotgame_box\">
        <p>Are you sure you want to create a new bot game?</p>
        <button class=\"confirm_reset_btn\" onclick=\"newBotGame(true)\">Yes</button>
        <button class=\"confirm_reset_btn\" onclick=\"newBotGame(false)\">No</button>
    </div>
";

#-================================
sub has_someone_won
{
    return "";
}

sub game_won
{
    my $win_con = $_ [0];

    if ($GAME_WON == 0 || $GAME_WON == 1 && $win_con > 1)
    {
        force_needs_refresh();
        $GAME_WON = $_ [0];
        $reason_for_game_end = "<br>" . $_ [1] . "<br>";
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
    $msg_body =~ s/href="/href="\/mastermind\//img;
    $msg_body =~ s/\/\//\//img;
    $msg_body =~ s/mastermind.mastermind/mastermind/img;
    $msg_body =~ s/mastermind.mastermind/mastermind/img;
    $msg_body =~ s/mastermind.mastermind/mastermind/img;
    $msg_body =~ s/mastermind.mastermind/mastermind/img;

    my $header;
    if ($redirect =~ m/^redirect/i)
    {
        $header = "HTTP/1.1 302 Moved\nLocation: \/mastermind\/\nLast-Modified: $yyyymmddhhmmss\nConnection: close\nContent-Type: text/html; charset=UTF-8\nContent-Length: " . length ($msg_body) . "\n\n";
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
    foreach $name_find (@player_names)
    {
        if ($name_find eq $this_name)
        {
            return "";
        }
    }

    $player_names [$num_players_in_lobby] = $this_name;
    $player_ips [$num_players_in_lobby] = $IP;
    $NEEDS_REFRESH [$num_players_in_lobby] = 1;
    $num_players_in_lobby++;

    my $col = sprintf ("#%lX%1X%1X", int (rand (200) + 55), int (rand (200) + 55), int (rand (200) + 55));
    $rand_colors {$this_name} = $col;
    return "Welcome $this_name";
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

sub set_next_turn
{
    if ($whos_turn >= $num_players_in_game)
    {
        $whos_turn = 0;
    }
    $GAME_WAITING_FOR_NEXT_TURN = 0;
    force_needs_refresh ();
}

sub new_game
{
    my $level = $_ [0];
    reset_game ();
    $num_players_in_game = $num_players_in_lobby;
    $whos_turn = int (rand ($num_players_in_game));
    set_next_turn ();
    $player = get_player_name ($whos_turn);

    $GAME_WON = 0;
    $GAME_TYPE = $GAME_TYPE_HUMAN;
    $GAME_STARTED = 1;
    $GAME_WAITING_FOR_CHOOSE = 0;
    $GAME_WAITING_FOR_NEXT_TURN = 0;

    force_needs_refresh ();

    my %CURRENT_GUESSES_NEW;
    %CURRENT_GUESSES = %CURRENT_GUESSES_NEW;
    $CURRENT_GUESSES_NUM = 0;
    $human_choices = "";
    $hard_bot_answers = "";
    $CURRENT_CODE = "";
    for (my $i = 0; $i < 4; $i++)
    {
        my $n = int (rand (6));
        if ($n == 0) { $CURRENT_CODE .= "W"; }
        if ($n == 1) { $CURRENT_CODE .= "U"; }
        if ($n == 2) { $CURRENT_CODE .= "B"; }
        if ($n == 3) { $CURRENT_CODE .= "R"; }
        if ($n == 4) { $CURRENT_CODE .= "G"; }
        if ($n == 5) { $CURRENT_CODE .= "Y"; }
    }
}

sub new_hard_game
{
    my $level = $_ [0];
    reset_game ();
    $num_players_in_game = $num_players_in_lobby;
    $whos_turn = int (rand ($num_players_in_game));
    set_next_turn ();
    $player = get_player_name ($whos_turn);

    $GAME_WON = 0;
    $GAME_TYPE = $GAME_TYPE_HARD;
    $GAME_STARTED = 1;
    $GAME_WAITING_FOR_CHOOSE = 0;
    $GAME_WAITING_FOR_NEXT_TURN = 0;

    force_needs_refresh ();

    my %CURRENT_GUESSES_NEW;
    %CURRENT_GUESSES = %CURRENT_GUESSES_NEW;
    $CURRENT_GUESSES_NUM = 0;
    $human_choices = "";
    $hard_bot_answers = "";
    $CURRENT_CODE = "";
    for (my $i = 0; $i < 4; $i++)
    {
        my $n = int (rand (6));
        if ($n == 0) { $CURRENT_CODE .= "W"; }
        if ($n == 1) { $CURRENT_CODE .= "U"; }
        if ($n == 2) { $CURRENT_CODE .= "B"; }
        if ($n == 3) { $CURRENT_CODE .= "R"; }
        if ($n == 4) { $CURRENT_CODE .= "G"; }
        if ($n == 5) { $CURRENT_CODE .= "Y"; }
    }
}

sub new_bot_game
{
    my $level = $_ [0];
    reset_game ();
    $num_players_in_game = $num_players_in_lobby;
    $whos_turn = int (rand ($num_players_in_game));
    set_next_turn ();
    $player = get_player_name ($whos_turn);

    $GAME_WON = 0;
    $GAME_TYPE = $GAME_TYPE_BOT;
    $GAME_STARTED = 1;
    $GAME_WAITING_FOR_CHOOSE = 0;
    $GAME_WAITING_FOR_NEXT_TURN = 0;

    force_needs_refresh ();

    my %CURRENT_GUESSES_NEW;
    %CURRENT_GUESSES = %CURRENT_GUESSES_NEW;
    $CURRENT_GUESSES_NUM = 0;
    $CURRENT_CODE = "";
    for (my $i = 0; $i < 4; $i++)
    {
        my $n = int (rand (6));
        if ($n == 0) { $CURRENT_CODE .= "W"; }
        if ($n == 1) { $CURRENT_CODE .= "U"; }
        if ($n == 2) { $CURRENT_CODE .= "B"; }
        if ($n == 3) { $CURRENT_CODE .= "R"; }
        if ($n == 4) { $CURRENT_CODE .= "G"; }
        if ($n == 5) { $CURRENT_CODE .= "Y"; }
    }
}

sub reset_game
{
    $GAME_WON = 0;
    $reason_for_game_end = "";
    $GAME_TYPE = "";
    $GAME_STARTED = 0;
    $GAME_WAITING_FOR_CHOOSE = 0;
    $GAME_WAITING_FOR_NEXT_TURN = 0;
    $reason_for_game_end = "";
    $CURRENT_LOGIN_NAME = "";
    %BANNED_NAMES;
    $whos_turn;
    $num_players_in_game = -1;
    $NUMBER_TIMES_FOR_DRAW = 10;
    $player = "";
    $CURRENT_CODE = 0;
    my %CURRENT_GUESSES_NEW;
    %CURRENT_GUESSES = %CURRENT_GUESSES_NEW;
    $CURRENT_GUESSES_NUM = 0;
    $CURRENT_CODE = "";
    $human_choices = "";
    $hard_bot_answers = "";
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
    }

    return $out;
}

sub get_game_started
{
    return $GAME_STARTED;
}

sub get_answer_code
{
    my $answer_code = $_ [0];
    my $exact;
    my $partial;

    if ($answer_code =~ m/^(\d+),(\d+)/)
    {
        $exact = $1;
        $partial = $2;
    }

    my $cc = 4;
    my $answer = "";
    while ($exact > 0)
    {
        $answer .= "2";
        $cc--;
        $exact--;
    }
    while ($partial > 0)
    {
        $answer .= "1";
        $cc--;
        $partial--;
    }
    while ($cc > 0)
    {
        $answer .= "0";
        $cc--;
    }
    $answer .= ",";
    return $answer;
}

sub mk_answer_code
{
    my $human_chosen_code = $_ [0];
    my $code_to_check = $_ [1];
    my $orig_human_chosen_code = $_ [0];
    my $orig_code_to_check = $_ [1];
    my $ret = "0000";

    $human_chosen_code =~ m/([wubrgy])([wubrgy])([wubrgy])([wubrgy])/i;
    my $hc1 = $1;
    my $hc2 = $2;
    my $hc3 = $3;
    my $hc4 = $4;

    $code_to_check =~ m/([wubrgy])([wubrgy])([wubrgy])([wubrgy])/i;
    my $cc1 = $1;
    my $cc2 = $2;
    my $cc3 = $3;
    my $cc4 = $4;

    if ($hc1 eq $cc1) { $ret =~ s/0/2/; $code_to_check =~ s/^./X/;        $human_chosen_code =~ s/^./Z/;        }
    if ($hc2 eq $cc2) { $ret =~ s/0/2/; $code_to_check =~ s/^(.)./$1X/;   $human_chosen_code =~ s/^(.)./$1Z/;   }
    if ($hc3 eq $cc3) { $ret =~ s/0/2/; $code_to_check =~ s/^(..)./$1X/;  $human_chosen_code =~ s/^(..)./$1Z/;  }
    if ($hc4 eq $cc4) { $ret =~ s/0/2/; $code_to_check =~ s/.$/X/;        $human_chosen_code =~ s/.$/Z/;        }

    $code_to_check =~ m/([wubrgyx])([wubrgyx])([wubrgyx])([wubrgyx])/i;
    $cc1 = $1;
    $cc2 = $2;
    $cc3 = $3;
    $cc4 = $4;

    if ($human_chosen_code =~ m/$cc1/i) { $ret =~ s/0/1/; $human_chosen_code =~ s/$cc1/A/i; }
    if ($human_chosen_code =~ m/$cc2/i) { $ret =~ s/0/1/; $human_chosen_code =~ s/$cc2/A/i; }
    if ($human_chosen_code =~ m/$cc3/i) { $ret =~ s/0/1/; $human_chosen_code =~ s/$cc3/A/i; }
    if ($human_chosen_code =~ m/$cc4/i) { $ret =~ s/0/1/; $human_chosen_code =~ s/$cc4/A/i; }

    return $ret;
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
    $txt .= "            client.get('/mastermind/needs_refresh', function(response) {\n";
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
    $txt .= "<a href=\"\/mastermind\/force_refresh\">Force Refresh<\/a> or reset the game here: <a href=\"reset_game\">Reset<\/a><br><br><br>";
    return $txt;
}

sub colors_match
{
    my $code = $_ [0];
    my $guess_orig = $_ [1];

    my %c1;
    my %c2;

    $code =~ m/(.)(.)(.)(.)/;
    $c1 {$1}++;
    $c1 {$2}++;
    $c1 {$3}++;
    $c1 {$4}++;

    $guess_orig =~ m/(.)(.)(.)(.)/;
    $c2 {$1}++;
    $c2 {$2}++;
    $c2 {$3}++;
    $c2 {$4}++;

    my $k;
    foreach $k (keys (%c1))
    {
        if (!exists ($c2 {$k}))
        {
            return 0;
        }
        if ($c2 {$k} != $c1 {$k})
        {
            return 0;
        }
    }
    return 1;
}

sub num_beads_match
{
    my $code = $_ [0];
    my $guess_orig = $_ [1];

    $code =~ m/(.)(.)(.)(.)/;
    my $b1 = $1;
    my $b2 = $2;
    my $b3 = $3;
    my $b4 = $4;

    $guess_orig =~ m/(.)(.)(.)(.)/;
    my $z1 = $1;
    my $z2 = $2;
    my $z3 = $3;
    my $z4 = $4;

    my $match = 0;
    if ($b1 eq $z1) { $match++; }
    if ($b2 eq $z2) { $match++; }
    if ($b3 eq $z3) { $match++; }
    if ($b4 eq $z4) { $match++; }

    return $match;
}

sub num_partial_beads_match
{
    my $code = $_ [0];
    my $guess = $_ [1];
    my $guess_orig = $guess;
    my $code_orig = $code;

    $code =~ m/(.)(.)(.)(.)/;
    my $b1 = $1;
    my $b2 = $2;
    my $b3 = $3;
    my $b4 = $4;

    $guess =~ m/(.)(.)(.)(.)/;
    my $z1 = $1;
    my $z2 = $2;
    my $z3 = $3;
    my $z4 = $4;

    my $partial_match = 0;
    if ($b1 eq $z1) { $code =~ s/^./X/;        $guess =~ s/^./Z/;  }
    if ($b2 eq $z2) { $code =~ s/^(.)./$1X/;   $guess =~ s/^(.)./$1Z/;  }
    if ($b3 eq $z3) { $code =~ s/^(..)./$1X/;  $guess =~ s/^(..)./$1Z/;  }
    if ($b4 eq $z4) { $code =~ s/^(...)./$1X/; $guess =~ s/^(...)./$1Z/;  }

    $code =~ m/(.)(.)(.)(.)/;
    $b1 = $1;
    $b2 = $2;
    $b3 = $3;
    $b4 = $4;

    if ($guess =~ m/$b1/) { $guess =~ s/$b1/Z/; $partial_match++; }
    if ($guess =~ m/$b2/) { $guess =~ s/$b2/Z/; $partial_match++; }
    if ($guess =~ m/$b3/) { $guess =~ s/$b3/Z/; $partial_match++; }
    if ($guess =~ m/$b4/) { $guess =~ s/$b4/Z/; $partial_match++; }

    return $partial_match;
}

sub get_valid_choices
{
    my $term = $_ [0];
    my $helper = $_ [1];

    my %mm;
    my %num_cols_in_mm;
    my %colors;
    $colors {"W"} = 1;
    $colors {"U"} = 1;
    $colors {"B"} = 1;
    $colors {"R"} = 1;
    $colors {"G"} = 1;
    $colors {"Y"} = 1;
    my $orig_helper = $helper;

    my $c = 0;
    my $c1;
    my $c2;
    my $c3;
    my $c4;
    foreach $c1 (sort (keys (%colors)))
    {
        foreach $c2 (sort (keys (%colors)))
        {
            foreach $c3 (sort (keys (%colors)))
            {
                foreach $c4 (sort (keys (%colors)))
                {
                    $c++;
                    my $code = "$c1$c2$c3$c4";
                    my $code2 = "$c1$c2$c3$c4";
                    $mm {$code} = 1;

                    my $num_same = 0;
                    if ($c1 eq $c2) { $num_same++; }
                    if ($c1 eq $c3) { $num_same++; }
                    if ($c1 eq $c4) { $num_same++; }
                    if ($c2 eq $c3 && $c2 ne $c1) { $num_same++; }
                    if ($c2 eq $c4 && $c2 ne $c1) { $num_same++; }
                    if ($c3 eq $c4 && $c3 ne $c1 && $c3 ne $c2) { $num_same++; }

                    my $num_cols = 4 - $num_same;
                    $num_cols_in_mm {$code} = $num_cols;
                }
            }
        }
    }

    my $num_eliminated = 0;
    $term = uc ($term);
    while ($term =~ s/^([WUBRGY][WUBRGY][WUBRGY][WUBRGY])(,|$)//)
    {
        my $guess_orig = $1;
        my $guess = $1;
        my %cols_in_guess;
        my $cols_in_guess_re = "[";
        my $number_cols_in_guess = 0;
        my $number_correct_cols_in_guess = 0;

        while ($guess =~ s/^([WUBRGY])//i)
        {
            my $col = $1;
            if (!defined ($cols_in_guess {$col}))
            {
                $number_cols_in_guess ++;
                $cols_in_guess_re .= $col;
            }
            $cols_in_guess {$col}++;
        }

        $cols_in_guess_re .= "]";
        my $real_helper = $helper;
        if ($orig_helper =~ m/^([WUBRGY])([WUBRGY])([WUBRGY])([WUBRGY])/i)
        {
            $real_helper = "0000";

            my $sac_helper = $orig_helper;
            my $sac_guess = $guess_orig;
            my $left_over_answer = "";
            my $left_over_guess = "";
            while ($sac_helper =~ s/^(.)//)
            {
                my $c = $1;
                if ($sac_guess =~ m/^$c/i)
                {
                    $real_helper =~ s/0/2/;
                }
                else
                {
                    $left_over_answer .= "$c";
                    $sac_guess =~ m/^(.)/;
                    $left_over_guess .= "$1";
                }

                $sac_guess =~ s/^.//;
            }

            if ($left_over_answer =~ m/W/i && $left_over_guess =~ m/W/i) { $real_helper =~ s/0/1/; }
            if ($left_over_answer =~ m/U/i && $left_over_guess =~ m/U/i) { $real_helper =~ s/0/1/; }
            if ($left_over_answer =~ m/B/i && $left_over_guess =~ m/B/i) { $real_helper =~ s/0/1/; }
            if ($left_over_answer =~ m/R/i && $left_over_guess =~ m/R/i) { $real_helper =~ s/0/1/; }
            if ($left_over_answer =~ m/G/i && $left_over_guess =~ m/G/i) { $real_helper =~ s/0/1/; }
            if ($left_over_answer =~ m/Y/i && $left_over_guess =~ m/Y/i) { $real_helper =~ s/0/1/; }
            $helper = $real_helper;
        }

        if ($helper =~ s/^([012][012][012][012])(,|$)//)
        {
            my $guess_result = $1;
            my $guess_result_orig = $1;
            my $num_absolutely_correct = 0;
            my $num_half_correct = 0;
            my $num_incorrect = 4;

            while ($guess_result =~ s/1//)
            {
                $num_half_correct ++;
                $number_correct_cols_in_guess ++;
                $num_incorrect --;

                if ($cols_in_guess {"W"} > 1) { $cols_in_guess {"W"} --; }
                elsif ($cols_in_guess {"U"} > 1) { $cols_in_guess {"U"} --; }
                elsif ($cols_in_guess {"B"} > 1) { $cols_in_guess {"B"} --; }
                elsif ($cols_in_guess {"R"} > 1) { $cols_in_guess {"R"} --; }
                elsif ($cols_in_guess {"G"} > 1) { $cols_in_guess {"G"} --; }
                elsif ($cols_in_guess {"Y"} > 1) { $cols_in_guess {"Y"} --; }
                elsif ($cols_in_guess {"W"} == 1) { $cols_in_guess {"W"} --; }
                elsif ($cols_in_guess {"U"} == 1) { $cols_in_guess {"U"} --; }
                elsif ($cols_in_guess {"B"} == 1) { $cols_in_guess {"B"} --; }
                elsif ($cols_in_guess {"R"} == 1) { $cols_in_guess {"R"} --; }
                elsif ($cols_in_guess {"G"} == 1) { $cols_in_guess {"G"} --; }
                elsif ($cols_in_guess {"Y"} == 1) { $cols_in_guess {"Y"} --; }
            }

            while ($guess_result =~ s/2//)
            {
                $num_absolutely_correct ++;
                $number_correct_cols_in_guess ++;
                $num_incorrect --;

                if ($cols_in_guess {"W"} > 1) { $cols_in_guess {"W"} --; }
                elsif ($cols_in_guess {"U"} > 1) { $cols_in_guess {"U"} --; }
                elsif ($cols_in_guess {"B"} > 1) { $cols_in_guess {"B"} --; }
                elsif ($cols_in_guess {"R"} > 1) { $cols_in_guess {"R"} --; }
                elsif ($cols_in_guess {"G"} > 1) { $cols_in_guess {"G"} --; }
                elsif ($cols_in_guess {"Y"} > 1) { $cols_in_guess {"Y"} --; }
                elsif ($cols_in_guess {"W"} == 1) { $cols_in_guess {"W"} --; }
                elsif ($cols_in_guess {"U"} == 1) { $cols_in_guess {"U"} --; }
                elsif ($cols_in_guess {"B"} == 1) { $cols_in_guess {"B"} --; }
                elsif ($cols_in_guess {"R"} == 1) { $cols_in_guess {"R"} --; }
                elsif ($cols_in_guess {"G"} == 1) { $cols_in_guess {"G"} --; }
                elsif ($cols_in_guess {"Y"} == 1) { $cols_in_guess {"Y"} --; }
            }

            my $min_number_cols_correct_in_guess = 4;
            $min_number_cols_correct_in_guess -= $cols_in_guess {"W"};
            $min_number_cols_correct_in_guess -= $cols_in_guess {"U"};
            $min_number_cols_correct_in_guess -= $cols_in_guess {"B"};
            $min_number_cols_correct_in_guess -= $cols_in_guess {"R"};
            $min_number_cols_correct_in_guess -= $cols_in_guess {"G"};
            $min_number_cols_correct_in_guess -= $cols_in_guess {"Y"};

            my $all_correct;
            if ($min_number_cols_correct_in_guess == 4)
            {
                $all_correct = "^[$guess_orig][$guess_orig][$guess_orig][$guess_orig]\$";
            }

            if ($num_incorrect == 4)
            {
                my $code;
                foreach $code (sort (keys (%mm)))
                {
                    if ($code =~ m/$cols_in_guess_re/)
                    {
                        if ($mm {$code} == 1)
                        {
                            $num_eliminated ++;
                        }
                        $mm {$code} = 0;
                    }
                }
            }

            my $partial_count = 0;
            my $check_partial;
            while ($partial_count + $num_incorrect < 4)
            {
                # check what must exist in solution
                $check_partial .= $cols_in_guess_re . ".*";
                $partial_count++;
            }

            if ($partial_count > 0)
            {
                my $code;
                foreach $code (sort (keys (%mm)))
                {
                    if ($mm {$code} == 1 && $min_number_cols_correct_in_guess > $num_cols_in_mm {$code} && $min_number_cols_correct_in_guess < 4)
                    {
                        $num_eliminated ++;
                    }

                    if ($mm {$code} == 1 && $min_number_cols_correct_in_guess == 4)
                    {
                        if ($code !~ m/$all_correct/img)
                        {
                            $num_eliminated ++;
                            $mm {$code} = 0;
                        }
                    }

                    if ($mm {$code} == 1 && !($code =~ m/$check_partial/))
                    {
                        $num_eliminated ++;
                        $mm {$code} = 0;
                    }
                }
            }

            # all greys!
            if ($num_absolutely_correct == 0 && $num_half_correct > 0)
            {
                my $code;
                $guess_orig =~ m/(.)(.)(.)(.)/;

                my $a = $1;
                my $b = $2;
                my $c = $3;
                my $d = $4;

                my $wrong_1 = "$a...";
                my $wrong_2 = ".$b..";
                my $wrong_3 = "..$c.";
                my $wrong_4 = "...$d";

                foreach $code (sort (keys (%mm)))
                {
                    if ($code =~ m/$wrong_1/ || $code =~ m/$wrong_2/ || $code =~ m/$wrong_3/ || $code =~ m/$wrong_4/)
                    {
                        if ($mm {$code} == 1)
                        {
                            $num_eliminated ++;
                        }
                        $mm {$code} = 0;
                    }
                }
            }

            # more than 1 partially correct
            if ($num_half_correct > 1)
            {
                my $code;
                $guess_orig =~ m/(.)(.)(.)(.)/;

                my $a = $1;
                my $b = $2;
                my $c = $3;
                my $d = $4;

                my $right_1 = "($a.*$b|$a.*$c|$a.*$d|$b.*$c|$b.*$d|$c.*$d)";
                my $right_2 = "($b.*$a|$c.*$a|$d.*$a|$c.*$b|$d.*$b|$d.*$c)";

                foreach $code (sort (keys (%mm)))
                {
                    if (!($code =~ m/$right_1/ || $code =~ m/$right_2/))
                    {
                        if ($mm {$code} == 1)
                        {
                            $num_eliminated ++;
                        }
                        $mm {$code} = 0;
                    }

                    if (num_beads_match ($code, $guess_orig) != $num_absolutely_correct)
                    {
                        if ($mm {$code} == 1)
                        {
                            $num_eliminated ++;
                        }
                        $mm {$code} = 0;
                    }

                }
            }

            # more than 2 partially correct
            if ($num_half_correct > 2)
            {
                my $code;
                $guess_orig =~ m/(.)(.)(.)(.)/;

                my $a = $1;
                my $b = $2;
                my $c = $3;
                my $d = $4;

                my $right_1 = "($a.*$b.*$c|$a.*$b.*$d|$a.*$c.*$b|$a.*$c.*$d|$a.*$d.*$b|$a.*$d.*$c|$b.*$a.*$c|$b.*$a.*$d|$b.*$c.*$a|$b.*$c.*$d|$b.*$d.*$a|$b.*$d.*$c|$c.*$a.*$b|$c.*$a.*$d|$c.*$b.*$a|$c.*$b.*$d|$c.*$d.*$a|$c.*$d.*$b|$d.*$a.*$b|$d.*$a.*$c|$d.*$b.*$a|$d.*$b.*$c|$d.*$c.*$a|$d.*$c.*$b)";

                foreach $code (sort (keys (%mm)))
                {
                    if (!($code =~ m/$right_1/))
                    {
                        if ($mm {$code} == 1)
                        {
                            $num_eliminated ++;
                        }
                        $mm {$code} = 0;
                    }

                    if (num_beads_match ($code, $guess_orig) != $num_absolutely_correct)
                    {
                        if ($mm {$code} == 1)
                        {
                            $num_eliminated ++;
                        }
                        $mm {$code} = 0;
                    }
                }
            }

            if ($num_absolutely_correct == 1 && $num_half_correct == 0)
            {
                my $code;
                $guess_orig =~ m/(.)(.)(.)(.)/;

                my $a = $1;
                my $b = $2;
                my $c = $3;
                my $d = $4;

                my $wrong_1a = "$a" . "[$b$c$d]..";
                my $wrong_1b = "$a" . ".[$b$c$d].";
                my $wrong_1c = "$a" . "..[$b$c$d]";

                my $wrong_2a = "[$a$c$d]$b" . "..";
                my $wrong_2b = ".$b" . "[$a$c$d].";
                my $wrong_2c = ".$b" . ".[$a$c$d]";

                my $wrong_3a = "[$a$b$d].$c" . ".";
                my $wrong_3b = ".[$a$b$d]$c" . ".";
                my $wrong_3c = "..$c" . "[$a$b$d]";

                my $wrong_4a = "[$a$b$c].." . "$d";
                my $wrong_4b = ".[$a$b$c]." . "$d";
                my $wrong_4c = "..[$a$b$c]" . "$d";

                foreach $code (sort (keys (%mm)))
                {
                    if ($code =~ m/$wrong_1a/ || $code =~ m/$wrong_1b/ || $code =~ m/$wrong_1c/ ||
                        $code =~ m/$wrong_2a/ || $code =~ m/$wrong_2b/ || $code =~ m/$wrong_2c/ ||
                        $code =~ m/$wrong_3a/ || $code =~ m/$wrong_3b/ || $code =~ m/$wrong_3c/ ||
                        $code =~ m/$wrong_4a/ || $code =~ m/$wrong_4b/ || $code =~ m/$wrong_4c/)
                    {
                        if ($mm {$code} == 1)
                        {
                            $num_eliminated ++;
                        }
                        $mm {$code} = 0;
                    }

                    if (num_beads_match ($code, $guess_orig) != $num_absolutely_correct)
                    {
                        if ($mm {$code} == 1)
                        {
                            $num_eliminated ++;
                        }
                        $mm {$code} = 0;
                    }
                }
            }

            if ($num_absolutely_correct == 0 && $num_half_correct == 1)
            {
                my $code;
                $guess_orig =~ m/(.)(.)(.)(.)/;

                my $a = $1;
                my $b = $2;
                my $c = $3;
                my $d = $4;

                my $wrong_1 = "($a.*$b|$a.*$c|$a.*$d|$b.*$c|$b.*$d|$c.*$d)";
                my $wrong_2 = "($b.*$a|$c.*$a|$d.*$a|$c.*$b|$d.*$b|$d.*$c)";

                foreach $code (sort (keys (%mm)))
                {
                    if ($code =~ m/$wrong_1/ || $code =~ m/$wrong_2/)
                    {
                        if ($mm {$code} == 1)
                        {
                            $num_eliminated ++;
                        }
                        $mm {$code} = 0;
                    }
                }
            }

            if ($num_absolutely_correct == 2 && $num_half_correct == 2)
            {
                my $code;
                $guess_orig =~ m/(.)(.)(.)(.)/;

                my $a = $1;
                my $b = $2;
                my $c = $3;
                my $d = $4;

                my $right_1 = "$a$b$d$c";
                my $right_2 = "$a$c$b$d";
                my $right_3 = "$a$d$c$b";
                my $right_4 = "$b$a$c$d";
                my $right_5 = "$c$b$a$d";
                my $right_6 = "$d$b$c$a";

                foreach $code (sort (keys (%mm)))
                {
                    if (!($code =~ m/$right_1/ || $code =~ m/$right_2/ || $code =~ m/$right_3/ || $code =~ m/$right_4/ || $code =~ m/$right_5/ || $code =~ m/$right_6/))
                    {
                        if ($mm {$code} == 1)
                        {
                            $num_eliminated ++;
                        }
                        $mm {$code} = 0;
                    }

                    if (num_beads_match ($code, $guess_orig) != $num_absolutely_correct)
                    {
                        if ($mm {$code} == 1)
                        {
                            $num_eliminated ++;
                        }
                        $mm {$code} = 0;
                    }
                }
            }

            if ($num_absolutely_correct == 1 && $num_half_correct == 3)
            {
                my $code;
                $guess_orig =~ m/(.)(.)(.)(.)/;

                my $a = $1;
                my $b = $2;
                my $c = $3;
                my $d = $4;

                my $right_1 = "$a" . "[$b$c$d][$b$c$d][$b$c$d]";
                my $right_2 = "[$a$c$d]$b" . "[$a$c$d][$a$c$d]";
                my $right_3 = "[$a$b$d][$a$b$d]$c" . "[$a$b$d]";
                my $right_4 = "[$a$b$c][$a$b$c][$a$b$c]". "$d";

                foreach $code (sort (keys (%mm)))
                {
                    if (!($code =~ m/$right_1/ || $code =~ m/$right_2/ || $code =~ m/$right_3/ || $code =~ m/$right_4/))
                    {
                        if ($mm {$code} == 1)
                        {
                            $num_eliminated ++;
                        }
                        $mm {$code} = 0;
                    }

                    if (!colors_match ($code, $guess_orig))
                    {
                        if ($mm {$code} == 1)
                        {
                            $num_eliminated ++;
                        }
                        $mm {$code} = 0;
                    }

                    if (num_beads_match ($code, $guess_orig) != 1)
                    {
                        if ($mm {$code} == 1)
                        {
                            $num_eliminated ++;
                        }
                        $mm {$code} = 0;
                    }
                }
            }

            # some blacks!
            if ($num_absolutely_correct >= 1)
            {
                my $code;
                my $right_1 = $guess_orig; $right_1 =~ s/...$/.../;
                my $right_2 = $guess_orig; $right_2 =~ s/^././;  $right_2 =~ s/..$/../;
                my $right_3 = $guess_orig; $right_3 =~ s/^../../ ;$right_3 =~ s/.$/./;
                my $right_4 = $guess_orig; $right_4 =~ s/^.../.../;

                foreach $code (sort (keys (%mm)))
                {
                    if (!($code =~ m/$right_1/ || $code =~ m/$right_2/ || $code =~ m/$right_3/ || $code =~ m/$right_4/))
                    {
                        if ($mm {$code} == 1)
                        {
                            $num_eliminated ++;
                        }
                        $mm {$code} = 0;
                    }

                    if (num_beads_match ($code, $guess_orig) != $num_absolutely_correct)
                    {
                        if ($mm {$code} == 1)
                        {
                            $num_eliminated ++;
                        }
                        $mm {$code} = 0;
                    }
                }
            }

            if ($num_absolutely_correct >= 2)
            {
                my $code;
                my $right_1 = $guess_orig; $right_1 =~ s/^(.)(.)../$1$2../;
                my $right_2 = $guess_orig; $right_2 =~ s/^(.).(.)./$1.$2./;
                my $right_3 = $guess_orig; $right_3 =~ s/^(.)..(.)/$1..$2/;
                my $right_4 = $guess_orig; $right_4 =~ s/^.(.).(.)/.$1.$2/;
                my $right_5 = $guess_orig; $right_5 =~ s/^.(.)(.)./.$1$2./;
                my $right_6 = $guess_orig; $right_6 =~ s/^..(.)(.)/..$1$2/;

                foreach $code (sort (keys (%mm)))
                {
                    if (!($code =~ m/$right_1/ || $code =~ m/$right_2/ || $code =~ m/$right_3/ || $code =~ m/$right_4/ || $code =~ m/$right_5/ || $code =~ m/$right_6/))
                    {
                        if ($mm {$code} == 1)
                        {
                            $num_eliminated ++;
                        }
                        $mm {$code} = 0;
                    }

                    if (num_beads_match ($code, $guess_orig) != $num_absolutely_correct)
                    {
                        if ($mm {$code} == 1)
                        {
                            $num_eliminated ++;
                        }
                        $mm {$code} = 0;
                    }
                }
            }

            if ($num_absolutely_correct >= 3)
            {
                my $code;
                my $right_1 = $guess_orig; $right_1 =~ s/^(.)(.)(.)./$1$2$3./;
                my $right_2 = $guess_orig; $right_2 =~ s/^(.)(.).(.)/$1$2.$3/;
                my $right_3 = $guess_orig; $right_3 =~ s/^(.).(.)(.)/$1.$2$3/;
                my $right_4 = $guess_orig; $right_4 =~ s/^.(.)(.)(.)/.$1$2$3/;

                foreach $code (sort (keys (%mm)))
                {
                    if (!($code =~ m/$right_1/ || $code =~ m/$right_2/ || $code =~ m/$right_3/ || $code =~ m/$right_4/))
                    {
                        if ($mm {$code} == 1)
                        {
                            $num_eliminated ++;
                        }
                        $mm {$code} = 0;
                    }

                    if (num_beads_match ($code, $guess_orig) != $num_absolutely_correct)
                    {
                        if ($mm {$code} == 1)
                        {
                            $num_eliminated ++;
                        }
                        $mm {$code} = 0;
                    }
                }
            }

            my $left_over = 0;
            my $code;
            foreach $code (sort (keys (%mm)))
            {
                $left_over += $mm {$code};
            }
        }
    }

    my $code;
    my $final_code = "INVALID";

    my $rand_code = int (rand ((scalar keys %mm) - $num_eliminated));
    my $solution_count = 0;

    foreach $code (sort (keys (%mm)))
    {
        if ($mm {$code} == 1)
        {
            $solution_count++;
        }
    }

    my $rand_code = int (rand ($solution_count));
    my $rr_count = 0;
    foreach $code (sort (keys (%mm)))
    {
        if ($mm {$code} == 1)
        {
            if ($rand_code == $rr_count)
            {
                $final_code = $code;
            }
            $rr_count++;
        }
    }

    if ($final_code =~ m/INVALID/)
    {
        return $final_code;
    }
    return $final_code;
}

sub get_number_matching_codes
{
    my $term = $_ [0];
    my $helper = $_ [1];
    my $answer = $_ [2];

    my $orig_term = $term;
    my $orig_helper = $helper;
    my $orig_answer = $answer;
    $helper =~ s/\d\d\d\d,$/$answer,/;

    my %mm;
    my %num_cols_in_mm;
    my %colors;
    $colors {"W"} = 1;
    $colors {"U"} = 1;
    $colors {"B"} = 1;
    $colors {"R"} = 1;
    $colors {"G"} = 1;
    $colors {"Y"} = 1;
    my $orig_helper = $helper;

    my $c = 0;
    my $c1;
    my $c2;
    my $c3;
    my $c4;
    foreach $c1 (sort (keys (%colors)))
    {
        foreach $c2 (sort (keys (%colors)))
        {
            foreach $c3 (sort (keys (%colors)))
            {
                foreach $c4 (sort (keys (%colors)))
                {
                    $c++;
                    my $code = "$c1$c2$c3$c4";
                    my $code2 = "$c1$c2$c3$c4";
                    $mm {$code} = 1;

                    my $num_same = 0;
                    if ($c1 eq $c2) { $num_same++; }
                    if ($c1 eq $c3) { $num_same++; }
                    if ($c1 eq $c4) { $num_same++; }
                    if ($c2 eq $c3 && $c2 ne $c1) { $num_same++; }
                    if ($c2 eq $c4 && $c2 ne $c1) { $num_same++; }
                    if ($c3 eq $c4 && $c3 ne $c1 && $c3 ne $c2) { $num_same++; }

                    my $num_cols = 4 - $num_same;
                    $num_cols_in_mm {$code} = $num_cols;
                }
            }
        }
    }

    my $num_eliminated = 0;
    my $last_term;
    $term = uc ($term);
    while ($term =~ s/^([WUBRGY][WUBRGY][WUBRGY][WUBRGY])(,|$)//)
    {
        my $guess_orig = $1;
        my $guess = $1;
        $last_term = $guess_orig;
        my %cols_in_guess;
        my $cols_in_guess_re = "[";
        my $number_cols_in_guess = 0;
        my $number_correct_cols_in_guess = 0;

        while ($guess =~ s/^([WUBRGY])//i)
        {
            my $col = $1;
            if (!defined ($cols_in_guess {$col}))
            {
                $number_cols_in_guess ++;
                $cols_in_guess_re .= $col;
            }
            $cols_in_guess {$col}++;
        }

        $cols_in_guess_re .= "]";
        my $real_helper = $helper;
        if ($orig_helper =~ m/^([WUBRGY])([WUBRGY])([WUBRGY])([WUBRGY])/i)
        {
            $real_helper = "0000";

            my $sac_helper = $orig_helper;
            my $sac_guess = $guess_orig;
            my $left_over_answer = "";
            my $left_over_guess = "";
            while ($sac_helper =~ s/^(.)//)
            {
                my $c = $1;
                if ($sac_guess =~ m/^$c/i)
                {
                    $real_helper =~ s/0/2/;
                }
                else
                {
                    $left_over_answer .= "$c";
                    $sac_guess =~ m/^(.)/;
                    $left_over_guess .= "$1";
                }

                $sac_guess =~ s/^.//;
            }

            if ($left_over_answer =~ m/W/i && $left_over_guess =~ m/W/i) { $real_helper =~ s/0/1/; }
            if ($left_over_answer =~ m/U/i && $left_over_guess =~ m/U/i) { $real_helper =~ s/0/1/; }
            if ($left_over_answer =~ m/B/i && $left_over_guess =~ m/B/i) { $real_helper =~ s/0/1/; }
            if ($left_over_answer =~ m/R/i && $left_over_guess =~ m/R/i) { $real_helper =~ s/0/1/; }
            if ($left_over_answer =~ m/G/i && $left_over_guess =~ m/G/i) { $real_helper =~ s/0/1/; }
            if ($left_over_answer =~ m/Y/i && $left_over_guess =~ m/Y/i) { $real_helper =~ s/0/1/; }
            $helper = $real_helper;
        }

        if ($helper =~ s/^([012][012][012][012])(,|$)//)
        {
            my $guess_result = $1;
            my $guess_result_orig = $1;
            my $num_absolutely_correct = 0;
            my $num_half_correct = 0;
            my $num_incorrect = 4;

            while ($guess_result =~ s/1//)
            {
                $num_half_correct ++;
                $number_correct_cols_in_guess ++;
                $num_incorrect --;

                if ($cols_in_guess {"W"} > 1) { $cols_in_guess {"W"} --; }
                elsif ($cols_in_guess {"U"} > 1) { $cols_in_guess {"U"} --; }
                elsif ($cols_in_guess {"B"} > 1) { $cols_in_guess {"B"} --; }
                elsif ($cols_in_guess {"R"} > 1) { $cols_in_guess {"R"} --; }
                elsif ($cols_in_guess {"G"} > 1) { $cols_in_guess {"G"} --; }
                elsif ($cols_in_guess {"Y"} > 1) { $cols_in_guess {"Y"} --; }
                elsif ($cols_in_guess {"W"} == 1) { $cols_in_guess {"W"} --; }
                elsif ($cols_in_guess {"U"} == 1) { $cols_in_guess {"U"} --; }
                elsif ($cols_in_guess {"B"} == 1) { $cols_in_guess {"B"} --; }
                elsif ($cols_in_guess {"R"} == 1) { $cols_in_guess {"R"} --; }
                elsif ($cols_in_guess {"G"} == 1) { $cols_in_guess {"G"} --; }
                elsif ($cols_in_guess {"Y"} == 1) { $cols_in_guess {"Y"} --; }
            }

            while ($guess_result =~ s/2//)
            {
                $num_absolutely_correct ++;
                $number_correct_cols_in_guess ++;
                $num_incorrect --;

                if ($cols_in_guess {"W"} > 1) { $cols_in_guess {"W"} --; }
                elsif ($cols_in_guess {"U"} > 1) { $cols_in_guess {"U"} --; }
                elsif ($cols_in_guess {"B"} > 1) { $cols_in_guess {"B"} --; }
                elsif ($cols_in_guess {"R"} > 1) { $cols_in_guess {"R"} --; }
                elsif ($cols_in_guess {"G"} > 1) { $cols_in_guess {"G"} --; }
                elsif ($cols_in_guess {"Y"} > 1) { $cols_in_guess {"Y"} --; }
                elsif ($cols_in_guess {"W"} == 1) { $cols_in_guess {"W"} --; }
                elsif ($cols_in_guess {"U"} == 1) { $cols_in_guess {"U"} --; }
                elsif ($cols_in_guess {"B"} == 1) { $cols_in_guess {"B"} --; }
                elsif ($cols_in_guess {"R"} == 1) { $cols_in_guess {"R"} --; }
                elsif ($cols_in_guess {"G"} == 1) { $cols_in_guess {"G"} --; }
                elsif ($cols_in_guess {"Y"} == 1) { $cols_in_guess {"Y"} --; }
            }

            my $col;
            foreach $col (sort (keys (%cols_in_guess)))
            {
            }

            my $min_number_cols_correct_in_guess = 4;
            $min_number_cols_correct_in_guess -= $cols_in_guess {"W"};
            $min_number_cols_correct_in_guess -= $cols_in_guess {"U"};
            $min_number_cols_correct_in_guess -= $cols_in_guess {"B"};
            $min_number_cols_correct_in_guess -= $cols_in_guess {"R"};
            $min_number_cols_correct_in_guess -= $cols_in_guess {"G"};
            $min_number_cols_correct_in_guess -= $cols_in_guess {"Y"};

            my $all_correct;
            if ($min_number_cols_correct_in_guess == 4)
            {
                $all_correct = "^[$guess_orig][$guess_orig][$guess_orig][$guess_orig]\$";
            }

            if ($num_absolutely_correct == 4)
            {
            }

            if ($num_incorrect == 4)
            {
                my $code;
                foreach $code (sort (keys (%mm)))
                {
                    if ($code =~ m/$cols_in_guess_re/)
                    {
                        if ($mm {$code} == 1)
                        {
                            $num_eliminated ++;
                        }
                        $mm {$code} = 0;
                    }
                }
            }

            my $partial_count = 0;
            my $check_partial;
            while ($partial_count + $num_incorrect < 4)
            {
                # check what must exist in solution
                $check_partial .= $cols_in_guess_re . ".*";
                $partial_count++;
            }

            if ($partial_count > 0)
            {
                my $code;
                foreach $code (sort (keys (%mm)))
                {
                    if ($mm {$code} == 1 && $min_number_cols_correct_in_guess > $num_cols_in_mm {$code} && $min_number_cols_correct_in_guess < 4)
                    {
                        $num_eliminated ++;
                        #$mm {$code} = 0;
                        #$num_eliminated ++;
                    }

                    if ($mm {$code} == 1 && $min_number_cols_correct_in_guess == 4)
                    {
                        if ($code !~ m/$all_correct/img)
                        {
                            $num_eliminated ++;
                            $mm {$code} = 0;
                        }
                    }

                    if ($mm {$code} == 1 && !($code =~ m/$check_partial/))
                    {
                        $num_eliminated ++;
                        $mm {$code} = 0;
                    }
                }
            }

            # all greys!
            if ($num_absolutely_correct == 0 && $num_half_correct > 0)
            {
                my $code;
                $guess_orig =~ m/(.)(.)(.)(.)/;

                my $a = $1;
                my $b = $2;
                my $c = $3;
                my $d = $4;

                my $wrong_1 = "$a...";
                my $wrong_2 = ".$b..";
                my $wrong_3 = "..$c.";
                my $wrong_4 = "...$d";

                foreach $code (sort (keys (%mm)))
                {
                    if ($code =~ m/$wrong_1/ || $code =~ m/$wrong_2/ || $code =~ m/$wrong_3/ || $code =~ m/$wrong_4/)
                    {
                        if ($mm {$code} == 1)
                        {
                            $num_eliminated ++;
                        }
                        $mm {$code} = 0;
                    }
                }
            }

            # more than 1 partially correct
            if ($num_half_correct > 1)
            {
                my $code;
                $guess_orig =~ m/(.)(.)(.)(.)/;

                my $a = $1;
                my $b = $2;
                my $c = $3;
                my $d = $4;

                my $right_1 = "($a.*$b|$a.*$c|$a.*$d|$b.*$c|$b.*$d|$c.*$d)";
                my $right_2 = "($b.*$a|$c.*$a|$d.*$a|$c.*$b|$d.*$b|$d.*$c)";

                foreach $code (sort (keys (%mm)))
                {
                    if (!($code =~ m/$right_1/ || $code =~ m/$right_2/))
                    {
                        if ($mm {$code} == 1)
                        {
                            $num_eliminated ++;
                        }
                        $mm {$code} = 0;
                    }

                    if (num_beads_match ($code, $guess_orig) != $num_absolutely_correct)
                    {
                        if ($mm {$code} == 1)
                        {
                            $num_eliminated ++;
                        }
                        $mm {$code} = 0;
                    }

                    my $npbm = num_partial_beads_match ($code, $guess_orig);
                    if ($mm {$code} == 1)
                    {
                    }
                    if (num_partial_beads_match ($code, $guess_orig) != $num_half_correct && $mm {$code} == 1)
                    {
                        if ($mm {$code} == 1)
                        {
                            $num_eliminated ++;
                        }
                        $mm {$code} = 0;
                    }
                }
            }

            # more than 2 partially correct
            if ($num_half_correct > 2)
            {
                my $code;
                $guess_orig =~ m/(.)(.)(.)(.)/;

                my $a = $1;
                my $b = $2;
                my $c = $3;
                my $d = $4;

                my $right_1 = "($a.*$b.*$c|$a.*$b.*$d|$a.*$c.*$b|$a.*$c.*$d|$a.*$d.*$b|$a.*$d.*$c|$b.*$a.*$c|$b.*$a.*$d|$b.*$c.*$a|$b.*$c.*$d|$b.*$d.*$a|$b.*$d.*$c|$c.*$a.*$b|$c.*$a.*$d|$c.*$b.*$a|$c.*$b.*$d|$c.*$d.*$a|$c.*$d.*$b|$d.*$a.*$b|$d.*$a.*$c|$d.*$b.*$a|$d.*$b.*$c|$d.*$c.*$a|$d.*$c.*$b)";

                foreach $code (sort (keys (%mm)))
                {
                    if (!($code =~ m/$right_1/))
                    {
                        if ($mm {$code} == 1)
                        {
                            $num_eliminated ++;
                        }
                        $mm {$code} = 0;
                    }

                    if (num_beads_match ($code, $guess_orig) != $num_absolutely_correct)
                    {
                        if ($mm {$code} == 1)
                        {
                            $num_eliminated ++;
                        }
                        $mm {$code} = 0;
                    }

                    my $npbm = num_partial_beads_match ($code, $guess_orig);
                    if ($mm {$code} == 1)
                    {
                    }
                    if (num_partial_beads_match ($code, $guess_orig) != $num_half_correct && $mm {$code} == 1)
                    {
                        if ($mm {$code} == 1)
                        {
                            $num_eliminated ++;
                        }
                        $mm {$code} = 0;
                    }
                }
            }

            if ($num_absolutely_correct == 1 && $num_half_correct == 0)
            {
                my $code;
                $guess_orig =~ m/(.)(.)(.)(.)/;

                my $a = $1;
                my $b = $2;
                my $c = $3;
                my $d = $4;

                my $wrong_1a = "$a" . "[$b$c$d]..";
                my $wrong_1b = "$a" . ".[$b$c$d].";
                my $wrong_1c = "$a" . "..[$b$c$d]";

                my $wrong_2a = "[$a$c$d]$b" . "..";
                my $wrong_2b = ".$b" . "[$a$c$d].";
                my $wrong_2c = ".$b" . ".[$a$c$d]";

                my $wrong_3a = "[$a$b$d].$c" . ".";
                my $wrong_3b = ".[$a$b$d]$c" . ".";
                my $wrong_3c = "..$c" . "[$a$b$d]";

                my $wrong_4a = "[$a$b$c].." . "$d";
                my $wrong_4b = ".[$a$b$c]." . "$d";
                my $wrong_4c = "..[$a$b$c]" . "$d";

                foreach $code (sort (keys (%mm)))
                {
                    if ($code =~ m/$wrong_1a/ || $code =~ m/$wrong_1b/ || $code =~ m/$wrong_1c/ ||
                        $code =~ m/$wrong_2a/ || $code =~ m/$wrong_2b/ || $code =~ m/$wrong_2c/ ||
                        $code =~ m/$wrong_3a/ || $code =~ m/$wrong_3b/ || $code =~ m/$wrong_3c/ ||
                        $code =~ m/$wrong_4a/ || $code =~ m/$wrong_4b/ || $code =~ m/$wrong_4c/)
                    {
                        if ($mm {$code} == 1)
                        {
                            $num_eliminated ++;
                        }
                        $mm {$code} = 0;
                    }

                    if (num_beads_match ($code, $guess_orig) != $num_absolutely_correct)
                    {
                        if ($mm {$code} == 1)
                        {
                            $num_eliminated ++;
                        }
                        $mm {$code} = 0;
                    }
                    my $npbm = num_partial_beads_match ($code, $guess_orig);
                    if ($mm {$code} == 1)
                    {
                    }
                    if (num_partial_beads_match ($code, $guess_orig) != $num_half_correct && $mm {$code} == 1)
                    {
                        if ($mm {$code} == 1)
                        {
                            $num_eliminated ++;
                        }
                        $mm {$code} = 0;
                    }
                }
            }

            if ($num_absolutely_correct == 0 && $num_half_correct == 1)
            {
                my $code;
                $guess_orig =~ m/(.)(.)(.)(.)/;

                my $a = $1;
                my $b = $2;
                my $c = $3;
                my $d = $4;

                my $wrong_1 = "($a.*$b|$a.*$c|$a.*$d|$b.*$c|$b.*$d|$c.*$d)";
                my $wrong_2 = "($b.*$a|$c.*$a|$d.*$a|$c.*$b|$d.*$b|$d.*$c)";

                foreach $code (sort (keys (%mm)))
                {
                    if ($code =~ m/$wrong_1/ || $code =~ m/$wrong_2/)
                    {
                        if ($mm {$code} == 1)
                        {
                            $num_eliminated ++;
                        }
                        $mm {$code} = 0;
                    }
                }
            }

            if ($num_absolutely_correct == 2 && $num_half_correct == 2)
            {
                my $code;
                $guess_orig =~ m/(.)(.)(.)(.)/;

                my $a = $1;
                my $b = $2;
                my $c = $3;
                my $d = $4;

                my $right_1 = "$a$b$d$c";
                my $right_2 = "$a$c$b$d";
                my $right_3 = "$a$d$c$b";
                my $right_4 = "$b$a$c$d";
                my $right_5 = "$c$b$a$d";
                my $right_6 = "$d$b$c$a";

                foreach $code (sort (keys (%mm)))
                {
                    if (!($code =~ m/$right_1/ || $code =~ m/$right_2/ || $code =~ m/$right_3/ || $code =~ m/$right_4/ || $code =~ m/$right_5/ || $code =~ m/$right_6/))
                    {
                        if ($mm {$code} == 1)
                        {
                            $num_eliminated ++;
                        }
                        $mm {$code} = 0;
                    }

                    if (num_beads_match ($code, $guess_orig) != $num_absolutely_correct)
                    {
                        if ($mm {$code} == 1)
                        {
                            $num_eliminated ++;
                        }
                        $mm {$code} = 0;
                    }

                    my $npbm = num_partial_beads_match ($code, $guess_orig);
                    if ($mm {$code} == 1)
                    {
                    }
                    if (num_partial_beads_match ($code, $guess_orig) != $num_half_correct && $mm {$code} == 1)
                    {
                        if ($mm {$code} == 1)
                        {
                            $num_eliminated ++;
                        }
                        $mm {$code} = 0;
                    }
                }
            }

            if ($num_absolutely_correct == 1 && $num_half_correct == 3)
            {
                my $code;
                $guess_orig =~ m/(.)(.)(.)(.)/;

                my $a = $1;
                my $b = $2;
                my $c = $3;
                my $d = $4;

                my $right_1 = "$a" . "[$b$c$d][$b$c$d][$b$c$d]";
                my $right_2 = "[$a$c$d]$b" . "[$a$c$d][$a$c$d]";
                my $right_3 = "[$a$b$d][$a$b$d]$c" . "[$a$b$d]";
                my $right_4 = "[$a$b$c][$a$b$c][$a$b$c]". "$d";

                foreach $code (sort (keys (%mm)))
                {
                    if (!($code =~ m/$right_1/ || $code =~ m/$right_2/ || $code =~ m/$right_3/ || $code =~ m/$right_4/))
                    {
                        if ($mm {$code} == 1)
                        {
                            $num_eliminated ++;
                        }
                        $mm {$code} = 0;
                    }

                    if (!colors_match ($code, $guess_orig))
                    {
                        if ($mm {$code} == 1)
                        {
                            $num_eliminated ++;
                        }
                        $mm {$code} = 0;
                    }

                    if (num_beads_match ($code, $guess_orig) != 1)
                    {
                        if ($mm {$code} == 1)
                        {
                            $num_eliminated ++;
                        }
                        $mm {$code} = 0;
                    }

                    my $npbm = num_partial_beads_match ($code, $guess_orig);
                    if ($mm {$code} == 1)
                    {
                    }
                    if (num_partial_beads_match ($code, $guess_orig) != $num_half_correct && $mm {$code} == 1)
                    {
                        if ($mm {$code} == 1)
                        {
                            $num_eliminated ++;
                        }
                        $mm {$code} = 0;
                    }
                }
            }

            # some blacks!
            if ($num_absolutely_correct >= 1)
            {
                my $code;
                my $right_1 = $guess_orig; $right_1 =~ s/...$/.../;
                my $right_2 = $guess_orig; $right_2 =~ s/^././;  $right_2 =~ s/..$/../;
                my $right_3 = $guess_orig; $right_3 =~ s/^../../ ;$right_3 =~ s/.$/./;
                my $right_4 = $guess_orig; $right_4 =~ s/^.../.../;

                foreach $code (sort (keys (%mm)))
                {
                    if (!($code =~ m/$right_1/ || $code =~ m/$right_2/ || $code =~ m/$right_3/ || $code =~ m/$right_4/))
                    {
                        if ($mm {$code} == 1)
                        {
                            $num_eliminated ++;
                        }
                        $mm {$code} = 0;
                    }

                    if (num_beads_match ($code, $guess_orig) != $num_absolutely_correct)
                    {
                        if ($mm {$code} == 1)
                        {
                            $num_eliminated ++;
                        }
                        $mm {$code} = 0;
                    }

                    my $npbm = num_partial_beads_match ($code, $guess_orig);
                    if ($mm {$code} == 1)
                    {
                    }
                    if (num_partial_beads_match ($code, $guess_orig) != $num_half_correct && $mm {$code} == 1)
                    {
                        if ($mm {$code} == 1)
                        {
                            $num_eliminated ++;
                        }
                        $mm {$code} = 0;
                    }
                }
            }

            if ($num_absolutely_correct >= 2)
            {
                my $code;
                my $right_1 = $guess_orig; $right_1 =~ s/^(.)(.)../$1$2../;
                my $right_2 = $guess_orig; $right_2 =~ s/^(.).(.)./$1.$2./;
                my $right_3 = $guess_orig; $right_3 =~ s/^(.)..(.)/$1..$2/;
                my $right_4 = $guess_orig; $right_4 =~ s/^.(.).(.)/.$1.$2/;
                my $right_5 = $guess_orig; $right_5 =~ s/^.(.)(.)./.$1$2./;
                my $right_6 = $guess_orig; $right_6 =~ s/^..(.)(.)/..$1$2/;

                foreach $code (sort (keys (%mm)))
                {
                    if (!($code =~ m/$right_1/ || $code =~ m/$right_2/ || $code =~ m/$right_3/ || $code =~ m/$right_4/ || $code =~ m/$right_5/ || $code =~ m/$right_6/))
                    {
                        if ($mm {$code} == 1)
                        {
                            $num_eliminated ++;
                        }
                        $mm {$code} = 0;
                    }

                    if (num_beads_match ($code, $guess_orig) != $num_absolutely_correct)
                    {
                        if ($mm {$code} == 1)
                        {
                            $num_eliminated ++;
                        }
                        $mm {$code} = 0;
                    }

                    my $npbm = num_partial_beads_match ($code, $guess_orig);
                    if ($mm {$code} == 1)
                    {
                    }
                    if (num_partial_beads_match ($code, $guess_orig) != $num_half_correct && $mm {$code} == 1)
                    {
                        if ($mm {$code} == 1)
                        {
                            $num_eliminated ++;
                        }
                        $mm {$code} = 0;
                    }
                }
            }

            if ($num_absolutely_correct >= 3)
            {
                my $code;
                my $right_1 = $guess_orig; $right_1 =~ s/^(.)(.)(.)./$1$2$3./;
                my $right_2 = $guess_orig; $right_2 =~ s/^(.)(.).(.)/$1$2.$3/;
                my $right_3 = $guess_orig; $right_3 =~ s/^(.).(.)(.)/$1.$2$3/;
                my $right_4 = $guess_orig; $right_4 =~ s/^.(.)(.)(.)/.$1$2$3/;

                foreach $code (sort (keys (%mm)))
                {
                    if (!($code =~ m/$right_1/ || $code =~ m/$right_2/ || $code =~ m/$right_3/ || $code =~ m/$right_4/))
                    {
                        if ($mm {$code} == 1)
                        {
                            $num_eliminated ++;
                        }
                        $mm {$code} = 0;
                    }

                    if (num_beads_match ($code, $guess_orig) != $num_absolutely_correct)
                    {
                        if ($mm {$code} == 1)
                        {
                            $num_eliminated ++;
                        }
                        $mm {$code} = 0;
                    }

                    my $npbm = num_partial_beads_match ($code, $guess_orig);
                    if ($mm {$code} == 1)
                    {
                    }
                    if (num_partial_beads_match ($code, $guess_orig) != $num_half_correct && $mm {$code} == 1)
                    {
                        if ($mm {$code} == 1)
                        {
                            $num_eliminated ++;
                        }
                        $mm {$code} = 0;
                    }
                }
            }
        }
    }

    my $left_over = 0;
    my $code;
    foreach $code (sort (keys (%mm)))
    {
        $left_over += $mm {$code};
    }

    if ($left_over < 50)
    {
        foreach $code (sort (keys (%mm)))
        {
            if ($mm {$code} > 0)
            {
            }
        }
    }
    my $code;
    my %solution_answers;

    foreach $code (sort (keys (%mm)))
    {
        if ($mm {$code} == 1)
        {
            # Get answer code matches answer string??$ against $last_term
            # Example:
            #  WWUU (bot determined 0000)
            #  BBRR (bot determined 0000)
            #  GGGG  << $last_term
            #   So... WGGG would be out already
            #   So... UGGG would be out already
            #   So... BGGG would be out already
            #   So... YGGG would be 2220
            #   So... YGYG would be 2200
            #

            my $ac = mk_answer_code ($last_term, $code);
            $solution_answers {$ac}++;
        }
    }

    my $k;
    my $max_num_of_codes = -1;
    my $best_answer;
    foreach $k (sort keys (%solution_answers))
    {

        if ($solution_answers{$k} > $max_num_of_codes)
        {
            $max_num_of_codes = $solution_answers{$k};
            $best_answer = $k;
        }
    }

    return "$best_answer -- $max_num_of_codes";
}

sub get_game_state
{
    my $IP = $_ [0];

    my $out .= "<h1>Welcome to \"Mastermind!\", <font color=" . $rand_colors {$CURRENT_LOGIN_NAME} . ">$CURRENT_LOGIN_NAME</font> </h1><br><br>&nbsp;There are $num_players_in_lobby players logged in.<br>";
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
            <form action=\"/mastermind/new_user\">
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
        $out .= "<font size=+1 color=red>Welcome to \"Mastermind!\", " . get_player_name ($id) . "<br><\/font>";
        if (in_game ($IP))
        {
            $out = print_game_state ($IP);
            $out .= "Reset the game here: <a href=\"reset_game\">Reset<\/a><br><br><br>";
        }
        elsif (!get_game_started ())
        {
            if ($num_players_in_lobby >= 1)
            {
                $out .= "$games_block";
            }
            else
            {
                $out .= "Need at least one player to play Mastermind! (The 'Start' URL will be here when there are enough players!)";
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

    return $out;
}

#####  BEAD HTML ####
my $header = "<!DOCTYPE html> <html lang=\"en\"> <head> <meta charset=\"utf-8\"> <meta name=\"viewport\" content=\"width=device-width, initial-scale=1, shrink-to-fit=no\"> <link rel=\"stylesheet\" href=\"\/maastermind\/bootstrap.min.css\"> <script src=\"\/maastermind\/jquery-3.5.1.min.js\"><\/script> <script src=\"\/maastermind\/popper.min.js\"><\/script> <script src=\"\/maastermind\/bootstrap.min.js\"><\/script> <\/head> <body> <center> <h1 style=\"color: royalblue\"> Master Mind <\/h1>
  <script>
    function confirmReset (event) 
    {
        event.preventDefault();
        let confirmBox = document.getElementById(\"confirm_reset_box\");
        confirmBox.style.display = \"block\";
    }
    
    function confirmNewGameEasy (event) 
    {
        event.preventDefault();
        let confirmBox = document.getElementById(\"confirm_newgame_box\");
        confirmBox.style.display = \"block\";
    }
    
    function confirmNewGameHard (event) 
    {
        event.preventDefault();
        let confirmBox = document.getElementById(\"confirm_newhardgame_box\");
        confirmBox.style.display = \"block\";
    }
    
    function confirmNewGameBot (event) 
    {
        event.preventDefault();
        let confirmBox = document.getElementById(\"confirm_newbotgame_box\");
        confirmBox.style.display = \"block\";
    }
    
    function resetGame(confirm) 
    {
        if (confirm)
        {
            window.location.href = \"/mastermind/reset_game\";
        }
        else 
        {
            document.getElementById(\"confirm_reset_box\").style.display = \"none\";
        }
    }
    
    function newEasyGame(confirm) 
    {
        if (confirm)
        {
            window.location.href = \"/mastermind/new_game\";
            \/\/\/\/\/window.location.href = \"mastermind\/youtube\/\";
        }
        else 
        {
            document.getElementById(\"confirm_newgame_box\").style.display = \"none\";
        }
    }
    
    function newHardGame(confirm) 
    {
        if (confirm)
        {
            window.location.href = \"/mastermind/new_hard_game\";
        }
        else 
        {
            document.getElementById(\"confirm_newhardgame_box\").style.display = \"none\";
        }
    }
    
    function newBotGame(confirm) 
    {
        if (confirm)
        {
            window.location.href = \"/mastermind/new_bot_game\";
        }
        else 
        {
            document.getElementById(\"confirm_newbotgame_box\").style.display = \"none\";
        }
    }
  </script>
  <style>
    #confirm_reset_box 
    {
        display: none;
        position: fixed;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
        background: white;
        padding: 20px;
        border: 1px solid black;
                box-shadow: 0px 0px 10px rgba(0, 0, 0, 0.1);
                text-align: center;
    }
    #confirm_newgame_box 
    {
        display: none;
        position: fixed;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
        background: white;
        padding: 20px;
        border: 1px solid black;
                box-shadow: 0px 0px 10px rgba(0, 0, 0, 0.1);
                text-align: center;
    }
    #confirm_newhardgame_box 
    {
        display: none;
        position: fixed;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
        background: white;
        padding: 20px;
        border: 1px solid black;
                box-shadow: 0px 0px 10px rgba(0, 0, 0, 0.1);
                text-align: center;
    }
    #confirm_newbotgame_box 
    {
        display: none;
        position: fixed;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
        background: white;
        padding: 20px;
        border: 1px solid black;
                box-shadow: 0px 0px 10px rgba(0, 0, 0, 0.1);
                text-align: center;
    }
    .confirm_reset_btn 
    {
        margin: 5px;
        padding: 5px 10px;
        cursor: pointer;
    }
  </style>
<table>";
my $footer = " <tr> <td> <div class=\"dropdown\"> <button class=\"btn btn-success dropdown-toggle\" type=\"button\" id=\"bead1\" data-toggle=\"dropdown\" aria-haspopup=\"true\" aria-expanded=\"false\"> ?</button> <ul class=\"dropdown-menu\" aria-labelledby=\"bead1\"> <li class=\"dropdown-item\" onclick=\"changeText('White', '/white.png', 'bead1')\"> <img src=\"/white.png\" width=\"20\" height=\"15\"> White</li> <li class=\"dropdown-item\" onclick=\"changeText('Blue', '/blue.png', 'bead1')\"> <img src=\"/blue.png\" width=\"20\" height=\"15\"> Blue</li> <li class=\"dropdown-item\" onclick=\"changeText('Black', '/black.png', 'bead1')\"> <img src=\"/black.png\" width=\"20\" height=\"15\"> Black</li> <li class=\"dropdown-item\" onclick=\"changeText('Red', '/red.png', 'bead1')\"> <img src=\"/red.png\" width=\"20\" height=\"15\"> Red</li> <li class=\"dropdown-item\" onclick=\"changeText('Green', '/green.png', 'bead1')\"> <img src=\"/green.png\" width=\"20\" height=\"15\"> Green</li> <li class=\"dropdown-item\" onclick=\"changeText('Yellow', '/yellow.png', 'bead1')\"> <img src=\"/yellow.png\" width=\"20\" height=\"15\"> Yellow</li> </ul> </div> </td> <td> <div class=\"dropdown\"> <button class=\"btn btn-success dropdown-toggle\" type=\"button\" id=\"bead2\" data-toggle=\"dropdown\" aria-haspopup=\"true\" aria-expanded=\"false\"> ?</button> <ul class=\"dropdown-menu\" aria-labelledby=\"bead2\"> <li class=\"dropdown-item\" onclick=\"changeText('White', '/white.png', 'bead2')\"> <img src=\"/white.png\" width=\"20\" height=\"15\"> White</li> <li class=\"dropdown-item\" onclick=\"changeText('Blue', '/blue.png', 'bead2')\"> <img src=\"/blue.png\" width=\"20\" height=\"15\"> Blue</li> <li class=\"dropdown-item\" onclick=\"changeText('Black', '/black.png', 'bead2')\"> <img src=\"/black.png\" width=\"20\" height=\"15\"> Black</li> <li class=\"dropdown-item\" onclick=\"changeText('Red', '/red.png', 'bead2')\"> <img src=\"/red.png\" width=\"20\" height=\"15\"> Red</li> <li class=\"dropdown-item\" onclick=\"changeText('Green', '/green.png', 'bead2')\"> <img src=\"/green.png\" width=\"20\" height=\"15\"> Green</li> <li class=\"dropdown-item\" onclick=\"changeText('Yellow', '/yellow.png', 'bead2')\"> <img src=\"/yellow.png\" width=\"20\" height=\"15\"> Yellow</li> </ul> </div> </td> <td> <div class=\"dropdown\"> <button class=\"btn btn-success dropdown-toggle\" type=\"button\" id=\"bead3\" data-toggle=\"dropdown\" aria-haspopup=\"true\" aria-expanded=\"false\"> ?</button> <ul class=\"dropdown-menu\" aria-labelledby=\"bead3\"> <li class=\"dropdown-item\" onclick=\"changeText('White', '/white.png', 'bead3')\"> <img src=\"/white.png\" width=\"20\" height=\"15\"> White</li> <li class=\"dropdown-item\" onclick=\"changeText('Blue', '/blue.png', 'bead3')\"> <img src=\"/blue.png\" width=\"20\" height=\"15\"> Blue</li> <li class=\"dropdown-item\" onclick=\"changeText('Black', '/black.png', 'bead3')\"> <img src=\"/black.png\" width=\"20\" height=\"15\"> Black</li> <li class=\"dropdown-item\" onclick=\"changeText('Red', '/red.png', 'bead3')\"> <img src=\"/red.png\" width=\"20\" height=\"15\"> Red</li> <li class=\"dropdown-item\" onclick=\"changeText('Green', '/green.png', 'bead3')\"> <img src=\"/green.png\" width=\"20\" height=\"15\"> Green</li> <li class=\"dropdown-item\" onclick=\"changeText('Yellow', '/yellow.png', 'bead3')\"> <img src=\"/yellow.png\" width=\"20\" height=\"15\"> Yellow</li> </ul> </div> </td> <td> <div class=\"dropdown\"> <button class=\"btn btn-success dropdown-toggle\" type=\"button\" id=\"bead4\" data-toggle=\"dropdown\" aria-haspopup=\"true\" aria-expanded=\"false\"> ?</button> <ul class=\"dropdown-menu\" aria-labelledby=\"bead4\"> <li class=\"dropdown-item\" onclick=\"changeText('White', '/white.png', 'bead4')\"> <img src=\"/white.png\" width=\"20\" height=\"15\"> White</li> <li class=\"dropdown-item\" onclick=\"changeText('Blue', '/blue.png', 'bead4')\"> <img src=\"/blue.png\" width=\"20\" height=\"15\"> Blue</li> <li class=\"dropdown-item\" onclick=\"changeText('Black', '/black.png', 'bead4')\"> <img src=\"/black.png\" width=\"20\" height=\"15\"> Black</li> <li class=\"dropdown-item\" onclick=\"changeText('Red', '/red.png', 'bead4')\"> <img src=\"/red.png\" width=\"20\" height=\"15\"> Red</li> <li class=\"dropdown-item\" onclick=\"changeText('Green', '/green.png', 'bead4')\"> <img src=\"/green.png\" width=\"20\" height=\"15\"> Green</li> <li class=\"dropdown-item\" onclick=\"changeText('Yellow', '/yellow.png', 'bead4')\"> <img src=\"/yellow.png\" width=\"20\" height=\"15\"> Yellow</li> </ul> </div> </td>
            <td>
                <button id=\"submitButton\" onclick=\"location.href='http://www.example.com'\" disabled>Submit</button>
            </td></tr> </table> </center>
<script>
var b1 = '';
var b2 = '';
var b3 = '';
var b4 = '';
var numBeadsSet = 0;
function changeText(bead, beadUrl, nameofId)
{
    if (nameofId == 'bead1') { b1 = bead; numBeadsSet = numBeadsSet | 1; }
    if (nameofId == 'bead2') { b2 = bead; numBeadsSet = numBeadsSet | 2; }
    if (nameofId == 'bead3') { b3 = bead; numBeadsSet = numBeadsSet | 4; }
    if (nameofId == 'bead4') { b4 = bead; numBeadsSet = numBeadsSet | 8; }
    document.getElementById(nameofId).innerHTML = `<img src=\"\${beadUrl}\" width=\"20\" height=\"15\">`;
    if (numBeadsSet == 15)
    {
        document.getElementById(\"submitButton\").disabled = false;
        var hhh = \"nextChoice?\" + b1 + \"&\" + b2 + \"&\" + b3 + \"&\" + b4;
        document.getElementById(\"submitButton\").href = hhh;
        document.getElementById(\"submitButton\").onclick = \"location.href='\" + hhh + \"'\";
        document.getElementById(\"submitButton\").setAttribute(\"onClick\", \"location.href='\" + hhh + \"'\");
    }
    else { document.getElementById(\"submitButton\").disabled = true; }
}
<\/script> <br>$center_games_block";
my $hard_footer = " <tr> <td> <div class=\"dropdown\"> <button class=\"btn btn-success dropdown-toggle\" type=\"button\" id=\"bead1\" data-toggle=\"dropdown\" aria-haspopup=\"true\" aria-expanded=\"false\"> ?</button> <ul class=\"dropdown-menu\" aria-labelledby=\"bead1\"> <li class=\"dropdown-item\" onclick=\"changeText('White', '/white.png', 'bead1')\"> <img src=\"/white.png\" width=\"20\" height=\"15\"> White</li> <li class=\"dropdown-item\" onclick=\"changeText('Blue', '/blue.png', 'bead1')\"> <img src=\"/blue.png\" width=\"20\" height=\"15\"> Blue</li> <li class=\"dropdown-item\" onclick=\"changeText('Black', '/black.png', 'bead1')\"> <img src=\"/black.png\" width=\"20\" height=\"15\"> Black</li> <li class=\"dropdown-item\" onclick=\"changeText('Red', '/red.png', 'bead1')\"> <img src=\"/red.png\" width=\"20\" height=\"15\"> Red</li> <li class=\"dropdown-item\" onclick=\"changeText('Green', '/green.png', 'bead1')\"> <img src=\"/green.png\" width=\"20\" height=\"15\"> Green</li> <li class=\"dropdown-item\" onclick=\"changeText('Yellow', '/yellow.png', 'bead1')\"> <img src=\"/yellow.png\" width=\"20\" height=\"15\"> Yellow</li> </ul> </div> </td> <td> <div class=\"dropdown\"> <button class=\"btn btn-success dropdown-toggle\" type=\"button\" id=\"bead2\" data-toggle=\"dropdown\" aria-haspopup=\"true\" aria-expanded=\"false\"> ?</button> <ul class=\"dropdown-menu\" aria-labelledby=\"bead2\"> <li class=\"dropdown-item\" onclick=\"changeText('White', '/white.png', 'bead2')\"> <img src=\"/white.png\" width=\"20\" height=\"15\"> White</li> <li class=\"dropdown-item\" onclick=\"changeText('Blue', '/blue.png', 'bead2')\"> <img src=\"/blue.png\" width=\"20\" height=\"15\"> Blue</li> <li class=\"dropdown-item\" onclick=\"changeText('Black', '/black.png', 'bead2')\"> <img src=\"/black.png\" width=\"20\" height=\"15\"> Black</li> <li class=\"dropdown-item\" onclick=\"changeText('Red', '/red.png', 'bead2')\"> <img src=\"/red.png\" width=\"20\" height=\"15\"> Red</li> <li class=\"dropdown-item\" onclick=\"changeText('Green', '/green.png', 'bead2')\"> <img src=\"/green.png\" width=\"20\" height=\"15\"> Green</li> <li class=\"dropdown-item\" onclick=\"changeText('Yellow', '/yellow.png', 'bead2')\"> <img src=\"/yellow.png\" width=\"20\" height=\"15\"> Yellow</li> </ul> </div> </td> <td> <div class=\"dropdown\"> <button class=\"btn btn-success dropdown-toggle\" type=\"button\" id=\"bead3\" data-toggle=\"dropdown\" aria-haspopup=\"true\" aria-expanded=\"false\"> ?</button> <ul class=\"dropdown-menu\" aria-labelledby=\"bead3\"> <li class=\"dropdown-item\" onclick=\"changeText('White', '/white.png', 'bead3')\"> <img src=\"/white.png\" width=\"20\" height=\"15\"> White</li> <li class=\"dropdown-item\" onclick=\"changeText('Blue', '/blue.png', 'bead3')\"> <img src=\"/blue.png\" width=\"20\" height=\"15\"> Blue</li> <li class=\"dropdown-item\" onclick=\"changeText('Black', '/black.png', 'bead3')\"> <img src=\"/black.png\" width=\"20\" height=\"15\"> Black</li> <li class=\"dropdown-item\" onclick=\"changeText('Red', '/red.png', 'bead3')\"> <img src=\"/red.png\" width=\"20\" height=\"15\"> Red</li> <li class=\"dropdown-item\" onclick=\"changeText('Green', '/green.png', 'bead3')\"> <img src=\"/green.png\" width=\"20\" height=\"15\"> Green</li> <li class=\"dropdown-item\" onclick=\"changeText('Yellow', '/yellow.png', 'bead3')\"> <img src=\"/yellow.png\" width=\"20\" height=\"15\"> Yellow</li> </ul> </div> </td> <td> <div class=\"dropdown\"> <button class=\"btn btn-success dropdown-toggle\" type=\"button\" id=\"bead4\" data-toggle=\"dropdown\" aria-haspopup=\"true\" aria-expanded=\"false\"> ?</button> <ul class=\"dropdown-menu\" aria-labelledby=\"bead4\"> <li class=\"dropdown-item\" onclick=\"changeText('White', '/white.png', 'bead4')\"> <img src=\"/white.png\" width=\"20\" height=\"15\"> White</li> <li class=\"dropdown-item\" onclick=\"changeText('Blue', '/blue.png', 'bead4')\"> <img src=\"/blue.png\" width=\"20\" height=\"15\"> Blue</li> <li class=\"dropdown-item\" onclick=\"changeText('Black', '/black.png', 'bead4')\"> <img src=\"/black.png\" width=\"20\" height=\"15\"> Black</li> <li class=\"dropdown-item\" onclick=\"changeText('Red', '/red.png', 'bead4')\"> <img src=\"/red.png\" width=\"20\" height=\"15\"> Red</li> <li class=\"dropdown-item\" onclick=\"changeText('Green', '/green.png', 'bead4')\"> <img src=\"/green.png\" width=\"20\" height=\"15\"> Green</li> <li class=\"dropdown-item\" onclick=\"changeText('Yellow', '/yellow.png', 'bead4')\"> <img src=\"/yellow.png\" width=\"20\" height=\"15\"> Yellow</li> </ul> </div> </td>
            <td>
                <button id=\"submitButton\" onclick=\"location.href='http://www.example.com'\" disabled>Submit</button>
            </td></tr> </table> </center>
<script>
var b1 = '';
var b2 = '';
var b3 = '';
var b4 = '';
var numBeadsSet = 0;
function changeText(bead, beadUrl, nameofId)
{
    if (nameofId == 'bead1') { b1 = bead; numBeadsSet = numBeadsSet | 1; }
    if (nameofId == 'bead2') { b2 = bead; numBeadsSet = numBeadsSet | 2; }
    if (nameofId == 'bead3') { b3 = bead; numBeadsSet = numBeadsSet | 4; }
    if (nameofId == 'bead4') { b4 = bead; numBeadsSet = numBeadsSet | 8; }
    document.getElementById(nameofId).innerHTML = `<img src=\"\${beadUrl}\" width=\"20\" height=\"15\">`;
    if (numBeadsSet == 15)
    {
        document.getElementById(\"submitButton\").disabled = false;
        var hhh = \"nextHardChoice?\" + b1 + \"&\" + b2 + \"&\" + b3 + \"&\" + b4;
        document.getElementById(\"submitButton\").href = hhh;
        document.getElementById(\"submitButton\").onclick = \"location.href='\" + hhh + \"'\";
        document.getElementById(\"submitButton\").setAttribute(\"onClick\", \"location.href='\" + hhh + \"'\");
    }
    else { document.getElementById(\"submitButton\").disabled = true; }
}
<\/script> <br>$center_games_block";

sub print_beads
{
    my $middle = "";
    my $middle = "<tr>";

    my $guess = 0;
    my $num_right = 0;
    while (exists ($CURRENT_GUESSES {$guess}))
    {
        $num_right = 0;
        my $new_guess = uc ($CURRENT_GUESSES {$guess});
        my $copy_guess = $new_guess;
        $guess++;
        while ($new_guess =~ s/^([wubrgy])//im)
        {
            my $col = uc($1);
            my $color = $1;
            if ($col eq "W") { $color = "white"; }
            if ($col eq "U") { $color = "blue"; }
            if ($col eq "B") { $color = "black"; }
            if ($col eq "R") { $color = "red"; }
            if ($col eq "G") { $color = "green"; }
            if ($col eq "Y") { $color = "yellow"; }
            $middle .= "<td> <img src=\"$color.png\" width=\"20\" height=\"15\"></img> </td>";
        }
        my $extra = " (from $CURRENT_CODE to $copy_guess)";
        my $num_semiright = 0;
        my $cg1 = $copy_guess; $cg1 =~ s/^(.)...$/$1.../i; my $bb1 = $1;
        my $cg2 = $copy_guess; $cg2 =~ s/^.(.)..$/.$1../i; my $bb2 = $1;
        my $cg3 = $copy_guess; $cg3 =~ s/^..(.).$/..$1./i; my $bb3 = $1;
        my $cg4 = $copy_guess; $cg4 =~ s/^...(.)$/...$1/i; my $bb4 = $1;

        my $to_check = $CURRENT_CODE;
        if ($CURRENT_CODE =~ m/$cg1/i) { $num_right++; $to_check =~ s/^./x/; $bb1 = "z"; }
        if ($CURRENT_CODE =~ m/$cg2/i) { $num_right++; $to_check =~ s/^(.)./$1x/; $bb2 = "z"; }
        if ($CURRENT_CODE =~ m/$cg3/i) { $num_right++; $to_check =~ s/^(..)./$1x/; $bb3 = "z"; }
        if ($CURRENT_CODE =~ m/$cg4/i) { $num_right++; $to_check =~ s/^(...)./$1x/; $bb4 = "z"; }

        if ($num_right == 4)
        {
            game_won (2, "You win! You got the code!");
        }

        if ($to_check =~ m/.*$bb1.*/) { $num_semiright++; $to_check =~ s/$bb1/x/; }
        if ($to_check =~ m/.*$bb2.*/) { $num_semiright++; $to_check =~ s/$bb2/x/; }
        if ($to_check =~ m/.*$bb3.*/) { $num_semiright++; $to_check =~ s/$bb3/x/; }
        if ($to_check =~ m/.*$bb4.*/) { $num_semiright++; }
        #$middle .= "<td> Right=$num_right; Partially Right=$num_semiright</td></tr>"; # $extra $to_check ($cg1,$cg2,$cg3,$cg4  vs $bb1,$bb2,$bb3,$bb4</td><tr>";
        # New images!
        my $wrong = 4 - $num_right - $num_semiright;
        my $image = $num_right . "r" . $num_semiright . "m" . $wrong . "w.png";
        $middle .= "<td><img src=\"$image\" width=50 height=50></img></td></tr>";
        #$middle .= "<td>$image</td></tr>";
        #$middle .= "<td> Right=$num_right; Partially Right=$num_semiright ($extra $to_check $cg1,$cg2,$cg3,$cg4  vs $bb1,$bb2,$bb3,$bb4)</td><tr>";
    }
    $middle .= "</tr>";

    if ($num_right == 4)
    {
        return ("$header$middle</tr> </td></table> <br> You won!<br>$center_games_block<\/body> <\/html>");
    }

    if (get_game_won () ne "")
    {
        $middle .= "<br>$reason_for_game_end<br>";
    }
    return ("$header$middle$footer");
}

sub print_hard_beads
{
    my $middle = "";
    my $middle = "<tr>";
    my $middle = "";
    my $middle = "<tr>";
    $human_choices = "";
    my $orig_answers = "";

    my $gg = 0;
    my $term = "";
    my $helper = "";

    while (exists ($CURRENT_GUESSES {$gg}) && $CURRENT_GUESSES {$gg . "_response"} ne "-1,-1")
    {
        $term .= "$CURRENT_GUESSES{$gg},";

        my $exact = 0;
        my $partial = 0;
        if ($CURRENT_GUESSES {$gg . "_response"} =~ m/^(\d+),(\d+)/)
        {
            $exact = $1;
            $partial = $2;
        }

        my $cc = 4;
        while ($exact > 0)
        {
            $helper .= "2";
            $cc--;
            $exact--;
        }
        while ($partial > 0)
        {
            $helper .= "1";
            $cc--;
            $partial--;
        }
        while ($cc > 0)
        {
            $helper .= "0";
            $cc--;
        }
        $helper .= ",";
        $gg++;
    }

    # Looking for the maximum number of valid codes left..
    my $nr = 0;
    my $npr = 0;
    my $max_number_of_codes_left = 0;
    my $max_answer;
    my %ans;
    for ($nr = 0; $nr <= 4; $nr++)
    {
        for ($npr = 0; $npr <= 4 - $nr; $npr ++)
        {
            my $i;
            my $answer = "";
            for ($i = 0; $i < $nr; $i++)
            {
                $answer .= "2";
            }

            for ($i = 0; $i < $npr; $i++)
            {
                $answer .= "1";
            }

            for ($i = 0; $i < 4 - ($npr + $nr); $i++)
            {
                $answer .= "0";
            }

            if (!defined ($ans {$answer}))
            {
                $ans {$answer} = 1;
                my $num_codes_left = get_number_matching_codes ($term, $helper, $answer);
                if ($num_codes_left =~ m/^(\d\d\d\d) -- (\d+)/)
                {
                    my $this_answer = $1;
                    my $this_num_codes = $2;
                    if ($max_number_of_codes_left < $this_num_codes)
                    {
                        $max_number_of_codes_left = $this_num_codes;
                        $max_answer = $this_answer;
                    }
                }
            }
        }
    }

    my $nr = 0;
    my $npr = 0;
    while ($max_answer =~ s/2//)
    {
        $nr++;
    }
    while ($max_answer =~ s/1//)
    {
        $npr++;
    }

    if ($nr == 4)
    {
        game_won (2, "You win! You guessed the code!");
    }

    $CURRENT_GUESSES {($CURRENT_GUESSES_NUM-1) . "_response"} = "$nr,$npr";

    my $guess = 0;
    while (exists ($CURRENT_GUESSES {$guess}))
    {
        my $new_guess = uc ($CURRENT_GUESSES {$guess});
        my $new_response = uc ($CURRENT_GUESSES {$guess . "_response"});
        my $copy_guess = $new_guess;
        $human_choices .= $CURRENT_GUESSES {$guess};
        $orig_answers .= get_answer_code ($CURRENT_GUESSES {$guess . "_response"});
        $guess++;

        while ($new_guess =~ s/^([wubrgy])//im)
        {
            my $col = uc($1);
            my $color = $1;
            if ($col eq "W") { $color = "white"; }
            if ($col eq "U") { $color = "blue"; }
            if ($col eq "B") { $color = "black"; }
            if ($col eq "R") { $color = "red"; }
            if ($col eq "G") { $color = "green"; }
            if ($col eq "Y") { $color = "yellow"; }
            $middle .= "<td> <img src=\"$color.png\" width=\"20\" height=\"15\"></img> </td>";
        }
        my $gg = $guess - 1;
        # New images!
        $new_response =~ m/(\d),(\d)/;
        my $num_right = $1;
        my $num_semiright = $2;
        my $wrong = 4 - $num_right - $num_semiright;
        my $image = $num_right . "r" . $num_semiright . "m" . $wrong . "w.png";
        $middle .= "<td><img src=\"$image\" width=50 height=50></img></td></tr>";
    }

    #$middle .= "</tr><br> ($helper,$term) ==> ($max_number_of_codes_left,$max_answer)";
    $middle .= "</tr>";
    if (get_game_won () ne "")
    {
        $middle .= "<br>$reason_for_game_end<br>";
    }
    return ("$header$middle$hard_footer");
}

my $bot_footer = "<td>
    <form>
        <label for=\"numberRight\">Exact:</label>
        <select id=\"numberRight\" onchange=\"validateForm()\">
            <option value=\"\">Choose:</option>
            <option value=\"0\">0</option>
            <option value=\"1\">1</option>
            <option value=\"2\">2</option>
            <option value=\"3\">3</option>
            <option value=\"4\">4</option>
        </select>
        <br>
        <label for=\"numberPartial\">Partial:</label>
        <select id=\"numberPartial\" onchange=\"validateForm()\">
            <option value=\"\">Choose:</option>
            <option value=\"0\">0</option>
            <option value=\"1\">1</option>
            <option value=\"2\">2</option>
            <option value=\"3\">3</option>
            <option value=\"4\">4</option>
        </select>
    </form><button id=\"humanCoderBtn\" onclick=\"location.href='http://www.example.com'\" disabled>Submit</button></td>
    <script>
        function validateForm()
        {
            let numberRight = parseInt(document.getElementById(\"numberRight\").value);
            let numberPartial = parseInt(document.getElementById(\"numberPartial\").value);
            if (!isNaN(numberRight) && !isNaN(numberPartial))
            {
                if (numberRight + numberPartial <= 4)
                {
                    var hhh = \"humanCoder?exact=\" + numberRight + \"&partial=\" + numberPartial;
                    document.getElementById(\"humanCoderBtn\").href = hhh;
                    document.getElementById(\"humanCoderBtn\").onclick = \"location.href='\" + hhh + \"'\";
                    document.getElementById(\"humanCoderBtn\").setAttribute(\"onClick\", \"location.href='\" + hhh + \"'\");
                    document.getElementById(\"humanCoderBtn\").disabled = false;
                }
                else
                {
                    document.getElementById(\"humanCoderBtn\").disabled = true;
                }
            }
            else
            {
                document.getElementById(\"humanCoderBtn\").disabled = true;
            }
        }
    </script>
";

sub print_bot_beads
{
    my $middle = "";
    my $middle = "<tr>";

    my $guess = 0;
    my $num_right = 0;

    my $next_guess = "";
    if ($CURRENT_GUESSES_NUM == 0)
    {
        for (my $i = 0; $i < 4; $i++)
        {
            my $n = int (rand (6));
            if ($n == 0) { $next_guess .= "W"; }
            if ($n == 1) { $next_guess .= "U"; }
            if ($n == 2) { $next_guess .= "B"; }
            if ($n == 3) { $next_guess .= "R"; }
            if ($n == 4) { $next_guess .= "G"; }
            if ($n == 5) { $next_guess .= "Y"; }
        }

        $next_guess = lc ($next_guess);
        $CURRENT_GUESSES {$CURRENT_GUESSES_NUM} = "$next_guess";
        $CURRENT_GUESSES {$CURRENT_GUESSES_NUM . "_response"} = "-1,-1";
        $CURRENT_GUESSES_NUM++;
    }
    elsif ($CURRENT_GUESSES_NUM > 0)
    {
        my $gg = 0;
        my $term = "";
        my $helper = "";

        while (exists ($CURRENT_GUESSES {$gg}) && $CURRENT_GUESSES {$gg . "_response"} ne "-1,-1")
        {
            $term .= "$CURRENT_GUESSES{$gg},";

            my $exact = 0;
            my $partial = 0;
            if ($CURRENT_GUESSES {$gg . "_response"} =~ m/^(\d+),(\d+)/)
            {
                $exact = $1;
                $partial = $2;
            }

            my $cc = 4;
            while ($exact > 0)
            {
                $helper .= "2";
                $cc--;
                $exact--;
            }
            while ($partial > 0)
            {
                $helper .= "1";
                $cc--;
                $partial--;
            }
            while ($cc > 0)
            {
                $helper .= "0";
                $cc--;
            }
            $helper .= ",";
            $gg++;
        }

        $next_guess = lc (get_valid_choices ($term, $helper));
        if ($next_guess =~ m/INVALID/i)
        {
            game_won (2, "You lose! No valid choices left.");
        }
        else
        {
            $CURRENT_GUESSES {$CURRENT_GUESSES_NUM} = "$next_guess";
            $CURRENT_GUESSES {$CURRENT_GUESSES_NUM . "_response"} = "-1,-1";
            $CURRENT_GUESSES_NUM++;
        }
    }

    while (exists ($CURRENT_GUESSES {$guess}))
    {
        my $new_guess = uc ($CURRENT_GUESSES {$guess});
        my $copy_guess = $new_guess;

        $middle .= "<td>";
        while ($new_guess =~ s/^([wubrgy])//im)
        {
            my $col = uc($1);
            my $color = $1;
            if ($col eq "W") { $color = "white"; }
            if ($col eq "U") { $color = "blue"; }
            if ($col eq "B") { $color = "black"; }
            if ($col eq "R") { $color = "red"; }
            if ($col eq "G") { $color = "green"; }
            if ($col eq "Y") { $color = "yellow"; }
            $middle .= "<img src=\"$color.png\" width=\"20\" height=\"15\"></img>";
        }

        my $user_guess = "<td></td>";
        if ($CURRENT_GUESSES {$guess . "_response"} ne "-1,-1")
        {
            $user_guess = "<td>" . $CURRENT_GUESSES {$guess . "_response"} . "</td>";
        }

        #$middle .= "$user_guess</tr>";

        # New images!
        if ($user_guess =~ m/(\d),(\d)/)
        {
            my $num_right = $1;
            my $num_semiright = $2;
            my $wrong = 4 - $num_right - $num_semiright;
            my $image = $num_right . "r" . $num_semiright . "m" . $wrong . "w.png";
            $middle .= "<td><img src=\"$image\" width=50 height=50></img></td></tr>";
        }
        else
        {
            $middle .= "<td></td></tr>";
        }

        $guess++;
    }

    if (get_game_won () ne "")
    {
        $middle .= "<br>$reason_for_game_end<br>";
    }

    $middle .= "$bot_footer</tr></table>";

    return ("$header$middle");
}
#####  // BEAD HTML ####

my $testing = 1;
# Main
{
    my $paddr;
    my $proto = "TCP";
    my $iaddr;
    my $client_port;
    my $client_addr;
    my $pid;
    my $SERVER;
    my $port = 6663; #MMND
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
            write_to_socket (\*CLIENT, get_game_state($client_addr), "", "noredirect");
            next;
        }

        if ($CURRENT_LOGIN_NAME eq "")
        {
            write_to_socket (\*CLIENT, get_game_state($client_addr), "", "noredirect");
            next;
        }

        # HTTP
        if ($txt =~ m/GET.{0,20}youtube.{0,20}HTTP/i)
        {
            new_hard_game ();
            print ("Saw ---> $txt!\n");
            if ($txt =~ m/(GET.{0,20}youtube.{0,20}HTTP)/i)
            {
                print ("$1 matched..!\n");
            }
            my $msg_body = "";
            my $http_header = "HTTP/1.1 302 Moved\nLocation: https:\/\/www.youtube.com\/watch?v=dQw4w9WgXcQ\nLast-Modified: 20250301010101\nConnection: close\nContent-Type: text/html; charset=UTF-8\nContent-Length: 0\n\n";
            $msg_body = $http_header . $msg_body;
            syswrite (\*CLIENT, $msg_body);
            next;
        }

        # HTTP
        if ($txt =~ m/GET.*new_hard_game/m)
        {
            new_hard_game ();
            write_to_socket (\*CLIENT, get_game_state($client_addr), "", "redirect");
            next;
        }

        # HTTP
        if ($txt =~ m/GET.*new_game/m)
        {
            new_game ();
            write_to_socket (\*CLIENT, get_game_state($client_addr), "", "redirect");
            next;
        }

        # HTTP
        if ($txt =~ m/GET.*new_bot_game/m)
        {
            new_bot_game ();
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
            my $size = -s ("d:/perl_programs/mastermind/maastermind.jpg");
            my $h = "HTTP/1.1 200 OK\nLast-Modified: 20150202020202\nConnection: close\nContent-Type: image/jpeg\nContent-Length: $size\n\n";
            print "===============\n", $h, "\n^^^^^^^^^^^^^^^^^^^\n";
            syswrite (\*CLIENT, $h);
            copy "d:/perl_programs/mastermind/mastermind.jpg", \*CLIENT;
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

        my $this_player_id = get_player_id_from_name ($CURRENT_LOGIN_NAME, "ddd");
        my $this_players_go = $this_player_id == $whos_turn;

        # HTTP
        if ($txt =~ m/.*next_turn.*/mi && !$GAME_WAITING_FOR_NEXT_TURN)
        {
            my $info .= "Cancelling next turn";
            write_to_socket (\*CLIENT, "$info", "", "redirect");
            next;
        }

        # HTTP
        # Human game choice made! (aka human is the codebreaker against the bot)
        if ($txt =~ m/.*nextChoice.*(White|Blue|Black|Red|Green|Yellow).(White|Blue|Black|Red|Green|Yellow).(White|Blue|Black|Red|Green|Yellow).(White|Blue|Black|Red|Green|Yellow).*/mi)
        {
            my $b1 = lc($1);
            my $b2 = lc($2);
            my $b3 = lc($3);
            my $b4 = lc($4);

            $b1 =~ s/^([WURGY]).*/$1/i;
            $b2 =~ s/^([WURGY]).*/$1/i;
            $b3 =~ s/^([WURGY]).*/$1/i;
            $b4 =~ s/^([WURGY]).*/$1/i;
            $b1 =~ s/^Black/b/i;
            $b2 =~ s/^Black/b/i;
            $b3 =~ s/^Black/b/i;
            $b4 =~ s/^Black/b/i;
            $b1 =~ s/^Blue/u/i;
            $b2 =~ s/^Blue/u/i;
            $b3 =~ s/^Blue/u/i;
            $b4 =~ s/^Blue/u/i;

            my $pot_guess = "$b1$b2$b3$b4";
            my $k;
            my $ok = 1;
            foreach $k (keys (%CURRENT_GUESSES))
            {
                if ($CURRENT_GUESSES {$k} eq $pot_guess)
                {
                    $ok = 0;
                }
            }

            if ($ok)
            {
                $CURRENT_GUESSES {$CURRENT_GUESSES_NUM} = $pot_guess;
                $CURRENT_GUESSES_NUM++;
            }

            if ($CURRENT_GUESSES_NUM >= 8)
            {
                game_won (1, "You lose! You made too many guesses!");
            }

            write_to_socket (\*CLIENT, "Choice made", "", "redirect");
            next;
        }

        if ($txt =~ m/.*nextHardChoice.*(White|Blue|Black|Red|Green|Yellow).(White|Blue|Black|Red|Green|Yellow).(White|Blue|Black|Red|Green|Yellow).(White|Blue|Black|Red|Green|Yellow).*/mi)
        {
            my $b1 = lc($1);
            my $b2 = lc($2);
            my $b3 = lc($3);
            my $b4 = lc($4);

            $b1 =~ s/^([WURGY]).*/$1/i;
            $b2 =~ s/^([WURGY]).*/$1/i;
            $b3 =~ s/^([WURGY]).*/$1/i;
            $b4 =~ s/^([WURGY]).*/$1/i;
            $b1 =~ s/^Black/b/i;
            $b2 =~ s/^Black/b/i;
            $b3 =~ s/^Black/b/i;
            $b4 =~ s/^Black/b/i;
            $b1 =~ s/^Blue/u/i;
            $b2 =~ s/^Blue/u/i;
            $b3 =~ s/^Blue/u/i;
            $b4 =~ s/^Blue/u/i;

            my $pot_guess = "$b1$b2$b3$b4";
            my $k;
            my $ok = 1;
            foreach $k (keys (%CURRENT_GUESSES))
            {
                if ($CURRENT_GUESSES {$k} eq $pot_guess)
                {
                    $ok = 0;
                }
            }

            if ($ok)
            {
                $CURRENT_GUESSES {$CURRENT_GUESSES_NUM} = $pot_guess;
                $CURRENT_GUESSES_NUM++;
            }

            if ($CURRENT_GUESSES_NUM >= 8)
            {
                game_won (1, "You lose! You made too many guesses!");
            }

            write_to_socket (\*CLIENT, "Choice made", "", "redirect");
            next;
        }

        # Bot game choice made! (aka human is the coder)
        if ($txt =~ m/.*humanCoder\?exact=([01234])&partial=([01234]).*/i)
        {
            my $exact = $1;
            my $partial = $2;
            $CURRENT_GUESSES {($CURRENT_GUESSES_NUM-1) . "_response"} = "$exact,$partial";

            if ($exact == 4)
            {
                game_won (1, "You lose! Bot chose the code!");
            }

            if ($CURRENT_GUESSES_NUM >= 9)
            {
                game_won (1, "You win! Bot made too many guesses!");
            }

            my $info = print_bot_beads ();
            $info .= "$reason_for_game_end $center_games_block";
            write_to_socket (\*CLIENT, $info, "", "noredirect");
            next;
        }

        if ($GAME_WAITING_FOR_NEXT_TURN)
        {
            $GAME_WAITING_FOR_NEXT_TURN = 0;
            set_next_turn ();

            my $info .= "Going to next turn";
            write_to_socket (\*CLIENT, "$info", "", "redirect");
            next;
        }

        $txt =~ s/mastermind.*mastermind/mastermind/img;
        print ("2- - - - - - -\n");

        my $won = has_someone_won ();
        if ($won =~ m/^./)
        {
            game_won (1, $won);
            my $info = "Game Over! $won..<br>$center_games_block";
            write_to_socket (\*CLIENT, $info, "", "noredirect");
            next;
        }
        elsif ($GAME_TYPE =~ m/$GAME_TYPE_HARD/)
        {
            my $info = print_hard_beads ();
            write_to_socket (\*CLIENT, $info, "", "noredirect");
            next;
        }
        elsif ($GAME_TYPE =~ m/$GAME_TYPE_HUMAN/)
        {
            my $info = print_beads ();
            write_to_socket (\*CLIENT, $info, "", "noredirect");
            next;
        }
        elsif ($GAME_TYPE =~ m/$GAME_TYPE_BOT/)
        {
            my $info = print_bot_beads ();
            write_to_socket (\*CLIENT, $info, "", "noredirect");
            next;
        }
    }
}
