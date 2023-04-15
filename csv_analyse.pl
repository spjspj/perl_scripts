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


my %csv_data;
my %meta_data;
my %calculated_data;
my $max_field_num = 0;
my $max_rows = 0;
my %col_types;

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

my %field_letters;
$field_letters {"A"} = 0;
$field_letters {"B"} = 1;
$field_letters {"C"} = 2;
$field_letters {"D"} = 3;
$field_letters {"E"} = 4;
$field_letters {"F"} = 5;
$field_letters {"G"} = 6;
$field_letters {"H"} = 7;
$field_letters {"I"} = 8;
$field_letters {"J"} = 9;
$field_letters {"K"} = 10;
$field_letters {"L"} = 11;
$field_letters {"M"} = 12;
$field_letters {"N"} = 13;
$field_letters {"O"} = 14;
$field_letters {"P"} = 15;
$field_letters {"Q"} = 16;
$field_letters {"R"} = 17;
$field_letters {"S"} = 18;
$field_letters {"T"} = 19;
$field_letters {"U"} = 20;
$field_letters {"V"} = 21;
$field_letters {"W"} = 22;
$field_letters {"X"} = 23;
$field_letters {"Y"} = 24;
$field_letters {"Z"} = 25;

$field_letters {0} = "A";
$field_letters {1} = "B";
$field_letters {2} = "C";
$field_letters {3} = "D";
$field_letters {4} = "E";
$field_letters {5} = "F";
$field_letters {6} = "G";
$field_letters {7} = "H";
$field_letters {8} = "I";
$field_letters {9} = "J";
$field_letters {10} = "K";
$field_letters {11} = "L";
$field_letters {12} = "M";
$field_letters {13} = "N";
$field_letters {14} = "O";
$field_letters {15} = "P";
$field_letters {16} = "Q";
$field_letters {17} = "R";
$field_letters {18} = "S";
$field_letters {19} = "T";
$field_letters {20} = "U";
$field_letters {21} = "V";
$field_letters {22} = "W";
$field_letters {23} = "X";
$field_letters {24} = "Y";
$field_letters {25} = "Z";

sub get_field_num_from_field_letter
{
    my $letter = $_ [0];
    return ($field_letters {$letter});
}

sub get_field_letter_from_field_num
{
    my $num = $_ [0];
    return ($field_letters {$num});
}

sub get_next_field_letter 
{
    my $letter = $_ [0];
    my $num = get_field_num_from_field_letter ($letter);
    return ($field_letters {$num + 1});
}

