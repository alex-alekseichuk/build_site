use strict;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use BST;
use BST::Product;

my $q = join ' ', @ARGV;

my $rs = BST::Product->name_search( $q );

if ($rs) {
    foreach ($rs->all) {
        print $_->product_id, "\n\t", $_->product_name, "\t", $_->manufacturer->legal_name, "\n";
    }
}
