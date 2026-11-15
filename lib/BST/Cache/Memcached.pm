package BST::Cache::Memcached;

use strict;
use warnings;

use Cache::Memcached;

use base qw/BST::Cache/;

my $memcached = new Cache::Memcached {
    servers     => [ "127.0.0.1:11211" ],
    #debug       => 1,
};

sub set {
    shift;
    my $key = shift;
    my $obj = shift;
    return $obj if $memcached->set($key, $obj);
}

sub get {
    local $DBIx::Class::ResultSourceHandle::thaw_schema = BST::schema();
    shift;
    return $memcached->get(shift);
}

sub clear {
    $memcached->flush_all();
}

sub storage {
    
}

1;