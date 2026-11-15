package BST::Schema::Product;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("product");
__PACKAGE__->add_columns(
  "product_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "manufacturer_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "category_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "superseded_by_product_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "product_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "brand",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "mfg_product_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "mfg_categories",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
  "mfg_product_kicker",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
  "mfg_flags",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "mfg_short_text",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
  "mfg_long_text",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
  "discontinued_date",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "is_accessory",
  {
    data_type => "character varying",
    default_value => "'false'::character varying",
    is_nullable => 0,
    size => 250,
  },
  "systemness",
  {
    data_type => "character varying",
    default_value => "'not'::character varying",
    is_nullable => 0,
    size => 250,
  },
  "system_parts",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
  "related_products",
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
  "buildsite_public_notes",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 11000,
  },
  "buildsite_private_notes",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 11000,
  },
  "check_flags",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "product_name_search_tsvector",
  {
    data_type => "tsvector",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "product_name_search_keywords",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "product_name_ext_search_tsvector",
  {
    data_type => "tsvector",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "is_green",
  {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 1,
    size => 1,
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
    default_value => "'2010-01-01 00:00:00-05'::timestamp with time zone",
    is_nullable => 1,
    size => 8,
  },
);
__PACKAGE__->set_primary_key("product_id");
__PACKAGE__->add_unique_constraint("product_pkey", ["product_id"]);
__PACKAGE__->has_many(
  "documents",
  "BST::Schema::Document",
  { "foreign.product_id" => "self.product_id" },
);
__PACKAGE__->belongs_to(
  "superseded_by_product_id",
  "BST::Schema::Product",
  { product_id => "superseded_by_product_id" },
);
__PACKAGE__->has_many(
  "products",
  "BST::Schema::Product",
  { "foreign.superseded_by_product_id" => "self.product_id" },
);
__PACKAGE__->belongs_to(
  "manufacturer_id",
  "BST::Schema::Company",
  { company_id => "manufacturer_id" },
);
__PACKAGE__->belongs_to(
  "category_id",
  "BST::Schema::Category",
  { category_id => "category_id" },
);
__PACKAGE__->has_many(
  "product_attribute_values",
  "BST::Schema::ProductAttributeValue",
  { "foreign.product_id" => "self.product_id" },
);
__PACKAGE__->has_many(
  "product_keywords",
  "BST::Schema::ProductKeyword",
  { "foreign.product_id" => "self.product_id" },
);
__PACKAGE__->has_many(
  "product_leed_credits",
  "BST::Schema::ProductLeedCredit",
  { "foreign.product_id" => "self.product_id" },
);
__PACKAGE__->has_many(
  "product_related_related_product_ids",
  "BST::Schema::ProductRelated",
  { "foreign.related_product_id" => "self.product_id" },
);
__PACKAGE__->has_many(
  "product_related_product_ids",
  "BST::Schema::ProductRelated",
  { "foreign.product_id" => "self.product_id" },
);
__PACKAGE__->has_many(
  "product_standards",
  "BST::Schema::ProductStandard",
  { "foreign.product_id" => "self.product_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-01-28 01:48:12
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:zoea5xZbxfEOUIuQQvuZ7Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
