package BST::CustomerOrder;

use strict;
use warnings;
use BST;
use BST::Product;
use Data::Dumper;

use base qw/BST::Core BST::Schema::CustomerOrder/;

__PACKAGE__->table('customer_order');

__PACKAGE__->belongs_to(
  "customer_user_id",
  "BST::CustomerUser",
  { customer_user_id => "customer_user_id" },
);


1;
