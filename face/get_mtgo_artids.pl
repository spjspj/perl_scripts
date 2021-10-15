#!/usr/bin/perl
##
#   File : get_modo_artids.pl
#   Date : 12/Aug/2021
#   Author : spjspj
#   Purpose : Get the artid for each face art of each card from modo (mtgo)
#             this then goes into some form of image such as:
#             http://mtgoclientdepot.onlinegaming.wizards.com/Graphics/Cards/Pics/161922_typ_reg_sty_050.jpg
#              "" /00100_typ_reg_sty_001.jpg
#              "" /01440_typ_reg_sty_010.jpg
#              "" /102392_typ_reg_sty_010.jpg
#              "" /400603_typ_reg_sty_050.jpg
#              "" /413288_typ_reg_sty_020.jpg
#             This program expects that you've copied the relevant .xml files from an installation of mtgo 
#             into the current working directory for this perl script:
#                 For example: CARDNAME_STRING.xml, client_BNG.xml, 
#             Also, it expects to be running on windows
##  

use strict;
use LWP::Simple;
use POSIX qw(strftime);


# From xmage code - fix from MODO to XMAGE type set codes
my %fix_set_codes;
$fix_set_codes {"2U"} = "2ED";
$fix_set_codes {"3E"} = "3ED";
$fix_set_codes {"4E"} = "4ED";
$fix_set_codes {"5E"} = "5ED";
$fix_set_codes {"6E"} = "6ED";
$fix_set_codes {"7E"} = "7ED";
$fix_set_codes {"AL"} = "ALL";
$fix_set_codes {"AP"} = "APC";
$fix_set_codes {"AN"} = "ARN";
$fix_set_codes {"AQ"} = "ATQ";
$fix_set_codes {"CM1"} = "CMA";
$fix_set_codes {"DD3_DVD"} = "DD3DVD";
$fix_set_codes {"DD3_EVG"} = "DD3EVG";
$fix_set_codes {"DD3_GLV"} = "DD3GLV";
$fix_set_codes {"DD3_JVC"} = "DD3JVC";
$fix_set_codes {"DK"} = "DRK";
$fix_set_codes {"EX"} = "EXO";
$fix_set_codes {"FE"} = "FEM";
$fix_set_codes {"HM"} = "HML";
$fix_set_codes {"IA"} = "ICE";
$fix_set_codes {"IN"} = "INV";
$fix_set_codes {"1E"} = "LEA";
$fix_set_codes {"2E"} = "LEB";
$fix_set_codes {"LE"} = "LEG";
$fix_set_codes {"MI"} = "MIR";
$fix_set_codes {"MM"} = "MMQ";
$fix_set_codes {"MPS_KLD"} = "MPS";
$fix_set_codes {"NE"} = "NEM";
$fix_set_codes {"NE"} = "NMS";
$fix_set_codes {"OD"} = "ODY";
$fix_set_codes {"PR"} = "PCY";
$fix_set_codes {"PS"} = "PLS";
$fix_set_codes {"P2"} = "PO2";
$fix_set_codes {"PO"} = "POR";
$fix_set_codes {"PK"} = "PTK";
$fix_set_codes {"ST"} = "STH";
$fix_set_codes {"TE"} = "TMP";
$fix_set_codes {"CG"} = "UDS";
$fix_set_codes {"UD"} = "UDS";
$fix_set_codes {"GU"} = "ULG";
$fix_set_codes {"UZ"} = "USG";
$fix_set_codes {"VI"} = "VIS";
$fix_set_codes {"WL"} = "WTH";

