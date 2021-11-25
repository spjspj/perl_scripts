#!/usr/bin/perl
##
#   File : filter_magic.pl
#   Date : 10/Sept/2013
#   Author : spjspj
#   Purpose : Search through the xmage list of files
##

use strict;
use LWP::Simple;
use Socket;
use File::Copy;

my %all_cards;
my %card_names;
my %original_lines;
my %original_lines_just_card_names;
my %card_text;
my %card_cost;
my %card_type;
my %card_converted_cost;
my %all_cards_abilities;
my %expansion;

sub print_card
{
    my $card_to_check = $_ [0];
    my $cn = card_name ($card_to_check);
    my $ctype = card_type ($card_to_check);
    my $ctxt = card_text ($card_to_check);
    my $cc = card_cost ($card_to_check);
    my $ccc = card_converted_cost ($card_to_check);
    my $exp = expansion ($card_to_check);

    #print ("$card_to_check - $cn - $ctxt - $ctype ($cc,,,$ccc)\n");
    return ("$card_to_check - nm,,$cn - txt,,$ctxt - typ,,$ctype ($cc,,,$ccc) -- $exp");
}

# Filter for a sublist of cards in X (i.e. hand, deck, graveyard, exiled, named, tapped, type (artifact,sorcery,enchantment,equipment,creature), )
sub get_filtered_cards_advanced
{
    my $cards = $_ [0];
    my $has_minconvertedcost = $_ [1];
    my $has_maxconvertedcost = $_ [2];
    my $no_red = $_ [3];
    my $no_green = $_ [4];
    my $no_blue = $_ [5];
    my $no_black = $_ [6];
    my $no_white = $_ [7];
    my $no_uncoloured = $_ [8];
    my $use_full_format = $_ [9];
    my $use_block = $_ [10];
    my $use_unique = $_ [11];
    my $card_text = $_ [12];
    my $card_name = $_ [13];
    my $rating = $_ [14];
    my $order_by_rating = 0;
    my $ret;
    my %names_of_cards;
    if ($card_text eq "") { $card_text = ".*"; }
    if ($card_name eq "") { $card_name = ".*"; }
    if ($rating eq "") { $rating = ".*"; }

    if ($card_name =~ m/\|/ && $card_name !~ m/^\(/)
    {
        $card_name = "($card_name)";
    }

    if ($rating =~ m/\d/)
    {
        $order_by_rating = 1;
    }

    print ("has_minconvertedcost  $has_minconvertedcost\n");
    print ("has_maxconvertedcost  $has_maxconvertedcost\n");
    print ("no_red  $no_red\n");
    print ("no_green  $no_green\n");
    print ("no_blue  $no_blue\n");
    print ("no_black  $no_black\n");
    print ("no_white  $no_white\n");
    print ("no_uncoloured  $no_uncoloured\n");
    print ("use_full_format  $use_full_format\n");
    print ("use_block  $use_block\n");
    $card_text =~ s/%20/./img;
    print ("card_text  $card_text\n");
    print ("card_name  $card_name\n");
    print ("rating  '$rating'\n");
    print ("\n\n\n\n\n\nStarting checking all the cards...\n");

    my $c;
    my @filtered;
    my $i;
    my $count = 0;

    {
        my @c_nums;
        @c_nums = sort keys (%card_names);

        foreach $c (@c_nums)
        {
            my $xp = expansion ($c);
            #print("$c >> $use_full_format ??? $xp");

            if ($use_unique =~ m/true/i && defined ($names_of_cards {card_name ($c)}))
            {
                print ("Non unique >>> " . card_name ($c) . "\n");
                next;
            }
            #print ("\n");

            my $cc = card_cost ($c);

            # Must not have a color
            if ($no_red == 1 && $cc =~ m/\{[^\}]*r[^\}]*\}/i) { next; }
            if ($no_blue == 1 && $cc =~ m/\{[^\}]*u[^\}]*\}/i) { next; }
            if ($no_green == 1 && $cc =~ m/\{[^\}]*g[^\}]*\}/i) { next; }
            if ($no_black == 1 && $cc =~ m/\{[^\}]*b[^\}]*\}/i) { next; }
            if ($no_white == 1 && $cc =~ m/\{[^\}]*w[^\}]*\}/i) { next; }
            if ($no_uncoloured == 1 && $cc =~ m/\{[^\}]*\d+[^\}]*\}/i) { next; }

            # Must have a color
            if ($no_red == 2 && $cc !~ m/\{[^\}]*r[^\}]*\}/i) { next; }
            if ($no_blue == 2 && $cc !~ m/\{[^\}]*u[^\}]*\}/i) { next; }
            if ($no_green == 2 && $cc !~ m/\{[^\}]*g[^\}]*\}/i) { next; }
            if ($no_black == 2 && $cc !~ m/\{[^\}]*b[^\}]*\}/i) { next; }
            if ($no_white == 2 && $cc !~ m/\{[^\}]*w[^\}]*\}/i) { next; }
            if ($no_uncoloured == 2 && $cc !~ m/\{[^\}]*\d+[^\}]*\}/i) { next; }

            {
                if ((card_converted_cost ($c) >= $has_minconvertedcost || $has_minconvertedcost eq "") &&
                    (card_converted_cost ($c) <= $has_maxconvertedcost || $has_maxconvertedcost eq ""))
                {
                    my $cn = card_name ($c);
                    my $cn_condense = $cn;
                    $cn_condense =~ s/\W//g;
                    if ($cn =~ m/$card_name/i || $cn_condense =~ m/$card_name/i)
                    {
                        my $ct = card_text ($c);
                        my $ol = original_line ($c);
                        my $condense_ol = $ol;
                        $condense_ol =~ s/\W//g;
                        #print ("$card_name ---- CCcost=" . card_converted_cost ($c) . " --> Min,max = " . $has_minconvertedcost . "," . $has_maxconvertedcost . "\n");


                        $ct =~ s/\W//g;
                        if ($ct =~ m/$card_text/i || $ol =~ m/$card_text/i || $condense_ol =~ m/$card_text/i)
                        {
                            my $ol = original_line ($c);
                            my $exp = expansion ($c);
                            $ol =~ s/^([^\|]*)\|([^\|]*)\|(.*)/$1|$exp|$3/gim;
                            $ol .= $exp;
                            $ret .= "$ol\n";
                            $names_of_cards {card_name ($c)} = 1;
                            $count++;
                            if ($count % 100 == 0) { print ($count, "\n"); }
                            if ($count > 99990) { $ret .= "TOO MANY CARDS\n"; return $ret; }
                        }
                    }
                }
            }
            $i++;
        }
    }
    return $ret . "\nHave found $count cards\n";
}

sub original_line
{
    my $id = $_ [0];
    return ($original_lines {$id});
}

sub original_line_from_cardname
{
    my $id = $_ [0];
    return ($original_lines_just_card_names {$id});
}

sub card_name
{
    my $id = $_ [0];
    return ($card_names {$id});
}

sub card_text
{
    my $id = $_ [0];
    return ($card_text {$id});
}

sub card_cost
{
    my $id = $_ [0];
    return ($card_cost {$id});
}

sub card_converted_cost
{
    my $id = $_ [0];
    return ($card_converted_cost{$id});
}

sub card_type
{
    my $id = $_ [0];
    return ($card_type {$id});
}

sub expansion
{
    my $id = $_ [0];
    return ($expansion {$id});
}

