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

my $sql = "select tgname, tgenabled, now() as now from pg_trigger where tgname in ('tr_product_mtime', 'tr_company_mtime') and tgenabled = 'D'";

my $sthdl = $dbh->prepare($sql) or die $dbh->errstr;
my $total = $sthdl->execute();

my ($returned);

while ($returned = $sthdl->fetchrow_hashref) {

	my $ps = `ps -ef | grep -vE 'ps -ef'`;

	my $message = qq|Disabled trigger $returned->{tgname} was enabled on $returned->{now}.\n\nProcesses are:\n$ps\n|;

	BST::Core->logger->log({ message => $message, email => 1 });
}
