package BST::Schema::AddressbookCompany;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("addressbook_company");
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
  "owner",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "addressbook_company_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "company_fullname",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "company_url",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "company_state",
  {
    data_type => "character varying",
    default_value => "'active'::character varying",
    is_nullable => 0,
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
__PACKAGE__->set_primary_key("addressbook_company_id");
__PACKAGE__->add_unique_constraint("pk_account_private_company", ["addressbook_company_id"]);
__PACKAGE__->has_many(
  "account_private_locations",
  "BST::Schema::AccountPrivateLocation",
  {
    "foreign.account_private_company_ref" => "self.addressbook_company_id",
  },
);
__PACKAGE__->belongs_to(
  "owner",
  "BST::Schema::AccountLocation",
  { account_location_id => "owner" },
);
__PACKAGE__->has_many(
  "addressbook_people",
  "BST::Schema::AddressbookPerson",
  {
    "foreign.addressbook_company_id" => "self.addressbook_company_id",
  },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-11-04 02:22:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:npSvXgK2o1nJKjEjvp94Yw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
