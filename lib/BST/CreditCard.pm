package BST::CreditCard;

use strict;
use warnings;
use BST;
use BST::Product;
use Data::Dumper;

use base qw/BST::Core BST::Schema::CreditCard/;

__PACKAGE__->table('credit_card');



1;
