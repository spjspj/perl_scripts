#!/usr/bin/perl
##
#   File : quest.pl
#   Date : 21/Sept/2021
#   Author : spjspj
#   Purpose : Implement Big box edition of Quest
#   Purpose : Requires having an Apache service setup (see conf file)
#             Not providing the images for the game, but you will need the following ones:
##

use strict;
use LWP::Simple;
use Socket;
use File::Copy;
use List::Util qw(shuffle);
use Time::HiRes;
use URI::Escape;
use POSIX qw(strftime);

$| = 1;

# Player roles
my $APPRENTICE = "apprentice"; my $APPRENTICE_IMAGE = "<img height=250 src=\"q_images/apprentice.jpg\"></img>";
my $ARCHDUKE = "archduke"; my $ARCHDUKE_IMAGE = "<img height=250 src=\"q_images/archduke.jpg\"></img>";
my $ARTHUR = "arthur"; my $ARTHUR_IMAGE = "<img height=250 src=\"q_images/arthur.jpg\"></img>";
my $BLIND_HUNTER = "blind_hunter"; my $BLIND_HUNTER_IMAGE = "<img height=250 src=\"q_images/blind_hunter.jpg\"></img>";
my $BRUTE = "brute"; my $BRUTE_IMAGE = "<img height=250 src=\"q_images/brute.jpg\"></img>";
my $CHANGELING = "changeling"; my $CHANGELING_IMAGE = "<img height=250 src=\"q_images/changeling.jpg\"></img>";
my $CLERIC = "cleric"; my $CLERIC_IMAGE = "<img height=250 src=\"q_images/cleric.jpg\"></img>";
my $DUKE = "duke"; my $DUKE_IMAGE = "<img height=250 src=\"q_images/duke.jpg\"></img>";
my $GENERIC_BAD = "generic_bad"; my $GENERIC_BAD_IMAGE = "<img height=250 src=\"q_images/generic_bad.jpg\"></img>";
my $GENERIC_GOOD = "generic_good"; my $GENERIC_GOOD_IMAGE = "<img height=250 src=\"q_images/generic_good.jpg\"></img>";
my $LUNATIC = "lunatic"; my $LUNATIC_IMAGE = "<img height=250 src=\"q_images/lunatic.jpg\"></img>";
my $MORGAN_LE_FAY = "morgan_le_fay"; my $MORGANA_LE_FAY_IMAGE = "<img height=250 src=\"q_images/morgan_le_fay.jpg\"></img>";
my $MUTINEER = "mutineer"; my $MUTINEER_IMAGE = "<img height=250 src=\"q_images/mutineer.jpg\"></img>";
my $RELUCTANT_LEADER = "reluctant_leader"; my $RELUCTANT_LEADER_IMAGE = "<img height=250 src=\"q_images/reluctant_leader.jpg\"></img>";
my $REVEALER = "revealer"; my $REVEALER_IMAGE = "<img height=250 src=\"q_images/revealer.jpg\"></img>";
my $SABOTEUR = "saboteur"; my $SABOTEUR_IMAGE = "<img height=250 src=\"q_images/saboteur.jpg\"></img>";
my $SCION = "scion"; my $SCION_IMAGE = "<img height=250 src=\"q_images/scion.jpg\"></img>";
my $SENTINEL = "sentinel"; my $SENTINEL_IMAGE = "<img height=250 src=\"q_images/sentinel.jpg\"></img>";
my $TRICKSTER = "trickster"; my $TRICKSTER_IMAGE = "<img height=250 src=\"q_images/trickster.jpg\"></img>";
my $TROUBLEMAKER = "troublemaker"; my $TROUBLEMAKER_IMAGE = "<img height=250 src=\"q_images/troublemaker.jpg\"></img>";
my $YOUTH = "youth"; my $YOUTH_IMAGE = "<img height=250 src=\"q_images/youth.jpg\"></img>";

# Quest player images
my %player_images;
$player_images {$APPRENTICE} = $APPRENTICE_IMAGE;
$player_images {$ARCHDUKE} = $ARCHDUKE_IMAGE;
$player_images {$ARTHUR} = $ARTHUR_IMAGE;
$player_images {$BLIND_HUNTER} = $BLIND_HUNTER_IMAGE;
$player_images {$BRUTE} = $BRUTE_IMAGE;
$player_images {$CHANGELING} = $CHANGELING_IMAGE;
$player_images {$CLERIC} = $CLERIC_IMAGE;
$player_images {$DUKE} = $DUKE_IMAGE;
$player_images {$GENERIC_BAD} = $GENERIC_BAD_IMAGE;
$player_images {$GENERIC_GOOD} = $GENERIC_GOOD_IMAGE;
$player_images {$LUNATIC} = $LUNATIC_IMAGE;
$player_images {$MORGAN_LE_FAY} = $MORGANA_LE_FAY_IMAGE;
$player_images {$MUTINEER} = $MUTINEER_IMAGE;
$player_images {$RELUCTANT_LEADER} = $RELUCTANT_LEADER_IMAGE;
$player_images {$REVEALER} = $REVEALER_IMAGE;
$player_images {$SABOTEUR} = $SABOTEUR_IMAGE;
$player_images {$SCION} = $SCION_IMAGE;
$player_images {$SENTINEL} = $SENTINEL_IMAGE;
$player_images {$TRICKSTER} = $TRICKSTER_IMAGE;
$player_images {$TROUBLEMAKER} = $TROUBLEMAKER_IMAGE;
$player_images {$YOUTH} = $YOUTH_IMAGE;

# Non player images
my $BOARD_10_PLAYER = "10_player"; my $BOARD_10_PLAYER_IMAGE = "<img height=400 src=\"q_images/10_player.jpg\">$BOARD_10_PLAYER</img>";
my $BOARD_10_PLAYER2 = "10_player2"; my $BOARD_10_PLAYER2_IMAGE = "<img height=400 src=\"q_images/10_player2.jpg\">$BOARD_10_PLAYER2</img>";
my $BOARD_4_PLAYER = "4_player"; my $BOARD_4_PLAYER_IMAGE = "<img height=400 src=\"q_images/4_player.jpg\">$BOARD_4_PLAYER</img>";
my $BOARD_4_PLAYERS_SAME = "4_players_same"; my $BOARD_4_PLAYERS_SAME_IMAGE = "<img height=400 src=\"q_images/4_players_same.jpg\">$BOARD_4_PLAYERS_SAME</img>";
my $BOARD_5_PLAYER = "5_player"; my $BOARD_5_PLAYER_IMAGE = "<img height=400 src=\"q_images/5_player.jpg\">$BOARD_5_PLAYER</img>";
my $BOARD_5_PLAYERS_2 = "5_players_2"; my $BOARD_5_PLAYERS_2_IMAGE = "<img height=400 src=\"q_images/5_players_2.jpg\">$BOARD_5_PLAYERS_2</img>";
my $BOARD_6_PLAYER2 = "6_player2"; my $BOARD_6_PLAYER2_IMAGE = "<img height=400 src=\"q_images/6_player2.jpg\">$BOARD_6_PLAYER2</img>";
my $BOARD_6_PLAYERS = "6_players"; my $BOARD_6_PLAYERS_IMAGE = "<img height=400 src=\"q_images/6_players.jpg\">$BOARD_6_PLAYERS</img>";
my $BOARD_7_PLAYERS = "7_players"; my $BOARD_7_PLAYERS_IMAGE = "<img height=400 src=\"q_images/7_players.jpg\">$BOARD_7_PLAYERS</img>";
my $BOARD_7_PLAYERS_2 = "7_players_2"; my $BOARD_7_PLAYERS_2_IMAGE = "<img height=400 src=\"q_images/7_players_2.jpg\">$BOARD_7_PLAYERS_2</img>";
my $BOARD_8_PLAYER = "8_player"; my $BOARD_8_PLAYER_IMAGE = "<img height=400 src=\"q_images/8_player.jpg\">$BOARD_8_PLAYER</img>";
my $BOARD_8_PLAYER2 = "8_player2"; my $BOARD_8_PLAYER2_IMAGE = "<img height=400 src=\"q_images/8_player2.jpg\">$BOARD_8_PLAYER2</img>";
my $BOARD_9_PLAYERS = "9_players"; my $BOARD_9_PLAYERS_IMAGE = "<img height=400 src=\"q_images/9_players.jpg\">$BOARD_9_PLAYERS</img>";
my $BOARD_9_PLAYERS2 = "9_players2"; my $BOARD_9_PLAYERS2_IMAGE = "<img height=400 src=\"q_images/9_players2.jpg\">$BOARD_9_PLAYERS2</img>";
my $CARD_BACK = "card_back"; my $CARD_BACK_IMAGE = "<img height=250 src=\"q_images/card_back.jpg\"></img>";
my $CARD_BACK2 = "card_back2"; my $CARD_BACK2_IMAGE = "<img height=250 src=\"q_images/card_back2.jpg\">$CARD_BACK2</img>";
my $CROWN = "crown"; my $CROWN_IMAGE = "<img height=70 src=\"q_images/crown.jpg\"></img>";
my $EVIL = "evil"; my $EVIL_IMAGE = "<img height=250 src=\"q_images/evil.jpg\">$EVIL</img>";
my $FAIL = "fail"; my $FAIL_IMAGE = "<img height=250 src=\"q_images/fail.jpg\">$FAIL</img>";
my $GOOD = "Good"; my $GOOD_IMAGE = "<img height=250 src=\"q_images/Good.jpg\">$GOOD</img>";
my $GOOD_TOKEN = "good_token"; my $GOOD_TOKEN_IMAGE = "<img height=250 src=\"q_images/good_token.jpg\">$GOOD_TOKEN</img>";
my $SUCCESS = "success"; my $SUCCESS_IMAGE = "<img height=250 src=\"q_images/success.jpg\">$SUCCESS</img>";
my $SWORD = "sword"; my $SWORD_IMAGE = "<img height=250 src=\"q_images/sword.jpg\">$SWORD</img>";
my $MAGIC_TOKEN = "magic_token"; my $MAGIC_TOKEN_IMAGE = "<img height=250 src=\"q_images/magic_token.jpg\">$MAGIC_TOKEN</img>";

# Error :(
my $ERROR_IMAGE = $SWORD_IMAGE;

my $EXPOSED = "exposed";
my $PRESC = "prescient_vision";
my $SMALL_GAME = 3;
my $MED_GAME = 6;
my %COUNTS_OF_ROLES;
my %ROLES_ESSENTIAL;
my %exposed_cards;
my %revealed_cards;
my %revealed_cards_imgs;
my $DONT_PASS_TORCH = 0;
my $NEXT_QUEST_IS_FORCED = 0;
my $BCK = "back";

my $STATE_AWAITING_QUEST = "STATE_AWAITING_QUEST";
my $STATE_AWAITING_QUEST_RESULTS = "STATE_AWAITING_QUEST_RESULTS";
my $STATE_AWAITING_NEXT_LEADER = "STATE_AWAITING_NEXT_LEADER";
my $STATE_GOODS_LAST_CHANCE = "STATE_GOODS_LAST_CHANCE";
my $THE_ACCUSED;
my $NUMBER_QUEST_RESULTS = 0;
my $NUMBER_FAILS_NEEDED = 2;
my $STATE_OF_ROUND = $STATE_AWAITING_QUEST;
my %AWAITING_QUESTERS;
my %AWAITING_LAST_ACCUSSED;
my %VOTING_RESULTS;
my %QUEST_OUTCOMES;
my %QUEST_INFO;
my %HAS_BEEN_LEADER;

my $GAME_WON = 0;
my $reason_for_game_end = "";
my $CURRENT_QUEST_NAME = "";
my $IN_DEBUG_MODE = 0;

my $BAD_GUYS = -1;
my $GOOD_GUYS = 1;

my %rand_colors;

my $DEBUG = "";
my @player_names;
my @player_roles;
my @NEEDS_REFRESH;
my @NEEDS_ALERT;

my $QUEST_NUMBER = 1;
my $TOTAL_QUESTS = 1;
my %num_players_on_quests;
my @in_game_players;
my $START_OF_NEW_ROUND = 0;
my %BANNED_NAMES;
my %CHAT_MESSAGES;
my $ZOOM_URL_LINK = "No zoom link pasted into chat yet!";
my $ZOOM_URL_LINK_DATE;
my $ZOOM_URL_LINK_set = 0;
my $RR_URL_LINK_set = 0;
my $NUM_CHAT_MESSAGES = 0;
my %NOT_HIDDEN_INFO;

