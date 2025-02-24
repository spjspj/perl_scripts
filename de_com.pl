#!/usr/bin/perl

use 5.010;
use Compress::Raw::Zlib;
use strict;
use warnings;

my $input = "This is a test string to be compressed and decompressed.";
my $input2 = "SECOND This is a test string to be compressed and decompressed.";

# Compress the string
my ($deflate, $inflate, $compressed, $decompressed);

$deflate = Compress::Raw::Zlib::Deflate->new
(
    -WindowBits   => 15, 
    -AppendOutput => 1 
);

my $compressed_bytes = '';
my $status = $deflate->deflate($input, $compressed_bytes);
$status = $deflate->flush($compressed_bytes);

my $hcb = unpack("H*", $compressed_bytes);
print $hcb, " << hcb\n";
my $compressed = pack("H*", $hcb);

$inflate = Compress::Raw::Zlib::Inflate->new ();

$status = $inflate->inflate($compressed, $decompressed);
print ("Status: $status\n");
print "aa) Decompressed string: $decompressed\n";

$inflate = Compress::Raw::Zlib::Inflate->new(
    -WindowBits   => 15, 
    -AppendOutput => 1
);

$decompressed .= "\nSecond go:\n";
#$compressed_bytes =~ s/$compressed_bytes/\r\n/mg;
$status = $inflate->inflate($compressed_bytes, $decompressed);
print "bb) Decompressed string ($status): $decompressed\n";
