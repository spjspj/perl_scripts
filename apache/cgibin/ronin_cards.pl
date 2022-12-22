#!D:\StrawberryPerl\perl\bin\perl.exe
# -T

use strict;
use warnings;

print "Content-type: text/html; charset=iso-8859-1\n\n";
print "Ronin Games queries<br>\n";

#https://roningames.com.au/search?type=product&options[prefix]=last&q=Druid+of+Purification
my %a_cards;
my %c_cards;
my %e_cards;
my %i_cards;
my %l_cards;
my %p_cards;
my %s_cards;

my %already_bought_a_cards;
my %already_bought_c_cards;
my %already_bought_e_cards;
my %already_bought_l_cards;
my %already_bought_p_cards;
my %already_bought_s_cards;

$already_bought_a_cards {"Bootleggers' Stash"} = 1;
$already_bought_a_cards {"Crown of Empires"} = 1; # 20220501
$already_bought_a_cards {"Geth's Grimoire"} = 1;
$already_bought_a_cards {"Luxior, Giada's Gift"} = 1;
$already_bought_a_cards {"Thrown of Empires"} = 1; # 20220501
$already_bought_c_cards {"Arcum Dagsson"} = 1; # 20220501
$already_bought_c_cards {"Bramble Sovereign"} = 1; # 20221203
$already_bought_c_cards {"Druid of Purification"} = 1;
$already_bought_c_cards {"Empress Galina"} = 1;
$already_bought_c_cards {"Giada, Font of Hope"} = 1; # 20220501
$already_bought_c_cards {"Horobi, Death's Wail"} = 1;
$already_bought_c_cards {"Yorion, Sky Nomad"} = 1;
$already_bought_l_cards {"Deserted Beach"} = 1;
$already_bought_l_cards {"The World Tree "} = 1;
$already_bought_s_cards {"Head Games"} = 1;


my %for_blue_edh;
$for_blue_edh {"Arcane Lighthouse -- Land"} = 1;
$for_blue_edh {"Buried Ruin -- Land ** "} = 1;
$for_blue_edh {"Capsize -- Instant ** "} = 1;
$for_blue_edh {"Fierce Guardianship -- Instant"} = 1;
$for_blue_edh {"Force of Will -- Instant"} = 1;
$for_blue_edh {"Homeward Path -- Land"} = 1;
$for_blue_edh {"Jace Beleren -- Planeswalker"} = 1;
$for_blue_edh {"Mana Web -- Artifact"} = 1;
$for_blue_edh {"Mystic Sanctuary -- Land"} = 1;
$for_blue_edh {"Nevinyrral's Disk -- Artifact"} = 1;
$for_blue_edh {"Propaganda -- Enchantment"} = 1;
$for_blue_edh {"Sapphire Medallion -- Artifact"} = 1;
$for_blue_edh {"Seat of the Synod -- Land"} = 1;
$for_blue_edh {"Solemn Simulacrum -- Creature **"} = 1;
$for_blue_edh {"Tormod's Crypt -- Artifact **"} = 1;


$a_cards {"Retrofitter Foundry"} = 1;
$a_cards {"Scepter of Empires"} = 1;
$a_cards {"Storage Matrix"} = 1;
$c_cards {"Disciple of the Vault"} = 1;
$c_cards {"Elvish Reclaimer"} = 1;
$c_cards {"Esper Sentinel"} = 1;
$c_cards {"Imperial Recruiter"} = 1;
$c_cards {"Kodama of the West Tree"} = 1;
$c_cards {"Korvold, Fae-Cursed King"} = 1;
$c_cards {"Luminous Broodmoth"} = 1;
$c_cards {"Ob Nixilis, the Fallen"} = 1;
$c_cards {"Old Gnawbone"} = 1;
$c_cards {"Painter's Servant"} = 1;
$c_cards {"Shorikai, Genesis Engine"} = 1;
$c_cards {"Terror of the Peaks"} = 1;
$c_cards {"Thrasios, Triton Hero"} = 1;
$c_cards {"Vito, Thorn of the Dusk Rose"} = 1;
$e_cards {"Necropotence"} = 1;
$e_cards {"Powerleech"} = 1;
$e_cards {"Reality Twist"} = 1;
$e_cards {"Roots of Life"} = 1;
$e_cards {"Stimulus Package"} = 1;
$e_cards {"Stranglehold"} = 1;
$e_cards {"Tranquil Grove"} = 1;
$e_cards {"War Tax"} = 1;
$i_cards {"Lae'Zel's Acrobatics"} = 1;
$l_cards {"Bountiful Promenade"} = 1;
$l_cards {"Luxury Suite"} = 1;
$l_cards {"Morphic Pool"} = 1;
$l_cards {"Overgrown Farmland"} = 1;
$l_cards {"Rejuvenating Springs"} = 1;
$l_cards {"Rockfall Vale"} = 1;
$l_cards {"Sea of Clouds"} = 1;
$l_cards {"Shipwreck Marsh"} = 1;
$l_cards {"Spectator Seating"} = 1;
$l_cards {"Training Center"} = 1;
$l_cards {"Vault of Champions"} = 1;
$p_cards {"No Planeswalker"} = 1;
$s_cards {"Farewell"} = 1;
$s_cards {"Reshape the Earth"} = 1;

