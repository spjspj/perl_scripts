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
# mk_form6_html.pl 20240802 20250214 5.30998553282281 385164.051577397 86200.8240665784 29883.864949341 157786.333333333 206527.31698628 688899.661589083
my %variables;
my $overall_text;
my $tj;
my $this_tj;
my $DO_DEBUG = 0;

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

sub simplify_text
{
    my $text = $_ [0];
    
    $text =~ s/\\\(/YYYY/img;
    $text =~ s/\\\)/ZZZZ/img;
    $text =~ s/\)[\-0-9]+\(//img;
    $text =~ s/YYYY/\\\(/img;
    $text =~ s/ZZZZ/\\\)/img;

    return $text;
}

sub needs_to_be_simplified
{
    my $text = $_ [0];

    # Array style
    # [(S)-4(ign)6(a)4(t)-5(u)4(r)5(e)4( )-5(o)4(f)9( )-5(r)5(e)4(s)-6(p)4(o)4(n)4(d)4(e)4(n)4(t)9( )-5(_)4(_)4(_)4(_)4(_)4(_)4(_)4(_)4(_)4(_)4(_)4(_)4(_)4(_)4(_)4(_)4(_)4(_)4(_)4(_)4(_)4(_)4(_)4(_)4(_)-10(_)4(_)4(_)4(_)] TJ
    #   should go to (for search..)
    # [Signature of applicant _____________________________]TJ
    if ($text =~ m/\[\([^\)]\).*?\([^\)]\)\] *TJ/)
    {
        if ($text =~ m/\[\([^\)]\).*?\([^\)]\)\] *TJ/)
        {
            return 1;
        }
    }
    return 0;
}

sub check_if_has_text
{
    my $text = $_ [0];
    my $thing = $_ [1];
    my $orig_thing = $_ [1];

    $thing = get_tj_val ($thing);
    #print ("CHeck if has text ---> $thing\n");

    if ($text =~ m/$thing/)
    {
        print ("Found as tj string ---> $thing\n");
        return 1;
    }

    if ($text =~ m/$orig_thing/i)
    {
        print ("Found as normal string ---> $orig_thing\n");
        return 2;
    }

    my $to_be_simplified = needs_to_be_simplified  ($text);
    if ($to_be_simplified)
    {
        my $text2 = simplify_text ($text);
        if ($text2 =~ m/$orig_thing/i)
        {
            print ("Found as ARRAY TJ string ---> $orig_thing\n");
            exit;
        }
    }

    return 0;
}

sub has_pdf_text
{
    my $text = $_ [0];
    my $key;
    foreach $key (sort keys (%variables))
    {
        my $type = check_if_has_text ($text, $key);
        if ($type > 0)
        {
            return $type;
        }
    }
    return 0;
}



sub change_text
{
    my $text = $_ [0];
    my $thing = $_ [1];
    my $change_to = $_ [2];

    my $orig_thing = $_ [1];
    my $orig_change_to = $_ [2];

    $thing = get_tj_val ($thing);
    $change_to =  get_tj_val ($change_to);

    if ($text =~ m/$thing/im)
    {
        print ("Type 1) Woot found $thing change to $change_to (aka $orig_thing to $orig_change_to)\n");
        $text =~ s/$thing/$change_to/img;
        #print (" >>>>> $text <<<<<\n");
    }
    elsif ($text =~ m/$orig_thing/im)
    {
        print ("Type 2) Woot found $orig_thing change to $orig_change_to\n");
        $text =~ s/$orig_thing/$orig_change_to/img;
        #print (" >>>>> $text <<<<<\n");
    }
    return $text;
}

sub modify_pdf_text
{
    my $text = $_ [0];
    my $key;
    foreach $key (sort keys (%variables))
    {
        my $type = check_if_has_text ($text, $key);
        if (check_if_has_text ($text, $key) > 0)
        {
            $text = change_text ($text, $key, $variables {$key});
        }
    }
    return $text;
}

