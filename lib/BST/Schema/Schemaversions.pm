package BST::Schema::Schemaversions;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("schemaversions");
__PACKAGE__->add_columns(
  "version",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "type",
  {
    data_type => "character varying",
    default_value => "'data'::character varying",
    is_nullable => 0,
    size => 8,
  },
  "installed",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 20,
  },
);
__PACKAGE__->set_primary_key("version", "type");
__PACKAGE__->add_unique_constraint("schemaversions_pkey", ["version", "type"]);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-11-04 02:22:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:XHaZgEbMkD2/xyL2byfKrA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
