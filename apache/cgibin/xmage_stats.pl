#!D:\StrawberryPerl\perl\bin\perl.exe
# -T

use strict;
use warnings;

open BAR_CHART, "> D:\\D_Downloads\\apache_lounge\\Apache24\\htdocs\\xmage_stats.html";
print BAR_CHART "<!DOCTYPE html>\n";
print BAR_CHART "<html lang=\"en\" >\n";
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
print BAR_CHART "<canvas id=\"canvas\" style=\"background: white;\"></canvas>\n";
print BAR_CHART "<legend for=\"canvas\"></legend>\n";
print BAR_CHART "<script id=\"rendered-js\" >\n";
print BAR_CHART "var canvas = document.getElementById (\"canvas\");\n";
print BAR_CHART "canvas.width = 500;\n";
print BAR_CHART "canvas.height = 500;\n";
print BAR_CHART "var ctx = canvas.getContext (\"2d\");\n";
print BAR_CHART "function drawLine (ctx, startX, startY, endX, endY, color) {\n";
print BAR_CHART "    ctx.save ();\n";
print BAR_CHART "    ctx.strokeStyle = color;\n";
print BAR_CHART "    ctx.beginPath ();\n";
print BAR_CHART "    ctx.moveTo (startX, startY);\n";
print BAR_CHART "    ctx.lineTo (endX, endY);\n";
print BAR_CHART "    ctx.stroke ();\n";
print BAR_CHART "    ctx.restore ();\n";
print BAR_CHART "}\n";
print BAR_CHART "function drawBar (ctx, upperLeftCornerX, upperLeftCornerY, width, height, color) {\n";
print BAR_CHART "    ctx.save ();\n";
print BAR_CHART "    ctx.fillStyle = color;\n";
print BAR_CHART "    ctx.fillRect (upperLeftCornerX, upperLeftCornerY, width, height);\n";
print BAR_CHART "    ctx.restore ();\n";
print BAR_CHART "}\n";
print BAR_CHART "class BarChart {\n";
print BAR_CHART "    constructor (options) {\n";
print BAR_CHART "        this.options = options;\n";
print BAR_CHART "        this.canvas = options.canvas;\n";
print BAR_CHART "        this.ctx = this.canvas.getContext (\"2d\");\n";
print BAR_CHART "        this.titleOptions = options.titleOptions;\n";
print BAR_CHART "        this.maxValue = Math.max (...Object.values (this.options.data));\n";
print BAR_CHART "    }\n";
print BAR_CHART "    drawGridLines () {\n";
print BAR_CHART "        var canvasActualHeight = this.canvas.height - this.options.padding * 2;\n";
print BAR_CHART "        var canvasActualWidth = this.canvas.width - this.options.padding * 2;\n";
print BAR_CHART "        var gridValue = 0;\n";
print BAR_CHART "        while (gridValue <= this.maxValue) {\n";
print BAR_CHART "            var gridY = canvasActualHeight * (1 - gridValue / this.maxValue) + this.options.padding;\n";
print BAR_CHART "            drawLine (this.ctx, 0, gridY, this.canvas.width, gridY, this.options.gridColor);\n";
print BAR_CHART "            drawLine (this.ctx, 15, this.options.padding / 2, 15, gridY + this.options.padding / 2, this.options.gridColor);\n";
print BAR_CHART "            // Writing grid markers\n";
print BAR_CHART "            this.ctx.save ();\n";
print BAR_CHART "            this.ctx.fillStyle = this.options.gridColor;\n";
print BAR_CHART "            this.ctx.textBaseline = \"bottom\";\n";
print BAR_CHART "            this.ctx.font = \"bold 10px Arial\";\n";
print BAR_CHART "            this.ctx.fillText (gridValue, 0, gridY - 2);\n";
print BAR_CHART "            this.ctx.restore ();\n";
print BAR_CHART "            gridValue += this.options.gridStep;\n";
print BAR_CHART "        }\n";
print BAR_CHART "    }\n";
print BAR_CHART "    getBar = function(x, y) {\n";
print BAR_CHART "        var canvasActualHeight = this.canvas.height - this.options.padding * 2;\n";
print BAR_CHART "        var canvasActualWidth = this.canvas.width - this.options.padding * 2;\n";
print BAR_CHART "        var barIndex = 0;\n";
print BAR_CHART "        var numberOfBars = Object.keys (this.options.data).length;\n";
print BAR_CHART "        var barSize = canvasActualWidth / numberOfBars;\n";
print BAR_CHART "        var values = Object.values (this.options.data);\n";
print BAR_CHART "        \n";
print BAR_CHART "        for (let ctg of Object.keys (this.options.data)) {\n";
print BAR_CHART "            if (x > this.options.padding + barIndex * barSize && x < this.options.padding + (barIndex+1) * barSize)\n";
print BAR_CHART "            {\n";
print BAR_CHART "                return ctg;\n";
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
print BAR_CHART "        var barSize = canvasActualWidth / numberOfBars;\n";
print BAR_CHART "        var values = Object.values (this.options.data);\n";
print BAR_CHART "        for (let val of values) {\n";
print BAR_CHART "            var barHeight = Math.round (canvasActualHeight * val / this.maxValue);\n";
print BAR_CHART "            console.log (barHeight);\n";
print BAR_CHART "            drawBar (\n";
print BAR_CHART "                    this.ctx,\n";
print BAR_CHART "                    this.options.padding + barIndex * barSize,\n";
print BAR_CHART "                    this.canvas.height - barHeight - this.options.padding,\n";
print BAR_CHART "                    barSize,\n";
print BAR_CHART "                    barHeight,\n";
print BAR_CHART "                    this.options.colors[barIndex % this.options.colors.length]);\n";
print BAR_CHART "            barIndex++;\n";
print BAR_CHART "        }\n";
print BAR_CHART "    }\n";
print BAR_CHART "    drawLabel () {\n";
print BAR_CHART "        this.ctx.save ();\n";
print BAR_CHART "        this.ctx.textBaseline = \"bottom\";\n";
print BAR_CHART "        this.ctx.textAlign = this.titleOptions.align;\n";
print BAR_CHART "        this.ctx.fillStyle = this.titleOptions.fill;\n";
print BAR_CHART "        this.ctx.font = \`\${this.titleOptions.font.weight} \${this.titleOptions.font.size} \${this.titleOptions.font.family}\`;\n";
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
print BAR_CHART "    drawLegend () {\n";
print BAR_CHART "        let pIndex = 0;\n";
print BAR_CHART "        let legend = document.querySelector (\"legend[for='canvas']\");\n";
print BAR_CHART "        let ul = document.createElement (\"ul\");\n";
print BAR_CHART "        legend.append (ul);\n";
print BAR_CHART "        for (let ctg of Object.keys (this.options.data)) {\n";
print BAR_CHART "            let li = document.createElement (\"li\");\n";
print BAR_CHART "            li.style.listStyle = \"none\";\n";
print BAR_CHART "            li.style.borderLeft =\n";
print BAR_CHART "                \"20px solid \" + this.options.colors[pIndex % this.options.colors.length];\n";
print BAR_CHART "            li.style.padding = \"5px\";\n";
print BAR_CHART "            li.textContent = ctg;\n";
print BAR_CHART "            ul.append (li);\n";
print BAR_CHART "            pIndex++;\n";
print BAR_CHART "        }\n";
print BAR_CHART "    }\n";
print BAR_CHART "    draw () {\n";
print BAR_CHART "        this.drawGridLines ();\n";
print BAR_CHART "        this.drawBars ();\n";
print BAR_CHART "        this.drawLabel ();\n";
print BAR_CHART "        //this.drawLegend ();\n";
print BAR_CHART "    }\n";
print BAR_CHART "}\n";
print BAR_CHART "var myBarchart = new BarChart (\n";
print BAR_CHART "    {\n";
print BAR_CHART "        canvas: canvas,\n";
print BAR_CHART "        seriesName: \"Xmage Users\",\n";
print BAR_CHART "        padding: 50,\n";
print BAR_CHART "        gridStep: 10,\n";
print BAR_CHART "        gridColor: \"black\",\n";

