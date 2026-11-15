package BST::Schema::CategoryAttribute;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("category_attribute");
__PACKAGE__->add_columns(
  "category_attribute_id",
  {
    data_type => "integer",
    default_value => "nextval('category_attribute_category_attribute_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "category_id",
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
);
__PACKAGE__->set_primary_key("category_attribute_id");
__PACKAGE__->add_unique_constraint("category_attribute_pkey", ["category_attribute_id"]);
__PACKAGE__->belongs_to(
  "attribute_id",
  "BST::Schema::Attribute",
  { attribute_id => "attribute_id" },
);
__PACKAGE__->belongs_to(
  "category_id",
  "BST::Schema::Category",
  { category_id => "category_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-11-04 02:22:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:V6LIo0LS9JkuVgcIZuHOVg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
