#!/usr/bin/perl

use strict;
use FindBin qw($Bin);
use lib "$Bin/../../lib";
use Test::More qw(no_plan);

use BST;
use BST::Settings;
use_ok('BST::SettingItem');

my $oSetting = BST::Setting->load('setting67576');
my $oSI = new BST::SettingItem($oSetting);
isa_ok($oSI, 'BST::SettingItem::UseLocationAddressBook');