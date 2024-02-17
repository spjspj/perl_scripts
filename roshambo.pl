#!/usr/bin/perl
##
#   File : roshambo.pl
#   Date : 17/Feb/2024
#   Author : spjspj
#   Purpose : Implement Roshambo
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
my $PLAYER_WHO_WON = -1;
my $reason_for_game_end = "";
my $CURRENT_LOGIN_NAME = "";
my $num_players_in_game = -1;
my $num_players_in_lobby = 0;
my $PATH = "d:\\perl_programs\\roshambo";
my $ROCK = "rock";
my $PAPER = "paper";
my $SCISSORS = "scissors";
my $ERROR = -100;

my $DEBUG = "";
my @player_names;
my @NEEDS_REFRESH;
my @NEEDS_ALERT;
my @player_ips;

my %player_chosen_rps;
my %already_shuffled;
my %BANNED_NAMES;
my %rand_colors;

sub is_valid_rps
{
    my $rps = $_ [0];
    if ($rps eq $ROCK || $rps eq $PAPER || $rps eq $SCISSORS)
    {
        return 1;
    }
    return 0;
}

sub who_won
{
    my $first_rps = $_ [0];
    my $second_rps = $_ [1];

    if (!is_valid_rps ($first_rps)) { return $ERROR; }
    if (!is_valid_rps ($second_rps)) { return $ERROR; }

    if ($first_rps eq $second_rps) 
    {
        return 0;
    }
    if ($first_rps eq $ROCK     && $second_rps eq $SCISSORS) { return 1; }
    if ($first_rps eq $ROCK     && $second_rps eq $PAPER)    { return -1; }
    if ($first_rps eq $PAPER    && $second_rps eq $ROCK)     { return 1; }
    if ($first_rps eq $PAPER    && $second_rps eq $SCISSORS) { return -1; }
    if ($first_rps eq $SCISSORS && $second_rps eq $PAPER)    { return 1; }
    if ($first_rps eq $SCISSORS && $second_rps eq $ROCK)     { return -1; }
    return $ERROR;
}

sub game_won
{
    my $player_id = 0;

    $GAME_WON = 0;
    if (!in_game ())
    {
        return;
    }

    while ($player_id < $num_players_in_game)
    {
        if (!has_id_chosen_rps ($player_id))
        {
            return;
        }
        $player_id++;
    }

    my %player_won; 
    my $someone_won = 1;
    my $player_id = 0;
    my $seen_rps = "000";
    while ($player_id < $num_players_in_game)
    {
        my $chosen_rps = $player_chosen_rps {$player_id};
        if ($chosen_rps eq $ROCK) { $seen_rps =~ s/^0/1/; }
        elsif ($chosen_rps eq $PAPER) { $seen_rps =~ s/0(.)$/1$1/; }
        elsif ($chosen_rps eq $SCISSORS) { $seen_rps =~ s/0$/1/; }

        my $opp_player_id = 0;
        while ($opp_player_id < $num_players_in_game)
        {
            if ($opp_player_id != $player_id)
            {
                my $opp_chosen_rps = $player_chosen_rps {$opp_player_id};

                if ($chosen_rps eq $ROCK) { $seen_rps =~ s/^0/1/; }
                elsif ($chosen_rps eq $PAPER) { $seen_rps =~ s/0(.)$/1$1/; }
                elsif ($chosen_rps eq $SCISSORS) { $seen_rps =~ s/0$/1/; }

                my $won = who_won ($chosen_rps, $opp_chosen_rps);
                if ($won != $ERROR)
                {
                    if (!defined (%player_won {$player_id})) 
                    {
                        $player_won {$player_id} = $won;
                    }
                    elsif (defined (%player_won {$player_id})) 
                    {
                           if ($won == 1) { $player_won {$player_id} = 1; }
                        elsif ($won == -1) { $player_won {$player_id} = -1; }
                    }
                }
            }
            $opp_player_id++;
        }
        $player_id++;
    }
    
    $seen_rps =~ s/0//im;
    
    if ($seen_rps eq "1") { $PLAYER_WHO_WON = -1; $GAME_WON = 1; } 
    if ($seen_rps eq "11") { $PLAYER_WHO_WON = 666; $GAME_WON = 1; } 
    if ($seen_rps eq "111") { $PLAYER_WHO_WON = -1; $GAME_WON = 1; } 

    if ($GAME_WON && $PLAYER_WHO_WON > 0)
    {
        $PLAYER_WHO_WON = -1;
        
        $player_id = 0;
        while ($player_id < $num_players_in_game)
        {
            print (" >> Info: ($seen_rps) $player_id $player_won{$player_id}\n");
            if ($PLAYER_WHO_WON == -1 && $player_won {$player_id} == 1)
            {
                $PLAYER_WHO_WON = $player_id;
            }
            elsif ($PLAYER_WHO_WON != -1 && $player_won {$player_id} == 1)
            {
                $GAME_WON = 0; 
                $PLAYER_WHO_WON = -1;
            }
            $player_id++;
        }
    }

    if ($GAME_WON == 1)
    {
        force_needs_refresh();
    }
}

