package BST::ProductKeyword;

use strict;
use warnings;

use base qw/BST::Core BST::Schema::ProductKeyword/;

__PACKAGE__->table("product_keyword");

__PACKAGE__->belongs_to(
  "product_id" => "BST::Product",
  { product_id => "product_id" },
);

1;
