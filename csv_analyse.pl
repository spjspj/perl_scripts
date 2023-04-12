#!/usr/bin/perl
##
#   File : csv_analyse.pl
#   Date : 12/Apr/2023
#   Author : spjspj
#   Purpose : Analyse CSV data ingested..
##

use strict;
use POSIX;
use LWP::Simple;
use Socket;
use File::Copy;


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
        $header = "HTTP/1.1 301 Moved\nLocation: /csv_analyse/\nLast-Modified: $yyyymmddhhmmss\nConnection: close\nContent-Type: text/html; charset=UTF-8\nContent-Length: " . length ($msg_body) . "\n\n";
    }
    elsif ($redirect =~ m/^noredirect/i)
    {
        $header = "HTTP/1.1 200 OK\nLast-Modified: $yyyymmddhhmmss\nConnection: close\nContent-Type: text/html; charset=UTF-8\nContent-Length: " . length ($msg_body) . "\n\n";
    }

    #my $header = "HTTP/1.1 200 OK\nLast-Modified: $yyyymmddhhmmss\nAccept-Ranges: bytes\nConnection: close\nContent-Type: text/html; charset=UTF-8\nContent-Length: " . length ($msg_body) . "\n\n";
    #my $header = "HTTP/1.1 301 Moved\nLocation: /full0\nLast-Modified: $yyyymmddhhmmss\nAccept-Ranges: bytes\nConnection: close\nContent-Type: text/html; charset=UTF-8\nContent-Length: " . length ($msg_body) . "\n\n";

    $msg_body =~ s/\n\n/\n/mig;
    $msg_body =~ s/\n\n/\n/mig;
    $msg_body =~ s/\n\n/\n/mig;
    $msg_body = $header . $msg_body;
    $msg_body =~ s/\.png/\.npg/;
    $msg_body =~ s/img/mgi/;
    #$msg_body .= chr(13) . chr(10);
    $msg_body .= chr(13) . chr(10) . "0";
    #print ("\n===========\nWrite to socket: $msg_body\n==========\n");
    print ("\n===========\nWrite to socket: ", length($msg_body), " characters!\n==========\n");

    #unless (defined (syswrite ($sock_ref, $msg_body)))
    #{
    #    return 0;
    #}
    #print ("\n&&&$redirect&&&&&&&&&&&&\n", $msg_body, "\nRRRRRRRRRRRRRR\n");
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
    my $isPost = 0;
    my $done_expected_content_len = 0;
    my $expected_content_len = 0;
    my $old_expected_content_len = 0;
    my $seen_content_len = -1;
    my $content = "";

    vec ($rin, fileno ($sock_ref), 1) = 1;

    # Read the message header
    while (((!(ord ($ch) == 13 and ord ($prev_ch) == 10)) && !$isPost) || ($isPost && $seen_content_len < $expected_content_len))
    {
        if (select ($rout=$rin, undef, undef, 200) == 1)
        {
            $prev_ch = $ch;
            if (sysread ($sock_ref, $ch, 1) < 1)
            {
                return "resend";
            }

            $header .= $ch;
            if (!$isPost && $header =~ m/POST/img)
            {
                $isPost = 1;
            }
        }
        
        if ($seen_content_len >= 0)
        {
            $seen_content_len ++;
            $content .= $ch;
        }
        if (ord ($ch) == 13 and ord ($prev_ch) == 10)
        {
            $seen_content_len = 0;
        }

        if ($isPost == 1 && $done_expected_content_len == 0)
        {
            if ($header =~ m/Content.Length: (\d+)/im)
            {
                $expected_content_len = $1; 
                if ($old_expected_content_len < $expected_content_len)
                {
                    $old_expected_content_len = $expected_content_len;
                }
                else
                {
                    $done_expected_content_len = 1;
                }
            }
        }
    }
    return $header;
}

# Read all cards
my %csv_data;
my $max_field_num = 0;
my $max_rows = 0;
my %col_types;

