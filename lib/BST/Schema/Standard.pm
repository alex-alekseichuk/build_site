package BST::Schema::Standard;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("standard");
__PACKAGE__->add_columns(
  "standard_id",
  {
    data_type => "integer",
    default_value => "nextval('standard_standard_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "standard_org_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "standard_document_identifier",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "other_identifiers",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
  "category_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "official_title",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "official_description",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 30000,
  },
  "buildsite_private_notes",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 30000,
  },
  "parameter_info",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
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
  "admin_mtime",
  {
    data_type => "timestamp with time zone",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
);
__PACKAGE__->set_primary_key("standard_id");
__PACKAGE__->add_unique_constraint(
  "standard_standard_org_id_key",
  ["standard_org_id", "standard_document_identifier"],
);
__PACKAGE__->add_unique_constraint("standard_pkey", ["standard_id"]);
__PACKAGE__->has_many(
  "product_standards",
  "BST::Schema::ProductStandard",
  { "foreign.standard_id" => "self.standard_id" },
);
__PACKAGE__->belongs_to(
  "category_id",
  "BST::Schema::Category",
  { category_id => "category_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-01-28 01:48:12
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:PDsTdLUGKA26c9vgrAKJmw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
