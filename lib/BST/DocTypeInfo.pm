package BST::DocTypeInfo;

use strict;
use warnings;
use POSIX qw(ceil);

use base qw/BST::Core BST::Schema::DocTypeInfo/;

__PACKAGE__->table("doc_type");


sub search {
    my ($class, $query, $params) = @_;
    return $class->next::method($query, $params);
}

1;
