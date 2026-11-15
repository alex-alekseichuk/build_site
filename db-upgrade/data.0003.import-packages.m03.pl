# import all packages and their items from files to database

use strict;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use BST;
use BST::Package;

# 4 test usage
#my @fi_packages = BST::Package->search(
#    { 'owner.account_id' => 'muller_construction_supply' },
#    { join => 'owner' }
#);

# for example
#my @fi_packages = BST::Package->search( {owner => 'muller_construction_supply_richmond'} );
#my @fi_packages = BST::Package->search( { file_class => "archive" } );

my @p = BST::Package->search({});
foreach my $pkg (@p) {
    my $arr = $pkg->contents;
    map { $pkg->add_item($_) } @{ $arr }
        if $arr;
}

