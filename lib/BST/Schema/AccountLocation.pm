package BST::Schema::AccountLocation;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("account_location");
__PACKAGE__->add_columns(
  "in_directory",
  {
    data_type => "character varying",
    default_value => "'false'::character varying",
    is_nullable => 0,
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
    is_nullable => 1,
    size => 250,
  },
  "addr_city",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "addr_region",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "addr_region_i",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "addr_postal_code",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "addr_postal_code_i",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "addr_country",
  {
    data_type => "character varying",
    default_value => "'us'::character varying",
    is_nullable => 1,
    size => 250,
  },
  "account_location_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "location_nickname",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "location_fullname",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "location_url",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "account_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "company_location_ref",
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
  "block_date",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
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
__PACKAGE__->set_primary_key("account_location_id");
__PACKAGE__->add_unique_constraint("pk_account_location", ["account_location_id"]);
__PACKAGE__->belongs_to(
  "account_id",
  "BST::Schema::Account",
  { account_id => "account_id" },
);
__PACKAGE__->belongs_to(
  "company_location_ref",
  "BST::Schema::Company",
  { company_id => "company_location_ref" },
);
__PACKAGE__->has_many(
  "addressbook_companies",
  "BST::Schema::AddressbookCompany",
  { "foreign.owner" => "self.account_location_id" },
);
__PACKAGE__->has_many(
  "addressbook_people",
  "BST::Schema::AddressbookPerson",
  { "foreign.owner" => "self.account_location_id" },
);
__PACKAGE__->has_many(
  "files",
  "BST::Schema::File",
  { "foreign.owner" => "self.account_location_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-11-04 02:22:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:6j2QtB+k4fkg6nYqlxRIWQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
