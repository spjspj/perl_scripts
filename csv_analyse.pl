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
        $str =~ s/\.00(.+)/.0$1/;
        if (defined ($csv_data {$str}))
        {
            return ($csv_data {$str});
        }
        return ($csv_data {$str});
    }
    return ($csv_data {"0.$col_num"});
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
            my $x = get_field ($i, $col);
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

#    #process_csv_data ("Name;Set;Card_Number;Rarity;Casting_Cost;Type;Power;Toughness;Text;Set
#Bribery;Eighth Edition [8ED];64;Rare;{3}{U}{U};Sorcery; ; ;Search taret opponent's library for a creature card and put that card onto the battlefield under your control. Then that player shuffles their library.;Eighth Edition [8ED]
#Harrow;Commander 2014 Edition [C14];199;Common;{2}{G};Instant; ; ;As an additional cost to cast Harrow, sacrifice a land..Search your library for up to two basic land cards and put them onto the battlefield. Then shuffle your library.;Commander 2014 Edition [C14]
#Acid-Spewer Dragon;Dragons of Tarkir [DTK];86;Uncommon;{5}{B};Creature - Dragon;3;3;Flying, deathtouch\$Megamorph {5}{B}{B} (You may cast this card face down as a 2/2 creature for {3}. Turn it face up any time for its megamorph cost and put a +1/+1 counter on it.)\$When Acid-Spewer Dragon is turned face up, put a +1/+1 counter on each other Dragon creature you control.;Dragons of Tarkir [DTK]
#Acolyte of Bahamut;Commander Legends: Battle for Baldur's Gate;212;Uncommon;{1}{G};Legendary Enchantment - Background; ; ;Commander creatures you own have \"The first Dragon spell you cast each turn costs {2} less to cast.\";Commander Legends: Battle for Baldur's Gate
#Adult Gold Dragon;Adventures in the Forgotten Realms;216;Rare;{3}{R}{W};Creature - Dragon;4;3;Flying, lifelink, haste;Adventures in the Forgotten Realms
#Advent of the Wurm;Dragon's Maze [DGM];51;Rare;{1}{G}{G}{W};Instant; ; ;Put a 5/5 green Wurm creature token with trample onto the battlefield.;Dragon's Maze [DGM]
#Aetherling;Dragon's Maze [DGM];11;Rare;{4}{U}{U};Creature - Shapeshifter;4;5;{U}: Exile Aetherling. Return it to the battlefield under its owner's control at the beginning of the next end step.\${U}: Aetherling is unblockable this turn.\${1}: Aetherling gets +1/-1 until end of turn.\${1}: Aetherling gets -1/+1 until end of turn.;Dragon's Maze [DGM]
#Ainok Artillerist;Dragons of Tarkir [DTK];171;Common;{2}{G};Creature - Hound Arch;4;1;Ainok Artillerist has reach as long as it has a +1/+1 counter on it. (It can block creatures with flying.);Dragons of Tarkir [DTK]
#Ainok Survivalist;Dragons of Tarkir [DTK];172;Uncommon;{1}{G};Creature - Hound Shaman;2;1;Megamorph {1}{G} (You may cast this card face down for {3}. Turn it face up any time for its megamorph cost and put a +1/+1 counter on it.)\$When Ainok Survivalist is turned face up, destroy target artifact or enchantment an opponent controls.;Dragons of Tarkir [DTK]
#Akoum Hellkite;Battle for Zendikar [BFZ];139;Rare;{4}{R}{R};Creature - Dragon;4;4;Flying\$Landfall ? Whenever a land enters the battlefield under your control, Akoum Hellkite deals 1 damage to any target. If that land was a Mountain, Akoum Hellkite deals 2 damage to that creature or player instead.;Battle for Zendikar [BFZ]
#Alabaster Dragon;Portal [POR];163;Rare;{4}{W}{W};Creature - Dragon;4;4;Flying\$When Alabaster Dragon dies, shuffle it into its owner's library.;Portal [POR]
#Alaborn Cavalier;Duel Decks: Knights vs. Dragons [DDU] [DDG];18;Uncommon;{2}{W}{W};Creature - Human Knight;2;2;Whenever Alaborn Cavalier attacks, you may tap target creature.;Duel Decks: Knights vs. Dragons [DDU] [DDG]
#Alive;Dragon's Maze [DGM];121;Uncommon;{3}{G};Sorcery; ; ;Put a 3/3 green Centaur creature token onto the battlefield.\$Fuse (You may cast one or both halves of this card from your hand.);Dragon's Maze [DGM]
#Amareth, the Lustrous;Commander Legends;586;Rare;{3}{G}{W}{U};Legendary Creature - Dragon;6;6;Flying\$Whenever another permanent enters the battlefield under your control, look at the top card of your library. If it shares a card type with that permanent, you may reveal that card and put it into your hand.;Commander Legends
#Ambitious Dragonborn;Commander Legends: Battle for Baldur's Gate;213;Common;{3}{G};Creature - Dragon Barbarian;0;0;Ambitious Dragonborn enters the battlefield with X +1/+1 counters on it, where X is the greatest power among creatures you control and creature cards in your graveyard.;Commander Legends: Battle for Baldur's Gate
#Amethyst Dragon;Commander Legends: Battle for Baldur's Gate;160;Uncommon;{4}{R}{R};Creature - Dragon;4;4;Flying, haste;Commander Legends: Battle for Baldur's Gate
#Anafenza, Kin-Tree Spirit;Dragons of Tarkir [DTK];2;Rare;{W}{W};Legendary Creature - Spirit Soldier;2;2;Whenever another nontoken creature enters the battlefield under your control, bolster 1. (Choose a creature with the least toughness among creatures you control and put a +1/+1 counter on it.);Dragons of Tarkir [DTK]
#Ancestor Dragon;Global Series: Jiang Yanggu & Mu Yanling;12;Rare;{4}{W}{W};Creature - Dragon;5;6;Flying\$Whenever one or more creatures you control attack, you gain 1 life for each attacking creature.;Global Series: Jiang Yanggu & Mu Yanling
#Ancestral Statue;Dragons of Tarkir [DTK];234;Common;{4};Artifact Creature - Golem;3;4;When Ancestral Statue enters the battlefield, return a nonland permanent you control to its owner's hand.;Dragons of Tarkir [DTK]
#Ancient Brass Dragon;Commander Legends: Battle for Baldur's Gate;111;Mythic Rare;{5}{B}{B};Creature - Elder Dragon;7;6;Flying\$Whenever Ancient Brass Dragon deals combat damage to a player, roll a d20. When you do, put any number of target creature cards with total mana value X or less from graveyards onto the battlefield under your control, where X is the result.;Commander Legends: Battle for Baldur's Gate
#Ancient Bronze Dragon;Commander Legends: Battle for Baldur's Gate;214;Mythic Rare;{5}{G}{G};Creature - Elder Dragon;7;7;Flying\$Whenever Ancient Bronze Dragon deals combat damage to a player, roll a d20. When you do, put X +1/+1 counters on each of up to two target creatures, where X is the result.;Commander Legends: Battle for Baldur's Gate
#Ancient Carp;Dragons of Tarkir [DTK];44;Common;{4}{U};Creature - Fish;2;5; ;Dragons of Tarkir [DTK]
#Ancient Copper Dragon;Commander Legends: Battle for Baldur's Gate;161;Mythic Rare;{4}{R}{R};Creature - Elder Dragon;6;5;Flying\$Whenever Ancient Copper Dragon deals combat damage to a player, roll a d20. You create a number of Treasure tokens equal to the result.;Commander Legends: Battle for Baldur's Gate
#Ancient Gold Dragon;Commander Legends: Battle for Baldur's Gate;3;Mythic Rare;{5}{W}{W};Creature - Elder Dragon;7;10;Flying\$Whenever Ancient Gold Dragon deals combat damage to a player, roll a d20. You create a number of 1/1 blue Faerie Dragon creature tokens with flying equal to the result.;Commander Legends: Battle for Baldur's Gate
#Ancient Hellkite;Game Night: Free-for-All;68;Rare;{4}{R}{R}{R};Creature - Dragon;6;6;Flying\${R}: Ancient Hellkite deals 1 damage to target creature defending player controls. Activate only if Ancient Hellkite is attacking.;Game Night: Free-for-All
#Ancient Silver Dragon;Commander Legends: Battle for Baldur's Gate;56;Mythic Rare;{6}{U}{U};Creature - Elder Dragon;8;8;Flying\$Whenever Ancient Silver Dragon deals combat damage to a player, roll a d20. Draw cards equal to the result. You have no maximum hand size for the rest of the game.;Commander Legends: Battle for Baldur's Gate
#Anticipate;Dragons of Tarkir [DTK];45;Common;{1}{U};Instant; ; ;Look at the top three cards of your library. Put one of them into your hand and the rest on the bottom of your library in any order.;Dragons of Tarkir [DTK]
#Ao, the Dawn Sky;Kamigawa: Neon Dynasty;2;Mythic Rare;{3}{W}{W};Legendary Creature - Dragon Spirit;5;4;Flying, vigilance\$When Ao, the Dawn Sky dies, choose one -\$* Look at the top seven cards of your library. Put any number of nonland permanent cards with total mana value 4 or less from among them onto the battlefield. Put the rest on the bottom of your library in a random order.\$* Put two +1/+1 counters on each permanent you control that's a creature or Vehicle.;Kamigawa: Neon Dynasty
#Arashin Foremost;Dragons of Tarkir [DTK];3;Rare;{1}{W}{W};Creature - Human Warrior;2;2;Double strike\$Whenever Arashin Foremost enters the battlefield or attacks, another target Warrior creature you control gains double strike until end of turn.;Dragons of Tarkir [DTK]
#Arashin Sovereign;Dragons of Tarkir [DTK];212;Rare;{5}{G}{W};Creature - Dragon;6;6;Flying\$When Arashin Sovereign dies, you may put it on the top or bottom of its owner's library.;Dragons of Tarkir [DTK]
#Arcades Sabboth;Chronicles [CHR];106;Rare;{2}{G}{G}{W}{W}{U}{U};Legendary Creature - Elder Dragon;7;7;Flying\$At the beginning of your upkeep, sacrifice Arcades Sabboth unless you pay {G}{W}{U}.\$Each untapped creature you control gets +0/+2 as long as it's not attacking.\${W}: Arcades Sabboth gets +0/+1 until end of turn.;Chronicles [CHR]
#Arcades, the Strategist;Core Set 2019 [M19];212;Mythic Rare;{1}{G}{W}{U};Legendary Creature - Elder Dragon;3;5;Flying, vigilance\$Whenever a creature with defender enters the battlefield under your control, draw a card.\$Each creature you control with defender assigns combat damage equal to its toughness rather than its power and can attack as though it didn't have defender.;Core Set 2019 [M19]
#Arcbound Whelp;Jumpstart: Historic Horizons [JMP];410;Uncommon;{3}{R};Artifact Creature - Dragon;0;0;Flying\${R}: Arcbound Whelp gets +1/+0 until end of turn.\$Modular 2;Jumpstart: Historic Horizons [JMP]
#Archwing Dragon;Avacyn Restored [AVR];126;Rare;{2}{R}{R};Creature - Dragon;4;4;Flying, haste\$At the beginning of the end step, return Archwing Dragon to its owner's hand.;Avacyn Restored [AVR]
#Armed;Dragon's Maze [DGM];122;Uncommon;{1}{R};Sorcery; ; ;Target creature gets +1/+1 and gains double strike until end of turn.\$Fuse (You may cast one or both halves of this card from your hand.);Dragon's Maze [DGM]
#Armillary Sphere;Duel Decks: Knights vs. Dragons [DDU] [DDG];62;Common;{2};Artifact; ; ;{2}, {tap}, Sacrifice Armillary Sphere: Search your library for up to two basic land cards, reveal them, and put them into your hand. Then shuffle your library.;Duel Decks: Knights vs. Dragons [DDU] [DDG]
#Armored Wolf-Rider;Dragon's Maze [DGM];52;Common;{3}{G}{W};Creature - Elf Knight;4;6; ;Dragon's Maze [DGM]
#Artful Maneuver;Dragons of Tarkir [DTK];4;Common;{1}{W};Instant; ; ;Target creature gets +2/+2 until end of turn.\$Rebound (If you cast this spell from your hand, exile it as it resolves. At the beginning of your next upkeep, you may cast this card from exile without paying its mana cost.);Dragons of Tarkir [DTK]
#Artificer's Dragon;The Brothers' War;291;Rare;{6};Artifact Creature - Dragon;4;4;Flying\${R}: Artifact creatures you control get +1/+0 until end of turn.\$Unearth {3}{R}{R};The Brothers' War
#Ascended Lawmage;Dragon's Maze [DGM];53;Uncommon;{2}{W}{U};Creature - Vedalken Wizard;3;2;Flying, hexproof;Dragon's Maze [DGM]
#Ashmouth Dragon;Innistrad: Midnight Hunt [ISD];159;Rare; ;Creature - Dragon;4;4;Flying\$Whenever you cast an instant or sorcery spell, Ashmouth Dragon deals 2 damage to any target.;Innistrad: Midnight Hunt [ISD]
#Assault Formation;Dragons of Tarkir [DTK];173;Rare;{1}{G};Enchantment; ; ;Each creature you control assigns combat damage equal to its toughness rather than its power.\${G}: Target creature with defender can attack this turn as though it didn't have defender.\${2}{G}: Creatures you control get +0/+1 until end of turn.;Dragons of Tarkir [DTK]
#Astral Dragon;Commander Legends: Battle for Baldur's Gate;664;Rare;{6}{U}{U};Creature - Dragon;4;4;Flying\$Project Image - When Astral Dragon enters the battlefield, create two tokens that are copies of target noncreature permanent, except they're 3/3 Dragon creatures in addition to their other types, and they have flying.;Commander Legends: Battle for Baldur's Gate
#Atarka Beastbreaker;Dragons of Tarkir [DTK];174;Common;{1}{G};Creature - Human Warrior;2;2;Formidable - {4}{G}: Atarka Beastbreaker gets +4/+4 until end of turn. Activate this only if creatures you control have total power 8 or greater.;Dragons of Tarkir [DTK]
#Atarka Efreet;Dragons of Tarkir [DTK];128;Common;{3}{R};Creature - Efreet Shaman;5;1;Megamorph {2}{R} (You may cast this card face down as a 2/2 creature for {3}. Turn it face up any time for its megamorph cost and put a +1/+1 counter on it.)\$When Atarka Efreet is turned face up, it deals 1 damage to any target.;Dragons of Tarkir [DTK]
#Atarka Monument;Dragons of Tarkir [DTK];235;Uncommon;{3};Artifact; ; ;{T}: Add {R} or {G}.\${4}{R}{G}: Atarka Monument becomes a 4/4 red and green Dragon artifact creature with flying until end of turn.;Dragons of Tarkir [DTK]
#Atarka Pummeler;Dragons of Tarkir [DTK];129;Uncommon;{4}{R};Creature - Ogre Warrior;4;5;Formidable - {3}{R}{R}: Each creature you control can't be blocked this turn except by two or more creatures. Activate this ability only if creature you control have total power 8 or greater,;Dragons of Tarkir [DTK]
#Atarka, World Render;Commander 2017 Edition [C17];161;Rare;{5}{R}{G};Legendary Creature - Dragon;6;4;Flying, trample\$Whenever a Dragon you control attacks, it gains double strike until end of turn.;Commander 2017 Edition [C17]
#");

