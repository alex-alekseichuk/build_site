#!/usr/bin/perl

use strict;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Data::Dumper;
use BST::Config;
use BST;
use DBI;

my $config = BST::configuration();
my $dbh = BST::dbh();

my $sql = "select customer_order_id, account_id from customer_order";

my $sthdl = $dbh->prepare($sql) or die $dbh->errstr;
my $total = $sthdl->execute();

my ($returned);

while ($returned = $sthdl->fetchrow_hashref) {
	next unless $returned->{account_id};
	$sql = "update account set customer_order_id = ? where account_id = ?";
	my $sthd2 = $dbh->prepare($sql) or die $dbh->errstr;
	$sthd2->execute($returned->{customer_order_id}, $returned->{account_id});
}
