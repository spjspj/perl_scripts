#!D:\StrawberryPerl\perl\bin\perl.exe
# -T
##
#   File : kill_perl.pl
#   Date : 22/12/2022
#   Author : spjspj
#   Purpose : Check expected perl scripts are running.. 
##

use strict;
use warnings;

print "Content-type: text/html; charset=iso-8859-1\n\n";
print "Restart games on this server!<br>\n";

# C:\Users\spjones>tasklist  /fi "PID eq 17764"
my $tasks = `tasklist | find /I "perl"`;
$tasks =~ s/^perl.exe\s*/taskkill \/f \/pid /img;
$tasks =~ s/(.*?\d+).*/$1/img;

print $tasks;
while ($tasks =~ s/^(.*)\n//)
{
    my $task = $1;
    print ("Running.. $task..\n");
    `$task`;
}

#my $pid = fork; exec "d:\\perl_programs\\abadice\\abadice.pl" if not $pid;

#d:\\perl_programs\\cthulhu\\cthulhu.pl
#d:\\perl_programs\\describe_magic_cards.pl
#d:\\perl_programs\\draft_magic_auto_normal.pl
#d:\\perl_programs\\draft_magic_cube.pl
#d:\\perl_programs\\filter_magic.pl
#d:\\perl_programs\\get_magic_deck.pl
#d:\\perl_programs\\nothanks\\nothanks.pl
#d:\\perl_programs\\quest\\quest.pl
