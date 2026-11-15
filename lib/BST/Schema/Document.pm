package BST::Schema::Document;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("document");
__PACKAGE__->add_columns(
  "document_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "document_type",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "publication_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "replaced_by_document_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "original_publisher_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "about_company_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "doc_type",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "other_doc_types",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "publisher_document_title",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "publisher_doc_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "publisher_doc_date",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "sweets_doc_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "lang_id",
  {
    data_type => "character varying",
    default_value => "'en'::character varying",
    is_nullable => 0,
    size => 250,
  },
  "country_id",
  {
    data_type => "character varying",
    default_value => "'US'::character varying",
    is_nullable => 0,
    size => 250,
  },
  "source_url",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
  "source_path",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
  "source_mtime",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "source_filesize",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "source_checksum",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "derived_path",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
  "derived_format",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "derived_how",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "derived_params",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
  "derived_pagecount",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "derived_filesize",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "authoritative_docset",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "image_path",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "document_derived_from",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "file_format_type",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "public_visible",
  {
    data_type => "boolean",
    default_value => "true",
    is_nullable => 1,
    size => 1,
  },
  "suppress_reason_code",
  {
    data_type => "character varying",
    default_value => "''::character varying",
    is_nullable => 0,
    size => 250,
  },
  "buildsite_private_notes",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 11000,
  },
  "buildsite_public_notes",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 11000,
  },
  "check_flags",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "product_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "category_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "is_generic",
  {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 0,
    size => 1,
  },
  "document_role",
  {
    data_type => "character varying",
    default_value => "'none'::character varying",
    is_nullable => 0,
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
__PACKAGE__->set_primary_key("document_id");
__PACKAGE__->add_unique_constraint("document_pkey", ["document_id"]);
__PACKAGE__->belongs_to(
  "replaced_by_document_id",
  "BST::Schema::Document",
  { document_id => "replaced_by_document_id" },
);
__PACKAGE__->has_many(
  "documents",
  "BST::Schema::Document",
  { "foreign.replaced_by_document_id" => "self.document_id" },
);
__PACKAGE__->belongs_to(
  "product_id",
  "BST::Schema::Product",
  { product_id => "product_id" },
);
__PACKAGE__->belongs_to(
  "original_publisher_id",
  "BST::Schema::Company",
  { company_id => "original_publisher_id" },
);
__PACKAGE__->belongs_to(
  "category_id",
  "BST::Schema::Category",
  { category_id => "category_id" },
);
__PACKAGE__->belongs_to(
  "doc_type",
  "BST::Schema::DocTypeInfo",
  { doc_type => "doc_type" },
);
__PACKAGE__->belongs_to(
  "publication_id",
  "BST::Schema::Publication",
  { publication_id => "publication_id" },
);
__PACKAGE__->belongs_to(
  "about_company_id",
  "BST::Schema::Company",
  { company_id => "about_company_id" },
);
__PACKAGE__->has_many(
  "document_list_members",
  "BST::Schema::DocumentListMember",
  { "foreign.document_id" => "self.document_id" },
);
__PACKAGE__->has_many(
  "msds_documents",
  "BST::Schema::MsdsDocument",
  { "foreign.document_id" => "self.document_id" },
);
__PACKAGE__->has_many(
  "package_items",
  "BST::Schema::PackageItem",
  { "foreign.document_id" => "self.document_id" },
);
__PACKAGE__->has_many(
  "product_relateds",
  "BST::Schema::ProductRelated",
  { "foreign.section_document_id" => "self.document_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-11-04 02:22:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:LSox9+4lag5jsKKy0Omk9g


# You can replace this text with custom content, and it will be preserved on regeneration
1;
