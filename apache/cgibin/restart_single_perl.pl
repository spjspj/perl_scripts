#!D:\StrawberryPerl\perl\bin\perl.exe
# -T

use strict;
use warnings;

print "Content-type: text/html; charset=iso-8859-1\n\n";
print "Restarting perl scripts on this server!<br>\n";

my $port = $ARGV [0];
my $perl_script;
print ("<br>&nbsp;Called with ($port):<br>");

my $output;
my %perl_ports;
$perl_ports {"create_magic_card.pl"} = "d:\\perl_programs\\create_magic_card.pl";
$perl_ports {"csv_analyse.pl"} = "d:\\perl_programs\\csv_analyse.pl";
$perl_ports {"cthulhu.pl"} = "d:\\perl_programs\\cthulhu\\cthulhu.pl";
$perl_ports {"decode_words.pl"} = "d:\\perl_programs\\decode_words.pl";
$perl_ports {"describe_magic_cards.pl"} = "d:\\perl_programs\\describe_magic_cards.pl";
$perl_ports {"draft_magic_auto_normal.pl"} = "d:\\perl_programs\\draft_magic_auto_normal.pl";
$perl_ports {"draft_magic_cube.pl"} = "d:\\perl_programs\\draft_magic_cube.pl";
$perl_ports {"filter_magic.pl"} = "d:\\perl_programs\\filter_magic.pl";
$perl_ports {"get_magic_deck.pl"} = "d:\\perl_programs\\get_magic_deck.pl";
$perl_ports {"hearts.pl"} = "d:\\perl_programs\\hearts\\hearts.pl";
$perl_ports {"mastermind.pl"} = "d:\\perl_programs\\mastermind\\mastermind.pl";
$perl_ports {"math_game_web.pl"} = "d:\\perl_programs\\math_game_web.pl";
$perl_ports {"mk_pss_html.pl"} = "d:\\perl_programs\\pss\\mk_pss_html.pl";
$perl_ports {"nothanks.pl"} = "d:\\perl_programs\\nothanks\\nothanks.pl";
$perl_ports {"purchased_cards.pl"} = "d:\\perl_programs\\purchased_cards.pl";
$perl_ports {"quest.pl"} = "d:\\perl_programs\\quest\\quest.pl";
$perl_ports {"roshambo.pl"} = "d:\\perl_programs\\roshambo\\roshambo.pl";
$perl_ports {"secure_copy_paste_w_images.pl"} = "d:\\perl_programs\\secure_copy_paste_w_images.pl";
$perl_ports {"solve_wordle.pl"} = "d:\\perl_programs\\solve_wordle.pl";
$perl_ports {"ALL"} = "all";

my %kill_perl_ports;
$kill_perl_ports {"create_magic_card.pl"} = 33334;
$kill_perl_ports {"csv_analyse.pl"} = 3867;
$kill_perl_ports {"cthulhu.pl"} = 6728;
$kill_perl_ports {"decode_words.pl"} = 23128;
$kill_perl_ports {"describe_magic_cards.pl"} = 50000;
$kill_perl_ports {"draft_magic_auto_normal.pl"} = 60000;
$kill_perl_ports {"draft_magic_cube.pl"} = 40000;
$kill_perl_ports {"filter_magic.pl"} = 56789;
$kill_perl_ports {"get_magic_deck.pl"} = 60001;
$kill_perl_ports {"hearts.pl"} = 2718;
$kill_perl_ports {"mastermind.pl"} = 6663;
$kill_perl_ports {"math_game_web.pl"} = 1234;
#$kill_perl_ports {"mk_pss_html.pl"} = 7732;
$kill_perl_ports {"nothanks.pl"} = 3967;
$kill_perl_ports {"purchased_cards.pl"} = 6723;
$kill_perl_ports {"quest.pl"} = 3672;
$kill_perl_ports {"roshambo.pl"} = 14159;
$kill_perl_ports {"secure_copy_paste_w_images.pl"} = 6725;
$kill_perl_ports {"solve_wordle.pl"} = 4590;

my %named_perl_ports;
$named_perl_ports {33334} = "create_magic_card.pl";
$named_perl_ports {3867} = "csv_analyse.pl";
$named_perl_ports {6728} = "cthulhu.pl";
$named_perl_ports {23128} = "decode_words.pl";
$named_perl_ports {50000} = "describe_magic_cards.pl";
$named_perl_ports {60000} = "draft_magic_auto_normal.pl";
$named_perl_ports {40000} = "draft_magic_cube.pl";
$named_perl_ports {56789} = "filter_magic.pl";
$named_perl_ports {60001} = "get_magic_deck.pl";
$named_perl_ports {2718} = "hearts.pl";
$named_perl_ports {6663} = "mastermind.pl";
$named_perl_ports {1234} = "math_game_web.pl";
#$named_perl_ports {7732} = "mk_pss_html.pl";
$named_perl_ports {3967} = "nothanks.pl";
$named_perl_ports {6723} = "purchased_cards.pl";
$named_perl_ports {3672} = "quest.pl";
$named_perl_ports {14159} = "roshambo.pl";
$named_perl_ports {6725} = "secure_copy_paste_w_images.pl";
$named_perl_ports {4590} = "solve_wordle.pl";

