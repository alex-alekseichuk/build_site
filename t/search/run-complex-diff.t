#!/usr/bin/perl

use strict;
use FindBin qw($Bin);

open FILE, $ARGV[0] or die $!;

foreach (<FILE>) {
    chomp;
    next unless m/[a-z0-9 ]/;
    $_ = sprintf '"%s"', $_ if m/ /;
    system("perl $Bin/diff.t $_ and");
}
close FILE;
