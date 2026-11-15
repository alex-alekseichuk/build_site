#!/usr/bin/perl -w

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Data::Dumper;

use BST;
use BST::Company;

my @list = BST::Company->search({ 'company_type' => 'manufacturer' }, {})->all;
my $i = 0;

foreach (@list) {
        ++$i;
        warn Dumper($i, $_->get_column("company_id"));
        warn Dumper($_->get_column("feature_level"));
    }