# MAIN
{
    my $text_file = "";
    my $pdf_file = "";
    my $pdf_out_file = "";
    if (scalar (@ARGV) >= 2)
    {
        $pdf_file = $ARGV [0];
        $text_file = $ARGV [1];
        $pdf_out_file = $pdf_file;
        $pdf_out_file =~ s/\.pdf$/.out.pdf/;
        print ("type $text_file\n");
        my $inputs = `type $text_file`;
        while ($inputs =~ s/^(.*?)\n//)
        {
            my $line = $1;
            chomp $line;
            if ($line =~ m/\{([^\}]+)\}=\{([^\}]+)\}/)
            {
                my $k = $1;
                my $v = $2;
                $variables {$k} = $v;
                print ("Value $k to go to $v\n");
            }
        }
    }
    else
    {
        print "Fail. Needs input in the form of a .txt file:\n";
        print "{key1}={value1}\n";
        print "{key2}={value2}\n";
        print "....\n";
        print "{keyn}={valuen}\n";
        print "\n\n";
        print "Call with:\n $0 test.pdf test_variables.txt";
        print "Call with:\n $0 fco.pdf modify_fco.txt";
        exit;
    }

    open my $in, '<', $pdf_file or die;
    binmode $in;

    my $cont = '';

    while (1)
    {
        my $success = read $in, $cont, 100, length ($cont);
        die $! if not defined $success;
        last if not $success;
    }
    close $in;

    open my $out, '>', $pdf_out_file or die;
    binmode $out;
    print $out $cont;
    close $out;

    # Write out the chunks of stream??
    my $keep = 1;
    my $cont2 = $cont;
    my $keep_cont2 = $cont2;

    my $stream_regex = qr/^(.*?FlateDecode.*?[^d]stream)/s;
    my $endstream_and_after_regex = qr/endstream.*/s;
    my $endstream_and_before_regex = qr/^.*?endstream/s;
    my $get_length_of_stream = qr/^.*FlateDecode.*?Length (\d+)/s;
    my $replace_length_of_stream = qr/^(.*FlateDecode.*?Length) (\d+)/s;
    my $newline = qr/\r\n/s;
    my $o;
    my $up_to_this_point;

    my $modified = 0;
    my $move_on = 0;
    while ($keep)
    {
        my $cont_two = 1;
        while ($cont2 =~ m/[^d]stream/im && !$move_on)
        {
            $cont2 =~ s/$stream_regex//;

            my $top_bit = $1;
            if (!defined ($top_bit))
            {
                print ($cont2);
                $move_on = 1;
                next;
            }
            $move_on = 0;
            $up_to_this_point .= $top_bit;

            $keep_cont2 = $cont2;                              #print ("\n $keep >>> " . length ($cont2));
            $cont2 =~ s/$endstream_and_after_regex//;
            my $before_cont2 = $cont2;                         #print ("\n 2>>> " . length ($cont2));
            $cont2 =~ s/$newline//img;
            $keep_cont2 =~ s/$endstream_and_before_regex/\nendstream/;   #print ("\n 3>>> " . length ($keep_cont2));
            my $orig_cont2 = $cont2;

            my $pdf_out_file2;
            my $out;

            # Decompressed
            my $do_inflate = new Compress::Raw::Zlib::Inflate();
            $do_inflate->inflate ($cont2, $o);

            # DEBUG ONLY!
            if ($DO_DEBUG)
            {
                # Compressed
                my $outfile2 = "perl_stream.$keep.orig.zip";
                open my $out, '>', $outfile2 or die;
                binmode $out;
                print $out $orig_cont2;
                close $out;
                # Decompressed
                my $o2;
                my $do_inflate2 = new Compress::Raw::Zlib::Inflate();
                $do_inflate2->inflate ($orig_cont2, $o2);
                $outfile2 = $pdf_out_file . ".$keep.orig.txt";
                open my $out, '>', $outfile2 or die;
                binmode $out;
                print $out $o2;
                close $out;
            }

            if (needs_to_be_simplified ($o))
            {
                my $o3 = simplify_text ($o);
                if (has_pdf_text ($o3))
                {
                    $modified = 1;
                    $o = $o3;
                }
            }

            if (has_pdf_text ($o))
            {
                $modified = 1;
                $o = modify_pdf_text ($o);

                my $zip_bytes = compress ($o);
                $before_cont2 = $zip_bytes;

                # DEBUG ONLY!
                if ($DO_DEBUG)
                {
                    # Compressed
                    my $outfile2 = "perl_stream.$keep.modded.zip";
                    open my $out, '>', $outfile2 or die;
                    binmode $out;
                    print $out $zip_bytes;
                    close $out;
                    # Decompressed
                    my $zip_bytes2 = $zip_bytes;
                    my $o2;
                    my $do_inflate = new Compress::Raw::Zlib::Inflate();
                    $do_inflate->inflate ($zip_bytes2, $o2);
                    $outfile2 = $pdf_out_file . ".$keep.modded.txt";
                    open my $out, '>', $outfile2 or die;
                    binmode $out;
                    print $out $o2;
                    close $out;
                }

                $up_to_this_point =~ m/^$get_length_of_stream/;
                my $length = $1;
                print ("Seen $length worth of bytes..\n");
                my $new_length = length ($zip_bytes);
                $up_to_this_point =~ s/^$replace_length_of_stream/$1 $new_length/;
                $up_to_this_point .= "\n";
            }

            $up_to_this_point .= $before_cont2;

            $keep++;
            $cont2 = $keep_cont2;
        }
        $move_on = 0;
        $up_to_this_point .= $cont2;
        $keep = 0;
    }

    # Print out modified pdf..
    if ($modified)
    {
        my $mod_file = "$pdf_out_file";
        $mod_file =~ s/\./.mod./;
        open my $out, '>', $mod_file or die;
        binmode $out;
        print $out $up_to_this_point;
        close $out;
        print ("\n\n=================\nPrinting the modified file to: $mod_file\n");
        print ("$mod_file >> ",  -s $mod_file, "\n");

        my $fixed_file = $mod_file;
        $fixed_file =~ s/\.mod\./.fixed./;
        # Automagically fix it :) :)
        print ("Running: \"c:\\Program Files\\qpdf 12.2.0\\bin\\qpdf.exe\" $mod_file $fixed_file\n");
        `"c:\\Program Files\\qpdf 12.2.0\\bin\\qpdf.exe" $mod_file $fixed_file`;
    }
    else
    {
        print ("\n\n!!!! ERROR! Nothing was found to be modified\n");
    }

    $cont =~ s/\W/_/img;
    $cont =~ s/___*/_/img;

    say length($cont);
    print ("$pdf_file >> ",  -s $pdf_file, "\n");
    print ("$pdf_out_file >> ",  -s $pdf_out_file, "\n");
}
