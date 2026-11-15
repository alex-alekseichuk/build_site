package BST::Cache::Dumb;

use strict;
use warnings;

use base qw/BST::Cache/;

my $_cache  = {};

sub set {
    shift;
    my $key = shift;
    return $_cache->{$key} = shift;
}

sub get {
    shift;
    return $_cache->{+shift};
}

sub clear {
    $_cache = {};
}

sub storage {
    $_cache;
}

1;