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

my $GOOD_COLOUR = "lightblue";
my $BAD_COLOUR = "darkred";


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
my $EVIL = "evil_indicator"; my $EVIL_IMAGE = "<img height=250 src=\"q_images/evil.jpg\">$EVIL</img>";
my $FAIL = "fail"; my $FAIL_IMAGE = "<img height=250 src=\"q_images/fail.jpg\">$FAIL</img>";
my $GOOD = "good_indicator"; my $GOOD_IMAGE = "<img height=250 src=\"q_images/Good.jpg\">$GOOD</img>";
my $GOOD_TOKEN = "good_token"; my $GOOD_TOKEN_IMAGE = "<img height=250 src=\"q_images/good_token.jpg\">$GOOD_TOKEN</img>";
my $SUCCESS = "success"; my $SUCCESS_IMAGE = "<img height=250 src=\"q_images/success.jpg\">$SUCCESS</img>";
my $SWORD = "sword"; my $SWORD_IMAGE = "<img height=250 src=\"q_images/sword.jpg\">$SWORD</img>";
my $MAGIC_TOKEN = "magic_token"; my $MAGIC_TOKEN_IMAGE = "<img height=250 src=\"q_images/magic_token.jpg\">$MAGIC_TOKEN</img>";
my $FAIL_BUTTON = "q_images/fail_button.png";
my $FAIL_BUTTON_IMAGE = "<img height=250 src=\"q_images/fail_button.png\"></img>";
my $SUCCESS_BUTTON = "q_images/success_button.png";
my $SUCCESS_BUTTON_IMAGE = "<img height=250 src=\"q_images/success_button.png\"></img>";
my $AMULET_BUTTON = "q_images/amulet.png";
my $NULL_BUTTON = "q_images/null.png";

# Error :(
my $ERROR_IMAGE = $SWORD_IMAGE;

my $EXPOSED = "exposed";
my $PRESC = "prescient_vision";
my $SMALL_GAME = 3;
my $MED_GAME = 6;
my %COUNTS_OF_ROLES;
my %ROLES_ESSENTIAL;
my %PLAYER_IS_BOT;
my %exposed_cards;
my %revealed_cards;
my %revealed_cards_imgs;
my $DONT_PASS_TORCH = 0;
my $NEXT_QUEST_IS_FORCED = 0;
my $BCK = "back";

my $STATE_AWAITING_QUEST = "STATE_AWAITING_QUEST";
my $STATE_AWAITING_QUEST_RESULTS = "STATE_AWAITING_QUEST_RESULTS";
my $STATE_AWAITING_AMULET = "STATE_AWAITING_AMULET";
my $STATE_AWAITING_AMULET_RESULT = "STATE_AWAITING_AMULET_RESULT";
my $STATE_AWAITING_NEXT_LEADER = "STATE_AWAITING_NEXT_LEADER";
my $STATE_GOODS_LAST_CHANCE = "STATE_GOODS_LAST_CHANCE";
my $STATE_GAME_FINISHED = "STATE_GAME_FINISHED";

my %relative_val_of_states;
$relative_val_of_states {$STATE_AWAITING_QUEST} = 1;
$relative_val_of_states {$STATE_AWAITING_QUEST_RESULTS} = 2;
$relative_val_of_states {$STATE_AWAITING_AMULET} = 3;
$relative_val_of_states {$STATE_AWAITING_AMULET_RESULT} = 4;
$relative_val_of_states {$STATE_AWAITING_NEXT_LEADER} = 5;
$relative_val_of_states {$STATE_GOODS_LAST_CHANCE} = 6;
$relative_val_of_states {$STATE_GAME_FINISHED} = 7;

my $STATE_OF_ROUND = $STATE_AWAITING_QUEST;
my $THE_ACCUSED;
my $NUMBER_QUEST_RESULTS = 0;
my $NUMBER_FAILS_NEEDED = 2;
my %AWAITING_QUESTERS;
my %AWAITING_LAST_ACCUSSED;
my %VOTING_RESULTS;
my $NO_VOTE = 0;
my $BAD_VOTE = -1;
my $GOOD_VOTE = 1;
my %QUEST_OUTCOMES;
my %AMULET_OUTCOMES;
my $AMULET_OUTCOMES_NUM = 1;
my %HAS_BEEN_LEADER;
my %HAS_HAD_AMULET;
my %BEEN_CHECKED_BY_AMULET;

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
my $TOTAL_QUESTS = 5;
my %num_players_on_quests;
my %num_amulets;
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
my $who_is_amulet;
my $pot_who_has_torch;
my $num_players_in_game = -1;
my $NUM_EXPOSED_CARDS = 0;
my $CHANGE_OF_ROUND = 0;
my @player_ips;
my $num_players_in_lobby = 0;

