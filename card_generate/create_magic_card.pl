#!/usr/bin/perl
##
#   File : create_magic_card.pl
#   Date : 06/June/2016
#   Author : spjspj
#   Purpose : Use the templates found in examples to create land html (similar to how http://ct-magefree.rhcloud.com/ does it , but with more updated thingos)
##  

use strict;
use LWP::Simple;
use Socket;
use File::Copy;

my %all_cards;
my %card_names;
my %stripped_card_names;
my %original_lines;
my %card_text;
my %card_rarity;
my %card_cost;
my %card_type;
my %card_power;
my %card_toughness;
my %card_rating;
my %card_converted_cost;
my %all_cards_abilities;
my %expansion;

my %card;

my %main_turn_structure;
my $active_player;
my $who_has_priority;

# The current turn..
my $current_player = 1;

# Filter for a sublist of cards in X (i.e. hand, deck, graveyard, exiled, named, tapped, type (artifact,sorcery,enchantment,equipment,creature), )

sub find_id_from_card_name
{
    my $name = $_ [0];
    my $id;
    foreach $id (keys (%card_names))
    {
        if ($name eq $card_names{$id})
        {
            return $id;
        }
    }
    return -1;
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

sub card_rating
{
    my $id = $_ [0];
    return ($card_rating {$id});
}

sub expansion
{
    my $id = $_ [0];
    return ($expansion {$id});
}

sub card_toughness
{
    my $id = $_ [0];
    return ($card_toughness {$id});
}
sub card_power
{
    my $id = $_ [0];
    return ($card_power {$id});
}
sub card_rarity
{
    my $id = $_ [0];
    return ($card_rarity {$id});
}

sub old_read_all_cards
{
    # change to new version of reading cards from file.. 20230202
    open ALL, "D:/perl_programs/all_magic_cards.txt";

    while (<ALL>)
    {
        chomp $_;
        my $line = $_;
        my @fields = split /;;;/, $line;
        $all_cards {$fields [0]} = $line;
        my $f;
        $original_lines {$fields [0]} = $line;

        foreach $f (@fields)
        {
            if ($f =~ m/Card\s*Name:(.*)/i)
            {
                $card_names {$fields [0]} = $1;

                my $cn = $1;
                $cn =~ s/\W//g;
                $stripped_card_names {$fields [0]} = $cn;
            }
            if ($f =~ m/Card\s*Text:(.*)/i)
            {
                $card_text {$fields [0]} = $1;
            }
            if ($f =~ m/^Mana\s*Cost:(.*)/i)
            {
                $card_cost {$fields [0]} = $1;
            }
            if ($f =~ m/ConvertedMana\s*Cost:(.*)/i)
            {
                $card_converted_cost {$fields [0]} = $1;
            }
            if ($f =~ m/Types:(.*)/i)
            {
                $card_type {$fields [0]} = $1;
            }
            if ($f =~ m/Rating.*:(.*)/i)
            {
                $card_rating {$fields [0]} = $1;
            }
            if ($f =~ m/Expansion\s*:(.*)/i)
            {
                $expansion {$fields [0]} = $1;
            }
        }
    }
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

sub read_all_cards
{
    # 20190322 - Use the xmage version of the cards..
    my $CURRENT_FILE = "c:/xmage_clean/mage/Utils/mtg-cards-data.txt";
    open ALL, $CURRENT_FILE; 
    print ("Reading from $CURRENT_FILE\n");

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
        my $expansion = expansion_trigraph ($fields [1]);

        {
            $card_names {$combined_name} = $fields [0];
            $cards_count++;
            $expansion {$combined_name} = $expansion;
            $card_rarity {$combined_name} = $fields [3];
            $card_cost {$combined_name} = $fields [4];
            $card_type {$combined_name} = $fields [5];
            $card_power {$combined_name} = $fields [6];
            $card_toughness {$combined_name} = $fields [7];
            $card_text {$combined_name} = $fields [8];

            $fields [4] =~ s/{X//g;
            $fields [4] =~ s/{Y//g;
            $fields [4] =~ s/[^{]//g;
            $card_converted_cost {$combined_name} = length($fields [4]);
        }
    }
    print ("Read in: $cards_count cards in total\n");
}

sub write_to_socket
{
    my $sock_ref = $_ [0];
    my $msg_body = $_ [1];
    my $form = $_ [2];
    my $redirect = $_ [3];
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    my $yyyymmddhhmmss = sprintf "%.4d%.2d%.2d-%.2d%.2d%.2d", $year+1900, $mon+1, $mday, $hour,  $min, $sec;
    print $yyyymmddhhmmss, "\n";

    $msg_body = '<html><head><META HTTP-EQUIV="CACHE-CONTROL" CONTENT="NO-CACHE"><br><META HTTP-EQUIV="EXPIRES" CONTENT="Mon, 22 Jul 2094 11:12:01 GMT"></head><body>' . $form . $msg_body . "</body></html>";

    my $header;
    if ($redirect =~ m/^redirect(\d)/i)
    {
        $header = "HTTP/1.1 301 Moved\nLocation: /full$1\nLast-Modified: $yyyymmddhhmmss\nConnection: close\nContent-Type: text/html; charset=UTF-8\nContent-Length: " . length ($msg_body) . "\n\n";
    }
    elsif ($redirect =~ m/^noredirect/i)
    {
        $header = "HTTP/1.1 200 OK\nLast-Modified: $yyyymmddhhmmss\nConnection: close\nContent-Type: text/html; charset=UTF-8\nContent-Length: " . length ($msg_body) . "\n\n";
    }

    $msg_body =~ s/\n\n/\n/mig;
    $msg_body =~ s/\n\n/\n/mig;
    $msg_body =~ s/\n\n/\n/mig;
    $msg_body = $header . $msg_body;
    #$msg_body .= chr(13) . chr(10);
    $msg_body .= chr(13) . chr(10) . "0";
    #print ("\n===========\nWrite to socket: $msg_body\n==========\n");

    #unless (defined (syswrite ($sock_ref, $msg_body)))
    #{
    #    return 0;
    #}
    #print ("\n&&&$redirect&&&&&&&&&&&&\n", $msg_body, "\nRRRRRRRRRRRRRR\n");
    syswrite ($sock_ref, $msg_body);
}
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
                return "resend";
            }
            $header .= $ch;
            {
                my $h = $header;
                $h =~ s/(.)/",$1-" . ord ($1) . ";"/emg;
            }
        }
        $num_chars_read++;
        
    }

    #print "\n++++++++++++++++++++++\n", $header, "\n";
    return $header;
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
    my $port = 33334;
    my $trusted_client;
    my $data_from_client;
    $|=1;
    read_all_cards;

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
    print ("Library comes from - c:/xmage_clean/mage/Utils/mtg-cards-data.txt\n");

    while ($paddr = accept (CLIENT, SERVER))
    {
        ($client_port, $iaddr) = sockaddr_in ($paddr);
        $client_addr = inet_ntoa ($iaddr);
        #print ("\n$client_addr\n");

        my $txt = read_from_socket (\*CLIENT);
        my $orig_txt = $txt;

        $txt =~ s/%0D/___/img;
        $txt =~ s/%0A/YYY/img;
        $txt =~ s/%5C/\\/img;
        $txt =~ s/%22/"/img;
        $txt =~ s/%3A/:/img;
        $txt =~ s/%3F/?/img;
        $txt =~ s/%24/\$/img;
        $txt =~ s/%22/"/img;
        $txt =~ s/%20/ /img;
        $txt =~ s/%27/'/img;
        $txt =~ s/%25/%/img;
        $txt =~ s/%2B/+/img;
        $txt =~ s/%2F/\//img;
        $txt =~ s/%5C/\//img;
        $txt =~ s/%2C/,/img;
        $txt =~ s/%5B/[/img;
        $txt =~ s/%5D/]/img;
        $txt =~ s/%5E/^/img;
        $txt =~ s/%7C/|/img;
        $txt =~ s/%7B/{/img;
        $txt =~ s/%7D/}/img;
        $txt =~ s/%3C/</img;
        $txt =~ s/%3E/>/img;
        $txt =~ s/%3B/;/img;
        $txt =~ s/\+/ /img;

        if ($txt =~ m/.*favico.*/m)
        {
            my $size = -s ("D:/perl_programs/aaa.jpg");
            print (">>>>> size for favico = $size\n");
            my $h = "HTTP/1.1 200 OK\nLast-Modified: 20150202020202\nConnection: close\nContent-Type: image/jpeg\nContent-Length: $size\n\n";
            #print "===============\n", $h, "\n^^^^^^^^^^^^^^^^^^^\n";
            syswrite (\*CLIENT, $h);
            copy "D:/perl_programs/aaa.jpg", \*CLIENT;
            #sleep (1);
            next;
        }

        if ($txt =~ m/.*resource.*FACE(.*(jpg|bmp|png)) HTTP/mi)
        {
            my $file = "D:/xmage_images/FACE/$1";
            $file =~ s/\.\.//g;
            $file =~ s/\//\\/img;
            $file =~ s/\//\\/img;
            $file =~ s/\\\\/\\/img;
            my $size = -s ("$file");
            if ($size == 0)
            {
                print (">>>>> bad FACE $file\n");
                if ($file =~ m/(.*FACE[\/\\]).+?[\/\\](.*)/)
                {
                    print (">>>>> in here bad FACE $file\n");
                    my $cmd = "dir /a /b /s $1 | find /I \"$2\"";
                    my $output = `$cmd`;
                    if ($output =~ m/^(.*)\n/img)
                    {
                        $file = $1;
                        $size = -s ("$file");
                        print ("Updated it to $file!\n");
                    }
                }
            }
            print (">>>>> size of $file = $size\n");
            my $h = "HTTP/1.1 200 OK\nLast-Modified: 20150202020202\nConnection: close\nContent-Type: image/jpeg\nContent-Length: $size\n\n";
            #print "===============\n", $h, "\n^^^^^^^^^^^^^^^^^^^\n";
            syswrite (\*CLIENT, $h);
            copy $file, \*CLIENT;
            next;
        }

        if ($txt =~ m/.*(resource.*(jpg|bmp|png)) HTTP/mi)
        {
            my $file = "D:/perl_programs/$1";
            $file =~ s/\.\.//g;
            $file =~ s/\//\\/img;
            my $size = -s ("$file");
            print (">>>>> size of $file = $size\n");

            if ($size == 0)
            {
                my $size = -s ("D:/perl_programs/aaa.jpg");
                print (">>>>> size = $size\n");
                my $h = "HTTP/1.1 200 OK\nLast-Modified: 20150202020202\nConnection: close\nContent-Type: image/jpeg\nContent-Length: $size\n\n";
                #print "===============\n", $h, "\n^^^^^^^^^^^^^^^^^^^\n";
                syswrite (\*CLIENT, $h);
                copy "D:/perl_programs/aaa.jpg", \*CLIENT;
                #sleep (1);
                next;
            }
            my $h = "HTTP/1.1 200 OK\nLast-Modified: 20150202020202\nConnection: close\nContent-Type: image/jpeg\nContent-Length: $size\n\n";
            #print "===============\n", $h, "\n^^^^^^^^^^^^^^^^^^^\n";
            syswrite (\*CLIENT, $h);
            copy $file, \*CLIENT;
            #sleep (1);
            next;
        }

        if ($txt =~ m/.*(resource.*) HTTP/mi)
        {
            my $file = "D:/perl_programs/show_lands/$1";
            $file =~ s/\.\.//g;

            my $size = -s ("$file");
            if (!-f ($file))
            {
                #print ("FAIL:\n $file\n");
            }
            else
            {
                #print ("$file\n");
            }
            my $h = "HTTP/1.1 200 OK\nLast-Modified: 20150202020202\nConnection: close\nContent-Type: html/txt\nContent-Length: $size\n\n";
            #print "===============\n", $h, "\n^^^^^^^^^^^^^^^^^^^\n";
            #syswrite (\*CLIENT, $h);
            #copy "$file", \*CLIENT;
            #sleep (1);
            next;
        }

        #print ("\n>>>$txt\n");
        $txt =~ s/.*cardinfo=/cardinfo=/;
        $txt =~ s/<\/i>/<\/i><br>/img;
        print ("\n>>>$txt\n");

        $txt =~ s/%../.*/img;
        $txt =~ s/___/%0D/img;
        $txt =~ s/YYY/%0A/img;
        $txt =~ s/ HTTP\/1.*//;
        chomp $txt;
        print ($txt, " hello there\n");
        $txt =~ s/GET.\/Cardtext=//img;
        ($txt, " hello there\n");


        $txt =~ s/^(.*?)\|//im;
        my $card_name = $1;
        $txt =~ s/^(.*?)\|//im;
        $txt =~ s/^(.*?)\|//im;
        $txt =~ s/^(.*?)\|//im;
        my $rarity = $1;
        $txt =~ s/^(.*?)\|//im;
        my $casting_cost = $1;
        $txt =~ s/^(.*?)\|//im;
        my $type = $1;
        my $p = -10;
        $txt =~ s/^(.*?)\|//im;
        $p = $1;
        my $t = -10;
        $txt =~ s/^(.*?)\|//im;
        $t = $1;
        $txt =~ s/^(.*?)(\||$)//im;
        my $text = $1;
        my $flavour = "";
        my $use_flavour = 0;
        if ($txt =~ s/^(.+?)(\||$)//im)
        {
            $flavour = $1;
            $use_flavour = 1;
        }

        print ("card_name =$card_name\n");
        print ("rarity =$rarity\n");
        print ("Changed $rarity to ... ");
        $rarity = uc ($rarity);
        $rarity =~ s/^(.).*/$1/img;
        print ("$rarity\n");
        print ("type =$type\n");
        print ("p =$p\n");
        print ("t =$t\n");
        print ("text =$text\n");
        print ("flavour ($use_flavour) =$flavour\n");


        my $w = 0;
        my $u = 0;
        my $b = 0;
        my $r = 0;
        my $g = 0;
        my $a = 0;
        my $m = 0;


        my $value = '
            <html>
            <body>
            <table>
            <tr>
            <td id="cardDisplay">
            BG_IMG_PLACE_HOLDER';

        my $left_value = -1;
        my $only_colour = '';
        my $first_colour = '';
        my $second_colour = '';
        my $stamp_first_colour = '';
        my $stamp_second_colour = '';
        my $mana_cost = "";

        while ($casting_cost =~ s/\{(.{1,2})\}[^{]*$//im)
            {
                my $mana_symbol = $1;
                my $hybrid_mana_symbol = 0;

                if ($mana_symbol =~ m/[wubrg][wubrg]/im)
                {
                    if ($left_value == -1)
                    {
                        $left_value = 345;  # Minus 20??
                    }
                    $left_value = $left_value - 20;

                    $hybrid_mana_symbol = 1;
                    $mana_cost .= '                <img height="21px" style="position: absolute; top:30px; left:' . $left_value . 'px;" src="resources/mana_shadow/MANA_' . $mana_symbol . '.png">';
                    $mana_cost .= "\n";
                }
                elsif ($mana_symbol =~ m/[WUBRG]/)
                {
                    if ($left_value == -1)
                    {
                        $left_value = 345;  # Minus 20??
                    }
                    $left_value = $left_value - 20;

                    $mana_cost .= '                <img height="21px" style="position: absolute; top:30px; left:' . $left_value . 'px;" src="resources/mana_shadow/MANA_' . $mana_symbol . '.png">';
                    $mana_cost .= "\n";
                }
                else # Number
                {
                    if ($left_value == -1)
                    {
                        $left_value = 345;  # Minus 27??
                    }
                    $left_value = $left_value - 20;
                    $mana_cost .= '                <img height="21px" style="position: absolute; top:30px; left:' . $left_value . 'px;" src="resources/mana_shadow/MANA_' . $mana_symbol . '.png">';
                    $mana_cost .= "\n";
                }

                if ($mana_symbol =~ m/w/i)
                {
                    $w = 1;
                    $only_colour = 'w';
                    if ($first_colour =~ m/^$/) { $first_colour = $only_colour; }
                    else { $second_colour = $only_colour; }
                }

                if ($mana_symbol =~ m/u/im)
                {
                    $u = 1;
                    $only_colour = 'u';
                    if ($first_colour =~ m/^$/) { $first_colour = $only_colour; }
                    else { $second_colour = $only_colour; }
                }

                if ($mana_symbol =~ m/b/im)
                {
                    $b = 1;
                    $only_colour = 'b';
                    if ($first_colour =~ m/^$/) { $first_colour = $only_colour; }
                    else { $second_colour = $only_colour; }
                }

                if ($mana_symbol =~ m/r/im)
                {
                    $r = 1;
                    $only_colour = 'r';
                    if ($first_colour =~ m/^$/) { $first_colour = $only_colour; }
                    else { $second_colour = $only_colour; }
                }

                if ($mana_symbol =~ m/g/im)
                {
                    $g = 1;
                    $only_colour = 'g';
                    if ($first_colour =~ m/^$/) { $first_colour = $only_colour; }
                    else { $second_colour = $only_colour; }
                }

            }

            $value .= $mana_cost;

            while ($text =~ s/\{([WUBRG][WUBRG])}/<img style="height: 16px;" src="resources\/mana\/mana_$1.png">/im)
            {
                my $colour = $1;
                my $two_colour = $1;
                if ($colour =~ m/W/im) { $w = 1; }
                if ($colour =~ m/U/im) { $u = 1; }
                if ($colour =~ m/B/im) { $b = 1; }
                if ($colour =~ m/R/im) { $r = 1; }
                if ($colour =~ m/G/im) { $g = 1; }
            }

            while ($text =~ s/\{([WUBRG])\}/<img style="height: 16px;" src="resources\/mana\/mana_$1.png">/im)
            {
                my $colour = $1;
                if ($colour =~ m/W/im) { $w = 1; }
                if ($colour =~ m/U/im) { $u = 1; }
                if ($colour =~ m/B/im) { $b = 1; }
                if ($colour =~ m/R/im) { $r = 1; }
                if ($colour =~ m/G/im) { $g = 1; }
            }

            my $total_color = $w + $u + $b + $r + $g;
            my $colour = '';
            my $artifact_border = 0;

            if ($total_color > 2 && $type =~ m/land/i) { $colour = 'ml'; $first_colour = "ml"; }
            if ($total_color > 2 && $type !~ m/land/i) { $colour = 'm'; $first_colour = "m"; }
            if ($total_color == 2 && $type =~ m/land/i) { $colour = $first_colour . "l"; }
            if ($total_color == 2 && $type !~ m/land/i) { $colour = $first_colour; }
            if ($total_color == 1 && $type =~ m/land/i) { $colour = "$only_colour" . "l"; $first_colour = $colour; }
            if ($total_color == 1 && $type !~ m/land/i) { $colour = "$only_colour"; $first_colour = $colour; }
            if ($total_color == 0 && $type =~ m/land/i) { $colour = "cl"; $first_colour = "cl"; }
            if ($total_color == 0 && $type !~ m/land/i) { $colour = "a";  $first_colour = "a"; }
            if ($type =~ m/artifact/i) { $artifact_border = 1; }


            print ("tot=$total_color = W$w + U$u + B$b + R$r + G$g..... $colour ... $only_colour,,, $first_colour, $second_colour\n");

            my $bg = "";

            if ($total_color > 2 || $total_color <= 1)
            {
                $bg = "<img src=\"resource_magick/magic-m15/" . $colour . "card.jpg\" style=\"position: absolute; left: 0; top: 0;\">\n";
                $stamp_first_colour = $colour;
                $stamp_second_colour = $colour;
                #if ($artifact_border == 1)
                #{
                #    #$bg .= "                <img src=\"resource_magick/acard_border_only.png\" style=\"position: absolute; top: 0px; left: 0px;\"/>\n";
                #}
            }
            else
            {
                # Switch..
                my $multi_c = 1;
                if (lc($first_colour) eq lc($second_colour))
                {
                    $multi_c = 0;
                }
                if (lc($first_colour) eq "w" && (lc($second_colour) eq "r" || lc($second_colour) eq "g") ||
                    lc($first_colour) eq "u" && (lc($second_colour) eq "g" || lc($second_colour) eq "w") ||
                    lc($first_colour) eq "b" && (lc($second_colour) eq "w" || lc($second_colour) eq "u") ||
                    lc($first_colour) eq "r" && (lc($second_colour) eq "u" || lc($second_colour) eq "b") ||
                    lc($first_colour) eq "g" && (lc($second_colour) eq "b" || lc($second_colour) eq "r")
                   )
                {
                    my $third = $first_colour;
                    $first_colour = $second_colour;
                    $second_colour = $third;
                }

                $bg =  "                <img src=\"resource_magick/magic-m15/mcard.jpg\" style=\"position: absolute; left: 0; top: 0;\">\n";
                if ($multi_c == 0)
                {
                    $bg =  "                <img src=\"resource_magick/magic-m15/" . $first_colour . "card.jpg\" style=\"position: absolute; left: 0; top: 0;\">\n";
                }
                #$bg .= "                <img src=\"resource_magick/" . $second_colour . "card.png\" style=\"position: absolute; top: 0px; left: 0px;\"/>\n";
                #$bg .= "                <img src=\"resource_magick/mcard_border_and_oval.png\" style=\"position: absolute; top: 0px; left: 0px;\"/>\n";
                $stamp_first_colour = $first_colour;
                $stamp_second_colour = $second_colour;
                $colour = "m";
                $first_colour = "m";
                #if ($artifact_border == 1)
                #{
                #    $bg .= "                <img src=\"resource_magick/acard_border_only.png\" style=\"position: absolute; top: 0px; left: 0px;\"/>\n";
                #}
            }

            $value =~ s/BG_IMG_PLACE_HOLDER/$bg/;

            if ($rarity =~ m/[MR]/img)
            {
                if ($first_colour eq "") { $first_colour = $colour; }
                $value .= '                <img style="position: absolute; top: 472px; left: 164px;" src="resources/magic-m15/' . $stamp_first_colour . 'stamp.jpg" class="stamp">'; $value .= "\n";
                if ($total_color == 2)
                {
                    $value .= '                <img style="position: absolute; top: 472px; left: 164px;" src="resource_magick/' . $stamp_second_colour . 'stamp_second.png" class="stamp">'; $value .= "\n";
                }
                $value .= '                <img style="position: absolute; top: 472px; left: 164px;" src="resources/magic-m15/foil_stamp.png" class="foil_stamp">'; $value .= "\n";
            }
            if ($type =~ m/Creature/img)
            {
                $value .= '                <img height=41px style="position: absolute; top: 465px; left: 282px;" src="resources/magic-m15/' . $colour . 'pt.png" class="stamp">'; $value .= "\n";
                #$value .= '                 <p id="ptbox" align="right" style="position: absolute; top: 443px; left: 294px;font-size: 23px; font-weight: bold; font-family: Beleren; z-index: 6;border:1px solid red;">' . $p . "/". $t .'</p>'; $value .= "\n";
                $value .= '                 <p id="ptbox" align="right" style="position: absolute; top: 445px; left: 294px;font-size: 23px; font-weight: bold; font-family: Beleren; z-index: 6;">' . $p . "/". $t .'</p>'; $value .= "\n";
            }

            $value .= '                <p style="font-color=black; position: absolute; top: 11px; left: 29px; font-size: 18px; font-weight: bold; font-family: Beleren; z-index: 6;">' . $card_name . '</p>'; $value .= "\n";
            $value .= '                <p style="position: absolute; top: 282px; left: 29px; font-size: 16px; font-weight: bold; font-family: Beleren; z-index: 6;">' . $type . '</p>'; $value .= "\n";


            $text =~ s/[\$\&]/<\/p><br>\n                <p id=TEXT_TO_BE_NUMBERED style="position: absolute; top: 322px; left: 32px; width: 306px; font-family: Times New Roman; line-height: 95%;">/img;
            $text =~ s/<i>(.*?)<\/i>/<\/p><br>\n                <p id=TEXT_TO_BE_NUMBERED style="position: absolute; top: 322px; left: 32px; width: 306px; font-family: Times New Roman; line-height: 95%;"><i>$1<\/i>/img;
            $text =~ s/{tap}/<img style="height: 16px;" src="resources\/mana\/mana_T.png">/img;
            $text =~ s/\{(.)\}/<img style="height: 16px;" src="resources\/mana\/mana_$1.png">/img;


            my $oracle_text = '                <p id=TEXT_TO_BE_NUMBERED style="position: absolute; top: 322px; left: 32px; width: 306px; font-family: Times New Roman; line-height: 95%;">';
            $oracle_text .= $text;
            $oracle_text .= '</p>';
            $oracle_text =~ s/<p [^>]+?>[^\s\n]*?<\/p><br>//img;

            $oracle_text =~ s/TEXT_TO_BE_NUMBERED/"text1"/im;
            $oracle_text =~ s/TEXT_TO_BE_NUMBERED/"text2"/im;
            $oracle_text =~ s/TEXT_TO_BE_NUMBERED/"text3"/im;
            $oracle_text =~ s/TEXT_TO_BE_NUMBERED/"text4"/im;
            $oracle_text =~ s/TEXT_TO_BE_NUMBERED/"text5"/im;
            $oracle_text =~ s/TEXT_TO_BE_NUMBERED/"text6"/im;
            $oracle_text =~ s/TEXT_TO_BE_NUMBERED/"text7"/im;
            $oracle_text =~ s/TEXT_TO_BE_NUMBERED/"text8"/im;
            $oracle_text =~ s/TEXT_TO_BE_NUMBERED/"text9"/im;

            if ($use_flavour)
            {
                $oracle_text .= "\n";
                $flavour =~ s/[\$\&]/<\/p><br>\n                <p id=FLAVOUR_TO_BE_NUMBERED style="position: absolute; top: 322px; left: 32px; width: 306px; font-family: Times New Roman; line-height: 95%;">/img;
                $oracle_text .= '                <p id=FLAVOUR_TO_BE_NUMBERED style="position: absolute; top: 322px; left: 32px; width: 306px; font-family: Times New Roman; line-height: 95%;">';
                $oracle_text .= '                <i>' . $flavour . '</i>';
                $oracle_text .= '                </p>';
                $oracle_text .= "\n";
                $oracle_text =~ s/FLAVOUR_TO_BE_NUMBERED/"flavour1"/im;
                $oracle_text =~ s/FLAVOUR_TO_BE_NUMBERED/"flavour2"/im;
                $oracle_text =~ s/FLAVOUR_TO_BE_NUMBERED/"flavour3"/im;
                $oracle_text =~ s/FLAVOUR_TO_BE_NUMBERED/"flavour4"/im;
                $oracle_text =~ s/FLAVOUR_TO_BE_NUMBERED/"flavour5"/im;
                $oracle_text =~ s/FLAVOUR_TO_BE_NUMBERED/"flavour6"/im;
                $oracle_text =~ s/FLAVOUR_TO_BE_NUMBERED/"flavour7"/im;
                $oracle_text =~ s/FLAVOUR_TO_BE_NUMBERED/"flavour8"/im;
                $oracle_text =~ s/FLAVOUR_TO_BE_NUMBERED/"flavour9"/im;
            }

            # Find the face image for the card..
            my $id = find_id_from_card_name ($card_name);
            my $face_image = "resources/card_images/enlightened.png";
            if ($id != -1)
            {
                my $exp = expansion_trigraph (expansion ($id));
                $exp =~ s/.*\[(...)\].*/$1/;
                $face_image = "resources/FACE/$exp/$card_name.jpg";
            }

            $value .= $oracle_text . "\n";
            $value .= '                <img style="position: absolute; top: 60px; left: 29px; height: 230px; Width: 316px" src="' . $face_image . '"/>';
            $value .= "\n";
            $value .= '            </td>';
            $value .= "\n";
            $value .= '        </tr>';
            $value .= "\n";
            $value .= '    </table>';
            $value .= "\n";

            $value .= '<script type="text/javascript" language="javascript">'; $value .= "\n";
            $value .= 'function fix_spaces ()'; $value .= "\n";
            $value .= '{'; $value .= "\n";
            $value .= '    var x = document.getElementsByTagName("P");'; $value .= "\n";
            $value .= '    var i;'; $value .= "\n";
            $value .= '    var total_height = 0;'; $value .= "\n";
            $value .= '    var total_to_play_with = 116;'; $value .= "\n";
            $value .= '    var total_paras = 0;'; $value .= "\n";
            $value .= '    var total_flavour = 0;'; $value .= "\n";
            $value .= '    for (i = 0; i < x.length; i++) '; $value .= "\n";
            $value .= '    {'; $value .= "\n";
                $value .= '        if (x[i].id.startsWith ("text"))'; $value .= "\n";
                $value .= '        {'; $value .= "\n";
                    $value .= '            var rect = x[i].getBoundingClientRect();'; $value .= "\n";
                    $value .= '            total_height += (rect.bottom - rect.top);'; $value .= "\n";
                    $value .= '            total_paras ++;'; $value .= "\n";
                    $value .= '        }'; $value .= "\n";
                $value .= '        if (x[i].id.startsWith ("flavour"))'; $value .= "\n";
                $value .= '        {'; $value .= "\n";
                    $value .= '            var rect = x[i].getBoundingClientRect();'; $value .= "\n";
                    $value .= '            total_height += (rect.bottom - rect.top);'; $value .= "\n";
                    $value .= '            total_flavour ++;'; $value .= "\n";
                    $value .= '        }'; $value .= "\n";
                $value .= '    }'; $value .= "\n";
            $value .= '    var gap_between_paras = 9;'; $value .= "\n";
            $value .= '    var gap_to_flavour = 11;'; $value .= "\n";
            $value .= '    var stupid_offset = -13;'; $value .= "\n";
            $value .= '    var extras = (total_paras - 1) * gap_between_paras + gap_to_flavour;'; $value .= "\n";
            $value .= '    var left_over = total_to_play_with - total_height - extras;'; $value .= "\n";
            $value .= '    if (left_over > 35)'; $value .= "\n";
            $value .= '    {'; $value .= "\n";
                $value .= '        return 1;'; $value .= "\n";
                $value .= '    }'; $value .= "\n";
            $value .= '    if (left_over < -20)'; $value .= "\n";
            $value .= '    {'; $value .= "\n";
                $value .= '        return -1;'; $value .= "\n";
                $value .= '    } '; $value .= "\n";
            $value .= '    var required_gap_at_top = left_over / 2;'; $value .= "\n";
            $value .= '    var current_top = 340 + stupid_offset + required_gap_at_top;'; $value .= "\n";
            $value .= '    var information = "Info: gap:" + gap_between_paras + " req_gap:" + required_gap_at_top + " gap_to_flavour:" + gap_to_flavour + " total_height:" + total_height + " total_play:" + total_to_play_with ;'; $value .= "\n";
            $value .= '    information += "total_play - total_h - extras:" + extras + " ==>" + (total_to_play_with - total_height - extras);'; $value .= "\n";
            $value .= '    for (i = 0; i < x.length; i++) '; $value .= "\n";
            $value .= '    {'; $value .= "\n";
                $value .= '        if (x[i].id.startsWith ("text"))'; $value .= "\n";
                $value .= '        {'; $value .= "\n";
                    $value .= '            x[i].style.top = current_top;'; $value .= "\n";
                    $value .= '            var rect = x[i].getBoundingClientRect();'; $value .= "\n";
                    $value .= '            current_top += (rect.bottom - rect.top) + gap_between_paras;'; $value .= "\n";
                    $value .= '            information += " current_top:" + x[i].id + " >> " + current_top + " ";'; $value .= "\n";
                    $value .= '        }'; $value .= "\n";
                $value .= '        if (x[i].id.startsWith ("flavour"))'; $value .= "\n";
                $value .= '        {'; $value .= "\n";
                    $value .= '            current_top = current_top - gap_between_paras + gap_to_flavour;'; $value .= "\n";
                    $value .= '            x[i].style.top = current_top;'; $value .= "\n";
                    $value .= '            var rect = x[i].getBoundingClientRect();'; $value .= "\n";
                    $value .= '            information += "current_top:" + x[i].id + " >> " + current_top;'; $value .= "\n";
                    $value .= '        }'; $value .= "\n";
                $value .= '    }'; $value .= "\n";
            $value .= '            '; $value .= "\n";
            $value .= '    for (i = 0; i < x.length; i++) '; $value .= "\n";
            $value .= '    {'; $value .= "\n";
                $value .= '        if (x[i].id.startsWith ("ptbox"))'; $value .= "\n";
                $value .= '        {'; $value .= "\n";
                    $value .= '            var rect = x[i].getBoundingClientRect();'; $value .= "\n";
                    $value .= '            var width = (rect.right - rect.left);'; $value .= "\n";
                    $value .= '            var pt_width = 54;'; $value .= "\n";
                    $value .= '            var pt_offset = rect.left + (pt_width - width)/2;'; $value .= "\n";
                    $value .= '            pt_offset += "px";'; $value .= "\n";
                    $value .= '            x[i].style.left = pt_offset ;'; $value .= "\n";
                    $value .= '        }'; $value .= "\n";
                $value .= '        if (x[i].id.startsWith ("info"))'; $value .= "\n";
                $value .= '        {'; $value .= "\n";
                    $value .= '            x[i].innerHTML = information;'; $value .= "\n";
                    $value .= '        }'; $value .= "\n";
                $value .= '        if (x[i].id.startsWith ("full"))'; $value .= "\n";
                $value .= '        {'; $value .= "\n";
                    $value .= '            x[i].style.width = "306px";'; $value .= "\n";
                    $value .= '            x[i].style.height = total_to_play_with + "px";'; $value .= "\n";
                    $value .= '            x[i].style.top = 340 + stupid_offset;'; $value .= "\n";
                    $value .= '        }'; $value .= "\n";
                $value .= '    }'; $value .= "\n";
            $value .= '    return 0;'; $value .= "\n";
            $value .= '}'; $value .= "\n";
            $value .= 'function inc_p_size (size_inc)'; $value .= "\n";
            $value .= '{'; $value .= "\n";
            $value .= '    var x = document.getElementsByTagName("P");'; $value .= "\n";
            $value .= '    for (i = 0; i < x.length; i++) '; $value .= "\n";
            $value .= '    {'; $value .= "\n";
                $value .= '        if (x[i].id.startsWith ("text") || x[i].id.startsWith ("flavour"))'; $value .= "\n";
                $value .= '        {'; $value .= "\n";
                    $value .= '            var style = window.getComputedStyle (x[i], null).getPropertyValue ("font-size");'; $value .= "\n";
                    $value .= '            var fontSize = parseFloat (style); '; $value .= "\n";
                    $value .= '            x[i].style.fontSize = (fontSize + size_inc) + "px";'; $value .= "\n";
                    $value .= '        }'; $value .= "\n";
                $value .= '    }'; $value .= "\n";
            $value .= '}'; $value .= "\n";
            $value .= 'var count = 0;'; $value .= "\n";
            $value .= 'while (count < 5)'; $value .= "\n";
            $value .= '{'; $value .= "\n";
            $value .= '    var ok = fix_spaces ();'; $value .= "\n";
            $value .= '    if (ok == 0)'; $value .= "\n";
            $value .= '    {'; $value .= "\n";
                $value .= '        count = 5;'; $value .= "\n";
                $value .= '    }'; $value .= "\n";
            $value .= '    else if (ok == 1)'; $value .= "\n";
            $value .= '    {'; $value .= "\n";
                $value .= '       inc_p_size (1);'; $value .= "\n";
                $value .= '    }'; $value .= "\n";
            $value .= '    else if (ok == -1)'; $value .= "\n";
            $value .= '    {'; $value .= "\n";
                $value .= '       inc_p_size (-1);'; $value .= "\n";
                $value .= '    }'; $value .= "\n";
            $value .= '    count++;'; $value .= "\n";
            $value .= '}'; $value .= "\n";
            $value .= '</script>'; $value .= "\n";
            $value .= "<a href='file:///D:/perl_programs/last_card.html'>View this card</a>";
            $value .= '</body>';
            $value .= '</html>';

            $value .= "ttt<br> ttt<br> ttt<br> ttt<br> ttt<br> ttt<br> ttt<br> ttt<br> ttt<br> ttt<br> ttt<br> ttt<br> ttt<br> ttt<br> ttt<br> ttt<br> ttt<br> ttt<br> ttt<br> ttt<br> ttt<br> ttt<br> ttt<br> ttt<br> ttt<br> ttt<br> ttt<br> ttt<br> ttt<br> ttt<br> ttt<br> ttt<br> ttt<br> ttt<br> ttt<br>\n";
            $value .= "<a href='$orig_txt'>Last card link</a><br>";
            my $alt_link = "http://127.0.0.1:33334/cardtext=Sphinx of the Steel Wind|Eternal Masters|207|M|{5}{W}{U}{B}|Artifact Creature - Sphinx|6|6|Flying, first strike, vigilance, lifelink, protection from red and from green|No one has properly answered her favorite riddle: \"Why should I spare your life?\"";
            $value .= "<a href='$alt_link'>Sphinx</a><br>\n";
            $alt_link = "http://127.0.0.1:33334/cardtext=Neruron, Glittering Isle|Eternal Master|1|M||Legendary Land|||Neruron, Glittering Isle enters the battlefield tapped&{1}, {tap}: Add {G}{W}{U} to your mana pool.&If another non-basic land you control is tapped for mana, it produces colorless mana instead of any other type.|\"Its light fills the world\"|";
            $value .= "<a href='$alt_link'>Neruron</a><br>\n";
            $alt_link = "http://127.0.0.1:33334/cardtext=Brago, King Eternal|Eternal Masters|198|R|{2}{W}{U}|Legendary Creature - Spirit|2|4|Flying&When Brago, King Eternal deals combat damage to a player, exile any number of target nonland permanents you control, then return those cards to the battlefield under their owner&#39;s control.|\"My rule persists beyond death itself.\"|";
            $value .= "<a href='$alt_link'>Brago</a><br>\n";

            $alt_link = "http://127.0.0.1:33334/cardtext=Kanos, Disintegrating Reef|Eternal Master|1|M||Legendary Land|||Kanos, Disintegrating Reef enters the battlefield tapped.&{1},{t} : Add to {u}{b}{r} to your mana pool.&When Kanos, Disintegrating Reef enters the battlefield, sacrifice it unless you sacrifice 2 other untapped, non-basic lands you control.|";
            $value .= "<a href='$alt_link'>Kanos</a><br>\n";

            $alt_link = "http://127.0.0.1:33334/cardtext= Pinaren, Isolated Aerie|Eternal Master|1|M||Legendary Land|||Pinaren, Isolated Aerie enters the battlefield tapped.&At the beginning of your upkeep, sacrifice an untapped, non-basic land that could produce a colour that Pinaren, Isolated Aerie could produce or sacrifice Pinaren, Isolated Aerie&{1},{t}: Add {W}{U}{B} to your mana pool.|";
            $value .= "<a href='$alt_link'>Pinarenxxxxxxxxxxxxxx</a><br>\n";


            $alt_link = "http://127.0.0.1:33334/cardtext=Young%20Pyromancer|Eternal%20Masters|155|U|%7B1%7D%7BR%7D|Creature%20-%20Human%20Shaman|2|1|Whenever%20you%20cast%20an%20instant%20or%20sorcery%20spell,%20put%20a%201/1%20red%20Elemental%20creature%20token%20onto%20the%20battlefield.|Immolation is the sincerest form of flattery.|";
            $value .= "<a href='$alt_link'>Young Pyro</a><br>\n";
            $alt_link = "http://127.0.0.1:33334/cardtext=Rakdos Guildmage|Champs|3|Special|{BR}{BR}|Creature - Zombie Shaman|2|2|<i>({BR} can be paid with either {B} or {R}.)</i>\${3}{B}, Discard a card: Target creature gets -2/-2 until end of turn.\${3}{R}: Put a 2/1 red Goblin creature token with haste onto the battlefield. Exile it at the beginning of the next end step.|";
            $value .= "<a href='$alt_link'>Rakdos Guildmage</a><br>\n";
            $alt_link = "http://127.0.0.1:33334/cardtext=Emrakul, the Aeons Torn|Rise of the Eldrazi|4|M|{15}|Legendary Creature - Eldrazi|15|15|Emrakul, the Aeons Torn can&#39;t be countered.\$When you cast Emrakul, take an extra turn after this one.\$Flying, protection from colored spells, annihilator 6\$When Emrakul is put into a graveyard from anywhere, its owner shuffles his or her graveyard into his or her library.|";
            $value .= "<a href='$alt_link'>Emrakul</a><br>\n";

            #my $random_card_id = (%card_names)[1+2*int rand keys%card_names];
            my $random_card_id = (keys %card_names)[rand keys %card_names];
            $alt_link = "http://127.0.0.1:33334/cardtext=" . 
                card_name($random_card_id) . "|" .
                expansion($random_card_id) . "|" .
                "33|" .
                card_rarity ($random_card_id) . "|" .
                card_cost ($random_card_id) . "|" .
                card_type ($random_card_id) . "|" . 
                card_power ($random_card_id) . "|" . 
                card_toughness ($random_card_id) . "|" . 
                card_text ($random_card_id) . "|";
            $value .= " --------- $random_card_id  ---------- <a href='$alt_link'>" . card_name($random_card_id) . "</a><br>\n";

            $alt_link = "<a href='http://127.0.0.1:56789/filter?0&89&0&0&0&0&0&0&false&false&false&$card_name&.*&'>Filter</a>";
            $value .= $alt_link;
            $alt_link = "http://127.0.0.1:33334/cardtext=Emrakul, the Aeons Torn|Rise of the Eldrazi|4|M|{15}|Legendary Creature - Eldrazi|15|15|Emrakul, the Aeons Torn can&#39;t be countered.\$When you cast Emrakul, take an extra turn after this one.\$Flying, protection from colored spells, annihilator 6\$When Emrakul is put into a graveyard from anywhere, its owner shuffles his or her graveyard into his or her library.|";
            $value .= "<a href='$alt_link'>Emrakul</a><br>\n";
            $alt_link = "http://127.0.0.1:33334/cardtext=Aether Transgression|Xmage|4|M|{3}{W}{W}{U}|Legendary Enchantment|||{X}{W}{U}, {t}: Each player exiles {X} target creatures that he or she controls, then returns those cards to the battlefield under their owner&#39;s control.\$Activate this ability only if you&#39;ve controlled Aether Transgression continuously since the beginning of your most recent turn.|\"A joyful feeling of transcendency descended\"|";
            $value .= "<a href='$alt_link'>Aether Transgression</a><br>\n";
            $alt_link = "http://127.0.0.1:33334/cardtext=Enlightened Tutor|Xmage|4|M|{W}|Instant|||Search your library for an artifact or enchantment card and reveal that card. Shuffle your library, then put the card on top of it.|\"I do not teach.  I simply reveal\" -Daudi, Femeref Tutor|";
            $value .= "<a href='$alt_link'>Enlightened Tutor</a><br>\n";
            $alt_link = "<a href='file:///D:/perl_programs/last_card.html'>This card</a>";
            $value .= $alt_link;


            write_to_socket (\*CLIENT, $value, "", "noredirect");

            open TMP, ">d:/perl_programs/last_card.html";
            print (TMP $value);
            $orig_txt =~ s/GET \//http:\/\/127.0.0.1:33334\//;
            print (TMP "ttt<br> ttt<br> ttt<br> ttt<br> ttt<br> ttt<br> ttt<br> ttt<br> ttt<br> ttt<br> ttt<br> ttt<br> ttt<br> ttt<br> ttt<br> ttt<br> ttt<br> ttt<br> ttt<br> ttt<br> ttt<br> ttt<br> ttt<br> ttt<br> ttt<br>\n");
            print (TMP "<a href='$orig_txt'>Last card link</a><br>");
            close (TMP);

            #sleep (1);
            next;
    }
}
