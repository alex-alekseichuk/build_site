package BST::ProductLeedCredit;

use strict;
use warnings;

use base qw/BST::Core BST::Schema::ProductLeedCredit/;

__PACKAGE__->table('product_leed_credit');

__PACKAGE__->belongs_to(
  "product_id",
  "BST::Product",
  { product_id => "product_id" },
);

__PACKAGE__->belongs_to(
  "leed_credit_id",
  "BST::LeedCredit",
  { leed_credit_id => "leed_credit_id" },
);

1;
