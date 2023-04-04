#!D:\StrawberryPerl\perl\bin\perl.exe
# -T
use strict;
use warnings;
open BAR_CHART, "> D:\\D_Downloads\\apache_lounge\\Apache24\\htdocs\\xmage_stats.html";

print BAR_CHART "<!DOCTYPE html>\n";
print BAR_CHART "<html lang=\"en\">\n";
print BAR_CHART "<head>\n";
print BAR_CHART "<meta charset=\"UTF-8\">\n";
print BAR_CHART "<title>Xmage Users</title>\n";
print BAR_CHART "<link rel=\"stylesheet\" href=\"https://cdnjs.cloudflare.com/ajax/libs/normalize/5.0.0/normalize.min.css\">\n";
print BAR_CHART "<link rel='stylesheet' href='https://fonts.googleapis.com/css?family=Khand'>\n";
print BAR_CHART "    <style>\n";
print BAR_CHART "        * {\n";
print BAR_CHART "        box-sizing: border-box;\n";
print BAR_CHART "        padding: 0;\n";
print BAR_CHART "        margin: 0;\n";
print BAR_CHART "        }\n";
print BAR_CHART "        body {\n";
print BAR_CHART "        margin: 50px auto;\n";
print BAR_CHART "        font-family: \"Khand\";\n";
print BAR_CHART "        font-size: 1.2em;\n";
print BAR_CHART "        text-align: center;\n";
print BAR_CHART "        }\n";
print BAR_CHART "        ul {\n";
print BAR_CHART "        padding-top: 20px;\n";
print BAR_CHART "        display: flex;\n";
print BAR_CHART "        gap: 2rem;\n";
print BAR_CHART "        }\n";
print BAR_CHART "        li {\n";
print BAR_CHART "        margin: 0.5rem 0;\n";
print BAR_CHART "        }\n";
print BAR_CHART "        legend {\n";
print BAR_CHART "        margin: 0 auto;\n";
print BAR_CHART "        }\n";
print BAR_CHART "    </style>\n";
print BAR_CHART "<script>\n";
print BAR_CHART "if (document.location.search.match (/type=embed/gi)) {\n";
print BAR_CHART "    window.parent.postMessage (\"resize\", \"*\");\n";
print BAR_CHART "}\n";
print BAR_CHART "</script>\n";
print BAR_CHART "</head>\n";
print BAR_CHART "<body translate=\"no\" >\n";
print BAR_CHART "<h1>Hourly stats for the maximum number of players on xmage.today</h1><br>\n";
print BAR_CHART "<h3>Hover over one of the bars in the graph below to view that hour's stats</h3><br>\n";
print BAR_CHART "<canvas id=\"xmage_canvas\" style=\"background: white;\"></canvas>\n";
print BAR_CHART "<legend for=\"xmage_canvas\"></legend>\n";
print BAR_CHART "<script id=\"rendered-js\" >\n";
print BAR_CHART "var canvas = document.getElementById (\"xmage_canvas\");\n";
print BAR_CHART "canvas.width = 500;\n";
print BAR_CHART "canvas.height = 500;\n";
print BAR_CHART "var ctx = canvas.getContext (\"2d\");\n";
print BAR_CHART "var min_gridy;\n";
print BAR_CHART "var max_gridy;\n";
print BAR_CHART "var barSize;\n";
print BAR_CHART "function drawActualLine (ctx, startX, startY, endX, endY, color) {\n";
print BAR_CHART "    ctx.save ();\n";
print BAR_CHART "    ctx.strokeStyle = color;\n";
print BAR_CHART "    ctx.beginPath ();\n";
print BAR_CHART "    ctx.moveTo (startX, startY);\n";
print BAR_CHART "    ctx.lineTo (endX, endY);\n";
print BAR_CHART "    ctx.stroke ();\n";
print BAR_CHART "    ctx.restore ();\n";
print BAR_CHART "}\n";
print BAR_CHART "function drawLine (ctx, startX, startY, endX, endY, color, options, canvas) {\n";
print BAR_CHART "    startX += options.padding;\n";
print BAR_CHART "    startY += canvas.height - options.padding;\n";
print BAR_CHART "    endX += options.padding + 2;\n";
print BAR_CHART "    endY += canvas.height - options.padding;\n";
print BAR_CHART "    ctx.save ();\n";
print BAR_CHART "    ctx.strokeStyle = color;\n";
print BAR_CHART "    ctx.beginPath ();\n";
print BAR_CHART "    ctx.moveTo (startX, startY);\n";
print BAR_CHART "    ctx.lineTo (endX, endY);\n";
print BAR_CHART "    ctx.stroke ();\n";
print BAR_CHART "    ctx.restore ();\n";
print BAR_CHART "}\n";
print BAR_CHART "function drawSquare (ctx, startX, startY, width, color, options, canvas) \n";
print BAR_CHART "{\n";
print BAR_CHART "    ctx.save ();\n";
print BAR_CHART "    ctx.fillStyle = color;\n";
print BAR_CHART "    ctx.fillRect (startX, startY, width, width);\n";
print BAR_CHART "    ctx.restore ();\n";
print BAR_CHART "}\n";
print BAR_CHART "function drawBar (ctx, upperLeftCornerX, upperLeftCornerY, width, height, color)\n";
print BAR_CHART "{\n";
print BAR_CHART "    ctx.save ();\n";
print BAR_CHART "    ctx.fillStyle = color;\n";
print BAR_CHART "    ctx.fillRect (upperLeftCornerX, upperLeftCornerY, width, height);\n";
print BAR_CHART "    ctx.restore ();\n";
print BAR_CHART "}\n";
print BAR_CHART "class BarChart \n";
print BAR_CHART "{\n";
print BAR_CHART "    constructor (options) {\n";
print BAR_CHART "        this.options = options;\n";
print BAR_CHART "        this.canvas = options.canvas;\n";
print BAR_CHART "        this.ctx = this.canvas.getContext (\"2d\");\n";
print BAR_CHART "        this.titleOptions = options.titleOptions;\n";
print BAR_CHART "        this.maxValue = Math.max (...Object.values (this.options.data));\n";
print BAR_CHART "        this.multiplier = (options.canvas.height - options.padding * 2) / this.maxValue;\n";
print BAR_CHART "        \n";
print BAR_CHART "    }\n";
print BAR_CHART "    drawGridLines () {\n";
print BAR_CHART "        var canvasActualHeight = this.canvas.height - this.options.padding * 2;\n";
print BAR_CHART "        var canvasActualWidth = this.canvas.width - this.options.padding * 2;\n";
print BAR_CHART "        var gridValue = 0;\n";
print BAR_CHART "        max_gridy = 0;\n";
print BAR_CHART "        min_gridy = 10000000000;\n";
print BAR_CHART "        while (gridValue <= this.maxValue) {\n";
print BAR_CHART "            var gridY = canvasActualHeight * (1 - gridValue / this.maxValue) + this.options.padding;\n";
print BAR_CHART "            if (max_gridy < gridY) { max_gridy  = gridY; }\n";
print BAR_CHART "            if (min_gridy > gridY) { min_gridy  = gridY; }\n";
print BAR_CHART "            drawActualLine (this.ctx, 0, gridY, this.canvas.width, gridY, this.options.gridColor);\n";
print BAR_CHART "            // Writing grid markers\n";
print BAR_CHART "            this.ctx.save ();\n";
print BAR_CHART "            this.ctx.fillStyle = \"black\";\n";
print BAR_CHART "            this.ctx.textBaseline = \"bottom\";\n";
print BAR_CHART "            this.ctx.font = \"bold 10px Arial\";\n";
print BAR_CHART "            this.ctx.fillText (gridValue, 0, gridY - 5);\n";
print BAR_CHART "            this.ctx.restore ();\n";
print BAR_CHART "            gridValue += this.options.gridStep;\n";
print BAR_CHART "        }\n";
print BAR_CHART "        min_gridy = canvasActualHeight * (1 - gridValue / this.maxValue) + this.options.padding;\n";
print BAR_CHART "        drawActualLine (this.ctx, 25, min_gridy, 25, max_gridy, \"red\");\n";
print BAR_CHART "    }\n";
print BAR_CHART "    getBar = function(x, y) {\n";
print BAR_CHART "        var canvasActualHeight = this.canvas.height - this.options.padding * 2;\n";
print BAR_CHART "        var canvasActualWidth = this.canvas.width - this.options.padding * 2;\n";
print BAR_CHART "        var barIndex = 0;\n";
print BAR_CHART "        var numberOfBars = Object.keys (this.options.data).length;\n";
print BAR_CHART "        barSize = canvasActualWidth / numberOfBars;\n";
print BAR_CHART "        var values = Object.values (this.options.data);\n";
print BAR_CHART "        \n";
print BAR_CHART "        for (let thekey of Object.keys (this.options.data)) {\n";
print BAR_CHART "            if (x > this.options.padding + barIndex * barSize && x < this.options.padding + (barIndex+1) * barSize)\n";
print BAR_CHART "            {\n";
print BAR_CHART "                return thekey;\n";
print BAR_CHART "            }\n";
print BAR_CHART "            barIndex++;\n";
print BAR_CHART "        }\n";
print BAR_CHART "        return \"\";\n";
print BAR_CHART "    }\n";
print BAR_CHART "    getKey = function(searchVal) {\n";
print BAR_CHART "        var barIndex = 0;\n";
print BAR_CHART "        for (let thekey of Object.keys (this.options.data)) {\n";
print BAR_CHART "            if (thekey == searchVal)\n";
print BAR_CHART "            {\n";
print BAR_CHART "                return barIndex;\n";
print BAR_CHART "            }\n";
print BAR_CHART "            barIndex++;\n";
print BAR_CHART "        }\n";
print BAR_CHART "        return 0;\n";
print BAR_CHART "    }\n";
print BAR_CHART "    getBarValue = function(x, y) {\n";
print BAR_CHART "        var canvasActualHeight = this.canvas.height - this.options.padding * 2;\n";
print BAR_CHART "        var canvasActualWidth = this.canvas.width - this.options.padding * 2;\n";
print BAR_CHART "        var barIndex = 0;\n";
print BAR_CHART "        var numberOfBars = Object.keys (this.options.data).length;\n";
print BAR_CHART "        barSize = canvasActualWidth / numberOfBars;\n";
print BAR_CHART "        var values = Object.values (this.options.data);\n";
print BAR_CHART "        \n";
print BAR_CHART "        for (let thekey of Object.keys (this.options.data)) {\n";
print BAR_CHART "            if (x > this.options.padding + barIndex * barSize && x < this.options.padding + (barIndex+1) * barSize)\n";
print BAR_CHART "            {\n";
print BAR_CHART "                var reg = /.*\\((.+)\\)/;\n";
print BAR_CHART "                return thekey.match(reg);\n";
print BAR_CHART "            }\n";
print BAR_CHART "            barIndex++;\n";
print BAR_CHART "        }\n";
print BAR_CHART "        return \"\";\n";
print BAR_CHART "    }\n";
print BAR_CHART "    drawBars () {\n";
print BAR_CHART "        var canvasActualHeight = this.canvas.height - this.options.padding * 2;\n";
print BAR_CHART "        var canvasActualWidth = this.canvas.width - this.options.padding * 2;\n";
print BAR_CHART "        var barIndex = 0;\n";
print BAR_CHART "        var numberOfBars = Object.keys (this.options.data).length;\n";
print BAR_CHART "        barSize = canvasActualWidth / numberOfBars;\n";
print BAR_CHART "        var values = Object.values (this.options.data);\n";
print BAR_CHART "        var oldBarHeight = 0;\n";
print BAR_CHART "        var barHeight = 0;\n";
print BAR_CHART "        var start_weekend_bars = 0;\n";
print BAR_CHART "        start_weekend_bars = this.getKey (\"2023-03-05 00 (81)\");\n";
print BAR_CHART "        for (let val of values) {\n";
print BAR_CHART "            oldBarHeight = barHeight;\n";
print BAR_CHART "            barHeight = Math.round (canvasActualHeight * val / this.maxValue);\n";
print BAR_CHART "            if ((barIndex - start_weekend_bars) % 168 == 0) {\n";
print BAR_CHART "                drawBar (this.ctx, this.options.padding + barIndex * barSize, this.options.padding, barSize, canvasActualHeight, \"royalblue\");\n";
print BAR_CHART "            }\n";
print BAR_CHART "            if (oldBarHeight > 0 && barHeight > 0) {\n";
print BAR_CHART "                drawLine (this.ctx, + barIndex * barSize,  -1*oldBarHeight , barIndex * barSize, -1*barHeight , \"skyblue\", this.options, this.canvas);\n";
print BAR_CHART "            }\n";
print BAR_CHART "            barIndex++;\n";
print BAR_CHART "        }\n";
print BAR_CHART "    }\n";
print BAR_CHART "    drawLabel () {\n";
print BAR_CHART "        this.ctx.save ();\n";
print BAR_CHART "        this.ctx.textBaseline = \"bottom\";\n";
print BAR_CHART "        this.ctx.textAlign = this.titleOptions.align;\n";
print BAR_CHART "        this.ctx.fillStyle = this.titleOptions.fill;\n";
print BAR_CHART "        this.ctx.font = \`\${this.titleOptions.font.weight} \${this.titleOptions.font.size} \${this.titleOptions.font.family}`;\n";
print BAR_CHART "        let xPos = this.canvas.width / 2;\n";
print BAR_CHART "        if (this.titleOptions.align == \"left\") {\n";
print BAR_CHART "            xPos = 10;\n";
print BAR_CHART "        }\n";
print BAR_CHART "        if (this.titleOptions.align == \"right\") {\n";
print BAR_CHART "            xPos = this.canvas.width - 10;\n";
print BAR_CHART "        }\n";
print BAR_CHART "        this.ctx.fillText (this.options.seriesName, xPos, this.canvas.height);\n";
print BAR_CHART "        this.ctx.restore ();\n";
print BAR_CHART "    }\n";
print BAR_CHART "    draw () {\n";
print BAR_CHART "        this.drawGridLines ();\n";
print BAR_CHART "        this.drawBars ();\n";
print BAR_CHART "        this.drawLabel ();\n";
print BAR_CHART "    }\n";
print BAR_CHART "}\n";
print BAR_CHART "var myBarchart = new BarChart (\n";
print BAR_CHART "    {\n";
print BAR_CHART "        canvas: canvas,\n";
print BAR_CHART "        seriesName: \"Xmage Users\",\n";
print BAR_CHART "        padding: 50,\n";
print BAR_CHART "        gridStep: 10,\n";
print BAR_CHART "        gridColor: \"lightgrey\",\n";

