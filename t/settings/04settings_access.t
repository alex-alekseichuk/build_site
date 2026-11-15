#!/usr/bin/perl

use strict;
use FindBin qw($Bin);
use lib "$Bin/../../lib";
use Test::More qw(no_plan); 

use BST;
use BST::Scope;
use BST::User;
use BST::Settings;
use BST::SettingItem;


my $oUser1 = BST::User->load( {login_id => 'ieg' } );
my $oUser2 = BST::User->load( {login_id => 'staff' } );

my $oSts1  = new BST::Settings($oUser1);
my $oSts2  = new BST::Settings($oUser2);

is(scalar @{ $oSts1->get_viewable(BST::Scope::USER) }, 4, 'User can access only 4 settings');
is(scalar @{ $oSts2->get_viewable(BST::Scope::USER) }, 26, 'Buildsite admin access 26 settings');
