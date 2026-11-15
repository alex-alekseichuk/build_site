package BST::ProductStandard;

use strict;
use warnings;

use base qw/BST::Core BST::Schema::ProductStandard/;

__PACKAGE__->table("product_standard");

__PACKAGE__->belongs_to(
  "product_id" => "BST::Product",
  { product_id => "product_id" },
);

__PACKAGE__->belongs_to(
  "standard",
  "BST::Schema::Standard",
  { standard_id => "standard_id" },
);

1;
