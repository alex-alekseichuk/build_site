#!/usr/bin/perl

use strict;
use FindBin qw($Bin);
use lib "$Bin/../../lib";
use Data::Dumper;
use Test::More qw(no_plan);  

use BST;
use BST::User;
use BST::Settings;


my $oUser = BST::User->load( {login_id => 'staff' } );
my $oSts  = new BST::Settings($oUser);

my $scopes = $oSts->get_scope_set(BST::Scope::LOCATION);
is($scopes->{BST::Scope::ACCOUNT}, 1, 'Buildsite admin can see account settings');
is($scopes->{BST::Scope::LOCATION}, 1, 'Buildsite admin can see location settings');

my $oUser = BST::User->load( {login_id => 'ieg' } );
my $oSts  = new BST::Settings($oUser);

my $scopes = $oSts->get_scope_set(BST::Scope::LOCATION);
is(scalar keys %$scopes, 0, 'User cannot see location settings');
