#!D:\StrawberryPerl\perl\bin\perl.exe
# -T

use strict;
use warnings;

print "Content-type: text/html; charset=iso-8859-1\n\n";
print "Restarting perl scripts on this server!<br>\n";

my $port = $ARGV [0];
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

# All kill??
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
elsif (defined ($perl_ports {lc ($port)}))
{
    my $fn = $perl_ports {lc ($port)};
    print "Restarting a single perl process -> $port from $fn:<br>\n";

    my @args;
    $args [0] = $fn;
    system (1, @args);
}

print "Finished!<br>\n";
