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
print "Kill perl on this server!<br>\n";

my $output;
my %perl_ports;
$perl_ports {"create_magic_card.pl"} = 33334;
$perl_ports {"csv_analyse.pl"} = 3867;
$perl_ports {"cthulhu.pl"} = 6728;
$perl_ports {"decode_words.pl"} = 23128;
$perl_ports {"describe_magic_cards.pl"} = 50000;
$perl_ports {"draft_magic_auto_normal.pl"} = 60000;
$perl_ports {"draft_magic_cube.pl"} = 40000;
$perl_ports {"filter_magic.pl"} = 56789;
$perl_ports {"get_magic_deck.pl"} = 60001;
$perl_ports {"hearts.pl"} = 2718;
$perl_ports {"mastermind.pl"} = 6663;
$perl_ports {"math_game_web.pl"} = 1234;
$perl_ports {"mk_pss_html.pl"} = 7732;
$perl_ports {"nothanks.pl"} = 3967;
$perl_ports {"purchased_cards.pl"} = 6723;
$perl_ports {"quest.pl"} = 3672;
$perl_ports {"roshambo.pl"} = 14159;
$perl_ports {"secure_copy_paste_w_images.pl"} = 6725;
$perl_ports {"solve_wordle.pl"} = 4590;
$perl_ports {"ALL"} = "all";

my $script;
my $val;
foreach $script (sort (keys (%perl_ports)))
{
    $val = $perl_ports {$script};
    print ("<a href='/cgibin/kill_single_perl.pl?$val'>$script (Port is $val)</a><br>");
}

my $netstat = `netstat -a -n -b -o`;
$netstat =~ s/\n//img;
$netstat =~ s/TCP/\nTCP/img;

while ($netstat =~ s/^(.*?)\n//m)
{
    my $line = $1;
    if ($line =~ m/perl/)
    {
        $output .= $line . "\n";
    }
}
print "<pre>$output</pre>";
# C:\Users\spjones>tasklist  /fi "PID eq 17764"
my $tasks = `tasklist | find /I "perl"`;
$tasks =~ s/^perl.exe\s*/taskkill \/f \/pid /img;
$tasks =~ s/(.*?\d+).*/$1/img;

my $tasks_web = $tasks;
$tasks_web =~ s/\n/<br>\n/img;
print "<br>The task list:<pre>$tasks_web</pre><br>";

while ($tasks =~ s/^(.*)\n//)
{
    my $task = $1;
    #print ("Running.. $task..\n");
    #`$task`;
}
