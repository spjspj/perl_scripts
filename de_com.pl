#!/usr/bin/perl
https://github.com/spjspj/perl_scripts/blob/master/de_com.pl
use Compress::Raw::Zlib;
use strict;
use warnings;

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

# Main
{
    my $input = "This is a test string to be compressed and decompressed.";
    my $compressed = compress ($input);
    my $decompressed = decompress ($compressed);
    print $decompressed;
}
