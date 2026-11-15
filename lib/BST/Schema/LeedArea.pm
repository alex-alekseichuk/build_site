package BST::Schema::LeedArea;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("leed_area");
__PACKAGE__->add_columns(
  "leed_area_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 10,
  },
  "leed_area_title",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 1000,
  },
  "leed_area_display_order",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
);
__PACKAGE__->set_primary_key("leed_area_id");
__PACKAGE__->add_unique_constraint("leed_area_pkey", ["leed_area_id"]);
__PACKAGE__->has_many(
  "leed_credits",
  "BST::Schema::LeedCredit",
  { "foreign.leed_area_id" => "self.leed_area_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-11-04 02:22:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:jcMxtkXT85uii6lbLF7gFA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