# Main
{
    my $card = $ARGV [0];

    # Example: <CARDNAME_STRING_ITEM id='ID258_461'>Abandoned Sarcophagus</CARDNAME_STRING_ITEM>
    my $vals = `find /I "CARDNAME" *CARDNAME*STR*`;
    my %ids;
    my %set_names;
    my $count = 0;
    while ($vals =~ s/^.*CARDNAME_STRING_ITEM id=.(.*?).>(.*?)<\/CARDNAME_STRING.*\n//im)
    {
        $ids {$1} = $2;
        $count++;
    }
    print ("Finished reading $count names\n"); 


    #$vals = `find /I "<" *lient*`;
    `findstr /I "CARDNAME_STRING DIGITALOBJECT ARTID CLONE FRAMESTYLE " *lient* | find /I /V "_DO.xml" > 2021_out.txt`;

    my $current_artid = "";
    my $current_clone_id = "";
    my $current_doc_id = "";
    my $current_line = "";
    my $current_name = "";
    my $current_set = "";
    my $num_set = 1;
    my $make_sure_working = 0;
    my %docid_to_clone;

    open PROC, "type 2021_out.txt |";
    while (<PROC>)
    {
        chomp;
        my $line = $_;
        $line =~ m/^client_(.*)?\.xml/;
        $current_set = $1;
        
#<DigitalObject DigitalObjectCatalogID='DOC_26588'> *** IN
#   <ARTID value='100691'/> *** IN
#   <ARTIST_NAME_STRING id='ID257_266'/>
#   <CARDNAME_STRING id='ID258_12464'/> *** IN
#   <CARDNAME_TOKEN id='ID259_12464'/>
#   <CARDSETNAME_STRING id='ID516_103'/>
#   <CARDTEXTURE_NUMBER value='53176'/>
#   <COLLECTOR_INFO_STRING value='150/180'/>
#   <COLOR id='ID517_6'/>
#   <COLOR_IDENTITY id='ID518_4'/>
#   <CONVERTED_MANA_COST id='ID520_3'/>
#   <CREATURE_TYPE_STRING0 id='ID777_71'/>
#   <CREATURE_TYPEID0 id='ID521_12'/>
#   <FRAMESTYLE value='7'/>
#   <IS_CREATURE value='1'/>
#   <MANA_COST_STRING id='ID1811_114'/>
#   <POWER value='4'/>
#   <POWERTOUGHNESS_STRING value='4/5'/>
#   <RARITY_STATUS id='ID1818_3'/>
#   <REAL_ORACLETEXT_STRING id='ID1819_11686'/>
#   <SHOULDWORK value='1'/>
#   <SHROUD value='1'/>
#   <TOUGHNESS value='5'/>
#   <WATERMARK value='0'/>
#</DigitalObject>

        if ($line =~ m/<DigitalObject DigitalObjectCatalogID=['"]([^'"]+)['"]/)
        {
            $current_line = "$current_set;$1;";
            $current_doc_id = $1; 
        }
        if ($line =~ m/\s*<ARTID value="(\d+)"/)
        {
            $current_line .= "artid=$1;";
        }
        if ($line =~ m/CARDNAME_STRING id="([^"]+)"/)
        {
            $current_line = "$ids{$1};$current_line;($1)";
            $current_name = "$ids{$1}";
        }
        if ($line =~ m/CLONE_ID value="([^"]+)"/)
        {
            my $clone_id = $1;
            $current_line .= ";Clone=($clone_id)";
            $current_clone_id = $clone_id;
        }

        if ($line =~ m/<\/DigitalObject/)
        {
            if ($current_name =~ m/.+/ && $current_doc_id =~ m/.+/)
            {
                $docid_to_clone {$current_doc_id} = $current_name;
            }
                
            $make_sure_working ++;
            if ($make_sure_working > 1000)
            {
                $make_sure_working = 0;
                print ($current_line, " << current line (1000th line..)\n");
            }
            $current_line = "";
            $current_name = "";
            $current_clone_id = "";
            $current_doc_id = "";
        }
    }
    close PROC;
   
    # Run it again..
    #$vals = `findstr /I "CARDNAME_STRING DIGITALOBJECT ARTID CLONE FRAMESTYLE" *lient* | find /I /V "_DO.xml"`;

    $current_set = "";
    $num_set = 1;
    $current_artid = "";
    $current_clone_id = "";
    $current_doc_id = "";
    $current_line = "";
    $current_name = "";
    my %seen_artids;
    my $current_framestyle = "";

    my %framestyles;
    $framestyles {1} = "001";  # Pre-modern cards
    $framestyles {3} = "010";  # M15 cards
    $framestyles {31} = "010"; # New cards
    $framestyles {11} = "010"; # Avatars
    $framestyles {14} = "010"; # Tokens
    $framestyles {15} = "010"; # Tokens as well
    $framestyles {48} = "020"; # Full art lands??
    $framestyles {69} = "050"; # Full art lands??