# Read from xmagelog of data gathering thingo..
`sort c:/xmage_clean/mage/Mage.Client/xmage_users.txt /unique > c:/xmage_clean/mage/Mage.Client/xmage_users2.txt`;
`find /I \"People Counter\" c:/xmage_clean/mage/Mage.Client/mageclient.log >> c:/xmage_clean/mage/Mage.Client/xmage_users.txt`;
`find /I \"People Counter\" c:/xmage_clean/mage/Mage.Client/mageclient.log.1 >> c:/xmage_clean/mage/Mage.Client/xmage_users.txt`;
`find /I \"People Counter\" c:/xmage_clean/mage/Mage.Client/mageclient.log.2 >> c:/xmage_clean/mage/Mage.Client/xmage_users.txt`;
`find /I \"People Counter\" c:/xmage_clean/mage/Mage.Client/mageclient.log.3 >> c:/xmage_clean/mage/Mage.Client/xmage_users.txt`;
`find /I \"People Counter\" c:/xmage_clean/mage/Mage.Client/mageclient.log.4 >> c:/xmage_clean/mage/Mage.Client/xmage_users.txt`;
`del c:/xmage_clean/mage/Mage.Client/mageclient.log.1`;
`del c:/xmage_clean/mage/Mage.Client/mageclient.log.2`;
`del c:/xmage_clean/mage/Mage.Client/mageclient.log.3`;
`del c:/xmage_clean/mage/Mage.Client/mageclient.log.4`;
`sort c:/xmage_clean/mage/Mage.Client/xmage_users444.txt /unique >> c:/xmage_clean/mage/Mage.Client/xmage_users2.txt`;
`sort c:/xmage_clean/mage/Mage.Client/xmage_users.txt /unique >> c:/xmage_clean/mage/Mage.Client/xmage_users2.txt`;
`sort c:/xmage_clean/mage/Mage.Client/xmage_users2.txt /unique > c:/xmage_clean/mage/Mage.Client/xmage_users.txt`;

