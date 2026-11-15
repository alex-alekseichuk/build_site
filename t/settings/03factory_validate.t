#!/usr/bin/perl

use strict;
use FindBin qw($Bin);
use lib "$Bin/../../lib";
use Test::More qw(no_plan);

use BST;
use BST::Settings;
use BST::User;
use BST::SettingItem;


my $oSet = BST::Setting->load({setting_id => 'setting157398' });
my $oSI = new BST::SettingItem($oSet);
is($oSI->validate_value('avaf'), 0, 'Literal area codes are not allowed for area code');
is($oSI->validate_value('1234'), 0, 'Too long codes are are not allowed for area code');
is($oSI->validate_value('666'), 1, 'Three-digit numbers are all we need for area code');
