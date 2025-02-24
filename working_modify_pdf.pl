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

my ($infile, $outfile) = @ARGV;
print ("Example usage:\n$0 test1.pdf blah.pdf\n");
die "Usage: $0 INFILE OUTFILE\n" if not $outfile;
 
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

# Decode the Tj components of the streams
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

my $overall_text;
my $tj;
my $this_tj;
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

sub has_pdf_text
{
    my $text = $_ [0];
    my $thing = $_ [1];
    my $change_to = $_ [2];

    if ($text =~ m/$thing/)
    {
        return 1;
    }
    return 0;
}

sub modify_pdf_text
{
    my $text = $_ [0];
    my $thing = $_ [1];
    my $change_to = $_ [2];

    if ($text =~ m/$thing/)
    {
        print ("Woot found $thing change to $change_to\n");
        $text =~ s/$thing/$change_to/img;
        #print (" >>>>> $text <<<<<\n");
    }
    return $text;
}
# Done - Decode the Tj components of the streams

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

my $billy = compress ("My name is billy bob.  Pleased ta meet ya");
my $bob = decompress ($billy);
print "Expect output of billy bob:\n", $bob;

# MAIN
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

        #get_pdf_text ($o);
        if (has_pdf_text ($o, get_tj_val ("4.115000"), get_tj_val ("1.234567")))
        {
            $modified = 1;
            $o = modify_pdf_text ($o, get_tj_val ("4.115000"), get_tj_val ("1.234567"));
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
    
    #print ("$overall_text\n");
    $keep = 0;
}

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
#print $cont;

say length($cont);
print ("$infile >> ",  -s $infile, "\n");
print ("$outfile >> ",  -s $outfile, "\n");