my $who_is_leader;
my $pot_who_has_torch;
my $num_players_in_game = -1;
my $NUM_EXPOSED_CARDS = 0;
my $CHANGE_OF_ROUND = 0;
my @player_ips;
my $num_players_in_lobby = 0;

# Player layouts for the table.
my $CROWN_TOKEN = "<img src=\"q_images/crown.jpg\" height=\"75\">";
my $PLAYER_LAYOUT_4 = "<table class=\"questTable\"><tbody> <tr> <td align=center><img src=\"q_images/PLAYER_ONE_IMAGE.jpg\" height=\"200\">CROWN_ONE<font size=\"+2\" color=\"darkblue\">PLAYER_ONE_NAME</font></td> <td rowspan=2><img height=600 src=\"q_images/4_player.jpg\" ></img></td> <td align=center><img src=\"q_images/PLAYER_TWO_IMAGE.jpg\" height=\"200\">CROWN_TWO <font color=\"darkgreen\">PLAYER_TWO_NAME</font></td> </tr> <tr> <td align=center><img src=\"q_images/PLAYER_THREE_IMAGE.jpg\" height=\"200\">CROWN_THREE <font color=\"darkgreen\">PLAYER_THREE_NAME</font></td> <td align=center><img src=\"q_images/PLAYER_FOUR_IMAGE.jpg\" height=\"200\">CROWN_FOUR <font color=\"darkgreen\">PLAYER_FOUR_NAME</font></td> </tr> </tbody></table>";
my $PLAYER_LAYOUT_5 = "<table class=\"questTable\"><tbody> <tr> <td align=center><img src=\"q_images/PLAYER_ONE_IMAGE.jpg\" height=\"200\">CROWN_ONE<font size=\"+2\" color=\"darkblue\">PLAYER_ONE_NAME</font></td> <td align=center><img src=\"q_images/PLAYER_TWO_IMAGE.jpg\" height=\"200\">CROWN_TWO <font color=\"darkgreen\">PLAYER_TWO_NAME</font></td> <td align=center><img src=\"q_images/PLAYER_THREE_IMAGE.jpg\" height=\"200\">CROWN_THREE <font color=\"darkgreen\">PLAYER_THREE_NAME</font></td> </tr> <tr> <td align=center><img src=\"q_images/PLAYER_FOUR_IMAGE.jpg\" height=\"200\">CROWN_FOUR <font color=\"darkgreen\">PLAYER_FOUR_NAME</font></td> <td rowspan=2><img height=600 src=\"q_images/5_player.jpg\" ></img></td> <td align=center><img src=\"q_images/PLAYER_FIVE_IMAGE.jpg\" height=\"200\">CROWN_FIVE <font color=\"darkgreen\">PLAYER_FIVE_NAME</font></td> </tr> </tbody></table>";
my $PLAYER_LAYOUT_6 = "<table class=\"questTable\"><tbody> <tr> <td align=center><img src=\"q_images/PLAYER_ONE_IMAGE.jpg\" height=\"200\">CROWN_ONE<font size=\"+2\" color=\"darkblue\">PLAYER_ONE_NAME</font></td> <td align=center><img src=\"q_images/PLAYER_TWO_IMAGE.jpg\" height=\"200\">CROWN_TWO <font color=\"darkgreen\">PLAYER_TWO_NAME</font></td> <td align=center><img src=\"q_images/PLAYER_THREE_IMAGE.jpg\" height=\"200\">CROWN_THREE <font color=\"darkgreen\">PLAYER_THREE_NAME</font></td> <td align=center><img src=\"q_images/PLAYER_FOUR_IMAGE.jpg\" height=\"200\">CROWN_FOUR <font color=\"darkgreen\">PLAYER_FOUR_NAME</font></td> </tr> <tr> <td align=center><img src=\"q_images/PLAYER_FIVE_IMAGE.jpg\" height=\"200\">CROWN_FIVE <font color=\"darkgreen\">PLAYER_FIVE_NAME</font></td> <td colspan=2 rowspan=2><img height=600 src=\"q_images/6_player.jpg\" ></img></td> <td align=center><img src=\"q_images/PLAYER_SIX_IMAGE.jpg\" height=\"200\">CROWN_SIX <font color=\"darkgreen\">PLAYER_SIX_NAME</font></td> </tr> </tbody></table>";
my $PLAYER_LAYOUT_7 = "<table class=\"questTable\"><tbody> <tr> <td align=center><img src=\"q_images/PLAYER_ONE_IMAGE.jpg\" height=\"200\">CROWN_ONE<font size=\"+2\" color=\"darkblue\">PLAYER_ONE_NAME</font></td> <td align=center><img src=\"q_images/PLAYER_TWO_IMAGE.jpg\" height=\"200\">CROWN_TWO <font color=\"darkgreen\">PLAYER_TWO_NAME</font></td> <td align=center><img src=\"q_images/PLAYER_THREE_IMAGE.jpg\" height=\"200\">CROWN_THREE <font color=\"darkgreen\">PLAYER_THREE_NAME</font></td> </tr> <tr> <td align=center><img src=\"q_images/PLAYER_FOUR_IMAGE.jpg\" height=\"200\">CROWN_FOUR <font color=\"darkgreen\">PLAYER_FOUR_NAME</font></td> <td align=center><img height=500 src=\"q_images/7_player.jpg\" ></img></td> <td align=center><img src=\"q_images/PLAYER_FIVE_IMAGE.jpg\" height=\"200\">CROWN_FIVE <font color=\"darkgreen\">PLAYER_FIVE_NAME</font></td> </tr> <tr> <td align=center><img src=\"q_images/PLAYER_SIX_IMAGE.jpg\" height=\"200\">CROWN_SIX <font color=\"darkgreen\">PLAYER_SIX_NAME</font></td> <td align=center></td> <td align=center><img src=\"q_images/PLAYER_SEVEN_IMAGE.jpg\" height=\"200\">CROWN_SEVEN <font color=\"darkgreen\">PLAYER_SEVEN_NAME</font></td> </tr> </tbody></table>";
my $PLAYER_LAYOUT_8 = "<table class=\"questTable\"><tbody> <tr> <td align=center><img src=\"q_images/PLAYER_ONE_IMAGE.jpg\" height=\"200\">CROWN_ONE<font size=\"+2\" color=\"darkblue\">PLAYER_ONE_NAME</font></td> <td align=center><img src=\"q_images/PLAYER_TWO_IMAGE.jpg\" height=\"200\">CROWN_TWO <font color=\"darkgreen\">PLAYER_TWO_NAME</font></td> <td align=center><img src=\"q_images/PLAYER_THREE_IMAGE.jpg\" height=\"200\">CROWN_THREE <font color=\"darkgreen\">PLAYER_THREE_NAME</font></td> </tr> <tr> <td align=center><img src=\"q_images/PLAYER_FOUR_IMAGE.jpg\" height=\"200\">CROWN_FOUR <font color=\"darkgreen\">PLAYER_FOUR_NAME</font></td> <td align=center><img height=500 src=\"q_images/8_player.jpg\" ></img></td> <td align=center><img src=\"q_images/PLAYER_FIVE_IMAGE.jpg\" height=\"200\">CROWN_FIVE <font color=\"darkgreen\">PLAYER_FIVE_NAME</font></td> </tr> <tr> <td align=center><img src=\"q_images/PLAYER_SIX_IMAGE.jpg\" height=\"200\">CROWN_SIX <font color=\"darkgreen\">PLAYER_SIX_NAME</font></td> <td align=center><img src=\"q_images/PLAYER_SEVEN_IMAGE.jpg\" height=\"200\">CROWN_SEVEN <font color=\"darkgreen\">PLAYER_SEVEN_NAME</font></td> <td align=center><img src=\"q_images/PLAYER_EIGHT_IMAGE.jpg\" height=\"200\">CROWN_EIGHT <font color=\"darkgreen\">PLAYER_EIGHT_NAME</font></td> </tr> </tbody></table>";
my $PLAYER_LAYOUT_9 = "<table class=\"questTable\"><tbody> <tr> <td align=center><img src=\"q_images/PLAYER_ONE_IMAGE.jpg\" height=\"200\">CROWN_ONE<font size=\"+2\" color=\"darkblue\">PLAYER_ONE_NAME</font></td> <td align=center><img src=\"q_images/PLAYER_TWO_IMAGE.jpg\" height=\"200\">CROWN_TWO <font color=\"darkgreen\">PLAYER_TWO_NAME</font></td> <td align=center><img src=\"q_images/PLAYER_THREE_IMAGE.jpg\" height=\"200\">CROWN_THREE <font color=\"darkgreen\">PLAYER_THREE_NAME</font></td> <td align=center><img src=\"q_images/PLAYER_FOUR_IMAGE.jpg\" height=\"200\">CROWN_FOUR <font color=\"darkgreen\">PLAYER_FOUR_NAME</font></td> </tr> <tr> <td align=center><img src=\"q_images/PLAYER_FIVE_IMAGE.jpg\" height=\"200\">CROWN_FIVE <font color=\"darkgreen\">PLAYER_FIVE_NAME</font></td> <td align=center colspan=2><img height=500 src=\"q_images/9_player.jpg\" ></img></td> <td align=center><img src=\"q_images/PLAYER_SIX_IMAGE.jpg\" height=\"200\">CROWN_SIX <font color=\"darkgreen\">PLAYER_SIX_NAME</font></td> </tr> <tr> <td align=center><img src=\"q_images/PLAYER_SEVEN_IMAGE.jpg\" height=\"200\">CROWN_SEVEN <font color=\"darkgreen\">PLAYER_SEVEN_NAME</font></td> <td align=center colspan=2><img src=\"q_images/PLAYER_EIGHT_IMAGE.jpg\" height=\"200\">CROWN_EIGHT <font color=\"darkgreen\">PLAYER_EIGHT_NAME</font></td> <td align=center><img src=\"q_images/PLAYER_NINE_IMAGE.jpg\" height=\"200\">CROWN_NINE <font color=\"darkgreen\">PLAYER_NINE_NAME</font></td> </tr> </tbody></table>";
my $PLAYER_LAYOUT_10 = "<table class=\"questTable\"><tbody> <tr> <td align=center><img src=\"q_images/PLAYER_ONE_IMAGE.jpg\" height=\"200\">CROWN_ONE<font size=\"+2\" color=\"darkblue\">PLAYER_ONE_NAME</font></td> <td align=center><img src=\"q_images/PLAYER_TWO_IMAGE.jpg\" height=\"200\">CROWN_TWO <font color=\"darkgreen\">PLAYER_TWO_NAME</font></td> <td align=center><img src=\"q_images/PLAYER_THREE_IMAGE.jpg\" height=\"200\">CROWN_THREE <font color=\"darkgreen\">PLAYER_THREE_NAME</font></td> <td align=center><img src=\"q_images/PLAYER_FOUR_IMAGE.jpg\" height=\"200\">CROWN_FOUR <font color=\"darkgreen\">PLAYER_FOUR_NAME</font></td> </tr> <tr> <td align=center><img src=\"q_images/PLAYER_FIVE_IMAGE.jpg\" height=\"200\">CROWN_FIVE <font color=\"darkgreen\">PLAYER_FIVE_NAME</font></td> <td align=center colspan=2><img height=500 src=\"q_images/10_player.jpg\" ></img></td> <td align=center><img src=\"q_images/PLAYER_SIX_IMAGE.jpg\" height=\"200\">CROWN_SIX <font color=\"darkgreen\">PLAYER_SIX_NAME</font></td> </tr> <tr> <td align=center><img src=\"q_images/PLAYER_SEVEN_IMAGE.jpg\" height=\"200\">CROWN_SEVEN <font color=\"darkgreen\">PLAYER_SEVEN_NAME</font></td> <td align=center><img src=\"q_images/PLAYER_EIGHT_IMAGE.jpg\" height=\"200\">CROWN_EIGHT <font color=\"darkgreen\">PLAYER_EIGHT_NAME</font></td> <td align=center><img src=\"q_images/PLAYER_NINE_IMAGE.jpg\" height=\"200\">CROWN_NINE <font color=\"darkgreen\">PLAYER_NINE_NAME</font></td> <td align=center><img src=\"q_images/PLAYER_TEN_IMAGE.jpg\" height=\"200\">CROWN_TEN  <font color=\"darkgreen\">PLAYER_TEN_NAME</font></td> </tr> </tbody></table>";
my $TEMPLATE_LAYOUT;


