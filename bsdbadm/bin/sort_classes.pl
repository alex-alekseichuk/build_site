#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;

my $file = shift || 'models.py';
open my $fh, $file or die "Can't open $file: $!";

my $content = do { local(@ARGV, $/) = $file; <> };

my @classes = split /(?=^class\s+)/m, $content;
my $header  = shift @classes;
print $header, sort @classes;
