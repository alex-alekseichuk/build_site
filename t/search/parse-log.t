#!/usr/bin/perl

use strict;
use Data::Dumper;

die "Usage: perl parse-log.t filename" unless @ARGV;

open FILE, $ARGV[0] or die $!;

my $q = {};
foreach (<FILE>) {
    next unless m/,"product","(.*?)"/;
    $q->{lc $1} ||= 0;
    $q->{lc $1}++;
}
close FILE;

print join "\n", grep { $q->{$_} > 2 } keys %$q;