$perl_script = $named_perl_ports {$port};
print ("Incoming port = $port, this maps to $perl_script<br>");

# All restart
if ($port =~ m/all/img)
{
    print "Starting all perl processes:<br>\n";

    my @args;
    $args [0] = "d:\\perl_programs\\abadice\\abadice.pl";
    system (1, @args);
    print ("Done -- abadice!<br>");
    my @args;
    $args [0] = "d:\\perl_programs\\mastermind\\mastermind.pl";
    system (1, @args);
    print ("Done -- mastermind!<br>");
    $args [0] = "d:\\perl_programs\\cthulhu\\cthulhu.pl";
    system (1, @args);
    print ("Done -- cthulhu!<br>");
    $args [0] = "d:\\perl_programs\\describe_magic_cards.pl";
    system (1, @args);
    print ("Done -- describe_magic_cards!<br>");
    $args [0] = "d:\\perl_programs\\draft_magic_auto_normal.pl";
    system (1, @args);
    print ("Done -- draft_magic_auto_normal!<br>");
    $args [0] = "d:\\perl_programs\\draft_magic_cube.pl";
    system (1, @args);
    print ("Done -- draft_magic_cube!<br>");
    $args [0] = "d:\\perl_programs\\filter_magic.pl";
    system (1, @args);
    print ("Done -- filter_magic!<br>");
    $args [0] = "d:\\perl_programs\\get_magic_deck.pl";
    system (1, @args);
    print ("Done -- get_magic_deck!<br>");
    $args [0] = "d:\\perl_programs\\nothanks\\nothanks.pl";
    system (1, @args);
    print ("Done -- nothanks!<br>");
    $args [0] = "d:\\perl_programs\\hearts\\hearts.pl";
    system (1, @args);
    print ("Done -- hearts!<br>");
    $args [0] = "d:\\perl_programs\\quest\\quest.pl";
    system (1, @args);
    print ("Done -- quest!<br>");
    $args [0] = "d:\\perl_programs\\create_magic_card.pl";
    system (1, @args);
    print ("Done -- create magic card!<br>");
    $args [0] = "d:\\perl_programs\\purchased_cards.pl";
    system (1, @args);
    print ("Done -- track purchased cards!<br>");
    $args [0] = "d:\\perl_programs\\secure_copy_paste_w_images.pl";
    system (1, @args);
    print ("Done -- secure copy paste!<br>");
    $args [0] = "d:\\perl_programs\\csv_analyse.pl";
    system (1, @args);
    print ("Done -- track csv analyse!<br>");
    $args [0] = "d:\\perl_programs\\math_game_web.pl";
    system (1, @args);
    print ("Done -- Math Game!<br>");
    $args [0] = "d:\\perl_programs\\solve_wordle.pl";
    system (1, @args);
    print ("Done -- Solve Wordle!<br>");
    $args [0] = "d:\\perl_programs\\roshambo\\roshambo.pl";
    system (1, @args);
    print ("Done -- Roshambo!<br>");
    $args [0] = "d:\\perl_programs\\grabarope\\grabarope.pl";
    system (1, @args);
    print ("Done -- Grabarope!<br>");
    $args [0] = "d:\\perl_programs\\decode_words.pl";
    system (1, @args);
    print ("Done -- Decodewords!<br>");
    $args [0] = "d:\\perl_programs\\pss\\mk_pss_html.pl";
    system (1, @args);
    print ("Done -- mk_pss_html!<br>");

    print "Started all perl processes:<br>$port was requested!<br>\n";
}
elsif (defined ($named_perl_ports {$port}))
{
    print ("$port is here: " . $perl_ports {lc ($port)} . "<br>" );
    if ($port =~ m/^\d+$/)
    {
        print "Killing a single perl process for $port:<br>\n";
        my $netstat = `netstat -a -no -b`;
        $netstat =~ s/\n//img;
        $netstat =~ s/TCP/\n<br>TCP/img;
        #print $netstat;

        # Example:
        # TCP    0.0.0.0:6725           0.0.0.0:0              LISTENING       14388 [perl.exe] 
        my $output;
        my $kill_pid;
        
        while ($netstat =~ s/^(.*?)\n//m)
        {
            my $line = $1;
            if ($line =~ m/(\d+) \[perl/)
            {
                print ("  Found perl - $line<br>\n");
                my $script;
                my $val;
                my $pid = $1;
                foreach $script (sort (keys (%perl_ports)))
                {
                    $val = $kill_perl_ports {$script};
                    if ($line =~ m/$val/)
                    {
                        if ($port == $val)
                        {
                            $kill_pid = $pid;
                            print ("  THE ONE TO KILL ($kill_pid)!<br>");
                        }
                    }
                }
            }
        }

        my $task_kill = "taskkill \/f \/pid $kill_pid";
        `$task_kill`;
        print "Killed single process:<br>$task_kill!<br>\n";
    }

    my $fn = $perl_ports {$perl_script};
    print "Restarting a single perl process -> $port from $fn:<br>\n";

    my @args;
    $args [0] = $fn;
    system (1, @args);
}

print "Finished!<br>\n";
