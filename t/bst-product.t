use strict;

#use Test::More qw(no_plan);

use FindBin qw($Bin);
use lib "$Bin/../lib";

use BST;
use BST::Product;
use Data::Dumper;

my $rs;
$rs = BST::Product->name_search('concrete', 'or');

#print Dumper [ map +{ $_->id, $_->product_standards->next->standard_document_identifier }, $rs->all ];
print Dumper scalar $rs->all;

1;
