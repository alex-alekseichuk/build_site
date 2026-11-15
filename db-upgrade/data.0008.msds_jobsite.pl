#!/usr/bin/perl

use strict;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Data::Dumper;
use DBI;
use BST;



my $msdsgroups = [
                   { name => 'Motor Fuels', docs => [qw(document234454 document234457 document234458 document234451 document154106)] },
                   { name => 'Motor Oils, Coolants, and Lubricants', docs => [qw(document234447 document126613 document234463 document234448 document234446 document234445 document234464 document234450 document234461 document234456 document234455 document234449 document234507 document234441 document234460 document154171 document234459 document128109 document154040)] },
                   { name => 'Paint Thinners and Solvents', docs => [qw(document234515 document234517)] },
                   { name => 'Welding and Utility Gases', docs => [qw(document234513 document234516 document234514 document128112)] },
                   { name => 'Tools, Accessories and Clean-Up', docs => [qw(document234671 document154009 document154022 document154025 document234687 document195550 document154039)] },
                   { name => 'Adhesives, Sealants and Fillers', docs => [qw(document154029 document234677 document227646 document154002 document154004 document234681 document154028)] },
                   { name => 'Basic Construction Materials', docs => [qw(document126706 document234683 document154033 document154034 document234662 document154036)] },
                ];


my $dbh = BST::dbh();

for my $i (0..$#{$msdsgroups}){
    my $sth = $dbh->prepare("INSERT INTO msds_group (msds_group_id, name, position) VALUES (?, ?, ?)") or die;
    $sth->execute("msdsgroup" . $i, $msdsgroups->[$i]->{name}, $i);
    $sth = $dbh->prepare("INSERT INTO msds_document (msds_group_id, document_id, position) VALUES (?, ?, ?)") or die;
    for my $j (0..$#{$msdsgroups->[$i]->{docs}}){
        $sth->execute("msdsgroup" . $i, $msdsgroups->[$i]->{docs}->[$j], $j);
    }
}