sub process_csv_data
{
    my $block = $_ [0];
    my %new_csv_data;
    %csv_data = %new_csv_data;
    my %new_col_types;
    %col_types = %new_col_types;
    $max_field_num = 0;
    $max_rows = 0;

    my $line_num = 1;
    my $col_letter = "A";
    while ($block =~ s/^(.*?)\n//im)
    {
        chomp;
        my $line = $1;
        if ($line =~ m/^$/)
        {
            next;
        }
        $col_letter = "A";
        while ($line =~ s/^([^;\t]+?)(;|\t|$)//)
        {
            my $field = $1;
            $csv_data {"$col_letter" . "$line_num"} = $field;
            print ("$col_letter$line_num= $field\n");
            $col_letter = get_next_field_letter ($col_letter);
            
            if ($max_field_num < get_field_num_from_field_letter ($col_letter))
            {
                $max_field_num = get_field_num_from_field_letter ($col_letter);
            }
        }
        $line_num++;
        $max_rows++;
    }
    
    #print ("Process_data Last line:$block\n");
    $col_letter = "A";
    while ($block =~ s/^([^;]+?)(;|$)//)
    {
        my $field = $1;
        $csv_data {"$line_num.$col_letter"} = $field;
        $col_letter = get_next_field_letter ($col_letter);
        if ($max_field_num < get_field_num_from_field_letter ($col_letter))
        {
            $max_field_num = get_field_num_from_field_letter ($col_letter);
        }
    }
    $max_rows++;
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
    my $col_letter = $_ [0];
    if ($col_letter =~ m/^\d+$/)
    {
        $col_letter =  get_field_letter_from_field_num ($col_letter);
    }
    return ($col_types {$col_letter});
}

sub set_col_type
{
    my $col_letter = $_ [0];
    my $col_type = $_ [1];
    $col_types {$col_letter} = $col_type;
}

sub get_col_header
{
    my $col_letter = $_ [0];
    if ($col_letter =~ m/^\d+$/)
    {
        $col_letter =  get_field_letter_from_field_num ($col_letter);
    }
    return ($csv_data {"$col_letter" . "1"});
}

sub get_col_name_of_number_type_col
{
    my $i = 0;
    for ($i = 0; $i < $max_field_num; $i++)
    {
        if (get_col_type ($i) eq "NUMBER" || get_col_type ($i) eq "PRICE")
        {
            my $ch = get_col_header ($i);
            if ($ch =~ m/.../)
            {
                return "%23" . get_col_header ($i);
            }
        }
    }
    return "%23NUM_COL";
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
        return get_field_value ($row_num, $col);
    }
    return "";
}

sub has_field_id
{
    my $field_val = $_ [0]; 
    print ("    has?? $field_val --= ");
    if ($field_val =~ m/^=.*([A-Z]+\d+)/)
    {
        print ("    yes $1\n");
        return $1;
    }
    print ("    no\n");
    return "";
}

sub get_row_num
{
    my $field_id = $_ [0];
    if ($field_id =~ m/(\d+)$/)
    {
        return $1;
    }
}

sub get_col_letter
{
    my $field_id = $_ [0];
    if ($field_id =~ m/^([A-Z]+)/)
    {
        return $1;
    }
}

sub calc_field_value
{
    my $field_val = $_ [0]; 
    my $row_num = $_ [1]; 
    my $col_letter = $_ [2]; 
    my $indent = $_ [3]; 
    my $next_field_id = has_field_id ($field_val);
    while ($next_field_id ne "")
    {
        my $rn = get_row_num ($next_field_id);
        my $cl = get_col_letter ($next_field_id);
        my $that_field_val = get_field_value ($rn, $cl, $indent);
        print ("$indent>> found $that_field_val for $next_field_id\n");
        print (" before - $col_letter$row_num -- $field_val >> ");
        $field_val =~ s/$next_field_id/$that_field_val/; 
        print (" after = $field_val\n");
        $next_field_id = has_field_id ($field_val);
    }
    if ($field_val =~ s/^=//)
    {
        $field_val =~ s/POWER\(([^|]+)\|(.+)\)/(($1)**($2))/;
        my $orig_field_val = $field_val;
        $field_val = eval ($field_val);
        print ("$field_val from - $orig_field_val\n");
    }
    print ("$indent$col_letter$row_num -- >$field_val< done \n");
    return $field_val;
}

sub set_field_value
{
    my $row_num = $_ [0];
    my $col_letter = $_ [1];
    my $new_val = $_ [2];

    if ($col_letter =~ m/^\d+$/)
    {
        $col_letter =  get_field_letter_from_field_num ($col_letter);
    }
    my $str = "$col_letter" . $row_num;
    if (defined ($csv_data {$str}))
    {
        $csv_data {$str} = $new_val;
    }
}

sub get_field_value
{
    my $row_num = $_ [0];
    my $col_letter = $_ [1];
    my $indent = $_ [2];
    if ($col_letter =~ m/^\d+$/)
    {
        $col_letter =  get_field_letter_from_field_num ($col_letter);
    }
    my $str = "$col_letter" . $row_num;
    if (defined ($csv_data {$str}))
    {
        my $field_val = $csv_data {$str};
        my $calc_val = "";
        if (!defined ($calculated_data {$str}))
        {
            if ($csv_data {$str} =~ m/^=/)
            {
                $calc_val = calc_field_value ($csv_data {$str}, $row_num, $col_letter, ".$indent");
            }
            else
            {
                $calc_val = $field_val;
            }
            $calculated_data {$str} = $calc_val;
        }
        $calc_val = $calculated_data {$str};
        print (" >> calculated $str as $calc_val\n");
        return ($calc_val);
    }
    print (" >> returning blank for $str<<\n");
    return ("");
}

sub get_graph_html
{
    my $graph_html = "";
    my $col = $_ [0];
    my $col_name = $_ [1];

    # graph_counts
    my $graph_counts = 0;
    if ($col == -1)
    {
        $graph_counts = 1;
    }

    # graph_totals
    my $graph_totals = 0;
    if ($col == -2)
    {
        $graph_totals = 1;
    }

    $graph_html .= "<!DOCTYPE html>\n";
    $graph_html .= "<html lang=\"en\">\n";
    $graph_html .= "<head>\n";
    $graph_html .= "<meta charset=\"UTF-8\">\n";
    $graph_html .= "<title>Graph Data</title>\n";
    $graph_html .= "<link rel=\"stylesheet\" href=\"https://cdnjs.cloudflare.com/ajax/libs/normalize/5.0.0/normalize.min.css\">\n";
    $graph_html .= "<link rel='stylesheet' href='https://fonts.googleapis.com/css?family=Khand'>\n";
    $graph_html .= "    <style>\n";
    $graph_html .= "        * {\n";
    $graph_html .= "        box-sizing: border-box;\n";
    $graph_html .= "        padding: 0;\n";
    $graph_html .= "        margin: 0;\n";
    $graph_html .= "        }\n";
    $graph_html .= "        body {\n";
    $graph_html .= "        margin: 50px auto;\n";
    $graph_html .= "        font-family: \"Khand\";\n";
    $graph_html .= "        font-size: 1.2em;\n";
    $graph_html .= "        text-align: center;\n";
    $graph_html .= "        }\n";
    $graph_html .= "        ul {\n";
    $graph_html .= "        padding-top: 20px;\n";
    $graph_html .= "        display: flex;\n";
    $graph_html .= "        gap: 2rem;\n";
    $graph_html .= "        }\n";
    $graph_html .= "        li {\n";
    $graph_html .= "        margin: 0.5rem 0;\n";
    $graph_html .= "        }\n";
    $graph_html .= "        legend {\n";
    $graph_html .= "        margin: 0 auto;\n";
    $graph_html .= "        }\n";
    $graph_html .= "    </style>\n";
    $graph_html .= "<style> table { border-collapse: collapse; } table.center { margin-left: auto; margin-right: auto; } td, th { border: 1px solid #dddddd; text-align: left; padding: 8px; } tr:nth-child(even) { background-color: #cfdfff; } </style>\n";
    $graph_html .= "<script>\n";
    $graph_html .= "if (document.location.search.match (/type=embed/gi)) {\n";
    $graph_html .= "    window.parent.postMessage (\"resize\", \"*\");\n";
    $graph_html .= "}\n";
    $graph_html .= "</script>\n";
    $graph_html .= "</head>\n";
    $graph_html .= "<body translate=\"no\" >\n";
    $graph_html .= "<h1>Graph for column $col_name</h1><br>\n";
    $graph_html .= "<canvas id=\"graph_canvas\" style=\"background: white;\"></canvas>\n";
    $graph_html .= "<legend for=\"graph_canvas\"></legend>\n";
    $graph_html .= "<script id=\"rendered-js\" >\n";
    $graph_html .= "var canvas = document.getElementById (\"graph_canvas\");\n";
    $graph_html .= "canvas.width = 1200;\n";
    $graph_html .= "canvas.height = 600;\n";
    $graph_html .= "var ctx = canvas.getContext (\"2d\");\n";
    $graph_html .= "var min_gridy;\n";
    $graph_html .= "var max_gridy;\n";
    $graph_html .= "var barSize;\n";
    $graph_html .= "function drawActualLine (ctx, startX, startY, endX, endY, color) {\n";
    $graph_html .= "    ctx.save ();\n";
    $graph_html .= "    ctx.strokeStyle = color;\n";
    $graph_html .= "    ctx.beginPath ();\n";
    $graph_html .= "    ctx.moveTo (startX, startY);\n";
    $graph_html .= "    ctx.lineTo (endX, endY);\n";
    $graph_html .= "    ctx.stroke ();\n";
    $graph_html .= "    ctx.restore ();\n";
    $graph_html .= "}\n";
    $graph_html .= "function drawLine (ctx, startX, startY, endX, endY, color, options, canvas) {\n";
    $graph_html .= "    startX += options.padding;\n";
    $graph_html .= "    startY += canvas.height - options.padding;\n";
    $graph_html .= "    endX += options.padding + 2;\n";
    $graph_html .= "    endY += canvas.height - options.padding;\n";
    $graph_html .= "    ctx.save ();\n";
    $graph_html .= "    ctx.strokeStyle = color;\n";
    $graph_html .= "    ctx.beginPath ();\n";
    $graph_html .= "    ctx.moveTo (startX, startY);\n";
    $graph_html .= "    ctx.lineTo (endX, endY);\n";
    $graph_html .= "    ctx.stroke ();\n";
    $graph_html .= "    ctx.restore ();\n";
    $graph_html .= "}\n";
    $graph_html .= "function drawSquare (ctx, startX, startY, width, color, options, canvas) \n";
    $graph_html .= "{\n";
    $graph_html .= "    ctx.save ();\n";
    $graph_html .= "    ctx.fillStyle = color;\n";
    $graph_html .= "    ctx.fillRect (startX, startY, width, width);\n";
    $graph_html .= "    ctx.restore ();\n";
    $graph_html .= "}\n";
    $graph_html .= "function drawBar (ctx, upperLeftCornerX, upperLeftCornerY, width, height, color)\n";
    $graph_html .= "{\n";
    $graph_html .= "    ctx.save ();\n";
    $graph_html .= "    ctx.fillStyle = color;\n";
    $graph_html .= "    ctx.fillRect (upperLeftCornerX, upperLeftCornerY, width, height);\n";
    $graph_html .= "    ctx.restore ();\n";
    $graph_html .= "}\n";
    $graph_html .= "class BarChart \n";
    $graph_html .= "{\n";
    $graph_html .= "    constructor (options) {\n";
    $graph_html .= "        this.options = options;\n";
    $graph_html .= "        this.canvas = options.canvas;\n";
    $graph_html .= "        this.ctx = this.canvas.getContext (\"2d\");\n";
    $graph_html .= "        this.titleOptions = options.titleOptions;\n";
    $graph_html .= "        this.minValue = Math.min (...Object.values (this.options.data));\n";
    $graph_html .= "        this.maxValue = Math.max (...Object.values (this.options.data));\n";
    $graph_html .= "        this.maxValue += 1;\n";
    $graph_html .= "        this.multiplier = (options.canvas.height - options.padding * 2) / this.maxValue;\n";
    $graph_html .= "    }\n";
    $graph_html .= "    drawGridLines () {\n";
    $graph_html .= "        var canvasActualHeight = this.canvas.height - this.options.padding * 2;\n";
    $graph_html .= "        var canvasActualWidth = this.canvas.width - this.options.padding * 2;\n";
    $graph_html .= "        var gridValue = this.minValue;\n";
    $graph_html .= "        max_gridy = 0;\n";
    $graph_html .= "        min_gridy = 10000000000;\n";
    $graph_html .= "        this.grid_jump = (this.maxValue - this.minValue) / 10;\n";
    $graph_html .= "        while (gridValue <= this.maxValue) {\n";
    $graph_html .= "            var gridY = canvasActualHeight * (1 - gridValue / this.maxValue) + this.options.padding;\n";
    $graph_html .= "            if (max_gridy < gridY) { max_gridy  = gridY; }\n";
    $graph_html .= "            if (min_gridy > gridY) { min_gridy  = gridY; }\n";
    $graph_html .= "            drawActualLine (this.ctx, 0, gridY, this.canvas.width, gridY, this.options.gridColor);\n";
    $graph_html .= "            // Writing grid markers\n";
    $graph_html .= "            this.ctx.save ();\n";
    $graph_html .= "            this.ctx.fillStyle = \"black\";\n";
    $graph_html .= "            this.ctx.textBaseline = \"bottom\";\n";
    $graph_html .= "            this.ctx.font = \"bold 10px Arial\";\n";
    $graph_html .= "            this.ctx.fillText (gridValue, 0, gridY - 5);\n";
    $graph_html .= "            this.ctx.restore ();\n";
    $graph_html .= "            gridValue += this.grid_jump;\n";
    $graph_html .= "        }\n";
    $graph_html .= "        min_gridy = canvasActualHeight * (1 - gridValue / this.maxValue) + this.options.padding;\n";
    $graph_html .= "        drawActualLine (this.ctx, 25, min_gridy, 25, max_gridy, \"red\");\n";
    $graph_html .= "    }\n";
    $graph_html .= "    getBar = function(x, y) {\n";
    $graph_html .= "        var canvasActualHeight = this.canvas.height - this.options.padding * 2;\n";
    $graph_html .= "        var canvasActualWidth = this.canvas.width - this.options.padding * 2;\n";
    $graph_html .= "        var barIndex = 0;\n";
    $graph_html .= "        var numberOfBars = Object.keys (this.options.data).length;\n";
    $graph_html .= "        barSize = canvasActualWidth / numberOfBars;\n";
    $graph_html .= "        var values = Object.values (this.options.data);\n";
    $graph_html .= "        \n";
    $graph_html .= "        for (let thekey of Object.keys (this.options.data)) {\n";
    $graph_html .= "            if (x > this.options.padding + barIndex * barSize && x < this.options.padding + (barIndex+1) * barSize)\n";
    $graph_html .= "            {\n";
    $graph_html .= "                return thekey;\n";
    $graph_html .= "            }\n";
    $graph_html .= "            barIndex++;\n";
    $graph_html .= "        }\n";
    $graph_html .= "        return \"\";\n";
    $graph_html .= "    }\n";
    $graph_html .= "    getKey = function(searchVal) {\n";
    $graph_html .= "        var barIndex = 0;\n";
    $graph_html .= "        for (let thekey of Object.keys (this.options.data)) {\n";
    $graph_html .= "            if (thekey == searchVal)\n";
    $graph_html .= "            {\n";
    $graph_html .= "                return barIndex;\n";
    $graph_html .= "            }\n";
    $graph_html .= "            barIndex++;\n";
    $graph_html .= "        }\n";
    $graph_html .= "        return 0;\n";
    $graph_html .= "    }\n";
    $graph_html .= "    getBarValue = function(x, y) {\n";
    $graph_html .= "        var canvasActualHeight = this.canvas.height - this.options.padding * 2;\n";
    $graph_html .= "        var canvasActualWidth = this.canvas.width - this.options.padding * 2;\n";
    $graph_html .= "        var barIndex = 0;\n";
    $graph_html .= "        var numberOfBars = Object.keys (this.options.data).length;\n";
    $graph_html .= "        barSize = canvasActualWidth / numberOfBars;\n";
    $graph_html .= "        var values = Object.values (this.options.data);\n";
    $graph_html .= "        \n";
    $graph_html .= "        for (let thekey of Object.keys (this.options.data)) {\n";
    $graph_html .= "            if (x > this.options.padding + barIndex * barSize && x < this.options.padding + (barIndex+1) * barSize)\n";
    $graph_html .= "            {\n";
    $graph_html .= "                var reg = /.*\\((.+)\\)/;\n";
    $graph_html .= "                if (thekey.match(reg))\n";
    $graph_html .= "                {\n";
    $graph_html .= "                    return thekey.match(reg);\n";
    $graph_html .= "                }\n";
    $graph_html .= "                return thekey;\n";
    $graph_html .= "            }\n";
    $graph_html .= "            barIndex++;\n";
    $graph_html .= "        }\n";
    $graph_html .= "        return \"\";\n";
    $graph_html .= "    }\n";
    $graph_html .= "    drawBars () {\n";
    $graph_html .= "        var canvasActualHeight = this.canvas.height - this.options.padding * 2;\n";
    $graph_html .= "        var canvasActualWidth = this.canvas.width - this.options.padding * 2;\n";
    $graph_html .= "        var barIndex = 0;\n";
    $graph_html .= "        var numberOfBars = Object.keys (this.options.data).length;\n";
    $graph_html .= "        barSize = canvasActualWidth / numberOfBars;\n";
    $graph_html .= "        var values = Object.values (this.options.data);\n";
    $graph_html .= "        var oldBarHeight = 0;\n";
    $graph_html .= "        var barHeight = 0;\n";
    $graph_html .= "        for (let val of values) {\n";
    $graph_html .= "            oldBarHeight = barHeight;\n";
    $graph_html .= "            barHeight = Math.round (canvasActualHeight * val / this.maxValue);\n";
    $graph_html .= "            drawLine (this.ctx, (-0.5 + barIndex) * barSize,  -1*oldBarHeight , (0.5+barIndex) * barSize, -1*barHeight , \"skyblue\", this.options, this.canvas);\n";
    $graph_html .= "            barIndex++;\n";
    $graph_html .= "        }\n";
    $graph_html .= "    }\n";
    $graph_html .= "    drawLabel () {\n";
    $graph_html .= "        this.ctx.save ();\n";
    $graph_html .= "        this.ctx.textBaseline = \"bottom\";\n";
    $graph_html .= "        this.ctx.textAlign = this.titleOptions.align;\n";
    $graph_html .= "        this.ctx.fillStyle = this.titleOptions.fill;\n";
    $graph_html .= "        this.ctx.font = \`\${this.titleOptions.font.weight} \${this.titleOptions.font.size} \${this.titleOptions.font.family}`;\n";
    $graph_html .= "        let xPos = this.canvas.width / 2;\n";
    $graph_html .= "        if (this.titleOptions.align == \"left\") {\n";
    $graph_html .= "            xPos = 10;\n";
    $graph_html .= "        }\n";
    $graph_html .= "        if (this.titleOptions.align == \"right\") {\n";
    $graph_html .= "            xPos = this.canvas.width - 10;\n";
    $graph_html .= "        }\n";
    $graph_html .= "        this.ctx.fillText (this.options.seriesName, xPos, this.canvas.height);\n";
    $graph_html .= "        this.ctx.restore ();\n";
    $graph_html .= "    }\n";
    $graph_html .= "    draw () {\n";
    $graph_html .= "        this.drawGridLines ();\n";
    $graph_html .= "        this.drawBars ();\n";
    $graph_html .= "        this.drawLabel ();\n";
    $graph_html .= "    }\n";
    $graph_html .= "}\n";
    $graph_html .= "var myBarchart = new BarChart (\n";
    $graph_html .= "    {\n";
    $graph_html .= "        canvas: canvas,\n";
    $graph_html .= "        seriesName: \"Cell Values\",\n";
    $graph_html .= "        padding: 50,\n";
    $graph_html .= "        gridStep: 10,\n";
    $graph_html .= "        gridColor: \"lightgrey\",\n";

    $graph_html .= "        data: {";
    my $i;
    if ($graph_counts == 0 && $graph_totals == 0)
    {
        for ($i = 1; $i < $max_rows; $i++)
        {
            my $x = get_field_value ($i, $col);
            $x =~ s/^$/0/;
            $x =~ s/,//g;
            $x =~ s/\$//g;
            $x =~ s/^ *$/0/g;
            $graph_html .= "\"Row $i,Col $col ($x)\":$x,";
        }
    }
    elsif ($graph_counts == 1 || $graph_totals == 1)
    {
        my $k;
        foreach $k (sort keys (%meta_data))
        {
            if ($k =~ m/_count/ && $graph_counts)
            {
                my $x = $meta_data {$k};
                $x =~ s/^$/0/;
                $x =~ s/,//g;
                $x =~ s/\$//g;
                $x =~ s/[^0-9\.]//g;
                $x =~ s/^ *$/0/g;
                $graph_html .= "\"Group $k ($x)\":$x,";
            }
            elsif ($k =~ m/_total/ && $graph_totals)
            {
                my $x = $meta_data {$k};
                $x =~ s/^$/0/;
                $x =~ s/,//g;
                $x =~ s/\$//g;
                $x =~ s/[^0-9\.]//g;
                $x =~ s/^ *$/0/g;
                $graph_html .= "\"Group $k ($x)\":$x,";
            }
        }
    }
    $graph_html .= "\"DONE\": 0 },\n";

    # Print colors line
    $graph_html .= "        colors: [";
    for ($i = 1; $i < $max_rows; $i++)
    {
        $graph_html .= "\"\#fbfbab\",";
    }
    $graph_html .= "],\n";

    $graph_html .= "        titleOptions: { align: \"center\", fill: \"black\", font: { weight: \"bold\", size: \"18px\", family: \"Lato\" } } \n";
    $graph_html .= "    }\n";
    $graph_html .= ");\n";
    $graph_html .= "myBarchart.draw ();\n";
    $graph_html .= "</script>\n";
    $graph_html .= "<canvas id=\"canvas_info\" style=\"background: skyblue;\"></canvas>\n";
    $graph_html .= "<script>\n";
    $graph_html .= "var canvas_info = document.getElementById(\"canvas_info\");\n";
    $graph_html .= "canvas_info.width = 900;\n";
    $graph_html .= "canvas_info.height = 100;\n";
    $graph_html .= "var graph_canvas = document.getElementById(\"graph_canvas\");\n";
    $graph_html .= "var ctx = canvas_info.getContext(\"2d\");\n";
    $graph_html .= "var graph_ctx = graph_canvas.getContext(\"2d\");\n";
    $graph_html .= "ctx.font = \"bold 20px Arial\";\n";
    $graph_html .= "var cw = graph_canvas.width;\n";
    $graph_html .= "var ch = graph_canvas.height;\n";
    $graph_html .= "function reOffset() {\n";
    $graph_html .= "  var BB = graph_canvas.getBoundingClientRect();\n";
    $graph_html .= "  offsetX = BB.left;\n";
    $graph_html .= "  offsetY = BB.top;\n";
    $graph_html .= "}\n";
    $graph_html .= "var offsetX, offsetY;\n";
    $graph_html .= "reOffset();\n";
    $graph_html .= "window.onscroll = function (e) {\n";
    $graph_html .= "  reOffset();\n";
    $graph_html .= "};\n";
    $graph_html .= "window.onresize = function (e) {\n";
    $graph_html .= "  reOffset();\n";
    $graph_html .= "};\n";
    $graph_html .= "graph_canvas.addEventListener(\"mousemove\", handleMouseMove, false);\n";
    $graph_html .= "var oldmouseX;\n";
    $graph_html .= "var oldY;\n";
    $graph_html .= "function handleMouseMove(e) {\n";
    $graph_html .= "    e.preventDefault();\n";
    $graph_html .= "    e.stopPropagation();\n";
    $graph_html .= "    mouseX = parseInt(e.clientX - offsetX);\n";
    $graph_html .= "    mouseY = parseInt(e.clientY - offsetY);\n";
    $graph_html .= "    ctx.clearRect(0, 0, cw, ch);\n";
    $graph_html .= "    var bar = myBarchart.getBar (mouseX, mouseY);\n";
    $graph_html .= "    ctx.fillText(bar, 50, 50);\n";
    $graph_html .= "    graph_ctx.clearRect(0, 0, 55, 55);\n";
    $graph_html .= "    var barVal = myBarchart.getBarValue (mouseX, mouseY);\n";
    $graph_html .= "    drawSquare (graph_ctx, oldmouseX, oldY, 10, \"white\", null, null); \n";
    $graph_html .= "    drawSquare (graph_ctx, mouseX, graph_canvas.height - 50 - myBarchart.multiplier *barVal[1], 5, \"darkorange\", null, null); \n";
    $graph_html .= "    oldmouseX = mouseX;\n";
    $graph_html .= "    oldY = graph_canvas.height - 50 - myBarchart.multiplier *barVal[1];\n";
    $graph_html .= "    myBarchart.draw ();\n";
    $graph_html .= "}\n";
    $graph_html .= "</script>\n";
    $graph_html .= "</table>\n";
    $graph_html .= "</body>\n";
    $graph_html .= "</html>\n";
    return $graph_html;
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

    #process_csv_data ("Tot_Month;Add_Month;Daily_Int;Date;MonDays;Int_Month;Tot_Mon2;Mon_Interest; 3640;0;0.000115068;20230430;30;1.003457821;\$3,652.59;\$0.00; 3652.586467;10;0.000115068;20230531;31;1.003573287;\$3,675.67;\$13.09; 3675.67394;10;0.000115068;20230630;30;1.003457821;\$3,698.42;\$12.74; 3698.41834;10;0.000115068;20230731;31;1.003573287;\$3,721.67;\$13.25; 3721.669583;10;0.000115068;20230831;31;1.003573287;\$3,745.00;\$13.33; 3745.00391;10;0.000115068;20230930;30;1.003457821;\$3,767.99;\$12.98; 3767.988041;10;0.000115068;20231031;31;1.003573287;\$3,791.49;\$13.50; 3791.487876;10;0.000115068;20231130;30;1.003457821;\$3,814.63;\$13.14; 3814.63274;10;0.000115068;20231231;31;1.003573287;\$3,838.30;\$13.67; 3838.299251;10;0.000115068;20240131;31;1.003573287;\$3,862.05;\$13.75; 3862.050329;10;0.000115068;20240228;28;1.003226928;\$3,884.55;\$12.49; 3884.545156;10;0.000115068;20240331;31;1.003573287;\$3,908.46;\$13.92; 3908.461484;10;0.000115068;20240430;30;1.003457821;\$3,932.01;\$13.55; 3932.010821;10;0.000115068;20240531;31;1.003573287;\$3,956.10;\$14.09; 3956.096757;10;0.000115068;20240630;30;1.003457821;\$3,979.81;\$13.71; 3979.810809;10;0.000115068;20240731;31;1.003573287;\$4,004.07;\$14.26; 4004.067548;10;0.000115068;20240831;31;1.003573287;\$4,028.41;\$14.34; 4028.410964;10;0.000115068;20240930;30;1.003457821;\$4,052.38;\$13.96; 4052.375065;10;0.000115068;20241031;31;1.003573287;\$4,076.89;\$14.52; 4076.891098;10;0.000115068;20241130;30;1.003457821;\$4,101.02;\$14.13; 4101.022834;10;0.000115068;20241231;31;1.003573287;\$4,125.71;\$14.69; 4125.712699;10;0.000115068;20250131;31;1.003573287;\$4,150.49;\$14.78; 4150.490788;10;0.000115068;20250228;28;1.003226928;\$4,173.92;\$13.43; 4173.916391;10;0.000115068;20250331;31;1.003573287;\$4,198.87;\$14.95; 4198.866726;10;0.000115068;20250430;30;1.003457821;\$4,223.42;\$14.55; 4223.420232;10;0.000115068;20250531;31;1.003573287;\$4,248.55;\$15.13; 4248.547458;10;0.000115068;20250630;30;1.003457821;\$4,273.27;\$14.73; 4273.272752;10;0.000115068;20250731;31;1.003573287;\$4,298.58;\$15.31; 4298.578115;10;0.000115068;20250831;31;1.003573287;\$4,323.97;\$15.40; 4323.973902;10;0.000115068;20250930;30;1.003457821;\$4,348.96;\$14.99; 4348.960006;10;0.000115068;20251031;31;1.003573287;\$4,374.54;\$15.58; 4374.535822;10;0.000115068;20251130;30;1.003457821;\$4,399.70;\$15.16; 4399.696761;10;0.000115068;20251231;31;1.003573287;\$4,425.45;\$15.76; 4425.453873;10;0.000115068;20260131;31;1.003573287;\$4,451.30;\$15.85; 4451.303023;10;0.000115068;20260228;28;1.003226928;\$4,475.70;\$14.40; 4475.699326;10;0.000115068;20260331;31;1.003573287;\$4,501.73;\$16.03; 4501.728018;10;0.000115068;20260430;30;1.003457821;\$4,527.33;\$15.60; 4527.328764;10;0.000115068;20260531;31;1.003573287;\$4,553.54;\$16.21; 4553.541943;10;0.000115068;20260630;30;1.003457821;\$4,579.32;\$15.78; 4579.321852;10;0.000115068;20260731;31;1.003573287;\$4,605.72;\$16.40; 4605.720817;10;0.000115068;20260831;31;1.003573287;\$4,632.21;\$16.49; 4632.214113;10;0.000115068;20260930;30;1.003457821;\$4,658.27;\$16.05; 4658.266057;10;0.000115068;20261031;31;1.003573287;\$4,684.95;\$16.68; 4684.947112;10;0.000115068;20261130;30;1.003457821;\$4,711.18;\$16.23; 4711.181397;10;0.000115068;20261231;31;1.003573287;\$4,738.05;\$16.87; 4738.051533;10;0.000115068;20270131;31;1.003573287;\$4,765.02;\$16.97; 4765.017685;10;0.000115068;20270228;28;1.003226928;\$4,790.43;\$15.41; 4790.426322;10;0.000115068;20270331;31;1.003573287;\$4,817.58;\$17.15; 4817.579624;10;0.000115068;20270430;30;1.003457821;\$4,844.27;\$16.69; 4844.272528;10;0.000115068;20270531;31;1.003573287;\$4,871.62;\$17.35; 4871.618238;10;0.000115068;20270630;30;1.003457821;\$4,898.50;\$16.88; 4898.497998;10;0.000115068;20270731;31;1.003573287;\$4,926.04;\$17.54; 4926.037471;10;0.000115068;20270831;31;1.003573287;\$4,953.68;\$17.64; 4953.67535;10;0.000115068;20270930;30;1.003457821;\$4,980.84;\$17.16; 4980.838849;10;0.000115068;20271031;31;1.003573287;\$5,008.67;\$17.83; 5008.672549;10;0.000115068;20271130;30;1.003457821;\$5,036.03;\$17.35; 5036.026219;10;0.000115068;20271231;31;1.003573287;\$5,064.06;\$18.03; 5064.05712;10;0.000115068;20280131;31;1.003573287;\$5,092.19;\$18.13; 5092.188183;10;0.000115068;20280228;28;1.003226928;\$5,118.65;\$16.46; 5118.652575;10;0.000115068;20280331;31;1.003573287;\$5,146.98;\$18.33; 5146.978724;10;0.000115068;20280430;30;1.003457821;\$5,174.81;\$17.83; 5174.810631;10;0.000115068;20280531;31;1.003573287;\$5,203.34;\$18.53; 5203.337448;10;0.000115068;20280630;30;1.003457821;\$5,231.36;\$18.03; 5231.364235;10;0.000115068;20280731;31;1.003573287;\$5,260.09;\$18.73; 5260.093134;10;0.000115068;20280831;31;1.003573287;\$5,288.92;\$18.83; 5288.924689;10;0.000115068;20280930;30;1.003457821;\$5,317.25;\$18.32; 5317.247421;10;0.000115068;20281031;31;1.003573287;\$5,346.28;\$19.04; 5346.283205;10;0.000115068;20281130;30;1.003457821;\$5,374.80;\$18.52; 5374.804273;10;0.000115068;20281231;31;1.003573287;\$5,404.05;\$19.24; 5404.045724;10;0.000115068;20290131;31;1.003573287;\$5,433.39;\$19.35; 5433.391664;10;0.000115068;20290228;28;1.003226928;\$5,460.96;\$17.57; 5460.957096;10;0.000115068;20290331;31;1.003573287;\$5,490.51;\$19.55; 5490.506396;10;0.000115068;20290430;30;1.003457821;\$5,519.53;\$19.02; 5519.526161;10;0.000115068;20290531;31;1.003573287;\$5,549.28;\$19.76; 5549.284746;10;0.000115068;20290630;30;1.003457821;\$5,578.51;\$19.22; 5578.507756;10;0.000115068;20290731;31;1.003573287;\$5,608.48;\$19.97; 5608.477098;10;0.000115068;20290831;31;1.003573287;\$5,638.55;\$20.08; 5638.55353;10;0.000115068;20290930;30;1.003457821;\$5,668.09;\$19.53; 5668.085215;10;0.000115068;20291031;31;1.003573287;\$5,698.37;\$20.29; 5698.374644;10;0.000115068;20291130;30;1.003457821;\$5,728.11;\$19.74; 5728.11318;10;0.000115068;20291231;31;1.003573287;\$5,758.62;\$20.50; 5758.617106;10;0.000115068;20300131;31;1.003573287;\$5,789.23;\$20.61");
    process_csv_data ("Tot_Month;Add_Month;Daily_Int;Date;MonDays;Int_Month;Tot_Mon2;Mon_Interest;
=3640;0;=0.042/365;20230430;30;=POWER(1+C2|E2);=A2*F2;0;
=G2;10;=0.042/365;20230531;31;=POWER(1+C3|E3);=(G2+B3)*F3;=G3-G2-B3;
=G3;10;=0.042/365;20230630;30;=POWER(1+C4|E4);=(G3+B4)*F4;=G4-G3-B4;
=G4;10;=0.042/365;20230731;31;=POWER(1+C5|E5);=(G4+B5)*F5;=G5-G4-B5;
=G5;10;=0.042/365;20230831;31;=POWER(1+C6|E6);=(G5+B6)*F6;=G6-G5-B6;
=G6;10;=0.042/365;20230930;30;=POWER(1+C7|E7);=(G6+B7)*F7;=G7-G6-B7;
=G7;10;=0.042/365;20231031;31;=POWER(1+C8|E8);=(G7+B8)*F8;=G8-G7-B8;
=G8;10;=0.042/365;20231130;30;=POWER(1+C9|E9);=(G8+B9)*F9;=G9-G8-B9;
=G9;10;=0.042/365;20231231;31;=POWER(1+C10|E10);=(G9+B10)*F10;=G10-G9-B10;
=G10;10;=0.042/365;20240131;31;=POWER(1+C11|E11);=(G10+B11)*F11;=G11-G10-B11;
=G11;10;=0.042/365;20240228;28;=POWER(1+C12|E12);=(G11+B12)*F12;=G12-G11-B12;
=G12;10;=0.042/365;20240331;31;=POWER(1+C13|E13);=(G12+B13)*F13;=G13-G12-B13;
=G13;10;=0.042/365;20240430;30;=POWER(1+C14|E14);=(G13+B14)*F14;=G14-G13-B14;
=G14;10;=0.042/365;20240531;31;=POWER(1+C15|E15);=(G14+B15)*F15;=G15-G14-B15;");

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
        my $get_group_info = 0;
        if ($txt =~ m/GET.*\.group_info/)
        {
            $get_group_info = 1;
            $txt =~ s/\.group_info//;
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
        
        if ($txt =~ m/GET.*update_csv.*/m)
        {
            $txt =~ m/(........update_csv.......)/im;
            my $matching_text = $1;
            my $html_text = "<html> <head> <META HTTP-EQUIV=\"CACHE-CONTROL\" CONTENT=\"NO-CACHE\"> <br> <META HTTP-EQUIV=\"EXPIRES\" CONTENT=\"Mon, 22 Jul 2094 11:12:01 GMT\"> </head> <body> <h1>Refresh CSV </h1> <br> 
<form action=\"updated_csv\" id=\"newcsv\" name=\"newcsv\" method=\"post\">
<textarea id=\"newcsv\" class=\"text\" cols=\"86\" rows =\"20\" form=\"newcsv\" name=\"newcsv\"></textarea>
<input type=\"submit\" value=\"New CSV\" class=\"submitButton\">
</form>
</body> </html>";
            write_to_socket (\*CLIENT, $html_text, "", "noredirect");
            next;
        }

        if ($txt =~ m/GET.*dograph_(\d+)/m)
        {
            my $col = $1;
            my $graph_html = get_graph_html ($1, get_col_header ($1));
            write_to_socket (\*CLIENT, $graph_html, "", "noredirect");
            next;
        }

        if ($txt =~ m/GET.*dograph_group_counts/m)
        {
            my $col = $1;
            my $graph_html = get_graph_html (-1, "graph_counts");
            write_to_socket (\*CLIENT, $graph_html, "", "noredirect");
            next;
        }
        
        if ($txt =~ m/GET.*dograph_group_totals/m)
        {
            my $col = $1;
            my $graph_html = get_graph_html (-2, "graph_totals");
            write_to_socket (\*CLIENT, $graph_html, "", "noredirect");
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
        
        my $dual_group = ".*";
        if ($txt =~ m/dualgroup=(.*)/im)
        {
            $dual_group = "$1";
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

        my $example = get_field_value (2, "C");
        $example =~ s/^(...).*$/$1../;
        $example = "\"/csv_analyse/groupby?groupstr=(" . $example . ")" . get_col_name_of_number_type_col () . "\"";
        $html_text .= "<form action=\"/csv_analyse/groupby\">
                <label for=\"groupstr\">Group by <font size=-2><a href=$example>Example</a></font></label><br>
                <input type=\"text\" id=\"groupstr\" name=\"groupstr\" value=\"$group\">
                <input type=\"submit\" value=\"Group By\">
                </form></td><td>";
                
        my $f1 = get_field_value (2, "D");
        $f1 =~ s/\W/./img;
        $f1 =~ s/^(...)..*$/$1../img;
        my $f2 = get_field_value (2, "E");
        $f2 =~ s/\W/./img;
        $f2 =~ s/^(...)..*$/$1../img;
        my $dual_example = "($f1).*($f2)";

        $dual_example = "\"/csv_analyse/dualgroupby?dualgroup=$dual_example" . get_col_name_of_number_type_col () . "\"";
        $html_text .= "<form action=\"/csv_analyse/dualgroupby\">
                <label for=\"dualgroup\">Dual groups <font size=-2><a href=$dual_example>Example</a></font></label><br>
                <input type=\"text\" id=\"dualgroup\" name=\"dualgroup\" value=\"$dual_group\">
                <input type=\"submit\" value=\"Dual Group By\">
                </form></td>";
                
        $html_text .= "<td><form action=\"/csv_analyse/update_csv\">
                <label>Update CSV:</label><br>
                <input type=\"submit\" value=\"Update CSV\">
                </form></td></tr></table>";

        my %groups;
        my $group_count = 0;
        my %group_colours;
        $group_colours {0} = "burntorange"; $group_colours {1} = "blue"; $group_colours {2} = "green"; $group_colours {3} = "darkred"; $group_colours {4} = "mediumaquamarine"; $group_colours {5} = "black"; $group_colours {6} = "darkyellow"; $group_colours {7} = "red"; $group_colours {8} = "skyblue"; $group_colours {9} = "royalblue";
        $group_colours {11} = "blueviolet"; $group_colours {12} = "darkblue"; $group_colours {13} = "darkcyan"; $group_colours {14} = "darkgoldenrod"; $group_colours {15} = "darkgray"; $group_colours {16} = "darkgreen"; $group_colours {17} = "darkgrey"; $group_colours {18} = "darkkhaki"; $group_colours {19} = "darkmagenta"; $group_colours {20} = "darkolivegreen";
        $group_colours {21} = "darkorange"; $group_colours {22} = "darkorchid"; $group_colours {23} = "darksalmon"; $group_colours {24} = "darkseagreen"; $group_colours {25} = "darkslateblue"; $group_colours {26} = "darkslategray"; $group_colours {27} = "darkslategrey"; $group_colours {28} = "darkturquoise"; $group_colours {29} = "deeppink"; $group_colours {30} = "deepskyblue";
        $group_colours {31} = "midnightblue"; $group_colours {32} = "mediumpurple"; $group_colours {33} = "dodgerblue"; $group_colours {34} = "firebrick"; $group_colours {35} = "forestgreen"; $group_colours {36} = "fuchsia"; $group_colours {37} = "slateblue"; $group_colours {38} = "slategray"; $group_colours {39} = "slategrey"; $group_colours {40} = "gainsboro";
        $group_colours {41} = "gold"; $group_colours {42} = "goldenrod"; $group_colours {43} = "gray"; $group_colours {44} = "saddlebrown"; $group_colours {45} = "grey"; $group_colours {46} = "sandybrown"; $group_colours {47} = "hotpink"; $group_colours {48} = "indianred"; $group_colours {49} = "indigo"; $group_colours {50} = "ivory";
        $group_colours {51} = "khaki"; $group_colours {52} = "lavender"; $group_colours {53} = "lavenderblush"; $group_colours {54} = "lawngreen"; $group_colours {55} = "lemonchiffon"; $group_colours {56} = "lime"; $group_colours {57} = "limegreen"; $group_colours {58} = "linen"; $group_colours {59} = "magenta"; $group_colours {60} = "maroon";
        $group_colours {61} = "mediumaquamarine"; $group_colours {62} = "mediumblue"; $group_colours {63} = "mediumorchid"; $group_colours {64} = "dimgrey"; $group_colours {65} = "mediumseagreen"; $group_colours {66} = "mediumslateblue"; $group_colours {67} = "mediumspringgreen"; $group_colours {68} = "mediumturquoise"; $group_colours {69} = "mediumvioletred"; $group_colours {70} = "dimgray";
        $group_colours {71} = "mintcream"; $group_colours {72} = "mistyrose"; $group_colours {73} = "moccasin"; $group_colours {74} = "navy"; $group_colours {75} = "oldlace"; $group_colours {76} = "olive"; $group_colours {77} = "olivedrab"; $group_colours {78} = "orange"; $group_colours {79} = "orangered"; $group_colours {80} = "orchid";
        $group_colours {81} = "palegoldenrod"; $group_colours {82} = "palegreen"; $group_colours {83} = "paleturquoise"; $group_colours {84} = "palevioletred"; $group_colours {85} = "papayawhip"; $group_colours {86} = "peachpuff"; $group_colours {87} = "peru"; $group_colours {88} = "pink"; $group_colours {89} = "plum"; $group_colours {90} = "powderblue";
        $group_colours {91} = "rebeccapurple"; $group_colours {92} = "rosybrown"; $group_colours {93} = "greenyellow"; $group_colours {94} = "salmon"; $group_colours {95} = "honeydew"; $group_colours {96} = "seagreen"; $group_colours {97} = "seashell"; $group_colours {98} = "sienna"; $group_colours {99} = "springgreen"; $group_colours {100} = "steelblue";
        $group_colours {101} = "tan"; $group_colours {102} = "teal"; $group_colours {103} = "thistle"; $group_colours {104} = "tomato"; $group_colours {105} = "turquoise"; $group_colours {106} = "violet"; $group_colours {107} = "wheat"; $group_colours {108} = "yellow"; $group_colours {109} = "yellowgreen"; $group_colours {110} = "AliceBlue";
        $group_colours {111} = "aqua"; $group_colours {112} = "aquamarine"; $group_colours {113} = "azure"; $group_colours {114} = "beige"; $group_colours {115} = "bisque"; $group_colours {116} = "purple"; $group_colours {117} = "blanchedalmond"; $group_colours {119} = "brown"; $group_colours {120} = "cadetblue"; $group_colours {121} = "chartreuse";
        $group_colours {122} = "chocolate"; $group_colours {123} = "coral"; $group_colours {124} = "cornflowerblue"; $group_colours {125} = "cornsilk"; $group_colours {126} = "crimson"; $group_colours {127} = "cyan"; $group_colours {128} = "navajowhite"; $group_colours {129} = "lightblue"; $group_colours {130} = "lightcoral"; $group_colours {131} = "lightcyan";
        $group_colours {132} = "lightgoldenrodyellow"; $group_colours {133} = "lightgray"; $group_colours {134} = "lightgreen"; $group_colours {135} = "lightgrey"; $group_colours {136} = "lightpink"; $group_colours {137} = "lightsalmon"; $group_colours {138} = "lightseagreen"; $group_colours {139} = "lightskyblue"; $group_colours {140} = "lightslategray"; $group_colours {141} = "lightslategrey";
        $group_colours {142} = "lightsteelblue"; $group_colours {143} = "lightyellow"; $group_colours {144} = "snow"; $group_colours {145} = "white"; $group_colours {146} = "whitesmoke"; $group_colours {147} = "antiquewhite"; $group_colours {148} = "floralwhite"; $group_colours {149} = "ghostwhite";

        $html_text .= "<script>\n";
        $html_text .= "'use strict';\n";
        $html_text .= "class SortableTable { constructor(tableNode) { this.tableNode = tableNode; this.columnHeaders = tableNode.querySelectorAll('thead th'); this.sortColumns = []; for (var i = 0; i < this.columnHeaders.length; i++) { var ch = this.columnHeaders[i]; var buttonNode = ch.querySelector('button'); if (buttonNode) { this.sortColumns.push(i); buttonNode.setAttribute('data-column-index', i); buttonNode.addEventListener('click', this.handleClick.bind(this)); } } this.optionCheckbox = document.querySelector( 'input[type=\"checkbox\"][value=\"show-unsorted-icon\"]'); if (this.optionCheckbox) { this.optionCheckbox.addEventListener( 'change', this.handleOptionChange.bind(this)); if (this.optionCheckbox.checked) { this.tableNode.classList.add('show-unsorted-icon'); } } } setColumnHeaderSort(columnIndex) { if (typeof columnIndex === 'string') { columnIndex = parseInt(columnIndex); } for (var i = 0; i < this.columnHeaders.length; i++) { var ch = this.columnHeaders[i]; var buttonNode = ch.querySelector('button'); if (i === columnIndex) { var value = ch.getAttribute('aria-sort'); if (value === 'descending') { ch.setAttribute('aria-sort', 'ascending'); this.sortColumn( columnIndex, 'ascending', ch.classList.contains('td.num'), ch.classList.contains('td.price')); } else { ch.setAttribute('aria-sort', 'descending'); this.sortColumn( columnIndex, 'descending', ch.classList.contains('td.num'), ch.classList.contains('td.price')); } } else { if (ch.hasAttribute('aria-sort') && buttonNode) { ch.removeAttribute('aria-sort'); } } } } sortColumn(columnIndex, sortValue, isNumber, isPrice) { function compareValues(a, b) { if (sortValue === 'ascending') { if (a.value === b.value) { return 0; } else { if (isNumber) { return a.value - b.value; } else if (isPrice) { var aval = a.value; aval = aval.replace (/\\W/g, ''); var bval = b.value; bval = bval.replace (/\\W/g, '');  return aval - bval < 0 ? -1 : 1; } else { return a.value < b.value ? -1 : 1; } } } else { if (a.value === b.value) { return 0; } else { if (isNumber) { return b.value - a.value; } else if (isPrice) { var aval = a.value; aval = aval.replace (/\\W/g, ''); var bval = b.value; bval = bval.replace (/\\W/g, '');  return aval - bval < 0 ? 1 : -1; } else { return a.value > b.value ? -1 : 1; } } } } if (typeof isNumber !== 'boolean') { isNumber = false; } var tbodyNode = this.tableNode.querySelector('tbody'); var rowNodes = []; var dataCells = []; var rowNode = tbodyNode.firstElementChild; var index = 0; while (rowNode) { rowNodes.push(rowNode); var rowCells = rowNode.querySelectorAll('th, td'); var dataCell = rowCells[columnIndex]; var data = {}; data.index = index; data.value = dataCell.textContent.toLowerCase().trim(); if (isNumber) { data.value = parseFloat(data.value); } dataCells.push(data); rowNode = rowNode.nextElementSibling; index += 1; } dataCells.sort(compareValues); while (tbodyNode.firstChild) { tbodyNode.removeChild(tbodyNode.lastChild); } for (var i = 0; i < dataCells.length; i += 1) { tbodyNode.appendChild(rowNodes[dataCells[i].index]); } }  handleClick(event) { var tgt = event.currentTarget; this.setColumnHeaderSort(tgt.getAttribute('data-column-index')); } handleOptionChange(event) { var tgt = event.currentTarget; if (tgt.checked) { this.tableNode.classList.add('show-unsorted-icon'); } else { this.tableNode.classList.remove('show-unsorted-icon'); } } }\n";
        $html_text .= "window.addEventListener('load', function () { var sortableTables = document.querySelectorAll('table.sortable'); for (var i = 0; i < sortableTables.length; i++) { new SortableTable(sortableTables[i]); } });\n";
        $html_text .= "</script>\n";
        $html_text .= "<div class=\"table-wrap\"><table class=\"sortable\">\n";
                
        $html_text .= "<thead>\n";
        $html_text .= "<br>Found YYY rows<br>";
        #$html_text .= "<br><textarea style=\"font-family:courier-new;size=-3;white-space:pre-wrap\"\">QQQ</textarea><br>";
        $html_text .= "QQQ";
        
        $html_text .= "<tr>\n";

        my $x;
        for ($x = 0; $x < $max_field_num; $x++)
        {
            $html_text .= "<th XYZ$x> <button><font size=-1>" . get_col_header ($x) . "<span aria-hidden=\"true\"></span> </font></button> </th> \n";
        }
        $html_text .= "<th> <button><font size=-1>Group<span aria-hidden=\"true\"></span> </font></button> </th> \n";
        $html_text .= "<th> <button><font size=-1>Group_Total<span aria-hidden=\"true\"></span> </font></button> </th> \n";
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
        my $dual_groups = 0;
        my $group2 = "";
        my $chosen_col = "";
        if ($group =~ s/#(.*)//)
        {
            $chosen_col = "$1";
            print ("WOOT $chosen_col\n");
        }
        
        if ($dual_group =~ s/#(.*)//)
        {
            $chosen_col = "$1";
            print ("dual WOOT $chosen_col\n");
        }

        my $overall_match = $group;
        if ($group =~ m/\((.*)\).*\((.*)\)/)
        {
            $only_one_group = 0;
            $first_group_only = 1;
            $dual_groups = 0;
            $group = "$1";
            $group2 = "$2";
        }
        
        if ($dual_group =~ m/\((.*)\).*\((.*)\)/)
        {
            $only_one_group = 0;
            $first_group_only = 0;
            $dual_groups = 1;
            $group = "$1";
            $group2 = "$2";
            $overall_match = $dual_group;
        }

        my $valid_regex = eval { qr/$overall_match/ };
        my $use_regex = 0;
        my %new_meta_data;
        my %new_calculated_data;
        if (defined ($valid_regex))
        {
            %meta_data = %new_meta_data;
            %calculated_data = %new_calculated_data;
            $use_regex = 1;
        }

        my $row_num = 1;
        my $col_letter = "A";
        my $old_row_num = 2;
        my $old_col_letter = "A";
        my $field_id = 0;
        my $row = "<tr class=\"$even_odd\">";
        my $fake_row;
        my $x = 0;
        my $y = 0;

        my %col_calculations;
        my $pot_group_price = "";

        #foreach $field_id (sort {$a <=> $b} keys (%csv_data))
        while ($row_num < $max_rows)
        {
            my $x = 0;
            $col_letter = "A";
            while ($x < $max_field_num)
            {
                if ($row_num eq "1") { $old_row_num = 2; $x++; $col_letter = get_next_field_letter ($col_letter); next; }
                $field_id = "$col_letter" . $row_num;
                print ("\n=============GETTING field of $col_letter$row_num: -- got:"); 
                my $field = get_field_value ($row_num, $col_letter, "aa");
                print (">>$field<<:\n"); 

                if (!defined ($col_types {$col_letter}))
                {
                    if ($field =~ m/^\s*$/)
                    {
                        
                    }
                    elsif ($field =~ m/^\d\d\d\d\d\d\d\d$/ || $field =~ m/^\d\d\d\d[\/]\d\d[\/]\d\d$/ || $field =~ m/^\d\d\d\d[\/]\d\d[\/]\d$/ || $field =~ m/^\d\d\d\d[\/]\d[\/]\d\d$/ || $field =~ m/^\d\d\d\d[\/]\d[\/]\d$/ || $field =~ m/^\d\d[\/]\d\d[\/]\d\d$/ || $field =~ m/^\d\d[\/]\d\d[\/]\d$/ || $field =~ m/^\d\d[\/]\d[\/]\d\d$/ || $field =~ m/^\d\d[\/]\d[\/]\d$/ || $field =~ m/^\d\d[\/]\d\d[\/]\d\d$/ || $field =~ m/^\d[\/]\d\d[\/]\d\d$/ || $field =~ m/^\d\d[\/]\d[\/]\d\d$/ || $field =~ m/^\d[\/]\d[\/]\d\d$/ || $field =~ m/^\d\d[\/]\d\d[\/]\d\d\d\d$/ || $field =~ m/^\d[\/]\d\d[\/]\d\d\d\d$/ || $field =~ m/^\d\d[\/]\d[\/]\d\d\d\d$/ || $field =~ m/^\d[\/]\d[\/]\d\d\d\d$/)
                    {
                        set_col_type ($col_letter, "DATE");
                        if ($field =~ m/^\d\d\d\d[\/]\d\d[\/]\d\d$/)
                        {
                            $field =~ m/^(\d\d\d\d)[\/](\d\d)[\/](\d\d)$/;
                            print ("$field_id for $field -- ");
                            set_field_value ($row_num, $col_letter, "$1" . "$2" . "0$3");
                            print ("now is $csv_data{$field_id}\n");
                        }
                        elsif ($field =~ m/^\d\d\d\d[\/]\d\d[\/]\d$/)
                        {
                            $field =~ m/^(\d\d\d\d)[\/](\d\d)[\/](\d)$/;
                            print ("$field_id for $field -- ");
                            set_field_value ($row_num, $col_letter, "$1" . "$2" . "0$3");
                            print ("now is $csv_data{$field_id}\n");
                        }
                        elsif ($field =~ m/^\d\d\d\d[\/]\d[\/]\d\d$/)
                        {
                            $field =~ m/^(\d\d\d\d)[\/](\d)[\/](\d\d)$/;
                            print ("$field_id for $field -- ");
                            set_field_value ($row_num, $col_letter, "$1" . "0$2" . "$3");
                            print ("now is $csv_data{$field_id}\n");
                        }
                        elsif ($field =~ m/^\d\d[\/]\d\d[\/]\d\d\d\d$/)
                        {
                            $field =~ m/^(\d\d)[\/](\d\d)[\/](\d\d\d\d)$/;
                            print ("$field_id for $field -- ");
                            set_field_value ($row_num, $col_letter, "$3" . "$2" . "$1");
                            print ("now is $csv_data{$field_id}\n");
                        }
                        elsif ($field =~ m/^\d[\/]\d\d[\/]\d\d\d\d$/)
                        {
                            $field =~ m/^(\d)[\/](\d\d)[\/](\d\d\d\d)$/;
                            print ("$field_id for $field -- ");
                            set_field_value ($row_num, $col_letter, "$3" . "$2" . "0$1");
                            print ("now is $csv_data{$field_id}\n");
                        }
                        elsif ($field =~ m/^\d\d[\/]\d[\/]\d\d\d\d$/)
                        {
                            $field =~ m/^(\d\d)[\/](\d)[\/](\d\d\d\d)$/;
                            print ("$field_id for $field -- ");
                            set_field_value ($row_num, $col_letter, "$3" . "0$2" . "$1");
                            print ("now is $csv_data{$field_id}\n");
                        }
                        elsif ($field =~ m/^\d[\/]\d[\/]\d\d\d\d$/)
                        {
                            $field =~ m/^(\d)[\/](\d)[\/](\d\d\d\d)$/;
                            print ("$field_id for $field -- ");
                            set_field_value ($row_num, $col_letter, "$3" . "0$2" . "0$1");
                            print ("now is $csv_data{$field_id}\n");
                        }
                    }
                    elsif ($field =~ m/^\d+($|\.\d+)$/ || $field =~ m/^-\d+($|\.\d+)$/)
                    {
                        set_col_type ($col_letter, "NUMBER");
                        $col_calculations {$col_letter} = $field;
                        print ("$col_letter is now number 'cos >>$field<<\n");
                    }
                    elsif ($field =~ m/^(-|)\$(\d*[\d,])+($|\.\d+)$/)
                    {
                        set_col_type ($col_letter, "PRICE");
                        $col_calculations {$col_letter} = add_price ($col_calculations {$col_letter}, $field);
                        print ("$col_letter is now price 'cos >>$field<<\n");
                    }
                    else
                    {
                        print ("$col_letter is now general 'cos >>$field<<\n");
                        set_col_type ($col_letter, "GENERAL");
                    }
                }
                elsif ($col_types {$col_letter} ne "GENERAL")
                {
                    if ($field =~ m/^\s*$/)
                    {
                        
                    }
                    elsif ($field =~ m/^\d\d\d\d\d\d\d\d$/ || $field =~ m/^\d\d\d\d[\/]\d\d[\/]\d\d$/ || $field =~ m/^\d\d\d\d[\/]\d\d[\/]\d$/ || $field =~ m/^\d\d\d\d[\/]\d[\/]\d\d$/ || $field =~ m/^\d\d\d\d[\/]\d[\/]\d$/ || $field =~ m/^\d\d[\/]\d\d[\/]\d\d$/ || $field =~ m/^\d\d[\/]\d\d[\/]\d$/ || $field =~ m/^\d\d[\/]\d[\/]\d\d$/ || $field =~ m/^\d\d[\/]\d[\/]\d$/ || $field =~ m/^\d\d[\/]\d\d[\/]\d\d$/ || $field =~ m/^\d[\/]\d\d[\/]\d\d$/ || $field =~ m/^\d\d[\/]\d[\/]\d\d$/ || $field =~ m/^\d[\/]\d[\/]\d\d$/ || $field =~ m/^\d\d[\/]\d\d[\/]\d\d\d\d$/ || $field =~ m/^\d[\/]\d\d[\/]\d\d\d\d$/ || $field =~ m/^\d\d[\/]\d[\/]\d\d\d\d$/ || $field =~ m/^\d[\/]\d[\/]\d\d\d\d$/)
                    {
                        if ($col_types {$col_letter} ne "DATE")
                        {
                            print ("$col_letter is now general (was date) 'cos >>$field<<\n");
                            set_col_type ($col_letter, "GENERAL");
                        }
                        else
                        {
                            if ($field =~ m/^\d\d\d\d[\/]\d\d[\/]\d\d$/)
                            {
                                $field =~ m/^(\d\d\d\d)[\/](\d\d)[\/](\d\d)$/;
                                print ("$field_id for $field -- ");
                                set_field_value ($row_num, $col_letter, "$1" . "$2" . "0$3");
                                print ("now is $csv_data{$field_id}\n");
                            }
                            elsif ($field =~ m/^\d\d\d\d[\/]\d\d[\/]\d$/)
                            {
                                $field =~ m/^(\d\d\d\d)[\/](\d\d)[\/](\d)$/;
                                print ("$field_id for $field -- ");
                                set_field_value ($row_num, $col_letter, "$1" . "$2" . "0$3");
                                print ("now is $csv_data{$field_id}\n");
                            }
                            elsif ($field =~ m/^\d\d\d\d[\/]\d[\/]\d\d$/)
                            {
                                $field =~ m/^(\d\d\d\d)[\/](\d)[\/](\d\d)$/;
                                print ("$field_id for $field -- ");
                                set_field_value ($row_num, $col_letter, "$1" . "0$2" . "$3");
                                print ("now is $csv_data{$field_id}\n");
                            }
                            elsif ($field =~ m/^\d\d[\/]\d\d[\/]\d\d\d\d$/)
                            {
                                $field =~ m/^(\d\d)[\/](\d\d)[\/](\d\d\d\d)$/;
                                print ("$field_id for $field -- ");
                                set_field_value ($row_num, $col_letter, "$3" . "$2" . "$1");
                                print ("now is $csv_data{$field_id}\n");
                            }
                            elsif ($field =~ m/^\d[\/]\d\d[\/]\d\d\d\d$/)
                            {
                                $field =~ m/^(\d)[\/](\d\d)[\/](\d\d\d\d)$/;
                                print ("$field_id for $field -- ");
                                set_field_value ($row_num, $col_letter, "$3" . "$2" . "0$1");
                                print ("now is $csv_data{$field_id}\n");
                            }
                            elsif ($field =~ m/^\d\d[\/]\d[\/]\d\d\d\d$/)
                            {
                                $field =~ m/^(\d\d)[\/](\d)[\/](\d\d\d\d)$/;
                                print ("$field_id for $field -- ");
                                set_field_value ($row_num, $col_letter, "$3" . "0$2" . "$1");
                                print ("now is $csv_data{$field_id}\n");
                            }
                            elsif ($field =~ m/^\d[\/]\d[\/]\d\d\d\d$/)
                            {
                                $field =~ m/^(\d)[\/](\d)[\/](\d\d\d\d)$/;
                                print ("$field_id for $field -- ");
                                set_field_value ($row_num, $col_letter, "$3" . "0$2" . "0$1");
                                print ("now is $csv_data{$field_id}\n");
                            }
                        }
                    }
                    elsif ($field =~ m/^\d+($|\.\d+)$/ || $field =~ m/^-\d+($|\.\d+)$/)
                    {
                        if ($col_types {$col_letter} eq "PRICE")
                        {
                            print ("$col_letter is now number (was price) 'cos >>$field<<\n");
                            set_col_type ($col_letter, "NUMBER");
                        }
                        else
                        {
                            $col_calculations {$col_letter} += $field;
                        }
                    }
                    elsif ($field =~ m/^(-|)\$(\d*[\d,])+($|\.\d+)$/)
                    {
                        if ($col_types {$col_letter} eq "PRICE")
                        {
                            $col_calculations {$col_letter} = add_price ($col_calculations {$col_letter}, $field);
                        }
                        elsif ($col_types {$col_letter} ne "NUMBER")
                        {
                            print ("$col_letter is now general (was NUMBER) 'cos >>$field<<\n");
                            set_col_type ($col_letter, "GENERAL");
                        }
                    }
                    else
                    {
                        print ("$col_letter is now general 'cos >>$field<<\n");
                        set_col_type ($col_letter, "GENERAL");
                    }
                }

                print ("\n=============GETTING field of $col_letter$row_num: -- got "); 
                $field = get_field_value ($row_num, $col_letter, "bb");
                print (">>>>>$field<<<<<:\n"); 
                if ($row_num > $old_row_num)
                {
                    # Add row to table if matched 
                    $fake_row = $row;
                    $fake_row =~ s/<[^>]*>//img;
                    $fake_row =~ s/\n//img;
                    my $force_row = 0;
                    if ($dual_groups)
                    {
                        print ("DUAL- checking $overall_match vs $fake_row\n");
                        $force_row = -1;
                    }
                    
                    if ($use_regex && $fake_row =~ m/$overall_match/im && $overall_match ne ".*" && $overall_match ne "") 
                    {
                        $force_row = 1;
                        if ($only_one_group == 1 && $fake_row =~ m/($group)/im) 
                        {
                            my $this_group = $1;
                            $row .= " <td>$this_group</td>\n";
                            my $g_price = "GPRICE_$this_group";
                            $row .= " <td>$g_price</td> </tr>\n";

                            if (!defined ($group_colours {$this_group}))
                            {
                                $group_colours {$this_group} = $group_colours {$group_count};
                                $group_count++;
                            }
                            $row =~ s/<td>/<td><font color=$group_colours{$this_group}>/img;
                            $row =~ s/<\/td>/<\/font><\/td>/img;
                            $group_counts {$this_group}++;

                            $pot_group_price = get_field_value ($old_row_num, get_num_of_col_header ($chosen_col));
                            $group_prices {$this_group} = add_price ($group_prices {$this_group}, $pot_group_price);
                            $group_prices {$this_group . "_calc"} .= "+$pot_group_price ($old_row_num,$chosen_col)";
                        }
                        elsif ($first_group_only && $fake_row =~ m/$overall_match/im && ($fake_row =~ m/($group)/mg))
                        {
                            my $this_group = $1;
                            if ($fake_row =~ m/($group2)/mg)
                            {
                                $group_counts {$this_group}++;
                                $pot_group_price = get_field_value ($old_row_num, get_num_of_col_header ($chosen_col));
                                $group_prices {$this_group} = add_price ($group_prices {$this_group}, $pot_group_price);
                                $group_prices {$this_group . "_calc"} .= "+$pot_group_price ($old_row_num,$chosen_col)";
                                $row .= " <td>$this_group</td>\n";
                                my $g_price = "GPRICE_$this_group";
                                $row .= " <td>$g_price</td> </tr>\n";
                                
                                if (!defined ($group_colours {$this_group}))
                                {
                                    $group_colours {$this_group} = $group_colours {$group_count};
                                    $group_count++;
                                }
                                $row =~ s/<td>/<td><font color=$group_colours{$this_group}>/img;
                                $row =~ s/<\/td>/<\/font><\/td>/img;
                            }
                            else
                            {
                                $row .= "<td><font size=-3>No group ($row_num A)</font></td>\n";
                                $row .= "<td><font size=-3>No group Total</font></td></tr>\n";
                            }
                        }
                        elsif ($dual_groups && $fake_row =~ m/($overall_match)/im)
                        {
                            $fake_row =~ m/($group)/im;
                            print ("DUAL $fake_row\n");
                            my $this_group = $1;
                            if ($fake_row =~ m/($group2)/im)
                            {
                                $this_group .= " " . $1;
                                $group_counts {$this_group}++;
                                $pot_group_price = get_field_value ($old_row_num, get_num_of_col_header ($chosen_col));
                                $group_prices {$this_group} = add_price ($group_prices {$this_group}, $pot_group_price);
                                $group_prices {$this_group . "_calc"} .= "+$pot_group_price ($old_row_num,$chosen_col)";
                                $row .= " <td>$this_group</td>\n";
                                my $g_price = "GPRICE_$this_group";
                                $row .= " <td>$g_price</td> </tr>\n";
                                if (!defined ($group_colours {$this_group}))
                                {
                                    $group_colours {$this_group} = $group_colours {$group_count};
                                    $group_count++;
                                }
                                $row =~ s/<td>/<td><font color=$group_colours{$this_group}>/img;
                                $row =~ s/<\/td>/<\/font><\/td>/img;
                            }
                        }
                    }
                    else
                    {
                        $row .= "<td><font size=-3>No group($row_num B)</font></td>\n";
                        $row .= "<td><font size=-3>No group Total</font></td></tr>\n";
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
                $x++;
                $col_letter = get_next_field_letter ($col_letter); 
            }
            $row_num++;
        }
        
        # Handle last row..
        {
            # Add row to table if matched 
            $fake_row = $row;
            $fake_row =~ s/<[^>]*>//img;
            my $force_row = 0;
            if ($dual_groups)
            {
                $force_row = -1;
            }

            if ($use_regex && $fake_row =~ m/$overall_match/im && $overall_match ne ".*" && $overall_match ne "") 
            {
                $force_row = 1;
                if ($only_one_group == 1 && $fake_row =~ m/($group)/im) 
                {
                    my $this_group = $1;
                    $group_counts {$this_group}++;
                    $row .= " <td>$this_group</td>\n";
                    my $g_price = "GPRICE_$this_group";
                    $row .= " <td>$g_price</td> </tr>\n";
                }
                elsif ($first_group_only && $fake_row =~ m/$overall_match/im && ($fake_row =~ m/($group)/mg))
                {
                    my $this_group = $1;
                    if ($fake_row =~ m/($group2)/mg)
                    {
                        $group_counts {$this_group}++;
                        $row .= " <td>$this_group</td>\n";
                        my $g_price = "GPRICE_$this_group";
                        $row .= " <td>$g_price</td> </tr>\n";
                    }
                    else
                    {
                        $row .= "<td><font size=-3>No group</font></td>\n";
                        $row .= "<td><font size=-3>No group Total</font></td></tr>\n";
                    }
                }
                elsif ($dual_groups && $fake_row =~ m/($group)/im)
                {
                    my $this_group = $1;
                    if ($fake_row =~ m/($group2)/im)
                    {
                        $this_group .= " " . $1;
                        $group_counts {$this_group}++;
                        $row .= " <td>$this_group</td>\n";
                        my $g_price = "GPRICE_$this_group";
                        $row .= " <td>$g_price</td> </tr>\n";
                    }
                    else
                    {
                        $row .= "<td><font size=-3>No group</font></td>\n";
                        $row .= "<td><font size=-3>No group Total</font></td></tr>\n";
                    }
                }
            }
            else
            {
                $row .= "<td><font size=-3>No group</font></td>\n";
                $row .= "<td><font size=-3>No group Total</font></td></tr>\n";
            }

            if (($row =~ m/$search/im || $search eq "") && $force_row >= 0)
            {
                $overall_count++;
                $html_text .= "$row ";
            }
        }

        $html_text .= "</font></tbody>\n";
        $html_text .= "</table></div>\n";
        if ($use_regex != 1) { $overall_count .= "&nbsp;&nbsp;<font color=red>NB: Error with regex $overall_match</font>"; }
        $html_text =~ s/YYY/$overall_count/mg;

        my $group_block;
        
        for ($x = 0; $x < $max_field_num; $x++)
        {
            if (get_col_type ($x) eq "PRICE" || get_col_type ($x) eq "NUMBER")
            {
                $group_block .= "<button onclick=\"location.href='dograph_$x'\">Graph " . get_col_header ($x) . "</button>";

                my $str = "class=td.price";
                $html_text =~ s/XYZ$x/$str/;
            }
            else
            {
                $html_text =~ s/XYZ$x//;
            }
        }

        if (($only_one_group || $first_group_only || $dual_groups) && $use_regex)
        {
            $group_block .= "<button onclick=\"location.href='dograph_group_counts'\">Graph group counts</button>";
            $group_block .= "<button onclick=\"location.href='dograph_group_totals'\">Graph group totals</button>";
        }
        
        $group_block .= "<br>";

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
                if ($g_price =~ m/\./)
                {
                    $g_price = $g_price / 100;
                }
                else
                {
                    $g_price =~ s/(\d\d)$/.$1/;
                }
                
                my $replace_g_price = "GPRICE_$g";
                $html_text =~ s/$replace_g_price/$g_price/img;

                if ($g_count != 1)
                {
                    $group_block .= "<font color=$group_colours{$g}>Group $g had $g_count rows (total was $g_price)</font><br>";
                }
                else
                {
                    $group_block .= "<font color=$group_colours{$g}>Group $g had $g_count row (total was $g_price)</font><br>";
                }

                if ($get_group_info)
                {
                    my $g_calc = $group_prices {$g. "_calc"};
                    $group_block .= "<font color=$group_colours{$g}>Group $g had calculation of $g_calc</font><br>";
                }

                $total_g_count += $g_count;
                $total_g_price += $g_price;

                $meta_data {$g . "_total"} = $g_price;
                $meta_data {$g . "_count"} = $g_count;
            }
            $group_block .= "Total group row count: $total_g_count"; 
        }

        my $c;
        foreach $c (sort keys (%col_types))
        {
            if ($col_types{$c} eq "PRICE")
            {
                $col_calculations{$c} = $col_calculations{$c} / 100;
            }
        
            if ($get_group_info)
            {
                #$group_block .= "<br>" . get_col_header ($c) . ": $col_types{$c} ($col_calculations{$c})"; 
                $group_block .= "<br>Column $c (" . get_col_header ($c) . "): $col_types{$c} ($col_calculations{$c})"; 
            }
            #$group_block .= "<br>Column $c (" . get_col_header ($c) . "): $col_types{$c}";
        }

        if ($get_group_info)
        {
            my $col = $1;
            $group_block = "<a href=\"/csv_analyse$original_url\">Return to Sheet view</a><br>$group_block";
            write_to_socket (\*CLIENT, $group_block, "", "noredirect");
            next;
        }

        
        my $g_url = "No group info to view<br>";
        if ($group_count == 1)
        {
            $g_url = "<a href=\"/csv_analyse$original_url.group_info\">View group information</a><br>";
        }
        elsif ($group_count > 1)
        {
            $g_url = "<a href=\"/csv_analyse$original_url.group_info\">View all $group_count groups</a><br>";
        }
        $group_block =~ s/<br>/\n/img;
        $group_block =~ s/^((.*\n){0,7})(.*)\n/$1\nrest truncated../m;
        $group_block = "$g_url<font size=-1>$1$2</font>";
                                    
        $group_block =~ s/\n/<br>/img;
        $group_block = "<div style=\"-webkit-mask-image:linear-gradient(to bottom, black 0%, transparent 100%);mask-image:linear-gradient(to bottom, black 0%, transparent 100%);background-color: skyblue\">" .
                       #"<div style=\"max-width:640px\" class=\"mx-auto mb-6 px-4 md:px-0 text-lg font-n leading-8 text-gray-800\">" .
                       $group_block . #"</div>"
                       "</div>";
        $html_text =~ s/QQQ/$group_block/im;
        $html_text =~ s/QQQ//im;
        
        my $c = get_col_name_of_number_type_col ();
        $html_text =~ s/%23NUM_COL/$c/im;
        $html_text =~ s/%23NUM_COL/$c/im;

        $html_text .= "<br>$deck";
        $html_text .= "</body>\n";
        $html_text .= "</html>\n";

        write_to_socket (\*CLIENT, $html_text, "", "noredirect");
        $have_to_write_to_socket = 0;
        print ("============================================================\n");
    }
}
