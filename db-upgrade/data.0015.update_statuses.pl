#!/usr/bin/perl

use strict;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Data::Dumper;
use BST;
use BST::Message;


my @messages = BST::Message->search({})->all;

my $messages_count = $#messages + 1;

my $count = 0;
for my $message (@messages) {
	$count++;
	$message->update_status();
	$message->save();
	print "$count of $messages_count messages updated\n";
}