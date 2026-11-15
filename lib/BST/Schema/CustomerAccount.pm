package BST::Schema::CustomerAccount;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("customer_account");
__PACKAGE__->add_columns(
  "customer_account_id",
  {
    data_type => "integer",
    default_value => "nextval('customer_account_customer_account_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "account_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "company_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "account_type",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "account_purpose",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "block_reason",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "location_phone",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "location_fax",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "addr_po",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "addr_street",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "addr_city",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "addr_region",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "addr_postal_code",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "addr_country",
  {
    data_type => "character varying",
    default_value => "'US'::character varying",
    is_nullable => 1,
    size => 250,
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
__PACKAGE__->set_primary_key("customer_account_id");
__PACKAGE__->add_unique_constraint("customer_account_account_name_key", ["account_name"]);
__PACKAGE__->add_unique_constraint("customer_account_pkey", ["customer_account_id"]);
__PACKAGE__->has_many(
  "credit_cards",
  "BST::Schema::CreditCard",
  { "foreign.customer_account_id" => "self.customer_account_id" },
);
__PACKAGE__->belongs_to(
  "company_id",
  "BST::Schema::Company",
  { company_id => "company_id" },
);
__PACKAGE__->has_many(
  "customer_users",
  "BST::Schema::CustomerUser",
  { "foreign.customer_account_id" => "self.customer_account_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-11-04 02:22:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:PZtPO5pPZ45MPPEX8CXJeQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
