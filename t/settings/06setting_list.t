#!/usr/bin/perl

use strict;
use FindBin qw($Bin);
use lib "$Bin/../../lib";
use Test::More qw(no_plan);  
use Data::Dumper;

use BST;
use BST::Scope;
use BST::User;
use BST::Settings;


my $oUser = BST::User->load( {login_id => 'ieg' } );
my $oSts  = new BST::Settings($oUser);

is($oSts->can_list(BST::Scope::ACCOUNT, 'ruttura_and_sons'), 0, 'User cannot list settings of another accounts');
is($oSts->can_list(BST::Scope::ACCOUNT, $oUser->primary_location->account_id->account_id), 0, 'User cannot list settings of his account');
is($oSts->can_list(BST::Scope::LOCATION, 'alcal_arcade_fresno'), 0, 'User cannot list settings of another locations');
is($oSts->can_list(BST::Scope::LOCATION, $oUser->primary_location->account_location_id), 0, 'User cannot list settings of his location');
is($oSts->can_list(BST::Scope::USER, 'buildsite100030'), 0, 'User cannot list settings of another users');
is($oSts->can_list(BST::Scope::USER, $oUser->user_id), 1, 'User can list his own settings');


print "\n";

my $ieg_id = $oUser->user_id;
my $oUser = BST::User->load( {login_id => 'petermuller' } );
my $oSts  = new BST::Settings($oUser);

is($oSts->can_list(BST::Scope::ACCOUNT, 'ruttura_and_sons'), 0, 'Account admin cannot list settings of another accounts');
is($oSts->can_list(BST::Scope::ACCOUNT, $oUser->primary_location->account_id->account_id), 1, 'Account admin can list settings of his account');
is($oSts->can_list(BST::Scope::LOCATION, 'alcal_arcade_fresno'), 0, 'Account admin cannot list settings of another locations');
is($oSts->can_list(BST::Scope::LOCATION, $oUser->primary_location->account_location_id), 1, 'Account admin can list settings of his location');
is($oSts->can_list(BST::Scope::USER, 'buildsite100030'), 0, 'Account admin cannot list settings of another account\'s users');
is($oSts->can_list(BST::Scope::USER, $oUser->user_id), 1, 'Account admin can list settings of his account\'s users');
is($oSts->can_list(BST::Scope::USER, $oUser->user_id), 1, 'Account admin can list his own settings');