sub add_to_debug
{
    print ("$_[0]\n");
}

sub game_won
{
    my $win_con = $_ [0];

    if ($GAME_WON == 0)
    {
        force_needs_refresh();
        $GAME_WON = $_ [0];
        $reason_for_game_end = $_ [1];
        add_to_debug ("GAME WON: $reason_for_game_end");
        add_to_debug (join ("<br>", @in_game_players));
    }
}

sub get_game_won
{
    if ($GAME_WON == 0)
    {
        return "";
    }
    my $i = 0;

    if ($GAME_WON == -1)
    {
        my %thes;
        $thes {1} = "wickedly";
        $thes {2} = "evilly";
        $thes {3} = "iniquitously";
        $thes {4} = "heinously";
        $thes {5} = "villainously";
        $thes {6} = "diabolically";
        $thes {7} = "diabolicly";
        $thes {8} = "fiendishly";
        $thes {9} = "viciously";
        $thes {10} = "murderously";
        $thes {11} = "barbarously";
        $thes {12} = "cruelly";
        $thes {13} = "blackly";
        $thes {14} = "darkly";
        $thes {15} = "rottenly";
        $thes {16} = "nefariously";
        $thes {17} = "vilely";
        $thes {18} = "foully";
        $thes {19} = "monstrously";
        $thes {20} = "shockingly";
        $thes {21} = "outrageously";
        $thes {22} = "atrociously";
        $thes {23} = "abominably";
        $thes {24} = "reprehensibly";
        $thes {25} = "despicably";
        $thes {26} = "execrably";
        $thes {27} = "corruptly";
        $thes {28} = "degenerately";
        $thes {29} = "reprobately";
        $thes {30} = "sordidly";
        $thes {31} = "depravedily";
        $thes {32} = "dissolutely";
        $thes {33} = "badly";
        $thes {34} = "basely";
        $thes {35} = "meanly";
        $thes {36} = "lowly";
        $thes {37} = "dishonourably";
        $thes {38} = "dishonestly";
        $thes {39} = "unscrupulously";
        $thes {40} = "unprincipledly";
        $thes {41} = "underhandly";
        $thes {42} = "roguishly";
        $thes {43} = "crookedly";
        $thes {44} = "lowly";
        $thes {45} = "stinkingly";
        $thes {46} = "dirtily";
        $thes {47} = "shadily";
        $thes {48} = "rascally";
        $thes {49} = "scoundrelly";
        $thes {50} = "beastly";
        $thes {51} = "malfeasantly";
        $thes {52} = "egregiously";
        $thes {53} = "flagitiously";
        $thes {54} = "immorally";
        $thes {55} = "dastardly";
        my $x = int (rand (55));

        my $t = "<font color=darkred size=+3>muhahaha, the evil forces of Morgan-Le-Fay have swept all beneath them with treachery (well done guys!) ($reason_for_game_end)<br>";
        $t .= "These were the evil characters who " . $thes {$x} . " merged their dark Lady's PR that had *no* unit testing :|<br>";

        while ($i < scalar @player_roles)
        {
            $t .= $player_names [$i] . " -- " . $player_roles [$i] . "<br>";
            $i++;
        }
        $t .= "<\/font>";
        return $t;
    }

    my $t = "<font color=lightblue size=+3>Good guys won! ($reason_for_game_end)<br>";
    $t .= "These were the vdsl hardware enginerds who reduced radioactive bit flipping to -125dbi: ";
    while ($i < scalar @player_roles)
    {
        $t .= $player_names [$i] . "<br>";
        $i++;
    }
    $t .= "<\/font>";
    return $t;
}

sub do_shuffle
{
    @in_game_players = shuffle (@in_game_players);
}

my $DO_DEBUG = 0;
sub get_debug
{
    if ($DO_DEBUG)
    {
        return ("xxx $DEBUG yyy");
    }
    return "";
}

sub change_game_state
{
    my $new_state = $_ [0];
    
    if ($new_state ne $STATE_OF_ROUND)
    {
        $STATE_OF_ROUND = $new_state;

        if ($STATE_OF_ROUND eq $STATE_GOODS_LAST_CHANCE) 
        {
            $THE_ACCUSED = "";
            my %newAWAITING_LAST_ACCUSSED;
            %AWAITING_LAST_ACCUSSED = %newAWAITING_LAST_ACCUSSED;
            
            my $m;
            for ($m = 0; $m < $num_players_in_game; $m++) 
            {
                $AWAITING_LAST_ACCUSSED {$m} = 1;
            }
        }
        check_if_won ();
    }
}

sub write_to_socket
{
    my $sock_ref = $_ [0];
    my $msg_body = $_ [1];
    my $form = $_ [2];
    my $redirect = $_ [3];
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime (time);
    my $yyyymmddhhmmss = sprintf "%.4d%.2d%.2d-%.2d%.2d%.2d", $year+1900, $mon+1, $mday, $hour,  $min, $sec;

    $msg_body = '<html><head><META HTTP-EQUIV="CACHE-CONTROL" CONTENT="NO-CACHE"><br></head><body>' . $form . $msg_body . get_debug() . "</body></html>";
    $msg_body =~ s/\n\n/\n/mig;
    $msg_body =~ s/\n\n/\n/mig;
    $msg_body =~ s/\n\n/\n/mig;
    $msg_body .= chr (13) . chr (10);
    #$msg_body =~ s/<img.*?src="(.*?)".*?>(.*?)<\/img>/$1 - $2/img;
    $msg_body =~ s/href="/href="\/Quest\//img;
    $msg_body =~ s/\/\//\//img;
    $msg_body =~ s/Quest.Quest/Quest/img;
    $msg_body =~ s/Quest.Quest/Quest/img;
    $msg_body =~ s/Quest.Quest/Quest/img;
    $msg_body =~ s/Quest.Quest/Quest/img;

    my $header;
    if ($redirect =~ m/^redirect/i)
    {
        $header = "HTTP/1.1 302 Moved\nLocation: \/Quest\/\nLast-Modified: $yyyymmddhhmmss\nConnection: close\nContent-Type: text/html; charset=UTF-8\nContent-Length: " . length ($msg_body) . "\n\n";
    }
    elsif ($redirect =~ m/^noredirect/i)
    {
        if ($CURRENT_QUEST_NAME ne "")
        {
            $header = "HTTP/1.1 200 OK\nLast-Modified: $yyyymmddhhmmss\nConnection: close\nContent-Type: text/html\nSet-Cookie: quest_name=$CURRENT_QUEST_NAME\nContent-Length: " . length ($msg_body) . "\n\n";
        }
        else
        {
            $header = "HTTP/1.1 200 OK\nLast-Modified: $yyyymmddhhmmss\nConnection: close\nContent-Type: text/html\nContent-Length: " . length ($msg_body) . "\n\n";
        }
    }

    $msg_body = $header . $msg_body;
    add_to_debug ("\n===========\nWrite to socket: ", length ($msg_body), "! >>$msg_body<<\n==========\n");

    syswrite ($sock_ref, $msg_body);
}

sub write_to_socket_zoom
{
    my $sock_ref = $_ [0];
    my $msg_body = $_ [1];
    my $form = $_ [2];
    my $redirect = $_ [3];
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime (time);
    my $yyyymmddhhmmss = sprintf "%.4d%.2d%.2d-%.2d%.2d%.2d", $year+1900, $mon+1, $mday, $hour,  $min, $sec;
    print $yyyymmddhhmmss, "\n";

    $msg_body = '<html><head><META HTTP-EQUIV="CACHE-CONTROL" CONTENT="NO-CACHE"><br></head><body>' . $form . $msg_body . get_debug() . "</body></html>";
    $msg_body =~ s/\n\n/\n/mig;
    $msg_body =~ s/\n\n/\n/mig;
    $msg_body =~ s/\n\n/\n/mig;
    $msg_body .= chr (13) . chr (10);
    #$msg_body =~ s/<img.*?src="(.*?)".*?>(.*?)<\/img>/$1 - $2/img;
    $msg_body =~ s/href="/href="\/Quest\//img;
    $msg_body =~ s/\/\//\//img;
    $msg_body =~ s/Quest.Quest/Quest/img;
    $msg_body =~ s/Quest.Quest/Quest/img;
    $msg_body =~ s/Quest.Quest/Quest/img;
    $msg_body =~ s/Quest.Quest/Quest/img;
    #print ("$msg_body\n");

    my $header;
    if ($redirect =~ m/^redirect/i)
    {
        $header = "HTTP/1.1 302 Moved\nLocation: $ZOOM_URL_LINK\nLast-Modified: $yyyymmddhhmmss\nConnection: close\nContent-Type: text/html; charset=UTF-8\nContent-Length: " . length ($msg_body) . "\n\n";
    }

    $msg_body = $header . $msg_body;
    #print ("\n===========\nWrite to socket: ", length ($msg_body), "! >>$msg_body<<\n==========\n");
    #add_to_debug ("\n===========\nWrite to socket: ", length ($msg_body), "! >>$msg_body<<\n==========\n");

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
    while ((!(ord ($ch) == 13 and ord ($prev_ch) == 10)))
    {
        if (select ($rout=$rin, undef, undef, 200) == 1)
        {
            $prev_ch = $ch;
            # There is at least one byte ready to be read..
            if (sysread ($sock_ref, $ch, 1) < 1)
            {
                #print ("$header!!\n");
                #print (" ---> Unable to read a character\n");
                return "resend";
            }
            $header .= $ch;
            my $h = $header;
            $h =~ s/(.)/",$1-" . ord ($1) . ";"/emg;
        }
    }

    return $header;
}

sub get_player_IP
{
    my $id = $_ [0];
    if ($id < $num_players_in_game)
    {
        return $player_ips [$id];
    }
    return -1;
}

sub get_player_id
{
    my $IP = $_ [0];
    my $ip_find;
    my $i = 0;

    my $x = get_player_id_from_name ($CURRENT_QUEST_NAME);
    if ($x != -1)
    {
        return $x;
    }
    while ($i < $num_players_in_lobby)
    {
        if ($player_ips [$i] eq $IP)
        {
            return $i;
        }
        $i ++;
    }
    #add_to_debug ("Didn't find |$IP| in |" . join ("|", @player_ips));
    return -1;
}

sub get_player_name
{
    my $ID = $_ [0];
    return $player_names [$ID];
}

sub set_leader
{
    $who_is_leader = $_ [0];
    $HAS_BEEN_LEADER {$who_is_leader} = 1;
    $HAS_BEEN_LEADER {get_player_name ($who_is_leader)} = 1;
}

sub get_character_role
{
    my $id = $_ [0];
    if (exists ($player_roles [$id]))
    {
        return $player_roles [$id];
    }
    return "";
}

sub get_character_image
{
    my $id = $_ [0];
    if (exists ($player_images {$player_roles [$id]}))
    {
        return $player_images {$player_roles [$id]};
    }
    return $ERROR_IMAGE;
}

sub get_image_from_role
{
    my $role = $_ [0];
    if (exists ($player_images {$role}))
    {
        return $player_images {$role};
    }
    return $ERROR_IMAGE;
}

sub get_small_image
{
    my $url = $_ [0];
    my $new_height = $_ [1];
    $url =~ s/height=\d+/height=$new_height/;
    return $url;
}

sub get_player_id_from_name
{
    my $this_name = $_ [0];
    my $id = 0;
    for ($id = 0; $id < scalar @player_names; $id++)
    {
        if ($this_name eq $player_names [$id])
        {
            return $id;
        }
    }
    return -1;
}

sub get_player_name_from_IP
{
    my $IP = $_ [0];
    my $id = get_player_id ($IP);
    return $player_names [$id];
}

