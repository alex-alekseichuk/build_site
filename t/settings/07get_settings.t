#!/usr/bin/perl

use strict;
use FindBin qw($Bin);
use lib "$Bin/../../lib";
use Test::More qw(no_plan);
use Data::Dumper;

use BST;
use BST::Account;
use BST::Settings;


is(ref BST::Account->search({})->first()->settings->list, 'HASH', 'Setting list for account got successfully');
is(ref BST::Location->search({})->first()->settings->list, 'HASH', 'Setting list for location can got successfully');