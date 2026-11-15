#!/usr/bin/perl -w

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Getopt::Long;

my ($log, $session, $content);

GetOptions(
    "log=s"         => \$log,
    "sessionid=s"   => \$session,
);

open (LOG, q{<}, $log) or die "Can't open log file: $!";
    local $/;
    $content = <LOG>;
close(LOG);

open (OUT, q{>}, "$session.log") or die "Can't open log file: $!";
    while ($content =~ /(\*\*\*\sRequest.*?\n\n\n)/gis) {
        my $part = $1;

        if ($part =~ /$session/i) {
            print OUT $part;
        }
    }
close(OUT);
