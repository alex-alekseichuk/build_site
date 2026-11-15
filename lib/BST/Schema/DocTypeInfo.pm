package BST::Schema::DocTypeInfo;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("doc_type_info");
__PACKAGE__->add_columns(
  "doc_type",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "dt_order",
  {
    data_type => "double precision",
    default_value => 9999,
    is_nullable => 1,
    size => 8,
  },
  "dt_abbrev",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 3,
  },
  "dt_label",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "dt_flags",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "dt_help",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 10000,
  },
);
__PACKAGE__->set_primary_key("doc_type");
__PACKAGE__->add_unique_constraint("doc_type_info_dt_abbrev_key", ["dt_abbrev"]);
__PACKAGE__->add_unique_constraint("doc_type_info_dt_label_key", ["dt_label"]);
__PACKAGE__->add_unique_constraint("doc_type_info_pkey", ["doc_type"]);
__PACKAGE__->has_many(
  "documents",
  "BST::Schema::Document",
  { "foreign.doc_type" => "self.doc_type" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-11-04 02:22:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:YqWOGYsFuJiZKPMQRSMG3Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