sub add_new_user
{
    my $in = $_ [0];
    my $IP = $_ [1];

    my $this_name = "";
    if ($in =~ m/name=([\w][\w][\w][\w_]+)_*$/)
    {
        $this_name = $1;
        $this_name =~ s/\W/_/g;
        $this_name =~ s/_*$//g;
        $this_name =~ s/HTTP.*//g;
        $IP .= "_$this_name";
        if ($this_name !~ m/..../)
        {
            return "";
        }
    }
    else
    {
        return "";
    }

    my $ip_find;
    foreach $ip_find (@player_ips)
    {
        if ($ip_find eq $IP)
        {
            return "";
        }
    }

    my $name_find;
    foreach $name_find (@player_names)
    {
        if ($name_find eq $this_name)
        {
            #add_to_debug (" ... 777 Already user logged in with that name ($name_find)..\n");
            return "";
        }
    }

    {
        add_to_debug ("ADDING NEW_USER ($this_name)..\n");
        $player_names [$num_players_in_lobby] = $this_name;
        $player_ips [$num_players_in_lobby] = $IP;
        add_to_debug ("ADDING NEW_USER Player IPS:" . join ("<br>", @player_ips));
        add_to_debug ("ADDING NEW_USER Player Names:" . join ("<br>", @player_names));
        $NEEDS_REFRESH [$num_players_in_lobby] = 1;
        $NEEDS_ALERT [$num_players_in_lobby] = 0;
        $num_players_in_lobby++;
        add_to_debug ("ADDING NEW_USER ($this_name)..\n");


        my $col = sprintf ("#%lX%1X%1X", int (rand (200) + 55), int (rand (200) + 55), int (rand (200) + 55));
        $rand_colors {$this_name} = $col;
        add_to_debug ("RAND COLOR - $this_name = $rand_colors{$this_name} ($col)\n");
        return "Welcome $this_name";
    }
}

sub boot_person
{
    my $person_to_boot = $_ [0];
    my $person_to_boot_id = get_player_id_from_name ($person_to_boot);

    if ($person_to_boot_id == -1)
    {
        return;
    }

    if (game_started () == 1)
    {
        return;
    }

    my @new_player_ips;
    my $len = scalar @player_ips;
    my @new_player_names;
    my $i = 0;
    my $new_i = 0;

    add_to_debug ("BOOT_PERSON $i, $len boot_person $person_to_boot ");
    while ($i < $len)
    {
        add_to_debug ("BOOT_PERSON in $i, $len boot_person $person_to_boot ");
        if ($i == $person_to_boot_id)
        {
            add_to_debug ("Booting this person BOOT_PERSON found in $i, $len boot_person $person_to_boot add $player_names[$i] to banned..");
            $BANNED_NAMES {$player_names [$i]} = 1;
            $i++;
            $num_players_in_lobby--;
            next;
        }
        add_to_debug ("Not booting this person BOOT_PERSON found in $new_i, $i, $len boot_person $person_to_boot ");
        $new_player_names [$new_i] = $player_names [$i];
        $new_player_ips [$new_i] = $player_ips [$i];

        $i++;
        $new_i++;
    }

    if ($num_players_in_lobby < 0)
    {
        $num_players_in_lobby = 0;
    }
    add_to_debug ("Before BOOT_PERSON ($person_to_boot) had names of: " . join (",", sort (@player_names)));
    add_to_debug ("Before BOOT_PERSON ($person_to_boot) had ips of: " . join (",", sort (@player_ips)));
    @player_names = @new_player_names;
    @player_ips = @new_player_ips;
    add_to_debug ("After BOOT_PERSON ($person_to_boot) had names of: " . join (",", sort (@player_names)));
    add_to_debug ("After BOOT_PERSON ($person_to_boot) had ips of: " . join (",", sort (@player_ips)));
    return "";
}

sub check_if_won
{
    my $q;
    my $num_fails = 0;
    my $num_successes = 0;

    foreach $q (sort keys (%QUEST_OUTCOMES))
    {
        if ($QUEST_OUTCOMES {$q} =~ m/Fail/img)
        {
            $num_fails ++;
            if ($num_fails >= $NUMBER_FAILS_NEEDED)
            {
                # Go to good's last chance..
                change_game_state ($STATE_GOODS_LAST_CHANCE);
            }
        }
        if ($QUEST_OUTCOMES {$q} =~ m/Success/img)
        {
            $num_successes ++;
            if ($num_successes >= 3)
            {
                game_won ($GOOD_GUYS, "3 or more successful quests!");
            }
        }
    }

    if (get_quest_number() > $TOTAL_QUESTS)
    {
        game_won ($GOOD_GUYS, "Enough successful quests!");
    }
}

sub increment_the_number_of_rounds
{
    $QUEST_NUMBER++;
    check_if_won ();
}

sub get_quest_number
{
    return $QUEST_NUMBER;
}

sub force_needs_refresh
{
    my $i = 0;
    add_to_debug (" IN FORCING REFRESH\n");
    for ($i = 0; $i < $num_players_in_lobby; $i++)
    {
        $NEEDS_REFRESH [$i] = 1;
        add_to_debug (" FORCING REFRESH FOR $i - " . get_player_name ($i));
    }
    add_to_debug (" DONE FORCING REFRESH");
}

sub force_needs_refresh_trigger
{
    my $i = 0;
    my $reason = $_ [0];
    for ($i = 0; $i < $num_players_in_lobby; $i++)
    {
        $NEEDS_REFRESH [$i] = 1;
    }
}

sub get_needs_refresh
{
    my $i = 0;
    my $IP = $_ [0];
    my $id = get_player_id ($IP);

    if ($NEEDS_REFRESH [$id])
    {
        $NEEDS_REFRESH [$id] = 0;
        return 1;
    }
    return 0;
}

sub get_id_by_role
{
    my $role = $_ [0];
    my $i = 0;

    while ($i < $num_players_in_game)
    {
        if ($player_roles [$i] eq $role)
        {
            return $i;
        }
        $i++;
    }
    return -1;
}

sub set_who_knows_who_id_id
{
    my $id1 = $_ [0];
    my $id2 = $_ [1];

    $NOT_HIDDEN_INFO {"$id1 knows $id2"} = 1;
}

# Can only be used for roles that are unique for both!
sub set_who_knows_who_role_role
{
    my $role1 = $_ [0];
    my $role2 = $_ [1];

    my $id1 = get_id_by_role ($role1);
    my $id2 = get_id_by_role ($role2);
    print (">>>> $role1, $role2 >>> $id1, $id2\n");
    set_who_knows_who_id_id ($id1, $id2);
}

sub setup_players
{
    my $role;
    my $i = 0;
    my @new_player_roles;
    my @new_players;

    @player_roles = @new_player_roles;

    foreach $role (sort keys (%COUNTS_OF_ROLES))
    {
        my $x = $COUNTS_OF_ROLES {$role};
        while ($x > 0)
        {
            $x--;
            $player_roles [$i] = $role;
            $in_game_players [$i] = $player_names [$i];
            $i++;
        }
    }
    @player_roles = shuffle (@player_roles);
    @in_game_players = shuffle (@in_game_players);

    my $n;
    for ($n = 0; $n < $i; $n++)
    {
        print ("$n === $player_roles[$n] and $in_game_players[$n]\n");
    }
}

sub new_game
{
    # Need 4 people
    if ($num_players_in_lobby <= 3)
    {
        return error_starting_game ();
    }

    $num_players_in_game = $num_players_in_lobby;
    if ($IN_DEBUG_MODE)
    {
        set_leader (0);
    }
    else
    {
        set_leader (int (rand ($num_players_in_game)));
    }
    $GAME_WON = 0;
    $NUM_EXPOSED_CARDS = 0;
    $CHANGE_OF_ROUND = 0;


    my $i;
    for ($i = 0; $i < $num_players_in_game; $i++)
    {
        $player_roles [$i] = 0;
    }

    # Setup counts for cards in players
    my %new_COUNTS_OF_ROLES;
    %COUNTS_OF_ROLES = %new_COUNTS_OF_ROLES;
    my %new_QUEST_INFO;
    %QUEST_INFO = %new_QUEST_INFO;
    $COUNTS_OF_ROLES {$MORGAN_LE_FAY} = 1;

    if ($num_players_in_game == 4)
    {
        $COUNTS_OF_ROLES {$GENERIC_GOOD} = 2;
        $COUNTS_OF_ROLES {$SCION} = 1;
        $TEMPLATE_LAYOUT = $PLAYER_LAYOUT_4;
        $num_players_on_quests {1} = 2;
        $num_players_on_quests {2} = 3;
        $num_players_on_quests {3} = 2;
        $num_players_on_quests {4} = 3;
        $TOTAL_QUESTS = 4;
        $NUMBER_FAILS_NEEDED = 2;
    }
    if ($num_players_in_game == 5)
    {
        $COUNTS_OF_ROLES {$GENERIC_GOOD} = 3;
        $COUNTS_OF_ROLES {$SCION} = 1;
        $TEMPLATE_LAYOUT = $PLAYER_LAYOUT_5;
        $num_players_on_quests {1} = 2;
        $num_players_on_quests {2} = 3;
        $num_players_on_quests {3} = 2;
        $num_players_on_quests {4} = 4;
        $num_players_on_quests {4} = 3;
        $TOTAL_QUESTS = 4;
        $NUMBER_FAILS_NEEDED = 2;
    }
    if ($num_players_in_game == 6)
    {
        $COUNTS_OF_ROLES {$ARTHUR} = 1;
        $COUNTS_OF_ROLES {$GENERIC_GOOD} = 2;
        $COUNTS_OF_ROLES {$GENERIC_BAD} = 1;
        $COUNTS_OF_ROLES {$CHANGELING} = 1;
        $TEMPLATE_LAYOUT = $PLAYER_LAYOUT_6;
        $num_players_on_quests {1} = 2;
        $num_players_on_quests {2} = 3;
        $num_players_on_quests {3} = 4;
        $num_players_on_quests {4} = 3;
        $num_players_on_quests {5} = 4;
        $TOTAL_QUESTS = 5;
        $NUMBER_FAILS_NEEDED = 3;
    }
    if ($num_players_in_game == 7)
    {
        $COUNTS_OF_ROLES {$ARTHUR} = 1;
        $COUNTS_OF_ROLES {$GENERIC_GOOD} = 2;
        $COUNTS_OF_ROLES {$DUKE} = 1;
        $COUNTS_OF_ROLES {$GENERIC_BAD} = 1;
        $COUNTS_OF_ROLES {$CHANGELING} = 1;
        $TEMPLATE_LAYOUT = $PLAYER_LAYOUT_7;
        $num_players_on_quests {1} = 2;
        $num_players_on_quests {2} = 3;
        $num_players_on_quests {3} = 3;
        $num_players_on_quests {4} = 4;
        $num_players_on_quests {5} = 4;
        $TOTAL_QUESTS = 5;
        $NUMBER_FAILS_NEEDED = 3;
    }
    if ($num_players_in_game == 8)
    {
        $COUNTS_OF_ROLES {$ARTHUR} = 1;
        $COUNTS_OF_ROLES {$GENERIC_GOOD} = 3;
        $COUNTS_OF_ROLES {$DUKE} = 1;
        $COUNTS_OF_ROLES {$GENERIC_BAD} = 1;
        $COUNTS_OF_ROLES {$CHANGELING} = 1;
        $TEMPLATE_LAYOUT = $PLAYER_LAYOUT_8;
        $num_players_on_quests {1} = 3;
        $num_players_on_quests {2} = 4;
        $num_players_on_quests {3} = 4;
        $num_players_on_quests {4} = 5;
        $num_players_on_quests {5} = 5;
        $TOTAL_QUESTS = 5;
        $NUMBER_FAILS_NEEDED = 3;
    }
    if ($num_players_in_game == 9)
    {
        $COUNTS_OF_ROLES {$ARTHUR} = 1;
        $COUNTS_OF_ROLES {$GENERIC_GOOD} = 3;
        $COUNTS_OF_ROLES {$DUKE} = 1;
        $COUNTS_OF_ROLES {$ARCHDUKE} = 1;
        $COUNTS_OF_ROLES {$GENERIC_BAD} = 1;
        $COUNTS_OF_ROLES {$CHANGELING} = 1;
        $TEMPLATE_LAYOUT = $PLAYER_LAYOUT_9;
        $num_players_on_quests {1} = 3;
        $num_players_on_quests {2} = 4;
        $num_players_on_quests {3} = 4;
        $num_players_on_quests {4} = 5;
        $num_players_on_quests {5} = 5;
        $TOTAL_QUESTS = 5;
        $NUMBER_FAILS_NEEDED = 3;
    }
    if ($num_players_in_game == 10)
    {
        $COUNTS_OF_ROLES {$ARTHUR} = 1;
        $COUNTS_OF_ROLES {$GENERIC_GOOD} = 3;
        $COUNTS_OF_ROLES {$DUKE} = 1;
        $COUNTS_OF_ROLES {$ARCHDUKE} = 1;
        $COUNTS_OF_ROLES {$GENERIC_BAD} = 2;
        $COUNTS_OF_ROLES {$CHANGELING} = 1;
        $TEMPLATE_LAYOUT = $PLAYER_LAYOUT_10;
        $num_players_on_quests {1} = 3;
        $num_players_on_quests {2} = 4;
        $num_players_on_quests {3} = 4;
        $num_players_on_quests {4} = 5;
        $num_players_on_quests {5} = 5;
        $TOTAL_QUESTS = 5;
        $NUMBER_FAILS_NEEDED = 3;
    }

    # Setup the players..
    setup_players ();

    # Setup whom knows whom.
    if ($num_players_in_game < 6)
    {
        set_who_knows_who_role_role ($MORGAN_LE_FAY, $SCION);
    }

    if ($num_players_in_game >= 6)
    {
        set_who_knows_who_role_role ($ARTHUR, $MORGAN_LE_FAY);
    }

    my $i = 0;
    for ($i = 0; $i < $num_players_in_game && $num_players_in_game >= 6; $i++)
    {
        if ($player_roles [$i] eq $GENERIC_BAD)
        {
            set_who_knows_who_id_id (get_id_by_role ($MORGAN_LE_FAY), $i);
            set_who_knows_who_id_id ($i, get_id_by_role ($MORGAN_LE_FAY));
            my $j;
            for ($j = 0; $j < $num_players_in_game && $num_players_in_game >= 6; $j++)
            {
                if ($player_roles [$j] eq $GENERIC_BAD && $i != $j)
                {
                    set_who_knows_who_id_id ($i, $j);
                    set_who_knows_who_id_id ($j, $i);
                }
            }
        }

    }

    my $i = 0;
    for ($i = 0; $i < $num_players_in_game && $num_players_in_game >= 6; $i++)
    {
        if ($player_roles [$i] eq $CLERIC)
        {
            set_who_knows_who_id_id ($i, $who_is_leader);
        }
    }

    $QUEST_NUMBER = 1;
    change_game_state ($STATE_AWAITING_QUEST);

    force_needs_refresh();
    my %new_already_shuffled;
    $START_OF_NEW_ROUND = 1;
    $DONT_PASS_TORCH = 0;
    $NEXT_QUEST_IS_FORCED = 0;
    return;
}