sub expansion_trigraph
{
    my $expansion = $_ [0];

    # This part is from: c:\xmage_release\mage\Mage.Client\src\main\java\org\mage\plugins\card\dl\sources\WizardCardsImageSource.java
    if ($expansion =~ m/^Aether Revolt/i) { $expansion .= " [AER]"; }
    if ($expansion =~ m/^Alara Reborn/i) { $expansion .= " [ARB]"; }
    if ($expansion =~ m/^Alliances/i) { $expansion .= " [ALL]"; }
    if ($expansion =~ m/^Amonkhet/i) { $expansion .= " [AKH]"; }
    if ($expansion =~ m/^Anthologies/i) { $expansion .= " [ATH]"; }
    if ($expansion =~ m/^Antiquities/i) { $expansion .= " [ATQ]"; }
    if ($expansion =~ m/^Apocalypse/i) { $expansion .= " [APC]"; }
    if ($expansion =~ m/^Arabian Nights/i) { $expansion .= " [ARN]"; }
    if ($expansion =~ m/^Archenemy/i) { $expansion .= " [ARC]"; }
    if ($expansion =~ m/^Archenemy/i) { $expansion .= " [E01]"; }
    if ($expansion =~ m/^Archenemy: Nicol Bolas/i) { $expansion .= " [ANB]"; }
    if ($expansion =~ m/^Archenemy: Nicol Bolas/i) { $expansion .= " [E01]"; }
    if ($expansion =~ m/^Avacyn Restored/i) { $expansion .= " [AVR]"; }
    if ($expansion =~ m/^Battle Royale Box Set/i) { $expansion .= " [BRB]"; }
    if ($expansion =~ m/^Battle for Zendikar/i) { $expansion .= " [BFZ]"; }
    if ($expansion =~ m/^Battlebond/i) { $expansion .= " [BBD]"; }
    if ($expansion =~ m/^Beatdown Box Set/i) { $expansion .= " [BTD]"; }
    if ($expansion =~ m/^Betrayers of Kamigawa/i) { $expansion .= " [BOK]"; }
    if ($expansion =~ m/^Born of the Gods/i) { $expansion .= " [BNG]"; }
    if ($expansion =~ m/^Casual Supplements/i) { $expansion .= " [JMP]"; }
    if ($expansion =~ m/^Champions of Kamigawa/i) { $expansion .= " [CHK]"; }
    if ($expansion =~ m/^Chronicles/i) { $expansion .= " [CHR]"; }
    if ($expansion =~ m/^Classic Sixth Edition/i) { $expansion .= " [6ED]"; }
    if ($expansion =~ m/^Coldsnap/i) { $expansion .= " [CSP]"; }
    if ($expansion =~ m/^Commander 2013 Edition/i) { $expansion .= " [C13]"; }
    if ($expansion =~ m/^Commander 2014/i) { $expansion .= " [C14]"; }
    if ($expansion =~ m/^Commander 2015/i) { $expansion .= " [C15]"; }
    if ($expansion =~ m/^Commander 2016/i) { $expansion .= " [C16]"; }
    if ($expansion =~ m/^Commander 2017/i) { $expansion .= " [C17]"; }
    if ($expansion =~ m/^Commander 2018/i) { $expansion .= " [C18]"; }
    if ($expansion =~ m/^Commander Anthology 2018/i) { $expansion .= " [CM2]"; }
    if ($expansion =~ m/^Commander Anthology/i) { $expansion .= " [CMA]"; }
    if ($expansion =~ m/^Conflux/i) { $expansion .= " [CON]"; }
    if ($expansion =~ m/^Conspiracy: Take the Crown/i) { $expansion .= " [CN2]"; }
    if ($expansion =~ m/^Core Set 2019/i) { $expansion .= " [M19]"; }
    if ($expansion =~ m/^Core Set 2020/i) { $expansion .= " [M20]"; }
    if ($expansion =~ m/^Core Set 2021/i) { $expansion .= " [M21]"; }
    #if ($expansion =~ m/^Core Sets/i) { $expansion .= " [M13]"; }
    #if ($expansion =~ m/^Core Sets/i) { $expansion .= " [M19]"; }
    #if ($expansion =~ m/^Core Sets/i) { $expansion .= " [ORI]"; }
    if ($expansion =~ m/^Dark Ascension/i) { $expansion .= " [DKA]"; }
    if ($expansion =~ m/^Darksteel/i) { $expansion .= " [DST]"; }
    if ($expansion =~ m/^Deckmasters/i) { $expansion .= " [DKM]"; }
    if ($expansion =~ m/^Dissension/i) { $expansion .= " [DIS]"; }
    if ($expansion =~ m/^Dominaria/i) { $expansion .= " [DOM]"; }
    if ($expansion =~ m/^Double Masters/i) { $expansion .= " [2XM]"; }
    if ($expansion =~ m/^Dragon's Maze/i) { $expansion .= " [DGM]"; }
    if ($expansion =~ m/^Dragons of Tarkir/i) { $expansion .= " [DTK]"; }
    if ($expansion =~ m/^Duel Decks Anthology, Divine vs. Demonic/i) { $expansion .= " [DD3DVD]"; }
    if ($expansion =~ m/^Duel Decks Anthology, Elves vs. Goblins/i) { $expansion .= " [DD3EVG]"; }
    if ($expansion =~ m/^Duel Decks Anthology, Garruk vs. Liliana/i) { $expansion .= " [DD3GVL]"; }
    if ($expansion =~ m/^Duel Decks Anthology, Jace vs. Chandra/i) { $expansion .= " [DD3JVC]"; }
    if ($expansion =~ m/^Duel Decks/i) { $expansion .= " [DDU]"; }
    if ($expansion =~ m/^Duel Decks: Ajani vs. Nicol Bolas/i) { $expansion .= " [DDH]"; }
    if ($expansion =~ m/^Duel Decks: Blessed vs. Cursed/i) { $expansion .= " [DDQ]"; }
    if ($expansion =~ m/^Duel Decks: Divine vs. Demonic/i) { $expansion .= " [DDC]"; }
    if ($expansion =~ m/^Duel Decks: Elspeth vs. Kiora/i) { $expansion .= " [DDO]"; }
    if ($expansion =~ m/^Duel Decks: Elspeth vs. Tezzeret/i) { $expansion .= " [DDF]"; }
    if ($expansion =~ m/^Duel Decks: Elves vs. Goblins/i) { $expansion .= " [EVG]"; }
    if ($expansion =~ m/^Duel Decks: Elves vs. Inventors/i) { $expansion .= " [DDU]"; }
    if ($expansion =~ m/^Duel Decks: Garruk vs. Liliana/i) { $expansion .= " [DDD]"; }
    if ($expansion =~ m/^Duel Decks: Heroes vs. Monsters/i) { $expansion .= " [DDL]"; }
    if ($expansion =~ m/^Duel Decks: Izzet vs. Golgari/i) { $expansion .= " [DDJ]"; }
    if ($expansion =~ m/^Duel Decks: Jace vs. Chandra/i) { $expansion .= " [DD2]"; }
    if ($expansion =~ m/^Duel Decks: Jace vs. Vraska/i) { $expansion .= " [DDM]"; }
    if ($expansion =~ m/^Duel Decks: Knights vs. Dragons/i) { $expansion .= " [DDG]"; }
    if ($expansion =~ m/^Duel Decks: Merfolk vs. Goblins/i) { $expansion .= " [DDT]"; }
    if ($expansion =~ m/^Duel Decks: Mind vs. Might/i) { $expansion .= " [DDS]"; }
    if ($expansion =~ m/^Duel Decks: Nissa vs. Ob Nixilis/i) { $expansion .= " [DDR]"; }
    if ($expansion =~ m/^Duel Decks: Phyrexia vs. the Coalition/i) { $expansion .= " [DDE]"; }
    if ($expansion =~ m/^Duel Decks: Sorin vs. Tibalt/i) { $expansion .= " [DDK]"; }
    if ($expansion =~ m/^Duel Decks: Speed vs. Cunning/i) { $expansion .= " [DDN]"; }
    if ($expansion =~ m/^Duel Decks: Venser vs. Koth/i) { $expansion .= " [DDI]"; }
    if ($expansion =~ m/^Duel Decks: Zendikar vs. Eldrazi/i) { $expansion .= " [DDP]"; }
    if ($expansion =~ m/^Eighth Edition/i) { $expansion .= " [8ED]"; }
    if ($expansion =~ m/^Eldritch Moon/i) { $expansion .= " [EMN]"; }
    if ($expansion =~ m/^Eternal Masters/i) { $expansion .= " [EMA]"; }
    if ($expansion =~ m/^Eventide/i) { $expansion .= " [EVE]"; }
    if ($expansion =~ m/^Exodus/i) { $expansion .= " [EXO]"; }
    if ($expansion =~ m/^Expansions/i) { $expansion .= " [FEM]"; }
    if ($expansion =~ m/^Fallen Empires/i) { $expansion .= " [FEM]"; }
    if ($expansion =~ m/^Fate Reforged/i) { $expansion .= " [FRF]"; }
    if ($expansion =~ m/^Fifth Dawn/i) { $expansion .= " [5DN]"; }
    if ($expansion =~ m/^Fifth Edition/i) { $expansion .= " [5ED]"; }
    if ($expansion =~ m/^Fourth Edition/i) { $expansion .= " [4ED]"; }
    if ($expansion =~ m/^Friday Night Magic/i) { $expansion .= " [FNMP]"; }
    if ($expansion =~ m/^Friday Night Magic/i) { $expansion .= " [FNM]"; }
    if ($expansion =~ m/^From the Vault/i) { $expansion .= " [V17]"; }
    if ($expansion =~ m/^From the Vault: Angels (2015)/i) { $expansion .= " [V15]"; }
    if ($expansion =~ m/^From the Vault: Annihilation (2014)/i) { $expansion .= " [V14]"; }
    if ($expansion =~ m/^From the Vault: Dragons/i) { $expansion .= " [DRB]"; }
    if ($expansion =~ m/^From the Vault: Exiled/i) { $expansion .= " [V09]"; }
    if ($expansion =~ m/^From the Vault: Legends/i) { $expansion .= " [V11]"; }
    if ($expansion =~ m/^From the Vault: Lore (2016)/i) { $expansion .= " [V16]"; }
    if ($expansion =~ m/^From the Vault: Lore/i) { $expansion .= " [V16]"; }
    if ($expansion =~ m/^From the Vault: Realms/i) { $expansion .= " [V12]"; }
    if ($expansion =~ m/^From the Vault: Relics/i) { $expansion .= " [V10]"; }
    if ($expansion =~ m/^From the Vault: Twenty/i) { $expansion .= " [V13]"; }
    if ($expansion =~ m/^Future Sight/i) { $expansion .= " [FUT]"; }
    if ($expansion =~ m/^Game Day/i) { $expansion .= " [MGDC]"; }
    if ($expansion =~ m/^Gatecrash/i) { $expansion .= " [GTC]"; }
    if ($expansion =~ m/^Grand Prix/i) { $expansion .= " [GPX]"; }
    if ($expansion =~ m/^Grand Prix/i) { $expansion .= " [PGPX]"; }
    if ($expansion =~ m/^Guild Kits/i) { $expansion .= " [GK1]"; }
    if ($expansion =~ m/^Guildpact/i) { $expansion .= " [GPT]"; }
    if ($expansion =~ m/^Guilds of Ravnica/i) { $expansion .= "[GRN]"; }
    if ($expansion =~ m/^Homelands/i) { $expansion .= " [HML]"; }
    if ($expansion =~ m/^Hour of Devastation/i) { $expansion .= " [HOU]"; }
    if ($expansion =~ m/^Ice Age/i) { $expansion .= " [ICE]"; }
    if ($expansion =~ m/^Iconic Masters/i) { $expansion .= " [IMA]"; }
    if ($expansion =~ m/^Ikoria: Lair of Behemoths/i) { $expansion .= " [IKO]"; }
    if ($expansion =~ m/^Innistrad/i) { $expansion .= " [ISD]"; }
    #if ($expansion =~ m/^Invasion/i) { $expansion .= " [AP]"; }
    if ($expansion =~ m/^Invasion/i) { $expansion .= " [INV]"; }
    if ($expansion =~ m/^Ixalan/i) { $expansion .= " [XLN]"; }
    if ($expansion =~ m/^Journey into Nyx/i) { $expansion .= " [JOU]"; }
    if ($expansion =~ m/^Judge Promo/i) { $expansion .= " [JR]"; }
    if ($expansion =~ m/^Judgment/i) { $expansion .= " [JUD]"; }
    if ($expansion =~ m/^Jumpstart/i) { $expansion .= " [JMP]"; }
    if ($expansion =~ m/^Kaladesh/i) { $expansion .= " [KLD]"; }
    if ($expansion =~ m/^Khans of Tarkir/i) { $expansion .= " [KTK]"; }
    if ($expansion =~ m/^Launch Party/i) { $expansion .= " [MLP]"; }
    if ($expansion =~ m/^Legends/i) { $expansion .= " [LEG]"; }
    if ($expansion =~ m/^Legions/i) { $expansion .= " [LGN]"; }
    if ($expansion =~ m/^Limited Edition Alpha/i) { $expansion .= " [LEA]"; }
    if ($expansion =~ m/^Limited Edition Beta/i) { $expansion .= " [LEB]"; }
    if ($expansion =~ m/^Eventide/i) { $expansion .= " [EVE]"; }
    if ($expansion =~ m/^Lorwyn/i) { $expansion .= " [LRW]"; }
    if ($expansion =~ m/^MTGO Vanguard/i) { $expansion .= " [VGO]"; }
    if ($expansion =~ m/^Magic 2010/i) { $expansion .= " [M10]"; }
    if ($expansion =~ m/^Magic 2011/i) { $expansion .= " [M11]"; }
    if ($expansion =~ m/^Magic 2012/i) { $expansion .= " [M12]"; }
    if ($expansion =~ m/^Magic 2013/i) { $expansion .= " [M13]"; }
    if ($expansion =~ m/^Magic 2014/i) { $expansion .= " [M14]"; }
    if ($expansion =~ m/^Magic 2015/i) { $expansion .= " [M15]"; }
    if ($expansion =~ m/^Magic Origins/i) { $expansion .= " [ORI]"; }
    if ($expansion =~ m/^Magic Player Rewards/i) { $expansion .= " [MPRP]"; }
    if ($expansion =~ m/^Magic: The Gathering-Commander/i) { $expansion .= " [CMD]"; }
    if ($expansion =~ m/^Magic: The Gathering.*Conspiracy/i) { $expansion .= "[CNS]"; }
    if ($expansion =~ m/^Magic: The Gathering.*Conspiracy/i) { $expansion .= " [CNS]"; }
    if ($expansion =~ m/^Masques/i) { $expansion .= " [PR]"; }
    if ($expansion =~ m/^Masterpiece Series MED/i) { $expansion .= " [WAR]"; }
    if ($expansion =~ m/^Masterpiece Series/i) { $expansion .= " [MPS]"; }
    if ($expansion =~ m/^Masters Edition II/i) { $expansion .= " [ME2]"; }
    if ($expansion =~ m/^Masters Edition III/i) { $expansion .= " [ME3]"; }
    if ($expansion =~ m/^Masters Edition IV/i) { $expansion .= " [ME4]"; }
    if ($expansion =~ m/^Masters Edition/i) { $expansion .= " [ME4]"; }
    if ($expansion =~ m/^Masters Edition/i) { $expansion .= " [MED]"; }
    if ($expansion =~ m/^Media Inserts/i) { $expansion .= " [MBP]"; }
    if ($expansion =~ m/^Media Inserts/i) { $expansion .= " [PMEI]"; }
    if ($expansion =~ m/^Mercadian Masques/i) { $expansion .= " [MMQ]"; }
    if ($expansion =~ m/^Mirage/i) { $expansion .= " [MIR]"; }
    if ($expansion =~ m/^Mirage/i) { $expansion .= " [WL]"; }
    if ($expansion =~ m/^Mirrodin Besieged/i) { $expansion .= " [MBS]"; }
    if ($expansion =~ m/^Mirrodin/i) { $expansion .= " [MRD]"; }
    if ($expansion =~ m/^Modern Masters 2015/i) { $expansion .= " [MM2]"; }
    if ($expansion =~ m/^Modern Masters 2017/i) { $expansion .= " [MM3]"; }
    if ($expansion =~ m/^Modern Horizons/i) { $expansion .= " [MH1]"; }
    if ($expansion =~ m/^Modern Masters/i) { $expansion .= " [MMA]"; }
    if ($expansion =~ m/^Morningtide/i) { $expansion .= " [MOR]"; }
    if ($expansion =~ m/^Nemesis/i) { $expansion .= " [NEM]"; }
    if ($expansion =~ m/^New Phyrexia/i) { $expansion .= " [NPH]"; }
    if ($expansion =~ m/^Ninth Edition/i) { $expansion .= " [9ED]"; }
    if ($expansion =~ m/^Oath of the Gatewatch/i) { $expansion .= " [OGW]"; }
    if ($expansion =~ m/^Odyssey/i) { $expansion .= " [ODY]"; }
    if ($expansion =~ m/^Onslaught/i) { $expansion .= " [ONS]"; }
    if ($expansion =~ m/^Planar Chaos/i) { $expansion .= " [PLC]"; }
    if ($expansion =~ m/^Planechase 2012 Edition/i) { $expansion .= " [PC2]"; }
    if ($expansion =~ m/^Planechase/i) { $expansion .= " [HOP]"; }
    if ($expansion =~ m/^Planechase/i) { $expansion .= " [PC1]"; }
    if ($expansion =~ m/^Planeshift/i) { $expansion .= " [PLS]"; }
    if ($expansion =~ m/^Portal Second Age/i) { $expansion .= " [PO2]"; }
    if ($expansion =~ m/^Portal Three Kingdoms/i) { $expansion .= " [PTK]"; }
    if ($expansion =~ m/^Portal/i) { $expansion .= " [POR]"; }
    if ($expansion =~ m/^Premium Deck Series/i) { $expansion .= " [PD3]"; }
    if ($expansion =~ m/^Premium Deck Series: Fire and Lightning/i) { $expansion .= " [PD2]"; }
    if ($expansion =~ m/^Premium Deck Series: Slivers/i) { $expansion .= " [H09]"; }
    if ($expansion =~ m/^Prerelease Events/i) { $expansion .= " [PPRE]"; }
    if ($expansion =~ m/^Prerelease Events/i) { $expansion .= " [PTC]"; }
    if ($expansion =~ m/^Promotional/i) { $expansion .= " [PRM]"; }
    if ($expansion =~ m/^Prophecy/i) { $expansion .= " [PCY]"; }
    if ($expansion =~ m/^Ravnica Allegiance/i) { $expansion .= " [RNA]"; }
    if ($expansion =~ m/^Ravnica: City of Guilds/i) { $expansion .= " [RAV]"; }
    if ($expansion =~ m/^Reprints.*Anthologies/i) { $expansion .= " [BTD]"; }
    if ($expansion =~ m/^Return to Ravnica/i) { $expansion .= " [DGM]"; }
    if ($expansion =~ m/^Return to Ravnica/i) { $expansion .= " [RTR]"; }
    if ($expansion =~ m/^Revised Edition/i) { $expansion .= " [3ED]"; }
    if ($expansion =~ m/^Rise of the Eldrazi/i) { $expansion .= " [ROE]"; }
    if ($expansion =~ m/^Rivals of Ixalan/i) { $expansion .= "[RIX]"; }
    if ($expansion =~ m/^Saviors of Kamigawa/i) { $expansion .= " [SOK]"; }
    if ($expansion =~ m/^Scars of Mirrodin/i) { $expansion .= " [SOM]"; }
    if ($expansion =~ m/^Scourge/i) { $expansion .= " [SCG]"; }
    if ($expansion =~ m/^Secret Lair/i) { $expansion .= " [SLD]"; }
    if ($expansion =~ m/^Seventh Edition/i) { $expansion .= " [7ED]"; }
    if ($expansion =~ m/^Shadowmoor/i) { $expansion .= " [SHM]"; }
    if ($expansion =~ m/^Shadows over Innistrad/i) { $expansion .= " [SOI]"; }
    if ($expansion =~ m/^Shards of Alara/i) { $expansion .= " [ALA]"; }
    if ($expansion =~ m/^Special Sets/i) { $expansion .= " [MB1]"; }
    if ($expansion =~ m/^Special Sets/i) { $expansion .= " [MH1]"; }
    if ($expansion =~ m/^Spellbooks/i) { $expansion .= " [SS1]"; }
    if ($expansion =~ m/^Starter 1999/i) { $expansion .= " [S99]"; }
    if ($expansion =~ m/^Starter 2000/i) { $expansion .= " [S00]"; }
    if ($expansion =~ m/^Starter/i) { $expansion .= " [S00]"; }
    if ($expansion =~ m/^Stronghold/i) { $expansion .= " [STH]"; }
    if ($expansion =~ m/^Tempest Remastered/i) { $expansion .= " [TPR]"; }
    if ($expansion =~ m/^Tempest/i) { $expansion .= " [EX]"; }
    if ($expansion =~ m/^Tempest/i) { $expansion .= " [TMP]"; }
    if ($expansion =~ m/^Tenth Edition/i) { $expansion .= " [10E]"; }
    if ($expansion =~ m/^The Dark/i) { $expansion .= " [DRK]"; }
    if ($expansion =~ m/^Theros.*Beyond Death/i) { $expansion .= " [THB]"; }
    elsif ($expansion =~ m/^Theros/i) { $expansion .= " [THS]"; }
    if ($expansion =~ m/^Throne of Eldraine/i) { $expansion .= " [ELD]"; }
    if ($expansion =~ m/^Time Spiral.*Timeshifted/) { $expansion .= " [TSB]"; }
    elsif ($expansion =~ m/^Time Spiral/i) { $expansion .= " [TSP]"; }
    if ($expansion =~ m/^Torment/i) { $expansion .= " [TOR]"; }
    if ($expansion =~ m/^Un-Sets/i) { $expansion .= " [UND]"; }
    if ($expansion =~ m/^Unglued/i) { $expansion .= " [UGL]"; }
    if ($expansion =~ m/^Unhinged/i) { $expansion .= " [UNH]"; }
    if ($expansion =~ m/^Unlimited Edition/i) { $expansion .= " [2ED]"; }
    if ($expansion =~ m/^Urza's Destiny/i) { $expansion .= " [UDS]"; }
    if ($expansion =~ m/^Urza's Legacy/i) { $expansion .= " [ULG]"; }
    if ($expansion =~ m/^Urza's Saga/i) { $expansion .= " [USG]"; }
    if ($expansion =~ m/^Urza/i) { $expansion .= " [UD]"; }
    if ($expansion =~ m/^Vanguard Set 1/i) { $expansion .= " [VG1]"; }
    if ($expansion =~ m/^Vanguard Set 2/i) { $expansion .= " [VG2]"; }
    if ($expansion =~ m/^Vanguard Set 3/i) { $expansion .= " [VG3]"; }
    if ($expansion =~ m/^Vanguard Set 4/i) { $expansion .= " [VG4]"; }
    if ($expansion =~ m/^Vintage Masters/i) { $expansion .= " [VMA]"; }
    if ($expansion =~ m/^Visions/i) { $expansion .= " [VIS]"; }
    if ($expansion =~ m/^WPN Gateway/i) { $expansion .= " [GRC]"; }
    if ($expansion =~ m/^War of the Spark/i) { $expansion .= " [WAR]"; }
    if ($expansion =~ m/^Weatherlight/i) { $expansion .= " [WTH]"; }
    if ($expansion =~ m/^Welcome Deck 2016/i) { $expansion .= " [W16]"; }
    if ($expansion =~ m/^Welcome Deck 2017/i) { $expansion .= " [W17]"; }
    if ($expansion =~ m/^World Magic Cup Qualifier/i) { $expansion .= " [WMCQ]"; }
    if ($expansion =~ m/^Worldwake/i) { $expansion .= " [WWK]"; }
    if ($expansion =~ m/^Zendikar Rising/i) { $expansion .= " [ZNR]"; }
    elsif ($expansion =~ m/^Zendikar/i) { $expansion .= " [ZEN]"; }

    return $expansion;
}

# Read all cards
sub read_all_cards
{
    #open ALL, "./modern_magic_cards";
    #open ALL, "d:/perl_programs/new_all_modern_cards.txt";
    #open ALL, "d:/perl_programs/all_magic_cards.txt";
    # 20190322 - Use the xmage version of the cards..
    print ("reading from c:/xmage_release/mage/Utils/mtg-cards-data.txt\n");
    print ("Now (20210707) reading from c:/xmage_release_xxx/mage/Utils/mtg-cards-data.txt\n");
    open ALL, "c:/xmage_release_xxx/mage/Utils/mtg-cards-data.txt";

    my $count = 0;
    my $cards_count = 0;
    while (<ALL>)
    {
        chomp $_;
        my $line = $_;
        $line =~ s/\|\|/| |/g;
        $line =~ s/\|\|/| |/g;
        $line =~ s/^([^\|]*)\|([^\|]*)\|([^\|]*)\|M\|(.*)/$1|$2|$3|Mythic Rare|$4/gim;
        $line =~ s/^([^\|]*)\|([^\|]*)\|([^\|]*)\|R\|(.*)/$1|$2|$3|Rare|$4/gim;
        $line =~ s/^([^\|]*)\|([^\|]*)\|([^\|]*)\|U\|(.*)/$1|$2|$3|Uncommon|$4/gim;
        $line =~ s/^([^\|]*)\|([^\|]*)\|([^\|]*)\|C\|(.*)/$1|$2|$3|Common|$4/gim;
        $line =~ s/^([^\|]*)\|([^\|]*)\|([^\|]*)\|L\|(.*)/$1|$2|$3|Land|$4/gim;
        #print $line, "\n";
        $count ++;
        my @fields = split /\|/, $line;
        my $combined_name = $fields [0] . " - " . $fields [1];
        if ($count % 1000 == 0)
        {
            print ("$count lines ($combined_name)\n");
        }

        $all_cards {$combined_name} = $line;
        my $f;
        $original_lines {$combined_name} = $line;
        $original_lines_just_card_names {$fields [0]} = $line;
        my $expansion = expansion_trigraph ($fields [1]);

        {
            $card_names {$combined_name} = $fields [0];
            $cards_count++;
            $expansion {$combined_name} = $expansion;
            $card_cost {$combined_name} = $fields [4];
            $card_type {$combined_name} = $fields [5];
            $card_text {$combined_name} = $fields [8];

            $fields [4] =~ s/{X//g;
            $fields [4] =~ s/{Y//g;
            $fields [4] =~ s/[^{]//g;
            $card_converted_cost {$combined_name} = length($fields [4]);
        }
    }
    print ("Read in: $cards_count cards in total\n");
}

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

    $msg_body = '<html><head><META HTTP-EQUIV="CACHE-CONTROL" CONTENT="NO-CACHE"><br><META HTTP-EQUIV="EXPIRES" CONTENT="Mon, 22 Jul 2094 11:12:01 GMT"></head><body>' . $form . $msg_body . "<body></html>";

    my $header;
    if ($redirect =~ m/^redirect(\d)/i)
    {
        $header = "HTTP/1.1 301 Moved\nLocation: /full$1\nLast-Modified: $yyyymmddhhmmss\nConnection: close\nContent-Type: text/html; charset=UTF-8\nContent-Length: " . length ($msg_body) . "\n\n";
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

sub bin_write_to_socket
{
    my $sock_ref = $_ [0];
    my $img = $_ [1];
    my $buffer;
    my $size = 0;

    if (-f $img)
    {
        $size = -s $img;
    }
    my $msg_body = "HTTP/2.0 200 OK\ndate: Mon, 20 May 2019 13:20:41 GMT\ncontent-type: image/jpeg\ncontent-length: $size\n\n";
    print $msg_body, "\n";
    syswrite ($sock_ref, $msg_body);


    open IMAGE, $img;
    binmode IMAGE;

    my $buffer;
    while (read (IMAGE, $buffer, 16384))
    {
        syswrite ($sock_ref, $buffer);
    }
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
    my $num_chars_read = 0;

    while ((!(ord ($ch) == 10 and ord ($prev_ch) == 13)))
    {
        if (select ($rout=$rin, undef, undef, 200) == 1)
        {
            $prev_ch = $ch;
            # There is at least one byte ready to be read..
            if (sysread ($sock_ref, $ch, 1) < 1)
            {
                print ("$header!!\n");
                print (" ---> Unable to read a character\n");
                return "resend";
            }
            $header .= $ch;
            print ("Reading in at the moment - '$header'!!\n");
            #if ($header =~ m/alive\n\n/m)
            {
                my $h = $header;
                $h =~ s/(.)/",$1-" . ord ($1) . ";"/emg;
            }
        }
        $num_chars_read++;

    }

    print "\n++++++++++++++++++++++\n", $header, "\n";
    return $header;
}

sub do_checked
{
    if ($_ [0] == 2) { return " checked "; }
    if ($_ [0] eq "true") { return " checked "; }
    return "";
}

sub no_checked
{
    if ($_ [0] == 1) { return " checked "; }
    return "";
}

sub get_sets
{
    my $expansion = $_ [0];
    my $pack_number = $_ [1];
    my $how_many_players = $_ [2];
    my %exps;
    my %exps_mins;

    my $c;
    my @ac = sort (keys (%all_cards));
    foreach $c (@ac)
    {
        my $ol = original_line ($c);

        if ($ol =~ m/Expansion: (.*?) \(/i)
        {
            my $set = $1;
            $set =~ s/ /.*/g;
            $set =~ s/'/.*/g;
            if (!defined ($exps {$set}))
            {
                $exps {$set} = 1;
                $exps_mins {$set} = $c;
            }
            if ($c < $exps_mins {$set})
            {
                $exps_mins {$set} = $c;
            }
        }
    }

    my $s = "<br>";
    my $k;
    my %mins;
    foreach $k (sort (keys %exps_mins))
    {
        my $val = sprintf ("%08d", $exps_mins {$k});
        $mins {$val . "---" . $k} = 1;
    }
    foreach $k (sort (keys %mins))
    {
        $s .= $k . "<br>\n";
    }
    $s =~ s/^.*?---//img;

    my %seen_expansions;
    foreach $k (sort (values %expansion))
    {
        if (!defined ($seen_expansions{$k}))
        {
            #http://127.0.0.1:56789/filter?0&89&0&0&0&0&0&0&false&false&return.*to.*ravnica.*&.*&[12345]..*
            $seen_expansions {$k} = 1;
            $k =~ s/ *\[.*\]//;
            $s .= "<a href='filter?0&89&0&0&0&0&0&0&false&false&false&$k&.*&[12345]\..*'>$k.*rare</a><br>";
        }
    }

    # Get the minimum/maximum of each sets and then order them!
    return $s;
}

sub edh_lands
{
    my $expansion = $_ [0];
    my $pack_number = $_ [1];
    my $how_many_players = $_ [2];
    my %exps;
    my %exps_mins;

    # Get from https://edhrec.com/top/year or https://edhrec.com/top/lands
    my %edh_land;
    $edh_land {"Academy Ruins"} = 1; $edh_land {"Access Tunnel"} = 1; $edh_land {"Adarkar Wastes"} = 1; $edh_land {"Akoum Refuge"} = 1; $edh_land {"Alchemist's Refuge"} = 1; $edh_land {"Alpine Meadow"} = 1; $edh_land {"Ancient Amphitheater"} = 1; $edh_land {"Ancient Den"} = 1; $edh_land {"Ancient Tomb"} = 1; $edh_land {"Ancient Ziggurat"} = 1; $edh_land {"Arcane Lighthouse"} = 1; $edh_land {"Arcane Sanctum"} = 1; $edh_land {"Arch of Orazca"} = 1; $edh_land {"Arctic Treeline"} = 1; $edh_land {"Arid Mesa"} = 1; $edh_land {"Ash Barrens"} = 1; $edh_land {"Axgard Armory"} = 1; $edh_land {"Azorius Chancery"} = 1; $edh_land {"Azorius Guildgate"} = 1; $edh_land {"Badlands"} = 1; $edh_land {"Bant Panorama"} = 1; $edh_land {"Barkchannel Pathway"} = 1; $edh_land {"Barren Moor"} = 1; $edh_land {"Battlefield Forge"} = 1; $edh_land {"Bayou"} = 1;
    $edh_land {"Blackcleave Cliffs"} = 1; $edh_land {"Blast Zone"} = 1; $edh_land {"Blasted Landscape"} = 1; $edh_land {"Blighted Cataract"} = 1; $edh_land {"Blighted Woodland"} = 1; $edh_land {"Blightstep Pathway"} = 1; $edh_land {"Blinkmoth Nexus"} = 1; $edh_land {"Blood Crypt"} = 1; $edh_land {"Bloodfell Caves"} = 1; $edh_land {"Bloodstained Mire"} = 1; $edh_land {"Blooming Marsh"} = 1; $edh_land {"Blossoming Sands"} = 1; $edh_land {"Bojuka Bog"} = 1; $edh_land {"Bonders' Enclave"} = 1; $edh_land {"Boros Garrison"} = 1; $edh_land {"Boros Guildgate"} = 1; $edh_land {"Boseiju, Who Shelters All"} = 1; $edh_land {"Botanical Sanctum"} = 1; $edh_land {"Bountiful Promenade"} = 1; $edh_land {"Branchloft Pathway"} = 1; $edh_land {"Breeding Pool"} = 1; $edh_land {"Brightclimb Pathway"} = 1; $edh_land {"Brushland"} = 1; $edh_land {"Buried Ruin"} = 1; $edh_land {"Cabal Coffers"} = 1;
    $edh_land {"Cabal Stronghold"} = 1; $edh_land {"Calciform Pools"} = 1; $edh_land {"Canopy Vista"} = 1; $edh_land {"Canyon Slough"} = 1; $edh_land {"Cascade Bluffs"} = 1; $edh_land {"Cascading Cataracts"} = 1; $edh_land {"Castle Ardenvale"} = 1; $edh_land {"Castle Embereth"} = 1; $edh_land {"Castle Garenbrig"} = 1; $edh_land {"Castle Locthwain"} = 1; $edh_land {"Castle Vantress"} = 1; $edh_land {"Cavern of Souls"} = 1; $edh_land {"Caves of Koilos"} = 1; $edh_land {"Celestial Colonnade"} = 1; $edh_land {"Cephalid Coliseum"} = 1; $edh_land {"Choked Estuary"} = 1; $edh_land {"Cinder Barrens"} = 1; $edh_land {"Cinder Glade"} = 1; $edh_land {"City of Brass"} = 1; $edh_land {"Clearwater Pathway"} = 1; $edh_land {"Clifftop Retreat"} = 1; $edh_land {"Command Beacon"} = 1; $edh_land {"Command Tower"} = 1; $edh_land {"Concealed Courtyard"} = 1; $edh_land {"Contested Cliffs"} = 1;
    $edh_land {"Copperline Gorge"} = 1; $edh_land {"Coral Atoll"} = 1; $edh_land {"Cragcrown Pathway"} = 1; $edh_land {"Creeping Tar Pit"} = 1; $edh_land {"Crosis's Catacombs"} = 1; $edh_land {"Crucible of the Spirit Dragon"} = 1; $edh_land {"Crumbling Necropolis"} = 1; $edh_land {"Crypt of Agadeem"} = 1; $edh_land {"Crypt of the Eternals"} = 1; $edh_land {"Cryptic Caves"} = 1; $edh_land {"Crystal Quarry"} = 1; $edh_land {"Crystal Vein"} = 1; $edh_land {"Dakmor Salvage"} = 1; $edh_land {"Darigaaz's Caldera"} = 1; $edh_land {"Dark Depths"} = 1; $edh_land {"Darkbore Pathway"} = 1; $edh_land {"Darkmoss Bridge"} = 1; $edh_land {"Darkslick Shores"} = 1; $edh_land {"Darksteel Citadel"} = 1; $edh_land {"Darkwater Catacombs"} = 1; $edh_land {"Den of the Bugbear"} = 1; $edh_land {"Desert of the Fervent"} = 1; $edh_land {"Desert of the Glorified"} = 1; $edh_land {"Desert of the Indomitable"} = 1; $edh_land {"Desert of the Mindful"} = 1;
    $edh_land {"Desert of the True"} = 1; $edh_land {"Deserted Beach"} = 1; $edh_land {"Desolate Lighthouse"} = 1; $edh_land {"Detection Tower"} = 1; $edh_land {"Dimir Aqueduct"} = 1; $edh_land {"Dimir Guildgate"} = 1; $edh_land {"Dismal Backwater"} = 1; $edh_land {"Dragonskull Summit"} = 1; $edh_land {"Dreadship Reef"} = 1; $edh_land {"Drifting Meadow"} = 1; $edh_land {"Dromar's Cavern"} = 1; $edh_land {"Drossforge Bridge"} = 1; $edh_land {"Drowned Catacomb"} = 1; $edh_land {"Drownyard Temple"} = 1; $edh_land {"Dryad Arbor"} = 1; $edh_land {"Duskmantle, House of Shadow"} = 1; $edh_land {"Dwarven Mine"} = 1; $edh_land {"Eiganjo Castle"} = 1; $edh_land {"Eldrazi Temple"} = 1; $edh_land {"Elfhame Palace"} = 1; $edh_land {"Emergence Zone"} = 1; $edh_land {"Emeria, the Sky Ruin"} = 1; $edh_land {"Esper Panorama"} = 1; $edh_land {"Evolving Wilds"} = 1; $edh_land {"Exotic Orchard"} = 1;
    $edh_land {"Eye of Ugin"} = 1; $edh_land {"Fabled Passage"} = 1; $edh_land {"Faerie Conclave"} = 1; $edh_land {"Fetid Heath"} = 1; $edh_land {"Fetid Pools"} = 1; $edh_land {"Field of Ruin"} = 1; $edh_land {"Field of the Dead"} = 1; $edh_land {"Fiery Islet"} = 1; $edh_land {"Fire-Lit Thicket"} = 1; $edh_land {"Flagstones of Trokair"} = 1; $edh_land {"Flamekin Village"} = 1; $edh_land {"Flood Plain"} = 1; $edh_land {"Flooded Grove"} = 1; $edh_land {"Flooded Strand"} = 1; $edh_land {"Forbidden Orchard"} = 1; $edh_land {"Foreboding Ruins"} = 1; $edh_land {"Forest"} = 1; $edh_land {"Forge of Heroes"} = 1; $edh_land {"Forgotten Cave"} = 1; $edh_land {"Forsaken Sanctuary"} = 1; $edh_land {"Fortified Village"} = 1; $edh_land {"Foul Orchard"} = 1; $edh_land {"Frontier Bivouac"} = 1; $edh_land {"Frostboil Snarl"} = 1; $edh_land {"Furycalm Snarl"} = 1;
    $edh_land {"Gaea's Cradle"} = 1; $edh_land {"Game Trail"} = 1; $edh_land {"Gates of Istfell"} = 1; $edh_land {"Gateway Plaza"} = 1; $edh_land {"Gavony Township"} = 1; $edh_land {"Geier Reach Sanitarium"} = 1; $edh_land {"Gemstone Caverns"} = 1; $edh_land {"Ghost Quarter"} = 1; $edh_land {"Gilt-Leaf Palace"} = 1; $edh_land {"Gingerbread Cabin"} = 1; $edh_land {"Glacial Chasm"} = 1; $edh_land {"Glacial Floodplain"} = 1; $edh_land {"Glacial Fortress"} = 1; $edh_land {"Godless Shrine"} = 1; $edh_land {"Goldmire Bridge"} = 1; $edh_land {"Golgari Guildgate"} = 1; $edh_land {"Golgari Rot Farm"} = 1; $edh_land {"Grasslands"} = 1; $edh_land {"Graven Cairns"} = 1; $edh_land {"Graypelt Refuge"} = 1; $edh_land {"Great Furnace"} = 1; $edh_land {"Grim Backwoods"} = 1; $edh_land {"Grixis Panorama"} = 1; $edh_land {"Grove of the Burnwillows"} = 1; $edh_land {"Grove of the Guardian"} = 1;
    $edh_land {"Gruul Guildgate"} = 1; $edh_land {"Gruul Turf"} = 1; $edh_land {"Guildless Commons"} = 1; $edh_land {"Halimar Depths"} = 1; $edh_land {"Hall of Heliod's Generosity"} = 1; $edh_land {"Hall of the Bandit Lord"} = 1; $edh_land {"Hallowed Fountain"} = 1; $edh_land {"Hanweir Battlements"} = 1; $edh_land {"Haunted Ridge"} = 1; $edh_land {"Haven of the Spirit Dragon"} = 1; $edh_land {"Hengegate Pathway"} = 1; $edh_land {"High Market"} = 1; $edh_land {"Highland Forest"} = 1; $edh_land {"Highland Lake"} = 1; $edh_land {"Hinterland Harbor"} = 1; $edh_land {"Hissing Quagmire"} = 1; $edh_land {"Holdout Settlement"} = 1; $edh_land {"Homeward Path"} = 1; $edh_land {"Horizon Canopy"} = 1; $edh_land {"Ice Tunnel"} = 1; $edh_land {"Idyllic Grange"} = 1; $edh_land {"Indatha Triome"} = 1; $edh_land {"Inkmoth Nexus"} = 1; $edh_land {"Inspiring Vantage"} = 1; $edh_land {"Interplanar Beacon"} = 1;
    $edh_land {"Inventors' Fair"} = 1; $edh_land {"Irrigated Farmland"} = 1; $edh_land {"Island"} = 1; $edh_land {"Isolated Chapel"} = 1; $edh_land {"Izzet Boilerworks"} = 1; $edh_land {"Izzet Guildgate"} = 1; $edh_land {"Jund Panorama"} = 1; $edh_land {"Jungle Basin"} = 1; $edh_land {"Jungle Hollow"} = 1; $edh_land {"Jungle Shrine"} = 1; $edh_land {"Jwar Isle Refuge"} = 1; $edh_land {"Kabira Crossroads"} = 1; $edh_land {"Karn's Bastion"} = 1; $edh_land {"Karplusan Forest"} = 1; $edh_land {"Kazandu Refuge"} = 1; $edh_land {"Kessig Wolf Run"} = 1; $edh_land {"Ketria Triome"} = 1; $edh_land {"Khalni Garden"} = 1; $edh_land {"Kher Keep"} = 1; $edh_land {"Kor Haven"} = 1; $edh_land {"Krosan Verge"} = 1; $edh_land {"Labyrinth of Skophos"} = 1; $edh_land {"Lake of the Dead"} = 1; $edh_land {"Lavaclaw Reaches"} = 1; $edh_land {"Leechridden Swamp"} = 1;
    $edh_land {"Littjara Mirrorlake"} = 1; $edh_land {"Llanowar Reborn"} = 1; $edh_land {"Llanowar Wastes"} = 1; $edh_land {"Lonely Sandbar"} = 1; $edh_land {"Lorehold Campus"} = 1; $edh_land {"Lotus Field"} = 1; $edh_land {"Lumbering Falls"} = 1; $edh_land {"Luxury Suite"} = 1; $edh_land {"Mage-Ring Network"} = 1; $edh_land {"Mana Confluence"} = 1; $edh_land {"Marsh Flats"} = 1; $edh_land {"Maze of Ith"} = 1; $edh_land {"Meandering River"} = 1; $edh_land {"Memorial to Folly"} = 1; $edh_land {"Memorial to Genius"} = 1; $edh_land {"Memorial to Unity"} = 1; $edh_land {"Mikokoro, Center of the Sea"} = 1; $edh_land {"Minamo, School at Water's Edge"} = 1; $edh_land {"Mirrorpool"} = 1; $edh_land {"Mishra's Factory"} = 1; $edh_land {"Mistvault Bridge"} = 1; $edh_land {"Mistveil Plains"} = 1; $edh_land {"Misty Rainforest"} = 1; $edh_land {"Molten Slagheap"} = 1; $edh_land {"Moorland Haunt"} = 1;
    $edh_land {"Morphic Pool"} = 1; $edh_land {"Mortuary Mire"} = 1; $edh_land {"Mossfire Valley"} = 1; $edh_land {"Mosswort Bridge"} = 1; $edh_land {"Mountain"} = 1; $edh_land {"Mountain Valley"} = 1; $edh_land {"Murmuring Bosk"} = 1; $edh_land {"Mutavault"} = 1; $edh_land {"Myriad Landscape"} = 1; $edh_land {"Mystic Gate"} = 1; $edh_land {"Mystic Monastery"} = 1; $edh_land {"Mystic Sanctuary"} = 1; $edh_land {"Naya Panorama"} = 1; $edh_land {"Necroblossom Snarl"} = 1; $edh_land {"Needle Spires"} = 1; $edh_land {"Needleverge Pathway"} = 1; $edh_land {"Nephalia Drownyard"} = 1; $edh_land {"New Benalia"} = 1; $edh_land {"Nimbus Maze"} = 1; $edh_land {"Nomad Outpost"} = 1; $edh_land {"Novijen, Heart of Progress"} = 1; $edh_land {"Nurturing Peatland"} = 1; $edh_land {"Nykthos, Shrine to Nyx"} = 1; $edh_land {"Oboro, Palace in the Clouds"} = 1; $edh_land {"Okina, Temple to the Grandfathers"} = 1;
    $edh_land {"Opal Palace"} = 1; $edh_land {"Opulent Palace"} = 1; $edh_land {"Oran-Rief, the Vastwood"} = 1; $edh_land {"Orzhov Basilica"} = 1; $edh_land {"Orzhov Guildgate"} = 1; $edh_land {"Overgrown Farmland"} = 1; $edh_land {"Overgrown Tomb"} = 1; $edh_land {"Path of Ancestry"} = 1; $edh_land {"Pendelhaven"} = 1; $edh_land {"Phyrexian Tower"} = 1; $edh_land {"Phyrexia's Core"} = 1; $edh_land {"Plains"} = 1; $edh_land {"Plateau"} = 1; $edh_land {"Polluted Delta"} = 1; $edh_land {"Polluted Mire"} = 1; $edh_land {"Port of Karfell"} = 1; $edh_land {"Port Town"} = 1; $edh_land {"Prairie Stream"} = 1; $edh_land {"Prismari Campus"} = 1; $edh_land {"Prismatic Vista"} = 1; $edh_land {"Quandrix Campus"} = 1; $edh_land {"Radiant Fountain"} = 1; $edh_land {"Raging Ravine"} = 1; $edh_land {"Rakdos Carnarium"} = 1; $edh_land {"Rakdos Guildgate"} = 1;
    $edh_land {"Raugrin Triome"} = 1; $edh_land {"Razortide Bridge"} = 1; $edh_land {"Razorverge Thicket"} = 1; $edh_land {"Reflecting Pool"} = 1; $edh_land {"Rejuvenating Springs"} = 1; $edh_land {"Reliquary Tower"} = 1; $edh_land {"Remote Isle"} = 1; $edh_land {"Riftstone Portal"} = 1; $edh_land {"Rimewood Falls"} = 1; $edh_land {"Riptide Laboratory"} = 1; $edh_land {"Rith's Grove"} = 1; $edh_land {"River of Tears"} = 1; $edh_land {"Riverglide Pathway"} = 1; $edh_land {"Rix Maadi, Dungeon Palace"} = 1; $edh_land {"Rockfall Vale"} = 1; $edh_land {"Rocky Tar Pit"} = 1; $edh_land {"Rogue's Passage"} = 1; $edh_land {"Rootbound Crag"} = 1; $edh_land {"Rugged Highlands"} = 1; $edh_land {"Rugged Prairie"} = 1; $edh_land {"Rupture Spire"} = 1; $edh_land {"Rustvale Bridge"} = 1; $edh_land {"Sacred Foundry"} = 1; $edh_land {"Salt Marsh"} = 1; $edh_land {"Saltcrusted Steppe"} = 1;
    $edh_land {"Sanctum of Eternity"} = 1; $edh_land {"Sanctum of Ugin"} = 1; $edh_land {"Sandsteppe Citadel"} = 1; $edh_land {"Sandstone Needle"} = 1; $edh_land {"Sapseep Forest"} = 1; $edh_land {"Savage Lands"} = 1; $edh_land {"Savai Triome"} = 1; $edh_land {"Savannah"} = 1; $edh_land {"Scalding Tarn"} = 1; $edh_land {"Scattered Groves"} = 1; $edh_land {"Scavenger Grounds"} = 1; $edh_land {"Scoured Barrens"} = 1; $edh_land {"Scrubland"} = 1; $edh_land {"Sea of Clouds"} = 1; $edh_land {"Seachrome Coast"} = 1; $edh_land {"Seaside Citadel"} = 1; $edh_land {"Seat of the Synod"} = 1; $edh_land {"Secluded Steppe"} = 1; $edh_land {"Sejiri Refuge"} = 1; $edh_land {"Selesnya Guildgate"} = 1; $edh_land {"Selesnya Sanctuary"} = 1; $edh_land {"Serra's Sanctum"} = 1; $edh_land {"Shadowblood Ridge"} = 1; $edh_land {"Shambling Vent"} = 1; $edh_land {"Shattered Sanctum"} = 1;
    $edh_land {"Sheltered Thicket"} = 1; $edh_land {"Shineshadow Snarl"} = 1; $edh_land {"Shinka, the Bloodsoaked Keep"} = 1; $edh_land {"Shipwreck Marsh"} = 1; $edh_land {"Shivan Reef"} = 1; $edh_land {"Shizo, Death's Storehouse"} = 1; $edh_land {"Shrine of the Forsaken Gods"} = 1; $edh_land {"Silent Clearing"} = 1; $edh_land {"Silverbluff Bridge"} = 1; $edh_land {"Silverquill Campus"} = 1; $edh_land {"Simic Growth Chamber"} = 1; $edh_land {"Simic Guildgate"} = 1; $edh_land {"Skarrg, the Rage Pits"} = 1; $edh_land {"Skemfar Elderhall"} = 1; $edh_land {"Skycloud Expanse"} = 1; $edh_land {"Slagwoods Bridge"} = 1; $edh_land {"Slayers' Stronghold"} = 1; $edh_land {"Slippery Karst"} = 1; $edh_land {"Smoldering Crater"} = 1; $edh_land {"Smoldering Marsh"} = 1; $edh_land {"Snow-Covered Forest"} = 1; $edh_land {"Snow-Covered Island"} = 1; $edh_land {"Snow-Covered Mountain"} = 1; $edh_land {"Snow-Covered Plains"} = 1; $edh_land {"Snow-Covered Swamp"} = 1;
    $edh_land {"Snowfield Sinkhole"} = 1; $edh_land {"Spectator Seating"} = 1; $edh_land {"Spinerock Knoll"} = 1; $edh_land {"Spire Garden"} = 1; $edh_land {"Spire of Industry"} = 1; $edh_land {"Spirebluff Canal"} = 1; $edh_land {"Steam Vents"} = 1; $edh_land {"Stirring Wildwood"} = 1; $edh_land {"Stomping Ground"} = 1; $edh_land {"Stone Quarry"} = 1; $edh_land {"Strip Mine"} = 1; $edh_land {"Submerged Boneyard"} = 1; $edh_land {"Sulfur Falls"} = 1; $edh_land {"Sulfurous Mire"} = 1; $edh_land {"Sulfurous Springs"} = 1; $edh_land {"Sunbaked Canyon"} = 1; $edh_land {"Sungrass Prairie"} = 1; $edh_land {"Sunhome, Fortress of the Legion"} = 1; $edh_land {"Sunken Hollow"} = 1; $edh_land {"Sunken Ruins"} = 1; $edh_land {"Sunpetal Grove"} = 1; $edh_land {"Survivors' Encampment"} = 1; $edh_land {"Svogthos, the Restless Tomb"} = 1; $edh_land {"Swamp"} = 1; $edh_land {"Swarmyard"} = 1;
    $edh_land {"Swiftwater Cliffs"} = 1; $edh_land {"Taiga"} = 1; $edh_land {"Tainted Field"} = 1; $edh_land {"Tainted Isle"} = 1; $edh_land {"Tainted Peak"} = 1; $edh_land {"Tainted Wood"} = 1; $edh_land {"Tanglepool Bridge"} = 1; $edh_land {"Tarnished Citadel"} = 1; $edh_land {"Tectonic Edge"} = 1; $edh_land {"Temple Garden"} = 1; $edh_land {"Temple of Abandon"} = 1; $edh_land {"Temple of Deceit"} = 1; $edh_land {"Temple of Enlightenment"} = 1; $edh_land {"Temple of Epiphany"} = 1; $edh_land {"Temple of Malady"} = 1; $edh_land {"Temple of Malice"} = 1; $edh_land {"Temple of Mystery"} = 1; $edh_land {"Temple of Plenty"} = 1; $edh_land {"Temple of Silence"} = 1; $edh_land {"Temple of the False God"} = 1; $edh_land {"Temple of Triumph"} = 1; $edh_land {"Terrain Generator"} = 1; $edh_land {"Terramorphic Expanse"} = 1; $edh_land {"The World Tree"} = 1; $edh_land {"Thespian's Stage"} = 1;
    $edh_land {"Thornglint Bridge"} = 1; $edh_land {"Thornwood Falls"} = 1; $edh_land {"Thriving Bluff"} = 1; $edh_land {"Thriving Grove"} = 1; $edh_land {"Thriving Heath"} = 1; $edh_land {"Thriving Isle"} = 1; $edh_land {"Thriving Moor"} = 1; $edh_land {"Timber Gorge"} = 1; $edh_land {"Tolaria West"} = 1; $edh_land {"Tomb of the Spirit Dragon"} = 1; $edh_land {"Tournament Grounds"} = 1; $edh_land {"Training Center"} = 1; $edh_land {"Tranquil Cove"} = 1; $edh_land {"Tranquil Expanse"} = 1; $edh_land {"Tranquil Thicket"} = 1; $edh_land {"Transguild Promenade"} = 1; $edh_land {"Treasure Vault"} = 1; $edh_land {"Tree of Tales"} = 1; $edh_land {"Treetop Village"} = 1; $edh_land {"Treva's Ruins"} = 1; $edh_land {"Tropical Island"} = 1; $edh_land {"Tundra"} = 1; $edh_land {"Twilight Mire"} = 1; $edh_land {"Tyrite Sanctum"} = 1; $edh_land {"Unclaimed Territory"} = 1;
    $edh_land {"Underground River"} = 1; $edh_land {"Underground Sea"} = 1; $edh_land {"Undergrowth Stadium"} = 1; $edh_land {"Unholy Grotto"} = 1; $edh_land {"Urborg, Tomb of Yawgmoth"} = 1; $edh_land {"Urborg Volcano"} = 1; $edh_land {"Urza's Mine"} = 1; $edh_land {"Urza's Power Plant"} = 1; $edh_land {"Urza's Saga"} = 1; $edh_land {"Urza's Tower"} = 1; $edh_land {"Valakut, the Molten Pinnacle"} = 1; $edh_land {"Vault of Champions"} = 1; $edh_land {"Vault of the Archangel"} = 1; $edh_land {"Vault of Whispers"} = 1; $edh_land {"Verdant Catacombs"} = 1; $edh_land {"Vesuva"} = 1; $edh_land {"Vineglimmer Snarl"} = 1; $edh_land {"Vitu-Ghazi, the City-Tree"} = 1; $edh_land {"Volrath's Stronghold"} = 1; $edh_land {"Wandering Fumarole"} = 1; $edh_land {"War Room"} = 1; $edh_land {"Warped Landscape"} = 1; $edh_land {"Wasteland"} = 1; $edh_land {"Wastes"} = 1; $edh_land {"Waterlogged Grove"} = 1;
    $edh_land {"Watery Grave"} = 1; $edh_land {"Westvale Abbey"} = 1; $edh_land {"Wind-Scarred Crag"} = 1; $edh_land {"Windbrisk Heights"} = 1; $edh_land {"Windswept Heath"} = 1; $edh_land {"Wirewood Lodge"} = 1; $edh_land {"Witch's Clinic"} = 1; $edh_land {"Witch's Cottage"} = 1; $edh_land {"Witherbloom Campus"} = 1; $edh_land {"Wooded Bastion"} = 1; $edh_land {"Wooded Foothills"} = 1; $edh_land {"Woodland Cemetery"} = 1; $edh_land {"Woodland Chasm"} = 1; $edh_land {"Woodland Stream"} = 1; $edh_land {"Yavimaya Coast"} = 1; $edh_land {"Yavimaya, Cradle of Growth"} = 1; $edh_land {"Yavimaya Hollow"} = 1; $edh_land {"Zagoth Triome"} = 1; $edh_land {"Zhalfirin Void"} = 1;

    my $s = "<br>";
    my $cardname_set;
    my $c;
    {
        foreach $c (sort (keys (%edh_land)))
        {
            {
                my $ol = original_line_from_cardname ($c);

                $s .= " $c -- ";
                my $coled = 0;
                if ($ol =~ m/\{[^}]*?w[^{]*?\}/img) { $s .= " white, "; $coled = 1; }
                if ($ol =~ m/\{[^}]*?u[^{]*?\}/img) { $s .= " blue, "; $coled = 1; }
                if ($ol =~ m/\{[^}]*?b[^{]*?\}/img) { $s .= " black, "; $coled = 1; }
                if ($ol =~ m/\{[^}]*?r[^{]*?\}/img) { $s .= " red, "; $coled = 1; }
                if ($ol =~ m/\{[^}]*?g[^{]*?\}/img) { $s .= " green, "; $coled = 1; }
                if ($ol =~ m/tap.*any.*col/img) { $s .= " all_colors "; $coled = 1; }

                if ($coled == 0)
                {
                    $s .= " colourless ";
                }
                
                $s .= " -- ";

                my $ol2 = $ol;
                while ($ol2 =~ s/(plains|island|swamp|mountain|forest)//im) { $s .= " $1, "; }
                if ($ol =~ m/^$/)
                {
                    $s .= " NOT FOUND!<br>";
                }
                else
                {
                    #$s .= " <font size=-2>$ol<\/font><br>";
                    $s .= " <br>\n";
                }
            }
        }
    }

    #$s .= join ("..", sort keys (%original_lines));
    # Return this..
    return $s;
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
    my $port = 56789;
    my $num_connections = 0;
    my $trusted_client;
    my $data_from_client;
    $|=1;
    read_all_cards;

    print ("example: filter_magic.pl 1 1 0 1 1 \"each opponent\" \".*\" 0 5\n\n");

    socket (SERVER, PF_INET, SOCK_STREAM, $proto) or die "Failed to create a socket: $!";
    setsockopt (SERVER, SOL_SOCKET, SO_REUSEADDR, 1) or die "setsocketopt: $!";

    # bind to a port, then listen
    bind (SERVER, sockaddr_in ($port, INADDR_ANY)) or die "Can't bind to port $port! \n";

    listen (SERVER, 10) or die "listen: $!";
    print ("Listening on port: $port\n");
    my $accept_fail_counter;
    my $count;
    my $not_seen_full = 1;

    my @ac = sort (keys (%all_cards));
    print ("========================\n");
    print ("Library comes from - \n");
    print ("gvim d:\/perl_programs\/all_magic_cards.txt\n");
    print ("Red Green Blue Black White  Text  Name name_chained (<=convertedcost)\n\n");

    while ($paddr = accept (CLIENT, SERVER))
    {
        print ("\n\nNEW============================================================\n");
        print ("New connection\n");

        $num_connections++;
        $accept_fail_counter = 0;
        unless ($paddr)
        {
            $accept_fail_counter++;

            if ($accept_fail_counter > 0)
            {
                #print "accept () has failedsockaddr_in $accept_fail_counter";
                next;
            }
        }

        print ("- - - - - - -\n");

        $accept_fail_counter = 0;
        ($client_port, $iaddr) = sockaddr_in ($paddr);
        $client_addr = inet_ntoa ($iaddr);
        print ("\n$client_addr\n");

        my $lat;
        my $long;
        my $txt = read_from_socket (\*CLIENT);

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

        print ("Read -> $txt\n");

        print ("2- - - - - - -\n");
        my $have_to_write_to_socket = 1;

        chomp ($txt);
        my $original_get = $txt;

        if ($original_get =~ m/\.(png|gif)/)
        {
            bin_write_to_socket (\*CLIENT, "d:\\perl_programs\\all_magic_cards.zip", "", "noredirect");
            next;
        }

        if ($original_get =~ m/all_sets/)
        {
            my $sets = get_sets ();
            write_to_socket (\*CLIENT, $sets, "", "noredirect");
            next;
        }
       
        if ($original_get =~ m/edh_lands/)
        {
            my $sets = edh_lands ();
            write_to_socket (\*CLIENT, $sets, "", "noredirect");
            next;
        }

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

        my @strs = split /&/, $txt;
        #print join (',,,', @strs);

        my $use_red = $strs [2];
        my $use_green = $strs [3];
        my $use_blue = $strs [4];
        my $use_black = $strs [5];
        my $use_white = $strs [6];
        my $use_uncoloured = $strs [7];
        my $use_full_format = $strs [8];
        my $use_block = $strs [9];
        my $use_unique = $strs [10];

        my $card_text = $strs [11];
        my $card_name = $strs [12];
        my $community_rating = $strs [13];
        my $min_cmc = $strs [0];
        my $max_cmc = $strs [1];

        # Do a form with the check boxes checked etc..
        my $form = "";
        my $checked = "";
        $form = "<form action=\"\">";
        $form .= "Card name: <input id=cn type=\"text\" size=30 value=\"$card_name\"><br>";
        $form .= "Card text: <input id=ct type=\"text\" size=30 value=\"$card_text\"><br>";
        $form .= "Rating&nbsp;&nbsp;: <input id=cr type=\"text\" size=30 value=\"$community_rating\">";
        $form .= "<a onclick=\"javascript: document.getElementById('cr').value='[4]\..*';\">Great!</a>&nbsp;";
        $form .= "<a onclick=\"javascript: document.getElementById('cr').value='[34]\..*';\">OK</a>&nbsp;";
        $form .= "<a onclick=\"javascript: document.getElementById('cr').value='[1234]\..*';\">Sorted</a>&nbsp;";
        $form .= "<a onclick=\"javascript: document.getElementById('cr').value='.*';\">All</a><br>";
        $form .= "Min CMC&nbsp;: <input id=mc type=\"text\" size=15 value=\"$min_cmc\">";
        $form .= "Max CMC&nbsp;: <input id=mxc type=\"text\" size=15 value=\"$max_cmc\"><br>";

        $form .= "<input id=yw type=\"checkbox\" name=\"mustbewhite\" value=\"m_white\"" . do_checked ($use_white) . ">Must have white</input>";
        $form .= "<input id=nw type=\"checkbox\" name=\"cannotbewhite\" value=\"no_white\"" . no_checked ($use_white) . ">Can't have white</input><br>\n";
        $form .= "<input id=yu type=\"checkbox\" name=\"mustbeblue\" value=\"m_blue\"" . do_checked ($use_blue) . ">Must have blue&nbsp;</input>";
        $form .= "<input id=nu type=\"checkbox\" name=\"cannotbeblue\" value=\"no_blue\"" . no_checked ($use_blue) . ">Can't have blue</input><br>\n";
        $form .= "<input id=yb type=\"checkbox\" name=\"mustbeblack\" value=\"m_black\"" . do_checked ($use_black) . ">Must have black</input>";
        $form .= "<input id=nb type=\"checkbox\" name=\"cannotbeblack\" value=\"no_black\"" . no_checked ($use_black) . ">Can't have black</input><br>\n";
        $form .= "<input id=yr type=\"checkbox\" name=\"mustbered\" value=\"m_red\"" . do_checked ($use_red) . ">Must have red&nbsp;</input>";
        $form .= "<input id=nr type=\"checkbox\" name=\"cannotbered\" value=\"no_red\"" . no_checked ($use_red) . ">Can't have red</input><br>\n";
        $form .= "<input id=yg type=\"checkbox\" name=\"mustbegreen\" value=\"m_green\"" . do_checked ($use_green) . ">Must have green</input>";
        $form .= "<input id=ng type=\"checkbox\" name=\"cannotbegreen\" value=\"no_green\"" . no_checked ($use_green) . ">Can't have green</input><br>\n";
        $form .= "<input id=yuc type=\"checkbox\" name=\"mustbeuncoloured\" value=\"m_uncoloured\"" . do_checked ($use_uncoloured) . ">Must have uncoloured</input>";
        $form .= "<input id=nuc type=\"checkbox\" name=\"cannotbeuncoloured\" value=\"no_uncoloured\"" . no_checked ($use_uncoloured) . ">Can't have uncoloured</input><br>\n";
        $form .= "<input id=full_format type=\"checkbox\" name=\"full_format_only\" value=\"m_full_format\"" . do_checked ($use_full_format) . ">Full format</input>&nbsp;&nbsp;\n";
        $form .= "<input id=block type=\"checkbox\" name=\"blockonly\" value=\"m_block\"" . do_checked ($use_block) . ">Only use current block</input><br>\n";
        $form .= "<input id=uniquenames type=\"checkbox\" name=\"uniquenames\" value=\"m_block\"" . do_checked ($use_unique) . ">Unique names</input><br>\n";
        $form .= "<a onclick=\"javascript: var ct=document.getElementById('ct').value; var cn=document.getElementById('cn').value; var cr=document.getElementById('cr').value; var mc=document.getElementById('mc').value; var mxc=document.getElementById('mxc').value; var yg=document.getElementById('yg').checked; var ng=document.getElementById('ng').checked; var fg=0;if(yg==true&&ng==false){fg=2;}else if(yg==false&&ng==true){fg=1;} var yr=document.getElementById('yr').checked; var nr=document.getElementById('nr').checked; var fr=0;if(yr==true&&nr==false){fr=2;}else if(yr==false&&nr==true){fr=1;} var yu=document.getElementById('yu').checked; var nu=document.getElementById('nu').checked; var fu=0;if(yu==true&&nu==false){fu=2;}else if(yu==false&&nu==true){fu=1;} var yb=document.getElementById('yb').checked; var nb=document.getElementById('nb').checked; var fb=0;if(yb==true&&nb==false){fb=2;}else if(yb==false&&nb==true){fb=1;} var yw=document.getElementById('yw').checked; var nw=document.getElementById('nw').checked; var fw=0;if(yw==true&&nw==false){fw=2;}else if(yw==false&&nw==true){fw=1;} var yuc=document.getElementById('yuc').checked; var nuc=document.getElementById('nuc').checked; var fuc=0;if(yuc==true&&nuc==false){fuc=2;}else if(yuc==false&&nuc==true){fuc=1;} var std=document.getElementById('full_format').checked; var blk=document.getElementById('block').checked; var uniquenames=document.getElementById('uniquenames').checked; var full = location.protocol+'//'+location.hostname+(location.port ? ':'+location.port: ''); full = full+'/filter?'+mc+'&'+mxc+'&'+fr+'&'+fg+'&'+fu+'&'+fb+'&'+fw+'&'+fuc+'&'+std+'&'+blk+'&'+uniquenames+'&'+ct+'&'+cn+'&'+cr; var resubmit=document.getElementById('resubmit'); resubmit.href=full;\"><font color=blue size=+2><u>Update the query (click here):</u></font></a>&nbsp;&nbsp;";
        my $x_card_name = $card_text;
        $x_card_name =~ s/(o.*?)o/$1&#664;/;
        $x_card_name =~ s/%20/ /img;
        $form .= "<p><br>$x_card_name<br></p>";

#        $form .= "&#000; -> 000 &#001; -> 001 &#002; -> 002 &#003; -> 003 &#004; -> 004 &#005; -> 005 &#006; -> 006 &#007; -> 007 &#008; -> 008<br> &#009; -> 009 &#010; -> 010 &#011; -> 011 &#012; -> 012 &#013; -> 013 &#014; -> 014 &#015; -> 015 &#016; -> 016 &#017; -> 017<br> &#018; -> 018 &#019; -> 019 &#020; -> 020 &#021; -> 021 &#022; -> 022 &#023; -> 023 &#024; -> 024";
#        $form .= "&#025; -> 025 &#026; -> 026<br> &#027; -> 027 &#028; -> 028 &#029; -> 029 &#030; -> 030 &#031; -> 031 &#032; -> 032 &#033; -> 033 &#034; -> 034 &#035; -> 035<br> &#036; -> 036 &#037; -> 037 &#038; -> 038 &#039; -> 039 &#040; -> 040 &#041; -> 041 &#042; -> 042 &#043; -> 043 &#044; -> 044<br> &#045; -> 045 &#046; -> 046 &#047; -> 047 &#048; -> 048 &#049; -> 049";
#        $form .= "&#050; -> 050 &#051; -> 051 &#052; -> 052 &#053; -> 053<br> &#054; -> 054 &#055; -> 055 &#056; -> 056 &#057; -> 057 &#058; -> 058 &#059; -> 059 &#060; -> 060 &#061; -> 061 &#062; -> 062<br> &#063; -> 063 &#064; -> 064 &#065; -> 065 &#066; -> 066 &#067; -> 067 &#068; -> 068 &#069; -> 069 &#070; -> 070 &#071; -> 071<br> &#072; -> 072 &#073; -> 073 &#074; -> 074";
#        $form .= "&#075; -> 075 &#076; -> 076 &#077; -> 077 &#078; -> 078 &#079; -> 079 &#080; -> 080<br> &#081; -> 081 &#082; -> 082 &#083; -> 083 &#084; -> 084 &#085; -> 085 &#086; -> 086 &#087; -> 087 &#088; -> 088 &#089; -> 089<br> &#090; -> 090 &#091; -> 091 &#092; -> 092 &#093; -> 093 &#094; -> 094 &#095; -> 095 &#096; -> 096 &#097; -> 097 &#098; -> 098<br> &#099; -> 099";
#        $form .= "&#100; -> 100 &#101; -> 101 &#102; -> 102 &#103; -> 103 &#104; -> 104 &#105; -> 105 &#106; -> 106 &#107; -> 107<br> &#108; -> 108 &#109; -> 109 &#110; -> 110 &#111; -> 111 &#112; -> 112 &#113; -> 113 &#114; -> 114 &#115; -> 115 &#116; -> 116<br> &#117; -> 117 &#118; -> 118 &#119; -> 119 &#120; -> 120 &#121; -> 121 &#122; -> 122 &#123; -> 123 &#124; -> 124";
#        $form .= "&#125; -> 125<br> &#126; -> 126 &#127; -> 127 &#128; -> 128 &#129; -> 129 &#130; -> 130 &#131; -> 131 &#132; -> 132 &#133; -> 133 &#134; -> 134<br> &#135; -> 135 &#136; -> 136 &#137; -> 137 &#138; -> 138 &#139; -> 139 &#140; -> 140 &#141; -> 141 &#142; -> 142 &#143; -> 143<br> &#144; -> 144 &#145; -> 145 &#146; -> 146 &#147; -> 147 &#148; -> 148 &#149; -> 149";
#        $form .= "&#150; -> 150 &#151; -> 151 &#152; -> 152<br> &#153; -> 153 &#154; -> 154 &#155; -> 155 &#156; -> 156 &#157; -> 157 &#158; -> 158 &#159; -> 159 &#160; -> 160 &#161; -> 161<br> &#162; -> 162 &#163; -> 163 &#164; -> 164 &#165; -> 165 &#166; -> 166 &#167; -> 167 &#168; -> 168 &#169; -> 169 &#170; -> 170<br> &#171; -> 171 &#172; -> 172 &#173; -> 173 &#174; -> 174";
#        $form .= "&#175; -> 175 &#176; -> 176 &#177; -> 177 &#178; -> 178 &#179; -> 179<br> &#180; -> 180 &#181; -> 181 &#182; -> 182 &#183; -> 183 &#184; -> 184 &#185; -> 185 &#186; -> 186 &#187; -> 187 &#188; -> 188<br> &#189; -> 189 &#190; -> 190 &#191; -> 191 &#192; -> 192 &#193; -> 193 &#194; -> 194 &#195; -> 195 &#196; -> 196 &#197; -> 197<br> &#198; -> 198 &#199; -> 199";
#        $form .= "&#200; -> 200 &#201; -> 201 &#202; -> 202 &#203; -> 203 &#204; -> 204 &#205; -> 205 &#206; -> 206<br> &#207; -> 207 &#208; -> 208 &#209; -> 209 &#210; -> 210 &#211; -> 211 &#212; -> 212 &#213; -> 213 &#214; -> 214 &#215; -> 215<br> &#216; -> 216 &#217; -> 217 &#218; -> 218 &#219; -> 219 &#220; -> 220 &#221; -> 221 &#222; -> 222 &#223; -> 223 &#224; -> 224<br>";
#        $form .= "&#225; -> 225 &#226; -> 226 &#227; -> 227 &#228; -> 228 &#229; -> 229 &#230; -> 230 &#231; -> 231 &#232; -> 232 &#233; -> 233<br> &#234; -> 234 &#235; -> 235 &#236; -> 236 &#237; -> 237 &#238; -> 238 &#239; -> 239 &#240; -> 240 &#241; -> 241 &#242; -> 242<br> &#243; -> 243 &#244; -> 244 &#245; -> 245 &#246; -> 246 &#247; -> 247 &#248; -> 248 &#249; -> 249";
#        $form .= "&#250; -> 250 &#251; -> 251<br> &#252; -> 252 &#253; -> 253 &#254; -> 254 &#255; -> 255 &#256; -> 256 &#257; -> 257 &#258; -> 258 &#259; -> 259 &#260; -> 260<br> &#261; -> 261 &#262; -> 262 &#263; -> 263 &#264; -> 264 &#265; -> 265 &#266; -> 266 &#267; -> 267 &#268; -> 268 &#269; -> 269<br> &#270; -> 270 &#271; -> 271 &#272; -> 272 &#273; -> 273 &#274; -> 274";
#        $form .= "&#275; -> 275 &#276; -> 276 &#277; -> 277 &#278; -> 278<br> &#279; -> 279 &#280; -> 280 &#281; -> 281 &#282; -> 282 &#283; -> 283 &#284; -> 284 &#285; -> 285 &#286; -> 286 &#287; -> 287<br> &#288; -> 288 &#289; -> 289 &#290; -> 290 &#291; -> 291 &#292; -> 292 &#293; -> 293 &#294; -> 294 &#295; -> 295 &#296; -> 296<br> &#297; -> 297 &#298; -> 298 &#299; -> 299";
#        $form .= "&#300; -> 300 &#301; -> 301 &#302; -> 302 &#303; -> 303 &#304; -> 304 &#305; -> 305<br> &#306; -> 306 &#307; -> 307 &#308; -> 308 &#309; -> 309 &#310; -> 310 &#311; -> 311 &#312; -> 312 &#313; -> 313 &#314; -> 314<br> &#315; -> 315 &#316; -> 316 &#317; -> 317 &#318; -> 318 &#319; -> 319 &#320; -> 320 &#321; -> 321 &#322; -> 322 &#323; -> 323<br> &#324; -> 324";
#        $form .= "&#325; -> 325 &#326; -> 326 &#327; -> 327 &#328; -> 328 &#329; -> 329 &#330; -> 330 &#331; -> 331 &#332; -> 332<br> &#333; -> 333 &#334; -> 334 &#335; -> 335 &#336; -> 336 &#337; -> 337 &#338; -> 338 &#339; -> 339 &#340; -> 340 &#341; -> 341<br> &#342; -> 342 &#343; -> 343 &#344; -> 344 &#345; -> 345 &#346; -> 346 &#347; -> 347 &#348; -> 348 &#349; -> 349";
#        $form .= "&#350; -> 350<br> &#351; -> 351 &#352; -> 352 &#353; -> 353 &#354; -> 354 &#355; -> 355 &#356; -> 356 &#357; -> 357 &#358; -> 358 &#359; -> 359<br> &#360; -> 360 &#361; -> 361 &#362; -> 362 &#363; -> 363 &#364; -> 364 &#365; -> 365 &#366; -> 366 &#367; -> 367 &#368; -> 368<br> &#369; -> 369 &#370; -> 370 &#371; -> 371 &#372; -> 372 &#373; -> 373 &#374; -> 374";
#        $form .= "&#375; -> 375 &#376; -> 376 &#377; -> 377<br> &#378; -> 378 &#379; -> 379 &#380; -> 380 &#381; -> 381 &#382; -> 382 &#383; -> 383 &#384; -> 384 &#385; -> 385 &#386; -> 386<br> &#387; -> 387 &#388; -> 388 &#389; -> 389 &#390; -> 390 &#391; -> 391 &#392; -> 392 &#393; -> 393 &#394; -> 394 &#395; -> 395<br> &#396; -> 396 &#397; -> 397 &#398; -> 398 &#399; -> 399";
#        $form .= "&#400; -> 400 &#401; -> 401 &#402; -> 402 &#403; -> 403 &#404; -> 404<br> &#405; -> 405 &#406; -> 406 &#407; -> 407 &#408; -> 408 &#409; -> 409 &#410; -> 410 &#411; -> 411 &#412; -> 412 &#413; -> 413<br> &#414; -> 414 &#415; -> 415 &#416; -> 416 &#417; -> 417 &#418; -> 418 &#419; -> 419 &#420; -> 420 &#421; -> 421 &#422; -> 422<br> &#423; -> 423 &#424; -> 424";
#        $form .= "&#425; -> 425 &#426; -> 426 &#427; -> 427 &#428; -> 428 &#429; -> 429 &#430; -> 430 &#431; -> 431<br> &#432; -> 432 &#433; -> 433 &#434; -> 434 &#435; -> 435 &#436; -> 436 &#437; -> 437 &#438; -> 438 &#439; -> 439 &#440; -> 440<br> &#441; -> 441 &#442; -> 442 &#443; -> 443 &#444; -> 444 &#445; -> 445 &#446; -> 446 &#447; -> 447 &#448; -> 448 &#449; -> 449<br>";
#        $form .= "&#450; -> 450 &#451; -> 451 &#452; -> 452 &#453; -> 453 &#454; -> 454 &#455; -> 455 &#456; -> 456 &#457; -> 457 &#458; -> 458<br> &#459; -> 459 &#460; -> 460 &#461; -> 461 &#462; -> 462 &#463; -> 463 &#464; -> 464 &#465; -> 465 &#466; -> 466 &#467; -> 467<br> &#468; -> 468 &#469; -> 469 &#470; -> 470 &#471; -> 471 &#472; -> 472 &#473; -> 473 &#474; -> 474";
#        $form .= "&#475; -> 475 &#476; -> 476<br> &#477; -> 477 &#478; -> 478 &#479; -> 479 &#480; -> 480 &#481; -> 481 &#482; -> 482 &#483; -> 483 &#484; -> 484 &#485; -> 485<br> &#486; -> 486 &#487; -> 487 &#488; -> 488 &#489; -> 489 &#490; -> 490 &#491; -> 491 &#492; -> 492 &#493; -> 493 &#494; -> 494<br> &#495; -> 495 &#496; -> 496 &#497; -> 497 &#498; -> 498 &#499; -> 499";
#        $form .= "&#500; -> 500 &#501; -> 501 &#502; -> 502 &#503; -> 503<br> &#504; -> 504 &#505; -> 505 &#506; -> 506 &#507; -> 507 &#508; -> 508 &#509; -> 509 &#510; -> 510 &#511; -> 511 &#512; -> 512<br> &#513; -> 513 &#514; -> 514 &#515; -> 515 &#516; -> 516 &#517; -> 517 &#518; -> 518 &#519; -> 519 &#520; -> 520 &#521; -> 521<br> &#522; -> 522 &#523; -> 523 &#524; -> 524";
#        $form .= "&#525; -> 525 &#526; -> 526 &#527; -> 527 &#528; -> 528 &#529; -> 529 &#530; -> 530<br> &#531; -> 531 &#532; -> 532 &#533; -> 533 &#534; -> 534 &#535; -> 535 &#536; -> 536 &#537; -> 537 &#538; -> 538 &#539; -> 539<br> &#540; -> 540 &#541; -> 541 &#542; -> 542 &#543; -> 543 &#544; -> 544 &#545; -> 545 &#546; -> 546 &#547; -> 547 &#548; -> 548<br> &#549; -> 549";
#        $form .= "&#550; -> 550 &#551; -> 551 &#552; -> 552 &#553; -> 553 &#554; -> 554 &#555; -> 555 &#556; -> 556 &#557; -> 557<br> &#558; -> 558 &#559; -> 559 &#560; -> 560 &#561; -> 561 &#562; -> 562 &#563; -> 563 &#564; -> 564 &#565; -> 565 &#566; -> 566<br> &#567; -> 567 &#568; -> 568 &#569; -> 569 &#570; -> 570 &#571; -> 571 &#572; -> 572 &#573; -> 573 &#574; -> 574";
#        $form .= "&#575; -> 575<br> &#576; -> 576 &#577; -> 577 &#578; -> 578 &#579; -> 579 &#580; -> 580 &#581; -> 581 &#582; -> 582 &#583; -> 583 &#584; -> 584<br> &#585; -> 585 &#586; -> 586 &#587; -> 587 &#588; -> 588 &#589; -> 589 &#590; -> 590 &#591; -> 591 &#592; -> 592 &#593; -> 593<br> &#594; -> 594 &#595; -> 595 &#596; -> 596 &#597; -> 597 &#598; -> 598 &#599; -> 599";
#        $form .= "&#600; -> 600 &#601; -> 601 &#602; -> 602<br> &#603; -> 603 &#604; -> 604 &#605; -> 605 &#606; -> 606 &#607; -> 607 &#608; -> 608 &#609; -> 609 &#610; -> 610 &#611; -> 611<br> &#612; -> 612 &#613; -> 613 &#614; -> 614 &#615; -> 615 &#616; -> 616 &#617; -> 617 &#618; -> 618 &#619; -> 619 &#620; -> 620<br> &#621; -> 621 &#622; -> 622 &#623; -> 623 &#624; -> 624";
#        $form .= "&#625; -> 625 &#626; -> 626 &#627; -> 627 &#628; -> 628 &#629; -> 629<br> &#630; -> 630 &#631; -> 631 &#632; -> 632 &#633; -> 633 &#634; -> 634 &#635; -> 635 &#636; -> 636 &#637; -> 637 &#638; -> 638<br> &#639; -> 639 &#640; -> 640 &#641; -> 641 &#642; -> 642 &#643; -> 643 &#644; -> 644 &#645; -> 645 &#646; -> 646 &#647; -> 647<br> &#648; -> 648 &#649; -> 649";
#        $form .= "&#650; -> 650 &#651; -> 651 &#652; -> 652 &#653; -> 653 &#654; -> 654 &#655; -> 655 &#656; -> 656<br> &#657; -> 657 &#658; -> 658 &#659; -> 659 &#660; -> 660 &#661; -> 661 &#662; -> 662 &#663; -> 663 &#664; -> 664 &#665; -> 665<br> &#666; -> 666 &#667; -> 667 &#668; -> 668 &#669; -> 669 &#670; -> 670 &#671; -> 671 &#672; -> 672 &#673; -> 673 &#674; -> 674<br>";
#        $form .= "&#675; -> 675 &#676; -> 676 &#677; -> 677 &#678; -> 678 &#679; -> 679 &#680; -> 680 &#681; -> 681 &#682; -> 682 &#683; -> 683<br> &#684; -> 684 &#685; -> 685 &#686; -> 686 &#687; -> 687 &#688; -> 688 &#689; -> 689 &#690; -> 690 &#691; -> 691 &#692; -> 692<br> &#693; -> 693 &#694; -> 694 &#695; -> 695 &#696; -> 696 &#697; -> 697 &#698; -> 698 &#699; -> 699";
#        $form .= "&#700; -> 700 &#701; -> 701<br> &#702; -> 702 &#703; -> 703 &#704; -> 704 &#705; -> 705 &#706; -> 706 &#707; -> 707 &#708; -> 708 &#709; -> 709 &#710; -> 710<br> &#711; -> 711 &#712; -> 712 &#713; -> 713 &#714; -> 714 &#715; -> 715 &#716; -> 716 &#717; -> 717 &#718; -> 718 &#719; -> 719<br> &#720; -> 720 &#721; -> 721 &#722; -> 722 &#723; -> 723 &#724; -> 724";
#        $form .= "&#725; -> 725 &#726; -> 726 &#727; -> 727 &#728; -> 728<br> &#729; -> 729 &#730; -> 730 &#731; -> 731 &#732; -> 732 &#733; -> 733 &#734; -> 734 &#735; -> 735 &#736; -> 736 &#737; -> 737<br> &#738; -> 738 &#739; -> 739 &#740; -> 740 &#741; -> 741 &#742; -> 742 &#743; -> 743 &#744; -> 744 &#745; -> 745 &#746; -> 746<br> &#747; -> 747 &#748; -> 748 &#749; -> 749";
#        $form .= "&#750; -> 750 &#751; -> 751 &#752; -> 752 &#753; -> 753 &#754; -> 754 &#755; -> 755<br> &#756; -> 756 &#757; -> 757 &#758; -> 758 &#759; -> 759 &#760; -> 760 &#761; -> 761 &#762; -> 762 &#763; -> 763 &#764; -> 764<br> &#765; -> 765 &#766; -> 766 &#767; -> 767 &#768; -> 768 &#769; -> 769 &#770; -> 770 &#771; -> 771 &#772; -> 772 &#773; -> 773<br> &#774; -> 774";
#        $form .= "&#775; -> 775 &#776; -> 776 &#777; -> 777 &#778; -> 778 &#779; -> 779 &#780; -> 780 &#781; -> 781 &#782; -> 782<br> &#783; -> 783 &#784; -> 784 &#785; -> 785 &#786; -> 786 &#787; -> 787 &#788; -> 788 &#789; -> 789 &#790; -> 790 &#791; -> 791<br> &#792; -> 792 &#793; -> 793 &#794; -> 794 &#795; -> 795 &#796; -> 796 &#797; -> 797 &#798; -> 798 &#799; -> 799";
#        $form .= "&#800; -> 800<br> &#801; -> 801 &#802; -> 802 &#803; -> 803 &#804; -> 804 &#805; -> 805 &#806; -> 806 &#807; -> 807 &#808; -> 808 &#809; -> 809<br> &#810; -> 810 &#811; -> 811 &#812; -> 812 &#813; -> 813 &#814; -> 814 &#815; -> 815 &#816; -> 816 &#817; -> 817 &#818; -> 818<br> &#819; -> 819 &#820; -> 820 &#821; -> 821 &#822; -> 822 &#823; -> 823 &#824; -> 824";
#        $form .= "&#825; -> 825 &#826; -> 826 &#827; -> 827<br> &#828; -> 828 &#829; -> 829 &#830; -> 830 &#831; -> 831 &#832; -> 832 &#833; -> 833 &#834; -> 834 &#835; -> 835 &#836; -> 836<br> &#837; -> 837 &#838; -> 838 &#839; -> 839 &#840; -> 840 &#841; -> 841 &#842; -> 842 &#843; -> 843 &#844; -> 844 &#845; -> 845<br> &#846; -> 846 &#847; -> 847 &#848; -> 848 &#849; -> 849";
#        $form .= "&#850; -> 850 &#851; -> 851 &#852; -> 852 &#853; -> 853 &#854; -> 854<br> &#855; -> 855 &#856; -> 856 &#857; -> 857 &#858; -> 858 &#859; -> 859 &#860; -> 860 &#861; -> 861 &#862; -> 862 &#863; -> 863<br> &#864; -> 864 &#865; -> 865 &#866; -> 866 &#867; -> 867 &#868; -> 868 &#869; -> 869 &#870; -> 870 &#871; -> 871 &#872; -> 872<br> &#873; -> 873 &#874; -> 874";
#        $form .= "&#875; -> 875 &#876; -> 876 &#877; -> 877 &#878; -> 878 &#879; -> 879 &#880; -> 880 &#881; -> 881<br> &#882; -> 882 &#883; -> 883 &#884; -> 884 &#885; -> 885 &#886; -> 886 &#887; -> 887 &#888; -> 888 &#889; -> 889 &#890; -> 890<br> &#891; -> 891 &#892; -> 892 &#893; -> 893 &#894; -> 894 &#895; -> 895 &#896; -> 896 &#897; -> 897 &#898; -> 898 &#899; -> 899<br>";
#        $form .= "&#900; -> 900 &#901; -> 901 &#902; -> 902 &#903; -> 903 &#904; -> 904 &#905; -> 905 &#906; -> 906 &#907; -> 907 &#908; -> 908<br> &#909; -> 909 &#910; -> 910 &#911; -> 911 &#912; -> 912 &#913; -> 913 &#914; -> 914 &#915; -> 915 &#916; -> 916 &#917; -> 917<br> &#918; -> 918 &#919; -> 919 &#920; -> 920 &#921; -> 921 &#922; -> 922 &#923; -> 923 &#924; -> 924";
#        $form .= "&#925; -> 925 &#926; -> 926<br> &#927; -> 927 &#928; -> 928 &#929; -> 929 &#930; -> 930 &#931; -> 931 &#932; -> 932 &#933; -> 933 &#934; -> 934 &#935; -> 935<br> &#936; -> 936 &#937; -> 937 &#938; -> 938 &#939; -> 939 &#940; -> 940 &#941; -> 941 &#942; -> 942 &#943; -> 943 &#944; -> 944<br> &#945; -> 945 &#946; -> 946 &#947; -> 947 &#948; -> 948 &#949; -> 949";
#        $form .= "&#950; -> 950 &#951; -> 951 &#952; -> 952 &#953; -> 953<br> &#954; -> 954 &#955; -> 955 &#956; -> 956 &#957; -> 957 &#958; -> 958 &#959; -> 959 &#960; -> 960 &#961; -> 961 &#962; -> 962<br> &#963; -> 963 &#964; -> 964 &#965; -> 965 &#966; -> 966 &#967; -> 967 &#968; -> 968 &#969; -> 969 &#970; -> 970 &#971; -> 971<br> &#972; -> 972 &#973; -> 973 &#974; -> 974";
#        $form .= "&#975; -> 975 &#976; -> 976 &#977; -> 977 &#978; -> 978 &#979; -> 979 &#980; -> 980<br> &#981; -> 981<br> &#982; -> 982<br> &#983; -> 983<br> &#984; -> 984<br> &#985; -> 985<br> &#986; -> 986<br> &#987; -> 987<br> &#988; -> 988<br> &#989; -> 989<br> &#990; -> 990<br> &#991; -> 991<br> &#992; -> 992<br> &#993; -> 993<br> &#994; -> 994<br> &#995; -> 995<br> &#996; -> 996<br> &#997; -> 997<br> &#998; -> 998<br> &#999; -> 999<br>";

        $form .= "<a id=\"resubmit\" href=\"$min_cmc&$max_cmc&$use_red&$use_green&$use_blue&$use_black&$use_white&$use_uncoloured&$use_full_format&$use_block&$use_unique&$card_text&$community_rating\">Resubmit</a><br>";
        $form .= "</form>";

        {
            print ("calling = get_filtered_cards_advanced (\@ac, $min_cmc, $max_cmc, $use_red, $use_green, $use_blue, $use_black, $use_white, $use_uncoloured, $use_full_format, $use_block, $use_unique, $card_text, $card_name, $community_rating);\n");
            my $txt = get_filtered_cards_advanced (\@ac, $min_cmc, $max_cmc, $use_red, $use_green, $use_blue, $use_black, $use_white, $use_uncoloured, $use_full_format, $use_block, $use_unique, $card_text, $card_name, $community_rating);
            $txt =~ s/\n\n/\n/gim;
            $txt =~ s/\n\n/\n/gim;
            my $copy = $txt;
            my $set = expansion ();
            #$txt =~ s/^([^\|]*)\|([^\|]*)\|([^\|]*)\|([^\|]*)\|([^\|]*)\|([^\|]*)\|.*/$1|$2|$3|$4|$5|$6<br>/gim; #<< normal one..
            if (!($use_full_format eq "true"))
            {
                $txt =~ s/^([^\|]*)\|([^\|]*)\|([^\|]*)\|([^\|]*)\|([^\|]*)\|([^\|]*)\|.*/1 $1 xx $2<br>/gim; #<< for entering rares one..
                $txt =~ s/xx.*\[/[/gim;
            }
            else
            {
                $txt =~ s/$/<br>/gim; #<< for entering rares one..
            }

            my $set = '<a href="http://gatherer.wizards.com/Pages/Search/Default.aspx?output=compact&sort=rating-&action=advanced&set=|[%22Dragons%20of%20Tarkir%22]"> All </a> &nbsp;' .
                '<a href="http://gatherer.wizards.com/Pages/Search/Default.aspx?output=compact&sort=rating-&action=advanced&set=|[%22Dragons%20of%20Tarkir%22]&color=%20[C]"> Colourless </a> &nbsp;<br>' .
                '<a href="https://scryfall.com/search?q=oracle:/' . $card_text . '/">Scryfall text</a><br>' .
                '<a href="https://scryfall.com/search?q=name:/' . $card_name . '/">Scryfall name</a><br>' .
                '<a href="https://scryfall.com/search?q=oracle:/' . $card_text . '/ name:/' . $card_name . '/">Scryfall both name/text</a><br>';

            $txt = "<style>p.a{font-family:\"Courier New\", Times, serif;}</style><font color=blue size=+3>MAGIC CARDS </font><font color=green size=+1><a href='http://127.0.0.1:60001/blah'>Deck input </a></font>&nbsp;&nbsp;<font color=red size=+1><a href='http://127.0.0.1:60000/dragons.*tarkir&dragons.*tarkir&fate.*reforged&8&1&1'>Draft (DTK,DTK,FRF)</a></font><br>$form<br>Example <a href='filter?0&89&0&0&0&0&0&0&false&false&false&dragons.*tarkir&.*&.*'>DTK</a>&nbsp;&nbsp; Example <a href='filter?0&89&0&0&0&0&0&0&false&false&false&dragons.*tarkir.*rare&.*&.*'>DTK (Rare)</a><br>Example <a href='filter?0&89&0&0&0&0&0&0&false&false&false&Fate.*Reforged&.*&.*'>FRF</a>&nbsp;&nbsp; Example <a href='filter?0&89&0&0&0&0&0&0&false&false&false&Fate.*Reforged.*rare&.*&.*'>FRF (Rare)</a> <br> Only planeswalkers: <a href='filter?0&89&0&0&0&0&0&0&false&false&false&.*types.*planeswalker.*cardtext.*&.*&[1234]..*'>Planewalkers</a> <br> View by expansion set: <a href='all_sets'>See the sets</a></br> <br> View EDH lands: <a href='edh_lands'>See EDH lands</a><br> $set <br> <p class=\"a\">$txt</p>";
            $txt = $txt . " $set";
            #Example <a href='filter?3&8&1&2&1&1&1&0&creature&nacatl&.*'>Green cool search</a> <br>



            write_to_socket (\*CLIENT, $txt, "", "noredirect");
            $have_to_write_to_socket = 0;
            #close CLIENT;
        }

        print ("============================================================\n");
    }
}
