#!/usr/bin/perl
##
#   File : purchased_cards.pl
#   Date : 23/Mar/2023
#   Author : spjspj
#   Purpose : Record which cards I've purchased..
#   Files: D:/D_Downloads/apache_lounge/Apache24/cgibin/cards_list.txt
#          D:/D_Downloads/apache_lounge/Apache24/cgibin/purchases.txt
##

use strict;
use POSIX;
use LWP::Simple;
use Socket;
use File::Copy;

my %card_names;
my %original_lines;
my %original_lines_just_card_names;
my %card_text;
my %card_cost;
my %card_type;
my %card_converted_cost;
my %all_cards_abilities;
my %expansion;
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
        $header = "HTTP/1.1 301 Moved\nLocation: /purchasedcards/\nLast-Modified: $yyyymmddhhmmss\nConnection: close\nAccess-Control-Allow-Origin: *\nContent-Type: text/html; charset=UTF-8\nContent-Length: " . length ($msg_body) . "\n\n";
    }
    elsif ($redirect =~ m/^noredirect/i)
    {
        if ($SUPPLIED_PASSWORD =~ m/^$/)
        {
            $header = "HTTP/1.1 200 OK\nLast-Modified: $yyyymmddhhmmss\nConnection: close\nAccess-Control-Allow-Origin: *\nContent-Type: text/html; charset=UTF-8\nContent-Length: " . length ($msg_body) . "\n\n";
        }
        else
        {
            $header = "HTTP/1.1 200 OK\nLast-Modified: $yyyymmddhhmmss\nConnection: close\nAccess-Control-Allow-Origin: *\nContent-Type: text/html\nSet-Cookie: SUPPLIED_PASSWORD=$SUPPLIED_PASSWORD\nContent-Length: " . length ($msg_body) . "\n\n";
        }
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

# Read all cards
my %all_cards;
my %all_cards_have;
my %all_cards_card_type;
my %all_cards_date;
my %all_cards_place;
my %all_cards_color;
my %all_cards_price;
my %all_cards_div_name;

sub add_new_card
{
    my $line = $_ [0];
    $line = fix_url_code ($line);
    if ($line =~ m/^([^;]+?);(already);(.);([^;]+?);([^;]+?);([^;]+?);(\$*\d+\.\d\d|\$\d+|)(;|$)/)
    {
        my $card = $1;
        my $have = $2;
        my $card_type = $3;
        my $date_of_purchase = $4;
        my $place_of_purchase = $5;
        my $color = $6;
        my $price = $7;
        $card =~ s/\+/ /g;

        $all_cards {$card} = 1;
        $all_cards_have {$card} = $have;
        $all_cards_card_type {$card} = uc($card_type);
        $all_cards_date {$card} = $date_of_purchase;
        $all_cards_place {$card} = $place_of_purchase;
        $all_cards_color {$card} = $color;
        $all_cards_price {$card} = $price;
        my $div_name = "div_$card";
        $div_name =~ s/\W+/_/img;
        $all_cards_div_name {$card} = $div_name;
    }
    elsif ($line =~ m/^([^;]+?);(want);(.); *; *;([^;]+?);/)
    {
        my $card = $1;
        my $have = $2;
        my $card_type = $3;
        my $color = $4;

        $all_cards {$card} = 1;
        $all_cards_have {$card} = $have;
        $all_cards_card_type {$card} = uc($card_type);
        $all_cards_color {$card} = $color;
        my $div_name = "want_div_$card";
        $div_name =~ s/\W+/_/img;
        $all_cards_div_name {$card} = $div_name;
    }
    else
    {
        print ("Found error with: $line\n");
        if ($line !~ m/^([^;]+?);(already);(.);([^;]+?);([^;]+?);([^;]+?);(\d+\.\d\d|\$*\d+|)(;|$)/)
        {
            print ("1 failed ($line) here\n");
        }
        if ($line !~ m/^([^;]+?);(already);(.);([^;]+?);([^;]+?);([^;]+?);(\$\d+\.\d\d|\$*\d+|)/)
        {
            print ("2 failed ($line) here\n");
        }
        if ($line !~ m/^([^;]+?);(already);(.);([^;]+?);([^;]+?);([^;]+?);/)
        {
            print ("3 failed ($line) here\n");
        }
        if ($line !~ m/^([^;]+?);(already);(.);([^;]+?);([^;]+?);/)
        {
            print ("4 failed ($line) here\n");
        }
        if ($line !~ m/^([^;]+?);(already);(.);([^;]+?);/)
        {
            print ("5 failed ($line) here\n");
        }
        if ($line !~ m/^([^;]+?);(already);(.);([^;]+?)/)
        {
            print ("6 failed ($line) here\n");
        }
        if ($line !~ m/^([^;]+?);(already);(.);/)
        {
            print ("7 failed ($line) here\n");
        }
    }
}

sub read_all_cards
{
    my $CURRENT_FILE = "D:/D_Downloads/apache_lounge/Apache24/cgibin/cards_list.txt";
    open ALL, $CURRENT_FILE; 
    print ("Reading from $CURRENT_FILE\n");

    #"Shorikai, Genesis Engine",already,c,20230218,ronin
    #"Stranglehold",already,e,20230313,ronin
    #"The World Tree ",already,l,nodate,ronin
    #"Throne of Empires",already,a,20220501,ronin
    #"Vito, Thorn of the Dusk Rose",already,c,nodate,ronin
    #"Yorion, Sky Nomad",already,c,nodate,ronin
    #"Arcane Lighthouse",want,l,,,,
    #"Buried Ruin",want,l,,,,

    while (<ALL>)
    {
        chomp $_;
        add_new_card ($_);
    }
    close ALL;
}

my %purchased_cards;
sub read_all_purchased_cards
{
    my $CURRENT_FILE = "D:/D_Downloads/apache_lounge/Apache24/cgibin/purchases.txt";
    open ALL, $CURRENT_FILE; 
    print ("Reading from $CURRENT_FILE\n");

    while (<ALL>)
    {
        chomp $_;
        my $line = $_;
        $purchased_cards {$line} = 1;
        $line =~ s/"//g;
        $line =~ s/,/;/g;
        add_new_card ($line);
    }
    close ALL;
}

sub is_authorized
{
    my $pw = $_ [0];
    if ($pw eq "IReallySmellLikeJig")
    {
        # Check that the other programs are running..
        return 1;
    }
    return 0;
}

sub fix_url_code
{
    my $txt = $_ [0];
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
    return $txt;
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
    my $port = 6723;
    my $trusted_client;
    my $data_from_client;
    $|=1;
    read_all_cards;
    read_all_purchased_cards;

    socket (SERVER, PF_INET, SOCK_STREAM, $proto) or die "Failed to create a socket: $!";
    setsockopt (SERVER, SOL_SOCKET, SO_REUSEADDR, 1) or die "setsocketopt: $!";

    # bind to a port, then listen
    bind (SERVER, sockaddr_in ($port, INADDR_ANY)) or die "Can't bind to port $port! \n";

    listen (SERVER, 10) or die "listen: $!";
    print ("Listening on port: $port\n");
    my $count;
    my $not_seen_full = 1;

    my @ac = sort (keys (%all_cards));

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
        $txt =~ s/purchasedlands\/purchasedlands/purchasedlands\//img;
        $txt =~ s/purchasedlands\/purchasedlands/purchasedlands\//img;
        $txt =~ s/purchasedlands\/purchasedlands/purchasedlands\//img;
        $txt =~ s/purchasedlands\/purchasedlands/purchasedlands\//img;

        $SUPPLIED_PASSWORD = "";
        if ($txt =~ m/^Cookie.*?SUPPLIED_PASSWORD=(\w\w\w[\w_]+).*?(;|$)/im)
        {
            $SUPPLIED_PASSWORD = $1;
        }

        if ($txt =~ m/password=(\w\w\w[\w_]+) HTTP/im)
        {
            $SUPPLIED_PASSWORD = $1;
        }

        my $authorized = is_authorized ($SUPPLIED_PASSWORD);

        

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
        
        if ($txt =~ m/.*get_list.*/m)
        {
            my $html_text;
            my $card;
            foreach $card (sort keys (%all_cards))
            {
                $html_text .= "$card;";
                $html_text .= $all_cards_have {$card} . ";";
                $html_text .= $all_cards_card_type {$card} . ";";
                $html_text .= $all_cards_date {$card} . ";";
                $html_text .= $all_cards_place {$card} . ";";
                $html_text .= $all_cards_color {$card} . ";";
                $html_text .= $all_cards_price {$card} . ";<br>\n";
            }
            write_to_socket (\*CLIENT, $html_text, "", "noredirect");
            next;
        }
        # Have got all information?? https://xmage.au/purchasedcards/card_info?card_name=Arcane+Adaptation&purchased=ronin&color=blue&type=enchantment&price=0.00 HTTP/1.1
        if ($txt =~ m/card_info\?card_name=(.*?)&purchased=(.*?)&color=(.*?)&type=(.*?)&price=((\d+)\.(\d+)|\d+) HTTP/im)
        {
            my $card = $1;
            my $place = $2;
            my $color = $3;
            my $card_type = $4;
            my $price = $5;

            $color =~ m/^(.)/;
            my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
            my $yyyymmdd = sprintf "%.4d%.2d%.2d", $year+1900, $mon+1, $mday;
            
            my $card_type_fl = $card_type;
            $card_type_fl =~ s/^(.).*/$1/;


            # name;have;type;date;place;color;price;currency;
            my $card_line = "$card;already;$card_type_fl;$yyyymmdd;$place;$color;$price";
            open PURCHASES, ">> D:/D_Downloads/apache_lounge/Apache24/cgibin/purchases.txt";
            print PURCHASES $card_line . "\n";
            close PURCHASES;
            my $html_text = "Noted - $card purchased in $place on the date: $yyyymmdd for $price (card color was $color and type was $card_type<br>Return to <a href=\"\/purchasedcards\/\">List here<\/a>\n";
            write_to_socket (\*CLIENT, $html_text, "", "noredirect");
            next;
        }
        elsif ($txt =~ m/\/card\?(.*)\Wplace\?(.*) HTTP/im)
        {
            my $card = $1;
            my $place = $2;
            my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
            my $yyyymmddhhmmss = sprintf "%.4d%.2d%.2d-%.2d%.2d%.2d", $year+1900, $mon+1, $mday, $hour,  $min, $sec;
            my $yyyymmdd = sprintf "%.4d%.2d%.2d", $year+1900, $mon+1, $mday;
            my $html_text;# = "Noted - $card purchased in $place on the date: $yyyymmddhhmmss<br>Return to <a href=\"\/purchasedcards\/\">List here<\/a>\n";
            # Example: "War Tax",already,e,20230329,endgames,blue
                #<input type=\"text\" id=\"color\" name=\"color\" list=value>
            
            $html_text = "<font color=red>Card information:</font><br><br>";
            $card =~ s/%20/ /img;
            $html_text .= "<form action=\"/purchasedcards/card_info\">
                <label for=\"card_name\">Card name:</label><br>
                <input type=\"text\" id=\"card_name\" name=\"card_name\" value=\"$card\"><br><br>
                <label for=\"card_name\">Purchased:</label><br>
                <input type=\"text\" id=\"purchased\" name=\"purchased\" value=\"$place\"><br><br>
                <label for=\"card_name\">color:</label><br>
                <select id=\"color\" name=\"color\">
                    <option value=\"Select\">Select....</option>
                    <option value=\"white\">white</option>
                    <option value=\"blue\">blue</option>
                    <option value=\"black\">black</option>
                    <option value=\"red\">red</option>
                    <option value=\"green\">green</option>
                    <option value=\"colorless\">colorless</option>
                    <option value=\"mulitcolored\">multicolored</option>
                </select><br><br>
                <label for=\"card_name\">Type:</label><br>
                <select id=\"type\" name=\"type\">
                    <option value=\"Select\">Select....</option>
                    <option value=\"creature\">creature</option>
                    <option value=\"enchantment\">enchantment</option>
                    <option value=\"artifact\">artifact</option>
                    <option value=\"land\">land</option>
                    <option value=\"saga\">saga</option>
                    <option value=\"battle\">battle</option>
                    <option value=\"planewalker\">planewalker</option>
                    <option value=\"instant\">instant</option>
                    <option value=\"sorcery\">sorcery</option>
                    <option value=\"planeswalker\">planeswalker</option>
                </select><br><br>
                <label for=\"card_name\">Price (\$):</label><br>
                <input type=\"text\" id=\"price\" name=\"price\" value=\"0.00\"><br><br>
                <input type=\"submit\" value=\"Submit\">
                </form>\n";
            write_to_socket (\*CLIENT, $html_text, "", "noredirect");
            next;
        }
        print "DID NOT PURCHASED SOMETHING!!!\n";
        print "$txt\n";

        print ("Read -> $txt\n");

        print ("2- - - - - - -\n");
        my $have_to_write_to_socket = 1;

        chomp ($txt);
        my $original_get = $txt;

        $txt =~ s/.*filter\?//;
        $txt =~ s/.*stats\?//;
        $txt =~ s/ http.*//i;
        $txt = fix_url_code ($txt);

        
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
        $html_text .= "  <title>Cards List</title>\n";
        $html_text .= "  <meta name=\"robots\" content=\"noindex\">\n";
        $html_text .= "  <link rel=\"icon\" href=\"favicon.ico\">\n";
        $html_text .= "<link rel=\"stylesheet\" href=\"https://www.w3.org/content/shared/css/core.css\">\n";
        $html_text .= "<link rel=\"stylesheet\" href=\"https://www.w3.org/StyleSheets/TR/2016/base.css\">\n";
        $html_text .= "<link rel=\"stylesheet\" href=\"https://use.fontawesome.com/releases/v5.1.0/css/all.css\">\n";
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
        $html_text .= "var xyz = 'bbbbbbb';";
        $html_text .= "xyz = xyz.replace (/b/, 'x');";
        $html_text .= "</script>\n";
        
        $html_text .= "<table><tr><td>\n";
        $html_text .= "<form action=\"/purchasedcards/search\">
                <label for=\"searchstr\">Search:</label><br>
                <input type=\"text\" id=\"searchstr\" name=\"searchstr\" value=\"$search\">
                <input type=\"submit\" value=\"Search\">
                </form></td><td>";

        $html_text .= "<form action=\"/purchasedcards/groupby\">
                <label for=\"groupstr\">Group by (first group only):</label><br>
                <input type=\"text\" id=\"groupstr\" name=\"groupstr\" value=\"$group\">
                <input type=\"submit\" value=\"Group By\">
                </form></td><td>";
                
        $html_text .= "<form action=\"/purchasedcards/multigroupby\">
                <label for=\"multigroup\">Multi group (row must match, 2 groups):</label><br>
                <input type=\"text\" id=\"multigroup\" name=\"multigroup\" value=\"$multi_group\">
                <input type=\"submit\" value=\"Multi Group By\">
                </form><a href=\"/purchasedcards/get_list\"><font size=-2>View CSV</font></a></td></tr></table>";

        my %groups;

        $html_text .= "<script>\n";
        $html_text .= "'use strict';\n";
        $html_text .= "class SortableTable { constructor(tableNode) { this.tableNode = tableNode; this.columnHeaders = tableNode.querySelectorAll('thead th'); this.sortColumns = []; for (var i = 0; i < this.columnHeaders.length; i++) { var ch = this.columnHeaders[i]; var buttonNode = ch.querySelector('button'); if (buttonNode) { this.sortColumns.push(i); buttonNode.setAttribute('data-column-index', i); buttonNode.addEventListener('click', this.handleClick.bind(this)); } } this.optionCheckbox = document.querySelector( 'input[type=\"checkbox\"][value=\"show-unsorted-icon\"]'); if (this.optionCheckbox) { this.optionCheckbox.addEventListener( 'change', this.handleOptionChange.bind(this)); if (this.optionCheckbox.checked) { this.tableNode.classList.add('show-unsorted-icon'); } } } setColumnHeaderSort(columnIndex) { if (typeof columnIndex === 'string') { columnIndex = parseInt(columnIndex); } for (var i = 0; i < this.columnHeaders.length; i++) { var ch = this.columnHeaders[i]; var buttonNode = ch.querySelector('button'); if (i === columnIndex) { var value = ch.getAttribute('aria-sort'); if (value === 'descending') { ch.setAttribute('aria-sort', 'ascending'); this.sortColumn( columnIndex, 'ascending', ch.classList.contains('td.num'), ch.classList.contains('td.price')); } else { ch.setAttribute('aria-sort', 'descending'); this.sortColumn( columnIndex, 'descending', ch.classList.contains('td.num'), ch.classList.contains('td.price')); } } else { if (ch.hasAttribute('aria-sort') && buttonNode) { ch.removeAttribute('aria-sort'); } } } } sortColumn(columnIndex, sortValue, isNumber, isPrice) { function compareValues(a, b) { if (sortValue === 'ascending') { if (a.value === b.value) { return 0; } else { if (isNumber) { return a.value - b.value; } else if (isPrice) { var aval = a.value; aval = aval.replace (/\\W/g, ''); var bval = b.value; bval = bval.replace (/\\W/g, '');  return aval - bval < 0 ? -1 : 1; } else { return a.value < b.value ? -1 : 1; } } } else { if (a.value === b.value) { return 0; } else { if (isNumber) { return b.value - a.value; } else if (isPrice) { var aval = a.value; aval = aval.replace (/\\W/g, ''); var bval = b.value; bval = bval.replace (/\\W/g, '');  return aval - bval < 0 ? 1 : -1; } else { return a.value > b.value ? -1 : 1; } } } } if (typeof isNumber !== 'boolean') { isNumber = false; } var tbodyNode = this.tableNode.querySelector('tbody'); var rowNodes = []; var dataCells = []; var rowNode = tbodyNode.firstElementChild; var index = 0; while (rowNode) { rowNodes.push(rowNode); var rowCells = rowNode.querySelectorAll('th, td'); var dataCell = rowCells[columnIndex]; var data = {}; data.index = index; data.value = dataCell.textContent.toLowerCase().trim(); if (isNumber) { data.value = parseFloat(data.value); } dataCells.push(data); rowNode = rowNode.nextElementSibling; index += 1; } dataCells.sort(compareValues); while (tbodyNode.firstChild) { tbodyNode.removeChild(tbodyNode.lastChild); } for (var i = 0; i < dataCells.length; i += 1) { tbodyNode.appendChild(rowNodes[dataCells[i].index]); } }  handleClick(event) { var tgt = event.currentTarget; this.setColumnHeaderSort(tgt.getAttribute('data-column-index')); } handleOptionChange(event) { var tgt = event.currentTarget; if (tgt.checked) { this.tableNode.classList.add('show-unsorted-icon'); } else { this.tableNode.classList.remove('show-unsorted-icon'); } } }\n";
        $html_text .= "window.addEventListener('load', function () { var sortableTables = document.querySelectorAll('table.sortable'); for (var i = 0; i < sortableTables.length; i++) { new SortableTable(sortableTables[i]); } });\n";
        $html_text .= "</script>\n";
        $html_text .= "<div class=\"table-wrap\"><table class=\"sortable\">\n";
                
        if ($authorized != 1)
        {
            $SUPPLIED_PASSWORD = "";
            $html_text .= "<font color=red>Supply password here:</font><br><br>";
            $html_text .= "
                <form action=\"/purchasedcards/password\">
                <label for=\"password\">Password:</label><br>
                <input type=\"text\" id=\"password\" name=\"password\" value=\"xyz\"><br>
                <input type=\"submit\" value=\"Supply password to proceed\">
                </form>";
        }

        $html_text .= "<thead>\n";
        $html_text .= "<br>Overall price was: \$XXX (from YYY cards)<br>";
        $html_text .= "<br>QQQ<br>";
       
        $html_text .= "<tr>\n";
        $html_text .= "<th> <button><font size=-1>Name<span aria-hidden=\"true\"></span> </font></button> </th> \n";
        $html_text .= "<th> <button><font size=-1>Type<span aria-hidden=\"true\"></span> </font></button> </th> \n";
        $html_text .= "<th> <button><font size=-1>Color<span aria-hidden=\"true\"></span> </font></button> </th> \n";
        $html_text .= "<th aria-sort=\"ascending\"> <button><font size=-1>Own?<span aria-hidden=\"true\"></span> </font></button> </th> \n";
        $html_text .= "<th> <button><font size=-1>When<span aria-hidden=\"true\"></span> </font></button> </th> \n";
        $html_text .= "<th> <button><font size=-1>Place<span aria-hidden=\"true\"></span> </font></button> </th> \n";
        $html_text .= "<th class=td.price> <button><font size=-1>Price<span aria-hidden=\"true\"></span> </font></button> </th> \n";
        $html_text .= "<th> <button><font size=-1>Goldfish<span aria-hidden=\"true\"></span> </font></button> </th> \n";
        $html_text .= "<th> <button><font size=-1>Buying?<span aria-hidden=\"true\"></span> </font></button> </th> \n";
        $html_text .= "<th> <button><font size=-1>LGS<span aria-hidden=\"true\"></span> </font></button> </th> \n";
        $html_text .= "<th> <button><font size=-1>cut.pl<span aria-hidden=\"true\"></span> </font></button> </th> \n";
        $html_text .= "<th> <button><font size=-1>Scryfall<span aria-hidden=\"true\"></span> </font></button> </th> \n";
        $html_text .= "<th> <button><font size=-1>Group<span aria-hidden=\"true\"></span> </font></button> </th> \n";
        $html_text .= "<th class=\"no-sort\">*</th>\n";
        $html_text .= "</tr>\n";
        $html_text .= "</thead>\n";
        $html_text .= "<tbody><font size=-2>\n";

        my $checked = "";

        my $card;
        my $even_odd = "even";
        my $deck;
        my $overall_price = 0;
        my $overall_price_str = "";
        my $overall_count = 0;
        my %group_prices;
        my %group_counts;
                
        my $only_one_group = 1;
        my $first_group_only = 0;
        my $many_groups = 0;
        my $overall_match = $group;

        my $group2 = "";
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

        foreach $card (sort keys (%all_cards))
        {
            my $color = $all_cards_color{$card};
            my $fontcolor = $color;
            if ($fontcolor eq "white") { $fontcolor = "darkgrey"; }
            if ($fontcolor eq "colorless") { $fontcolor = "purple"; }
            if ($fontcolor eq "multicolored") { $fontcolor = "darkyellow"; }
            #if (lc ($all_cards_have{$card}) eq "want")
            {
                my $row = "";
                my $fake_row = "";
                if ($all_cards_have{$card} ne "already")
                {
                    $row .= "<tr class=\"$even_odd\"><td> <font color=\"$fontcolor\">$card</font></td>\n";
                    $fake_row .= "cardname=$card ; ";
                    $deck .= "1 $card<br>";
                }
                else
                {
                    $row .= "<tr class=\"$even_odd\"><td> <font size=-2 color=\"darkred\">zzz $card</font></td>\n";
                    $fake_row .= "cardname=$card ; ";
                }

                my $card_type;
                if (lc ($all_cards_card_type{$card}) eq "a")
                {
                    $card_type = "artifact";
                }
                elsif (lc ($all_cards_card_type{$card}) eq "c")
                {
                    $card_type = "creature";
                }
                elsif (lc ($all_cards_card_type{$card}) eq "e")
                {
                    $card_type = "enchantment";
                }
                elsif (lc ($all_cards_card_type{$card}) eq "l")
                {
                    $card_type = "land";
                }
                elsif (lc ($all_cards_card_type{$card}) eq "i")
                {
                    $card_type = "instant";
                }
                elsif (lc ($all_cards_card_type{$card}) eq "p")
                {
                    $card_type = "planeswalker";
                }
                elsif (lc ($all_cards_card_type{$card}) eq "s")
                {
                    $card_type = "sorcery";
                }
                elsif (lc ($all_cards_card_type{$card}) eq "b")
                {
                    $card_type = "battle";
                }

                $row .= " <td> <font color=\"$fontcolor\">$card_type</a> </font>\n </td>\n";
                $fake_row .= "type=$all_cards_card_type{$card} ; ";
                $row .= " <td> <font color=\"$fontcolor\">$color</a> </font>\n</td>\n";
                $fake_row .= "color=$color ; ";
                $row .= " <td> <font color=\"$fontcolor\">$all_cards_have{$card}</a></font></td>\n";
                $fake_row .= "have=$all_cards_have{$card} ; ";

                my $d = $all_cards_date{$card};
                $row .= " <td> <font color=\"$fontcolor\">$d</a> </font>\n </td>\n";
                $fake_row .= "date=$d ; ";
                $row .= " <td> <font color=\"$fontcolor\">$all_cards_place{$card}</a> </font>\n </td>\n";
                $fake_row .= "place=$all_cards_place{$card} ; ";
                $row .= " <td> <font color=\"$fontcolor\">$all_cards_price{$card}</a> </font>\n </td>\n";
                $fake_row .= "price=$all_cards_price{$card} ; ";
                my $current_price = $all_cards_price{$card};
                $row .= " <td> <font color=\"$fontcolor\"><a href=\"https://www.mtggoldfish.com/q?query_string=$card\">Goldfish</a> </font>\n </td>\n";

                #  Scryfall additional images..
                #  https://api.scryfall.com/cards/named?exact=Kavu%20Aggressor
                #  ,"image_uris":{"small":"https://cards.scryfall.io/small/front/a/2/a2832ad3-ce7f-44d2-beb2-c95d982905a6.jpg?1562927844"
                #,"normal":"https://cards.scryfall.io/normal/front/a/2/a2832ad3-ce7f-44d2-beb2-c95d982905a6.jpg?1562927844"
                #,"large":"https://cards.scryfall.io/large/front/a/2/a2832ad3-ce7f-44d2-beb2-c95d982905a6.jpg?1562927844"

                if ($all_cards_have{$card} ne "already")
                {
                    if ($authorized)
                    {
                        $row .= " <td> <font color=\"$fontcolor\"> <a href=\"purchasedcards/card?$card&place?CardKingdom\">Bought it</a> </font>\n </td>\n";
                    }
                    else
                    {
                        $row .= " <td><font color=red size=-2>Not authorized</font></td>\n";
                    }
                }
                else
                {
                    $row .= "<td><font size=-2>Already have..</font> <br>\n </td>\n";
                }
                
                my $url = "https://roningames.com.au/search?type=product&options[prefix]=last&q=$card $card_type";
                $fake_row .= "cardtype=$card_type ; ";
                $row .= " <td> <font size=-2 color=\"$fontcolor\"><a href=\"$url\">$card</a> </font></td>\n";

                if ($all_cards_price{$card} =~ m/^$/ && $all_cards_have{$card} =~ m/already/)
                {
                    $row .= " <td> <font size=-3>echo \"1\" | cut.pl stdin \"https://www.mtggoldfish.com/price/Commander+2013+Edition/$card#paper\" $d mtgfcurl</font></td>\n\n";
                }
                else
                {
                    $row .= "<td><font size=-3>Already have price</font></td>\n";
                }

                # Add in div for small image of each card if you hover over
                my $div_name = $all_cards_div_name {$card};
                my $c = $card;
                $c =~ s/\W/ /img;
                if ($div_name =~ m/^want/)
                {
                    $row .= "<td><div id='$div_name' onmouseover='if (done_$div_name == 0) { done_$div_name = 1; getResponse(\"https://api.scryfall.com/cards/named?fuzzy=$c\", document.getElementById(\"$div_name\"), 0); }'><font size=-3>Image</font></div></td>\n";
                }
                else
                {
                    $row .= "<td><div id='$div_name' onmouseover='if (done_$div_name == 0) { done_$div_name = 1; getResponse(\"https://api.scryfall.com/cards/named?fuzzy=$c\", document.getElementById(\"$div_name\"), 0); }'><font size=-3>Image</font></div></td>\n";
                }
                $row =~ s/\n//img;

                my $force_row = 0;
                if ($many_groups)
                {
                    $force_row = -1;
                }

                $fake_row = $row;
                $fake_row =~ s/<[^>]*>//img;
                if ($fake_row =~ m/$overall_match/im && $overall_match ne ".*" && $overall_match ne "") 
                {
                    $force_row = 1;
                    if ($only_one_group == 1 && $fake_row =~ m/($group)/im) 
                    {
                        my $this_group = $1;
                        $group_counts {$this_group}++;
                        $row .= " <td>$this_group</td> </tr>\n";
                        if ($current_price =~ m/\$(\d+)\.(\d\d)/) 
                        {
                            $group_prices {$this_group} += $1*100 + $2;
                        }
                    }
                    elsif ($first_group_only && $fake_row =~ m/$overall_match/im && ($fake_row =~ m/($group)/mg))
                    {
                        my $this_group = $1;
                        if ($fake_row =~ m/($group2)/mg)
                        {
                            $group_counts {$this_group}++;
                            $row .= " <td>$this_group</td> </tr>\n";
                            if ($current_price =~ m/\$(\d+)\.(\d\d)/) 
                            {
                                $group_prices {$this_group} += $1*100 + $2;
                            }
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
                            if ($current_price =~ m/\$(\d+)\.(\d\d)/) 
                            {
                                $group_prices {$this_group} += $1*100 + $2;
                            }
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
                    $html_text .= "$row";
                    if ($current_price =~ m/\$(\d+)\.(\d\d)/) 
                    {
                        $overall_price += $1*100 + $2;
                        $overall_price_str .= " + $1*100 + $2 ";
                    }
                }

                if ($even_odd eq "even") { $even_odd = "odd"; } 
                else { $even_odd = "even"; } 
            }
        }

        $html_text .= "</font></tbody>\n";
        $html_text .= "</table></div>\n";
        $html_text .= "<script>\n";

        foreach $card (sort keys (%all_cards))
        {
            my $div_name = $all_cards_div_name {$card};
            $html_text .= "var done_$div_name = 0\n";
        }

        $html_text .= "async function getResponse(url, theObj, bigOrSmall) {\n";
        $html_text .= "    let response = await fetch(url);\n";
        $html_text .= "    let response_json = await response.json();\n";
        $html_text .= "    var image = new Image();\n";
        $html_text .= "    if (response_json.image_uris !== undefined) \n";
        $html_text .= "    {\n";
        $html_text .= "        if (bigOrSmall) {image.src = response_json.image_uris.normal; }\n";
        $html_text .= "        else { image.src = response_json.image_uris.small; } \n";
        $html_text .= "    }\n";
        $html_text .= "    else if (response_json.card_faces[0].image_uris !== undefined) \n";
        $html_text .= "    {\n";
        $html_text .= "        image.src = response_json.card_faces[0].image_uris.small;\n";
        $html_text .= "    }\n";
        $html_text .= "    theObj.innerHTML = '';\n";
        $html_text .= "    theObj.appendChild(image);\n";
        $html_text .= "}\n";
        $html_text .= "</script>\n";

        $overall_price =~ s/(\d\d)$/.$1/;
        #$html_text =~ s/XXX/$overall_price <font size=-2>$overall_price_str<\/font>/mg;
        $html_text =~ s/XXX/$overall_price/mg;
        $html_text =~ s/YYY/$overall_count/mg;

        if ($group =~ m/.../)
        {
            my $group_block;
            my $g;
            my $total_g_count;
            my $total_g_price;
            foreach $g (sort keys (%group_counts))
            {
                my $g_price = $group_prices {$g};
                my $g_count = $group_counts {$g};
                $g_price =~ s/(\d\d)$/.$1/;
                $group_block .= "Group $g costed \$$g_price and had $g_count cards<br>";
                $total_g_count += $g_count;
                $total_g_price += $g_price;
            }
            $group_block .= "Total cost: $total_g_price, Total count: $total_g_count"; 
            $html_text =~ s/QQQ/<font size=-3>$group_block<\/font>/im;
        }
        $html_text =~ s/QQQ//im;

        $html_text .= "<a href=\"https://imgur.com/a/9uj84ka\">Boxes2</a><br>";
        $html_text .= "<a href=\"https://imgur.com/a/Bdt159R\">EDH Decklists</a><br>";
        $html_text .= "<a href=\"https://www.mtggoldfish.com/deck/3985938#paper\">My Wanted list..</a><br>";
        $html_text .= "<h2><a href=\"https://www.mtggoldfish.com/deck_searches/create?utf8=%E2%9C%93&deck_search%5Bname%5D=&deck_search%5Bformat%5D=free_form&deck_search%5Btypes%5D%5B%5D=&deck_search%5Btypes%5D%5B%5D=tournament&deck_search%5Btypes%5D%5B%5D=budget&deck_search%5Btypes%5D%5B%5D=user&deck_search%5Bplayer%5D=spjspj&deck_search%5Bdate_range%5D=12%2F01%2F2017+-+11%2F08%2F2055&deck_search%5Bdeck_search_card_filters_attributes%5D%5B0%5D%5Bcard%5D=&deck_search%5Bdeck_search_card_filters_attributes%5D%5B0%5D%5Bquantity%5D=1&deck_search%5Bdeck_search_card_filters_attributes%5D%5B0%5D%5Btype%5D=maindeck&deck_search%5Bdeck_search_card_filters_attributes%5D%5B1%5D%5Bcard%5D=&deck_search%5Bdeck_search_card_filters_attributes%5D%5B1%5D%5Bquantity%5D=1&deck_search%5Bdeck_search_card_filters_attributes%5D%5B1%5D%5Btype%5D=maindeck&counter=2&commit=Search\">Search my EDH decks</a><br></h2>";

        foreach $card (sort keys (%purchased_cards))
        {
            $html_text .= "<br>$card";
        }
        $html_text .= "<br>$deck";
        $html_text .= "</body>\n";
        $html_text .= "</html>\n";

        if (!$authorized)
        {
            $html_text =~ s/ronin/obscura/img;
            $html_text =~ s/.com.au/.com/img;
        }
        write_to_socket (\*CLIENT, $html_text, "", "noredirect");
        $have_to_write_to_socket = 0;
        print ("============================================================\n");
    }
}