open PROC, "find /I \"People Counter\" c:/xmage_clean/mage/Mage.Client/xmage_users.txt |";
my %yyyymmddhh;
my $lines_read = 0;
my $found_yyyymmddhh = 0;
while (<PROC>)
{
    chomp;
    my $line = $_;
    # Example line: ERROR 2023-03-05 20:07:36,928 Banned (People counter = 68:beta.xmage.today,70
    $lines_read++;
    
    if ($line =~ m/(\d\d\d\d).(\d\d).(\d\d) (\d\d).*People counter = (\d+):beta/)
    {
         my $ymdh = "$1-$2-$3 $4";
         my $people_count = $5;
         if (!defined ($yyyymmddhh {$ymdh}))
         {
             $found_yyyymmddhh++;
             $yyyymmddhh {$ymdh} = $people_count;
         }
         if ($people_count > $yyyymmddhh {$ymdh})
         {
             $yyyymmddhh {$ymdh} = $people_count;
         }
    }
}
close PROC;

open XMAGE_OUT, "> c:\\xmage_clean\\mage\\Mage.Client\\xmage_users444.txt";
my $key;
my $first_key;
foreach $key (sort keys (%yyyymmddhh))
{
    my $k = $key;
    $first_key = $key;
    $first_key =~ s/\W//g;
    print XMAGE_OUT "$k People counter = $yyyymmddhh{$key}:beta\n";
}
close XMAGE_OUT;
`sort c:/xmage_clean/mage/Mage.Client/xmage_users.txt > c:/xmage_clean/mage/Mage.Client/xmage_backup_$first_key.txt`;
`del c:/xmage_clean/mage/Mage.Client/xmage_users.txt`;
`sort c:/xmage_clean/mage/Mage.Client/xmage_users444.txt > c:/xmage_clean/mage/Mage.Client/xmage_users.txt`;

# Print data line
print BAR_CHART "        data: {";

