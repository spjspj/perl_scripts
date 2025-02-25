#!/usr/bin/perl

use 5.010;
use Compress::Raw::Zlib;
use Digest::MD5 qw(md5 md5_hex md5_base64);
use File::Copy;
use LWP::Simple;
use MIME::Base64 qw(encode_base64url decode_base64url);
use POSIX qw(strftime);
use Socket;
use bytes;
use strict;
use warnings;

# Variables:
my $DATE_ADMIN = "bbbbb";
my $SomeDate = "bbbbb";
my $NumberA = "Accccc";
my $NumberB = "Bbbbbb";
my $NumberC = "Cbbbbb";
my $NumberD = "Dbbbbb";
my $Place = "bbbbb";
my $ADMIN_DATE = "bbbbb";
my $EFFECTIVE_DATE = "bbbbb";
my $NumberE = "Ebbbbb";
my $NumberF = "Fbbbbb";
my $NumberG = "Gbbbbb";
my $old_date_yyyymmdd = "bbbbb";
my $old_date_yyyy_mm_dd = "bbbbb";
my $infile;
my $outfile;
my $overall_text;
my $tj;
my $this_tj;

sub compress
{
    my $input = $_ [0];
    my $deflate;
    $deflate = Compress::Raw::Zlib::Deflate->new
        (
         -WindowBits   => 15, 
         -AppendOutput => 1 
        );
    my $compressed_bytes = '';
    my $status = $deflate->deflate($input, $compressed_bytes);
    $status = $deflate->flush($compressed_bytes);

    my $hcb = unpack("H*", $compressed_bytes);
    my $compressed = pack("H*", $hcb);
    return $compressed;
}

sub decompress
{
    my $compressed = $_ [0];
    my $decompressed;
    my $inflate = Compress::Raw::Zlib::Inflate->new ();
    my $status = $inflate->inflate($compressed, $decompressed);
    return $decompressed;
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
    elsif ($month == 2) { $month = "Feb" ; }
    elsif ($month == 3) { $month = "Mar" ; }
    elsif ($month == 4) { $month = "Apr" ; }
    elsif ($month == 5) { $month = "May" ; }
    elsif ($month == 6) { $month = "Jun" ; }
    elsif ($month == 7) { $month = "Jul" ; }
    elsif ($month == 8) { $month = "Aug" ; }
    elsif ($month == 9) { $month = "Sep" ; }
    elsif ($month == 10) { $month = "Oct" ; }
    elsif ($month == 11) { $month = "Nov" ; }
    elsif ($month == 12) { $month = "Dec" ; }

    my $ret = "$day $month $year";
    if ($ret =~ m/^\d /)
    {
        $ret = "0$ret";
    }
    return $ret;
}

