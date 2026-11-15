package BST::Schema::CreditCard;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("credit_card");
__PACKAGE__->add_columns(
  "credit_card_id",
  {
    data_type => "integer",
    default_value => "nextval('credit_card_credit_card_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "customer_account_id",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "card_active",
  {
    data_type => "boolean",
    default_value => "true",
    is_nullable => 1,
    size => 1,
  },
  "billing_from_account",
  { data_type => "boolean", default_value => undef, is_nullable => 0, size => 1 },
  "billing_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "billing_street",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "billing_city",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "billing_region",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "billing_postal_code",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "billing_country",
  {
    data_type => "character varying",
    default_value => "'US'::character varying",
    is_nullable => 1,
    size => 250,
  },
  "cc_type",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "cc_number_encrypted",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 1024,
  },
  "cc_number_last4",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 20,
  },
  "cc_expire_month",
  {
    data_type => "character",
    default_value => undef,
    is_nullable => 0,
    size => 2,
  },
  "cc_expire_year",
  {
    data_type => "character",
    default_value => undef,
    is_nullable => 0,
    size => 4,
  },
  "cc_verif_number",
  {
    data_type => "character",
    default_value => undef,
    is_nullable => 1,
    size => 5,
  },
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
__PACKAGE__->set_primary_key("credit_card_id");
__PACKAGE__->add_unique_constraint(
  "credit_card_customer_account_id_key",
  ["customer_account_id", "cc_number_encrypted"],
);
__PACKAGE__->add_unique_constraint("credit_card_pkey", ["credit_card_id"]);
__PACKAGE__->belongs_to(
  "customer_account_id",
  "BST::Schema::CustomerAccount",
  { customer_account_id => "customer_account_id" },
);
__PACKAGE__->has_many(
  "customer_orders",
  "BST::Schema::CustomerOrder",
  { "foreign.credit_card_id" => "self.credit_card_id" },
);
__PACKAGE__->has_many(
  "gateway_payments",
  "BST::Schema::GatewayPayment",
  { "foreign.credit_card_id" => "self.credit_card_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-11-04 02:22:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:l8wfE0NmOdJBPRbw1hvdvg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
