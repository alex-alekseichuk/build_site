#!/usr/bin/perl -w

use strict;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Test::More tests => 1;

use Storable qw(freeze thaw);

use Object::Signature;

use Data::Dumper;
use BST;
use BST::Product;

my ($product_id, $original_product, $restored_product);

$product_id = $ARGV[0] or die "supply a product id";

$original_product = BST::Product->load($product_id);

open(TMP, q{>}, $product_id) or die "Can't open file: $!";
    print TMP freeze($original_product);
close(TMP);

open(TMP, q{<}, $product_id) or die "Can't open file: $!";
    local $/;
    $restored_product = thaw(<TMP>);
close(TMP);

unlink($product_id);

is(Object::Signature::signature($original_product), Object::Signature::signature($restored_product), 'object is same');
