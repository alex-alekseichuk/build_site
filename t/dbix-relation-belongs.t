#!/usr/bin/perl

use strict;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Test::More qw(no_plan);  
use Data::Dumper;

use BST;
use BST::Location;



my $oLoc = BST::Location->create({});

is($oLoc->account, undef, 'Related object is empty');
# is($oLoc->account->account_id, $oLoc->account_id, 'Related object is not empty');