foreach $key (sort keys (%yyyymmddhh))
{
    # Check that the full 24 hours for that day exist..
    my $ymd = $key;
    $ymd =~ s/..$//;
    
    $yyyymmddhh {$ymd . "00"} = 0 + $yyyymmddhh {$ymd . "00"};
    $yyyymmddhh {$ymd . "01"} = 0 + $yyyymmddhh {$ymd . "01"};
    $yyyymmddhh {$ymd . "02"} = 0 + $yyyymmddhh {$ymd . "02"};
    $yyyymmddhh {$ymd . "03"} = 0 + $yyyymmddhh {$ymd . "03"};
    $yyyymmddhh {$ymd . "04"} = 0 + $yyyymmddhh {$ymd . "04"};
    $yyyymmddhh {$ymd . "05"} = 0 + $yyyymmddhh {$ymd . "05"};
    $yyyymmddhh {$ymd . "06"} = 0 + $yyyymmddhh {$ymd . "06"};
    $yyyymmddhh {$ymd . "07"} = 0 + $yyyymmddhh {$ymd . "07"};
    $yyyymmddhh {$ymd . "08"} = 0 + $yyyymmddhh {$ymd . "08"};
    $yyyymmddhh {$ymd . "09"} = 0 + $yyyymmddhh {$ymd . "09"};
    $yyyymmddhh {$ymd . "10"} = 0 + $yyyymmddhh {$ymd . "10"};
    $yyyymmddhh {$ymd . "11"} = 0 + $yyyymmddhh {$ymd . "11"};
    $yyyymmddhh {$ymd . "12"} = 0 + $yyyymmddhh {$ymd . "12"};
    $yyyymmddhh {$ymd . "13"} = 0 + $yyyymmddhh {$ymd . "13"};
    $yyyymmddhh {$ymd . "14"} = 0 + $yyyymmddhh {$ymd . "14"};
    $yyyymmddhh {$ymd . "15"} = 0 + $yyyymmddhh {$ymd . "15"};
    $yyyymmddhh {$ymd . "16"} = 0 + $yyyymmddhh {$ymd . "16"};
    $yyyymmddhh {$ymd . "17"} = 0 + $yyyymmddhh {$ymd . "17"};
    $yyyymmddhh {$ymd . "18"} = 0 + $yyyymmddhh {$ymd . "18"};
    $yyyymmddhh {$ymd . "19"} = 0 + $yyyymmddhh {$ymd . "19"};
    $yyyymmddhh {$ymd . "20"} = 0 + $yyyymmddhh {$ymd . "20"};
    $yyyymmddhh {$ymd . "21"} = 0 + $yyyymmddhh {$ymd . "21"};
    $yyyymmddhh {$ymd . "22"} = 0 + $yyyymmddhh {$ymd . "22"};
    $yyyymmddhh {$ymd . "23"} = 0 + $yyyymmddhh {$ymd . "23"};
}

foreach $key (sort keys (%yyyymmddhh))
{
    print BAR_CHART "\"$key ($yyyymmddhh{$key})\": $yyyymmddhh{$key},";
}
print BAR_CHART "\"DONE\": 0 },\n";

# Print colors line
print BAR_CHART "        colors: [";

my @chars = ('0'..'9', 'A'..'F');
my $len = 8;
my $string;
my %hour_colours;

foreach $key (sort keys (%yyyymmddhh))
{
    my $hour = $key;
    $hour =~ s/.*(..)$/$1/;
    if (!defined ($hour_colours {$hour}))
    {
        $len = 6;
        $string = "";
        while ($len--)
        {
             $string .= $chars[rand @chars] 
        }
        $string =~ s/^../33/;
        $hour_colours {$hour} = $string;
    }

    $string = $hour_colours {$hour};
    print BAR_CHART "\"\#$string\",";
}
print BAR_CHART "],\n";

