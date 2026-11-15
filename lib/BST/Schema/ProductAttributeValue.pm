package BST::Schema::ProductAttributeValue;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("product_attribute_value");
__PACKAGE__->add_columns(
  "product_attribute_value_id",
  {
    data_type => "integer",
    default_value => "nextval('product_attribute_value_product_attribute_value_id_seq'::regclass)",
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
  "attribute_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "val",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 1000,
  },
  "max_val",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 1000,
  },
);
__PACKAGE__->set_primary_key("product_attribute_value_id");
__PACKAGE__->add_unique_constraint(
  "product_attribute_value_pkey",
  ["product_attribute_value_id"],
);
__PACKAGE__->belongs_to(
  "attribute_id",
  "BST::Schema::Attribute",
  { attribute_id => "attribute_id" },
);
__PACKAGE__->belongs_to(
  "product_id",
  "BST::Schema::Product",
  { product_id => "product_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-11-04 02:22:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Y7gQkvP0FIMO5n15PQbKjA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
