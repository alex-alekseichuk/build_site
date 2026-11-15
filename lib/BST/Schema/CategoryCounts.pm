package BST::Schema::CategoryCounts;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("category_counts");
__PACKAGE__->add_columns(
  "category_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "products",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "manufacturers",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "products_admin",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "manufacturers_admin",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "green_products",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "green_manufacturers",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "green_products_admin",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "green_manufacturers_admin",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("category_id"); 


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-11-04 02:22:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:yv6KO7weFP0q4S0Uk9JKsw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
