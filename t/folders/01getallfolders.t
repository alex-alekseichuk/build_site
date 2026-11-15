#!/usr/bin/perl

use strict;
use FindBin qw($Bin);
use lib "$Bin/../../lib";
use Test::More qw(no_plan);

use BST;
use BST::User;
use Data::Dumper;


my $oUser = BST::User->load({ login_id => 'ieg' });
print Dumper $oUser->get_all_folders();
