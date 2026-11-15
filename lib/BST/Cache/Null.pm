package BST::Cache::Null;

use strict;
use warnings;

use base qw/BST::Cache/;

sub is_cached { return 0; }

sub set {
    shift;
    shift;
    return shift;
}

1;