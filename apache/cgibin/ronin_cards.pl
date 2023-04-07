#!D:\StrawberryPerl\perl\bin\perl.exe
# -T

use strict;
use warnings;

print "Content-type: text/html; charset=iso-8859-1\n\n";
print "Ronin Games queries<br>\n";

# Read all cards
my %all_cards;
my %all_cards_have;
my %all_cards_card_type;
my %all_cards_date;
my %all_cards_place;
my %all_cards_font;

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
my %already_bought_i_cards;
my %already_bought_l_cards;
my %already_bought_p_cards;
my %already_bought_s_cards;


sub read_all_cards
{
    my $CURRENT_FILE = "D:/D_Downloads/apache_lounge/Apache24/cgibin/cards_list.txt";
    open ALL, $CURRENT_FILE; 

    #"Shorikai, Genesis Engine",already,c,20230218,ronin

    while (<ALL>)
    {
        chomp $_;
        my $line = $_;
        if ($line =~ m/^([^;]+?);already;(.);/)
        {
            my $card = $1;
            my $card_type = $2;

            if (lc($card_type) eq "a") { $already_bought_a_cards {$card} = 1; }
            if (lc($card_type) eq "c") { $already_bought_c_cards {$card} = 1; }
            if (lc($card_type) eq "e") { $already_bought_e_cards {$card} = 1; }
            if (lc($card_type) eq "i") { $already_bought_i_cards {$card} = 1; }
            if (lc($card_type) eq "l") { $already_bought_l_cards {$card} = 1; }
            if (lc($card_type) eq "p") { $already_bought_p_cards {$card} = 1; }
            if (lc($card_type) eq "s") { $already_bought_s_cards {$card} = 1; }
        }
        
        if ($line =~ m/^([^;]+?);want;(.);/)
        {
            my $card = $1;
            my $card_type = $2;

            if (lc($card_type) eq "a") { $a_cards {$card} = 1; }
            if (lc($card_type) eq "c") { $c_cards {$card} = 1; }
            if (lc($card_type) eq "e") { $e_cards {$card} = 1; }
            if (lc($card_type) eq "i") { $i_cards {$card} = 1; }
            if (lc($card_type) eq "l") { $l_cards {$card} = 1; }
            if (lc($card_type) eq "p") { $p_cards {$card} = 1; }
            if (lc($card_type) eq "s") { $s_cards {$card} = 1; }
        }
    }
    close ALL;
}


my $k;
my $https_games = "https://roningames.com.au/search?type=product&options[prefix]=last&q=";

read_all_cards ();
print ("<h2>Artifact cards:</h2><br>\n");
foreach $k (sort keys (%a_cards))
{
    print ("<a href=\"$https_games$k artifact\">$k</a><br>\n");
}
print ("<h2>Creature cards:</h2><br>\n");
foreach $k (sort keys (%c_cards))
{
    print ("<a href=\"$https_games$k creature\">$k</a><br>\n");
}
print ("<h2>Enchantment cards:</h2><br>\n");
foreach $k (sort keys (%e_cards))
{
    print ("<a href=\"$https_games$k enchantment\">$k</a><br>\n");
}
print ("<h2>Instant cards:</h2><br>\n");
foreach $k (sort keys (%i_cards))
{
    print ("<a href=\"$https_games$k instant\">$k</a><br>\n");
}
print ("<h2>Land cards:</h2><br>\n");
foreach $k (sort keys (%l_cards))
{
    print ("<a href=\"$https_games$k land\">$k</a><br>\n");
}
print ("<h2>Sorcery cards:</h2><br>\n");
foreach $k (sort keys (%s_cards))
{
    print ("<a href=\"$https_games$k sorcery\">$k</a><br>\n");
}

print ("<h2>Planeswalker cards:</h2><br>\n");
foreach $k (sort keys (%p_cards))
{
    print ("<a href=\"$https_games$k planeswalker\">$k</a><br>\n");
}

print ("<h4><br><br><font color=grey>&nbsp;&nbsp;Already bought: Artifact cards:</h4><br>\n");
foreach $k (sort keys (%already_bought_a_cards))
{
    print ("&nbsp;&nbsp;<a href=\"$https_games$k artifact\"><font size=-2>$k</font></a><br>\n");
}
print ("<h4>&nbsp;&nbsp;Already bought Creature cards:</h4><br>\n");
foreach $k (sort keys (%already_bought_c_cards))
{
    print ("&nbsp;&nbsp;<a href=\"$https_games$k creature\"><font size=-2>$k</font></a><br>\n");
}
print ("<h4>&nbsp;&nbsp;Already bought Enchantment cards:</h4><br>\n");
foreach $k (sort keys (%already_bought_e_cards))
{
    print ("&nbsp;&nbsp;<a href=\"$https_games$k enchantment\"><font size=-2>$k</font></a><br>\n");
}
print ("<h4>&nbsp;&nbsp;Already bought Instant cards:</h4><br>\n");
foreach $k (sort keys (%already_bought_i_cards))
{
    print ("&nbsp;&nbsp;<a href=\"$https_games$k instant\"><font size=-2>$k</font></a><br>\n");
}
print ("<h4>&nbsp;&nbsp;Already bought Land cards:</h4><br>\n");
foreach $k (sort keys (%already_bought_l_cards))
{
    print ("&nbsp;&nbsp;<a href=\"$https_games$k land\"><font size=-2>$k</font></a><br>\n");
}
print ("<h4>&nbsp;&nbsp;Already bought Sorcery cards:</h4><br>\n");
foreach $k (sort keys (%already_bought_s_cards))
{
    print ("&nbsp;&nbsp;<a href=\"$https_games$k sorcery\"><font size=-2>$k</font></a><br>\n");
}

print ("<h4>&nbsp;&nbsp;Already bought Planeswalker cards:</h4><br>\n");
foreach $k (sort keys (%already_bought_p_cards))
{
    print ("&nbsp;&nbsp;<a href=\"$https_games$k planeswalker\"><font size=-2>$k</font></a><br>\n");
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
print ("<h2><a href=\"https://www.mtggoldfish.com/deck_searches/create?utf8=%E2%9C%93&deck_search%5Bname%5D=&deck_search%5Bformat%5D=free_form&deck_search%5Btypes%5D%5B%5D=&deck_search%5Btypes%5D%5B%5D=tournament&deck_search%5Btypes%5D%5B%5D=budget&deck_search%5Btypes%5D%5B%5D=user&deck_search%5Bplayer%5D=spjspj&deck_search%5Bdate_range%5D=12%2F01%2F2017+-+11%2F08%2F2055&deck_search%5Bdeck_search_card_filters_attributes%5D%5B0%5D%5Bcard%5D=&deck_search%5Bdeck_search_card_filters_attributes%5D%5B0%5D%5Bquantity%5D=1&deck_search%5Bdeck_search_card_filters_attributes%5D%5B0%5D%5Btype%5D=maindeck&deck_search%5Bdeck_search_card_filters_attributes%5D%5B1%5D%5Bcard%5D=&deck_search%5Bdeck_search_card_filters_attributes%5D%5B1%5D%5Bquantity%5D=1&deck_search%5Bdeck_search_card_filters_attributes%5D%5B1%5D%5Btype%5D=maindeck&counter=2&commit=Search\">Search my EDH decks</a><br></h2>");
print ("<br><br>&nbsp;&nbsp;<a href=\"https://rainymood.com/audio1112/0.mp3\">Rainy Mood</a><br>\n");
