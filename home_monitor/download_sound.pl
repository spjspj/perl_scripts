#!/usr/bin/perl
##
#   File : download_sound.pl
#   Date : 25/Dec/2022
#   Author : spjspj
#   Purpose : Search for particular files and download..
##

use strict;
use POSIX;
use LWP::Simple;
use Socket;
use File::Copy;
use MIME::Base64 qw(encode_base64url decode_base64url);
use Digest::MD5 qw(md5 md5_hex md5_base64);

my %all_cards;
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

    $msg_body = '<html><head><META HTTP-EQUIV="CACHE-CONTROL" CONTENT="NO-CACHE"><br><META HTTP-EQUIV="EXPIRES" CONTENT="Mon, 22 Jul 2094 11:12:01 GMT"></head><body>' . $form . $msg_body . "<body></html>";

    my $header;
    if ($redirect =~ m/^redirect(\d)/i)
    {
        $header = "HTTP/1.1 301 Moved\nLocation: /full$1\nLast-Modified: $yyyymmddhhmmss\nConnection: close\nContent-Type: text/html; charset=UTF-8\nContent-Length: " . length ($msg_body) . "\n\n";
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

sub copy_file_to_socket
{
    my $sock_ref = $_ [0];
    my $img = $_ [1];
    my $buffer;
    my $size = 0;
    $img =~ s/ //img;
    $img =~ m/(\/home_monitor.*wav)/;
    my $real_img = $1;
    chomp $real_img;
    print ("Looking at: $real_img\n");

    my $size = -s ("$real_img");
    print (">>>>> size = $size<< (for $real_img)\n");
    my $h = "HTTP/1.1 200 OK\nLast-Modified: 20150202020202\nConnection: close\nContent-Type: image/jpeg\nSet-Cookie: SUPPLIED_PASSWORD=$SUPPLIED_PASSWORD\nContent-Length: $size\n\n";
    print "===============\n", $h, "\n^^^^^^^^^^^^^^^^^^^\n";
    syswrite (\*CLIENT, $h);
    copy "$real_img", \*CLIENT;
}

sub zip_copy_file_to_socket
{
    my $sock_ref = $_ [0];
    my $img = $_ [1];
    my $buffer;
    my $size = 0;
    my $size = -s ("$img");
    print (">>>>> size = $size<< (for $img)\n");
    my $h = "HTTP/1.1 200 OK\nLast-Modified: 20150202020202\nConnection: close\nContent-Type: application\/zip\nSet-Cookie: SUPPLIED_PASSWORD=$SUPPLIED_PASSWORD\nContent-Length: $size\n\n";
    print "===============\n", $h, "\n^^^^^^^^^^^^^^^^^^^\n";
    syswrite (\*CLIENT, $h);
    copy "$img", \*CLIENT;
}

sub web_cam_copy_file_to_socket
{
    my $sock_ref = $_ [0];
    my $img = $_ [1];
    my $buffer;
    my $size = 0;

    open F, "$img";
    my $content = do { local $/; <F> };
    close F;

    my $b64_content = encode_base64url ($content);
    $b64_content =~ s/_/\//g;
    $b64_content =~ s/-/+/g;
    my $image_html = "<html><body><img src=\"data:image/jpg;base64,$b64_content\"/></body></html>";
    print $image_html , "\n";
    my $size = length ($image_html);
    print (">>>>> size = $size<<\n");

    my $h = "HTTP/1.1 200 OK\nLast-Modified: 20150202020202\nConnection: close\nContent-Type: text\/html\nSet-Cookie: SUPPLIED_PASSWORD=$SUPPLIED_PASSWORD\nContent-Length: $size\n\n";
    print "===============\n", $h, "\n^^^^^^^^^^^^^^^^^^^\n";
    syswrite (\*CLIENT, $h);
    syswrite (\*CLIENT, $image_html);
}

sub bin_write_to_socket
{
    my $sock_ref = $_ [0];
    my $img = $_ [1];
    my $buffer;
    my $size = 0;
    $img =~ s/ //img;

    print ("Looking at >>$img<<\n");
    if (-f $img)
    {
        $size = -s $img;
        print ("Size was $size at $img\n");
    }
    print ("Size was $size for $img\n");
    my $msg_body = "HTTP/2.0 200 OK\ndate: Mon, 20 May 2019 13:20:41 GMT\ncontent-type: image/jpeg\ncontent-length: $size\n\n";
    print $msg_body, "\n";
    syswrite ($sock_ref, $msg_body);

    open IMAGE, $img;
    binmode IMAGE;

    my $buffer;
    my $i = 0;
    print (">>DOING\n");
    while (read (IMAGE, $buffer, 4006384))
    {
        print ("$i DOING\n");
        $i ++;
        syswrite ($sock_ref, $buffer);
    }
    print ("REALLY DOING\n");
}

sub read_from_socket2
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

sub restart_monitor
{
    my $ds_count = `ps -ef | grep -i download_sound.pl | grep -v grep | wc -l`;
    my $rs_count = `ps -ef | grep -i run_sound.pl | grep -v grep | wc -l`;
    my $ts_count = `ps -ef | grep -i test_sound.pl | grep -v grep | wc -l`;

    if ($ds_count =~ m/0/img)
    {
        print ("Going to restart download_sound.pl!\n");
        my $pid = fork ();
        if ($pid == 0)
        {
            exec ("/home/spjspj/download_sound/download_sound.pl");
        }
    }
    if ($rs_count =~ m/0/img)
    {
        print ("Going to restart run_sound.pl!\n");
        my $pid = fork ();
        if ($pid == 0)
        {
            exec ("/home_monitor/run_sound.pl");
        }
    }
    if ($ts_count =~ m/0/img)
    {
        print ("Going to restart test_sound.pl!\n");
        my $pid = fork ();
        if ($pid == 0)
        {
            exec ("/home_monitor/test_sound.pl");
        }
    }
}

sub is_authorized
{
    my $pw = $_ [0];
    if ($pw eq "SuperSecretPasswordHeHe123415253")
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
    my $port = 4578;
    my $num_connections = 0;
    my $trusted_client;
    my $data_from_client;
    $|=1;
    srand (time);

    print ("example: filter_magic.pl 1 1 0 1 1 \"each opponent\" \".*\" 0 5\n\n");

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
                <form action=\"/homemonitor/password\">
                <label for=\"password\">Password:</label><br>
                <input type=\"text\" id=\"password\" name=\"password\" value=\"xyz\"><br>
                <input type=\"submit\" value=\"Supply password to proceed\">
                </form>";
            write_to_socket (\*CLIENT, $txt, "", "noredirect");
            next;
        }
        print ("Session is authorized\n");

        if ($txt =~ m/.*favico.*/m)
        {
            my $size = -s ("/home/spjspj/download_sound/favicon.ico");
            print (">>>>> size = $size\n");
            my $h = "HTTP/1.1 200 OK\nLast-Modified: 20150202020202\nConnection: close\nContent-Type: image/jpeg\nContent-Length: $size\n\n";
            print "===============\n", $h, "\n^^^^^^^^^^^^^^^^^^^\n";
            syswrite (\*CLIENT, $h);
            copy "/home/spjspj/download_sound/favicon.ico", \*CLIENT;
            next;
        }

        if ($txt =~ m/.*keep.*/m)
        {
            `touch /home_monitor/keep.5`;
            $txt = "<font color=red>Keeping!</font><br><br>";
            write_to_socket (\*CLIENT, $txt, "", "noredirect");
            next;
        }

        if ($txt =~ m/.*restart.*/img)
        {
            restart_monitor ();
            $txt = "<font color=red>Restarted!</font><br><br>";
            write_to_socket (\*CLIENT, $txt, "", "noredirect");
            next;
        }

        if ($txt =~ m/.*stop_me_now.*/img)
        {
            `killall run_sound.pl; killall test_sound.pl; killall arecord;`;
            $txt = "<font color=red>Stopped!</font><br><br>";
            write_to_socket (\*CLIENT, $txt, "", "noredirect");
            next;
        }

        print ("Read -> $txt\n");

        print ("2- - - - - - -\n");

        chomp ($txt);
        my $original_get = $txt;

        if ($original_get =~ m/\.(wav|png|gif|[as]xx)/)
        {
            my $b = $original_get; 
            $original_get =~ s/GET //img;
            $original_get =~ s/HTTP.*//img;
            $original_get =~ s/^.*\///img;
            $original_get =~ s/(.*)axx/\/home_monitor\/Archive\/$1.wav/;
            $original_get =~ s/(.*)sxx/\/home_monitor\/Spool\/$1.wav/;
            $original_get =~ s/\.\./\./img;
            $original_get =~ s/[as]xx/wav/img;
            #write_to_socket (\*CLIENT, "Getting $original_get", "", "noredirect");
            print ("DOING --> $original_get\n");
            copy_file_to_socket (\*CLIENT, $original_get, "", "noredirect");
            print ("DONE --> $original_get\n");
            next;
        }

        if ($original_get =~ m/\.(zip)/)
        {
            my $b = $original_get; 
            $original_get =~ s/GET //img;
            $original_get =~ s/HTTP.*//img;
            $original_get =~ s/^.*\///img;
            $original_get =~ m/(.*zip)/img;
            my $zip_file = "/home_monitor/Archive/" . $1;
            $zip_file =~ s/\.\././img;
            $zip_file =~ s/\.\././img;
            $zip_file =~ s/\.\././img;
            print ("DOING >>>$zip_file<<<<\n");
            zip_copy_file_to_socket (\*CLIENT, $zip_file, "", "noredirect");
            print ("DONE\n");
        }

        print ("Session is authorized - all web cam??\n");
        if ($original_get =~ m/all_web_cam/)
        {
            print ("Session is all web cam!!\n");
            my $ls = `ls -1 /home_monitor/images/*.jpg`;
            $ls =~ s/\n/<br>/img;

            my $ls2 = `ls -1 /home_monitor/images/*jpg`;
            my $jpg_info;
            while ($ls2 =~ s/^(.*?)\n//m)
            {
                my $jpg_file = $1;
                $jpg_file =~  s/^.*\///;
                $jpg_file =~  s/\.jpg//img;
                $jpg_info .= "<a href=\"\/homemonitor\/web_cam_$jpg_file\"<\/a>$jpg_file</a><br>";
            }
 
            write_to_socket (\*CLIENT, $jpg_info, "", "noredirect");
            next;
        }

        print ("Session is authorized - web cam image?? \n###$original_get\n###\n");
        if ($original_get =~ m/web_cam_(shot_\d+_\d+)/im)
        {
            my $b = $original_get; 
            my $jpg_file = "/home_monitor/images/" . $1 . ".jpg";
            $jpg_file =~ s/\.jpg\.jpg/.jpg/img;
            $jpg_file =~ s/\.jpg\.jpg/.jpg/img;
            $jpg_file =~ s/\.\././img;
            $jpg_file =~ s/\.\././img;
            $jpg_file =~ s/\.\././img;
            $jpg_file .= ".jpg";
            $jpg_file =~ s/\.jpg\.jpg/.jpg/img;
            web_cam_copy_file_to_socket (\*CLIENT, $jpg_file, "", "noredirect");
            next;
        }

        {
            $txt = "";
            my $ls = `ls -1 /home_monitor/Archive | grep -v _1.wav `;
            $ls =~ s/^(.*?)\n/<a href="homemonitor\/$1">$1<\/a><br>/img;
            $ls =~ s/\/\//\//img;
            $ls =~ s/\/\//\//img;
            $ls =~ s/\/\//\//img;
            $ls =~ s/\.wav/\.axx/img;
            $txt .= "<font color=red><a href=\"keep_it\">Keep it</a></font><br>";
            $txt .= "<font color=red><a href=\"all_web_cam\">Web Cam images</a></font><br>";
            $txt .=  "Archive:<br>$ls<br>";

            my $ls = `ls -l /home_monitor/Archive/*zip`;
            $ls =~ s/^(.*?)\n/$1<br>/img;
            $txt .=  "<br>Zips:<br>$ls<br>";

            my $ls2 = `ls -1 /home_monitor/Archive/*zip`;
            my $zip_info;
            while ($ls2 =~ s/^(.*?)\n//m)
            {
                my $zip_file = $1;
                my $zi = `zipinfo $zip_file | grep -i REALLY_LOUD | wc -l`;
                chomp $zi;
                my $zip_name = $zip_file;
                $zip_name = $zip_file;
                $zip_name =~ s/^.*\///;
                $zip_info .= "<a href=\"homemonitor\/$zip_name\"<\/a>$zip_name</a>: REALLY_LOUD=$zi";
                $zi = `zipinfo $zip_file | grep -i [^YD].LOUD | wc -l`;
                chomp $zi;
                $zip_info .= " - LOUD = $zi";
                $zi = `zipinfo $zip_file | grep -i D_LOUD | wc -l`;
                chomp $zi;
                $zip_info .= " - MOD_LOUD = $zi<br>\n";
                print ("Looking at $zip_file\n");
            }
            $txt .=  "<br>Zip_info:<br><pre>$zip_info</pre><br>";

            $txt .= "<br><a href=\"restart_me\">Restart here</a></br>";
            $txt .= "<br><a href=\"stop_me_new\">Stop here</a>";
            write_to_socket (\*CLIENT, $txt, "", "noredirect");
        }

        print ("============================================================\n");
    }
}
