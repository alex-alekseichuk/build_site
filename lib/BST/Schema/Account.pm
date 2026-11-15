package BST::Schema::Account;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("account");
__PACKAGE__->add_columns(
  "account_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "account_type",
  {
    data_type => "character varying",
    default_value => "'dealer'::character varying",
    is_nullable => 0,
    size => 250,
  },
  "access_constraints",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "allow_self_registration",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "block_access",
  {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 1,
    size => 1,
  },
  "block_reason",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "signed_final_date",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "signed_trial_date",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "expiration_date",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "mail_opt_out",
  {
    data_type => "character varying",
    default_value => "'false'::character varying",
    is_nullable => 1,
    size => 250,
  },
  "email_opt_out",
  {
    data_type => "character varying",
    default_value => "'false'::character varying",
    is_nullable => 1,
    size => 250,
  },
  "email_opt_out_date",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "mail_opt_out_date",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "sponsor_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "company_id",
  {
    data_type => "character varying",
    default_value => "NULL::character varying",
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
__PACKAGE__->set_primary_key("account_id");
__PACKAGE__->add_unique_constraint("pk_account", ["account_id"]);
__PACKAGE__->belongs_to(
  "company_id",
  "BST::Schema::Company",
  { company_id => "company_id" },
);
__PACKAGE__->has_many(
  "account_locations",
  "BST::Schema::AccountLocation",
  { "foreign.account_id" => "self.account_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-11-04 02:22:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:c9EPbVYWanAvSkC6o7LBwA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
