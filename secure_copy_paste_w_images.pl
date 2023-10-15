#!/usr/bin/perl
##
#   File : secure_copy_paste.pl
#   Date : 19/Sept/2023
#   Author : spjspj
#   Purpose : Allow a copy and paste to happen (also drag/drop of an image..)
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
    my $content = "";
    my $rin = "";
    my $rout;
    my $isPost = 0;
    my $done_expected_content_len = 0;
    my $expected_content_len = 0;
    my $boundary_number = -1;
    my $seen_boundary_number = 0;
    my $old_expected_content_len = 0;
    my $seen_content_len = -2;

        # D:\perl_programs>secure_copy_paste.pl
        # Listening on port: 6725
        #
        #
        # NEW============================================================
        # New connection
        #
        # 192.168.1.100
        # POST /image/upload HTTP/1.1
        # Host: xmage.au
        # User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/118.0
        # Accept: */*
        # Accept-Language: en-US,en;q=0.5
        # Accept-Encoding: gzip, deflate, br
        # X-Requested-With: XMLHttpRequest
        # Content-Type: multipart/form-data; boundary=---------------------------16872368921677059352327625213
        # X-Forwarded-Host: xmage.au
        # X-Forwarded-Server: xmage.au
        # Content-Length: 31117 <<< look for this !
        # Connection: Keep-Alive
        #
        # -----------------------------16872368921677059352327625213
        # Content-Disposition: form-data; name="upload_preset"
        #
        # ujpu6gyk
        # -----------------------------16872368921677059352327625213
        # Content-Disposition: form-data; name="file"; filename="asdf.bmp"
        # Content-Type: image/bmp
        #
        # BM6x      6   (   �   P   ? ?                         ������������������������������������������������
        # �����������������������������������������������'��'��'��'��'�����������������������������'��'��'��'��'
        #  etc
        #  etc..
        #  -----------------------------16872368921677059352327625213--

    vec ($rin, fileno ($sock_ref), 1) = 1;
    my $count = 0;
    my $content_length = -1;
    my $finished_content_length = 0;
    my $actual_content_length = -1;

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
            #print ("$ch");
            if (!$isPost && $header =~ m/POST/img)
            {
                $isPost = 1;
            }

            if ($isPost && $finished_content_length == 0)
            {
                if ($header =~ m/CONTENT.LENGTH: (\d+)/img)
                {
                    if ($content_length < $1)
                    {
                        $content_length = $1;
                    }
                    else
                    {
                        $finished_content_length = 1;
                    }
                }
            }
        }

        if ($seen_content_len >= -1)
        {
            $seen_content_len ++;
            $count ++;
            if ($count > $content_length - 2000 && $count % 100 == 0)
            {
                print "ALMOST FINSIHING - seen $count characters.. of $content_length\n";
            }
            if ($count == $content_length)
            {
                print "FINSIHING - seen $count characters..\n";
                return ($header, $content);
            }
            if ($seen_content_len > 0)
            {
                $content .= $ch;
            }
        }

        if ($actual_content_length >= 0)
        {
            $actual_content_length ++;
        }
        if (ord ($ch) == 13 and ord ($prev_ch) == 10 && $actual_content_length == -1)
        {
            print "\n!! starting actual from here!!\n";
            $actual_content_length++;
        }


        if ($seen_boundary_number == 1 && $header =~ m/\x0A--+$boundary_number(.)/img)
        {
            print (">>>\nHEADER BEGINS HERE (0xA - $boundary_number):\n\n$header\nAND FINI\n");
            print (">>>\nCONTENT BEGINS HERE:\n\n$content\nAND FINI AS WELL\n");
            print ("SEEN BOUNDARY CONDITION!!\n");
            $seen_boundary_number = 2;
            $seen_content_len = -1;
            print "aaaaa\n";
            my $new_content;
            $content = $new_content;
            $count = $actual_content_length;
            # Keep this stuff..
        }

        if ($isPost == 1 && $done_expected_content_len == 0)
        {
            if ($boundary_number == -1 && $header =~ m/Content-Type: multipart.form-data; boundary=--+(\d+)[^0-9]/img)
            {
                $boundary_number = $1;
                $seen_boundary_number = 1;
                print ("found boundary: $boundary_number\n");
            }

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

        #if ($count % 10000 == 0)
        {
            print "$ch";
        }
    }
    return ($header, "");
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

