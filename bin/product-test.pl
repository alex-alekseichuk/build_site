use strict;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Data::Dumper;
use BST;
use BST::Product;

my $resultset = BST::Product->search({
    product_name => [ -and => map +{'ilike', "%$_%"}, split(' ', 'roof') ],
});

print Dumper $resultset->next->manufacturer->id;
