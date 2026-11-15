package BST::CompanyGrouping;

use strict;
use warnings;

use base qw(BST::Core BST::Schema::CompanyGrouping);
__PACKAGE__->table('company_grouping');

=head1 DESCRIPTION

Company grouping object

=cut

__PACKAGE__->belongs_to(
  "grouping_id",
  "BST::Grouping",
  { grouping_id => "grouping_id" },
);
__PACKAGE__->belongs_to(
  "company_id",
  "BST::Company",
  { company_id => "company_id" },
);

1;