sub get_game_won
{
    if ($GAME_WON == 0)
    {
        return "";
    }
    if ($PLAYER_WHO_WON == -1)
    {
        return "The game was a draw!<br>";
    }
    my $t = get_player_name ($PLAYER_WHO_WON) . " Won!!<br>";
    return $t;
}

sub is_game_over
{
    my $x = get_game_won ();
    return $x ne "";
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
    $msg_body =~ s/href="/href="\/roshambo\//img;
    $msg_body =~ s/\/\//\//img;
    $msg_body =~ s/roshambo.roshambo/roshambo/img;
    $msg_body =~ s/roshambo.roshambo/roshambo/img;
    $msg_body =~ s/roshambo.roshambo/roshambo/img;
    $msg_body =~ s/roshambo.roshambo/roshambo/img;

    my $header;
    if ($redirect =~ m/^redirect/i)
    {
        $header = "HTTP/1.1 302 Moved\nLocation: \/roshambo\/\nLast-Modified: $yyyymmddhhmmss\nConnection: close\nContent-Type: text/html; charset=UTF-8\nContent-Length: " . length ($msg_body) . "\n\n";
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

sub has_id_chosen_rps
{
    my $id = $_ [0];
    print ("Testing - $id --- $player_chosen_rps{$id}\n");
    if (!defined ($player_chosen_rps {$id}))
    {
        return 0;
    }
    if ($player_chosen_rps {$id} eq $ROCK || $player_chosen_rps {$id} eq $PAPER || $player_chosen_rps {$id} eq $SCISSORS)
    {
        return 1;
    }
    return 0;
}

sub choose_rps_with_id
{
    my $in = $_ [0];
    my $id = $_ [1];
    my $n = get_player_name ($id);

    if (has_id_chosen_rps ($id))
    {
        return;
    }

    if ($in =~ m/.*choose.*($ROCK|$PAPER|$SCISSORS).*/mi)
    {
        my $chosen_rps = $1;
        print ("TOOK name_of_card_picked=$chosen_rps by $id!!!\n"); 
        $player_chosen_rps {$id} = "$chosen_rps";
        game_won ();
    }

    force_needs_refresh ();
}

sub choose_rps
{
    my $in = $_ [0];
    my $IP = $_ [1];
    my $id = get_player_id ($IP);
    return choose_rps_with_id ($in, $id);
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
    
    $GAME_WON = 0;
    $PLAYER_WHO_WON = -1;

    $player_chosen_rps {0} = "";
    $player_chosen_rps {1} = "";
    $player_chosen_rps {2} = "";
    $player_chosen_rps {3} = "";
    $player_chosen_rps {4} = "";
    $player_chosen_rps {5} = "";
    $player_chosen_rps {6} = "";
    $player_chosen_rps {7} = "";
    $player_chosen_rps {8} = "";
    $player_chosen_rps {9} = "";

    my $i;
    for ($i = 0; $i < $num_players_in_game; $i++)
    {
        if (get_player_name ($i) =~ m/robot_\d+/)
        {
            my $x = int (rand (3));
            if ($x == 0) { choose_rps_with_id ("choose_$ROCK", $i); }
            if ($x == 1) { choose_rps_with_id ("choose_$PAPER", $i); }
            if ($x == 2) { choose_rps_with_id ("choose_$SCISSORS", $i); }
        }
    }

    force_needs_refresh();
    return;
}

sub reset_game
{
    $num_players_in_game = -1;
    $GAME_WON = 0;
    $PLAYER_WHO_WON = -1;
    $reason_for_game_end = "";
    my $out = "Game reset <a href=\"\/\">Lobby or Game window<\/a>";
    force_needs_refresh();
    my %new_already_shuffled;
    %already_shuffled = %new_already_shuffled;
    
    $player_chosen_rps {0} = "";
    $player_chosen_rps {1} = "";
    $player_chosen_rps {2} = "";
    $player_chosen_rps {3} = "";
    $player_chosen_rps {4} = "";
    $player_chosen_rps {5} = "";
    $player_chosen_rps {6} = "";
    $player_chosen_rps {7} = "";
    $player_chosen_rps {8} = "";
    $player_chosen_rps {9} = "";
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

sub player_row
{
    my $id = $_ [0];
    my $IP = $_ [1];
    my $this_player_id = get_player_id_from_name ($CURRENT_LOGIN_NAME, "ddd");

    my $this_name = get_player_name ($id);
    my $name_cell = "<td><font size=+1 color=darkgreen>$this_name</font></td>";

    my $out = "$this_player_id ($CURRENT_LOGIN_NAME) has chosen???" + has_id_chosen_rps ($id) + "<br>";

    if (!has_id_chosen_rps ($id) && $this_player_id == $id )
    {
        $out .= "You ($this_name) can choose the following: <a href=\"choose_$ROCK\">$ROCK</a>, <a href=\"choose_$PAPER\">$PAPER</a>,<a href=\"choose_$SCISSORS\">$SCISSORS</a><br>";
    }
    elsif (has_id_chosen_rps ($id) && $this_player_id == $id )
    {
        $out .= "You ($this_name) chose: $player_chosen_rps{$id}<br>";
    }
    elsif (has_id_chosen_rps ($id) && $this_player_id ne $id )
    {
        $out .= "Player $this_name has already chosen!";

        if (is_game_over ())
        {
            $out .= " (GAME IS CONCLUDED - They chose " . $player_chosen_rps{$id} . ") ";
        }
        
        $out .= "<br>";
    }
    elsif (!has_id_chosen_rps ($id) && $this_player_id ne $id )
    {
        $out .= "Player $this_name has not yet chosen<br>";
    }

    return "<br>$out<br>";
}

sub get_board
{
    my $IP = $_ [0];
    my $id = get_player_id ($IP);
    if (!in_game ($IP))
    {
        return " NO BOARD TO SEE..";
    }

    my $out = "Current state:<br>";
    $out .= player_row (0, $IP);
    if ($num_players_in_game >= 2) { $out .= player_row (1, $IP); }
    if ($num_players_in_game >= 3) { $out .= player_row (2, $IP); }
    if ($num_players_in_game >= 4) { $out .= player_row (3, $IP); }
    if ($num_players_in_game >= 5) { $out .= player_row (4, $IP); }
    if ($num_players_in_game >= 6) { $out .= player_row (5, $IP); }
    if ($num_players_in_game >= 7) { $out .= player_row (6, $IP); }

    #$out .= $DEBUG;
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

    my $out = "You are in the game! (Total players=$num_players_in_game)<br>";

    if (get_game_won () ne "")
    {
        $out .= get_game_won ();
    }

    my $id = get_player_id ($IP);
    $out .= "Your ID=$id<br>" . get_board ($IP) . "<br>";
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
    $txt .= "            client.get('/roshambo/needs_refresh', function(response) {\n";
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
    $txt .= "<a href=\"\/roshambo\/force_refresh\">Force Refresh<\/a><br>";
    return $txt;
}

sub debug_game
{
    return "";
}

sub get_game_state
{
    my $IP = $_ [0];

    my $out .= "<h1>Welcome to \"ROSHAMBO!\", <font color=" . $rand_colors {$CURRENT_LOGIN_NAME} . ">$CURRENT_LOGIN_NAME</font> </h1><br><br>&nbsp;There are $num_players_in_lobby players logged in.<br>";
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
        $out .= "<font color=green size=+2>Join with your user name here:</font><br><br>";
        $out .= "
            <form action=\"/roshambo/new_user\">
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
        $out .= "<font size=+1 color=red>Welcome to \"ROSHAMBO!\", " . get_player_name ($id) . "<br><\/font>";
        if (in_game ($IP))
        {
            $out = print_game_state ($IP);
            $out .= "Reset the game here: <a href=\"reset_game\">Reset<\/a><br><br><br>";
        }
        elsif (!game_started ())
        {
            if ($num_players_in_lobby >= 1)
            {
                $out .= "<a href=\"new_game\">Start new game!<\/a>";
                $out .= "<br><a href=\"add_bot\">Add bot!<\/a>";
                $out .= "<br><font size=-1>"; 
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
    $out .= get_refresh_code ($do_refresh, $id, -1);
    return $out;
}

sub add_bot
{
    add_new_user ("name=robot_$num_players_in_lobby", "$num_players_in_lobby.$num_players_in_lobby.$num_players_in_lobby.$num_players_in_lobby");
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
    my $port = 14159;
    my $trusted_client;
    my $data_from_client;
    $|=1;

    print ("example: $PATH\\roshambo.pl 1 1 0 1 1 \"each opponent\" \".*\" 0 5\n\n");

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
            my $size = -s ("d:/perl_programs/roshambo/_roshambo.jpg");
            print (">>>>> size = $size\n");
            my $h = "HTTP/1.1 200 OK\nLast-Modified: 20150202020202\nConnection: close\nContent-Type: image/jpeg\nContent-Length: $size\n\n";
            print "===============\n", $h, "\n^^^^^^^^^^^^^^^^^^^\n";
            syswrite (\*CLIENT, $h);
            copy "d:/perl_programs/roshambo/_roshambo.jpg", \*CLIENT;
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
        
        if ($txt =~ m/.*choose.*(rock|paper|scissors).*/mi)
        {
            choose_rps ("$txt", $client_addr);
            my $page = get_game_state ($client_addr);
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
        }

        # HTTP
        if ($txt =~ m/GET.*add_bot.*/m)
        {
            add_bot ();
            write_to_socket (\*CLIENT, "New bot added <a href=\"\/DONEDASBOOT\">Lobby or Game window<\/a>", "", "redirect");
            next;
        }

        # HTTP
        if ($txt =~ m/.*reset.*game.*/m)
        {
            write_to_socket (\*CLIENT, reset_game (), "", "redirect");
            next;
        }

        $txt =~ s/roshambo.*roshambo/roshambo/img;

        print ("2- - - - - - -\n");
        write_to_socket (\*CLIENT, get_game_state($client_addr), "", "noredirect");

        print ("============================================================\n");
    }
}
