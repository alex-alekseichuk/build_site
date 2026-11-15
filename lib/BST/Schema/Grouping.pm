package BST::Schema::Grouping;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("grouping");
__PACKAGE__->add_columns(
  "grouping_id",
  {
    data_type => "integer",
    default_value => "nextval('grouping_grouping_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "grouping_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "grouping_type",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "parent_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "buildsite_private_notes",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 11000,
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
__PACKAGE__->set_primary_key("grouping_id");
__PACKAGE__->add_unique_constraint("grouping_pkey", ["grouping_id"]);
__PACKAGE__->add_unique_constraint("grouping_grouping_name_key", ["grouping_name"]);
__PACKAGE__->has_many(
  "category_groupings",
  "BST::Schema::CategoryGrouping",
  { "foreign.grouping_id" => "self.grouping_id" },
);
__PACKAGE__->has_many(
  "companies",
  "BST::Schema::Company",
  { "foreign.linecard_grouping_id" => "self.grouping_id" },
);
__PACKAGE__->has_many(
  "company_groupings",
  "BST::Schema::CompanyGrouping",
  { "foreign.grouping_id" => "self.grouping_id" },
);
__PACKAGE__->belongs_to(
  "parent_id",
  "BST::Schema::Grouping",
  { grouping_id => "parent_id" },
);
__PACKAGE__->has_many(
  "groupings",
  "BST::Schema::Grouping",
  { "foreign.parent_id" => "self.grouping_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-11-04 02:22:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:BMS5+VwDdSXUmro+P7g3sQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
