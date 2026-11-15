#!/usr/bin/perl

use strict;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Data::Dumper;
use DBI;
use BST;

my $dbh = BST::dbh();

$dbh->do("DELETE FROM setting WHERE att_name='allow_publishers' OR att_name='allow_categories'");