# Player layouts for the table.
my $CROWN_TOKEN = "<img src=\"q_images/crown.jpg\" height=\"75\">";
my $PLAYER_LAYOUT_4 = "<table class=\"questTable\"><tbody> <tr> <td align=center> <img src=\"q_images/PLAYER_ONE_IMAGE.jpg\" height=\"200\">CROWN_ONE<font size=\"+2\" color=\"darkblue\">PLAYER_ONE_NAME</font></td> <td rowspan=2> <div style=\"position:relative;\"><img src=\"q_images/4_player.jpg\" height=\"600\"/> <img src=\"QUEST1_BUTTON\" height=\"140\" style=\"position:absolute; top:240px; left:120px; z-index:5; border:none;\"/> <img src=\"QUEST2_BUTTON\" height=\"140\" style=\"position:absolute; top:240px; left:270px; z-index:5; border:none;\"/> <img src=\"QUEST3_BUTTON\" height=\"140\" style=\"position:absolute; top:240px; left:420px; z-index:5; border:none;\"/> <img src=\"QUEST4_BUTTON\" height=\"140\" style=\"position:absolute; top:240px; left:565px; z-index:5; border:none;\"/> </div></td> <td align=center><img src=\"q_images/PLAYER_TWO_IMAGE.jpg\" height=\"200\">CROWN_TWO <font color=\"darkgreen\">PLAYER_TWO_NAME</font></td> </tr> <tr> <td align=center><img src=\"q_images/PLAYER_THREE_IMAGE.jpg\" height=\"200\">CROWN_THREE <font color=\"darkgreen\">PLAYER_THREE_NAME</font></td> <td align=center><img src=\"q_images/PLAYER_FOUR_IMAGE.jpg\" height=\"200\">CROWN_FOUR <font color=\"darkgreen\">PLAYER_FOUR_NAME</font></td> </tr> </tbody></table>";
my $PLAYER_LAYOUT_5 = "<table class=\"questTable\"><tbody> <tr> <td align=center><img src=\"q_images/PLAYER_ONE_IMAGE.jpg\" height=\"200\">CROWN_ONE<font size=\"+2\" color=\"darkblue\">PLAYER_ONE_NAME</font></td> <td align=center><img src=\"q_images/PLAYER_TWO_IMAGE.jpg\" height=\"200\">CROWN_TWO <font color=\"darkgreen\">PLAYER_TWO_NAME</font></td> <td align=center><img src=\"q_images/PLAYER_THREE_IMAGE.jpg\" height=\"200\">CROWN_THREE <font color=\"darkgreen\">PLAYER_THREE_NAME</font></td> </tr> <tr> <td align=center><img src=\"q_images/PLAYER_FOUR_IMAGE.jpg\" height=\"200\">CROWN_FOUR <font color=\"darkgreen\">PLAYER_FOUR_NAME</font></td> <td rowspan=2> <div style=\"position:relative;\"><img src=\"q_images/5_player.jpg\" height=\"600\"/> <img src=\"QUEST1_BUTTON\" height=\"150\" style=\"position:absolute; top:220px; left:20px; z-index:5; border:none;\"/> <img src=\"QUEST2_BUTTON\" height=\"150\" style=\"position:absolute; top:220px; left:170px; z-index:5; border:none;\"/> <img src=\"QUEST3_BUTTON\" height=\"150\" style=\"position:absolute; top:220px; left:330px; z-index:5; border:none;\"/> <img src=\"QUEST4_BUTTON\" height=\"150\" style=\"position:absolute; top:220px; left:480px; z-index:5; border:none;\"/> <img src=\"QUEST5_BUTTON\" height=\"150\" style=\"position:absolute; top:220px; left:635px; z-index:5; border:none;\"/> </div> </td> <td align=center><img src=\"q_images/PLAYER_FIVE_IMAGE.jpg\" height=\"200\">CROWN_FIVE <font color=\"darkgreen\">PLAYER_FIVE_NAME</font></td> </tr> </tbody></table>";
my $PLAYER_LAYOUT_6 = "<table class=\"questTable\"><tbody> <tr> <td align=center><img src=\"q_images/PLAYER_ONE_IMAGE.jpg\" height=\"200\">CROWN_ONE<font size=\"+2\" color=\"darkblue\">PLAYER_ONE_NAME</font></td> <td align=center><img src=\"q_images/PLAYER_TWO_IMAGE.jpg\" height=\"200\">CROWN_TWO <font color=\"darkgreen\">PLAYER_TWO_NAME</font></td> <td align=center><img src=\"q_images/PLAYER_THREE_IMAGE.jpg\" height=\"200\">CROWN_THREE <font color=\"darkgreen\">PLAYER_THREE_NAME</font></td> <td align=center><img src=\"q_images/PLAYER_FOUR_IMAGE.jpg\" height=\"200\">CROWN_FOUR <font color=\"darkgreen\">PLAYER_FOUR_NAME</font></td> </tr> <tr> <td align=center><img src=\"q_images/PLAYER_FIVE_IMAGE.jpg\" height=\"200\">CROWN_FIVE <font color=\"darkgreen\">PLAYER_FIVE_NAME</font></td> <td colspan=2 rowspan=2> <div style=\"position:relative;\"><img height=600 src=\"q_images/6_player.jpg\" ></img><img src=\"QUEST1_BUTTON\" height=\"150\" style=\"position:absolute; top:220px; left:30px; z-index:5; border:none;\"/> <img src=\"QUEST2_BUTTON\" height=\"150\" style=\"position:absolute; top:220px; left:190px; z-index:5; border:none;\"/> <img src=\"QUEST3_BUTTON\" height=\"150\" style=\"position:absolute; top:220px; left:350px; z-index:5; border:none;\"/> <img src=\"QUEST4_BUTTON\" height=\"150\" style=\"position:absolute; top:220px; left:500px; z-index:5; border:none;\"/> <img src=\"AMULET1_BUTTON\" height=\"100\" style=\"position:absolute; top:140px; left:290px; z-index:5; border:none;\"/> <img src=\"QUEST5_BUTTON\" height=\"150\" style=\"position:absolute; top:220px; left:660px; z-index:5; border:none;\"/> </div> </td> <td align=center><img src=\"q_images/PLAYER_SIX_IMAGE.jpg\" height=\"200\">CROWN_SIX <font color=\"darkgreen\">PLAYER_SIX_NAME</font></td> </tr> </tbody></table>";
my $PLAYER_LAYOUT_7 = "<table class=\"questTable\"><tbody> <tr> <td align=center><img src=\"q_images/PLAYER_ONE_IMAGE.jpg\" height=\"200\">CROWN_ONE<font size=\"+2\" color=\"darkblue\">PLAYER_ONE_NAME</font></td> <td align=center><img src=\"q_images/PLAYER_TWO_IMAGE.jpg\" height=\"200\">CROWN_TWO <font color=\"darkgreen\">PLAYER_TWO_NAME</font></td> <td align=center><img src=\"q_images/PLAYER_THREE_IMAGE.jpg\" height=\"200\">CROWN_THREE <font color=\"darkgreen\">PLAYER_THREE_NAME</font></td> </tr> <tr> <td align=center><img src=\"q_images/PLAYER_FOUR_IMAGE.jpg\" height=\"200\">CROWN_FOUR <font color=\"darkgreen\">PLAYER_FOUR_NAME</font></td> <td> <div style=\"position:relative;\"> <img src=\"q_images/7_player.jpg\" height=\"500\"/> <img src=\"QUEST1_BUTTON\" height=\"125\" style=\"position:absolute; top:180px; left:15px; z-index:5; border:none;\"/> <img src=\"QUEST2_BUTTON\" height=\"125\" style=\"position:absolute; top:180px; left:140px; z-index:5; border:none;\"/> <img src=\"QUEST3_BUTTON\" height=\"125\" style=\"position:absolute; top:180px; left:270px; z-index:5; border:none;\"/> <img src=\"QUEST4_BUTTON\" height=\"125\" style=\"position:absolute; top:175px; left:390px; z-index:5; border:none;\"/> <img src=\"AMULET1_BUTTON\" height=\"75\" style=\"position:absolute; top:130px; left:230px; z-index:5; border:none;\"/> <img src=\"AMULET2_BUTTON\" height=\"75\" style=\"position:absolute; top:125px; left:345px; z-index:5; border:none;\"/> <img src=\"QUEST5_BUTTON\" height=\"125\" style=\"position:absolute; top:170px; left:510px; z-index:5; border:none;\"/> </div> </td> <td align=center><img src=\"q_images/PLAYER_FIVE_IMAGE.jpg\" height=\"200\">CROWN_FIVE <font color=\"darkgreen\">PLAYER_FIVE_NAME</font></td> </tr> <tr> <td align=center><img src=\"q_images/PLAYER_SIX_IMAGE.jpg\" height=\"200\">CROWN_SIX <font color=\"darkgreen\">PLAYER_SIX_NAME</font></td> <td align=center></td> <td align=center><img src=\"q_images/PLAYER_SEVEN_IMAGE.jpg\" height=\"200\">CROWN_SEVEN <font color=\"darkgreen\">PLAYER_SEVEN_NAME</font></td> </tr> </tbody></table>";
my $PLAYER_LAYOUT_8 = "<table class=\"questTable\"><tbody> <tr> <td align=center><img src=\"q_images/PLAYER_ONE_IMAGE.jpg\" height=\"200\">CROWN_ONE<font size=\"+2\" color=\"darkblue\">PLAYER_ONE_NAME</font></td> <td align=center><img src=\"q_images/PLAYER_TWO_IMAGE.jpg\" height=\"200\">CROWN_TWO <font color=\"darkgreen\">PLAYER_TWO_NAME</font></td> <td align=center><img src=\"q_images/PLAYER_THREE_IMAGE.jpg\" height=\"200\">CROWN_THREE <font color=\"darkgreen\">PLAYER_THREE_NAME</font></td> </tr> <tr> <td align=center><img src=\"q_images/PLAYER_FOUR_IMAGE.jpg\" height=\"200\">CROWN_FOUR <font color=\"darkgreen\">PLAYER_FOUR_NAME</font></td> <td > <div style=\"position:relative;\"> <img src=\"q_images/8_player.jpg\" height=\"500\"/> <img src=\"QUEST1_BUTTON\" height=\"125\" style=\"position:absolute; top:180px; left:15px; z-index:5; border:none;\"/> <img src=\"QUEST2_BUTTON\" height=\"125\" style=\"position:absolute; top:180px; left:140px; z-index:5; border:none;\"/> <img src=\"QUEST3_BUTTON\" height=\"125\" style=\"position:absolute; top:180px; left:270px; z-index:5; border:none;\"/> <img src=\"QUEST4_BUTTON\" height=\"125\" style=\"position:absolute; top:175px; left:390px; z-index:5; border:none;\"/> <img src=\"AMULET1_BUTTON\" height=\"75\" style=\"position:absolute; top:135px; left:240px; z-index:5; border:none;\"/> <img src=\"AMULET2_BUTTON\" height=\"75\" style=\"position:absolute; top:130px; left:360px; z-index:5; border:none;\"/> <img src=\"AMULET3_BUTTON\" height=\"75\" style=\"position:absolute; top:125px; left:475px; z-index:5; border:none;\"/> <img src=\"QUEST5_BUTTON\" height=\"125\" style=\"position:absolute; top:170px; left:510px; z-index:5; border:none;\"/> </div> </td> <td align=center><img src=\"q_images/PLAYER_FIVE_IMAGE.jpg\" height=\"200\">CROWN_FIVE <font color=\"darkgreen\">PLAYER_FIVE_NAME</font></td> </tr> <tr> <td align=center><img src=\"q_images/PLAYER_SIX_IMAGE.jpg\" height=\"200\">CROWN_SIX <font color=\"darkgreen\">PLAYER_SIX_NAME</font></td> <td align=center><img src=\"q_images/PLAYER_SEVEN_IMAGE.jpg\" height=\"200\">CROWN_SEVEN <font color=\"darkgreen\">PLAYER_SEVEN_NAME</font></td> <td align=center><img src=\"q_images/PLAYER_EIGHT_IMAGE.jpg\" height=\"200\">CROWN_EIGHT <font color=\"darkgreen\">PLAYER_EIGHT_NAME</font></td> </tr> </tbody></table>";
my $PLAYER_LAYOUT_9 = "<table class=\"questTable\"><tbody> <tr> <td align=center><img src=\"q_images/PLAYER_ONE_IMAGE.jpg\" height=\"200\">CROWN_ONE<font size=\"+2\" color=\"darkblue\">PLAYER_ONE_NAME</font></td> <td align=center><img src=\"q_images/PLAYER_TWO_IMAGE.jpg\" height=\"200\">CROWN_TWO <font color=\"darkgreen\">PLAYER_TWO_NAME</font></td> <td align=center><img src=\"q_images/PLAYER_THREE_IMAGE.jpg\" height=\"200\">CROWN_THREE <font color=\"darkgreen\">PLAYER_THREE_NAME</font></td> <td align=center><img src=\"q_images/PLAYER_FOUR_IMAGE.jpg\" height=\"200\">CROWN_FOUR <font color=\"darkgreen\">PLAYER_FOUR_NAME</font></td> </tr> <tr> <td align=center><img src=\"q_images/PLAYER_FIVE_IMAGE.jpg\" height=\"200\">CROWN_FIVE <font color=\"darkgreen\">PLAYER_FIVE_NAME</font></td> <td colspan=2> <div style=\"position:relative;\"> <img src=\"q_images/9_player.jpg\" height=\"500\"/> <img src=\"QUEST1_BUTTON\" height=\"125\" style=\"position:absolute; top:180px; left:30px; z-index:5; border:none;\"/> <img src=\"QUEST2_BUTTON\" height=\"125\" style=\"position:absolute; top:180px; left:160px; z-index:5; border:none;\"/> <img src=\"QUEST3_BUTTON\" height=\"125\" style=\"position:absolute; top:180px; left:280px; z-index:5; border:none;\"/> <img src=\"QUEST4_BUTTON\" height=\"125\" style=\"position:absolute; top:180px; left:410px; z-index:5; border:none;\"/> <img src=\"q_images/amulet.png\" height=\"75\" style=\"position:absolute; top:135px; left:240px; z-index:5; border:none;\"/> <img src=\"AMULET1_BUTTON\" height=\"75\" style=\"position:absolute; top:135px; left:250px; z-index:5; border:none;\"/> <img src=\"AMULET2_BUTTON\" height=\"75\" style=\"position:absolute; top:135px; left:370px; z-index:5; border:none;\"/> <img src=\"AMULET3_BUTTON\" height=\"75\" style=\"position:absolute; top:135px; left:490px; z-index:5; border:none;\"/> <img src=\"QUEST5_BUTTON\" height=\"125\" style=\"position:absolute; top:180px; left:535px; z-index:5; border:none;\"/> </div> </td> <td align=center> <img src=\"q_images/PLAYER_SIX_IMAGE.jpg\" height=\"200\">CROWN_SIX <font color=\"darkgreen\">PLAYER_SIX_NAME</font></td> </tr> <tr> <td align=center><img src=\"q_images/PLAYER_SEVEN_IMAGE.jpg\" height=\"200\">CROWN_SEVEN <font color=\"darkgreen\">PLAYER_SEVEN_NAME</font></td> <td align=center colspan=2><img src=\"q_images/PLAYER_EIGHT_IMAGE.jpg\" height=\"200\">CROWN_EIGHT <font color=\"darkgreen\">PLAYER_EIGHT_NAME</font></td> <td align=center><img src=\"q_images/PLAYER_NINE_IMAGE.jpg\" height=\"200\">CROWN_NINE <font color=\"darkgreen\">PLAYER_NINE_NAME</font></td> </tr> </tbody></table>";
my $PLAYER_LAYOUT_10 = "<table class=\"questTable\"><tbody> <tr> <td align=center><img src=\"q_images/PLAYER_ONE_IMAGE.jpg\" height=\"200\">CROWN_ONE<font size=\"+2\" color=\"darkblue\">PLAYER_ONE_NAME</font></td> <td align=center><img src=\"q_images/PLAYER_TWO_IMAGE.jpg\" height=\"200\">CROWN_TWO <font color=\"darkgreen\">PLAYER_TWO_NAME</font></td> <td align=center><img src=\"q_images/PLAYER_THREE_IMAGE.jpg\" height=\"200\">CROWN_THREE <font color=\"darkgreen\">PLAYER_THREE_NAME</font></td> <td align=center><img src=\"q_images/PLAYER_FOUR_IMAGE.jpg\" height=\"200\">CROWN_FOUR <font color=\"darkgreen\">PLAYER_FOUR_NAME</font></td> </tr> <tr> <td align=center><img src=\"q_images/PLAYER_FIVE_IMAGE.jpg\" height=\"200\">CROWN_FIVE <font color=\"darkgreen\">PLAYER_FIVE_NAME</font></td> <td colspan=2> <div style=\"position:relative;\"> <img src=\"q_images/10_player.jpg\" height=\"500\"/> <img src=\"QUEST1_BUTTON\" height=\"135\" style=\"position:absolute; top:180px; left:30px; z-index:5; border:none;\"/> <img src=\"QUEST2_BUTTON\" height=\"135\" style=\"position:absolute; top:180px; left:160px; z-index:5; border:none;\"/> <img src=\"QUEST3_BUTTON\" height=\"135\" style=\"position:absolute; top:180px; left:280px; z-index:5; border:none;\"/> <img src=\"QUEST4_BUTTON\" height=\"135\" style=\"position:absolute; top:180px; left:410px; z-index:5; border:none;\"/> <img src=\"AMULET1_BUTTON\" height=\"75\" style=\"position:absolute; top:135px; left:250px; z-index:5; border:none;\"/> <img src=\"AMULET2_BUTTON\" height=\"75\" style=\"position:absolute; top:135px; left:375px; z-index:5; border:none;\"/> <img src=\"AMULET3_BUTTON\" height=\"75\" style=\"position:absolute; top:135px; left:500px; z-index:5; border:none;\"/> <img src=\"QUEST5_BUTTON\" height=\"135\" style=\"position:absolute; top:180px; left:530px; z-index:5; border:none;\"/> </div> </td> <td align=center> <img src=\"q_images/PLAYER_SIX_IMAGE.jpg\" height=\"200\">CROWN_SIX <font color=\"darkgreen\">PLAYER_SIX_NAME</font></td> </tr> <tr> <td align=center><img src=\"q_images/PLAYER_SEVEN_IMAGE.jpg\" height=\"200\">CROWN_SEVEN <font color=\"darkgreen\">PLAYER_SEVEN_NAME</font></td> <td align=center><img src=\"q_images/PLAYER_EIGHT_IMAGE.jpg\" height=\"200\">CROWN_EIGHT <font color=\"darkgreen\">PLAYER_EIGHT_NAME</font></td> <td align=center><img src=\"q_images/PLAYER_NINE_IMAGE.jpg\" height=\"200\">CROWN_NINE <font color=\"darkgreen\">PLAYER_NINE_NAME</font></td> <td align=center><img src=\"q_images/PLAYER_TEN_IMAGE.jpg\" height=\"200\">CROWN_TEN  <font color=\"darkgreen\">PLAYER_TEN_NAME</font></td> </tr> </tbody></table>";
my $TEMPLATE_LAYOUT;


