use strict;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Data::Dumper;

#my $logger = BST::Logger->instance();

#$logger->search(message => "preved medved\n");
#$logger->bst(message => "here is BST\n");

use BST::Logger;
use BST;
use BST::Product;

my $rs = BST::Product->name_search( 'concrete', 'and' );

1;