#    #process_csv_data ("c;c2;c3;i;j;x;y;dist_from_center;sin_value;thedate;circle;color;
#1;2;31;0;1;0;20.943951023932;0.20943951023932;20.7911690817759;2021-08-26T05:51:00.001[UTC];1;Banana;
#2;3;32;0;2;0;41.8879020478639;0.418879020478639;40.67366430758;2021-08-26T05:51:00.002[UTC];1;Banana;
#3;4;33;0;3;0;62.8318530717959;0.628318530717959;58.7785252292473;2021-08-26T05:51:00.003[UTC];1;Banana;
#4;5;34;0;4;0;83.7758040957278;0.837758040957278;74.3144825477394;2021-08-26T05:51:00.004[UTC];1;Banana;
#5;6;35;0;5;0;104.71975511966;1.0471975511966;86.6025403784439;2021-08-26T05:51:00.005[UTC];0;Blueberry;
#6;7;36;0;6;0;125.663706143592;1.25663706143592;95.1056516295154;2021-08-26T05:51:00.006[UTC];0;Blueberry;
#7;8;37;0;7;0;146.607657167524;1.46607657167524;99.4521895368273;2021-08-26T05:51:00.007[UTC];0;Blueberry;
#8;9;38;0;8;0;167.551608191456;1.67551608191456;99.4521895368273;2021-08-26T05:51:00.008[UTC];1;Blueberry;
#9;10;39;0;9;0;188.495559215388;1.88495559215388;95.1056516295154;2021-08-26T05:51:00.009[UTC];1;Blueberry;
#10;11;40;0;10;0;209.43951023932;2.0943951023932;86.6025403784439;2021-08-26T05:51:00.010[UTC];1;Banana;
#11;12;41;0;11;0;230.383461263251;2.30383461263251;74.3144825477394;2021-08-26T05:51:00.011[UTC];1;Banana;
#12;13;42;0;12;0;251.327412287183;2.51327412287183;58.7785252292473;2021-08-26T05:51:00.012[UTC];1;Banana;
#13;14;43;0;13;0;272.271363311115;2.72271363311115;40.67366430758;2021-08-26T05:51:00.013[UTC];1;Banana;
#14;15;44;0;14;0;293.215314335047;2.93215314335047;20.7911690817759;2021-08-26T05:51:00.014[UTC];1;Banana;
#15;16;45;0;15;0;314.159265358979;3.14159265358979;1.22460635382238e-014;2021-08-26T05:51:00.015[UTC];0;Blueberry;
#16;17;46;0;16;0;335.103216382911;3.35103216382911;-20.7911690817759;2021-08-26T05:51:00.016[UTC];0;Blueberry;
#17;18;47;0;17;0;356.047167406843;3.56047167406843;-40.67366430758;2021-08-26T05:51:00.017[UTC];1;Blueberry;
#18;19;48;0;18;0;376.991118430775;3.76991118430775;-58.7785252292473;2021-08-26T05:51:00.018[UTC];1;Blueberry;
#19;20;49;0;19;0;397.935069454707;3.97935069454707;-74.3144825477394;2021-08-26T05:51:00.019[UTC];1;Blueberry;
#20;21;50;0;20;0;418.879020478639;4.18879020478639;-86.6025403784438;2021-08-26T05:51:00.020[UTC];1;Banana;
#21;22;51;0;21;0;439.822971502571;4.39822971502571;-95.1056516295154;2021-08-26T05:51:00.021[UTC];1;Banana;
#22;23;52;0;22;0;460.766922526503;4.60766922526503;-99.4521895368273;2021-08-26T05:51:00.022[UTC];1;Banana;
#23;24;53;0;23;0;481.710873550435;4.81710873550435;-99.4521895368273;2021-08-26T05:51:00.023[UTC];1;Banana;
#24;25;54;0;24;0;502.654824574367;5.02654824574367;-95.1056516295154;2021-08-26T05:51:00.024[UTC];0;Blueberry;
#25;26;55;0;25;0;523.598775598299;5.23598775598299;-86.6025403784439;2021-08-26T05:51:00.025[UTC];0;Blueberry;
#26;27;56;0;26;0;544.542726622231;5.44542726622231;-74.3144825477394;2021-08-26T05:51:00.026[UTC];0;Blueberry;
#27;28;57;0;27;0;565.486677646163;5.65486677646163;-58.7785252292473;2021-08-26T05:51:00.027[UTC];1;Blueberry;
#28;29;58;0;28;0;586.430628670095;5.86430628670095;-40.67366430758;2021-08-26T05:51:00.028[UTC];1;Blueberry;
#30;31;60;1;0;20.943951023932;0;0.20943951023932;20.7911690817759;2021-08-26T05:51:00.030[UTC];1;Banana;
#31;32;61;1;1;20.943951023932;20.943951023932;0.296192195877224;29.1880338804062;2021-08-26T05:51:00.031[UTC];1;Banana;
#32;33;62;1;2;20.943951023932;41.8879020478639;0.468320982069382;45.1388688574176;2021-08-26T05:51:00.032[UTC];1;Banana;
#33;34;63;1;3;20.943951023932;62.8318530717959;0.662305884386407;61.4936851109183;2021-08-26T05:51:00.033[UTC];1;Banana;
#34;35;64;1;4;20.943951023932;83.7758040957278;0.863541222894346;76.0148232799513;2021-08-26T05:51:00.034[UTC];1;Banana;
#35;36;65;1;5;20.943951023932;104.71975511966;1.06793614962761;87.6207732201642;2021-08-26T05:51:00.035[UTC];1;Banana;
#36;37;66;1;6;20.943951023932;125.663706143592;1.27397080524774;95.6269796469826;2021-08-26T05:51:00.036[UTC];1;Banana;
#37;38;67;1;7;20.943951023932;146.607657167524;1.48096097938612;99.5967518247572;2021-08-26T05:51:00.037[UTC];1;Banana;
#38;39;68;1;8;20.943951023932;167.551608191456;1.68855531422681;99.3074419180788;2021-08-26T05:51:00.038[UTC];1;Banana;
#39;40;69;1;9;20.943951023932;188.495559215388;1.89655542835991;94.7408065604194;2021-08-26T05:51:00.039[UTC];1;Banana;
#40;41;70;1;10;20.943951023932;209.43951023932;2.10484102805364;86.0755287165195;2021-08-26T05:51:00.040[UTC];1;Banana;
#41;42;71;1;11;20.943951023932;230.383461263251;2.31333500185617;73.6754382996891;2021-08-26T05:51:00.041[UTC];1;Banana;
#42;43;72;1;12;20.943951023932;251.327412287183;2.5219856710827;58.0715247200825;2021-08-26T05:51:00.042[UTC];1;Banana;
#43;44;73;1;13;20.943951023932;272.271363311115;2.73075711779327;39.9375476033882;2021-08-26T05:51:00.043[UTC];1;Banana;
#44;45;74;1;14;20.943951023932;293.215314335047;2.93962360932643;20.0598738887047;2021-08-26T05:51:00.044[UTC];1;Banana;
#45;46;75;1;15;20.943951023932;314.159265358979;3.14856623076896;-0.69735206575545;2021-08-26T05:51:00.045[UTC];1;Banana;
#46;47;76;1;16;20.943951023932;335.103216382911;3.35757076939065;-21.4302922140791;2021-08-26T05:51:00.046[UTC];1;Banana;
#47;48;77;1;17;20.943951023932;356.047167406843;3.56662634015577;-41.2351471275857;2021-08-26T05:51:00.047[UTC];1;Banana;
#48;49;78;1;18;20.943951023932;376.991118430775;3.77572446637966;-59.2478337940025;2021-08-26T05:51:00.048[UTC];1;Banana;
#49;50;79;1;19;20.943951023932;397.935069454707;3.98485844900939;-74.6818942173325;2021-08-26T05:51:00.049[UTC];1;Banana;
#50;51;80;1;20;20.943951023932;418.879020478639;4.19402292413426;-86.862989507242;2021-08-26T05:51:00.050[UTC];1;Banana;
#51;52;81;1;21;20.943951023932;439.822971502571;4.40321354633005;-95.2584787070094;2021-08-26T05:51:00.051[UTC];1;Banana;
#52;53;82;1;22;20.943951023932;460.766922526503;4.61242675799884;-99.5007936036309;2021-08-26T05:51:00.052[UTC];1;Banana;
#53;54;83;1;23;20.943951023932;481.710873550435;4.82165961865016;-99.4035901664835;2021-08-26T05:51:00.053[UTC];1;Banana;
#54;55;84;1;24;20.943951023932;502.654824574367;5.03090967671236;-94.9699718756611;2021-08-26T05:51:00.054[UTC];1;Banana;
#55;56;85;1;25;20.943951023932;523.598775598299;5.24017487201077;-86.3924260346009;2021-08-26T05:51:00.055[UTC];1;Banana;
#56;57;86;1;26;20.943951023932;544.542726622231;5.44945346068454;-74.0444759543555;2021-08-26T05:51:00.056[UTC];1;Banana;
#57;58;87;1;27;20.943951023932;565.486677646163;5.6587439567433;-58.4644137469822;2021-08-26T05:51:00.057[UTC];1;Banana;
#58;59;88;1;28;20.943951023932;586.430628670095;5.86804508611595;-40.3318245005268;2021-08-26T05:51:00.058[UTC];1;Banana;
#60;61;90;2;0;41.8879020478639;0;0.418879020478639;40.67366430758;2021-08-26T05:51:00.060[UTC];1;Banana;
#61;62;91;2;1;41.8879020478639;20.943951023932;0.468320982069382;45.1388688574176;2021-08-26T05:51:00.061[UTC];1;Banana;
#62;63;92;2;2;41.8879020478639;41.8879020478639;0.592384391754449;55.834072759349;2021-08-26T05:51:00.062[UTC];1;Banana;
#63;64;93;2;3;41.8879020478639;62.8318530717959;0.755144893275932;68.5394183113249;2021-08-26T05:51:00.063[UTC];1;Banana;
#64;65;94;2;4;41.8879020478639;83.7758040957278;0.936641964138763;80.5573021616979;2021-08-26T05:51:00.064[UTC];1;Banana;
#65;66;95;2;5;41.8879020478639;104.71975511966;1.12786627976427;90.3499758617695;2021-08-26T05:51:00.065[UTC];1;Banana;
#66;67;96;2;6;41.8879020478639;125.663706143592;1.32461176877281;96.984932236204;2021-08-26T05:51:00.066[UTC];1;Banana;
#67;68;97;2;7;41.8879020478639;146.607657167524;1.52474264969934;99.8939716832716;2021-08-26T05:51:00.067[UTC];1;Banana;
#68;69;98;2;8;41.8879020478639;167.551608191456;1.72708244578869;98.781216251517;2021-08-26T05:51:00.068[UTC];1;Banana;
#69;70;99;2;9;41.8879020478639;188.495559215388;1.93093687576506;93.5847302653539;2021-08-26T05:51:00.069[UTC];1;Banana;
#70;71;100;2;10;41.8879020478639;209.43951023932;2.13587229925521;84.4547921129154;2021-08-26T05:51:00.070[UTC];1;Banana;
#71;72;101;2;11;41.8879020478639;230.383461263251;2.34160491034691;71.7347551480723;2021-08-26T05:51:00.071[UTC];1;Banana;
#72;73;102;2;12;41.8879020478639;251.327412287183;2.54794161049549;55.9391108226567;2021-08-26T05:51:00.072[UTC];1;Banana;
#73;74;103;2;13;41.8879020478639;272.271363311115;2.75474666017158;37.7269359687847;2021-08-26T05:51:00.073[UTC];1;Banana;
#74;75;104;2;14;41.8879020478639;293.215314335047;2.96192195877224;17.8705578897769;2021-08-26T05:51:00.074[UTC];1;Banana;
#75;76;105;2;15;41.8879020478639;314.159265358979;3.16939490043234;-2.77986652873387;2021-08-26T05:51:00.075[UTC];1;Banana;
#76;77;106;2;16;41.8879020478639;335.103216382911;3.37711062845362;-23.334669223776;2021-08-26T05:51:00.076[UTC];1;Banana;
#77;78;107;2;17;41.8879020478639;356.047167406843;3.58502694210808;-42.9044125372587;2021-08-26T05:51:00.077[UTC];1;Banana;
#78;79;108;2;18;41.8879020478639;376.991118430775;3.79311085671983;-60.6394324727199;2021-08-26T05:51:00.078[UTC];1;Banana;
#79;80;109;2;19;41.8879020478639;397.935069454707;4.00133622481158;-75.7675234238049;2021-08-26T05:51:00.079[UTC];1;Banana;
#80;81;110;2;20;41.8879020478639;418.879020478639;4.20968205610727;-87.6281579631197;2021-08-26T05:51:00.080[UTC];1;Banana;
#81;82;111;2;21;41.8879020478639;439.822971502571;4.41813130858877;-95.7017703068533;2021-08-26T05:51:00.081[UTC];1;Banana;
#82;83;112;2;22;41.8879020478639;460.766922526503;4.62667000371234;-99.63283775235;2021-08-26T05:51:00.082[UTC];1;Banana;
#83;84;113;2;23;41.8879020478639;481.710873550435;4.83528656890876;-99.2457591803936;2021-08-26T05:51:00.083[UTC];1;Banana;
#84;85;114;2;24;41.8879020478639;502.654824574367;5.04397134216541;-94.5528406056216;2021-08-26T05:51:00.084[UTC];1;Banana;
#85;86;115;2;25;41.8879020478639;523.598775598299;5.25271619398963;-85.7540403158672;2021-08-26T05:51:00.085[UTC];1;Banana;
#86;87;116;2;26;41.8879020478639;544.542726622231;5.46151423558655;-73.2284848821059;2021-08-26T05:51:00.086[UTC];1;Banana;
#87;88;117;2;27;41.8879020478639;565.486677646163;5.6703595911835;-57.5181262455921;2021-08-26T05:51:00.087[UTC];1;Banana;
#88;89;118;2;28;41.8879020478639;586.430628670095;5.87924721865286;-39.3042533014765;2021-08-26T05:51:00.088[UTC];1;Banana;
#90;91;120;3;0;62.8318530717959;0;0.628318530717959;58.7785252292473;2021-08-26T05:51:00.090[UTC];1;Banana;
#91;92;121;3;1;62.8318530717959;20.943951023932;0.662305884386407;61.4936851109183;2021-08-26T05:51:00.091[UTC];1;Banana;
#92;93;122;3;2;62.8318530717959;41.8879020478639;0.755144893275932;68.5394183113249;2021-08-26T05:51:00.092[UTC];1;Banana;
#93;94;123;3;3;62.8318530717959;62.8318530717959;0.888576587631673;77.6175047752483;2021-08-26T05:51:00.093[UTC];1;Banana;
#94;95;124;3;4;62.8318530717959;83.7758040957278;1.0471975511966;86.6025403784439;2021-08-26T05:51:00.094[UTC];1;Banana;
#95;96;125;3;5;62.8318530717959;104.71975511966;1.22123170908543;93.952191544281;2021-08-26T05:51:00.095[UTC];1;Banana;
#96;97;126;3;6;62.8318530717959;125.663706143592;1.40496294620815;98.6281128113019;2021-08-26T05:51:00.096[UTC];1;Banana;
#97;98;127;3;7;62.8318530717959;146.607657167524;1.59504378938592;99.9706044681699;2021-08-26T05:51:00.097[UTC];1;Banana;
#98;99;128;3;8;62.8318530717959;167.551608191456;1.78945195990222;97.6189948042006;2021-08-26T05:51:00.098[UTC];1;Banana;
#99;100;129;3;9;62.8318530717959;188.495559215388;1.98691765315922;91.4663637769473;2021-08-26T05:51:00.099[UTC];1;Banana;
#100;101;130;3;10;62.8318530717959;209.43951023932;2.18661268197461;81.6302171711484;2021-08-26T05:51:00.100[UTC];1;Banana;
#101;102;131;3;11;62.8318530717959;230.383461263251;2.38797782619671;68.4279229755372;2021-08-26T05:51:00.101[UTC];1;Banana;
#102;103;132;3;12;62.8318530717959;251.327412287183;2.59062366868304;52.3513066812103;2021-08-26T05:51:00.102[UTC];1;Banana;
#103;104;133;3;13;62.8318530717959;272.271363311115;2.79427158736815;34.0380062740337;2021-08-26T05:51:00.103[UTC];1;Banana;
#104;105;134;3;14;62.8318530717959;293.215314335047;2.99871743118681;14.2389625143207;2021-08-26T05:51:00.104[UTC];1;Banana;
#105;106;135;3;15;62.8318530717959;314.159265358979;3.20380844888282;-6.21756655233814;2021-08-26T05:51:00.105[UTC];1;Banana;
#106;107;136;3;16;62.8318530717959;335.103216382911;3.40942821292087;-26.4644788602053;2021-08-26T05:51:00.106[UTC];1;Banana;
#107;108;137;3;17;62.8318530717959;356.047167406843;3.61548651192163;-45.6354483856911;2021-08-26T05:51:00.107[UTC];1;Banana;
#108;109;138;3;18;62.8318530717959;376.991118430775;3.82191241574323;-62.904163019487;2021-08-26T05:51:00.108[UTC];1;Banana;
#109;110;139;3;19;62.8318530717959;397.935069454707;4.02864941714166;-77.5215876039641;2021-08-26T05:51:00.109[UTC];1;Banana;
#110;111;140;3;20;62.8318530717959;418.879020478639;4.23565196348307;-88.8496975811155;2021-08-26T05:51:00.110[UTC];1;Banana;
#111;112;141;3;21;62.8318530717959;439.822971502571;4.44288293815837;-96.3902532849877;2021-08-26T05:51:00.111[UTC];1;Banana;
#112;113;142;3;22;62.8318530717959;460.766922526503;4.65031180304052;-99.8073830698998;2021-08-26T05:51:00.112[UTC];1;Banana;
#113;114;143;3;23;62.8318530717959;481.710873550435;4.85791320895257;-98.9430022850545;2021-08-26T05:51:00.113[UTC];1;Banana;
#114;115;144;3;24;62.8318530717959;502.654824574367;5.06566594268042;-93.8244007958212;2021-08-26T05:51:00.114[UTC];1;Banana;
#115;116;145;3;25;62.8318530717959;523.598775598299;5.27355211947766;-84.663669459778;2021-08-26T05:51:00.115[UTC];1;Banana;
#116;117;146;3;26;62.8318530717959;544.542726622231;5.48155655701562;-71.848990005426;2021-08-26T05:51:00.116[UTC];1;Banana;
#117;118;147;3;27;62.8318530717959;565.486677646163;5.68966628507974;-55.9281670641689;2021-08-26T05:51:00.117[UTC];1;Banana;
#118;119;148;3;28;62.8318530717959;586.430628670095;5.89787015797091;-37.5851197885242;2021-08-26T05:51:00.118[UTC];1;Banana;
#120;121;150;4;0;83.7758040957278;0;0.837758040957278;74.3144825477394;2021-08-26T05:51:00.120[UTC];1;Banana;
#121;122;151;4;1;83.7758040957278;20.943951023932;0.863541222894346;76.0148232799513;2021-08-26T05:51:00.121[UTC];1;Banana;
#122;123;152;4;2;83.7758040957278;41.8879020478639;0.936641964138763;80.5573021616979;2021-08-26T05:51:00.122[UTC];1;Banana;
#123;124;153;4;3;83.7758040957278;62.8318530717959;1.0471975511966;86.6025403784439;2021-08-26T05:51:00.123[UTC];1;Banana;
#124;125;154;4;4;83.7758040957278;83.7758040957278;1.1847687835089;92.6412040193836;2021-08-26T05:51:00.124[UTC];1;Banana;
#125;126;155;4;5;83.7758040957278;104.71975511966;1.34106720428945;97.3728113263811;2021-08-26T05:51:00.125[UTC];1;Banana;
#126;127;156;4;6;83.7758040957278;125.663706143592;1.51028978655186;99.8170037693437;2021-08-26T05:51:00.126[UTC];1;Banana;
#127;128;157;4;7;83.7758040957278;146.607657167524;1.68855531422681;99.3074419180788;2021-08-26T05:51:00.127[UTC];1;Banana;
#128;129;158;4;8;83.7758040957278;167.551608191456;1.87328392827753;95.4598397493016;2021-08-26T05:51:00.128[UTC];1;Banana;
#129;130;159;4;9;83.7758040957278;188.495559215388;2.06273995442488;88.1416471117648;2021-08-26T05:51:00.129[UTC];1;Banana;
#130;131;160;4;10;83.7758040957278;209.43951023932;2.25573255952854;77.4459389345857;2021-08-26T05:51:00.130[UTC];1;Banana;
#131;132;161;4;11;83.7758040957278;230.383461263251;2.45142661679933;63.6665228660274;2021-08-26T05:51:00.131[UTC];1;Banana;
#132;133;162;4;12;83.7758040957278;251.327412287183;2.64922353754563;47.2714914404474;2021-08-26T05:51:00.132[UTC];1;Banana;
#133;134;163;4;13;83.7758040957278;272.271363311115;2.8486853218841;28.8736945465341;2021-08-26T05:51:00.133[UTC];1;Banana;
#134;135;164;4;14;83.7758040957278;293.215314335047;3.04948529939868;9.19771732379936;2021-08-26T05:51:00.134[UTC];1;Banana;
#135;136;165;4;15;83.7758040957278;314.159265358979;3.25137554525434;-10.9562502097669;2021-08-26T05:51:00.135[UTC];1;Banana;
#136;137;166;4;16;83.7758040957278;335.103216382911;3.45416489157738;-30.7507253131787;2021-08-26T05:51:00.136[UTC];1;Banana;
#137;138;167;4;17;83.7758040957278;356.047167406843;3.65770379842767;-49.3501566050665;2021-08-26T05:51:00.137[UTC];1;Banana;
#138;139;168;4;18;83.7758040957278;376.991118430775;3.86187375153011;-65.9595976959684;2021-08-26T05:51:00.138[UTC];1;Banana;
#139;140;169;4;19;83.7758040957278;397.935069454707;4.06657970355689;-79.8612969354075;2021-08-26T05:51:00.139[UTC];1;Banana;
#140;141;170;4;20;83.7758040957278;418.879020478639;4.27174459851042;-90.447700772903;2021-08-26T05:51:00.140[UTC];1;Banana;
#141;142;171;4;21;83.7758040957278;439.822971502571;4.47730534600039;-97.2494864251707;2021-08-26T05:51:00.141[UTC];1;Banana;
#142;143;172;4;22;83.7758040957278;460.766922526503;4.68320982069382;-99.9574318524082;2021-08-26T05:51:00.142[UTC];1;Banana;
#143;144;173;4;23;83.7758040957278;481.710873550435;4.88941459735835;-98.4371842520433;2021-08-26T05:51:00.143[UTC];1;Banana;
#144;145;174;4;24;83.7758040957278;502.654824574367;5.09588322099097;-92.7362883487439;2021-08-26T05:51:00.144[UTC];1;Banana;
#145;146;175;4;25;83.7758040957278;523.598775598299;5.30258487117296;-83.0831677158593;2021-08-26T05:51:00.145[UTC];1;Banana;
#146;147;176;4;26;83.7758040957278;544.542726622231;5.50949332034316;-69.8781004924702;2021-08-26T05:51:00.146[UTC];1;Banana;
#147;148;177;4;27;83.7758040957278;565.486677646163;5.71658611364493;-53.6765791423318;2021-08-26T05:51:00.147[UTC];1;Banana;
#148;149;178;4;28;83.7758040957278;586.430628670095;5.92384391754449;-35.1657765568525;2021-08-26T05:51:00.148[UTC];1;Banana;
#150;151;180;5;0;104.71975511966;0;1.0471975511966;86.6025403784439;2021-08-26T05:51:00.150[UTC];0;Blueberry;
#151;152;181;5;1;104.71975511966;20.943951023932;1.06793614962761;87.6207732201642;2021-08-26T05:51:00.151[UTC];1;Banana;
#152;153;182;5;2;104.71975511966;41.8879020478639;1.12786627976427;90.3499758617695;2021-08-26T05:51:00.152[UTC];1;Banana;
#153;154;183;5;3;104.71975511966;62.8318530717959;1.22123170908543;93.952191544281;2021-08-26T05:51:00.153[UTC];1;Banana;
#154;155;184;5;4;104.71975511966;83.7758040957278;1.34106720428945;97.3728113263811;2021-08-26T05:51:00.154[UTC];1;Banana;
#155;156;185;5;5;104.71975511966;104.71975511966;1.48096097938612;99.5967518247572;2021-08-26T05:51:00.155[UTC];0;Blueberry;
#156;157;186;5;6;104.71975511966;125.663706143592;1.63577486696869;99.7889637348202;2021-08-26T05:51:00.156[UTC];1;Blueberry;
#157;158;187;5;7;104.71975511966;146.607657167524;1.80166679084873;97.3467579913892;2021-08-26T05:51:00.157[UTC];1;Blueberry;
#158;159;188;5;8;104.71975511966;167.551608191456;1.97584838790492;91.9081882866202;2021-08-26T05:51:00.158[UTC];1;Blueberry;
#159;160;189;5;9;104.71975511966;188.495559215388;2.15631173433349;83.3427367439484;2021-08-26T05:51:00.159[UTC];0;Blueberry;
#160;161;190;5;10;104.71975511966;209.43951023932;2.34160491034691;71.7347551480723;2021-08-26T05:51:00.160[UTC];1;Banana;
#161;162;191;5;11;104.71975511966;230.383461263251;2.53066723090883;57.3625735554462;2021-08-26T05:51:00.161[UTC];1;Banana;
#162;163;192;5;12;104.71975511966;251.327412287183;2.72271363311115;40.67366430758;2021-08-26T05:51:00.162[UTC];1;Banana;
#163;164;193;5;13;104.71975511966;272.271363311115;2.91715481919652;22.2558331185803;2021-08-26T05:51:00.163[UTC];1;Banana;
#164;165;194;5;14;104.71975511966;293.215314335047;3.11354215762244;2.80468176152606;2021-08-26T05:51:00.164[UTC];1;Banana;
#165;166;195;5;15;104.71975511966;314.159265358979;3.31152942193203;-16.9120028570147;2021-08-26T05:51:00.165[UTC];0;Blueberry;
#166;167;196;5;16;104.71975511966;335.103216382911;3.51084594852143;-36.0919157662648;2021-08-26T05:51:00.166[UTC];1;Blueberry;
#167;168;197;5;17;104.71975511966;356.047167406843;3.71127757693706;-53.9366758611645;2021-08-26T05:51:00.167[UTC];1;Blueberry;
#168;169;198;5;18;104.71975511966;376.991118430775;3.91265294254433;-69.6896039936078;2021-08-26T05:51:00.168[UTC];1;Blueberry;
#169;170;199;5;19;104.71975511966;397.935069454707;4.11483349133649;-82.6713422294605;2021-08-26T05:51:00.169[UTC];0;Blueberry;
#170;171;200;5;20;104.71975511966;418.879020478639;4.31770611447173;-92.3118553739974;2021-08-26T05:51:00.170[UTC];1;Banana;
#171;172;201;5;21;104.71975511966;439.822971502571;4.52117764939261;-98.1774744082102;2021-08-26T05:51:00.171[UTC];1;Banana;
#172;173;202;5;22;104.71975511966;460.766922526503;4.72517072714697;-99.9918314586961;2021-08-26T05:51:00.172[UTC];1;Banana;
#173;174;203;5;23;104.71975511966;481.710873550435;4.92962060212593;-97.6497851106161;2021-08-26T05:51:00.173[UTC];1;Banana;
#174;175;204;5;24;104.71975511966;502.654824574367;5.13447270691168;-91.223729737734;2021-08-26T05:51:00.174[UTC];0;Blueberry;
#175;176;205;5;25;104.71975511966;523.598775598299;5.33968074813803;-80.9620083947223;2021-08-26T05:51:00.175[UTC];0;Blueberry;
#176;177;206;5;26;104.71975511966;544.542726622231;5.54520521017478;-67.2794902239219;2021-08-26T05:51:00.176[UTC];1;Blueberry;
#177;178;207;5;27;104.71975511966;565.486677646163;5.75101216924131;-50.7407144810069;2021-08-26T05:51:00.177[UTC];1;Blueberry;
#178;179;208;5;28;104.71975511966;586.430628670095;5.95707234599953;-32.0363286348913;2021-08-26T05:51:00.178[UTC];1;Blueberry;
#180;181;210;6;0;125.663706143592;0;1.25663706143592;95.1056516295154;2021-08-26T05:51:00.180[UTC];0;Blueberry;
#181;182;211;6;1;125.663706143592;20.943951023932;1.27397080524774;95.6269796469826;2021-08-26T05:51:00.181[UTC];1;Banana;
#182;183;212;6;2;125.663706143592;41.8879020478639;1.32461176877281;96.984932236204;2021-08-26T05:51:00.182[UTC];1;Banana;
#183;184;213;6;3;125.663706143592;62.8318530717959;1.40496294620815;98.6281128113019;2021-08-26T05:51:00.183[UTC];1;Banana;
#184;185;214;6;4;125.663706143592;83.7758040957278;1.51028978655186;99.8170037693437;2021-08-26T05:51:00.184[UTC];1;Banana;
#185;186;215;6;5;125.663706143592;104.71975511966;1.63577486696869;99.7889637348202;2021-08-26T05:51:00.185[UTC];1;Blueberry;
#186;187;216;6;6;125.663706143592;125.663706143592;1.77715317526335;97.8783873571128;2021-08-26T05:51:00.186[UTC];1;Blueberry;
#187;188;217;6;7;125.663706143592;146.607657167524;1.93093687576506;93.5847302653539;2021-08-26T05:51:00.187[UTC];1;Blueberry;
#188;189;218;6;8;125.663706143592;167.551608191456;2.0943951023932;86.6025403784439;2021-08-26T05:51:00.188[UTC];0;Blueberry;
#189;190;219;6;9;125.663706143592;188.495559215388;2.2654346798278;76.8285245012696;2021-08-26T05:51:00.189[UTC];0;Blueberry;
#190;191;220;6;10;125.663706143592;209.43951023932;2.44246341817086;64.3551445602178;2021-08-26T05:51:00.190[UTC];1;Banana;
#191;192;221;6;11;125.663706143592;230.383461263251;2.62426954151777;49.4555305679245;2021-08-26T05:51:00.191[UTC];1;Banana;
#192;193;222;6;12;125.663706143592;251.327412287183;2.80992589241629;32.5619404200757;2021-08-26T05:51:00.192[UTC];1;Banana;
#193;194;223;6;13;125.663706143592;272.271363311115;2.99871743118681;14.2389625143207;2021-08-26T05:51:00.193[UTC];1;Banana;
#194;195;224;6;14;125.663706143592;293.215314335047;3.19008757877184;-4.84759193641976;2021-08-26T05:51:00.194[UTC];1;Banana;
#195;196;225;6;15;125.663706143592;314.159265358979;3.38359883929281;-23.9650831127554;2021-08-26T05:51:00.195[UTC];0;Blueberry;
#196;197;226;6;16;125.663706143592;335.103216382911;3.57890391980443;-42.350529201388;2021-08-26T05:51:00.196[UTC];1;Blueberry;
#197;198;227;6;17;125.663706143592;356.047167406843;3.77572446637966;-59.2478337940025;2021-08-26T05:51:00.197[UTC];1;Blueberry;
#198;199;228;6;18;125.663706143592;376.991118430775;3.97383530631844;-73.9443026097172;2021-08-26T05:51:00.198[UTC];1;Blueberry;
#199;200;229;6;19;125.663706143592;397.935069454707;4.17305267812025;-85.804972332415;2021-08-26T05:51:00.199[UTC];0;Blueberry;
#200;201;230;6;20;125.663706143592;418.879020478639;4.37322536394921;-94.3033258872587;2021-08-26T05:51:00.200[UTC];1;Banana;
#201;202;231;6;21;125.663706143592;439.822971502571;4.57422794909802;-99.0470937131299;2021-08-26T05:51:00.201[UTC];1;Banana;
#202;203;232;6;22;125.663706143592;460.766922526503;4.77595565239343;-99.7980319322933;2021-08-26T05:51:00.202[UTC];1;Banana;
#203;204;233;6;23;125.663706143592;481.710873550435;4.97832032656062;-96.4848154157926;2021-08-26T05:51:00.203[UTC];1;Banana;
#204;205;234;6;24;125.663706143592;502.654824574367;5.18124733736608;-89.2084741536787;2021-08-26T05:51:00.204[UTC];0;Blueberry;
#205;206;235;6;25;125.663706143592;523.598775598299;5.38467310846054;-78.2401210894113;2021-08-26T05:51:00.205[UTC];0;Blueberry;
#206;207;236;6;26;125.663706143592;544.542726622231;5.5885431747363;-64.0110537028509;2021-08-26T05:51:00.206[UTC];1;Blueberry;
#207;208;237;6;27;125.663706143592;565.486677646163;5.79281062729517;-47.0956447502496;2021-08-26T05:51:00.207[UTC];1;Blueberry;
#208;209;238;6;28;125.663706143592;586.430628670095;5.99743486237363;-28.1877545161062;2021-08-26T05:51:00.208[UTC];1;Blueberry;
#210;211;240;7;0;146.607657167524;0;1.46607657167524;99.4521895368273;2021-08-26T05:51:00.210[UTC];0;Blueberry;
#211;212;241;7;1;146.607657167524;20.943951023932;1.48096097938612;99.5967518247572;2021-08-26T05:51:00.211[UTC];1;Banana;
#212;213;242;7;2;146.607657167524;41.8879020478639;1.52474264969934;99.8939716832716;2021-08-26T05:51:00.212[UTC];1;Banana;
#213;214;243;7;3;146.607657167524;62.8318530717959;1.59504378938592;99.9706044681699;2021-08-26T05:51:00.213[UTC];1;Banana;
#214;215;244;7;4;146.607657167524;83.7758040957278;1.68855531422681;99.3074419180788;2021-08-26T05:51:00.214[UTC];1;Banana;
#215;216;245;7;5;146.607657167524;104.71975511966;1.80166679084873;97.3467579913892;2021-08-26T05:51:00.215[UTC];1;Blueberry;
#216;217;246;7;6;146.607657167524;125.663706143592;1.93093687576506;93.5847302653539;2021-08-26T05:51:00.216[UTC];1;Blueberry;
#217;218;247;7;7;146.607657167524;146.607657167524;2.07334537114057;87.6357635154891;2021-08-26T05:51:00.217[UTC];0;Blueberry;
#218;219;248;7;8;146.607657167524;167.551608191456;2.2263725327917;79.2696795260822;2021-08-26T05:51:00.218[UTC];0;Blueberry;
#219;220;249;7;9;146.607657167524;188.495559215388;2.38797782619671;68.4279229755371;2021-08-26T05:51:00.219[UTC];0;Blueberry;
#220;221;250;7;10;146.607657167524;209.43951023932;2.55653502986828;55.2247423006471;2021-08-26T05:51:00.220[UTC];1;Banana;
#221;222;251;7;11;146.607657167524;230.383461263251;2.73075711779327;39.9375476033883;2021-08-26T05:51:00.221[UTC];1;Banana;
#222;223;252;7;12;146.607657167524;251.327412287183;2.90962666517755;22.9891298573043;2021-08-26T05:51:00.222[UTC];1;Banana;
#223;224;253;7;13;146.607657167524;272.271363311115;3.09233731050549;4.9235429193879;2021-08-26T05:51:00.223[UTC];1;Banana;
#224;225;254;7;14;146.607657167524;293.215314335047;3.27824687448567;-13.6229295798029;2021-08-26T05:51:00.224[UTC];1;Banana;
#225;226;255;7;15;146.607657167524;314.159265358979;3.46684076864;-31.9543902433653;2021-08-26T05:51:00.225[UTC];0;Blueberry;
#226;227;256;7;16;146.607657167524;335.103216382911;3.65770379842767;-49.3501566050665;2021-08-26T05:51:00.226[UTC];1;Blueberry;
#227;228;257;7;17;146.607657167524;356.047167406843;3.85049854640392;-65.10036518636;2021-08-26T05:51:00.227[UTC];1;Blueberry;
#228;229;258;7;18;146.607657167524;376.991118430775;4.04494880704116;-78.5408712550093;2021-08-26T05:51:00.228[UTC];0;Blueberry;
#229;230;259;7;19;146.607657167524;397.935069454707;4.240826860909;-89.0859738186452;2021-08-26T05:51:00.229[UTC];0;Blueberry;
#230;231;260;7;20;146.607657167524;418.879020478639;4.4379436559886;-96.2575670029477;2021-08-26T05:51:00.230[UTC];1;Banana;
#231;232;261;7;21;146.607657167524;439.822971502571;4.63614119070485;-99.7094545320055;2021-08-26T05:51:00.231[UTC];1;Banana;
#232;233;262;7;22;146.607657167524;460.766922526503;4.83528656890876;-99.2457591803936;2021-08-26T05:51:00.232[UTC];1;Banana;
#233;234;263;7;23;146.607657167524;481.710873550435;5.03526732991282;-94.8326054665715;2021-08-26T05:51:00.233[UTC];1;Banana;
#234;235;264;7;24;146.607657167524;502.654824574367;5.23598775598299;-86.6025403784439;2021-08-26T05:51:00.234[UTC];0;Blueberry;
#235;236;265;7;25;146.607657167524;523.598775598299;5.43736593350298;-74.8514704971479;2021-08-26T05:51:00.235[UTC];0;Blueberry;
#236;237;266;7;26;146.607657167524;544.542726622231;5.63933139882135;-60.0282202305846;2021-08-26T05:51:00.236[UTC];1;Blueberry;
#237;238;267;7;27;146.607657167524;565.486677646163;5.84182324052556;-42.7171401648773;2021-08-26T05:51:00.237[UTC];1;Blueberry;
#238;239;268;7;28;146.607657167524;586.430628670095;6.04478856026042;-23.6145020995794;2021-08-26T05:51:00.238[UTC];0;Blueberry;
#240;241;270;8;0;167.551608191456;0;1.67551608191456;99.4521895368273;2021-08-26T05:51:00.240[UTC];1;Blueberry;
#241;242;271;8;1;167.551608191456;20.943951023932;1.68855531422681;99.3074419180788;2021-08-26T05:51:00.241[UTC];1;Banana;
#242;243;272;8;2;167.551608191456;41.8879020478639;1.72708244578869;98.781216251517;2021-08-26T05:51:00.242[UTC];1;Banana;
#243;244;273;8;3;167.551608191456;62.8318530717959;1.78945195990222;97.6189948042006;2021-08-26T05:51:00.243[UTC];1;Banana;
#244;245;274;8;4;167.551608191456;83.7758040957278;1.87328392827753;95.4598397493016;2021-08-26T05:51:00.244[UTC];1;Banana;
#245;246;275;8;5;167.551608191456;104.71975511966;1.97584838790492;91.9081882866202;2021-08-26T05:51:00.245[UTC];1;Blueberry;
#246;247;276;8;6;167.551608191456;125.663706143592;2.0943951023932;86.6025403784439;2021-08-26T05:51:00.246[UTC];0;Blueberry;
#247;248;277;8;7;167.551608191456;146.607657167524;2.2263725327917;79.2696795260822;2021-08-26T05:51:00.247[UTC];0;Blueberry;
#248;249;278;8;8;167.551608191456;167.551608191456;2.3695375670178;69.7609136144272;2021-08-26T05:51:00.248[UTC];0;Blueberry;
#249;250;279;8;9;167.551608191456;188.495559215388;2.5219856710827;58.0715247200825;2021-08-26T05:51:00.249[UTC];1;Blueberry;
#250;251;280;8;10;167.551608191456;209.43951023932;2.6821344085789;44.3462600929183;2021-08-26T05:51:00.250[UTC];1;Banana;
#251;252;281;8;11;167.551608191456;230.383461263251;2.8486853218841;28.8736945465341;2021-08-26T05:51:00.251[UTC];1;Banana;
#252;253;282;8;12;167.551608191456;251.327412287183;3.02057957310373;12.0717940740021;2021-08-26T05:51:00.252[UTC];1;Banana;
#253;254;283;8;13;167.551608191456;272.271363311115;3.19695537483457;-5.53344441700427;2021-08-26T05:51:00.253[UTC];1;Banana;
#254;255;284;8;14;167.551608191456;293.215314335047;3.37711062845362;-23.334669223776;2021-08-26T05:51:00.254[UTC];1;Banana;
#255;256;285;8;15;167.551608191456;314.159265358979;3.56047167406843;-40.67366430758;2021-08-26T05:51:00.255[UTC];1;Blueberry;
#256;257;286;8;16;167.551608191456;335.103216382911;3.74656785655505;-56.874168047095;2021-08-26T05:51:00.256[UTC];1;Blueberry;
#257;258;287;8;17;167.551608191456;356.047167406843;3.93501114135627;-71.2755203721435;2021-08-26T05:51:00.257[UTC];1;Blueberry;
#258;259;288;8;18;167.551608191456;376.991118430775;4.12547990884975;-83.2656379151013;2021-08-26T05:51:00.258[UTC];0;Blueberry;
#259;260;289;8;19;167.551608191456;397.935069454707;4.31770611447173;-92.3118553739974;2021-08-26T05:51:00.259[UTC];0;Blueberry;
#260;261;290;8;20;167.551608191456;418.879020478639;4.51146511905708;-97.9882616702586;2021-08-26T05:51:00.260[UTC];1;Banana;
#261;262;291;8;21;167.551608191456;439.822971502571;4.70656762055847;-99.9983055932737;2021-08-26T05:51:00.261[UTC];1;Banana;
#262;263;292;8;22;167.551608191456;460.766922526503;4.90285323359865;-98.1916450945244;2021-08-26T05:51:00.262[UTC];1;Banana;
#263;264;293;8;23;167.551608191456;481.710873550435;5.10018536039884;-92.5744604318201;2021-08-26T05:51:00.263[UTC];1;Banana;
#264;265;294;8;24;167.551608191456;502.654824574367;5.29844707509125;-83.3127340055504;2021-08-26T05:51:00.264[UTC];0;Blueberry;
#265;266;295;8;25;167.551608191456;523.598775598299;5.49753780537779;-70.7283068080956;2021-08-26T05:51:00.265[UTC];0;Blueberry;
#266;267;296;8;26;167.551608191456;544.542726622231;5.6973706437682;-55.2878393746244;2021-08-26T05:51:00.266[UTC];1;Blueberry;
#267;268;297;8;27;167.551608191456;565.486677646163;5.89787015797091;-37.5851197885242;2021-08-26T05:51:00.267[UTC];1;Blueberry;
#268;269;298;8;28;167.551608191456;586.430628670095;6.09897059879735;-18.3174585290616;2021-08-26T05:51:00.268[UTC];0;Blueberry;
#270;271;300;9;0;188.495559215388;0;1.88495559215388;95.1056516295154;2021-08-26T05:51:00.270[UTC];1;Blueberry;
#271;272;301;9;1;188.495559215388;20.943951023932;1.89655542835991;94.7408065604194;2021-08-26T05:51:00.271[UTC];1;Banana;
#272;273;302;9;2;188.495559215388;41.8879020478639;1.93093687576506;93.5847302653539;2021-08-26T05:51:00.272[UTC];1;Banana;
#273;274;303;9;3;188.495559215388;62.8318530717959;1.98691765315922;91.4663637769473;2021-08-26T05:51:00.273[UTC];1;Banana;
#274;275;304;9;4;188.495559215388;83.7758040957278;2.06273995442488;88.1416471117648;2021-08-26T05:51:00.274[UTC];1;Banana;
#275;276;305;9;5;188.495559215388;104.71975511966;2.15631173433349;83.3427367439484;2021-08-26T05:51:00.275[UTC];0;Blueberry;
#276;277;306;9;6;188.495559215388;125.663706143592;2.2654346798278;76.8285245012696;2021-08-26T05:51:00.276[UTC];0;Blueberry;
#277;278;307;9;7;188.495559215388;146.607657167524;2.38797782619671;68.4279229755371;2021-08-26T05:51:00.277[UTC];0;Blueberry;
#278;279;308;9;8;188.495559215388;167.551608191456;2.5219856710827;58.0715247200825;2021-08-26T05:51:00.278[UTC];1;Blueberry;
#279;280;309;9;9;188.495559215388;188.495559215388;2.66572976289502;45.8105639235546;2021-08-26T05:51:00.279[UTC];1;Blueberry;
#280;281;310;9;10;188.495559215388;209.43951023932;2.81772043136305;31.8239843595852;2021-08-26T05:51:00.280[UTC];1;Banana;
#281;282;311;9;11;188.495559215388;230.383461263251;2.97669472851278;16.4151641557304;2021-08-26T05:51:00.281[UTC];1;Banana;
#282;283;312;9;12;188.495559215388;251.327412287183;3.14159265358979;1.22460635382238e-014;2021-08-26T05:51:00.282[UTC];1;Banana;
#283;284;313;9;13;188.495559215388;272.271363311115;3.31152942193203;-16.9120028570147;2021-08-26T05:51:00.283[UTC];1;Banana;
#284;285;314;9;14;188.495559215388;293.215314335047;3.48576815644016;-33.7420648355146;2021-08-26T05:51:00.284[UTC];1;Banana;
#285;286;315;9;15;188.495559215388;314.159265358979;3.6636951272563;-49.8703605269115;2021-08-26T05:51:00.285[UTC];1;Blueberry;
#286;287;316;9;16;188.495559215388;335.103216382911;3.84479832337268;-64.6666204436533;2021-08-26T05:51:00.286[UTC];1;Blueberry;
#287;288;317;9;17;188.495559215388;356.047167406843;4.02864941714166;-77.5215876039641;2021-08-26T05:51:00.287[UTC];0;Blueberry;
#288;289;318;9;18;188.495559215388;376.991118430775;4.21488883862444;-87.8778314392035;2021-08-26T05:51:00.288[UTC];0;Blueberry;
#289;290;319;9;19;188.495559215388;397.935069454707;4.40321354633005;-95.2584787070094;2021-08-26T05:51:00.289[UTC];0;Blueberry;
#290;291;320;9;20;188.495559215388;418.879020478639;4.59336706176489;-99.2925249234358;2021-08-26T05:51:00.290[UTC];1;Banana;
#291;292;321;9;21;188.495559215388;439.822971502571;4.78513136815775;-99.7355438950439;2021-08-26T05:51:00.291[UTC];1;Banana;
#292;293;322;9;22;188.495559215388;460.766922526503;4.97832032656062;-96.4848154157926;2021-08-26T05:51:00.292[UTC];1;Banana;
#293;294;323;9;23;188.495559215388;481.710873550435;5.17277431888;-89.5881360708708;2021-08-26T05:51:00.293[UTC];1;Banana;
#294;295;324;9;24;188.495559215388;502.654824574367;5.36835587970665;-79.2458561826131;2021-08-26T05:51:00.294[UTC];0;Blueberry;
#295;296;325;9;25;188.495559215388;523.598775598299;5.56494612419527;-65.8059858132082;2021-08-26T05:51:00.295[UTC];1;Blueberry;
#296;297;326;9;26;188.495559215388;544.542726622231;5.76244181715612;-49.7525215354503;2021-08-26T05:51:00.296[UTC];1;Blueberry;
#297;298;327;9;27;188.495559215388;565.486677646163;5.96075295947766;-31.6874498390185;2021-08-26T05:51:00.297[UTC];1;Blueberry;
#298;299;328;9;28;188.495559215388;586.430628670095;6.15980079293417;-12.3071690197622;2021-08-26T05:51:00.298[UTC];0;Blueberry;
#300;301;330;10;0;209.43951023932;0;2.0943951023932;86.6025403784439;2021-08-26T05:51:00.300[UTC];1;Banana;
#301;302;331;10;1;209.43951023932;20.943951023932;2.10484102805364;86.0755287165195;2021-08-26T05:51:00.301[UTC];1;Banana;
#302;303;332;10;2;209.43951023932;41.8879020478639;2.13587229925521;84.4547921129154;2021-08-26T05:51:00.302[UTC];1;Banana;
#303;304;333;10;3;209.43951023932;62.8318530717959;2.18661268197461;81.6302171711484;2021-08-26T05:51:00.303[UTC];1;Banana;
#304;305;334;10;4;209.43951023932;83.7758040957278;2.25573255952854;77.4459389345857;2021-08-26T05:51:00.304[UTC];1;Banana;
#305;306;335;10;5;209.43951023932;104.71975511966;2.34160491034691;71.7347551480723;2021-08-26T05:51:00.305[UTC];1;Banana;
#306;307;336;10;6;209.43951023932;125.663706143592;2.44246341817086;64.3551445602178;2021-08-26T05:51:00.306[UTC];1;Banana;
#307;308;337;10;7;209.43951023932;146.607657167524;2.55653502986828;55.2247423006471;2021-08-26T05:51:00.307[UTC];1;Banana;
#308;309;338;10;8;209.43951023932;167.551608191456;2.6821344085789;44.3462600929183;2021-08-26T05:51:00.308[UTC];1;Banana;
#309;310;339;10;9;209.43951023932;188.495559215388;2.81772043136305;31.8239843595852;2021-08-26T05:51:00.309[UTC];1;Banana;
#310;311;340;10;10;209.43951023932;209.43951023932;2.96192195877224;17.870557889777;2021-08-26T05:51:00.310[UTC];1;Banana;
#311;312;341;10;11;209.43951023932;230.383461263251;3.11354215762244;2.8046817615261;2021-08-26T05:51:00.311[UTC];1;Banana;
#312;313;342;10;12;209.43951023932;251.327412287183;3.27154973393739;-12.9591585008492;2021-08-26T05:51:00.312[UTC];1;Banana;
#313;314;343;10;13;209.43951023932;272.271363311115;3.43506337246607;-28.9276291261901;2021-08-26T05:51:00.313[UTC];1;Banana;
#314;315;344;10;14;209.43951023932;293.215314335047;3.60333358169746;-44.5507396390812;2021-08-26T05:51:00.314[UTC];1;Banana;
#315;316;345;10;15;209.43951023932;314.159265358979;3.77572446637966;-59.2478337940025;2021-08-26T05:51:00.315[UTC];1;Banana;
#316;317;346;10;16;209.43951023932;335.103216382911;3.95169677580983;-72.4358962551408;2021-08-26T05:51:00.316[UTC];1;Banana;
#317;318;347;10;17;209.43951023932;356.047167406843;4.13079282786879;-83.5586854972216;2021-08-26T05:51:00.317[UTC];1;Banana;
#318;319;348;10;18;209.43951023932;376.991118430775;4.31262346866699;-92.1152282718075;2021-08-26T05:51:00.318[UTC];1;Banana;
#319;320;349;10;19;209.43951023932;397.935069454707;4.49685699073485;-97.6862757340038;2021-08-26T05:51:00.319[UTC];1;Banana;
#320;321;350;10;20;209.43951023932;418.879020478639;4.68320982069382;-99.9574318524082;2021-08-26T05:51:00.320[UTC];1;Banana;
#321;322;351;10;21;209.43951023932;439.822971502571;4.87143874754304;-98.7378227040362;2021-08-26T05:51:00.321[UTC];1;Banana;
#322;323;352;10;22;209.43951023932;460.766922526503;5.06133446181766;-93.9733782589321;2021-08-26T05:51:00.322[UTC];1;Banana;
#323;324;353;10;23;209.43951023932;481.710873550435;5.25271619398963;-85.7540403158672;2021-08-26T05:51:00.323[UTC];1;Banana;
#324;325;354;10;24;209.43951023932;502.654824574367;5.44542726622231;-74.3144825477395;2021-08-26T05:51:00.324[UTC];1;Banana;
#325;326;355;10;25;209.43951023932;523.598775598299;5.63933139882135;-60.0282202305846;2021-08-26T05:51:00.325[UTC];1;Banana;
#326;327;356;10;26;209.43951023932;544.542726622231;5.83430963839304;-43.3952858616853;2021-08-26T05:51:00.326[UTC];1;Banana;
#327;328;357;10;27;209.43951023932;565.486677646163;6.03025779751232;-25.0239395520294;2021-08-26T05:51:00.327[UTC];1;Banana;
#328;329;358;10;28;209.43951023932;586.430628670095;6.22708431524488;-5.60715685908781;2021-08-26T05:51:00.328[UTC];1;Banana;
#330;331;360;11;0;230.383461263251;0;2.30383461263251;74.3144825477394;2021-08-26T05:51:00.330[UTC];1;Banana;
#331;332;361;11;1;230.383461263251;20.943951023932;2.31333500185617;73.6754382996891;2021-08-26T05:51:00.331[UTC];1;Banana;
#332;333;362;11;2;230.383461263251;41.8879020478639;2.34160491034691;71.7347551480723;2021-08-26T05:51:00.332[UTC];1;Banana;
#333;334;363;11;3;230.383461263251;62.8318530717959;2.38797782619671;68.4279229755372;2021-08-26T05:51:00.333[UTC];1;Banana;
#334;335;364;11;4;230.383461263251;83.7758040957278;2.45142661679933;63.6665228660274;2021-08-26T05:51:00.334[UTC];1;Banana;
#335;336;365;11;5;230.383461263251;104.71975511966;2.53066723090883;57.3625735554462;2021-08-26T05:51:00.335[UTC];1;Banana;
#336;337;366;11;6;230.383461263251;125.663706143592;2.62426954151777;49.4555305679245;2021-08-26T05:51:00.336[UTC];1;Banana;
#337;338;367;11;7;230.383461263251;146.607657167524;2.73075711779327;39.9375476033883;2021-08-26T05:51:00.337[UTC];1;Banana;
#338;339;368;11;8;230.383461263251;167.551608191456;2.8486853218841;28.8736945465341;2021-08-26T05:51:00.338[UTC];1;Banana;
#339;340;369;11;9;230.383461263251;188.495559215388;2.97669472851278;16.4151641557304;2021-08-26T05:51:00.339[UTC];1;Banana;
#340;341;370;11;10;230.383461263251;209.43951023932;3.11354215762244;2.8046817615261;2021-08-26T05:51:00.340[UTC];1;Banana;
#341;342;371;11;11;230.383461263251;230.383461263251;3.25811415464947;-11.6258006210228;2021-08-26T05:51:00.341[UTC];1;Banana;
#342;343;372;11;12;230.383461263251;251.327412287183;3.40942821292087;-26.4644788602053;2021-08-26T05:51:00.342[UTC];1;Banana;
#343;344;373;11;13;230.383461263251;272.271363311115;3.56662634015577;-41.2351471275857;2021-08-26T05:51:00.343[UTC];1;Banana;
#344;345;374;11;14;230.383461263251;293.215314335047;3.72896446462335;-55.4175234805705;2021-08-26T05:51:00.344[UTC];1;Banana;
#345;346;375;11;15;230.383461263251;314.159265358979;3.89580008771664;-68.4711250310687;2021-08-26T05:51:00.345[UTC];1;Banana;
#346;347;376;11;16;230.383461263251;335.103216382911;4.06657970355689;-79.8612969354075;2021-08-26T05:51:00.346[UTC];1;Banana;
#347;348;377;11;17;230.383461263251;356.047167406843;4.240826860909;-89.0859738186452;2021-08-26T05:51:00.347[UTC];1;Banana;
#348;349;378;11;18;230.383461263251;376.991118430775;4.41813130858877;-95.7017703068533;2021-08-26T05:51:00.348[UTC];1;Banana;
#349;350;379;11;19;230.383461263251;397.935069454707;4.5981393924669;-99.3480611908124;2021-08-26T05:51:00.349[UTC];1;Banana;
#350;351;380;11;20;230.383461263251;418.879020478639;4.78054571174443;-99.767822897863;2021-08-26T05:51:00.350[UTC];1;Banana;
#351;352;381;11;21;230.383461263251;439.822971502571;4.96508595580165;-96.824165634779;2021-08-26T05:51:00.351[UTC];1;Banana;
#352;353;382;11;22;230.383461263251;460.766922526503;5.1515308027632;-90.5116861731447;2021-08-26T05:51:00.352[UTC];1;Banana;
#353;354;383;11;23;230.383461263251;481.710873550435;5.33968074813803;-80.9620083947223;2021-08-26T05:51:00.353[UTC];1;Banana;
#354;355;384;11;24;230.383461263251;502.654824574367;5.52936173433719;-68.4431436220424;2021-08-26T05:51:00.354[UTC];1;Banana;
#355;356;385;11;25;230.383461263251;523.598775598299;5.72042146202248;-53.3525848053095;2021-08-26T05:51:00.355[UTC];1;Banana;
#356;357;386;11;26;230.383461263251;544.542726622231;5.91272627762194;-36.2043359661314;2021-08-26T05:51:00.356[UTC];1;Banana;
#357;358;387;11;27;230.383461263251;565.486677646163;6.10615854542716;-17.6103584715488;2021-08-26T05:51:00.357[UTC];1;Banana;
#358;359;388;11;28;230.383461263251;586.430628670095;6.30061442611781;1.74282365322203;2021-08-26T05:51:00.358[UTC];1;Banana;
#360;361;390;12;0;251.327412287183;0;2.51327412287183;58.7785252292473;2021-08-26T05:51:00.360[UTC];1;Banana;
#361;362;391;12;1;251.327412287183;20.943951023932;2.5219856710827;58.0715247200825;2021-08-26T05:51:00.361[UTC];1;Banana;
#362;363;392;12;2;251.327412287183;41.8879020478639;2.54794161049549;55.9391108226567;2021-08-26T05:51:00.362[UTC];1;Banana;
#363;364;393;12;3;251.327412287183;62.8318530717959;2.59062366868304;52.3513066812103;2021-08-26T05:51:00.363[UTC];1;Banana;
#364;365;394;12;4;251.327412287183;83.7758040957278;2.64922353754563;47.2714914404474;2021-08-26T05:51:00.364[UTC];1;Banana;
#365;366;395;12;5;251.327412287183;104.71975511966;2.72271363311115;40.67366430758;2021-08-26T05:51:00.365[UTC];1;Banana;
#366;367;396;12;6;251.327412287183;125.663706143592;2.80992589241629;32.5619404200757;2021-08-26T05:51:00.366[UTC];1;Banana;
#367;368;397;12;7;251.327412287183;146.607657167524;2.90962666517755;22.9891298573043;2021-08-26T05:51:00.367[UTC];1;Banana;
#368;369;398;12;8;251.327412287183;167.551608191456;3.02057957310373;12.0717940740021;2021-08-26T05:51:00.368[UTC];1;Banana;
#369;370;399;12;9;251.327412287183;188.495559215388;3.14159265358979;1.22460635382238e-014;2021-08-26T05:51:00.369[UTC];1;Banana;
#370;371;400;12;10;251.327412287183;209.43951023932;3.27154973393739;-12.9591585008492;2021-08-26T05:51:00.370[UTC];1;Banana;
#371;372;401;12;11;251.327412287183;230.383461263251;3.40942821292087;-26.4644788602053;2021-08-26T05:51:00.371[UTC];1;Banana;
#372;373;402;12;12;251.327412287183;251.327412287183;3.55430635052669;-40.109664518868;2021-08-26T05:51:00.372[UTC];1;Banana;
#373;374;403;12;13;251.327412287183;272.271363311115;3.70536318660216;-53.437701780614;2021-08-26T05:51:00.373[UTC];1;Banana;
#374;375;404;12;14;251.327412287183;293.215314335047;3.86187375153011;-65.9595976959684;2021-08-26T05:51:00.374[UTC];1;Banana;
#375;376;405;12;15;251.327412287183;314.159265358979;4.02320161286836;-77.1763031077059;2021-08-26T05:51:00.375[UTC];1;Banana;
#376;377;406;12;16;251.327412287183;335.103216382911;4.18879020478639;-86.6025403784438;2021-08-26T05:51:00.376[UTC];1;Banana;
#377;378;407;12;17;251.327412287183;356.047167406843;4.35815389339808;-93.7912090882442;2021-08-26T05:51:00.377[UTC];1;Banana;
#378;379;408;12;18;251.327412287183;376.991118430775;4.53086935965559;-98.3570499873021;2021-08-26T05:51:00.378[UTC];1;Banana;
#379;380;409;12;19;251.327412287183;397.935069454707;4.70656762055847;-99.9983055932737;2021-08-26T05:51:00.379[UTC];1;Banana;
#380;381;410;12;20;251.327412287183;418.879020478639;4.88492683634173;-98.5152233005516;2021-08-26T05:51:00.380[UTC];1;Banana;
#381;382;411;12;21;251.327412287183;439.822971502571;5.06566594268042;-93.8244007958212;2021-08-26T05:51:00.381[UTC];1;Banana;
#382;383;412;12;22;251.327412287183;460.766922526503;5.24853908303555;-85.9681690918935;2021-08-26T05:51:00.382[UTC];1;Banana;
#383;384;413;12;23;251.327412287183;481.710873550435;5.43333078197614;-75.1184386277109;2021-08-26T05:51:00.383[UTC];1;Banana;
#384;385;414;12;24;251.327412287183;502.654824574367;5.61985178483258;-61.5746897265888;2021-08-26T05:51:00.384[UTC];1;Banana;
#385;386;415;12;25;251.327412287183;523.598775598299;5.80793548496374;-45.7560597983392;2021-08-26T05:51:00.385[UTC];1;Banana;
#386;387;416;12;26;251.327412287183;544.542726622231;5.99743486237363;-28.1877545161061;2021-08-26T05:51:00.386[UTC];1;Banana;
#387;388;417;12;27;251.327412287183;565.486677646163;6.18821986327463;-9.48227683000212;2021-08-26T05:51:00.387[UTC];1;Banana;
#388;389;418;12;28;251.327412287183;586.430628670095;6.38017515754367;9.68378574491064;2021-08-26T05:51:00.388[UTC];1;Banana;
#390;391;420;13;0;272.271363311115;0;2.72271363311115;40.67366430758;2021-08-26T05:51:00.390[UTC];1;Banana;
#391;392;421;13;1;272.271363311115;20.943951023932;2.73075711779327;39.9375476033882;2021-08-26T05:51:00.391[UTC];1;Banana;
#392;393;422;13;2;272.271363311115;41.8879020478639;2.75474666017158;37.7269359687847;2021-08-26T05:51:00.392[UTC];1;Banana;
#393;394;423;13;3;272.271363311115;62.8318530717959;2.79427158736815;34.0380062740337;2021-08-26T05:51:00.393[UTC];1;Banana;
#394;395;424;13;4;272.271363311115;83.7758040957278;2.8486853218841;28.8736945465341;2021-08-26T05:51:00.394[UTC];1;Banana;
#395;396;425;13;5;272.271363311115;104.71975511966;2.91715481919652;22.2558331185803;2021-08-26T05:51:00.395[UTC];1;Banana;
#396;397;426;13;6;272.271363311115;125.663706143592;2.99871743118681;14.2389625143207;2021-08-26T05:51:00.396[UTC];1;Banana;
#397;398;427;13;7;272.271363311115;146.607657167524;3.09233731050549;4.9235429193879;2021-08-26T05:51:00.397[UTC];1;Banana;
#398;399;428;13;8;272.271363311115;167.551608191456;3.19695537483457;-5.53344441700427;2021-08-26T05:51:00.398[UTC];1;Banana;
#399;400;429;13;9;272.271363311115;188.495559215388;3.31152942193203;-16.9120028570147;2021-08-26T05:51:00.399[UTC];1;Banana;
#400;401;430;13;10;272.271363311115;209.43951023932;3.43506337246607;-28.9276291261901;2021-08-26T05:51:00.400[UTC];1;Banana;
#401;402;431;13;11;272.271363311115;230.383461263251;3.56662634015577;-41.2351471275857;2021-08-26T05:51:00.401[UTC];1;Banana;
#402;403;432;13;12;272.271363311115;251.327412287183;3.70536318660216;-53.437701780614;2021-08-26T05:51:00.402[UTC];1;Banana;
#403;404;433;13;13;272.271363311115;272.271363311115;3.85049854640392;-65.1003651863601;2021-08-26T05:51:00.403[UTC];1;Banana;
#404;405;434;13;14;272.271363311115;293.215314335047;4.00133622481158;-75.7675234238049;2021-08-26T05:51:00.404[UTC];1;Banana;
#405;406;435;13;15;272.271363311115;314.159265358979;4.15725557658159;-84.9830136467115;2021-08-26T05:51:00.405[UTC];1;Banana;
#406;407;436;13;16;272.271363311115;335.103216382911;4.31770611447173;-92.3118553739974;2021-08-26T05:51:00.406[UTC];1;Banana;
#407;408;437;13;17;272.271363311115;356.047167406843;4.48220125270754;-97.362358015787;2021-08-26T05:51:00.407[UTC];1;Banana;
#408;409;438;13;18;272.271363311115;376.991118430775;4.65031180304053;-99.8073830698998;2021-08-26T05:51:00.408[UTC];1;Banana;
#409;410;439;13;19;272.271363311115;397.935069454707;4.82165961865016;-99.4035901664835;2021-08-26T05:51:00.409[UTC];1;Banana;
#410;411;440;13;20;272.271363311115;418.879020478639;4.99591161927868;-96.0075976312937;2021-08-26T05:51:00.410[UTC];1;Banana;
#411;412;441;13;21;272.271363311115;439.822971502571;5.17277431888;-89.5881360708708;2021-08-26T05:51:00.411[UTC];1;Banana;
#412;413;442;13;22;272.271363311115;460.766922526503;5.35198890295783;-80.2334618100927;2021-08-26T05:51:00.412[UTC];1;Banana;
#413;414;443;13;23;272.271363311115;481.710873550435;5.53332685620519;-68.1535183348542;2021-08-26T05:51:00.413[UTC];1;Banana;
#414;415;444;13;24;272.271363311115;502.654824574367;5.71658611364493;-53.6765791423318;2021-08-26T05:51:00.414[UTC];1;Banana;
#415;416;445;13;25;272.271363311115;523.598775598299;5.90158769389502;-37.2403642377847;2021-08-26T05:51:00.415[UTC];1;Banana;
#416;417;446;13;26;272.271363311115;544.542726622231;6.08817276690196;-19.3778837557323;2021-08-26T05:51:00.416[UTC];1;Banana;
#417;418;447;13;27;272.271363311115;565.486677646163;6.27620010734671;-0.698514302818596;2021-08-26T05:51:00.417[UTC];1;Banana;
#418;419;448;13;28;272.271363311115;586.430628670095;6.46554388680253;18.1349546998989;2021-08-26T05:51:00.418[UTC];1;Banana;
#420;421;450;14;0;293.215314335047;0;2.93215314335047;20.7911690817759;2021-08-26T05:51:00.420[UTC];1;Banana;
#421;422;451;14;1;293.215314335047;20.943951023932;2.93962360932643;20.0598738887047;2021-08-26T05:51:00.421[UTC];1;Banana;
#422;423;452;14;2;293.215314335047;41.8879020478639;2.96192195877224;17.8705578897769;2021-08-26T05:51:00.422[UTC];1;Banana;
#423;424;453;14;3;293.215314335047;62.8318530717959;2.99871743118681;14.2389625143207;2021-08-26T05:51:00.423[UTC];1;Banana;
#424;425;454;14;4;293.215314335047;83.7758040957278;3.04948529939868;9.19771732379936;2021-08-26T05:51:00.424[UTC];1;Banana;
#425;426;455;14;5;293.215314335047;104.71975511966;3.11354215762244;2.80468176152606;2021-08-26T05:51:00.425[UTC];1;Banana;
#426;427;456;14;6;293.215314335047;125.663706143592;3.19008757877184;-4.84759193641976;2021-08-26T05:51:00.426[UTC];1;Banana;
#427;428;457;14;7;293.215314335047;146.607657167524;3.27824687448567;-13.6229295798029;2021-08-26T05:51:00.427[UTC];1;Banana;
#428;429;458;14;8;293.215314335047;167.551608191456;3.37711062845362;-23.334669223776;2021-08-26T05:51:00.428[UTC];1;Banana;
#429;430;459;14;9;293.215314335047;188.495559215388;3.48576815644016;-33.7420648355146;2021-08-26T05:51:00.429[UTC];1;Banana;
#430;431;460;14;10;293.215314335047;209.43951023932;3.60333358169746;-44.5507396390812;2021-08-26T05:51:00.430[UTC];1;Banana;
#431;432;461;14;11;293.215314335047;230.383461263251;3.72896446462335;-55.4175234805705;2021-08-26T05:51:00.431[UTC];1;Banana;
#432;433;462;14;12;293.215314335047;251.327412287183;3.86187375153011;-65.9595976959684;2021-08-26T05:51:00.432[UTC];1;Banana;
#433;434;463;14;13;293.215314335047;272.271363311115;4.00133622481158;-75.7675234238049;2021-08-26T05:51:00.433[UTC];1;Banana;
#434;435;464;14;14;293.215314335047;293.215314335047;4.14669074228114;-84.4214546845894;2021-08-26T05:51:00.434[UTC];1;Banana;
#435;436;465;14;15;293.215314335047;314.159265358979;4.29733946263841;-91.509635431603;2021-08-26T05:51:00.435[UTC];1;Banana;
#436;437;466;14;16;293.215314335047;335.103216382911;4.4527450655834;-96.6481459444469;2021-08-26T05:51:00.436[UTC];1;Banana;
#437;438;467;14;17;293.215314335047;356.047167406843;4.61242675799884;-99.500793603631;2021-08-26T05:51:00.437[UTC];1;Banana;
#438;439;468;14;18;293.215314335047;376.991118430775;4.77595565239343;-99.7980319322933;2021-08-26T05:51:00.438[UTC];1;Banana;
#439;440;469;14;19;293.215314335047;397.935069454707;4.94294992957164;-97.3538358016738;2021-08-26T05:51:00.439[UTC];1;Banana;
#440;441;470;14;20;293.215314335047;418.879020478639;5.11307005973656;-92.0795555605351;2021-08-26T05:51:00.440[UTC];1;Banana;
#441;442;471;14;21;293.215314335047;439.822971502571;5.28601425293152;-83.9939133817517;2021-08-26T05:51:00.441[UTC];1;Banana;
#442;443;472;14;22;293.215314335047;460.766922526503;5.46151423558655;-73.228484882106;2021-08-26T05:51:00.442[UTC];1;Banana;
#443;444;473;14;23;293.215314335047;481.710873550435;5.63933139882135;-60.0282202305846;2021-08-26T05:51:00.443[UTC];1;Banana;
#444;445;474;14;24;293.215314335047;502.654824574367;5.81925333035509;-44.7467923728306;2021-08-26T05:51:00.444[UTC];1;Banana;
#445;446;475;14;25;293.215314335047;523.598775598299;6.00109072059937;-27.8368054689727;2021-08-26T05:51:00.445[UTC];1;Banana;
#446;447;476;14;26;293.215314335047;544.542726622231;6.18467462101099;-9.83514330109705;2021-08-26T05:51:00.446[UTC];1;Banana;
#447;448;477;14;27;293.215314335047;565.486677646163;6.36985402623872;8.65602582669099;2021-08-26T05:51:00.447[UTC];1;Banana;
#448;449;478;14;28;293.215314335047;586.430628670095;6.55649374897134;26.9918550991705;2021-08-26T05:51:00.448[UTC];1;Banana;
#450;451;480;15;0;314.159265358979;0;3.14159265358979;1.22460635382238e-014;2021-08-26T05:51:00.450[UTC];0;Blueberry;
#451;452;481;15;1;314.159265358979;20.943951023932;3.14856623076896;-0.69735206575545;2021-08-26T05:51:00.451[UTC];1;Banana;
#452;453;482;15;2;314.159265358979;41.8879020478639;3.16939490043234;-2.77986652873387;2021-08-26T05:51:00.452[UTC];1;Banana;
#453;454;483;15;3;314.159265358979;62.8318530717959;3.20380844888282;-6.21756655233814;2021-08-26T05:51:00.453[UTC];1;Banana;
#454;455;484;15;4;314.159265358979;83.7758040957278;3.25137554525434;-10.9562502097669;2021-08-26T05:51:00.454[UTC];1;Banana;
#455;456;485;15;5;314.159265358979;104.71975511966;3.31152942193203;-16.9120028570147;2021-08-26T05:51:00.455[UTC];0;Blueberry;
#456;457;486;15;6;314.159265358979;125.663706143592;3.38359883929281;-23.9650831127554;2021-08-26T05:51:00.456[UTC];0;Blueberry;
#457;458;487;15;7;314.159265358979;146.607657167524;3.46684076864;-31.9543902433653;2021-08-26T05:51:00.457[UTC];0;Blueberry;
#458;459;488;15;8;314.159265358979;167.551608191456;3.56047167406843;-40.67366430758;2021-08-26T05:51:00.458[UTC];1;Blueberry;
#459;460;489;15;9;314.159265358979;188.495559215388;3.6636951272563;-49.8703605269115;2021-08-26T05:51:00.459[UTC];1;Blueberry;
#460;461;490;15;10;314.159265358979;209.43951023932;3.77572446637966;-59.2478337940025;2021-08-26T05:51:00.460[UTC];1;Banana;
#461;462;491;15;11;314.159265358979;230.383461263251;3.89580008771664;-68.4711250310687;2021-08-26T05:51:00.461[UTC];1;Banana;
#462;463;492;15;12;314.159265358979;251.327412287183;4.02320161286836;-77.1763031077059;2021-08-26T05:51:00.462[UTC];1;Banana;
#463;464;493;15;13;314.159265358979;272.271363311115;4.15725557658159;-84.9830136467115;2021-08-26T05:51:00.463[UTC];1;Banana;
#464;465;494;15;14;314.159265358979;293.215314335047;4.29733946263841;-91.509635431603;2021-08-26T05:51:00.464[UTC];1;Banana;
#465;466;495;15;15;314.159265358979;314.159265358979;4.44288293815837;-96.3902532849877;2021-08-26T05:51:00.465[UTC];0;Blueberry;
#466;467;496;15;16;314.159265358979;335.103216382911;4.59336706176489;-99.2925249234359;2021-08-26T05:51:00.466[UTC];1;Blueberry;
#467;468;497;15;17;314.159265358979;356.047167406843;4.74832211869972;-99.9354474247957;2021-08-26T05:51:00.467[UTC];1;Blueberry;
#468;469;498;15;18;314.159265358979;376.991118430775;4.90732460090608;-98.1060142104979;2021-08-26T05:51:00.468[UTC];1;Blueberry;
#469;470;499;15;19;314.159265358979;397.935069454707;5.06999372300219;-93.6737925589561;2021-08-26T05:51:00.469[UTC];0;Blueberry;
#470;471;500;15;20;314.159265358979;418.879020478639;5.23598775598299;-86.6025403784439;2021-08-26T05:51:00.470[UTC];1;Banana;
#471;472;501;15;21;314.159265358979;439.822971502571;5.40500037254619;-76.9581138974096;2021-08-26T05:51:00.471[UTC];1;Banana;
#472;473;502;15;22;314.159265358979;460.766922526503;5.57675713031721;-64.9120884268515;2021-08-26T05:51:00.472[UTC];1;Banana;
#473;474;503;15;23;314.159265358979;481.710873550435;5.75101216924131;-50.7407144810068;2021-08-26T05:51:00.473[UTC];1;Banana;
#474;475;504;15;24;314.159265358979;502.654824574367;5.92754516371475;-34.8190522248513;2021-08-26T05:51:00.474[UTC];1;Blueberry;
#475;476;505;15;25;314.159265358979;523.598775598299;6.10615854542716;-17.6103584715487;2021-08-26T05:51:00.475[UTC];0;Blueberry;
#476;477;506;15;26;314.159265358979;544.542726622231;6.28667499659452;0.34896823320722;2021-08-26T05:51:00.476[UTC];0;Blueberry;
#477;478;507;15;27;314.159265358979;565.486677646163;6.46893520300048;18.4683581524922;2021-08-26T05:51:00.477[UTC];0;Blueberry;
#478;479;508;15;28;314.159265358979;586.430628670095;6.65279585026698;36.1252303220272;2021-08-26T05:51:00.478[UTC];1;Blueberry;
#480;481;510;16;0;335.103216382911;0;3.35103216382911;-20.7911690817759;2021-08-26T05:51:00.480[UTC];0;Blueberry;
#481;482;511;16;1;335.103216382911;20.943951023932;3.35757076939065;-21.4302922140791;2021-08-26T05:51:00.481[UTC];1;Banana;
#482;483;512;16;2;335.103216382911;41.8879020478639;3.37711062845362;-23.334669223776;2021-08-26T05:51:00.482[UTC];1;Banana;
#483;484;513;16;3;335.103216382911;62.8318530717959;3.40942821292087;-26.4644788602053;2021-08-26T05:51:00.483[UTC];1;Banana;
#484;485;514;16;4;335.103216382911;83.7758040957278;3.45416489157738;-30.7507253131787;2021-08-26T05:51:00.484[UTC];1;Banana;
#485;486;515;16;5;335.103216382911;104.71975511966;3.51084594852143;-36.0919157662648;2021-08-26T05:51:00.485[UTC];1;Blueberry;
#486;487;516;16;6;335.103216382911;125.663706143592;3.57890391980443;-42.350529201388;2021-08-26T05:51:00.486[UTC];1;Blueberry;
#487;488;517;16;7;335.103216382911;146.607657167524;3.65770379842767;-49.3501566050665;2021-08-26T05:51:00.487[UTC];1;Blueberry;
#488;489;518;16;8;335.103216382911;167.551608191456;3.74656785655505;-56.874168047095;2021-08-26T05:51:00.488[UTC];1;Blueberry;
#489;490;519;16;9;335.103216382911;188.495559215388;3.84479832337268;-64.6666204436533;2021-08-26T05:51:00.489[UTC];1;Blueberry;
#490;491;520;16;10;335.103216382911;209.43951023932;3.95169677580983;-72.4358962551408;2021-08-26T05:51:00.490[UTC];1;Banana;
#491;492;521;16;11;335.103216382911;230.383461263251;4.06657970355689;-79.8612969354075;2021-08-26T05:51:00.491[UTC];1;Banana;
#492;493;522;16;12;335.103216382911;251.327412287183;4.18879020478639;-86.6025403784438;2021-08-26T05:51:00.492[UTC];1;Banana;
#493;494;523;16;13;335.103216382911;272.271363311115;4.31770611447173;-92.3118553739974;2021-08-26T05:51:00.493[UTC];1;Banana;
#494;495;524;16;14;335.103216382911;293.215314335047;4.4527450655834;-96.6481459444469;2021-08-26T05:51:00.494[UTC];1;Banana;
#495;496;525;16;15;335.103216382911;314.159265358979;4.59336706176489;-99.2925249234359;2021-08-26T05:51:00.495[UTC];1;Blueberry;
#496;497;526;16;16;335.103216382911;335.103216382911;4.73907513403559;-99.9643945732773;2021-08-26T05:51:00.496[UTC];1;Blueberry;
#497;498;527;16;17;335.103216382911;356.047167406843;4.88941459735835;-98.4371842520433;2021-08-26T05:51:00.497[UTC];1;Blueberry;
#498;499;528;16;18;335.103216382911;376.991118430775;5.04397134216541;-94.5528406056216;2021-08-26T05:51:00.498[UTC];0;Blueberry;
#499;500;529;16;19;335.103216382911;397.935069454707;5.20236950948407;-88.2342021952767;2021-08-26T05:51:00.499[UTC];0;Blueberry;
#500;501;530;16;20;335.103216382911;418.879020478639;5.36426881715781;-79.4944740964404;2021-08-26T05:51:00.500[UTC];1;Banana;
#501;502;531;16;21;335.103216382911;439.822971502571;5.52936173433719;-68.4431436220424;2021-08-26T05:51:00.501[UTC];1;Banana;
#502;503;532;16;22;335.103216382911;460.766922526503;5.6973706437682;-55.2878393746244;2021-08-26T05:51:00.502[UTC];1;Banana;
#503;504;533;16;23;335.103216382911;481.710873550435;5.86804508611595;-40.3318245005268;2021-08-26T05:51:00.503[UTC];1;Banana;
#504;505;534;16;24;335.103216382911;502.654824574367;6.04115914620745;-23.9670224252432;2021-08-26T05:51:00.504[UTC];0;Blueberry;
#505;506;535;16;25;335.103216382911;523.598775598299;6.21650901582399;-6.66268982289559;2021-08-26T05:51:00.505[UTC];0;Blueberry;
#506;507;536;16;26;335.103216382911;544.542726622231;6.39391074966914;11.0499329873802;2021-08-26T05:51:00.506[UTC];0;Blueberry;
#507;508;537;16;27;335.103216382911;565.486677646163;6.57319821871718;28.5964597482825;2021-08-26T05:51:00.507[UTC];1;Blueberry;
#508;509;538;16;28;335.103216382911;586.430628670095;6.75422125690723;45.3809662122285;2021-08-26T05:51:00.508[UTC];1;Blueberry;
#510;511;540;17;0;356.047167406843;0;3.56047167406843;-40.67366430758;2021-08-26T05:51:00.510[UTC];1;Blueberry;
#511;512;541;17;1;356.047167406843;20.943951023932;3.56662634015577;-41.2351471275857;2021-08-26T05:51:00.511[UTC];1;Banana;
#512;513;542;17;2;356.047167406843;41.8879020478639;3.58502694210808;-42.9044125372587;2021-08-26T05:51:00.512[UTC];1;Banana;
#513;514;543;17;3;356.047167406843;62.8318530717959;3.61548651192163;-45.6354483856911;2021-08-26T05:51:00.513[UTC];1;Banana;
#514;515;544;17;4;356.047167406843;83.7758040957278;3.65770379842767;-49.3501566050665;2021-08-26T05:51:00.514[UTC];1;Banana;
#515;516;545;17;5;356.047167406843;104.71975511966;3.71127757693706;-53.9366758611645;2021-08-26T05:51:00.515[UTC];1;Blueberry;
#516;517;546;17;6;356.047167406843;125.663706143592;3.77572446637966;-59.2478337940025;2021-08-26T05:51:00.516[UTC];1;Blueberry;
#517;518;547;17;7;356.047167406843;146.607657167524;3.85049854640392;-65.10036518636;2021-08-26T05:51:00.517[UTC];1;Blueberry;
#518;519;548;17;8;356.047167406843;167.551608191456;3.93501114135627;-71.2755203721435;2021-08-26T05:51:00.518[UTC];1;Blueberry;
#519;520;549;17;9;356.047167406843;188.495559215388;4.02864941714166;-77.5215876039641;2021-08-26T05:51:00.519[UTC];0;Blueberry;
#520;521;550;17;10;356.047167406843;209.43951023932;4.13079282786879;-83.5586854972216;2021-08-26T05:51:00.520[UTC];1;Banana;
#521;522;551;17;11;356.047167406843;230.383461263251;4.240826860909;-89.0859738186452;2021-08-26T05:51:00.521[UTC];1;Banana;
#522;523;552;17;12;356.047167406843;251.327412287183;4.35815389339808;-93.7912090882442;2021-08-26T05:51:00.522[UTC];1;Banana;
#523;524;553;17;13;356.047167406843;272.271363311115;4.48220125270754;-97.362358015787;2021-08-26T05:51:00.523[UTC];1;Banana;
#524;525;554;17;14;356.047167406843;293.215314335047;4.61242675799884;-99.500793603631;2021-08-26T05:51:00.524[UTC];1;Banana;
#525;526;555;17;15;356.047167406843;314.159265358979;4.74832211869972;-99.9354474247957;2021-08-26T05:51:00.525[UTC];1;Blueberry;
#526;527;556;17;16;356.047167406843;335.103216382911;4.88941459735835;-98.4371842520433;2021-08-26T05:51:00.526[UTC];1;Blueberry;
#527;528;557;17;17;356.047167406843;356.047167406843;5.03526732991281;-94.8326054665716;2021-08-26T05:51:00.527[UTC];0;Blueberry;
#528;529;558;17;18;356.047167406843;376.991118430775;5.1854786548025;-89.016476376019;2021-08-26T05:51:00.528[UTC];0;Blueberry;
#529;530;559;17;19;356.047167406843;397.935069454707;5.33968074813803;-80.9620083947223;2021-08-26T05:51:00.529[UTC];0;Blueberry;
#530;531;560;17;20;356.047167406843;418.879020478639;5.49753780537779;-70.7283068080957;2021-08-26T05:51:00.530[UTC];1;Banana;
#531;532;561;17;21;356.047167406843;439.822971502571;5.6587439567433;-58.4644137469822;2021-08-26T05:51:00.531[UTC];1;Banana;
#532;533;562;17;22;356.047167406843;460.766922526503;5.82302105708867;-44.4095277680602;2021-08-26T05:51:00.532[UTC];1;Banana;
#533;534;563;17;23;356.047167406843;481.710873550435;5.99011645224999;-28.8891585400622;2021-08-26T05:51:00.533[UTC];1;Banana;
#534;535;564;17;24;356.047167406843;502.654824574367;6.15980079293417;-12.3071690197623;2021-08-26T05:51:00.534[UTC];0;Blueberry;
#535;536;565;17;25;356.047167406843;523.598775598299;6.33186594319932;4.86614110342328;2021-08-26T05:51:00.535[UTC];0;Blueberry;
#536;537;566;17;26;356.047167406843;544.542726622231;6.50612301248301;22.1095576397343;2021-08-26T05:51:00.536[UTC];1;Blueberry;
#537;538;567;17;27;356.047167406843;565.486677646163;6.68240052685958;38.8695391923719;2021-08-26T05:51:00.537[UTC];1;Blueberry;
#538;539;568;17;28;356.047167406843;586.430628670095;6.86054274573695;54.5811621957242;2021-08-26T05:51:00.538[UTC];1;Blueberry;
#540;541;570;18;0;376.991118430775;0;3.76991118430775;-58.7785252292473;2021-08-26T05:51:00.540[UTC];1;Blueberry;
#541;542;571;18;1;376.991118430775;20.943951023932;3.77572446637966;-59.2478337940025;2021-08-26T05:51:00.541[UTC];1;Banana;
#542;543;572;18;2;376.991118430775;41.8879020478639;3.79311085671983;-60.6394324727199;2021-08-26T05:51:00.542[UTC];1;Banana;
#543;544;573;18;3;376.991118430775;62.8318530717959;3.82191241574323;-62.904163019487;2021-08-26T05:51:00.543[UTC];1;Banana;
#544;545;574;18;4;376.991118430775;83.7758040957278;3.86187375153011;-65.9595976959684;2021-08-26T05:51:00.544[UTC];1;Banana;
#545;546;575;18;5;376.991118430775;104.71975511966;3.91265294254433;-69.6896039936078;2021-08-26T05:51:00.545[UTC];1;Blueberry;
#546;547;576;18;6;376.991118430775;125.663706143592;3.97383530631844;-73.9443026097172;2021-08-26T05:51:00.546[UTC];1;Blueberry;
#547;548;577;18;7;376.991118430775;146.607657167524;4.04494880704116;-78.5408712550093;2021-08-26T05:51:00.547[UTC];0;Blueberry;
#548;549;578;18;8;376.991118430775;167.551608191456;4.12547990884975;-83.2656379151013;2021-08-26T05:51:00.548[UTC];0;Blueberry;
#549;550;579;18;9;376.991118430775;188.495559215388;4.21488883862444;-87.8778314392035;2021-08-26T05:51:00.549[UTC];0;Blueberry;
#550;551;580;18;10;376.991118430775;209.43951023932;4.31262346866699;-92.1152282718075;2021-08-26T05:51:00.550[UTC];1;Banana;
#551;552;581;18;11;376.991118430775;230.383461263251;4.41813130858877;-95.7017703068533;2021-08-26T05:51:00.551[UTC];1;Banana;
#552;553;582;18;12;376.991118430775;251.327412287183;4.53086935965559;-98.3570499873021;2021-08-26T05:51:00.552[UTC];1;Banana;
#553;554;583;18;13;376.991118430775;272.271363311115;4.65031180304053;-99.8073830698998;2021-08-26T05:51:00.553[UTC];1;Banana;
#554;555;584;18;14;376.991118430775;293.215314335047;4.77595565239343;-99.7980319322933;2021-08-26T05:51:00.554[UTC];1;Banana;
#555;556;585;18;15;376.991118430775;314.159265358979;4.90732460090608;-98.1060142104979;2021-08-26T05:51:00.555[UTC];1;Blueberry;
#556;557;586;18;16;376.991118430775;335.103216382911;5.04397134216541;-94.5528406056216;2021-08-26T05:51:00.556[UTC];0;Blueberry;
#557;558;587;18;17;376.991118430775;356.047167406843;5.1854786548025;-89.016476376019;2021-08-26T05:51:00.557[UTC];0;Blueberry;
#558;559;588;18;18;376.991118430775;376.991118430775;5.33145952579004;-81.4418150835379;2021-08-26T05:51:00.558[UTC];0;Blueberry;
#559;560;589;18;19;376.991118430775;397.935069454707;5.48155655701562;-71.848990005426;2021-08-26T05:51:00.559[UTC];0;Blueberry;
#560;561;590;18;20;376.991118430775;418.879020478639;5.6354408627261;-60.3389256579677;2021-08-26T05:51:00.560[UTC];1;Banana;
#561;562;591;18;21;376.991118430775;439.822971502571;5.79281062729517;-47.0956447502496;2021-08-26T05:51:00.561[UTC];1;Banana;
#562;563;592;18;22;376.991118430775;460.766922526503;5.95338945702556;-32.3849887244897;2021-08-26T05:51:00.562[UTC];1;Banana;
#563;564;593;18;23;376.991118430775;481.710873550435;6.11692462821318;-16.5495757009701;2021-08-26T05:51:00.563[UTC];1;Banana;
#564;565;594;18;24;376.991118430775;502.654824574367;6.28318530717959;-2.44921270764475e-014;2021-08-26T05:51:00.564[UTC];0;Blueberry;
#565;566;595;18;25;376.991118430775;523.598775598299;6.45196079640697;16.7975363365943;2021-08-26T05:51:00.565[UTC];0;Blueberry;
#566;567;596;18;26;376.991118430775;544.542726622231;6.62305884386407;33.3367865593684;2021-08-26T05:51:00.566[UTC];1;Blueberry;
#567;568;597;18;27;376.991118430775;565.486677646163;6.79630403948339;49.0896724835597;2021-08-26T05:51:00.567[UTC];1;Blueberry;
#568;569;598;18;28;376.991118430775;586.430628670095;6.97153631288032;63.5264537086182;2021-08-26T05:51:00.568[UTC];1;Blueberry;
#570;571;600;19;0;397.935069454707;0;3.97935069454707;-74.3144825477394;2021-08-26T05:51:00.570[UTC];1;Blueberry;
#571;572;601;19;1;397.935069454707;20.943951023932;3.98485844900939;-74.6818942173325;2021-08-26T05:51:00.571[UTC];1;Banana;
#572;573;602;19;2;397.935069454707;41.8879020478639;4.00133622481158;-75.7675234238049;2021-08-26T05:51:00.572[UTC];1;Banana;
#573;574;603;19;3;397.935069454707;62.8318530717959;4.02864941714166;-77.5215876039641;2021-08-26T05:51:00.573[UTC];1;Banana;
#574;575;604;19;4;397.935069454707;83.7758040957278;4.06657970355689;-79.8612969354075;2021-08-26T05:51:00.574[UTC];1;Banana;
#575;576;605;19;5;397.935069454707;104.71975511966;4.11483349133649;-82.6713422294605;2021-08-26T05:51:00.575[UTC];0;Blueberry;
#576;577;606;19;6;397.935069454707;125.663706143592;4.17305267812025;-85.804972332415;2021-08-26T05:51:00.576[UTC];0;Blueberry;
#577;578;607;19;7;397.935069454707;146.607657167524;4.240826860909;-89.0859738186452;2021-08-26T05:51:00.577[UTC];0;Blueberry;
#578;579;608;19;8;397.935069454707;167.551608191456;4.31770611447173;-92.3118553739974;2021-08-26T05:51:00.578[UTC];0;Blueberry;
#579;580;609;19;9;397.935069454707;188.495559215388;4.40321354633005;-95.2584787070094;2021-08-26T05:51:00.579[UTC];0;Blueberry;
#580;581;610;19;10;397.935069454707;209.43951023932;4.49685699073485;-97.6862757340038;2021-08-26T05:51:00.580[UTC];1;Banana;
#581;582;611;19;11;397.935069454707;230.383461263251;4.5981393924669;-99.3480611908124;2021-08-26T05:51:00.581[UTC];1;Banana;
#582;583;612;19;12;397.935069454707;251.327412287183;4.70656762055847;-99.9983055932737;2021-08-26T05:51:00.582[UTC];1;Banana;
#583;584;613;19;13;397.935069454707;272.271363311115;4.82165961865016;-99.4035901664835;2021-08-26T05:51:00.583[UTC];1;Banana;
#584;585;614;19;14;397.935069454707;293.215314335047;4.94294992957164;-97.3538358016738;2021-08-26T05:51:00.584[UTC];1;Banana;
#585;586;615;19;15;397.935069454707;314.159265358979;5.06999372300219;-93.6737925589561;2021-08-26T05:51:00.585[UTC];0;Blueberry;
#586;587;616;19;16;397.935069454707;335.103216382911;5.20236950948407;-88.2342021952767;2021-08-26T05:51:00.586[UTC];0;Blueberry;
#587;588;617;19;17;397.935069454707;356.047167406843;5.33968074813803;-80.9620083947223;2021-08-26T05:51:00.587[UTC];0;Blueberry;
#588;589;618;19;18;397.935069454707;376.991118430775;5.48155655701562;-71.848990005426;2021-08-26T05:51:00.588[UTC];0;Blueberry;
#589;590;619;19;19;397.935069454707;397.935069454707;5.62765172166726;-60.958231547642;2021-08-26T05:51:00.589[UTC];1;Blueberry;
#590;591;620;19;20;397.935069454707;418.879020478639;5.77764617555512;-48.4279204224757;2021-08-26T05:51:00.590[UTC];1;Banana;
#591;592;621;19;21;397.935069454707;439.822971502571;5.93124410021434;-34.4720677095299;2021-08-26T05:51:00.591[UTC];1;Banana;
#592;593;622;19;22;397.935069454707;460.766922526503;6.08817276690196;-19.3778837557325;2021-08-26T05:51:00.592[UTC];1;Banana;
#593;594;623;19;23;397.935069454707;481.710873550435;6.24818121695142;-3.49969423271972;2021-08-26T05:51:00.593[UTC];1;Banana;
#594;595;624;19;24;397.935069454707;502.654824574367;6.41103885629942;12.7505506726066;2021-08-26T05:51:00.594[UTC];0;Blueberry;
#595;596;625;19;25;397.935069454707;523.598775598299;6.57653402112359;28.9159500418985;2021-08-26T05:51:00.595[UTC];1;Blueberry;
#596;597;626;19;26;397.935069454707;544.542726622231;6.7444725562426;44.5101181571619;2021-08-26T05:51:00.596[UTC];1;Blueberry;
#597;598;627;19;27;397.935069454707;565.486677646163;6.91467643564916;59.0348975346622;2021-08-26T05:51:00.597[UTC];1;Blueberry;
#598;599;628;19;28;397.935069454707;586.430628670095;7.08698244490788;71.9996404368636;2021-08-26T05:51:00.598[UTC];0;Blueberry;
#600;601;630;20;0;418.879020478639;0;4.18879020478639;-86.6025403784438;2021-08-26T05:51:00.600[UTC];1;Banana;
#601;602;631;20;1;418.879020478639;20.943951023932;4.19402292413426;-86.862989507242;2021-08-26T05:51:00.601[UTC];1;Banana;
#602;603;632;20;2;418.879020478639;41.8879020478639;4.20968205610727;-87.6281579631197;2021-08-26T05:51:00.602[UTC];1;Banana;
#603;604;633;20;3;418.879020478639;62.8318530717959;4.23565196348307;-88.8496975811155;2021-08-26T05:51:00.603[UTC];1;Banana;
#604;605;634;20;4;418.879020478639;83.7758040957278;4.27174459851042;-90.447700772903;2021-08-26T05:51:00.604[UTC];1;Banana;
#605;606;635;20;5;418.879020478639;104.71975511966;4.31770611447173;-92.3118553739974;2021-08-26T05:51:00.605[UTC];1;Banana;
#606;607;636;20;6;418.879020478639;125.663706143592;4.37322536394921;-94.3033258872587;2021-08-26T05:51:00.606[UTC];1;Banana;
#607;608;637;20;7;418.879020478639;146.607657167524;4.4379436559886;-96.2575670029477;2021-08-26T05:51:00.607[UTC];1;Banana;
#608;609;638;20;8;418.879020478639;167.551608191456;4.51146511905708;-97.9882616702586;2021-08-26T05:51:00.608[UTC];1;Banana;
#609;610;639;20;9;418.879020478639;188.495559215388;4.59336706176489;-99.2925249234358;2021-08-26T05:51:00.609[UTC];1;Banana;
#610;611;640;20;10;418.879020478639;209.43951023932;4.68320982069382;-99.9574318524082;2021-08-26T05:51:00.610[UTC];1;Banana;
#611;612;641;20;11;418.879020478639;230.383461263251;4.78054571174443;-99.767822897863;2021-08-26T05:51:00.611[UTC];1;Banana;
#612;613;642;20;12;418.879020478639;251.327412287183;4.88492683634173;-98.5152233005516;2021-08-26T05:51:00.612[UTC];1;Banana;
#613;614;643;20;13;418.879020478639;272.271363311115;4.99591161927868;-96.0075976312937;2021-08-26T05:51:00.613[UTC];1;Banana;
#614;615;644;20;14;418.879020478639;293.215314335047;5.11307005973656;-92.0795555605351;2021-08-26T05:51:00.614[UTC];1;Banana;
#615;616;645;20;15;418.879020478639;314.159265358979;5.23598775598299;-86.6025403784439;2021-08-26T05:51:00.615[UTC];1;Banana;
#616;617;646;20;16;418.879020478639;335.103216382911;5.36426881715781;-79.4944740964404;2021-08-26T05:51:00.616[UTC];1;Banana;
#617;618;647;20;17;418.879020478639;356.047167406843;5.49753780537779;-70.7283068080957;2021-08-26T05:51:00.617[UTC];1;Banana;
#618;619;648;20;18;418.879020478639;376.991118430775;5.6354408627261;-60.3389256579677;2021-08-26T05:51:00.618[UTC];1;Banana;
#619;620;649;20;19;418.879020478639;397.935069454707;5.77764617555512;-48.4279204224757;2021-08-26T05:51:00.619[UTC];1;Banana;
#620;621;650;20;20;418.879020478639;418.879020478639;5.92384391754449;-35.1657765568526;2021-08-26T05:51:00.620[UTC];1;Banana;
#621;622;651;20;21;418.879020478639;439.822971502571;6.07374579694027;-20.791169081776;2021-08-26T05:51:00.621[UTC];1;Banana;
#622;623;652;20;22;418.879020478639;460.766922526503;6.22708431524488;-5.60715685908789;2021-08-26T05:51:00.622[UTC];1;Banana;
#623;624;653;20;23;418.879020478639;481.710873550435;6.38361182633991;10.0257795894274;2021-08-26T05:51:00.623[UTC];1;Banana;
#624;625;654;20;24;418.879020478639;502.654824574367;6.54309946787478;25.6997596701223;2021-08-26T05:51:00.624[UTC];1;Banana;
#625;626;655;20;25;418.879020478639;523.598775598299;6.70533602144726;40.9723301894937;2021-08-26T05:51:00.625[UTC];1;Banana;
#626;627;656;20;26;418.879020478639;544.542726622231;6.87012674493213;55.3816940762466;2021-08-26T05:51:00.626[UTC];1;Banana;
#627;628;657;20;27;418.879020478639;565.486677646163;7.03729220931204;68.463797768045;2021-08-26T05:51:00.627[UTC];1;Banana;
#628;629;658;20;28;418.879020478639;586.430628670095;7.20666716339493;79.7706171789323;2021-08-26T05:51:00.628[UTC];1;Banana;
#630;631;660;21;0;439.822971502571;0;4.39822971502571;-95.1056516295154;2021-08-26T05:51:00.630[UTC];1;Banana;
#631;632;661;21;1;439.822971502571;20.943951023932;4.40321354633005;-95.2584787070094;2021-08-26T05:51:00.631[UTC];1;Banana;
#632;633;662;21;2;439.822971502571;41.8879020478639;4.41813130858877;-95.7017703068533;2021-08-26T05:51:00.632[UTC];1;Banana;
#633;634;663;21;3;439.822971502571;62.8318530717959;4.44288293815837;-96.3902532849877;2021-08-26T05:51:00.633[UTC];1;Banana;
#634;635;664;21;4;439.822971502571;83.7758040957278;4.47730534600039;-97.2494864251707;2021-08-26T05:51:00.634[UTC];1;Banana;
#635;636;665;21;5;439.822971502571;104.71975511966;4.52117764939261;-98.1774744082102;2021-08-26T05:51:00.635[UTC];1;Banana;
#636;637;666;21;6;439.822971502571;125.663706143592;4.57422794909802;-99.0470937131299;2021-08-26T05:51:00.636[UTC];1;Banana;
#637;638;667;21;7;439.822971502571;146.607657167524;4.63614119070485;-99.7094545320055;2021-08-26T05:51:00.637[UTC];1;Banana;
#638;639;668;21;8;439.822971502571;167.551608191456;4.70656762055847;-99.9983055932737;2021-08-26T05:51:00.638[UTC];1;Banana;
#639;640;669;21;9;439.822971502571;188.495559215388;4.78513136815775;-99.7355438950439;2021-08-26T05:51:00.639[UTC];1;Banana;
#640;641;670;21;10;439.822971502571;209.43951023932;4.87143874754304;-98.7378227040362;2021-08-26T05:51:00.640[UTC];1;Banana;
#641;642;671;21;11;439.822971502571;230.383461263251;4.96508595580165;-96.824165634779;2021-08-26T05:51:00.641[UTC];1;Banana;
#642;643;672;21;12;439.822971502571;251.327412287183;5.06566594268042;-93.8244007958212;2021-08-26T05:51:00.642[UTC];1;Banana;
#643;644;673;21;13;439.822971502571;272.271363311115;5.17277431888;-89.5881360708708;2021-08-26T05:51:00.643[UTC];1;Banana;
#644;645;674;21;14;439.822971502571;293.215314335047;5.28601425293152;-83.9939133817517;2021-08-26T05:51:00.644[UTC];1;Banana;
#645;646;675;21;15;439.822971502571;314.159265358979;5.40500037254619;-76.9581138974096;2021-08-26T05:51:00.645[UTC];1;Banana;
#646;647;676;21;16;439.822971502571;335.103216382911;5.52936173433719;-68.4431436220424;2021-08-26T05:51:00.646[UTC];1;Banana;
#647;648;677;21;17;439.822971502571;356.047167406843;5.6587439567433;-58.4644137469822;2021-08-26T05:51:00.647[UTC];1;Banana;
#648;649;678;21;18;439.822971502571;376.991118430775;5.79281062729517;-47.0956447502496;2021-08-26T05:51:00.648[UTC];1;Banana;
#649;650;679;21;19;439.822971502571;397.935069454707;5.93124410021434;-34.4720677095299;2021-08-26T05:51:00.649[UTC];1;Banana;
#650;651;680;21;20;439.822971502571;418.879020478639;6.07374579694027;-20.791169081776;2021-08-26T05:51:00.650[UTC];1;Banana;
#651;652;681;21;21;439.822971502571;439.822971502571;6.22003611342171;-6.31072308490583;2021-08-26T05:51:00.651[UTC];1;Banana;
#652;653;682;21;22;439.822971502571;460.766922526503;6.36985402623872;8.6560258266909;2021-08-26T05:51:00.652[UTC];1;Banana;
#653;654;683;21;23;439.822971502571;481.710873550435;6.52295647661453;23.7480348387967;2021-08-26T05:51:00.653[UTC];1;Banana;
#654;655;684;21;24;439.822971502571;502.654824574367;6.6791175983751;38.5668523022779;2021-08-26T05:51:00.654[UTC];1;Banana;
#655;656;685;21;25;439.822971502571;523.598775598299;6.83812784371124;52.6894461106283;2021-08-26T05:51:00.655[UTC];1;Banana;
#656;657;686;21;26;439.822971502571;544.542726622231;6.99979304964458;65.6830564311553;2021-08-26T05:51:00.656[UTC];1;Banana;
#657;658;687;21;27;439.822971502571;565.486677646163;7.16393347859014;77.1215361410224;2021-08-26T05:51:00.657[UTC];1;Banana;
#658;659;688;21;28;439.822971502571;586.430628670095;7.33038285837618;86.6025403784439;2021-08-26T05:51:00.658[UTC];1;Banana;
#660;661;690;22;0;460.766922526503;0;4.60766922526503;-99.4521895368273;2021-08-26T05:51:00.660[UTC];1;Banana;
#661;662;691;22;1;460.766922526503;20.943951023932;4.61242675799884;-99.5007936036309;2021-08-26T05:51:00.661[UTC];1;Banana;
#662;663;692;22;2;460.766922526503;41.8879020478639;4.62667000371234;-99.63283775235;2021-08-26T05:51:00.662[UTC];1;Banana;
#663;664;693;22;3;460.766922526503;62.8318530717959;4.65031180304052;-99.8073830698998;2021-08-26T05:51:00.663[UTC];1;Banana;
#664;665;694;22;4;460.766922526503;83.7758040957278;4.68320982069382;-99.9574318524082;2021-08-26T05:51:00.664[UTC];1;Banana;
#665;666;695;22;5;460.766922526503;104.71975511966;4.72517072714697;-99.9918314586961;2021-08-26T05:51:00.665[UTC];1;Banana;
#666;667;696;22;6;460.766922526503;125.663706143592;4.77595565239343;-99.7980319322933;2021-08-26T05:51:00.666[UTC];1;Banana;
#667;668;697;22;7;460.766922526503;146.607657167524;4.83528656890876;-99.2457591803936;2021-08-26T05:51:00.667[UTC];1;Banana;
#668;669;698;22;8;460.766922526503;167.551608191456;4.90285323359865;-98.1916450945244;2021-08-26T05:51:00.668[UTC];1;Banana;
#669;670;699;22;9;460.766922526503;188.495559215388;4.97832032656062;-96.4848154157926;2021-08-26T05:51:00.669[UTC];1;Banana;
#670;671;700;22;10;460.766922526503;209.43951023932;5.06133446181766;-93.9733782589321;2021-08-26T05:51:00.670[UTC];1;Banana;
#671;672;701;22;11;460.766922526503;230.383461263251;5.1515308027632;-90.5116861731447;2021-08-26T05:51:00.671[UTC];1;Banana;
#672;673;702;22;12;460.766922526503;251.327412287183;5.24853908303555;-85.9681690918935;2021-08-26T05:51:00.672[UTC];1;Banana;
#673;674;703;22;13;460.766922526503;272.271363311115;5.35198890295783;-80.2334618100927;2021-08-26T05:51:00.673[UTC];1;Banana;
#674;675;704;22;14;460.766922526503;293.215314335047;5.46151423558655;-73.228484882106;2021-08-26T05:51:00.674[UTC];1;Banana;
#675;676;705;22;15;460.766922526503;314.159265358979;5.57675713031721;-64.9120884268515;2021-08-26T05:51:00.675[UTC];1;Banana;
#676;677;706;22;16;460.766922526503;335.103216382911;5.6973706437682;-55.2878393746244;2021-08-26T05:51:00.676[UTC];1;Banana;
#677;678;707;22;17;460.766922526503;356.047167406843;5.82302105708867;-44.4095277680602;2021-08-26T05:51:00.677[UTC];1;Banana;
#678;679;708;22;18;460.766922526503;376.991118430775;5.95338945702556;-32.3849887244897;2021-08-26T05:51:00.678[UTC];1;Banana;
#679;680;709;22;19;460.766922526503;397.935069454707;6.08817276690196;-19.3778837557325;2021-08-26T05:51:00.679[UTC];1;Banana;
#680;681;710;22;20;460.766922526503;418.879020478639;6.22708431524488;-5.60715685908789;2021-08-26T05:51:00.680[UTC];1;Banana;
#681;682;711;22;21;460.766922526503;439.822971502571;6.36985402623872;8.6560258266909;2021-08-26T05:51:00.681[UTC];1;Banana;
#682;683;712;22;22;460.766922526503;460.766922526503;6.51622830929894;23.0939332346727;2021-08-26T05:51:00.682[UTC];1;Banana;
#683;684;713;22;23;460.766922526503;481.710873550435;6.66596971633736;37.3504810527452;2021-08-26T05:51:00.683[UTC];1;Banana;
#684;685;714;22;24;460.766922526503;502.654824574367;6.81885642584174;51.0418266900664;2021-08-26T05:51:00.684[UTC];1;Banana;
#685;686;715;22;25;460.766922526503;523.598775598299;6.97468160350408;63.7690481796594;2021-08-26T05:51:00.685[UTC];1;Banana;
#686;687;716;22;26;460.766922526503;544.542726622231;7.13325268031154;75.1324868566752;2021-08-26T05:51:00.686[UTC];1;Banana;
#687;688;717;22;27;460.766922526503;565.486677646163;7.294390581055;84.7472267205711;2021-08-26T05:51:00.687[UTC];1;Banana;
#688;689;718;22;28;460.766922526503;586.430628670095;7.45792892924669;92.2590963611822;2021-08-26T05:51:00.688[UTC];1;Banana;
#690;691;720;23;0;481.710873550435;0;4.81710873550435;-99.4521895368273;2021-08-26T05:51:00.690[UTC];1;Banana;
#691;692;721;23;1;481.710873550435;20.943951023932;4.82165961865016;-99.4035901664835;2021-08-26T05:51:00.691[UTC];1;Banana;
#692;693;722;23;2;481.710873550435;41.8879020478639;4.83528656890876;-99.2457591803936;2021-08-26T05:51:00.692[UTC];1;Banana;
#693;694;723;23;3;481.710873550435;62.8318530717959;4.85791320895257;-98.9430022850545;2021-08-26T05:51:00.693[UTC];1;Banana;
#694;695;724;23;4;481.710873550435;83.7758040957278;4.88941459735835;-98.4371842520433;2021-08-26T05:51:00.694[UTC];1;Banana;
#695;696;725;23;5;481.710873550435;104.71975511966;4.92962060212593;-97.6497851106161;2021-08-26T05:51:00.695[UTC];1;Banana;
#696;697;726;23;6;481.710873550435;125.663706143592;4.97832032656062;-96.4848154157926;2021-08-26T05:51:00.696[UTC];1;Banana;
#697;698;727;23;7;481.710873550435;146.607657167524;5.03526732991282;-94.8326054665715;2021-08-26T05:51:00.697[UTC];1;Banana;
#698;699;728;23;8;481.710873550435;167.551608191456;5.10018536039884;-92.5744604318201;2021-08-26T05:51:00.698[UTC];1;Banana;
#699;700;729;23;9;481.710873550435;188.495559215388;5.17277431888;-89.5881360708708;2021-08-26T05:51:00.699[UTC];1;Banana;
#700;701;730;23;10;481.710873550435;209.43951023932;5.25271619398963;-85.7540403158672;2021-08-26T05:51:00.700[UTC];1;Banana;
#701;702;731;23;11;481.710873550435;230.383461263251;5.33968074813803;-80.9620083947223;2021-08-26T05:51:00.701[UTC];1;Banana;
#702;703;732;23;12;481.710873550435;251.327412287183;5.43333078197614;-75.1184386277109;2021-08-26T05:51:00.702[UTC];1;Banana;
#703;704;733;23;13;481.710873550435;272.271363311115;5.53332685620519;-68.1535183348542;2021-08-26T05:51:00.703[UTC];1;Banana;
#704;705;734;23;14;481.710873550435;293.215314335047;5.63933139882135;-60.0282202305846;2021-08-26T05:51:00.704[UTC];1;Banana;
#705;706;735;23;15;481.710873550435;314.159265358979;5.75101216924131;-50.7407144810068;2021-08-26T05:51:00.705[UTC];1;Banana;
#706;707;736;23;16;481.710873550435;335.103216382911;5.86804508611595;-40.3318245005268;2021-08-26T05:51:00.706[UTC];1;Banana;
#707;708;737;23;17;481.710873550435;356.047167406843;5.99011645224999;-28.8891585400622;2021-08-26T05:51:00.707[UTC];1;Banana;
#708;709;738;23;18;481.710873550435;376.991118430775;6.11692462821318;-16.5495757009701;2021-08-26T05:51:00.708[UTC];1;Banana;
#709;710;739;23;19;481.710873550435;397.935069454707;6.24818121695142;-3.49969423271972;2021-08-26T05:51:00.709[UTC];1;Banana;
#710;711;740;23;20;481.710873550435;418.879020478639;6.38361182633991;10.0257795894274;2021-08-26T05:51:00.710[UTC];1;Banana;
#711;712;741;23;21;481.710873550435;439.822971502571;6.52295647661453;23.7480348387967;2021-08-26T05:51:00.711[UTC];1;Banana;
#712;713;742;23;22;481.710873550435;460.766922526503;6.66596971633736;37.3504810527452;2021-08-26T05:51:00.712[UTC];1;Banana;
#713;714;743;23;23;481.710873550435;481.710873550435;6.81242050517616;50.4873316844272;2021-08-26T05:51:00.713[UTC];1;Banana;
#714;715;744;23;24;481.710873550435;502.654824574367;6.96209191525515;62.7942456593675;2021-08-26T05:51:00.714[UTC];1;Banana;
#715;716;745;23;25;481.710873550435;523.598775598299;7.11478069588066;73.900712070018;2021-08-26T05:51:00.715[UTC];1;Banana;
#716;717;746;23;26;481.710873550435;544.542726622231;7.27029673956914;83.4437565221221;2021-08-26T05:51:00.716[UTC];1;Banana;
#717;718;747;23;27;481.710873550435;565.486677646163;7.42846248083692;91.0824552564557;2021-08-26T05:51:00.717[UTC];1;Banana;
#718;719;748;23;28;481.710873550435;586.430628670095;7.58911225334772;96.512670307276;2021-08-26T05:51:00.718[UTC];1;Banana;
#720;721;750;24;0;502.654824574367;0;5.02654824574367;-95.1056516295154;2021-08-26T05:51:00.720[UTC];0;Blueberry;
#721;722;751;24;1;502.654824574367;20.943951023932;5.03090967671236;-94.9699718756611;2021-08-26T05:51:00.721[UTC];1;Banana;
#722;723;752;24;2;502.654824574367;41.8879020478639;5.04397134216541;-94.5528406056216;2021-08-26T05:51:00.722[UTC];1;Banana;
#723;724;753;24;3;502.654824574367;62.8318530717959;5.06566594268042;-93.8244007958212;2021-08-26T05:51:00.723[UTC];1;Banana;
#724;725;754;24;4;502.654824574367;83.7758040957278;5.09588322099097;-92.7362883487439;2021-08-26T05:51:00.724[UTC];1;Banana;
#725;726;755;24;5;502.654824574367;104.71975511966;5.13447270691168;-91.223729737734;2021-08-26T05:51:00.725[UTC];0;Blueberry;
#726;727;756;24;6;502.654824574367;125.663706143592;5.18124733736608;-89.2084741536787;2021-08-26T05:51:00.726[UTC];0;Blueberry;
#727;728;757;24;7;502.654824574367;146.607657167524;5.23598775598299;-86.6025403784439;2021-08-26T05:51:00.727[UTC];0;Blueberry;
#728;729;758;24;8;502.654824574367;167.551608191456;5.29844707509125;-83.3127340055504;2021-08-26T05:51:00.728[UTC];0;Blueberry;
#729;730;759;24;9;502.654824574367;188.495559215388;5.36835587970665;-79.2458561826131;2021-08-26T05:51:00.729[UTC];0;Blueberry;
#730;731;760;24;10;502.654824574367;209.43951023932;5.44542726622231;-74.3144825477395;2021-08-26T05:51:00.730[UTC];1;Banana;
#731;732;761;24;11;502.654824574367;230.383461263251;5.52936173433719;-68.4431436220424;2021-08-26T05:51:00.731[UTC];1;Banana;
#732;733;762;24;12;502.654824574367;251.327412287183;5.61985178483258;-61.5746897265888;2021-08-26T05:51:00.732[UTC];1;Banana;
#733;734;763;24;13;502.654824574367;272.271363311115;5.71658611364493;-53.6765791423318;2021-08-26T05:51:00.733[UTC];1;Banana;
#734;735;764;24;14;502.654824574367;293.215314335047;5.81925333035509;-44.7467923728306;2021-08-26T05:51:00.734[UTC];1;Banana;
#735;736;765;24;15;502.654824574367;314.159265358979;5.92754516371475;-34.8190522248513;2021-08-26T05:51:00.735[UTC];1;Blueberry;
#736;737;766;24;16;502.654824574367;335.103216382911;6.04115914620745;-23.9670224252432;2021-08-26T05:51:00.736[UTC];0;Blueberry;
#737;738;767;24;17;502.654824574367;356.047167406843;6.15980079293417;-12.3071690197623;2021-08-26T05:51:00.737[UTC];0;Blueberry;
#738;739;768;24;18;502.654824574367;376.991118430775;6.28318530717959;-2.44921270764475e-014;2021-08-26T05:51:00.738[UTC];0;Blueberry;
#739;740;769;24;19;502.654824574367;397.935069454707;6.41103885629942;12.7505506726066;2021-08-26T05:51:00.739[UTC];0;Blueberry;
#740;741;770;24;20;502.654824574367;418.879020478639;6.54309946787478;25.6997596701223;2021-08-26T05:51:00.740[UTC];1;Banana;
#741;742;771;24;21;502.654824574367;439.822971502571;6.6791175983751;38.5668523022779;2021-08-26T05:51:00.741[UTC];1;Banana;
#742;743;772;24;22;502.654824574367;460.766922526503;6.81885642584174;51.0418266900664;2021-08-26T05:51:00.742[UTC];1;Banana;
#743;744;773;24;23;502.654824574367;481.710873550435;6.96209191525515;62.7942456593675;2021-08-26T05:51:00.743[UTC];1;Banana;
#744;745;774;24;24;502.654824574367;502.654824574367;7.10861270105339;73.4837726239604;2021-08-26T05:51:00.744[UTC];0;Blueberry;
#745;746;775;24;25;502.654824574367;523.598775598299;7.25821982634809;82.7721258728721;2021-08-26T05:51:00.745[UTC];0;Blueberry;
#746;747;776;24;26;502.654824574367;544.542726622231;7.41072637320432;90.3360327940672;2021-08-26T05:51:00.746[UTC];0;Blueberry;
#747;748;777;24;27;502.654824574367;565.486677646163;7.56595701324811;95.8806869651799;2021-08-26T05:51:00.747[UTC];1;Blueberry;
#748;749;778;24;28;502.654824574367;586.430628670095;7.72374750306022;99.1531515177369;2021-08-26T05:51:00.748[UTC];1;Blueberry;
#750;751;780;25;0;523.598775598299;0;5.23598775598299;-86.6025403784439;2021-08-26T05:51:00.750[UTC];0;Blueberry;
#751;752;781;25;1;523.598775598299;20.943951023932;5.24017487201077;-86.3924260346009;2021-08-26T05:51:00.751[UTC];1;Banana;
#752;753;782;25;2;523.598775598299;41.8879020478639;5.25271619398963;-85.7540403158672;2021-08-26T05:51:00.752[UTC];1;Banana;
#753;754;783;25;3;523.598775598299;62.8318530717959;5.27355211947766;-84.663669459778;2021-08-26T05:51:00.753[UTC];1;Banana;
#754;755;784;25;4;523.598775598299;83.7758040957278;5.30258487117296;-83.0831677158593;2021-08-26T05:51:00.754[UTC];1;Banana;
#755;756;785;25;5;523.598775598299;104.71975511966;5.33968074813803;-80.9620083947223;2021-08-26T05:51:00.755[UTC];0;Blueberry;
#756;757;786;25;6;523.598775598299;125.663706143592;5.38467310846054;-78.2401210894113;2021-08-26T05:51:00.756[UTC];0;Blueberry;
#757;758;787;25;7;523.598775598299;146.607657167524;5.43736593350298;-74.8514704971479;2021-08-26T05:51:00.757[UTC];0;Blueberry;
#758;759;788;25;8;523.598775598299;167.551608191456;5.49753780537779;-70.7283068080956;2021-08-26T05:51:00.758[UTC];0;Blueberry;
#759;760;789;25;9;523.598775598299;188.495559215388;5.56494612419527;-65.8059858132082;2021-08-26T05:51:00.759[UTC];1;Blueberry;
#760;761;790;25;10;523.598775598299;209.43951023932;5.63933139882135;-60.0282202305846;2021-08-26T05:51:00.760[UTC];1;Banana;
#761;762;791;25;11;523.598775598299;230.383461263251;5.72042146202248;-53.3525848053095;2021-08-26T05:51:00.761[UTC];1;Banana;
#762;763;792;25;12;523.598775598299;251.327412287183;5.80793548496374;-45.7560597983392;2021-08-26T05:51:00.762[UTC];1;Banana;
#763;764;793;25;13;523.598775598299;272.271363311115;5.90158769389502;-37.2403642377847;2021-08-26T05:51:00.763[UTC];1;Banana;
#764;765;794;25;14;523.598775598299;293.215314335047;6.00109072059937;-27.8368054689727;2021-08-26T05:51:00.764[UTC];1;Banana;
#765;766;795;25;15;523.598775598299;314.159265358979;6.10615854542716;-17.6103584715487;2021-08-26T05:51:00.765[UTC];0;Blueberry;
#766;767;796;25;16;523.598775598299;335.103216382911;6.21650901582399;-6.66268982289559;2021-08-26T05:51:00.766[UTC];0;Blueberry;
#767;768;797;25;17;523.598775598299;356.047167406843;6.33186594319932;4.86614110342328;2021-08-26T05:51:00.767[UTC];0;Blueberry;
#768;769;798;25;18;523.598775598299;376.991118430775;6.45196079640697;16.7975363365943;2021-08-26T05:51:00.768[UTC];0;Blueberry;
#769;770;799;25;19;523.598775598299;397.935069454707;6.57653402112359;28.9159500418985;2021-08-26T05:51:00.769[UTC];1;Blueberry;
#770;771;800;25;20;523.598775598299;418.879020478639;6.70533602144726;40.9723301894937;2021-08-26T05:51:00.770[UTC];1;Banana;
#771;772;801;25;21;523.598775598299;439.822971502571;6.83812784371124;52.6894461106283;2021-08-26T05:51:00.771[UTC];1;Banana;
#772;773;802;25;22;523.598775598299;460.766922526503;6.97468160350408;63.7690481796594;2021-08-26T05:51:00.772[UTC];1;Banana;
#773;774;803;25;23;523.598775598299;481.710873550435;7.11478069588066;73.900712070018;2021-08-26T05:51:00.773[UTC];1;Banana;
#774;775;804;25;24;523.598775598299;502.654824574367;7.25821982634809;82.7721258728721;2021-08-26T05:51:00.774[UTC];0;Blueberry;
#775;776;805;25;25;523.598775598299;523.598775598299;7.40480489693061;90.0804888179303;2021-08-26T05:51:00.775[UTC];0;Blueberry;
#776;777;806;25;26;523.598775598299;544.542726622231;7.55435277787059;95.5446103846222;2021-08-26T05:51:00.776[UTC];1;Blueberry;
#777;778;807;25;27;523.598775598299;565.486677646163;7.70669099162107;98.9172329694014;2021-08-26T05:51:00.777[UTC];1;Blueberry;
#778;779;808;25;28;523.598775598299;586.430628670095;7.8616573319526;99.9970541974905;2021-08-26T05:51:00.778[UTC];1;Blueberry;
#780;781;810;26;0;544.542726622231;0;5.44542726622231;-74.3144825477394;2021-08-26T05:51:00.780[UTC];0;Blueberry;
#781;782;811;26;1;544.542726622231;20.943951023932;5.44945346068454;-74.0444759543555;2021-08-26T05:51:00.781[UTC];1;Banana;
#782;783;812;26;2;544.542726622231;41.8879020478639;5.46151423558655;-73.2284848821059;2021-08-26T05:51:00.782[UTC];1;Banana;
#783;784;813;26;3;544.542726622231;62.8318530717959;5.48155655701562;-71.848990005426;2021-08-26T05:51:00.783[UTC];1;Banana;
#784;785;814;26;4;544.542726622231;83.7758040957278;5.50949332034316;-69.8781004924702;2021-08-26T05:51:00.784[UTC];1;Banana;
#785;786;815;26;5;544.542726622231;104.71975511966;5.54520521017478;-67.2794902239219;2021-08-26T05:51:00.785[UTC];1;Blueberry;
#786;787;816;26;6;544.542726622231;125.663706143592;5.5885431747363;-64.0110537028509;2021-08-26T05:51:00.786[UTC];1;Blueberry;
#787;788;817;26;7;544.542726622231;146.607657167524;5.63933139882135;-60.0282202305846;2021-08-26T05:51:00.787[UTC];1;Blueberry;
#788;789;818;26;8;544.542726622231;167.551608191456;5.6973706437682;-55.2878393746244;2021-08-26T05:51:00.788[UTC];1;Blueberry;
#789;790;819;26;9;544.542726622231;188.495559215388;5.76244181715612;-49.7525215354503;2021-08-26T05:51:00.789[UTC];1;Blueberry;
#790;791;820;26;10;544.542726622231;209.43951023932;5.83430963839304;-43.3952858616853;2021-08-26T05:51:00.790[UTC];1;Banana;
#791;792;821;26;11;544.542726622231;230.383461263251;5.91272627762194;-36.2043359661314;2021-08-26T05:51:00.791[UTC];1;Banana;
#792;793;822;26;12;544.542726622231;251.327412287183;5.99743486237363;-28.1877545161061;2021-08-26T05:51:00.792[UTC];1;Banana;
#793;794;823;26;13;544.542726622231;272.271363311115;6.08817276690196;-19.3778837557323;2021-08-26T05:51:00.793[UTC];1;Banana;
#794;795;824;26;14;544.542726622231;293.215314335047;6.18467462101099;-9.83514330109705;2021-08-26T05:51:00.794[UTC];1;Banana;
#795;796;825;26;15;544.542726622231;314.159265358979;6.28667499659452;0.34896823320722;2021-08-26T05:51:00.795[UTC];0;Blueberry;
#796;797;826;26;16;544.542726622231;335.103216382911;6.39391074966914;11.0499329873802;2021-08-26T05:51:00.796[UTC];0;Blueberry;
#797;798;827;26;17;544.542726622231;356.047167406843;6.50612301248301;22.1095576397343;2021-08-26T05:51:00.797[UTC];1;Blueberry;
#798;799;828;26;18;544.542726622231;376.991118430775;6.62305884386407;33.3367865593684;2021-08-26T05:51:00.798[UTC];1;Blueberry;
#799;800;829;26;19;544.542726622231;397.935069454707;6.7444725562426;44.5101181571619;2021-08-26T05:51:00.799[UTC];1;Blueberry;
#800;801;830;26;20;544.542726622231;418.879020478639;6.87012674493213;55.3816940762466;2021-08-26T05:51:00.800[UTC];1;Banana;
#801;802;831;26;21;544.542726622231;439.822971502571;6.99979304964458;65.6830564311553;2021-08-26T05:51:00.801[UTC];1;Banana;
#802;803;832;26;22;544.542726622231;460.766922526503;7.13325268031154;75.1324868566752;2021-08-26T05:51:00.802[UTC];1;Banana;
#803;804;833;26;23;544.542726622231;481.710873550435;7.27029673956914;83.4437565221221;2021-08-26T05:51:00.803[UTC];1;Banana;
#804;805;834;26;24;544.542726622231;502.654824574367;7.41072637320432;90.3360327940672;2021-08-26T05:51:00.804[UTC];0;Blueberry;
#805;806;835;26;25;544.542726622231;523.598775598299;7.55435277787059;95.5446103846222;2021-08-26T05:51:00.805[UTC];1;Blueberry;
#806;807;836;26;26;544.542726622231;544.542726622231;7.70099709280784;98.8320670610951;2021-08-26T05:51:00.806[UTC];1;Blueberry;
#807;808;837;26;27;544.542726622231;565.486677646163;7.85049019942366;99.999390494858;2021-08-26T05:51:00.807[UTC];1;Blueberry;
#808;809;838;26;28;544.542726622231;586.430628670095;8.00267244962316;98.896587258595;2021-08-26T05:51:00.808[UTC];0;Blueberry;
#810;811;840;27;0;565.486677646163;0;5.65486677646163;-58.7785252292473;2021-08-26T05:51:00.810[UTC];1;Blueberry;
#811;812;841;27;1;565.486677646163;20.943951023932;5.6587439567433;-58.4644137469822;2021-08-26T05:51:00.811[UTC];1;Banana;
#812;813;842;27;2;565.486677646163;41.8879020478639;5.6703595911835;-57.5181262455921;2021-08-26T05:51:00.812[UTC];1;Banana;
#813;814;843;27;3;565.486677646163;62.8318530717959;5.68966628507974;-55.9281670641689;2021-08-26T05:51:00.813[UTC];1;Banana;
#814;815;844;27;4;565.486677646163;83.7758040957278;5.71658611364493;-53.6765791423318;2021-08-26T05:51:00.814[UTC];1;Banana;
#815;816;845;27;5;565.486677646163;104.71975511966;5.75101216924131;-50.7407144810069;2021-08-26T05:51:00.815[UTC];1;Blueberry;
#816;817;846;27;6;565.486677646163;125.663706143592;5.79281062729517;-47.0956447502496;2021-08-26T05:51:00.816[UTC];1;Blueberry;
#817;818;847;27;7;565.486677646163;146.607657167524;5.84182324052556;-42.7171401648773;2021-08-26T05:51:00.817[UTC];1;Blueberry;
#818;819;848;27;8;565.486677646163;167.551608191456;5.89787015797091;-37.5851197885242;2021-08-26T05:51:00.818[UTC];1;Blueberry;
#819;820;849;27;9;565.486677646163;188.495559215388;5.96075295947766;-31.6874498390185;2021-08-26T05:51:00.819[UTC];1;Blueberry;
#820;821;850;27;10;565.486677646163;209.43951023932;6.03025779751232;-25.0239395520294;2021-08-26T05:51:00.820[UTC];1;Banana;
#821;822;851;27;11;565.486677646163;230.383461263251;6.10615854542716;-17.6103584715488;2021-08-26T05:51:00.821[UTC];1;Banana;
#822;823;852;27;12;565.486677646163;251.327412287183;6.18821986327463;-9.48227683000212;2021-08-26T05:51:00.822[UTC];1;Banana;
#823;824;853;27;13;565.486677646163;272.271363311115;6.27620010734671;-0.698514302818596;2021-08-26T05:51:00.823[UTC];1;Banana;
#824;825;854;27;14;565.486677646163;293.215314335047;6.36985402623872;8.65602582669099;2021-08-26T05:51:00.824[UTC];1;Banana;
#825;826;855;27;15;565.486677646163;314.159265358979;6.46893520300048;18.4683581524922;2021-08-26T05:51:00.825[UTC];0;Blueberry;
#826;827;856;27;16;565.486677646163;335.103216382911;6.57319821871718;28.5964597482825;2021-08-26T05:51:00.826[UTC];1;Blueberry;
#827;828;857;27;17;565.486677646163;356.047167406843;6.68240052685958;38.8695391923719;2021-08-26T05:51:00.827[UTC];1;Blueberry;
#828;829;858;27;18;565.486677646163;376.991118430775;6.79630403948339;49.0896724835597;2021-08-26T05:51:00.828[UTC];1;Blueberry;
#829;830;859;27;19;565.486677646163;397.935069454707;6.91467643564916;59.0348975346622;2021-08-26T05:51:00.829[UTC];1;Blueberry;
#830;831;860;27;20;565.486677646163;418.879020478639;7.03729220931204;68.463797768045;2021-08-26T05:51:00.830[UTC];1;Banana;
#831;832;861;27;21;565.486677646163;439.822971502571;7.16393347859014;77.1215361410224;2021-08-26T05:51:00.831[UTC];1;Banana;
#832;833;862;27;22;565.486677646163;460.766922526503;7.294390581055;84.7472267205711;2021-08-26T05:51:00.832[UTC];1;Banana;
#833;834;863;27;23;565.486677646163;481.710873550435;7.42846248083692;91.0824552564557;2021-08-26T05:51:00.833[UTC];1;Banana;
#834;835;864;27;24;565.486677646163;502.654824574367;7.56595701324811;95.8806869651799;2021-08-26T05:51:00.834[UTC];1;Blueberry;
#835;836;865;27;25;565.486677646163;523.598775598299;7.70669099162107;98.9172329694014;2021-08-26T05:51:00.835[UTC];1;Blueberry;
#836;837;866;27;26;565.486677646163;544.542726622231;7.85049019942366;99.999390494858;2021-08-26T05:51:00.836[UTC];1;Blueberry;
#837;838;867;27;27;565.486677646163;565.486677646163;7.99718928868506;98.9763296665236;2021-08-26T05:51:00.837[UTC];1;Blueberry;
#838;839;868;27;28;565.486677646163;586.430628670095;8.14663160353835;95.7482747151778;2021-08-26T05:51:00.838[UTC];0;Blueberry;
#840;841;870;28;0;586.430628670095;0;5.86430628670095;-40.67366430758;2021-08-26T05:51:00.840[UTC];1;Blueberry;
#841;842;871;28;1;586.430628670095;20.943951023932;5.86804508611595;-40.3318245005268;2021-08-26T05:51:00.841[UTC];1;Banana;
#842;843;872;28;2;586.430628670095;41.8879020478639;5.87924721865286;-39.3042533014765;2021-08-26T05:51:00.842[UTC];1;Banana;
#843;844;873;28;3;586.430628670095;62.8318530717959;5.89787015797091;-37.5851197885242;2021-08-26T05:51:00.843[UTC];1;Banana;
#844;845;874;28;4;586.430628670095;83.7758040957278;5.92384391754449;-35.1657765568525;2021-08-26T05:51:00.844[UTC];1;Banana;
#845;846;875;28;5;586.430628670095;104.71975511966;5.95707234599953;-32.0363286348913;2021-08-26T05:51:00.845[UTC];1;Blueberry;
#846;847;876;28;6;586.430628670095;125.663706143592;5.99743486237363;-28.1877545161062;2021-08-26T05:51:00.846[UTC];1;Blueberry;
#847;848;877;28;7;586.430628670095;146.607657167524;6.04478856026042;-23.6145020995794;2021-08-26T05:51:00.847[UTC];0;Blueberry;
#848;849;878;28;8;586.430628670095;167.551608191456;6.09897059879735;-18.3174585290616;2021-08-26T05:51:00.848[UTC];0;Blueberry;
#849;850;879;28;9;586.430628670095;188.495559215388;6.15980079293417;-12.3071690197622;2021-08-26T05:51:00.849[UTC];0;Blueberry;
#850;851;880;28;10;586.430628670095;209.43951023932;6.22708431524488;-5.60715685908781;2021-08-26T05:51:00.850[UTC];1;Banana;
#851;852;881;28;11;586.430628670095;230.383461263251;6.30061442611781;1.74282365322203;2021-08-26T05:51:00.851[UTC];1;Banana;
#852;853;882;28;12;586.430628670095;251.327412287183;6.38017515754367;9.68378574491064;2021-08-26T05:51:00.852[UTC];1;Banana;
#853;854;883;28;13;586.430628670095;272.271363311115;6.46554388680253;18.1349546998989;2021-08-26T05:51:00.853[UTC];1;Banana;
#854;855;884;28;14;586.430628670095;293.215314335047;6.55649374897134;26.9918550991705;2021-08-26T05:51:00.854[UTC];1;Banana;
#855;856;885;28;15;586.430628670095;314.159265358979;6.65279585026698;36.1252303220272;2021-08-26T05:51:00.855[UTC];1;Blueberry;
#856;857;886;28;16;586.430628670095;335.103216382911;6.75422125690723;45.3809662122285;2021-08-26T05:51:00.856[UTC];1;Blueberry;
#857;858;887;28;17;586.430628670095;356.047167406843;6.86054274573695;54.5811621957242;2021-08-26T05:51:00.857[UTC];1;Blueberry;
#858;859;888;28;18;586.430628670095;376.991118430775;6.97153631288032;63.5264537086182;2021-08-26T05:51:00.858[UTC];1;Blueberry;
#859;860;889;28;19;586.430628670095;397.935069454707;7.08698244490788;71.9996404368636;2021-08-26T05:51:00.859[UTC];0;Blueberry;
#860;861;890;28;20;586.430628670095;418.879020478639;7.20666716339493;79.7706171789323;2021-08-26T05:51:00.860[UTC];1;Banana;
#861;862;891;28;21;586.430628670095;439.822971502571;7.33038285837618;86.6025403784439;2021-08-26T05:51:00.861[UTC];1;Banana;
#862;863;892;28;22;586.430628670095;460.766922526503;7.45792892924669;92.2590963611822;2021-08-26T05:51:00.862[UTC];1;Banana;
#863;864;893;28;23;586.430628670095;481.710873550435;7.58911225334772;96.512670307276;2021-08-26T05:51:00.863[UTC];1;Banana;
#864;865;894;28;24;586.430628670095;502.654824574367;7.72374750306022;99.1531515177369;2021-08-26T05:51:00.864[UTC];1;Blueberry;
#865;866;895;28;25;586.430628670095;523.598775598299;7.8616573319526;99.9970541974905;2021-08-26T05:51:00.865[UTC];1;Blueberry;
#866;867;896;28;26;586.430628670095;544.542726622231;8.00267244962316;98.896587258595;2021-08-26T05:51:00.866[UTC];0;Blueberry;
#867;868;897;28;27;586.430628670095;565.486677646163;8.14663160353835;95.7482747151778;2021-08-26T05:51:00.867[UTC];0;Blueberry;
#868;869;898;28;28;586.430628670095;586.430628670095;8.29338148456228;90.5007127587797;2021-08-26T05:51:00.868[UTC];0;Blueberry;
#870;871;900;29;0;607.374579694027;0;6.07374579694027;-20.791169081776;2021-08-26T05:51:00.870[UTC];1;Banana;
#871;872;901;29;1;607.374579694027;20.943951023932;6.07735575018435;-20.4379276656218;2021-08-26T05:51:00.871[UTC];1;Banana;
#872;873;902;29;2;607.374579694027;41.8879020478639;6.08817276690196;-19.3778837557324;2021-08-26T05:51:00.872[UTC];1;Banana;
#873;874;903;29;3;607.374579694027;62.8318530717959;6.10615854542716;-17.6103584715488;2021-08-26T05:51:00.873[UTC];1;Banana;
#874;875;904;29;4;607.374579694027;83.7758040957278;6.1312499982498;-15.1351428921476;2021-08-26T05:51:00.874[UTC];1;Banana;
#875;876;905;29;5;607.374579694027;104.71975511966;6.16336034295267;-11.9538428428859;2021-08-26T05:51:00.875[UTC];1;Banana;
#876;877;906;29;6;607.374579694027;125.663706143592;6.20238056797742;-8.0716833415861;2021-08-26T05:51:00.876[UTC];1;Banana;
#877;878;907;29;7;607.374579694027;146.607657167524;6.24818121695142;-3.49969423271981;2021-08-26T05:51:00.877[UTC];1;Banana;
#878;879;908;29;8;607.374579694027;167.551608191456;6.30061442611781;1.74282365322203;2021-08-26T05:51:00.878[UTC];1;Banana;
#879;880;909;29;9;607.374579694027;188.495559215388;6.35951614434948;7.62567364705237;2021-08-26T05:51:00.879[UTC];1;Banana;
#880;881;910;29;10;607.374579694027;209.43951023932;6.42470846426343;14.1051206699704;2021-08-26T05:51:00.880[UTC];1;Banana;
#881;882;911;29;11;607.374579694027;230.383461263251;6.49600199570576;21.1213877727013;2021-08-26T05:51:00.881[UTC];1;Banana;
#882;883;912;29;12;607.374579694027;251.327412287183;6.57319821871718;28.5964597482825;2021-08-26T05:51:00.882[UTC];1;Banana;
#883;884;913;29;13;607.374579694027;272.271363311115;6.65609176121986;36.4323667362742;2021-08-26T05:51:00.883[UTC];1;Banana;
#884;885;914;29;14;607.374579694027;293.215314335047;6.7444725562426;44.5101181571619;2021-08-26T05:51:00.884[UTC];1;Banana;
#885;886;915;29;15;607.374579694027;314.159265358979;6.83812784371124;52.6894461106283;2021-08-26T05:51:00.885[UTC];1;Banana;
#886;887;916;29;16;607.374579694027;335.103216382911;6.93684399196542;60.8094968419666;2021-08-26T05:51:00.886[UTC];1;Banana;
#887;888;917;29;17;607.374579694027;356.047167406843;7.04040812365968;68.6905788337371;2021-08-26T05:51:00.887[UTC];1;Banana;
#888;889;918;29;18;607.374579694027;376.991118430775;7.14860953916342;76.1370369017971;2021-08-26T05:51:00.888[UTC];1;Banana;
#889;890;919;29;19;607.374579694027;397.935069454707;7.26124093774899;82.9412743685056;2021-08-26T05:51:00.889[UTC];1;Banana;
#890;891;920;29;20;607.374579694027;418.879020478639;7.37809944264537;88.8888915611792;2021-08-26T05:51:00.890[UTC];1;Banana;
#891;892;921;29;21;607.374579694027;439.822971502571;7.49898744044719;93.7648507077512;2021-08-26T05:51:00.891[UTC];1;Banana;
#892;893;922;29;22;607.374579694027;460.766922526503;7.62371324849669;97.3605174082563;2021-08-26T05:51:00.892[UTC];1;Banana;
#893;894;923;29;23;607.374579694027;481.710873550435;7.75209162584666;99.4813702279525;2021-08-26T05:51:00.893[UTC];1;Banana;
#894;895;924;29;24;607.374579694027;502.654824574367;7.88394414443927;99.9551157563932;2021-08-26T05:51:00.894[UTC];1;Banana;
#895;896;925;29;25;607.374579694027;523.598775598299;8.01909943738406;98.639899901719;2021-08-26T05:51:00.895[UTC];1;Banana;
#896;897;926;29;26;607.374579694027;544.542726622231;8.15739334086367;95.4322702825923;2021-08-26T05:51:00.896[UTC];1;Banana;
#897;898;927;29;27;607.374579694027;565.486677646163;8.29866894540197;90.2745220528065;2021-08-26T05:51:00.897[UTC];1;Banana;
#898;899;928;29;28;607.374579694027;586.430628670095;8.44277657113404;83.1610525596311;2021-08-26T05:51:00.898[UTC];1;Banana;");

    process_csv_data ("Tot_Month;Add_Month;Daily_Int;Date;MonDays;Int_Month;Tot_Mon2;Mon_Interest;
3640;0;0.000115068;20230430;30;1.003457821;\$3,652.59;\$0.00;
3652.586467;10;0.000115068;20230531;31;1.003573287;\$3,675.67;\$13.09;
3675.67394;10;0.000115068;20230630;30;1.003457821;\$3,698.42;\$12.74;
3698.41834;10;0.000115068;20230731;31;1.003573287;\$3,721.67;\$13.25;
3721.669583;10;0.000115068;20230831;31;1.003573287;\$3,745.00;\$13.33;
3745.00391;10;0.000115068;20230930;30;1.003457821;\$3,767.99;\$12.98;
3767.988041;10;0.000115068;20231031;31;1.003573287;\$3,791.49;\$13.50;
3791.487876;10;0.000115068;20231130;30;1.003457821;\$3,814.63;\$13.14;
3814.63274;10;0.000115068;20231231;31;1.003573287;\$3,838.30;\$13.67;
3838.299251;10;0.000115068;20240131;31;1.003573287;\$3,862.05;\$13.75;
3862.050329;10;0.000115068;20240228;28;1.003226928;\$3,884.55;\$12.49;
3884.545156;10;0.000115068;20240331;31;1.003573287;\$3,908.46;\$13.92;
3908.461484;10;0.000115068;20240430;30;1.003457821;\$3,932.01;\$13.55;
3932.010821;10;0.000115068;20240531;31;1.003573287;\$3,956.10;\$14.09;
3956.096757;10;0.000115068;20240630;30;1.003457821;\$3,979.81;\$13.71;
3979.810809;10;0.000115068;20240731;31;1.003573287;\$4,004.07;\$14.26;
4004.067548;10;0.000115068;20240831;31;1.003573287;\$4,028.41;\$14.34;
4028.410964;10;0.000115068;20240930;30;1.003457821;\$4,052.38;\$13.96;
4052.375065;10;0.000115068;20241031;31;1.003573287;\$4,076.89;\$14.52;
4076.891098;10;0.000115068;20241130;30;1.003457821;\$4,101.02;\$14.13;
4101.022834;10;0.000115068;20241231;31;1.003573287;\$4,125.71;\$14.69;
4125.712699;10;0.000115068;20250131;31;1.003573287;\$4,150.49;\$14.78;
4150.490788;10;0.000115068;20250228;28;1.003226928;\$4,173.92;\$13.43;
4173.916391;10;0.000115068;20250331;31;1.003573287;\$4,198.87;\$14.95;
4198.866726;10;0.000115068;20250430;30;1.003457821;\$4,223.42;\$14.55;
4223.420232;10;0.000115068;20250531;31;1.003573287;\$4,248.55;\$15.13;
4248.547458;10;0.000115068;20250630;30;1.003457821;\$4,273.27;\$14.73;
4273.272752;10;0.000115068;20250731;31;1.003573287;\$4,298.58;\$15.31;
4298.578115;10;0.000115068;20250831;31;1.003573287;\$4,323.97;\$15.40;
4323.973902;10;0.000115068;20250930;30;1.003457821;\$4,348.96;\$14.99;
4348.960006;10;0.000115068;20251031;31;1.003573287;\$4,374.54;\$15.58;
4374.535822;10;0.000115068;20251130;30;1.003457821;\$4,399.70;\$15.16;
4399.696761;10;0.000115068;20251231;31;1.003573287;\$4,425.45;\$15.76;
4425.453873;10;0.000115068;20260131;31;1.003573287;\$4,451.30;\$15.85;
4451.303023;10;0.000115068;20260228;28;1.003226928;\$4,475.70;\$14.40;
4475.699326;10;0.000115068;20260331;31;1.003573287;\$4,501.73;\$16.03;
4501.728018;10;0.000115068;20260430;30;1.003457821;\$4,527.33;\$15.60;
4527.328764;10;0.000115068;20260531;31;1.003573287;\$4,553.54;\$16.21;
4553.541943;10;0.000115068;20260630;30;1.003457821;\$4,579.32;\$15.78;
4579.321852;10;0.000115068;20260731;31;1.003573287;\$4,605.72;\$16.40;
4605.720817;10;0.000115068;20260831;31;1.003573287;\$4,632.21;\$16.49;
4632.214113;10;0.000115068;20260930;30;1.003457821;\$4,658.27;\$16.05;
4658.266057;10;0.000115068;20261031;31;1.003573287;\$4,684.95;\$16.68;
4684.947112;10;0.000115068;20261130;30;1.003457821;\$4,711.18;\$16.23;
4711.181397;10;0.000115068;20261231;31;1.003573287;\$4,738.05;\$16.87;
4738.051533;10;0.000115068;20270131;31;1.003573287;\$4,765.02;\$16.97;
4765.017685;10;0.000115068;20270228;28;1.003226928;\$4,790.43;\$15.41;
4790.426322;10;0.000115068;20270331;31;1.003573287;\$4,817.58;\$17.15;
4817.579624;10;0.000115068;20270430;30;1.003457821;\$4,844.27;\$16.69;
4844.272528;10;0.000115068;20270531;31;1.003573287;\$4,871.62;\$17.35;
4871.618238;10;0.000115068;20270630;30;1.003457821;\$4,898.50;\$16.88;
4898.497998;10;0.000115068;20270731;31;1.003573287;\$4,926.04;\$17.54;
4926.037471;10;0.000115068;20270831;31;1.003573287;\$4,953.68;\$17.64;
4953.67535;10;0.000115068;20270930;30;1.003457821;\$4,980.84;\$17.16;
4980.838849;10;0.000115068;20271031;31;1.003573287;\$5,008.67;\$17.83;
5008.672549;10;0.000115068;20271130;30;1.003457821;\$5,036.03;\$17.35;
5036.026219;10;0.000115068;20271231;31;1.003573287;\$5,064.06;\$18.03;
5064.05712;10;0.000115068;20280131;31;1.003573287;\$5,092.19;\$18.13;
5092.188183;10;0.000115068;20280228;28;1.003226928;\$5,118.65;\$16.46;
5118.652575;10;0.000115068;20280331;31;1.003573287;\$5,146.98;\$18.33;
5146.978724;10;0.000115068;20280430;30;1.003457821;\$5,174.81;\$17.83;
5174.810631;10;0.000115068;20280531;31;1.003573287;\$5,203.34;\$18.53;
5203.337448;10;0.000115068;20280630;30;1.003457821;\$5,231.36;\$18.03;
5231.364235;10;0.000115068;20280731;31;1.003573287;\$5,260.09;\$18.73;
5260.093134;10;0.000115068;20280831;31;1.003573287;\$5,288.92;\$18.83;
5288.924689;10;0.000115068;20280930;30;1.003457821;\$5,317.25;\$18.32;
5317.247421;10;0.000115068;20281031;31;1.003573287;\$5,346.28;\$19.04;
5346.283205;10;0.000115068;20281130;30;1.003457821;\$5,374.80;\$18.52;
5374.804273;10;0.000115068;20281231;31;1.003573287;\$5,404.05;\$19.24;
5404.045724;10;0.000115068;20290131;31;1.003573287;\$5,433.39;\$19.35;
5433.391664;10;0.000115068;20290228;28;1.003226928;\$5,460.96;\$17.57;
5460.957096;10;0.000115068;20290331;31;1.003573287;\$5,490.51;\$19.55;
5490.506396;10;0.000115068;20290430;30;1.003457821;\$5,519.53;\$19.02;
5519.526161;10;0.000115068;20290531;31;1.003573287;\$5,549.28;\$19.76;
5549.284746;10;0.000115068;20290630;30;1.003457821;\$5,578.51;\$19.22;
5578.507756;10;0.000115068;20290731;31;1.003573287;\$5,608.48;\$19.97;
5608.477098;10;0.000115068;20290831;31;1.003573287;\$5,638.55;\$20.08;
5638.55353;10;0.000115068;20290930;30;1.003457821;\$5,668.09;\$19.53;
5668.085215;10;0.000115068;20291031;31;1.003573287;\$5,698.37;\$20.29;
5698.374644;10;0.000115068;20291130;30;1.003457821;\$5,728.11;\$19.74;
5728.11318;10;0.000115068;20291231;31;1.003573287;\$5,758.62;\$20.50;
5758.617106;10;0.000115068;20300131;31;1.003573287;\$5,789.23;\$20.61");

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
        if ($txt =~ m/\.group_info/)
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

        my $example = get_field (2, 3);
        $example =~ s/^(...).*$/$1../;
        $example = "\"/csv_analyse/groupby?groupstr=(" . $example . ")" . get_col_name_of_number_type_col () . "\"";
        $html_text .= "<form action=\"/csv_analyse/groupby\">
                <label for=\"groupstr\">Group by <font size=-2><a href=$example>Example</a></font></label><br>
                <input type=\"text\" id=\"groupstr\" name=\"groupstr\" value=\"$group\">
                <input type=\"submit\" value=\"Group By\">
                </form></td><td>";
                
        my $f1 = get_field (2, 3);
        $f1 =~ s/\W/./img;
        $f1 =~ s/^(...)..*$/$1../img;
        my $f2 = get_field (2, 5);
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
        my $group_cols = 0;
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
        if (defined ($valid_regex))
        {
            %meta_data = %new_meta_data;
            $use_regex = 1;
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
                        if ($col_types {$col_num} eq "PRICE")
                        {
                            print ("$col_num is now number (was price) 'cos >>$field<<\n");
                            set_col_type ($col_num, "NUMBER");
                        }
                        else
                        {
                            $col_calculations {$col_num} += $field;
                        }
                    }
                    elsif ($field =~ m/^(-|)\$(\d*[\d,])+($|\.\d+)$/)
                    {
                        if ($col_types {$col_num} eq "PRICE")
                        {
                            $col_calculations {$col_num} = add_price ($col_calculations {$col_num}, $field);
                        }
                        elsif ($col_types {$col_num} ne "NUMBER")
                        {
                            print ("$col_num is now general (was NUMBER) 'cos >>$field<<\n");
                            set_col_type ($col_num, "GENERAL");
                        }
                    }
                    else
                    {
                        print ("$col_num is now general 'cos >>$field<<\n");
                        set_col_type ($col_num, "GENERAL");
                    }
                }

                $field = $csv_data {$field_id};
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
                                $group_colours {$this_group} = $group_colours {$group_cols};
                                $group_cols++;
                            }
                            $row =~ s/<td>/<td><font color=$group_colours{$this_group}>/img;
                            $row =~ s/<\/td>/<\/font><\/td>/img;
                            $group_counts {$this_group}++;

                            $pot_group_price = get_field ($old_row_num, get_num_of_col_header ($chosen_col));
                            $group_prices {$this_group} = add_price ($group_prices {$this_group}, $pot_group_price);
                            $group_prices {$this_group . "_calc"} .= "+$pot_group_price ($old_row_num,$chosen_col)";
                        }
                        elsif ($first_group_only && $fake_row =~ m/$overall_match/im && ($fake_row =~ m/($group)/mg))
                        {
                            my $this_group = $1;
                            if ($fake_row =~ m/($group2)/mg)
                            {
                                $group_counts {$this_group}++;
                                $pot_group_price = get_field ($old_row_num, get_num_of_col_header ($chosen_col));
                                $group_prices {$this_group} = add_price ($group_prices {$this_group}, $pot_group_price);
                                $group_prices {$this_group . "_calc"} .= "+$pot_group_price ($old_row_num,$chosen_col)";
                                $row .= " <td>$this_group</td>\n";
                                my $g_price = "GPRICE_$this_group";
                                $row .= " <td>$g_price</td> </tr>\n";
                                
                                if (!defined ($group_colours {$this_group}))
                                {
                                    $group_colours {$this_group} = $group_colours {$group_cols};
                                    $group_cols++;
                                }
                                $row =~ s/<td>/<td><font color=$group_colours{$this_group}>/img;
                                $row =~ s/<\/td>/<\/font><\/td>/img;
                            }
                            else
                            {
                                $row .= "<td><font size=-3>No group</font></td>\n";
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
                                $pot_group_price = get_field ($old_row_num, get_num_of_col_header ($chosen_col));
                                $group_prices {$this_group} = add_price ($group_prices {$this_group}, $pot_group_price);
                                $group_prices {$this_group . "_calc"} .= "+$pot_group_price ($old_row_num,$chosen_col)";
                                $row .= " <td>$this_group</td>\n";
                                my $g_price = "GPRICE_$this_group";
                                $row .= " <td>$g_price</td> </tr>\n";
                                if (!defined ($group_colours {$this_group}))
                                {
                                    $group_colours {$this_group} = $group_colours {$group_cols};
                                    $group_cols++;
                                }
                                $row =~ s/<td>/<td><font color=$group_colours{$this_group}>/img;
                                $row =~ s/<\/td>/<\/font><\/td>/img;
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
                $g_price =~ s/(\d\d)$/.$1/;
                
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
                $group_block .= "<br>" . get_col_header ($c) . ": $col_types{$c} ($col_calculations{$c})"; 
            }
            #$group_block .= "<br>Column $c (" . get_col_header ($c) . "): $col_types{$c} ($col_calculations{$c})"; 
            #$group_block .= "<br>Column $c (" . get_col_header ($c) . "): $col_types{$c}";
        }

        if ($get_group_info)
        {
            my $col = $1;
            write_to_socket (\*CLIENT, $group_block, "", "noredirect");
            next;
        }

        $group_block =~ s/<br>/\n/img;
        $group_block =~ s/^((.*\n){0,7})(.*)\n/$1\nrest truncated../m;
        $group_block = "<a href=\"/csv_analyse$original_url.group_info\">View all group information</a><br><font size=-1>$1$2</font>";
        $group_block =~ s/\n/<br>/img;
        $group_block = "<div style=\"-webkit-mask-image:linear-gradient(to bottom, black 0%, transparent 100%);mask-image:linear-gradient(to bottom, black 0%, transparent 100%)\">" .
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