sub add_to_debug
{
    print ("$_[0]\n");
}

sub game_won
{
    my $win_con = $_ [0];
    if ($reason_for_game_end eq "")
    {
        $reason_for_game_end = $_ [1];
    }
    print (">>> $win_con, $reason_for_game_end\n");

    if ($GAME_WON == 0)
    {
        force_needs_refresh("game_won");
        $GAME_WON = $_ [0];
        $reason_for_game_end = $_ [1];
        add_to_debug ("GAME WON: $reason_for_game_end");
        add_to_debug (join ("<br>", @in_game_players));
    }
}


sub get_roles
{
    my $i = 0;
    my $t;
    while ($i < scalar @player_roles)
    {
        my $role = $player_roles [$i];
        my $font_color = "$BAD_COLOUR";

        if ($role eq $APPRENTICE || $role eq $ARCHDUKE ||
            $role eq $ARTHUR || $role eq $CLERIC ||
            $role eq $DUKE || $role eq $GENERIC_GOOD ||
            $role eq $RELUCTANT_LEADER || $role eq $SABOTEUR ||
            $role eq $SENTINEL || $role eq $TROUBLEMAKER ||
            $role eq $YOUTH)
        {
            $font_color = "$GOOD_COLOUR";
        }

        $t .= "<font color=$font_color>" . $player_names [$i] . " -- " . $player_roles [$i] . "</font><br>";
        $i++;
    }
    return $t;
}

sub prettify_accused
{
    my $new_accused = $THE_ACCUSED;
    my $i;

    while ($i < scalar @player_roles)
    {
        my $role = $player_roles [$i];
        my $name = $player_names [$i];

        my $font_color = "$GOOD_COLOUR";
        my $bad = is_role_bad ($role);
        if ($bad)
        {
            $font_color = "$BAD_COLOUR";
            $new_accused =~ s/(Player $name.*?of being bad)/<font size=-2 color=grey>$1<\/font>/img;
        }
        $new_accused =~ s/($name)/<font color=$font_color>$1<\/font>/img;
        $i++;
    }

    $new_accused = "\n$new_accused\n";
    $new_accused =~ s/Player/\n<br>Player/img;
    $new_accused =~ s/(Player.*?<font.*?$GOOD_COLOUR.*?accused.*<font.*?$GOOD_COLOUR.*?of being bad)/\n$1 -- <font size=+1 color=$BAD_COLOUR> BAD WINS! (as good guys accused other good guys)<\/font>/img;

    if ($new_accused =~ m/BAD WINS/img)
    {
        game_won ($BAD_GUYS, "Good guys accused goods guys in Last-chance round!");
    }
    else
    {
        game_won ($GOOD_GUYS, "<font size=-1>Good guys didn't accuse any other good guy (check if they accused all bad guys though..)!<\/font>");
    }
    return $new_accused . "<br><br>$THE_ACCUSED<br>";
}

sub get_game_won
{
    if ($GAME_WON == 0)
    {
        return "";
    }
    print ("GAME WON??$GAME_WON\n"); 
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

        my $t = "<font color=$BAD_COLOUR size=+3>muhahaha, the evil forces of Morgan-Le-Fay have swept all beneath them with treachery (well done guys!) ($reason_for_game_end)<br>";
        $t .= "These were the evil characters who " . $thes {$x} . " merged their dark Lady's PR that had *no* unit testing :|<br><\/font>";
        $t .= "<br>These were the roles:<br>" . get_roles ();
        return $t;
    }

    my $t = "<font color=$GOOD_COLOUR size=+3>Good guys won! ($reason_for_game_end)<br><\/font>";
    $t .= "These were the roles:<br>" . get_roles ();
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

my $GAME_STATES;
sub change_game_state
{
    my $new_state = $_ [0];
    my $force = $_ [1];
    my $reason = $_ [2];

    print ("Change Game State ($reason) - $new_state, current=$STATE_OF_ROUND, $force\n");
    if ($force)
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
                print ("LAST ACCUSED setting to 1!\n");
            }
        }

        $GAME_STATES .= "<br>\n$STATE_OF_ROUND ($force) -- $reason -- " . get_quest_number ();
        print ("\n==gggg=================\n$GAME_STATES\n=====================\n");
        check_if_won ("game_state_change");
        return;
    }
    print ("22) Change Game State ($reason) - $new_state, current=$STATE_OF_ROUND, $force\n");

    my $new_state_val = $relative_val_of_states {$new_state};
    my $old_state_val = $relative_val_of_states {$STATE_OF_ROUND};

    # Have some kind of order..
    if ($new_state_val < $old_state_val)
    {
        print ("33) Change Game State ($reason) - $new_state, current=$STATE_OF_ROUND, $force\n");
        return;
    }

    print ("44) Change Game State ($reason) - $new_state, current=$STATE_OF_ROUND, $force\n");
    if ($new_state ne $STATE_OF_ROUND)
    {
        $STATE_OF_ROUND = $new_state;
        $GAME_STATES .= "<br>\n$STATE_OF_ROUND (no force) -- $reason -- " . get_quest_number ();
        print ("\n====gggg==============\n$GAME_STATES\n=====================\n");

        if ($STATE_OF_ROUND eq $STATE_GOODS_LAST_CHANCE)
        {
            $THE_ACCUSED = "";
            my %newAWAITING_LAST_ACCUSSED;
            %AWAITING_LAST_ACCUSSED = %newAWAITING_LAST_ACCUSSED;

            my $m;
            for ($m = 0; $m < $num_players_in_game; $m++)
            {
                $AWAITING_LAST_ACCUSSED {$m} = 1;
                print ("22) LAST ACCUSED setting to 1!\n");
            }
        }
        print ("66) Change Game State ($reason) - $new_state, current=$STATE_OF_ROUND, $force\n");
        print ("Check if won..\n");
        check_if_won ("gamestate2");
        print ("OUT OF GAMESTATE2\n");
    }
    print ("55) Change Game State ($reason) - $new_state, current=$STATE_OF_ROUND, $force\n");
}