sub reset_game
{
    $num_players_in_game = -1;
    $who_is_leader = -1;
    $GAME_WON = 0;
    $NUM_EXPOSED_CARDS = 0;
    $CHANGE_OF_ROUND = 0;
    $QUEST_NUMBER = 1;
    change_game_state ($STATE_AWAITING_QUEST);
    $IN_DEBUG_MODE = 0;
    $TEMPLATE_LAYOUT = "";
    $reason_for_game_end = "";
    my %no_exposure;
    %exposed_cards = %no_exposure;
    my %no_revealed_cards;
    %revealed_cards = %no_revealed_cards;
    my %no_revealed_cards_strs;
    %revealed_cards_imgs = %no_revealed_cards_strs;
    $DONT_PASS_TORCH = 0;
    $NEXT_QUEST_IS_FORCED = 0;
    my @new_players;
    @in_game_players = @new_players;
    my $out = "Game reset <a href=\"\/\">Lobby or Game window<\/a>";
    force_needs_refresh();
    #add_to_debug ("Game reset");
    my %new_already_shuffled;
    my %new_NOT_HIDDEN_INFO;
    %NOT_HIDDEN_INFO = %new_NOT_HIDDEN_INFO;
    $START_OF_NEW_ROUND = 0;
    my %new_HAS_BEEN_LEADER;
    %HAS_BEEN_LEADER = %new_HAS_BEEN_LEADER;
    return $out;
}

sub simulate_game
{
    # Add simulated users..
    my $num_users = $_ [0];
    add_new_user ("name=Aaron", "192.155.155.150");
    add_new_user ("name=Bob_Bobberson", "192.156.155.150");
    add_new_user ("name=Charlie", "192.165.155.150");
    $IN_DEBUG_MODE = 1;
    if ($num_users > 4) { add_new_user ("name=Donquil", "192.185.155.150"); }
    if ($num_users > 5) { add_new_user ("name=Eragon", "193.155.155.150"); }
    if ($num_users > 6) { add_new_user ("name=Caesar", "194.155.155.150"); }
    if ($num_users > 7) { add_new_user ("name=Gerry", "195.155.155.150"); }
    if ($num_users > 8) { add_new_user ("name=Gaius", "197.155.155.150"); }
    if ($num_users > 9) { add_new_user ("name=Julius", "198.155.155.150"); }
    new_game ();
}

sub in_game
{
    my $id = get_player_id_from_name ($CURRENT_QUEST_NAME);
    if ($id >= 0 && $id < $num_players_in_game)
    {
        return 1;
    }
    return 0;
}

sub get_template_player_name
{
    my $id = $_ [0];
    if ($id == 0) { return "PLAYER_ONE_NAME"; }
    if ($id == 1) { return "PLAYER_TWO_NAME"; }
    if ($id == 2) { return "PLAYER_THREE_NAME"; }
    if ($id == 3) { return "PLAYER_FOUR_NAME"; }
    if ($id == 4) { return "PLAYER_FIVE_NAME"; }
    if ($id == 5) { return "PLAYER_SIX_NAME"; }
    if ($id == 6) { return "PLAYER_SEVEN_NAME"; }
    if ($id == 7) { return "PLAYER_EIGHT_NAME"; }
    if ($id == 8) { return "PLAYER_NINE_NAME"; }
    if ($id == 9) { return "PLAYER_TEN_NAME"; }
}

sub get_template_player_image
{
    my $id = $_ [0];
    if ($id == 0) { return "PLAYER_ONE_IMAGE"; }
    if ($id == 1) { return "PLAYER_TWO_IMAGE"; }
    if ($id == 2) { return "PLAYER_THREE_IMAGE"; }
    if ($id == 3) { return "PLAYER_FOUR_IMAGE"; }
    if ($id == 4) { return "PLAYER_FIVE_IMAGE"; }
    if ($id == 5) { return "PLAYER_SIX_IMAGE"; }
    if ($id == 6) { return "PLAYER_SEVEN_IMAGE"; }
    if ($id == 7) { return "PLAYER_EIGHT_IMAGE"; }
    if ($id == 8) { return "PLAYER_NINE_IMAGE"; }
    if ($id == 9) { return "PLAYER_TEN_IMAGE"; }
}

sub get_template_crown
{
    my $id = $_ [0];
    if ($id == 0) { return "CROWN_ONE"; }
    if ($id == 1) { return "CROWN_TWO"; }
    if ($id == 2) { return "CROWN_THREE"; }
    if ($id == 3) { return "CROWN_FOUR"; }
    if ($id == 4) { return "CROWN_FIVE"; }
    if ($id == 5) { return "CROWN_SIX"; }
    if ($id == 6) { return "CROWN_SEVEN"; }
    if ($id == 7) { return "CROWN_EIGHT"; }
    if ($id == 8) { return "CROWN_NINE"; }
    if ($id == 9) { return "CROWN_TEN"; }
}

sub player_row
{
    my $id = $_ [0];
    my $IP = $_ [1];
    my $current_table = $_ [2];

    my $template_player_name = get_template_player_name ($id);
    my $template_player_image = get_template_player_image ($id);
    my $template_crown = get_template_crown ($id);

    my $this_player_id = get_player_id_from_name ($CURRENT_QUEST_NAME);
    print ("checking who knows who: $this_player_id ===== $id\n");

    my $known_to_user = -1;
    my $hidden_identity = "";
    if (defined ($NOT_HIDDEN_INFO {"$this_player_id knows $id"}) || $this_player_id == $id || $IN_DEBUG_MODE)
    {
        $known_to_user = $NOT_HIDDEN_INFO {"$this_player_id knows $id"};
        $hidden_identity = get_character_role ($id);
    }
    else
    {
        $hidden_identity = $CARD_BACK;
    }

    my $crown_token = "";
    if ($id == $who_is_leader)
    {
        $crown_token = "$CROWN_IMAGE";
    }
    my $name_cell = "<font color=darkgreen>" . get_player_name ($id) . "</font>";
    if ($id == $this_player_id)
    {
        $name_cell = "**<font size=+2 color=darkblue>" . get_player_name ($id) . "</font>**";
    }

    my $start_bit = "";
    if ($id % 2 == 0)
    {
        $start_bit = "<tr>";
    }
    my $final_bit = "";
    if ($id % 2 == 1)
    {
        $final_bit = "</tr>";
    }
    my $out;
    $out .= "$start_bit$name_cell$crown_token<td></td>$final_bit\n";

    my $make_pickable = $this_player_id == $who_is_leader && $id != $this_player_id;
    if ($NEXT_QUEST_IS_FORCED == 2)
    {
        $make_pickable = $this_player_id == $who_is_leader;
    }

    if ($make_pickable)
    {
        $out =~ s/<img id=.card_(\d+)/<a href="\/pick_card_$1"><img id="card_$1/g;
        $out =~ s/<\/img>/<\/img><\/a>/g;
    }
    print (" 333 returning $out\n");

    $current_table =~ s/$template_player_name/$name_cell/;
    $current_table =~ s/$template_player_image/$hidden_identity/;
    if ($id != $who_is_leader)
    {
        $current_table =~ s/$template_crown//;
    }
    else
    {
        $current_table =~ s/$template_crown/$CROWN_TOKEN/;
    }
    return $current_table;
}

sub get_board
{
    my $IP = $_ [0];
    my $id = get_player_id ($IP);
    if (!in_game ($IP))
    {
        #add_to_debug ("No game in place for this player");
        return " NO BOARD TO SEE..";
    }

    my $current_table_for_player = $TEMPLATE_LAYOUT;
    $current_table_for_player = player_row (0, $IP, $current_table_for_player);
    if ($num_players_in_game >= 2) { $current_table_for_player = player_row (1, $IP, $current_table_for_player); }
    if ($num_players_in_game >= 3) { $current_table_for_player = player_row (2, $IP, $current_table_for_player); }
    if ($num_players_in_game >= 4) { $current_table_for_player = player_row (3, $IP, $current_table_for_player); }
    if ($num_players_in_game >= 5) { $current_table_for_player = player_row (4, $IP, $current_table_for_player); }
    if ($num_players_in_game >= 6) { $current_table_for_player = player_row (5, $IP, $current_table_for_player); }
    if ($num_players_in_game >= 7) { $current_table_for_player = player_row (6, $IP, $current_table_for_player); }
    if ($num_players_in_game >= 8) { $current_table_for_player = player_row (7, $IP, $current_table_for_player); }
    if ($num_players_in_game >= 9) { $current_table_for_player = player_row (8, $IP, $current_table_for_player); }
    if ($num_players_in_game >= 10) { $current_table_for_player = player_row (9, $IP, $current_table_for_player); }

    return $current_table_for_player;
}

sub start_of_new_round
{
    if ($START_OF_NEW_ROUND)
    {
        return 1;
    }
    return 0;
}

sub get_all_character_roles
{
    my $role;
    my $all_characters;
    foreach $role (sort @player_roles)
    {
        $all_characters .= get_small_image (get_image_from_role ($role), 125);
    }
    return $all_characters;
}

sub get_current_quests_outcomes
{
    my $q;
    my $o = "0 Quests completed";
    my $a_quest = 0;
    foreach $q (sort keys (%QUEST_OUTCOMES))
    {
        if ($a_quest == 0)
        {
            $a_quest = 1;
            $o = "";
        }
        $o .= "Quest $q result was:  $QUEST_OUTCOMES{$q} ($QUEST_INFO{$q})<br>";
    }
    return $o;
}

sub get_players_for_current_quest
{
    my $num_questers = $num_players_on_quests {$QUEST_NUMBER};
    if ($IN_DEBUG_MODE && $num_questers > 2)
    {
        return 2;
    }
    return ($num_players_on_quests {$QUEST_NUMBER});
}

