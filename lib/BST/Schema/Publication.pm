package BST::Schema::Publication;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("publication");
__PACKAGE__->add_columns(
  "publication_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "company_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "buildsite_publication_title",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "publisher_publication_title",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "publisher_publication_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "publication_type",
  {
    data_type => "character varying",
    default_value => "'product'::character varying",
    is_nullable => 0,
    size => 250,
  },
  "web_url",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "web_completeness",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "web_file_format",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "standard_electronic_offered",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "electronic_completeness",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "electronic_file_format",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
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
__PACKAGE__->set_primary_key("publication_id");
__PACKAGE__->add_unique_constraint("publication_pkey", ["publication_id"]);
__PACKAGE__->has_many(
  "documents",
  "BST::Schema::Document",
  { "foreign.publication_id" => "self.publication_id" },
);
__PACKAGE__->belongs_to(
  "company_id",
  "BST::Schema::Company",
  { company_id => "company_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-11-04 02:22:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:UXH3yztkskIdGrk+PLhmQQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
