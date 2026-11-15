package BST::Grouping;

use strict;
use warnings;

use base qw(BST::Core BST::Schema::Grouping);
__PACKAGE__->table('grouping');

=head1 DESCRIPTION

Grouping object

=cut

__PACKAGE__->has_many(
  "companies",
  "BST::Company",
  { "foreign.linecard_grouping_id" => "self.grouping_id" },
);
__PACKAGE__->has_many(
  "company_groupings",
  "BST::CompanyGrouping",
  { "foreign.grouping_id" => "self.grouping_id" },
);
__PACKAGE__->belongs_to(
  "parent_id",
  "BST::Grouping",
  { grouping_id => "parent_id" },
);
__PACKAGE__->has_many(
  "groupings",
  "BST::Grouping",
  { "foreign.parent_id" => "self.grouping_id" },
);

1;