sub print_game_state
{
    my $IP = $_ [0];
    if (in_game ($IP) == 0)
    {
        return "";
    }

    my $out;

    if (get_game_won () ne "")
    {
        $out .= get_game_won ();
    }

    my $id = get_player_id ($IP);
    if ($id == $who_is_leader)
    {
        $out .= "";
    }
    $out .= "<style>table.questTable { border: 1px solid #1C6EA4; background-color: #ABE6EE; width: 100%; text-align: left; border-collapse: collapse; }\n table.questTable td, table.questTable th { border: 1px solid #AAAAAA; padding: 3px 2px; }\n table.questTable tbody td { font-size: 13px; }\n table.questTable tr:nth-child(even)\n { background: #D0E4F5; }\n table.questTable tfoot td { font-size: 14px; }\n table.questTable tfoot .links { text-align: right; }\n\n<br></style>\n";

    my $interaction = "";
    if (start_of_new_round ())
    {
        $out .= "You are: " . get_small_image (get_character_image($id), 75);

        my $num_questers = get_players_for_current_quest ();
        if ($STATE_OF_ROUND ne $STATE_GOODS_LAST_CHANCE)
        {
            $out .= "<br><font size=+1 color=darkblue>" . get_player_name ($who_is_leader) . " is the leader for the next quest of $num_questers!</font>\n";
        }
        else
        {
            $out .= "<br><font size=+2 color=darkblue>This is Good's last chance to win!</font>$THE_ACCUSED<br>Each person has to nominate in a circle two other people whom they think are bad.<br>After each person has nominated their two, the evil players out themselves and their nominations no longer count.<br>If *all* the evil characters and *only* the evil characters are pointed at, then good wins the day!<br>";  
            $interaction = "<script>alert (\"This is good's last chance to win.  Accuse two (2) players of being bad!\"); <\/script>\n";
            if (defined ($AWAITING_LAST_ACCUSSED {$id}) && $AWAITING_LAST_ACCUSSED {$id} >= 1 && $STATE_OF_ROUND eq $STATE_GOODS_LAST_CHANCE)
            {
                $out .= "<script>function last_chance_accuse(numExpected){ var inputElems = document.getElementsByTagName(\"input\"), count = 0; for (var i=0; i<inputElems.length; i++) { if (inputElems[i].type === \"checkbox\" && inputElems[i].checked === true){ count++; } } document.getElementById(\"submitlastchance\").disabled=true; if (numExpected == count) { document.getElementById(\"submitlastchance\").disabled=false; }}</script>\n<br>";
                $out .= "<br>Select two folk to accuse of being bad and press 'Submit Accused':<br>";
                $out .= "<div width=300 style=\"background-image: url('q_images/evil_indicator.jpg'); width:300px;\">";
                $out .= "<form action=\"/Quest/last_chance_accuse\">";
                my $name;
                my $i = 1;
                foreach $name (@player_names)
                {
                    $out .= "\n<input type=\"checkbox\" id=\"ACCUSED_$i\" name=\"ACCUSED_$i\" value=\"$name\" onchange=\"last_chance_accuse(2)\"> <label for=\"ACCUSED_$i\">Accuse $name of badness</label><br>";
                    $i++;
                }

                $out .= "<input id=\"submitlastchance\" type=\"submit\" value=\"Submit Accused\" disabled></form>";

            }
            $out .= "</div>";
        }

        if ($id == $who_is_leader && $STATE_OF_ROUND eq $STATE_AWAITING_QUEST)
        {
            $interaction = "<script>alert (\"You are the leader.  You have to put $num_questers players on the next quest.  Choose one player to get the magic token (they can't fail the quest)!\"); <\/script>\n";
            $out .= "<script>function check_questers(numExpected, numMagic){var cbs = document.getElementsByTagName(\"input\"), magic = 0, count = 0; for (var i=0; i<cbs.length; i++) { if (cbs[i].type === \"checkbox\" && cbs[i].checked === true){ count++; } if (cbs[i].type === \"radio\" && cbs[i].checked === true){ magic++;}} document.getElementById(\"submitnewquest\").disabled=true; if (numExpected == count && numMagic == magic) { document.getElementById(\"submitnewquest\").disabled=false; }}</script>\n<br>";
            $out .= "<br>Select $num_questers questers for the next quest (1 will have the " . get_small_image ($MAGIC_TOKEN_IMAGE, 75) . " which means they can't lie) and press 'Submit New Quest':<br>";
            $out .= "<div width=300 style=\"background-image: url('q_images/evil_indicator.jpg'); width:300px;\">";
            $out .= "<form action=\"/Quest/set_next_on_quest\">";
            my $name;
            my $i = 1;
            my $radio = "";
            foreach $name (@player_names)
            {
                $out .= "\n<input type=\"checkbox\" id=\"QUESTER_$i\" name=\"QUESTER_$i\" value=\"$name\" onchange=\"document.getElementById('QUESTER_MAGIC_$i\').checked = false;check_questers(" . ($num_questers-1) . ", 1)\"> <label for=\"QUESTER_$i\">Add $name to the Quest</label><br>";
                $radio .= "\n<input type=\"radio\" id=\"QUESTER_MAGIC_$i\" name=\"QUESTER_MAGIC\" value=\"$name\" onclick=\"document.getElementById('QUESTER_$i\').checked = false;check_questers(" . ($num_questers-1) . ", 1)\"> <label for=\"QUESTER_MAGIC_$i\">Add $name with the 'Magic Token'</label><br>";
                $i++;
            }

            $out .= $radio;
            $out .= "<input id=\"submitnewquest\" type=\"submit\" value=\"Submit New Quest\" disabled></form>";
            $out .= "</div>";
        }


        my %no_revealed_cards;
        %revealed_cards = %no_revealed_cards;
        my %no_revealed_cards_imgs;
        %revealed_cards_imgs = %no_revealed_cards_imgs;
        if ($CHANGE_OF_ROUND == 0)
        {
            $CHANGE_OF_ROUND = 1;
            force_needs_refresh_trigger ("PRINT_GAME_STATE");
        }
    }

    if ($STATE_OF_ROUND eq $STATE_AWAITING_QUEST_RESULTS)
    {
        $out .= "$STATE_OF_ROUND " . join (keys (%AWAITING_QUESTERS));
    }

    if (defined ($AWAITING_QUESTERS {$id}) && $AWAITING_QUESTERS {$id} >= 1 && $STATE_OF_ROUND eq $STATE_AWAITING_QUEST_RESULTS)
    {
        my $with_magic_token = 0;
        if ($AWAITING_QUESTERS {$id} == 1)
        {
            $interaction = "<script>alert (\"You can vote now\"); <\/script>\n";
        }
        elsif ($AWAITING_QUESTERS {$id} == 2)
        {
            $interaction = "<script>alert (\"You can vote now.  You have the Magic token which means you can't fail unless your identity says you can ignore it or you must fail the quest in some other way!\"); <\/script>\n";
            $with_magic_token = 1;
        }
        $out .= "<script>function voteboxes(numExpected){ var inputElems = document.getElementsByTagName(\"input\"), count = 0; for (var i=0; i<inputElems.length; i++) { if (inputElems[i].type === \"checkbox\" && inputElems[i].checked === true){ count++; } } document.getElementById(\"postalvote\").disabled=true; if (numExpected == count) { document.getElementById(\"postalvote\").disabled=false; }}</script>\n<br>";
        $out .= "<br>Select success or failure and press 'Postal Vote':<br>";
        $out .= "<div width=300 style=\"background-image: url('q_images/good_indicator.jpg'); width:300px;\">";
        if ($with_magic_token)
        {
            $out .= "You have the Magic Token! " . get_small_image ($MAGIC_TOKEN_IMAGE, 125) . " which means you can't fail unless your card says otherwise!!<br>";
        }
        $out .= "<form action=\"/Quest/voted_on_quest\">";
        $out .= "\n<input type=\"checkbox\" id=\"success_$id\" name=\"success_$id\" value=\"success_$id\" onchange=\"voteboxes(1)\"> <label for=\"success_$id\">Succeed the Quest (must do if you're good/forced to)</label><br>";
        $out .= "\n<input type=\"checkbox\" id=\"failure_$id\" name=\"failure_$id\" value=\"failure_$id\" onchange=\"voteboxes(1)\"> <label for=\"failure_$id\">Fail the Quest (can do if you're bad)</label><br>";
        $out .= "<input id=\"postalvote\" type=\"submit\" value=\"Postal Vote\" disabled></form>";
        $out .= "</div>";
    }
    
    if ($id == $who_is_leader && $STATE_OF_ROUND eq $STATE_AWAITING_NEXT_LEADER)
    {
        $interaction = "<script>alert (\"You must pick the next leader now\"); <\/script>\n";
        $out .= "<script>function check_leader(numExpected){ var inputElems = document.getElementsByTagName(\"input\"), count = 0; for (var i=0; i<inputElems.length; i++) { if (inputElems[i].type === \"checkbox\" && inputElems[i].checked === true){ count++; } } document.getElementById(\"submitnewquest\").disabled=true; if (numExpected == count) { document.getElementById(\"submitnewquest\").disabled=false; }}</script>\n<br>";
        $out .= "<br>Select the next leader and press 'Submit New Leader':<br>";
        $out .= "<div width=300 style=\"background-image: url('q_images/evil_indicator.jpg'); width:300px;\">";
        $out .= "<form action=\"/Quest/next_leader_chosen\">";
        my $name;
        my $i = 1;
        foreach $name (@player_names)
        {
            my $pot_leader_id = get_player_id_from_name ($name);
            if (!defined ($HAS_BEEN_LEADER {$name}))
            {
                $out .= "\n<input type=\"checkbox\" id=\"LEADER_$pot_leader_id\" name=\"LEADER_$pot_leader_id\" value=\"$name\" onchange=\"check_leader(1)\"> <label for=\"LEADER_$pot_leader_id\">Set $name to be the next leader</label><br>";
            }
            $i++;
        }

        $out .= "<input id=\"submitnewquest\" type=\"submit\" value=\"Submit New Leader\" disabled></form>";
        $out .= "</div>";
    }

    if ($STATE_OF_ROUND eq $STATE_AWAITING_QUEST_RESULTS)
    {
        my $done_voting;
        my $not_done_voting;
        my $x;
        my $finished_voting = 1;
        foreach $x (sort keys (%AWAITING_QUESTERS))
        {
            if ($AWAITING_QUESTERS {$x} == 0)
            {
                $done_voting .= ": " . get_player_name ($x);
            }
            if ($AWAITING_QUESTERS {$x} >= 1)
            {
                $not_done_voting .= ": " . get_player_name ($x);
                $finished_voting = 0;
            }
        }
        $out .= "Awaiting results of votes!<br>Already voted:$done_voting<br>Yet to vote: $not_done_voting";

        if ($finished_voting)
        {
            my $num_failed_votes;
            my $num_success_votes;
            foreach $out (sort keys (%VOTING_RESULTS))
            {
                if ($VOTING_RESULTS{$out} == -1)
                {
                    $num_failed_votes++;
                }
                elsif ($VOTING_RESULTS{$out} == 1)
                {
                    $num_success_votes++;
                }
            }

            if ($num_failed_votes == 0)
            {
                $QUEST_OUTCOMES {get_quest_number()} = "Success";
            }
            else
            {
                $QUEST_OUTCOMES {get_quest_number()} = "Fail ($num_failed_votes)";
            }
            change_game_state ($STATE_AWAITING_NEXT_LEADER);
            $out .= "<br>Voting just finished. Result was: " .  $QUEST_OUTCOMES {get_quest_number()} . "<br>Please press F5 to refresh manually!";
            $QUEST_INFO {get_quest_number()} = "Leader was - " . get_player_name ($who_is_leader) . " - Folk on it were: $done_voting";
        }
    }

    $out .= get_board ($IP) . "<br>";
    $out .= "Players=$num_players_in_game. Characters in game:" . get_all_character_roles () . "<br>";
    $out .= get_current_quests_outcomes () . "<br>";

    if ($IN_DEBUG_MODE)
    {
        $out .= "NOT_HIDDEN:::" . join (",", sort keys (%NOT_HIDDEN_INFO));
    }

    $out .= $interaction;
    return $out;
}

sub game_started
{
    return $num_players_in_game > -1;
}

