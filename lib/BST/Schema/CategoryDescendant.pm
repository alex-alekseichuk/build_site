package BST::Schema::CategoryDescendant;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("category_descendant");
__PACKAGE__->add_columns(
  "category_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "descendant_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "descendant_distance",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
);
__PACKAGE__->add_unique_constraint(
  "category_descendant_category_id_key",
  ["category_id", "descendant_id"],
);
__PACKAGE__->belongs_to(
  "descendant_id",
  "BST::Schema::Category",
  { category_id => "descendant_id" },
);
__PACKAGE__->belongs_to(
  "category_id",
  "BST::Schema::Category",
  { category_id => "category_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-11-04 02:22:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:IL9cn+E86iyES1XL4RrI9A


# You can replace this text with custom content, and it will be preserved on regeneration
1;
