package BST::Publication;

use strict;
use warnings;

use base qw/BST::Core BST::Schema::Publication/;

__PACKAGE__->table("publication");
__PACKAGE__->has_many(
  "documents",
  "BST::Document",
  { "foreign.publication_id" => "self.publication_id" },
);
__PACKAGE__->belongs_to(
  "company",
  "BST::Company",
  { company_id => "company_id" },
);

1;