sub get_refresh_code
{
    my $do_refresh = $_ [0];
    my $bb = $_ [1];
    my $bb2 = $_ [2];
    my $name = get_player_name ($bb);
    my $txt = "";

    if (!game_started ())
    {
        $do_refresh = 1;
    }

    $txt .= "<div id='countdown'></div>" . "\n";
    $txt .= "<script>" . "\n";

    $txt .= "var HttpClient = function() {\n";
    $txt .= "   this.get = function(aUrl, aCallback) {\n";
    $txt .= "       var anHttpRequest = new XMLHttpRequest();\n";
    $txt .= "       anHttpRequest.onreadystatechange = function() { \n";
    $txt .= "           if (anHttpRequest.readyState == 3 && anHttpRequest.status == 200)\n";
    $txt .= "               aCallback(anHttpRequest.responseText);\n";
    $txt .= "       }\n";
    $txt .= "       anHttpRequest.open( \"GET\", aUrl, true );            \n";
    $txt .= "       anHttpRequest.send( null );\n";
    $txt .= "   }\n";
    $txt .= "}\n";
    $txt .= "    var doRefresh = " . $do_refresh . ";\n";
    $txt .= "    var numseconds = 2;" . "\n";
    $txt .= "    function countdownTimer() {" . "\n";
    $txt .= "        if (numseconds > 0)" . "\n";
    $txt .= "        {" . "\n";
    $txt .= "            if (doRefresh)" . "\n";
    $txt .= "            {" . "\n";
    $txt .= "                numseconds --;" . "\n";
    $txt .= "            }" . "\n";
    $txt .= "        }" . "\n";
    $txt .= "        else" . "\n";
    $txt .= "        {" . "\n";
    $txt .= "            var client = new HttpClient();\n";
    $txt .= "            numseconds = 2;\n";
    $txt .= "            client.get('/Quest/needs_refresh', function(response) {\n";
    $txt .= "                    var str = response;\n";
    $txt .= "                    var match = str.match(/.*NEEDS_REFRESH.*/i);\n";
    $txt .= "                    numseconds = 2;\n";
    $txt .= "                    if (match != null && match.length > 0) {";
    $txt .= "                        location.reload();" . "\n\n";
    $txt .= "                    }";
    #$txt .= "                    document.getElementById('countdown').innerHTML = response;" . "\n\n";
    $txt .= "            });\n";
    $txt .= "        }" . "\n";
    $txt .= "        document.getElementById('countdown').innerHTML = '<font color=white>Refreshing page in:' + numseconds + '</font>';" . "\n";
    $txt .= "    }" . "\n";
    $txt .= "    countdownTimer();" . "\n";
    $txt .= "    setInterval(countdownTimer, 1000);" . "\n";
    $txt .= "    function setCookie(cname, cvalue, exdays) {\n";
    $txt .= "      const d = new Date();\n";
    $txt .= "      d.setTime(d.getTime() + (exdays * 24 * 60 * 60 * 1000));\n";
    $txt .= "      let expires = \"expires=\"+d.toUTCString();\n";
    $txt .= "      document.cookie = cname + \"=\" + cvalue + \";\" + expires + \";path=\/\";\n";
    $txt .= "    }\n";
    $txt .= "    setCookie(\"quest_name\", \"" . $CURRENT_QUEST_NAME . "\", 0.05);\n";
    $txt .= "    function getCookie(cname) {\n";
    $txt .= "      let name = cname + \"=\";\n";
    $txt .= "      let decodedCookie = decodeURIComponent(document.cookie);\n";
    $txt .= "      let ca = decodedCookie.split(';');\n";
    $txt .= "      for(let i = 0; i < ca.length; i++) {\n";
    $txt .= "        let c = ca[i];\n";
    $txt .= "        while (c.charAt(0) == ' ') {\n";
    $txt .= "          c = c.substring(1);\n";
    $txt .= "        }\n";
    $txt .= "        if (c.indexOf(name) == 0) {\n";
    $txt .= "          return c.substring(name.length, c.length);\n";
    $txt .= "        }\n";
    $txt .= "      }\n";
    $txt .= "      return \"\";\n";
    $txt .= "    }\n";
    $txt .= "<\/script>" . "\n";
    $txt .= "<a href=\"\/Quest\/force_refresh\">Force Refresh<\/a><br>";
    if ($ZOOM_URL_LINK_set)
    {
        $txt .= "<br><font size=+1><a href=\"$ZOOM_URL_LINK\">Current Meeting Zoom URL (pasted in chat at $ZOOM_URL_LINK_DATE)<\/a></font>";
    }
    else
    {
        $txt .= "<br>No Zoom Meeting URL pasted in chat as yet";
    }
    return $txt;
}

sub get_chat_code
{
    my $out = "<form action=\"/Quest/add_chat_message\"><input size=80 type=\"text\" id=\"msg\" name=\"msg\" value=\"CopyAndPasteAMessageInHere\"><br><input type=\"submit\" value=\"Send Message!!\"></form>";
    $out .= "&nbsp;Precanned chat messages: <font size=-1><a href=\"/Quest/add_chat_message_msg=I have passed the torch\">Torch</a>";
    $out .= "&nbsp;&nbsp;<a href=\"/Quest/add_chat_message_msg=Howdy folks\">Hello</a>";
    $out .= "&nbsp;&nbsp;<a href=\"/Quest/add_chat_message_msg=Insane.. wrong game?\">Insane</a>";
    $out .= "&nbsp;&nbsp;<a href=\"/Quest/add_chat_message_msg=Carmen Sandiego\">Private eye</a>";
    $out .= "&nbsp;&nbsp;<a href=\"/Quest/add_chat_message_msg=Just double bluffing... PLEASE PICK ME!!\">Don't pick me!</a>";
    $out .= "&nbsp;&nbsp;<a href=\"/Quest/add_chat_message_msg=Hello.  Not sure how this translates to Quest..\">Phil special</a>";
    $out .= "&nbsp;&nbsp;<a href=\"/Quest/add_chat_message_msg=Shane is bad :|\">Shane is bad..</a>";
    $out .= "&nbsp;&nbsp;<a href=\"/Quest/add_chat_message_msg=2B or not 2B.  I lead you astray with this one.\">...</a></font>";
    $out .= "<table>\n";

    my $i = $NUM_CHAT_MESSAGES - 1;
    my $total = 0;
    add_to_debug ("CHAT msgs = $i");
    while ($total < 10 && defined ($CHAT_MESSAGES {$i}))
    {
        my $u = $CHAT_MESSAGES{$i};
        $u =~ s/^(.*)&nbsp;--.*/$1/;
        add_to_debug ("CHAT with $CHAT_MESSAGES{$i}");
        my $col = $rand_colors {$u};
        add_to_debug (" using RAND COLOR >$u< >$col<\n");
        $out .= "<tr bgcolor=\"$col\"><td><font size=-1>$CHAT_MESSAGES{$i}</font></td></tr>\n";
        $i--;
        $total++;
    }
    $out .= "</table>\n";
    return $out;
}

sub add_chat_message
{
    my $msg = $_ [0];
    #$msg =~ s/\W/ /img;
    #$msg =~ s/  / /img;
    #$msg =~ s/^(......................................................................).*/$1/img;

    if ($CURRENT_QUEST_NAME =~ m/\w\w\w[\w_]+/)
    {
        my $orig_msg = $msg;
        $msg =~ s/%2F/\//img;
        $msg =~ s/%3A/:/img;
        $msg =~ s/%3F/?/img;
        $msg =~ s/%3D/=/img;
        force_needs_refresh ();

        if ($msg =~ m/https.*zoom/img)
        {
            $ZOOM_URL_LINK = $msg;
            $ZOOM_URL_LINK_set = 1;
            $ZOOM_URL_LINK_DATE = strftime "%Y%m%d %H%M", localtime(time());
        }
        else
        {
            $msg =~ s/%20/ /img;
            $msg =~ s/\+/ /img;
            $CHAT_MESSAGES {$NUM_CHAT_MESSAGES} = $CURRENT_QUEST_NAME . "&nbsp;--&nbsp;$msg";
            $NUM_CHAT_MESSAGES++;
        }
    }
}

sub error_starting_game
{
    return "Error starting game (need minimum of 4 players for quest!) <a href=\"\/\">Lobby or game window<\/a>";
}

