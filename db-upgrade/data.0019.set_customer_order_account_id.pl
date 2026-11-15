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

my $sql = "select customer_order.customer_order_id, account_location.account_id, customer_user.email from customer_order left join customer_user on customer_user.customer_user_id=customer_order.customer_user_id left join account_user on account_user.email_address = customer_user.email left join account_location on account_location.account_location_id=account_user.primary_location";

my $sthdl = $dbh->prepare($sql) or die $dbh->errstr;
my $total = $sthdl->execute();

my ($returned);

while ($returned = $sthdl->fetchrow_hashref) {
	$returned->{account_id} = "individual_michael_e_jaca_mikejmsf_aol_com" if $returned->{email} eq "mikejmsf\@aol.com";
	next unless $returned->{account_id};
	$sql = "update customer_order set account_id = ? where customer_order_id = ?";
	my $sthd2 = $dbh->prepare($sql) or die $dbh->errstr;
	$sthd2->execute($returned->{account_id}, $returned->{customer_order_id});
}


