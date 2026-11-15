package BST::Schema::CustomerUser;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("customer_user");
__PACKAGE__->add_columns(
  "customer_user_id",
  {
    data_type => "integer",
    default_value => "nextval('customer_user_customer_user_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "customer_account_id",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "login_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "login_password",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "user_role",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "fullname",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
  "email",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "phone",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "employer_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "last_login",
  {
    data_type => "timestamp with time zone",
    default_value => undef,
    is_nullable => 1,
    size => 8,
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
__PACKAGE__->set_primary_key("customer_user_id");
__PACKAGE__->add_unique_constraint("customer_user_pkey", ["customer_user_id"]);
__PACKAGE__->add_unique_constraint("customer_user_login_id_key", ["login_id"]);
__PACKAGE__->has_many(
  "customer_orders",
  "BST::Schema::CustomerOrder",
  { "foreign.customer_user_id" => "self.customer_user_id" },
);
__PACKAGE__->belongs_to(
  "document_list_id",
  "BST::Schema::DocumentList",
  { document_list_id => "document_list_id" },
);
__PACKAGE__->belongs_to(
  "customer_account_id",
  "BST::Schema::CustomerAccount",
  { customer_account_id => "customer_account_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-11-04 02:22:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:9lrNGT+500FFQF/PCt8ywg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
