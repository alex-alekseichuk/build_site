package BST::Schema::MsdsDocument;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("msds_document");
__PACKAGE__->add_columns(
  "msds_group_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "document_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "position",
  {
    data_type => "smallint",
    default_value => undef,
    is_nullable => 1,
    size => 2,
  },
);
__PACKAGE__->set_primary_key("msds_group_id", "document_id");
__PACKAGE__->add_unique_constraint("pk_msds_document", ["msds_group_id", "document_id"]);
__PACKAGE__->belongs_to(
  "msds_group_id",
  "BST::Schema::MsdsGroup",
  { msds_group_id => "msds_group_id" },
);
__PACKAGE__->belongs_to(
  "document_id",
  "BST::Schema::Document",
  { document_id => "document_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-11-04 02:22:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:QtYjMoYFr1ZHIVCopziJlw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