sub is_game_over
{
    if ($STATE_OF_ROUND eq $STATE_GAME_FINISHED) 
    {
        return 1;
    }
    return 0;
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

sub get_player_name_from_id
{
    return get_player_name ($_ [0]);
}

sub set_leader
{
    $who_is_leader = $_ [0];
    increment_the_number_of_rounds ();

    print ("NEW_LEADER $who_is_leader for quest " . get_quest_number () . "\n");
    if (is_bot (get_player_name ($who_is_leader), $who_is_leader, "set_leader"))
    {
        print ("NEW_LEADER IS A BOT $who_is_leader\n");
        handle_bot_being_leader ($who_is_leader, "set_leader");
    }
    $HAS_BEEN_LEADER {$who_is_leader} = 1;
    $HAS_BEEN_LEADER {get_player_name ($who_is_leader)} = 1;
}

sub set_amulet
{
    $who_is_amulet = $_ [0];
    $HAS_HAD_AMULET {$who_is_amulet} = 1;
    $HAS_HAD_AMULET {get_player_name ($who_is_amulet)} = 1;
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
    my $is_bot = $_ [2];

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
        $PLAYER_IS_BOT {$this_name} = 0;
        if ($is_bot)
        {
            $PLAYER_IS_BOT {$this_name} = 1;
            print ("THIS PLAYER IS A BOT: $this_name\n");
        }
        return "Welcome $this_name";
    }
}

sub is_bot
{
    my $name = $_ [0];
    my $id = $_ [1];
    my $from = $_ [2];

    if ($name eq "")
    {
        $name = get_player_id_from_name ($id);
    }

    print (join (",", sort keys (%PLAYER_IS_BOT)));
    if (defined ($PLAYER_IS_BOT {$name}) && ($PLAYER_IS_BOT {$name} == 1))
    {
        print ("\nBOT found ($from): $name $id >> a bot!!!\n");
        return 1;
    }
    print ("\nNot a BOT found ($from): $name $id >> a bot!!!\n");
    return 0;
}

sub get_vote_from_bot
{
    my $id = $_ [0];
    my $magic_token = $_ [1];

    print ("Getting vote for bot from $id, $magic_token\n");
    if (!is_bot (get_player_name ($id), $id, "get_vote_from_bot"))
    {
        print ("Error with bot checking..");
        return $NO_VOTE;
    }

    if (is_role_bad (get_character_role ($id)) && (!$magic_token || $magic_token && get_character_role ($id) eq $MORGAN_LE_FAY))
    {
        my $r = int (rand (10));
        if ($r < 7)
        {
            return $BAD_VOTE;
        }
        return $GOOD_VOTE;
    }

    return $GOOD_VOTE;
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
    my $reason = $_ [0];
    my $q;
    my $num_fails = 0;
    my $num_successes = 0;

    print ("Check if won!! ($reason)\n");
    foreach $q (sort keys (%QUEST_OUTCOMES))
    {
        if ($QUEST_OUTCOMES {$q} =~ m/Fail/img)
        {
            $num_fails ++;
            if ($num_fails >= $NUMBER_FAILS_NEEDED)
            {
                # Go to good's last chance..
                change_game_state ($STATE_GOODS_LAST_CHANCE, 0, "check_if_won");
                print ("After change game state\n");
            }
        }
        if ($QUEST_OUTCOMES {$q} =~ m/Success/img)
        {
            $num_successes ++;
            if ($num_successes >= 3)
            {
                game_won ($GOOD_GUYS, "3 or more successful quests!");
                change_game_state ($STATE_GAME_FINISHED, 0, "check_if_won2");
                print ("2After change game state\n");
            }
        }
    }

    print ("tttt >>> $TOTAL_QUESTS\n");
    if (get_quest_number () >= $TOTAL_QUESTS && $num_successes >= 3)
    {
        game_won ($GOOD_GUYS, "$TOTAL_QUESTS Enough successful quests! (" . get_quest_number () . ")");
        change_game_state ($STATE_GAME_FINISHED, 0, "check_if_won44 (qn=". get_quest_number () . " total_quests=$TOTAL_QUESTS");
        print ("3After change game state\n");
        print ("Done change game state...check_if_won44\n");
    }
    print ("check_if_won666 ($reason)\n");
}

sub get_quest_button
{
    my $q = $_ [0];
    my $qq = $QUEST_OUTCOMES {$q};
    if ($qq =~ m/Fail/img)
    {
        return $FAIL_BUTTON;
    }
    if ($qq =~ m/Success/img)
    {
        return $SUCCESS_BUTTON;
    }
    return $NULL_BUTTON;
}

sub get_amulet_button
{
    my $q = $_ [0];
    my $qq = $AMULET_OUTCOMES {$q};
    if ($qq =~ m/..../img)
    {
        return $AMULET_BUTTON;
    }
    return $NULL_BUTTON;
}


sub increment_the_number_of_rounds
{
    $QUEST_NUMBER++;
    if ($QUEST_NUMBER > $TOTAL_QUESTS)
    {
        change_game_state ($STATE_GAME_FINISHED, 1, "increment_num_rounds");
        check_if_won ("increment_rounds");
        $QUEST_NUMBER = $TOTAL_QUESTS;
    }
    check_if_won ("increment_rounds");
}

sub get_quest_number
{
    return $QUEST_NUMBER;
}

