#!D:\StrawberryPerl\perl\bin\perl.exe
# -T

use strict;
use warnings;

print "Content-type: text/html; charset=iso-8859-1\n\n";
print "Restarting perl scripts on this server!<br>\n";

#my $pid = fork; exec "d:\\perl_programs\\abadice\\abadice.pl" if not $pid;
my @args;
$args [0] = "d:\\perl_programs\\abadice\\abadice.pl";
system (1, @args);
print ("Done -- abadice!<br>");
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
$args [0] = "d:\\perl_programs\\quest\\quest.pl";
system (1, @args);
print ("Done -- quest!<br>");
$args [0] = "d:\\perl_programs\\create_magic_card.pl";
system (1, @args);
print ("Done -- create magic card!<br>");
$args [0] = "d:\\perl_programs\\purchased_cards.pl";
system (1, @args);
print ("Done -- track purchased cards!<br>");
$args [0] = "d:\\perl_programs\\secure_image.pl";
system (1, @args);
print ("Done -- secure image!<br>");
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
$args [0] = "d:\\perl_programs\\roshambo.pl";
system (1, @args);
print ("Done -- Roshambo!<br>");
