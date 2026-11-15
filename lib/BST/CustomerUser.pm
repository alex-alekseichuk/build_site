package BST::CustomerUser;

use strict;
use warnings;
use BST;
use BST::Product;
use Data::Dumper;

use base qw/BST::Core BST::Schema::CustomerUser/;

__PACKAGE__->table('customer_user');

__PACKAGE__->has_many(
  "customer_orders",
  "BST::CustomerOrder",
  { "foreign.customer_user_id" => "self.customer_user_id" },
);



1;
