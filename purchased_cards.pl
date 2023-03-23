#!/usr/bin/perl
##
#   File : purchased_cards.pl
#   Date : 23/Mar/2023
#   Author : spjspj
#   Purpose : Record which cards I've purchased..
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
        $header = "HTTP/1.1 301 Moved\nLocation: /purchasedcards/\nLast-Modified: $yyyymmddhhmmss\nConnection: close\nContent-Type: text/html; charset=UTF-8\nContent-Length: " . length ($msg_body) . "\n\n";
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
my %all_cards_font;
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
        my $line = $_;
        if ($line =~ m/^"(.+?)",(already|want),(.),(.*?),(.*?),(.*)/)
        {
            my $card = $1;
            my $have = $2;
            my $card_type = $3;
            my $date_of_purchase = $4;
            my $place_of_purchase = $5;
            my $font = $6;

            $all_cards {$card} = 1;
            $all_cards_have {$card} = $have;
            $all_cards_card_type {$card} = $card_type;
            $all_cards_date {$card} = $date_of_purchase;
            $all_cards_place {$card} = $place_of_purchase;
            $all_cards_font {$card} = $font;
        }
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

        my $ok = is_authorized ($SUPPLIED_PASSWORD);

        if ($ok != 1)
        {
            $SUPPLIED_PASSWORD = "";
            print ("\n\n\n=======================\n\nCould not find a password in::$txt\n::\n");
            $txt = "<font color=red>Supply password here:</font><br><br>";
            $txt .= "
                <form action=\"/purchasedcards/password\">
                <label for=\"password\">Password:</label><br>
                <input type=\"text\" id=\"password\" name=\"password\" value=\"xyz\"><br>
                <input type=\"submit\" value=\"Supply password to proceed\">
                </form>";
            write_to_socket (\*CLIENT, $txt, "", "noredirect");
            next;
        }

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
        
        if ($txt =~ m/\/card\?(.*)\Wplace\?(.*) HTTP/im)
        {
            my $card = $1;
            my $place = $2;
            my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
            my $yyyymmddhhmmss = sprintf "%.4d%.2d%.2d-%.2d%.2d%.2d", $year+1900, $mon+1, $mday, $hour,  $min, $sec;
            my $html_text = "Noted - $card purchased in $place on the date: $yyyymmddhhmmss<br>Return to <a href=\"\/purchasedcards\/\">List here<\/a>\n";
            open PURCHASES, ">> D:/D_Downloads/apache_lounge/Apache24/cgibin/purchases.txt";
            print PURCHASES $html_text . " <<< Correct password..\n";
            close PURCHASES;
            print "JUST PURCHASED SOMETHING!!!\n";
            print "$html_text\n";
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

        my @strs = split /&/, $txt;
        #print join (',,,', @strs);

        # Sortable table with cards in it..
        my $html_text = "<!DOCTYPE html>\n";
        $html_text .= "<html lang='en' class=''>\n";
        $html_text .= "<head>\n";
        $html_text .= "  <meta charset='UTF-8'>\n";
        $html_text .= "  <title>CodePen Demo</title>\n";
        $html_text .= "  <meta name=\"robots\" content=\"noindex\">\n";
        $html_text .= "  <link rel=\"shortcut icon\" type=\"image/x-icon\" href=\"https://cpwebassets.codepen.io/assets/favicon/favicon-aec34940fbc1a6e787974dcd360f2c6b63348d4b1f4e06c77743096d55480f33.ico\">\n";
        $html_text .= "  <link rel=\"mask-icon\" href=\"https://cpwebassets.codepen.io/assets/favicon/logo-pin-b4b4269c16397ad2f0f7a01bcdf513a1994f4c94b8af2f191c09eb0d601762b1.svg\" color=\"#111\">\n";
        $html_text .= "  <link rel=\"canonical\" href=\"https://codepen.io/pen\">\n";
        $html_text .= "  \n";
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
        $html_text .= "<script src=\"https://cpwebassets.codepen.io/assets/editor/iframe/iframeConsoleRunner-6bce046e7128ddf9391ccf7acbecbf7ce0cbd7b6defbeb2e217a867f51485d25.js\"></script>\n";
        $html_text .= "<script src=\"https://cpwebassets.codepen.io/assets/editor/iframe/iframeRefreshCSS-44fe83e49b63affec96918c9af88c0d80b209a862cf87ac46bc933074b8c557d.js\"></script>\n";
        $html_text .= "<script src=\"https://cpwebassets.codepen.io/assets/editor/iframe/iframeRuntimeErrors-4f205f2c14e769b448bcf477de2938c681660d5038bc464e3700256713ebe261.js\"></script>\n";
        $html_text .= "</head>\n";
        $html_text .= "<body>\n";
        $html_text .= "<script>\n";
        $html_text .= "'use strict';\n";
        $html_text .= "class SortableTable { constructor(tableNode) { this.tableNode = tableNode; this.columnHeaders = tableNode.querySelectorAll('thead th'); this.sortColumns = []; for (var i = 0; i < this.columnHeaders.length; i++) { var ch = this.columnHeaders[i]; var buttonNode = ch.querySelector('button'); if (buttonNode) { this.sortColumns.push(i); buttonNode.setAttribute('data-column-index', i); buttonNode.addEventListener('click', this.handleClick.bind(this)); } } this.optionCheckbox = document.querySelector( 'input[type=\"checkbox\"][value=\"show-unsorted-icon\"]'); if (this.optionCheckbox) { this.optionCheckbox.addEventListener( 'change', this.handleOptionChange.bind(this)); if (this.optionCheckbox.checked) { this.tableNode.classList.add('show-unsorted-icon'); } } } setColumnHeaderSort(columnIndex) { if (typeof columnIndex === 'string') { columnIndex = parseInt(columnIndex); } for (var i = 0; i < this.columnHeaders.length; i++) { var ch = this.columnHeaders[i]; var buttonNode = ch.querySelector('button'); if (i === columnIndex) { var value = ch.getAttribute('aria-sort'); if (value === 'descending') { ch.setAttribute('aria-sort', 'ascending'); this.sortColumn( columnIndex, 'ascending', ch.classList.contains('num')); } else { ch.setAttribute('aria-sort', 'descending'); this.sortColumn( columnIndex, 'descending', ch.classList.contains('num')); } } else { if (ch.hasAttribute('aria-sort') && buttonNode) { ch.removeAttribute('aria-sort'); } } } } sortColumn(columnIndex, sortValue, isNumber) { function compareValues(a, b) { if (sortValue === 'ascending') { if (a.value === b.value) { return 0; } else { if (isNumber) { return a.value - b.value; } else { return a.value < b.value ? -1 : 1; } } } else { if (a.value === b.value) { return 0; } else { if (isNumber) { return b.value - a.value; } else { return a.value > b.value ? -1 : 1; } } } } if (typeof isNumber !== 'boolean') { isNumber = false; } var tbodyNode = this.tableNode.querySelector('tbody'); var rowNodes = []; var dataCells = []; var rowNode = tbodyNode.firstElementChild; var index = 0; while (rowNode) { rowNodes.push(rowNode); var rowCells = rowNode.querySelectorAll('th, td'); var dataCell = rowCells[columnIndex]; var data = {}; data.index = index; data.value = dataCell.textContent.toLowerCase().trim(); if (isNumber) { data.value = parseFloat(data.value); } dataCells.push(data); rowNode = rowNode.nextElementSibling; index += 1; } dataCells.sort(compareValues); while (tbodyNode.firstChild) { tbodyNode.removeChild(tbodyNode.lastChild); } for (var i = 0; i < dataCells.length; i += 1) { tbodyNode.appendChild(rowNodes[dataCells[i].index]); } }  handleClick(event) { var tgt = event.currentTarget; this.setColumnHeaderSort(tgt.getAttribute('data-column-index')); } handleOptionChange(event) { var tgt = event.currentTarget; if (tgt.checked) { this.tableNode.classList.add('show-unsorted-icon'); } else { this.tableNode.classList.remove('show-unsorted-icon'); } } }\n";
        $html_text .= "window.addEventListener('load', function () { var sortableTables = document.querySelectorAll('table.sortable'); for (var i = 0; i < sortableTables.length; i++) { new SortableTable(sortableTables[i]); } });\n";
        $html_text .= "</script>\n";
        $html_text .= "<div class=\"table-wrap\"><table class=\"sortable\">\n";
        $html_text .= "<caption>\n";
        $html_text .= "Cards\n";
        $html_text .= "</caption>\n";
        $html_text .= "<thead>\n";
        $html_text .= "<tr>\n";
        $html_text .= "<th> <button><font size=-1>Name<span aria-hidden=\"true\"></span> </font></button> </th> \n";
        $html_text .= "<th> <button><font size=-1>Type<span aria-hidden=\"true\"></span> </font></button> </th> \n";
        $html_text .= "<th> <button><font size=-1>Color<span aria-hidden=\"true\"></span> </font></button> </th> \n";
        $html_text .= "<th aria-sort=\"ascending\"> <button><font size=-1>Own?<span aria-hidden=\"true\"></span> </font></button> </th> \n";
        $html_text .= "<th> <button><font size=-1>When<span aria-hidden=\"true\"></span> </font></button> </th> \n";
        $html_text .= "<th> <button><font size=-1>Place<span aria-hidden=\"true\"></span> </font></button> </th> \n";
        $html_text .= "<th> <button><font size=-1>Ronin<span aria-hidden=\"true\"></span> </font></button> </th> \n";
        $html_text .= "<th> <button><font size=-1>EndGames<span aria-hidden=\"true\"></span> </font></button> </th> \n";
        $html_text .= "<th> <button><font size=-1>RoninURL<span aria-hidden=\"true\"></span> </font></button> </th> \n";
        $html_text .= "<th> <button><font size=-1>EndGamesURL<span aria-hidden=\"true\"></span> </font></button> </th> \n";
        $html_text .= "<th class=\"no-sort\">*</th>\n";
        $html_text .= "</tr>\n";
        $html_text .= "</thead>\n";
        $html_text .= "<tbody><font size=-2>\n";

        my $checked = "";

        my $card;
        my $even_odd = "even";
        foreach $card (sort keys (%all_cards))
        {
            my $color = $all_cards_font{$card};
            if ($color eq "white") { $color = "darkgrey"; }
            if ($color eq "colorless") { $color = "purple"; }
            if ($color eq "multicolored") { $color = "darkyellow"; }
            #if (lc ($all_cards_have{$card}) eq "want")
            {
                $html_text .= " <tr class=\"$even_odd\"><td> <font color=\"$color\">$card</font></td>";
                $html_text .= " <td> <font color=\"$color\">$all_cards_card_type{$card}&nbsp;&nbsp;</a> </font>&nbsp;&nbsp;\n </td>";
                $html_text .= " <td> <font color=\"$color\">$color</a> </font>\n</td>";
                $html_text .= " <td> <font color=\"$color\">$all_cards_have{$card}</a> &nbsp;&nbsp;</font>&nbsp;&nbsp;\n </td>";

                my $d = $all_cards_date{$card};
                $html_text .= " <td> <font color=\"$color\">$d</a> </font>&nbsp;&nbsp;\n </td>";
                $html_text .= " <td> <font color=\"$color\">$all_cards_place{$card}</a> </font>&nbsp;&nbsp;\n </td>";
                #$html_text .= " <td> <font color=\"$color\"> <a href=\"purchasedcards/card?$card&place?ronin\">$card</a> </font>&nbsp;&nbsp;\n </td>";
                $html_text .= " <td> <font color=\"$color\"> <font size=-2>not in oz..</font></font>&nbsp;&nbsp;\n </td>";

                if ($all_cards_have{$card} ne "already")
                {
                    $html_text .= "<td><font color=\"$color\"> <a href=\"/purchasedcards/card?$card&place?end_games\">Bought it</a> </font> <br>\n </td>\n";
                }
                else
                {
                    $html_text .= "<td><font size=-2>Already have..</font> <br>\n </td>\n";
                }
                if ($all_cards_have{$card} ne "already")
                {
                    #$html_text .= " <td> <font size=-2 color=\"$color\"><a href=\"https://roningames.com.au/search?type=product&options[prefix]=last&q=$card\">$card</a> </font></td>\n";
                    $html_text .= " <td> <font color=\"$color\"> <font size=-2>not in oz..</font></font>&nbsp;&nbsp;\n </td>";
                }
                else
                {
                    $html_text .= "<td><font size=-2>Already have..</font> <br>\n </td>\n";
                }

                
                if ($all_cards_have{$card} ne "already")
                {
                    $html_text .= "<td> <font size=-2 color=\"$color\"><a href=\"https://www.theendgames.co/products/search?q=$card\">$card</a> </font></td></tr>\n";
                }
                else
                {
                    $html_text .= "<td><font size=-2>Already have..</font> <br>\n </td>\n";
                }

                if ($even_odd eq "even") { $even_odd = "odd"; } 
                else { $even_odd = "even"; } 
            }
            #if (lc ($all_cards_have{$card}) eq "already")
            #{
            #    $already_bought .= " <font color=\"$color\"> $card </font> (Have?=$all_cards_have{$card}), $all_cards_card_type{$card}, $all_cards_date{$card}, $all_cards_place{$card} </font>, $all_cards_font{$card} <br>\n";
            #}
        }

        $html_text .= "</font></tbody>\n";
        $html_text .= "</table></div>\n";

        $html_text .= "<a href=\"https://i.imgur.com/wZIV4Al.png\">Boxes1</a><br>";
        $html_text .= "<a href=\"https://imgur.com/a/9uj84ka\">Boxes2</a><br>";
        $html_text .= "<a href=\"https://imgur.com/a/Bdt159R\">EDH Decklists</a><br>";
        $html_text .= "<a href=\"https://www.mtggoldfish.com/deck/3985938#paper\">My Wanted list..</a><br>";
        $html_text .= "<h2><a href=\"https://www.mtggoldfish.com/deck_searches/create?utf8=%E2%9C%93&deck_search%5Bname%5D=&deck_search%5Bformat%5D=free_form&deck_search%5Btypes%5D%5B%5D=&deck_search%5Btypes%5D%5B%5D=tournament&deck_search%5Btypes%5D%5B%5D=budget&deck_search%5Btypes%5D%5B%5D=user&deck_search%5Bplayer%5D=spjspj&deck_search%5Bdate_range%5D=12%2F01%2F2017+-+11%2F08%2F2055&deck_search%5Bdeck_search_card_filters_attributes%5D%5B0%5D%5Bcard%5D=&deck_search%5Bdeck_search_card_filters_attributes%5D%5B0%5D%5Bquantity%5D=1&deck_search%5Bdeck_search_card_filters_attributes%5D%5B0%5D%5Btype%5D=maindeck&deck_search%5Bdeck_search_card_filters_attributes%5D%5B1%5D%5Bcard%5D=&deck_search%5Bdeck_search_card_filters_attributes%5D%5B1%5D%5Bquantity%5D=1&deck_search%5Bdeck_search_card_filters_attributes%5D%5B1%5D%5Btype%5D=maindeck&counter=2&commit=Search\">Search my EDH decks</a><br></h2>";

        foreach $card (sort keys (%purchased_cards))
        {
            $html_text .= "<br>$card";
        }
        $html_text .= "</body>\n";
        $html_text .= "</html>\n";

        write_to_socket (\*CLIENT, $html_text, "", "noredirect");
        $have_to_write_to_socket = 0;
        print ("============================================================\n");
    }
}
