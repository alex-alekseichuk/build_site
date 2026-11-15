package BST::Schema::ProductRelated;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("product_related");
__PACKAGE__->add_columns(
  "product_related_id",
  {
    data_type => "integer",
    default_value => "nextval('product_related_product_related_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "product_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "related_product_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "related_product_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "related_type",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "display_order",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "section_title",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "section_document_id",
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
__PACKAGE__->set_primary_key("product_related_id");
__PACKAGE__->add_unique_constraint("product_related_pkey", ["product_related_id"]);
__PACKAGE__->belongs_to(
  "related_product_id",
  "BST::Schema::Product",
  { product_id => "related_product_id" },
);
__PACKAGE__->belongs_to(
  "product_id",
  "BST::Schema::Product",
  { product_id => "product_id" },
);
__PACKAGE__->belongs_to(
  "section_document_id",
  "BST::Schema::Document",
  { document_id => "section_document_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-11-04 02:22:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:JTrylOEs0Vro4EfqOiT+tw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