#client_ZNR.xml:  <DigitalObject DigitalObjectCatalogID="DOC_83567">
#client_ZNR.xml:    <ARTID value="413288"/>
#client_ZNR.xml:    <CARDNAME_STRING id="ID2_7848"/>
#client_ZNR.xml:    <FRAMESTYLE value="48"/>
#client_ZNR.xml:  </DigitalObject>
#client_2XM.xml:  <DigitalObject DigitalObjectCatalogID="DOC_82780"> C:\Users\me\AppData\Local\Wizards of the Coast\Magic Online\Images\ArtInFrame\Tier1\160741_typ_reg_sty_050.jpg
#client_2XM.xml:    <ARTID value="160741"/>
#client_2XM.xml:    <CARDNAME_STRING id="ID2_7848"/>
#client_2XM.xml:    <FRAMESTYLE value="69"/>
#client_2XM.xml:  </DigitalObject>

    open PROC, "type 2021_out.txt |";
    while (<PROC>)
    {
        chomp;
        my $line = $_;
        $line =~ m/^client_(.*)?\.xml/;
        $current_set = $1;
        if (defined ($fix_set_codes {$current_set}))
        {
            $current_set = $fix_set_codes {$current_set};
        }
        
        if ($line =~ m/<DigitalObject DigitalObjectCatalogID="([^"]+)"/)
        {
            $current_line = "$current_set;$1;";
            $current_doc_id = $1; 
        }
        if ($line =~ m/\s*<ARTID value="(\d+)"/)
        {
            $current_line .= "artid=$1;";
            $current_artid = $1;
        }
        if ($line =~ m/CARDNAME_STRING id="([^"]+)"/)
        {
            $current_line = "$ids{$1};$current_line;($1)";
            $current_name = "$ids{$1}";
        }
        if ($line =~ m/CLONE_ID value="([^"]+)"/)
        {
            my $clone_id = $1;
            $current_line .= ";Clone=($clone_id)";
            $current_clone_id = $clone_id;
        }
        if ($line =~ m/FRAMESTYLE value="([^"]+)"/)
        {
            $current_framestyle = "$1";
            $current_framestyle = $framestyles {$current_framestyle};
        }

        if ($line =~ m/<\/DigitalObject/)
        {
            if ($docid_to_clone {$current_doc_id} =~ m/.+/) 
            {
                $current_name = "$docid_to_clone{$current_doc_id}";
            }
            if ($current_name =~ m/.+/ && $current_doc_id =~ m/.+/)
            {
                $docid_to_clone {$current_doc_id} = $current_name;
            }
            if ($current_name =~ m/^$/)
            {
                $current_name = $docid_to_clone {$current_clone_id};
            }
                
            if ($current_name =~ m/..*/ && $current_set =~ m/..*/ && $current_artid =~ m/..*/)
            {
                print ("$current_name;$current_set;$current_artid;$current_framestyle\n");
                # cut.pl statement..
                #   echo "1" | cut.pl stdin "http://mtgoclientdepot.onlinegaming.wizards.com/Graphics/Cards/Pics/00010_typ_reg_sty_001.jpg" "ME4\Badlands.jpg" wget_image
                if (!defined ($seen_artids {$current_artid}))
                {
                    $seen_artids {$current_artid} = "$current_set\\$current_name.jpg";
                    if ($current_artid < 10)
                    {
                        print ("  echo \"1\" | cut.pl stdin \"http://mtgoclientdepot.onlinegaming.wizards.com/Graphics/Cards/Pics/0000$current_artid" . "_typ_reg_sty_$current_framestyle.jpg\" \"$current_set\\$current_name.jpg\" wget_image\n");
                    }
                    if ($current_artid < 100)
                    {
                        print ("  echo \"1\" | cut.pl stdin \"http://mtgoclientdepot.onlinegaming.wizards.com/Graphics/Cards/Pics/000$current_artid" . "_typ_reg_sty_$current_framestyle.jpg\" \"$current_set\\$current_name.jpg\" wget_image\n");
                    }
                    elsif ($current_artid < 1000)
                    {
                        print ("  echo \"1\" | cut.pl stdin \"http://mtgoclientdepot.onlinegaming.wizards.com/Graphics/Cards/Pics/00$current_artid" . "_typ_reg_sty_$current_framestyle.jpg\" \"$current_set\\$current_name.jpg\" wget_image\n");
                    }
                    elsif ($current_artid < 10000)
                    {
                        print ("  echo \"1\" | cut.pl stdin \"http://mtgoclientdepot.onlinegaming.wizards.com/Graphics/Cards/Pics/0$current_artid" . "_typ_reg_sty_$current_framestyle.jpg\" \"$current_set\\$current_name.jpg\" wget_image\n");
                    }
                    else
                    {
                        print ("  echo \"1\" | cut.pl stdin \"http://mtgoclientdepot.onlinegaming.wizards.com/Graphics/Cards/Pics/$current_artid" . "_typ_reg_sty_$current_framestyle.jpg\" \"$current_set\\$current_name.jpg\" wget_image\n");
                    }
                }
                else
                {
                    print ("   copy \"$seen_artids{$current_artid}\" \"$current_set\\$current_name.jpg\"\n");
                }
            }

            $current_artid = "";
            $current_clone_id = "";
            $current_doc_id = "";
            $current_line = "";
            $current_name = "";
        }
    }
    close PROC;
}

