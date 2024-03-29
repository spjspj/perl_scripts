#!/usr/bin/perl
##
#   File : secure_copy_paste.pl
#   Date : 19/Sept/2023
#   Author : spjspj
#   Purpose : Allow a copy and paste to happen
##

use strict;
use POSIX;
use LWP::Simple;
use Socket;
use File::Copy;
use Math::Trig;

my %secure_paste;
my $pasted_text = "HELLO!  You can change me now!";
my %all_pasted_text;
my %meta_data;
my %calculated_data;
my %col_roundings;
my $max_field_num = 0;
my $max_rows = 0;
my %col_types;
my $show_formulas = 0;
my $count = 0;
my %each_element;
my $each_element_count = 0;

my $SUPPLIED_KEYWORD;

sub write_to_socket
{
    my $sock_ref = $_ [0];
    my $msg_body = $_ [1];
    my $form = $_ [2];
    my $redirect = $_ [3];
    my $is_admin_session = $_ [4];
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    my $yyyymmddhhmmss = sprintf "%.4d%.2d%.2d-%.2d%.2d%.2d", $year+1900, $mon+1, $mday, $hour,  $min, $sec;
    print $yyyymmddhhmmss, "\n";

    $msg_body = $msg_body;

    my $admin_cookie;
    if ($is_admin_session)
    {
        $admin_cookie = "Set-Cookie: ADMIN_SESSION=1\n";
    }

    my $header;
    if ($redirect =~ m/^redirect/i)
    {
        $header = "HTTP/1.1 301 Moved\nLocation: /secure_paste/\nLast-Modified: $yyyymmddhhmmss\nConnection: close\nContent-Type: text/html; charset=UTF-8\nContent-Length: " . length ($msg_body) . "\n\n";
    }
    elsif ($redirect =~ m/^noredirect/i)
    {
        if ($SUPPLIED_KEYWORD =~ m/^$/)
        {
            $header = "HTTP/1.1 200 OK\nLast-Modified: $yyyymmddhhmmss\nConnection: close\nContent-Type: text/html; charset=UTF-8\nContent-Length: " . length ($msg_body) . "\n\n";
        }
        else
        {
            $header = "HTTP/1.1 200 OK\nLast-Modified: $yyyymmddhhmmss\nConnection: close\nContent-Type: text/html\nSet-Cookie: SUPPLIED_KEYWORD=$SUPPLIED_KEYWORD\n" . $admin_cookie . "Content-Length: " . length ($msg_body) . "\n\n";
        }
    }

    $msg_body =~ s/\n\n/\n/mig;
    $msg_body =~ s/\n\n/\n/mig;
    $msg_body =~ s/\n\n/\n/mig;
    $msg_body = $header . $msg_body;
    $msg_body =~ s/\.png/\.npg/;
    $msg_body =~ s/img/mgi/;
    $msg_body .= chr(13) . chr(10) . "0";
    print ("\n===========\nWrite to socket: ", length($msg_body), " characters!\n==========\n");
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
    my $seen_content_len = -2;
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

        if ($seen_content_len >= -1)
        {
            $seen_content_len ++;
            $content .= $ch;
        }
        if (ord ($ch) == 13 and ord ($prev_ch) == 10)
        {
            $seen_content_len = -1;
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

sub has_valid_keyword
{
    my $pw = $_ [0];
    print ("\npw = $pw\n");
    if ($pw =~ m/^......*/)
    {
        # Check that the other programs are running..
        return 1;
    }
   return 0;
}

sub get_admin_session
{
    my $pw = $_ [0];
    if ($pw =~ m/spjwashere/img)
    {
        return 1;
    }
    if ($pw =~ m/ADMIN_SESSION/img)
    {
        return 1;
    }
   return 0;
}

sub fix_url_code
{
    my $txt = $_ [0];
    $txt =~ s/\+/ /g;
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
    my $port = 6725;
    my $trusted_client;
    my $data_from_client;
    my $html_text = "";
    my $is_admin_session;
    $|=1;

    socket (SERVER, PF_INET, SOCK_STREAM, $proto) or die "Failed to create a socket: $!";
    setsockopt (SERVER, SOL_SOCKET, SO_REUSEADDR, 1) or die "setsocketopt: $!";

    # bind to a port, then listen
    bind (SERVER, sockaddr_in ($port, INADDR_ANY)) or die "Can't bind to port $port! \n";

    listen (SERVER, 10) or die "listen: $!";
    print ("Listening on port: $port\n");
    my $count;
    my $not_seen_full = 1;
    my $html_text = "";

    while ($paddr = accept (CLIENT, SERVER))
    {
        print ("\n\nNEW============================================================\n");
        print ("New connection\n");
        ($client_port, $iaddr) = sockaddr_in ($paddr);
        $client_addr = inet_ntoa ($iaddr);
        print ("\n$client_addr\n");

        my $txt = read_from_socket (\*CLIENT);
        print ("Raw data was $txt\n");
        $txt =~ s/secure_paste\/secure_paste/secure_paste\//img;
        $txt =~ s/secure_paste\/secure_paste/secure_paste\//img;
        $txt =~ s/secure_paste\/secure_paste/secure_paste\//img;

        $SUPPLIED_KEYWORD = "";
        if ($txt =~ m/^Cookie.*?SUPPLIED_KEYWORD=(\w\w\w[\w_\.\d-]+).*?(;|$)/im)
        {
            $SUPPLIED_KEYWORD = $1;
        }

        $is_admin_session = get_admin_session ($txt);

        print ("\n0pw = $SUPPLIED_KEYWORD\n");
        my $old_valid_keyword = has_valid_keyword ($SUPPLIED_KEYWORD);
        print ("\n1pw = $SUPPLIED_KEYWORD\n");
        my $valid_keyword = has_valid_keyword ($SUPPLIED_KEYWORD);


        if ($txt =~ m/keyword=(\w\w\w[\w_\.\d-]+) HTTP/im)
        {
            $SUPPLIED_KEYWORD = $1;
            print ("\n2pw = $SUPPLIED_KEYWORD\n");
            $valid_keyword = has_valid_keyword ($SUPPLIED_KEYWORD);
            $SUPPLIED_KEYWORD = $1;
        }

        if ($old_valid_keyword > $valid_keyword)
        {
            $valid_keyword = $old_valid_keyword;
        }

        if ($valid_keyword == 0)
        {
            $html_text = "<font color=red>Supply keyword here:</font><br><br>";
            $html_text .= "
                <form action=\"/secure_paste/keyword\">
                <label for=\"keyword\">Keyword:</label><br>
                <input type=\"text\" id=\"keyword\" name=\"keyword\" value=\"xyzabc\"><br>
                <input type=\"submit\" value=\"Supply keyword to proceed\">
                </form><br>You supplied: $SUPPLIED_KEYWORD<br>";
            $SUPPLIED_KEYWORD = "";
            write_to_socket (\*CLIENT, $html_text, "", "noredirect", $is_admin_session);
            next;
        }

        $txt =~ m/GET (.*) HTTP/;
        my $original_url = $1;

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

        print ("Dealing with >>>$txt<<<\n");

        if ($is_admin_session == 1 && $txt =~ m/GET.*show_history.*/m)
        {
            $txt =~ m/(........show_examples.......)/im;
            
            my $html_text = "<html> <head> <META HTTP-EQUIV=\"CACHE-CONTROL\" CONTENT=\"NO-CACHE\"> <br> <META HTTP-EQUIV=\"EXPIRES\" CONTENT=\"Mon, 22 Jul 2094 11:12:01 GMT\"> </head> <body> <h1>Previous CSVs</h1> <br>";
            my $listing = `dir /a /b /s d:\\perl_programs\\secure_paste\\*.txt`;
            $listing =~ s/d:\\.*\\//img;
            print ("Found >>> $listing\n");
            $listing =~ s/(.*?)\n/<a href="\/secure_paste\/old_paste?$1">$1<\/a><br>\n/img;
            $html_text .= "$listing </body> </html>";
            write_to_socket (\*CLIENT, $html_text, "", "noredirect", $is_admin_session);
            next;
        }

        if ($is_admin_session == 1 && $txt =~ m/GET.*old_paste.(.*)/i)
        {
            my $file = $1;
            $file =~ s/ HTTP.*//;
            $file =~ s/\n//img;
            $file =~ s/^.*old_paste.PASTE/PASTE/;
            print ("Going to look at... d:\\perl_programs\\secure_paste\\$file\n");
            my $old_paste = `type d:\\perl_programs\\secure_paste\\$file`;
            print ("Adding it under: $file\n");
            $all_pasted_text{$file} = fix_url_code ($old_paste);
        }

        if ($txt =~ m/GET/m)
        {
            $txt =~ m/(........secure_paste.......)/im;
            my $matching_text = $1;
            my $pasted_txt = $all_pasted_text {$SUPPLIED_KEYWORD};

            if (length ($pasted_txt) == 0)
            {
                $pasted_txt .= "<font color=red>NB: Nothing pasted as yet for $SUPPLIED_KEYWORD</font>";
            }
            
            my $html_text = "<html> <head> <META HTTP-EQUIV=\"CACHE-CONTROL\" CONTENT=\"NO-CACHE\"> <br> <META HTTP-EQUIV=\"EXPIRES\" CONTENT=\"Mon, 22 Jul 2094 11:12:01 GMT\"> </head> <body> <h1>Copy Paste</h1> <br>";
            if ($is_admin_session == 1)
            {
                $html_text .= "<form action=\"updated_paste\" id=\"newpaste\" name=\"newpaste\" method=\"post\"> <textarea id=\"newpaste\" class=\"text\" cols=\"86\" rows =\"20\" form=\"newpaste\" name=\"newpaste\">$all_pasted_text{$SUPPLIED_KEYWORD}</textarea> <input type=\"submit\" value=\"Create New Paste\" class=\"submitButton\"></form>";
                my $k;
                foreach $k (sort (keys (%all_pasted_text)))
                {
                    $html_text .= "<br>&nbsp;See paste here: <a href='/secure_paste/keyword?keyword=$k'>$k (" . length ($all_pasted_text {$k}). ")</a>";
                }
                $html_text .= "<br>&nbsp;<a href=\"/secure_paste/show_history\">History</a><br>";
            }
            $html_text .= "<br>Current paste for '$SUPPLIED_KEYWORD':<br><pre>$pasted_txt</pre><br>View Example here: <a href='/secure_paste/keyword?keyword=examplePaste'>examplePaste</a></body></html>";
            
            write_to_socket (\*CLIENT, $html_text, "", "noredirect", $is_admin_session);
            next;
        }
        
        if ($txt =~ m/POST.*updated_paste.*/i)
        {
            my $secure_paste = $txt;
            my $new_paste = "";
            my $discard_header = 1;

            while ($secure_paste =~ s/^(.*?)(\n|$)//im && $discard_header >= 0)
            {
                my $line = $1;
                if ($line =~ m/^$/ || $line =~ m/^
$/)
                {
                    $discard_header --;
                }

                if (!$discard_header)
                {
                    $new_paste .= "$line\n";
                }
            }

            $new_paste =~ s/^
$//img;
            $new_paste =~ s/^\n$//img;
            $new_paste =~ s/^\n$//img;
            $new_paste =~ s/^.*newpaste=//img;
            $new_paste =~ s/%0D%0A/<br>/img;
            $all_pasted_text{$SUPPLIED_KEYWORD} = fix_url_code ($new_paste);

            if ($is_admin_session == 1)
            {
                my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
                my $yyyymmddhhmmss = sprintf "%.4d%.2d%.2d-%.2d%.2d%.2d", $year+1900, $mon+1, $mday, $hour,  $min, $sec;
                print ("> d:\\perl_programs\\secure_paste\\PASTE_$SUPPLIED_KEYWORD.$yyyymmddhhmmss.txt");
                open PASTE_FILE, ("> d:\\perl_programs\\secure_paste\\PASTE_$SUPPLIED_KEYWORD.$yyyymmddhhmmss.txt");
                print PASTE_FILE fix_url_code ($new_paste);
                close PASTE_FILE;
            }

            my $pasted_txt = $all_pasted_text {$SUPPLIED_KEYWORD};
            if (length ($pasted_txt) == 0)
            {
                $pasted_txt = "<font color=red>NB: Nothing pasted as yet for $SUPPLIED_KEYWORD</font>";
            }

            my $html_text = "<html> <head> <META HTTP-EQUIV=\"CACHE-CONTROL\" CONTENT=\"NO-CACHE\"> <br> <META HTTP-EQUIV=\"EXPIRES\" CONTENT=\"Mon, 22 Jul 2094 11:12:01 GMT\"> </head> <body><h1>Copy Paste</h1> <br>";

            if ($is_admin_session == 1)
            {
                $html_text .= "<form action=\"updated_paste\" id=\"newpaste\" name=\"newpaste\" method=\"post\"> <textarea id=\"newpaste\" class=\"text\" cols=\"86\" rows =\"20\" form=\"newpaste\" name=\"newpaste\">$all_pasted_text{$SUPPLIED_KEYWORD}</textarea> <input type=\"submit\" value=\"Create New Paste\" class=\"submitButton\"></form>";
                my $k;
                foreach $k (sort (keys (%all_pasted_text)))
                {
                    $html_text .= "<br>&nbsp;See paste here: <a href='/secure_paste/keyword?keyword=$k'>$k (" . length ($all_pasted_text {$k}). ")</a>";
                }
                $html_text .= "<br>&nbsp;<a href=\"/secure_paste/show_history\">History</a><br>";
            }

            $html_text .= "<br>Current pasted text for '$SUPPLIED_KEYWORD':<br><pre>$pasted_txt</pre><br>View Example here: <a href='/secure_paste/keyword?keyword=examplePaste'>examplePaste</a></body></html>";
            write_to_socket (\*CLIENT, $html_text, "", "noredirect", $is_admin_session);
            next;
        }

        write_to_socket (\*CLIENT, $html_text, "", "noredirect", $is_admin_session);
        print ("============================================================\n");
    }
}
