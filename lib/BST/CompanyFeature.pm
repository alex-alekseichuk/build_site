package BST::CompanyFeature;

use strict;
use warnings;

use base qw/BST::Core BST::Schema::CompanyFeature/;

__PACKAGE__->table("company_feature");

=head1 DESCRIPTION
    Company (Manufacturer) feature class
=cut

__PACKAGE__->belongs_to(
  "company" => "BST::Company",
  { company_id => "company_id" },
);

1;
