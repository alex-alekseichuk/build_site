package BST::Schema::MsdsGroup;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("msds_group");
__PACKAGE__->add_columns(
  "msds_group_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "position",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
);
__PACKAGE__->set_primary_key("msds_group_id");
__PACKAGE__->add_unique_constraint("ps_msds_group", ["msds_group_id"]);
__PACKAGE__->has_many(
  "msds_documents",
  "BST::Schema::MsdsDocument",
  { "foreign.msds_group_id" => "self.msds_group_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-11-04 02:22:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:cYSt8Lnn9egkIvDKd702Kw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
