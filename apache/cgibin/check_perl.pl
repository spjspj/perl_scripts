#!/usr/bin/perl
##
#   File : check_perl.pl
#   Date : 22/12/2022
#   Author : spjspj
#   Purpose : Check expected perl scripts are running.. 
##

use strict;
use POSIX;
use LWP::Simple;
use Socket;
use File::Copy;

sub print_card
{
    my $card_to_check = $_ [0];
    my $cn = card_name ($card_to_check);
    my $ctype = card_type ($card_to_check);
    my $ctxt = card_text ($card_to_check);
    my $cc = card_cost ($card_to_check);
    my $ccc = card_converted_cost ($card_to_check);
    my $exp = expansion ($card_to_check);

    #print ("$card_to_check - $cn - $ctxt - $ctype ($cc,,,$ccc)\n");
    return ("$card_to_check - nm,,$cn - txt,,$ctxt - typ,,$ctype ($cc,,,$ccc) -- $exp");
}

sub write_to_socket
{
    my $sock_ref = $_ [0];
    my $msg_body = $_ [1];
    my $form = $_ [2];
    my $redirect = $_ [3];
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    my $yyyymmddhhmmss = sprintf "%.4d%.2d%.2d-%.2d%.2d%.2d", $year+1900, $mon+1, $mday, $hour,  $min, $sec;
    print $yyyymmddhhmmss, "\n";

    $msg_body = '<html><head><META HTTP-EQUIV="CACHE-CONTROL" CONTENT="NO-CACHE"><br><META HTTP-EQUIV="EXPIRES" CONTENT="Mon, 22 Jul 2094 11:12:01 GMT"></head><body>' . $form . $msg_body . "<body></html>";

    my $header;
    if ($redirect =~ m/^redirect(\d)/i)
    {
        $header = "HTTP/1.1 301 Moved\nLocation: /full$1\nLast-Modified: $yyyymmddhhmmss\nConnection: close\nContent-Type: text/html; charset=UTF-8\nContent-Length: " . length ($msg_body) . "\n\n";
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
    my $min;
    my $max;
    my $msg_type;
    my $msg_body;
    my $msg_len;

    vec ($rin, fileno ($sock_ref), 1) = 1;

    # Read the message header
    my $num_chars_read = 0;

    while ((!(ord ($ch) == 10 and ord ($prev_ch) == 13)))
    {
        if (select ($rout=$rin, undef, undef, 200) == 1)
        {
            $prev_ch = $ch;
            # There is at least one byte ready to be read..
            if (sysread ($sock_ref, $ch, 1) < 1)
            {
                print ("$header!!\n");
                print (" ---> Unable to read a character\n");
                return "resend";
            }
            $header .= $ch;
            print ("Reading in at the moment - '$header'!!\n");
            #if ($header =~ m/alive\n\n/m)
            {
                my $h = $header;
                $h =~ s/(.)/",$1-" . ord ($1) . ";"/emg;
            }
        }
        $num_chars_read++;

    }

    print "\n++++++++++++++++++++++\n", $header, "\n";
    return $header;
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
    my $port = 33412;
    my $num_connections = 0;
    my $trusted_client;
    my $data_from_client;
    $|=1;
    read_all_cards;
    srand (time);

    print ("example: check_perl.pl\n");

    socket (SERVER, PF_INET, SOCK_STREAM, $proto) or die "Failed to create a socket: $!";
    setsockopt (SERVER, SOL_SOCKET, SO_REUSEADDR, 1) or die "setsocketopt: $!";

    # bind to a port, then listen
    bind (SERVER, sockaddr_in ($port, INADDR_ANY)) or die "Can't bind to port $port! \n";

    listen (SERVER, 10) or die "listen: $!";
    print ("Listening on port: $port\n");
    my $accept_fail_counter;
    my $count;
    my $not_seen_full = 1;

    my @ac = sort (keys (%all_cards));
    print ("========================\n");
    print ("Library comes from - \n");
    print ("gvim d:\/perl_programs\/all_magic_cards.txt\n");
    print ("Red Green Blue Black White  Text  Name name_chained (<=convertedcost)\n\n");

    while ($paddr = accept (CLIENT, SERVER))
    {
        print ("\n\nNEW============================================================\n");
        print ("New connection\n");

        $num_connections++;
        $accept_fail_counter = 0;
        unless ($paddr)
        {
            $accept_fail_counter++;

            if ($accept_fail_counter > 0)
            {
                #print "accept () has failedsockaddr_in $accept_fail_counter";
                next;
            }
        }

        print ("- - - - - - -\n");

        $accept_fail_counter = 0;
        ($client_port, $iaddr) = sockaddr_in ($paddr);
        $client_addr = inet_ntoa ($iaddr);
        print ("\n$client_addr\n");

        my $lat;
        my $long;
        my $txt = read_from_socket (\*CLIENT);

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

        print ("Read -> $txt\n");

        print ("2- - - - - - -\n");
        my $have_to_write_to_socket = 1;

        chomp ($txt);
        my $original_get = $txt;

        if ($original_get =~ m/all_sets/)
        {
            my $sets = get_sets ();
            write_to_socket (\*CLIENT, $sets, "", "noredirect");
            next;
        }

        if ($original_get =~ m/edh_filter_(.*)/)
        {
            my $edh_lands_filtered = edh_lands ($1);
            #my $edh_lands_filtered = edh_lands ();
            write_to_socket (\*CLIENT, $edh_lands_filtered, "", "noredirect");
            #sleep (10);
            next;
        }
        elsif ($original_get =~ m/edh_lands/)
        {
            my $edh_lands = edh_lands ();
            write_to_socket (\*CLIENT, $edh_lands, "", "noredirect");
            next;
        }
        
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

        my $use_red = $strs [2];
        my $use_green = $strs [3];
        my $use_blue = $strs [4];
        my $use_black = $strs [5];
        my $use_white = $strs [6];
        my $use_uncoloured = $strs [7];
        my $use_full_format = $strs [8];
        my $use_block = $strs [9];
        my $use_unique = $strs [10];

        my $card_text = $strs [11];
        my $card_name = $strs [12];
        my $community_rating = $strs [13];
        my $min_cmc = $strs [0];
        my $max_cmc = $strs [1];

        # Do a form with the check boxes checked etc..
        my $form = "";
        my $checked = "";
        $form = "<form action=\"\">";
        $form .= "Card name: <input id=cn type=\"text\" size=30 value=\"$card_name\"><br>";
        $form .= "Card text: <input id=ct type=\"text\" size=30 value=\"$card_text\"><br>";
        $form .= "Rating&nbsp;&nbsp;: <input id=cr type=\"text\" size=30 value=\"$community_rating\">";
        $form .= "<a onclick=\"javascript: document.getElementById('cr').value='[4]\..*';\">Great!</a>&nbsp;";
        $form .= "<a onclick=\"javascript: document.getElementById('cr').value='[34]\..*';\">OK</a>&nbsp;";
        $form .= "<a onclick=\"javascript: document.getElementById('cr').value='[1234]\..*';\">Sorted</a>&nbsp;";
        $form .= "<a onclick=\"javascript: document.getElementById('cr').value='.*';\">All</a><br>";
        $form .= "Min CMC&nbsp;: <input id=mc type=\"text\" size=15 value=\"$min_cmc\">";
        $form .= "Max CMC&nbsp;: <input id=mxc type=\"text\" size=15 value=\"$max_cmc\"><br>";

        $form .= "<input id=yw type=\"checkbox\" name=\"mustbewhite\" value=\"m_white\"" . do_checked ($use_white) . ">Must have white</input>";
        $form .= "<input id=nw type=\"checkbox\" name=\"cannotbewhite\" value=\"no_white\"" . no_checked ($use_white) . ">Can't have white</input><br>\n";
        $form .= "<input id=yu type=\"checkbox\" name=\"mustbeblue\" value=\"m_blue\"" . do_checked ($use_blue) . ">Must have blue&nbsp;</input>";
        $form .= "<input id=nu type=\"checkbox\" name=\"cannotbeblue\" value=\"no_blue\"" . no_checked ($use_blue) . ">Can't have blue</input><br>\n";
        $form .= "<input id=yb type=\"checkbox\" name=\"mustbeblack\" value=\"m_black\"" . do_checked ($use_black) . ">Must have black</input>";
        $form .= "<input id=nb type=\"checkbox\" name=\"cannotbeblack\" value=\"no_black\"" . no_checked ($use_black) . ">Can't have black</input><br>\n";
        $form .= "<input id=yr type=\"checkbox\" name=\"mustbered\" value=\"m_red\"" . do_checked ($use_red) . ">Must have red&nbsp;</input>";
        $form .= "<input id=nr type=\"checkbox\" name=\"cannotbered\" value=\"no_red\"" . no_checked ($use_red) . ">Can't have red</input><br>\n";
        $form .= "<input id=yg type=\"checkbox\" name=\"mustbegreen\" value=\"m_green\"" . do_checked ($use_green) . ">Must have green</input>";
        $form .= "<input id=ng type=\"checkbox\" name=\"cannotbegreen\" value=\"no_green\"" . no_checked ($use_green) . ">Can't have green</input><br>\n";
        $form .= "<input id=yuc type=\"checkbox\" name=\"mustbeuncoloured\" value=\"m_uncoloured\"" . do_checked ($use_uncoloured) . ">Must have uncoloured</input>";
        $form .= "<input id=nuc type=\"checkbox\" name=\"cannotbeuncoloured\" value=\"no_uncoloured\"" . no_checked ($use_uncoloured) . ">Can't have uncoloured</input><br>\n";
        $form .= "<input id=full_format type=\"checkbox\" name=\"full_format_only\" value=\"m_full_format\"" . do_checked ($use_full_format) . ">Full format</input>&nbsp;&nbsp;\n";
        $form .= "<input id=block type=\"checkbox\" name=\"blockonly\" value=\"m_block\"" . do_checked ($use_block) . ">Only use current block</input><br>\n";
        $form .= "<input id=uniquenames type=\"checkbox\" name=\"uniquenames\" value=\"m_block\"" . do_checked ($use_unique) . ">Unique names</input><br>\n";
        $form .= "<a onclick=\"javascript: var ct=document.getElementById('ct').value; var cn=document.getElementById('cn').value; var cr=document.getElementById('cr').value; var mc=document.getElementById('mc').value; var mxc=document.getElementById('mxc').value; var yg=document.getElementById('yg').checked; var ng=document.getElementById('ng').checked; var fg=0;if(yg==true&&ng==false){fg=2;}else if(yg==false&&ng==true){fg=1;} var yr=document.getElementById('yr').checked; var nr=document.getElementById('nr').checked; var fr=0;if(yr==true&&nr==false){fr=2;}else if(yr==false&&nr==true){fr=1;} var yu=document.getElementById('yu').checked; var nu=document.getElementById('nu').checked; var fu=0;if(yu==true&&nu==false){fu=2;}else if(yu==false&&nu==true){fu=1;} var yb=document.getElementById('yb').checked; var nb=document.getElementById('nb').checked; var fb=0;if(yb==true&&nb==false){fb=2;}else if(yb==false&&nb==true){fb=1;} var yw=document.getElementById('yw').checked; var nw=document.getElementById('nw').checked; var fw=0;if(yw==true&&nw==false){fw=2;}else if(yw==false&&nw==true){fw=1;} var yuc=document.getElementById('yuc').checked; var nuc=document.getElementById('nuc').checked; var fuc=0;if(yuc==true&&nuc==false){fuc=2;}else if(yuc==false&&nuc==true){fuc=1;} var std=document.getElementById('full_format').checked; var blk=document.getElementById('block').checked; var uniquenames=document.getElementById('uniquenames').checked; var full = location.protocol+'//'+location.hostname+(location.port ? ':'+location.port: ''); full = full+'/filter/filter?'+mc+'&'+mxc+'&'+fr+'&'+fg+'&'+fu+'&'+fb+'&'+fw+'&'+fuc+'&'+std+'&'+blk+'&'+uniquenames+'&'+ct+'&'+cn+'&'+cr; var resubmit=document.getElementById('resubmit'); resubmit.href=full;\"><font color=blue size=+2><u>Update the query (click here):</u></font></a>&nbsp;&nbsp;";
        my $x_card_name = $card_text;
        
        
        my $rand_letter = rand (10);
        print ("RANT was $rand_letter\n");

        #char a
        if ($rand_letter < 3) { $x_card_name =~ s/a/&#192;/img; }
        #elsif ($rand_letter > 7) { $x_card_name =~ s/a/&#7680;/img; }
        #char b
        $rand_letter = rand (10);
        print ("RANT was $rand_letter\n");
        if ($rand_letter < 3) { $x_card_name =~ s/b/&#946;/img; }
        elsif ($rand_letter > 7) { $x_card_name =~ s/b/&#384;/img; }
        #char c
        $rand_letter = rand (10);
        print ("RANT was $rand_letter\n");
        if ($rand_letter < 3) { $x_card_name =~ s/c/&#199;/img; }
        elsif ($rand_letter > 7) { $x_card_name =~ s/c/&#891;/img; }
        #char d
        $rand_letter = rand (10);
        print ("RANT was $rand_letter\n");
        if ($rand_letter < 3) { $x_card_name =~ s/d/&#270;/img; }
        elsif ($rand_letter > 7) { $x_card_name =~ s/d/&#270;/img; }
        #char e
        $rand_letter = rand (10);
        print ("RANT was $rand_letter\n");
        if ($rand_letter < 3) { $x_card_name =~ s/e/&#276;/img; }
        elsif ($rand_letter > 7) { $x_card_name =~ s/e/&#276;/img; }
        #char e
        $rand_letter = rand (10);
        print ("RANT was $rand_letter\n");
        if ($rand_letter < 3) { $x_card_name =~ s/f/&#131;/img; }
        elsif ($rand_letter > 7) { $x_card_name =~ s/f/&#131;/img; }
        #char f
        $rand_letter = rand (10);
        print ("RANT was $rand_letter\n");
        if ($rand_letter < 3) { $x_card_name =~ s/f/&#1171;/img; }
        elsif ($rand_letter > 7) { $x_card_name =~ s/f/&#1171;/img; }
        #char g
        $rand_letter = rand (10);
        print ("RANT was $rand_letter\n");
        if ($rand_letter < 3) { $x_card_name =~ s/g/&#485;/img; }
        elsif ($rand_letter > 7) { $x_card_name =~ s/g/&#42924;/img; }
        #char h
        $rand_letter = rand (10);
        print ("RANT was $rand_letter\n");
        if ($rand_letter < 3) { $x_card_name =~ s/h/&#614;/img; }
        elsif ($rand_letter > 7) { $x_card_name =~ s/h/&#615;/img; }
        #char i
        $rand_letter = rand (10);
        print ("RANT was $rand_letter\n");
        if ($rand_letter < 3) { $x_card_name =~ s/i/&#204;/img; }
        elsif ($rand_letter > 7) { $x_card_name =~ s/i/&#407;/img; }
        #char j
        $rand_letter = rand (10);
        print ("RANT was $rand_letter\n");
        if ($rand_letter < 3) { $x_card_name =~ s/j/&#4325;/img; }
        elsif ($rand_letter > 7) { $x_card_name =~ s/j/&#4325;/img; }
        #char k
        $rand_letter = rand (10);
        print ("RANT was $rand_letter\n");
        if ($rand_letter < 3) { $x_card_name =~ s/k/&#1036;/img; }
        elsif ($rand_letter > 7) { $x_card_name =~ s/k/&#1036;/img; }
        #char l
        $rand_letter = rand (10);
        print ("RANT was $rand_letter\n");
        if ($rand_letter < 3) { $x_card_name =~ s/l/&#8467;/img; }
        elsif ($rand_letter > 7) { $x_card_name =~ s/l/&#621;/img; }
        #char m
        $rand_letter = rand (10);
        print ("RANT was $rand_letter\n");
        if ($rand_letter < 3) { $x_card_name =~ s/m/&#653;/img; }
        elsif ($rand_letter > 7) { $x_card_name =~ s/m/&#625;/img; }
        #char n
        $rand_letter = rand (10);
        print ("RANT was $rand_letter\n");
        if ($rand_letter < 3) { $x_card_name =~ s/n/&#209;/img; }
        elsif ($rand_letter > 7) { $x_card_name =~ s/n/&#627;/img; }
        #char o
        $rand_letter = rand (10);
        print ("RANT was $rand_letter\n");
        if ($rand_letter < 3) { $x_card_name =~ s/o/&#210;/img; }
        elsif ($rand_letter > 7) { $x_card_name =~ s/o/&#248;/img; }
        #char p
        $rand_letter = rand (10);
        print ("RANT was $rand_letter\n");
        if ($rand_letter < 3) { $x_card_name =~ s/p/&#254;/img; }
        elsif ($rand_letter > 7) { $x_card_name =~ s/p/&#421;/img; }
        #char q
        $rand_letter = rand (10);
        print ("RANT was $rand_letter\n");
        if ($rand_letter < 3) { $x_card_name =~ s/q/&#493;/img; }
        elsif ($rand_letter > 7) { $x_card_name =~ s/q/&#493;/img; }
        #char r
        $rand_letter = rand (10);
        print ("RANT was $rand_letter\n");
        if ($rand_letter < 3) { $x_card_name =~ s/r/&#1103;/img; }
        elsif ($rand_letter > 7) { $x_card_name =~ s/r/&#7449;/img; }
        #char s
        $rand_letter = rand (10);
        print ("RANT was $rand_letter\n");
        if ($rand_letter < 3) { $x_card_name =~ s/s/&#575;/img; }
        elsif ($rand_letter > 7) { $x_card_name =~ s/s/&#642;/img; }
        #char t
        $rand_letter = rand (10);
        print ("RANT was $rand_letter\n");
        if ($rand_letter < 3) { $x_card_name =~ s/t/&#430;/img; }
        elsif ($rand_letter > 7) { $x_card_name =~ s/t/&#648;/img; }
        #char u
        $rand_letter = rand (10);
        print ("RANT was $rand_letter\n");
        if ($rand_letter < 3) { $x_card_name =~ s/u/&#217;/img; }
        elsif ($rand_letter > 7) { $x_card_name =~ s/u/&#650;/img; }
        #char v
        $rand_letter = rand (10);
        print ("RANT was $rand_letter\n");
        if ($rand_letter < 3) { $x_card_name =~ s/v/&#8730;/img; }
        elsif ($rand_letter > 7) { $x_card_name =~ s/v/&#651;/img; }
        #char w
        $rand_letter = rand (10);
        print ("RANT was $rand_letter\n");
        if ($rand_letter > 7) { $x_card_name =~ s/w/&#42934;/img; }
        elsif ($rand_letter < 3) { $x_card_name =~ s/w/&#936;/img; }
        #char x
        $rand_letter = rand (10);
        print ("RANT was $rand_letter\n");
        if ($rand_letter < 3) { $x_card_name =~ s/x/&#1078;/img; }
        elsif ($rand_letter > 7) { $x_card_name =~ s/x//img; }
        #char y
        $rand_letter = rand (10);
        print ("RANT was $rand_letter\n");
        if ($rand_letter < 3) { $x_card_name =~ s/y/&#221;/img; }
        elsif ($rand_letter > 7) { $x_card_name =~ s/y/&#221;/img; }
        #char z
        $rand_letter = rand (10);
        print ("RANT was $rand_letter\n");
        if ($rand_letter < 3) { $x_card_name =~ s/z/&#382;/img; }
        elsif ($rand_letter > 7) { $x_card_name =~ s/z/&#657;/img; }

        $x_card_name =~ s/%20/&nbsp;/img;
        # Weird font html text from: https://graphemica.com/%C5%BE#code

        $form .= "<p><br>$x_card_name<br></p>";

#        $form .= "&#000; -> 000 &#001; -> 001 &#002; -> 002 &#003; -> 003 &#004; -> 004 &#005; -> 005 &#006; -> 006 &#007; -> 007 &#008; -> 008<br> &#009; -> 009 &#010; -> 010 &#011; -> 011 &#012; -> 012 &#013; -> 013 &#014; -> 014 &#015; -> 015 &#016; -> 016 &#017; -> 017<br> &#018; -> 018 &#019; -> 019 &#020; -> 020 &#021; -> 021 &#022; -> 022 &#023; -> 023 &#024; -> 024";
#        $form .= "&#025; -> 025 &#026; -> 026<br> &#027; -> 027 &#028; -> 028 &#029; -> 029 &#030; -> 030 &#031; -> 031 &#032; -> 032 &#033; -> 033 &#034; -> 034 &#035; -> 035<br> &#036; -> 036 &#037; -> 037 &#038; -> 038 &#039; -> 039 &#040; -> 040 &#041; -> 041 &#042; -> 042 &#043; -> 043 &#044; -> 044<br> &#045; -> 045 &#046; -> 046 &#047; -> 047 &#048; -> 048 &#049; -> 049";
#        $form .= "&#050; -> 050 &#051; -> 051 &#052; -> 052 &#053; -> 053<br> &#054; -> 054 &#055; -> 055 &#056; -> 056 &#057; -> 057 &#058; -> 058 &#059; -> 059 &#060; -> 060 &#061; -> 061 &#062; -> 062<br> &#063; -> 063 &#064; -> 064 &#065; -> 065 &#066; -> 066 &#067; -> 067 &#068; -> 068 &#069; -> 069 &#070; -> 070 &#071; -> 071<br> &#072; -> 072 &#073; -> 073 &#074; -> 074";
#        $form .= "&#075; -> 075 &#076; -> 076 &#077; -> 077 &#078; -> 078 &#079; -> 079 &#080; -> 080<br> &#081; -> 081 &#082; -> 082 &#083; -> 083 &#084; -> 084 &#085; -> 085 &#086; -> 086 &#087; -> 087 &#088; -> 088 &#089; -> 089<br> &#090; -> 090 &#091; -> 091 &#092; -> 092 &#093; -> 093 &#094; -> 094 &#095; -> 095 &#096; -> 096 &#097; -> 097 &#098; -> 098<br> &#099; -> 099";
#        $form .= "&#100; -> 100 &#101; -> 101 &#102; -> 102 &#103; -> 103 &#104; -> 104 &#105; -> 105 &#106; -> 106 &#107; -> 107<br> &#108; -> 108 &#109; -> 109 &#110; -> 110 &#111; -> 111 &#112; -> 112 &#113; -> 113 &#114; -> 114 &#115; -> 115 &#116; -> 116<br> &#117; -> 117 &#118; -> 118 &#119; -> 119 &#120; -> 120 &#121; -> 121 &#122; -> 122 &#123; -> 123 &#124; -> 124";
#        $form .= "&#125; -> 125<br> &#126; -> 126 &#127; -> 127 &#128; -> 128 &#129; -> 129 &#130; -> 130 &#131; -> 131 &#132; -> 132 &#133; -> 133 &#134; -> 134<br> &#135; -> 135 &#136; -> 136 &#137; -> 137 &#138; -> 138 &#139; -> 139 &#140; -> 140 &#141; -> 141 &#142; -> 142 &#143; -> 143<br> &#144; -> 144 &#145; -> 145 &#146; -> 146 &#147; -> 147 &#148; -> 148 &#149; -> 149";
#        $form .= "&#150; -> 150 &#151; -> 151 &#152; -> 152<br> &#153; -> 153 &#154; -> 154 &#155; -> 155 &#156; -> 156 &#157; -> 157 &#158; -> 158 &#159; -> 159 &#160; -> 160 &#161; -> 161<br> &#162; -> 162 &#163; -> 163 &#164; -> 164 &#165; -> 165 &#166; -> 166 &#167; -> 167 &#168; -> 168 &#169; -> 169 &#170; -> 170<br> &#171; -> 171 &#172; -> 172 &#173; -> 173 &#174; -> 174";
#        $form .= "&#175; -> 175 &#176; -> 176 &#177; -> 177 &#178; -> 178 &#179; -> 179<br> &#180; -> 180 &#181; -> 181 &#182; -> 182 &#183; -> 183 &#184; -> 184 &#185; -> 185 &#186; -> 186 &#187; -> 187 &#188; -> 188<br> &#189; -> 189 &#190; -> 190 &#191; -> 191 &#192; -> 192 &#193; -> 193 &#194; -> 194 &#195; -> 195 &#196; -> 196 &#197; -> 197<br> &#198; -> 198 &#199; -> 199";
#        $form .= "&#200; -> 200 &#201; -> 201 &#202; -> 202 &#203; -> 203 &#204; -> 204 &#205; -> 205 &#206; -> 206<br> &#207; -> 207 &#208; -> 208 &#209; -> 209 &#210; -> 210 &#211; -> 211 &#212; -> 212 &#213; -> 213 &#214; -> 214 &#215; -> 215<br> &#216; -> 216 &#217; -> 217 &#218; -> 218 &#219; -> 219 &#220; -> 220 &#221; -> 221 &#222; -> 222 &#223; -> 223 &#224; -> 224<br>";
#        $form .= "&#225; -> 225 &#226; -> 226 &#227; -> 227 &#228; -> 228 &#229; -> 229 &#230; -> 230 &#231; -> 231 &#232; -> 232 &#233; -> 233<br> &#234; -> 234 &#235; -> 235 &#236; -> 236 &#237; -> 237 &#238; -> 238 &#239; -> 239 &#240; -> 240 &#241; -> 241 &#242; -> 242<br> &#243; -> 243 &#244; -> 244 &#245; -> 245 &#246; -> 246 &#247; -> 247 &#248; -> 248 &#249; -> 249";
#        $form .= "&#250; -> 250 &#251; -> 251<br> &#252; -> 252 &#253; -> 253 &#254; -> 254 &#255; -> 255 &#256; -> 256 &#257; -> 257 &#258; -> 258 &#259; -> 259 &#260; -> 260<br> &#261; -> 261 &#262; -> 262 &#263; -> 263 &#264; -> 264 &#265; -> 265 &#266; -> 266 &#267; -> 267 &#268; -> 268 &#269; -> 269<br> &#270; -> 270 &#271; -> 271 &#272; -> 272 &#273; -> 273 &#274; -> 274";
#        $form .= "&#275; -> 275 &#276; -> 276 &#277; -> 277 &#278; -> 278<br> &#279; -> 279 &#280; -> 280 &#281; -> 281 &#282; -> 282 &#283; -> 283 &#284; -> 284 &#285; -> 285 &#286; -> 286 &#287; -> 287<br> &#288; -> 288 &#289; -> 289 &#290; -> 290 &#291; -> 291 &#292; -> 292 &#293; -> 293 &#294; -> 294 &#295; -> 295 &#296; -> 296<br> &#297; -> 297 &#298; -> 298 &#299; -> 299";
#        $form .= "&#300; -> 300 &#301; -> 301 &#302; -> 302 &#303; -> 303 &#304; -> 304 &#305; -> 305<br> &#306; -> 306 &#307; -> 307 &#308; -> 308 &#309; -> 309 &#310; -> 310 &#311; -> 311 &#312; -> 312 &#313; -> 313 &#314; -> 314<br> &#315; -> 315 &#316; -> 316 &#317; -> 317 &#318; -> 318 &#319; -> 319 &#320; -> 320 &#321; -> 321 &#322; -> 322 &#323; -> 323<br> &#324; -> 324";
#        $form .= "&#325; -> 325 &#326; -> 326 &#327; -> 327 &#328; -> 328 &#329; -> 329 &#330; -> 330 &#331; -> 331 &#332; -> 332<br> &#333; -> 333 &#334; -> 334 &#335; -> 335 &#336; -> 336 &#337; -> 337 &#338; -> 338 &#339; -> 339 &#340; -> 340 &#341; -> 341<br> &#342; -> 342 &#343; -> 343 &#344; -> 344 &#345; -> 345 &#346; -> 346 &#347; -> 347 &#348; -> 348 &#349; -> 349";
#        $form .= "&#350; -> 350<br> &#351; -> 351 &#352; -> 352 &#353; -> 353 &#354; -> 354 &#355; -> 355 &#356; -> 356 &#357; -> 357 &#358; -> 358 &#359; -> 359<br> &#360; -> 360 &#361; -> 361 &#362; -> 362 &#363; -> 363 &#364; -> 364 &#365; -> 365 &#366; -> 366 &#367; -> 367 &#368; -> 368<br> &#369; -> 369 &#370; -> 370 &#371; -> 371 &#372; -> 372 &#373; -> 373 &#374; -> 374";
#        $form .= "&#375; -> 375 &#376; -> 376 &#377; -> 377<br> &#378; -> 378 &#379; -> 379 &#380; -> 380 &#381; -> 381 &#382; -> 382 &#383; -> 383 &#384; -> 384 &#385; -> 385 &#386; -> 386<br> &#387; -> 387 &#388; -> 388 &#389; -> 389 &#390; -> 390 &#391; -> 391 &#392; -> 392 &#393; -> 393 &#394; -> 394 &#395; -> 395<br> &#396; -> 396 &#397; -> 397 &#398; -> 398 &#399; -> 399";
#        $form .= "&#400; -> 400 &#401; -> 401 &#402; -> 402 &#403; -> 403 &#404; -> 404<br> &#405; -> 405 &#406; -> 406 &#407; -> 407 &#408; -> 408 &#409; -> 409 &#410; -> 410 &#411; -> 411 &#412; -> 412 &#413; -> 413<br> &#414; -> 414 &#415; -> 415 &#416; -> 416 &#417; -> 417 &#418; -> 418 &#419; -> 419 &#420; -> 420 &#421; -> 421 &#422; -> 422<br> &#423; -> 423 &#424; -> 424";
#        $form .= "&#425; -> 425 &#426; -> 426 &#427; -> 427 &#428; -> 428 &#429; -> 429 &#430; -> 430 &#431; -> 431<br> &#432; -> 432 &#433; -> 433 &#434; -> 434 &#435; -> 435 &#436; -> 436 &#437; -> 437 &#438; -> 438 &#439; -> 439 &#440; -> 440<br> &#441; -> 441 &#442; -> 442 &#443; -> 443 &#444; -> 444 &#445; -> 445 &#446; -> 446 &#447; -> 447 &#448; -> 448 &#449; -> 449<br>";
#        $form .= "&#450; -> 450 &#451; -> 451 &#452; -> 452 &#453; -> 453 &#454; -> 454 &#455; -> 455 &#456; -> 456 &#457; -> 457 &#458; -> 458<br> &#459; -> 459 &#460; -> 460 &#461; -> 461 &#462; -> 462 &#463; -> 463 &#464; -> 464 &#465; -> 465 &#466; -> 466 &#467; -> 467<br> &#468; -> 468 &#469; -> 469 &#470; -> 470 &#471; -> 471 &#472; -> 472 &#473; -> 473 &#474; -> 474";
#        $form .= "&#475; -> 475 &#476; -> 476<br> &#477; -> 477 &#478; -> 478 &#479; -> 479 &#480; -> 480 &#481; -> 481 &#482; -> 482 &#483; -> 483 &#484; -> 484 &#485; -> 485<br> &#486; -> 486 &#487; -> 487 &#488; -> 488 &#489; -> 489 &#490; -> 490 &#491; -> 491 &#492; -> 492 &#493; -> 493 &#494; -> 494<br> &#495; -> 495 &#496; -> 496 &#497; -> 497 &#498; -> 498 &#499; -> 499";
#        $form .= "&#500; -> 500 &#501; -> 501 &#502; -> 502 &#503; -> 503<br> &#504; -> 504 &#505; -> 505 &#506; -> 506 &#507; -> 507 &#508; -> 508 &#509; -> 509 &#510; -> 510 &#511; -> 511 &#512; -> 512<br> &#513; -> 513 &#514; -> 514 &#515; -> 515 &#516; -> 516 &#517; -> 517 &#518; -> 518 &#519; -> 519 &#520; -> 520 &#521; -> 521<br> &#522; -> 522 &#523; -> 523 &#524; -> 524";
#        $form .= "&#525; -> 525 &#526; -> 526 &#527; -> 527 &#528; -> 528 &#529; -> 529 &#530; -> 530<br> &#531; -> 531 &#532; -> 532 &#533; -> 533 &#534; -> 534 &#535; -> 535 &#536; -> 536 &#537; -> 537 &#538; -> 538 &#539; -> 539<br> &#540; -> 540 &#541; -> 541 &#542; -> 542 &#543; -> 543 &#544; -> 544 &#545; -> 545 &#546; -> 546 &#547; -> 547 &#548; -> 548<br> &#549; -> 549";
#        $form .= "&#550; -> 550 &#551; -> 551 &#552; -> 552 &#553; -> 553 &#554; -> 554 &#555; -> 555 &#556; -> 556 &#557; -> 557<br> &#558; -> 558 &#559; -> 559 &#560; -> 560 &#561; -> 561 &#562; -> 562 &#563; -> 563 &#564; -> 564 &#565; -> 565 &#566; -> 566<br> &#567; -> 567 &#568; -> 568 &#569; -> 569 &#570; -> 570 &#571; -> 571 &#572; -> 572 &#573; -> 573 &#574; -> 574";
#        $form .= "&#575; -> 575<br> &#576; -> 576 &#577; -> 577 &#578; -> 578 &#579; -> 579 &#580; -> 580 &#581; -> 581 &#582; -> 582 &#583; -> 583 &#584; -> 584<br> &#585; -> 585 &#586; -> 586 &#587; -> 587 &#588; -> 588 &#589; -> 589 &#590; -> 590 &#591; -> 591 &#592; -> 592 &#593; -> 593<br> &#594; -> 594 &#595; -> 595 &#596; -> 596 &#597; -> 597 &#598; -> 598 &#599; -> 599";
#        $form .= "&#600; -> 600 &#601; -> 601 &#602; -> 602<br> &#603; -> 603 &#604; -> 604 &#605; -> 605 &#606; -> 606 &#607; -> 607 &#608; -> 608 &#609; -> 609 &#610; -> 610 &#611; -> 611<br> &#612; -> 612 &#613; -> 613 &#614; -> 614 &#615; -> 615 &#616; -> 616 &#617; -> 617 &#618; -> 618 &#619; -> 619 &#620; -> 620<br> &#621; -> 621 &#622; -> 622 &#623; -> 623 &#624; -> 624";
#        $form .= "&#625; -> 625 &#626; -> 626 &#627; -> 627 &#628; -> 628 &#629; -> 629<br> &#630; -> 630 &#631; -> 631 &#632; -> 632 &#633; -> 633 &#634; -> 634 &#635; -> 635 &#636; -> 636 &#637; -> 637 &#638; -> 638<br> &#639; -> 639 &#640; -> 640 &#641; -> 641 &#642; -> 642 &#643; -> 643 &#644; -> 644 &#645; -> 645 &#646; -> 646 &#647; -> 647<br> &#648; -> 648 &#649; -> 649";
#        $form .= "&#650; -> 650 &#651; -> 651 &#652; -> 652 &#653; -> 653 &#654; -> 654 &#655; -> 655 &#656; -> 656<br> &#657; -> 657 &#658; -> 658 &#659; -> 659 &#660; -> 660 &#661; -> 661 &#662; -> 662 &#663; -> 663 &#664; -> 664 &#665; -> 665<br> &#666; -> 666 &#667; -> 667 &#668; -> 668 &#669; -> 669 &#670; -> 670 &#671; -> 671 &#672; -> 672 &#673; -> 673 &#674; -> 674<br>";
#        $form .= "&#675; -> 675 &#676; -> 676 &#677; -> 677 &#678; -> 678 &#679; -> 679 &#680; -> 680 &#681; -> 681 &#682; -> 682 &#683; -> 683<br> &#684; -> 684 &#685; -> 685 &#686; -> 686 &#687; -> 687 &#688; -> 688 &#689; -> 689 &#690; -> 690 &#691; -> 691 &#692; -> 692<br> &#693; -> 693 &#694; -> 694 &#695; -> 695 &#696; -> 696 &#697; -> 697 &#698; -> 698 &#699; -> 699";
#        $form .= "&#700; -> 700 &#701; -> 701<br> &#702; -> 702 &#703; -> 703 &#704; -> 704 &#705; -> 705 &#706; -> 706 &#707; -> 707 &#708; -> 708 &#709; -> 709 &#710; -> 710<br> &#711; -> 711 &#712; -> 712 &#713; -> 713 &#714; -> 714 &#715; -> 715 &#716; -> 716 &#717; -> 717 &#718; -> 718 &#719; -> 719<br> &#720; -> 720 &#721; -> 721 &#722; -> 722 &#723; -> 723 &#724; -> 724";
#        $form .= "&#725; -> 725 &#726; -> 726 &#727; -> 727 &#728; -> 728<br> &#729; -> 729 &#730; -> 730 &#731; -> 731 &#732; -> 732 &#733; -> 733 &#734; -> 734 &#735; -> 735 &#736; -> 736 &#737; -> 737<br> &#738; -> 738 &#739; -> 739 &#740; -> 740 &#741; -> 741 &#742; -> 742 &#743; -> 743 &#744; -> 744 &#745; -> 745 &#746; -> 746<br> &#747; -> 747 &#748; -> 748 &#749; -> 749";
#        $form .= "&#750; -> 750 &#751; -> 751 &#752; -> 752 &#753; -> 753 &#754; -> 754 &#755; -> 755<br> &#756; -> 756 &#757; -> 757 &#758; -> 758 &#759; -> 759 &#760; -> 760 &#761; -> 761 &#762; -> 762 &#763; -> 763 &#764; -> 764<br> &#765; -> 765 &#766; -> 766 &#767; -> 767 &#768; -> 768 &#769; -> 769 &#770; -> 770 &#771; -> 771 &#772; -> 772 &#773; -> 773<br> &#774; -> 774";
#        $form .= "&#775; -> 775 &#776; -> 776 &#777; -> 777 &#778; -> 778 &#779; -> 779 &#780; -> 780 &#781; -> 781 &#782; -> 782<br> &#783; -> 783 &#784; -> 784 &#785; -> 785 &#786; -> 786 &#787; -> 787 &#788; -> 788 &#789; -> 789 &#790; -> 790 &#791; -> 791<br> &#792; -> 792 &#793; -> 793 &#794; -> 794 &#795; -> 795 &#796; -> 796 &#797; -> 797 &#798; -> 798 &#799; -> 799";
#        $form .= "&#800; -> 800<br> &#801; -> 801 &#802; -> 802 &#803; -> 803 &#804; -> 804 &#805; -> 805 &#806; -> 806 &#807; -> 807 &#808; -> 808 &#809; -> 809<br> &#810; -> 810 &#811; -> 811 &#812; -> 812 &#813; -> 813 &#814; -> 814 &#815; -> 815 &#816; -> 816 &#817; -> 817 &#818; -> 818<br> &#819; -> 819 &#820; -> 820 &#821; -> 821 &#822; -> 822 &#823; -> 823 &#824; -> 824";
#        $form .= "&#825; -> 825 &#826; -> 826 &#827; -> 827<br> &#828; -> 828 &#829; -> 829 &#830; -> 830 &#831; -> 831 &#832; -> 832 &#833; -> 833 &#834; -> 834 &#835; -> 835 &#836; -> 836<br> &#837; -> 837 &#838; -> 838 &#839; -> 839 &#840; -> 840 &#841; -> 841 &#842; -> 842 &#843; -> 843 &#844; -> 844 &#845; -> 845<br> &#846; -> 846 &#847; -> 847 &#848; -> 848 &#849; -> 849";
#        $form .= "&#850; -> 850 &#851; -> 851 &#852; -> 852 &#853; -> 853 &#854; -> 854<br> &#855; -> 855 &#856; -> 856 &#857; -> 857 &#858; -> 858 &#859; -> 859 &#860; -> 860 &#861; -> 861 &#862; -> 862 &#863; -> 863<br> &#864; -> 864 &#865; -> 865 &#866; -> 866 &#867; -> 867 &#868; -> 868 &#869; -> 869 &#870; -> 870 &#871; -> 871 &#872; -> 872<br> &#873; -> 873 &#874; -> 874";
#        $form .= "&#875; -> 875 &#876; -> 876 &#877; -> 877 &#878; -> 878 &#879; -> 879 &#880; -> 880 &#881; -> 881<br> &#882; -> 882 &#883; -> 883 &#884; -> 884 &#885; -> 885 &#886; -> 886 &#887; -> 887 &#888; -> 888 &#889; -> 889 &#890; -> 890<br> &#891; -> 891 &#892; -> 892 &#893; -> 893 &#894; -> 894 &#895; -> 895 &#896; -> 896 &#897; -> 897 &#898; -> 898 &#899; -> 899<br>";
#        $form .= "&#900; -> 900 &#901; -> 901 &#902; -> 902 &#903; -> 903 &#904; -> 904 &#905; -> 905 &#906; -> 906 &#907; -> 907 &#908; -> 908<br> &#909; -> 909 &#910; -> 910 &#911; -> 911 &#912; -> 912 &#913; -> 913 &#914; -> 914 &#915; -> 915 &#916; -> 916 &#917; -> 917<br> &#918; -> 918 &#919; -> 919 &#920; -> 920 &#921; -> 921 &#922; -> 922 &#923; -> 923 &#924; -> 924";
#        $form .= "&#925; -> 925 &#926; -> 926<br> &#927; -> 927 &#928; -> 928 &#929; -> 929 &#930; -> 930 &#931; -> 931 &#932; -> 932 &#933; -> 933 &#934; -> 934 &#935; -> 935<br> &#936; -> 936 &#937; -> 937 &#938; -> 938 &#939; -> 939 &#940; -> 940 &#941; -> 941 &#942; -> 942 &#943; -> 943 &#944; -> 944<br> &#945; -> 945 &#946; -> 946 &#947; -> 947 &#948; -> 948 &#949; -> 949";
#        $form .= "&#950; -> 950 &#951; -> 951 &#952; -> 952 &#953; -> 953<br> &#954; -> 954 &#955; -> 955 &#956; -> 956 &#957; -> 957 &#958; -> 958 &#959; -> 959 &#960; -> 960 &#961; -> 961 &#962; -> 962<br> &#963; -> 963 &#964; -> 964 &#965; -> 965 &#966; -> 966 &#967; -> 967 &#968; -> 968 &#969; -> 969 &#970; -> 970 &#971; -> 971<br> &#972; -> 972 &#973; -> 973 &#974; -> 974";
#        $form .= "&#975; -> 975 &#976; -> 976 &#977; -> 977 &#978; -> 978 &#979; -> 979 &#980; -> 980<br> &#981; -> 981<br> &#982; -> 982<br> &#983; -> 983<br> &#984; -> 984<br> &#985; -> 985<br> &#986; -> 986<br> &#987; -> 987<br> &#988; -> 988<br> &#989; -> 989<br> &#990; -> 990<br> &#991; -> 991<br> &#992; -> 992<br> &#993; -> 993<br> &#994; -> 994<br> &#995; -> 995<br> &#996; -> 996<br> &#997; -> 997<br> &#998; -> 998<br> &#999; -> 999<br>";

        $form .= "<a id=\"resubmit\" href=\"$min_cmc&$max_cmc&$use_red&$use_green&$use_blue&$use_black&$use_white&$use_uncoloured&$use_full_format&$use_block&$use_unique&$card_text&$community_rating\">Resubmit</a><br>";
        $form .= "</form>";

        {
            print ("calling = get_filtered_cards_advanced (\@ac, $min_cmc, $max_cmc, $use_red, $use_green, $use_blue, $use_black, $use_white, $use_uncoloured, $use_full_format, $use_block, $use_unique, $card_text, $card_name, $community_rating);\n");
            my $txt = get_filtered_cards_advanced (\@ac, $min_cmc, $max_cmc, $use_red, $use_green, $use_blue, $use_black, $use_white, $use_uncoloured, $use_full_format, $use_block, $use_unique, $card_text, $card_name, $community_rating);
            $txt =~ s/\n\n/\n/gim;
            $txt =~ s/\n\n/\n/gim;
            my $copy = $txt;
            if (!($use_full_format eq "true"))
            {
                #$txt =~ s/^([^\|]*)\|([^\|]*)\|([^\|]*)\|([^\|]*)\|([^\|]*)\|([^\|]*)\|.*/1 $1 xx $2<br>/gim; #<< for entering rares one..
                $txt =~ s/^([^\|]*)\|([^\|]*)\|([^\|]*)\|([^\|]*)\|([^\|]*)\|([^\|]*)\|.*/1 $1<br>/gim; #<< for entering rares one..
                $txt =~ s/xx.*\[/[/gim;
            }
            else
            {
                $txt =~ s/$/<br>/gim; #<< for entering rares one..
            }

            my $set = '<a href="http://gatherer.wizards.com/Pages/Search/Default.aspx?output=compact&sort=rating-&action=advanced&set=|[%22Dragons%20of%20Tarkir%22]"> All </a> &nbsp;' .
                '<a href="http://gatherer.wizards.com/Pages/Search/Default.aspx?output=compact&sort=rating-&action=advanced&set=|[%22Dragons%20of%20Tarkir%22]&color=%20[C]"> Colourless </a> &nbsp;<br>' .
                '<a href="https://scryfall.com/search?q=oracle:/' . $card_text . '/">Scryfall text</a><br>' .
                '<a href="https://scryfall.com/search?q=name:/' . $card_name . '/">Scryfall name</a><br>' .
                '<a href="https://scryfall.com/search?q=oracle:/' . $card_text . '/ name:/' . $card_name . '/">Scryfall both name/text</a><br>';

            $txt = "<style>p.a{font-family:\"Courier New\", Times, serif;}</style><font color=blue size=+3>MAGIC CARDS </font><font color=green size=+1><a href='http://127.0.0.1:60001/blah'>Deck input </a></font>&nbsp;&nbsp;<font color=red size=+1><a href='http://127.0.0.1:60000/dragons.*tarkir&dragons.*tarkir&fate.*reforged&8&1&1'>Draft (DTK,DTK,FRF)</a></font><br>$form<br>Example <a href='/filter/filter?0&89&0&0&0&0&0&0&false&false&false&dragons.*tarkir&.*&.*'>DTK</a>&nbsp;&nbsp; Example <a href='/filter/filter?0&89&0&0&0&0&0&0&false&false&false&dragons.*tarkir.*rare&.*&.*'>DTK (Rare)</a><br>Example <a href='/filter/filter?0&89&0&0&0&0&0&0&false&false&false&Fate.*Reforged&.*&.*'>FRF</a>&nbsp;&nbsp; Example <a href='/filter/filter?0&89&0&0&0&0&0&0&false&false&false&Fate.*Reforged.*rare&.*&.*'>FRF (Rare)</a> <br> Only planeswalkers: <a href='/filter/filter?0&89&0&0&0&0&0&0&false&false&false&.*types.*planeswalker.*cardtext.*&.*&[1234]..*'>Planewalkers</a> <br> View by expansion set: <a href='all_sets'>See the sets</a></br> <br> View EDH lands: <a href='edh_lands'>See EDH lands</a><br> View non red EDH lands: <a href='edh_filter_notr_notw_notg'>See EDH lands</a><br> $set <br> <p class=\"a\">$txt</p>";
            $txt = $txt . " $set";
            #Example <a href='filter?3&8&1&2&1&1&1&0&creature&nacatl&.*'>Green cool search</a> <br>



            write_to_socket (\*CLIENT, $txt, "", "noredirect");
            $have_to_write_to_socket = 0;
            #close CLIENT;
        }

        print ("============================================================\n");
    }
}
