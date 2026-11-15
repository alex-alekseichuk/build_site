package BST::CategoryCounts;

use strict;
use warnings;

use Data::Dumper;
use Params::Validate qw(:all);


use base qw/BST::Core BST::Schema::CategoryCounts/;

=head1 DESCRIPTION
    Product Category Counters class
=cut

__PACKAGE__->table("category_counts");

__PACKAGE__->belongs_to(
    "category" => "BST::Category",
    { category_id => "category_id" },
    { join_type => 'LEFT' },
);

1;
