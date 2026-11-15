package BST::Schema::CategoryGrouping;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("category_grouping");
__PACKAGE__->add_columns(
  "category_grouping_id",
  {
    data_type => "integer",
    default_value => "nextval('category_grouping_category_grouping_id_seq'::regclass)",
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
  "grouping_id",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
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
__PACKAGE__->set_primary_key("category_grouping_id");
__PACKAGE__->add_unique_constraint("category_grouping_pkey", ["category_grouping_id"]);
__PACKAGE__->add_unique_constraint(
  "category_grouping_category_id_key",
  ["category_id", "grouping_id"],
);
__PACKAGE__->belongs_to(
  "grouping_id",
  "BST::Schema::Grouping",
  { grouping_id => "grouping_id" },
);
__PACKAGE__->belongs_to(
  "category_id",
  "BST::Schema::Category",
  { category_id => "category_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-11-04 02:22:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:pjf4aEKHigjk6L70blHOBg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