my $k;
print ("<h2>For Blue EDH deck..:</h2><br>\n");
foreach $k (sort keys (%for_blue_edh))
{
    print ("<a href=\"https://roningames.com.au/search?type=product&options[prefix]=last&q=$k\">$k</a><br>\n");
}
print ("<h2>Artifact cards:</h2><br>\n");
foreach $k (sort keys (%a_cards))
{
    print ("<a href=\"https://roningames.com.au/search?type=product&options[prefix]=last&q=$k artifact\">$k</a><br>\n");
}
print ("<h2>Creature cards:</h2><br>\n");
foreach $k (sort keys (%c_cards))
{
    print ("<a href=\"https://roningames.com.au/search?type=product&options[prefix]=last&q=$k creature\">$k</a><br>\n");
}
print ("<h2>Enchantment cards:</h2><br>\n");
foreach $k (sort keys (%e_cards))
{
    print ("<a href=\"https://roningames.com.au/search?type=product&options[prefix]=last&q=$k enchantment\">$k</a><br>\n");
}
print ("<h2>Instant cards:</h2><br>\n");
foreach $k (sort keys (%i_cards))
{
    print ("<a href=\"https://roningames.com.au/search?type=product&options[prefix]=last&q=$k instant\">$k</a><br>\n");
}
print ("<h2>Land cards:</h2><br>\n");
foreach $k (sort keys (%l_cards))
{
    print ("<a href=\"https://roningames.com.au/search?type=product&options[prefix]=last&q=$k land\">$k</a><br>\n");
}
print ("<h2>Sorcery cards:</h2><br>\n");
foreach $k (sort keys (%s_cards))
{
    print ("<a href=\"https://roningames.com.au/search?type=product&options[prefix]=last&q=$k sorcery\">$k</a><br>\n");
}

print ("<h2>Planeswalker cards:</h2><br>\n");
foreach $k (sort keys (%p_cards))
{
    print ("<a href=\"https://roningames.com.au/search?type=product&options[prefix]=last&q=$k planeswalker\">$k</a><br>\n");
}

print ("<h4><font color=grey>&nbsp;&nbsp;Already bought: Artifact cards:</h4><br>\n");
foreach $k (sort keys (%already_bought_a_cards))
{
    print ("&nbsp;&nbsp;<a href=\"https://roningames.com.au/search?type=product&options[prefix]=last&q=$k artifact\">$k</a><br>\n");
}
print ("<h4>&nbsp;&nbsp;Already bought Creature cards:</h4><br>\n");
foreach $k (sort keys (%already_bought_c_cards))
{
    print ("&nbsp;&nbsp;<a href=\"https://roningames.com.au/search?type=product&options[prefix]=last&q=$k creature\">$k</a><br>\n");
}
print ("<h4>&nbsp;&nbsp;Already bought Enchantment cards:</h4><br>\n");
foreach $k (sort keys (%already_bought_e_cards))
{
    print ("&nbsp;&nbsp;<a href=\"https://roningames.com.au/search?type=product&options[prefix]=last&q=$k enchantment\">$k</a><br>\n");
}
print ("<h4>&nbsp;&nbsp;Already bought Land cards:</h4><br>\n");
foreach $k (sort keys (%already_bought_l_cards))
{
    print ("&nbsp;&nbsp;<a href=\"https://roningames.com.au/search?type=product&options[prefix]=last&q=$k land\">$k</a><br>\n");
}
print ("<h4>&nbsp;&nbsp;Already bought Sorcery cards:</h4><br>\n");
foreach $k (sort keys (%already_bought_s_cards))
{
    print ("&nbsp;&nbsp;<a href=\"https://roningames.com.au/search?type=product&options[prefix]=last&q=$k sorcery\">$k</a><br>\n");
}

