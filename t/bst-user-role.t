#!/usr/bin/perl

use Test::More qw(no_plan);

use FindBin qw($Bin);
use lib "$Bin/../lib";

use BST;
use BST::User;


my $oUser1 = BST::User->load( {login_id => 'ieg'} );
my $oUser2 = BST::User->load( {login_id => 'petermuller'} );
my $oUser3 = BST::User->load( {login_id => 'staff'} );

is($oUser1->get_role(), ROLE_SINGLE_USER, 'Detecting simple users');
is($oUser2->get_role(), ROLE_ACCOUNT_ADMIN, 'Detecting account admins');
is($oUser3->get_role(), ROLE_BUILDSITE_ADMIN, 'Detecting buildsite admins');
