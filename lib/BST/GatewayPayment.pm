package BST::GatewayPayment;

use strict;
use warnings;
use BST;
use BST::Product;
use Data::Dumper;

use base qw/BST::Core BST::Schema::GatewayPayment/;

__PACKAGE__->table('gateway_payment');

sub sequence_name {
    return 'gateway_payment_payment_id_seq';
}


1;
