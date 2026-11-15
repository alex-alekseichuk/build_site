package BST::Schema::FileMarkup;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("file_markup");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "bigint",
    default_value => "nextval('file_markup_id_seq'::regclass)",
    is_nullable => 0,
    size => 8,
  },
  "file_id",
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
  "package_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "page",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "is_active",
  { data_type => "boolean", default_value => undef, is_nullable => 0, size => 1 },
  "json_markup",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 5000,
  },
  "svg_markup",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 5000,
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
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("file_markup_pkey", ["id"]);
__PACKAGE__->belongs_to("file_id", "BST::Schema::File", { file_id => "file_id" });


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-01-23 07:00:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fiPUlt2tCM9sB7tUEOB7Hg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