# Read from xmagelog of data gathering thingo..
open PROC, "find /I \"People Counter\" c:/xmage_clean/mage/Mage.Client/mageclient.log |";
my %yyyymmddhh;
while (<PROC>)
{
    chomp;
    my $line = $_;
    # Example line: ERROR 2023-03-05 20:07:36,928 Banned (People counter = 68:beta.xmage.today,70
    
    if ($line =~ m/ERROR (\d\d\d\d).(\d\d).(\d\d) (\d\d).*People counter = (\d+):beta/)
    {
         my $ymdh = "$1$2$3$4";
         my $people_count = $5;
         if (!defined ($yyyymmddhh {$ymdh}))
         {
             $yyyymmddhh {$ymdh} = $people_count;
         }
         if ($people_count > $yyyymmddhh {$ymdh})
         {
             $yyyymmddhh {$ymdh} = $people_count;
         }
    }
}

# Print data line
print BAR_CHART "        data: {";
my $key;
foreach $key (sort keys (%yyyymmddhh))
{
    print BAR_CHART "\"$key\": $yyyymmddhh{$key},";
}
print BAR_CHART "\"DONE\": 0 },\n";

# Print colors line
print BAR_CHART "        colors: [";

my @chars = ('0'..'9', 'A'..'F');
my $len = 8;
my $string;

