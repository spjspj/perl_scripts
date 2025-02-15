#!/usr/bin/perl
##
#   File : mk_pss.pl
#   Date : 30/Jan/2025
#   Author : spjspj
#   Purpose : Make the PSS stuff..
##  

use strict;
use POSIX qw(strftime);
use LWP::Simple;
use Socket;
use File::Copy;
use MIME::Base64 qw(encode_base64url decode_base64url);
use Digest::MD5 qw(md5 md5_hex md5_base64);

my $a;
my $y;
my $before_99;
my $sex;
my %ABF;
my %PCF;
my %MCF;
my $DEBUG = 1;

my $Birthday;
my $RelevantDate;
my $ABM;
my $AMC;
my $APC;
my $ATA;
my $ERDA;
my $FirstDateMembership;
my $AS;
my $SurchargeDebt;
my $YearsScheme;
my $MemberAgeYears;
my $MemberAgeMonths;
my $FamilyLawValuation;
my $StartedBefore = 0;
my $MemberSex;
my $MemberInfo;
my $MemberInfo_plusone;
my $MemberName;
my $MemberReference;
my $ABFyms = -100;
my $MCFyms = -100;
my $PCFyms = -100;
my $ABFyms_plusone = -100;
my $MCFyms_plusone = -100;
my $PCFyms_plusone = -100;
my $completed_years = -100;
my $first_year;
my $first_month;
my $first_day;
my $relevant_year;
my $relevant_month;
my $relevant_day;
my $birth_year;
my $birth_month;
my $birth_day;
my $final_ABF;
my $final_MCF;
my $final_PCF;

my $now = time ();
my $starttime = $now - 7 * 24 * 3600;
my $yyyymmdd = strftime "%d-%b-%Y %H:%M", localtime($starttime);
$yyyymmdd =~ s/(.*) (1[89]|2[0123]|0[0-8]):/$1 11:/;
my $filetime = $now - 22 * 24 * 3600 - 7*3600;
my $filedate = strftime "%b-%Y", localtime($filetime);

sub set_params_1
{
    $MemberSex = "male";
    $Birthday = "08-May-1978";
    $RelevantDate = "22-Feb-2024";
    $ABM = 5.29538462;
    $AMC = 368425.35;
    $APC = 82591.45;
    $ATA = 28976.57;
    $ERDA = "0.00";
    $FirstDateMembership = "01-Dec-2003";
    $AS = 145102.33;
    $SurchargeDebt = "0.00";
    $YearsScheme = 20;
    $MemberAgeYears = 45;
    $MemberAgeMonths = 9;
    $FamilyLawValuation = "INVALID";
    $MemberName = "BillyBob";
    $MemberReference = "PSSdb Family Valuation";
}

sub get_yymondd
{
    my $yyyymmdd = $_ [0];
    my $year = $1;
    my $month = $2;
    my $day = $3;

    if ($yyyymmdd =~ m/^(\d\d\d\d)(\d\d)(\d\d)$/i)
    {
        # YYYYMMDD
        $year = $1;
        $month = $2;
        $day = $3;
    }
    else { return $yyyymmdd; }
    
    if ($month == 1) { $month = "Jan" ; }
    if ($month == 2) { $month = "Feb" ; }
    if ($month == 3) { $month = "Mar" ; }
    if ($month == 4) { $month = "Apr" ; }
    if ($month == 5) { $month = "May" ; }
    if ($month == 6) { $month = "Jun" ; }
    if ($month == 7) { $month = "Jul" ; }
    if ($month == 8) { $month = "Aug" ; }
    if ($month == 9) { $month = "Sep" ; }
    if ($month == 10) { $month = "Oct" ; }
    if ($month == 11) { $month = "Nov" ; }
    if ($month == 12) { $month = "Dec" ; }

    my $ret = "$day-$month-$year";
    if ($ret =~ m/^\d-/)
    {
        $ret = "0$ret";
    }
    return $ret;
}

sub get_month
{
    my $ddmonyyyy = $_ [0];
    my $year;
    my $month;
    my $day;

    if ($ddmonyyyy =~ m/^(\d\d)-([A-Z][a-z][a-z])-(\d\d\d\d)$/i)
    {
        $year = $3;
        $month = $2;
        $day = $1;

        if ( $month eq "Jan"  ) { $month = 1; }
        if ( $month eq "Feb"  ) { $month = 2; }
        if ( $month eq "Mar"  ) { $month = 3; }
        if ( $month eq "Apr"  ) { $month = 4; }
        if ( $month eq "May"  ) { $month = 5; }
        if ( $month eq "Jun"  ) { $month = 6; }
        if ( $month eq "Jul"  ) { $month = 7; }
        if ( $month eq "Aug"  ) { $month = 8; }
        if ( $month eq "Sep"  ) { $month = 9; }
        if ( $month eq "Oct"  ) { $month = 10; }
        if ( $month eq "Nov"  ) { $month = 11; }
        if ( $month eq "Dec"  ) { $month = 12; }
    }
    elsif ($ddmonyyyy =~ m/^(\d\d\d\d)(\d\d)(\d\d)$/)
    {
        $month = $2;
        return $month;
    }

    return $month;
}

sub get_day
{
    my $ddmonyyyy = $_ [0];
    my $year;
    my $month;
    my $day;

    if ($ddmonyyyy =~ m/^(\d\d)-([A-Z][a-z][a-z])-(\d\d\d\d)$/i)
    {
        $day = $1;
    }
    elsif ($ddmonyyyy =~ m/^(\d\d\d\d)(\d\d)(\d\d)$/)
    {
        $day = $3;
    }

    return $day;
}

sub setup_member
{
    $first_year = $FirstDateMembership;
    $first_month = 1;
    $first_day = $FirstDateMembership;

    $RelevantDate = get_yymondd ($RelevantDate);
    $Birthday = get_yymondd ($Birthday);
    $FirstDateMembership = get_yymondd ($FirstDateMembership);

    if ($FirstDateMembership =~ m/\d\d-[A-Z]+-\d\d\d\d/i)
    {
        $first_year =~ s/^.*-//;
        if ($FirstDateMembership =~ m/Jan/i) { $first_month = 1; }
        if ($FirstDateMembership =~ m/Feb/i) { $first_month = 2; }
        if ($FirstDateMembership =~ m/Mar/i) { $first_month = 3; }
        if ($FirstDateMembership =~ m/Apr/i) { $first_month = 4; }
        if ($FirstDateMembership =~ m/May/i) { $first_month = 5; }
        if ($FirstDateMembership =~ m/Jun/i) { $first_month = 6; }
        if ($FirstDateMembership =~ m/Jul/i) { $first_month = 7; }
        if ($FirstDateMembership =~ m/Aug/i) { $first_month = 8; }
        if ($FirstDateMembership =~ m/Sep/i) { $first_month = 9; }
        if ($FirstDateMembership =~ m/Oct/i) { $first_month = 10; }
        if ($FirstDateMembership =~ m/Nov/i) { $first_month = 11; }
        if ($FirstDateMembership =~ m/Dec/i) { $first_month = 12; }
        $first_day =~ s/-.*$//;
    }
    elsif ($FirstDateMembership =~ m/^(\d\d\d\d)(\d\d)(\d\d)$/i)
    {
        # YYYYMMDD
        $first_year = $1;
        $first_month = $2;
        $first_day = $3;
    }

    $StartedBefore = 1;
    if ($first_year > 1999) { $StartedBefore = 0; }
    elsif ($first_year == 1999 && $first_month > 6) { $StartedBefore = 0; }

    if ($RelevantDate =~ m/\d\d-[A-Z]+-\d\d\d\d/i)
    {
        $relevant_year = $RelevantDate;
        $relevant_month = 1;
        $relevant_day = $RelevantDate;
        {
            $relevant_year =~ s/^.*-//;
            print (">>>$relevant_year\n");
            if ($RelevantDate =~ m/Jan/i) { $relevant_month = 1; }
            if ($RelevantDate =~ m/Feb/i) { $relevant_month = 2; }
            if ($RelevantDate =~ m/Mar/i) { $relevant_month = 3; }
            if ($RelevantDate =~ m/Apr/i) { $relevant_month = 4; }
            if ($RelevantDate =~ m/May/i) { $relevant_month = 5; }
            if ($RelevantDate =~ m/Jun/i) { $relevant_month = 6; }
            if ($RelevantDate =~ m/Jul/i) { $relevant_month = 7; }
            if ($RelevantDate =~ m/Aug/i) { $relevant_month = 8; }
            if ($RelevantDate =~ m/Sep/i) { $relevant_month = 9; }
            if ($RelevantDate =~ m/Oct/i) { $relevant_month = 10; }
            if ($RelevantDate =~ m/Nov/i) { $relevant_month = 11; }
            if ($RelevantDate =~ m/Dec/i) { $relevant_month = 12; }
            $relevant_day =~ s/-.*$//;
        }
    }
    elsif ($RelevantDate =~ m/^(\d\d\d\d)(\d\d)(\d\d)$/i)
    {
        # YYYYMMDD
        $relevant_year = $1;
        $relevant_month = $2;
        $relevant_day = $3;
    }

    if ($Birthday =~ m/\d\d-[A-Z]+-\d\d\d\d/i)
    {
        $birth_year = $Birthday;
        $birth_year =~ s/^.*-//;
        $birth_month = $Birthday;
        $birth_day = $Birthday;
        $MemberAgeYears = $relevant_year - $birth_year;
        print ("zzz>> ($RelevantDate vs $Birthday) $MemberAgeYears = $relevant_year - $birth_year;\n");
        $MemberAgeMonths = 0;

        if ($Birthday =~ m/Jan/i) { $birth_month = 1; }
        if ($Birthday =~ m/Feb/i) { $birth_month = 2; }
        if ($Birthday =~ m/Mar/i) { $birth_month = 3; }
        if ($Birthday =~ m/Apr/i) { $birth_month = 4; }
        if ($Birthday =~ m/May/i) { $birth_month = 5; }
        if ($Birthday =~ m/Jun/i) { $birth_month = 6; }
        if ($Birthday =~ m/Jul/i) { $birth_month = 7; }
        if ($Birthday =~ m/Aug/i) { $birth_month = 8; }
        if ($Birthday =~ m/Sep/i) { $birth_month = 9; }
        if ($Birthday =~ m/Oct/i) { $birth_month = 10; }
        if ($Birthday =~ m/Nov/i) { $birth_month = 11; }
        if ($Birthday =~ m/Dec/i) { $birth_month = 12; }
        $birth_day =~ s/-.*//;
    }
    elsif ($Birthday =~ m/^(\d\d\d\d)(\d\d)(\d\d)$/i)
    {
        # YYYYMMDD
        $birth_year = $1;
        $birth_month = $2;
        $birth_day = $3;
    }

    $MemberAgeMonths = $relevant_month - $birth_month;
    print ("b>> $MemberAgeMonths = $relevant_month - $birth_month;\n");

    if ($relevant_month < $birth_month)
    {
        $MemberAgeYears--;
        $MemberAgeMonths = 12 + $MemberAgeMonths;
        print ("d>>$MemberAgeYears vs $MemberAgeMonths = 12 - $MemberAgeMonths;\n");
    }
    elsif ($relevant_month == $birth_month)
    {
        if ($relevant_day < $birth_day)
        {
            $MemberAgeYears--;
        }
    }
    if ($relevant_day < $birth_day)
    {
        $MemberAgeMonths--;
        if ($MemberAgeMonths < 0)
        {
            $MemberAgeMonths += 12;
        }
    }

    $completed_years = $relevant_year - $first_year;
    if ($relevant_month < $first_month)
    {
        $completed_years--;
    }
    elsif ($relevant_month == $first_month)
    {
        if ($relevant_day < $first_day)
        {
            $completed_years--;
        }
    }

    my $bora = "after";
    if ($StartedBefore) { $bora = "before"; }
    $MemberInfo = "$MemberAgeYears - $completed_years - $bora - $MemberSex";
    $MemberAgeYears++;
    $MemberInfo_plusone = "$MemberAgeYears - $completed_years - $bora - $MemberSex";
    $MemberAgeYears--;

    $ABFyms = get_abf ($MemberInfo); 
    $ABFyms_plusone  = get_abf ($MemberInfo_plusone);

    $PCFyms = get_pcf ($MemberInfo);
    $PCFyms_plusone = get_pcf ($MemberInfo_plusone);

    $MCFyms = get_mcf ($MemberInfo);
    $MCFyms_plusone = get_mcf ($MemberInfo_plusone);
    
    if ($DEBUG >= 1) { print ("$MemberInfo\n"); }
}

sub get_debug
{
    my $debug = "ABFyms -> $ABFyms<br>\n";
    $debug .= "ABFyms_plusone -> $ABFyms_plusone<br>\n";
    $debug .= "ABM -> $ABM<br>\n";
    $debug .= "AMC -> $AMC<br>\n";
    $debug .= "APC -> $APC<br>\n";
    $debug .= "AS -> $AS<br>\n";
    $debug .= "ATA -> $ATA<br>\n";
    $debug .= "Birthday -> $Birthday<br>\n";
    $debug .= "ERDA -> $ERDA<br>\n";
    $debug .= "FamilyLawValuation -> $FamilyLawValuation<br>\n";
    $debug .= "FirstDateMembership -> $FirstDateMembership<br>\n";
    $debug .= "MCFyms -> $MCFyms<br>\n";
    $debug .= "MCFyms_plusone -> $MCFyms_plusone<br>\n";
    $debug .= "MemberAgeMonths -> $MemberAgeMonths<br>\n";
    $debug .= "MemberAgeYears -> $MemberAgeYears<br>\n";
    $debug .= "PCFyms -> $PCFyms<br>\n";
    $debug .= "PCFyms_plusone -> $PCFyms_plusone<br>\n";
    $debug .= "RelevantDate -> $RelevantDate<br>\n";
    $debug .= "SurchargeDebt -> $SurchargeDebt<br>\n";
    $debug .= "YearsScheme -> $YearsScheme<br>\n";
    $debug .= "completed_years -> $completed_years<br>\n";
    $debug .= "first_day -> $first_day<br>\n";
    $debug .= "first_month -> $first_month<br>\n";
    $debug .= "first_year -> $first_year<br>\n";
    $debug .= "relevant_day -> $relevant_day<br>\n";
    $debug .= "relevant_month -> $relevant_month<br>\n";
    $debug .= "relevant_year -> $relevant_year<br>\n";
    $debug .= "MemberSex -> $MemberSex<br>\n";
    $debug .= "Started Before 30th June 1999 -> $StartedBefore<br>\n";
    $debug .= "final_ABF => $final_ABF<br>\n";
    $debug .= "final_MCF => $final_MCF<br>\n";
    $debug .= "final_PCF => $final_PCF<br>\n";
    return $debug;
}

sub do_ABF
{
    my $a = $_ [0];
    my $val = $_ [1];
    $ABF {"$a - $y - $before_99 - $sex"} = $val;
    if ($DEBUG > 1) { print ("do_ABF : $a - $y - $before_99 - $sex => $val\n"); }
    $y++;
}

sub do_PCF
{
    my $a = $_ [0];
    my $val = $_ [1];
    $PCF {"$a - $y - $before_99 - $sex"} = $val;
    if ($DEBUG > 1) { print ("do_PCF : $a - $y - $before_99 - $sex => $val\n"); }
    $y++;
}

sub do_MCF
{
    my $a = $_ [0];
    my $val = $_ [1];
    $MCF {"$a - $y - $before_99 - $sex"} = $val;
    if ($DEBUG > 1) { print ("do_MCF : $a - $y - $before_99 - $sex => $val\n"); }
    $y++;
}

sub get_pcf
{
    my $member_info = $_ [0];
    if ($DEBUG >= 1) { print (" >> GET PCF $member_info\n"); }
    if (defined ($PCF {$member_info}))
    {
        return $PCF {$member_info};
    }
    return "ERRORPCF";
}

sub get_mcf
{
    my $member_info = $_ [0];
    if ($DEBUG >= 1) { print (" >> GET MCF $member_info\n"); }

    if (defined ($MCF {$member_info}))
    {
        return $MCF {$member_info};
    }
    return "ERRORMCF";
}

sub get_abf
{
    my $member_info = $_ [0];
    if ($DEBUG >= 1) { print (" >> GET ABF $member_info\n"); }
    
    if (defined ($ABF {$member_info}))
    {
        return $ABF {$member_info};
    }
    return "ERRORABF";
}

# ABF -- females before Age 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33
$sex = "female";
$before_99 = "before";
$y = 17 ; $a=33; do_ABF($a,0.593663);
$y = 17 ; $a=34; do_ABF($a,0.614211); do_ABF($a,0.616263);
$y = 17 ; $a=35; do_ABF($a,0.634888); do_ABF($a,0.636843); do_ABF($a,0.638721);
$y = 17 ; $a=36; do_ABF($a,0.655791); do_ABF($a,0.657655); do_ABF($a,0.659445); do_ABF($a,0.661162);
$y = 17 ; $a=37; do_ABF($a,0.676934); do_ABF($a,0.678713); do_ABF($a,0.680419); do_ABF($a,0.682055); do_ABF($a,0.683624);
$y = 17 ; $a=38; do_ABF($a,0.698345); do_ABF($a,0.700044); do_ABF($a,0.701674); do_ABF($a,0.703235); do_ABF($a,0.704731); do_ABF($a,0.706164);
$y = 17 ; $a=39; do_ABF($a,0.720123); do_ABF($a,0.721740); do_ABF($a,0.723290); do_ABF($a,0.724774); do_ABF($a,0.726196); do_ABF($a,0.727556); do_ABF($a,0.728857);
$y = 17 ; $a=40; do_ABF($a,0.742239); do_ABF($a,0.743771); do_ABF($a,0.745239); do_ABF($a,0.746644); do_ABF($a,0.747989); do_ABF($a,0.749276); do_ABF($a,0.750506); do_ABF($a,0.751682);
$y = 17 ; $a=41; do_ABF($a,0.763777); do_ABF($a,0.765219); do_ABF($a,0.766599); do_ABF($a,0.767919); do_ABF($a,0.769182); do_ABF($a,0.770390); do_ABF($a,0.771544); do_ABF($a,0.772647); do_ABF($a,0.773701);
$y = 17 ; $a=42; do_ABF($a,0.785603); do_ABF($a,0.786950); do_ABF($a,0.788239); do_ABF($a,0.789472); do_ABF($a,0.790651); do_ABF($a,0.791777); do_ABF($a,0.792853); do_ABF($a,0.793881); do_ABF($a,0.794863); do_ABF($a,0.795801);
$y = 17 ; $a=43; do_ABF($a,0.807703); do_ABF($a,0.808953); do_ABF($a,0.810149); do_ABF($a,0.811292); do_ABF($a,0.812384); do_ABF($a,0.813427); do_ABF($a,0.814423); do_ABF($a,0.815375); do_ABF($a,0.816283); do_ABF($a,0.817149); do_ABF($a,0.817976);
$y = 17 ; $a=44; do_ABF($a,0.830115); do_ABF($a,0.831269); do_ABF($a,0.832371); do_ABF($a,0.833425); do_ABF($a,0.834431); do_ABF($a,0.835391); do_ABF($a,0.836308); do_ABF($a,0.837184); do_ABF($a,0.838019); do_ABF($a,0.838815); do_ABF($a,0.839575); do_ABF($a,0.840300);
$y = 17 ; $a=45; do_ABF($a,0.852828); do_ABF($a,0.853886); do_ABF($a,0.854897); do_ABF($a,0.855862); do_ABF($a,0.856783); do_ABF($a,0.857663); do_ABF($a,0.858502); do_ABF($a,0.859303); do_ABF($a,0.860067); do_ABF($a,0.860795); do_ABF($a,0.861489); do_ABF($a,0.862151); do_ABF($a,0.862782);
$y = 17 ; $a=46; do_ABF($a,0.875839); do_ABF($a,0.876803); do_ABF($a,0.877723); do_ABF($a,0.878602); do_ABF($a,0.879440); do_ABF($a,0.880240); do_ABF($a,0.881002); do_ABF($a,0.881729); do_ABF($a,0.882423); do_ABF($a,0.883084); do_ABF($a,0.883714); do_ABF($a,0.884314); do_ABF($a,0.884886); do_ABF($a,0.885431);
$y = 17 ; $a=47; do_ABF($a,0.899156); do_ABF($a,0.900026); do_ABF($a,0.900857); do_ABF($a,0.901649); do_ABF($a,0.902405); do_ABF($a,0.903126); do_ABF($a,0.903813); do_ABF($a,0.904468); do_ABF($a,0.905092); do_ABF($a,0.905687); do_ABF($a,0.906254); do_ABF($a,0.906793); do_ABF($a,0.907308); do_ABF($a,0.907797); do_ABF($a,0.908264);
$y = 17 ; $a=48; do_ABF($a,0.922806); do_ABF($a,0.923584); do_ABF($a,0.924325); do_ABF($a,0.925032); do_ABF($a,0.925706); do_ABF($a,0.926349); do_ABF($a,0.926961); do_ABF($a,0.927544); do_ABF($a,0.928100); do_ABF($a,0.928629); do_ABF($a,0.929133); do_ABF($a,0.929613); do_ABF($a,0.930070); do_ABF($a,0.930505); do_ABF($a,0.930920); do_ABF($a,0.931314);
$y = 17 ; $a=49; do_ABF($a,0.947077); do_ABF($a,0.947753); do_ABF($a,0.948397); do_ABF($a,0.949011); do_ABF($a,0.949596); do_ABF($a,0.950153); do_ABF($a,0.950683); do_ABF($a,0.951188); do_ABF($a,0.951670); do_ABF($a,0.952128); do_ABF($a,0.952564); do_ABF($a,0.952979); do_ABF($a,0.953374); do_ABF($a,0.953750); do_ABF($a,0.954108); do_ABF($a,0.954448); do_ABF($a,0.954772);
$y = 17 ; $a=50; do_ABF($a,0.972015); do_ABF($a,0.972578); do_ABF($a,0.973115); do_ABF($a,0.973626); do_ABF($a,0.974112); do_ABF($a,0.974576); do_ABF($a,0.975017); do_ABF($a,0.975436); do_ABF($a,0.975836); do_ABF($a,0.976216); do_ABF($a,0.976578); do_ABF($a,0.976922); do_ABF($a,0.977249); do_ABF($a,0.977561); do_ABF($a,0.977857); do_ABF($a,0.978139); do_ABF($a,0.978407);
$y = 17 ; $a=51; do_ABF($a,0.997602); do_ABF($a,0.998043); do_ABF($a,0.998463); do_ABF($a,0.998862); do_ABF($a,0.999242); do_ABF($a,0.999604); do_ABF($a,0.999948); do_ABF($a,1.000275); do_ABF($a,1.000586); do_ABF($a,1.000883); do_ABF($a,1.001164); do_ABF($a,1.001432); do_ABF($a,1.001687); do_ABF($a,1.001929); do_ABF($a,1.002159); do_ABF($a,1.002378); do_ABF($a,1.002586);
$y = 17 ; $a=52; do_ABF($a,1.023900); do_ABF($a,1.024206); do_ABF($a,1.024498); do_ABF($a,1.024775); do_ABF($a,1.025038); do_ABF($a,1.025288); do_ABF($a,1.025526); do_ABF($a,1.025753); do_ABF($a,1.025968); do_ABF($a,1.026172); do_ABF($a,1.026367); do_ABF($a,1.026551); do_ABF($a,1.026727); do_ABF($a,1.026894); do_ABF($a,1.027052); do_ABF($a,1.027203); do_ABF($a,1.027347);
$y = 17 ; $a=53; do_ABF($a,1.050936); do_ABF($a,1.051094); do_ABF($a,1.051244); do_ABF($a,1.051386); do_ABF($a,1.051521); do_ABF($a,1.051650); do_ABF($a,1.051772); do_ABF($a,1.051888); do_ABF($a,1.051998); do_ABF($a,1.052103); do_ABF($a,1.052202); do_ABF($a,1.052297); do_ABF($a,1.052387); do_ABF($a,1.052472); do_ABF($a,1.052553); do_ABF($a,1.052630); do_ABF($a,1.052703);
$y = 17 ; $a=54; do_ABF($a,1.078975); do_ABF($a,1.078975); do_ABF($a,1.078975); do_ABF($a,1.078975); do_ABF($a,1.078975); do_ABF($a,1.078975); do_ABF($a,1.078975); do_ABF($a,1.078975); do_ABF($a,1.078975); do_ABF($a,1.078975); do_ABF($a,1.078975); do_ABF($a,1.078975); do_ABF($a,1.078975); do_ABF($a,1.078975); do_ABF($a,1.078975); do_ABF($a,1.078975); do_ABF($a,1.078975);
$y = 17 ; $a=55; do_ABF($a,1.109297); do_ABF($a,1.109297); do_ABF($a,1.109297); do_ABF($a,1.109297); do_ABF($a,1.109297); do_ABF($a,1.109297); do_ABF($a,1.109297); do_ABF($a,1.109297); do_ABF($a,1.109297); do_ABF($a,1.109297); do_ABF($a,1.109297); do_ABF($a,1.109297); do_ABF($a,1.109297); do_ABF($a,1.109297); do_ABF($a,1.109297); do_ABF($a,1.109297); do_ABF($a,1.109297);
$y = 17 ; $a=56; do_ABF($a,1.116478); do_ABF($a,1.116478); do_ABF($a,1.116478); do_ABF($a,1.116478); do_ABF($a,1.116478); do_ABF($a,1.116478); do_ABF($a,1.116478); do_ABF($a,1.116478); do_ABF($a,1.116478); do_ABF($a,1.116478); do_ABF($a,1.116478); do_ABF($a,1.116478); do_ABF($a,1.116478); do_ABF($a,1.116478); do_ABF($a,1.116478); do_ABF($a,1.116478); do_ABF($a,1.116478);
$y = 17 ; $a=57; do_ABF($a,1.125985); do_ABF($a,1.125985); do_ABF($a,1.125985); do_ABF($a,1.125985); do_ABF($a,1.125985); do_ABF($a,1.125985); do_ABF($a,1.125985); do_ABF($a,1.125985); do_ABF($a,1.125985); do_ABF($a,1.125985); do_ABF($a,1.125985); do_ABF($a,1.125985); do_ABF($a,1.125985); do_ABF($a,1.125985); do_ABF($a,1.125985); do_ABF($a,1.125985); do_ABF($a,1.125985);
$y = 17 ; $a=58; do_ABF($a,1.135808); do_ABF($a,1.135808); do_ABF($a,1.135808); do_ABF($a,1.135808); do_ABF($a,1.135808); do_ABF($a,1.135808); do_ABF($a,1.135808); do_ABF($a,1.135808); do_ABF($a,1.135808); do_ABF($a,1.135808); do_ABF($a,1.135808); do_ABF($a,1.135808); do_ABF($a,1.135808); do_ABF($a,1.135808); do_ABF($a,1.135808); do_ABF($a,1.135808); do_ABF($a,1.135808);
$y = 17 ; $a=59; do_ABF($a,1.146496); do_ABF($a,1.146496); do_ABF($a,1.146496); do_ABF($a,1.146496); do_ABF($a,1.146496); do_ABF($a,1.146496); do_ABF($a,1.146496); do_ABF($a,1.146496); do_ABF($a,1.146496); do_ABF($a,1.146496); do_ABF($a,1.146496); do_ABF($a,1.146496); do_ABF($a,1.146496); do_ABF($a,1.146496); do_ABF($a,1.146496); do_ABF($a,1.146496); do_ABF($a,1.146496);
$y = 17 ; $a=60; do_ABF($a,1.159652); do_ABF($a,1.159652); do_ABF($a,1.159652); do_ABF($a,1.159652); do_ABF($a,1.159652); do_ABF($a,1.159652); do_ABF($a,1.159652); do_ABF($a,1.159652); do_ABF($a,1.159652); do_ABF($a,1.159652); do_ABF($a,1.159652); do_ABF($a,1.159652); do_ABF($a,1.159652); do_ABF($a,1.159652); do_ABF($a,1.159652); do_ABF($a,1.159652); do_ABF($a,1.159652);
$y = 17 ; $a=61; do_ABF($a,1.172927); do_ABF($a,1.172927); do_ABF($a,1.172927); do_ABF($a,1.172927); do_ABF($a,1.172927); do_ABF($a,1.172927); do_ABF($a,1.172927); do_ABF($a,1.172927); do_ABF($a,1.172927); do_ABF($a,1.172927); do_ABF($a,1.172927); do_ABF($a,1.172927); do_ABF($a,1.172927); do_ABF($a,1.172927); do_ABF($a,1.172927); do_ABF($a,1.172927); do_ABF($a,1.172927);
$y = 17 ; $a=62; do_ABF($a,1.186743); do_ABF($a,1.186743); do_ABF($a,1.186743); do_ABF($a,1.186743); do_ABF($a,1.186743); do_ABF($a,1.186743); do_ABF($a,1.186743); do_ABF($a,1.186743); do_ABF($a,1.186743); do_ABF($a,1.186743); do_ABF($a,1.186743); do_ABF($a,1.186743); do_ABF($a,1.186743); do_ABF($a,1.186743); do_ABF($a,1.186743); do_ABF($a,1.186743); do_ABF($a,1.186743);
$y = 17 ; $a=63; do_ABF($a,1.200059); do_ABF($a,1.200059); do_ABF($a,1.200059); do_ABF($a,1.200059); do_ABF($a,1.200059); do_ABF($a,1.200059); do_ABF($a,1.200059); do_ABF($a,1.200059); do_ABF($a,1.200059); do_ABF($a,1.200059); do_ABF($a,1.200059); do_ABF($a,1.200059); do_ABF($a,1.200059); do_ABF($a,1.200059); do_ABF($a,1.200059); do_ABF($a,1.200059); do_ABF($a,1.200059);
$y = 17 ; $a=64; do_ABF($a,1.216318); do_ABF($a,1.216318); do_ABF($a,1.216318); do_ABF($a,1.216318); do_ABF($a,1.216318); do_ABF($a,1.216318); do_ABF($a,1.216318); do_ABF($a,1.216318); do_ABF($a,1.216318); do_ABF($a,1.216318); do_ABF($a,1.216318); do_ABF($a,1.216318); do_ABF($a,1.216318); do_ABF($a,1.216318); do_ABF($a,1.216318); do_ABF($a,1.216318); do_ABF($a,1.216318);
$y = 17 ; $a=65; do_ABF($a,1.240774); do_ABF($a,1.240774); do_ABF($a,1.240774); do_ABF($a,1.240774); do_ABF($a,1.240774); do_ABF($a,1.240774); do_ABF($a,1.240774); do_ABF($a,1.240774); do_ABF($a,1.240774); do_ABF($a,1.240774); do_ABF($a,1.240774); do_ABF($a,1.240774); do_ABF($a,1.240774); do_ABF($a,1.240774); do_ABF($a,1.240774); do_ABF($a,1.240774); do_ABF($a,1.240774);
$y = 17 ; $a=66; do_ABF($a,1.236506); do_ABF($a,1.236506); do_ABF($a,1.236506); do_ABF($a,1.236506); do_ABF($a,1.236506); do_ABF($a,1.236506); do_ABF($a,1.236506); do_ABF($a,1.236506); do_ABF($a,1.236506); do_ABF($a,1.236506); do_ABF($a,1.236506); do_ABF($a,1.236506); do_ABF($a,1.236506); do_ABF($a,1.236506); do_ABF($a,1.236506); do_ABF($a,1.236506); do_ABF($a,1.236506);
$y = 17 ; $a=67; do_ABF($a,1.231617); do_ABF($a,1.231617); do_ABF($a,1.231617); do_ABF($a,1.231617); do_ABF($a,1.231617); do_ABF($a,1.231617); do_ABF($a,1.231617); do_ABF($a,1.231617); do_ABF($a,1.231617); do_ABF($a,1.231617); do_ABF($a,1.231617); do_ABF($a,1.231617); do_ABF($a,1.231617); do_ABF($a,1.231617); do_ABF($a,1.231617); do_ABF($a,1.231617); do_ABF($a,1.231617);
$y = 17 ; $a=68; do_ABF($a,1.226073); do_ABF($a,1.226073); do_ABF($a,1.226073); do_ABF($a,1.226073); do_ABF($a,1.226073); do_ABF($a,1.226073); do_ABF($a,1.226073); do_ABF($a,1.226073); do_ABF($a,1.226073); do_ABF($a,1.226073); do_ABF($a,1.226073); do_ABF($a,1.226073); do_ABF($a,1.226073); do_ABF($a,1.226073); do_ABF($a,1.226073); do_ABF($a,1.226073); do_ABF($a,1.226073);
$y = 17 ; $a=69; do_ABF($a,1.219827); do_ABF($a,1.219827); do_ABF($a,1.219827); do_ABF($a,1.219827); do_ABF($a,1.219827); do_ABF($a,1.219827); do_ABF($a,1.219827); do_ABF($a,1.219827); do_ABF($a,1.219827); do_ABF($a,1.219827); do_ABF($a,1.219827); do_ABF($a,1.219827); do_ABF($a,1.219827); do_ABF($a,1.219827); do_ABF($a,1.219827); do_ABF($a,1.219827); do_ABF($a,1.219827);
$y = 17 ; $a=70; do_ABF($a,1.212857); do_ABF($a,1.212857); do_ABF($a,1.212857); do_ABF($a,1.212857); do_ABF($a,1.212857); do_ABF($a,1.212857); do_ABF($a,1.212857); do_ABF($a,1.212857); do_ABF($a,1.212857); do_ABF($a,1.212857); do_ABF($a,1.212857); do_ABF($a,1.212857); do_ABF($a,1.212857); do_ABF($a,1.212857); do_ABF($a,1.212857); do_ABF($a,1.212857); do_ABF($a,1.212857);
$y = 17 ; $a=71; do_ABF($a,1.205136); do_ABF($a,1.205136); do_ABF($a,1.205136); do_ABF($a,1.205136); do_ABF($a,1.205136); do_ABF($a,1.205136); do_ABF($a,1.205136); do_ABF($a,1.205136); do_ABF($a,1.205136); do_ABF($a,1.205136); do_ABF($a,1.205136); do_ABF($a,1.205136); do_ABF($a,1.205136); do_ABF($a,1.205136); do_ABF($a,1.205136); do_ABF($a,1.205136); do_ABF($a,1.205136);
$y = 17 ; $a=72; do_ABF($a,1.196643); do_ABF($a,1.196643); do_ABF($a,1.196643); do_ABF($a,1.196643); do_ABF($a,1.196643); do_ABF($a,1.196643); do_ABF($a,1.196643); do_ABF($a,1.196643); do_ABF($a,1.196643); do_ABF($a,1.196643); do_ABF($a,1.196643); do_ABF($a,1.196643); do_ABF($a,1.196643); do_ABF($a,1.196643); do_ABF($a,1.196643); do_ABF($a,1.196643); do_ABF($a,1.196643);
$y = 17 ; $a=73; do_ABF($a,1.187377); do_ABF($a,1.187377); do_ABF($a,1.187377); do_ABF($a,1.187377); do_ABF($a,1.187377); do_ABF($a,1.187377); do_ABF($a,1.187377); do_ABF($a,1.187377); do_ABF($a,1.187377); do_ABF($a,1.187377); do_ABF($a,1.187377); do_ABF($a,1.187377); do_ABF($a,1.187377); do_ABF($a,1.187377); do_ABF($a,1.187377); do_ABF($a,1.187377); do_ABF($a,1.187377);
$y = 17 ; $a=74; do_ABF($a,1.177218); do_ABF($a,1.177218); do_ABF($a,1.177218); do_ABF($a,1.177218); do_ABF($a,1.177218); do_ABF($a,1.177218); do_ABF($a,1.177218); do_ABF($a,1.177218); do_ABF($a,1.177218); do_ABF($a,1.177218); do_ABF($a,1.177218); do_ABF($a,1.177218); do_ABF($a,1.177218); do_ABF($a,1.177218); do_ABF($a,1.177218); do_ABF($a,1.177218); do_ABF($a,1.177218); 
$y = 17 ; $a=75; do_ABF($a,1.166119); do_ABF($a,1.166119); do_ABF($a,1.166119); do_ABF($a,1.166119); do_ABF($a,1.166119); do_ABF($a,1.166119); do_ABF($a,1.166119); do_ABF($a,1.166119); do_ABF($a,1.166119); do_ABF($a,1.166119); do_ABF($a,1.166119); do_ABF($a,1.166119); do_ABF($a,1.166119); do_ABF($a,1.166119); do_ABF($a,1.166119); do_ABF($a,1.166119); do_ABF($a,1.166119); 
# ABF -- females before Age 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 or more
$sex = "female";
$before_99 = "before";
$y = 34 ; $a=50; do_ABF ($a,0.978662);
$y = 34 ; $a=51; do_ABF ($a,1.002784); do_ABF ($a,1.002972);
$y = 34 ; $a=52; do_ABF ($a,1.027483); do_ABF ($a,1.027612); do_ABF ($a,1.027735);
$y = 34 ; $a=53; do_ABF ($a,1.052772); do_ABF ($a,1.052838); do_ABF ($a,1.052901); do_ABF ($a,1.052961);
$y = 34 ; $a=54; do_ABF ($a,1.078975); do_ABF ($a,1.078975); do_ABF ($a,1.078975); do_ABF ($a,1.078975); do_ABF ($a,1.078975);
$y = 34 ; $a=55; do_ABF ($a,1.109297); do_ABF ($a,1.109297); do_ABF ($a,1.109297); do_ABF ($a,1.109297); do_ABF ($a,1.109297); do_ABF ($a,1.109297);
$y = 34 ; $a=56; do_ABF ($a,1.116478); do_ABF ($a,1.116478); do_ABF ($a,1.116478); do_ABF ($a,1.116478); do_ABF ($a,1.116478); do_ABF ($a,1.116478); do_ABF ($a,1.116478);
$y = 34 ; $a=57; do_ABF ($a,1.125985); do_ABF ($a,1.125985); do_ABF ($a,1.125985); do_ABF ($a,1.125985); do_ABF ($a,1.125985); do_ABF ($a,1.125985); do_ABF ($a,1.125985); do_ABF ($a,1.125985);
$y = 34 ; $a=58; do_ABF ($a,1.135808); do_ABF ($a,1.135808); do_ABF ($a,1.135808); do_ABF ($a,1.135808); do_ABF ($a,1.135808); do_ABF ($a,1.135808); do_ABF ($a,1.135808); do_ABF ($a,1.135808); do_ABF ($a,1.135808);
$y = 34 ; $a=59; do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496);
$y = 34 ; $a=60; do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652);
$y = 34 ; $a=61; do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927);
$y = 34 ; $a=62; do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743);
$y = 34 ; $a=63; do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059);
$y = 34 ; $a=64; do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318);
$y = 34 ; $a=65; do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774);
$y = 34 ; $a=66; do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506);
$y = 34 ; $a=67; do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617);
$y = 34 ; $a=68; do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073);
$y = 34 ; $a=69; do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827);
$y = 34 ; $a=70; do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857);
$y = 34 ; $a=71; do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136);
$y = 34 ; $a=72; do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643);
$y = 34 ; $a=73; do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377);
$y = 34 ; $a=74; do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); 
$y = 34 ; $a=75; do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); 
# MCF -- males before Age 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16
$sex = "male";
$before_99 = "before";
$y = 0 ; $a=18; do_MCF ($a,0.355973); do_MCF ($a,0.383502); do_MCF ($a,0.408049);
$y = 0 ; $a=19; do_MCF ($a,0.360665); do_MCF ($a,0.388216); do_MCF ($a,0.413432); do_MCF ($a,0.435463);
$y = 0 ; $a=20; do_MCF ($a,0.367430); do_MCF ($a,0.394837); do_MCF ($a,0.419997); do_MCF ($a,0.442652); do_MCF ($a,0.462017);
$y = 0 ; $a=21; do_MCF ($a,0.376238); do_MCF ($a,0.403538); do_MCF ($a,0.428446); do_MCF ($a,0.450934); do_MCF ($a,0.470858); do_MCF ($a,0.487480);
$y = 0 ; $a=22; do_MCF ($a,0.386750); do_MCF ($a,0.413995); do_MCF ($a,0.438702); do_MCF ($a,0.460826); do_MCF ($a,0.480483); do_MCF ($a,0.497616); do_MCF ($a,0.511513);
$y = 0 ; $a=23; do_MCF ($a,0.400690); do_MCF ($a,0.427546); do_MCF ($a,0.451969); do_MCF ($a,0.473648); do_MCF ($a,0.492695); do_MCF ($a,0.509341); do_MCF ($a,0.523594); do_MCF ($a,0.534741);
$y = 0 ; $a=24; do_MCF ($a,0.415783); do_MCF ($a,0.442370); do_MCF ($a,0.466286); do_MCF ($a,0.487597); do_MCF ($a,0.506115); do_MCF ($a,0.522071); do_MCF ($a,0.535780); do_MCF ($a,0.547286); do_MCF ($a,0.555859);
$y = 0 ; $a=25; do_MCF ($a,0.431904); do_MCF ($a,0.458082); do_MCF ($a,0.481642); do_MCF ($a,0.502356); do_MCF ($a,0.520449); do_MCF ($a,0.535822); do_MCF ($a,0.548789); do_MCF ($a,0.559722); do_MCF ($a,0.568678); do_MCF ($a,0.574896);
$y = 0 ; $a=26; do_MCF ($a,0.449101); do_MCF ($a,0.474679); do_MCF ($a,0.497737); do_MCF ($a,0.518035); do_MCF ($a,0.535468); do_MCF ($a,0.550385); do_MCF ($a,0.562739); do_MCF ($a,0.572899); do_MCF ($a,0.581272); do_MCF ($a,0.587910); do_MCF ($a,0.592010);
$y = 0 ; $a=27; do_MCF ($a,0.466936); do_MCF ($a,0.492019); do_MCF ($a,0.514392); do_MCF ($a,0.534147); do_MCF ($a,0.551152); do_MCF ($a,0.565389); do_MCF ($a,0.577295); do_MCF ($a,0.586847); do_MCF ($a,0.594448); do_MCF ($a,0.600517); do_MCF ($a,0.605094); do_MCF ($a,0.623069);
$y = 0 ; $a=28; do_MCF ($a,0.484951); do_MCF ($a,0.509375); do_MCF ($a,0.531246); do_MCF ($a,0.550315); do_MCF ($a,0.566813); do_MCF ($a,0.580678); do_MCF ($a,0.591945); do_MCF ($a,0.601109); do_MCF ($a,0.608150); do_MCF ($a,0.613488); do_MCF ($a,0.617542); do_MCF ($a,0.634919); do_MCF ($a,0.650950);
$y = 0 ; $a=29; do_MCF ($a,0.503252); do_MCF ($a,0.527169); do_MCF ($a,0.548345); do_MCF ($a,0.566923); do_MCF ($a,0.582744); do_MCF ($a,0.596139); do_MCF ($a,0.607085); do_MCF ($a,0.615644); do_MCF ($a,0.622345); do_MCF ($a,0.627159); do_MCF ($a,0.630509); do_MCF ($a,0.647279); do_MCF ($a,0.662731); do_MCF ($a,0.676913);
$y = 0 ; $a=30; do_MCF ($a,0.521739); do_MCF ($a,0.544987); do_MCF ($a,0.565670); do_MCF ($a,0.583571); do_MCF ($a,0.598955); do_MCF ($a,0.611719); do_MCF ($a,0.622259); do_MCF ($a,0.630567); do_MCF ($a,0.636715); do_MCF ($a,0.641249); do_MCF ($a,0.644121); do_MCF ($a,0.660260); do_MCF ($a,0.675112); do_MCF ($a,0.688730); do_MCF ($a,0.701175);
$y = 0 ; $a=31; do_MCF ($a,0.540684); do_MCF ($a,0.563219); do_MCF ($a,0.583212); do_MCF ($a,0.600641); do_MCF ($a,0.615364); do_MCF ($a,0.627736); do_MCF ($a,0.637679); do_MCF ($a,0.645631); do_MCF ($a,0.651582); do_MCF ($a,0.655597); do_MCF ($a,0.658233); do_MCF ($a,0.673727); do_MCF ($a,0.687968); do_MCF ($a,0.701012); do_MCF ($a,0.712920); do_MCF ($a,0.723761);
$y = 0 ; $a=32; do_MCF ($a,0.560340); do_MCF ($a,0.582012); do_MCF ($a,0.601260); do_MCF ($a,0.617992); do_MCF ($a,0.632274); do_MCF ($a,0.644006); do_MCF ($a,0.653601); do_MCF ($a,0.660988); do_MCF ($a,0.666626); do_MCF ($a,0.670491); do_MCF ($a,0.672636); do_MCF ($a,0.687487); do_MCF ($a,0.701122); do_MCF ($a,0.713596); do_MCF ($a,0.724974); do_MCF ($a,0.735323); do_MCF ($a,0.744715);
$y = 0 ; $a=33; do_MCF ($a,0.580913); do_MCF ($a,0.601777); do_MCF ($a,0.620086); do_MCF ($a,0.636040); do_MCF ($a,0.649614); do_MCF ($a,0.660925); do_MCF ($a,0.669891); do_MCF ($a,0.676961); do_MCF ($a,0.682051); do_MCF ($a,0.685632); do_MCF ($a,0.687659); do_MCF ($a,0.701841); do_MCF ($a,0.714845); do_MCF ($a,0.726729); do_MCF ($a,0.737558); do_MCF ($a,0.747399); do_MCF ($a,0.756322);
$y = 0 ; $a=34; do_MCF ($a,0.601320); do_MCF ($a,0.621759); do_MCF ($a,0.639249); do_MCF ($a,0.654266); do_MCF ($a,0.667096); do_MCF ($a,0.677748); do_MCF ($a,0.686362); do_MCF ($a,0.692855); do_MCF ($a,0.697694); do_MCF ($a,0.700776); do_MCF ($a,0.702573); do_MCF ($a,0.716102); do_MCF ($a,0.728491); do_MCF ($a,0.739801); do_MCF ($a,0.750097); do_MCF ($a,0.759446); do_MCF ($a,0.767916);
$y = 0 ; $a=35; do_MCF ($a,0.621628); do_MCF ($a,0.641617); do_MCF ($a,0.658716); do_MCF ($a,0.672923); do_MCF ($a,0.684830); do_MCF ($a,0.694775); do_MCF ($a,0.702777); do_MCF ($a,0.708981); do_MCF ($a,0.713290); do_MCF ($a,0.716179); do_MCF ($a,0.717517); do_MCF ($a,0.730395); do_MCF ($a,0.742174); do_MCF ($a,0.752916); do_MCF ($a,0.762685); do_MCF ($a,0.771548); do_MCF ($a,0.779573);
$y = 0 ; $a=36; do_MCF ($a,0.641592); do_MCF ($a,0.661096); do_MCF ($a,0.677811); do_MCF ($a,0.691707); do_MCF ($a,0.702850); do_MCF ($a,0.711916); do_MCF ($a,0.719273); do_MCF ($a,0.724929); do_MCF ($a,0.729024); do_MCF ($a,0.731438); do_MCF ($a,0.732645); do_MCF ($a,0.744859); do_MCF ($a,0.756018); do_MCF ($a,0.766183); do_MCF ($a,0.775419); do_MCF ($a,0.783791); do_MCF ($a,0.791365);
$y = 0 ; $a=37; do_MCF ($a,0.661449); do_MCF ($a,0.680320); do_MCF ($a,0.696609); do_MCF ($a,0.710195); do_MCF ($a,0.721107); do_MCF ($a,0.729453); do_MCF ($a,0.735967); do_MCF ($a,0.741030); do_MCF ($a,0.744629); do_MCF ($a,0.746891); do_MCF ($a,0.747667); do_MCF ($a,0.759230); do_MCF ($a,0.769781); do_MCF ($a,0.779382); do_MCF ($a,0.788097); do_MCF ($a,0.795991); do_MCF ($a,0.803127);
$y = 0 ; $a=38; do_MCF ($a,0.681191); do_MCF ($a,0.699412); do_MCF ($a,0.715117); do_MCF ($a,0.728352); do_MCF ($a,0.739037); do_MCF ($a,0.747236); do_MCF ($a,0.753076); do_MCF ($a,0.757333); do_MCF ($a,0.760386); do_MCF ($a,0.762199); do_MCF ($a,0.762879); do_MCF ($a,0.773773); do_MCF ($a,0.783702); do_MCF ($a,0.792728); do_MCF ($a,0.800912); do_MCF ($a,0.808319); do_MCF ($a,0.815010);
$y = 0 ; $a=39; do_MCF ($a,0.701232); do_MCF ($a,0.718374); do_MCF ($a,0.733477); do_MCF ($a,0.746190); do_MCF ($a,0.756606); do_MCF ($a,0.764662); do_MCF ($a,0.770436); do_MCF ($a,0.774061); do_MCF ($a,0.776343); do_MCF ($a,0.777651); do_MCF ($a,0.777923); do_MCF ($a,0.788160); do_MCF ($a,0.797479); do_MCF ($a,0.805940); do_MCF ($a,0.813606); do_MCF ($a,0.820538); do_MCF ($a,0.826794);
$y = 0 ; $a=40; do_MCF ($a,0.721620); do_MCF ($a,0.737687); do_MCF ($a,0.751715); do_MCF ($a,0.763887); do_MCF ($a,0.773847); do_MCF ($a,0.781714); do_MCF ($a,0.787425); do_MCF ($a,0.791059); do_MCF ($a,0.792746); do_MCF ($a,0.793312); do_MCF ($a,0.793114); do_MCF ($a,0.802674); do_MCF ($a,0.811365); do_MCF ($a,0.819247); do_MCF ($a,0.826381); do_MCF ($a,0.832826); do_MCF ($a,0.838639);
$y = 0 ; $a=41; do_MCF ($a,0.742432); do_MCF ($a,0.757451); do_MCF ($a,0.770411); do_MCF ($a,0.781528); do_MCF ($a,0.791018); do_MCF ($a,0.798502); do_MCF ($a,0.804108); do_MCF ($a,0.807762); do_MCF ($a,0.809535); do_MCF ($a,0.809547); do_MCF ($a,0.808638); do_MCF ($a,0.817484); do_MCF ($a,0.825516); do_MCF ($a,0.832791); do_MCF ($a,0.839370); do_MCF ($a,0.845307); do_MCF ($a,0.850657);
$y = 0 ; $a=42; do_MCF ($a,0.763413); do_MCF ($a,0.777272); do_MCF ($a,0.789226); do_MCF ($a,0.799325); do_MCF ($a,0.807815); do_MCF ($a,0.814922); do_MCF ($a,0.820235); do_MCF ($a,0.823877); do_MCF ($a,0.825756); do_MCF ($a,0.825931); do_MCF ($a,0.824511); do_MCF ($a,0.832595); do_MCF ($a,0.839924); do_MCF ($a,0.846555); do_MCF ($a,0.852543); do_MCF ($a,0.857943); do_MCF ($a,0.862804);
$y = 0 ; $a=43; do_MCF ($a,0.784403); do_MCF ($a,0.797121); do_MCF ($a,0.807968); do_MCF ($a,0.817134); do_MCF ($a,0.824677); do_MCF ($a,0.830856); do_MCF ($a,0.835893); do_MCF ($a,0.839335); do_MCF ($a,0.841298); do_MCF ($a,0.841666); do_MCF ($a,0.840486); do_MCF ($a,0.847777); do_MCF ($a,0.854378); do_MCF ($a,0.860342); do_MCF ($a,0.865723); do_MCF ($a,0.870569); do_MCF ($a,0.874929);
$y = 0 ; $a=44; do_MCF ($a,0.805220); do_MCF ($a,0.816892); do_MCF ($a,0.826676); do_MCF ($a,0.834819); do_MCF ($a,0.841523); do_MCF ($a,0.846841); do_MCF ($a,0.851030); do_MCF ($a,0.854302); do_MCF ($a,0.856160); do_MCF ($a,0.856705); do_MCF ($a,0.855802); do_MCF ($a,0.862350); do_MCF ($a,0.868270); do_MCF ($a,0.873613); do_MCF ($a,0.878427); do_MCF ($a,0.882760); do_MCF ($a,0.886654);
$y = 0 ; $a=45; do_MCF ($a,0.820491); do_MCF ($a,0.836542); do_MCF ($a,0.845360); do_MCF ($a,0.852519); do_MCF ($a,0.858279); do_MCF ($a,0.862844); do_MCF ($a,0.866249); do_MCF ($a,0.868742); do_MCF ($a,0.870521); do_MCF ($a,0.871043); do_MCF ($a,0.870396); do_MCF ($a,0.876255); do_MCF ($a,0.881545); do_MCF ($a,0.886314); do_MCF ($a,0.890607); do_MCF ($a,0.894466); do_MCF ($a,0.897933);
$y = 0 ; $a=46; do_MCF ($a,0.838554); do_MCF ($a,0.850065); do_MCF ($a,0.863877); do_MCF ($a,0.870161); do_MCF ($a,0.875021); do_MCF ($a,0.878721); do_MCF ($a,0.881455); do_MCF ($a,0.883234); do_MCF ($a,0.884296); do_MCF ($a,0.884822); do_MCF ($a,0.884225); do_MCF ($a,0.889449); do_MCF ($a,0.894161); do_MCF ($a,0.898403); do_MCF ($a,0.902219); do_MCF ($a,0.905646); do_MCF ($a,0.908722);
$y = 0 ; $a=47; do_MCF ($a,0.856393); do_MCF ($a,0.866660); do_MCF ($a,0.875744); do_MCF ($a,0.887615); do_MCF ($a,0.891690); do_MCF ($a,0.894570); do_MCF ($a,0.896512); do_MCF ($a,0.897694); do_MCF ($a,0.898105); do_MCF ($a,0.897967); do_MCF ($a,0.897447); do_MCF ($a,0.902073); do_MCF ($a,0.906239); do_MCF ($a,0.909986); do_MCF ($a,0.913353); do_MCF ($a,0.916375); do_MCF ($a,0.919084);
$y = 0 ; $a=48; do_MCF ($a,0.874009); do_MCF ($a,0.883008); do_MCF ($a,0.890943); do_MCF ($a,0.897916); do_MCF ($a,0.908149); do_MCF ($a,0.910328); do_MCF ($a,0.911521); do_MCF ($a,0.911977); do_MCF ($a,0.911855); do_MCF ($a,0.911119); do_MCF ($a,0.909980); do_MCF ($a,0.914046); do_MCF ($a,0.917703); do_MCF ($a,0.920989); do_MCF ($a,0.923939); do_MCF ($a,0.926583); do_MCF ($a,0.928953);
$y = 0 ; $a=49; do_MCF ($a,0.891753); do_MCF ($a,0.899463); do_MCF ($a,0.906238); do_MCF ($a,0.912173); do_MCF ($a,0.917357); do_MCF ($a,0.926255); do_MCF ($a,0.926829); do_MCF ($a,0.926604); do_MCF ($a,0.925813); do_MCF ($a,0.924602); do_MCF ($a,0.922910); do_MCF ($a,0.926388); do_MCF ($a,0.929511); do_MCF ($a,0.932314); do_MCF ($a,0.934826); do_MCF ($a,0.937076); do_MCF ($a,0.939091);
$y = 0 ; $a=50; do_MCF ($a,0.909682); do_MCF ($a,0.916064); do_MCF ($a,0.921648); do_MCF ($a,0.926521); do_MCF ($a,0.930766); do_MCF ($a,0.934457); do_MCF ($a,0.942290); do_MCF ($a,0.941512); do_MCF ($a,0.940094); do_MCF ($a,0.938259); do_MCF ($a,0.936135); do_MCF ($a,0.938995); do_MCF ($a,0.941559); do_MCF ($a,0.943856); do_MCF ($a,0.945912); do_MCF ($a,0.947752); do_MCF ($a,0.949396);
$y = 0 ; $a=51; do_MCF ($a,0.927934); do_MCF ($a,0.932906); do_MCF ($a,0.937235); do_MCF ($a,0.940999); do_MCF ($a,0.944265); do_MCF ($a,0.947096); do_MCF ($a,0.949547); do_MCF ($a,0.956537); do_MCF ($a,0.954626); do_MCF ($a,0.952211); do_MCF ($a,0.949504); do_MCF ($a,0.951717); do_MCF ($a,0.953696); do_MCF ($a,0.955467); do_MCF ($a,0.957049); do_MCF ($a,0.958463); do_MCF ($a,0.959725);
$y = 0 ; $a=52; do_MCF ($a,0.946292); do_MCF ($a,0.949776); do_MCF ($a,0.952793); do_MCF ($a,0.955403); do_MCF ($a,0.957658); do_MCF ($a,0.959607); do_MCF ($a,0.961288); do_MCF ($a,0.962739); do_MCF ($a,0.969102); do_MCF ($a,0.966247); do_MCF ($a,0.963000); do_MCF ($a,0.964524); do_MCF ($a,0.965884); do_MCF ($a,0.967098); do_MCF ($a,0.968181); do_MCF ($a,0.969147); do_MCF ($a,0.970008);
$y = 0 ; $a=53; do_MCF ($a,0.965017); do_MCF ($a,0.966871); do_MCF ($a,0.968464); do_MCF ($a,0.969835); do_MCF ($a,0.971014); do_MCF ($a,0.972028); do_MCF ($a,0.972900); do_MCF ($a,0.973649); do_MCF ($a,0.974294); do_MCF ($a,0.980211); do_MCF ($a,0.976560); do_MCF ($a,0.977345); do_MCF ($a,0.978044); do_MCF ($a,0.978666); do_MCF ($a,0.979220); do_MCF ($a,0.979713); do_MCF ($a,0.980151);
$y = 0 ; $a=54; do_MCF ($a,0.984513); do_MCF ($a,0.984513); do_MCF ($a,0.984513); do_MCF ($a,0.984513); do_MCF ($a,0.984513); do_MCF ($a,0.984513); do_MCF ($a,0.984513); do_MCF ($a,0.984513); do_MCF ($a,0.984513); do_MCF ($a,0.984513); do_MCF ($a,0.990137); do_MCF ($a,0.990137); do_MCF ($a,0.990137); do_MCF ($a,0.990137); do_MCF ($a,0.990137); do_MCF ($a,0.990137); do_MCF ($a,0.990137);
$y = 0 ; $a=55; do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797);
$y = 0 ; $a=56; do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097);
$y = 0 ; $a=57; do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409);
$y = 0 ; $a=58; do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); 
$y = 0 ; $a=59; do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); 
# MCF -- males before Age 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33
$sex = "male";
$before_99 = "before";
$y = 17 ; $a=33; do_MCF ($a,0.764396);
$y = 17 ; $a=34; do_MCF ($a,0.775576); do_MCF ($a,0.782490);
$y = 17 ; $a=35; do_MCF ($a,0.786824); do_MCF ($a,0.793366); do_MCF ($a,0.799258);
$y = 17 ; $a=36; do_MCF ($a,0.798204); do_MCF ($a,0.804371); do_MCF ($a,0.809923); do_MCF ($a,0.814914);
$y = 17 ; $a=37; do_MCF ($a,0.809566); do_MCF ($a,0.815369); do_MCF ($a,0.820590); do_MCF ($a,0.825282); do_MCF ($a,0.829495);
$y = 17 ; $a=38; do_MCF ($a,0.821044); do_MCF ($a,0.826477); do_MCF ($a,0.831363); do_MCF ($a,0.835753); do_MCF ($a,0.839692); do_MCF ($a,0.843224);
$y = 17 ; $a=39; do_MCF ($a,0.832432); do_MCF ($a,0.837506); do_MCF ($a,0.842067); do_MCF ($a,0.846162); do_MCF ($a,0.849836); do_MCF ($a,0.853128); do_MCF ($a,0.856076);
$y = 17 ; $a=40; do_MCF ($a,0.843873); do_MCF ($a,0.848581); do_MCF ($a,0.852811); do_MCF ($a,0.856606); do_MCF ($a,0.860009); do_MCF ($a,0.863058); do_MCF ($a,0.865788); do_MCF ($a,0.868229);
$y = 17 ; $a=41; do_MCF ($a,0.855471); do_MCF ($a,0.859799); do_MCF ($a,0.863684); do_MCF ($a,0.867169); do_MCF ($a,0.870292); do_MCF ($a,0.873089); do_MCF ($a,0.875592); do_MCF ($a,0.877830); do_MCF ($a,0.879831);
$y = 17 ; $a=42; do_MCF ($a,0.867175); do_MCF ($a,0.871102); do_MCF ($a,0.874625); do_MCF ($a,0.877783); do_MCF ($a,0.880612); do_MCF ($a,0.883144); do_MCF ($a,0.885409); do_MCF ($a,0.887434); do_MCF ($a,0.889244); do_MCF ($a,0.890861);
$y = 17 ; $a=43; do_MCF ($a,0.878846); do_MCF ($a,0.882362); do_MCF ($a,0.885514); do_MCF ($a,0.888339); do_MCF ($a,0.890868); do_MCF ($a,0.893130); do_MCF ($a,0.895153); do_MCF ($a,0.896961); do_MCF ($a,0.898577); do_MCF ($a,0.900019); do_MCF ($a,0.901307);
$y = 17 ; $a=44; do_MCF ($a,0.890150); do_MCF ($a,0.893286); do_MCF ($a,0.896096); do_MCF ($a,0.898613); do_MCF ($a,0.900865); do_MCF ($a,0.902879); do_MCF ($a,0.904679); do_MCF ($a,0.906287); do_MCF ($a,0.907724); do_MCF ($a,0.909006); do_MCF ($a,0.910150); do_MCF ($a,0.911171);
$y = 17 ; $a=45; do_MCF ($a,0.901042); do_MCF ($a,0.903830); do_MCF ($a,0.906327); do_MCF ($a,0.908561); do_MCF ($a,0.910560); do_MCF ($a,0.912347); do_MCF ($a,0.913944); do_MCF ($a,0.915370); do_MCF ($a,0.916643); do_MCF ($a,0.917779); do_MCF ($a,0.918793); do_MCF ($a,0.919697); do_MCF ($a,0.920504);
$y = 17 ; $a=46; do_MCF ($a,0.911479); do_MCF ($a,0.913949); do_MCF ($a,0.916161); do_MCF ($a,0.918139); do_MCF ($a,0.919907); do_MCF ($a,0.921488); do_MCF ($a,0.922900); do_MCF ($a,0.924160); do_MCF ($a,0.925286); do_MCF ($a,0.926289); do_MCF ($a,0.927185); do_MCF ($a,0.927984); do_MCF ($a,0.928696); do_MCF ($a,0.929331);
$y = 17 ; $a=47; do_MCF ($a,0.921512); do_MCF ($a,0.923685); do_MCF ($a,0.925629); do_MCF ($a,0.927368); do_MCF ($a,0.928921); do_MCF ($a,0.930309); do_MCF ($a,0.931549); do_MCF ($a,0.932655); do_MCF ($a,0.933642); do_MCF ($a,0.934523); do_MCF ($a,0.935308); do_MCF ($a,0.936008); do_MCF ($a,0.936632); do_MCF ($a,0.937189); do_MCF ($a,0.937685);
$y = 17 ; $a=48; do_MCF ($a,0.931074); do_MCF ($a,0.932972); do_MCF ($a,0.934669); do_MCF ($a,0.936185); do_MCF ($a,0.937540); do_MCF ($a,0.938750); do_MCF ($a,0.939830); do_MCF ($a,0.940793); do_MCF ($a,0.941653); do_MCF ($a,0.942419); do_MCF ($a,0.943103); do_MCF ($a,0.943712); do_MCF ($a,0.944255); do_MCF ($a,0.944739); do_MCF ($a,0.945170); do_MCF ($a,0.945554);
$y = 17 ; $a=49; do_MCF ($a,0.940892); do_MCF ($a,0.942503); do_MCF ($a,0.943942); do_MCF ($a,0.945228); do_MCF ($a,0.946376); do_MCF ($a,0.947400); do_MCF ($a,0.948314); do_MCF ($a,0.949129); do_MCF ($a,0.949856); do_MCF ($a,0.950505); do_MCF ($a,0.951082); do_MCF ($a,0.951597); do_MCF ($a,0.952056); do_MCF ($a,0.952465); do_MCF ($a,0.952829); do_MCF ($a,0.953154); do_MCF ($a,0.953443);
$y = 17 ; $a=50; do_MCF ($a,0.950866); do_MCF ($a,0.952179); do_MCF ($a,0.953351); do_MCF ($a,0.954397); do_MCF ($a,0.955331); do_MCF ($a,0.956163); do_MCF ($a,0.956906); do_MCF ($a,0.957568); do_MCF ($a,0.958158); do_MCF ($a,0.958684); do_MCF ($a,0.959153); do_MCF ($a,0.959571); do_MCF ($a,0.959943); do_MCF ($a,0.960274); do_MCF ($a,0.960569); do_MCF ($a,0.960832); do_MCF ($a,0.961067);
$y = 17 ; $a=51; do_MCF ($a,0.960851); do_MCF ($a,0.961857); do_MCF ($a,0.962753); do_MCF ($a,0.963553); do_MCF ($a,0.964266); do_MCF ($a,0.964902); do_MCF ($a,0.965469); do_MCF ($a,0.965973); do_MCF ($a,0.966423); do_MCF ($a,0.966824); do_MCF ($a,0.967181); do_MCF ($a,0.967499); do_MCF ($a,0.967782); do_MCF ($a,0.968035); do_MCF ($a,0.968259); do_MCF ($a,0.968459); do_MCF ($a,0.968637);
$y = 17 ; $a=52; do_MCF ($a,0.970775); do_MCF ($a,0.971459); do_MCF ($a,0.972069); do_MCF ($a,0.972612); do_MCF ($a,0.973096); do_MCF ($a,0.973527); do_MCF ($a,0.973911); do_MCF ($a,0.974252); do_MCF ($a,0.974557); do_MCF ($a,0.974828); do_MCF ($a,0.975069); do_MCF ($a,0.975284); do_MCF ($a,0.975476); do_MCF ($a,0.975646); do_MCF ($a,0.975798); do_MCF ($a,0.975933); do_MCF ($a,0.976053);
$y = 17 ; $a=53; do_MCF ($a,0.980541); do_MCF ($a,0.980889); do_MCF ($a,0.981198); do_MCF ($a,0.981473); do_MCF ($a,0.981718); do_MCF ($a,0.981936); do_MCF ($a,0.982130); do_MCF ($a,0.982303); do_MCF ($a,0.982456); do_MCF ($a,0.982593); do_MCF ($a,0.982715); do_MCF ($a,0.982823); do_MCF ($a,0.982919); do_MCF ($a,0.983005); do_MCF ($a,0.983082); do_MCF ($a,0.983149); do_MCF ($a,0.983210);
$y = 17 ; $a=54; do_MCF ($a,0.990137); do_MCF ($a,0.990137); do_MCF ($a,0.990137); do_MCF ($a,0.990137); do_MCF ($a,0.990137); do_MCF ($a,0.990137); do_MCF ($a,0.990137); do_MCF ($a,0.990137); do_MCF ($a,0.990137); do_MCF ($a,0.990137); do_MCF ($a,0.990137); do_MCF ($a,0.990137); do_MCF ($a,0.990137); do_MCF ($a,0.990137); do_MCF ($a,0.990137); do_MCF ($a,0.990137); do_MCF ($a,0.990137);
$y = 17 ; $a=55; do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797);
$y = 17 ; $a=56; do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097);
$y = 17 ; $a=57; do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409);
$y = 17 ; $a=58; do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); 
$y = 17 ; $a=59; do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); 
# MCF -- males before Age 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 or more
$sex = "male";
$before_99 = "before";
$y = 34 ; $a=50; do_MCF ($a,0.961275);
$y = 34 ; $a=51; do_MCF ($a,0.968796); do_MCF ($a,0.968937);
$y = 34 ; $a=52; do_MCF ($a,0.976160); do_MCF ($a,0.976255); do_MCF ($a,0.976340);
$y = 34 ; $a=53; do_MCF ($a,0.983264); do_MCF ($a,0.983312); do_MCF ($a,0.983354); do_MCF ($a,0.983392);
$y = 34 ; $a=54; do_MCF ($a,0.990137); do_MCF ($a,0.990137); do_MCF ($a,0.990137); do_MCF ($a,0.990137); do_MCF ($a,0.990137);
$y = 34 ; $a=55; do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797);
$y = 34 ; $a=56; do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097);
$y = 34 ; $a=57; do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409);
$y = 34 ; $a=58; do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732);
$y = 34 ; $a=59; do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000);
$y = 34 ; $a=60; do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000);
$y = 34 ; $a=61; do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000);
$y = 34 ; $a=62; do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000);
$y = 34 ; $a=63; do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000);
$y = 34 ; $a=64; do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000);
$y = 34 ; $a=65; do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); 
$y = 34 ; $a=66; do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); 
# MCF -- females before Age 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16
$sex = "female";
$before_99 = "before";
$y = 0 ; $a=18; do_MCF ($a,0.286521); do_MCF ($a,0.301217); do_MCF ($a,0.318006);
$y = 0 ; $a=19; do_MCF ($a,0.294763); do_MCF ($a,0.309821); do_MCF ($a,0.323847); do_MCF ($a,0.340097);
$y = 0 ; $a=20; do_MCF ($a,0.303915); do_MCF ($a,0.320019); do_MCF ($a,0.334390); do_MCF ($a,0.347585); do_MCF ($a,0.363167);
$y = 0 ; $a=21; do_MCF ($a,0.314945); do_MCF ($a,0.331105); do_MCF ($a,0.346582); do_MCF ($a,0.360083); do_MCF ($a,0.372274); do_MCF ($a,0.387052);
$y = 0 ; $a=22; do_MCF ($a,0.327662); do_MCF ($a,0.343961); do_MCF ($a,0.359448); do_MCF ($a,0.374104); do_MCF ($a,0.386550); do_MCF ($a,0.397573); do_MCF ($a,0.411418);
$y = 0 ; $a=23; do_MCF ($a,0.343132); do_MCF ($a,0.359315); do_MCF ($a,0.374867); do_MCF ($a,0.389434); do_MCF ($a,0.403041); do_MCF ($a,0.414213); do_MCF ($a,0.423870); do_MCF ($a,0.436630);
$y = 0 ; $a=24; do_MCF ($a,0.359967); do_MCF ($a,0.376710); do_MCF ($a,0.392064); do_MCF ($a,0.406638); do_MCF ($a,0.420079); do_MCF ($a,0.432458); do_MCF ($a,0.442198); do_MCF ($a,0.450356); do_MCF ($a,0.461936);
$y = 0 ; $a=25; do_MCF ($a,0.378388); do_MCF ($a,0.395579); do_MCF ($a,0.411486); do_MCF ($a,0.425752); do_MCF ($a,0.439121); do_MCF ($a,0.451240); do_MCF ($a,0.462221); do_MCF ($a,0.470383); do_MCF ($a,0.476923); do_MCF ($a,0.487240);
$y = 0 ; $a=26; do_MCF ($a,0.398560); do_MCF ($a,0.415999); do_MCF ($a,0.432329); do_MCF ($a,0.447128); do_MCF ($a,0.460063); do_MCF ($a,0.472017); do_MCF ($a,0.482634); do_MCF ($a,0.492072); do_MCF ($a,0.498533); do_MCF ($a,0.503360); do_MCF ($a,0.512352);
$y = 0 ; $a=27; do_MCF ($a,0.420457); do_MCF ($a,0.438022); do_MCF ($a,0.454543); do_MCF ($a,0.469732); do_MCF ($a,0.483176); do_MCF ($a,0.494562); do_MCF ($a,0.504923); do_MCF ($a,0.513894); do_MCF ($a,0.521675); do_MCF ($a,0.526345); do_MCF ($a,0.529393); do_MCF ($a,0.539954);
$y = 0 ; $a=28; do_MCF ($a,0.442736); do_MCF ($a,0.460341); do_MCF ($a,0.476966); do_MCF ($a,0.492343); do_MCF ($a,0.506204); do_MCF ($a,0.518143); do_MCF ($a,0.527871); do_MCF ($a,0.536564); do_MCF ($a,0.543846); do_MCF ($a,0.549952); do_MCF ($a,0.552840); do_MCF ($a,0.562941); do_MCF ($a,0.572789);
$y = 0 ; $a=29; do_MCF ($a,0.465789); do_MCF ($a,0.483076); do_MCF ($a,0.499704); do_MCF ($a,0.515167); do_MCF ($a,0.529219); do_MCF ($a,0.541607); do_MCF ($a,0.551934); do_MCF ($a,0.559929); do_MCF ($a,0.566910); do_MCF ($a,0.572484); do_MCF ($a,0.576922); do_MCF ($a,0.586533); do_MCF ($a,0.595888); do_MCF ($a,0.604982);
$y = 0 ; $a=30; do_MCF ($a,0.489034); do_MCF ($a,0.505999); do_MCF ($a,0.522251); do_MCF ($a,0.537721); do_MCF ($a,0.551882); do_MCF ($a,0.564503); do_MCF ($a,0.575351); do_MCF ($a,0.584029); do_MCF ($a,0.590284); do_MCF ($a,0.595570); do_MCF ($a,0.599475); do_MCF ($a,0.608639); do_MCF ($a,0.617544); do_MCF ($a,0.626187); do_MCF ($a,0.634569);
$y = 0 ; $a=31; do_MCF ($a,0.512220); do_MCF ($a,0.528778); do_MCF ($a,0.544676); do_MCF ($a,0.559750); do_MCF ($a,0.573955); do_MCF ($a,0.586742); do_MCF ($a,0.597894); do_MCF ($a,0.607191); do_MCF ($a,0.614236); do_MCF ($a,0.618792); do_MCF ($a,0.622441); do_MCF ($a,0.631143); do_MCF ($a,0.639586); do_MCF ($a,0.647770); do_MCF ($a,0.655694); do_MCF ($a,0.663360);
$y = 0 ; $a=32; do_MCF ($a,0.535693); do_MCF ($a,0.551802); do_MCF ($a,0.567247); do_MCF ($a,0.581943); do_MCF ($a,0.595737); do_MCF ($a,0.608608); do_MCF ($a,0.619981); do_MCF ($a,0.629649); do_MCF ($a,0.637404); do_MCF ($a,0.642848); do_MCF ($a,0.645752); do_MCF ($a,0.653979); do_MCF ($a,0.661951); do_MCF ($a,0.669666); do_MCF ($a,0.677128); do_MCF ($a,0.684336); do_MCF ($a,0.691295);
$y = 0 ; $a=33; do_MCF ($a,0.559798); do_MCF ($a,0.575437); do_MCF ($a,0.590374); do_MCF ($a,0.604573); do_MCF ($a,0.617967); do_MCF ($a,0.630411); do_MCF ($a,0.641904); do_MCF ($a,0.651843); do_MCF ($a,0.660029); do_MCF ($a,0.666263); do_MCF ($a,0.670139); do_MCF ($a,0.677854); do_MCF ($a,0.685318); do_MCF ($a,0.692532); do_MCF ($a,0.699499); do_MCF ($a,0.706222); do_MCF ($a,0.712704);
$y = 0 ; $a=34; do_MCF ($a,0.583434); do_MCF ($a,0.598782); do_MCF ($a,0.613206); do_MCF ($a,0.626865); do_MCF ($a,0.639745); do_MCF ($a,0.651792); do_MCF ($a,0.662869); do_MCF ($a,0.672990); do_MCF ($a,0.681521); do_MCF ($a,0.688269); do_MCF ($a,0.693040); do_MCF ($a,0.700271); do_MCF ($a,0.707258); do_MCF ($a,0.714004); do_MCF ($a,0.720511); do_MCF ($a,0.726783); do_MCF ($a,0.732824);
$y = 0 ; $a=35; do_MCF ($a,0.606675); do_MCF ($a,0.621731); do_MCF ($a,0.635847); do_MCF ($a,0.648964); do_MCF ($a,0.661285); do_MCF ($a,0.672812); do_MCF ($a,0.683503); do_MCF ($a,0.693222); do_MCF ($a,0.702000); do_MCF ($a,0.709167); do_MCF ($a,0.714534); do_MCF ($a,0.721314); do_MCF ($a,0.727858); do_MCF ($a,0.734169); do_MCF ($a,0.740251); do_MCF ($a,0.746107); do_MCF ($a,0.751743);
$y = 0 ; $a=36; do_MCF ($a,0.629693); do_MCF ($a,0.644408); do_MCF ($a,0.658216); do_MCF ($a,0.671018); do_MCF ($a,0.682774); do_MCF ($a,0.693728); do_MCF ($a,0.703895); do_MCF ($a,0.713241); do_MCF ($a,0.721631); do_MCF ($a,0.729106); do_MCF ($a,0.734962); do_MCF ($a,0.741315); do_MCF ($a,0.747440); do_MCF ($a,0.753342); do_MCF ($a,0.759024); do_MCF ($a,0.764490); do_MCF ($a,0.769747);
$y = 0 ; $a=37; do_MCF ($a,0.652562); do_MCF ($a,0.666839); do_MCF ($a,0.680292); do_MCF ($a,0.692783); do_MCF ($a,0.704227); do_MCF ($a,0.714604); do_MCF ($a,0.724191); do_MCF ($a,0.733017); do_MCF ($a,0.741053); do_MCF ($a,0.748159); do_MCF ($a,0.754386); do_MCF ($a,0.760336); do_MCF ($a,0.766067); do_MCF ($a,0.771584); do_MCF ($a,0.776891); do_MCF ($a,0.781993); do_MCF ($a,0.786895);
$y = 0 ; $a=38; do_MCF ($a,0.675114); do_MCF ($a,0.688933); do_MCF ($a,0.701938); do_MCF ($a,0.714083); do_MCF ($a,0.725235); do_MCF ($a,0.735322); do_MCF ($a,0.744338); do_MCF ($a,0.752594); do_MCF ($a,0.760126); do_MCF ($a,0.766907); do_MCF ($a,0.772796); do_MCF ($a,0.778370); do_MCF ($a,0.783734); do_MCF ($a,0.788893); do_MCF ($a,0.793853); do_MCF ($a,0.798617); do_MCF ($a,0.803192);
$y = 0 ; $a=39; do_MCF ($a,0.697547); do_MCF ($a,0.710552); do_MCF ($a,0.723090); do_MCF ($a,0.734786); do_MCF ($a,0.745606); do_MCF ($a,0.755424); do_MCF ($a,0.764177); do_MCF ($a,0.771868); do_MCF ($a,0.778841); do_MCF ($a,0.785137); do_MCF ($a,0.790730); do_MCF ($a,0.795925); do_MCF ($a,0.800921); do_MCF ($a,0.805722); do_MCF ($a,0.810333); do_MCF ($a,0.814760); do_MCF ($a,0.819008);
$y = 0 ; $a=40; do_MCF ($a,0.719737); do_MCF ($a,0.731955); do_MCF ($a,0.743643); do_MCF ($a,0.754880); do_MCF ($a,0.765268); do_MCF ($a,0.774783); do_MCF ($a,0.783302); do_MCF ($a,0.790767); do_MCF ($a,0.797193); do_MCF ($a,0.802949); do_MCF ($a,0.808081); do_MCF ($a,0.812899); do_MCF ($a,0.817529); do_MCF ($a,0.821975); do_MCF ($a,0.826242); do_MCF ($a,0.830335); do_MCF ($a,0.834260);
$y = 0 ; $a=41; do_MCF ($a,0.741620); do_MCF ($a,0.753023); do_MCF ($a,0.763904); do_MCF ($a,0.774274); do_MCF ($a,0.784226); do_MCF ($a,0.793338); do_MCF ($a,0.801595); do_MCF ($a,0.808874); do_MCF ($a,0.815121); do_MCF ($a,0.820358); do_MCF ($a,0.824979); do_MCF ($a,0.829416); do_MCF ($a,0.833677); do_MCF ($a,0.837765); do_MCF ($a,0.841686); do_MCF ($a,0.845445); do_MCF ($a,0.849047);
$y = 0 ; $a=42; do_MCF ($a,0.762851); do_MCF ($a,0.773513); do_MCF ($a,0.783579); do_MCF ($a,0.793149); do_MCF ($a,0.802243); do_MCF ($a,0.810966); do_MCF ($a,0.818869); do_MCF ($a,0.825943); do_MCF ($a,0.832065); do_MCF ($a,0.837181); do_MCF ($a,0.841321); do_MCF ($a,0.845377); do_MCF ($a,0.849269); do_MCF ($a,0.853001); do_MCF ($a,0.856578); do_MCF ($a,0.860005); do_MCF ($a,0.863286);
$y = 0 ; $a=43; do_MCF ($a,0.783396); do_MCF ($a,0.793277); do_MCF ($a,0.802619); do_MCF ($a,0.811390); do_MCF ($a,0.819706); do_MCF ($a,0.827591); do_MCF ($a,0.835160); do_MCF ($a,0.841936); do_MCF ($a,0.847916); do_MCF ($a,0.852972); do_MCF ($a,0.857052); do_MCF ($a,0.860730); do_MCF ($a,0.864256); do_MCF ($a,0.867635); do_MCF ($a,0.870870); do_MCF ($a,0.873968); do_MCF ($a,0.876933);
$y = 0 ; $a=44; do_MCF ($a,0.803584); do_MCF ($a,0.812873); do_MCF ($a,0.821428); do_MCF ($a,0.829480); do_MCF ($a,0.836999); do_MCF ($a,0.844114); do_MCF ($a,0.850852); do_MCF ($a,0.857334); do_MCF ($a,0.863056); do_MCF ($a,0.868017); do_MCF ($a,0.872085); do_MCF ($a,0.875396); do_MCF ($a,0.878568); do_MCF ($a,0.881606); do_MCF ($a,0.884513); do_MCF ($a,0.887294); do_MCF ($a,0.889954);
$y = 0 ; $a=45; do_MCF ($a,0.819462); do_MCF ($a,0.832075); do_MCF ($a,0.840053); do_MCF ($a,0.847320); do_MCF ($a,0.854132); do_MCF ($a,0.860459); do_MCF ($a,0.866440); do_MCF ($a,0.872102); do_MCF ($a,0.877572); do_MCF ($a,0.882318); do_MCF ($a,0.886339); do_MCF ($a,0.889300); do_MCF ($a,0.892134); do_MCF ($a,0.894846); do_MCF ($a,0.897439); do_MCF ($a,0.899919); do_MCF ($a,0.902289);
$y = 0 ; $a=46; do_MCF ($a,0.838870); do_MCF ($a,0.846594); do_MCF ($a,0.858265); do_MCF ($a,0.864976); do_MCF ($a,0.871012); do_MCF ($a,0.876647); do_MCF ($a,0.881851); do_MCF ($a,0.886772); do_MCF ($a,0.891435); do_MCF ($a,0.895972); do_MCF ($a,0.899819); do_MCF ($a,0.902445); do_MCF ($a,0.904956); do_MCF ($a,0.907357); do_MCF ($a,0.909652); do_MCF ($a,0.911845); do_MCF ($a,0.913940);
$y = 0 ; $a=47; do_MCF ($a,0.857879); do_MCF ($a,0.864760); do_MCF ($a,0.871222); do_MCF ($a,0.882012); do_MCF ($a,0.887531); do_MCF ($a,0.892414); do_MCF ($a,0.896957); do_MCF ($a,0.901126); do_MCF ($a,0.905075); do_MCF ($a,0.908827); do_MCF ($a,0.912519); do_MCF ($a,0.914824); do_MCF ($a,0.917028); do_MCF ($a,0.919134); do_MCF ($a,0.921145); do_MCF ($a,0.923066); do_MCF ($a,0.924900);
$y = 0 ; $a=48; do_MCF ($a,0.876611); do_MCF ($a,0.882622); do_MCF ($a,0.888251); do_MCF ($a,0.893514); do_MCF ($a,0.903497); do_MCF ($a,0.907901); do_MCF ($a,0.911713); do_MCF ($a,0.915248); do_MCF ($a,0.918467); do_MCF ($a,0.921528); do_MCF ($a,0.924454); do_MCF ($a,0.926454); do_MCF ($a,0.928365); do_MCF ($a,0.930190); do_MCF ($a,0.931932); do_MCF ($a,0.933593); do_MCF ($a,0.935179);
$y = 0 ; $a=49; do_MCF ($a,0.895065); do_MCF ($a,0.900188); do_MCF ($a,0.904973); do_MCF ($a,0.909435); do_MCF ($a,0.913592); do_MCF ($a,0.922861); do_MCF ($a,0.926246); do_MCF ($a,0.929084); do_MCF ($a,0.931707); do_MCF ($a,0.934069); do_MCF ($a,0.936336); do_MCF ($a,0.938023); do_MCF ($a,0.939633); do_MCF ($a,0.941169); do_MCF ($a,0.942634); do_MCF ($a,0.944031); do_MCF ($a,0.945363);
$y = 0 ; $a=50; do_MCF ($a,0.913472); do_MCF ($a,0.917670); do_MCF ($a,0.921578); do_MCF ($a,0.925212); do_MCF ($a,0.928589); do_MCF ($a,0.931723); do_MCF ($a,0.940366); do_MCF ($a,0.942818); do_MCF ($a,0.944768); do_MCF ($a,0.946562); do_MCF ($a,0.948152); do_MCF ($a,0.949514); do_MCF ($a,0.950813); do_MCF ($a,0.952052); do_MCF ($a,0.953232); do_MCF ($a,0.954356); do_MCF ($a,0.955427);
$y = 0 ; $a=51; do_MCF ($a,0.931538); do_MCF ($a,0.934784); do_MCF ($a,0.937796); do_MCF ($a,0.940588); do_MCF ($a,0.943174); do_MCF ($a,0.945569); do_MCF ($a,0.947785); do_MCF ($a,0.955905); do_MCF ($a,0.957524); do_MCF ($a,0.958682); do_MCF ($a,0.959743); do_MCF ($a,0.960774); do_MCF ($a,0.961756); do_MCF ($a,0.962692); do_MCF ($a,0.963582); do_MCF ($a,0.964430); do_MCF ($a,0.965237);
$y = 0 ; $a=52; do_MCF ($a,0.949627); do_MCF ($a,0.951860); do_MCF ($a,0.953922); do_MCF ($a,0.955828); do_MCF ($a,0.957588); do_MCF ($a,0.959212); do_MCF ($a,0.960711); do_MCF ($a,0.962095); do_MCF ($a,0.969781); do_MCF ($a,0.970648); do_MCF ($a,0.971093); do_MCF ($a,0.971784); do_MCF ($a,0.972442); do_MCF ($a,0.973067); do_MCF ($a,0.973662); do_MCF ($a,0.974228); do_MCF ($a,0.974766);
$y = 0 ; $a=53; do_MCF ($a,0.967486); do_MCF ($a,0.968647); do_MCF ($a,0.969716); do_MCF ($a,0.970700); do_MCF ($a,0.971604); do_MCF ($a,0.972437); do_MCF ($a,0.973202); do_MCF ($a,0.973907); do_MCF ($a,0.974555); do_MCF ($a,0.981905); do_MCF ($a,0.982111); do_MCF ($a,0.982454); do_MCF ($a,0.982779); do_MCF ($a,0.983089); do_MCF ($a,0.983382); do_MCF ($a,0.983662); do_MCF ($a,0.983927);
$y = 0 ; $a=54; do_MCF ($a,0.985892); do_MCF ($a,0.985892); do_MCF ($a,0.985892); do_MCF ($a,0.985892); do_MCF ($a,0.985892); do_MCF ($a,0.985892); do_MCF ($a,0.985892); do_MCF ($a,0.985892); do_MCF ($a,0.985892); do_MCF ($a,0.985892); do_MCF ($a,0.993017); do_MCF ($a,0.993017); do_MCF ($a,0.993017); do_MCF ($a,0.993017); do_MCF ($a,0.993017); do_MCF ($a,0.993017); do_MCF ($a,0.993017);
$y = 0 ; $a=55; do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304);
$y = 0 ; $a=56; do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562);
$y = 0 ; $a=57; do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749);
$y = 0 ; $a=58; do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); 
$y = 0 ; $a=59; do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); 
# MCF -- females before Age 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33
$sex = "female";
$before_99 = "before";
$y = 17 ; $a=33; do_MCF ($a,0.718950);
$y = 17 ; $a=34; do_MCF ($a,0.738639); do_MCF ($a,0.744232);
$y = 17 ; $a=35; do_MCF ($a,0.757163); do_MCF ($a,0.762372); do_MCF ($a,0.767375);
$y = 17 ; $a=36; do_MCF ($a,0.774798); do_MCF ($a,0.779648); do_MCF ($a,0.784305); do_MCF ($a,0.788772);
$y = 17 ; $a=37; do_MCF ($a,0.791602); do_MCF ($a,0.796120); do_MCF ($a,0.800453); do_MCF ($a,0.804608); do_MCF ($a,0.808590);
$y = 17 ; $a=38; do_MCF ($a,0.807581); do_MCF ($a,0.811792); do_MCF ($a,0.815828); do_MCF ($a,0.819696); do_MCF ($a,0.823400); do_MCF ($a,0.826947);
$y = 17 ; $a=39; do_MCF ($a,0.823082); do_MCF ($a,0.826986); do_MCF ($a,0.830727); do_MCF ($a,0.834310); do_MCF ($a,0.837740); do_MCF ($a,0.841022); do_MCF ($a,0.844162);
$y = 17 ; $a=40; do_MCF ($a,0.838022); do_MCF ($a,0.841626); do_MCF ($a,0.845077); do_MCF ($a,0.848380); do_MCF ($a,0.851540); do_MCF ($a,0.854563); do_MCF ($a,0.857453); do_MCF ($a,0.860216);
$y = 17 ; $a=41; do_MCF ($a,0.852498); do_MCF ($a,0.855801); do_MCF ($a,0.858962); do_MCF ($a,0.861986); do_MCF ($a,0.864878); do_MCF ($a,0.867644); do_MCF ($a,0.870286); do_MCF ($a,0.872811); do_MCF ($a,0.875223);
$y = 17 ; $a=42; do_MCF ($a,0.866427); do_MCF ($a,0.869432); do_MCF ($a,0.872307); do_MCF ($a,0.875056); do_MCF ($a,0.877683); do_MCF ($a,0.880194); do_MCF ($a,0.882593); do_MCF ($a,0.884884); do_MCF ($a,0.887071); do_MCF ($a,0.889158);
$y = 17 ; $a=43; do_MCF ($a,0.879769); do_MCF ($a,0.882481); do_MCF ($a,0.885074); do_MCF ($a,0.887552); do_MCF ($a,0.889919); do_MCF ($a,0.892180); do_MCF ($a,0.894339); do_MCF ($a,0.896401); do_MCF ($a,0.898368); do_MCF ($a,0.900245); do_MCF ($a,0.902036);
$y = 17 ; $a=44; do_MCF ($a,0.892497); do_MCF ($a,0.894928); do_MCF ($a,0.897250); do_MCF ($a,0.899469); do_MCF ($a,0.901587); do_MCF ($a,0.903610); do_MCF ($a,0.905540); do_MCF ($a,0.907383); do_MCF ($a,0.909140); do_MCF ($a,0.910816); do_MCF ($a,0.912415); do_MCF ($a,0.913939);
$y = 17 ; $a=45; do_MCF ($a,0.904554); do_MCF ($a,0.906718); do_MCF ($a,0.908784); do_MCF ($a,0.910757); do_MCF ($a,0.912640); do_MCF ($a,0.914436); do_MCF ($a,0.916151); do_MCF ($a,0.917786); do_MCF ($a,0.919345); do_MCF ($a,0.920832); do_MCF ($a,0.922249); do_MCF ($a,0.923600); do_MCF ($a,0.924888);
$y = 17 ; $a=46; do_MCF ($a,0.915941); do_MCF ($a,0.917851); do_MCF ($a,0.919674); do_MCF ($a,0.921414); do_MCF ($a,0.923074); do_MCF ($a,0.924657); do_MCF ($a,0.926167); do_MCF ($a,0.927606); do_MCF ($a,0.928979); do_MCF ($a,0.930287); do_MCF ($a,0.931533); do_MCF ($a,0.932721); do_MCF ($a,0.933852); do_MCF ($a,0.934930);
$y = 17 ; $a=47; do_MCF ($a,0.926650); do_MCF ($a,0.928319); do_MCF ($a,0.929913); do_MCF ($a,0.931432); do_MCF ($a,0.932881); do_MCF ($a,0.934263); do_MCF ($a,0.935580); do_MCF ($a,0.936835); do_MCF ($a,0.938031); do_MCF ($a,0.939170); do_MCF ($a,0.940256); do_MCF ($a,0.941290); do_MCF ($a,0.942275); do_MCF ($a,0.943213); do_MCF ($a,0.944106);
$y = 17 ; $a=48; do_MCF ($a,0.936692); do_MCF ($a,0.938134); do_MCF ($a,0.939509); do_MCF ($a,0.940821); do_MCF ($a,0.942070); do_MCF ($a,0.943261); do_MCF ($a,0.944396); do_MCF ($a,0.945477); do_MCF ($a,0.946507); do_MCF ($a,0.947488); do_MCF ($a,0.948422); do_MCF ($a,0.949311); do_MCF ($a,0.950158); do_MCF ($a,0.950964); do_MCF ($a,0.951731); do_MCF ($a,0.952462);
$y = 17 ; $a=49; do_MCF ($a,0.946632); do_MCF ($a,0.947843); do_MCF ($a,0.948996); do_MCF ($a,0.950094); do_MCF ($a,0.951141); do_MCF ($a,0.952138); do_MCF ($a,0.953087); do_MCF ($a,0.953992); do_MCF ($a,0.954853); do_MCF ($a,0.955672); do_MCF ($a,0.956452); do_MCF ($a,0.957195); do_MCF ($a,0.957902); do_MCF ($a,0.958574); do_MCF ($a,0.959214); do_MCF ($a,0.959823); do_MCF ($a,0.960403);
$y = 17 ; $a=50; do_MCF ($a,0.956447); do_MCF ($a,0.957419); do_MCF ($a,0.958345); do_MCF ($a,0.959226); do_MCF ($a,0.960065); do_MCF ($a,0.960864); do_MCF ($a,0.961624); do_MCF ($a,0.962347); do_MCF ($a,0.963036); do_MCF ($a,0.963691); do_MCF ($a,0.964315); do_MCF ($a,0.964908); do_MCF ($a,0.965472); do_MCF ($a,0.966009); do_MCF ($a,0.966520); do_MCF ($a,0.967006); do_MCF ($a,0.967468);
$y = 17 ; $a=51; do_MCF ($a,0.966005); do_MCF ($a,0.966736); do_MCF ($a,0.967432); do_MCF ($a,0.968094); do_MCF ($a,0.968724); do_MCF ($a,0.969323); do_MCF ($a,0.969893); do_MCF ($a,0.970435); do_MCF ($a,0.970951); do_MCF ($a,0.971441); do_MCF ($a,0.971908); do_MCF ($a,0.972352); do_MCF ($a,0.972773); do_MCF ($a,0.973175); do_MCF ($a,0.973556); do_MCF ($a,0.973919); do_MCF ($a,0.974264);
$y = 17 ; $a=52; do_MCF ($a,0.975278); do_MCF ($a,0.975764); do_MCF ($a,0.976227); do_MCF ($a,0.976667); do_MCF ($a,0.977085); do_MCF ($a,0.977482); do_MCF ($a,0.977860); do_MCF ($a,0.978220); do_MCF ($a,0.978561); do_MCF ($a,0.978886); do_MCF ($a,0.979195); do_MCF ($a,0.979488); do_MCF ($a,0.979767); do_MCF ($a,0.980032); do_MCF ($a,0.980284); do_MCF ($a,0.980523); do_MCF ($a,0.980751);
$y = 17 ; $a=53; do_MCF ($a,0.984179); do_MCF ($a,0.984418); do_MCF ($a,0.984645); do_MCF ($a,0.984861); do_MCF ($a,0.985067); do_MCF ($a,0.985262); do_MCF ($a,0.985447); do_MCF ($a,0.985623); do_MCF ($a,0.985790); do_MCF ($a,0.985949); do_MCF ($a,0.986099); do_MCF ($a,0.986243); do_MCF ($a,0.986379); do_MCF ($a,0.986508); do_MCF ($a,0.986631); do_MCF ($a,0.986748); do_MCF ($a,0.986859);
$y = 17 ; $a=54; do_MCF ($a,0.993017); do_MCF ($a,0.993017); do_MCF ($a,0.993017); do_MCF ($a,0.993017); do_MCF ($a,0.993017); do_MCF ($a,0.993017); do_MCF ($a,0.993017); do_MCF ($a,0.993017); do_MCF ($a,0.993017); do_MCF ($a,0.993017); do_MCF ($a,0.993017); do_MCF ($a,0.993017); do_MCF ($a,0.993017); do_MCF ($a,0.993017); do_MCF ($a,0.993017); do_MCF ($a,0.993017); do_MCF ($a,0.993017);
$y = 17 ; $a=55; do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304);
$y = 17 ; $a=56; do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562);
$y = 17 ; $a=57; do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749);
$y = 17 ; $a=58; do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); 
$y = 17 ; $a=59; do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); 
# MCF -- females before Age 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 or more
$sex = "female";
$before_99 = "before";
$y = 34 ; $a=50; do_MCF ($a,0.967907);
$y = 34 ; $a=51; do_MCF ($a,0.974592); do_MCF ($a,0.974903);
$y = 34 ; $a=52; do_MCF ($a,0.980967); do_MCF ($a,0.981173); do_MCF ($a,0.981368);
$y = 34 ; $a=53; do_MCF ($a,0.986964); do_MCF ($a,0.987064); do_MCF ($a,0.987159); do_MCF ($a,0.987249);
$y = 34 ; $a=54; do_MCF ($a,0.993017); do_MCF ($a,0.993017); do_MCF ($a,0.993017); do_MCF ($a,0.993017); do_MCF ($a,0.993017);
$y = 34 ; $a=55; do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304);
$y = 34 ; $a=56; do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562);
$y = 34 ; $a=57; do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749);
$y = 34 ; $a=58; do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886);
$y = 34 ; $a=59; do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000);
$y = 34 ; $a=60; do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000);
$y = 34 ; $a=61; do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000);
$y = 34 ; $a=62; do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000);
$y = 34 ; $a=63; do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000);
$y = 34 ; $a=64; do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000);
$y = 34 ; $a=65; do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); 
$y = 34 ; $a=66; do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); 
# PCF -- males before Age 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16
$sex = "male";
$before_99 = "before";
$y = 0 ; $a=18; do_PCF ($a,0.350697); do_PCF ($a,0.377677); do_PCF ($a,0.401730);
$y = 0 ; $a=19; do_PCF ($a,0.355387); do_PCF ($a,0.382384); do_PCF ($a,0.407088); do_PCF ($a,0.428667);
$y = 0 ; $a=20; do_PCF ($a,0.362118); do_PCF ($a,0.388970); do_PCF ($a,0.413615); do_PCF ($a,0.435801); do_PCF ($a,0.454761);
$y = 0 ; $a=21; do_PCF ($a,0.370867); do_PCF ($a,0.397610); do_PCF ($a,0.422003); do_PCF ($a,0.444023); do_PCF ($a,0.463527); do_PCF ($a,0.479794);
$y = 0 ; $a=22; do_PCF ($a,0.381295); do_PCF ($a,0.407978); do_PCF ($a,0.432172); do_PCF ($a,0.453831); do_PCF ($a,0.473071); do_PCF ($a,0.489836); do_PCF ($a,0.503428);
$y = 0 ; $a=23; do_PCF ($a,0.395091); do_PCF ($a,0.421388); do_PCF ($a,0.445298); do_PCF ($a,0.466519); do_PCF ($a,0.485158); do_PCF ($a,0.501444); do_PCF ($a,0.515382); do_PCF ($a,0.526277);
$y = 0 ; $a=24; do_PCF ($a,0.410021); do_PCF ($a,0.436048); do_PCF ($a,0.459457); do_PCF ($a,0.480313); do_PCF ($a,0.498432); do_PCF ($a,0.514039); do_PCF ($a,0.527444); do_PCF ($a,0.538689); do_PCF ($a,0.547060);
$y = 0 ; $a=25; do_PCF ($a,0.425971); do_PCF ($a,0.451591); do_PCF ($a,0.474647); do_PCF ($a,0.494914); do_PCF ($a,0.512615); do_PCF ($a,0.527649); do_PCF ($a,0.540326); do_PCF ($a,0.551009); do_PCF ($a,0.559755); do_PCF ($a,0.565817);
$y = 0 ; $a=26; do_PCF ($a,0.442979); do_PCF ($a,0.468007); do_PCF ($a,0.490567); do_PCF ($a,0.510423); do_PCF ($a,0.527473); do_PCF ($a,0.542060); do_PCF ($a,0.554135); do_PCF ($a,0.564061); do_PCF ($a,0.572235); do_PCF ($a,0.578710); do_PCF ($a,0.582697);
$y = 0 ; $a=27; do_PCF ($a,0.460617); do_PCF ($a,0.485154); do_PCF ($a,0.507038); do_PCF ($a,0.526359); do_PCF ($a,0.542987); do_PCF ($a,0.556906); do_PCF ($a,0.568542); do_PCF ($a,0.577871); do_PCF ($a,0.585290); do_PCF ($a,0.591208); do_PCF ($a,0.595662); do_PCF ($a,0.613234);
$y = 0 ; $a=28; do_PCF ($a,0.478431); do_PCF ($a,0.502317); do_PCF ($a,0.523705); do_PCF ($a,0.542351); do_PCF ($a,0.558481); do_PCF ($a,0.572033); do_PCF ($a,0.583043); do_PCF ($a,0.591993); do_PCF ($a,0.598863); do_PCF ($a,0.604066); do_PCF ($a,0.608009); do_PCF ($a,0.624994); do_PCF ($a,0.640662);
$y = 0 ; $a=29; do_PCF ($a,0.496534); do_PCF ($a,0.519919); do_PCF ($a,0.540622); do_PCF ($a,0.558784); do_PCF ($a,0.574249); do_PCF ($a,0.587340); do_PCF ($a,0.598034); do_PCF ($a,0.606391); do_PCF ($a,0.612930); do_PCF ($a,0.617621); do_PCF ($a,0.620877); do_PCF ($a,0.637264); do_PCF ($a,0.652363); do_PCF ($a,0.666222);
$y = 0 ; $a=30; do_PCF ($a,0.514828); do_PCF ($a,0.537554); do_PCF ($a,0.557772); do_PCF ($a,0.575267); do_PCF ($a,0.590301); do_PCF ($a,0.602773); do_PCF ($a,0.613069); do_PCF ($a,0.621182); do_PCF ($a,0.627179); do_PCF ($a,0.631597); do_PCF ($a,0.634387); do_PCF ($a,0.650155); do_PCF ($a,0.664666); do_PCF ($a,0.677970); do_PCF ($a,0.690129);
$y = 0 ; $a=31; do_PCF ($a,0.533583); do_PCF ($a,0.555609); do_PCF ($a,0.575147); do_PCF ($a,0.592178); do_PCF ($a,0.606564); do_PCF ($a,0.618650); do_PCF ($a,0.628361); do_PCF ($a,0.636125); do_PCF ($a,0.641930); do_PCF ($a,0.645842); do_PCF ($a,0.648402); do_PCF ($a,0.663537); do_PCF ($a,0.677448); do_PCF ($a,0.690190); do_PCF ($a,0.701822); do_PCF ($a,0.712412);
$y = 0 ; $a=32; do_PCF ($a,0.553040); do_PCF ($a,0.574219); do_PCF ($a,0.593026); do_PCF ($a,0.609374); do_PCF ($a,0.623325); do_PCF ($a,0.634784); do_PCF ($a,0.644154); do_PCF ($a,0.651365); do_PCF ($a,0.656865); do_PCF ($a,0.660630); do_PCF ($a,0.662712); do_PCF ($a,0.677217); do_PCF ($a,0.690534); do_PCF ($a,0.702717); do_PCF ($a,0.713829); do_PCF ($a,0.723937); do_PCF ($a,0.733109);
$y = 0 ; $a=33; do_PCF ($a,0.573399); do_PCF ($a,0.593785); do_PCF ($a,0.611673); do_PCF ($a,0.627258); do_PCF ($a,0.640517); do_PCF ($a,0.651563); do_PCF ($a,0.660317); do_PCF ($a,0.667217); do_PCF ($a,0.672182); do_PCF ($a,0.675671); do_PCF ($a,0.677638); do_PCF ($a,0.691488); do_PCF ($a,0.704187); do_PCF ($a,0.715792); do_PCF ($a,0.726366); do_PCF ($a,0.735976); do_PCF ($a,0.744690);
$y = 0 ; $a=34; do_PCF ($a,0.593617); do_PCF ($a,0.613585); do_PCF ($a,0.630671); do_PCF ($a,0.645340); do_PCF ($a,0.657871); do_PCF ($a,0.668272); do_PCF ($a,0.676680); do_PCF ($a,0.683016); do_PCF ($a,0.687736); do_PCF ($a,0.690737); do_PCF ($a,0.692482); do_PCF ($a,0.705691); do_PCF ($a,0.717788); do_PCF ($a,0.728831); do_PCF ($a,0.738884); do_PCF ($a,0.748013); do_PCF ($a,0.756283);
$y = 0 ; $a=35; do_PCF ($a,0.613756); do_PCF ($a,0.633280); do_PCF ($a,0.649983); do_PCF ($a,0.663860); do_PCF ($a,0.675489); do_PCF ($a,0.685199); do_PCF ($a,0.693010); do_PCF ($a,0.699064); do_PCF ($a,0.703266); do_PCF ($a,0.706078); do_PCF ($a,0.707375); do_PCF ($a,0.719948); do_PCF ($a,0.731448); do_PCF ($a,0.741935); do_PCF ($a,0.751472); do_PCF ($a,0.760125); do_PCF ($a,0.767960);
$y = 0 ; $a=36; do_PCF ($a,0.633588); do_PCF ($a,0.652636); do_PCF ($a,0.668962); do_PCF ($a,0.682534); do_PCF ($a,0.693417); do_PCF ($a,0.702269); do_PCF ($a,0.709450); do_PCF ($a,0.714969); do_PCF ($a,0.718961); do_PCF ($a,0.721311); do_PCF ($a,0.722481); do_PCF ($a,0.734404); do_PCF ($a,0.745297); do_PCF ($a,0.755220); do_PCF ($a,0.764235); do_PCF ($a,0.772408); do_PCF ($a,0.779801);
$y = 0 ; $a=37; do_PCF ($a,0.653343); do_PCF ($a,0.671770); do_PCF ($a,0.687678); do_PCF ($a,0.700945); do_PCF ($a,0.711602); do_PCF ($a,0.719752); do_PCF ($a,0.726112); do_PCF ($a,0.731051); do_PCF ($a,0.734560); do_PCF ($a,0.736761); do_PCF ($a,0.737511); do_PCF ($a,0.748797); do_PCF ($a,0.759095); do_PCF ($a,0.768467); do_PCF ($a,0.776973); do_PCF ($a,0.784678); do_PCF ($a,0.791643);
$y = 0 ; $a=38; do_PCF ($a,0.673022); do_PCF ($a,0.690811); do_PCF ($a,0.706145); do_PCF ($a,0.719069); do_PCF ($a,0.729503); do_PCF ($a,0.737509); do_PCF ($a,0.743211); do_PCF ($a,0.747366); do_PCF ($a,0.750342); do_PCF ($a,0.752106); do_PCF ($a,0.752761); do_PCF ($a,0.763394); do_PCF ($a,0.773084); do_PCF ($a,0.781893); do_PCF ($a,0.789881); do_PCF ($a,0.797110); do_PCF ($a,0.803639);
$y = 0 ; $a=39; do_PCF ($a,0.692995); do_PCF ($a,0.709727); do_PCF ($a,0.724471); do_PCF ($a,0.736882); do_PCF ($a,0.747052); do_PCF ($a,0.754918); do_PCF ($a,0.760556); do_PCF ($a,0.764095); do_PCF ($a,0.766320); do_PCF ($a,0.767593); do_PCF ($a,0.767851); do_PCF ($a,0.777841); do_PCF ($a,0.786935); do_PCF ($a,0.795192); do_PCF ($a,0.802672); do_PCF ($a,0.809436); do_PCF ($a,0.815542);
$y = 0 ; $a=40; do_PCF ($a,0.713310); do_PCF ($a,0.728989); do_PCF ($a,0.742680); do_PCF ($a,0.754561); do_PCF ($a,0.764284); do_PCF ($a,0.771965); do_PCF ($a,0.777541); do_PCF ($a,0.781090); do_PCF ($a,0.782736); do_PCF ($a,0.783285); do_PCF ($a,0.783087); do_PCF ($a,0.792415); do_PCF ($a,0.800895); do_PCF ($a,0.808586); do_PCF ($a,0.815548); do_PCF ($a,0.821836); do_PCF ($a,0.827508);
$y = 0 ; $a=41; do_PCF ($a,0.734095); do_PCF ($a,0.748748); do_PCF ($a,0.761395); do_PCF ($a,0.772245); do_PCF ($a,0.781509); do_PCF ($a,0.788816); do_PCF ($a,0.794291); do_PCF ($a,0.797860); do_PCF ($a,0.799592); do_PCF ($a,0.799603); do_PCF ($a,0.798713); do_PCF ($a,0.807345); do_PCF ($a,0.815182); do_PCF ($a,0.822282); do_PCF ($a,0.828701); do_PCF ($a,0.834494); do_PCF ($a,0.839715);
$y = 0 ; $a=42; do_PCF ($a,0.755053); do_PCF ($a,0.768573); do_PCF ($a,0.780236); do_PCF ($a,0.790092); do_PCF ($a,0.798379); do_PCF ($a,0.805318); do_PCF ($a,0.810507); do_PCF ($a,0.814065); do_PCF ($a,0.815902); do_PCF ($a,0.816075); do_PCF ($a,0.814688); do_PCF ($a,0.822577); do_PCF ($a,0.829729); do_PCF ($a,0.836200); do_PCF ($a,0.842044); do_PCF ($a,0.847314); do_PCF ($a,0.852058);
$y = 0 ; $a=43; do_PCF ($a,0.776033); do_PCF ($a,0.788436); do_PCF ($a,0.799018); do_PCF ($a,0.807961); do_PCF ($a,0.815324); do_PCF ($a,0.821356); do_PCF ($a,0.826276); do_PCF ($a,0.829640); do_PCF ($a,0.831560); do_PCF ($a,0.831923); do_PCF ($a,0.830772); do_PCF ($a,0.837889); do_PCF ($a,0.844332); do_PCF ($a,0.850154); do_PCF ($a,0.855405); do_PCF ($a,0.860136); do_PCF ($a,0.864391);
$y = 0 ; $a=44; do_PCF ($a,0.796881); do_PCF ($a,0.808262); do_PCF ($a,0.817804); do_PCF ($a,0.825747); do_PCF ($a,0.832289); do_PCF ($a,0.837482); do_PCF ($a,0.841574); do_PCF ($a,0.844772); do_PCF ($a,0.846591); do_PCF ($a,0.847128); do_PCF ($a,0.846249); do_PCF ($a,0.852642); do_PCF ($a,0.858422); do_PCF ($a,0.863638); do_PCF ($a,0.868339); do_PCF ($a,0.872569); do_PCF ($a,0.876371);
$y = 0 ; $a=45; do_PCF ($a,0.812319); do_PCF ($a,0.828014); do_PCF ($a,0.836612); do_PCF ($a,0.843593); do_PCF ($a,0.849213); do_PCF ($a,0.853669); do_PCF ($a,0.856995); do_PCF ($a,0.859433); do_PCF ($a,0.861175); do_PCF ($a,0.861690); do_PCF ($a,0.861065); do_PCF ($a,0.866786); do_PCF ($a,0.871953); do_PCF ($a,0.876610); do_PCF ($a,0.880803); do_PCF ($a,0.884573); do_PCF ($a,0.887958);
$y = 0 ; $a=46; do_PCF ($a,0.830558); do_PCF ($a,0.841801); do_PCF ($a,0.855318); do_PCF ($a,0.861442); do_PCF ($a,0.866181); do_PCF ($a,0.869792); do_PCF ($a,0.872462); do_PCF ($a,0.874203); do_PCF ($a,0.875245); do_PCF ($a,0.875765); do_PCF ($a,0.875188); do_PCF ($a,0.880293); do_PCF ($a,0.884896); do_PCF ($a,0.889041); do_PCF ($a,0.892769); do_PCF ($a,0.896118); do_PCF ($a,0.899123);
$y = 0 ; $a=47; do_PCF ($a,0.848643); do_PCF ($a,0.858676); do_PCF ($a,0.867554); do_PCF ($a,0.879182); do_PCF ($a,0.883152); do_PCF ($a,0.885958); do_PCF ($a,0.887853); do_PCF ($a,0.889009); do_PCF ($a,0.889415); do_PCF ($a,0.889286); do_PCF ($a,0.888785); do_PCF ($a,0.893307); do_PCF ($a,0.897380); do_PCF ($a,0.901044); do_PCF ($a,0.904335); do_PCF ($a,0.907289); do_PCF ($a,0.909938);
$y = 0 ; $a=48; do_PCF ($a,0.866591); do_PCF ($a,0.875390); do_PCF ($a,0.883150); do_PCF ($a,0.889969); do_PCF ($a,0.900003); do_PCF ($a,0.902122); do_PCF ($a,0.903282); do_PCF ($a,0.903725); do_PCF ($a,0.903609); do_PCF ($a,0.902895); do_PCF ($a,0.901789); do_PCF ($a,0.905766); do_PCF ($a,0.909344); do_PCF ($a,0.912559); do_PCF ($a,0.915444); do_PCF ($a,0.918031); do_PCF ($a,0.920349);
$y = 0 ; $a=49; do_PCF ($a,0.884735); do_PCF ($a,0.892281); do_PCF ($a,0.898911); do_PCF ($a,0.904720); do_PCF ($a,0.909794); do_PCF ($a,0.918528); do_PCF ($a,0.919079); do_PCF ($a,0.918852); do_PCF ($a,0.918079); do_PCF ($a,0.916898); do_PCF ($a,0.915250); do_PCF ($a,0.918654); do_PCF ($a,0.921712); do_PCF ($a,0.924456); do_PCF ($a,0.926915); do_PCF ($a,0.929118); do_PCF ($a,0.931090);
$y = 0 ; $a=50; do_PCF ($a,0.903134); do_PCF ($a,0.909384); do_PCF ($a,0.914854); do_PCF ($a,0.919628); do_PCF ($a,0.923787); do_PCF ($a,0.927402); do_PCF ($a,0.935100); do_PCF ($a,0.934328); do_PCF ($a,0.932935); do_PCF ($a,0.931140); do_PCF ($a,0.929067); do_PCF ($a,0.931869); do_PCF ($a,0.934382); do_PCF ($a,0.936632); do_PCF ($a,0.938647); do_PCF ($a,0.940449); do_PCF ($a,0.942061);
$y = 0 ; $a=51; do_PCF ($a,0.922022); do_PCF ($a,0.926899); do_PCF ($a,0.931146); do_PCF ($a,0.934837); do_PCF ($a,0.938041); do_PCF ($a,0.940819); do_PCF ($a,0.943223); do_PCF ($a,0.950101); do_PCF ($a,0.948219); do_PCF ($a,0.945849); do_PCF ($a,0.943200); do_PCF ($a,0.945371); do_PCF ($a,0.947313); do_PCF ($a,0.949050); do_PCF ($a,0.950603); do_PCF ($a,0.951989); do_PCF ($a,0.953227);
$y = 0 ; $a=52; do_PCF ($a,0.941088); do_PCF ($a,0.944511); do_PCF ($a,0.947475); do_PCF ($a,0.950038); do_PCF ($a,0.952254); do_PCF ($a,0.954168); do_PCF ($a,0.955820); do_PCF ($a,0.957245); do_PCF ($a,0.963513); do_PCF ($a,0.960705); do_PCF ($a,0.957518); do_PCF ($a,0.959015); do_PCF ($a,0.960352); do_PCF ($a,0.961544); do_PCF ($a,0.962608); do_PCF ($a,0.963557); do_PCF ($a,0.964403);
$y = 0 ; $a=53; do_PCF ($a,0.960579); do_PCF ($a,0.962402); do_PCF ($a,0.963970); do_PCF ($a,0.965319); do_PCF ($a,0.966479); do_PCF ($a,0.967476); do_PCF ($a,0.968334); do_PCF ($a,0.969071); do_PCF ($a,0.969706); do_PCF ($a,0.975539); do_PCF ($a,0.971947); do_PCF ($a,0.972720); do_PCF ($a,0.973407); do_PCF ($a,0.974019); do_PCF ($a,0.974564); do_PCF ($a,0.975049); do_PCF ($a,0.975481);
$y = 0 ; $a=54; do_PCF ($a,0.980865); do_PCF ($a,0.980865); do_PCF ($a,0.980865); do_PCF ($a,0.980865); do_PCF ($a,0.980865); do_PCF ($a,0.980865); do_PCF ($a,0.980865); do_PCF ($a,0.980865); do_PCF ($a,0.980865); do_PCF ($a,0.980865); do_PCF ($a,0.986414); do_PCF ($a,0.986414); do_PCF ($a,0.986414); do_PCF ($a,0.986414); do_PCF ($a,0.986414); do_PCF ($a,0.986414); do_PCF ($a,0.986414); 
$y = 0 ; $a=55; do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); 
# PCF -- males before Age 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33
$sex = "male";
$before_99 = "before";
$y = 17 ; $a=33; do_PCF ($a,0.752574);
$y = 17 ; $a=34; do_PCF ($a,0.763761); do_PCF ($a,0.770512);
$y = 17 ; $a=35; do_PCF ($a,0.775039); do_PCF ($a,0.781425); do_PCF ($a,0.787177);
$y = 17 ; $a=36; do_PCF ($a,0.786478); do_PCF ($a,0.792497); do_PCF ($a,0.797916); do_PCF ($a,0.802789);
$y = 17 ; $a=37; do_PCF ($a,0.797929); do_PCF ($a,0.803592); do_PCF ($a,0.808688); do_PCF ($a,0.813268); do_PCF ($a,0.817380);
$y = 17 ; $a=38; do_PCF ($a,0.809528); do_PCF ($a,0.814831); do_PCF ($a,0.819600); do_PCF ($a,0.823883); do_PCF ($a,0.827728); do_PCF ($a,0.831174);
$y = 17 ; $a=39; do_PCF ($a,0.821044); do_PCF ($a,0.825995); do_PCF ($a,0.830446); do_PCF ($a,0.834442); do_PCF ($a,0.838027); do_PCF ($a,0.841240); do_PCF ($a,0.844117);
$y = 17 ; $a=40; do_PCF ($a,0.832615); do_PCF ($a,0.837209); do_PCF ($a,0.841336); do_PCF ($a,0.845040); do_PCF ($a,0.848360); do_PCF ($a,0.851335); do_PCF ($a,0.853998); do_PCF ($a,0.856381);
$y = 17 ; $a=41; do_PCF ($a,0.844413); do_PCF ($a,0.848636); do_PCF ($a,0.852427); do_PCF ($a,0.855828); do_PCF ($a,0.858875); do_PCF ($a,0.861605); do_PCF ($a,0.864047); do_PCF ($a,0.866231); do_PCF ($a,0.868184);
$y = 17 ; $a=42; do_PCF ($a,0.856324); do_PCF ($a,0.860156); do_PCF ($a,0.863594); do_PCF ($a,0.866676); do_PCF ($a,0.869437); do_PCF ($a,0.871908); do_PCF ($a,0.874119); do_PCF ($a,0.876095); do_PCF ($a,0.877861); do_PCF ($a,0.879439);
$y = 17 ; $a=43; do_PCF ($a,0.868215); do_PCF ($a,0.871646); do_PCF ($a,0.874723); do_PCF ($a,0.877480); do_PCF ($a,0.879949); do_PCF ($a,0.882157); do_PCF ($a,0.884132); do_PCF ($a,0.885897); do_PCF ($a,0.887474); do_PCF ($a,0.888882); do_PCF ($a,0.890138);
$y = 17 ; $a=44; do_PCF ($a,0.879784); do_PCF ($a,0.882846); do_PCF ($a,0.885590); do_PCF ($a,0.888047); do_PCF ($a,0.890245); do_PCF ($a,0.892212); do_PCF ($a,0.893970); do_PCF ($a,0.895540); do_PCF ($a,0.896942); do_PCF ($a,0.898194); do_PCF ($a,0.899312); do_PCF ($a,0.900308);
$y = 17 ; $a=45; do_PCF ($a,0.890995); do_PCF ($a,0.893718); do_PCF ($a,0.896156); do_PCF ($a,0.898339); do_PCF ($a,0.900291); do_PCF ($a,0.902036); do_PCF ($a,0.903596); do_PCF ($a,0.904988); do_PCF ($a,0.906232); do_PCF ($a,0.907342); do_PCF ($a,0.908332); do_PCF ($a,0.909215); do_PCF ($a,0.910003);
$y = 17 ; $a=46; do_PCF ($a,0.901818); do_PCF ($a,0.904231); do_PCF ($a,0.906392); do_PCF ($a,0.908325); do_PCF ($a,0.910053); do_PCF ($a,0.911598); do_PCF ($a,0.912977); do_PCF ($a,0.914209); do_PCF ($a,0.915309); do_PCF ($a,0.916290); do_PCF ($a,0.917165); do_PCF ($a,0.917945); do_PCF ($a,0.918641); do_PCF ($a,0.919261);
$y = 17 ; $a=47; do_PCF ($a,0.912311); do_PCF ($a,0.914436); do_PCF ($a,0.916337); do_PCF ($a,0.918037); do_PCF ($a,0.919556); do_PCF ($a,0.920913); do_PCF ($a,0.922125); do_PCF ($a,0.923206); do_PCF ($a,0.924171); do_PCF ($a,0.925032); do_PCF ($a,0.925800); do_PCF ($a,0.926485); do_PCF ($a,0.927095); do_PCF ($a,0.927639); do_PCF ($a,0.928124);
$y = 17 ; $a=48; do_PCF ($a,0.922424); do_PCF ($a,0.924281); do_PCF ($a,0.925941); do_PCF ($a,0.927425); do_PCF ($a,0.928750); do_PCF ($a,0.929934); do_PCF ($a,0.930990); do_PCF ($a,0.931933); do_PCF ($a,0.932773); do_PCF ($a,0.933523); do_PCF ($a,0.934192); do_PCF ($a,0.934788); do_PCF ($a,0.935319); do_PCF ($a,0.935793); do_PCF ($a,0.936215); do_PCF ($a,0.936590);
$y = 17 ; $a=49; do_PCF ($a,0.932854); do_PCF ($a,0.934431); do_PCF ($a,0.935840); do_PCF ($a,0.937099); do_PCF ($a,0.938223); do_PCF ($a,0.939226); do_PCF ($a,0.940120); do_PCF ($a,0.940919); do_PCF ($a,0.941630); do_PCF ($a,0.942265); do_PCF ($a,0.942831); do_PCF ($a,0.943335); do_PCF ($a,0.943784); do_PCF ($a,0.944184); do_PCF ($a,0.944541); do_PCF ($a,0.944859); do_PCF ($a,0.945141);
$y = 17 ; $a=50; do_PCF ($a,0.943501); do_PCF ($a,0.944787); do_PCF ($a,0.945936); do_PCF ($a,0.946961); do_PCF ($a,0.947876); do_PCF ($a,0.948692); do_PCF ($a,0.949419); do_PCF ($a,0.950068); do_PCF ($a,0.950646); do_PCF ($a,0.951162); do_PCF ($a,0.951621); do_PCF ($a,0.952030); do_PCF ($a,0.952395); do_PCF ($a,0.952720); do_PCF ($a,0.953009); do_PCF ($a,0.953267); do_PCF ($a,0.953496);
$y = 17 ; $a=51; do_PCF ($a,0.954333); do_PCF ($a,0.955319); do_PCF ($a,0.956199); do_PCF ($a,0.956984); do_PCF ($a,0.957683); do_PCF ($a,0.958307); do_PCF ($a,0.958863); do_PCF ($a,0.959358); do_PCF ($a,0.959800); do_PCF ($a,0.960193); do_PCF ($a,0.960543); do_PCF ($a,0.960855); do_PCF ($a,0.961133); do_PCF ($a,0.961380); do_PCF ($a,0.961601); do_PCF ($a,0.961797); do_PCF ($a,0.961972);
$y = 17 ; $a=52; do_PCF ($a,0.965157); do_PCF ($a,0.965829); do_PCF ($a,0.966428); do_PCF ($a,0.966961); do_PCF ($a,0.967436); do_PCF ($a,0.967860); do_PCF ($a,0.968237); do_PCF ($a,0.968573); do_PCF ($a,0.968872); do_PCF ($a,0.969138); do_PCF ($a,0.969376); do_PCF ($a,0.969587); do_PCF ($a,0.969775); do_PCF ($a,0.969942); do_PCF ($a,0.970091); do_PCF ($a,0.970224); do_PCF ($a,0.970342);
$y = 17 ; $a=53; do_PCF ($a,0.975865); do_PCF ($a,0.976206); do_PCF ($a,0.976511); do_PCF ($a,0.976781); do_PCF ($a,0.977022); do_PCF ($a,0.977237); do_PCF ($a,0.977428); do_PCF ($a,0.977597); do_PCF ($a,0.977749); do_PCF ($a,0.977883); do_PCF ($a,0.978003); do_PCF ($a,0.978109); do_PCF ($a,0.978204); do_PCF ($a,0.978289); do_PCF ($a,0.978364); do_PCF ($a,0.978431); do_PCF ($a,0.978490);
$y = 17 ; $a=54; do_PCF ($a,0.986414); do_PCF ($a,0.986414); do_PCF ($a,0.986414); do_PCF ($a,0.986414); do_PCF ($a,0.986414); do_PCF ($a,0.986414); do_PCF ($a,0.986414); do_PCF ($a,0.986414); do_PCF ($a,0.986414); do_PCF ($a,0.986414); do_PCF ($a,0.986414); do_PCF ($a,0.986414); do_PCF ($a,0.986414); do_PCF ($a,0.986414); do_PCF ($a,0.986414); do_PCF ($a,0.986414); do_PCF ($a,0.986414); 
$y = 17 ; $a=55; do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); 
# PCF -- males before Age 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 or more
$sex = "male";
$before_99 = "before";
$y = 34 ; $a=50; do_PCF ($a,0.953700);
$y = 34 ; $a=51; do_PCF ($a,0.962127); do_PCF ($a,0.962266);
$y = 34 ; $a=52; do_PCF ($a,0.970447); do_PCF ($a,0.970541); do_PCF ($a,0.970624);
$y = 34 ; $a=53; do_PCF ($a,0.978543); do_PCF ($a,0.978590); do_PCF ($a,0.978632); do_PCF ($a,0.978670);
$y = 34 ; $a=54; do_PCF ($a,0.986414); do_PCF ($a,0.986414); do_PCF ($a,0.986414); do_PCF ($a,0.986414); do_PCF ($a,0.986414);
$y = 34 ; $a=55; do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000);
$y = 34 ; $a=56; do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000);
$y = 34 ; $a=57; do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000);
$y = 34 ; $a=58; do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000);
$y = 34 ; $a=59; do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000);
$y = 34 ; $a=60; do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000);
$y = 34 ; $a=61; do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000);
$y = 34 ; $a=62; do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000);
$y = 34 ; $a=63; do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000);
$y = 34 ; $a=64; do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000);
$y = 34 ; $a=65; do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); 
$y = 34 ; $a=66; do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); 
# PCF -- females before Age 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16
$sex = "female";
$before_99 = "before";
$y = 0 ; $a=18; do_PCF ($a,0.282770); do_PCF ($a,0.297185); do_PCF ($a,0.313646);
$y = 0 ; $a=19; do_PCF ($a,0.290933); do_PCF ($a,0.305700); do_PCF ($a,0.319453); do_PCF ($a,0.335380);
$y = 0 ; $a=20; do_PCF ($a,0.299995); do_PCF ($a,0.315782); do_PCF ($a,0.329870); do_PCF ($a,0.342802); do_PCF ($a,0.358068);
$y = 0 ; $a=21; do_PCF ($a,0.310906); do_PCF ($a,0.326743); do_PCF ($a,0.341909); do_PCF ($a,0.355138); do_PCF ($a,0.367082); do_PCF ($a,0.381556);
$y = 0 ; $a=22; do_PCF ($a,0.323479); do_PCF ($a,0.339449); do_PCF ($a,0.354621); do_PCF ($a,0.368977); do_PCF ($a,0.381167); do_PCF ($a,0.391961); do_PCF ($a,0.405516);
$y = 0 ; $a=23; do_PCF ($a,0.338757); do_PCF ($a,0.354609); do_PCF ($a,0.369840); do_PCF ($a,0.384105); do_PCF ($a,0.397428); do_PCF ($a,0.408366); do_PCF ($a,0.417817); do_PCF ($a,0.430304);
$y = 0 ; $a=24; do_PCF ($a,0.355378); do_PCF ($a,0.371771); do_PCF ($a,0.386804); do_PCF ($a,0.401072); do_PCF ($a,0.414229); do_PCF ($a,0.426344); do_PCF ($a,0.435875); do_PCF ($a,0.443855); do_PCF ($a,0.455182);
$y = 0 ; $a=25; do_PCF ($a,0.373555); do_PCF ($a,0.390380); do_PCF ($a,0.405949); do_PCF ($a,0.419912); do_PCF ($a,0.432995); do_PCF ($a,0.444852); do_PCF ($a,0.455596); do_PCF ($a,0.463577); do_PCF ($a,0.469969); do_PCF ($a,0.480056);
$y = 0 ; $a=26; do_PCF ($a,0.393449); do_PCF ($a,0.410510); do_PCF ($a,0.426487); do_PCF ($a,0.440966); do_PCF ($a,0.453621); do_PCF ($a,0.465315); do_PCF ($a,0.475699); do_PCF ($a,0.484928); do_PCF ($a,0.491241); do_PCF ($a,0.495952); do_PCF ($a,0.504740);
$y = 0 ; $a=27; do_PCF ($a,0.415039); do_PCF ($a,0.432219); do_PCF ($a,0.448377); do_PCF ($a,0.463233); do_PCF ($a,0.476381); do_PCF ($a,0.487516); do_PCF ($a,0.497648); do_PCF ($a,0.506418); do_PCF ($a,0.514021); do_PCF ($a,0.518579); do_PCF ($a,0.521546); do_PCF ($a,0.531869);
$y = 0 ; $a=28; do_PCF ($a,0.437007); do_PCF ($a,0.454220); do_PCF ($a,0.470474); do_PCF ($a,0.485509); do_PCF ($a,0.499061); do_PCF ($a,0.510734); do_PCF ($a,0.520244); do_PCF ($a,0.528741); do_PCF ($a,0.535855); do_PCF ($a,0.541818); do_PCF ($a,0.544630); do_PCF ($a,0.554501); do_PCF ($a,0.564125);
$y = 0 ; $a=29; do_PCF ($a,0.459738); do_PCF ($a,0.476635); do_PCF ($a,0.492888); do_PCF ($a,0.508003); do_PCF ($a,0.521737); do_PCF ($a,0.533846); do_PCF ($a,0.543939); do_PCF ($a,0.551752); do_PCF ($a,0.558572); do_PCF ($a,0.564014); do_PCF ($a,0.568343); do_PCF ($a,0.577734); do_PCF ($a,0.586875); do_PCF ($a,0.595760);
$y = 0 ; $a=30; do_PCF ($a,0.482668); do_PCF ($a,0.499247); do_PCF ($a,0.515129); do_PCF ($a,0.530246); do_PCF ($a,0.544084); do_PCF ($a,0.556418); do_PCF ($a,0.567018); do_PCF ($a,0.575496); do_PCF ($a,0.581606); do_PCF ($a,0.586766); do_PCF ($a,0.590574); do_PCF ($a,0.599526); do_PCF ($a,0.608226); do_PCF ($a,0.616670); do_PCF ($a,0.624858);
$y = 0 ; $a=31; do_PCF ($a,0.505554); do_PCF ($a,0.521731); do_PCF ($a,0.537263); do_PCF ($a,0.551990); do_PCF ($a,0.565868); do_PCF ($a,0.578361); do_PCF ($a,0.589256); do_PCF ($a,0.598338); do_PCF ($a,0.605220); do_PCF ($a,0.609666); do_PCF ($a,0.613225); do_PCF ($a,0.621724); do_PCF ($a,0.629972); do_PCF ($a,0.637965); do_PCF ($a,0.645705); do_PCF ($a,0.653192);
$y = 0 ; $a=32; do_PCF ($a,0.528737); do_PCF ($a,0.544473); do_PCF ($a,0.559560); do_PCF ($a,0.573915); do_PCF ($a,0.587389); do_PCF ($a,0.599961); do_PCF ($a,0.611070); do_PCF ($a,0.620513); do_PCF ($a,0.628088); do_PCF ($a,0.633402); do_PCF ($a,0.636233); do_PCF ($a,0.644268); do_PCF ($a,0.652053); do_PCF ($a,0.659589); do_PCF ($a,0.666875); do_PCF ($a,0.673915); do_PCF ($a,0.680711);
$y = 0 ; $a=33; do_PCF ($a,0.552554); do_PCF ($a,0.567828); do_PCF ($a,0.582416); do_PCF ($a,0.596283); do_PCF ($a,0.609364); do_PCF ($a,0.621517); do_PCF ($a,0.632742); do_PCF ($a,0.642448); do_PCF ($a,0.650443); do_PCF ($a,0.656529); do_PCF ($a,0.660311); do_PCF ($a,0.667844); do_PCF ($a,0.675133); do_PCF ($a,0.682177); do_PCF ($a,0.688981); do_PCF ($a,0.695546); do_PCF ($a,0.701876);
$y = 0 ; $a=34; do_PCF ($a,0.575931); do_PCF ($a,0.590917); do_PCF ($a,0.605002); do_PCF ($a,0.618340); do_PCF ($a,0.630917); do_PCF ($a,0.642681); do_PCF ($a,0.653497); do_PCF ($a,0.663381); do_PCF ($a,0.671710); do_PCF ($a,0.678299); do_PCF ($a,0.682956); do_PCF ($a,0.690016); do_PCF ($a,0.696838); do_PCF ($a,0.703425); do_PCF ($a,0.709778); do_PCF ($a,0.715902); do_PCF ($a,0.721800);
$y = 0 ; $a=35; do_PCF ($a,0.598934); do_PCF ($a,0.613632); do_PCF ($a,0.627414); do_PCF ($a,0.640222); do_PCF ($a,0.652251); do_PCF ($a,0.663506); do_PCF ($a,0.673944); do_PCF ($a,0.683434); do_PCF ($a,0.692004); do_PCF ($a,0.699001); do_PCF ($a,0.704241); do_PCF ($a,0.710860); do_PCF ($a,0.717249); do_PCF ($a,0.723411); do_PCF ($a,0.729348); do_PCF ($a,0.735066); do_PCF ($a,0.740568);
$y = 0 ; $a=36; do_PCF ($a,0.621733); do_PCF ($a,0.636098); do_PCF ($a,0.649578); do_PCF ($a,0.662075); do_PCF ($a,0.673552); do_PCF ($a,0.684246); do_PCF ($a,0.694171); do_PCF ($a,0.703296); do_PCF ($a,0.711488); do_PCF ($a,0.718785); do_PCF ($a,0.724501); do_PCF ($a,0.730704); do_PCF ($a,0.736683); do_PCF ($a,0.742445); do_PCF ($a,0.747992); do_PCF ($a,0.753329); do_PCF ($a,0.758460);
$y = 0 ; $a=37; do_PCF ($a,0.644406); do_PCF ($a,0.658342); do_PCF ($a,0.671473); do_PCF ($a,0.683666); do_PCF ($a,0.694838); do_PCF ($a,0.704968); do_PCF ($a,0.714327); do_PCF ($a,0.722943); do_PCF ($a,0.730787); do_PCF ($a,0.737725); do_PCF ($a,0.743804); do_PCF ($a,0.749612); do_PCF ($a,0.755207); do_PCF ($a,0.760593); do_PCF ($a,0.765774); do_PCF ($a,0.770755); do_PCF ($a,0.775540);
$y = 0 ; $a=38; do_PCF ($a,0.666776); do_PCF ($a,0.680264); do_PCF ($a,0.692959); do_PCF ($a,0.704813); do_PCF ($a,0.715698); do_PCF ($a,0.725545); do_PCF ($a,0.734346); do_PCF ($a,0.742405); do_PCF ($a,0.749757); do_PCF ($a,0.756378); do_PCF ($a,0.762126); do_PCF ($a,0.767567); do_PCF ($a,0.772804); do_PCF ($a,0.777841); do_PCF ($a,0.782683); do_PCF ($a,0.787334); do_PCF ($a,0.791800);
$y = 0 ; $a=39; do_PCF ($a,0.689057); do_PCF ($a,0.701750); do_PCF ($a,0.713988); do_PCF ($a,0.725404); do_PCF ($a,0.735965); do_PCF ($a,0.745549); do_PCF ($a,0.754093); do_PCF ($a,0.761601); do_PCF ($a,0.768408); do_PCF ($a,0.774554); do_PCF ($a,0.780015); do_PCF ($a,0.785086); do_PCF ($a,0.789964); do_PCF ($a,0.794651); do_PCF ($a,0.799153); do_PCF ($a,0.803475); do_PCF ($a,0.807622);
$y = 0 ; $a=40; do_PCF ($a,0.711132); do_PCF ($a,0.723058); do_PCF ($a,0.734466); do_PCF ($a,0.745435); do_PCF ($a,0.755574); do_PCF ($a,0.764862); do_PCF ($a,0.773179); do_PCF ($a,0.780466); do_PCF ($a,0.786740); do_PCF ($a,0.792359); do_PCF ($a,0.797370); do_PCF ($a,0.802073); do_PCF ($a,0.806593); do_PCF ($a,0.810934); do_PCF ($a,0.815100); do_PCF ($a,0.819097); do_PCF ($a,0.822929);
$y = 0 ; $a=41; do_PCF ($a,0.732994); do_PCF ($a,0.744126); do_PCF ($a,0.754749); do_PCF ($a,0.764874); do_PCF ($a,0.774590); do_PCF ($a,0.783486); do_PCF ($a,0.791548); do_PCF ($a,0.798655); do_PCF ($a,0.804755); do_PCF ($a,0.809869); do_PCF ($a,0.814381); do_PCF ($a,0.818714); do_PCF ($a,0.822875); do_PCF ($a,0.826867); do_PCF ($a,0.830696); do_PCF ($a,0.834367); do_PCF ($a,0.837885);
$y = 0 ; $a=42; do_PCF ($a,0.754264); do_PCF ($a,0.764676); do_PCF ($a,0.774505); do_PCF ($a,0.783851); do_PCF ($a,0.792732); do_PCF ($a,0.801250); do_PCF ($a,0.808967); do_PCF ($a,0.815876); do_PCF ($a,0.821854); do_PCF ($a,0.826852); do_PCF ($a,0.830895); do_PCF ($a,0.834858); do_PCF ($a,0.838659); do_PCF ($a,0.842305); do_PCF ($a,0.845799); do_PCF ($a,0.849146); do_PCF ($a,0.852351);
$y = 0 ; $a=43; do_PCF ($a,0.774915); do_PCF ($a,0.784566); do_PCF ($a,0.793691); do_PCF ($a,0.802259); do_PCF ($a,0.810382); do_PCF ($a,0.818084); do_PCF ($a,0.825477); do_PCF ($a,0.832096); do_PCF ($a,0.837938); do_PCF ($a,0.842877); do_PCF ($a,0.846863); do_PCF ($a,0.850457); do_PCF ($a,0.853902); do_PCF ($a,0.857204); do_PCF ($a,0.860365); do_PCF ($a,0.863392); do_PCF ($a,0.866289);
$y = 0 ; $a=44; do_PCF ($a,0.795248); do_PCF ($a,0.804323); do_PCF ($a,0.812682); do_PCF ($a,0.820549); do_PCF ($a,0.827896); do_PCF ($a,0.834848); do_PCF ($a,0.841432); do_PCF ($a,0.847765); do_PCF ($a,0.853356); do_PCF ($a,0.858204); do_PCF ($a,0.862179); do_PCF ($a,0.865416); do_PCF ($a,0.868517); do_PCF ($a,0.871485); do_PCF ($a,0.874327); do_PCF ($a,0.877045); do_PCF ($a,0.879645);
$y = 0 ; $a=45; do_PCF ($a,0.811371); do_PCF ($a,0.823724); do_PCF ($a,0.831522); do_PCF ($a,0.838625); do_PCF ($a,0.845283); do_PCF ($a,0.851468); do_PCF ($a,0.857314); do_PCF ($a,0.862848); do_PCF ($a,0.868195); do_PCF ($a,0.872833); do_PCF ($a,0.876764); do_PCF ($a,0.879659); do_PCF ($a,0.882430); do_PCF ($a,0.885082); do_PCF ($a,0.887618); do_PCF ($a,0.890043); do_PCF ($a,0.892360);
$y = 0 ; $a=46; do_PCF ($a,0.831004); do_PCF ($a,0.838558); do_PCF ($a,0.849995); do_PCF ($a,0.856558); do_PCF ($a,0.862459); do_PCF ($a,0.867970); do_PCF ($a,0.873059); do_PCF ($a,0.877870); do_PCF ($a,0.882430); do_PCF ($a,0.886866); do_PCF ($a,0.890628); do_PCF ($a,0.893197); do_PCF ($a,0.895653); do_PCF ($a,0.898002); do_PCF ($a,0.900247); do_PCF ($a,0.902392); do_PCF ($a,0.904441);
$y = 0 ; $a=47; do_PCF ($a,0.850286); do_PCF ($a,0.857018); do_PCF ($a,0.863339); do_PCF ($a,0.873922); do_PCF ($a,0.879321); do_PCF ($a,0.884098); do_PCF ($a,0.888542); do_PCF ($a,0.892621); do_PCF ($a,0.896483); do_PCF ($a,0.900154); do_PCF ($a,0.903765); do_PCF ($a,0.906022); do_PCF ($a,0.908178); do_PCF ($a,0.910239); do_PCF ($a,0.912208); do_PCF ($a,0.914087); do_PCF ($a,0.915882);
$y = 0 ; $a=48; do_PCF ($a,0.869333); do_PCF ($a,0.875216); do_PCF ($a,0.880726); do_PCF ($a,0.885879); do_PCF ($a,0.895676); do_PCF ($a,0.899987); do_PCF ($a,0.903718); do_PCF ($a,0.907178); do_PCF ($a,0.910328); do_PCF ($a,0.913325); do_PCF ($a,0.916188); do_PCF ($a,0.918147); do_PCF ($a,0.920018); do_PCF ($a,0.921805); do_PCF ($a,0.923510); do_PCF ($a,0.925137); do_PCF ($a,0.926690);
$y = 0 ; $a=49; do_PCF ($a,0.888164); do_PCF ($a,0.893182); do_PCF ($a,0.897868); do_PCF ($a,0.902239); do_PCF ($a,0.906310); do_PCF ($a,0.915414); do_PCF ($a,0.918729); do_PCF ($a,0.921509); do_PCF ($a,0.924077); do_PCF ($a,0.926391); do_PCF ($a,0.928611); do_PCF ($a,0.930264); do_PCF ($a,0.931841); do_PCF ($a,0.933346); do_PCF ($a,0.934781); do_PCF ($a,0.936150); do_PCF ($a,0.937455);
$y = 0 ; $a=50; do_PCF ($a,0.907003); do_PCF ($a,0.911118); do_PCF ($a,0.914948); do_PCF ($a,0.918510); do_PCF ($a,0.921819); do_PCF ($a,0.924892); do_PCF ($a,0.933387); do_PCF ($a,0.935790); do_PCF ($a,0.937700); do_PCF ($a,0.939459); do_PCF ($a,0.941017); do_PCF ($a,0.942353); do_PCF ($a,0.943627); do_PCF ($a,0.944841); do_PCF ($a,0.945997); do_PCF ($a,0.947100); do_PCF ($a,0.948150);
$y = 0 ; $a=51; do_PCF ($a,0.925567); do_PCF ($a,0.928751); do_PCF ($a,0.931705); do_PCF ($a,0.934444); do_PCF ($a,0.936981); do_PCF ($a,0.939330); do_PCF ($a,0.941504); do_PCF ($a,0.949490); do_PCF ($a,0.951078); do_PCF ($a,0.952214); do_PCF ($a,0.953254); do_PCF ($a,0.954266); do_PCF ($a,0.955230); do_PCF ($a,0.956148); do_PCF ($a,0.957021); do_PCF ($a,0.957853); do_PCF ($a,0.958645);
$y = 0 ; $a=52; do_PCF ($a,0.944207); do_PCF ($a,0.946398); do_PCF ($a,0.948424); do_PCF ($a,0.950294); do_PCF ($a,0.952022); do_PCF ($a,0.953617); do_PCF ($a,0.955089); do_PCF ($a,0.956446); do_PCF ($a,0.964011); do_PCF ($a,0.964862); do_PCF ($a,0.965300); do_PCF ($a,0.965978); do_PCF ($a,0.966624); do_PCF ($a,0.967238); do_PCF ($a,0.967822); do_PCF ($a,0.968378); do_PCF ($a,0.968906);
$y = 0 ; $a=53; do_PCF ($a,0.962674); do_PCF ($a,0.963815); do_PCF ($a,0.964866); do_PCF ($a,0.965832); do_PCF ($a,0.966721); do_PCF ($a,0.967539); do_PCF ($a,0.968291); do_PCF ($a,0.968984); do_PCF ($a,0.969621); do_PCF ($a,0.976858); do_PCF ($a,0.977060); do_PCF ($a,0.977397); do_PCF ($a,0.977717); do_PCF ($a,0.978021); do_PCF ($a,0.978310); do_PCF ($a,0.978584); do_PCF ($a,0.978845);
$y = 0 ; $a=54; do_PCF ($a,0.981773); do_PCF ($a,0.981773); do_PCF ($a,0.981773); do_PCF ($a,0.981773); do_PCF ($a,0.981773); do_PCF ($a,0.981773); do_PCF ($a,0.981773); do_PCF ($a,0.981773); do_PCF ($a,0.981773); do_PCF ($a,0.981773); do_PCF ($a,0.988791); do_PCF ($a,0.988791); do_PCF ($a,0.988791); do_PCF ($a,0.988791); do_PCF ($a,0.988791); do_PCF ($a,0.988791); do_PCF ($a,0.988791); 
$y = 0 ; $a=55; do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); 
# PCF -- females before Age 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33
$sex = "female";
$before_99 = "before";
$y = 17 ; $a=33; do_PCF ($a,0.707974);
$y = 17 ; $a=34; do_PCF ($a,0.727478); do_PCF ($a,0.732939);
$y = 17 ; $a=35; do_PCF ($a,0.745859); do_PCF ($a,0.750945); do_PCF ($a,0.755830);
$y = 17 ; $a=36; do_PCF ($a,0.763391); do_PCF ($a,0.768127); do_PCF ($a,0.772673); do_PCF ($a,0.777034);
$y = 17 ; $a=37; do_PCF ($a,0.780135); do_PCF ($a,0.784546); do_PCF ($a,0.788776); do_PCF ($a,0.792832); do_PCF ($a,0.796719);
$y = 17 ; $a=38; do_PCF ($a,0.796085); do_PCF ($a,0.800195); do_PCF ($a,0.804136); do_PCF ($a,0.807912); do_PCF ($a,0.811528); do_PCF ($a,0.814991);
$y = 17 ; $a=39; do_PCF ($a,0.811599); do_PCF ($a,0.815411); do_PCF ($a,0.819063); do_PCF ($a,0.822561); do_PCF ($a,0.825909); do_PCF ($a,0.829114); do_PCF ($a,0.832179);
$y = 17 ; $a=40; do_PCF ($a,0.826602); do_PCF ($a,0.830120); do_PCF ($a,0.833490); do_PCF ($a,0.836715); do_PCF ($a,0.839800); do_PCF ($a,0.842752); do_PCF ($a,0.845574); do_PCF ($a,0.848271);
$y = 17 ; $a=41; do_PCF ($a,0.841254); do_PCF ($a,0.844480); do_PCF ($a,0.847567); do_PCF ($a,0.850521); do_PCF ($a,0.853346); do_PCF ($a,0.856046); do_PCF ($a,0.858627); do_PCF ($a,0.861093); do_PCF ($a,0.863448);
$y = 17 ; $a=42; do_PCF ($a,0.855419); do_PCF ($a,0.858355); do_PCF ($a,0.861163); do_PCF ($a,0.863848); do_PCF ($a,0.866415); do_PCF ($a,0.868868); do_PCF ($a,0.871211); do_PCF ($a,0.873449); do_PCF ($a,0.875585); do_PCF ($a,0.877625);
$y = 17 ; $a=43; do_PCF ($a,0.869060); do_PCF ($a,0.871710); do_PCF ($a,0.874244); do_PCF ($a,0.876665); do_PCF ($a,0.878978); do_PCF ($a,0.881188); do_PCF ($a,0.883298); do_PCF ($a,0.885312); do_PCF ($a,0.887234); do_PCF ($a,0.889068); do_PCF ($a,0.890818);
$y = 17 ; $a=44; do_PCF ($a,0.882131); do_PCF ($a,0.884507); do_PCF ($a,0.886777); do_PCF ($a,0.888946); do_PCF ($a,0.891017); do_PCF ($a,0.892994); do_PCF ($a,0.894881); do_PCF ($a,0.896681); do_PCF ($a,0.898399); do_PCF ($a,0.900038); do_PCF ($a,0.901600); do_PCF ($a,0.903090);
$y = 17 ; $a=45; do_PCF ($a,0.894575); do_PCF ($a,0.896691); do_PCF ($a,0.898711); do_PCF ($a,0.900640); do_PCF ($a,0.902481); do_PCF ($a,0.904238); do_PCF ($a,0.905914); do_PCF ($a,0.907513); do_PCF ($a,0.909038); do_PCF ($a,0.910492); do_PCF ($a,0.911878); do_PCF ($a,0.913199); do_PCF ($a,0.914458);
$y = 17 ; $a=46; do_PCF ($a,0.906398); do_PCF ($a,0.908267); do_PCF ($a,0.910050); do_PCF ($a,0.911752); do_PCF ($a,0.913376); do_PCF ($a,0.914924); do_PCF ($a,0.916401); do_PCF ($a,0.917810); do_PCF ($a,0.919152); do_PCF ($a,0.920432); do_PCF ($a,0.921651); do_PCF ($a,0.922813); do_PCF ($a,0.923920); do_PCF ($a,0.924974);
$y = 17 ; $a=47; do_PCF ($a,0.917594); do_PCF ($a,0.919229); do_PCF ($a,0.920788); do_PCF ($a,0.922275); do_PCF ($a,0.923693); do_PCF ($a,0.925045); do_PCF ($a,0.926334); do_PCF ($a,0.927562); do_PCF ($a,0.928733); do_PCF ($a,0.929848); do_PCF ($a,0.930911); do_PCF ($a,0.931923); do_PCF ($a,0.932887); do_PCF ($a,0.933805); do_PCF ($a,0.934679);
$y = 17 ; $a=48; do_PCF ($a,0.928171); do_PCF ($a,0.929583); do_PCF ($a,0.930930); do_PCF ($a,0.932214); do_PCF ($a,0.933438); do_PCF ($a,0.934604); do_PCF ($a,0.935715); do_PCF ($a,0.936774); do_PCF ($a,0.937782); do_PCF ($a,0.938742); do_PCF ($a,0.939657); do_PCF ($a,0.940528); do_PCF ($a,0.941357); do_PCF ($a,0.942146); do_PCF ($a,0.942898); do_PCF ($a,0.943613);
$y = 17 ; $a=49; do_PCF ($a,0.938699); do_PCF ($a,0.939884); do_PCF ($a,0.941014); do_PCF ($a,0.942090); do_PCF ($a,0.943116); do_PCF ($a,0.944093); do_PCF ($a,0.945023); do_PCF ($a,0.945909); do_PCF ($a,0.946752); do_PCF ($a,0.947555); do_PCF ($a,0.948319); do_PCF ($a,0.949047); do_PCF ($a,0.949739); do_PCF ($a,0.950398); do_PCF ($a,0.951026); do_PCF ($a,0.951622); do_PCF ($a,0.952190);
$y = 17 ; $a=50; do_PCF ($a,0.949150); do_PCF ($a,0.950103); do_PCF ($a,0.951010); do_PCF ($a,0.951874); do_PCF ($a,0.952696); do_PCF ($a,0.953479); do_PCF ($a,0.954225); do_PCF ($a,0.954934); do_PCF ($a,0.955609); do_PCF ($a,0.956252); do_PCF ($a,0.956863); do_PCF ($a,0.957444); do_PCF ($a,0.957998); do_PCF ($a,0.958524); do_PCF ($a,0.959025); do_PCF ($a,0.959501); do_PCF ($a,0.959954);
$y = 17 ; $a=51; do_PCF ($a,0.959398); do_PCF ($a,0.960115); do_PCF ($a,0.960798); do_PCF ($a,0.961447); do_PCF ($a,0.962065); do_PCF ($a,0.962653); do_PCF ($a,0.963212); do_PCF ($a,0.963744); do_PCF ($a,0.964250); do_PCF ($a,0.964731); do_PCF ($a,0.965189); do_PCF ($a,0.965624); do_PCF ($a,0.966038); do_PCF ($a,0.966432); do_PCF ($a,0.966806); do_PCF ($a,0.967162); do_PCF ($a,0.967500);
$y = 17 ; $a=52; do_PCF ($a,0.969408); do_PCF ($a,0.969886); do_PCF ($a,0.970340); do_PCF ($a,0.970772); do_PCF ($a,0.971182); do_PCF ($a,0.971573); do_PCF ($a,0.971944); do_PCF ($a,0.972297); do_PCF ($a,0.972632); do_PCF ($a,0.972951); do_PCF ($a,0.973254); do_PCF ($a,0.973542); do_PCF ($a,0.973816); do_PCF ($a,0.974076); do_PCF ($a,0.974323); do_PCF ($a,0.974558); do_PCF ($a,0.974782);
$y = 17 ; $a=53; do_PCF ($a,0.979093); do_PCF ($a,0.979328); do_PCF ($a,0.979551); do_PCF ($a,0.979764); do_PCF ($a,0.979965); do_PCF ($a,0.980157); do_PCF ($a,0.980339); do_PCF ($a,0.980512); do_PCF ($a,0.980676); do_PCF ($a,0.980832); do_PCF ($a,0.980980); do_PCF ($a,0.981121); do_PCF ($a,0.981255); do_PCF ($a,0.981382); do_PCF ($a,0.981503); do_PCF ($a,0.981617); do_PCF ($a,0.981726);
$y = 17 ; $a=54; do_PCF ($a,0.988791); do_PCF ($a,0.988791); do_PCF ($a,0.988791); do_PCF ($a,0.988791); do_PCF ($a,0.988791); do_PCF ($a,0.988791); do_PCF ($a,0.988791); do_PCF ($a,0.988791); do_PCF ($a,0.988791); do_PCF ($a,0.988791); do_PCF ($a,0.988791); do_PCF ($a,0.988791); do_PCF ($a,0.988791); do_PCF ($a,0.988791); do_PCF ($a,0.988791); do_PCF ($a,0.988791); do_PCF ($a,0.988791); 
$y = 17 ; $a=55; do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); 
# PCF -- females before Age 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 or more
$sex = "female";
$before_99 = "before";
$y = 34 ; $a=50; do_PCF ($a,0.960385);
$y = 34 ; $a=51; do_PCF ($a,0.967822); do_PCF ($a,0.968128);
$y = 34 ; $a=52; do_PCF ($a,0.974994); do_PCF ($a,0.975196); do_PCF ($a,0.975388);
$y = 34 ; $a=53; do_PCF ($a,0.981830); do_PCF ($a,0.981928); do_PCF ($a,0.982022); do_PCF ($a,0.982110);
$y = 34 ; $a=54; do_PCF ($a,0.988791); do_PCF ($a,0.988791); do_PCF ($a,0.988791); do_PCF ($a,0.988791); do_PCF ($a,0.988791);
$y = 34 ; $a=55; do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000);
$y = 34 ; $a=56; do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000);
$y = 34 ; $a=57; do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000);
$y = 34 ; $a=58; do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000);
$y = 34 ; $a=59; do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000);
$y = 34 ; $a=60; do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000);
$y = 34 ; $a=61; do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000);
$y = 34 ; $a=62; do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000);
$y = 34 ; $a=63; do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000);
$y = 34 ; $a=64; do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000);
$y = 34 ; $a=65; do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); 
$y = 34 ; $a=66; do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); 
# ABF -- males before Age 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16
$sex = "male";
$before_99 = "before";
$y = 0; $a=18; do_ABF ($a,0.320730); do_ABF ($a,0.328158); do_ABF ($a,0.334754);
$y = 0 ; $a=19; do_ABF ($a,0.329830); do_ABF ($a,0.337402); do_ABF ($a,0.344301); do_ABF ($a,0.350301);
$y = 0 ; $a=20; do_ABF ($a,0.339713); do_ABF ($a,0.347384); do_ABF ($a,0.354395); do_ABF ($a,0.360678); do_ABF ($a,0.366020);
$y = 0 ; $a=21; do_ABF ($a,0.350397); do_ABF ($a,0.358175); do_ABF ($a,0.365244); do_ABF ($a,0.371597); do_ABF ($a,0.377196); do_ABF ($a,0.381835);
$y = 0 ; $a=22; do_ABF ($a,0.361847); do_ABF ($a,0.369745); do_ABF ($a,0.376885); do_ABF ($a,0.383252); do_ABF ($a,0.388879); do_ABF ($a,0.393753); do_ABF ($a,0.397670);
$y = 0 ; $a=23; do_ABF ($a,0.374620); do_ABF ($a,0.382539); do_ABF ($a,0.389719); do_ABF ($a,0.396070); do_ABF ($a,0.401624); do_ABF ($a,0.406447); do_ABF ($a,0.410543); do_ABF ($a,0.413704);
$y = 0 ; $a=24; do_ABF ($a,0.388085); do_ABF ($a,0.396057); do_ABF ($a,0.403211); do_ABF ($a,0.409565); do_ABF ($a,0.415063); do_ABF ($a,0.419772); do_ABF ($a,0.423786); do_ABF ($a,0.427118); do_ABF ($a,0.429549);
$y = 0 ; $a=25; do_ABF ($a,0.402197); do_ABF ($a,0.410180); do_ABF ($a,0.417349); do_ABF ($a,0.423634); do_ABF ($a,0.429103); do_ABF ($a,0.433725); do_ABF ($a,0.437593); do_ABF ($a,0.440819); do_ABF ($a,0.443421); do_ABF ($a,0.445164);
$y = 0 ; $a=26; do_ABF ($a,0.417017); do_ABF ($a,0.424951); do_ABF ($a,0.432089); do_ABF ($a,0.438357); do_ABF ($a,0.443722); do_ABF ($a,0.448290); do_ABF ($a,0.452045); do_ABF ($a,0.455099); do_ABF ($a,0.457578); do_ABF ($a,0.459496); do_ABF ($a,0.460600);
$y = 0 ; $a=27; do_ABF ($a,0.432434); do_ABF ($a,0.440348); do_ABF ($a,0.447396); do_ABF ($a,0.453604); do_ABF ($a,0.458933); do_ABF ($a,0.463375); do_ABF ($a,0.467063); do_ABF ($a,0.469991); do_ABF ($a,0.472281); do_ABF ($a,0.474066); do_ABF ($a,0.475357); do_ABF ($a,0.480943);
$y = 0 ; $a=28; do_ABF ($a,0.448321); do_ABF ($a,0.456162); do_ABF ($a,0.463173); do_ABF ($a,0.469276); do_ABF ($a,0.474541); do_ABF ($a,0.478948); do_ABF ($a,0.482508); do_ABF ($a,0.485373); do_ABF ($a,0.487537); do_ABF ($a,0.489131); do_ABF ($a,0.490291); do_ABF ($a,0.495792); do_ABF ($a,0.500865);
$y = 0 ; $a=29; do_ABF ($a,0.464708); do_ABF ($a,0.472519); do_ABF ($a,0.479431); do_ABF ($a,0.485485); do_ABF ($a,0.490630); do_ABF ($a,0.494970); do_ABF ($a,0.498497); do_ABF ($a,0.501227); do_ABF ($a,0.503332); do_ABF ($a,0.504797); do_ABF ($a,0.505761); do_ABF ($a,0.511169); do_ABF ($a,0.516151); do_ABF ($a,0.520722);
$y = 0 ; $a=30; do_ABF ($a,0.481576); do_ABF ($a,0.489304); do_ABF ($a,0.496176); do_ABF ($a,0.502120); do_ABF ($a,0.507218); do_ABF ($a,0.511437); do_ABF ($a,0.514902); do_ABF ($a,0.517609); do_ABF ($a,0.519580); do_ABF ($a,0.520994); do_ABF ($a,0.521831); do_ABF ($a,0.527135); do_ABF ($a,0.532014); do_ABF ($a,0.536487); do_ABF ($a,0.540574);
$y = 0 ; $a=31; do_ABF ($a,0.499025); do_ABF ($a,0.506651); do_ABF ($a,0.513416); do_ABF ($a,0.519312); do_ABF ($a,0.524288); do_ABF ($a,0.528458); do_ABF ($a,0.531796); do_ABF ($a,0.534444); do_ABF ($a,0.536398); do_ABF ($a,0.537675); do_ABF ($a,0.538464); do_ABF ($a,0.543654); do_ABF ($a,0.548423); do_ABF ($a,0.552790); do_ABF ($a,0.556776); do_ABF ($a,0.560405);
$y = 0 ; $a=32; do_ABF ($a,0.517177); do_ABF ($a,0.524645); do_ABF ($a,0.531280); do_ABF ($a,0.537049); do_ABF ($a,0.541970); do_ABF ($a,0.546007); do_ABF ($a,0.549297); do_ABF ($a,0.551813); do_ABF ($a,0.553708); do_ABF ($a,0.554973); do_ABF ($a,0.555621); do_ABF ($a,0.560693); do_ABF ($a,0.565349); do_ABF ($a,0.569608); do_ABF ($a,0.573492); do_ABF ($a,0.577024); do_ABF ($a,0.580229);
$y = 0 ; $a=33; do_ABF ($a,0.536139); do_ABF ($a,0.543460); do_ABF ($a,0.549891); do_ABF ($a,0.555498); do_ABF ($a,0.560269); do_ABF ($a,0.564242); do_ABF ($a,0.567385); do_ABF ($a,0.569849); do_ABF ($a,0.571602); do_ABF ($a,0.572806); do_ABF ($a,0.573442); do_ABF ($a,0.578382); do_ABF ($a,0.582911); do_ABF ($a,0.587049); do_ABF ($a,0.590820); do_ABF ($a,0.594246); do_ABF ($a,0.597353);
$y = 0 ; $a=34; do_ABF ($a,0.555524); do_ABF ($a,0.562826); do_ABF ($a,0.569086); do_ABF ($a,0.574468); do_ABF ($a,0.579069); do_ABF ($a,0.582890); do_ABF ($a,0.585976); do_ABF ($a,0.588295); do_ABF ($a,0.590006); do_ABF ($a,0.591070); do_ABF ($a,0.591653); do_ABF ($a,0.596461); do_ABF ($a,0.600864); do_ABF ($a,0.604883); do_ABF ($a,0.608542); do_ABF ($a,0.611864); do_ABF ($a,0.614874);
$y = 0 ; $a=35; do_ABF ($a,0.575379); do_ABF ($a,0.582652); do_ABF ($a,0.588886); do_ABF ($a,0.594078); do_ABF ($a,0.598437); do_ABF ($a,0.602082); do_ABF ($a,0.605015); do_ABF ($a,0.607285); do_ABF ($a,0.608852); do_ABF ($a,0.609883); do_ABF ($a,0.610327); do_ABF ($a,0.614999); do_ABF ($a,0.619273); do_ABF ($a,0.623170); do_ABF ($a,0.626714); do_ABF ($a,0.629930); do_ABF ($a,0.632841);
$y = 0 ; $a=36; do_ABF ($a,0.595598); do_ABF ($a,0.602831); do_ABF ($a,0.609042); do_ABF ($a,0.614219); do_ABF ($a,0.618384); do_ABF ($a,0.621782); do_ABF ($a,0.624542); do_ABF ($a,0.626665); do_ABF ($a,0.628197); do_ABF ($a,0.629090); do_ABF ($a,0.629513); do_ABF ($a,0.634039); do_ABF ($a,0.638174); do_ABF ($a,0.641941); do_ABF ($a,0.645364); do_ABF ($a,0.648467); do_ABF ($a,0.651275);
$y = 0 ; $a=37; do_ABF ($a,0.616287); do_ABF ($a,0.623425); do_ABF ($a,0.629599); do_ABF ($a,0.634762); do_ABF ($a,0.638924); do_ABF ($a,0.642122); do_ABF ($a,0.644628); do_ABF ($a,0.646579); do_ABF ($a,0.647968); do_ABF ($a,0.648837); do_ABF ($a,0.649125); do_ABF ($a,0.653504); do_ABF ($a,0.657501); do_ABF ($a,0.661138); do_ABF ($a,0.664440); do_ABF ($a,0.667431); do_ABF ($a,0.670135);
$y = 0 ; $a=38; do_ABF ($a,0.637443); do_ABF ($a,0.644479); do_ABF ($a,0.650556); do_ABF ($a,0.655692); do_ABF ($a,0.659853); do_ABF ($a,0.663062); do_ABF ($a,0.665365); do_ABF ($a,0.667056); do_ABF ($a,0.668275); do_ABF ($a,0.669004); do_ABF ($a,0.669280); do_ABF ($a,0.673500); do_ABF ($a,0.677347); do_ABF ($a,0.680845); do_ABF ($a,0.684017); do_ABF ($a,0.686889); do_ABF ($a,0.689483);
$y = 0 ; $a=39; do_ABF ($a,0.659331); do_ABF ($a,0.666090); do_ABF ($a,0.672062); do_ABF ($a,0.677103); do_ABF ($a,0.681249); do_ABF ($a,0.684472); do_ABF ($a,0.686802); do_ABF ($a,0.688287); do_ABF ($a,0.689239); do_ABF ($a,0.689799); do_ABF ($a,0.689936); do_ABF ($a,0.693996); do_ABF ($a,0.697693); do_ABF ($a,0.701050); do_ABF ($a,0.704093); do_ABF ($a,0.706844); do_ABF ($a,0.709328);
$y = 0 ; $a=40; do_ABF ($a,0.682002); do_ABF ($a,0.688473); do_ABF ($a,0.694142); do_ABF ($a,0.699078); do_ABF ($a,0.703134); do_ABF ($a,0.706355); do_ABF ($a,0.708714); do_ABF ($a,0.710240); do_ABF ($a,0.710982); do_ABF ($a,0.711267); do_ABF ($a,0.711234); do_ABF ($a,0.715119); do_ABF ($a,0.718652); do_ABF ($a,0.721857); do_ABF ($a,0.724759); do_ABF ($a,0.727381); do_ABF ($a,0.729746);
$y = 0 ; $a=41; do_ABF ($a,0.704416); do_ABF ($a,0.710584); do_ABF ($a,0.715926); do_ABF ($a,0.720529); do_ABF ($a,0.724478); do_ABF ($a,0.727610); do_ABF ($a,0.729977); do_ABF ($a,0.731545); do_ABF ($a,0.732343); do_ABF ($a,0.732415); do_ABF ($a,0.732101); do_ABF ($a,0.735781); do_ABF ($a,0.739123); do_ABF ($a,0.742152); do_ABF ($a,0.744891); do_ABF ($a,0.747363); do_ABF ($a,0.749592);
$y = 0 ; $a=42; do_ABF ($a,0.727547); do_ABF ($a,0.733344); do_ABF ($a,0.738368); do_ABF ($a,0.742635); do_ABF ($a,0.746243); do_ABF ($a,0.749285); do_ABF ($a,0.751580); do_ABF ($a,0.753180); do_ABF ($a,0.754042); do_ABF ($a,0.754189); do_ABF ($a,0.753664); do_ABF ($a,0.757109); do_ABF ($a,0.760234); do_ABF ($a,0.763063); do_ABF ($a,0.765618); do_ABF ($a,0.767922); do_ABF ($a,0.769997);
$y = 0 ; $a=43; do_ABF ($a,0.751367); do_ABF ($a,0.756779); do_ABF ($a,0.761419); do_ABF ($a,0.765365); do_ABF ($a,0.768637); do_ABF ($a,0.771341); do_ABF ($a,0.773568); do_ABF ($a,0.775117); do_ABF ($a,0.776036); do_ABF ($a,0.776273); do_ABF ($a,0.775845); do_ABF ($a,0.779033); do_ABF ($a,0.781920); do_ABF ($a,0.784530); do_ABF ($a,0.786885); do_ABF ($a,0.789006); do_ABF ($a,0.790916);
$y = 0 ; $a=44; do_ABF ($a,0.775792); do_ABF ($a,0.780837); do_ABF ($a,0.785085); do_ABF ($a,0.788647); do_ABF ($a,0.791609); do_ABF ($a,0.793984); do_ABF ($a,0.795881); do_ABF ($a,0.797389); do_ABF ($a,0.798282); do_ABF ($a,0.798604); do_ABF ($a,0.798292); do_ABF ($a,0.801232); do_ABF ($a,0.803891); do_ABF ($a,0.806291); do_ABF ($a,0.808455); do_ABF ($a,0.810402); do_ABF ($a,0.812153);
$y = 0 ; $a=45; do_ABF ($a,0.797871); do_ABF ($a,0.805531); do_ABF ($a,0.809407); do_ABF ($a,0.812574); do_ABF ($a,0.815151); do_ABF ($a,0.817224); do_ABF ($a,0.818799); do_ABF ($a,0.819983); do_ABF ($a,0.820859); do_ABF ($a,0.821177); do_ABF ($a,0.820975); do_ABF ($a,0.823678); do_ABF ($a,0.826120); do_ABF ($a,0.828322); do_ABF ($a,0.830305); do_ABF ($a,0.832089); do_ABF ($a,0.833691);
$y = 0 ; $a=46; do_ABF ($a,0.822091); do_ABF ($a,0.827504); do_ABF ($a,0.834342); do_ABF ($a,0.837137); do_ABF ($a,0.839319); do_ABF ($a,0.841011); do_ABF ($a,0.842292); do_ABF ($a,0.843161); do_ABF ($a,0.843718); do_ABF ($a,0.844043); do_ABF ($a,0.843858); do_ABF ($a,0.846338); do_ABF ($a,0.848575); do_ABF ($a,0.850591); do_ABF ($a,0.852404); do_ABF ($a,0.854033); do_ABF ($a,0.855495);
$y = 0 ; $a=47; do_ABF ($a,0.846825); do_ABF ($a,0.851798); do_ABF ($a,0.856201); do_ABF ($a,0.862306); do_ABF ($a,0.864119); do_ABF ($a,0.865418); do_ABF ($a,0.866321); do_ABF ($a,0.866905); do_ABF ($a,0.867152); do_ABF ($a,0.867161); do_ABF ($a,0.867004); do_ABF ($a,0.869265); do_ABF ($a,0.871303); do_ABF ($a,0.873137); do_ABF ($a,0.874784); do_ABF ($a,0.876264); do_ABF ($a,0.877590);
$y = 0 ; $a=48; do_ABF ($a,0.872094); do_ABF ($a,0.876591); do_ABF ($a,0.880560); do_ABF ($a,0.884050); do_ABF ($a,0.889521); do_ABF ($a,0.890454); do_ABF ($a,0.890965); do_ABF ($a,0.891172); do_ABF ($a,0.891142); do_ABF ($a,0.890844); do_ABF ($a,0.890373); do_ABF ($a,0.892423); do_ABF ($a,0.894267); do_ABF ($a,0.895925); do_ABF ($a,0.897413); do_ABF ($a,0.898747); do_ABF ($a,0.899943);
$y = 0 ; $a=49; do_ABF ($a,0.898149); do_ABF ($a,0.902132); do_ABF ($a,0.905635); do_ABF ($a,0.908705); do_ABF ($a,0.911388); do_ABF ($a,0.916334); do_ABF ($a,0.916485); do_ABF ($a,0.916302); do_ABF ($a,0.915895); do_ABF ($a,0.915326); do_ABF ($a,0.914550); do_ABF ($a,0.916360); do_ABF ($a,0.917987); do_ABF ($a,0.919446); do_ABF ($a,0.920755); do_ABF ($a,0.921927); do_ABF ($a,0.922977);
$y = 0 ; $a=50; do_ABF ($a,0.925107); do_ABF ($a,0.928523); do_ABF ($a,0.931513); do_ABF ($a,0.934124); do_ABF ($a,0.936400); do_ABF ($a,0.938378); do_ABF ($a,0.942900); do_ABF ($a,0.942357); do_ABF ($a,0.941557); do_ABF ($a,0.940609); do_ABF ($a,0.939562); do_ABF ($a,0.941102); do_ABF ($a,0.942484); do_ABF ($a,0.943721); do_ABF ($a,0.944829); do_ABF ($a,0.945820); do_ABF ($a,0.946707);
$y = 0 ; $a=51; do_ABF ($a,0.949959); do_ABF ($a,0.952702); do_ABF ($a,0.955091); do_ABF ($a,0.957169); do_ABF ($a,0.958972); do_ABF ($a,0.960535); do_ABF ($a,0.961889); do_ABF ($a,0.966034); do_ABF ($a,0.964884); do_ABF ($a,0.963549); do_ABF ($a,0.962129); do_ABF ($a,0.963355); do_ABF ($a,0.964452); do_ABF ($a,0.965433); do_ABF ($a,0.966310); do_ABF ($a,0.967094); do_ABF ($a,0.967793);
$y = 0 ; $a=52; do_ABF ($a,0.975617); do_ABF ($a,0.977600); do_ABF ($a,0.979318); do_ABF ($a,0.980804); do_ABF ($a,0.982088); do_ABF ($a,0.983197); do_ABF ($a,0.984155); do_ABF ($a,0.984981); do_ABF ($a,0.988840); do_ABF ($a,0.987161); do_ABF ($a,0.985356); do_ABF ($a,0.986225); do_ABF ($a,0.987002); do_ABF ($a,0.987695); do_ABF ($a,0.988313); do_ABF ($a,0.988864); do_ABF ($a,0.989355);
$y = 0 ; $a=53; do_ABF ($a,1.002345); do_ABF ($a,1.003434); do_ABF ($a,1.004371); do_ABF ($a,1.005177); do_ABF ($a,1.005870); do_ABF ($a,1.006466); do_ABF ($a,1.006978); do_ABF ($a,1.007419); do_ABF ($a,1.007798); do_ABF ($a,1.011448); do_ABF ($a,1.009299); do_ABF ($a,1.009762); do_ABF ($a,1.010173); do_ABF ($a,1.010539); do_ABF ($a,1.010865); do_ABF ($a,1.011155); do_ABF ($a,1.011413);
$y = 0 ; $a=54; do_ABF ($a,1.030546); do_ABF ($a,1.030546); do_ABF ($a,1.030546); do_ABF ($a,1.030546); do_ABF ($a,1.030546); do_ABF ($a,1.030546); do_ABF ($a,1.030546); do_ABF ($a,1.030546); do_ABF ($a,1.030546); do_ABF ($a,1.030546); do_ABF ($a,1.034057); do_ABF ($a,1.034057); do_ABF ($a,1.034057); do_ABF ($a,1.034057); do_ABF ($a,1.034057); do_ABF ($a,1.034057); do_ABF ($a,1.034057);
$y = 0 ; $a=55; do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139);
$y = 0 ; $a=56; do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015);
$y = 0 ; $a=57; do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805);
$y = 0 ; $a=58; do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755);
$y = 0 ; $a=59; do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734);
$y = 0 ; $a=60; do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223);
$y = 0 ; $a=61; do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930);
$y = 0 ; $a=62; do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972);
$y = 0 ; $a=63; do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116);
$y = 0 ; $a=64; do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312);
$y = 0 ; $a=65; do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050);
$y = 0 ; $a=66; do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613);
$y = 0 ; $a=67; do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527);
$y = 0 ; $a=68; do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763);
$y = 0 ; $a=69; do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384);
$y = 0 ; $a=70; do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384);
$y = 0 ; $a=71; do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750);
$y = 0 ; $a=72; do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476);
$y = 0 ; $a=73; do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534);
$y = 0 ; $a=74; do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); 
$y = 0 ; $a=75; do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); 
# ABF -- males before Age 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33
$sex = "male";
$before_99 = "before";
$y = 17 ; $a=33; do_ABF ($a,0.600164);
$y = 17 ; $a=34; do_ABF ($a,0.617595); do_ABF ($a,0.620052);
$y = 17 ; $a=35; do_ABF ($a,0.635472); do_ABF ($a,0.637846); do_ABF ($a,0.639984);
$y = 17 ; $a=36; do_ABF ($a,0.653810); do_ABF ($a,0.656096); do_ABF ($a,0.658154); do_ABF ($a,0.660005);
$y = 17 ; $a=37; do_ABF ($a,0.672575); do_ABF ($a,0.674775); do_ABF ($a,0.676754); do_ABF ($a,0.678532); do_ABF ($a,0.680129);
$y = 17 ; $a=38; do_ABF ($a,0.691822); do_ABF ($a,0.693929); do_ABF ($a,0.695825); do_ABF ($a,0.697527); do_ABF ($a,0.699055); do_ABF ($a,0.700425);
$y = 17 ; $a=39; do_ABF ($a,0.711567); do_ABF ($a,0.713582); do_ABF ($a,0.715393); do_ABF ($a,0.717020); do_ABF ($a,0.718479); do_ABF ($a,0.719787); do_ABF ($a,0.720958);
$y = 17 ; $a=40; do_ABF ($a,0.731876); do_ABF ($a,0.733793); do_ABF ($a,0.735514); do_ABF ($a,0.737060); do_ABF ($a,0.738445); do_ABF ($a,0.739687); do_ABF ($a,0.740799); do_ABF ($a,0.741793);
$y = 17 ; $a=41; do_ABF ($a,0.751598); do_ABF ($a,0.753401); do_ABF ($a,0.755021); do_ABF ($a,0.756473); do_ABF ($a,0.757775); do_ABF ($a,0.758941); do_ABF ($a,0.759985); do_ABF ($a,0.760918); do_ABF ($a,0.761753);
$y = 17 ; $a=42; do_ABF ($a,0.771864); do_ABF ($a,0.773540); do_ABF ($a,0.775045); do_ABF ($a,0.776394); do_ABF ($a,0.777603); do_ABF ($a,0.778685); do_ABF ($a,0.779653); do_ABF ($a,0.780518); do_ABF ($a,0.781292); do_ABF ($a,0.781983);
$y = 17 ; $a=43; do_ABF ($a,0.792631); do_ABF ($a,0.794171); do_ABF ($a,0.795553); do_ABF ($a,0.796790); do_ABF ($a,0.797899); do_ABF ($a,0.798890); do_ABF ($a,0.799777); do_ABF ($a,0.800570); do_ABF ($a,0.801278); do_ABF ($a,0.801911); do_ABF ($a,0.802475);
$y = 17 ; $a=44; do_ABF ($a,0.813726); do_ABF ($a,0.815136); do_ABF ($a,0.816401); do_ABF ($a,0.817533); do_ABF ($a,0.818546); do_ABF ($a,0.819453); do_ABF ($a,0.820263); do_ABF ($a,0.820987); do_ABF ($a,0.821634); do_ABF ($a,0.822211); do_ABF ($a,0.822727); do_ABF ($a,0.823186);
$y = 17 ; $a=45; do_ABF ($a,0.835128); do_ABF ($a,0.836417); do_ABF ($a,0.837571); do_ABF ($a,0.838605); do_ABF ($a,0.839529); do_ABF ($a,0.840356); do_ABF ($a,0.841095); do_ABF ($a,0.841755); do_ABF ($a,0.842344); do_ABF ($a,0.842870); do_ABF ($a,0.843339); do_ABF ($a,0.843757); do_ABF ($a,0.844131);
$y = 17 ; $a=46; do_ABF ($a,0.856807); do_ABF ($a,0.857982); do_ABF ($a,0.859033); do_ABF ($a,0.859975); do_ABF ($a,0.860816); do_ABF ($a,0.861568); do_ABF ($a,0.862240); do_ABF ($a,0.862840); do_ABF ($a,0.863376); do_ABF ($a,0.863854); do_ABF ($a,0.864280); do_ABF ($a,0.864661); do_ABF ($a,0.865000); do_ABF ($a,0.865302);
$y = 17 ; $a=47; do_ABF ($a,0.878779); do_ABF ($a,0.879844); do_ABF ($a,0.880796); do_ABF ($a,0.881648); do_ABF ($a,0.882409); do_ABF ($a,0.883089); do_ABF ($a,0.883697); do_ABF ($a,0.884239); do_ABF ($a,0.884723); do_ABF ($a,0.885155); do_ABF ($a,0.885540); do_ABF ($a,0.885883); do_ABF ($a,0.886189); do_ABF ($a,0.886462); do_ABF ($a,0.886705);
$y = 17 ; $a=48; do_ABF ($a,0.901014); do_ABF ($a,0.901972); do_ABF ($a,0.902829); do_ABF ($a,0.903595); do_ABF ($a,0.904279); do_ABF ($a,0.904890); do_ABF ($a,0.905435); do_ABF ($a,0.905922); do_ABF ($a,0.906356); do_ABF ($a,0.906744); do_ABF ($a,0.907089); do_ABF ($a,0.907397); do_ABF ($a,0.907671); do_ABF ($a,0.907916); do_ABF ($a,0.908134); do_ABF ($a,0.908328);
$y = 17 ; $a=49; do_ABF ($a,0.923916); do_ABF ($a,0.924756); do_ABF ($a,0.925506); do_ABF ($a,0.926176); do_ABF ($a,0.926775); do_ABF ($a,0.927309); do_ABF ($a,0.927785); do_ABF ($a,0.928211); do_ABF ($a,0.928590); do_ABF ($a,0.928928); do_ABF ($a,0.929229); do_ABF ($a,0.929498); do_ABF ($a,0.929737); do_ABF ($a,0.929950); do_ABF ($a,0.930140); do_ABF ($a,0.930310); do_ABF ($a,0.930461);
$y = 17 ; $a=50; do_ABF ($a,0.947499); do_ABF ($a,0.948207); do_ABF ($a,0.948839); do_ABF ($a,0.949403); do_ABF ($a,0.949906); do_ABF ($a,0.950355); do_ABF ($a,0.950756); do_ABF ($a,0.951113); do_ABF ($a,0.951431); do_ABF ($a,0.951715); do_ABF ($a,0.951968); do_ABF ($a,0.952193); do_ABF ($a,0.952394); do_ABF ($a,0.952573); do_ABF ($a,0.952732); do_ABF ($a,0.952874); do_ABF ($a,0.953000);
$y = 17 ; $a=51; do_ABF ($a,0.968418); do_ABF ($a,0.968975); do_ABF ($a,0.969472); do_ABF ($a,0.969916); do_ABF ($a,0.970311); do_ABF ($a,0.970664); do_ABF ($a,0.970978); do_ABF ($a,0.971258); do_ABF ($a,0.971508); do_ABF ($a,0.971730); do_ABF ($a,0.971928); do_ABF ($a,0.972104); do_ABF ($a,0.972261); do_ABF ($a,0.972401); do_ABF ($a,0.972526); do_ABF ($a,0.972637); do_ABF ($a,0.972736);
$y = 17 ; $a=52; do_ABF ($a,0.989794); do_ABF ($a,0.990184); do_ABF ($a,0.990532); do_ABF ($a,0.990842); do_ABF ($a,0.991118); do_ABF ($a,0.991364); do_ABF ($a,0.991583); do_ABF ($a,0.991779); do_ABF ($a,0.991952); do_ABF ($a,0.992107); do_ABF ($a,0.992245); do_ABF ($a,0.992368); do_ABF ($a,0.992477); do_ABF ($a,0.992574); do_ABF ($a,0.992661); do_ABF ($a,0.992738); do_ABF ($a,0.992807);
$y = 17 ; $a=53; do_ABF ($a,1.011643); do_ABF ($a,1.011848); do_ABF ($a,1.012030); do_ABF ($a,1.012192); do_ABF ($a,1.012336); do_ABF ($a,1.012464); do_ABF ($a,1.012578); do_ABF ($a,1.012680); do_ABF ($a,1.012770); do_ABF ($a,1.012851); do_ABF ($a,1.012922); do_ABF ($a,1.012986); do_ABF ($a,1.013043); do_ABF ($a,1.013093); do_ABF ($a,1.013138); do_ABF ($a,1.013178); do_ABF ($a,1.013214);
$y = 17 ; $a=54; do_ABF ($a,1.034057); do_ABF ($a,1.034057); do_ABF ($a,1.034057); do_ABF ($a,1.034057); do_ABF ($a,1.034057); do_ABF ($a,1.034057); do_ABF ($a,1.034057); do_ABF ($a,1.034057); do_ABF ($a,1.034057); do_ABF ($a,1.034057); do_ABF ($a,1.034057); do_ABF ($a,1.034057); do_ABF ($a,1.034057); do_ABF ($a,1.034057); do_ABF ($a,1.034057); do_ABF ($a,1.034057); do_ABF ($a,1.034057);
$y = 17 ; $a=55; do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139);
$y = 17 ; $a=56; do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015);
$y = 17 ; $a=57; do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805);
$y = 17 ; $a=58; do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755);
$y = 17 ; $a=59; do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734);
$y = 17 ; $a=60; do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223);
$y = 17 ; $a=61; do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930);
$y = 17 ; $a=62; do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972);
$y = 17 ; $a=63; do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116);
$y = 17 ; $a=64; do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312);
$y = 17 ; $a=65; do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050);
$y = 17 ; $a=66; do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613);
$y = 17 ; $a=67; do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527);
$y = 17 ; $a=68; do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763);
$y = 17 ; $a=69; do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384);
$y = 17 ; $a=70; do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384);
$y = 17 ; $a=71; do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750);
$y = 17 ; $a=72; do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476);
$y = 17 ; $a=73; do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534);
$y = 17 ; $a=74; do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); 
$y = 17 ; $a=75; do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); 
# ABF -- males before Age 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 or more
$sex = "male";
$before_99 = "before";
$y = 34 ; $a=50; do_ABF ($a,0.953113);
$y = 34 ; $a=51; do_ABF ($a,0.972824); do_ABF ($a,0.972902);
$y = 34 ; $a=52; do_ABF ($a,0.992868); do_ABF ($a,0.992922); do_ABF ($a,0.992971);
$y = 34 ; $a=53; do_ABF ($a,1.013246); do_ABF ($a,1.013274); do_ABF ($a,1.013299); do_ABF ($a,1.013321);
$y = 34 ; $a=54; do_ABF ($a,1.034057); do_ABF ($a,1.034057); do_ABF ($a,1.034057); do_ABF ($a,1.034057); do_ABF ($a,1.034057);
$y = 34 ; $a=55; do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139);
$y = 34 ; $a=56; do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015);
$y = 34 ; $a=57; do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805);
$y = 34 ; $a=58; do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755);
$y = 34 ; $a=59; do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734);
$y = 34 ; $a=60; do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223);
$y = 34 ; $a=61; do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930);
$y = 34 ; $a=62; do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972);
$y = 34 ; $a=63; do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116);
$y = 34 ; $a=64; do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312);
$y = 34 ; $a=65; do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050);
$y = 34 ; $a=66; do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613);
$y = 34 ; $a=67; do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527);
$y = 34 ; $a=68; do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763);
$y = 34 ; $a=69; do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384);
$y = 34 ; $a=70; do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384);
$y = 34 ; $a=71; do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750);
$y = 34 ; $a=72; do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476);
$y = 34 ; $a=73; do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534);
$y = 34 ; $a=74; do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); 
$y = 34 ; $a=75; do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); 
# ABF -- females before Age 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16
$sex = "female";
$before_99 = "before";
$y = 0 ; $a=18; do_ABF ($a,0.306478); do_ABF ($a,0.310501); do_ABF ($a,0.315060);
$y = 0 ; $a=19; do_ABF ($a,0.316242); do_ABF ($a,0.320438); do_ABF ($a,0.324338); do_ABF ($a,0.328825);
$y = 0 ; $a=20; do_ABF ($a,0.326544); do_ABF ($a,0.331104); do_ABF ($a,0.335173); do_ABF ($a,0.338901); do_ABF ($a,0.343274);
$y = 0 ; $a=21; do_ABF ($a,0.337665); do_ABF ($a,0.342324); do_ABF ($a,0.346777); do_ABF ($a,0.350661); do_ABF ($a,0.354159); do_ABF ($a,0.358375);
$y = 0 ; $a=22; do_ABF ($a,0.349569); do_ABF ($a,0.354352); do_ABF ($a,0.358890); do_ABF ($a,0.363177); do_ABF ($a,0.366815); do_ABF ($a,0.370025); do_ABF ($a,0.374041);
$y = 0 ; $a=23; do_ABF ($a,0.362630); do_ABF ($a,0.367465); do_ABF ($a,0.372104); do_ABF ($a,0.376443); do_ABF ($a,0.380489); do_ABF ($a,0.383804); do_ABF ($a,0.386656); do_ABF ($a,0.390418);
$y = 0 ; $a=24; do_ABF ($a,0.376480); do_ABF ($a,0.381564); do_ABF ($a,0.386228); do_ABF ($a,0.390649); do_ABF ($a,0.394720); do_ABF ($a,0.398460); do_ABF ($a,0.401393); do_ABF ($a,0.403833); do_ABF ($a,0.407302);
$y = 0 ; $a=25; do_ABF ($a,0.391222); do_ABF ($a,0.396529); do_ABF ($a,0.401442); do_ABF ($a,0.405850); do_ABF ($a,0.409974); do_ABF ($a,0.413705); do_ABF ($a,0.417077); do_ABF ($a,0.419568); do_ABF ($a,0.421542); do_ABF ($a,0.424682);
$y = 0 ; $a=26; do_ABF ($a,0.406948); do_ABF ($a,0.412423); do_ABF ($a,0.417551); do_ABF ($a,0.422201); do_ABF ($a,0.426266); do_ABF ($a,0.430017); do_ABF ($a,0.433339); do_ABF ($a,0.436282); do_ABF ($a,0.438274); do_ABF ($a,0.439734); do_ABF ($a,0.442513);
$y = 0 ; $a=27; do_ABF ($a,0.423662); do_ABF ($a,0.429271); do_ABF ($a,0.434549); do_ABF ($a,0.439403); do_ABF ($a,0.443702); do_ABF ($a,0.447343); do_ABF ($a,0.450648); do_ABF ($a,0.453499); do_ABF ($a,0.455959); do_ABF ($a,0.457404); do_ABF ($a,0.458309); do_ABF ($a,0.461659);
$y = 0 ; $a=28; do_ABF ($a,0.440979); do_ABF ($a,0.446700); do_ABF ($a,0.452104); do_ABF ($a,0.457105); do_ABF ($a,0.461615); do_ABF ($a,0.465501); do_ABF ($a,0.468666); do_ABF ($a,0.471485); do_ABF ($a,0.473833); do_ABF ($a,0.475787); do_ABF ($a,0.476666); do_ABF ($a,0.479933); do_ABF ($a,0.483118);
$y = 0 ; $a=29; do_ABF ($a,0.459020); do_ABF ($a,0.464741); do_ABF ($a,0.470242); do_ABF ($a,0.475362); do_ABF ($a,0.480016); do_ABF ($a,0.484122); do_ABF ($a,0.487545); do_ABF ($a,0.490191); do_ABF ($a,0.492490); do_ABF ($a,0.494310); do_ABF ($a,0.495738); do_ABF ($a,0.498909); do_ABF ($a,0.501994); do_ABF ($a,0.504993);
$y = 0 ; $a=30; do_ABF ($a,0.477604); do_ABF ($a,0.483323); do_ABF ($a,0.488802); do_ABF ($a,0.494017); do_ABF ($a,0.498795); do_ABF ($a,0.503056); do_ABF ($a,0.506719); do_ABF ($a,0.509649); do_ABF ($a,0.511753); do_ABF ($a,0.513518); do_ABF ($a,0.514801); do_ABF ($a,0.517885); do_ABF ($a,0.520883); do_ABF ($a,0.523792); do_ABF ($a,0.526612);
$y = 0 ; $a=31; do_ABF ($a,0.496654); do_ABF ($a,0.502343); do_ABF ($a,0.507805); do_ABF ($a,0.512986); do_ABF ($a,0.517869); do_ABF ($a,0.522268); do_ABF ($a,0.526108); do_ABF ($a,0.529309); do_ABF ($a,0.531732); do_ABF ($a,0.533286); do_ABF ($a,0.534516); do_ABF ($a,0.537505); do_ABF ($a,0.540406); do_ABF ($a,0.543218); do_ABF ($a,0.545940); do_ABF ($a,0.548574);
$y = 0 ; $a=32; do_ABF ($a,0.516294); do_ABF ($a,0.521937); do_ABF ($a,0.527349); do_ABF ($a,0.532500); do_ABF ($a,0.537336); do_ABF ($a,0.541851); do_ABF ($a,0.545844); do_ABF ($a,0.549240); do_ABF ($a,0.551965); do_ABF ($a,0.553871); do_ABF ($a,0.554870); do_ABF ($a,0.557757); do_ABF ($a,0.560554); do_ABF ($a,0.563261); do_ABF ($a,0.565879); do_ABF ($a,0.568409); do_ABF ($a,0.570851);
$y = 0 ; $a=33; do_ABF ($a,0.536678); do_ABF ($a,0.542267); do_ABF ($a,0.547607); do_ABF ($a,0.552684); do_ABF ($a,0.557476); do_ABF ($a,0.561931); do_ABF ($a,0.566048); do_ABF ($a,0.569611); do_ABF ($a,0.572547); do_ABF ($a,0.574782); do_ABF ($a,0.576163); do_ABF ($a,0.578928); do_ABF ($a,0.581603); do_ABF ($a,0.584190); do_ABF ($a,0.586688); do_ABF ($a,0.589099); do_ABF ($a,0.591423);
$y = 0 ; $a=34; do_ABF ($a,0.557437); do_ABF ($a,0.563034); do_ABF ($a,0.568298); do_ABF ($a,0.573285); do_ABF ($a,0.577990); do_ABF ($a,0.582393); do_ABF ($a,0.586445); do_ABF ($a,0.590150); do_ABF ($a,0.593275); do_ABF ($a,0.595749); do_ABF ($a,0.597496); do_ABF ($a,0.600146); do_ABF ($a,0.602706); do_ABF ($a,0.605179); do_ABF ($a,0.607564); do_ABF ($a,0.609864); do_ABF ($a,0.612079);
$y = 0 ; $a=35; do_ABF ($a,0.578620); do_ABF ($a,0.584227); do_ABF ($a,0.589488); do_ABF ($a,0.594380); do_ABF ($a,0.598979); do_ABF ($a,0.603284); do_ABF ($a,0.607279); do_ABF ($a,0.610915); do_ABF ($a,0.614201); do_ABF ($a,0.616887); do_ABF ($a,0.618901); do_ABF ($a,0.621442); do_ABF ($a,0.623896); do_ABF ($a,0.626262); do_ABF ($a,0.628543); do_ABF ($a,0.630740); do_ABF ($a,0.632855);
$y = 0 ; $a=36; do_ABF ($a,0.600301); do_ABF ($a,0.605903); do_ABF ($a,0.611162); do_ABF ($a,0.616041); do_ABF ($a,0.620527); do_ABF ($a,0.624709); do_ABF ($a,0.628594); do_ABF ($a,0.632169); do_ABF ($a,0.635382); do_ABF ($a,0.638247); do_ABF ($a,0.640496); do_ABF ($a,0.642933); do_ABF ($a,0.645284); do_ABF ($a,0.647550); do_ABF ($a,0.649732); do_ABF ($a,0.651831); do_ABF ($a,0.653850);
$y = 0 ; $a=37; do_ABF ($a,0.622517); do_ABF ($a,0.628077); do_ABF ($a,0.633318); do_ABF ($a,0.638188); do_ABF ($a,0.642653); do_ABF ($a,0.646707); do_ABF ($a,0.650456); do_ABF ($a,0.653910); do_ABF ($a,0.657059); do_ABF ($a,0.659848); do_ABF ($a,0.662295); do_ABF ($a,0.664634); do_ABF ($a,0.666887); do_ABF ($a,0.669057); do_ABF ($a,0.671145); do_ABF ($a,0.673152); do_ABF ($a,0.675081);
$y = 0 ; $a=38; do_ABF ($a,0.645245); do_ABF ($a,0.650757); do_ABF ($a,0.655945); do_ABF ($a,0.660791); do_ABF ($a,0.665245); do_ABF ($a,0.669278); do_ABF ($a,0.672888); do_ABF ($a,0.676197); do_ABF ($a,0.679221); do_ABF ($a,0.681946); do_ABF ($a,0.684318); do_ABF ($a,0.686564); do_ABF ($a,0.688726); do_ABF ($a,0.690806); do_ABF ($a,0.692806); do_ABF ($a,0.694728); do_ABF ($a,0.696573);
$y = 0 ; $a=39; do_ABF ($a,0.668543); do_ABF ($a,0.673858); do_ABF ($a,0.678985); do_ABF ($a,0.683769); do_ABF ($a,0.688195); do_ABF ($a,0.692216); do_ABF ($a,0.695805); do_ABF ($a,0.698966); do_ABF ($a,0.701835); do_ABF ($a,0.704430); do_ABF ($a,0.706740); do_ABF ($a,0.708887); do_ABF ($a,0.710953); do_ABF ($a,0.712939); do_ABF ($a,0.714846); do_ABF ($a,0.716679); do_ABF ($a,0.718437);
$y = 0 ; $a=40; do_ABF ($a,0.692375); do_ABF ($a,0.697497); do_ABF ($a,0.702400); do_ABF ($a,0.707116); do_ABF ($a,0.711475); do_ABF ($a,0.715470); do_ABF ($a,0.719051); do_ABF ($a,0.722195); do_ABF ($a,0.724909); do_ABF ($a,0.727344); do_ABF ($a,0.729520); do_ABF ($a,0.731565); do_ABF ($a,0.733531); do_ABF ($a,0.735419); do_ABF ($a,0.737232); do_ABF ($a,0.738971); do_ABF ($a,0.740639);
$y = 0 ; $a=41; do_ABF ($a,0.715851); do_ABF ($a,0.720750); do_ABF ($a,0.725430); do_ABF ($a,0.729892); do_ABF ($a,0.734175); do_ABF ($a,0.738098); do_ABF ($a,0.741654); do_ABF ($a,0.744794); do_ABF ($a,0.747496); do_ABF ($a,0.749770); do_ABF ($a,0.751781); do_ABF ($a,0.753714); do_ABF ($a,0.755570); do_ABF ($a,0.757352); do_ABF ($a,0.759062); do_ABF ($a,0.760701); do_ABF ($a,0.762272);
$y = 0 ; $a=42; do_ABF ($a,0.739656); do_ABF ($a,0.744358); do_ABF ($a,0.748799); do_ABF ($a,0.753025); do_ABF ($a,0.757043); do_ABF ($a,0.760897); do_ABF ($a,0.764389); do_ABF ($a,0.767518); do_ABF ($a,0.770232); do_ABF ($a,0.772508); do_ABF ($a,0.774361); do_ABF ($a,0.776176); do_ABF ($a,0.777918); do_ABF ($a,0.779588); do_ABF ($a,0.781190); do_ABF ($a,0.782725); do_ABF ($a,0.784195);
$y = 0 ; $a=43; do_ABF ($a,0.763792); do_ABF ($a,0.768264); do_ABF ($a,0.772498); do_ABF ($a,0.776476); do_ABF ($a,0.780252); do_ABF ($a,0.783832); do_ABF ($a,0.787268); do_ABF ($a,0.790345); do_ABF ($a,0.793064); do_ABF ($a,0.795370); do_ABF ($a,0.797242); do_ABF ($a,0.798935); do_ABF ($a,0.800558); do_ABF ($a,0.802113); do_ABF ($a,0.803603); do_ABF ($a,0.805030); do_ABF ($a,0.806396);
$y = 0 ; $a=44; do_ABF ($a,0.788447); do_ABF ($a,0.792780); do_ABF ($a,0.796765); do_ABF ($a,0.800521); do_ABF ($a,0.804031); do_ABF ($a,0.807355); do_ABF ($a,0.810502); do_ABF ($a,0.813529); do_ABF ($a,0.816202); do_ABF ($a,0.818525); do_ABF ($a,0.820438); do_ABF ($a,0.822007); do_ABF ($a,0.823510); do_ABF ($a,0.824949); do_ABF ($a,0.826328); do_ABF ($a,0.827647); do_ABF ($a,0.828909);
$y = 0 ; $a=45; do_ABF ($a,0.811270); do_ABF ($a,0.817826); do_ABF ($a,0.821663); do_ABF ($a,0.825150); do_ABF ($a,0.828425); do_ABF ($a,0.831468); do_ABF ($a,0.834347); do_ABF ($a,0.837072); do_ABF ($a,0.839702); do_ABF ($a,0.841986); do_ABF ($a,0.843927); do_ABF ($a,0.845372); do_ABF ($a,0.846757); do_ABF ($a,0.848081); do_ABF ($a,0.849349); do_ABF ($a,0.850561); do_ABF ($a,0.851720);
$y = 0 ; $a=46; do_ABF ($a,0.836949); do_ABF ($a,0.840782); do_ABF ($a,0.847094); do_ABF ($a,0.850426); do_ABF ($a,0.853414); do_ABF ($a,0.856210); do_ABF ($a,0.858794); do_ABF ($a,0.861238); do_ABF ($a,0.863553); do_ABF ($a,0.865800); do_ABF ($a,0.867710); do_ABF ($a,0.869033); do_ABF ($a,0.870299); do_ABF ($a,0.871509); do_ABF ($a,0.872667); do_ABF ($a,0.873773); do_ABF ($a,0.874830);
$y = 0 ; $a=47; do_ABF ($a,0.863233); do_ABF ($a,0.866764); do_ABF ($a,0.870081); do_ABF ($a,0.876158); do_ABF ($a,0.878989); do_ABF ($a,0.881488); do_ABF ($a,0.883818); do_ABF ($a,0.885957); do_ABF ($a,0.887984); do_ABF ($a,0.889908); do_ABF ($a,0.891794); do_ABF ($a,0.892995); do_ABF ($a,0.894142); do_ABF ($a,0.895239); do_ABF ($a,0.896287); do_ABF ($a,0.897288); do_ABF ($a,0.898243);
$y = 0 ; $a=48; do_ABF ($a,0.890242); do_ABF ($a,0.893437); do_ABF ($a,0.896432); do_ABF ($a,0.899234); do_ABF ($a,0.905087); do_ABF ($a,0.907426); do_ABF ($a,0.909445); do_ABF ($a,0.911323); do_ABF ($a,0.913034); do_ABF ($a,0.914661); do_ABF ($a,0.916213); do_ABF ($a,0.917290); do_ABF ($a,0.918319); do_ABF ($a,0.919302); do_ABF ($a,0.920241); do_ABF ($a,0.921136); do_ABF ($a,0.921991);
$y = 0 ; $a=49; do_ABF ($a,0.918016); do_ABF ($a,0.920844); do_ABF ($a,0.923487); do_ABF ($a,0.925952); do_ABF ($a,0.928251); do_ABF ($a,0.933905); do_ABF ($a,0.935770); do_ABF ($a,0.937328); do_ABF ($a,0.938774); do_ABF ($a,0.940080); do_ABF ($a,0.941330); do_ABF ($a,0.942271); do_ABF ($a,0.943170); do_ABF ($a,0.944027); do_ABF ($a,0.944845); do_ABF ($a,0.945625); do_ABF ($a,0.946368);
$y = 0 ; $a=50; do_ABF ($a,0.946769); do_ABF ($a,0.949181); do_ABF ($a,0.951427); do_ABF ($a,0.953516); do_ABF ($a,0.955459); do_ABF ($a,0.957263); do_ABF ($a,0.962742); do_ABF ($a,0.964145); do_ABF ($a,0.965259); do_ABF ($a,0.966290); do_ABF ($a,0.967207); do_ABF ($a,0.967996); do_ABF ($a,0.968749); do_ABF ($a,0.969466); do_ABF ($a,0.970150); do_ABF ($a,0.970802); do_ABF ($a,0.971423);
$y = 0 ; $a=51; do_ABF ($a,0.976447); do_ABF ($a,0.978393); do_ABF ($a,0.980198); do_ABF ($a,0.981873); do_ABF ($a,0.983424); do_ABF ($a,0.984861); do_ABF ($a,0.986191); do_ABF ($a,0.991528); do_ABF ($a,0.992493); do_ABF ($a,0.993184); do_ABF ($a,0.993825); do_ABF ($a,0.994447); do_ABF ($a,0.995039); do_ABF ($a,0.995603); do_ABF ($a,0.996140); do_ABF ($a,0.996652); do_ABF ($a,0.997139);
$y = 0 ; $a=52; do_ABF ($a,1.007398); do_ABF ($a,1.008798); do_ABF ($a,1.010092); do_ABF ($a,1.011288); do_ABF ($a,1.012392); do_ABF ($a,1.013411); do_ABF ($a,1.014352); do_ABF ($a,1.015220); do_ABF ($a,1.020442); do_ABF ($a,1.020982); do_ABF ($a,1.021266); do_ABF ($a,1.021701); do_ABF ($a,1.022115); do_ABF ($a,1.022509); do_ABF ($a,1.022883); do_ABF ($a,1.023239); do_ABF ($a,1.023578);
$y = 0 ; $a=53; do_ABF ($a,1.039645); do_ABF ($a,1.040409); do_ABF ($a,1.041113); do_ABF ($a,1.041760); do_ABF ($a,1.042355); do_ABF ($a,1.042903); do_ABF ($a,1.043406); do_ABF ($a,1.043870); do_ABF ($a,1.044296); do_ABF ($a,1.049437); do_ABF ($a,1.049573); do_ABF ($a,1.049799); do_ABF ($a,1.050013); do_ABF ($a,1.050217); do_ABF ($a,1.050411); do_ABF ($a,1.050595); do_ABF ($a,1.050770);
$y = 0 ; $a=54; do_ABF ($a,1.073870); do_ABF ($a,1.073870); do_ABF ($a,1.073870); do_ABF ($a,1.073870); do_ABF ($a,1.073870); do_ABF ($a,1.073870); do_ABF ($a,1.073870); do_ABF ($a,1.073870); do_ABF ($a,1.073870); do_ABF ($a,1.073870); do_ABF ($a,1.078975); do_ABF ($a,1.078975); do_ABF ($a,1.078975); do_ABF ($a,1.078975); do_ABF ($a,1.078975); do_ABF ($a,1.078975); do_ABF ($a,1.078975);
$y = 0 ; $a=55; do_ABF ($a,1.109297); do_ABF ($a,1.109297); do_ABF ($a,1.109297); do_ABF ($a,1.109297); do_ABF ($a,1.109297); do_ABF ($a,1.109297); do_ABF ($a,1.109297); do_ABF ($a,1.109297); do_ABF ($a,1.109297); do_ABF ($a,1.109297); do_ABF ($a,1.109297); do_ABF ($a,1.109297); do_ABF ($a,1.109297); do_ABF ($a,1.109297); do_ABF ($a,1.109297); do_ABF ($a,1.109297); do_ABF ($a,1.109297);
$y = 0 ; $a=56; do_ABF ($a,1.116478); do_ABF ($a,1.116478); do_ABF ($a,1.116478); do_ABF ($a,1.116478); do_ABF ($a,1.116478); do_ABF ($a,1.116478); do_ABF ($a,1.116478); do_ABF ($a,1.116478); do_ABF ($a,1.116478); do_ABF ($a,1.116478); do_ABF ($a,1.116478); do_ABF ($a,1.116478); do_ABF ($a,1.116478); do_ABF ($a,1.116478); do_ABF ($a,1.116478); do_ABF ($a,1.116478); do_ABF ($a,1.116478);
$y = 0 ; $a=57; do_ABF ($a,1.125985); do_ABF ($a,1.125985); do_ABF ($a,1.125985); do_ABF ($a,1.125985); do_ABF ($a,1.125985); do_ABF ($a,1.125985); do_ABF ($a,1.125985); do_ABF ($a,1.125985); do_ABF ($a,1.125985); do_ABF ($a,1.125985); do_ABF ($a,1.125985); do_ABF ($a,1.125985); do_ABF ($a,1.125985); do_ABF ($a,1.125985); do_ABF ($a,1.125985); do_ABF ($a,1.125985); do_ABF ($a,1.125985);
$y = 0 ; $a=58; do_ABF ($a,1.135808); do_ABF ($a,1.135808); do_ABF ($a,1.135808); do_ABF ($a,1.135808); do_ABF ($a,1.135808); do_ABF ($a,1.135808); do_ABF ($a,1.135808); do_ABF ($a,1.135808); do_ABF ($a,1.135808); do_ABF ($a,1.135808); do_ABF ($a,1.135808); do_ABF ($a,1.135808); do_ABF ($a,1.135808); do_ABF ($a,1.135808); do_ABF ($a,1.135808); do_ABF ($a,1.135808); do_ABF ($a,1.135808);
$y = 0 ; $a=59; do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496);
$y = 0 ; $a=60; do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652);
$y = 0 ; $a=61; do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927);
$y = 0 ; $a=62; do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743);
$y = 0 ; $a=63; do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059);
$y = 0 ; $a=64; do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318);
$y = 0 ; $a=65; do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774);
$y = 0 ; $a=66; do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506);
$y = 0 ; $a=67; do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617);
$y = 0 ; $a=68; do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073);
$y = 0 ; $a=69; do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827);
$y = 0 ; $a=70; do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857);
$y = 0 ; $a=71; do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136);
$y = 0 ; $a=72; do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643);
$y = 0 ; $a=73; do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377);
$y = 0 ; $a=74; do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); 
$y = 0 ; $a=75; do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); 
# PCF -- females Age 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16
$sex = "female";
$before_99 = "after";
$y = 0 ; $a=18; do_PCF ($a,0.207256); do_PCF ($a,0.223189); do_PCF ($a,0.241382);
$y = 0 ; $a=19; do_PCF ($a,0.216424); do_PCF ($a,0.232742); do_PCF ($a,0.247941); do_PCF ($a,0.265541);
$y = 0 ; $a=20; do_PCF ($a,0.226582); do_PCF ($a,0.244024); do_PCF ($a,0.259590); do_PCF ($a,0.273878); do_PCF ($a,0.290745);
$y = 0 ; $a=21; do_PCF ($a,0.238779); do_PCF ($a,0.256274); do_PCF ($a,0.273027); do_PCF ($a,0.287641); do_PCF ($a,0.300835); do_PCF ($a,0.316824);
$y = 0 ; $a=22; do_PCF ($a,0.252809); do_PCF ($a,0.270447); do_PCF ($a,0.287204); do_PCF ($a,0.303059); do_PCF ($a,0.316523); do_PCF ($a,0.328445); do_PCF ($a,0.343415);
$y = 0 ; $a=23; do_PCF ($a,0.269821); do_PCF ($a,0.287325); do_PCF ($a,0.304144); do_PCF ($a,0.319896); do_PCF ($a,0.334608); do_PCF ($a,0.346686); do_PCF ($a,0.357122); do_PCF ($a,0.370911);
$y = 0 ; $a=24; do_PCF ($a,0.288309); do_PCF ($a,0.306407); do_PCF ($a,0.323004); do_PCF ($a,0.338756); do_PCF ($a,0.353283); do_PCF ($a,0.366659); do_PCF ($a,0.377181); do_PCF ($a,0.385991); do_PCF ($a,0.398496);
$y = 0 ; $a=25; do_PCF ($a,0.308508); do_PCF ($a,0.327081); do_PCF ($a,0.344266); do_PCF ($a,0.359678); do_PCF ($a,0.374120); do_PCF ($a,0.387209); do_PCF ($a,0.399068); do_PCF ($a,0.407878); do_PCF ($a,0.414933); do_PCF ($a,0.426068);
$y = 0 ; $a=26; do_PCF ($a,0.330596); do_PCF ($a,0.349425); do_PCF ($a,0.367057); do_PCF ($a,0.383037); do_PCF ($a,0.397003); do_PCF ($a,0.409909); do_PCF ($a,0.421369); do_PCF ($a,0.431554); do_PCF ($a,0.438521); do_PCF ($a,0.443720); do_PCF ($a,0.453419);
$y = 0 ; $a=27; do_PCF ($a,0.354547); do_PCF ($a,0.373503); do_PCF ($a,0.391333); do_PCF ($a,0.407724); do_PCF ($a,0.422232); do_PCF ($a,0.434519); do_PCF ($a,0.445698); do_PCF ($a,0.455375); do_PCF ($a,0.463765); do_PCF ($a,0.468794); do_PCF ($a,0.472068); do_PCF ($a,0.483459);
$y = 0 ; $a=28; do_PCF ($a,0.378906); do_PCF ($a,0.397895); do_PCF ($a,0.415827); do_PCF ($a,0.432413); do_PCF ($a,0.447364); do_PCF ($a,0.460242); do_PCF ($a,0.470733); do_PCF ($a,0.480107); do_PCF ($a,0.487955); do_PCF ($a,0.494534); do_PCF ($a,0.497636); do_PCF ($a,0.508525); do_PCF ($a,0.519143);
$y = 0 ; $a=29; do_PCF ($a,0.404098); do_PCF ($a,0.422735); do_PCF ($a,0.440662); do_PCF ($a,0.457334); do_PCF ($a,0.472482); do_PCF ($a,0.485839); do_PCF ($a,0.496971); do_PCF ($a,0.505588); do_PCF ($a,0.513111); do_PCF ($a,0.519113); do_PCF ($a,0.523888); do_PCF ($a,0.534246); do_PCF ($a,0.544328); do_PCF ($a,0.554128);
$y = 0 ; $a=30; do_PCF ($a,0.429501); do_PCF ($a,0.447783); do_PCF ($a,0.465297); do_PCF ($a,0.481968); do_PCF ($a,0.497228); do_PCF ($a,0.510829); do_PCF ($a,0.522519); do_PCF ($a,0.531868); do_PCF ($a,0.538606); do_PCF ($a,0.544297); do_PCF ($a,0.548496); do_PCF ($a,0.558368); do_PCF ($a,0.567962); do_PCF ($a,0.577274); do_PCF ($a,0.586303);
$y = 0 ; $a=31; do_PCF ($a,0.454844); do_PCF ($a,0.472680); do_PCF ($a,0.489806); do_PCF ($a,0.506043); do_PCF ($a,0.521345); do_PCF ($a,0.535118); do_PCF ($a,0.547130); do_PCF ($a,0.557144); do_PCF ($a,0.564731); do_PCF ($a,0.569634); do_PCF ($a,0.573558); do_PCF ($a,0.582929); do_PCF ($a,0.592022); do_PCF ($a,0.600835); do_PCF ($a,0.609369); do_PCF ($a,0.617624);
$y = 0 ; $a=32; do_PCF ($a,0.480507); do_PCF ($a,0.497853); do_PCF ($a,0.514484); do_PCF ($a,0.530308); do_PCF ($a,0.545161); do_PCF ($a,0.559020); do_PCF ($a,0.571266); do_PCF ($a,0.581676); do_PCF ($a,0.590025); do_PCF ($a,0.595884); do_PCF ($a,0.599004); do_PCF ($a,0.607862); do_PCF ($a,0.616443); do_PCF ($a,0.624750); do_PCF ($a,0.632782); do_PCF ($a,0.640543); do_PCF ($a,0.648034);
$y = 0 ; $a=33; do_PCF ($a,0.506858); do_PCF ($a,0.523692); do_PCF ($a,0.539770); do_PCF ($a,0.555053); do_PCF ($a,0.569470); do_PCF ($a,0.582864); do_PCF ($a,0.595236); do_PCF ($a,0.605933); do_PCF ($a,0.614744); do_PCF ($a,0.621452); do_PCF ($a,0.625620); do_PCF ($a,0.633922); do_PCF ($a,0.641955); do_PCF ($a,0.649719); do_PCF ($a,0.657218); do_PCF ($a,0.664453); do_PCF ($a,0.671429);
$y = 0 ; $a=34; do_PCF ($a,0.532714); do_PCF ($a,0.549228); do_PCF ($a,0.564748); do_PCF ($a,0.579446); do_PCF ($a,0.593305); do_PCF ($a,0.606267); do_PCF ($a,0.618185); do_PCF ($a,0.629076); do_PCF ($a,0.638255); do_PCF ($a,0.645515); do_PCF ($a,0.650646); do_PCF ($a,0.658426); do_PCF ($a,0.665944); do_PCF ($a,0.673201); do_PCF ($a,0.680202); do_PCF ($a,0.686950); do_PCF ($a,0.693449);
$y = 0 ; $a=35; do_PCF ($a,0.558149); do_PCF ($a,0.574342); do_PCF ($a,0.589526); do_PCF ($a,0.603635); do_PCF ($a,0.616888); do_PCF ($a,0.629288); do_PCF ($a,0.640787); do_PCF ($a,0.651242); do_PCF ($a,0.660684); do_PCF ($a,0.668392); do_PCF ($a,0.674165); do_PCF ($a,0.681457); do_PCF ($a,0.688496); do_PCF ($a,0.695284); do_PCF ($a,0.701825); do_PCF ($a,0.708125); do_PCF ($a,0.714186);
$y = 0 ; $a=36; do_PCF ($a,0.583350); do_PCF ($a,0.599172); do_PCF ($a,0.614020); do_PCF ($a,0.627785); do_PCF ($a,0.640427); do_PCF ($a,0.652206); do_PCF ($a,0.663139); do_PCF ($a,0.673189); do_PCF ($a,0.682212); do_PCF ($a,0.690250); do_PCF ($a,0.696546); do_PCF ($a,0.703378); do_PCF ($a,0.709964); do_PCF ($a,0.716310); do_PCF ($a,0.722420); do_PCF ($a,0.728299); do_PCF ($a,0.733951);
$y = 0 ; $a=37; do_PCF ($a,0.608402); do_PCF ($a,0.623748); do_PCF ($a,0.638210); do_PCF ($a,0.651637); do_PCF ($a,0.663940); do_PCF ($a,0.675095); do_PCF ($a,0.685402); do_PCF ($a,0.694890); do_PCF ($a,0.703529); do_PCF ($a,0.711169); do_PCF ($a,0.717864); do_PCF ($a,0.724260); do_PCF ($a,0.730422); do_PCF ($a,0.736353); do_PCF ($a,0.742058); do_PCF ($a,0.747543); do_PCF ($a,0.752813);
$y = 0 ; $a=38; do_PCF ($a,0.633110); do_PCF ($a,0.647961); do_PCF ($a,0.661938); do_PCF ($a,0.674989); do_PCF ($a,0.686975); do_PCF ($a,0.697817); do_PCF ($a,0.707506); do_PCF ($a,0.716380); do_PCF ($a,0.724475); do_PCF ($a,0.731764); do_PCF ($a,0.738094); do_PCF ($a,0.744084); do_PCF ($a,0.749850); do_PCF ($a,0.755396); do_PCF ($a,0.760727); do_PCF ($a,0.765848); do_PCF ($a,0.770765);
$y = 0 ; $a=39; do_PCF ($a,0.657711); do_PCF ($a,0.671683); do_PCF ($a,0.685155); do_PCF ($a,0.697722); do_PCF ($a,0.709348); do_PCF ($a,0.719898); do_PCF ($a,0.729303); do_PCF ($a,0.737569); do_PCF ($a,0.745061); do_PCF ($a,0.751827); do_PCF ($a,0.757838); do_PCF ($a,0.763421); do_PCF ($a,0.768790); do_PCF ($a,0.773950); do_PCF ($a,0.778906); do_PCF ($a,0.783663); do_PCF ($a,0.788228);
$y = 0 ; $a=40; do_PCF ($a,0.682075); do_PCF ($a,0.695201); do_PCF ($a,0.707757); do_PCF ($a,0.719829); do_PCF ($a,0.730988); do_PCF ($a,0.741211); do_PCF ($a,0.750363); do_PCF ($a,0.758384); do_PCF ($a,0.765288); do_PCF ($a,0.771473); do_PCF ($a,0.776988); do_PCF ($a,0.782165); do_PCF ($a,0.787139); do_PCF ($a,0.791916); do_PCF ($a,0.796502); do_PCF ($a,0.800900); do_PCF ($a,0.805118);
$y = 0 ; $a=41; do_PCF ($a,0.706328); do_PCF ($a,0.718572); do_PCF ($a,0.730256); do_PCF ($a,0.741391); do_PCF ($a,0.752078); do_PCF ($a,0.761863); do_PCF ($a,0.770729); do_PCF ($a,0.778546); do_PCF ($a,0.785255); do_PCF ($a,0.790880); do_PCF ($a,0.795843); do_PCF ($a,0.800609); do_PCF ($a,0.805185); do_PCF ($a,0.809576); do_PCF ($a,0.813788); do_PCF ($a,0.817826); do_PCF ($a,0.821695);
$y = 0 ; $a=42; do_PCF ($a,0.729899); do_PCF ($a,0.741343); do_PCF ($a,0.752147); do_PCF ($a,0.762420); do_PCF ($a,0.772181); do_PCF ($a,0.781543); do_PCF ($a,0.790026); do_PCF ($a,0.797620); do_PCF ($a,0.804191); do_PCF ($a,0.809684); do_PCF ($a,0.814128); do_PCF ($a,0.818484); do_PCF ($a,0.822662); do_PCF ($a,0.826669); do_PCF ($a,0.830509); do_PCF ($a,0.834188); do_PCF ($a,0.837712);
$y = 0 ; $a=43; do_PCF ($a,0.752761); do_PCF ($a,0.763362); do_PCF ($a,0.773385); do_PCF ($a,0.782796); do_PCF ($a,0.791718); do_PCF ($a,0.800179); do_PCF ($a,0.808299); do_PCF ($a,0.815570); do_PCF ($a,0.821987); do_PCF ($a,0.827412); do_PCF ($a,0.831791); do_PCF ($a,0.835738); do_PCF ($a,0.839523); do_PCF ($a,0.843149); do_PCF ($a,0.846622); do_PCF ($a,0.849946); do_PCF ($a,0.853128);
$y = 0 ; $a=44; do_PCF ($a,0.775244); do_PCF ($a,0.785206); do_PCF ($a,0.794381); do_PCF ($a,0.803017); do_PCF ($a,0.811082); do_PCF ($a,0.818713); do_PCF ($a,0.825940); do_PCF ($a,0.832892); do_PCF ($a,0.839030); do_PCF ($a,0.844351); do_PCF ($a,0.848715); do_PCF ($a,0.852268); do_PCF ($a,0.855671); do_PCF ($a,0.858930); do_PCF ($a,0.862049); do_PCF ($a,0.865033); do_PCF ($a,0.867887);
$y = 0 ; $a=45; do_PCF ($a,0.793081); do_PCF ($a,0.806632); do_PCF ($a,0.815186); do_PCF ($a,0.822978); do_PCF ($a,0.830281); do_PCF ($a,0.837065); do_PCF ($a,0.843478); do_PCF ($a,0.849549); do_PCF ($a,0.855415); do_PCF ($a,0.860503); do_PCF ($a,0.864815); do_PCF ($a,0.867991); do_PCF ($a,0.871030); do_PCF ($a,0.873939); do_PCF ($a,0.876721); do_PCF ($a,0.879381); do_PCF ($a,0.881923);
$y = 0 ; $a=46; do_PCF ($a,0.814743); do_PCF ($a,0.823023); do_PCF ($a,0.835561); do_PCF ($a,0.842755); do_PCF ($a,0.849224); do_PCF ($a,0.855265); do_PCF ($a,0.860844); do_PCF ($a,0.866118); do_PCF ($a,0.871117); do_PCF ($a,0.875980); do_PCF ($a,0.880104); do_PCF ($a,0.882919); do_PCF ($a,0.885612); do_PCF ($a,0.888187); do_PCF ($a,0.890648); do_PCF ($a,0.893000); do_PCF ($a,0.895246);
$y = 0 ; $a=47; do_PCF ($a,0.835991); do_PCF ($a,0.843366); do_PCF ($a,0.850290); do_PCF ($a,0.861884); do_PCF ($a,0.867799); do_PCF ($a,0.873031); do_PCF ($a,0.877900); do_PCF ($a,0.882368); do_PCF ($a,0.886600); do_PCF ($a,0.890621); do_PCF ($a,0.894576); do_PCF ($a,0.897048); do_PCF ($a,0.899411); do_PCF ($a,0.901669); do_PCF ($a,0.903825); do_PCF ($a,0.905884); do_PCF ($a,0.907850);
$y = 0 ; $a=48; do_PCF ($a,0.856954); do_PCF ($a,0.863395); do_PCF ($a,0.869427); do_PCF ($a,0.875067); do_PCF ($a,0.885793); do_PCF ($a,0.890512); do_PCF ($a,0.894597); do_PCF ($a,0.898384); do_PCF ($a,0.901833); do_PCF ($a,0.905113); do_PCF ($a,0.908248); do_PCF ($a,0.910393); do_PCF ($a,0.912441); do_PCF ($a,0.914397); do_PCF ($a,0.916264); do_PCF ($a,0.918045); do_PCF ($a,0.919745);
$y = 0 ; $a=49; do_PCF ($a,0.877653); do_PCF ($a,0.883143); do_PCF ($a,0.888269); do_PCF ($a,0.893051); do_PCF ($a,0.897505); do_PCF ($a,0.907464); do_PCF ($a,0.911091); do_PCF ($a,0.914132); do_PCF ($a,0.916942); do_PCF ($a,0.919473); do_PCF ($a,0.921901); do_PCF ($a,0.923710); do_PCF ($a,0.925435); do_PCF ($a,0.927082); do_PCF ($a,0.928652); do_PCF ($a,0.930149); do_PCF ($a,0.931577);
$y = 0 ; $a=50; do_PCF ($a,0.898333); do_PCF ($a,0.902831); do_PCF ($a,0.907018); do_PCF ($a,0.910912); do_PCF ($a,0.914531); do_PCF ($a,0.917890); do_PCF ($a,0.927177); do_PCF ($a,0.929804); do_PCF ($a,0.931892); do_PCF ($a,0.933815); do_PCF ($a,0.935518); do_PCF ($a,0.936979); do_PCF ($a,0.938371); do_PCF ($a,0.939698); do_PCF ($a,0.940963); do_PCF ($a,0.942168); do_PCF ($a,0.943316);
$y = 0 ; $a=51; do_PCF ($a,0.918685); do_PCF ($a,0.922163); do_PCF ($a,0.925390); do_PCF ($a,0.928382); do_PCF ($a,0.931153); do_PCF ($a,0.933720); do_PCF ($a,0.936095); do_PCF ($a,0.944820); do_PCF ($a,0.946554); do_PCF ($a,0.947795); do_PCF ($a,0.948932); do_PCF ($a,0.950037); do_PCF ($a,0.951090); do_PCF ($a,0.952093); do_PCF ($a,0.953047); do_PCF ($a,0.953956); do_PCF ($a,0.954821);
$y = 0 ; $a=52; do_PCF ($a,0.939091); do_PCF ($a,0.941483); do_PCF ($a,0.943694); do_PCF ($a,0.945736); do_PCF ($a,0.947622); do_PCF ($a,0.949363); do_PCF ($a,0.950970); do_PCF ($a,0.952453); do_PCF ($a,0.960711); do_PCF ($a,0.961640); do_PCF ($a,0.962117); do_PCF ($a,0.962858); do_PCF ($a,0.963563); do_PCF ($a,0.964234); do_PCF ($a,0.964871); do_PCF ($a,0.965478); do_PCF ($a,0.966054);
$y = 0 ; $a=53; do_PCF ($a,0.959279); do_PCF ($a,0.960525); do_PCF ($a,0.961671); do_PCF ($a,0.962725); do_PCF ($a,0.963695); do_PCF ($a,0.964587); do_PCF ($a,0.965408); do_PCF ($a,0.966163); do_PCF ($a,0.966858); do_PCF ($a,0.974754); do_PCF ($a,0.974975); do_PCF ($a,0.975342); do_PCF ($a,0.975691); do_PCF ($a,0.976023); do_PCF ($a,0.976338); do_PCF ($a,0.976637); do_PCF ($a,0.976921);
$y = 0 ; $a=54; do_PCF ($a,0.980130); do_PCF ($a,0.980130); do_PCF ($a,0.980130); do_PCF ($a,0.980130); do_PCF ($a,0.980130); do_PCF ($a,0.980130); do_PCF ($a,0.980130); do_PCF ($a,0.980130); do_PCF ($a,0.980130); do_PCF ($a,0.980130); do_PCF ($a,0.987780); do_PCF ($a,0.987780); do_PCF ($a,0.987780); do_PCF ($a,0.987780); do_PCF ($a,0.987780); do_PCF ($a,0.987780); do_PCF ($a,0.987780); 
$y = 0 ; $a=55; do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); 
# PCF -- males Age 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16
$sex = "male";
$before_99 = "after";
$y = 0 ; $a=18; do_PCF ($a,0.285404); do_PCF ($a,0.315097); do_PCF ($a,0.341569);
$y = 0 ; $a=19; do_PCF ($a,0.290706); do_PCF ($a,0.320411); do_PCF ($a,0.347595); do_PCF ($a,0.371338);
$y = 0 ; $a=20; do_PCF ($a,0.298252); do_PCF ($a,0.327792); do_PCF ($a,0.354905); do_PCF ($a,0.379312); do_PCF ($a,0.400170);
$y = 0 ; $a=21; do_PCF ($a,0.308016); do_PCF ($a,0.337430); do_PCF ($a,0.364261); do_PCF ($a,0.388480); do_PCF ($a,0.409933); do_PCF ($a,0.427825);
$y = 0 ; $a=22; do_PCF ($a,0.319623); do_PCF ($a,0.348965); do_PCF ($a,0.375570); do_PCF ($a,0.399389); do_PCF ($a,0.420546); do_PCF ($a,0.438983); do_PCF ($a,0.453929);
$y = 0 ; $a=23; do_PCF ($a,0.334929); do_PCF ($a,0.363841); do_PCF ($a,0.390129); do_PCF ($a,0.413460); do_PCF ($a,0.433953); do_PCF ($a,0.451858); do_PCF ($a,0.467183); do_PCF ($a,0.479162);
$y = 0 ; $a=24; do_PCF ($a,0.351476); do_PCF ($a,0.380085); do_PCF ($a,0.405817); do_PCF ($a,0.428743); do_PCF ($a,0.448660); do_PCF ($a,0.465816); do_PCF ($a,0.480551); do_PCF ($a,0.492912); do_PCF ($a,0.502113);
$y = 0 ; $a=25; do_PCF ($a,0.369137); do_PCF ($a,0.397294); do_PCF ($a,0.422633); do_PCF ($a,0.444907); do_PCF ($a,0.464360); do_PCF ($a,0.480882); do_PCF ($a,0.494814); do_PCF ($a,0.506555); do_PCF ($a,0.516167); do_PCF ($a,0.522829);
$y = 0 ; $a=26; do_PCF ($a,0.387955); do_PCF ($a,0.415455); do_PCF ($a,0.440244); do_PCF ($a,0.462062); do_PCF ($a,0.480796); do_PCF ($a,0.496824); do_PCF ($a,0.510091); do_PCF ($a,0.520998); do_PCF ($a,0.529980); do_PCF ($a,0.537094); do_PCF ($a,0.541475);
$y = 0 ; $a=27; do_PCF ($a,0.407458); do_PCF ($a,0.434413); do_PCF ($a,0.458454); do_PCF ($a,0.479679); do_PCF ($a,0.497946); do_PCF ($a,0.513237); do_PCF ($a,0.526019); do_PCF ($a,0.536269); do_PCF ($a,0.544419); do_PCF ($a,0.550920); do_PCF ($a,0.555813); do_PCF ($a,0.575117);
$y = 0 ; $a=28; do_PCF ($a,0.427147); do_PCF ($a,0.453382); do_PCF ($a,0.476873); do_PCF ($a,0.497352); do_PCF ($a,0.515068); do_PCF ($a,0.529953); do_PCF ($a,0.542045); do_PCF ($a,0.551875); do_PCF ($a,0.559421); do_PCF ($a,0.565135); do_PCF ($a,0.569467); do_PCF ($a,0.588121); do_PCF ($a,0.605329);
$y = 0 ; $a=29; do_PCF ($a,0.447147); do_PCF ($a,0.472825); do_PCF ($a,0.495559); do_PCF ($a,0.515502); do_PCF ($a,0.532485); do_PCF ($a,0.546859); do_PCF ($a,0.558602); do_PCF ($a,0.567780); do_PCF ($a,0.574960); do_PCF ($a,0.580111); do_PCF ($a,0.583686); do_PCF ($a,0.601681); do_PCF ($a,0.618262); do_PCF ($a,0.633480);
$y = 0 ; $a=30; do_PCF ($a,0.467347); do_PCF ($a,0.492297); do_PCF ($a,0.514493); do_PCF ($a,0.533701); do_PCF ($a,0.550206); do_PCF ($a,0.563899); do_PCF ($a,0.575202); do_PCF ($a,0.584109); do_PCF ($a,0.590693); do_PCF ($a,0.595544); do_PCF ($a,0.598607); do_PCF ($a,0.615918); do_PCF ($a,0.631849); do_PCF ($a,0.646455); do_PCF ($a,0.659803);
$y = 0 ; $a=31; do_PCF ($a,0.488046); do_PCF ($a,0.512222); do_PCF ($a,0.533668); do_PCF ($a,0.552362); do_PCF ($a,0.568152); do_PCF ($a,0.581418); do_PCF ($a,0.592077); do_PCF ($a,0.600599); do_PCF ($a,0.606971); do_PCF ($a,0.611264); do_PCF ($a,0.614075); do_PCF ($a,0.630687); do_PCF ($a,0.645957); do_PCF ($a,0.659942); do_PCF ($a,0.672710); do_PCF ($a,0.684334);
$y = 0 ; $a=32; do_PCF ($a,0.509507); do_PCF ($a,0.532749); do_PCF ($a,0.553387); do_PCF ($a,0.571328); do_PCF ($a,0.586638); do_PCF ($a,0.599213); do_PCF ($a,0.609496); do_PCF ($a,0.617409); do_PCF ($a,0.623444); do_PCF ($a,0.627577); do_PCF ($a,0.629860); do_PCF ($a,0.645779); do_PCF ($a,0.660392); do_PCF ($a,0.673762); do_PCF ($a,0.685957); do_PCF ($a,0.697049); do_PCF ($a,0.707114);
$y = 0 ; $a=33; do_PCF ($a,0.531950); do_PCF ($a,0.554316); do_PCF ($a,0.573942); do_PCF ($a,0.591042); do_PCF ($a,0.605589); do_PCF ($a,0.617708); do_PCF ($a,0.627313); do_PCF ($a,0.634883); do_PCF ($a,0.640330); do_PCF ($a,0.644158); do_PCF ($a,0.646316); do_PCF ($a,0.661512); do_PCF ($a,0.675445); do_PCF ($a,0.688177); do_PCF ($a,0.699779); do_PCF ($a,0.710323); do_PCF ($a,0.719883);
$y = 0 ; $a=34; do_PCF ($a,0.554228); do_PCF ($a,0.576131); do_PCF ($a,0.594873); do_PCF ($a,0.610964); do_PCF ($a,0.624709); do_PCF ($a,0.636118); do_PCF ($a,0.645342); do_PCF ($a,0.652292); do_PCF ($a,0.657469); do_PCF ($a,0.660761); do_PCF ($a,0.662675); do_PCF ($a,0.677165); do_PCF ($a,0.690434); do_PCF ($a,0.702548); do_PCF ($a,0.713575); do_PCF ($a,0.723588); do_PCF ($a,0.732660);
$y = 0 ; $a=35; do_PCF ($a,0.576410); do_PCF ($a,0.597822); do_PCF ($a,0.616141); do_PCF ($a,0.631359); do_PCF ($a,0.644112); do_PCF ($a,0.654762); do_PCF ($a,0.663328); do_PCF ($a,0.669966); do_PCF ($a,0.674575); do_PCF ($a,0.677659); do_PCF ($a,0.679082); do_PCF ($a,0.692870); do_PCF ($a,0.705482); do_PCF ($a,0.716983); do_PCF ($a,0.727442); do_PCF ($a,0.736932); do_PCF ($a,0.745524);
$y = 0 ; $a=36; do_PCF ($a,0.598247); do_PCF ($a,0.619133); do_PCF ($a,0.637033); do_PCF ($a,0.651915); do_PCF ($a,0.663847); do_PCF ($a,0.673553); do_PCF ($a,0.681427); do_PCF ($a,0.687477); do_PCF ($a,0.691855); do_PCF ($a,0.694432); do_PCF ($a,0.695714); do_PCF ($a,0.708787); do_PCF ($a,0.720731); do_PCF ($a,0.731610); do_PCF ($a,0.741496); do_PCF ($a,0.750457); do_PCF ($a,0.758563);
$y = 0 ; $a=37; do_PCF ($a,0.619991); do_PCF ($a,0.640191); do_PCF ($a,0.657629); do_PCF ($a,0.672173); do_PCF ($a,0.683856); do_PCF ($a,0.692790); do_PCF ($a,0.699761); do_PCF ($a,0.705176); do_PCF ($a,0.709022); do_PCF ($a,0.711435); do_PCF ($a,0.712257); do_PCF ($a,0.724629); do_PCF ($a,0.735918); do_PCF ($a,0.746191); do_PCF ($a,0.755516); do_PCF ($a,0.763962); do_PCF ($a,0.771597);
$y = 0 ; $a=38; do_PCF ($a,0.641643); do_PCF ($a,0.661138); do_PCF ($a,0.677944); do_PCF ($a,0.692108); do_PCF ($a,0.703544); do_PCF ($a,0.712318); do_PCF ($a,0.718568); do_PCF ($a,0.723121); do_PCF ($a,0.726383); do_PCF ($a,0.728316); do_PCF ($a,0.729034); do_PCF ($a,0.740687); do_PCF ($a,0.751308); do_PCF ($a,0.760962); do_PCF ($a,0.769716); do_PCF ($a,0.777639); do_PCF ($a,0.784795);
$y = 0 ; $a=39; do_PCF ($a,0.663607); do_PCF ($a,0.681940); do_PCF ($a,0.698095); do_PCF ($a,0.711695); do_PCF ($a,0.722838); do_PCF ($a,0.731457); do_PCF ($a,0.737635); do_PCF ($a,0.741513); do_PCF ($a,0.743951); do_PCF ($a,0.745345); do_PCF ($a,0.745628); do_PCF ($a,0.756575); do_PCF ($a,0.766539); do_PCF ($a,0.775586); do_PCF ($a,0.783783); do_PCF ($a,0.791195); do_PCF ($a,0.797884);
$y = 0 ; $a=40; do_PCF ($a,0.685937); do_PCF ($a,0.703113); do_PCF ($a,0.718111); do_PCF ($a,0.731126); do_PCF ($a,0.741777); do_PCF ($a,0.750192); do_PCF ($a,0.756300); do_PCF ($a,0.760188); do_PCF ($a,0.761992); do_PCF ($a,0.762593); do_PCF ($a,0.762376); do_PCF ($a,0.772595); do_PCF ($a,0.781884); do_PCF ($a,0.790310); do_PCF ($a,0.797936); do_PCF ($a,0.804825); do_PCF ($a,0.811038);
$y = 0 ; $a=41; do_PCF ($a,0.708941); do_PCF ($a,0.724981); do_PCF ($a,0.738824); do_PCF ($a,0.750701); do_PCF ($a,0.760840); do_PCF ($a,0.768839); do_PCF ($a,0.774832); do_PCF ($a,0.778738); do_PCF ($a,0.780634); do_PCF ($a,0.780647); do_PCF ($a,0.779672); do_PCF ($a,0.789120); do_PCF ($a,0.797699); do_PCF ($a,0.805470); do_PCF ($a,0.812496); do_PCF ($a,0.818838); do_PCF ($a,0.824552);
$y = 0 ; $a=42; do_PCF ($a,0.732101); do_PCF ($a,0.746887); do_PCF ($a,0.759643); do_PCF ($a,0.770422); do_PCF ($a,0.779486); do_PCF ($a,0.787075); do_PCF ($a,0.792750); do_PCF ($a,0.796642); do_PCF ($a,0.798651); do_PCF ($a,0.798840); do_PCF ($a,0.797323); do_PCF ($a,0.805951); do_PCF ($a,0.813774); do_PCF ($a,0.820851); do_PCF ($a,0.827243); do_PCF ($a,0.833006); do_PCF ($a,0.838195);
$y = 0 ; $a=43; do_PCF ($a,0.755247); do_PCF ($a,0.768801); do_PCF ($a,0.780365); do_PCF ($a,0.790138); do_PCF ($a,0.798184); do_PCF ($a,0.804777); do_PCF ($a,0.810153); do_PCF ($a,0.813830); do_PCF ($a,0.815928); do_PCF ($a,0.816324); do_PCF ($a,0.815067); do_PCF ($a,0.822844); do_PCF ($a,0.829885); do_PCF ($a,0.836247); do_PCF ($a,0.841986); do_PCF ($a,0.847155); do_PCF ($a,0.851806);
$y = 0 ; $a=44; do_PCF ($a,0.778214); do_PCF ($a,0.790640); do_PCF ($a,0.801059); do_PCF ($a,0.809732); do_PCF ($a,0.816876); do_PCF ($a,0.822546); do_PCF ($a,0.827014); do_PCF ($a,0.830506); do_PCF ($a,0.832492); do_PCF ($a,0.833078); do_PCF ($a,0.832119); do_PCF ($a,0.839099); do_PCF ($a,0.845410); do_PCF ($a,0.851106); do_PCF ($a,0.856239); do_PCF ($a,0.860858); do_PCF ($a,0.865009);
$y = 0 ; $a=45; do_PCF ($a,0.795241); do_PCF ($a,0.812365); do_PCF ($a,0.821744); do_PCF ($a,0.829360); do_PCF ($a,0.835492); do_PCF ($a,0.840353); do_PCF ($a,0.843982); do_PCF ($a,0.846642); do_PCF ($a,0.848543); do_PCF ($a,0.849105); do_PCF ($a,0.848422); do_PCF ($a,0.854664); do_PCF ($a,0.860301); do_PCF ($a,0.865382); do_PCF ($a,0.869957); do_PCF ($a,0.874069); do_PCF ($a,0.877763);
$y = 0 ; $a=46; do_PCF ($a,0.815295); do_PCF ($a,0.827551); do_PCF ($a,0.842285); do_PCF ($a,0.848961); do_PCF ($a,0.854127); do_PCF ($a,0.858063); do_PCF ($a,0.860973); do_PCF ($a,0.862871); do_PCF ($a,0.864007); do_PCF ($a,0.864574); do_PCF ($a,0.863945); do_PCF ($a,0.869509); do_PCF ($a,0.874528); do_PCF ($a,0.879046); do_PCF ($a,0.883110); do_PCF ($a,0.886761); do_PCF ($a,0.890037);
$y = 0 ; $a=47; do_PCF ($a,0.835149); do_PCF ($a,0.846076); do_PCF ($a,0.855746); do_PCF ($a,0.868411); do_PCF ($a,0.872734); do_PCF ($a,0.875790); do_PCF ($a,0.877854); do_PCF ($a,0.879114); do_PCF ($a,0.879555); do_PCF ($a,0.879415); do_PCF ($a,0.878870); do_PCF ($a,0.883795); do_PCF ($a,0.888231); do_PCF ($a,0.892221); do_PCF ($a,0.895806); do_PCF ($a,0.899023); do_PCF ($a,0.901909);
$y = 0 ; $a=48; do_PCF ($a,0.854821); do_PCF ($a,0.864396); do_PCF ($a,0.872841); do_PCF ($a,0.880262); do_PCF ($a,0.891181); do_PCF ($a,0.893486); do_PCF ($a,0.894749); do_PCF ($a,0.895231); do_PCF ($a,0.895104); do_PCF ($a,0.894328); do_PCF ($a,0.893124); do_PCF ($a,0.897452); do_PCF ($a,0.901346); do_PCF ($a,0.904844); do_PCF ($a,0.907984); do_PCF ($a,0.910799); do_PCF ($a,0.913322);
$y = 0 ; $a=49; do_PCF ($a,0.874673); do_PCF ($a,0.882878); do_PCF ($a,0.890087); do_PCF ($a,0.896402); do_PCF ($a,0.901919); do_PCF ($a,0.911416); do_PCF ($a,0.912015); do_PCF ($a,0.911769); do_PCF ($a,0.910928); do_PCF ($a,0.909644); do_PCF ($a,0.907852); do_PCF ($a,0.911553); do_PCF ($a,0.914878); do_PCF ($a,0.917861); do_PCF ($a,0.920536); do_PCF ($a,0.922931); do_PCF ($a,0.925075);
$y = 0 ; $a=50; do_PCF ($a,0.894769); do_PCF ($a,0.901560); do_PCF ($a,0.907502); do_PCF ($a,0.912688); do_PCF ($a,0.917206); do_PCF ($a,0.921133); do_PCF ($a,0.929495); do_PCF ($a,0.928657); do_PCF ($a,0.927144); do_PCF ($a,0.925194); do_PCF ($a,0.922942); do_PCF ($a,0.925986); do_PCF ($a,0.928715); do_PCF ($a,0.931160); do_PCF ($a,0.933349); do_PCF ($a,0.935307); do_PCF ($a,0.937058);
$y = 0 ; $a=51; do_PCF ($a,0.915468); do_PCF ($a,0.920754); do_PCF ($a,0.925358); do_PCF ($a,0.929360); do_PCF ($a,0.932833); do_PCF ($a,0.935844); do_PCF ($a,0.938451); do_PCF ($a,0.945906); do_PCF ($a,0.943866); do_PCF ($a,0.941298); do_PCF ($a,0.938426); do_PCF ($a,0.940779); do_PCF ($a,0.942885); do_PCF ($a,0.944768); do_PCF ($a,0.946450); do_PCF ($a,0.947954); do_PCF ($a,0.949296);
$y = 0 ; $a=52; do_PCF ($a,0.936273); do_PCF ($a,0.939976); do_PCF ($a,0.943182); do_PCF ($a,0.945955); do_PCF ($a,0.948352); do_PCF ($a,0.950422); do_PCF ($a,0.952209); do_PCF ($a,0.953750); do_PCF ($a,0.960531); do_PCF ($a,0.957493); do_PCF ($a,0.954045); do_PCF ($a,0.955665); do_PCF ($a,0.957111); do_PCF ($a,0.958401); do_PCF ($a,0.959552); do_PCF ($a,0.960578); do_PCF ($a,0.961493);
$y = 0 ; $a=53; do_PCF ($a,0.957449); do_PCF ($a,0.959417); do_PCF ($a,0.961110); do_PCF ($a,0.962566); do_PCF ($a,0.963817); do_PCF ($a,0.964894); do_PCF ($a,0.965820); do_PCF ($a,0.966616); do_PCF ($a,0.967301); do_PCF ($a,0.973597); do_PCF ($a,0.969720); do_PCF ($a,0.970554); do_PCF ($a,0.971296); do_PCF ($a,0.971957); do_PCF ($a,0.972545); do_PCF ($a,0.973068); do_PCF ($a,0.973534);
$y = 0 ; $a=54; do_PCF ($a,0.979392); do_PCF ($a,0.979392); do_PCF ($a,0.979392); do_PCF ($a,0.979392); do_PCF ($a,0.979392); do_PCF ($a,0.979392); do_PCF ($a,0.979392); do_PCF ($a,0.979392); do_PCF ($a,0.979392); do_PCF ($a,0.979392); do_PCF ($a,0.985368); do_PCF ($a,0.985368); do_PCF ($a,0.985368); do_PCF ($a,0.985368); do_PCF ($a,0.985368); do_PCF ($a,0.985368); do_PCF ($a,0.985368); 
$y = 0 ; $a=55; do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); 
# MCF -- females Age 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16
$sex = "female";
$before_99 = "after";
$y = 0 ; $a=18; do_MCF ($a,0.211007); do_MCF ($a,0.227221); do_MCF ($a,0.245742);
$y = 0 ; $a=19; do_MCF ($a,0.220254); do_MCF ($a,0.236863); do_MCF ($a,0.252335); do_MCF ($a,0.270258);
$y = 0 ; $a=20; do_MCF ($a,0.230502); do_MCF ($a,0.248261); do_MCF ($a,0.264110); do_MCF ($a,0.278661); do_MCF ($a,0.295844);
$y = 0 ; $a=21; do_MCF ($a,0.242819); do_MCF ($a,0.260636); do_MCF ($a,0.277700); do_MCF ($a,0.292586); do_MCF ($a,0.306028); do_MCF ($a,0.322321);
$y = 0 ; $a=22; do_MCF ($a,0.256991); do_MCF ($a,0.274959); do_MCF ($a,0.292031); do_MCF ($a,0.308187); do_MCF ($a,0.321906); do_MCF ($a,0.334056); do_MCF ($a,0.349317);
$y = 0 ; $a=23; do_MCF ($a,0.274195); do_MCF ($a,0.292031); do_MCF ($a,0.309171); do_MCF ($a,0.325225); do_MCF ($a,0.340221); do_MCF ($a,0.352533); do_MCF ($a,0.363176); do_MCF ($a,0.377237);
$y = 0 ; $a=24; do_MCF ($a,0.292898); do_MCF ($a,0.311346); do_MCF ($a,0.328264); do_MCF ($a,0.344323); do_MCF ($a,0.359133); do_MCF ($a,0.372772); do_MCF ($a,0.383504); do_MCF ($a,0.392492); do_MCF ($a,0.405250);
$y = 0 ; $a=25; do_MCF ($a,0.313341); do_MCF ($a,0.332279); do_MCF ($a,0.349803); do_MCF ($a,0.365519); do_MCF ($a,0.380247); do_MCF ($a,0.393596); do_MCF ($a,0.405693); do_MCF ($a,0.414683); do_MCF ($a,0.421888); do_MCF ($a,0.433252);
$y = 0 ; $a=26; do_MCF ($a,0.335707); do_MCF ($a,0.354914); do_MCF ($a,0.372899); do_MCF ($a,0.389199); do_MCF ($a,0.403445); do_MCF ($a,0.416611); do_MCF ($a,0.428304); do_MCF ($a,0.438698); do_MCF ($a,0.445814); do_MCF ($a,0.451129); do_MCF ($a,0.461031);
$y = 0 ; $a=27; do_MCF ($a,0.359964); do_MCF ($a,0.379306); do_MCF ($a,0.397499); do_MCF ($a,0.414224); do_MCF ($a,0.429027); do_MCF ($a,0.441565); do_MCF ($a,0.452974); do_MCF ($a,0.462851); do_MCF ($a,0.471418); do_MCF ($a,0.476560); do_MCF ($a,0.479915); do_MCF ($a,0.491543);
$y = 0 ; $a=28; do_MCF ($a,0.384635); do_MCF ($a,0.404016); do_MCF ($a,0.422319); do_MCF ($a,0.439247); do_MCF ($a,0.454507); do_MCF ($a,0.467651); do_MCF ($a,0.478360); do_MCF ($a,0.487930); do_MCF ($a,0.495946); do_MCF ($a,0.502668); do_MCF ($a,0.505846); do_MCF ($a,0.516965); do_MCF ($a,0.527806);
$y = 0 ; $a=29; do_MCF ($a,0.410149); do_MCF ($a,0.429176); do_MCF ($a,0.447478); do_MCF ($a,0.464498); do_MCF ($a,0.479964); do_MCF ($a,0.493600); do_MCF ($a,0.504966); do_MCF ($a,0.513765); do_MCF ($a,0.521449); do_MCF ($a,0.527583); do_MCF ($a,0.532467); do_MCF ($a,0.543045); do_MCF ($a,0.553341); do_MCF ($a,0.563350);
$y = 0 ; $a=30; do_MCF ($a,0.435866); do_MCF ($a,0.454535); do_MCF ($a,0.472419); do_MCF ($a,0.489443); do_MCF ($a,0.505027); do_MCF ($a,0.518915); do_MCF ($a,0.530852); do_MCF ($a,0.540401); do_MCF ($a,0.547284); do_MCF ($a,0.553101); do_MCF ($a,0.557397); do_MCF ($a,0.567481); do_MCF ($a,0.577280); do_MCF ($a,0.586791); do_MCF ($a,0.596014);
$y = 0 ; $a=31; do_MCF ($a,0.461511); do_MCF ($a,0.479728); do_MCF ($a,0.497219); do_MCF ($a,0.513803); do_MCF ($a,0.529431); do_MCF ($a,0.543500); do_MCF ($a,0.555768); do_MCF ($a,0.565997); do_MCF ($a,0.573748); do_MCF ($a,0.578760); do_MCF ($a,0.582774); do_MCF ($a,0.592348); do_MCF ($a,0.601637); do_MCF ($a,0.610640); do_MCF ($a,0.619358); do_MCF ($a,0.627792);
$y = 0 ; $a=32; do_MCF ($a,0.487462); do_MCF ($a,0.505182); do_MCF ($a,0.522171); do_MCF ($a,0.538336); do_MCF ($a,0.553509); do_MCF ($a,0.567667); do_MCF ($a,0.580176); do_MCF ($a,0.590811); do_MCF ($a,0.599342); do_MCF ($a,0.605329); do_MCF ($a,0.608523); do_MCF ($a,0.617573); do_MCF ($a,0.626341); do_MCF ($a,0.634828); do_MCF ($a,0.643035); do_MCF ($a,0.650964); do_MCF ($a,0.658618);
$y = 0 ; $a=33; do_MCF ($a,0.514102); do_MCF ($a,0.531301); do_MCF ($a,0.547728); do_MCF ($a,0.563343); do_MCF ($a,0.578073); do_MCF ($a,0.591758); do_MCF ($a,0.604398); do_MCF ($a,0.615328); do_MCF ($a,0.624330); do_MCF ($a,0.631186); do_MCF ($a,0.635448); do_MCF ($a,0.643932); do_MCF ($a,0.652140); do_MCF ($a,0.660074); do_MCF ($a,0.667736); do_MCF ($a,0.675129); do_MCF ($a,0.682258);
$y = 0 ; $a=34; do_MCF ($a,0.540218); do_MCF ($a,0.557092); do_MCF ($a,0.572952); do_MCF ($a,0.587971); do_MCF ($a,0.602132); do_MCF ($a,0.615378); do_MCF ($a,0.627557); do_MCF ($a,0.638686); do_MCF ($a,0.648065); do_MCF ($a,0.655485); do_MCF ($a,0.660730); do_MCF ($a,0.668681); do_MCF ($a,0.676363); do_MCF ($a,0.683780); do_MCF ($a,0.690935); do_MCF ($a,0.697831); do_MCF ($a,0.704473);
$y = 0 ; $a=35; do_MCF ($a,0.565891); do_MCF ($a,0.582441); do_MCF ($a,0.597958); do_MCF ($a,0.612378); do_MCF ($a,0.625922); do_MCF ($a,0.638594); do_MCF ($a,0.650346); do_MCF ($a,0.661031); do_MCF ($a,0.670680); do_MCF ($a,0.678558); do_MCF ($a,0.684458); do_MCF ($a,0.691912); do_MCF ($a,0.699105); do_MCF ($a,0.706043); do_MCF ($a,0.712728); do_MCF ($a,0.719166); do_MCF ($a,0.725361);
$y = 0 ; $a=36; do_MCF ($a,0.591310); do_MCF ($a,0.607482); do_MCF ($a,0.622658); do_MCF ($a,0.636728); do_MCF ($a,0.649649); do_MCF ($a,0.661687); do_MCF ($a,0.672862); do_MCF ($a,0.683134); do_MCF ($a,0.692355); do_MCF ($a,0.700571); do_MCF ($a,0.707006); do_MCF ($a,0.713989); do_MCF ($a,0.720721); do_MCF ($a,0.727207); do_MCF ($a,0.733452); do_MCF ($a,0.739460); do_MCF ($a,0.745237);
$y = 0 ; $a=37; do_MCF ($a,0.616558); do_MCF ($a,0.632245); do_MCF ($a,0.647028); do_MCF ($a,0.660754); do_MCF ($a,0.673329); do_MCF ($a,0.684732); do_MCF ($a,0.695266); do_MCF ($a,0.704965); do_MCF ($a,0.713794); do_MCF ($a,0.721603); do_MCF ($a,0.728446); do_MCF ($a,0.734984); do_MCF ($a,0.741282); do_MCF ($a,0.747344); do_MCF ($a,0.753176); do_MCF ($a,0.758782); do_MCF ($a,0.764168);
$y = 0 ; $a=38; do_MCF ($a,0.641448); do_MCF ($a,0.656630); do_MCF ($a,0.670918); do_MCF ($a,0.684260); do_MCF ($a,0.696512); do_MCF ($a,0.707594); do_MCF ($a,0.717499); do_MCF ($a,0.726569); do_MCF ($a,0.734843); do_MCF ($a,0.742294); do_MCF ($a,0.748763); do_MCF ($a,0.754887); do_MCF ($a,0.760780); do_MCF ($a,0.766448); do_MCF ($a,0.771897); do_MCF ($a,0.777131); do_MCF ($a,0.782157);
$y = 0 ; $a=39; do_MCF ($a,0.666201); do_MCF ($a,0.680485); do_MCF ($a,0.694257); do_MCF ($a,0.707104); do_MCF ($a,0.718988); do_MCF ($a,0.729773); do_MCF ($a,0.739387); do_MCF ($a,0.747835); do_MCF ($a,0.755494); do_MCF ($a,0.762410); do_MCF ($a,0.768554); do_MCF ($a,0.774260); do_MCF ($a,0.779747); do_MCF ($a,0.785021); do_MCF ($a,0.790086); do_MCF ($a,0.794949); do_MCF ($a,0.799615);
$y = 0 ; $a=40; do_MCF ($a,0.690681); do_MCF ($a,0.704098); do_MCF ($a,0.716934); do_MCF ($a,0.729274); do_MCF ($a,0.740682); do_MCF ($a,0.751131); do_MCF ($a,0.760487); do_MCF ($a,0.768685); do_MCF ($a,0.775742); do_MCF ($a,0.782063); do_MCF ($a,0.787699); do_MCF ($a,0.792991); do_MCF ($a,0.798075); do_MCF ($a,0.802957); do_MCF ($a,0.807643); do_MCF ($a,0.812139); do_MCF ($a,0.816449);
$y = 0 ; $a=41; do_MCF ($a,0.714954); do_MCF ($a,0.727469); do_MCF ($a,0.739411); do_MCF ($a,0.750791); do_MCF ($a,0.761714); do_MCF ($a,0.771714); do_MCF ($a,0.780777); do_MCF ($a,0.788766); do_MCF ($a,0.795622); do_MCF ($a,0.801370); do_MCF ($a,0.806441); do_MCF ($a,0.811311); do_MCF ($a,0.815987); do_MCF ($a,0.820474); do_MCF ($a,0.824778); do_MCF ($a,0.828904); do_MCF ($a,0.832857);
$y = 0 ; $a=42; do_MCF ($a,0.738486); do_MCF ($a,0.750181); do_MCF ($a,0.761221); do_MCF ($a,0.771718); do_MCF ($a,0.781692); do_MCF ($a,0.791260); do_MCF ($a,0.799927); do_MCF ($a,0.807687); do_MCF ($a,0.814401); do_MCF ($a,0.820014); do_MCF ($a,0.824554); do_MCF ($a,0.829003); do_MCF ($a,0.833272); do_MCF ($a,0.837366); do_MCF ($a,0.841289); do_MCF ($a,0.845047); do_MCF ($a,0.848646);
$y = 0 ; $a=43; do_MCF ($a,0.761242); do_MCF ($a,0.772073); do_MCF ($a,0.782313); do_MCF ($a,0.791927); do_MCF ($a,0.801043); do_MCF ($a,0.809686); do_MCF ($a,0.817982); do_MCF ($a,0.825410); do_MCF ($a,0.831965); do_MCF ($a,0.837507); do_MCF ($a,0.841979); do_MCF ($a,0.846011); do_MCF ($a,0.849876); do_MCF ($a,0.853580); do_MCF ($a,0.857127); do_MCF ($a,0.860522); do_MCF ($a,0.863772);
$y = 0 ; $a=44; do_MCF ($a,0.783581); do_MCF ($a,0.793756); do_MCF ($a,0.803127); do_MCF ($a,0.811948); do_MCF ($a,0.820185); do_MCF ($a,0.827979); do_MCF ($a,0.835360); do_MCF ($a,0.842461); do_MCF ($a,0.848729); do_MCF ($a,0.854164); do_MCF ($a,0.858620); do_MCF ($a,0.862248); do_MCF ($a,0.865723); do_MCF ($a,0.869050); do_MCF ($a,0.872235); do_MCF ($a,0.875282); do_MCF ($a,0.878196);
$y = 0 ; $a=45; do_MCF ($a,0.801172); do_MCF ($a,0.814983); do_MCF ($a,0.823716); do_MCF ($a,0.831673); do_MCF ($a,0.839130); do_MCF ($a,0.846057); do_MCF ($a,0.852605); do_MCF ($a,0.858803); do_MCF ($a,0.864792); do_MCF ($a,0.869987); do_MCF ($a,0.874390); do_MCF ($a,0.877631); do_MCF ($a,0.880734); do_MCF ($a,0.883703); do_MCF ($a,0.886542); do_MCF ($a,0.889257); do_MCF ($a,0.891852);
$y = 0 ; $a=46; do_MCF ($a,0.822608); do_MCF ($a,0.831060); do_MCF ($a,0.843830); do_MCF ($a,0.851174); do_MCF ($a,0.857777); do_MCF ($a,0.863942); do_MCF ($a,0.869637); do_MCF ($a,0.875020); do_MCF ($a,0.880122); do_MCF ($a,0.885086); do_MCF ($a,0.889295); do_MCF ($a,0.892168); do_MCF ($a,0.894916); do_MCF ($a,0.897543); do_MCF ($a,0.900054); do_MCF ($a,0.902453); do_MCF ($a,0.904745);
$y = 0 ; $a=47; do_MCF ($a,0.843584); do_MCF ($a,0.851108); do_MCF ($a,0.858173); do_MCF ($a,0.869974); do_MCF ($a,0.876009); do_MCF ($a,0.881348); do_MCF ($a,0.886315); do_MCF ($a,0.890874); do_MCF ($a,0.895191); do_MCF ($a,0.899294); do_MCF ($a,0.903330); do_MCF ($a,0.905851); do_MCF ($a,0.908261); do_MCF ($a,0.910563); do_MCF ($a,0.912763); do_MCF ($a,0.914863); do_MCF ($a,0.916868);
$y = 0 ; $a=48; do_MCF ($a,0.864232); do_MCF ($a,0.870800); do_MCF ($a,0.876952); do_MCF ($a,0.882703); do_MCF ($a,0.893614); do_MCF ($a,0.898426); do_MCF ($a,0.902592); do_MCF ($a,0.906455); do_MCF ($a,0.909972); do_MCF ($a,0.913317); do_MCF ($a,0.916514); do_MCF ($a,0.918700); do_MCF ($a,0.920788); do_MCF ($a,0.922782); do_MCF ($a,0.924685); do_MCF ($a,0.926501); do_MCF ($a,0.928234);
$y = 0 ; $a=49; do_MCF ($a,0.884554); do_MCF ($a,0.890149); do_MCF ($a,0.895374); do_MCF ($a,0.900247); do_MCF ($a,0.904787); do_MCF ($a,0.914911); do_MCF ($a,0.918608); do_MCF ($a,0.921707); do_MCF ($a,0.924571); do_MCF ($a,0.927151); do_MCF ($a,0.929626); do_MCF ($a,0.931469); do_MCF ($a,0.933227); do_MCF ($a,0.934904); do_MCF ($a,0.936504); do_MCF ($a,0.938030); do_MCF ($a,0.939485);
$y = 0 ; $a=50; do_MCF ($a,0.904802); do_MCF ($a,0.909384); do_MCF ($a,0.913648); do_MCF ($a,0.917615); do_MCF ($a,0.921300); do_MCF ($a,0.924721); do_MCF ($a,0.934156); do_MCF ($a,0.936832); do_MCF ($a,0.938960); do_MCF ($a,0.940918); do_MCF ($a,0.942653); do_MCF ($a,0.944140); do_MCF ($a,0.945558); do_MCF ($a,0.946909); do_MCF ($a,0.948197); do_MCF ($a,0.949424); do_MCF ($a,0.950593);
$y = 0 ; $a=51; do_MCF ($a,0.924656); do_MCF ($a,0.928196); do_MCF ($a,0.931481); do_MCF ($a,0.934526); do_MCF ($a,0.937347); do_MCF ($a,0.939959); do_MCF ($a,0.942376); do_MCF ($a,0.951235); do_MCF ($a,0.953000); do_MCF ($a,0.954263); do_MCF ($a,0.955420); do_MCF ($a,0.956545); do_MCF ($a,0.957617); do_MCF ($a,0.958637); do_MCF ($a,0.959608); do_MCF ($a,0.960533); do_MCF ($a,0.961413);
$y = 0 ; $a=52; do_MCF ($a,0.944511); do_MCF ($a,0.946944); do_MCF ($a,0.949193); do_MCF ($a,0.951270); do_MCF ($a,0.953188); do_MCF ($a,0.954959); do_MCF ($a,0.956593); do_MCF ($a,0.958101); do_MCF ($a,0.966481); do_MCF ($a,0.967426); do_MCF ($a,0.967911); do_MCF ($a,0.968665); do_MCF ($a,0.969381); do_MCF ($a,0.970063); do_MCF ($a,0.970712); do_MCF ($a,0.971328); do_MCF ($a,0.971915);
$y = 0 ; $a=53; do_MCF ($a,0.964091); do_MCF ($a,0.965357); do_MCF ($a,0.966521); do_MCF ($a,0.967593); do_MCF ($a,0.968578); do_MCF ($a,0.969485); do_MCF ($a,0.970319); do_MCF ($a,0.971086); do_MCF ($a,0.971792); do_MCF ($a,0.979801); do_MCF ($a,0.980025); do_MCF ($a,0.980398); do_MCF ($a,0.980753); do_MCF ($a,0.981090); do_MCF ($a,0.981410); do_MCF ($a,0.981714); do_MCF ($a,0.982003);
$y = 0 ; $a=54; do_MCF ($a,0.984248); do_MCF ($a,0.984248); do_MCF ($a,0.984248); do_MCF ($a,0.984248); do_MCF ($a,0.984248); do_MCF ($a,0.984248); do_MCF ($a,0.984248); do_MCF ($a,0.984248); do_MCF ($a,0.984248); do_MCF ($a,0.984248); do_MCF ($a,0.992006); do_MCF ($a,0.992006); do_MCF ($a,0.992006); do_MCF ($a,0.992006); do_MCF ($a,0.992006); do_MCF ($a,0.992006); do_MCF ($a,0.992006);
$y = 0 ; $a=55; do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304);
$y = 0 ; $a=56; do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562);
$y = 0 ; $a=57; do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749);
$y = 0 ; $a=58; do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); 
$y = 0 ; $a=59; do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); 
# MCF -- males Age 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16
$sex = "male";
$before_99 = "after";
$y = 0 ; $a=18; do_MCF ($a,0.290679); do_MCF ($a,0.320922); do_MCF ($a,0.347888);
$y = 0 ; $a=19; do_MCF ($a,0.295984); do_MCF ($a,0.326243); do_MCF ($a,0.353939); do_MCF ($a,0.378135);
$y = 0 ; $a=20; do_MCF ($a,0.303564); do_MCF ($a,0.333660); do_MCF ($a,0.361287); do_MCF ($a,0.386163); do_MCF ($a,0.407426);
$y = 0 ; $a=21; do_MCF ($a,0.313386); do_MCF ($a,0.343359); do_MCF ($a,0.370703); do_MCF ($a,0.395390); do_MCF ($a,0.417263); do_MCF ($a,0.435511);
$y = 0 ; $a=22; do_MCF ($a,0.325078); do_MCF ($a,0.354982); do_MCF ($a,0.382101); do_MCF ($a,0.406384); do_MCF ($a,0.427958); do_MCF ($a,0.446763); do_MCF ($a,0.462014);
$y = 0 ; $a=23; do_MCF ($a,0.340527); do_MCF ($a,0.369999); do_MCF ($a,0.396799); do_MCF ($a,0.420590); do_MCF ($a,0.441490); do_MCF ($a,0.459756); do_MCF ($a,0.475395); do_MCF ($a,0.487625);
$y = 0 ; $a=24; do_MCF ($a,0.357238); do_MCF ($a,0.386407); do_MCF ($a,0.412646); do_MCF ($a,0.436026); do_MCF ($a,0.456343); do_MCF ($a,0.473847); do_MCF ($a,0.488886); do_MCF ($a,0.501508); do_MCF ($a,0.510912);
$y = 0 ; $a=25; do_MCF ($a,0.375070); do_MCF ($a,0.403785); do_MCF ($a,0.429628); do_MCF ($a,0.452348); do_MCF ($a,0.472194); do_MCF ($a,0.489055); do_MCF ($a,0.503277); do_MCF ($a,0.515268); do_MCF ($a,0.525090); do_MCF ($a,0.531908);
$y = 0 ; $a=26; do_MCF ($a,0.394077); do_MCF ($a,0.422127); do_MCF ($a,0.447415); do_MCF ($a,0.469674); do_MCF ($a,0.488791); do_MCF ($a,0.505149); do_MCF ($a,0.518695); do_MCF ($a,0.529837); do_MCF ($a,0.539016); do_MCF ($a,0.546294); do_MCF ($a,0.550788);
$y = 0 ; $a=27; do_MCF ($a,0.413777); do_MCF ($a,0.441278); do_MCF ($a,0.465808); do_MCF ($a,0.487468); do_MCF ($a,0.506111); do_MCF ($a,0.521720); do_MCF ($a,0.534773); do_MCF ($a,0.545244); do_MCF ($a,0.553577); do_MCF ($a,0.560229); do_MCF ($a,0.565244); do_MCF ($a,0.584951);
$y = 0 ; $a=28; do_MCF ($a,0.433667); do_MCF ($a,0.460440); do_MCF ($a,0.484414); do_MCF ($a,0.505317); do_MCF ($a,0.523401); do_MCF ($a,0.538598); do_MCF ($a,0.550948); do_MCF ($a,0.560992); do_MCF ($a,0.568708); do_MCF ($a,0.574557); do_MCF ($a,0.578999); do_MCF ($a,0.598047); do_MCF ($a,0.615618);
$y = 0 ; $a=29; do_MCF ($a,0.453864); do_MCF ($a,0.480075); do_MCF ($a,0.503282); do_MCF ($a,0.523641); do_MCF ($a,0.540980); do_MCF ($a,0.555659); do_MCF ($a,0.567654); do_MCF ($a,0.577032); do_MCF ($a,0.584375); do_MCF ($a,0.589649); do_MCF ($a,0.593319); do_MCF ($a,0.611696); do_MCF ($a,0.628629); do_MCF ($a,0.644171);
$y = 0 ; $a=30; do_MCF ($a,0.474258); do_MCF ($a,0.499730); do_MCF ($a,0.522392); do_MCF ($a,0.542005); do_MCF ($a,0.558860); do_MCF ($a,0.572844); do_MCF ($a,0.584392); do_MCF ($a,0.593494); do_MCF ($a,0.600229); do_MCF ($a,0.605195); do_MCF ($a,0.608341); do_MCF ($a,0.626023); do_MCF ($a,0.642295); do_MCF ($a,0.657215); do_MCF ($a,0.670850);
$y = 0 ; $a=31; do_MCF ($a,0.495147); do_MCF ($a,0.519832); do_MCF ($a,0.541733); do_MCF ($a,0.560825); do_MCF ($a,0.576952); do_MCF ($a,0.590504); do_MCF ($a,0.601395); do_MCF ($a,0.610105); do_MCF ($a,0.616623); do_MCF ($a,0.621020); do_MCF ($a,0.623906); do_MCF ($a,0.640877); do_MCF ($a,0.656477); do_MCF ($a,0.670764); do_MCF ($a,0.683808); do_MCF ($a,0.695684);
$y = 0 ; $a=32; do_MCF ($a,0.516807); do_MCF ($a,0.540542); do_MCF ($a,0.561621); do_MCF ($a,0.579946); do_MCF ($a,0.595586); do_MCF ($a,0.608435); do_MCF ($a,0.618943); do_MCF ($a,0.627032); do_MCF ($a,0.633205); do_MCF ($a,0.637437); do_MCF ($a,0.639784); do_MCF ($a,0.656049); do_MCF ($a,0.670980); do_MCF ($a,0.684641); do_MCF ($a,0.697102); do_MCF ($a,0.708435); do_MCF ($a,0.718720);
$y = 0 ; $a=33; do_MCF ($a,0.539463); do_MCF ($a,0.562308); do_MCF ($a,0.582355); do_MCF ($a,0.599823); do_MCF ($a,0.614686); do_MCF ($a,0.627070); do_MCF ($a,0.636887); do_MCF ($a,0.644626); do_MCF ($a,0.650199); do_MCF ($a,0.654119); do_MCF ($a,0.656337); do_MCF ($a,0.671865); do_MCF ($a,0.686103); do_MCF ($a,0.699115); do_MCF ($a,0.710971); do_MCF ($a,0.721746); do_MCF ($a,0.731516);
$y = 0 ; $a=34; do_MCF ($a,0.561931); do_MCF ($a,0.584305); do_MCF ($a,0.603451); do_MCF ($a,0.619890); do_MCF ($a,0.633935); do_MCF ($a,0.645595); do_MCF ($a,0.655023); do_MCF ($a,0.662131); do_MCF ($a,0.667427); do_MCF ($a,0.670800); do_MCF ($a,0.672766); do_MCF ($a,0.687575); do_MCF ($a,0.701137); do_MCF ($a,0.713517); do_MCF ($a,0.724788); do_MCF ($a,0.735022); do_MCF ($a,0.744294);
$y = 0 ; $a=35; do_MCF ($a,0.584283); do_MCF ($a,0.606159); do_MCF ($a,0.624874); do_MCF ($a,0.640422); do_MCF ($a,0.653453); do_MCF ($a,0.664337); do_MCF ($a,0.673094); do_MCF ($a,0.679884); do_MCF ($a,0.684599); do_MCF ($a,0.687760); do_MCF ($a,0.689223); do_MCF ($a,0.703317); do_MCF ($a,0.716208); do_MCF ($a,0.727964); do_MCF ($a,0.738655); do_MCF ($a,0.748355); do_MCF ($a,0.757137);
$y = 0 ; $a=36; do_MCF ($a,0.606251); do_MCF ($a,0.627593); do_MCF ($a,0.645882); do_MCF ($a,0.661088); do_MCF ($a,0.673280); do_MCF ($a,0.683200); do_MCF ($a,0.691249); do_MCF ($a,0.697437); do_MCF ($a,0.701918); do_MCF ($a,0.704559); do_MCF ($a,0.705879); do_MCF ($a,0.719243); do_MCF ($a,0.731452); do_MCF ($a,0.742574); do_MCF ($a,0.752679); do_MCF ($a,0.761839); do_MCF ($a,0.770127);
$y = 0 ; $a=37; do_MCF ($a,0.628097); do_MCF ($a,0.648741); do_MCF ($a,0.666561); do_MCF ($a,0.681423); do_MCF ($a,0.693361); do_MCF ($a,0.702490); do_MCF ($a,0.709617); do_MCF ($a,0.715154); do_MCF ($a,0.719091); do_MCF ($a,0.721565); do_MCF ($a,0.722413); do_MCF ($a,0.735062); do_MCF ($a,0.746603); do_MCF ($a,0.757106); do_MCF ($a,0.766640); do_MCF ($a,0.775275); do_MCF ($a,0.783081);
$y = 0 ; $a=38; do_MCF ($a,0.649812); do_MCF ($a,0.669739); do_MCF ($a,0.686916); do_MCF ($a,0.701392); do_MCF ($a,0.713078); do_MCF ($a,0.722045); do_MCF ($a,0.728432); do_MCF ($a,0.733088); do_MCF ($a,0.736427); do_MCF ($a,0.738410); do_MCF ($a,0.739151); do_MCF ($a,0.751066); do_MCF ($a,0.761926); do_MCF ($a,0.771796); do_MCF ($a,0.780748); do_MCF ($a,0.788848); do_MCF ($a,0.796165);
$y = 0 ; $a=39; do_MCF ($a,0.671844); do_MCF ($a,0.690587); do_MCF ($a,0.707102); do_MCF ($a,0.721003); do_MCF ($a,0.732393); do_MCF ($a,0.741201); do_MCF ($a,0.747515); do_MCF ($a,0.751479); do_MCF ($a,0.753974); do_MCF ($a,0.755404); do_MCF ($a,0.755700); do_MCF ($a,0.766894); do_MCF ($a,0.777083); do_MCF ($a,0.786335); do_MCF ($a,0.794717); do_MCF ($a,0.802296); do_MCF ($a,0.809136);
$y = 0 ; $a=40; do_MCF ($a,0.694247); do_MCF ($a,0.711811); do_MCF ($a,0.727146); do_MCF ($a,0.740452); do_MCF ($a,0.751341); do_MCF ($a,0.759941); do_MCF ($a,0.766184); do_MCF ($a,0.770157); do_MCF ($a,0.772002); do_MCF ($a,0.772619); do_MCF ($a,0.772403); do_MCF ($a,0.782854); do_MCF ($a,0.792354); do_MCF ($a,0.800971); do_MCF ($a,0.808770); do_MCF ($a,0.815815); do_MCF ($a,0.822169);
$y = 0 ; $a=41; do_MCF ($a,0.717278); do_MCF ($a,0.733683); do_MCF ($a,0.747839); do_MCF ($a,0.759983); do_MCF ($a,0.770349); do_MCF ($a,0.778525); do_MCF ($a,0.784649); do_MCF ($a,0.788640); do_MCF ($a,0.790577); do_MCF ($a,0.790590); do_MCF ($a,0.789597); do_MCF ($a,0.799260); do_MCF ($a,0.808033); do_MCF ($a,0.815980); do_MCF ($a,0.823165); do_MCF ($a,0.829650); do_MCF ($a,0.835494);
$y = 0 ; $a=42; do_MCF ($a,0.740460); do_MCF ($a,0.755586); do_MCF ($a,0.768633); do_MCF ($a,0.779656); do_MCF ($a,0.788922); do_MCF ($a,0.796680); do_MCF ($a,0.802479); do_MCF ($a,0.806454); do_MCF ($a,0.808505); do_MCF ($a,0.808697); do_MCF ($a,0.807147); do_MCF ($a,0.815970); do_MCF ($a,0.823969); do_MCF ($a,0.831206); do_MCF ($a,0.837742); do_MCF ($a,0.843635); do_MCF ($a,0.848941);
$y = 0 ; $a=43; do_MCF ($a,0.763617); do_MCF ($a,0.777486); do_MCF ($a,0.789315); do_MCF ($a,0.799311); do_MCF ($a,0.807538); do_MCF ($a,0.814276); do_MCF ($a,0.819770); do_MCF ($a,0.823525); do_MCF ($a,0.825665); do_MCF ($a,0.826067); do_MCF ($a,0.824780); do_MCF ($a,0.832732); do_MCF ($a,0.839931); do_MCF ($a,0.846435); do_MCF ($a,0.852303); do_MCF ($a,0.857589); do_MCF ($a,0.862343);
$y = 0 ; $a=44; do_MCF ($a,0.786553); do_MCF ($a,0.799271); do_MCF ($a,0.809932); do_MCF ($a,0.818804); do_MCF ($a,0.826109); do_MCF ($a,0.831905); do_MCF ($a,0.836470); do_MCF ($a,0.840036); do_MCF ($a,0.842061); do_MCF ($a,0.842656); do_MCF ($a,0.841671); do_MCF ($a,0.848807); do_MCF ($a,0.855258); do_MCF ($a,0.861081); do_MCF ($a,0.866327); do_MCF ($a,0.871049); do_MCF ($a,0.875292);
$y = 0 ; $a=45; do_MCF ($a,0.803413); do_MCF ($a,0.820892); do_MCF ($a,0.830493); do_MCF ($a,0.838287); do_MCF ($a,0.844558); do_MCF ($a,0.849529); do_MCF ($a,0.853236); do_MCF ($a,0.855951); do_MCF ($a,0.857888); do_MCF ($a,0.858457); do_MCF ($a,0.857754); do_MCF ($a,0.864133); do_MCF ($a,0.869893); do_MCF ($a,0.875086); do_MCF ($a,0.879760); do_MCF ($a,0.883963); do_MCF ($a,0.887737);
$y = 0 ; $a=46; do_MCF ($a,0.823291); do_MCF ($a,0.835815); do_MCF ($a,0.850844); do_MCF ($a,0.857679); do_MCF ($a,0.862966); do_MCF ($a,0.866992); do_MCF ($a,0.869966); do_MCF ($a,0.871903); do_MCF ($a,0.873058); do_MCF ($a,0.873631); do_MCF ($a,0.872982); do_MCF ($a,0.878666); do_MCF ($a,0.883792); do_MCF ($a,0.888408); do_MCF ($a,0.892560); do_MCF ($a,0.896289); do_MCF ($a,0.899635);
$y = 0 ; $a=47; do_MCF ($a,0.842899); do_MCF ($a,0.854060); do_MCF ($a,0.863936); do_MCF ($a,0.876843); do_MCF ($a,0.881272); do_MCF ($a,0.884402); do_MCF ($a,0.886513); do_MCF ($a,0.887798); do_MCF ($a,0.888245); do_MCF ($a,0.888096); do_MCF ($a,0.887532); do_MCF ($a,0.892560); do_MCF ($a,0.897089); do_MCF ($a,0.901163); do_MCF ($a,0.904824); do_MCF ($a,0.908109); do_MCF ($a,0.911054);
$y = 0 ; $a=48; do_MCF ($a,0.862239); do_MCF ($a,0.872014); do_MCF ($a,0.880634); do_MCF ($a,0.888208); do_MCF ($a,0.899326); do_MCF ($a,0.901692); do_MCF ($a,0.902988); do_MCF ($a,0.903482); do_MCF ($a,0.903350); do_MCF ($a,0.902551); do_MCF ($a,0.901315); do_MCF ($a,0.905732); do_MCF ($a,0.909705); do_MCF ($a,0.913275); do_MCF ($a,0.916479); do_MCF ($a,0.919351); do_MCF ($a,0.921925);
$y = 0 ; $a=49; do_MCF ($a,0.881691); do_MCF ($a,0.890060); do_MCF ($a,0.897414); do_MCF ($a,0.903855); do_MCF ($a,0.909483); do_MCF ($a,0.919143); do_MCF ($a,0.919766); do_MCF ($a,0.919520); do_MCF ($a,0.918662); do_MCF ($a,0.917348); do_MCF ($a,0.915512); do_MCF ($a,0.919287); do_MCF ($a,0.922677); do_MCF ($a,0.925719); do_MCF ($a,0.928446); do_MCF ($a,0.930889); do_MCF ($a,0.933075);
$y = 0 ; $a=50; do_MCF ($a,0.901318); do_MCF ($a,0.908239); do_MCF ($a,0.914295); do_MCF ($a,0.919581); do_MCF ($a,0.924185); do_MCF ($a,0.928188); do_MCF ($a,0.936686); do_MCF ($a,0.935842); do_MCF ($a,0.934303); do_MCF ($a,0.932312); do_MCF ($a,0.930010); do_MCF ($a,0.933112); do_MCF ($a,0.935893); do_MCF ($a,0.938384); do_MCF ($a,0.940614); do_MCF ($a,0.942609); do_MCF ($a,0.944393);
$y = 0 ; $a=51; do_MCF ($a,0.921379); do_MCF ($a,0.926761); do_MCF ($a,0.931448); do_MCF ($a,0.935521); do_MCF ($a,0.939057); do_MCF ($a,0.942121); do_MCF ($a,0.944775); do_MCF ($a,0.952343); do_MCF ($a,0.950274); do_MCF ($a,0.947659); do_MCF ($a,0.944729); do_MCF ($a,0.947125); do_MCF ($a,0.949268); do_MCF ($a,0.951184); do_MCF ($a,0.952897); do_MCF ($a,0.954427); do_MCF ($a,0.955793);
$y = 0 ; $a=52; do_MCF ($a,0.941477); do_MCF ($a,0.945241); do_MCF ($a,0.948500); do_MCF ($a,0.951319); do_MCF ($a,0.953756); do_MCF ($a,0.955861); do_MCF ($a,0.957677); do_MCF ($a,0.959244); do_MCF ($a,0.966120); do_MCF ($a,0.963036); do_MCF ($a,0.959528); do_MCF ($a,0.961174); do_MCF ($a,0.962644); do_MCF ($a,0.963955); do_MCF ($a,0.965125); do_MCF ($a,0.966168); do_MCF ($a,0.967098);
$y = 0 ; $a=53; do_MCF ($a,0.961888); do_MCF ($a,0.963886); do_MCF ($a,0.965604); do_MCF ($a,0.967082); do_MCF ($a,0.968353); do_MCF ($a,0.969446); do_MCF ($a,0.970386); do_MCF ($a,0.971194); do_MCF ($a,0.971889); do_MCF ($a,0.978269); do_MCF ($a,0.974333); do_MCF ($a,0.975179); do_MCF ($a,0.975933); do_MCF ($a,0.976604); do_MCF ($a,0.977201); do_MCF ($a,0.977732); do_MCF ($a,0.978205);
$y = 0 ; $a=54; do_MCF ($a,0.983039); do_MCF ($a,0.983039); do_MCF ($a,0.983039); do_MCF ($a,0.983039); do_MCF ($a,0.983039); do_MCF ($a,0.983039); do_MCF ($a,0.983039); do_MCF ($a,0.983039); do_MCF ($a,0.983039); do_MCF ($a,0.983039); do_MCF ($a,0.989090); do_MCF ($a,0.989090); do_MCF ($a,0.989090); do_MCF ($a,0.989090); do_MCF ($a,0.989090); do_MCF ($a,0.989090); do_MCF ($a,0.989090);
$y = 0 ; $a=55; do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797);
$y = 0 ; $a=56; do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097);
$y = 0 ; $a=57; do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409);
$y = 0 ; $a=58; do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); 
$y = 0 ; $a=59; do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); 
# ABF -- females Age 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16
$sex = "female";
$before_99 = "after";
$y = 0 ; $a=18; do_ABF ($a,0.331041); do_ABF ($a,0.334860); do_ABF ($a,0.339164);
$y = 0 ; $a=19; do_ABF ($a,0.341496); do_ABF ($a,0.345469); do_ABF ($a,0.349148); do_ABF ($a,0.353359);
$y = 0 ; $a=20; do_ABF ($a,0.352509); do_ABF ($a,0.356809); do_ABF ($a,0.360636); do_ABF ($a,0.364126); do_ABF ($a,0.368205);
$y = 0 ; $a=21; do_ABF ($a,0.364338); do_ABF ($a,0.368717); do_ABF ($a,0.372888); do_ABF ($a,0.376514); do_ABF ($a,0.379762); do_ABF ($a,0.383667);
$y = 0 ; $a=22; do_ABF ($a,0.376946); do_ABF ($a,0.381424); do_ABF ($a,0.385659); do_ABF ($a,0.389645); do_ABF ($a,0.393011); do_ABF ($a,0.395962); do_ABF ($a,0.399654);
$y = 0 ; $a=23; do_ABF ($a,0.390688); do_ABF ($a,0.395196); do_ABF ($a,0.399506); do_ABF ($a,0.403523); do_ABF ($a,0.407251); do_ABF ($a,0.410288); do_ABF ($a,0.412876); do_ABF ($a,0.416304);
$y = 0 ; $a=24; do_ABF ($a,0.405212); do_ABF ($a,0.409924); do_ABF ($a,0.414237); do_ABF ($a,0.418310); do_ABF ($a,0.422045); do_ABF ($a,0.425458); do_ABF ($a,0.428109); do_ABF ($a,0.430285); do_ABF ($a,0.433415);
$y = 0 ; $a=25; do_ABF ($a,0.420613); do_ABF ($a,0.425500); do_ABF ($a,0.430015); do_ABF ($a,0.434055); do_ABF ($a,0.437819); do_ABF ($a,0.441206); do_ABF ($a,0.444247); do_ABF ($a,0.446458); do_ABF ($a,0.448174); do_ABF ($a,0.450973);
$y = 0 ; $a=26; do_ABF ($a,0.436973); do_ABF ($a,0.441980); do_ABF ($a,0.446660); do_ABF ($a,0.450894); do_ABF ($a,0.454582); do_ABF ($a,0.457967); do_ABF ($a,0.460945); do_ABF ($a,0.463559); do_ABF ($a,0.465280); do_ABF ($a,0.466493); do_ABF ($a,0.468933);
$y = 0 ; $a=27; do_ABF ($a,0.454289); do_ABF ($a,0.459381); do_ABF ($a,0.464162); do_ABF ($a,0.468549); do_ABF ($a,0.472421); do_ABF ($a,0.475684); do_ABF ($a,0.478626); do_ABF ($a,0.481139); do_ABF ($a,0.483279); do_ABF ($a,0.484468); do_ABF ($a,0.485143); do_ABF ($a,0.488104);
$y = 0 ; $a=28; do_ABF ($a,0.472189); do_ABF ($a,0.477341); do_ABF ($a,0.482198); do_ABF ($a,0.486682); do_ABF ($a,0.490715); do_ABF ($a,0.494174); do_ABF ($a,0.496968); do_ABF ($a,0.499433); do_ABF ($a,0.501456); do_ABF ($a,0.503104); do_ABF ($a,0.503748); do_ABF ($a,0.506613); do_ABF ($a,0.509402);
$y = 0 ; $a=29; do_ABF ($a,0.490776); do_ABF ($a,0.495887); do_ABF ($a,0.500790); do_ABF ($a,0.505343); do_ABF ($a,0.509471); do_ABF ($a,0.513099); do_ABF ($a,0.516102); do_ABF ($a,0.518391); do_ABF ($a,0.520354); do_ABF ($a,0.521867); do_ABF ($a,0.523011); do_ABF ($a,0.525766); do_ABF ($a,0.528443); do_ABF ($a,0.531043);
$y = 0 ; $a=30; do_ABF ($a,0.509874); do_ABF ($a,0.514940); do_ABF ($a,0.519781); do_ABF ($a,0.524379); do_ABF ($a,0.528581); do_ABF ($a,0.532316); do_ABF ($a,0.535509); do_ABF ($a,0.538034); do_ABF ($a,0.539803); do_ABF ($a,0.541253); do_ABF ($a,0.542254); do_ABF ($a,0.544910); do_ABF ($a,0.547488); do_ABF ($a,0.549987); do_ABF ($a,0.552408);
$y = 0 ; $a=31; do_ABF ($a,0.529404); do_ABF ($a,0.534399); do_ABF ($a,0.539184); do_ABF ($a,0.543711); do_ABF ($a,0.547968); do_ABF ($a,0.551791); do_ABF ($a,0.555112); do_ABF ($a,0.557857); do_ABF ($a,0.559897); do_ABF ($a,0.561144); do_ABF ($a,0.562086); do_ABF ($a,0.564636); do_ABF ($a,0.567107); do_ABF ($a,0.569500); do_ABF ($a,0.571814); do_ABF ($a,0.574050);
$y = 0 ; $a=32; do_ABF ($a,0.549475); do_ABF ($a,0.554385); do_ABF ($a,0.559082); do_ABF ($a,0.563541); do_ABF ($a,0.567718); do_ABF ($a,0.571607); do_ABF ($a,0.575032); do_ABF ($a,0.577925); do_ABF ($a,0.580215); do_ABF ($a,0.581765); do_ABF ($a,0.582490); do_ABF ($a,0.584926); do_ABF ($a,0.587284); do_ABF ($a,0.589563); do_ABF ($a,0.591765); do_ABF ($a,0.593891); do_ABF ($a,0.595941);
$y = 0 ; $a=33; do_ABF ($a,0.570224); do_ABF ($a,0.575039); do_ABF ($a,0.579627); do_ABF ($a,0.583980); do_ABF ($a,0.588077); do_ABF ($a,0.591876); do_ABF ($a,0.595376); do_ABF ($a,0.598388); do_ABF ($a,0.600844); do_ABF ($a,0.602671); do_ABF ($a,0.603730); do_ABF ($a,0.606035); do_ABF ($a,0.608263); do_ABF ($a,0.610415); do_ABF ($a,0.612491); do_ABF ($a,0.614492); do_ABF ($a,0.616421);
$y = 0 ; $a=34; do_ABF ($a,0.591314); do_ABF ($a,0.596081); do_ABF ($a,0.600557); do_ABF ($a,0.604787); do_ABF ($a,0.608768); do_ABF ($a,0.612484); do_ABF ($a,0.615893); do_ABF ($a,0.618998); do_ABF ($a,0.621595); do_ABF ($a,0.623617); do_ABF ($a,0.624990); do_ABF ($a,0.627171); do_ABF ($a,0.629277); do_ABF ($a,0.631308); do_ABF ($a,0.633266); do_ABF ($a,0.635152); do_ABF ($a,0.636966);
$y = 0 ; $a=35; do_ABF ($a,0.612789); do_ABF ($a,0.617505); do_ABF ($a,0.621925); do_ABF ($a,0.626029); do_ABF ($a,0.629877); do_ABF ($a,0.633470); do_ABF ($a,0.636794); do_ABF ($a,0.639808); do_ABF ($a,0.642518); do_ABF ($a,0.644706); do_ABF ($a,0.646300); do_ABF ($a,0.648366); do_ABF ($a,0.650357); do_ABF ($a,0.652276); do_ABF ($a,0.654124); do_ABF ($a,0.655903); do_ABF ($a,0.657613);
$y = 0 ; $a=36; do_ABF ($a,0.634714); do_ABF ($a,0.639361); do_ABF ($a,0.643721); do_ABF ($a,0.647763); do_ABF ($a,0.651472); do_ABF ($a,0.654921); do_ABF ($a,0.658115); do_ABF ($a,0.661044); do_ABF ($a,0.663663); do_ABF ($a,0.665983); do_ABF ($a,0.667767); do_ABF ($a,0.669721); do_ABF ($a,0.671603); do_ABF ($a,0.673416); do_ABF ($a,0.675160); do_ABF ($a,0.676836); do_ABF ($a,0.678447);
$y = 0 ; $a=37; do_ABF ($a,0.657113); do_ABF ($a,0.661659); do_ABF ($a,0.665942); do_ABF ($a,0.669918); do_ABF ($a,0.673561); do_ABF ($a,0.676862); do_ABF ($a,0.679904); do_ABF ($a,0.682698); do_ABF ($a,0.685233); do_ABF ($a,0.687462); do_ABF ($a,0.689400); do_ABF ($a,0.691248); do_ABF ($a,0.693027); do_ABF ($a,0.694738); do_ABF ($a,0.696384); do_ABF ($a,0.697964); do_ABF ($a,0.699482);
$y = 0 ; $a=38; do_ABF ($a,0.679967); do_ABF ($a,0.684401); do_ABF ($a,0.688574); do_ABF ($a,0.692471); do_ABF ($a,0.696051); do_ABF ($a,0.699288); do_ABF ($a,0.702177); do_ABF ($a,0.704816); do_ABF ($a,0.707216); do_ABF ($a,0.709366); do_ABF ($a,0.711218); do_ABF ($a,0.712967); do_ABF ($a,0.714649); do_ABF ($a,0.716266); do_ABF ($a,0.717819); do_ABF ($a,0.719311); do_ABF ($a,0.720742);
$y = 0 ; $a=39; do_ABF ($a,0.703292); do_ABF ($a,0.707504); do_ABF ($a,0.711557); do_ABF ($a,0.715339); do_ABF ($a,0.718839); do_ABF ($a,0.722016); do_ABF ($a,0.724847); do_ABF ($a,0.727329); do_ABF ($a,0.729570); do_ABF ($a,0.731585); do_ABF ($a,0.733364); do_ABF ($a,0.735010); do_ABF ($a,0.736592); do_ABF ($a,0.738112); do_ABF ($a,0.739571); do_ABF ($a,0.740970); do_ABF ($a,0.742312);
$y = 0 ; $a=40; do_ABF ($a,0.727047); do_ABF ($a,0.731039); do_ABF ($a,0.734851); do_ABF ($a,0.738511); do_ABF ($a,0.741896); do_ABF ($a,0.744999); do_ABF ($a,0.747778); do_ABF ($a,0.750209); do_ABF ($a,0.752293); do_ABF ($a,0.754151); do_ABF ($a,0.755797); do_ABF ($a,0.757338); do_ABF ($a,0.758819); do_ABF ($a,0.760239); do_ABF ($a,0.761602); do_ABF ($a,0.762909); do_ABF ($a,0.764161);
$y = 0 ; $a=41; do_ABF ($a,0.750136); do_ABF ($a,0.753893); do_ABF ($a,0.757471); do_ABF ($a,0.760877); do_ABF ($a,0.764142); do_ABF ($a,0.767134); do_ABF ($a,0.769847); do_ABF ($a,0.772238); do_ABF ($a,0.774284); do_ABF ($a,0.775988); do_ABF ($a,0.777480); do_ABF ($a,0.778912); do_ABF ($a,0.780286); do_ABF ($a,0.781604); do_ABF ($a,0.782867); do_ABF ($a,0.784078); do_ABF ($a,0.785237);
$y = 0 ; $a=42; do_ABF ($a,0.773445); do_ABF ($a,0.776985); do_ABF ($a,0.780323); do_ABF ($a,0.783491); do_ABF ($a,0.786499); do_ABF ($a,0.789382); do_ABF ($a,0.791997); do_ABF ($a,0.794340); do_ABF ($a,0.796364); do_ABF ($a,0.798047); do_ABF ($a,0.799393); do_ABF ($a,0.800713); do_ABF ($a,0.801978); do_ABF ($a,0.803192); do_ABF ($a,0.804354); do_ABF ($a,0.805467); do_ABF ($a,0.806532);
$y = 0 ; $a=43; do_ABF ($a,0.796954); do_ABF ($a,0.800261); do_ABF ($a,0.803383); do_ABF ($a,0.806311); do_ABF ($a,0.809083); do_ABF ($a,0.811710); do_ABF ($a,0.814232); do_ABF ($a,0.816493); do_ABF ($a,0.818488); do_ABF ($a,0.820170); do_ABF ($a,0.821515); do_ABF ($a,0.822721); do_ABF ($a,0.823877); do_ABF ($a,0.824984); do_ABF ($a,0.826044); do_ABF ($a,0.827058); do_ABF ($a,0.828028);
$y = 0 ; $a=44; do_ABF ($a,0.820838); do_ABF ($a,0.823962); do_ABF ($a,0.826844); do_ABF ($a,0.829552); do_ABF ($a,0.832079); do_ABF ($a,0.834468); do_ABF ($a,0.836730); do_ABF ($a,0.838907); do_ABF ($a,0.840832); do_ABF ($a,0.842499); do_ABF ($a,0.843858); do_ABF ($a,0.844953); do_ABF ($a,0.846000); do_ABF ($a,0.847003); do_ABF ($a,0.847963); do_ABF ($a,0.848880); do_ABF ($a,0.849758);
$y = 0 ; $a=45; do_ABF ($a,0.844012); do_ABF ($a,0.848032); do_ABF ($a,0.850731); do_ABF ($a,0.853195); do_ABF ($a,0.855501); do_ABF ($a,0.857642); do_ABF ($a,0.859664); do_ABF ($a,0.861579); do_ABF ($a,0.863432); do_ABF ($a,0.865041); do_ABF ($a,0.866402); do_ABF ($a,0.867387); do_ABF ($a,0.868330); do_ABF ($a,0.869232); do_ABF ($a,0.870095); do_ABF ($a,0.870919); do_ABF ($a,0.871707);
$y = 0 ; $a=46; do_ABF ($a,0.868621); do_ABF ($a,0.871251); do_ABF ($a,0.874972); do_ABF ($a,0.877256); do_ABF ($a,0.879316); do_ABF ($a,0.881236); do_ABF ($a,0.883008); do_ABF ($a,0.884682); do_ABF ($a,0.886271); do_ABF ($a,0.887822); do_ABF ($a,0.889137); do_ABF ($a,0.890017); do_ABF ($a,0.890859); do_ABF ($a,0.891664); do_ABF ($a,0.892433); do_ABF ($a,0.893167); do_ABF ($a,0.893869);
$y = 0 ; $a=47; do_ABF ($a,0.893583); do_ABF ($a,0.895939); do_ABF ($a,0.898150); do_ABF ($a,0.901596); do_ABF ($a,0.903485); do_ABF ($a,0.905162); do_ABF ($a,0.906719); do_ABF ($a,0.908147); do_ABF ($a,0.909499); do_ABF ($a,0.910787); do_ABF ($a,0.912061); do_ABF ($a,0.912840); do_ABF ($a,0.913584); do_ABF ($a,0.914295); do_ABF ($a,0.914974); do_ABF ($a,0.915622); do_ABF ($a,0.916241);
$y = 0 ; $a=48; do_ABF ($a,0.918960); do_ABF ($a,0.921028); do_ABF ($a,0.922964); do_ABF ($a,0.924772); do_ABF ($a,0.927968); do_ABF ($a,0.929484); do_ABF ($a,0.930801); do_ABF ($a,0.932019); do_ABF ($a,0.933128); do_ABF ($a,0.934182); do_ABF ($a,0.935194); do_ABF ($a,0.935875); do_ABF ($a,0.936525); do_ABF ($a,0.937146); do_ABF ($a,0.937738); do_ABF ($a,0.938303); do_ABF ($a,0.938842);
$y = 0 ; $a=49; do_ABF ($a,0.944726); do_ABF ($a,0.946497); do_ABF ($a,0.948150); do_ABF ($a,0.949691); do_ABF ($a,0.951126); do_ABF ($a,0.954105); do_ABF ($a,0.955277); do_ABF ($a,0.956262); do_ABF ($a,0.957171); do_ABF ($a,0.957988); do_ABF ($a,0.958772); do_ABF ($a,0.959351); do_ABF ($a,0.959902); do_ABF ($a,0.960428); do_ABF ($a,0.960930); do_ABF ($a,0.961409); do_ABF ($a,0.961865);
$y = 0 ; $a=50; do_ABF ($a,0.970983); do_ABF ($a,0.972440); do_ABF ($a,0.973795); do_ABF ($a,0.975055); do_ABF ($a,0.976225); do_ABF ($a,0.977312); do_ABF ($a,0.980107); do_ABF ($a,0.980960); do_ABF ($a,0.981640); do_ABF ($a,0.982263); do_ABF ($a,0.982813); do_ABF ($a,0.983283); do_ABF ($a,0.983731); do_ABF ($a,0.984158); do_ABF ($a,0.984564); do_ABF ($a,0.984952); do_ABF ($a,0.985321);
$y = 0 ; $a=51; do_ABF ($a,0.997627); do_ABF ($a,0.998757); do_ABF ($a,0.999806); do_ABF ($a,1.000777); do_ABF ($a,1.001677); do_ABF ($a,1.002510); do_ABF ($a,1.003281); do_ABF ($a,1.005931); do_ABF ($a,1.006497); do_ABF ($a,1.006901); do_ABF ($a,1.007269); do_ABF ($a,1.007626); do_ABF ($a,1.007967); do_ABF ($a,1.008291); do_ABF ($a,1.008600); do_ABF ($a,1.008893); do_ABF ($a,1.009173);
$y = 0 ; $a=52; do_ABF ($a,1.024813); do_ABF ($a,1.025592); do_ABF ($a,1.026312); do_ABF ($a,1.026977); do_ABF ($a,1.027591); do_ABF ($a,1.028158); do_ABF ($a,1.028681); do_ABF ($a,1.029163); do_ABF ($a,1.031702); do_ABF ($a,1.032006); do_ABF ($a,1.032160); do_ABF ($a,1.032401); do_ABF ($a,1.032630); do_ABF ($a,1.032847); do_ABF ($a,1.033054); do_ABF ($a,1.033251); do_ABF ($a,1.033439);
$y = 0 ; $a=53; do_ABF ($a,1.052458); do_ABF ($a,1.052864); do_ABF ($a,1.053238); do_ABF ($a,1.053582); do_ABF ($a,1.053898); do_ABF ($a,1.054189); do_ABF ($a,1.054457); do_ABF ($a,1.054703); do_ABF ($a,1.054930); do_ABF ($a,1.057396); do_ABF ($a,1.057468); do_ABF ($a,1.057588); do_ABF ($a,1.057702); do_ABF ($a,1.057810); do_ABF ($a,1.057912); do_ABF ($a,1.058010); do_ABF ($a,1.058102);
$y = 0 ; $a=54; do_ABF ($a,1.080799); do_ABF ($a,1.080799); do_ABF ($a,1.080799); do_ABF ($a,1.080799); do_ABF ($a,1.080799); do_ABF ($a,1.080799); do_ABF ($a,1.080799); do_ABF ($a,1.080799); do_ABF ($a,1.080799); do_ABF ($a,1.080799); do_ABF ($a,1.083237); do_ABF ($a,1.083237); do_ABF ($a,1.083237); do_ABF ($a,1.083237); do_ABF ($a,1.083237); do_ABF ($a,1.083237); do_ABF ($a,1.083237);
$y = 0 ; $a=55; do_ABF ($a,1.109297); do_ABF ($a,1.109297); do_ABF ($a,1.109297); do_ABF ($a,1.109297); do_ABF ($a,1.109297); do_ABF ($a,1.109297); do_ABF ($a,1.109297); do_ABF ($a,1.109297); do_ABF ($a,1.109297); do_ABF ($a,1.109297); do_ABF ($a,1.109297); do_ABF ($a,1.109297); do_ABF ($a,1.109297); do_ABF ($a,1.109297); do_ABF ($a,1.109297); do_ABF ($a,1.109297); do_ABF ($a,1.109297);
$y = 0 ; $a=56; do_ABF ($a,1.116478); do_ABF ($a,1.116478); do_ABF ($a,1.116478); do_ABF ($a,1.116478); do_ABF ($a,1.116478); do_ABF ($a,1.116478); do_ABF ($a,1.116478); do_ABF ($a,1.116478); do_ABF ($a,1.116478); do_ABF ($a,1.116478); do_ABF ($a,1.116478); do_ABF ($a,1.116478); do_ABF ($a,1.116478); do_ABF ($a,1.116478); do_ABF ($a,1.116478); do_ABF ($a,1.116478); do_ABF ($a,1.116478);
$y = 0 ; $a=57; do_ABF ($a,1.125985); do_ABF ($a,1.125985); do_ABF ($a,1.125985); do_ABF ($a,1.125985); do_ABF ($a,1.125985); do_ABF ($a,1.125985); do_ABF ($a,1.125985); do_ABF ($a,1.125985); do_ABF ($a,1.125985); do_ABF ($a,1.125985); do_ABF ($a,1.125985); do_ABF ($a,1.125985); do_ABF ($a,1.125985); do_ABF ($a,1.125985); do_ABF ($a,1.125985); do_ABF ($a,1.125985); do_ABF ($a,1.125985);
$y = 0 ; $a=58; do_ABF ($a,1.135808); do_ABF ($a,1.135808); do_ABF ($a,1.135808); do_ABF ($a,1.135808); do_ABF ($a,1.135808); do_ABF ($a,1.135808); do_ABF ($a,1.135808); do_ABF ($a,1.135808); do_ABF ($a,1.135808); do_ABF ($a,1.135808); do_ABF ($a,1.135808); do_ABF ($a,1.135808); do_ABF ($a,1.135808); do_ABF ($a,1.135808); do_ABF ($a,1.135808); do_ABF ($a,1.135808); do_ABF ($a,1.135808);
$y = 0 ; $a=59; do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496);
$y = 0 ; $a=60; do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652);
$y = 0 ; $a=61; do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927);
$y = 0 ; $a=62; do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743);
$y = 0 ; $a=63; do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059);
$y = 0 ; $a=64; do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318);
$y = 0 ; $a=65; do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774);
$y = 0 ; $a=66; do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506);
$y = 0 ; $a=67; do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617);
$y = 0 ; $a=68; do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073);
$y = 0 ; $a=69; do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827);
$y = 0 ; $a=70; do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857);
$y = 0 ; $a=71; do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136);
$y = 0 ; $a=72; do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643);
$y = 0 ; $a=73; do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377);
$y = 0 ; $a=74; do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); 
$y = 0 ; $a=75; do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); 
# ABF -- males Age 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16
$sex = "male";
$before_99 = "after";
$y = 0 ; $a=18; do_ABF ($a,0.342849); do_ABF ($a,0.349890); do_ABF ($a,0.356118);
$y = 0 ; $a=19; do_ABF ($a,0.352638); do_ABF ($a,0.359801); do_ABF ($a,0.366299); do_ABF ($a,0.371924);
$y = 0 ; $a=20; do_ABF ($a,0.363210); do_ABF ($a,0.370449); do_ABF ($a,0.377037); do_ABF ($a,0.382912); do_ABF ($a,0.387878);
$y = 0 ; $a=21; do_ABF ($a,0.374581); do_ABF ($a,0.381902); do_ABF ($a,0.388525); do_ABF ($a,0.394448); do_ABF ($a,0.399638); do_ABF ($a,0.403907);
$y = 0 ; $a=22; do_ABF ($a,0.386717); do_ABF ($a,0.394127); do_ABF ($a,0.400795); do_ABF ($a,0.406712); do_ABF ($a,0.411911); do_ABF ($a,0.416382); do_ABF ($a,0.419939);
$y = 0 ; $a=23; do_ABF ($a,0.400152); do_ABF ($a,0.407554); do_ABF ($a,0.414233); do_ABF ($a,0.420111); do_ABF ($a,0.425219); do_ABF ($a,0.429624); do_ABF ($a,0.433331); do_ABF ($a,0.436148);
$y = 0 ; $a=24; do_ABF ($a,0.414275); do_ABF ($a,0.421693); do_ABF ($a,0.428319); do_ABF ($a,0.434173); do_ABF ($a,0.439206); do_ABF ($a,0.443484); do_ABF ($a,0.447096); do_ABF ($a,0.450057); do_ABF ($a,0.452165);
$y = 0 ; $a=25; do_ABF ($a,0.429036); do_ABF ($a,0.436429); do_ABF ($a,0.443037); do_ABF ($a,0.448800); do_ABF ($a,0.453781); do_ABF ($a,0.457956); do_ABF ($a,0.461413); do_ABF ($a,0.464258); do_ABF ($a,0.466511); do_ABF ($a,0.467953);
$y = 0 ; $a=26; do_ABF ($a,0.444490); do_ABF ($a,0.451801); do_ABF ($a,0.458346); do_ABF ($a,0.464061); do_ABF ($a,0.468920); do_ABF ($a,0.473022); do_ABF ($a,0.476355); do_ABF ($a,0.479024); do_ABF ($a,0.481146); do_ABF ($a,0.482739); do_ABF ($a,0.483566);
$y = 0 ; $a=27; do_ABF ($a,0.460530); do_ABF ($a,0.467782); do_ABF ($a,0.474208); do_ABF ($a,0.479837); do_ABF ($a,0.484633); do_ABF ($a,0.488595); do_ABF ($a,0.491845); do_ABF ($a,0.494379); do_ABF ($a,0.496312); do_ABF ($a,0.497769); do_ABF ($a,0.498760); do_ABF ($a,0.503772);
$y = 0 ; $a=28; do_ABF ($a,0.477029); do_ABF ($a,0.484173); do_ABF ($a,0.490528); do_ABF ($a,0.496027); do_ABF ($a,0.500736); do_ABF ($a,0.504641); do_ABF ($a,0.507751); do_ABF ($a,0.510210); do_ABF ($a,0.512012); do_ABF ($a,0.513279); do_ABF ($a,0.514137); do_ABF ($a,0.519041); do_ABF ($a,0.523558);
$y = 0 ; $a=29; do_ABF ($a,0.494016); do_ABF ($a,0.501088); do_ABF ($a,0.507314); do_ABF ($a,0.512733); do_ABF ($a,0.517304); do_ABF ($a,0.521121); do_ABF ($a,0.524179); do_ABF ($a,0.526497); do_ABF ($a,0.528229); do_ABF ($a,0.529365); do_ABF ($a,0.530031); do_ABF ($a,0.534820); do_ABF ($a,0.539225); do_ABF ($a,0.543263);
$y = 0 ; $a=30; do_ABF ($a,0.511466); do_ABF ($a,0.518418); do_ABF ($a,0.524566); do_ABF ($a,0.529851); do_ABF ($a,0.534348); do_ABF ($a,0.538028); do_ABF ($a,0.541008); do_ABF ($a,0.543287); do_ABF ($a,0.544882); do_ABF ($a,0.545958); do_ABF ($a,0.546498); do_ABF ($a,0.551159); do_ABF ($a,0.555443); do_ABF ($a,0.559365); do_ABF ($a,0.562945);
$y = 0 ; $a=31; do_ABF ($a,0.529465); do_ABF ($a,0.536280); do_ABF ($a,0.542291); do_ABF ($a,0.547494); do_ABF ($a,0.551850); do_ABF ($a,0.555460); do_ABF ($a,0.558304); do_ABF ($a,0.560509); do_ABF ($a,0.562073); do_ABF ($a,0.563014); do_ABF ($a,0.563499); do_ABF ($a,0.568024); do_ABF ($a,0.572177); do_ABF ($a,0.575976); do_ABF ($a,0.579440); do_ABF ($a,0.582591);
$y = 0 ; $a=32; do_ABF ($a,0.548119); do_ABF ($a,0.554748); do_ABF ($a,0.560600); do_ABF ($a,0.565653); do_ABF ($a,0.569926); do_ABF ($a,0.573391); do_ABF ($a,0.576168); do_ABF ($a,0.578235); do_ABF ($a,0.579732); do_ABF ($a,0.580648); do_ABF ($a,0.580998); do_ABF ($a,0.585382); do_ABF ($a,0.589402); do_ABF ($a,0.593074); do_ABF ($a,0.596421); do_ABF ($a,0.599461); do_ABF ($a,0.602218);
$y = 0 ; $a=33; do_ABF ($a,0.567522); do_ABF ($a,0.573971); do_ABF ($a,0.579601); do_ABF ($a,0.584472); do_ABF ($a,0.588579); do_ABF ($a,0.591957); do_ABF ($a,0.594580); do_ABF ($a,0.596582); do_ABF ($a,0.597936); do_ABF ($a,0.598786); do_ABF ($a,0.599115); do_ABF ($a,0.603345); do_ABF ($a,0.607219); do_ABF ($a,0.610754); do_ABF ($a,0.613973); do_ABF ($a,0.616894); do_ABF ($a,0.619542);
$y = 0 ; $a=34; do_ABF ($a,0.587321); do_ABF ($a,0.593691); do_ABF ($a,0.599127); do_ABF ($a,0.603764); do_ABF ($a,0.607689); do_ABF ($a,0.610905); do_ABF ($a,0.613454); do_ABF ($a,0.615309); do_ABF ($a,0.616611); do_ABF ($a,0.617325); do_ABF ($a,0.617598); do_ABF ($a,0.621674); do_ABF ($a,0.625402); do_ABF ($a,0.628802); do_ABF ($a,0.631893); do_ABF ($a,0.634697); do_ABF ($a,0.637236);
$y = 0 ; $a=35; do_ABF ($a,0.607556); do_ABF ($a,0.613835); do_ABF ($a,0.619193); do_ABF ($a,0.623628); do_ABF ($a,0.627311); do_ABF ($a,0.630346); do_ABF ($a,0.632738); do_ABF ($a,0.634532); do_ABF ($a,0.635693); do_ABF ($a,0.636367); do_ABF ($a,0.636509); do_ABF ($a,0.640427); do_ABF ($a,0.644007); do_ABF ($a,0.647268); do_ABF ($a,0.650230); do_ABF ($a,0.652916); do_ABF ($a,0.655345);
$y = 0 ; $a=36; do_ABF ($a,0.628126); do_ABF ($a,0.634301); do_ABF ($a,0.639580); do_ABF ($a,0.643954); do_ABF ($a,0.647439); do_ABF ($a,0.650236); do_ABF ($a,0.652457); do_ABF ($a,0.654106); do_ABF ($a,0.655223); do_ABF ($a,0.655766); do_ABF ($a,0.655883); do_ABF ($a,0.659635); do_ABF ($a,0.663058); do_ABF ($a,0.666174); do_ABF ($a,0.669001); do_ABF ($a,0.671563); do_ABF ($a,0.673878);
$y = 0 ; $a=37; do_ABF ($a,0.649118); do_ABF ($a,0.655141); do_ABF ($a,0.660327); do_ABF ($a,0.664637); do_ABF ($a,0.668079); do_ABF ($a,0.670682); do_ABF ($a,0.672667); do_ABF ($a,0.674152); do_ABF ($a,0.675133); do_ABF ($a,0.675647); do_ABF ($a,0.675641); do_ABF ($a,0.679226); do_ABF ($a,0.682494); do_ABF ($a,0.685464); do_ABF ($a,0.688158); do_ABF ($a,0.690596); do_ABF ($a,0.692798);
$y = 0 ; $a=38; do_ABF ($a,0.670519); do_ABF ($a,0.676383); do_ABF ($a,0.681424); do_ABF ($a,0.685657); do_ABF ($a,0.689057); do_ABF ($a,0.691638); do_ABF ($a,0.693434); do_ABF ($a,0.694685); do_ABF ($a,0.695511); do_ABF ($a,0.695898); do_ABF ($a,0.695877); do_ABF ($a,0.699285); do_ABF ($a,0.702388); do_ABF ($a,0.705206); do_ABF ($a,0.707759); do_ABF ($a,0.710068); do_ABF ($a,0.712152);
$y = 0 ; $a=39; do_ABF ($a,0.692537); do_ABF ($a,0.698113); do_ABF ($a,0.703002); do_ABF ($a,0.707103); do_ABF ($a,0.710445); do_ABF ($a,0.713004); do_ABF ($a,0.714800); do_ABF ($a,0.715868); do_ABF ($a,0.716462); do_ABF ($a,0.716700); do_ABF ($a,0.716559); do_ABF ($a,0.719791); do_ABF ($a,0.722729); do_ABF ($a,0.725395); do_ABF ($a,0.727807); do_ABF ($a,0.729987); do_ABF ($a,0.731954);
$y = 0 ; $a=40; do_ABF ($a,0.715197); do_ABF ($a,0.720480); do_ABF ($a,0.725072); do_ABF ($a,0.729032); do_ABF ($a,0.732256); do_ABF ($a,0.734778); do_ABF ($a,0.736574); do_ABF ($a,0.737663); do_ABF ($a,0.738078); do_ABF ($a,0.738085); do_ABF ($a,0.737800); do_ABF ($a,0.740843); do_ABF ($a,0.743607); do_ABF ($a,0.746111); do_ABF ($a,0.748376); do_ABF ($a,0.750421); do_ABF ($a,0.752263);
$y = 0 ; $a=41; do_ABF ($a,0.737184); do_ABF ($a,0.742170); do_ABF ($a,0.746459); do_ABF ($a,0.750117); do_ABF ($a,0.753213); do_ABF ($a,0.755634); do_ABF ($a,0.757414); do_ABF ($a,0.758526); do_ABF ($a,0.758984); do_ABF ($a,0.758819); do_ABF ($a,0.758305); do_ABF ($a,0.761141); do_ABF ($a,0.763713); do_ABF ($a,0.766041); do_ABF ($a,0.768145); do_ABF ($a,0.770042); do_ABF ($a,0.771750);
$y = 0 ; $a=42; do_ABF ($a,0.759685); do_ABF ($a,0.764338); do_ABF ($a,0.768336); do_ABF ($a,0.771698); do_ABF ($a,0.774502); do_ABF ($a,0.776819); do_ABF ($a,0.778522); do_ABF ($a,0.779646); do_ABF ($a,0.780154); do_ABF ($a,0.780057); do_ABF ($a,0.779379); do_ABF ($a,0.781986); do_ABF ($a,0.784347); do_ABF ($a,0.786481); do_ABF ($a,0.788407); do_ABF ($a,0.790143); do_ABF ($a,0.791705);
$y = 0 ; $a=43; do_ABF ($a,0.782646); do_ABF ($a,0.786965); do_ABF ($a,0.790639); do_ABF ($a,0.793727); do_ABF ($a,0.796251); do_ABF ($a,0.798291); do_ABF ($a,0.799922); do_ABF ($a,0.800996); do_ABF ($a,0.801547); do_ABF ($a,0.801528); do_ABF ($a,0.800944); do_ABF ($a,0.803305); do_ABF ($a,0.805441); do_ABF ($a,0.807370); do_ABF ($a,0.809108); do_ABF ($a,0.810673); do_ABF ($a,0.812080);
$y = 0 ; $a=44; do_ABF ($a,0.805962); do_ABF ($a,0.809968); do_ABF ($a,0.813328); do_ABF ($a,0.816113); do_ABF ($a,0.818388); do_ABF ($a,0.820172); do_ABF ($a,0.821546); do_ABF ($a,0.822580); do_ABF ($a,0.823111); do_ABF ($a,0.823167); do_ABF ($a,0.822690); do_ABF ($a,0.824818); do_ABF ($a,0.826740); do_ABF ($a,0.828474); do_ABF ($a,0.830035); do_ABF ($a,0.831439); do_ABF ($a,0.832700);
$y = 0 ; $a=45; do_ABF ($a,0.828283); do_ABF ($a,0.833325); do_ABF ($a,0.836395); do_ABF ($a,0.838888); do_ABF ($a,0.840882); do_ABF ($a,0.842441); do_ABF ($a,0.843579); do_ABF ($a,0.844374); do_ABF ($a,0.844895); do_ABF ($a,0.844957); do_ABF ($a,0.844584); do_ABF ($a,0.846493); do_ABF ($a,0.848215); do_ABF ($a,0.849766); do_ABF ($a,0.851161); do_ABF ($a,0.852416); do_ABF ($a,0.853541);
$y = 0 ; $a=46; do_ABF ($a,0.851655); do_ABF ($a,0.855470); do_ABF ($a,0.859768); do_ABF ($a,0.861999); do_ABF ($a,0.863726); do_ABF ($a,0.865027); do_ABF ($a,0.865964); do_ABF ($a,0.866543); do_ABF ($a,0.866842); do_ABF ($a,0.866922); do_ABF ($a,0.866581); do_ABF ($a,0.868286); do_ABF ($a,0.869823); do_ABF ($a,0.871206); do_ABF ($a,0.872449); do_ABF ($a,0.873564); do_ABF ($a,0.874565);
$y = 0 ; $a=47; do_ABF ($a,0.875318); do_ABF ($a,0.878721); do_ABF ($a,0.881727); do_ABF ($a,0.885383); do_ABF ($a,0.886877); do_ABF ($a,0.887936); do_ABF ($a,0.888638); do_ABF ($a,0.889039); do_ABF ($a,0.889139); do_ABF ($a,0.889012); do_ABF ($a,0.888716); do_ABF ($a,0.890227); do_ABF ($a,0.891587); do_ABF ($a,0.892810); do_ABF ($a,0.893908); do_ABF ($a,0.894893); do_ABF ($a,0.895776);
$y = 0 ; $a=48; do_ABF ($a,0.899247); do_ABF ($a,0.902224); do_ABF ($a,0.904847); do_ABF ($a,0.907150); do_ABF ($a,0.910267); do_ABF ($a,0.911122); do_ABF ($a,0.911606); do_ABF ($a,0.911793); do_ABF ($a,0.911737); do_ABF ($a,0.911428); do_ABF ($a,0.910936); do_ABF ($a,0.912265); do_ABF ($a,0.913460); do_ABF ($a,0.914534); do_ABF ($a,0.915496); do_ABF ($a,0.916359); do_ABF ($a,0.917132);
$y = 0 ; $a=49; do_ABF ($a,0.923586); do_ABF ($a,0.926129); do_ABF ($a,0.928362); do_ABF ($a,0.930317); do_ABF ($a,0.932023); do_ABF ($a,0.934706); do_ABF ($a,0.935016); do_ABF ($a,0.935009); do_ABF ($a,0.934758); do_ABF ($a,0.934313); do_ABF ($a,0.933653); do_ABF ($a,0.934789); do_ABF ($a,0.935808); do_ABF ($a,0.936723); do_ABF ($a,0.937543); do_ABF ($a,0.938276); do_ABF ($a,0.938933);
$y = 0 ; $a=50; do_ABF ($a,0.948358); do_ABF ($a,0.950454); do_ABF ($a,0.952286); do_ABF ($a,0.953884); do_ABF ($a,0.955275); do_ABF ($a,0.956484); do_ABF ($a,0.958828); do_ABF ($a,0.958673); do_ABF ($a,0.958248); do_ABF ($a,0.957623); do_ABF ($a,0.956843); do_ABF ($a,0.957774); do_ABF ($a,0.958609); do_ABF ($a,0.959357); do_ABF ($a,0.960026); do_ABF ($a,0.960625); do_ABF ($a,0.961160);
$y = 0 ; $a=51; do_ABF ($a,0.970062); do_ABF ($a,0.971681); do_ABF ($a,0.973091); do_ABF ($a,0.974315); do_ABF ($a,0.975378); do_ABF ($a,0.976298); do_ABF ($a,0.977095); do_ABF ($a,0.979174); do_ABF ($a,0.978626); do_ABF ($a,0.977847); do_ABF ($a,0.976904); do_ABF ($a,0.977620); do_ABF ($a,0.978262); do_ABF ($a,0.978835); do_ABF ($a,0.979347); do_ABF ($a,0.979804); do_ABF ($a,0.980213);
$y = 0 ; $a=52; do_ABF ($a,0.991964); do_ABF ($a,0.993088); do_ABF ($a,0.994060); do_ABF ($a,0.994901); do_ABF ($a,0.995628); do_ABF ($a,0.996256); do_ABF ($a,0.996798); do_ABF ($a,0.997265); do_ABF ($a,0.999158); do_ABF ($a,0.998279); do_ABF ($a,0.997199); do_ABF ($a,0.997688); do_ABF ($a,0.998126); do_ABF ($a,0.998516); do_ABF ($a,0.998864); do_ABF ($a,0.999174); do_ABF ($a,0.999450);
$y = 0 ; $a=53; do_ABF ($a,1.014148); do_ABF ($a,1.014739); do_ABF ($a,1.015247); do_ABF ($a,1.015684); do_ABF ($a,1.016059); do_ABF ($a,1.016382); do_ABF ($a,1.016660); do_ABF ($a,1.016899); do_ABF ($a,1.017105); do_ABF ($a,1.018877); do_ABF ($a,1.017715); do_ABF ($a,1.017965); do_ABF ($a,1.018188); do_ABF ($a,1.018386); do_ABF ($a,1.018562); do_ABF ($a,1.018719); do_ABF ($a,1.018858);
$y = 0 ; $a=54; do_ABF ($a,1.036759); do_ABF ($a,1.036759); do_ABF ($a,1.036759); do_ABF ($a,1.036759); do_ABF ($a,1.036759); do_ABF ($a,1.036759); do_ABF ($a,1.036759); do_ABF ($a,1.036759); do_ABF ($a,1.036759); do_ABF ($a,1.036759); do_ABF ($a,1.038468); do_ABF ($a,1.038468); do_ABF ($a,1.038468); do_ABF ($a,1.038468); do_ABF ($a,1.038468); do_ABF ($a,1.038468); do_ABF ($a,1.038468);
$y = 0 ; $a=55; do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139);
$y = 0 ; $a=56; do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015);
$y = 0 ; $a=57; do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805);
$y = 0 ; $a=58; do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755);
$y = 0 ; $a=59; do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734);
$y = 0 ; $a=60; do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223);
$y = 0 ; $a=61; do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930);
$y = 0 ; $a=62; do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972);
$y = 0 ; $a=63; do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116);
$y = 0 ; $a=64; do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312);
$y = 0 ; $a=65; do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050);
$y = 0 ; $a=66; do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613);
$y = 0 ; $a=67; do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527);
$y = 0 ; $a=68; do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763);
$y = 0 ; $a=69; do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384);
$y = 0 ; $a=70; do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384);
$y = 0 ; $a=71; do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750);
$y = 0 ; $a=72; do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476);
$y = 0 ; $a=73; do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534);
$y = 0 ; $a=74; do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); 
$y = 0 ; $a=75; do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); 
# ABF -- males Age 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33
$sex = "male";
$before_99 = "after";
$y = 17 ; $a=33; do_ABF ($a,0.621935);
$y = 17 ; $a=34; do_ABF ($a,0.639530); do_ABF ($a,0.641600);
$y = 17 ; $a=35; do_ABF ($a,0.657539); do_ABF ($a,0.659517); do_ABF ($a,0.661297);
$y = 17 ; $a=36; do_ABF ($a,0.675968); do_ABF ($a,0.677850); do_ABF ($a,0.679544); do_ABF ($a,0.681067);
$y = 17 ; $a=37; do_ABF ($a,0.694784); do_ABF ($a,0.696573); do_ABF ($a,0.698181); do_ABF ($a,0.699626); do_ABF ($a,0.700923);
$y = 17 ; $a=38; do_ABF ($a,0.714030); do_ABF ($a,0.715720); do_ABF ($a,0.717240); do_ABF ($a,0.718604); do_ABF ($a,0.719828); do_ABF ($a,0.720925);
$y = 17 ; $a=39; do_ABF ($a,0.733725); do_ABF ($a,0.735318); do_ABF ($a,0.736749); do_ABF ($a,0.738034); do_ABF ($a,0.739186); do_ABF ($a,0.740218); do_ABF ($a,0.741142);
$y = 17 ; $a=40; do_ABF ($a,0.753922); do_ABF ($a,0.755413); do_ABF ($a,0.756752); do_ABF ($a,0.757953); do_ABF ($a,0.759029); do_ABF ($a,0.759993); do_ABF ($a,0.760856); do_ABF ($a,0.761628);
$y = 17 ; $a=41; do_ABF ($a,0.773287); do_ABF ($a,0.774667); do_ABF ($a,0.775906); do_ABF ($a,0.777017); do_ABF ($a,0.778012); do_ABF ($a,0.778903); do_ABF ($a,0.779700); do_ABF ($a,0.780412); do_ABF ($a,0.781049);
$y = 17 ; $a=42; do_ABF ($a,0.793108); do_ABF ($a,0.794368); do_ABF ($a,0.795499); do_ABF ($a,0.796511); do_ABF ($a,0.797418); do_ABF ($a,0.798230); do_ABF ($a,0.798956); do_ABF ($a,0.799604); do_ABF ($a,0.800184); do_ABF ($a,0.800702);
$y = 17 ; $a=43; do_ABF ($a,0.813343); do_ABF ($a,0.814477); do_ABF ($a,0.815493); do_ABF ($a,0.816403); do_ABF ($a,0.817217); do_ABF ($a,0.817946); do_ABF ($a,0.818597); do_ABF ($a,0.819179); do_ABF ($a,0.819699); do_ABF ($a,0.820163); do_ABF ($a,0.820577);
$y = 17 ; $a=44; do_ABF ($a,0.833832); do_ABF ($a,0.834847); do_ABF ($a,0.835756); do_ABF ($a,0.836570); do_ABF ($a,0.837298); do_ABF ($a,0.837949); do_ABF ($a,0.838530); do_ABF ($a,0.839050); do_ABF ($a,0.839514); do_ABF ($a,0.839928); do_ABF ($a,0.840298); do_ABF ($a,0.840627);
$y = 17 ; $a=45; do_ABF ($a,0.854551); do_ABF ($a,0.855456); do_ABF ($a,0.856266); do_ABF ($a,0.856990); do_ABF ($a,0.857638); do_ABF ($a,0.858218); do_ABF ($a,0.858735); do_ABF ($a,0.859197); do_ABF ($a,0.859610); do_ABF ($a,0.859978); do_ABF ($a,0.860306); do_ABF ($a,0.860599); do_ABF ($a,0.860860);
$y = 17 ; $a=46; do_ABF ($a,0.875463); do_ABF ($a,0.876266); do_ABF ($a,0.876985); do_ABF ($a,0.877628); do_ABF ($a,0.878203); do_ABF ($a,0.878716); do_ABF ($a,0.879175); do_ABF ($a,0.879584); do_ABF ($a,0.879950); do_ABF ($a,0.880276); do_ABF ($a,0.880566); do_ABF ($a,0.880826); do_ABF ($a,0.881057); do_ABF ($a,0.881263);
$y = 17 ; $a=47; do_ABF ($a,0.896567); do_ABF ($a,0.897275); do_ABF ($a,0.897908); do_ABF ($a,0.898474); do_ABF ($a,0.898979); do_ABF ($a,0.899431); do_ABF ($a,0.899834); do_ABF ($a,0.900194); do_ABF ($a,0.900515); do_ABF ($a,0.900802); do_ABF ($a,0.901057); do_ABF ($a,0.901285); do_ABF ($a,0.901488); do_ABF ($a,0.901669); do_ABF ($a,0.901830);
$y = 17 ; $a=48; do_ABF ($a,0.917824); do_ABF ($a,0.918443); do_ABF ($a,0.918996); do_ABF ($a,0.919490); do_ABF ($a,0.919932); do_ABF ($a,0.920326); do_ABF ($a,0.920678); do_ABF ($a,0.920991); do_ABF ($a,0.921271); do_ABF ($a,0.921521); do_ABF ($a,0.921743); do_ABF ($a,0.921942); do_ABF ($a,0.922119); do_ABF ($a,0.922276); do_ABF ($a,0.922417); do_ABF ($a,0.922542);
$y = 17 ; $a=49; do_ABF ($a,0.939520); do_ABF ($a,0.940045); do_ABF ($a,0.940514); do_ABF ($a,0.940933); do_ABF ($a,0.941307); do_ABF ($a,0.941641); do_ABF ($a,0.941938); do_ABF ($a,0.942204); do_ABF ($a,0.942441); do_ABF ($a,0.942652); do_ABF ($a,0.942840); do_ABF ($a,0.943007); do_ABF ($a,0.943157); do_ABF ($a,0.943290); do_ABF ($a,0.943409); do_ABF ($a,0.943514); do_ABF ($a,0.943608);
$y = 17 ; $a=50; do_ABF ($a,0.961638); do_ABF ($a,0.962065); do_ABF ($a,0.962446); do_ABF ($a,0.962787); do_ABF ($a,0.963090); do_ABF ($a,0.963361); do_ABF ($a,0.963602); do_ABF ($a,0.963817); do_ABF ($a,0.964009); do_ABF ($a,0.964180); do_ABF ($a,0.964333); do_ABF ($a,0.964468); do_ABF ($a,0.964589); do_ABF ($a,0.964697); do_ABF ($a,0.964793); do_ABF ($a,0.964878); do_ABF ($a,0.964954);
$y = 17 ; $a=51; do_ABF ($a,0.980577); do_ABF ($a,0.980903); do_ABF ($a,0.981193); do_ABF ($a,0.981451); do_ABF ($a,0.981682); do_ABF ($a,0.981888); do_ABF ($a,0.982071); do_ABF ($a,0.982234); do_ABF ($a,0.982380); do_ABF ($a,0.982509); do_ABF ($a,0.982625); do_ABF ($a,0.982728); do_ABF ($a,0.982819); do_ABF ($a,0.982901); do_ABF ($a,0.982974); do_ABF ($a,0.983038); do_ABF ($a,0.983096);
$y = 17 ; $a=52; do_ABF ($a,0.999697); do_ABF ($a,0.999917); do_ABF ($a,1.000112); do_ABF ($a,1.000287); do_ABF ($a,1.000442); do_ABF ($a,1.000581); do_ABF ($a,1.000704); do_ABF ($a,1.000814); do_ABF ($a,1.000912); do_ABF ($a,1.000999); do_ABF ($a,1.001076); do_ABF ($a,1.001145); do_ABF ($a,1.001207); do_ABF ($a,1.001261); do_ABF ($a,1.001310); do_ABF ($a,1.001354); do_ABF ($a,1.001392);
$y = 17 ; $a=53; do_ABF ($a,1.018983); do_ABF ($a,1.019093); do_ABF ($a,1.019191); do_ABF ($a,1.019279); do_ABF ($a,1.019357); do_ABF ($a,1.019426); do_ABF ($a,1.019488); do_ABF ($a,1.019543); do_ABF ($a,1.019592); do_ABF ($a,1.019635); do_ABF ($a,1.019674); do_ABF ($a,1.019709); do_ABF ($a,1.019739); do_ABF ($a,1.019767); do_ABF ($a,1.019791); do_ABF ($a,1.019812); do_ABF ($a,1.019832);
$y = 17 ; $a=54; do_ABF ($a,1.038468); do_ABF ($a,1.038468); do_ABF ($a,1.038468); do_ABF ($a,1.038468); do_ABF ($a,1.038468); do_ABF ($a,1.038468); do_ABF ($a,1.038468); do_ABF ($a,1.038468); do_ABF ($a,1.038468); do_ABF ($a,1.038468); do_ABF ($a,1.038468); do_ABF ($a,1.038468); do_ABF ($a,1.038468); do_ABF ($a,1.038468); do_ABF ($a,1.038468); do_ABF ($a,1.038468); do_ABF ($a,1.038468);
$y = 17 ; $a=55; do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139);
$y = 17 ; $a=56; do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015);
$y = 17 ; $a=57; do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805);
$y = 17 ; $a=58; do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755);
$y = 17 ; $a=59; do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734);
$y = 17 ; $a=60; do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223);
$y = 17 ; $a=61; do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930);
$y = 17 ; $a=62; do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972);
$y = 17 ; $a=63; do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116);
$y = 17 ; $a=64; do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312);
$y = 17 ; $a=65; do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050);
$y = 17 ; $a=66; do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613);
$y = 17 ; $a=67; do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527);
$y = 17 ; $a=68; do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763);
$y = 17 ; $a=69; do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384);
$y = 17 ; $a=70; do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384);
$y = 17 ; $a=71; do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750);
$y = 17 ; $a=72; do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476);
$y = 17 ; $a=73; do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534);
$y = 17 ; $a=74; do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); 
$y = 17 ; $a=75; do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); 
# ABF -- males Age 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 or more
$sex = "male";
$before_99 = "after";
$y = 34 ; $a=50; do_ABF ($a,0.965022);
$y = 34 ; $a=51; do_ABF ($a,0.983147); do_ABF ($a,0.983193);
$y = 34 ; $a=52; do_ABF ($a,1.001427); do_ABF ($a,1.001457); do_ABF ($a,1.001484);
$y = 34 ; $a=53; do_ABF ($a,1.019849); do_ABF ($a,1.019864); do_ABF ($a,1.019878); do_ABF ($a,1.019890);
$y = 34 ; $a=54; do_ABF ($a,1.038468); do_ABF ($a,1.038468); do_ABF ($a,1.038468); do_ABF ($a,1.038468); do_ABF ($a,1.038468);
$y = 34 ; $a=55; do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139); do_ABF ($a,1.059139);
$y = 34 ; $a=56; do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015); do_ABF ($a,1.066015);
$y = 34 ; $a=57; do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805); do_ABF ($a,1.073805);
$y = 34 ; $a=58; do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755); do_ABF ($a,1.082755);
$y = 34 ; $a=59; do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734); do_ABF ($a,1.092734);
$y = 34 ; $a=60; do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223); do_ABF ($a,1.101223);
$y = 34 ; $a=61; do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930); do_ABF ($a,1.108930);
$y = 34 ; $a=62; do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972); do_ABF ($a,1.119972);
$y = 34 ; $a=63; do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116); do_ABF ($a,1.134116);
$y = 34 ; $a=64; do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312); do_ABF ($a,1.153312);
$y = 34 ; $a=65; do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050); do_ABF ($a,1.178050);
$y = 34 ; $a=66; do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613); do_ABF ($a,1.170613);
$y = 34 ; $a=67; do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527); do_ABF ($a,1.162527);
$y = 34 ; $a=68; do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763); do_ABF ($a,1.153763);
$y = 34 ; $a=69; do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384); do_ABF ($a,1.144384);
$y = 34 ; $a=70; do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384); do_ABF ($a,1.134384);
$y = 34 ; $a=71; do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750); do_ABF ($a,1.123750);
$y = 34 ; $a=72; do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476); do_ABF ($a,1.112476);
$y = 34 ; $a=73; do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534); do_ABF ($a,1.100534);
$y = 34 ; $a=74; do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); do_ABF ($a,1.087904); 
$y = 34 ; $a=75; do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); do_ABF ($a,1.074602); 
# ABF -- females Age 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33
$sex = "female";
$before_99 = "after";
$y = 17 ; $a=33; do_ABF ($a,0.618277);
$y = 17 ; $a=34; do_ABF ($a,0.638712); do_ABF ($a,0.640390);
$y = 17 ; $a=35; do_ABF ($a,0.659256); do_ABF ($a,0.660835); do_ABF ($a,0.662350);
$y = 17 ; $a=36; do_ABF ($a,0.679994); do_ABF ($a,0.681479); do_ABF ($a,0.682904); do_ABF ($a,0.684270);
$y = 17 ; $a=37; do_ABF ($a,0.700938); do_ABF ($a,0.702336); do_ABF ($a,0.703675); do_ABF ($a,0.704959); do_ABF ($a,0.706188);
$y = 17 ; $a=38; do_ABF ($a,0.722114); do_ABF ($a,0.723430); do_ABF ($a,0.724691); do_ABF ($a,0.725898); do_ABF ($a,0.727054); do_ABF ($a,0.728161);
$y = 17 ; $a=39; do_ABF ($a,0.743599); do_ABF ($a,0.744831); do_ABF ($a,0.746012); do_ABF ($a,0.747142); do_ABF ($a,0.748223); do_ABF ($a,0.749257); do_ABF ($a,0.750247);
$y = 17 ; $a=40; do_ABF ($a,0.765361); do_ABF ($a,0.766509); do_ABF ($a,0.767609); do_ABF ($a,0.768661); do_ABF ($a,0.769667); do_ABF ($a,0.770629); do_ABF ($a,0.771549); do_ABF ($a,0.772428);
$y = 17 ; $a=41; do_ABF ($a,0.786348); do_ABF ($a,0.787410); do_ABF ($a,0.788426); do_ABF ($a,0.789398); do_ABF ($a,0.790328); do_ABF ($a,0.791216); do_ABF ($a,0.792065); do_ABF ($a,0.792875); do_ABF ($a,0.793649);
$y = 17 ; $a=42; do_ABF ($a,0.807551); do_ABF ($a,0.808526); do_ABF ($a,0.809459); do_ABF ($a,0.810350); do_ABF ($a,0.811201); do_ABF ($a,0.812015); do_ABF ($a,0.812792); do_ABF ($a,0.813534); do_ABF ($a,0.814242); do_ABF ($a,0.814918);
$y = 17 ; $a=43; do_ABF ($a,0.828956); do_ABF ($a,0.829843); do_ABF ($a,0.830691); do_ABF ($a,0.831501); do_ABF ($a,0.832274); do_ABF ($a,0.833013); do_ABF ($a,0.833718); do_ABF ($a,0.834391); do_ABF ($a,0.835034); do_ABF ($a,0.835646); do_ABF ($a,0.836231);
$y = 17 ; $a=44; do_ABF ($a,0.850596); do_ABF ($a,0.851398); do_ABF ($a,0.852163); do_ABF ($a,0.852894); do_ABF ($a,0.853592); do_ABF ($a,0.854258); do_ABF ($a,0.854894); do_ABF ($a,0.855500); do_ABF ($a,0.856079); do_ABF ($a,0.856630); do_ABF ($a,0.857156); do_ABF ($a,0.857657);
$y = 17 ; $a=45; do_ABF ($a,0.872460); do_ABF ($a,0.873179); do_ABF ($a,0.873865); do_ABF ($a,0.874520); do_ABF ($a,0.875145); do_ABF ($a,0.875742); do_ABF ($a,0.876310); do_ABF ($a,0.876853); do_ABF ($a,0.877370); do_ABF ($a,0.877864); do_ABF ($a,0.878334); do_ABF ($a,0.878782); do_ABF ($a,0.879208);
$y = 17 ; $a=46; do_ABF ($a,0.894539); do_ABF ($a,0.895178); do_ABF ($a,0.895788); do_ABF ($a,0.896370); do_ABF ($a,0.896926); do_ABF ($a,0.897455); do_ABF ($a,0.897960); do_ABF ($a,0.898442); do_ABF ($a,0.898901); do_ABF ($a,0.899338); do_ABF ($a,0.899755); do_ABF ($a,0.900152); do_ABF ($a,0.900530); do_ABF ($a,0.900890);
$y = 17 ; $a=47; do_ABF ($a,0.916831); do_ABF ($a,0.917395); do_ABF ($a,0.917932); do_ABF ($a,0.918444); do_ABF ($a,0.918933); do_ABF ($a,0.919399); do_ABF ($a,0.919842); do_ABF ($a,0.920266); do_ABF ($a,0.920669); do_ABF ($a,0.921053); do_ABF ($a,0.921418); do_ABF ($a,0.921767); do_ABF ($a,0.922098); do_ABF ($a,0.922414); do_ABF ($a,0.922715);
$y = 17 ; $a=48; do_ABF ($a,0.939357); do_ABF ($a,0.939847); do_ABF ($a,0.940314); do_ABF ($a,0.940760); do_ABF ($a,0.941185); do_ABF ($a,0.941589); do_ABF ($a,0.941975); do_ABF ($a,0.942342); do_ABF ($a,0.942692); do_ABF ($a,0.943025); do_ABF ($a,0.943342); do_ABF ($a,0.943644); do_ABF ($a,0.943932); do_ABF ($a,0.944205); do_ABF ($a,0.944466); do_ABF ($a,0.944714);
$y = 17 ; $a=49; do_ABF ($a,0.962299); do_ABF ($a,0.962714); do_ABF ($a,0.963109); do_ABF ($a,0.963485); do_ABF ($a,0.963843); do_ABF ($a,0.964184); do_ABF ($a,0.964509); do_ABF ($a,0.964818); do_ABF ($a,0.965113); do_ABF ($a,0.965393); do_ABF ($a,0.965660); do_ABF ($a,0.965914); do_ABF ($a,0.966156); do_ABF ($a,0.966386); do_ABF ($a,0.966605); do_ABF ($a,0.966813); do_ABF ($a,0.967012);
$y = 17 ; $a=50; do_ABF ($a,0.985673); do_ABF ($a,0.986007); do_ABF ($a,0.986326); do_ABF ($a,0.986630); do_ABF ($a,0.986919); do_ABF ($a,0.987194); do_ABF ($a,0.987456); do_ABF ($a,0.987705); do_ABF ($a,0.987942); do_ABF ($a,0.988168); do_ABF ($a,0.988383); do_ABF ($a,0.988587); do_ABF ($a,0.988781); do_ABF ($a,0.988966); do_ABF ($a,0.989142); do_ABF ($a,0.989309); do_ABF ($a,0.989468);
$y = 17 ; $a=51; do_ABF ($a,1.009439); do_ABF ($a,1.009693); do_ABF ($a,1.009934); do_ABF ($a,1.010163); do_ABF ($a,1.010381); do_ABF ($a,1.010589); do_ABF ($a,1.010786); do_ABF ($a,1.010974); do_ABF ($a,1.011153); do_ABF ($a,1.011323); do_ABF ($a,1.011484); do_ABF ($a,1.011638); do_ABF ($a,1.011784); do_ABF ($a,1.011923); do_ABF ($a,1.012055); do_ABF ($a,1.012181); do_ABF ($a,1.012300);
$y = 17 ; $a=52; do_ABF ($a,1.033617); do_ABF ($a,1.033786); do_ABF ($a,1.033947); do_ABF ($a,1.034100); do_ABF ($a,1.034246); do_ABF ($a,1.034384); do_ABF ($a,1.034516); do_ABF ($a,1.034641); do_ABF ($a,1.034760); do_ABF ($a,1.034873); do_ABF ($a,1.034980); do_ABF ($a,1.035082); do_ABF ($a,1.035179); do_ABF ($a,1.035272); do_ABF ($a,1.035359); do_ABF ($a,1.035443); do_ABF ($a,1.035522);
$y = 17 ; $a=53; do_ABF ($a,1.058190); do_ABF ($a,1.058274); do_ABF ($a,1.058353); do_ABF ($a,1.058429); do_ABF ($a,1.058500); do_ABF ($a,1.058569); do_ABF ($a,1.058633); do_ABF ($a,1.058695); do_ABF ($a,1.058753); do_ABF ($a,1.058808); do_ABF ($a,1.058861); do_ABF ($a,1.058911); do_ABF ($a,1.058959); do_ABF ($a,1.059004); do_ABF ($a,1.059047); do_ABF ($a,1.059088); do_ABF ($a,1.059126);
$y = 17 ; $a=54; do_ABF ($a,1.083237); do_ABF ($a,1.083237); do_ABF ($a,1.083237); do_ABF ($a,1.083237); do_ABF ($a,1.083237); do_ABF ($a,1.083237); do_ABF ($a,1.083237); do_ABF ($a,1.083237); do_ABF ($a,1.083237); do_ABF ($a,1.083237); do_ABF ($a,1.083237); do_ABF ($a,1.083237); do_ABF ($a,1.083237); do_ABF ($a,1.083237); do_ABF ($a,1.083237); do_ABF ($a,1.083237); do_ABF ($a,1.083237);
$y = 17 ; $a=55; do_ABF ($a,1.109297); do_ABF ($a,1.109297); do_ABF ($a,1.109297); do_ABF ($a,1.109297); do_ABF ($a,1.109297); do_ABF ($a,1.109297); do_ABF ($a,1.109297); do_ABF ($a,1.109297); do_ABF ($a,1.109297); do_ABF ($a,1.109297); do_ABF ($a,1.109297); do_ABF ($a,1.109297); do_ABF ($a,1.109297); do_ABF ($a,1.109297); do_ABF ($a,1.109297); do_ABF ($a,1.109297); do_ABF ($a,1.109297);
$y = 17 ; $a=56; do_ABF ($a,1.116478); do_ABF ($a,1.116478); do_ABF ($a,1.116478); do_ABF ($a,1.116478); do_ABF ($a,1.116478); do_ABF ($a,1.116478); do_ABF ($a,1.116478); do_ABF ($a,1.116478); do_ABF ($a,1.116478); do_ABF ($a,1.116478); do_ABF ($a,1.116478); do_ABF ($a,1.116478); do_ABF ($a,1.116478); do_ABF ($a,1.116478); do_ABF ($a,1.116478); do_ABF ($a,1.116478); do_ABF ($a,1.116478);
$y = 17 ; $a=57; do_ABF ($a,1.125985); do_ABF ($a,1.125985); do_ABF ($a,1.125985); do_ABF ($a,1.125985); do_ABF ($a,1.125985); do_ABF ($a,1.125985); do_ABF ($a,1.125985); do_ABF ($a,1.125985); do_ABF ($a,1.125985); do_ABF ($a,1.125985); do_ABF ($a,1.125985); do_ABF ($a,1.125985); do_ABF ($a,1.125985); do_ABF ($a,1.125985); do_ABF ($a,1.125985); do_ABF ($a,1.125985); do_ABF ($a,1.125985);
$y = 17 ; $a=58; do_ABF ($a,1.135808); do_ABF ($a,1.135808); do_ABF ($a,1.135808); do_ABF ($a,1.135808); do_ABF ($a,1.135808); do_ABF ($a,1.135808); do_ABF ($a,1.135808); do_ABF ($a,1.135808); do_ABF ($a,1.135808); do_ABF ($a,1.135808); do_ABF ($a,1.135808); do_ABF ($a,1.135808); do_ABF ($a,1.135808); do_ABF ($a,1.135808); do_ABF ($a,1.135808); do_ABF ($a,1.135808); do_ABF ($a,1.135808);
$y = 17 ; $a=59; do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496);
$y = 17 ; $a=60; do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652);
$y = 17 ; $a=61; do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927);
$y = 17 ; $a=62; do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743);
$y = 17 ; $a=63; do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059);
$y = 17 ; $a=64; do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318);
$y = 17 ; $a=65; do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774);
$y = 17 ; $a=66; do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506);
$y = 17 ; $a=67; do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617);
$y = 17 ; $a=68; do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073);
$y = 17 ; $a=69; do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827);
$y = 17 ; $a=70; do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857);
$y = 17 ; $a=71; do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136);
$y = 17 ; $a=72; do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643);
$y = 17 ; $a=73; do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377);
$y = 17 ; $a=74; do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); 
$y = 17 ; $a=75; do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); 
# ABF -- females Age 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 or more
$sex = "female";
$before_99 = "after";
$y = 34 ; $a=50; do_ABF ($a,0.989620);
$y = 34 ; $a=51; do_ABF ($a,1.012414); do_ABF ($a,1.012522);
$y = 34 ; $a=52; do_ABF ($a,1.035597); do_ABF ($a,1.035669); do_ABF ($a,1.035737);
$y = 34 ; $a=53; do_ABF ($a,1.059163); do_ABF ($a,1.059198); do_ABF ($a,1.059231); do_ABF ($a,1.059263);
$y = 34 ; $a=54; do_ABF ($a,1.083237); do_ABF ($a,1.083237); do_ABF ($a,1.083237); do_ABF ($a,1.083237); do_ABF ($a,1.083237);
$y = 34 ; $a=55; do_ABF ($a,1.109297); do_ABF ($a,1.109297); do_ABF ($a,1.109297); do_ABF ($a,1.109297); do_ABF ($a,1.109297); do_ABF ($a,1.109297);
$y = 34 ; $a=56; do_ABF ($a,1.116478); do_ABF ($a,1.116478); do_ABF ($a,1.116478); do_ABF ($a,1.116478); do_ABF ($a,1.116478); do_ABF ($a,1.116478); do_ABF ($a,1.116478);
$y = 34 ; $a=57; do_ABF ($a,1.125985); do_ABF ($a,1.125985); do_ABF ($a,1.125985); do_ABF ($a,1.125985); do_ABF ($a,1.125985); do_ABF ($a,1.125985); do_ABF ($a,1.125985); do_ABF ($a,1.125985);
$y = 34 ; $a=58; do_ABF ($a,1.135808); do_ABF ($a,1.135808); do_ABF ($a,1.135808); do_ABF ($a,1.135808); do_ABF ($a,1.135808); do_ABF ($a,1.135808); do_ABF ($a,1.135808); do_ABF ($a,1.135808); do_ABF ($a,1.135808);
$y = 34 ; $a=59; do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496); do_ABF ($a,1.146496);
$y = 34 ; $a=60; do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652); do_ABF ($a,1.159652);
$y = 34 ; $a=61; do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927); do_ABF ($a,1.172927);
$y = 34 ; $a=62; do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743); do_ABF ($a,1.186743);
$y = 34 ; $a=63; do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059); do_ABF ($a,1.200059);
$y = 34 ; $a=64; do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318); do_ABF ($a,1.216318);
$y = 34 ; $a=65; do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774); do_ABF ($a,1.240774);
$y = 34 ; $a=66; do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506); do_ABF ($a,1.236506);
$y = 34 ; $a=67; do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617); do_ABF ($a,1.231617);
$y = 34 ; $a=68; do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073); do_ABF ($a,1.226073);
$y = 34 ; $a=69; do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827); do_ABF ($a,1.219827);
$y = 34 ; $a=70; do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857); do_ABF ($a,1.212857);
$y = 34 ; $a=71; do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136); do_ABF ($a,1.205136);
$y = 34 ; $a=72; do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643); do_ABF ($a,1.196643);
$y = 34 ; $a=73; do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377); do_ABF ($a,1.187377);
$y = 34 ; $a=74; do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); do_ABF ($a,1.177218); 
$y = 34 ; $a=75; do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); do_ABF ($a,1.166119); 
# MCF -- males Age 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33
$sex = "male";
$before_99 = "after";
$y = 17 ; $a=33; do_MCF ($a,0.740356);
$y = 17 ; $a=34; do_MCF ($a,0.752678); do_MCF ($a,0.760246);
$y = 17 ; $a=35; do_MCF ($a,0.765073); do_MCF ($a,0.772232); do_MCF ($a,0.778681);
$y = 17 ; $a=36; do_MCF ($a,0.777610); do_MCF ($a,0.784357); do_MCF ($a,0.790432); do_MCF ($a,0.795893);
$y = 17 ; $a=37; do_MCF ($a,0.790125); do_MCF ($a,0.796472); do_MCF ($a,0.802184); do_MCF ($a,0.807317); do_MCF ($a,0.811925);
$y = 17 ; $a=38; do_MCF ($a,0.802764); do_MCF ($a,0.808707); do_MCF ($a,0.814051); do_MCF ($a,0.818851); do_MCF ($a,0.823159); do_MCF ($a,0.827022);
$y = 17 ; $a=39; do_MCF ($a,0.815301); do_MCF ($a,0.820850); do_MCF ($a,0.825837); do_MCF ($a,0.830314); do_MCF ($a,0.834331); do_MCF ($a,0.837931); do_MCF ($a,0.841154);
$y = 17 ; $a=40; do_MCF ($a,0.827891); do_MCF ($a,0.833038); do_MCF ($a,0.837661); do_MCF ($a,0.841811); do_MCF ($a,0.845531); do_MCF ($a,0.848864); do_MCF ($a,0.851847); do_MCF ($a,0.854516);
$y = 17 ; $a=41; do_MCF ($a,0.840753); do_MCF ($a,0.845480); do_MCF ($a,0.849724); do_MCF ($a,0.853531); do_MCF ($a,0.856942); do_MCF ($a,0.859997); do_MCF ($a,0.862731); do_MCF ($a,0.865176); do_MCF ($a,0.867362);
$y = 17 ; $a=42; do_MCF ($a,0.853712); do_MCF ($a,0.857998); do_MCF ($a,0.861843); do_MCF ($a,0.865290); do_MCF ($a,0.868377); do_MCF ($a,0.871141); do_MCF ($a,0.873614); do_MCF ($a,0.875824); do_MCF ($a,0.877799); do_MCF ($a,0.879563);
$y = 17 ; $a=43; do_MCF ($a,0.866615); do_MCF ($a,0.870449); do_MCF ($a,0.873888); do_MCF ($a,0.876968); do_MCF ($a,0.879726); do_MCF ($a,0.882193); do_MCF ($a,0.884400); do_MCF ($a,0.886372); do_MCF ($a,0.888133); do_MCF ($a,0.889706); do_MCF ($a,0.891111);
$y = 17 ; $a=44; do_MCF ($a,0.879102); do_MCF ($a,0.882519); do_MCF ($a,0.885581); do_MCF ($a,0.888324); do_MCF ($a,0.890778); do_MCF ($a,0.892973); do_MCF ($a,0.894934); do_MCF ($a,0.896687); do_MCF ($a,0.898252); do_MCF ($a,0.899650); do_MCF ($a,0.900897); do_MCF ($a,0.902009);
$y = 17 ; $a=45; do_MCF ($a,0.891124); do_MCF ($a,0.894159); do_MCF ($a,0.896877); do_MCF ($a,0.899311); do_MCF ($a,0.901487); do_MCF ($a,0.903433); do_MCF ($a,0.905171); do_MCF ($a,0.906724); do_MCF ($a,0.908110); do_MCF ($a,0.909348); do_MCF ($a,0.910452); do_MCF ($a,0.911436); do_MCF ($a,0.912314);
$y = 17 ; $a=46; do_MCF ($a,0.902635); do_MCF ($a,0.905323); do_MCF ($a,0.907729); do_MCF ($a,0.909881); do_MCF ($a,0.911805); do_MCF ($a,0.913525); do_MCF ($a,0.915061); do_MCF ($a,0.916432); do_MCF ($a,0.917657); do_MCF ($a,0.918749); do_MCF ($a,0.919723); do_MCF ($a,0.920592); do_MCF ($a,0.921367); do_MCF ($a,0.922058);
$y = 17 ; $a=47; do_MCF ($a,0.913694); do_MCF ($a,0.916056); do_MCF ($a,0.918170); do_MCF ($a,0.920060); do_MCF ($a,0.921749); do_MCF ($a,0.923258); do_MCF ($a,0.924606); do_MCF ($a,0.925808); do_MCF ($a,0.926881); do_MCF ($a,0.927839); do_MCF ($a,0.928693); do_MCF ($a,0.929454); do_MCF ($a,0.930132); do_MCF ($a,0.930737); do_MCF ($a,0.931276);
$y = 17 ; $a=48; do_MCF ($a,0.924230); do_MCF ($a,0.926291); do_MCF ($a,0.928135); do_MCF ($a,0.929782); do_MCF ($a,0.931254); do_MCF ($a,0.932568); do_MCF ($a,0.933741); do_MCF ($a,0.934788); do_MCF ($a,0.935721); do_MCF ($a,0.936554); do_MCF ($a,0.937297); do_MCF ($a,0.937958); do_MCF ($a,0.938548); do_MCF ($a,0.939074); do_MCF ($a,0.939542); do_MCF ($a,0.939960);
$y = 17 ; $a=49; do_MCF ($a,0.935031); do_MCF ($a,0.936779); do_MCF ($a,0.938342); do_MCF ($a,0.939737); do_MCF ($a,0.940983); do_MCF ($a,0.942095); do_MCF ($a,0.943087); do_MCF ($a,0.943972); do_MCF ($a,0.944761); do_MCF ($a,0.945465); do_MCF ($a,0.946092); do_MCF ($a,0.946651); do_MCF ($a,0.947149); do_MCF ($a,0.947593); do_MCF ($a,0.947988); do_MCF ($a,0.948340); do_MCF ($a,0.948654);
$y = 17 ; $a=50; do_MCF ($a,0.945987); do_MCF ($a,0.947411); do_MCF ($a,0.948683); do_MCF ($a,0.949817); do_MCF ($a,0.950830); do_MCF ($a,0.951733); do_MCF ($a,0.952538); do_MCF ($a,0.953256); do_MCF ($a,0.953897); do_MCF ($a,0.954467); do_MCF ($a,0.954975); do_MCF ($a,0.955428); do_MCF ($a,0.955832); do_MCF ($a,0.956192); do_MCF ($a,0.956512); do_MCF ($a,0.956797); do_MCF ($a,0.957051);
$y = 17 ; $a=51; do_MCF ($a,0.957013); do_MCF ($a,0.958101); do_MCF ($a,0.959072); do_MCF ($a,0.959937); do_MCF ($a,0.960709); do_MCF ($a,0.961397); do_MCF ($a,0.962011); do_MCF ($a,0.962557); do_MCF ($a,0.963044); do_MCF ($a,0.963478); do_MCF ($a,0.963865); do_MCF ($a,0.964209); do_MCF ($a,0.964515); do_MCF ($a,0.964788); do_MCF ($a,0.965032); do_MCF ($a,0.965248); do_MCF ($a,0.965441);
$y = 17 ; $a=52; do_MCF ($a,0.967927); do_MCF ($a,0.968666); do_MCF ($a,0.969325); do_MCF ($a,0.969911); do_MCF ($a,0.970434); do_MCF ($a,0.970900); do_MCF ($a,0.971314); do_MCF ($a,0.971684); do_MCF ($a,0.972013); do_MCF ($a,0.972306); do_MCF ($a,0.972566); do_MCF ($a,0.972799); do_MCF ($a,0.973005); do_MCF ($a,0.973189); do_MCF ($a,0.973353); do_MCF ($a,0.973499); do_MCF ($a,0.973629);
$y = 17 ; $a=53; do_MCF ($a,0.978625); do_MCF ($a,0.979000); do_MCF ($a,0.979333); do_MCF ($a,0.979630); do_MCF ($a,0.979894); do_MCF ($a,0.980129); do_MCF ($a,0.980338); do_MCF ($a,0.980524); do_MCF ($a,0.980690); do_MCF ($a,0.980837); do_MCF ($a,0.980968); do_MCF ($a,0.981085); do_MCF ($a,0.981189); do_MCF ($a,0.981282); do_MCF ($a,0.981364); do_MCF ($a,0.981437); do_MCF ($a,0.981502);
$y = 17 ; $a=54; do_MCF ($a,0.989090); do_MCF ($a,0.989090); do_MCF ($a,0.989090); do_MCF ($a,0.989090); do_MCF ($a,0.989090); do_MCF ($a,0.989090); do_MCF ($a,0.989090); do_MCF ($a,0.989090); do_MCF ($a,0.989090); do_MCF ($a,0.989090); do_MCF ($a,0.989090); do_MCF ($a,0.989090); do_MCF ($a,0.989090); do_MCF ($a,0.989090); do_MCF ($a,0.989090); do_MCF ($a,0.989090); do_MCF ($a,0.989090);
$y = 17 ; $a=55; do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797);
$y = 17 ; $a=56; do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097);
$y = 17 ; $a=57; do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409);
$y = 17 ; $a=58; do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); 
$y = 17 ; $a=59; do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); 
# MCF -- males Age 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 or more
$sex = "male";
$before_99 = "after";
$y = 34 ; $a=50; do_MCF ($a,0.957277);
$y = 34 ; $a=51; do_MCF ($a,0.965613); do_MCF ($a,0.965765);
$y = 34 ; $a=52; do_MCF ($a,0.973745); do_MCF ($a,0.973848); do_MCF ($a,0.973939);
$y = 34 ; $a=53; do_MCF ($a,0.981560); do_MCF ($a,0.981612); do_MCF ($a,0.981658); do_MCF ($a,0.981699);
$y = 34 ; $a=54; do_MCF ($a,0.989090); do_MCF ($a,0.989090); do_MCF ($a,0.989090); do_MCF ($a,0.989090); do_MCF ($a,0.989090);
$y = 34 ; $a=55; do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797); do_MCF ($a,1.002797);
$y = 34 ; $a=56; do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097); do_MCF ($a,1.002097);
$y = 34 ; $a=57; do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409); do_MCF ($a,1.001409);
$y = 34 ; $a=58; do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732); do_MCF ($a,1.000732);
$y = 34 ; $a=59; do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000);
$y = 34 ; $a=60; do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000);
$y = 34 ; $a=61; do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000);
$y = 34 ; $a=62; do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000);
$y = 34 ; $a=63; do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000);
$y = 34 ; $a=64; do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000);
$y = 34 ; $a=65; do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); 
$y = 34 ; $a=66; do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); 
# MCF -- females Age 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33
$sex = "female";
$before_99 = "after";
$y = 17 ; $a=33; do_MCF ($a,0.689127);
$y = 17 ; $a=34; do_MCF ($a,0.710866); do_MCF ($a,0.717016);
$y = 17 ; $a=35; do_MCF ($a,0.731319); do_MCF ($a,0.737045); do_MCF ($a,0.742546);
$y = 17 ; $a=36; do_MCF ($a,0.750788); do_MCF ($a,0.756120); do_MCF ($a,0.761237); do_MCF ($a,0.766147);
$y = 17 ; $a=37; do_MCF ($a,0.769341); do_MCF ($a,0.774305); do_MCF ($a,0.779067); do_MCF ($a,0.783632); do_MCF ($a,0.788007);
$y = 17 ; $a=38; do_MCF ($a,0.786980); do_MCF ($a,0.791605); do_MCF ($a,0.796039); do_MCF ($a,0.800289); do_MCF ($a,0.804359); do_MCF ($a,0.808255);
$y = 17 ; $a=39; do_MCF ($a,0.804089); do_MCF ($a,0.808378); do_MCF ($a,0.812487); do_MCF ($a,0.816422); do_MCF ($a,0.820190); do_MCF ($a,0.823795); do_MCF ($a,0.827244);
$y = 17 ; $a=40; do_MCF ($a,0.820581); do_MCF ($a,0.824538); do_MCF ($a,0.828328); do_MCF ($a,0.831955); do_MCF ($a,0.835426); do_MCF ($a,0.838746); do_MCF ($a,0.841920); do_MCF ($a,0.844954);
$y = 17 ; $a=41; do_MCF ($a,0.836643); do_MCF ($a,0.840269); do_MCF ($a,0.843738); do_MCF ($a,0.847058); do_MCF ($a,0.850232); do_MCF ($a,0.853267); do_MCF ($a,0.856167); do_MCF ($a,0.858938); do_MCF ($a,0.861585);
$y = 17 ; $a=42; do_MCF ($a,0.852092); do_MCF ($a,0.855388); do_MCF ($a,0.858541); do_MCF ($a,0.861556); do_MCF ($a,0.864438); do_MCF ($a,0.867192); do_MCF ($a,0.869823); do_MCF ($a,0.872336); do_MCF ($a,0.874735); do_MCF ($a,0.877025);
$y = 17 ; $a=43; do_MCF ($a,0.866881); do_MCF ($a,0.869854); do_MCF ($a,0.872696); do_MCF ($a,0.875412); do_MCF ($a,0.878007); do_MCF ($a,0.880486); do_MCF ($a,0.882853); do_MCF ($a,0.885112); do_MCF ($a,0.887269); do_MCF ($a,0.889326); do_MCF ($a,0.891289);
$y = 17 ; $a=44; do_MCF ($a,0.880982); do_MCF ($a,0.883645); do_MCF ($a,0.886189); do_MCF ($a,0.888619); do_MCF ($a,0.890940); do_MCF ($a,0.893156); do_MCF ($a,0.895271); do_MCF ($a,0.897289); do_MCF ($a,0.899214); do_MCF ($a,0.901050); do_MCF ($a,0.902801); do_MCF ($a,0.904471);
$y = 17 ; $a=45; do_MCF ($a,0.894332); do_MCF ($a,0.896701); do_MCF ($a,0.898963); do_MCF ($a,0.901122); do_MCF ($a,0.903184); do_MCF ($a,0.905151); do_MCF ($a,0.907028); do_MCF ($a,0.908818); do_MCF ($a,0.910525); do_MCF ($a,0.912153); do_MCF ($a,0.913705); do_MCF ($a,0.915184); do_MCF ($a,0.916593);
$y = 17 ; $a=46; do_MCF ($a,0.906934); do_MCF ($a,0.909024); do_MCF ($a,0.911019); do_MCF ($a,0.912922); do_MCF ($a,0.914738); do_MCF ($a,0.916470); do_MCF ($a,0.918122); do_MCF ($a,0.919697); do_MCF ($a,0.921199); do_MCF ($a,0.922630); do_MCF ($a,0.923994); do_MCF ($a,0.925293); do_MCF ($a,0.926531); do_MCF ($a,0.927711);
$y = 17 ; $a=47; do_MCF ($a,0.918781); do_MCF ($a,0.920607); do_MCF ($a,0.922349); do_MCF ($a,0.924011); do_MCF ($a,0.925595); do_MCF ($a,0.927106); do_MCF ($a,0.928546); do_MCF ($a,0.929918); do_MCF ($a,0.931226); do_MCF ($a,0.932472); do_MCF ($a,0.933659); do_MCF ($a,0.934790); do_MCF ($a,0.935867); do_MCF ($a,0.936892); do_MCF ($a,0.937869);
$y = 17 ; $a=48; do_MCF ($a,0.929887); do_MCF ($a,0.931463); do_MCF ($a,0.932966); do_MCF ($a,0.934399); do_MCF ($a,0.935765); do_MCF ($a,0.937066); do_MCF ($a,0.938306); do_MCF ($a,0.939487); do_MCF ($a,0.940613); do_MCF ($a,0.941685); do_MCF ($a,0.942705); do_MCF ($a,0.943677); do_MCF ($a,0.944602); do_MCF ($a,0.945483); do_MCF ($a,0.946322); do_MCF ($a,0.947120);
$y = 17 ; $a=49; do_MCF ($a,0.940871); do_MCF ($a,0.942193); do_MCF ($a,0.943452); do_MCF ($a,0.944652); do_MCF ($a,0.945795); do_MCF ($a,0.946884); do_MCF ($a,0.947921); do_MCF ($a,0.948908); do_MCF ($a,0.949848); do_MCF ($a,0.950743); do_MCF ($a,0.951595); do_MCF ($a,0.952406); do_MCF ($a,0.953178); do_MCF ($a,0.953913); do_MCF ($a,0.954612); do_MCF ($a,0.955277); do_MCF ($a,0.955909);
$y = 17 ; $a=50; do_MCF ($a,0.951707); do_MCF ($a,0.952767); do_MCF ($a,0.953777); do_MCF ($a,0.954739); do_MCF ($a,0.955655); do_MCF ($a,0.956527); do_MCF ($a,0.957356); do_MCF ($a,0.958146); do_MCF ($a,0.958898); do_MCF ($a,0.959613); do_MCF ($a,0.960293); do_MCF ($a,0.960941); do_MCF ($a,0.961557); do_MCF ($a,0.962143); do_MCF ($a,0.962700); do_MCF ($a,0.963230); do_MCF ($a,0.963735);
$y = 17 ; $a=51; do_MCF ($a,0.962251); do_MCF ($a,0.963048); do_MCF ($a,0.963807); do_MCF ($a,0.964529); do_MCF ($a,0.965216); do_MCF ($a,0.965869); do_MCF ($a,0.966491); do_MCF ($a,0.967083); do_MCF ($a,0.967645); do_MCF ($a,0.968180); do_MCF ($a,0.968689); do_MCF ($a,0.969173); do_MCF ($a,0.969633); do_MCF ($a,0.970071); do_MCF ($a,0.970487); do_MCF ($a,0.970882); do_MCF ($a,0.971259);
$y = 17 ; $a=52; do_MCF ($a,0.972472); do_MCF ($a,0.973003); do_MCF ($a,0.973507); do_MCF ($a,0.973986); do_MCF ($a,0.974442); do_MCF ($a,0.974876); do_MCF ($a,0.975288); do_MCF ($a,0.975679); do_MCF ($a,0.976052); do_MCF ($a,0.976406); do_MCF ($a,0.976742); do_MCF ($a,0.977062); do_MCF ($a,0.977366); do_MCF ($a,0.977655); do_MCF ($a,0.977929); do_MCF ($a,0.978190); do_MCF ($a,0.978438);
$y = 17 ; $a=53; do_MCF ($a,0.982278); do_MCF ($a,0.982538); do_MCF ($a,0.982786); do_MCF ($a,0.983021); do_MCF ($a,0.983245); do_MCF ($a,0.983457); do_MCF ($a,0.983659); do_MCF ($a,0.983851); do_MCF ($a,0.984033); do_MCF ($a,0.984206); do_MCF ($a,0.984370); do_MCF ($a,0.984526); do_MCF ($a,0.984674); do_MCF ($a,0.984815); do_MCF ($a,0.984949); do_MCF ($a,0.985076); do_MCF ($a,0.985197);
$y = 17 ; $a=54; do_MCF ($a,0.992006); do_MCF ($a,0.992006); do_MCF ($a,0.992006); do_MCF ($a,0.992006); do_MCF ($a,0.992006); do_MCF ($a,0.992006); do_MCF ($a,0.992006); do_MCF ($a,0.992006); do_MCF ($a,0.992006); do_MCF ($a,0.992006); do_MCF ($a,0.992006); do_MCF ($a,0.992006); do_MCF ($a,0.992006); do_MCF ($a,0.992006); do_MCF ($a,0.992006); do_MCF ($a,0.992006); do_MCF ($a,0.992006);
$y = 17 ; $a=55; do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304);
$y = 17 ; $a=56; do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562);
$y = 17 ; $a=57; do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749);
$y = 17 ; $a=58; do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); 
$y = 17 ; $a=59; do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); 
# MCF -- females Age 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 or more
$sex = "female";
$before_99 = "after";
$y = 34 ; $a=50; do_MCF ($a,0.964214);
$y = 34 ; $a=51; do_MCF ($a,0.971616); do_MCF ($a,0.971956);
$y = 34 ; $a=52; do_MCF ($a,0.978674); do_MCF ($a,0.978898); do_MCF ($a,0.979111);
$y = 34 ; $a=53; do_MCF ($a,0.985312); do_MCF ($a,0.985421); do_MCF ($a,0.985524); do_MCF ($a,0.985623);
$y = 34 ; $a=54; do_MCF ($a,0.992006); do_MCF ($a,0.992006); do_MCF ($a,0.992006); do_MCF ($a,0.992006); do_MCF ($a,0.992006);
$y = 34 ; $a=55; do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304); do_MCF ($a,1.003304);
$y = 34 ; $a=56; do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562); do_MCF ($a,1.002562);
$y = 34 ; $a=57; do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749); do_MCF ($a,1.001749);
$y = 34 ; $a=58; do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886); do_MCF ($a,1.000886);
$y = 34 ; $a=59; do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000);
$y = 34 ; $a=60; do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000);
$y = 34 ; $a=61; do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000);
$y = 34 ; $a=62; do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000);
$y = 34 ; $a=63; do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000);
$y = 34 ; $a=64; do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000);
$y = 34 ; $a=65; do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); 
$y = 34 ; $a=66; do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); do_MCF ($a,1.000000); 
# PCF -- males Age 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33
$sex = "male";
$before_99 = "after";
$y = 17 ; $a=33; do_PCF ($a,0.728533);
$y = 17 ; $a=34; do_PCF ($a,0.740863); do_PCF ($a,0.748268);
$y = 17 ; $a=35; do_PCF ($a,0.753287); do_PCF ($a,0.760291); do_PCF ($a,0.766600);
$y = 17 ; $a=36; do_PCF ($a,0.765884); do_PCF ($a,0.772483); do_PCF ($a,0.778425); do_PCF ($a,0.783768);
$y = 17 ; $a=37; do_PCF ($a,0.778487); do_PCF ($a,0.784696); do_PCF ($a,0.790282); do_PCF ($a,0.795303); do_PCF ($a,0.799810);
$y = 17 ; $a=38; do_PCF ($a,0.791249); do_PCF ($a,0.797060); do_PCF ($a,0.802287); do_PCF ($a,0.806982); do_PCF ($a,0.811195); do_PCF ($a,0.814972);
$y = 17 ; $a=39; do_PCF ($a,0.803913); do_PCF ($a,0.809339); do_PCF ($a,0.814216); do_PCF ($a,0.818594); do_PCF ($a,0.822522); do_PCF ($a,0.826042); do_PCF ($a,0.829195);
$y = 17 ; $a=40; do_PCF ($a,0.816633); do_PCF ($a,0.821666); do_PCF ($a,0.826187); do_PCF ($a,0.830244); do_PCF ($a,0.833882); do_PCF ($a,0.837141); do_PCF ($a,0.840058); do_PCF ($a,0.842668);
$y = 17 ; $a=41; do_PCF ($a,0.829695); do_PCF ($a,0.834317); do_PCF ($a,0.838467); do_PCF ($a,0.842190); do_PCF ($a,0.845526); do_PCF ($a,0.848513); do_PCF ($a,0.851186); do_PCF ($a,0.853577); do_PCF ($a,0.855714);
$y = 17 ; $a=42; do_PCF ($a,0.842861); do_PCF ($a,0.847052); do_PCF ($a,0.850812); do_PCF ($a,0.854183); do_PCF ($a,0.857202); do_PCF ($a,0.859905); do_PCF ($a,0.862323); do_PCF ($a,0.864485); do_PCF ($a,0.866416); do_PCF ($a,0.868142);
$y = 17 ; $a=43; do_PCF ($a,0.855984); do_PCF ($a,0.859734); do_PCF ($a,0.863097); do_PCF ($a,0.866110); do_PCF ($a,0.868807); do_PCF ($a,0.871221); do_PCF ($a,0.873379); do_PCF ($a,0.875307); do_PCF ($a,0.877030); do_PCF ($a,0.878569); do_PCF ($a,0.879942);
$y = 17 ; $a=44; do_PCF ($a,0.868736); do_PCF ($a,0.872079); do_PCF ($a,0.875075); do_PCF ($a,0.877758); do_PCF ($a,0.880159); do_PCF ($a,0.882306); do_PCF ($a,0.884225); do_PCF ($a,0.885940); do_PCF ($a,0.887471); do_PCF ($a,0.888838); do_PCF ($a,0.890058); do_PCF ($a,0.891146);
$y = 17 ; $a=45; do_PCF ($a,0.881076); do_PCF ($a,0.884046); do_PCF ($a,0.886707); do_PCF ($a,0.889088); do_PCF ($a,0.891218); do_PCF ($a,0.893122); do_PCF ($a,0.894823); do_PCF ($a,0.896343); do_PCF ($a,0.897700); do_PCF ($a,0.898910); do_PCF ($a,0.899991); do_PCF ($a,0.900954); do_PCF ($a,0.901814);
$y = 17 ; $a=46; do_PCF ($a,0.892974); do_PCF ($a,0.895605); do_PCF ($a,0.897960); do_PCF ($a,0.900067); do_PCF ($a,0.901951); do_PCF ($a,0.903635); do_PCF ($a,0.905138); do_PCF ($a,0.906481); do_PCF ($a,0.907680); do_PCF ($a,0.908749); do_PCF ($a,0.909703); do_PCF ($a,0.910554); do_PCF ($a,0.911312); do_PCF ($a,0.911988);
$y = 17 ; $a=47; do_PCF ($a,0.904493); do_PCF ($a,0.906807); do_PCF ($a,0.908878); do_PCF ($a,0.910729); do_PCF ($a,0.912384); do_PCF ($a,0.913862); do_PCF ($a,0.915181); do_PCF ($a,0.916359); do_PCF ($a,0.917411); do_PCF ($a,0.918348); do_PCF ($a,0.919184); do_PCF ($a,0.919930); do_PCF ($a,0.920595); do_PCF ($a,0.921187); do_PCF ($a,0.921715);
$y = 17 ; $a=48; do_PCF ($a,0.915580); do_PCF ($a,0.917600); do_PCF ($a,0.919407); do_PCF ($a,0.921022); do_PCF ($a,0.922464); do_PCF ($a,0.923752); do_PCF ($a,0.924901); do_PCF ($a,0.925927); do_PCF ($a,0.926842); do_PCF ($a,0.927658); do_PCF ($a,0.928386); do_PCF ($a,0.929035); do_PCF ($a,0.929613); do_PCF ($a,0.930128); do_PCF ($a,0.930587); do_PCF ($a,0.930996);
$y = 17 ; $a=49; do_PCF ($a,0.926993); do_PCF ($a,0.928707); do_PCF ($a,0.930240); do_PCF ($a,0.931608); do_PCF ($a,0.932830); do_PCF ($a,0.933920); do_PCF ($a,0.934893); do_PCF ($a,0.935761); do_PCF ($a,0.936535); do_PCF ($a,0.937225); do_PCF ($a,0.937840); do_PCF ($a,0.938388); do_PCF ($a,0.938877); do_PCF ($a,0.939312); do_PCF ($a,0.939700); do_PCF ($a,0.940045); do_PCF ($a,0.940353);
$y = 17 ; $a=50; do_PCF ($a,0.938622); do_PCF ($a,0.940020); do_PCF ($a,0.941267); do_PCF ($a,0.942381); do_PCF ($a,0.943375); do_PCF ($a,0.944261); do_PCF ($a,0.945052); do_PCF ($a,0.945756); do_PCF ($a,0.946385); do_PCF ($a,0.946945); do_PCF ($a,0.947443); do_PCF ($a,0.947888); do_PCF ($a,0.948284); do_PCF ($a,0.948637); do_PCF ($a,0.948951); do_PCF ($a,0.949231); do_PCF ($a,0.949480);
$y = 17 ; $a=51; do_PCF ($a,0.950494); do_PCF ($a,0.951563); do_PCF ($a,0.952517); do_PCF ($a,0.953368); do_PCF ($a,0.954126); do_PCF ($a,0.954802); do_PCF ($a,0.955405); do_PCF ($a,0.955942); do_PCF ($a,0.956420); do_PCF ($a,0.956847); do_PCF ($a,0.957227); do_PCF ($a,0.957565); do_PCF ($a,0.957866); do_PCF ($a,0.958134); do_PCF ($a,0.958373); do_PCF ($a,0.958586); do_PCF ($a,0.958775);
$y = 17 ; $a=52; do_PCF ($a,0.962309); do_PCF ($a,0.963036); do_PCF ($a,0.963684); do_PCF ($a,0.964261); do_PCF ($a,0.964775); do_PCF ($a,0.965233); do_PCF ($a,0.965641); do_PCF ($a,0.966004); do_PCF ($a,0.966328); do_PCF ($a,0.966616); do_PCF ($a,0.966873); do_PCF ($a,0.967101); do_PCF ($a,0.967304); do_PCF ($a,0.967485); do_PCF ($a,0.967647); do_PCF ($a,0.967790); do_PCF ($a,0.967918);
$y = 17 ; $a=53; do_PCF ($a,0.973949); do_PCF ($a,0.974318); do_PCF ($a,0.974646); do_PCF ($a,0.974938); do_PCF ($a,0.975198); do_PCF ($a,0.975430); do_PCF ($a,0.975636); do_PCF ($a,0.975819); do_PCF ($a,0.975982); do_PCF ($a,0.976127); do_PCF ($a,0.976257); do_PCF ($a,0.976372); do_PCF ($a,0.976474); do_PCF ($a,0.976565); do_PCF ($a,0.976646); do_PCF ($a,0.976718); do_PCF ($a,0.976783);
$y = 17 ; $a=54; do_PCF ($a,0.985368); do_PCF ($a,0.985368); do_PCF ($a,0.985368); do_PCF ($a,0.985368); do_PCF ($a,0.985368); do_PCF ($a,0.985368); do_PCF ($a,0.985368); do_PCF ($a,0.985368); do_PCF ($a,0.985368); do_PCF ($a,0.985368); do_PCF ($a,0.985368); do_PCF ($a,0.985368); do_PCF ($a,0.985368); do_PCF ($a,0.985368); do_PCF ($a,0.985368); do_PCF ($a,0.985368); do_PCF ($a,0.985368); 
$y = 17 ; $a=55; do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); 
# PCF -- males Age 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 or more
$sex = "male";
$before_99 = "after";
$y = 34 ; $a=50; do_PCF ($a,0.949702);
$y = 34 ; $a=51; do_PCF ($a,0.958944); do_PCF ($a,0.959094);
$y = 34 ; $a=52; do_PCF ($a,0.968032); do_PCF ($a,0.968133); do_PCF ($a,0.968223);
$y = 34 ; $a=53; do_PCF ($a,0.976840); do_PCF ($a,0.976891); do_PCF ($a,0.976936); do_PCF ($a,0.976976);
$y = 34 ; $a=54; do_PCF ($a,0.985368); do_PCF ($a,0.985368); do_PCF ($a,0.985368); do_PCF ($a,0.985368); do_PCF ($a,0.985368);
$y = 34 ; $a=55; do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000);
$y = 34 ; $a=56; do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000);
$y = 34 ; $a=57; do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000);
$y = 34 ; $a=58; do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000);
$y = 34 ; $a=59; do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000);
$y = 34 ; $a=60; do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000);
$y = 34 ; $a=61; do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000);
$y = 34 ; $a=62; do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000);
$y = 34 ; $a=63; do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000);
$y = 34 ; $a=64; do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000);
$y = 34 ; $a=65; do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); 
$y = 34 ; $a=66; do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); 
# PCF -- females Age 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33
$sex = "female";
$before_99 = "after";
$y = 17 ; $a=33; do_PCF ($a,0.678151);
$y = 17 ; $a=34; do_PCF ($a,0.699706); do_PCF ($a,0.705723);
$y = 17 ; $a=35; do_PCF ($a,0.720016); do_PCF ($a,0.725619); do_PCF ($a,0.731000);
$y = 17 ; $a=36; do_PCF ($a,0.739382); do_PCF ($a,0.744599); do_PCF ($a,0.749606); do_PCF ($a,0.754409);
$y = 17 ; $a=37; do_PCF ($a,0.757874); do_PCF ($a,0.762731); do_PCF ($a,0.767389); do_PCF ($a,0.771856); do_PCF ($a,0.776137);
$y = 17 ; $a=38; do_PCF ($a,0.775483); do_PCF ($a,0.780009); do_PCF ($a,0.784347); do_PCF ($a,0.788505); do_PCF ($a,0.792487); do_PCF ($a,0.796299);
$y = 17 ; $a=39; do_PCF ($a,0.792606); do_PCF ($a,0.796802); do_PCF ($a,0.800823); do_PCF ($a,0.804673); do_PCF ($a,0.808360); do_PCF ($a,0.811887); do_PCF ($a,0.815261);
$y = 17 ; $a=40; do_PCF ($a,0.809160); do_PCF ($a,0.813033); do_PCF ($a,0.816741); do_PCF ($a,0.820290); do_PCF ($a,0.823686); do_PCF ($a,0.826935); do_PCF ($a,0.830041); do_PCF ($a,0.833010);
$y = 17 ; $a=41; do_PCF ($a,0.825400); do_PCF ($a,0.828948); do_PCF ($a,0.832344); do_PCF ($a,0.835592); do_PCF ($a,0.838699); do_PCF ($a,0.841669); do_PCF ($a,0.844508); do_PCF ($a,0.847220); do_PCF ($a,0.849810);
$y = 17 ; $a=42; do_PCF ($a,0.841084); do_PCF ($a,0.844311); do_PCF ($a,0.847398); do_PCF ($a,0.850349); do_PCF ($a,0.853170); do_PCF ($a,0.855866); do_PCF ($a,0.858441); do_PCF ($a,0.860901); do_PCF ($a,0.863249); do_PCF ($a,0.865491);
$y = 17 ; $a=43; do_PCF ($a,0.856172); do_PCF ($a,0.859083); do_PCF ($a,0.861866); do_PCF ($a,0.864526); do_PCF ($a,0.867067); do_PCF ($a,0.869494); do_PCF ($a,0.871811); do_PCF ($a,0.874024); do_PCF ($a,0.876135); do_PCF ($a,0.878150); do_PCF ($a,0.880072);
$y = 17 ; $a=44; do_PCF ($a,0.870616); do_PCF ($a,0.873224); do_PCF ($a,0.875716); do_PCF ($a,0.878096); do_PCF ($a,0.880369); do_PCF ($a,0.882539); do_PCF ($a,0.884611); do_PCF ($a,0.886587); do_PCF ($a,0.888473); do_PCF ($a,0.890272); do_PCF ($a,0.891987); do_PCF ($a,0.893622);
$y = 17 ; $a=45; do_PCF ($a,0.884353); do_PCF ($a,0.886673); do_PCF ($a,0.888890); do_PCF ($a,0.891006); do_PCF ($a,0.893025); do_PCF ($a,0.894953); do_PCF ($a,0.896791); do_PCF ($a,0.898545); do_PCF ($a,0.900218); do_PCF ($a,0.901813); do_PCF ($a,0.903333); do_PCF ($a,0.904782); do_PCF ($a,0.906163);
$y = 17 ; $a=46; do_PCF ($a,0.897392); do_PCF ($a,0.899440); do_PCF ($a,0.901395); do_PCF ($a,0.903260); do_PCF ($a,0.905040); do_PCF ($a,0.906738); do_PCF ($a,0.908357); do_PCF ($a,0.909901); do_PCF ($a,0.911373); do_PCF ($a,0.912775); do_PCF ($a,0.914112); do_PCF ($a,0.915386); do_PCF ($a,0.916599); do_PCF ($a,0.917755);
$y = 17 ; $a=47; do_PCF ($a,0.909726); do_PCF ($a,0.911516); do_PCF ($a,0.913224); do_PCF ($a,0.914854); do_PCF ($a,0.916407); do_PCF ($a,0.917888); do_PCF ($a,0.919300); do_PCF ($a,0.920646); do_PCF ($a,0.921928); do_PCF ($a,0.923150); do_PCF ($a,0.924314); do_PCF ($a,0.925423); do_PCF ($a,0.926479); do_PCF ($a,0.927484); do_PCF ($a,0.928441);
$y = 17 ; $a=48; do_PCF ($a,0.921366); do_PCF ($a,0.922913); do_PCF ($a,0.924387); do_PCF ($a,0.925792); do_PCF ($a,0.927132); do_PCF ($a,0.928408); do_PCF ($a,0.929625); do_PCF ($a,0.930784); do_PCF ($a,0.931888); do_PCF ($a,0.932939); do_PCF ($a,0.933940); do_PCF ($a,0.934894); do_PCF ($a,0.935801); do_PCF ($a,0.936666); do_PCF ($a,0.937488); do_PCF ($a,0.938271);
$y = 17 ; $a=49; do_PCF ($a,0.932937); do_PCF ($a,0.934234); do_PCF ($a,0.935470); do_PCF ($a,0.936648); do_PCF ($a,0.937770); do_PCF ($a,0.938838); do_PCF ($a,0.939856); do_PCF ($a,0.940825); do_PCF ($a,0.941748); do_PCF ($a,0.942626); do_PCF ($a,0.943462); do_PCF ($a,0.944258); do_PCF ($a,0.945016); do_PCF ($a,0.945737); do_PCF ($a,0.946423); do_PCF ($a,0.947075); do_PCF ($a,0.947696);
$y = 17 ; $a=50; do_PCF ($a,0.944409); do_PCF ($a,0.945451); do_PCF ($a,0.946443); do_PCF ($a,0.947387); do_PCF ($a,0.948286); do_PCF ($a,0.949142); do_PCF ($a,0.949957); do_PCF ($a,0.950733); do_PCF ($a,0.951471); do_PCF ($a,0.952173); do_PCF ($a,0.952841); do_PCF ($a,0.953477); do_PCF ($a,0.954082); do_PCF ($a,0.954657); do_PCF ($a,0.955205); do_PCF ($a,0.955725); do_PCF ($a,0.956221);
$y = 17 ; $a=51; do_PCF ($a,0.955644); do_PCF ($a,0.956427); do_PCF ($a,0.957173); do_PCF ($a,0.957882); do_PCF ($a,0.958557); do_PCF ($a,0.959200); do_PCF ($a,0.959811); do_PCF ($a,0.960392); do_PCF ($a,0.960944); do_PCF ($a,0.961470); do_PCF ($a,0.961970); do_PCF ($a,0.962446); do_PCF ($a,0.962898); do_PCF ($a,0.963328); do_PCF ($a,0.963737); do_PCF ($a,0.964126); do_PCF ($a,0.964495);
$y = 17 ; $a=52; do_PCF ($a,0.966603); do_PCF ($a,0.967124); do_PCF ($a,0.967620); do_PCF ($a,0.968092); do_PCF ($a,0.968540); do_PCF ($a,0.968966); do_PCF ($a,0.969371); do_PCF ($a,0.969756); do_PCF ($a,0.970122); do_PCF ($a,0.970470); do_PCF ($a,0.970801); do_PCF ($a,0.971116); do_PCF ($a,0.971415); do_PCF ($a,0.971699); do_PCF ($a,0.971969); do_PCF ($a,0.972225); do_PCF ($a,0.972469);
$y = 17 ; $a=53; do_PCF ($a,0.977191); do_PCF ($a,0.977448); do_PCF ($a,0.977692); do_PCF ($a,0.977923); do_PCF ($a,0.978143); do_PCF ($a,0.978352); do_PCF ($a,0.978551); do_PCF ($a,0.978740); do_PCF ($a,0.978919); do_PCF ($a,0.979089); do_PCF ($a,0.979251); do_PCF ($a,0.979404); do_PCF ($a,0.979550); do_PCF ($a,0.979689); do_PCF ($a,0.979821); do_PCF ($a,0.979946); do_PCF ($a,0.980065);
$y = 17 ; $a=54; do_PCF ($a,0.987780); do_PCF ($a,0.987780); do_PCF ($a,0.987780); do_PCF ($a,0.987780); do_PCF ($a,0.987780); do_PCF ($a,0.987780); do_PCF ($a,0.987780); do_PCF ($a,0.987780); do_PCF ($a,0.987780); do_PCF ($a,0.987780); do_PCF ($a,0.987780); do_PCF ($a,0.987780); do_PCF ($a,0.987780); do_PCF ($a,0.987780); do_PCF ($a,0.987780); do_PCF ($a,0.987780); do_PCF ($a,0.987780); 
$y = 17 ; $a=55; do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); 
# PCF -- females Age 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 or more
$sex = "female";
$before_99 = "after";
$y = 34 ; $a=50; do_PCF ($a,0.956692);
$y = 34 ; $a=51; do_PCF ($a,0.964847); do_PCF ($a,0.965181);
$y = 34 ; $a=52; do_PCF ($a,0.972701); do_PCF ($a,0.972921); do_PCF ($a,0.973131);
$y = 34 ; $a=53; do_PCF ($a,0.980178); do_PCF ($a,0.980285); do_PCF ($a,0.980387); do_PCF ($a,0.980484);
$y = 34 ; $a=54; do_PCF ($a,0.987780); do_PCF ($a,0.987780); do_PCF ($a,0.987780); do_PCF ($a,0.987780); do_PCF ($a,0.987780);
$y = 34 ; $a=55; do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000);
$y = 34 ; $a=56; do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000);
$y = 34 ; $a=57; do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000);
$y = 34 ; $a=58; do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000);
$y = 34 ; $a=59; do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000);
$y = 34 ; $a=60; do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000);
$y = 34 ; $a=61; do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000);
$y = 34 ; $a=62; do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000);
$y = 34 ; $a=63; do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000);
$y = 34 ; $a=64; do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000);
$y = 34 ; $a=65; do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); 
$y = 34 ; $a=66; do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); do_PCF ($a,1.000000); 

sub do_pss
{
    setup_member ();
    $final_ABF = ($ABFyms * (12 - $MemberAgeMonths) + $ABFyms_plusone * $MemberAgeMonths) / 12;
    $final_MCF = ($MCFyms * (12 - $MemberAgeMonths) + $MCFyms_plusone * $MemberAgeMonths) / 12;
    $final_PCF = ($PCFyms * (12 - $MemberAgeMonths) + $PCFyms_plusone * $MemberAgeMonths) / 12;
    $FamilyLawValuation = $ABM * $AS * $final_ABF + $AMC * (1 - $final_MCF) + $APC * (1 - $final_PCF) + $ATA - $ERDA;
    $FamilyLawValuation =~ s/\.(\d\d).*/.$1/;

    # Read in from pss..
    my $val = `type pss.html`;
    if ($DEBUG >= 2) { print $val; }

    $val =~ s/\$ABFyms_plusone/xxx$ABFyms_plusone.yyy/img;
    $val =~ s/\$ABFyms/xxx$ABFyms.yyy/img;
    $val =~ s/\$ABM/xxx$ABM.yyy/img;
    $val =~ s/\$AMC/xxx$AMC.yyy/img;
    $val =~ s/\$APC/xxx$APC.yyy/img;
    $val =~ s/\$AS/xxx$AS.yyy/img;
    $val =~ s/\$ATA/xxx$ATA.yyy/img;
    $val =~ s/\$ERDA/xxx$ERDA.yyy/img;
    $val =~ s/\$FamilyLawValuation/xxx$FamilyLawValuation.yyy/img;
    $val =~ s/\$MCFyms_plusone/xxx$MCFyms_plusone.yyy/img;
    $val =~ s/\$MCFyms/xxx$MCFyms.yyy/img;
    $val =~ s/\$MemberAgeMonths/xxx$MemberAgeMonths.yyy/img;
    $val =~ s/\$MemberAgeYears/xxx$MemberAgeYears.yyy/img;
    $val =~ s/\$PCFyms_plusone/xxx$PCFyms_plusone.yyy/img;
    $val =~ s/\$PCFyms/xxx$PCFyms.yyy/img;
    $val =~ s/\$RelevantDate/xxx$RelevantDate.yyy/img;
    $val =~ s/\$SurchargeDebt/xxx$SurchargeDebt.yyy/img;
    $val =~ s/\$YearsScheme/xxx$YearsScheme.yyy/img;
    $val =~ s/\$final_ABF/xxx$final_ABF.yyy/img;
    $val =~ s/\$final_MCF/xxx$final_MCF.yyy/img;
    $val =~ s/\$final_PCF/xxx$final_PCF.yyy/img;
    $val =~ s/\$yyyymmdd/xxx$yyyymmdd.yyy/img;
    $val =~ s/\$Birthday/xxx$Birthday.yyy/img;
    $val =~ s/\$MemberName/xxx$MemberName.yyy/img;
    $val =~ s/\$MemberReference/xxx$MemberReference.yyy/img;
    $val =~ s/\\\$/\$/img;
    $val =~ s/\\\"/"/img;
    $val =~ s/xxx//img;
    $val =~ s/\.yyy//img;
    $val =~ s/\.(\d\d\d\d\d\d\d\d)\d+/.$1/img;
    $val =~ s/\$(\d\d\d+) /\$$1.00 /img;
    $val =~ s/\$(\d\d\d+)\.(\d) /\$$1.$2zzz /img;
    $val =~ s/zzz/0/img;
    $val =~ s/\$(\d+)(\d\d\d)(\d\d\d)\./\$$1,$2,$3./img;
    $val =~ s/\$(\d+)(\d\d\d)\./\$$1,$2./img;

    my $file = $RelevantDate;
    $file =~ s/\W/_/g;
    open (OUTPUT_HTML, ">./$file.new.html");
    print OUTPUT_HTML $val;
    close (OUTPUT_HTML);
    
    return $val;
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
            #print ("Reading in at the moment - '$header'!!\n");
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

sub fix_url
{
    my $txt = $_ [0]; 
    $txt =~ s/%20/ /g;
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
    return $txt;
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
    my $port = 7732; # PSSDB
    my $num_connections = 0;
    my $trusted_client;
    my $data_from_client;
    $|=1;

    socket (SERVER, PF_INET, SOCK_STREAM, $proto) or die "Failed to create a socket: $!";
    setsockopt (SERVER, SOL_SOCKET, SO_REUSEADDR, 1) or die "setsocketopt: $!";

    # bind to a port, then listen
    bind (SERVER, sockaddr_in ($port, INADDR_ANY)) or die "Can't bind to port $port! \n";

    listen (SERVER, 10) or die "listen: $!";
    print ("Listening on port: $port\n");
    my $accept_fail_counter;
    my $count;
    my $not_seen_full = 1;
    set_params_fake ();

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
        $txt =~ s/^.*GET%20\///;
        $txt =~ s/^.*GET \///;

        print ("2- - - - - - -\n");
        my $have_to_write_to_socket = 1;

        chomp ($txt);
        my $original_get = $txt;

        if ($original_get =~ m/set_params_1/) { set_params_1 (); }

        if ($original_get =~ m/\?/img)
        {
            if ($txt =~ m/MemberSex=(.*?)&/im) { $MemberSex = $1; }
            if ($txt =~ m/Birthday=(.*?)&/im) { $Birthday = $1; }
            if ($txt =~ m/RelevantDate=(.*?)&/im) { $RelevantDate = $1; }
            if ($txt =~ m/FirstDateMembership=(.*?)&/im) { $FirstDateMembership = $1; }
            if ($txt =~ m/YearsScheme=(.*?)&/im) { $YearsScheme = $1; }
            $RelevantDate = get_yymondd ($RelevantDate);

            my $first_year_membership = get_yymondd ($FirstDateMembership);
            if ($FirstDateMembership =~ m/.*-(\d\d\d\d)/)
            {
                $first_year_membership = $1;
                if ($RelevantDate =~ m/.*-(\d\d\d\d)/)
                {
                    my $relevant_year_membership = $1;

                    my $rel_month = get_month ($RelevantDate);
                    my $fy_month = get_month ($FirstDateMembership);
                    my $rel_day = get_day ($RelevantDate);
                    my $fy_day = get_day ($FirstDateMembership);
                    $YearsScheme = $relevant_year_membership - $first_year_membership;

                    if ($rel_month < $fy_month)
                    {
                        $YearsScheme --;
                    }
                    if ($rel_month == $fy_month)
                    {
                        if ($rel_day < $fy_day)
                        {
                            $YearsScheme --;
                        }
                    }
                    print (" >>> $YearsScheme , $RelevantDate , $first_year_membership\n");
                }
            }

            if ($txt =~ m/AS=(.*?)&/im) { $AS = $1; }
            if ($txt =~ m/ABM=(.*?)&/im) { $ABM = $1; }
            if ($txt =~ m/AMC=(.*?)&/im) { $AMC = $1; }
            if ($txt =~ m/APC=(.*?)&/im) { $APC = $1; }
            if ($txt =~ m/ATA=(.*?)&/im) { $ATA  = $1; }
            if ($txt =~ m/ERDA=(.*?)&/im) { $ERDA = $1; }
            if ($txt =~ m/SurchargeDebt=(.*?)&/im) { $SurchargeDebt = $1; }
            if ($txt =~ m/MemberAgeYears=(.*?)&/im) { $MemberAgeYears = $1; print ("a22>> ($RelevantDate vs $Birthday) $MemberAgeYears = $relevant_year - $birth_year;\n"); }
            if ($txt =~ m/MemberAgeMonths=(.*?)&/im) { $MemberAgeMonths = $1; }

            $AS =~ s/\.(\d\d)\d*/.$1/;
            $AMC =~ s/\.(\d\d)\d*/.$1/;
            $ATA =~ s/\.(\d\d)\d*/.$1/;
            $APC =~ s/\.(\d\d)\d*/.$1/;
            $ABM =~ s/\.(\d\d\d\d\d\d\d\d)\d*/.$1/;

            print_debug ();
        }

        $original_get = $txt;
        {
            my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
            my $yyyymmdd = sprintf "%.4d%.2d%.2d", $year+1900, $mon+1, $mday;

            $original_get =~  s/ HTTP.*//;
            my @args;
            my $i = 0;
            while ($original_get =~ s/do_pss\?([^&]*)&/do_pss?/ && $i < 20)
            {
                $args [$i] = $1;
                $i++;
            }

            my $pss_html = do_pss ();
            my $form;
            $form = "<form action=\"\">";
            $form .= "<table>";
            $form .= "<tr><td>Super Type: &nbsp;</td><td><input id=supra type=\"text\" size=40 value=\"PSS\"><br></td></tr>";
            $form .= "<tr><td>Interest Type: &nbsp;</td><td><input id=int type=\"text\" size=40 value=\"Growth Phase\"><br></td></tr>";
            $form .= "<tr><td>Valuation Type: &nbsp;</td><td><input id=val type=\"text\" size=60 value=\"Valuation type	Schedule 1, Part 2, Division 2.2, Item 1\"><br></td></tr>"; 
            $form .= "<tr><td>Gender of member: &nbsp;</td><td><input id=gen type=\"text\" size=15 value=\"$MemberSex\"><br></td></tr>"; 
            $form .= "<tr><td>Birthday: &nbsp;</td><td><input id=bir type=\"text\" size=15 value=\"$Birthday\"><br></td></tr>"; 
            $form .= "<tr><td>Relevant (appropriate) date: &nbsp;</td><td><input id=rel type=\"text\" size=15 value=\"$RelevantDate\"><br></td></tr>"; 
            $form .= "<tr><td>Accrued Benefit Multiple (ABM): &nbsp;</td><td><input id=acc type=\"text\" size=15 value=\"$ABM\"><br></td></tr>"; 
            $form .= "<tr><td>Accumulated Member Contributions (AMC): &nbsp;</td><td><input id=amc type=\"text\" size=15 value=\"$AMC\"><br></td></tr>"; 
            $form .= "<tr><td>Accumulated Productivity Contributions (APC): &nbsp;</td><td><input id=apc type=\"text\" size=15 value=\"$APC\"><br></td></tr>"; 
            $form .= "<tr><td>Accumulated Transfer Amounts (ATA): &nbsp;</td><td><input id=ata type=\"text\" size=15 value=\"$ATA\"><br></td></tr>"; 
            $form .= "<tr><td>Early Release Deduction Amount (ERDA): &nbsp;</td><td><input id=erda type=\"text\" size=15 value=\"$ERDA\"><br></td></tr>"; 
            $form .= "<tr><td>First date of membership: &nbsp;</td><td><input id=fdm type=\"text\" size=15 value=\"$FirstDateMembership\"><br></td></tr>"; 
            $form .= "<tr><td>Average Salary (AS): &nbsp;</td><td><input id=avgsal type=\"text\" size=15 value=\"$AS\"><br></td></tr>"; 
            $form .= "<tr><td>Surcharge debt: &nbsp;</td><td><input id=sur type=\"text\" size=15 value=\"$SurchargeDebt\"><br></td></tr>"; 
            $form .= "<tr><td>Is the superannuation interest still subject to an earlier payment split?: &nbsp;</td><td><input id=paysplit  type=\"text\" size=15 value=\"No\"><br></td></tr>"; 
            $form .= "<tr><td>Excess Contributions Multiple: &nbsp;</td><td><input id=exc type=\"text\" size=15 value=\"0\"><br></td></tr>"; 
            $form .= "<tr><td>Years from date first joined scheme: &nbsp;</td><td><input id=yrsfm type=\"text\" size=15 value=\"$YearsScheme\"><br></td></tr>"; 
            $form .= "<tr><td>Member age: Years:&nbsp;</td><td><input id=years type=\"text\" size=15 value=\"$MemberAgeYears\"><br></td></tr>";
            $form .= "<tr><td>Member age: Months: &nbsp;</td><td><input id=months type=\"text\" size=15 value=\"$MemberAgeMonths\"><br></td></tr>"; 
            $form .= "</table>";
            $form .= "
            <a onclick=\"javascript: 
var supra = document.getElementById('supra').value; 
var int = document.getElementById('int').value; 
var val = document.getElementById('val').value; 
var gen = 'MemberSex=' + document.getElementById('gen').value; 
var bir = 'Birthday=' + document.getElementById('bir').value; 
var rel = 'RelevantDate=' + document.getElementById('rel').value; 
var acc = 'ABM=' + document.getElementById('acc').value; 
var amc = 'AMC=' + document.getElementById('amc').value; 
var apc = 'APC=' + document.getElementById('apc').value; 
var ata = 'ATA=' + document.getElementById('ata').value; 
var erda = 'ERDA=' + document.getElementById('erda').value; 
var fdm = 'FirstDateMembership=' + document.getElementById('fdm').value; 
var avgsal = 'AS=' + document.getElementById('avgsal').value; 
var sur = 'SurchargeDebt=' + document.getElementById('sur').value; 
var paysplit  = document.getElementById('paysplit').value;  
var exc = document.getElementById('exc').value; 
var yrsfm = 'YearsScheme=' + document.getElementById('yrsfm').value; 
var years = 'MemberAgeYears=' + document.getElementById('years').value; 
var months = 'MemberAgeMonths=' + document.getElementById('months').value;
var full = location.protocol+'//'+location.hostname+(location.port ? ':'+location.port: ''); full = full+'/do_pss?'+supra+'&'+int+'&'+val+'&'+gen+'&'+bir+'&'+rel+'&'+acc+'&'+amc+'&'+apc+'&'+ata+'&'+erda+'&'+fdm+'&'+avgsal+'&'+sur+'&'+paysplit+'&'+exc+'&'+yrsfm+'&'+years+'&'+months;
var resubmit=document.getElementById('resubmit'); resubmit.href=full;\">
            <font color=blue size=+2><u>Update the query (click here):</u></font></a>&nbsp;&nbsp; 
            "; 
            $form .= "<br><a id=\"resubmit\" href=\"$Birthday&$RelevantDate&$ABM&$AMC&$APC&$ATA&$ERDA&$FirstDateMembership&$AS&$SurchargeDebt&$YearsScheme&$MemberAgeYears&$MemberAgeMonths&$FamilyLawValuation&$StartedBefore&$MemberSex&$MemberInfo&$MemberInfo_plusone&$MemberName&$MemberReference\">Resubmit</a><br>";
            $form .= "<br><a href=\"set_params_1\">SetParams1</a>&nbsp;";
            my $debug = get_debug ();
            $form .= "<br>Debug:<br>$debug<br><br>$pss_html";

            write_to_socket (\*CLIENT, $form, "", "noredirect");
            next;
        }

        print ("============================================================\n");
    }
}
