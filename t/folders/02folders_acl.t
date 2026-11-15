#!/usr/bin/perl

use strict;
use FindBin qw($Bin);
use lib "$Bin/../../lib";
use Test::More qw(no_plan);  
use Data::Dumper;

use BST;
use BST::Scope;
use BST::User;
use BST::FolderItem;


my $oUser = BST::User->load( { login_id => 'ieg' } );
my $oAdmin = BST::User->load( { login_id => 'petermuller' } );

my ($oLoc) = BST::Location->search( {
    account_id => $oUser->primary_location->account->account_id,
    account_location_id => { '<>' => $oUser->primary_location->account_location_id }
} );

my ($ownCompany) = BST::File->search( { 
    owner => $oUser->primary_location->account_location_id, 
    scope => BST::Scope::ACCOUNT,
    creator_user => { '<>' => $oUser->user_id }
} );
my ($ownLocation) = BST::File->search( { 
    owner => $oUser->primary_location->account_location_id, 
    creator_user => { '<>' => $oUser->user_id },
    scope => BST::Scope::LOCATION 
} );
my ($ownUser) = BST::File->search( {
    creator_user => $oUser->user_id,
    scope => BST::Scope::USER
} );

my ($otherCompany) = BST::File->search( { owner => 'drywall_stmichael', scope => BST::Scope::ACCOUNT } );
my ($otherLocation) = BST::File->search( { owner => $oLoc->account_location_id, scope => BST::Scope::LOCATION } );
my ($otherUser) = BST::File->search( { creator_user => 'buildsite109363', scope => BST::Scope::USER } );



is($ownCompany->can_read($oUser), 1, 'User can read documents from his company drawer');
is($otherCompany->can_read($oUser), 0, 'User cannot read documents from other companies drawer');
is($ownLocation->can_read($oUser), 1, 'User can read documents from his location drawer');
is($otherLocation->can_read($oUser), 0, 'User cannot read documents from other locations drawer');
is($ownUser->can_read($oUser), 1, 'User can read documents from his private drawer');
is($otherUser->can_read($oUser), 0, 'User cannot read documents from other users private drawer');

print "\n";

is($ownCompany->can_write($oUser), 0, 'User cannot save documents to his company drawer');
is($otherCompany->can_write($oUser), 0, 'User cannot save documents to other companies drawer');
is($ownLocation->can_read($oUser), 1, 'User can save documents to his location drawer');
is($otherLocation->can_read($oUser), 0, 'User cannot save documents to other locations drawer');
is($ownUser->can_write($oUser), 1, 'User can save documents to his private drawer');
is($otherUser->can_read($oUser), 0, 'User cannot save documents to other users drawer');

print "\n";

is($ownCompany->can_write($oAdmin), 1, 'Account admin can save documents to his company drawer');
is($otherLocation->can_write($oAdmin), 0, 'Account admin cannot save documents to other locations drawer');
is($ownUser->can_read($oAdmin), 0, 'Account admin cannot see documents from users private drawer');
