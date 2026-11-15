package BST::Schema::Attribute;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("attribute");
__PACKAGE__->add_columns(
  "attribute_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "attribute_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "attribute_type",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 100,
  },
  "attribute_description",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 30000,
  },
  "data_type_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 100,
  },
  "value_units",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 100,
  },
  "detail_display_order",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "result_display_type",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 100,
  },
  "result_display_order",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "search_display_order",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "comments",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 10000,
  },
);
__PACKAGE__->set_primary_key("attribute_id");
__PACKAGE__->add_unique_constraint("attribute_attribute_name_key", ["attribute_name"]);
__PACKAGE__->add_unique_constraint("attribute_pkey", ["attribute_id"]);
__PACKAGE__->has_many(
  "category_attributes",
  "BST::Schema::CategoryAttribute",
  { "foreign.attribute_id" => "self.attribute_id" },
);
__PACKAGE__->has_many(
  "leed_credit_attributes",
  "BST::Schema::LeedCreditAttribute",
  { "foreign.attribute_id" => "self.attribute_id" },
);
__PACKAGE__->has_many(
  "product_attribute_values",
  "BST::Schema::ProductAttributeValue",
  { "foreign.attribute_id" => "self.attribute_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-11-04 02:22:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:7DQAua/Hw1PaZE3bGhD7kQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