sub get_yyyymmdd
{
    my $yymondd = $_ [0];
    my $year;
    my $month;
    my $day;

    if ($yymondd =~ m/^(\d\d\d\d)(\d\d)(\d\d)$/i)
    {
        # YYYYMMDD
        return $yymondd;
    }
    elsif ($yymondd =~ m/^(\d\d).([A-Z][a-z][a-z]).(\d\d\d\d)$/i)
    {
        $day = $1;
        $month = lc($2);
        $year = $3;
    }
    
    if ($month eq "jan") { $month = 1 ; }
    elsif ($month eq "feb") { $month = 2 ; }
    elsif ($month eq "mar") { $month = 3 ; }
    elsif ($month eq "apr") { $month = 4 ; }
    elsif ($month eq "may") { $month = 5 ; }
    elsif ($month eq "jun") { $month = 6 ; }
    elsif ($month eq "jul") { $month = 7 ; }
    elsif ($month eq "aug") { $month = 8 ; }
    elsif ($month eq "sep") { $month = 9 ; }
    elsif ($month eq "oct") { $month = 10 ; }
    elsif ($month eq "nov") { $month = 11 ; }
    elsif ($month eq "dec") { $month = 12 ; }

    my $ret = "$year";
    if ($month < 10) { $ret .= "0$month"; } else { $ret .= "$month"; }
    if ($day < 10) { $day =~ s/^0*//; $ret .= "0$day"; } else { $ret .= "$day"; }
    return $ret;
}

sub get_dollar
{
    my $in = $_ [0];
    if ($in =~ m/^(\d+)\.(\d\d)\d*$/)
    {
        return "\$$1.$2";
    }
    if ($in =~ m/^(\d+)\.(\d)$/)
    {
        return "\$$1.$2" . "0";
    }
    if ($in =~ m/^(\d+)$/)
    {
        return "\$$1.00";
    }
    return "$in";
}

sub round_to_eight
{
    my $in = $_ [0] . "000000000000000000000000";
    
    if ($in =~ m/^(\d)\.(\d{8}).*$/)
    {
        return "$1.$2";
    }
    return $in;
}

sub hex_val
{
    my $v = $_ [0];
    
    if ($v =~ m/\d/) { return $v; }
    if ($v eq "a") { return 10; }
    if ($v eq "b") { return 11; }
    if ($v eq "c") { return 12; }
    if ($v eq "d") { return 13; }
    if ($v eq "e") { return 14; }
    if ($v eq "f") { return 15; }
    return $v;
}

sub to_hex_val
{
    my $v = $_ [0];
    
    if ($v eq 10) { return "a"; }
    if ($v eq 11) { return "b"; }
    if ($v eq 12) { return "c"; }
    if ($v eq 13) { return "d"; }
    if ($v eq 14) { return "e"; }
    if ($v eq 15) { return "f"; }
    return $v;
}

sub print_str
{
    my $str = $_ [0];
    my $orig_str = $str;
    my $this_s;

    while ($str =~ s/(.)(.)//)
    {
        my $a = hex_val ($1) * 16;
        my $b = hex_val ($2);
        #print ($a+$b, " ");
        $this_s .= chr ($a+$b);
    }

    if ($this_s =~ m/ +[A-Z]/)
    {
        $this_s .= "   $this_tj$orig_str<<\n";
        $this_tj = "   >> TJ=";
    }
    else
    {
        $this_tj .= "\n    str:($this_s) $orig_str :";
    }
    return $this_s; 
}

sub get_pdf_text
{
    my $text = $_ [0];
    # hh hh hh hh hh << hex based on two 
    while ($text =~ s/^(.*)\n//im)
    {
        my $line = $1;
        if ($line =~ m/<([0-9a-f]+)>.*?Tj/)
        {
            my $str = $1;
            my $this_s = print_str ($str);
            $overall_text .= $this_s;
        }
    }
}

sub get_tj_val
{
    my $text = $_ [0];
    my $tj;
    while ($text =~ s/^(.)//)
    {
        my $c2 = $1;
        my $c = ord ($c2);
        my $a2 = $c % 16;
        my $a1 = ($c - $a2) / 16;
        $tj .= to_hex_val ("$a1") . to_hex_val ("$a2");
    }
    return $tj;
}

sub check_if_has_text
{
    my $text = $_ [0];
    my $thing = $_ [1];

    $thing = get_tj_val ($thing);

    if ($text =~ m/$thing/)
    {
        return 1;
    }
    return 0;
}

my $old_ADMIN_DATE = "aaaaa";
my $old_Date = "aaaaa";
my $old_NumberA = "aaaaa";
my $old_NumberB = "aaaaa";
my $old_NumberC = "aaaaa";
my $old_NumberD = "aaaaa";
my $old_PLACE = "aaaaa";
my $old_NumberE = "aaaaa";
my $old_NumberF = "aaaaa";
my $old_NumberG = "aaaaa";

sub has_pdf_text
{
    my $text = $_ [0];
    if (check_if_has_text ($text, $old_NumberA)) { return 1; }
    if (check_if_has_text ($text, $old_NumberB)) { return 1; }
    if (check_if_has_text ($text, $old_NumberC)) { return 1; }
    if (check_if_has_text ($text, $old_NumberD)) { return 1; }
    if (check_if_has_text ($text, $old_ADMIN_DATE)) { return 1; }
    if (check_if_has_text ($text, $old_Date)) { return 1; }
    if (check_if_has_text ($text, $old_PLACE)) { return 1; }
    if (check_if_has_text ($text, $old_NumberE)) { return 1; }
    if (check_if_has_text ($text, $old_NumberF)) { return 1; }
    if (check_if_has_text ($text, $old_NumberG)) { return 1; }
    print ($text, "\n");
    return 0;
}

sub change_text
{
    my $text = $_ [0];
    my $thing = $_ [1];
    my $change_to = $_ [2];
    
    $thing = get_tj_val ($thing);
    $change_to =  get_tj_val ($change_to);

    if ($text =~ m/$thing/)
    {
        print ("Woot found $thing change to $change_to\n");
        $text =~ s/$thing/$change_to/img;
        #print (" >>>>> $text <<<<<\n");
    }
    return $text;
}

sub modify_pdf_text
{
    my $text = $_ [0];

    $text = change_text ($text, $old_NumberA, $NumberA);
    $text = change_text ($text, $old_NumberB, $NumberB);
    $text = change_text ($text, $old_NumberC, $NumberC);
    $text = change_text ($text, $old_NumberD, $NumberD);
    $text = change_text ($text, $old_PLACE, $Place);
    $text = change_text ($text, $old_ADMIN_DATE, $DATE_ADMIN);
    $text = change_text ($text, $old_Date, $SomeDate);
    $text = change_text ($text, $old_NumberE, $NumberE);
    $text = change_text ($text, $old_NumberF, $NumberF);
    $text = change_text ($text, $old_NumberG, $NumberG);

    return $text;
}

# MAIN
{
    if (scalar (@ARGV) > 10)
    {
        $SomeDate = get_yymondd ($ARGV [0]);
        $DATE_ADMIN = get_yymondd ($ARGV [1]);
        $NumberA = round_to_eight ($ARGV [2]);
        $NumberB = get_dollar ($ARGV [3]);
        $NumberC = get_dollar ($ARGV [4]);
        $NumberD = get_dollar ($ARGV [5]);
        $NumberE = get_dollar ($ARGV [6]);
        $NumberF = get_dollar ($ARGV [7]);
        $NumberG = get_dollar ($ARGV [8]);
        $infile = $ARGV [9];
        $outfile = $ARGV [10];;
    }
    else
    {
        print "Fail. Only :" . (scalar (@ARGV)) . " arguments found\n";
        print "$0 SomeDate DATE_ADMIN NumberA NumberB NumberC NumberD NumberE NumberF NumberG INFILE OUTFILE\n";
        exit;
    }

    open my $in, '<', $infile or die;
    binmode $in;

    my $cont = '';

    while (1)
    {
        my $success = read $in, $cont, 100, length ($cont);
        die $! if not defined $success;
        last if not $success;
    }
    close $in;

    open my $out, '>', $outfile or die;
    binmode $out;
    print $out $cont;
    close $out;

    # Write out the chunks of stream??
    my $keep = 1;
    my $cont2 = $cont;
    my $keep_cont2 = $cont2;

    my $stream_r = qr/^(.*?FlateDecode.*?[^d]stream)/s;
    my $endstream_after_r = qr/endstream.*/s;
    my $endstream_before_r = qr/^.*?endstream/s;
    my $get_length_of_stream = qr/^.*FlateDecode.*?Length (\d+)/s;
    my $replace_length_of_stream = qr/^(.*FlateDecode.*?Length) (\d+)/s;
    my $newline = qr/\r\n/s;
    my $o;
    my $up_to_this_point;

    my $modified = 0;
    while ($keep)
    {
        my $cont_two = 1;
        while ($cont2 =~ m/[^d]stream/im)
        {
            $cont2 =~ s/$stream_r//;

            my $top_bit = $1;
            $up_to_this_point .= $top_bit;

            $keep_cont2 = $cont2;                              print ("\n >>> " . length ($cont2));
            $cont2 =~ s/$endstream_after_r//;
            my $before_cont2 = $cont2;                         print ("\n 2>>> " . length ($cont2));
            $cont2 =~ s/$newline//img;
            $keep_cont2 =~ s/$endstream_before_r/endstream/;   print ("\n 3>>> " . length ($keep_cont2));

            # Compressed
            my $outfile2 = "perl_stream.$keep.zip";
            open my $out, '>', $outfile2 or die;
            binmode $out;
            print $out $cont2;
            close $out;

            # Decompressed
            my $do_inflate = new Compress::Raw::Zlib::Inflate();
            $do_inflate->inflate ($cont2, $o);
            my $outfile2 = $outfile . ".$keep.txt";
            open my $out, '>', $outfile2 or die;
            binmode $out;
            print $out $o;
            close $out;

            if (has_pdf_text ($o))
            {
                $modified = 1;
                $o = modify_pdf_text ($o);
                my $zip_bytes = compress ($o);
                print ("\nMODIFIED CHUNK - new length = " . length ($zip_bytes));

                $before_cont2 = $zip_bytes;
                # Decompressed
                my $unzip_bytes = decompress ($zip_bytes);
                $unzip_bytes =~ s/\n//img;
                $up_to_this_point =~ m/^$get_length_of_stream/;
                my $length = $1;
                my $new_length = length ($zip_bytes);
                $up_to_this_point =~ s/^$replace_length_of_stream/$1 $new_length/;
                $up_to_this_point .= "\n";
            }
            $up_to_this_point .= $before_cont2;

            $keep++;
            $cont2 = $keep_cont2;
        }
        $up_to_this_point .= $cont2;
        $keep = 0;
    }

    my $admin_date_yyyymmdd = get_yyyymmdd ($DATE_ADMIN);
    my $admin_date_yyyy_mm_dd = $admin_date_yyyymmdd;
    $admin_date_yyyy_mm_dd =~ s/^(\d\d\d\d)(\d\d)(\d\d)/$1-$2-$3/;
    $up_to_this_point =~ s/$old_date_yyyymmdd/$admin_date_yyyymmdd/imgs;
    $up_to_this_point =~ s/$old_date_yyyy_mm_dd/$admin_date_yyyy_mm_dd/imgs;

    # Print out modified pdf..
    if ($modified)
    {
        my $mod_file = "$outfile";
        $mod_file =~ s/\./.mod./;
        open my $out, '>', $mod_file or die;
        binmode $out;
        print $out $up_to_this_point;
        close $out;
        print ("Changed file to: $mod_file\n");
        print ("$mod_file >> ",  -s $mod_file, "\n");
    }

    $cont =~ s/\W/_/img;
    $cont =~ s/___*/_/img;

    say length($cont);
    print ("$infile >> ",  -s $infile, "\n");
    print ("$outfile >> ",  -s $outfile, "\n");
}
