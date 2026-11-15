#!/usr/bin/perl

use strict;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use BST;
use File::Temp qw(tempdir);
use File::Basename;

=head USAGE

perl t/funkload/run.pl -u http://crunch.ahinea.com:3005 --simple-fetch -v -l 3:14 -n 3 t/funkload/test_01_basic_browsing.py

=cut

my @fl_args;
my @tests;

foreach ( @ARGV ) {
    if (m/test_/ and m/.py$/ ) {
        push @tests, $_;
    } else {
        push @fl_args, $_;
    }
}

my $tmpdir = $ENV{TEMP} || $ENV{TMP} || "/tmp";
my $tmp = tempdir( "$tmpdir/bsa-test-fl-XXXXX" );
if ( not -d $tmp ) { die "can't get a temp dir"; }

foreach( @tests ) {
    if (not -f $_ ) { undef $_; next; }
    system( "cp $_ $tmp/" );
    $_ = basename( $_ );
}
system( "cp $FindBin::Bin/Bsa.conf $tmp/" );

chdir $tmp or die;

foreach (@tests) {
    next if not $_;
    system( "fl-run-test", $_, @fl_args );
}

print "ran the test(s) in $tmp dir\n";