foreach $key (sort keys (%yyyymmddhh))
{
    $key =~ s/^..//;
    $len = 6;
    $string = "";
    while ($len--)
    {
         $string .= $chars[rand @chars] 
    }

    print BAR_CHART "\"\#$string\",";
}
print BAR_CHART "],\n";

# Example lines:
#print BAR_CHART "        data: {\"2023030416\": 98,\"2023030417\": 99,\"2023030418\": 89,\"2023030419\": 78,\"2023030420\": 70,\"2023030421\": 75,\"2023030423\": 66,\"2023030500\": 81,\"2023030501\": 95,\"2023030513\": 91,\"2023030514\": 89,\"2023030515\": 97,\"2023030516\": 100,\"2023030517\": 90,\"2023030518\": 85,\"2023030519\": 85,\"2023030520\": 80,\"2023030521\": 80,\"2023030522\": 77,\"DONE\": 0 },\n";
#print BAR_CHART "        colors: [\"#53FA00\",\"#EAE39D\",\"#905E6E\",\"#1B879E\",\"#CDA433\",\"#F39109\",\"#C81079\",\"#BBB088\",\"#285A6C\",\"#F178B7\",\"#E37170\",\"#07AB31\",\"#2B21C0\",\"#9A200D\",\"#F4458B\",\"#D38F3D\",\"#3AF760\",\"#95DB9D\",\"#85BF83\",\"#000000\"],\n";
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
print BAR_CHART "var xmage_canvas = document.getElementById(\"canvas\");\n";
print BAR_CHART "var ctx = canvas_info.getContext(\"2d\");\n";
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
print BAR_CHART "function handleMouseMove(e) {\n";
print BAR_CHART "    e.preventDefault();\n";
print BAR_CHART "    e.stopPropagation();\n";
print BAR_CHART "    mouseX = parseInt(e.clientX - offsetX);\n";
print BAR_CHART "    mouseY = parseInt(e.clientY - offsetY);\n";
print BAR_CHART "    ctx.clearRect(0, 0, cw, ch);\n";
print BAR_CHART "    var bar = myBarchart.getBar (mouseX, mouseY);\n";
print BAR_CHART "    ctx.fillText(\"YYYYMMDDhh chosen=\" + bar, 50, 50);\n";
print BAR_CHART "}\n";
print BAR_CHART "</script>\n";
print BAR_CHART "</body>\n";
print BAR_CHART "</html>\n";
print BAR_CHART "\n";
close BAR_CHART;


print "Content-type: text/html; charset=iso-8859-1\n\n";
print "View Xmage stats here:<a href=\"https://xmage.au/xmage_stats.html\">Xmage Statistics</a><br>\n";

