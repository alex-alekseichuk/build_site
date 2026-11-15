use strict;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Data::Dumper;
use BST::UserNew2;

#foreach (1..10000) {
    my $u = BST::UserNew2->load(user_id => 'vicki');
#}

print Dumper $u;

