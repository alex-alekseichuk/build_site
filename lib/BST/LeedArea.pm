package BST::LeedArea;

use strict;
use warnings;

use base qw/BST::Core BST::Schema::LeedArea/;
use BST::LeedCredit;

__PACKAGE__->table('leed_area');

__PACKAGE__->has_many(
  "leed_credits",
  "BST::LeedCredit",
  { "foreign.leed_area_id" => "self.leed_area_id" },
  { order_by => 'leed_credit_id' },
);

1;