sub get_drag_drop_header
{
    my $dd_header = "<style> body {";
    $dd_header .= "  font-family: sans-serif;" . "\n";
    $dd_header .= "}" . "\n";
    $dd_header .= "a {" . "\n";
    $dd_header .= "  color: #369;" . "\n";
    $dd_header .= "}" . "\n";
    $dd_header .= ".note {" . "\n";
    $dd_header .= "  width: 500px;" . "\n";
    $dd_header .= "  margin: 50px auto;" . "\n";
    $dd_header .= "  font-size: 1.1em;" . "\n";
    $dd_header .= "  color: #333;" . "\n";
    $dd_header .= "  text-align: justify;" . "\n";
    $dd_header .= "}" . "\n";
    $dd_header .= "#drop-area {" . "\n";
    $dd_header .= "  border: 2px dashed #ccc;" . "\n";
    $dd_header .= "  border-radius: 20px;" . "\n";
    $dd_header .= "  width: 480px;" . "\n";
    $dd_header .= "  margin: 50px auto;" . "\n";
    $dd_header .= "  padding: 20px;" . "\n";
    $dd_header .= "}" . "\n";
    $dd_header .= "#drop-area.highlight {" . "\n";
    $dd_header .= "  border-color: purple;" . "\n";
    $dd_header .= "}" . "\n";
    $dd_header .= "p {" . "\n";
    $dd_header .= "  margin-top: 0;" . "\n";
    $dd_header .= "}" . "\n";
    $dd_header .= ".my-form {" . "\n";
    $dd_header .= "  margin-bottom: 10px;" . "\n";
    $dd_header .= "}" . "\n";
    $dd_header .= "#gallery {" . "\n";
    $dd_header .= "  margin-top: 10px;" . "\n";
    $dd_header .= "}" . "\n";
    $dd_header .= "#gallery img {" . "\n";
    $dd_header .= "  width: 150px;" . "\n";
    $dd_header .= "  margin-bottom: 10px;" . "\n";
    $dd_header .= "  margin-right: 10px;" . "\n";
    $dd_header .= "  vertical-align: middle;" . "\n";
    $dd_header .= "}" . "\n";
    $dd_header .= ".button {" . "\n";
    $dd_header .= "  display: inline-block;" . "\n";
    $dd_header .= "  padding: 10px;" . "\n";
    $dd_header .= "  background: #ccc;" . "\n";
    $dd_header .= "  cursor: pointer;" . "\n";
    $dd_header .= "  border-radius: 5px;" . "\n";
    $dd_header .= "  border: 1px solid #ccc;" . "\n";
    $dd_header .= "}" . "\n";
    $dd_header .= ".button:hover {" . "\n";
    $dd_header .= "  background: #ddd;" . "\n";
    $dd_header .= "}" . "\n";
    $dd_header .= "#fileElem {" . "\n";
    $dd_header .= "  display: none;" . "\n";
    $dd_header .= "}</style>" . "\n";
    return $dd_header;
}

