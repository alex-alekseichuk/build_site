#!/usr/bin/perl

use strict;

use FindBin qw($Bin);
use lib "$Bin/../../lib";
use Test::More qw(no_plan);

use Data::Dumper;

use BST::SearchKeywords;

#ok( join(', ', @{BST::SearchKeywords::tokenize_category_search("a b c")}), 'a, b, c, abc');
#ok( join(', ', @{BST::SearchKeywords::tokenize_manufacturer_search("a b c")}), 'a, b, c, abc');
#ok( join(', ', @{BST::SearchKeywords::tokenize_product_search("a b c")}), 'a, b, c, abc');
#ok( join(', ', @{BST::SearchKeywords::tokenize_astm_search("a b c")}), 'abc');

#print Dumper(BST::SearchKeywords::tokenize_product_search("a b c"));

1;
