package BST::Cache;

use strict;
use warnings;

my $_cache;

sub new {
    my $proto   = shift;
    bless { @_ }, ref($proto) || $proto;
}

sub cache {
    return $_cache ||= _get_cache();
}

sub _get_cache {
    require BST; BST->import(qw/config/);
    
    my ($cache, $module);
    
    $cache = BST::config("cache") || 'BST::Cache::Dumb';
    ($module = $cache) =~ s!::!/!gis;
    
    require "$module.pm";
    
    return new $cache;
}

sub get {};
sub set {};
sub clear {};
sub storage {};

1;