sub get_drag_drop_body
{
    my $dd_body = "<div id=\"drop-area\">";
    $dd_body .= "  <form class=\"my-form\">" . "\n";
    $dd_body .= "    <p>Upload multiple files with the file dialog or by dragging and dropping images onto the dashed region</p>" . "\n";
    $dd_body .= "    <input type=\"file\" id=\"fileElem\" multiple accept=\"image/*\" onchange=\"handleFiles(this.files)\">" . "\n";
    $dd_body .= "    <label class=\"button\" for=\"fileElem\">Select some files</label>" . "\n";
    $dd_body .= "  </form>" . "\n";
    $dd_body .= "  <progress id=\"progress-bar\" max=100 value=0></progress>" . "\n";
    $dd_body .= "  <div id=\"gallery\" /></div>" . "\n";
    $dd_body .= "  " . "\n";
    $dd_body .= "<script>" . "\n";
    $dd_body .= "let dropArea = document.getElementById(\"drop-area\")" . "\n";
    $dd_body .= ";['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {" . "\n";
    $dd_body .= "  dropArea.addEventListener(eventName, preventDefaults, false)   " . "\n";
    $dd_body .= "  document.body.addEventListener(eventName, preventDefaults, false)" . "\n";
    $dd_body .= "})" . "\n";
    $dd_body .= ";['dragenter', 'dragover'].forEach(eventName => {" . "\n";
    $dd_body .= "  dropArea.addEventListener(eventName, highlight, false)" . "\n";
    $dd_body .= "})" . "\n";
    $dd_body .= ";['dragleave', 'drop'].forEach(eventName => {" . "\n";
    $dd_body .= "  dropArea.addEventListener(eventName, unhighlight, false)" . "\n";
    $dd_body .= "})" . "\n";
    $dd_body .= "dropArea.addEventListener('drop', handleDrop, false)" . "\n";
    $dd_body .= "function preventDefaults (e) {" . "\n";
    $dd_body .= "  e.preventDefault()" . "\n";
    $dd_body .= "  e.stopPropagation()" . "\n";
    $dd_body .= "}" . "\n";
    $dd_body .= "function highlight(e) {" . "\n";
    $dd_body .= "  dropArea.classList.add('highlight')" . "\n";
    $dd_body .= "}" . "\n";
    $dd_body .= "function unhighlight(e) {" . "\n";
    $dd_body .= "  dropArea.classList.remove('active')" . "\n";
    $dd_body .= "}" . "\n";
    $dd_body .= "function handleDrop(e) {" . "\n";
    $dd_body .= "  var dt = e.dataTransfer" . "\n";
    $dd_body .= "  var files = dt.files" . "\n";
    $dd_body .= "  handleFiles(files)" . "\n";
    $dd_body .= "}" . "\n";
    $dd_body .= "let uploadProgress = []" . "\n";
    $dd_body .= "let progressBar = document.getElementById('progress-bar')" . "\n";
    $dd_body .= "function initializeProgress(numFiles) {" . "\n";
    $dd_body .= "  progressBar.value = 0" . "\n";
    $dd_body .= "  uploadProgress = []" . "\n";
    $dd_body .= "  for(let i = numFiles; i > 0; i--) {" . "\n";
    $dd_body .= "    uploadProgress.push(0)" . "\n";
    $dd_body .= "  }" . "\n";
    $dd_body .= "}" . "\n";
    $dd_body .= "function updateProgress(fileNumber, percent) {" . "\n";
    $dd_body .= "  uploadProgress[fileNumber] = percent" . "\n";
    $dd_body .= "  let total = uploadProgress.reduce((tot, curr) => tot + curr, 0) / uploadProgress.length" . "\n";
    $dd_body .= "  progressBar.value = total" . "\n";
    $dd_body .= "}" . "\n";
    $dd_body .= "function handleFiles(files) {" . "\n";
    $dd_body .= "  files = [...files]" . "\n";
    $dd_body .= "  initializeProgress(files.length)" . "\n";
    $dd_body .= "  files.forEach(uploadFile)" . "\n";
    $dd_body .= "  files.forEach(previewFile)" . "\n";
    $dd_body .= "}" . "\n";
    $dd_body .= "function previewFile(file) {" . "\n";
    $dd_body .= "  let reader = new FileReader()" . "\n";
    $dd_body .= "  reader.readAsDataURL(file)" . "\n";
    $dd_body .= "  reader.onloadend = function() {" . "\n";
    $dd_body .= "    let img = document.createElement('img')" . "\n";
    $dd_body .= "    img.src = reader.result" . "\n";
    $dd_body .= "    document.getElementById('gallery').appendChild(img)" . "\n";
    $dd_body .= "  }" . "\n";
    $dd_body .= "}" . "\n";
    $dd_body .= "function uploadFile(file, i) {" . "\n";
    $dd_body .= "  var url = 'https://xmage.au/secure_paste/image/upload';" . "\n";
    $dd_body .= "  var xhr = new XMLHttpRequest();" . "\n";
    $dd_body .= "  var formData = new FormData();" . "\n";
    $dd_body .= "  xhr.open('POST', url, true)" . "\n";
    $dd_body .= "  xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest')" . "\n";
    $dd_body .= "  xhr.upload.addEventListener(\"progress\", function(e) {" . "\n";
    $dd_body .= "    updateProgress(i, (e.loaded * 100.0 / e.total) || 100)" . "\n";
    $dd_body .= "  })" . "\n";
    $dd_body .= "  xhr.addEventListener('readystatechange', function(e) {" . "\n";
    $dd_body .= "    if (xhr.readyState == 4 && xhr.status == 200) {" . "\n";
    $dd_body .= "      updateProgress(i, 100)" . "\n";
    $dd_body .= "    }" . "\n";
    $dd_body .= "    else if (xhr.readyState == 4 && xhr.status != 200) {" . "\n";
    $dd_body .= "      alert (\"hi, error found! \" + xhr.readyState + \" and \" + xhr.status);" . "\n";
    $dd_body .= "    }" . "\n";
    $dd_body .= "  })" . "\n";
    $dd_body .= "  formData.append('file', file)" . "\n";
    $dd_body .= "  xhr.send(formData)" . "\n";
    $dd_body .= "}" . "\n";
    $dd_body .= "</script>" . "\n";
    $dd_body .= "</div>";
    return $dd_body;
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

    my $dd_header = get_drag_drop_header ();
    my $dd_body = get_drag_drop_body ();
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

        my ($txt, $content) = read_from_socket (\*CLIENT);
        print ("Raw data was $txt\n");
        if (length ($content) > 0)
        {
            print ("Was a post!!\n");
            print (length ($content) ." was length!!\n");

            open my $fh, '>', "d:/d_downloads/test.bmp" or die;
            binmode $fh;
            syswrite ($fh, $content);
            close ($fh);
        }
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

            my $html_text = "<html> <head> <META HTTP-EQUIV=\"CACHE-CONTROL\" CONTENT=\"NO-CACHE\"> <br> <META HTTP-EQUIV=\"EXPIRES\" CONTENT=\"Mon, 22 Jul 2094 11:12:01 GMT\"> $dd_header </head> <body> <h1>Previous CSVs</h1> <br>";
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

            my $html_text = "<html> <head> <META HTTP-EQUIV=\"CACHE-CONTROL\" CONTENT=\"NO-CACHE\"> <br> <META HTTP-EQUIV=\"EXPIRES\" CONTENT=\"Mon, 22 Jul 2094 11:12:01 GMT\"> $dd_header </head> <body> <h1>Copy Paste</h1> <br>";
            if ($is_admin_session == 1)
            {
                $html_text .= "<table><tr><td>$dd_body<br></td>";
                $html_text .= "<td><form action=\"updated_paste\" id=\"newpaste\" name=\"newpaste\" method=\"post\"> <textarea id=\"newpaste\" class=\"text\" cols=\"86\" rows =\"20\" form=\"newpaste\" name=\"newpaste\">$all_pasted_text{$SUPPLIED_KEYWORD}</textarea> <input type=\"submit\" value=\"Create New Paste\" class=\"submitButton\"></form></td><tr></table>";
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
                if ($line =~ m/^$/ || $line =~ m/^$/)
                {
                    $discard_header --;
                }

                if (!$discard_header)
                {
                    $new_paste .= "$line\n";
                }
            }

            $new_paste =~ s/^$//img;
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

            my $html_text = "<html> <head> <META HTTP-EQUIV=\"CACHE-CONTROL\" CONTENT=\"NO-CACHE\"> <br> <META HTTP-EQUIV=\"EXPIRES\" CONTENT=\"Mon, 22 Jul 2094 11:12:01 GMT\"> $dd_header </head> <body><h1>Copy Paste</h1> <br>";

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
