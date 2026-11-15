package BST::Schema::File;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("file");
__PACKAGE__->add_columns(
  "file_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "creator_user",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "owner",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "file_original_path",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "file_format_type",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "file_mtime",
  {
    data_type => "character varying",
    default_value => "round(date_part('epoch'::text, now()))",
    is_nullable => 0,
    size => 250,
  },
  "file_title",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "file_comment",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
  "page_count",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "is_public",
  {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 0,
    size => 1,
  },
  "scope",
  {
    data_type => "character varying",
    default_value => "'location'::character varying",
    is_nullable => 0,
    size => 250,
  },
  "parent",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "shortcut_to",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "file_size",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "replaced_by_doc",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "deleted_date",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "is_deleted",
  {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 1,
    size => 1,
  },
  "replaced_by_date",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "deleted_by_user",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "replaced_by_user",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "file_class",
  {
    data_type => "file_class_type",
    default_value => "'file'::file_class_type",
    is_nullable => 0,
    size => 4,
  },
  "package_toc_type",
  {
    data_type => "character varying",
    default_value => "NULL::character varying",
    is_nullable => 1,
    size => 255,
  },
  "package_toc_template",
  {
    data_type => "character varying",
    default_value => "NULL::character varying",
    is_nullable => 1,
    size => 255,
  },
  "package_toc_data",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "package_ext_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "file_extension",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
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
__PACKAGE__->set_primary_key("file_id");
__PACKAGE__->add_unique_constraint("pk_account_private_file", ["file_id"]);
__PACKAGE__->has_many(
  "account_users",
  "BST::Schema::AccountUser",
  { "foreign.current_package_id" => "self.file_id" },
);
__PACKAGE__->belongs_to(
  "creator_user",
  "BST::Schema::AccountUser",
  { user_id => "creator_user" },
);
__PACKAGE__->belongs_to(
  "owner",
  "BST::Schema::AccountLocation",
  { account_location_id => "owner" },
);
__PACKAGE__->belongs_to("parent", "BST::Schema::File", { file_id => "parent" });
__PACKAGE__->has_many(
  "files",
  "BST::Schema::File",
  { "foreign.parent" => "self.file_id" },
);
__PACKAGE__->has_many(
  "package_item_package_ids",
  "BST::Schema::PackageItem",
  { "foreign.package_id" => "self.file_id" },
);
__PACKAGE__->has_many(
  "package_item_file_ids",
  "BST::Schema::PackageItem",
  { "foreign.file_id" => "self.file_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-11-04 02:22:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:bsx0rR2+W+L8eWs7hlShEg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
