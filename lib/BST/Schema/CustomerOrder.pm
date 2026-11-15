package BST::Schema::CustomerOrder;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("customer_order");
__PACKAGE__->add_columns(
  "customer_order_id",
  {
    data_type => "integer",
    default_value => "nextval('customer_order_customer_order_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "customer_user_id",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "service_nickname",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "service_dsn",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "product_params",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
  "amount",
  {
    data_type => "numeric",
    default_value => undef,
    is_nullable => 0,
    size => "2,10",
  },
  "recur_interval",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "created_epoch",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "order_start",
  { data_type => "date", default_value => undef, is_nullable => 0, size => 4 },
  "order_expires",
  { data_type => "date", default_value => undef, is_nullable => 1, size => 4 },
  "order_status",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "free_until",
  { data_type => "date", default_value => undef, is_nullable => 1, size => 4 },
  "ipaddr",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 20,
  },
  "private_comments",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 11000,
  },
  "credit_card_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
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
__PACKAGE__->set_primary_key("customer_order_id");
__PACKAGE__->add_unique_constraint(
  "customer_order_customer_user_id_key",
  ["customer_user_id", "service_nickname", "created_epoch"],
);
__PACKAGE__->add_unique_constraint("customer_order_pkey", ["customer_order_id"]);
__PACKAGE__->belongs_to(
  "customer_user_id",
  "BST::Schema::CustomerUser",
  { customer_user_id => "customer_user_id" },
);
__PACKAGE__->belongs_to(
  "service_nickname",
  "BST::Schema::Service",
  { service_nickname => "service_nickname" },
);
__PACKAGE__->belongs_to(
  "credit_card_id",
  "BST::Schema::CreditCard",
  { credit_card_id => "credit_card_id" },
);
__PACKAGE__->has_many(
  "gateway_payments",
  "BST::Schema::GatewayPayment",
  { "foreign.customer_order_id" => "self.customer_order_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-11-04 02:22:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Ne0Fjflqsk8oj3VfABT3sQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