sub force_needs_refresh
{
    my $reason = $_ [0];
    my $i = 0;
    add_to_debug (" IN FORCING REFRESH - $reason\n");
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

sub is_role_bad
{
    my $role = $_ [0];
    my $is_bad = 1;

    if ($role eq $APPRENTICE || $role eq $ARCHDUKE ||
        $role eq $ARTHUR || $role eq $CLERIC ||
        $role eq $DUKE || $role eq $GENERIC_GOOD ||
        $role eq $RELUCTANT_LEADER || $role eq $SABOTEUR ||
        $role eq $SENTINEL || $role eq $TROUBLEMAKER ||
        $role eq $YOUTH)
    {
        $is_bad = 0;
    }
    return $is_bad;
}

sub set_who_knows_who_id_id_good_or_bad_only
{
    my $id1 = $_ [0];
    my $id2 = $_ [1];

    print ("Setting that $id1 knows $id2!!!\n");
    print (" $id2 is - " . get_character_role ($id2));
    if (is_role_bad (get_character_role ($id2)))
    {
        $NOT_HIDDEN_INFO {"$id1 knows $id2 is bad"} = 1;
    }
    else
    {
        $NOT_HIDDEN_INFO {"$id1 knows $id2 is good"} = 1;
    }
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
    print ("NEW_GAME HERE\n"); 

    my %new_NOT_HIDDEN_INFO;
    %NOT_HIDDEN_INFO = %new_NOT_HIDDEN_INFO;
    print ("4After change game state\n");
    reset_game ();
    $num_players_in_game = $num_players_in_lobby;
    $who_is_leader = -1;
    $who_is_amulet = -1;
    my %new_BEEN_CHECKED_BY_AMULET;
    %BEEN_CHECKED_BY_AMULET = %new_BEEN_CHECKED_BY_AMULET;
    print ("22 NEW_GAME HERE\n"); 
    my %new_HAS_BEEN_LEADER;
    %HAS_BEEN_LEADER = %new_HAS_BEEN_LEADER;
    my %new_HAS_HAD_AMULET;
    %HAS_HAD_AMULET = %new_HAS_HAD_AMULET;
    my %new_BEEN_CHECKED_BY_AMULET;
    %BEEN_CHECKED_BY_AMULET = %new_BEEN_CHECKED_BY_AMULET;
    $THE_ACCUSED = "";

    print ("33 NEW_GAME HERE\n"); 
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
    $COUNTS_OF_ROLES {$MORGAN_LE_FAY} = 1;
    print ("44 NEW_GAME HERE\n"); 

    if ($num_players_in_game == 4)
    {
        $COUNTS_OF_ROLES {$GENERIC_GOOD} = 2;
        $COUNTS_OF_ROLES {$SCION} = 1;
        $TEMPLATE_LAYOUT = $PLAYER_LAYOUT_4;
        $num_players_on_quests {1} = 2;
        $num_players_on_quests {2} = 3;
        $num_players_on_quests {3} = 2;
        $num_players_on_quests {4} = 3;
        $num_amulets {1} = 0;
        $num_amulets {2} = 0;
        $num_amulets {3} = 0;
        $num_amulets {4} = 0;
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
        $num_players_on_quests {5} = 3;
        $num_amulets {1} = 0;
        $num_amulets {2} = 0;
        $num_amulets {3} = 0;
        $num_amulets {4} = 0;
        $num_amulets {5} = 0;
        $TOTAL_QUESTS = 4;
        $NUMBER_FAILS_NEEDED = 3;
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
        $num_amulets {1} = 0;
        $num_amulets {2} = 1;
        $num_amulets {3} = 0;
        $num_amulets {4} = 0;
        $num_amulets {5} = 0;
        $TOTAL_QUESTS = 5;
        $NUMBER_FAILS_NEEDED = 3;
    }
    print ("$TOTAL_QUESTS << total quests qqq vs  $num_players_in_game zzz\n"); 
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
        $num_amulets {1} = 0;
        $num_amulets {2} = 1;
        $num_amulets {3} = 1;
        $num_amulets {4} = 0;
        $num_amulets {5} = 0;
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
        $num_amulets {1} = 0;
        $num_amulets {2} = 1;
        $num_amulets {3} = 1;
        $num_amulets {4} = 1;
        $num_amulets {5} = 0;
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
        $num_amulets {1} = 0;
        $num_amulets {2} = 1;
        $num_amulets {3} = 1;
        $num_amulets {4} = 1;
        $num_amulets {5} = 0;
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
        $num_amulets {1} = 0;
        $num_amulets {2} = 1;
        $num_amulets {3} = 1;
        $num_amulets {4} = 1;
        $num_amulets {5} = 0;
        $TOTAL_QUESTS = 5;
        $NUMBER_FAILS_NEEDED = 3;
    }

    # Setup the players..
    setup_players ();
    $THE_ACCUSED = "";

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

    change_game_state ($STATE_AWAITING_QUEST, 1, "new_game");
    if ($IN_DEBUG_MODE)
    {
        $QUEST_NUMBER = 0;
        set_leader (0);
    }
    else
    {
        $QUEST_NUMBER = 0;
        set_leader (int (rand ($num_players_in_game)));
    }

 
    $QUEST_NUMBER = 1;

    force_needs_refresh("new_game");
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
    $who_is_amulet = -1;
    $GAME_WON = 0;
    $NUM_EXPOSED_CARDS = 0;
    $CHANGE_OF_ROUND = 0;
    $QUEST_NUMBER = 1;
    my %newQUEST_OUTCOMES;
    %QUEST_OUTCOMES = %newQUEST_OUTCOMES;
    my %newAMULET_OUTCOMES;
    %AMULET_OUTCOMES = %newAMULET_OUTCOMES;
    $AMULET_OUTCOMES_NUM = 1;
    change_game_state ($STATE_AWAITING_QUEST, 1, "reset_game");
    print ("5After change game state\n");
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
    force_needs_refresh("reset_game");
    #add_to_debug ("Game reset");
    my %new_already_shuffled;
    my %new_NOT_HIDDEN_INFO;
    %NOT_HIDDEN_INFO = %new_NOT_HIDDEN_INFO;
    $START_OF_NEW_ROUND = 0;
    my %new_HAS_BEEN_LEADER;
    %HAS_BEEN_LEADER = %new_HAS_BEEN_LEADER;
    my %new_HAS_HAD_AMULET;
    %HAS_HAD_AMULET = %new_HAS_HAD_AMULET;
    my %new_BEEN_CHECKED_BY_AMULET;
    %BEEN_CHECKED_BY_AMULET = %new_BEEN_CHECKED_BY_AMULET;
    $THE_ACCUSED = "";
    $GAME_STATES = "";
    return $out;
}