print ("<h4>&nbsp;&nbsp;Already bought Planeswalker cards:</h4><br>\n");
foreach $k (sort keys (%already_bought_p_cards))
{
    print ("&nbsp;&nbsp;<a href=\"https://roningames.com.au/search?type=product&options[prefix]=last&q=$k planeswalker\">$k</a><br>\n");
}
print ("</font>\n");


print ("<h2>Boxes:</h2><br>\n");
print ("<a href=\"https://www.mtggoldfish.com/price/Commander+Legends/Commander+Legends+Draft+Booster+Box-sealed#paper\">Commander Legends Commander</a><br>");
print ("<a href=\"https://www.mtggoldfish.com/price/Iconic+Masters/Iconic+Masters+Booster+Box-sealed#paper\">Iconic Masters Iconic</a><br>");
print ("<a href=\"https://www.mtggoldfish.com/price/Modern+Masters+2017+Edition/Modern+Masters+2017+Booster+Box-sealed#paper\">Modern Masters 2017</a><br>");
print ("<a href=\"https://www.mtggoldfish.com/price/Eternal+Masters/Eternal+Masters+Booster+Box-sealed#paper\">Eternal Masters Eternal</a><br>");
print ("<a href=\"https://www.mtggoldfish.com/price/Time+Spiral+Remastered/Time+Spiral+Remastered+Draft+Booster+Box-sealed#paper\">Time Spiral Remastered</a><br>");
print ("<a href=\"https://www.mtggoldfish.com/price/Dominaria/Dominaria+Booster+Box-sealed#paper\">Dominaria Dominaria Booster</a><br>");
print ("<a href=\"https://www.mtggoldfish.com/price/Masters+25/Masters+25+Booster+Box-sealed#paper\">Masters 25 Masters</a><br>");
print ("<a href=\"https://www.mtggoldfish.com/price/Throne+of+Eldraine/Throne+of+Eldraine+Draft+Booster+Box-sealed#paper\">Throne of Eldraine</a><br>");
print ("<a href=\"https://www.mtggoldfish.com/price/Mystery+Booster/Mystery+Booster+Retail+Edition+Booster+Box-sealed#paper\">Mystery Booster Mystery</a><br>");
print ("<a href=\"https://www.mtggoldfish.com/price/Modern+Horizons/Modern+Horizons+Booster+Box-sealed#paper\">Modern Horizons</a><br>");
print ("<a href=\"https://www.mtggoldfish.com/price/Modern+Horizons+2/Modern+Horizons+2+Set+Booster+Box-sealed#paper\">Modern Horizons 2 Set</a><br>");
print ("<a href=\"https://www.mtggoldfish.com/price/Masters+25/Masters+25+Booster+Box-sealed#paper\">Masters 25 Masters</a><br>");
print ("<a href=\"https://www.mtggoldfish.com/prices/paper/boosters\">Booster boxes</a><br>");
print ("<a href=\"https://www.mtggoldfish.com/price/Jumpstart/Jumpstart+Booster+Box-sealed#paper\">Jumpstart Jumpstart Booster</a><br>");
print ("<a href=\"https://i.imgur.com/wZIV4Al.png\">Boxes1</a><br>");
print ("<a href=\"https://imgur.com/a/9uj84ka\">Boxes2</a><br>");
print ("<a href=\"https://imgur.com/a/Bdt159R\">EDH Decklists</a><br>");
print ("<a href=\"https://www.mtggoldfish.com/deck/3985938#paper\">My Wanted list..</a><br>");
print ("<br><br>&nbsp;&nbsp;<a href=\"https://rainymood.com/audio1112/0.mp3\">Rainy Mood</a><br>\n");
