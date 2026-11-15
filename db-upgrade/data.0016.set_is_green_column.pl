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

my $sql = "update product set is_green = 'false'";
$dbh->do($sql) or die $dbh->errstr;

$dbh->do("ALTER TABLE product DISABLE TRIGGER USER");
$sql = "update product set is_green = 'true' where product_id in (select distinct(product.product_id) from product left join product_attribute_value on product.product_id=product_attribute_value.product_id where product_attribute_value.attribute_id = 'leed_credits')";
$dbh->do("ALTER TABLE product ENABLE TRIGGER USER");
$dbh->do($sql) or die $dbh->errstr;
