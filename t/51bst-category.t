use strict;

#use Test::More qw(no_plan);

use FindBin qw($Bin);
use lib "$Bin/../lib";

use BST;
use BST::Category;
use Data::Dumper;

my $rs;
$rs = BST::Category->search({});

print Dumper $rs->next->manufacturers;

1;