sub simulate_game
{
    # Add simulated users..
    my $num_users = $_ [0];
    add_new_user ("name=Aaron_bot", "192.155.155.150", 1);
    add_new_user ("name=Bob_Bobberson_bot", "192.156.155.150", 1);
    add_new_user ("name=Charlie_bot", "192.165.155.150", 1);
    #$IN_DEBUG_MODE = 1;
    if ($num_users > 4) { add_new_user ("name=Donquil_bot", "192.185.155.150", 1); }
    if ($num_users > 5) { add_new_user ("name=Eragon_bot", "193.155.155.150", 1); }
    if ($num_users > 6) { add_new_user ("name=Caesar_bot", "194.155.155.150", 1); }
    if ($num_users > 7) { add_new_user ("name=Gerry_bot", "195.155.155.150", 1); }
    if ($num_users > 8) { add_new_user ("name=Gaius_bot", "197.155.155.150", 1); }
    if ($num_users > 9) { add_new_user ("name=Julius_bot", "198.155.155.150", 1); }
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

sub get_template_quest_outcome
{
    my $id = $_ [0];
    if ($id == 1) { return "QUEST1_BUTTON"; }
    if ($id == 2) { return "QUEST2_BUTTON"; }
    if ($id == 3) { return "QUEST3_BUTTON"; }
    if ($id == 4) { return "QUEST4_BUTTON"; }
    if ($id == 5) { return "QUEST5_BUTTON"; }
}

sub get_template_amulet_outcome
{
    my $id = $_ [0];
    if ($id == 1) { return "AMULET1_BUTTON"; }
    if ($id == 2) { return "AMULET2_BUTTON"; }
    if ($id == 3) { return "AMULET3_BUTTON"; }
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
    print (" ###### NOT_HIDDEN:::" . join (",", sort keys (%NOT_HIDDEN_INFO)));
    if (defined ($NOT_HIDDEN_INFO {"$this_player_id knows $id"}) || $this_player_id == $id || $IN_DEBUG_MODE)
    {
        $known_to_user = $NOT_HIDDEN_INFO {"$this_player_id knows $id"};
        $hidden_identity = get_character_role ($id);
        print ("$this_player_id knows $id\n");
    }
    elsif (defined ($NOT_HIDDEN_INFO {"$this_player_id knows $id is bad"}))
    {
        print (" ###### $this_player_id knows $id is bad\n");
        $hidden_identity = $EVIL;
    }
    elsif (defined ($NOT_HIDDEN_INFO {"$this_player_id knows $id is good"}))
    {
        print (" ###### $this_player_id knows $id is good\n");
        $hidden_identity = $GOOD;
    }
    else
    {
        print ("  >>###### $this_player_id does not know $id\n");
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

sub add_quest_button
{
    my $quest_num = $_ [0];
    my $table = $_ [1];
    my $button_template = get_template_quest_outcome ($quest_num);
    my $button = get_quest_button ($quest_num);

    $table =~ s/$button_template/$button/img;
    return $table;
}

sub add_amulet_button
{
    my $amulet_num = $_ [0];
    my $table = $_ [1];
    my $button_template = get_template_amulet_outcome ($amulet_num);
    my $button = get_amulet_button ($amulet_num);

    $table =~ s/$button_template/$button/img;
    return $table;
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

    $current_table_for_player = add_quest_button (1, $current_table_for_player);
    $current_table_for_player = add_quest_button (2, $current_table_for_player);
    $current_table_for_player = add_quest_button (3, $current_table_for_player);
    $current_table_for_player = add_quest_button (4, $current_table_for_player);
    $current_table_for_player = add_quest_button (5, $current_table_for_player);

    $current_table_for_player = add_amulet_button (1, $current_table_for_player);
    $current_table_for_player = add_amulet_button (2, $current_table_for_player);
    $current_table_for_player = add_amulet_button (3, $current_table_for_player);

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
    my $roles;
    foreach $role (sort @player_roles)
    {
        $all_characters .= get_small_image (get_image_from_role ($role), 175);
        $roles .= ",$role";
    }
    return $all_characters; # . "&nbsp;$roles";
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
        
        $o .= "Quest $q result was:  $QUEST_OUTCOMES{$q} (for Quest#$q -- Had $num_players_on_quests{$q} questers)<br>";
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

sub get_amulet_for_current_quest
{
    #if ($IN_DEBUG_MODE)
    #{
    #    return 1;
    #}
    return ($num_amulets {$QUEST_NUMBER});
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
        $out .= "You (" . get_player_name ($id) . ") are: " . get_small_image (get_character_image($id), 115) . " INTERACTION_HOLDER";

        my $num_questers = get_players_for_current_quest ();
        if ($STATE_OF_ROUND ne $STATE_GOODS_LAST_CHANCE && $STATE_OF_ROUND ne $STATE_GAME_FINISHED)
        {
            $out .= "<br><font size=+1 color=darkblue>" . get_player_name ($who_is_leader) . " is the leader for the next quest of $num_questers!</font>\n";
        }
        elsif ($STATE_OF_ROUND eq $STATE_GOODS_LAST_CHANCE)
        {
            $out .= "<br><font size=+2 color=darkblue>This is Good's last chance to win!</font><br>$THE_ACCUSED<br>If *all* the evil characters and *only* the evil characters are pointed at by the good guys, then good wins the day!<br>";
            $interaction = "<br>Alert!! This is good's last chance to win.  Accuse two (2) players of being bad";
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
                    my $id_of_accused = get_player_id_from_name ($name);
                    # Can't accuse yourself..
                    if ($id != $id_of_accused)
                    {
                        $out .= "\n<input type=\"checkbox\" id=\"ACCUSED_$id_of_accused\" name=\"ACCUSED_$id_of_accused\" value=\"$name\" onchange=\"last_chance_accuse(2)\"> <label for=\"ACCUSED_$id_of_accused\">Accuse $name of badness</label><br>";
                    }
                    $i++;
                }

                $out .= "<input id=\"submitlastchance\" type=\"submit\" value=\"Submit Accused\" disabled></form>";

            }
            $out .= "</div>";


        }
        elsif ($STATE_OF_ROUND eq $STATE_GAME_FINISHED)
        {
            $out .= "<br><font size=+2 color=darkblue>Game has finished!</font><br>" . get_current_quests_outcomes () . "<br>" . prettify_accused () . "<br><br>If *all* the evil characters and *only* the evil characters are pointed at, then good wins the day!<br>"; #$GAME_STATES";
            return $out;
        }

        if ($id == $who_is_leader && $STATE_OF_ROUND eq $STATE_AWAITING_QUEST)
        {
            $interaction = "<br>Alert!! You are the leader.  You have to put $num_questers players on the next quest (Quest #" . get_quest_number() . ").  Choose one player to get the magic token (they can't fail the quest)";
            $out .= "<script>function check_questers(numExpected, numMagic){var cbs = document.getElementsByTagName(\"input\"), magic = 0, count = 0; for (var i=0; i<cbs.length; i++) { if (cbs[i].type === \"checkbox\" && cbs[i].checked === true){ count++; } if (cbs[i].type === \"radio\" && cbs[i].checked === true){ magic++;}} document.getElementById(\"submitnewquest\").disabled=true; if (numExpected == count && numMagic == magic) { document.getElementById(\"submitnewquest\").disabled=false; }}</script>\n<br>";
            $out .= "<div width=300 style=\"background-image: url('q_images/evil_indicator.jpg'); width:300px;\">";
            $out .= "<form action=\"/Quest/set_next_on_quest\">";
            $out .= "<br><font color=blue>Check " . ($num_questers - 1) . " quester/s below,</font><br>";
            my $name;
            my $i = 1;
            my $radio = "";
            foreach $name (@player_names)
            {
                $out .= "\n<input type=\"checkbox\" id=\"QUESTER_$i\" name=\"QUESTER_$i\" value=\"$name\" onchange=\"document.getElementById('QUESTER_MAGIC_$i\').checked = false;check_questers(" . ($num_questers-1) . ", 1)\"> <label for=\"QUESTER_$i\">Add $name to the Quest</label><br>";
                $radio .= "\n<input type=\"radio\" id=\"QUESTER_MAGIC_$i\" name=\"QUESTER_MAGIC\" value=\"$name\" onclick=\"document.getElementById('QUESTER_$i\').checked = false;check_questers(" . ($num_questers-1) . ", 1)\"> <label for=\"QUESTER_MAGIC_$i\">Add $name with the 'Magic Token'</label><br>";
                $i++;
            }

            $out .= "<br><font color=blue>and then add an extra person with the" . get_small_image ($MAGIC_TOKEN_IMAGE, 75) . ".</font><br>";
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
        $out .= "$STATE_OF_ROUND " . join (",", keys (%AWAITING_QUESTERS));
    }

    if (defined ($AWAITING_QUESTERS {$id}) && $AWAITING_QUESTERS {$id} >= 1 && $STATE_OF_ROUND eq $STATE_AWAITING_QUEST_RESULTS)
    {
        my $with_magic_token = 0;
        if ($AWAITING_QUESTERS {$id} == 1)
        {
            $interaction = "<br>Alert!! You can vote now";
        }
        elsif ($AWAITING_QUESTERS {$id} == 2)
        {
            $interaction = "<br>Alert!! You can vote now.  You have the Magic token which means you can't fail unless your identity says you can ignore it or you must fail the quest in some other way";
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

    if ($id == $who_is_leader && $STATE_OF_ROUND eq $STATE_AWAITING_AMULET && get_amulet_for_current_quest () > 0)
    {
        $interaction = "<br>Alert!! Pick who will have the amulet";
        $out .= "<script>function check_amulet(numExpected){ var inputElems = document.getElementsByTagName(\"input\"), count = 0; for (var i=0; i<inputElems.length; i++) { if (inputElems[i].type === \"checkbox\" && inputElems[i].checked === true){ count++; } } document.getElementById(\"new_amulet_holder\").disabled=true; if (numExpected == count) { document.getElementById(\"new_amulet_holder\").disabled=false; }}</script>\n<br>";
        $out .= "<br>Select the next amulet holder and press 'Submit New Amulet Holder':<br>";
        $out .= "<div width=300 style=\"background-image: url('q_images/light_amulet.png'); width:300px;\">";
        $out .= "<form action=\"/Quest/next_amulet_chosen\">";
        my $name;
        my $i = 1;
        foreach $name (@player_names)
        {
            my $pot_amulet_id = get_player_id_from_name ($name);
            if (!defined ($HAS_BEEN_LEADER {$name}) && !defined ($HAS_HAD_AMULET {$name}))
            {
                $out .= "\n<input type=\"checkbox\" id=\"AMULET_$pot_amulet_id\" name=\"AMULET_$pot_amulet_id\" value=\"$name\" onchange=\"check_amulet(1)\"> <label for=\"AMULET_$pot_amulet_id\">Set $name to have the next amulet</label><br>";
            }
            $i++;
        }

        $out .= "<input id=\"new_amulet_holder\" type=\"submit\" value=\"Submit New Amulet Holder\" disabled></form>";
        $out .= "</div>";
    }

    if ($id == $who_is_leader && $STATE_OF_ROUND eq $STATE_AWAITING_NEXT_LEADER)
    {
        $interaction = "<br>Alert!! You must pick the next leader now";
        $out .= "<script>function check_leader(numExpected){ var inputElems = document.getElementsByTagName(\"input\"), count = 0; for (var i=0; i<inputElems.length; i++) { if (inputElems[i].type === \"checkbox\" && inputElems[i].checked === true){ count++; } } document.getElementById(\"new_leader\").disabled=true; if (numExpected == count) { document.getElementById(\"new_leader\").disabled=false; }}</script>\n<br>";
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

        $out .= "<input id=\"new_leader\" type=\"submit\" value=\"Submit New Leader\" disabled></form>";
        $out .= "</div>";
    }

    if ($id == $who_is_amulet && $STATE_OF_ROUND eq $STATE_AWAITING_AMULET_RESULT)
    {
        $interaction = "<br>Alert!! You have the amulet. Pick someone to find out if they're evil or not!";
        $out .= "<script>function amulet_check(numExpected){ var inputElems = document.getElementsByTagName(\"input\"), count = 0; for (var i=0; i<inputElems.length; i++) { if (inputElems[i].type === \"checkbox\" && inputElems[i].checked === true){ count++; } } document.getElementById(\"checkamulet\").disabled=true; if (numExpected == count) { document.getElementById(\"checkamulet\").disabled=false; }}</script>\n<br>";
        $out .= "<br>Select whom you wish to see is bad or good then press 'Submit Check If Bad':<br>";
        $out .= "<div width=350 style=\"background-image: url('q_images/light_amulet.png'); width:350px;\">";
        $out .= "<form action=\"/Quest/amulet_check\">";
        my $name;
        my $i = 1;
        foreach $name (@player_names)
        {
            my $check_amulet_id = get_player_id_from_name ($name);
            if (!defined ($BEEN_CHECKED_BY_AMULET {$check_amulet_id}) && !defined ($HAS_HAD_AMULET {$check_amulet_id}))
            {
                $out .= "\n<input type=\"checkbox\" id=\"CHECK_AMULET_$check_amulet_id\" name=\"CHECK_AMULET_$check_amulet_id\" value=\"$name\" onchange=\"amulet_check(1)\"> <label for=\"CHECK_AMULET_$check_amulet_id\">Check if $name is bad or not..</label><br>";
            }
            $i++;
        }

        $out .= "<input id=\"checkamulet\" type=\"submit\" value=\"Check if they're bad!\" disabled></form>";
        $out .= "</div>";
    }

    if ($STATE_OF_ROUND eq $STATE_AWAITING_QUEST_RESULTS)
    {
        $out .= handle_quest_voting ();
    }

    $out .= get_board ($IP) . "<br>";
    $out .= "Players=$num_players_in_game. Characters in game:" . get_all_character_roles () . "<br>";
    $out .= get_current_quests_outcomes () . "<br>";

    if ($IN_DEBUG_MODE)
    {
        $out .= "NOT_HIDDEN:::" . join (",", sort keys (%NOT_HIDDEN_INFO));
    }

    if ($interaction =~ m/...../)
    {
        $interaction = "<font color=darkgreen size=+2>$interaction</font><br>";
    }
    $out =~ s/INTERACTION_HOLDER/$interaction/;
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
    $txt .= "    var numseconds = 5;" . "\n";
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
        force_needs_refresh ("chat_message");

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

sub handle_quest_voting
{
    my $done_voting;
    my $not_done_voting;
    my $x;
    my $finished_voting = 1;
    
    foreach $x (sort keys (%AWAITING_QUESTERS))
    {
        if ($x eq $MAGIC_TOKEN)
        {
            $done_voting .= ": ($x>>" . $AWAITING_QUESTERS{$x} . ")";
        }
        elsif ($AWAITING_QUESTERS {$x} == 0)
        {
            $done_voting .= ": ($x>>" . get_player_name ($x) . ")";
        }
        elsif ($AWAITING_QUESTERS {$x} >= 1)
        {
            if (is_bot (get_player_name ($x), $x, "is_bot_to_vote"))
            {
                $VOTING_RESULTS {$x} = get_vote_from_bot ($x, 0);
                $AWAITING_QUESTERS {$x} = 0;
                print ("AWAITING_QUESTERS << Adding $x to 0 - 2182 line \n");
                $done_voting .= ": " . get_player_name ($x);
            }
            else
            {
                $not_done_voting .= ": " . get_player_name ($x);
                $finished_voting = 0;
            }
        }
    }

    my $out = "Awaiting results of votes!<br>Already voted:$done_voting<br>Yet to vote: $not_done_voting<br>" . join (",", keys (%AWAITING_QUESTERS));
    if ($finished_voting)
    {
        my $num_failed_votes;
        my $num_success_votes;
        foreach $out (sort keys (%VOTING_RESULTS))
        {
            if ($VOTING_RESULTS{$out} == $BAD_VOTE)
            {
                $num_failed_votes++;
            }
            elsif ($VOTING_RESULTS{$out} == $GOOD_VOTE)
            {
                $num_success_votes++;
            }
        }

        if ($num_failed_votes == 0)
        {
            $QUEST_OUTCOMES {get_quest_number()} = "Success (Leader was " . get_player_name ($who_is_leader) . " People on quest: " . $done_voting . ")";
            print ("QUEST - JUST DID SUCCESS: " . $QUEST_OUTCOMES {get_quest_number()} . " ccc " . get_quest_number());
        }
        else
        {
            $QUEST_OUTCOMES {get_quest_number()} = "Fail ($num_failed_votes) (Leader was " . get_player_name ($who_is_leader) . " People on quest: $done_voting)";
            print ("QUEST - JUST DID FAIL: " . $QUEST_OUTCOMES {get_quest_number()} . " ccc " . get_quest_number());
        }

        if (get_amulet_for_current_quest () > 0)
        {
            change_game_state ($STATE_AWAITING_AMULET, 0, "amulet_for_quest");
            print ("6After change game state\n");
        }
        else
        {
            change_game_state ($STATE_AWAITING_NEXT_LEADER, 0, "new_quest_leader");
            print ("7After change game state\n");
        }

        $out .= "<br>Voting just finished. Result was: " .  $QUEST_OUTCOMES {get_quest_number()} . "<br>Please press F5 to refresh manually!";
    }
    return $out;
}

sub handle_bot_choose_next_leader
{
    my $num_leader;
    my $only_bots = 1;
    for ($num_leader = 0; $num_leader < 1; $num_leader++)
    {
        my $pot_leader_id = int (rand ($num_players_in_game));
        print "hbcnl: Quest has been " . get_quest_number() . " $pot_leader_id\n";
        if (!defined ($HAS_BEEN_LEADER {$pot_leader_id}))
        {
            $HAS_BEEN_LEADER {$pot_leader_id} = 1;
            print ("  >> BOT set new leader $pot_leader_id --> is_bot?? = " . is_bot (get_player_name ($pot_leader_id), $pot_leader_id, "next_leader") . "\n");
            set_leader ($pot_leader_id);

            # Handle $pot_leader_id being a bot..
            if (is_bot (get_player_name ($pot_leader_id), $pot_leader_id, "next_leader"))
            {
                handle_bot_being_leader ($pot_leader_id, "handle-bot_choose_next_leader");
                force_needs_refresh ("next leader chosen");
                write_to_socket (\*CLIENT, "", "", "redirect");
                next;
            }
        }
        else
        {
            $num_leader--;
        }
    }
}

sub handle_bot_being_leader
{
    my $next_leader_id = $_ [0];
    my $reason = $_ [1];
    print (" handle_bot_being_leader => $reason\n");

    print (get_player_name ($next_leader_id) . " <<< BOT IS LEADER !!!\n");
    if (is_bot (get_player_name ($next_leader_id), $next_leader_id, "handle_bot_being_leader"))
    {
        # Bot was chosen as leader
        change_game_state ($STATE_AWAITING_QUEST_RESULTS, 1, "bot_is_leader");
        print ("8After change game state\n");

        my %new_AWAITING_QUESTERS;
        %AWAITING_QUESTERS = %new_AWAITING_QUESTERS;
        print ("AWAITING_QUESTERS << resetting line 2222\n");
        my %new_VOTING_RESULTS;
        %VOTING_RESULTS = %new_VOTING_RESULTS;

        my $num_questers;
        my $only_bots = 1;
        for ($num_questers = 0; $num_questers < get_players_for_current_quest () - 1; $num_questers++)
        {
            my $pot_id = int (rand ($num_players_in_game));
            if (!defined ($AWAITING_QUESTERS {$pot_id}))
            {
                $AWAITING_QUESTERS {$pot_id} = 1;
                print ("AWAITING_QUESTERS << set $pot_id to 1 resetting line 2234\n");
                print ("  >> BOT was leader - put on $pot_id\n");

                # Handle $pot_id being a bot..
                if (is_bot (get_player_name ($pot_id), $pot_id, "handle_bot_handle_vote.."))
                {
                    $VOTING_RESULTS {$pot_id} = get_vote_from_bot ($pot_id, 0);
                    $AWAITING_QUESTERS {$pot_id} = 0;
                    print ("AWAITING_QUESTERS << set $pot_id to 0 resetting line 2242\n");
                }
                else
                {
                    $only_bots = 0;
                }
            }
            else
            {
                $num_questers--;
            }
        }

        for ($num_questers = 0; $num_questers < 1; $num_questers++)
        {
            my $pot_id = int (rand ($num_players_in_game));
            if (!defined ($AWAITING_QUESTERS {$pot_id}))
            {
                $AWAITING_QUESTERS {$pot_id} = 2;
                print ("AWAITING_QUESTERS << set $pot_id to 2 line 2261\n");
                print ("  >> BOT was leader - put on $pot_id with magic token\n");

                # Handle $pot_id being a bot..
                if (is_bot (get_player_name ($pot_id), $pot_id, "handle_bot_handle_vote.."))
                {
                    $VOTING_RESULTS {$pot_id} = get_vote_from_bot ($pot_id, 1);
                    $AWAITING_QUESTERS {$pot_id} = 0;
                    print ("AWAITING_QUESTERS << set $pot_id to 0 line 2269\n");
                    $AWAITING_QUESTERS {$MAGIC_TOKEN} = get_player_name ($pot_id);
                }
                else
                {
                    $only_bots = 0;
                }
            }
            else
            {
                $num_questers--;
            }
        }

        print ("BOT was leader - " . get_player_name ($next_leader_id) . " and put only bots on? $only_bots\n");
        handle_quest_voting ();

        if ($only_bots)
        {
            print (" Progress as only bots were on .. \n");
            if (get_amulet_for_current_quest () > 0)
            {
                print (" AMULET Progress as only bots were on .. \n");
                change_game_state ($STATE_AWAITING_AMULET, 1, "amulet_progress_bot");
                print ("9After change game state\n");
            }
            else
            {
                print (" NEXT LEADER Progress as only bots were on .. \n");
                change_game_state ($STATE_AWAITING_QUEST, 1, "next_leader_bot");
                print ("10After change game state\n");
                
                if (!is_game_over ())
                {
                    handle_bot_choose_next_leader ();
                }
            }
        }
        force_needs_refresh ("set next quest");
    }
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

        $CURRENT_QUEST_NAME = "";
        print (">>>\n\nread in: $txt\n"); 
        if ($txt =~ m/^Cookie.*?QUEST_NAME=(\w\w\w[\w_]+).*?(;|$)/im)
        {
            $CURRENT_QUEST_NAME = $1;
        }

        if ($txt =~ m/fname=(\w\w\w[\w_]+) HTTP/im)
        {
            $CURRENT_QUEST_NAME = $1;
        }

        # HTTP
        if (defined $BANNED_NAMES {$CURRENT_QUEST_NAME})
        {
            add_to_debug ("BANNING $CURRENT_QUEST_NAME atm");
            $CURRENT_QUEST_NAME = "";
            write_to_socket (\*CLIENT, get_game_state($client_addr), "", "redirect");
            next;
        }

        $CURRENT_QUEST_NAME =~ s/^(...........).*/$1/img;
        my $this_player_id = get_player_id_from_name ($CURRENT_QUEST_NAME);
        # HTTP
        if ($CURRENT_QUEST_NAME ne "" && get_player_id_from_name ($CURRENT_QUEST_NAME) == -1)
        {
            add_new_user ("name=$CURRENT_QUEST_NAME", $client_addr, 0);
            write_to_socket (\*CLIENT, get_game_state($client_addr), "", "noredirect");
            next;
        }

        # HTTP
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

        # HTTP
        if ($txt =~ m/.*force.*refresh.*/m)
        {
            force_needs_refresh ("called explicitly");
            write_to_socket (\*CLIENT, "", "", "redirect");
            next;
        }

        # HTTP
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

        # HTTP - bot..
        if (is_bot (get_player_name ($who_is_leader), $who_is_leader, "http_auto_next_leader") && $STATE_OF_ROUND eq $STATE_AWAITING_NEXT_LEADER)
        {
            if (!is_game_over ())
            {
                handle_bot_choose_next_leader ();
            }
            force_needs_refresh ("next leader chosen");
            write_to_socket (\*CLIENT, "", "", "redirect");
            next;
        }
        print ("\n====mmmm======\n$STATE_OF_ROUND, $who_is_leader, $THE_ACCUSED, \n========mmmm=======\n");
        
        # HTTP - bot..
        if (is_bot (get_player_name ($who_is_leader), $who_is_leader, "http_auto_next_leader") && $STATE_OF_ROUND eq $STATE_AWAITING_AMULET)
        {
            print ("11BEFORE change game state\n");
            change_game_state ($STATE_AWAITING_NEXT_LEADER, 1, "bot_amulet");
            print ("11After change game state\n");
            if (!is_game_over ())
            {
                handle_bot_choose_next_leader ();
            }
            force_needs_refresh ("next leader chosen");
            write_to_socket (\*CLIENT, "", "", "redirect");
            next;
        }
        
        # HTTP - bot..
        if ($STATE_OF_ROUND eq $STATE_GOODS_LAST_CHANCE)
        {
            my $p = 0;
            for ($p = 0; $p < $num_players_in_game; $p++)
            {
                if (is_bot (get_player_name ($p), $p, "bot_last_chance") && $AWAITING_LAST_ACCUSSED {$p} > 0)
                {
                    $AWAITING_LAST_ACCUSSED {$p} = 0;
                    $THE_ACCUSED .= "Player " . get_player_name ($p) . " was a bot so doesn't count in voting!";
                }
                print ("AUTO: LAST_CHANcE $THE_ACCUSED\n");
                $GAME_STATES .= "AUTO: LAST_CHANcE $THE_ACCUSED\n";
            }
        }
        print ("just after AUTO: LAST_CHANcE\n");


        # HTTP
        if ($txt =~ m/GET[^\n]*?new_user/mi)
        {
            add_to_debug ("REAL INSTANCE OF calling New_User: $txt with $client_addr<br>");
            my $ret = add_new_user ($txt, $client_addr, 0);
            write_to_socket (\*CLIENT, "Welcome!!<a href=\"\/\">Lobby or Game window<\/a>", "", "noredirect");
            next;
        }

        # HTTP
        if ($txt =~ m/.*boot.*person.*name=(\w\w\w[\w_]+)/mi)
        {
            my $person_to_boot = $1;
            boot_person ($person_to_boot);
            write_to_socket (\*CLIENT, "$person_to_boot was booted <a href=\"\/DONEDASBOOT\">Lobby or Game window<\/a>", "", "redirect");
            next;
        }

        # HTTP
        if ($txt =~ m/.*set_next_on_quest.*/m && $STATE_OF_ROUND eq $STATE_AWAITING_QUEST)
        {
            change_game_state ($STATE_AWAITING_QUEST_RESULTS, 0, "set_next_on_quest");
            print ("12After change game state\n");
            $NUMBER_QUEST_RESULTS = 0;
            my %new_AWAITING_QUESTERS;
            %AWAITING_QUESTERS = %new_AWAITING_QUESTERS;
            print ("AWAITING_QUESTERS << Resetting line 2471\n");
            my %new_VOTING_RESULTS;
            %VOTING_RESULTS = %new_VOTING_RESULTS;
            while ($txt =~ s/.*(set_next_on_quest.*)QUESTER_(\d+)/$1/s)
            {
                my $id_of_quester = $2 - 1;
                $AWAITING_QUESTERS {$id_of_quester} = 1;
                print ("AWAITING_QUESTERS << Adding $id_of_quester - 2472 line \n");
                $VOTING_RESULTS {$id_of_quester} = $NO_VOTE;
                print ("QUESTER was $id_of_quester\n");

                # Check if bot
                if (is_bot (get_player_name ($id_of_quester), $id_of_quester, "set_next_on_quest"))
                {
                    $VOTING_RESULTS {$id_of_quester} = get_vote_from_bot ($id_of_quester, 0);
                    $AWAITING_QUESTERS {$id_of_quester} = 0;
                    print ("AWAITING_QUESTERS << Adding $id_of_quester to 0 - 2481 line \n");
                }

                force_needs_refresh ("set next quest");
            }

            while ($txt =~ s/.*(set_next_on_quest.*)QUESTER_MAGIC=(\w+)/$1/s)
            {
                my $name_of_magic_token_holder = $2;
                my $id_of_quester = get_player_id_from_name ($name_of_magic_token_holder);
                $AWAITING_QUESTERS {$id_of_quester} = 2;
                print ("AWAITING_QUESTERS << Adding $id_of_quester to 2 - 2492 line \n");
                $AWAITING_QUESTERS {$MAGIC_TOKEN} = $name_of_magic_token_holder;
                $VOTING_RESULTS {$id_of_quester} = $NO_VOTE;

                # Check if bot
                if (is_bot (get_player_name ($id_of_quester), $id_of_quester, "setnext"))
                {
                    $VOTING_RESULTS {$id_of_quester} = get_vote_from_bot ($id_of_quester, 1);
                    $AWAITING_QUESTERS {$id_of_quester} = 0;
                    print ("AWAITING_QUESTERS << Adding $id_of_quester to 0 - 2501 line \n");
                }

                print ("MAGIC QUESTER was $id_of_quester\n");
                force_needs_refresh ("magic token quester");
            }
            write_to_socket (\*CLIENT, "", "", "redirect");


            next;
        }

        # HTTP
        if ($txt =~ m/.*last_chance_accuse.*/m && $STATE_OF_ROUND eq $STATE_GOODS_LAST_CHANCE && $AWAITING_LAST_ACCUSSED {get_player_id_from_name ($CURRENT_QUEST_NAME)} == 1)
        {
            while ($txt =~ s/.*(last_chance_accuse.*)ACCUSED_(\d+)/$1/s)
            {
                my $id_of_accused = $2;
                my $accused_name = get_player_name ($id_of_accused);
                force_needs_refresh ("last chance");
                $THE_ACCUSED .= "Player $CURRENT_QUEST_NAME accused $accused_name of being bad";
                $AWAITING_LAST_ACCUSSED {get_player_id_from_name ($CURRENT_QUEST_NAME)} = 0;
                print (">>ACCUSED=$THE_ACCUSED\n");
            }

            my $done = 1;
            my $already_done_done = 0;
            my $ala;
            foreach $ala (sort keys (%AWAITING_LAST_ACCUSSED))
            {
                if ($AWAITING_LAST_ACCUSSED {$ala} > 0)
                {
                    $done = 0;
                }
                if ($AWAITING_LAST_ACCUSSED {$ala} < 0)
                {
                    $already_done_done = 1;
                }
            }
            if ($done == 1 && !$already_done_done)
            {
                change_game_state ($STATE_GAME_FINISHED, 1, "last_chance_accuse");
                print ("13After change game state\n");
            }

            $THE_ACCUSED .= "<br>";
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
                    print ("AWAITING_QUESTERS << Adding $id_of_quester to 0 - 2562 line \n");

                    if ($success =~ m/success/img)
                    {
                        $VOTING_RESULTS {$id_of_quester} = $GOOD_VOTE;
                    }
                    elsif ($success =~ m/failure/img)
                    {
                        $VOTING_RESULTS {$id_of_quester} = $BAD_VOTE;
                    }
                    force_needs_refresh ("voted on quest");
                }
            }
            write_to_socket (\*CLIENT, "", "", "redirect");
            next;
        }

        # HTTP
        if ($txt =~ m/.*next_amulet_chosen.*AMULET_(\d+)/m && $STATE_OF_ROUND eq $STATE_AWAITING_AMULET)
        {
            my $next_amulet_id = $1;
            set_amulet ($next_amulet_id);

            change_game_state ($STATE_AWAITING_AMULET_RESULT, 1, "next_amulet_holder_chosen");
            print ("14After change game state\n");
            if (is_bot (get_player_name ($next_amulet_id), $next_amulet_id, "amulet"))
            {
                # Bot don't need to check ..
                change_game_state ($STATE_AWAITING_NEXT_LEADER, 1, "bot_next_amulet_holder_chosen");
                print ("14After change game state\n");
            }

            force_needs_refresh ("next amulet chosen");
            write_to_socket (\*CLIENT, "", "", "redirect");
            next;
        }

        # HTTP
        if ($txt =~ m/.*amulet_check.*CHECK_AMULET_(\d+)/m && $STATE_OF_ROUND eq $STATE_AWAITING_AMULET_RESULT)
        {
            my $check_amulet_id = $1;
            change_game_state ($STATE_AWAITING_NEXT_LEADER, 1, "amulet_check_done");
            print ("15After change game state\n");
            $BEEN_CHECKED_BY_AMULET {$check_amulet_id} = 1;
            $BEEN_CHECKED_BY_AMULET {get_player_name ($check_amulet_id)} = 1;
            set_who_knows_who_id_id_good_or_bad_only ($this_player_id, $check_amulet_id);
            $AMULET_OUTCOMES {$AMULET_OUTCOMES_NUM} = "amulet_result_done";
            $AMULET_OUTCOMES_NUM++;
            force_needs_refresh ("amulet result just done");
            write_to_socket (\*CLIENT, "", "", "redirect");
            next;
        }

        # HTTP
        if ($txt =~ m/.*next_leader_chosen.*LEADER_(\d+)/m && $STATE_OF_ROUND eq $STATE_AWAITING_NEXT_LEADER)
        {
            my $next_leader_id = $1;

            change_game_state ($STATE_AWAITING_QUEST, 1, "next_leader_33");
            print ("16After change game state\n");
            set_leader ($next_leader_id);

            if (is_bot (get_player_name ($next_leader_id), $next_leader_id, "next_leader"))
            {
                handle_bot_being_leader ($next_leader_id, "http_next_leader");
                force_needs_refresh ("next leader chosen");
                write_to_socket (\*CLIENT, "", "", "redirect");
                next;
            }

            force_needs_refresh ("next leader chosen");
            write_to_socket (\*CLIENT, "", "", "redirect");
            next;
        }

        # HTTP
        if ($txt =~ m/GET.*new_game.*/m)
        {
            new_game ();
            write_to_socket (\*CLIENT, "New game was just made <a href=\"\/\">Game window<\/a>", "", "redirect");
            next;
        }

        # HTTP
        if ($txt =~ m/GET.*simulate_game_(\d*).*/m)
        {
            simulate_game ($1);
            write_to_socket (\*CLIENT, "Simulated game was just made <a href=\"\/\">Game window<\/a>", "", "redirect");
            next;
        }

        # HTTP
        if ($txt =~ m/.*reset.*game.*/m)
        {
            write_to_socket (\*CLIENT, reset_game (), "", "redirect");
            next;
        }

        # HTTP
        if ($txt =~ m/.*add_chat_message.msg=(....+).HTTP/im)
        {
            add_to_debug ("CHAT WITH $1 <br>");
            write_to_socket (\*CLIENT, add_chat_message ($1), "", "redirect");
            print ($txt);
            next;
        }

        # HTTP
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