#d:\perl_programs\modo>find /I "FRAMESTYLE"  *CLIENT* | find /I "Frame" | cut.pl stdin 0 0 countlines
#1 ====    <FRAMESTYLE value='24'/>
#1 ====    <FRAMESTYLE value='49'/>
#1 ====    <FRAMESTYLE value='50'/>
#1 ====    <FRAMESTYLE value='20'/>
#1 ====    <FRAMESTYLE value='30'/>
#3 ====    <FRAMESTYLE value='38'/>
#5 ====    <FRAMESTYLE value='8'/>
#5 ====    <FRAMESTYLE value='45'/>
#6 ====    <FRAMESTYLE value='41'/>
#7 ====    <FRAMESTYLE value='17'/>
#8 ====    <FRAMESTYLE value='37'/>
#9 ====    <FRAMESTYLE value='29'/>
#10 ====    <FRAMESTYLE value='25'/>
#11 ====    <FRAMESTYLE value='22'/>
#12 ====    <FRAMESTYLE value='40'/>
#14 ====    <FRAMESTYLE value='35'/>
#16 ====    <FRAMESTYLE value='26'/>
#16 ====    <FRAMESTYLE value='27'/>
#17 ====    <FRAMESTYLE value='51'/>
#19 ====    <FRAMESTYLE value='13'/>
#23 ====    <FRAMESTYLE value='52'/>
#23 ====    <FRAMESTYLE value='4'/>
#27 ====    <FRAMESTYLE value='36'/>
#32 ====    <FRAMESTYLE value='12'/>
#36 ====    <FRAMESTYLE value='18'/>
#37 ====    <FRAMESTYLE value='19'/>
#37 ====    <FRAMESTYLE value='48'/> << 20
#44 ====    <FRAMESTYLE value='43'/>
#45 ====    <FRAMESTYLE value='47'/>
#46 ====    <FRAMESTYLE value='9'/>
#54 ====    <FRAMESTYLE value='53'/>
#54 ====    <FRAMESTYLE value='54'/>
#54 ====    <FRAMESTYLE value='39'/>
#58 ====    <FRAMESTYLE value='5'/>
#60 ====    <FRAMESTYLE value='34'/>
#64 ====    <FRAMESTYLE value='6'/>
#69 ====    <FRAMESTYLE value='2'/>
#69 ====    <FRAMESTYLE value='42'/>
#75 ====    <FRAMESTYLE value='16'/>
#78 ====    <FRAMESTYLE value='7'/>
#85 ====    <FRAMESTYLE value='10'/>
#86 ====    <FRAMESTYLE value='23'/>
#91 ====    <FRAMESTYLE value='28'/>
#104 ====    <FRAMESTYLE value='46'/>
#121 ====    <FRAMESTYLE value='32'/>
#129 ====    <FRAMESTYLE value='33'/>
#141 ====    <FRAMESTYLE value='15'/>
#219 ====    <FRAMESTYLE value='14'/>
#234 ====    <FRAMESTYLE value='11'/>
#5130 ====    <FRAMESTYLE value='31'/>
#10676 ====    <FRAMESTYLE value='1'/>
#14080 ====    <FRAMESTYLE value='3'/>
