package BST::Schema::PackageItem;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("package_item");
__PACKAGE__->add_columns(
  "package_item_id",
  {
    data_type => "character varying",
    default_value => "nextval('package_item_package_item_id_seq'::regclass)",
    is_nullable => 0,
    size => 255,
  },
  "package_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 255,
  },
  "position",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "item_type",
  {
    data_type => "package_item_type",
    default_value => undef,
    is_nullable => 1,
    size => 4,
  },
  "document_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "file_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
);
__PACKAGE__->set_primary_key("package_item_id");
__PACKAGE__->add_unique_constraint("package_item_pkey", ["package_item_id"]);
__PACKAGE__->belongs_to(
  "document_id",
  "BST::Schema::Document",
  { document_id => "document_id" },
);
__PACKAGE__->belongs_to("package_id", "BST::Schema::File", { file_id => "package_id" });
__PACKAGE__->belongs_to("file_id", "BST::Schema::File", { file_id => "file_id" });


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-11-04 02:22:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/1mBxeRnTkicYZenqPYRAg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