sub get_game_state
{
    my $IP = $_ [0];

    my $out .= "<h1>Welcome to Quest, <font color=" . $rand_colors {$CURRENT_QUEST_NAME} . ">$CURRENT_QUEST_NAME</font> </h1><br><br>&nbsp;There are $num_players_in_lobby players logged in.<br>";
    $out .= "Player names are:<br>" . join ("<br>", @player_names); # . "<br>IPs:<br>" . join ("<br>", @player_ips);
    $out .= "<br><br><font size=-2>You can boot players here whilst the game is not started:</font><br>";

    my $n;
    foreach $n (sort @player_names)
    {
        $out .= "&nbsp;&nbsp;&nbsp;<font size=-2><a href=\"boot_person?name=$n\">Boot $n</a></font><br>";
    }

    if (scalar keys (%BANNED_NAMES) > 0)
    {
        $out .= "<br><font size=-2>These players are already banned (use a new user name if you're affected :) ) |" . join (",", sort keys (%BANNED_NAMES)) . "|</font><br>";
    }

    my $id = get_player_id_from_name ($CURRENT_QUEST_NAME);
    if ($id == -1)
    {
        $out .= "<font color=green size=+2>Join with your user name here:</font><br><br>";
        $out .= "
            <form action=\"/Quest/new_user\">
            <label for=\"fname\">User name:</label><br>
            <input type=\"text\" id=\"fname\" name=\"fname\" value=\"xyz\"><br>
            <input type=\"submit\" value=\"Join Now!!\">
            </form>";
        my $next_num = $num_players_in_lobby +1;
        $out =~ s/xyz/User$next_num/img;
    }
    else
    {
        $out .= "<font size=+1 color=red>Welcome to Quest, " . get_player_name ($id) . "<br><\/font>";
        if (in_game ($IP))
        {
            $out = print_game_state ($IP);
            $out .= "<br>Current state of game is: $STATE_OF_ROUND";
            $out .= "<br>Reset the game here: <a href=\"reset_game\">Reset<\/a><br>";

            # Stupid popup box stuff..
            # https://bbbootstrap.com/snippets/modal-popup-custom-radio-buttons-and-checkboxes-32199170
            #$out .= "<link rel=\"stylesheet\" href=\"q_images/css/alert_css.css\"></link>";
            #$out .= "<link rel=\"stylesheet\" href=\"q_images/css/bootstrap.bundle.min.js\"></link>";
            #$out .= "<link rel=\"stylesheet\" href=\"q_images/css/bootstrap.min.css\"></link>";
            #$out .= "<link rel=\"stylesheet\" href=\"q_images/css/font-awesome.min.css\"></link>";
            #$out .= "<link rel=\"stylesheet\" href=\"q_images/css/jquery.min.js\"></link>";
            #$out .= "<script>" . "\n";
            #$out .= "\$(document).ready(function(){ \$('[data-toggle=\"popover\"]').popover(); \$(function () { \$('.example-popover').popover({ container: 'body' }) }) \$(function() { function reposition() { var modal = \$(this), dialog = modal.find('.modal-dialog'); modal.css('display', 'block'); dialog.css(\"margin-top\", Math.max(0, (\$(window).height() - dialog.height()) / 2)); } \$('.modal').on('show.bs.modal', reposition); \$(window).on('resize', function() { \$('.modal:visible').each(reposition); }); }); });";
            #$out .= "<\/script>" . "\n";
            #$out .= "<div class=\"container d-flex justify-content-center\"> <button type=\"button\" class=\"btn btn-primary\" data-toggle=\"modal\" data-target=\"#myModal\" id=\"Modal_button\"> Open modal </button> <div class=\"modal fade\" id=\"myModal\"> <div class=\"modal-dialog\"> <div class=\"modal-content\"> <div class=\"modal-header\"> <button type=\"button\" class=\"close\" data-dismiss=\"modal\">&times;</button> </div> <div class=\"modal-body mb-0 pb-0 mt-0\"> <div class=\"container \"> <div class=\"holder\"> <div class=\"row mb-1\"> <div class=\"col\"> <h2>Choose File Types</h2> </div> </div> <form action=\"#\" class=\"customRadio customCheckbox m-0 p-0\"> <div class=\"row mb-0\"> <div class=\"row justify-content-start\"> <div class=\"col-12\"> <div class=\"row\"> <input type=\"radio\" name=\"textEditor\" id=\"dreamweaver\" checked> <label for=\"dreamweaver\">Back up all files folders</label> </div> <div class=\"row\"> <input type=\"radio\" name=\"textEditor\" id=\"sublime\"> <label for=\"sublime\">Back up photos and videos</label> </div> </div> </div> </div> <div class=\"row mt-0 ml-4\"> <div class=\"col-12 my_checkbox \"> <div class=\"row\"> <input type=\"checkbox\" id=\"screenshots\" checked> <label for=\"javascript\" id=\"screenshots_label\">Back up screenshots</label> </div> <div class=\"row\"> <input type=\"checkbox\" id=\"RAW\"> <label for=\"RAW\">Back up RAW files</label> </div> <div class=\"row\"> <input type=\"checkbox\" id=\"Library\"> <label for=\"Library\">Back up Photos Library metadata</label> </div> </div> </div> <div class=\"row mt-4\"> <div class=\"col-12 Advanced_setting\"> Advanced Setting &nbsp;<i class=\"icon-action fa fa-chevron-down\"></i> </div> </div> </form> </div> </div> </div> <div class=\"modal-footer pt-0 mt-0 pb-5 pr-6 m-1 \"> <div class=\"col-2\"> </div> <div class=\"col-6 justify-content-start\"> <a href=\"#\" id=\"modal_footer_support\" data-toggle=\"popover\" title=\"Support\" data-content=\"Support Message\" class=\"modal_footer\"><i class=\"fa fa-question-circle-o modal_footer\" aria-hidden=\"true\"></i> <span class=\"modal_footer\">Support</span> </a> </div> <div class=\"col-2 justify-content-end \"> <button type=\"button\" class=\"btn btn-outline-light modal_footer\" data-dismiss=\"modal\">Cancel</button> </div> <div class=\"col-2 justify-content-start m-0 p-0\"> <button type=\"button\" class=\"btn btn-success box-shadow--16dp\" data-dismiss=\"modal\">OK</button> </div> </div> </div> </div> </div> </div>";
        }
        elsif (!game_started ())
        {
            if ($num_players_in_lobby >= 4)
            {
                $out .= "<a href=\"new_game\">Start new game!<\/a>";
            }
            else
            {
                $out .= "Need 4 players minimum to play Quest (The 'Start' URL will be here when there are enough players!)";
                $out .= "<br><a href=\"simulate_game_4\">Start simulated_4 game!<\/a>";
                $out .= "<br><a href=\"simulate_game_5\">Start simulated_5 game!<\/a>";
                $out .= "<br><a href=\"simulate_game_6\">Start simulated_6 game!<\/a>";
                $out .= "<br><a href=\"simulate_game_7\">Start simulated_7 game!<\/a>";
                $out .= "<br><a href=\"simulate_game_8\">Start simulated_8 game!<\/a>";
                $out .= "<br><a href=\"simulate_game_9\">Start simulated_9 game!<\/a>";
                $out .= "<br><a href=\"simulate_game_10\">Start simulated_10 game!<\/a>";
            }
        }
        else
        {
            $out .= "Game has already started!<br><br>";
            $out .= "*Reset and Restart* the game here: <a href=\"reset_game\">Reset<\/a><br><br><br>";
        }
    }

    my $do_refresh = 1;
    if ($id == $who_is_leader && $STATE_OF_ROUND eq $STATE_AWAITING_QUEST)
    {
        $do_refresh = 0;
    }
    $out .= get_refresh_code ($do_refresh, $id, $who_is_leader);
    $out .= get_chat_code ();
    return $out;
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
    my $port = 3672;
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

    print ("========================\n");

    while ($paddr = accept (CLIENT, SERVER))
    {
        print ("\n\nNEW============================================================\n");
        print ("- - - - - - -\n");

        ($client_port, $iaddr) = sockaddr_in ($paddr);
        add_to_debug ("Saw iaddr of $iaddr");
        $client_addr = inet_ntoa ($iaddr);
        $client_addr =~ s/\W//img;

        my $lat;
        my $long;
        my $txt = read_from_socket (\*CLIENT);
        print $txt;

        $CURRENT_QUEST_NAME = "";
        if ($txt =~ m/^Cookie.*?QUEST_NAME=(\w\w\w[\w_]+).*?(;|$)/im)
        {
            $CURRENT_QUEST_NAME = $1;
        }

        if ($txt =~ m/fname=(\w\w\w[\w_]+) HTTP/im)
        {
            $CURRENT_QUEST_NAME = $1;
        }

        if (defined $BANNED_NAMES {$CURRENT_QUEST_NAME})
        {
            add_to_debug ("BANNING $CURRENT_QUEST_NAME atm");
            $CURRENT_QUEST_NAME = "";
        }

        $CURRENT_QUEST_NAME =~ s/^(...........).*/$1/img;

        if ($CURRENT_QUEST_NAME ne "" && get_player_id_from_name ($CURRENT_QUEST_NAME) == -1)
        {
            add_new_user ("name=$CURRENT_QUEST_NAME", $client_addr);
            write_to_socket (\*CLIENT, get_game_state($client_addr), "", "noredirect");
            next;
        }

        if ($txt =~ m/.*need.*refresh.*/m)
        {
            if (get_needs_refresh ($client_addr))
            {
                write_to_socket (\*CLIENT, "NEEDS_REFRESH", "", "noredirect");
                print ("$client_addr << needs_refresh!!\n");
                next;
            }
            write_to_socket (\*CLIENT, "FINE_FOR_NOW", "", "noredirect");
            next;
        }

        if ($txt =~ m/.*force.*refresh.*/m)
        {
            force_needs_refresh ();
        }

        if ($txt =~ m/.*favico.*/m)
        {
            my $size = -s ("d:/perl_programs/quest/_quest.jpg");
            print (">>>>> size = $size\n");
            my $h = "HTTP/1.1 200 OK\nLast-Modified: 20150202020202\nConnection: close\nContent-Type: image/jpeg\nContent-Length: $size\n\n";
            print "===============\n", $h, "\n^^^^^^^^^^^^^^^^^^^\n";
            syswrite (\*CLIENT, $h);
            copy "d:/perl_programs/quest/_quest.jpg", \*CLIENT;
            next;
        }

        if ($txt =~ m/GET[^\n]*?new_user/mi)
        {
            add_to_debug ("REAL INSTANCE OF calling New_User: $txt with $client_addr<br>");
            my $ret = add_new_user ($txt, $client_addr);
            write_to_socket (\*CLIENT, "Welcome!!<a href=\"\/\">Lobby or Game window<\/a>", "", "noredirect");
            next;
        }

        add_to_debug ("Just before BOOT_PERSON had names of: " . join (",", sort (@player_names)));
        add_to_debug ("Just before BOOT_PERSON had ips of: " . join (",", sort (@player_ips)));
        if ($txt =~ m/.*boot.*person.*name=(\w\w\w[\w_]+)/mi)
        {
            my $person_to_boot = $1;
            boot_person ($person_to_boot);
            write_to_socket (\*CLIENT, "$person_to_boot was booted <a href=\"\/DONEDASBOOT\">Lobby or Game window<\/a>", "", "redirect");
            next;
        }

        if ($txt =~ m/.*set_next_on_quest.*/m && $STATE_OF_ROUND eq $STATE_AWAITING_QUEST)
        {
            change_game_state ($STATE_AWAITING_QUEST_RESULTS);
            $NUMBER_QUEST_RESULTS = 0; 
            my %new_AWAITING_QUESTERS;
            %AWAITING_QUESTERS = %new_AWAITING_QUESTERS;
            my %new_VOTING_RESULTS;
            %VOTING_RESULTS = %new_VOTING_RESULTS;
            while ($txt =~ s/.*(set_next_on_quest.*)QUESTER_(\d+)/$1/s)
            {
                my $id_of_quester = $2 - 1;
                $AWAITING_QUESTERS {$id_of_quester} = 1;
                $VOTING_RESULTS {$id_of_quester} = 0;
                print ("QUESTER was $id_of_quester\n");
                force_needs_refresh ();
            }
            
            while ($txt =~ s/.*(set_next_on_quest.*)QUESTER_MAGIC=(\w+)/$1/s)
            {
                my $name_of_magic_token_holder = $2;
                my $id_of_quester = get_player_id_from_name ($name_of_magic_token_holder);
                $AWAITING_QUESTERS {$id_of_quester} = 2;
                $VOTING_RESULTS {$id_of_quester} = 0;
                print ("MAGIC QUESTER was $id_of_quester\n");
                force_needs_refresh ();
            }
            write_to_socket (\*CLIENT, "", "", "redirect");
            next;
        }
        
        if ($txt =~ m/.*last_chance_accuse.*/m && $STATE_OF_ROUND eq $STATE_GOODS_LAST_CHANCE)
        {
            while ($txt =~ s/.*(last_chance_accuse.*)ACCUSED_(\d+)/$1/s)
            {
                my $id_of_accused = $2 - 1;
                my $accused_name = get_player_name ($id_of_accused);
                force_needs_refresh ();
                $THE_ACCUSED .= ",$CURRENT_QUEST_NAME accused $accused_name ";
                $AWAITING_LAST_ACCUSSED {get_player_id_from_name ($CURRENT_QUEST_NAME)} = 0;
            }
            write_to_socket (\*CLIENT, "", "", "redirect");
            next;
        }
        
        if ($txt =~ m/.*voted_on_quest.*/m && $STATE_OF_ROUND eq $STATE_AWAITING_QUEST_RESULTS && $NUMBER_QUEST_RESULTS < get_players_for_current_quest ())
        {
            if ($txt =~ m/.*(voted_on_quest.*)(SUCCESS|FAILURE)_(\d+)/img)
            {
                my $success = $2;
                my $id_of_quester = $3;
                print ("$3 VOTED ON THE QUEST for $2\n");
                if ($AWAITING_QUESTERS {$id_of_quester} >= 1)
                {
                    print ("Changed $3 from not VOTED to voted\n");
                    my $id_of_quester = $3;
                    $AWAITING_QUESTERS {$id_of_quester} = 0;

                    if ($success =~ m/success/img)
                    {
                        $VOTING_RESULTS {$id_of_quester} = 1;
                    }
                    elsif ($success =~ m/failure/img)
                    {
                        $VOTING_RESULTS {$id_of_quester} = -1;
                    }
                    force_needs_refresh ();
                }
            }
            write_to_socket (\*CLIENT, "", "", "redirect");
            next;
        }
        
        if ($txt =~ m/.*next_leader_chosen.*LEADER_(\d+)/m && $STATE_OF_ROUND eq $STATE_AWAITING_NEXT_LEADER)
        {
            my $next_leader = $1;
            set_leader ($next_leader);
            change_game_state ($STATE_AWAITING_QUEST);
            increment_the_number_of_rounds ();
            force_needs_refresh ();
            write_to_socket (\*CLIENT, "", "", "redirect");
            next;
        }

        if ($txt =~ m/GET.*new_game.*/m)
        {
            new_game ();
            write_to_socket (\*CLIENT, "New game was just made <a href=\"\/\">Game window<\/a>", "", "redirect");
            next;
        }

        if ($txt =~ m/GET.*simulate_game_(\d*).*/m)
        {
            simulate_game ($1);
            write_to_socket (\*CLIENT, "Simulated game was just made <a href=\"\/\">Game window<\/a>", "", "redirect");
            next;
        }

        if ($txt =~ m/.*reset.*game.*/m)
        {
            write_to_socket (\*CLIENT, reset_game (), "", "redirect");
            next;
        }

        if ($txt =~ m/.*add_chat_message.msg=(....+).HTTP/im)
        {
            add_to_debug ("CHAT WITH $1 <br>");
            write_to_socket (\*CLIENT, add_chat_message ($1), "", "redirect");
            print ($txt);
            next;
        }

        if ($txt =~ m/GET .*zoom.*/mi)
        {
            write_to_socket_zoom (\*CLIENT, "$txt", "", "redirect");
            next;
        }

        print ("Read -> $txt\n");
        $txt =~ s/Quest.*Quest/Quest/img;

        print ("2- - - - - - -\n");
        write_to_socket (\*CLIENT, get_game_state($client_addr), "", "noredirect");

        print ("============================================================\n");
    }
}
