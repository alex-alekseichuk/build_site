package BST::Schema::Category;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("category");
__PACKAGE__->add_columns(
  "category_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "parent_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "category_title",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "category_full_title",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
  "buildsite_description",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 1024,
  },
  "see_also_category_ids",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
  "see_instead_category_ids",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
  "mf_see_also_category_ids",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
  "mf_see_instead_category_ids",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
  "mf_references_from",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
  "mf_includes",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
  "mf_usually_includes",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
  "mf_may_include",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
  "mf_note",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
  "public_visible",
  {
    data_type => "boolean",
    default_value => "true",
    is_nullable => 1,
    size => 1,
  },
  "suppress_reason_code",
  {
    data_type => "character varying",
    default_value => "''::character varying",
    is_nullable => 0,
    size => 250,
  },
  "check_flags",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "buildsite_private_notes",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 11000,
  },
  "buildsite_public_notes",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 11000,
  },
  "category_search_tsvector",
  {
    data_type => "tsvector",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "category_search_keywords",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
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
__PACKAGE__->set_primary_key("category_id");
__PACKAGE__->add_unique_constraint("category_pkey", ["category_id"]);
__PACKAGE__->belongs_to(
  "parent_id",
  "BST::Schema::Category",
  { category_id => "parent_id" },
);
__PACKAGE__->has_many(
  "categories",
  "BST::Schema::Category",
  { "foreign.parent_id" => "self.category_id" },
);
__PACKAGE__->has_many(
  "category_attributes",
  "BST::Schema::CategoryAttribute",
  { "foreign.category_id" => "self.category_id" },
);
__PACKAGE__->has_many(
  "category_descendant_descendant_ids",
  "BST::Schema::CategoryDescendant",
  { "foreign.descendant_id" => "self.category_id" },
);
__PACKAGE__->has_many(
  "category_descendant_category_ids",
  "BST::Schema::CategoryDescendant",
  { "foreign.category_id" => "self.category_id" },
);
__PACKAGE__->has_many(
  "category_groupings",
  "BST::Schema::CategoryGrouping",
  { "foreign.category_id" => "self.category_id" },
);
__PACKAGE__->has_many(
  "category_keywords",
  "BST::Schema::CategoryKeyword",
  { "foreign.category_id" => "self.category_id" },
);
__PACKAGE__->has_many(
  "documents",
  "BST::Schema::Document",
  { "foreign.category_id" => "self.category_id" },
);
__PACKAGE__->has_many(
  "products",
  "BST::Schema::Product",
  { "foreign.category_id" => "self.category_id" },
);
__PACKAGE__->has_many(
  "standards",
  "BST::Schema::Standard",
  { "foreign.category_id" => "self.category_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-11-04 02:22:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Y9hV/VTRXFc9lXPydQiVuw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
