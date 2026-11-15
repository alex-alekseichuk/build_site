use strict;

use FindBin qw($Bin);
use lib "$Bin/../lib";

#use Data::Dumper;
use BST::User;

for (1..10000) {
    my $u = BST::User->load(id => 'vicki');
}

#print Dumper $u;
