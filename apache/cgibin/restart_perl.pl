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
