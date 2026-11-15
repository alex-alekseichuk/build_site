#!/usr/bin/perl

use strict;
use FindBin qw($Bin);
use lib "$Bin/../../lib";
use Test::More qw(no_plan);

use BST;
use BST::Settings;
use BST::User;
use BST::SettingItem;


my $oSet = BST::Setting->load({setting_id => 'setting67573' });
my $oSI = new BST::SettingItem($oSet);
is($oSI->get_type(), 'select', 'Special input fields are supported');
isa_ok($oSI->get_values_list(), 'HASH', 'Values list is returned for items');

$oSet = BST::Setting->create({att_name => 'lalala'});
$oSI = new BST::SettingItem($oSet);
isa_ok($oSI, 'BST::SettingItem::Default');
is($oSI->get_type(), 'text', 'Default input field is text');
