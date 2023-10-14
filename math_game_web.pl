#!/usr/bin/perl
##
#   File : math_game_web.pl
#   Date : 8/Oct/2023
#   Author : spjspj
#   Purpose : Make a online math game ..
##

use strict;
use POSIX;
use LWP::Simple;
use Socket;
use File::Copy;

my $SUPPLIED_PASSWORD;

#####
sub write_to_socket
{
    my $sock_ref = $_ [0];
    my $msg_body = $_ [1];
    my $form = $_ [2];
    my $redirect = $_ [3];
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    my $yyyymmddhhmmss = sprintf "%.4d%.2d%.2d-%.2d%.2d%.2d", $year+1900, $mon+1, $mday, $hour,  $min, $sec;
    print $yyyymmddhhmmss, "\n";

    $msg_body = $msg_body;

    my $header;
    if ($redirect =~ m/^redirect/i)
    {
        $header = "HTTP/1.1 302 Moved\nLocation: /math_game/\nLast-Modified: $yyyymmddhhmmss\nConnection: close\nContent-Type: text/html; charset=UTF-8\nContent-Length: " . length ($msg_body) . "\n\n";
        print (">>> $header <<<\n");
    }
    elsif ($redirect =~ m/^noredirect/i)
    {
        if ($SUPPLIED_PASSWORD =~ m/^$/)
        {
            $header = "HTTP/1.1 200 OK\nLast-Modified: $yyyymmddhhmmss\nConnection: close\nContent-Type: text/html; charset=UTF-8\nContent-Length: " . length ($msg_body) . "\n\n";
        }
        else
        {
            $header = "HTTP/1.1 200 OK\nLast-Modified: $yyyymmddhhmmss\nConnection: close\nContent-Type: text/html\nSet-Cookie: SUPPLIED_PASSWORD=$SUPPLIED_PASSWORD\nContent-Length: " . length ($msg_body) . "\n\n";
        }
    }

    $msg_body =~ s/\n\n/\n/mig;
    $msg_body =~ s/\n\n/\n/mig;
    $msg_body =~ s/\n\n/\n/mig;
    $msg_body = $header . $msg_body;
    $msg_body =~ s/\.png/\.npg/;
    $msg_body =~ s/img/mgi/;
    $msg_body .= chr(13) . chr(10) . "0";
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

my $num_terms = int (rand (4)) + 3;
my %nums;
my %used_nums;
my %used_terms;
my $equation;
my $eq;

sub new_number
{
    my $upper_limit = $_ [0];
    my $temp_num = int (rand ($upper_limit)) + 1;
    while (defined ($used_nums {$temp_num}))
    {
        $temp_num = int (rand ($upper_limit)) + 1;
    }
    
    $used_nums {$temp_num} = 1;
    return $temp_num;
}

sub create_new_game
{
    my %a;
    my %b;
    my %c;
    my %d;
    my $hard = $_ [0];

    $num_terms = int (rand (4)) + 3;
    %nums = %b;
    %used_nums = %c;
    %used_terms = %d;
    $equation = "";

    print ($num_terms , " is number of terms\n");
    my $operator_dice = 7;
    if ($hard)
    {
        $nums {0} = new_number (4);
        $nums {1} = new_number (10);
        $nums {2} = new_number (20);
        $nums {3} = new_number (50);
        $nums {4} = new_number (100);
        $nums {5} = new_number (100);
        $operator_dice = 9;
        $num_terms = int (rand (2));
        if ($num_terms == 0)
        {
            $num_terms = 5;
        }
        else
        {
            $num_terms = 6;
        }
    }
    elsif (!$hard)
    {
        $nums {0} = new_number (5);
        $nums {1} = new_number (5);
        $nums {2} = new_number (10);
        $nums {3} = new_number (10);
        $nums {4} = new_number (20);
        $nums {5} = new_number (40);
    }

    $used_terms {0} = 0;
    $used_terms {1} = 0;
    $used_terms {2} = 0;
    $used_terms {3} = 0;
    $used_terms {4} = 0;
    $used_terms {5} = 0;
    $used_terms {6} = 0;
    my $had_divide = 0;

    for (my $i = 0; $i < $num_terms - 1; $i++)
    {
        my $number = int (rand (6));
        while ($used_terms {$number} == 1)
        {
            $number = int (rand (6));
        }
        $used_terms {$number} = 1;
        $equation .= $nums {$number};

        my $operator = int (rand ($operator_dice));
        my $sign;
        if ($operator < 2) { $sign = "+"; }
        elsif ($operator < 4) { $sign = "-"; }
        elsif ($operator < 6 || $had_divide) { $sign = "*"; }
        else { $sign = "/"; $had_divide = 1; }
    
        $equation .= $sign;
    }

    my $number = int (rand (6));
    while ($used_terms {$number} == 1)
    {
        $number = int (rand (6));
    }
    $used_terms {$number} = 1;
    $equation .= $nums {$number};
    
    print ("ANSWER GIVEN:\n");
    print (join (",", values (%nums))), "\n";
    print "\n";
    print ($equation, "\n");
    $eq = eval ($equation);
    print ("Answer is: ", $eq, "\n");

    print ("\n\n\n\n\n\n\n\n\nNO ANSWER GIVEN:\n");
    print (join (",", values (%nums))), "\n";
    print "\n";
    #print ($equation, "\n");
    $eq = eval ($equation);
    print ("Answer is: ", $eq, "\n");
}

sub make_html_code
{
    my $string = "";
    my $green = '#04AA6D';
    $string = "<!DOCTYPE html>\n";
    $string .= "<html>\n";
    $string .= "<head>\n";
    $string .= "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n";
    $string .= "<style>\n";
    $string .= ".button {\n";
    $string .= "  background-color: $green; /* Green */\n";
    $string .= "  border: none;\n";
    $string .= "  color: white;\n";
    $string .= "  padding: 20px;\n";
    $string .= "  text-align: center;\n";
    $string .= "  text-decoration: none;\n";
    $string .= "  display: inline-block;\n";
    $string .= "  font-size: 16px;\n";
    $string .= "  margin: 4px 2px;\n";
    $string .= "  cursor: pointer;\n";
    $string .= "}\n";
    $string .= ".button1 {border-radius: 12px;}\n";
    $string .= ".answer_button {\n";
    $string .= "  background-color: #B939C9; /* purple */\n";
    $string .= "  border: none;\n";
    $string .= "  color: white;\n";
    $string .= "  padding: 20px;\n";
    $string .= "  text-align: center;\n";
    $string .= "  text-decoration: none;\n";
    $string .= "  display: inline-block;\n";
    $string .= "  font-size: 16px;\n";
    $string .= "  margin: 4px 2px;\n";
    $string .= "  cursor: pointer;\n";
    $string .= "}\n";
    $string .= ".answer_button1 {border-radius: 12px;}\n";
    $string .= ".youranswer_button {\n";
    $string .= "  background-color: #B9D949; /* yellowy */\n";
    $string .= "  border: none;\n";
    $string .= "  color: white;\n";
    $string .= "  padding: 20px;\n";
    $string .= "  text-align: center;\n";
    $string .= "  text-decoration: none;\n";
    $string .= "  display: inline-block;\n";
    $string .= "  font-size: 16px;\n";
    $string .= "  margin: 4px 2px;\n";
    $string .= "  cursor: pointer;\n";
    $string .= "}\n";
    $string .= ".youranswer_button1 {border-radius: 12px;}\n";
    $string .= ".operation_button {\n";
    $string .= "  background-color: #B98949; /* bluey */";
    $string .= "  border: none;\n";
    $string .= "  color: white;\n";
    $string .= "  padding: 20px;\n";
    $string .= "  text-align: center;\n";
    $string .= "  text-decoration: none;\n";
    $string .= "  display: inline-block;\n";
    $string .= "  font-size: 16px;\n";
    $string .= "  margin: 4px 2px;\n";
    $string .= "  cursor: pointer;\n";
    $string .= "}\n";
    $string .= ".operation_button1 {border-radius: 12px;}\n";
    $string .= ".undo_button {\n";
    $string .= "  background-color: #343499; /* bluey */";
    $string .= "  border: none;\n";
    $string .= "  color: white;\n";
    $string .= "  padding: 20px;\n";
    $string .= "  text-align: center;\n";
    $string .= "  text-decoration: none;\n";
    $string .= "  display: inline-block;\n";
    $string .= "  font-size: 16px;\n";
    $string .= "  margin: 4px 2px;\n";
    $string .= "  cursor: pointer;\n";
    $string .= "}\n";
    $string .= ".undo_button1 {border-radius: 12px;}\n";
    $string .= "</style>\n";
    $string .= "</head>\n";
    $string .= "<body>\n";
    $string .= "<h2>Math Game!</h2>\n";

    my $num;
    my $num_html;
    my $reset_button_ids = "";
    foreach $num (sort (values (%nums)))
    {
        $num_html .= "<button id='button$num' onclick=\"add_to_equation($num, 'button$num')\" class=\"button button1\">$num</button>&nbsp;\n";
        $reset_button_ids .= "enable_thing ('button$num');";
    }

    $num_html .= "<br><br><button onclick=\"add_to_equation('+')\" class=\"operation_button operation_button1\">+</button>&nbsp;\n";
    $num_html .= "<button onclick=\"add_to_equation('-')\" class=\"operation_button operation_button1\">-</button>&nbsp;\n";
    $num_html .= "<button onclick=\"add_to_equation('*')\" class=\"operation_button operation_button1\">*</button>&nbsp;\n";
    $num_html .= "<button onclick=\"add_to_equation('\/')\" class=\"operation_button operation_button1\">\/</button>&nbsp;\n";
    $num_html .= "<br><br>Your equation so far:\n";
    $num_html .= "<br><p id='equation'></p>\n";
    $num_html .= "<br><br>Your answer so far:\n";
    $num_html .= "<br><br><button id=\"youranswer\" class=\"youranswer_button youranswer_button1\">&nbsp;</button>&nbsp;\n";
    $num_html .= "<button id=\"status\" onclick=\"clear_all();$reset_button_ids\" class=\"operation_button operation_button1\">Clear</button>&nbsp;\n";
    $num_html .= "<button id=\"undo\" onclick=\"undo_last_action();\" class=\"undo_button undo_button1\">Undo</button>&nbsp;\n";
    $num_html .= "<button id=\"reveal\" onclick=\"reveal_answer();\" class=\"undo_button undo_button1\">Reveal Answer..</button>&nbsp;\n";
    #$num_html .= "<br><br>Actual answer for hidden equation ($equation - based on $num_terms):\n";
    $num_html .= "<br><br>Actual answer for hidden equation (Solution will use $num_terms terms):\n";
    $num_html .= "<br><br><button id=\"actualanswer\" class=\"answer_button answer_button1\">$eq</button>&nbsp;\n";

    $num_html .= "<script>\n";
    $num_html .= " let old_state1 = \"\";";
    $num_html .= " let old_state2 = \"\";";
    $num_html .= " let old_state3 = \"\";";
    $num_html .= " let old_state4 = \"\";";
    $num_html .= " let old_state5 = \"\";";
    $num_html .= " let old_state6 = \"\";";
    $num_html .= " let old_state7 = \"\";";
    $num_html .= " let old_state8 = \"\";";
    $num_html .= " let old_state9 = \"\";";
    $num_html .= " let old_state10 = \"\";";
    $num_html .= " let old_state11 = \"\";";
    $num_html .= " let old_button1 = \"\";";
    $num_html .= " let old_button2 = \"\";";
    $num_html .= " let old_button3 = \"\";";
    $num_html .= " let old_button4 = \"\";";
    $num_html .= " let old_button5 = \"\";";
    $num_html .= " let old_button6 = \"\";";
    $num_html .= " let old_button7 = \"\";";
    $num_html .= " let old_button8 = \"\";";
    $num_html .= " let old_button9 = \"\";";
    $num_html .= " let old_button10 = \"\";";
    $num_html .= " let old_button11 = \"\";";
    $num_html .= " let track_states = 0;";
    $num_html .= " document.getElementById('undo').disabled = true;\n";
    $num_html .= " document.getElementById('undo').style.background='#999999';\n";
    $num_html .= "function add_to_equation(thing_to_add, button_id)\n";
    $num_html .= "{\n";
    $num_html .= "    document.getElementById('equation').innerHTML = document.getElementById('equation').innerHTML + thing_to_add;\n";
    $num_html .= "    document.getElementById('youranswer').innerHTML = eval (document.getElementById('equation').innerHTML);\n";
    $num_html .= "    document.getElementById(button_id).disabled = true;\n";
    $num_html .= "    document.getElementById(button_id).style.background='#999999';\n";
    $num_html .= "    if (document.getElementById('youranswer').innerHTML == document.getElementById('actualanswer').innerHTML)\n";
    $num_html .= "    {\n";
    $num_html .= "        document.getElementById('status').innerHTML = 'YOU WIN!';\n";
    $num_html .= "    }\n";
    $num_html .= "    track_states++;";
    $num_html .= "    if (track_states == 11) { old_state11 = document.getElementById('equation').innerHTML; old_button11 = button_id; } ";
    $num_html .= "    if (track_states == 10) { old_state10 = document.getElementById('equation').innerHTML; old_button10 = button_id; } ";
    $num_html .= "    if (track_states == 9) { old_state9 = document.getElementById('equation').innerHTML; old_button9 = button_id; } ";
    $num_html .= "    if (track_states == 8) { old_state8 = document.getElementById('equation').innerHTML; old_button8 = button_id; } ";
    $num_html .= "    if (track_states == 7) { old_state7 = document.getElementById('equation').innerHTML; old_button7 = button_id; } ";
    $num_html .= "    if (track_states == 6) { old_state6 = document.getElementById('equation').innerHTML; old_button6 = button_id; } ";
    $num_html .= "    if (track_states == 5) { old_state5 = document.getElementById('equation').innerHTML; old_button5 = button_id; } ";
    $num_html .= "    if (track_states == 4) { old_state4 = document.getElementById('equation').innerHTML; old_button4 = button_id; } ";
    $num_html .= "    if (track_states == 3) { old_state3 = document.getElementById('equation').innerHTML; old_button3 = button_id; } ";
    $num_html .= "    if (track_states == 2) { old_state2 = document.getElementById('equation').innerHTML; old_button2 = button_id; } ";
    $num_html .= "    if (track_states == 1) { old_state1 = document.getElementById('equation').innerHTML; old_button1 = button_id; } ";
    $num_html .= "    document.getElementById('undo').disabled = false;\n";
    $num_html .= "    document.getElementById('undo').style.background='#343499';\n";
    $num_html .= "}\n";
    $num_html .= "function clear_all()\n";
    $num_html .= "{\n";
    $num_html .= "    document.getElementById('equation').innerHTML = '';\n";
    $num_html .= "    document.getElementById('youranswer').innerHTML = '&nbsp;';\n";
    $num_html .= "    document.getElementById('status').innerHTML = 'Clear';\n";
    $num_html .= "    document.getElementById('undo').disabled = true;\n";
    $num_html .= "    document.getElementById('undo').style.background='#999999';\n $reset_button_ids";
    $num_html .= "    old_state1 = \"\";";
    $num_html .= "    old_state2 = \"\";";
    $num_html .= "    old_state3 = \"\";";
    $num_html .= "    old_state4 = \"\";";
    $num_html .= "    old_state5 = \"\";";
    $num_html .= "    old_state6 = \"\";";
    $num_html .= "    old_state7 = \"\";";
    $num_html .= "    old_state8 = \"\";";
    $num_html .= "    old_state9 = \"\";";
    $num_html .= "    old_state10 = \"\";";
    $num_html .= "    old_state11 = \"\";";
    $num_html .= "    old_button1 = \"\";";
    $num_html .= "    old_button2 = \"\";";
    $num_html .= "    old_button3 = \"\";";
    $num_html .= "    old_button4 = \"\";";
    $num_html .= "    old_button5 = \"\";";
    $num_html .= "    old_button6 = \"\";";
    $num_html .= "    old_button7 = \"\";";
    $num_html .= "    old_button8 = \"\";";
    $num_html .= "    old_button9 = \"\";";
    $num_html .= "    old_button10 = \"\";";
    $num_html .= "    old_button11 = \"\";";
    $num_html .= "    track_states = 0;";
    $num_html .= "}\n";
    $num_html .= "function undo_last_action()\n";
    $num_html .= "{\n";
    $num_html .= "    if (track_states == 1) { clear_all(); return; } ";
    $num_html .= "    if (track_states == 2) { document.getElementById('equation').innerHTML = old_state1; track_states = 1; enable_thing (old_button2); } ";
    $num_html .= "    if (track_states == 3) { document.getElementById('equation').innerHTML = old_state2; track_states = 2; enable_thing (old_button3); } ";
    $num_html .= "    if (track_states == 4) { document.getElementById('equation').innerHTML = old_state3; track_states = 3; enable_thing (old_button4); } ";
    $num_html .= "    if (track_states == 5) { document.getElementById('equation').innerHTML = old_state4; track_states = 4; enable_thing (old_button5); } ";
    $num_html .= "    if (track_states == 6) { document.getElementById('equation').innerHTML = old_state5; track_states = 5; enable_thing (old_button6); } ";
    $num_html .= "    if (track_states == 7) { document.getElementById('equation').innerHTML = old_state6; track_states = 6; enable_thing (old_button7); } ";
    $num_html .= "    if (track_states == 8) { document.getElementById('equation').innerHTML = old_state7; track_states = 7; enable_thing (old_button8); } ";
    $num_html .= "    if (track_states == 9) { document.getElementById('equation').innerHTML = old_state8; track_states = 8; enable_thing (old_button9); } ";
    $num_html .= "    if (track_states == 10) { document.getElementById('equation').innerHTML = old_state9; track_states = 9; enable_thing (old_button10); } ";
    $num_html .= "    if (track_states == 11) { document.getElementById('equation').innerHTML = old_state10; track_states = 10; enable_thing (old_button11); } ";
    $num_html .= "    document.getElementById('youranswer').innerHTML = eval (document.getElementById('equation').innerHTML);\n";
    $num_html .= "}\n";
    $num_html .= "function enable_thing (button_id)\n";
    $num_html .= "{\n";
    $num_html .= "    document.getElementById(button_id).disabled = false;\n";
    $num_html .= "    document.getElementById(button_id).style.background='$green';\n";
    $num_html .= "}\n";
    $num_html .= "function reveal_answer ()\n";
    $num_html .= "{\n";
    $num_html .= "    document.getElementById('equation').innerHTML = '$equation';\n";
    $num_html .= "    document.getElementById('status').innerHTML = 'YOU LOSE :(';\n";
    $num_html .= "    document.getElementById('status').disabled = true;\n";
    $num_html .= "    document.getElementById('undo').disabled = true;\n";
    $num_html .= "}\n";

    $num_html .= "</script>\n";
    
    $string .= "$num_html<br><a href=\"make_new_game_now_$eq\">Make a new game!<\/a>\n";
    $string .= "&nbsp;<a href=\"make_new_hard_game_now_$eq\">*HARD* Make a new game!<\/a></body>\n";


    $string .= "</html>";
    return $string;
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
    my $port = 1234;
    my $trusted_client;
    my $data_from_client;
    $|=1;

    create_new_game (0);

    socket (SERVER, PF_INET, SOCK_STREAM, $proto) or die "Failed to create a socket: $!";
    setsockopt (SERVER, SOL_SOCKET, SO_REUSEADDR, 1) or die "setsocketopt: $!";

    # bind to a port, then listen
    bind (SERVER, sockaddr_in ($port, INADDR_ANY)) or die "Can't bind to port $port! \n";

    listen (SERVER, 10) or die "listen: $!";
    print ("Listening on port: $port\n");
    my $count;
    my $not_seen_full = 1;
    my $html_text = "";

    while ($paddr = accept (CLIENT, SERVER))
    {
        print ("\n\nNEW============================================================\n");
        print ("New connection\n");
        ($client_port, $iaddr) = sockaddr_in ($paddr);
        $client_addr = inet_ntoa ($iaddr);
        print ("\n$client_addr\n");

        my $lat;
        my $long;
        my $txt = read_from_socket (\*CLIENT);
        print ("FIRST Checking against - $txt\n");
        $txt =~ s/math_game\/math_game/math_game\//img;
        $txt =~ s/math_game\/math_game/math_game\//img;
        $txt =~ s/math_game\/math_game/math_game\//img;
        $txt =~ s/math_game\/math_game/math_game\//img;

        print ("Checking against - $txt\n");
        if ($txt =~ m/make_new_game/im)
        {
            create_new_game (0);
            my $html_text = make_html_code ();
            write_to_socket (\*CLIENT, $html_text, "", "redirect");
            next;
        }
        
        if ($txt =~ m/make_new_hard_game_now_/im)
        {
            create_new_game (1);
            my $html_text = make_html_code ();
            write_to_socket (\*CLIENT, $html_text, "", "redirect");
            next;
        }

        my $html_text = make_html_code ();
        write_to_socket (\*CLIENT, $html_text, "", "noredirect");
    }
}