sub process_csv_data
{
    my $block = $_ [0];
    my %new_csv_data;
    %csv_data = %new_csv_data;
    my %new_col_types;
    %col_types = %new_col_types;
    $max_field_num = 0;
    $max_rows = 0;

    my $line_num = 0;
    my $field_num = 0;
    while ($block =~ s/^(.*?)\n//im)
    {
        chomp;
        my $line = $1;
        if ($line =~ m/^$/)
        {
            next;
        }
        $field_num = 0;
        while ($line =~ s/^([^;\t]+?)(;|\t|$)//)
        {
            my $field = $1;
            my $this_field_num = $field_num; 
            if ($field_num =~ m/^\d$/)
            {
                $this_field_num = "0$field_num";
            }
            $csv_data {"$line_num.$this_field_num"} = $field;
            $field_num++;
            if ($max_field_num < $field_num)
            {
                $max_field_num = $field_num;
            }
        }
        $line_num++;
        $max_rows++;
    }
    
    #print ("Process_data Last line:$block\n");
    $field_num = 0;
    while ($block =~ s/^([^;]+?)(;|$)//)
    {
        my $field = $1;
        $csv_data {"$line_num.$field_num"} = $field;
        $field_num++;
        if ($max_field_num < $field_num)
        {
            $max_field_num = $field_num;
        }
    }
    $max_rows++;
    #print ("Process_data Done Last line:$block\n");
}

sub add_price
{
    my $initial_price = $_ [0];
    my $field = $_ [1];

    $field =~ s/[\$,]//img;

    if ($field =~ m/^-(\d+)($|\.\d+)$/)
    {
        my $whole = $1;
        my $decimal = $2;
        $decimal =~ s/\.//;
        $decimal =~ s/^(\d\d)(\d+)/$1.$2/;
        $initial_price += -1 * ($whole*100 + $decimal);
    }
    elsif ($field =~ m/^(\d+)($|\.\d+)$/)
    {
        my $whole = $1;
        my $decimal = $2;
        $decimal =~ s/\.//;
        $decimal =~ s/^(\d\d)(\d+)/$1.$2/;
        $initial_price += $whole*100 + $decimal;
    }
    return $initial_price;
}

sub get_col_type
{
    my $col_num = $_ [0];
    if ($col_num < 10)
    {
        $col_num = "0$col_num";
    }
    return ($col_types {$col_num});
}

sub set_col_type
{
    my $col_num = $_ [0];
    my $col_type = $_ [1];
    $col_types {$col_num} = $col_type;
}

sub get_col_header
{
    my $col_num = $_ [0];
    if ($col_num < 10)
    {
        my $str = "0.0$col_num";
        $str =~ s/00/0/img;
        if (defined ($csv_data {$str}))
        {
            print ("YAY $col_num found for $str\n");
            return ($csv_data {$str});
        }
        return ($csv_data {$str});
    }
    return ($csv_data {"0.$col_num"});
}

sub get_num_of_col_header
{
    my $col_name = $_ [0];
    my $i = 0;
    for ($i = 0; $i < $max_field_num; $i++)
    {
        if (get_col_header ($i) eq $col_name)
        {
            return $i;
        }
    }
    return -1;
}

sub get_field_from_col_header
{
    my $row_num = $_ [0];
    my $col_name = $_ [1];

    my $col = get_num_of_col_header ($col_name);
    if ($col > -1)
    {
        return get_field ($row_num, $col);
    }
    return "";
}

sub get_field
{
    my $row_num = $_ [0];
    my $col_num = $_ [1];
    if ($col_num < 10)
    {
        my $str = "$row_num.0$col_num";
        $str =~ s/00/0/img;
        if (defined ($csv_data {$str}))
        {
            return ($csv_data {$str});
        }
        return ($csv_data {$str});
    }
    return ("");
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
    my $port = 3867;
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

    process_csv_data ("Name;Set;Card Number;Rarity;Casting Cost;Type;Power;Toughness;Text;Set
Bribery;Eighth Edition [8ED];64;Rare;{3}{U}{U};Sorcery; ; ;Search taret opponent's library for a creature card and put that card onto the battlefield under your control. Then that player shuffles their library.;Eighth Edition [8ED]
Harrow;Commander 2014 Edition [C14];199;Common;{2}{G};Instant; ; ;As an additional cost to cast Harrow, sacrifice a land..Search your library for up to two basic land cards and put them onto the battlefield. Then shuffle your library.;Commander 2014 Edition [C14]
Acid-Spewer Dragon;Dragons of Tarkir [DTK];86;Uncommon;{5}{B};Creature - Dragon;3;3;Flying, deathtouch\$Megamorph {5}{B}{B} (You may cast this card face down as a 2/2 creature for {3}. Turn it face up any time for its megamorph cost and put a +1/+1 counter on it.)\$When Acid-Spewer Dragon is turned face up, put a +1/+1 counter on each other Dragon creature you control.;Dragons of Tarkir [DTK]
Acolyte of Bahamut;Commander Legends: Battle for Baldur's Gate;212;Uncommon;{1}{G};Legendary Enchantment - Background; ; ;Commander creatures you own have \"The first Dragon spell you cast each turn costs {2} less to cast.\";Commander Legends: Battle for Baldur's Gate
Adult Gold Dragon;Adventures in the Forgotten Realms;216;Rare;{3}{R}{W};Creature - Dragon;4;3;Flying, lifelink, haste;Adventures in the Forgotten Realms
Advent of the Wurm;Dragon's Maze [DGM];51;Rare;{1}{G}{G}{W};Instant; ; ;Put a 5/5 green Wurm creature token with trample onto the battlefield.;Dragon's Maze [DGM]
Aetherling;Dragon's Maze [DGM];11;Rare;{4}{U}{U};Creature - Shapeshifter;4;5;{U}: Exile Ætherling. Return it to the battlefield under its owner's control at the beginning of the next end step.\${U}: Ætherling is unblockable this turn.\${1}: Ætherling gets +1/-1 until end of turn.\${1}: Ætherling gets -1/+1 until end of turn.;Dragon's Maze [DGM]
Ainok Artillerist;Dragons of Tarkir [DTK];171;Common;{2}{G};Creature - Hound Arch;4;1;Ainok Artillerist has reach as long as it has a +1/+1 counter on it. (It can block creatures with flying.);Dragons of Tarkir [DTK]
Ainok Survivalist;Dragons of Tarkir [DTK];172;Uncommon;{1}{G};Creature - Hound Shaman;2;1;Megamorph {1}{G} (You may cast this card face down for {3}. Turn it face up any time for its megamorph cost and put a +1/+1 counter on it.)\$When Ainok Survivalist is turned face up, destroy target artifact or enchantment an opponent controls.;Dragons of Tarkir [DTK]
Akoum Hellkite;Battle for Zendikar [BFZ];139;Rare;{4}{R}{R};Creature - Dragon;4;4;Flying\$Landfall ? Whenever a land enters the battlefield under your control, Akoum Hellkite deals 1 damage to any target. If that land was a Mountain, Akoum Hellkite deals 2 damage to that creature or player instead.;Battle for Zendikar [BFZ]
Alabaster Dragon;Portal [POR];163;Rare;{4}{W}{W};Creature - Dragon;4;4;Flying\$When Alabaster Dragon dies, shuffle it into its owner's library.;Portal [POR]
Alaborn Cavalier;Duel Decks: Knights vs. Dragons [DDU] [DDG];18;Uncommon;{2}{W}{W};Creature - Human Knight;2;2;Whenever Alaborn Cavalier attacks, you may tap target creature.;Duel Decks: Knights vs. Dragons [DDU] [DDG]
Alive;Dragon's Maze [DGM];121;Uncommon;{3}{G};Sorcery; ; ;Put a 3/3 green Centaur creature token onto the battlefield.\$Fuse (You may cast one or both halves of this card from your hand.);Dragon's Maze [DGM]
Amareth, the Lustrous;Commander Legends;586;Rare;{3}{G}{W}{U};Legendary Creature - Dragon;6;6;Flying\$Whenever another permanent enters the battlefield under your control, look at the top card of your library. If it shares a card type with that permanent, you may reveal that card and put it into your hand.;Commander Legends
Ambitious Dragonborn;Commander Legends: Battle for Baldur's Gate;213;Common;{3}{G};Creature - Dragon Barbarian;0;0;Ambitious Dragonborn enters the battlefield with X +1/+1 counters on it, where X is the greatest power among creatures you control and creature cards in your graveyard.;Commander Legends: Battle for Baldur's Gate
Amethyst Dragon;Commander Legends: Battle for Baldur's Gate;160;Uncommon;{4}{R}{R};Creature - Dragon;4;4;Flying, haste;Commander Legends: Battle for Baldur's Gate
Anafenza, Kin-Tree Spirit;Dragons of Tarkir [DTK];2;Rare;{W}{W};Legendary Creature - Spirit Soldier;2;2;Whenever another nontoken creature enters the battlefield under your control, bolster 1. (Choose a creature with the least toughness among creatures you control and put a +1/+1 counter on it.);Dragons of Tarkir [DTK]
Ancestor Dragon;Global Series: Jiang Yanggu & Mu Yanling;12;Rare;{4}{W}{W};Creature - Dragon;5;6;Flying\$Whenever one or more creatures you control attack, you gain 1 life for each attacking creature.;Global Series: Jiang Yanggu & Mu Yanling
Ancestral Statue;Dragons of Tarkir [DTK];234;Common;{4};Artifact Creature - Golem;3;4;When Ancestral Statue enters the battlefield, return a nonland permanent you control to its owner's hand.;Dragons of Tarkir [DTK]
Ancient Brass Dragon;Commander Legends: Battle for Baldur's Gate;111;Mythic Rare;{5}{B}{B};Creature - Elder Dragon;7;6;Flying\$Whenever Ancient Brass Dragon deals combat damage to a player, roll a d20. When you do, put any number of target creature cards with total mana value X or less from graveyards onto the battlefield under your control, where X is the result.;Commander Legends: Battle for Baldur's Gate
Ancient Bronze Dragon;Commander Legends: Battle for Baldur's Gate;214;Mythic Rare;{5}{G}{G};Creature - Elder Dragon;7;7;Flying\$Whenever Ancient Bronze Dragon deals combat damage to a player, roll a d20. When you do, put X +1/+1 counters on each of up to two target creatures, where X is the result.;Commander Legends: Battle for Baldur's Gate
Ancient Carp;Dragons of Tarkir [DTK];44;Common;{4}{U};Creature - Fish;2;5; ;Dragons of Tarkir [DTK]
Ancient Copper Dragon;Commander Legends: Battle for Baldur's Gate;161;Mythic Rare;{4}{R}{R};Creature - Elder Dragon;6;5;Flying\$Whenever Ancient Copper Dragon deals combat damage to a player, roll a d20. You create a number of Treasure tokens equal to the result.;Commander Legends: Battle for Baldur's Gate
Ancient Gold Dragon;Commander Legends: Battle for Baldur's Gate;3;Mythic Rare;{5}{W}{W};Creature - Elder Dragon;7;10;Flying\$Whenever Ancient Gold Dragon deals combat damage to a player, roll a d20. You create a number of 1/1 blue Faerie Dragon creature tokens with flying equal to the result.;Commander Legends: Battle for Baldur's Gate
Ancient Hellkite;Game Night: Free-for-All;68;Rare;{4}{R}{R}{R};Creature - Dragon;6;6;Flying\${R}: Ancient Hellkite deals 1 damage to target creature defending player controls. Activate only if Ancient Hellkite is attacking.;Game Night: Free-for-All
Ancient Silver Dragon;Commander Legends: Battle for Baldur's Gate;56;Mythic Rare;{6}{U}{U};Creature - Elder Dragon;8;8;Flying\$Whenever Ancient Silver Dragon deals combat damage to a player, roll a d20. Draw cards equal to the result. You have no maximum hand size for the rest of the game.;Commander Legends: Battle for Baldur's Gate
Anticipate;Dragons of Tarkir [DTK];45;Common;{1}{U};Instant; ; ;Look at the top three cards of your library. Put one of them into your hand and the rest on the bottom of your library in any order.;Dragons of Tarkir [DTK]
Ao, the Dawn Sky;Kamigawa: Neon Dynasty;2;Mythic Rare;{3}{W}{W};Legendary Creature - Dragon Spirit;5;4;Flying, vigilance\$When Ao, the Dawn Sky dies, choose one —\$• Look at the top seven cards of your library. Put any number of nonland permanent cards with total mana value 4 or less from among them onto the battlefield. Put the rest on the bottom of your library in a random order.\$• Put two +1/+1 counters on each permanent you control that's a creature or Vehicle.;Kamigawa: Neon Dynasty
Arashin Foremost;Dragons of Tarkir [DTK];3;Rare;{1}{W}{W};Creature - Human Warrior;2;2;Double strike\$Whenever Arashin Foremost enters the battlefield or attacks, another target Warrior creature you control gains double strike until end of turn.;Dragons of Tarkir [DTK]
Arashin Sovereign;Dragons of Tarkir [DTK];212;Rare;{5}{G}{W};Creature - Dragon;6;6;Flying\$When Arashin Sovereign dies, you may put it on the top or bottom of its owner's library.;Dragons of Tarkir [DTK]
Arcades Sabboth;Chronicles [CHR];106;Rare;{2}{G}{G}{W}{W}{U}{U};Legendary Creature - Elder Dragon;7;7;Flying\$At the beginning of your upkeep, sacrifice Arcades Sabboth unless you pay {G}{W}{U}.\$Each untapped creature you control gets +0/+2 as long as it's not attacking.\${W}: Arcades Sabboth gets +0/+1 until end of turn.;Chronicles [CHR]
Arcades, the Strategist;Core Set 2019 [M19];212;Mythic Rare;{1}{G}{W}{U};Legendary Creature - Elder Dragon;3;5;Flying, vigilance\$Whenever a creature with defender enters the battlefield under your control, draw a card.\$Each creature you control with defender assigns combat damage equal to its toughness rather than its power and can attack as though it didn't have defender.;Core Set 2019 [M19]
Arcbound Whelp;Jumpstart: Historic Horizons [JMP];410;Uncommon;{3}{R};Artifact Creature - Dragon;0;0;Flying\${R}: Arcbound Whelp gets +1/+0 until end of turn.\$Modular 2;Jumpstart: Historic Horizons [JMP]
Archwing Dragon;Avacyn Restored [AVR];126;Rare;{2}{R}{R};Creature - Dragon;4;4;Flying, haste\$At the beginning of the end step, return Archwing Dragon to its owner's hand.;Avacyn Restored [AVR]
Armed;Dragon's Maze [DGM];122;Uncommon;{1}{R};Sorcery; ; ;Target creature gets +1/+1 and gains double strike until end of turn.\$Fuse (You may cast one or both halves of this card from your hand.);Dragon's Maze [DGM]
Armillary Sphere;Duel Decks: Knights vs. Dragons [DDU] [DDG];62;Common;{2};Artifact; ; ;{2}, {tap}, Sacrifice Armillary Sphere: Search your library for up to two basic land cards, reveal them, and put them into your hand. Then shuffle your library.;Duel Decks: Knights vs. Dragons [DDU] [DDG]
Armored Wolf-Rider;Dragon's Maze [DGM];52;Common;{3}{G}{W};Creature - Elf Knight;4;6; ;Dragon's Maze [DGM]
Artful Maneuver;Dragons of Tarkir [DTK];4;Common;{1}{W};Instant; ; ;Target creature gets +2/+2 until end of turn.\$Rebound (If you cast this spell from your hand, exile it as it resolves. At the beginning of your next upkeep, you may cast this card from exile without paying its mana cost.);Dragons of Tarkir [DTK]
Artificer's Dragon;The Brothers' War;291;Rare;{6};Artifact Creature - Dragon;4;4;Flying\${R}: Artifact creatures you control get +1/+0 until end of turn.\$Unearth {3}{R}{R};The Brothers' War
Ascended Lawmage;Dragon's Maze [DGM];53;Uncommon;{2}{W}{U};Creature - Vedalken Wizard;3;2;Flying, hexproof;Dragon's Maze [DGM]
Ashmouth Dragon;Innistrad: Midnight Hunt [ISD];159;Rare; ;Creature - Dragon;4;4;Flying\$Whenever you cast an instant or sorcery spell, Ashmouth Dragon deals 2 damage to any target.;Innistrad: Midnight Hunt [ISD]
Assault Formation;Dragons of Tarkir [DTK];173;Rare;{1}{G};Enchantment; ; ;Each creature you control assigns combat damage equal to its toughness rather than its power.\${G}: Target creature with defender can attack this turn as though it didn't have defender.\${2}{G}: Creatures you control get +0/+1 until end of turn.;Dragons of Tarkir [DTK]
Astral Dragon;Commander Legends: Battle for Baldur's Gate;664;Rare;{6}{U}{U};Creature - Dragon;4;4;Flying\$Project Image — When Astral Dragon enters the battlefield, create two tokens that are copies of target noncreature permanent, except they're 3/3 Dragon creatures in addition to their other types, and they have flying.;Commander Legends: Battle for Baldur's Gate
Atarka Beastbreaker;Dragons of Tarkir [DTK];174;Common;{1}{G};Creature - Human Warrior;2;2;Formidable — {4}{G}: Atarka Beastbreaker gets +4/+4 until end of turn. Activate this only if creatures you control have total power 8 or greater.;Dragons of Tarkir [DTK]
Atarka Efreet;Dragons of Tarkir [DTK];128;Common;{3}{R};Creature - Efreet Shaman;5;1;Megamorph {2}{R} (You may cast this card face down as a 2/2 creature for {3}. Turn it face up any time for its megamorph cost and put a +1/+1 counter on it.)\$When Atarka Efreet is turned face up, it deals 1 damage to any target.;Dragons of Tarkir [DTK]
Atarka Monument;Dragons of Tarkir [DTK];235;Uncommon;{3};Artifact; ; ;{T}: Add {R} or {G}.\${4}{R}{G}: Atarka Monument becomes a 4/4 red and green Dragon artifact creature with flying until end of turn.;Dragons of Tarkir [DTK]
Atarka Pummeler;Dragons of Tarkir [DTK];129;Uncommon;{4}{R};Creature - Ogre Warrior;4;5;Formidable — {3}{R}{R}: Each creature you control can't be blocked this turn except by two or more creatures. Activate this ability only if creature you control have total power 8 or greater,;Dragons of Tarkir [DTK]
Atarka, World Render;Commander 2017 Edition [C17];161;Rare;{5}{R}{G};Legendary Creature - Dragon;6;4;Flying, trample\$Whenever a Dragon you control attacks, it gains double strike until end of turn.;Commander 2017 Edition [C17]
");

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
        print ("Raw data was $txt\n");
        $txt =~ s/csv_data\/csv_data/csv_data\//img;
        $txt =~ s/csv_data\/csv_data/csv_data\//img;
        $txt =~ s/csv_data\/csv_data/csv_data\//img;

        if ($txt =~ m/.*favico.*/m)
        {
            my $size = -s ("d:/perl_programs/aaa.jpg");
            print (">>>>> size = $size\n");
            my $h = "HTTP/1.1 200 OK\nLast-Modified: 20150202020202\nConnection: close\nContent-Type: image/jpeg\nContent-Length: $size\n\n";
            print "===============\n", $h, "\n^^^^^^^^^^^^^^^^^^^\n";
            syswrite (\*CLIENT, $h);
            copy "d:/perl_programs/aaa.jpg", \*CLIENT;
            next;
        }
        
        if ($txt =~ m/GET.*update_csv.*/m)
        {
            $txt =~ m/(........update_csv.......)/im;
            my $matching_text = $1;
            #my $html_text = "<html> <head> <META HTTP-EQUIV=\"CACHE-CONTROL\" CONTENT=\"NO-CACHE\"> <br> <META HTTP-EQUIV=\"EXPIRES\" CONTENT=\"Mon, 22 Jul 2094 11:12:01 GMT\"> </head> <body> <h1>Refresh CSV </h1> <br> <form action=\"updated_csv\" id=\"update_csv\" method=\"post\">  New CSV Text: <input type=\"submit\"> <textarea id=\"new_csv_id\" rows=\"30\" cols=\"70\" name=\"new_csv\" form=\"update_csv\"> </textarea> </form> GOT HERE in update_csv ($txt) (<font color=red>$matching_text</font>)</body> </html>";

#<form action=\"updated_csv\" id=\"update_csv\" method=\"post\"> New CSV Text: <input type=\"submit\"> <textarea id=\"new_csv_id\" rows=\"30\" cols=\"70\" name=\"new_csv\" form=\"update_csv\"> </textarea> </form> GOT HERE in update_csv ($txt) (<font color=red>$matching_text</font>)
            my $html_text = "<html> <head> <META HTTP-EQUIV=\"CACHE-CONTROL\" CONTENT=\"NO-CACHE\"> <br> <META HTTP-EQUIV=\"EXPIRES\" CONTENT=\"Mon, 22 Jul 2094 11:12:01 GMT\"> </head> <body> <h1>Refresh CSV </h1> <br> 
<form action=\"updated_csv\" id=\"newcsv\" name=\"newcsv\" method=\"post\">
<textarea id=\"newcsv\" class=\"text\" cols=\"86\" rows =\"20\" form=\"newcsv\" name=\"newcsv\"></textarea>
<input type=\"submit\" value=\"New CSV\" class=\"submitButton\">
</form>
</body> </html>";
            write_to_socket (\*CLIENT, $html_text, "", "noredirect");
            next;
        }
        
        print ("2- - - - - - -\n");
        my $have_to_write_to_socket = 1;

        chomp ($txt);
        my $original_get = $txt;

        $txt =~ s/.*filter\?//;
        $txt =~ s/.*stats\?//;
        $txt =~ s/ http.*//i;
        $txt =~ s/%21/!/g;
        $txt =~ s/%22/"/g;
        $txt =~ s/%23/#/g;
        $txt =~ s/%24/\$/g;
        $txt =~ s/%25/%/g;
        $txt =~ s/%26/&/g;
        $txt =~ s/%27/'/g;
        $txt =~ s/%28/(/g;
        $txt =~ s/%29/)/g;
        $txt =~ s/%2A/*/g;
        $txt =~ s/%2B/+/g;
        $txt =~ s/%2C/,/g;
        $txt =~ s/%2D/-/g;
        $txt =~ s/%2E/./g;
        $txt =~ s/%2F/\//g;
        $txt =~ s/%3A/:/g;
        $txt =~ s/%3B/;/g;
        $txt =~ s/%3C/</g;
        $txt =~ s/%3D/=/g;
        $txt =~ s/%3E/>/g;
        $txt =~ s/%3F/?/g;
        $txt =~ s/%40/@/g;
        $txt =~ s/%5B/[/g;
        $txt =~ s/%5C/\\/g;
        $txt =~ s/%5D/]/g;
        $txt =~ s/%5E/\^/g;
        $txt =~ s/%5F/_/g;
        $txt =~ s/%60/`/g;
        $txt =~ s/%7B/{/g;
        $txt =~ s/%7C/|/g;
        $txt =~ s/%7D/}/g;
        $txt =~ s/%7E/~/g;
        $txt =~ s/%09/;/g;

        if ($txt =~ m/POST.*updated_csv.*/i)
        {
            my $csv_data = $txt;
            my $new_csv_data = "";
            my $discard_header = 1;

            while ($csv_data =~ s/^(.*?)(\n|$)//im && $discard_header >= 0)
            {
                my $line = $1;
                if ($line =~ m/^$/ || $line =~ m/^
$/)
                {
                    $discard_header --;
                }

                if (!$discard_header)
                {
                    $new_csv_data .= "$line\n";
                }
            }

            $new_csv_data =~ s/^
$//img;
            $new_csv_data =~ s/^\n$//img;
            $new_csv_data =~ s/^\n$//img;
            $new_csv_data =~ s/^.*newcsv=//img;
            $new_csv_data =~ s/\+/ /img;
            $new_csv_data =~ s/%0D%0A/\n/img;
            $new_csv_data =~ s/..$//im;
            process_csv_data ($new_csv_data); 
        }

        my $search = ".*";
        if ($txt =~ m/searchstr=(.*)/im)
        {
            $search = "$1";
        }
        
        my $group = ".*";
        if ($txt =~ m/groupstr=(.*)/im)
        {
            $group = "$1";
        }
        
        my $multi_group = ".*";
        if ($txt =~ m/multigroup=(.*)/im)
        {
            $multi_group = "$1";
        }

        my @strs = split /&/, $txt;
        #print join (',,,', @strs);

        # Sortable table with cards in it..
        my $html_text = "<!DOCTYPE html>\n";
        $html_text .= "<html lang='en' class=''>\n";
        $html_text .= "<head>\n";
        $html_text .= "  <meta charset='UTF-8'>\n";
        $html_text .= "  <title>Analyse CSV</title>\n";
        $html_text .= "  <meta name=\"robots\" content=\"noindex\">\n";
        $html_text .= "  <link rel=\"icon\" href=\"favicon.ico\">\n";
        $html_text .= "  <style id=\"INLINE_PEN_STYLESHEET_ID\">\n";
        $html_text .= "    .sr-only {\n";
        $html_text .= "  position: absolute;\n";
        $html_text .= "  top: -30em;\n";
        $html_text .= "}\n";
        $html_text .= "table.sortable td,\n";
        $html_text .= "table.sortable th {\n";
        $html_text .= "  padding: 0.125em 0.25em;\n";
        $html_text .= "  width: 8em;\n";
        $html_text .= "}\n";
        $html_text .= "table.sortable th {\n";
        $html_text .= "  font-weight: bold;\n";
        $html_text .= "  border-bottom: thin solid #888;\n";
        $html_text .= "  position: relative;\n";
        $html_text .= "}\n";
        $html_text .= "table.sortable th.no-sort {\n";
        $html_text .= "  padding-top: 0.35em;\n";
        $html_text .= "}\n";
        $html_text .= "table.sortable th:nth-child(5) {\n";
        $html_text .= "  width: 10em;\n";
        $html_text .= "}\n";
        $html_text .= "table.sortable th button {\n";
        $html_text .= "  position: absolute;\n";
        $html_text .= "  padding: 4px;\n";
        $html_text .= "  margin: 1px;\n";
        $html_text .= "  font-size: 100%;\n";
        $html_text .= "  font-weight: bold;\n";
        $html_text .= "  background: transparent;\n";
        $html_text .= "  border: none;\n";
        $html_text .= "  display: inline;\n";
        $html_text .= "  right: 0;\n";
        $html_text .= "  left: 0;\n";
        $html_text .= "  top: 0;\n";
        $html_text .= "  bottom: 0;\n";
        $html_text .= "  width: 100%;\n";
        $html_text .= "  text-align: left;\n";
        $html_text .= "  outline: none;\n";
        $html_text .= "  cursor: pointer;\n";
        $html_text .= "}\n";
        $html_text .= "table.sortable th button span {\n";
        $html_text .= "  position: absolute;\n";
        $html_text .= "  right: 4px;\n";
        $html_text .= "}\n";
        $html_text .= "table.sortable th[aria-sort=\"descending\"] span::after {\n";
        $html_text .= "  content: ' \\25BC';\n";
        $html_text .= "  color: currentcolor;\n";
        $html_text .= "  font-size: 100%;\n";
        $html_text .= "  top: 0;\n";
        $html_text .= "}\n";
        $html_text .= "table.sortable th[aria-sort=\"ascending\"] span::after {\n";
        $html_text .= "  content: ' \\25B2';\n";
        $html_text .= "  color: currentcolor;\n";
        $html_text .= "  font-size: 100%;\n";
        $html_text .= "  top: 0;\n";
        $html_text .= "}\n";
        $html_text .= "table.show-unsorted-icon th:not([aria-sort]) button span::after {\n";
        $html_text .= "  content: ' \\2662';\n";
        $html_text .= "  color: currentcolor;\n";
        $html_text .= "  font-size: 100%;\n";
        $html_text .= "  position: relative;\n";
        $html_text .= "  top: -3px;\n";
        $html_text .= "  left: -4px;\n";
        $html_text .= "}\n";
        $html_text .= "table.sortable td.num {\n";
        $html_text .= "  text-align: right;\n";
        $html_text .= "}\n";
        $html_text .= "table.sortable td.price {\n";
        $html_text .= "  text-align: right;\n";
        $html_text .= "}\n";
        $html_text .= "table.sortable tbody tr:nth-child(odd) {\n";
        $html_text .= "  background-color: #ddd;\n";
        $html_text .= "}\n";
        $html_text .= "table.sortable th button:focus,\n";
        $html_text .= "table.sortable th button:hover {\n";
        $html_text .= "  padding: 2px;\n";
        $html_text .= "  border: 2px solid currentcolor;\n";
        $html_text .= "  background-color: #e5f4ff;\n";
        $html_text .= "}\n";
        $html_text .= "table.sortable th button:focus span,\n";
        $html_text .= "table.sortable th button:hover span {\n";
        $html_text .= "  right: 2px;\n";
        $html_text .= "}\n";
        $html_text .= "table.sortable th:not([aria-sort]) button:focus span::after,\n";
        $html_text .= "table.sortable th:not([aria-sort]) button:hover span::after {\n";
        $html_text .= "  content: ' \\2662';\n";
        $html_text .= "  color: currentcolor;\n";
        $html_text .= "  font-size: 100%;\n";
        $html_text .= "  top: 0;\n";
        $html_text .= "}\n";
        $html_text .= "</style>\n";
        $html_text .= "</head>\n";
        $html_text .= "<body>\n";
        $html_text .= "<script>\n";
        $html_text .= "var xyz = 'bbb';";
        $html_text .= "xyz = xyz.replace (/b/, 'x');";
        $html_text .= "</script>\n";
        $html_text .= "<table width=100%><tr><td>\n";
        
        $html_text .= "<form action=\"/csv_analyse/search\">
                <label for=\"searchstr\">Search:</label><br>
                <input type=\"text\" id=\"searchstr\" name=\"searchstr\" value=\"$search\">
                <input type=\"submit\" value=\"Search\">
                </form></td><td>";

        $html_text .= "<form action=\"/csv_analyse/groupby\">
                <label for=\"groupstr\">Group by <font size=-2>(first group only, eg (..Scott..)#credit):</font></label><br>
                <input type=\"text\" id=\"groupstr\" name=\"groupstr\" value=\"$group\">
                <input type=\"submit\" value=\"Group By\">
                </form></td><td>";
                
        $html_text .= "<form action=\"/csv_analyse/multigroupby\">
                <label for=\"multigroup\">Multi group <font size=-2>(row must match, 2 groups):</font></label><br>
                <input type=\"text\" id=\"multigroup\" name=\"multigroup\" value=\"$multi_group\">
                <input type=\"submit\" value=\"Multi Group By\">
                </form></td>";
                
        $html_text .= "<td><form action=\"/csv_analyse/update_csv\">
                <label>Update CSV:</label><br>
                <input type=\"submit\" value=\"Update CSV\">
                </form></td></tr></table>";

        my %groups;
        my $group_cols = 0;
        my %group_colours;
        $group_colours {0} = "burntorange";
        $group_colours {1} = "blue";
        $group_colours {2} = "green";
        $group_colours {3} = "darkred";
        $group_colours {4} = "silver";
        $group_colours {5} = "purple";
        $group_colours {6} = "darkyellow";
        $group_colours {7} = "red";

        $html_text .= "<script>\n";
        $html_text .= "'use strict';\n";
        $html_text .= "class SortableTable { constructor(tableNode) { this.tableNode = tableNode; this.columnHeaders = tableNode.querySelectorAll('thead th'); this.sortColumns = []; for (var i = 0; i < this.columnHeaders.length; i++) { var ch = this.columnHeaders[i]; var buttonNode = ch.querySelector('button'); if (buttonNode) { this.sortColumns.push(i); buttonNode.setAttribute('data-column-index', i); buttonNode.addEventListener('click', this.handleClick.bind(this)); } } this.optionCheckbox = document.querySelector( 'input[type=\"checkbox\"][value=\"show-unsorted-icon\"]'); if (this.optionCheckbox) { this.optionCheckbox.addEventListener( 'change', this.handleOptionChange.bind(this)); if (this.optionCheckbox.checked) { this.tableNode.classList.add('show-unsorted-icon'); } } } setColumnHeaderSort(columnIndex) { if (typeof columnIndex === 'string') { columnIndex = parseInt(columnIndex); } for (var i = 0; i < this.columnHeaders.length; i++) { var ch = this.columnHeaders[i]; var buttonNode = ch.querySelector('button'); if (i === columnIndex) { var value = ch.getAttribute('aria-sort'); if (value === 'descending') { ch.setAttribute('aria-sort', 'ascending'); this.sortColumn( columnIndex, 'ascending', ch.classList.contains('td.num'), ch.classList.contains('td.price')); } else { ch.setAttribute('aria-sort', 'descending'); this.sortColumn( columnIndex, 'descending', ch.classList.contains('td.num'), ch.classList.contains('td.price')); } } else { if (ch.hasAttribute('aria-sort') && buttonNode) { ch.removeAttribute('aria-sort'); } } } } sortColumn(columnIndex, sortValue, isNumber, isPrice) { function compareValues(a, b) { if (sortValue === 'ascending') { if (a.value === b.value) { return 0; } else { if (isNumber) { return a.value - b.value; } else if (isPrice) { var aval = a.value; aval = aval.replace (/\\W/g, ''); var bval = b.value; bval = bval.replace (/\\W/g, '');  return aval - bval < 0 ? -1 : 1; } else { return a.value < b.value ? -1 : 1; } } } else { if (a.value === b.value) { return 0; } else { if (isNumber) { return b.value - a.value; } else if (isPrice) { var aval = a.value; aval = aval.replace (/\\W/g, ''); var bval = b.value; bval = bval.replace (/\\W/g, '');  return aval - bval < 0 ? 1 : -1; } else { return a.value > b.value ? -1 : 1; } } } } if (typeof isNumber !== 'boolean') { isNumber = false; } var tbodyNode = this.tableNode.querySelector('tbody'); var rowNodes = []; var dataCells = []; var rowNode = tbodyNode.firstElementChild; var index = 0; while (rowNode) { rowNodes.push(rowNode); var rowCells = rowNode.querySelectorAll('th, td'); var dataCell = rowCells[columnIndex]; var data = {}; data.index = index; data.value = dataCell.textContent.toLowerCase().trim(); if (isNumber) { data.value = parseFloat(data.value); } dataCells.push(data); rowNode = rowNode.nextElementSibling; index += 1; } dataCells.sort(compareValues); while (tbodyNode.firstChild) { tbodyNode.removeChild(tbodyNode.lastChild); } for (var i = 0; i < dataCells.length; i += 1) { tbodyNode.appendChild(rowNodes[dataCells[i].index]); } }  handleClick(event) { var tgt = event.currentTarget; this.setColumnHeaderSort(tgt.getAttribute('data-column-index')); } handleOptionChange(event) { var tgt = event.currentTarget; if (tgt.checked) { this.tableNode.classList.add('show-unsorted-icon'); } else { this.tableNode.classList.remove('show-unsorted-icon'); } } }\n";
        $html_text .= "window.addEventListener('load', function () { var sortableTables = document.querySelectorAll('table.sortable'); for (var i = 0; i < sortableTables.length; i++) { new SortableTable(sortableTables[i]); } });\n";
        $html_text .= "</script>\n";
        $html_text .= "<div class=\"table-wrap\"><table class=\"sortable\">\n";
                
        $html_text .= "<thead>\n";
        $html_text .= "<br>Found YYY rows<br>";
        $html_text .= "<br>QQQ<br>";
        
        $html_text .= "<tr>\n";

        my $x;
        for ($x = 0; $x < $max_field_num; $x++)
        {
            $html_text .= "<th XYZ$x> <button><font size=-1>" . get_col_header ($x) . "<span aria-hidden=\"true\"></span> </font></button> </th> \n";
        }
        $html_text .= "<th> <button><font size=-1>Group<span aria-hidden=\"true\"></span> </font></button> </th> \n";
        $html_text .= "<th class=\"no-sort\">*</th>";
        $html_text .= "</tr>\n";
        $html_text .= "</thead>\n";
        $html_text .= "<tbody><font size=-2>\n";

        my $checked = "";

        my $card;
        my $even_odd = "even";
        my $deck;
        my $overall_count = 0;
        my %group_prices;
        my %group_counts;
                
        my $only_one_group = 1;
        my $first_group_only = 0;
        my $many_groups = 0;

        my $group2 = "";
        my $chosen_col = "";
        if ($group =~ s/#(.*)//)
        {
            $chosen_col = "$1";
            print ("WOOT $chosen_col\n");
        }
        my $overall_match = $group;
        if ($group =~ m/\((.*)\).*\((.*)\)/)
        {
            $only_one_group = 0;
            $first_group_only = 1;
            $many_groups = 0;
            $group = "$1";
            $group2 = "$2";
        }
        
        if ($multi_group =~ m/\((.*)\).*\((.*)\)/)
        {
            $only_one_group = 0;
            $first_group_only = 0;
            $many_groups = 1;
            $group = "$1";
            $group2 = "$2";
            $overall_match = $multi_group;
        }

        my $row_num = 0;
        my $col_num = 0;
        my $old_row_num = 0;
        my $old_col_num = 0;
        my $field_id = 0;
        my $row = "<tr class=\"$even_odd\">";
        my $fake_row;

        my %col_calculations;
        my $pot_group_price = "";

        foreach $field_id (sort {$a <=> $b} keys (%csv_data))
        {
            if ($field_id =~ m/(\d+)\.(\d+)/)
            {
                $row_num = "$1";
                if ($row_num eq "0") { $old_row_num = 1; next; }
                $col_num = "$2";
                my $field = $csv_data {$field_id};
                #print ("        rrrrrr Handling - $field_id ($field)\n");

                if (!defined ($col_types {$col_num}))
                {
                    if ($field =~ m/^\s*$/)
                    {
                        
                    }
                    elsif ($field =~ m/^\d\d\d\d\d\d\d\d$/ || $field =~ m/^\d\d\d\d[\/]\d\d[\/]\d\d$/ || $field =~ m/^\d\d\d\d[\/]\d\d[\/]\d$/ || $field =~ m/^\d\d\d\d[\/]\d[\/]\d\d$/ || $field =~ m/^\d\d\d\d[\/]\d[\/]\d$/ || $field =~ m/^\d\d[\/]\d\d[\/]\d\d$/ || $field =~ m/^\d\d[\/]\d\d[\/]\d$/ || $field =~ m/^\d\d[\/]\d[\/]\d\d$/ || $field =~ m/^\d\d[\/]\d[\/]\d$/ || $field =~ m/^\d\d[\/]\d\d[\/]\d\d$/ || $field =~ m/^\d[\/]\d\d[\/]\d\d$/ || $field =~ m/^\d\d[\/]\d[\/]\d\d$/ || $field =~ m/^\d[\/]\d[\/]\d\d$/ || $field =~ m/^\d\d[\/]\d\d[\/]\d\d\d\d$/ || $field =~ m/^\d[\/]\d\d[\/]\d\d\d\d$/ || $field =~ m/^\d\d[\/]\d[\/]\d\d\d\d$/ || $field =~ m/^\d[\/]\d[\/]\d\d\d\d$/)
                    {
                        set_col_type ($col_num, "DATE");
                        if ($field =~ m/^\d\d\d\d[\/]\d\d[\/]\d\d$/)
                        {
                            $field =~ m/^(\d\d\d\d)[\/](\d\d)[\/](\d\d)$/;
                            print ("$field_id for $field -- ");
                            $csv_data {$field_id} = "$1" . "$2" . "0$3";
                            print ("now is $csv_data{$field_id}\n");
                        }
                        elsif ($field =~ m/^\d\d\d\d[\/]\d\d[\/]\d$/)
                        {
                            $field =~ m/^(\d\d\d\d)[\/](\d\d)[\/](\d)$/;
                            print ("$field_id for $field -- ");
                            $csv_data {$field_id} = "$1" . "$2" . "0$3";
                            print ("now is $csv_data{$field_id}\n");
                        }
                        elsif ($field =~ m/^\d\d\d\d[\/]\d[\/]\d\d$/)
                        {
                            $field =~ m/^(\d\d\d\d)[\/](\d)[\/](\d\d)$/;
                            print ("$field_id for $field -- ");
                            $csv_data {$field_id} = "$1" . "0$2" . "$3";
                            print ("now is $csv_data{$field_id}\n");
                        }
                        elsif ($field =~ m/^\d\d[\/]\d\d[\/]\d\d\d\d$/)
                        {
                            $field =~ m/^(\d\d)[\/](\d\d)[\/](\d\d\d\d)$/;
                            print ("$field_id for $field -- ");
                            $csv_data {$field_id} = "$3" . "$2" . "$1";
                            print ("now is $csv_data{$field_id}\n");
                        }
                        elsif ($field =~ m/^\d[\/]\d\d[\/]\d\d\d\d$/)
                        {
                            $field =~ m/^(\d)[\/](\d\d)[\/](\d\d\d\d)$/;
                            print ("$field_id for $field -- ");
                            $csv_data {$field_id} = "$3" . "$2" . "0$1";
                            print ("now is $csv_data{$field_id}\n");
                        }
                        elsif ($field =~ m/^\d\d[\/]\d[\/]\d\d\d\d$/)
                        {
                            $field =~ m/^(\d\d)[\/](\d)[\/](\d\d\d\d)$/;
                            print ("$field_id for $field -- ");
                            $csv_data {$field_id} = "$3" . "0$2" . "$1";
                            print ("now is $csv_data{$field_id}\n");
                        }
                        elsif ($field =~ m/^\d[\/]\d[\/]\d\d\d\d$/)
                        {
                            $field =~ m/^(\d)[\/](\d)[\/](\d\d\d\d)$/;
                            print ("$field_id for $field -- ");
                            $csv_data {$field_id} = "$3" . "0$2" . "0$1";
                            print ("now is $csv_data{$field_id}\n");
                        }
                    }
                    elsif ($field =~ m/^\d+($|\.\d+)$/ || $field =~ m/^-\d+($|\.\d+)$/)
                    {
                        set_col_type ($col_num, "NUMBER");
                        $col_calculations {$col_num} = $field;
                        print ("$col_num is now number 'cos >>$field<<\n");
                    }
                    elsif ($field =~ m/^(-|)\$(\d*[\d,])+($|\.\d+)$/)
                    {
                        set_col_type ($col_num, "PRICE");
                        $col_calculations {$col_num} = add_price ($col_calculations {$col_num}, $field);
                        print ("$col_num is now price 'cos >>$field<<\n");
                    }
                    else
                    {
                        print ("$col_num is now general 'cos >>$field<<\n");
                        set_col_type ($col_num, "GENERAL");
                    }
                }
                elsif ($col_types {$col_num} ne "GENERAL")
                {
                    if ($field =~ m/^\s*$/)
                    {
                        
                    }
                    elsif ($field =~ m/^\d\d\d\d\d\d\d\d$/ || $field =~ m/^\d\d\d\d[\/]\d\d[\/]\d\d$/ || $field =~ m/^\d\d\d\d[\/]\d\d[\/]\d$/ || $field =~ m/^\d\d\d\d[\/]\d[\/]\d\d$/ || $field =~ m/^\d\d\d\d[\/]\d[\/]\d$/ || $field =~ m/^\d\d[\/]\d\d[\/]\d\d$/ || $field =~ m/^\d\d[\/]\d\d[\/]\d$/ || $field =~ m/^\d\d[\/]\d[\/]\d\d$/ || $field =~ m/^\d\d[\/]\d[\/]\d$/ || $field =~ m/^\d\d[\/]\d\d[\/]\d\d$/ || $field =~ m/^\d[\/]\d\d[\/]\d\d$/ || $field =~ m/^\d\d[\/]\d[\/]\d\d$/ || $field =~ m/^\d[\/]\d[\/]\d\d$/ || $field =~ m/^\d\d[\/]\d\d[\/]\d\d\d\d$/ || $field =~ m/^\d[\/]\d\d[\/]\d\d\d\d$/ || $field =~ m/^\d\d[\/]\d[\/]\d\d\d\d$/ || $field =~ m/^\d[\/]\d[\/]\d\d\d\d$/)
                    {
                        if ($col_types {$col_num} ne "DATE")
                        {
                            print ("$col_num is now general (was date) 'cos >>$field<<\n");
                            set_col_type ($col_num, "GENERAL");
                        }
                        else
                        {
                            if ($field =~ m/^\d\d\d\d[\/]\d\d[\/]\d\d$/)
                            {
                                $field =~ m/^(\d\d\d\d)[\/](\d\d)[\/](\d\d)$/;
                                print ("$field_id for $field -- ");
                                $csv_data {$field_id} = "$1" . "$2" . "0$3";
                                print ("now is $csv_data{$field_id}\n");
                            }
                            elsif ($field =~ m/^\d\d\d\d[\/]\d\d[\/]\d$/)
                            {
                                $field =~ m/^(\d\d\d\d)[\/](\d\d)[\/](\d)$/;
                                print ("$field_id for $field -- ");
                                $csv_data {$field_id} = "$1" . "$2" . "0$3";
                                print ("now is $csv_data{$field_id}\n");
                            }
                            elsif ($field =~ m/^\d\d\d\d[\/]\d[\/]\d\d$/)
                            {
                                $field =~ m/^(\d\d\d\d)[\/](\d)[\/](\d\d)$/;
                                print ("$field_id for $field -- ");
                                $csv_data {$field_id} = "$1" . "0$2" . "$3";
                                print ("now is $csv_data{$field_id}\n");
                            }
                            elsif ($field =~ m/^\d\d[\/]\d\d[\/]\d\d\d\d$/)
                            {
                                $field =~ m/^(\d\d)[\/](\d\d)[\/](\d\d\d\d)$/;
                                print ("$field_id for $field -- ");
                                $csv_data {$field_id} = "$3" . "$2" . "$1";
                                print ("now is $csv_data{$field_id}\n");
                            }
                            elsif ($field =~ m/^\d[\/]\d\d[\/]\d\d\d\d$/)
                            {
                                $field =~ m/^(\d)[\/](\d\d)[\/](\d\d\d\d)$/;
                                print ("$field_id for $field -- ");
                                $csv_data {$field_id} = "$3" . "$2" . "0$1";
                                print ("now is $csv_data{$field_id}\n");
                            }
                            elsif ($field =~ m/^\d\d[\/]\d[\/]\d\d\d\d$/)
                            {
                                $field =~ m/^(\d\d)[\/](\d)[\/](\d\d\d\d)$/;
                                print ("$field_id for $field -- ");
                                $csv_data {$field_id} = "$3" . "0$2" . "$1";
                                print ("now is $csv_data{$field_id}\n");
                            }
                            elsif ($field =~ m/^\d[\/]\d[\/]\d\d\d\d$/)
                            {
                                $field =~ m/^(\d)[\/](\d)[\/](\d\d\d\d)$/;
                                print ("$field_id for $field -- ");
                                $csv_data {$field_id} = "$3" . "0$2" . "0$1";
                                print ("now is $csv_data{$field_id}\n");
                            }
                        }
                    }
                    elsif ($field =~ m/^\d+($|\.\d+)$/ || $field =~ m/^-\d+($|\.\d+)$/)
                    {
                        if ($col_types {$col_num} ne "NUMBER")
                        {
                            print ("$col_num is now general (was number) 'cos >>$field<<\n");
                            set_col_type ($col_num, "GENERAL");
                        }
                        else
                        {
                            $col_calculations {$col_num} += $field;
                        }
                    }
                    elsif ($field =~ m/^(-|)\$(\d*[\d,])+($|\.\d+)$/)
                    {
                        if ($col_types {$col_num} ne "PRICE")
                        {
                            print ("$col_num is now general (was price) 'cos >>$field<<\n");
                            set_col_type ($col_num, "GENERAL");
                        }
                        else
                        {
                            $col_calculations {$col_num} = add_price ($col_calculations {$col_num}, $field);
                        }
                    }
                    else
                    {
                        print ("$col_num is now general 'cos >>$field<<\n");
                        set_col_type ($col_num, "GENERAL");
                    }
                }

                # STILL NEED?? TODO
                #if ($col_types {$col_num} eq "PRICE")
                #{
                #    if (lc($chosen_col) eq lc (get_col_header ($col_num)))
                #    {
                #        $pot_group_price = $field;
                #    }
                #}

                $field = $csv_data {$field_id};
                if ($row_num > $old_row_num)
                {
                    # Add row to table if matched 
                    $fake_row = $row;
                    $fake_row =~ s/<[^>]*>//img;
                    my $force_row = 0;
                    if ($many_groups)
                    {
                        $force_row = -1;
                    }
                    
                    if ($fake_row =~ m/$overall_match/im && $overall_match ne ".*" && $overall_match ne "") 
                    {
                        $force_row = 1;
                        if ($only_one_group == 1 && $fake_row =~ m/($group)/im) 
                        {
                            my $this_group = $1;
                            $row .= " <td>$this_group</td> </tr>\n";

                            if (!defined ($group_colours {$this_group}))
                            {
                                $group_colours {$this_group} = $group_colours {$group_cols};
                                $group_cols++;
                            }
                            $row =~ s/<td>/<td><font color=$group_colours{$this_group}>/img;
                            $row =~ s/<\/td>/<\/font><\/td>/img;
                            $group_counts {$this_group}++;

                            $pot_group_price = get_field ($row_num, get_num_of_col_header ($chosen_col));
                            $group_prices {$this_group} = add_price ($group_prices {$this_group}, $pot_group_price);
                            $group_prices {$this_group . "_calc"} .= "+$pot_group_price";
                        }
                        elsif ($first_group_only && $fake_row =~ m/$overall_match/im && ($fake_row =~ m/($group)/mg))
                        {
                            my $this_group = $1;
                            if ($fake_row =~ m/($group2)/mg)
                            {
                                $group_counts {$this_group}++;
                                $pot_group_price = get_field ($row_num, get_num_of_col_header ($chosen_col));
                                $group_prices {$this_group} = add_price ($group_prices {$this_group}, $pot_group_price);
                                $group_prices {$this_group . "_calc"} .= "+$pot_group_price";
                                $row .= " <td>$this_group</td> </tr>\n";
                                
                                if (!defined ($group_colours {$this_group}))
                                {
                                    $group_colours {$group_cols} = $this_group;
                                    $group_colours {$this_group} = $group_colours {$group_cols};
                                    $group_cols++;
                                }
                                $row =~ s/<td>/<td><font color=$group_colours{$this_group}>/img;
                                $row =~ s/<\/td>/<\/font><\/td>/img;
                            }
                            else
                            {
                                $row .= "<td><font size=-3>No group</font></td></tr>\n";
                            }
                        }
                        elsif ($many_groups && $fake_row =~ m/($group)/im)
                        {
                            my $this_group = $1;
                            if ($fake_row =~ m/($group2)/im)
                            {
                                $this_group .= " " . $1;
                                $group_counts {$this_group}++;
                                $pot_group_price = get_field ($row_num, get_num_of_col_header ($chosen_col));
                                $group_prices {$this_group} = add_price ($group_prices {$this_group}, $pot_group_price);
                                $group_prices {$this_group . "_calc"} .= "+$pot_group_price";
                                $row .= " <td>$this_group</td> </tr>\n";
                                if (!defined ($group_colours {$this_group}))
                                {
                                    $group_colours {$group_cols} = $this_group;
                                    $group_colours {$this_group} = $group_colours {$group_cols};
                                    $group_cols++;
                                }
                                $row =~ s/<td>/<td><font color=$group_colours{$this_group}>/img;
                                $row =~ s/<\/td>/<\/font><\/td>/img;
                            }
                            else
                            {
                                $row .= "<td><font size=-3>No group</font></td></tr>\n";
                            }
                        }
                    }
                    else
                    {
                        $row .= "<td><font size=-3>No group</font></td></tr>\n";
                    }

                    if (($row =~ m/$search/im || $search eq "") && $force_row >= 0)
                    {
                        $overall_count++;
                        $html_text .= "$row ";
                    }

                    $old_row_num = $row_num;
                    $row = "<tr class=\"$even_odd\"><td>$field</td>\n";
                }
                else
                {
                    $row .= "<td>$field</td>\n";
                }
            }
        }
        
        # Handle last row..
        {
            # Add row to table if matched 
            $fake_row = $row;
            $fake_row =~ s/<[^>]*>//img;
            my $force_row = 0;
            if ($many_groups)
            {
                $force_row = -1;
            }

            if ($fake_row =~ m/$overall_match/im && $overall_match ne ".*" && $overall_match ne "") 
            {
                $force_row = 1;
                if ($only_one_group == 1 && $fake_row =~ m/($group)/im) 
                {
                    my $this_group = $1;
                    $group_counts {$this_group}++;
                    $row .= " <td>$this_group</td> </tr>\n";
                }
                elsif ($first_group_only && $fake_row =~ m/$overall_match/im && ($fake_row =~ m/($group)/mg))
                {
                    my $this_group = $1;
                    if ($fake_row =~ m/($group2)/mg)
                    {
                        $group_counts {$this_group}++;
                        $row .= " <td>$this_group</td> </tr>\n";
                    }
                    else
                    {
                        $row .= "<td><font size=-3>No group</font></td></tr>\n";
                    }
                }
                elsif ($many_groups && $fake_row =~ m/($group)/im)
                {
                    my $this_group = $1;
                    if ($fake_row =~ m/($group2)/im)
                    {
                        $this_group .= " " . $1;
                        $group_counts {$this_group}++;
                        $row .= " <td>$this_group</td> </tr>\n";
                    }
                    else
                    {
                        $row .= "<td><font size=-3>No group</font></td></tr>\n";
                    }
                }
            }
            else
            {
                $row .= "<td><font size=-3>No group</font></td></tr>\n";
            }

            if (($row =~ m/$search/im || $search eq "") && $force_row >= 0)
            {
                $overall_count++;
                $html_text .= "$row ";
            }
        }

        $html_text .= "</font></tbody>\n";
        $html_text .= "</table></div>\n";
        $html_text =~ s/YYY/$overall_count/mg;

        my $group_block;
        if ($group =~ m/.../)
        {
            my $g;
            my $total_g_count;
            my $total_g_price;
            foreach $g (sort keys (%group_counts))
            {
                my $g_price = $group_prices {$g};
                my $g_count = $group_counts {$g};
                my $g_calc = $group_prices {$g. "_calc"};
                $g_price =~ s/(\d\d)$/.$1/;
                $group_block .= "<font color=$group_colours{$g}>Group $g had $g_count rows (price was $g_price from $g_calc)</font><br>";
                $total_g_count += $g_count;
                $total_g_price += $g_price;
            }
            $group_block .= "Total row count: $total_g_count"; 
        }

        my $c;
        foreach $c (sort keys (%col_types))
        {
            if ($col_types{$c} eq "PRICE")
            {
                $col_calculations{$c} = $col_calculations{$c} / 100;
            }
            $group_block .= "<br>Column $c (" . get_col_header ($c) . "): $col_types{$c} ($col_calculations{$c})"; 
        }

        $html_text =~ s/QQQ/<font size=-3>$group_block<\/font>/im;
        $html_text =~ s/QQQ//im;
        
        for ($x = 0; $x < $max_field_num; $x++)
        {
            if (get_col_type ($x) eq "PRICE" || get_col_type ($x) eq "NUMBER")
            {
                $html_text =~ s/XYZ$x/ class=td.price/;
            }
            else
            {
                my $ccc = get_col_type ($x);
                $html_text =~ s/XYZ$x//;
            }
        }

        $html_text .= "<br>$deck";
        $html_text .= "</body>\n";
        $html_text .= "</html>\n";

        write_to_socket (\*CLIENT, $html_text, "", "noredirect");
        $have_to_write_to_socket = 0;
        print ("============================================================\n");
    }
}
