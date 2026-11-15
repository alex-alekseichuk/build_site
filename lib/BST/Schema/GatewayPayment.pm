package BST::Schema::GatewayPayment;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("gateway_payment");
__PACKAGE__->add_columns(
  "payment_id",
  {
    data_type => "integer",
    default_value => "nextval('gateway_payment_payment_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "customer_order_id",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "credit_card_id",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "recur_index",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "txn_start_epoch",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "txn_finish_epoch",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "txn_status_flag",
  {
    data_type => "character",
    default_value => undef,
    is_nullable => 0,
    size => 1,
  },
  "txn_type",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 20,
  },
  "txn_amount",
  {
    data_type => "numeric",
    default_value => undef,
    is_nullable => 0,
    size => "2,10",
  },
  "txn_avs_flags",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
  "txn_verif_flags",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
  "txn_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "txn_refnum",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "txn_result_code",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "txn_message",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
  "gw_system",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "gw_account",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "gw_testmode",
  { data_type => "boolean", default_value => undef, is_nullable => 0, size => 1 },
  "auto_ctime",
  {
    data_type => "timestamp with time zone",
    default_value => "now()",
    is_nullable => 0,
    size => 8,
  },
  "auto_mtime",
  {
    data_type => "timestamp with time zone",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
);
__PACKAGE__->set_primary_key("payment_id");
__PACKAGE__->add_unique_constraint("gateway_payment_pkey", ["payment_id"]);
__PACKAGE__->add_unique_constraint(
  "gateway_payment_customer_order_id_key",
  ["customer_order_id", "txn_start_epoch"],
);
__PACKAGE__->belongs_to(
  "customer_order_id",
  "BST::Schema::CustomerOrder",
  { customer_order_id => "customer_order_id" },
);
__PACKAGE__->belongs_to(
  "credit_card_id",
  "BST::Schema::CreditCard",
  { credit_card_id => "credit_card_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-11-04 02:22:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:IkuMo3KDlQnFS9C1or8ATw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
