package BST::Schema::SystemInfo;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("system_info");
__PACKAGE__->add_columns(
  "att_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "att_val",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 10000,
  },
);
__PACKAGE__->add_unique_constraint("system_info_att_name_key", ["att_name"]);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-11-04 02:22:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:o28qYb3A56s/zw9XZ6P05w


# You can replace this text with custom content, and it will be preserved on regeneration
1;