# Example lines:
#print BAR_CHART "        data: {\"2023-03-04 00 (0)\": 0,\"2023-03-04 01 (0)\": 0,\"2023-03-04 02 (0)\": 0,\"2023-03-04 03 (0)\": 0,\"2023-03-04 04 (0)\": 0,\"2023-03-04 05 (0)\": 0,\"2023-03-04 06 (0)\": 0,\"2023-03-04 07 (0)\": 0,\"2023-03-04 08 (0)\": 0,\"2023-03-04 09 (0)\": 0,\"2023-03-04 10 (0)\": 0,\"2023-03-04 11 (0)\": 0,\"2023-03-04 12 (0)\": 0,\"2023-03-04 13 (0)\": 0,\"2023-03-04 14 (0)\": 0,\"2023-03-04 15 (0)\": 0,\"2023-03-04 16 (98)\": 98,\"2023-03-04 17 (99)\": 99,\"2023-03-04 18 (89)\": 89,\"2023-03-04 19 (78)\": 78,\"2023-03-04 20 (70)\": 70,\"2023-03-04 21 (75)\": 75,\"2023-03-04 22 (0)\": 0,\"2023-03-04 23 (66)\": 66,\"2023-03-05 00 (81)\": 81,\"2023-03-05 01 (95)\": 95,\"2023-03-05 02 (0)\": 0,\"2023-03-05 03 (0)\": 0,\"2023-03-05 04 (0)\": 0,\"2023-03-05 05 (0)\": 0,\"2023-03-05 06 (0)\": 0,\"2023-03-05 07 (0)\": 0,\"2023-03-05 08 (0)\": 0,\"2023-03-05 09 (0)\": 0,\"2023-03-05 10 (0)\": 0,\"2023-03-05 11 (0)\": 0,\"2023-03-05 12 (0)\": 0,\"2023-03-05 13 (91)\": 91,\"2023-03-05 14 (89)\": 89,\"2023-03-05 15 (97)\": 97,\"2023-03-05 16 (100)\": 100,\"2023-03-05 17 (90)\": 90,\"2023-03-05 18 (85)\": 85,\"2023-03-05 19 (85)\": 85,\"2023-03-05 20 (80)\": 80,\"2023-03-05 21 (80)\": 80,\"2023-03-05 22 (94)\": 94,\"2023-03-05 23 (99)\": 99,\"2023-03-06 00 (99)\": 99,\"2023-03-06 01 (99)\": 99,\"2023-03-06 02 (119)\": 119,\"2023-03-06 03 (0)\": 0,\"2023-03-06 04 (0)\": 0,\"2023-03-06 05 (0)\": 0,\"2023-03-06 06 (121)\": 121,\"2023-03-06 07 (145)\": 145,\"2023-03-06 08 (0)\": 0,\"2023-03-06 09 (0)\": 0,\"2023-03-06 10 (0)\": 0,\"2023-03-06 11 (0)\": 0,\"2023-03-06 12 (0)\": 0,\"2023-03-06 13 (0)\": 0,\"2023-03-06 14 (0)\": 0,\"2023-03-06 15 (0)\": 0,\"2023-03-06 16 (0)\": 0,\"2023-03-06 17 (0)\": 0,\"2023-03-06 18 (0)\": 0,\"2023-03-06 19 (51)\": 51,\"2023-03-06 20 (50)\": 50,\"2023-03-06 21 (64)\": 64,\"2023-03-06 22 (71)\": 71,\"2023-03-06 23 (91)\": 91,\"2023-03-07 00 (97)\": 97,\"2023-03-07 01 (94)\": 94,\"2023-03-07 02 (0)\": 0,\"2023-03-07 03 (0)\": 0,\"2023-03-07 04 (0)\": 0,\"2023-03-07 05 (0)\": 0,\"2023-03-07 06 (127)\": 127,\"2023-03-07 07 (147)\": 147,\"2023-03-07 08 (0)\": 0,\"2023-03-07 09 (0)\": 0,\"2023-03-07 10 (0)\": 0,\"2023-03-07 11 (0)\": 0,\"2023-03-07 12 (0)\": 0,\"2023-03-07 13 (0)\": 0,\"2023-03-07 14 (0)\": 0,\"2023-03-07 15 (0)\": 0,\"2023-03-07 16 (0)\": 0,\"2023-03-07 17 (0)\": 0,\"2023-03-07 18 (0)\": 0,\"2023-03-07 19 (0)\": 0,\"2023-03-07 20 (71)\": 71,\"2023-03-07 21 (71)\": 71,\"2023-03-07 22 (82)\": 82,\"2023-03-07 23 (84)\": 84,\"2023-03-08 00 (98)\": 98,\"2023-03-08 01 (80)\": 80,\"2023-03-08 02 (0)\": 0,\"2023-03-08 03 (87)\": 87,\"2023-03-08 04 (122)\": 122,\"2023-03-08 05 (0)\": 0,\"2023-03-08 06 (0)\": 0,\"2023-03-08 07 (0)\": 0,\"2023-03-08 08 (0)\": 0,\"2023-03-08 09 (0)\": 0,\"2023-03-08 10 (0)\": 0,\"2023-03-08 11 (0)\": 0,\"2023-03-08 12 (0)\": 0,\"2023-03-08 13 (0)\": 0,\"2023-03-08 14 (0)\": 0,\"2023-03-08 15 (0)\": 0,\"2023-03-08 16 (0)\": 0,\"2023-03-08 17 (0)\": 0,\"2023-03-08 18 (0)\": 0,\"2023-03-08 19 (0)\": 0,\"2023-03-08 20 (0)\": 0,\"2023-03-08 21 (0)\": 0,\"2023-03-08 22 (69)\": 69,\"2023-03-08 23 (77)\": 77,\"2023-03-09 00 (97)\": 97,\"2023-03-09 01 (99)\": 99,\"2023-03-09 02 (99)\": 99,\"2023-03-09 03 (119)\": 119,\"2023-03-09 04 (40)\": 40,\"2023-03-09 05 (0)\": 0,\"2023-03-09 06 (0)\": 0,\"2023-03-09 07 (126)\": 126,\"2023-03-09 08 (137)\": 137,\"2023-03-09 09 (104)\": 104,\"2023-03-09 10 (0)\": 0,\"2023-03-09 11 (0)\": 0,\"2023-03-09 12 (0)\": 0,\"2023-03-09 13 (0)\": 0,\"2023-03-09 14 (0)\": 0,\"2023-03-09 15 (0)\": 0,\"2023-03-09 16 (0)\": 0,\"2023-03-09 17 (0)\": 0,\"2023-03-09 18 (0)\": 0,\"2023-03-09 19 (70)\": 70,\"2023-03-09 20 (67)\": 67,\"2023-03-09 21 (80)\": 80,\"2023-03-09 22 (83)\": 83,\"2023-03-09 23 (92)\": 92,\"2023-03-10 00 (97)\": 97,\"2023-03-10 01 (104)\": 104,\"2023-03-10 02 (102)\": 102,\"2023-03-10 03 (103)\": 103,\"2023-03-10 04 (106)\": 106,\"2023-03-10 05 (121)\": 121,\"2023-03-10 06 (123)\": 123,\"2023-03-10 07 (133)\": 133,\"2023-03-10 08 (143)\": 143,\"2023-03-10 09 (124)\": 124,\"2023-03-10 10 (105)\": 105,\"2023-03-10 11 (105)\": 105,\"2023-03-10 12 (56)\": 56,\"2023-03-10 13 (94)\": 94,\"2023-03-10 14 (95)\": 95,\"2023-03-10 15 (87)\": 87,\"2023-03-10 16 (84)\": 84,\"2023-03-10 17 (75)\": 75,\"2023-03-10 18 (72)\": 72,\"2023-03-10 19 (62)\": 62,\"2023-03-10 20 (81)\": 81,\"2023-03-10 21 (99)\": 99,\"2023-03-10 22 (97)\": 97,\"2023-03-10 23 (100)\": 100,\"2023-03-11 00 (108)\": 108,\"2023-03-11 01 (105)\": 105,\"2023-03-11 02 (118)\": 118,\"2023-03-11 03 (90)\": 90,\"2023-03-11 04 (103)\": 103,\"2023-03-11 05 (110)\": 110,\"2023-03-11 06 (121)\": 121,\"2023-03-11 07 (143)\": 143,\"2023-03-11 08 (136)\": 136,\"2023-03-11 09 (118)\": 118,\"2023-03-11 10 (113)\": 113,\"2023-03-11 11 (105)\": 105,\"2023-03-11 12 (98)\": 98,\"2023-03-11 13 (87)\": 87,\"2023-03-11 14 (91)\": 91,\"2023-03-11 15 (96)\": 96,\"2023-03-11 16 (91)\": 91,\"2023-03-11 17 (56)\": 56,\"2023-03-11 18 (58)\": 58,\"2023-03-11 19 (52)\": 52,\"2023-03-11 20 (61)\": 61,\"2023-03-11 21 (63)\": 63,\"2023-03-11 22 (67)\": 67,\"2023-03-11 23 (77)\": 77,\"2023-03-12 00 (89)\": 89,\"2023-03-12 01 (93)\": 93,\"2023-03-12 02 (99)\": 99,\"2023-03-12 03 (103)\": 103,\"2023-03-12 04 (105)\": 105,\"2023-03-12 05 (120)\": 120,\"2023-03-12 06 (136)\": 136,\"2023-03-12 07 (137)\": 137,\"2023-03-12 08 (137)\": 137,\"2023-03-12 09 (132)\": 132,\"2023-03-12 10 (116)\": 116,\"2023-03-12 11 (107)\": 107,\"2023-03-12 12 (110)\": 110,\"2023-03-12 13 (96)\": 96,\"2023-03-12 14 (96)\": 96,\"2023-03-12 15 (96)\": 96,\"2023-03-12 16 (82)\": 82,\"2023-03-12 17 (80)\": 80,\"2023-03-12 18 (74)\": 74,\"2023-03-12 19 (68)\": 68,\"2023-03-12 20 (70)\": 70,\"2023-03-12 21 (77)\": 77,\"2023-03-12 22 (81)\": 81,\"2023-03-12 23 (95)\": 95,\"2023-03-13 00 (105)\": 105,\"2023-03-13 01 (0)\": 0,\"2023-03-13 02 (0)\": 0,\"2023-03-13 03 (0)\": 0,\"2023-03-13 04 (0)\": 0,\"2023-03-13 05 (0)\": 0,\"2023-03-13 06 (0)\": 0,\"2023-03-13 07 (0)\": 0,\"2023-03-13 08 (0)\": 0,\"2023-03-13 09 (0)\": 0,\"2023-03-13 10 (97)\": 97,\"2023-03-13 11 (117)\": 117,\"2023-03-13 12 (121)\": 121,\"2023-03-13 13 (106)\": 106,\"2023-03-13 14 (78)\": 78,\"2023-03-13 15 (74)\": 74,\"2023-03-13 16 (63)\": 63,\"2023-03-13 17 (58)\": 58,\"2023-03-13 18 (48)\": 48,\"2023-03-13 19 (53)\": 53,\"2023-03-13 20 (65)\": 65,\"2023-03-13 21 (66)\": 66,\"2023-03-13 22 (69)\": 69,\"2023-03-13 23 (73)\": 73,\"2023-03-14 00 (85)\": 85,\"2023-03-14 01 (91)\": 91,\"2023-03-14 02 (104)\": 104,\"2023-03-14 03 (112)\": 112,\"2023-03-14 04 (112)\": 112,\"2023-03-14 05 (112)\": 112,\"2023-03-14 06 (142)\": 142,\"2023-03-14 07 (155)\": 155,\"2023-03-14 08 (150)\": 150,\"2023-03-14 09 (139)\": 139,\"2023-03-14 10 (125)\": 125,\"2023-03-14 11 (119)\": 119,\"2023-03-14 12 (109)\": 109,\"2023-03-14 13 (111)\": 111,\"2023-03-14 14 (114)\": 114,\"2023-03-14 15 (77)\": 77,\"2023-03-14 16 (75)\": 75,\"2023-03-14 17 (66)\": 66,\"2023-03-14 18 (60)\": 60,\"2023-03-14 19 (63)\": 63,\"2023-03-14 20 (67)\": 67,\"2023-03-14 21 (51)\": 51,\"2023-03-14 22 (63)\": 63,\"2023-03-14 23 (62)\": 62,\"2023-03-15 00 (74)\": 74,\"2023-03-15 01 (94)\": 94,\"2023-03-15 02 (106)\": 106,\"2023-03-15 03 (113)\": 113,\"2023-03-15 04 (111)\": 111,\"2023-03-15 05 (112)\": 112,\"2023-03-15 06 (117)\": 117,\"2023-03-15 07 (124)\": 124,\"2023-03-15 08 (119)\": 119,\"2023-03-15 09 (114)\": 114,\"2023-03-15 10 (120)\": 120,\"2023-03-15 11 (99)\": 99,\"2023-03-15 12 (101)\": 101,\"2023-03-15 13 (101)\": 101,\"2023-03-15 14 (67)\": 67,\"2023-03-15 15 (68)\": 68,\"2023-03-15 16 (58)\": 58,\"2023-03-15 17 (54)\": 54,\"2023-03-15 18 (51)\": 51,\"2023-03-15 19 (54)\": 54,\"2023-03-15 20 (65)\": 65,\"2023-03-15 21 (67)\": 67,\"2023-03-15 22 (74)\": 74,\"2023-03-15 23 (76)\": 76,\"2023-03-16 00 (79)\": 79,\"2023-03-16 01 (85)\": 85,\"2023-03-16 02 (0)\": 0,\"2023-03-16 03 (0)\": 0,\"2023-03-16 04 (0)\": 0,\"2023-03-16 05 (0)\": 0,\"2023-03-16 06 (0)\": 0,\"2023-03-16 07 (0)\": 0,\"2023-03-16 08 (0)\": 0,\"2023-03-16 09 (0)\": 0,\"2023-03-16 10 (0)\": 0,\"2023-03-16 11 (0)\": 0,\"2023-03-16 12 (0)\": 0,\"2023-03-16 13 (0)\": 0,\"2023-03-16 14 (0)\": 0,\"2023-03-16 15 (0)\": 0,\"2023-03-16 16 (0)\": 0,\"2023-03-16 17 (0)\": 0,\"2023-03-16 18 (46)\": 46,\"2023-03-16 19 (49)\": 49,\"2023-03-16 20 (53)\": 53,\"2023-03-16 21 (67)\": 67,\"2023-03-16 22 (68)\": 68,\"2023-03-16 23 (76)\": 76,\"2023-03-17 00 (88)\": 88,\"2023-03-17 01 (97)\": 97,\"2023-03-17 02 (95)\": 95,\"2023-03-17 03 (100)\": 100,\"2023-03-17 04 (112)\": 112,\"2023-03-17 05 (111)\": 111,\"2023-03-17 06 (120)\": 120,\"2023-03-17 07 (123)\": 123,\"2023-03-17 08 (125)\": 125,\"2023-03-17 09 (107)\": 107,\"2023-03-17 10 (106)\": 106,\"2023-03-17 11 (108)\": 108,\"2023-03-17 12 (111)\": 111,\"2023-03-17 13 (105)\": 105,\"2023-03-17 14 (87)\": 87,\"2023-03-17 15 (77)\": 77,\"2023-03-17 16 (67)\": 67,\"2023-03-17 17 (64)\": 64,\"2023-03-17 18 (41)\": 41,\"2023-03-17 19 (50)\": 50,\"2023-03-17 20 (64)\": 64,\"2023-03-17 21 (82)\": 82,\"2023-03-17 22 (91)\": 91,\"2023-03-17 23 (96)\": 96,\"2023-03-18 00 (107)\": 107,\"2023-03-18 01 (109)\": 109,\"2023-03-18 02 (123)\": 123,\"2023-03-18 03 (119)\": 119,\"2023-03-18 04 (113)\": 113,\"2023-03-18 05 (110)\": 110,\"2023-03-18 06 (122)\": 122,\"2023-03-18 07 (129)\": 129,\"2023-03-18 08 (133)\": 133,\"2023-03-18 09 (125)\": 125,\"2023-03-18 10 (106)\": 106,\"2023-03-18 11 (90)\": 90,\"2023-03-18 12 (108)\": 108,\"2023-03-18 13 (103)\": 103,\"2023-03-18 14 (0)\": 0,\"2023-03-18 15 (0)\": 0,\"2023-03-18 16 (84)\": 84,\"2023-03-18 17 (32)\": 32,\"2023-03-18 18 (0)\": 0,\"2023-03-18 19 (0)\": 0,\"2023-03-18 20 (0)\": 0,\"2023-03-18 21 (0)\": 0,\"2023-03-18 22 (0)\": 0,\"2023-03-18 23 (0)\": 0,\"DONE\": 0 },\n";
#print BAR_CHART "        colors: [\"#33AB28\",\"#33AD0F\",\"#33D1E7\",\"#33D451\",\"#338248\",\"#333A5F\",\"#33B7CD\",\"#33CA3A\",\"#334C97\",\"#337749\",\"#334C3D\",\"#336028\",\"#3342CC\",\"#33E65B\",\"#3363E1\",\"#336F87\",\"#337655\",\"#335716\",\"#3391E7\",\"#33DF55\",\"#33A487\",\"#332040\",\"#334685\",\"#33D491\",\"#33AB28\",\"#33AD0F\",\"#33D1E7\",\"#33D451\",\"#338248\",\"#333A5F\",\"#33B7CD\",\"#33CA3A\",\"#334C97\",\"#337749\",\"#334C3D\",\"#336028\",\"#3342CC\",\"#33E65B\",\"#3363E1\",\"#336F87\",\"#337655\",\"#335716\",\"#3391E7\",\"#33DF55\",\"#33A487\",\"#332040\",\"#334685\",\"#33D491\",\"#33AB28\",\"#33AD0F\",\"#33D1E7\",\"#33D451\",\"#338248\",\"#333A5F\",\"#33B7CD\",\"#33CA3A\",\"#334C97\",\"#337749\",\"#334C3D\",\"#336028\",\"#3342CC\",\"#33E65B\",\"#3363E1\",\"#336F87\",\"#337655\",\"#335716\",\"#3391E7\",\"#33DF55\",\"#33A487\",\"#332040\",\"#334685\",\"#33D491\",\"#33AB28\",\"#33AD0F\",\"#33D1E7\",\"#33D451\",\"#338248\",\"#333A5F\",\"#33B7CD\",\"#33CA3A\",\"#334C97\",\"#337749\",\"#334C3D\",\"#336028\",\"#3342CC\",\"#33E65B\",\"#3363E1\",\"#336F87\",\"#337655\",\"#335716\",\"#3391E7\",\"#33DF55\",\"#33A487\",\"#332040\",\"#334685\",\"#33D491\",\"#33AB28\",\"#33AD0F\",\"#33D1E7\",\"#33D451\",\"#338248\",\"#333A5F\",\"#33B7CD\",\"#33CA3A\",\"#334C97\",\"#337749\",\"#334C3D\",\"#336028\",\"#3342CC\",\"#33E65B\",\"#3363E1\",\"#336F87\",\"#337655\",\"#335716\",\"#3391E7\",\"#33DF55\",\"#33A487\",\"#332040\",\"#334685\",\"#33D491\",\"#33AB28\",\"#33AD0F\",\"#33D1E7\",\"#33D451\",\"#338248\",\"#333A5F\",\"#33B7CD\",\"#33CA3A\",\"#334C97\",\"#337749\",\"#334C3D\",\"#336028\",\"#3342CC\",\"#33E65B\",\"#3363E1\",\"#336F87\",\"#337655\",\"#335716\",\"#3391E7\",\"#33DF55\",\"#33A487\",\"#332040\",\"#334685\",\"#33D491\",\"#33AB28\",\"#33AD0F\",\"#33D1E7\",\"#33D451\",\"#338248\",\"#333A5F\",\"#33B7CD\",\"#33CA3A\",\"#334C97\",\"#337749\",\"#334C3D\",\"#336028\",\"#3342CC\",\"#33E65B\",\"#3363E1\",\"#336F87\",\"#337655\",\"#335716\",\"#3391E7\",\"#33DF55\",\"#33A487\",\"#332040\",\"#334685\",\"#33D491\",\"#33AB28\",\"#33AD0F\",\"#33D1E7\",\"#33D451\",\"#338248\",\"#333A5F\",\"#33B7CD\",\"#33CA3A\",\"#334C97\",\"#337749\",\"#334C3D\",\"#336028\",\"#3342CC\",\"#33E65B\",\"#3363E1\",\"#336F87\",\"#337655\",\"#335716\",\"#3391E7\",\"#33DF55\",\"#33A487\",\"#332040\",\"#334685\",\"#33D491\",\"#33AB28\",\"#33AD0F\",\"#33D1E7\",\"#33D451\",\"#338248\",\"#333A5F\",\"#33B7CD\",\"#33CA3A\",\"#334C97\",\"#337749\",\"#334C3D\",\"#336028\",\"#3342CC\",\"#33E65B\",\"#3363E1\",\"#336F87\",\"#337655\",\"#335716\",\"#3391E7\",\"#33DF55\",\"#33A487\",\"#332040\",\"#334685\",\"#33D491\",\"#33AB28\",\"#33AD0F\",\"#33D1E7\",\"#33D451\",\"#338248\",\"#333A5F\",\"#33B7CD\",\"#33CA3A\",\"#334C97\",\"#337749\",\"#334C3D\",\"#336028\",\"#3342CC\",\"#33E65B\",\"#3363E1\",\"#336F87\",\"#337655\",\"#335716\",\"#3391E7\",\"#33DF55\",\"#33A487\",\"#332040\",\"#334685\",\"#33D491\",\"#33AB28\",\"#33AD0F\",\"#33D1E7\",\"#33D451\",\"#338248\",\"#333A5F\",\"#33B7CD\",\"#33CA3A\",\"#334C97\",\"#337749\",\"#334C3D\",\"#336028\",\"#3342CC\",\"#33E65B\",\"#3363E1\",\"#336F87\",\"#337655\",\"#335716\",\"#3391E7\",\"#33DF55\",\"#33A487\",\"#332040\",\"#334685\",\"#33D491\",\"#33AB28\",\"#33AD0F\",\"#33D1E7\",\"#33D451\",\"#338248\",\"#333A5F\",\"#33B7CD\",\"#33CA3A\",\"#334C97\",\"#337749\",\"#334C3D\",\"#336028\",\"#3342CC\",\"#33E65B\",\"#3363E1\",\"#336F87\",\"#337655\",\"#335716\",\"#3391E7\",\"#33DF55\",\"#33A487\",\"#332040\",\"#334685\",\"#33D491\",\"#33AB28\",\"#33AD0F\",\"#33D1E7\",\"#33D451\",\"#338248\",\"#333A5F\",\"#33B7CD\",\"#33CA3A\",\"#334C97\",\"#337749\",\"#334C3D\",\"#336028\",\"#3342CC\",\"#33E65B\",\"#3363E1\",\"#336F87\",\"#337655\",\"#335716\",\"#3391E7\",\"#33DF55\",\"#33A487\",\"#332040\",\"#334685\",\"#33D491\",\"#33AB28\",\"#33AD0F\",\"#33D1E7\",\"#33D451\",\"#338248\",\"#333A5F\",\"#33B7CD\",\"#33CA3A\",\"#334C97\",\"#337749\",\"#334C3D\",\"#336028\",\"#3342CC\",\"#33E65B\",\"#3363E1\",\"#336F87\",\"#337655\",\"#335716\",\"#3391E7\",\"#33DF55\",\"#33A487\",\"#332040\",\"#334685\",\"#33D491\",\"#33AB28\",\"#33AD0F\",\"#33D1E7\",\"#33D451\",\"#338248\",\"#333A5F\",\"#33B7CD\",\"#33CA3A\",\"#334C97\",\"#337749\",\"#334C3D\",\"#336028\",\"#3342CC\",\"#33E65B\",\"#3363E1\",\"#336F87\",\"#337655\",\"#335716\",\"#3391E7\",\"#33DF55\",\"#33A487\",\"#332040\",\"#334685\",\"#33D491\",],\n";
print BAR_CHART "        titleOptions: { align: \"center\", fill: \"black\", font: { weight: \"bold\", size: \"18px\", family: \"Lato\" } } \n";
print BAR_CHART "    }\n";
print BAR_CHART ");\n";
print BAR_CHART "myBarchart.draw ();\n";
print BAR_CHART "</script>\n";
print BAR_CHART "<canvas id=\"canvas_info\" style=\"background: skyblue;\"></canvas>\n";
print BAR_CHART "<script>\n";
print BAR_CHART "var canvas_info = document.getElementById(\"canvas_info\");\n";
print BAR_CHART "canvas_info.width = 500;\n";
print BAR_CHART "canvas_info.height = 100;\n";
print BAR_CHART "var xmage_canvas = document.getElementById(\"xmage_canvas\");\n";
print BAR_CHART "var ctx = canvas_info.getContext(\"2d\");\n";
print BAR_CHART "var xmage_ctx = xmage_canvas.getContext(\"2d\");\n";
print BAR_CHART "ctx.font = \"bold 20px Arial\";\n";
print BAR_CHART "var cw = xmage_canvas.width;\n";
print BAR_CHART "var ch = xmage_canvas.height;\n";
print BAR_CHART "function reOffset() {\n";
print BAR_CHART "  var BB = xmage_canvas.getBoundingClientRect();\n";
print BAR_CHART "  offsetX = BB.left;\n";
print BAR_CHART "  offsetY = BB.top;\n";
print BAR_CHART "}\n";
print BAR_CHART "var offsetX, offsetY;\n";
print BAR_CHART "reOffset();\n";
print BAR_CHART "window.onscroll = function (e) {\n";
print BAR_CHART "  reOffset();\n";
print BAR_CHART "};\n";
print BAR_CHART "window.onresize = function (e) {\n";
print BAR_CHART "  reOffset();\n";
print BAR_CHART "};\n";
print BAR_CHART "xmage_canvas.addEventListener(\"mousemove\", handleMouseMove, false);\n";
print BAR_CHART "var oldmouseX;\n";
print BAR_CHART "var oldY;\n";
print BAR_CHART "function handleMouseMove(e) {\n";
print BAR_CHART "    e.preventDefault();\n";
print BAR_CHART "    e.stopPropagation();\n";
print BAR_CHART "    mouseX = parseInt(e.clientX - offsetX);\n";
print BAR_CHART "    mouseY = parseInt(e.clientY - offsetY);\n";
print BAR_CHART "    ctx.clearRect(0, 0, cw, ch);\n";
print BAR_CHART "    var bar = myBarchart.getBar (mouseX, mouseY);\n";
print BAR_CHART "    ctx.fillText(\"YYYYMMDDhh chosen=\" + bar, 50, 50);\n";
print BAR_CHART "    xmage_ctx.clearRect(0, 0, 55, 55);\n";
print BAR_CHART "    var barVal = myBarchart.getBarValue (mouseX, mouseY);\n";
print BAR_CHART "    drawSquare (xmage_ctx, oldmouseX, oldY, 10, \"white\", null, null); \n";
print BAR_CHART "    drawSquare (xmage_ctx, mouseX, xmage_canvas.height - 50 - myBarchart.multiplier *barVal[1], 5, \"darkorange\", null, null); \n";
print BAR_CHART "    oldmouseX = mouseX;\n";
print BAR_CHART "    oldY = xmage_canvas.height - 50 - myBarchart.multiplier *barVal[1];\n";
print BAR_CHART "    myBarchart.draw ();\n";
print BAR_CHART "}\n";
print BAR_CHART "</script>\n";
print BAR_CHART "<a href=\"https://xmage.au/cgibin/xmage_stats.pl\">Refresh here</a>\n";
print BAR_CHART "</body>\n";
print BAR_CHART "</html>\n";


close BAR_CHART;


print "Content-type: text/html; charset=iso-8859-1\n\n";
print "View Xmage stats here:<a href=\"https://xmage.au/xmage_stats.html\">Xmage Statistics</a><br>\n";
print "Lines read: $lines_read\n";
print "Found yyyymmddhh: $found_yyyymmddhh\n";
