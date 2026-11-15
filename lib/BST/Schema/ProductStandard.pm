package BST::Schema::ProductStandard;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("product_standard");
__PACKAGE__->add_columns(
  "product_standard_id",
  {
    data_type => "integer",
    default_value => "nextval('product_standard_product_standard_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "product_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "standard_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "standard_org_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "standard_document_identifier",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "standard_parameters",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
  "astm_search_tsvector",
  {
    data_type => "tsvector",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "astm_search_keywords",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
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
  "admin_mtime",
  {
    data_type => "timestamp with time zone",
    default_value => "'2010-01-01 00:00:00-05'::timestamp with time zone",
    is_nullable => 1,
    size => 8,
  },
);
__PACKAGE__->set_primary_key("product_standard_id");
__PACKAGE__->add_unique_constraint("product_standard_pkey", ["product_standard_id"]);
__PACKAGE__->belongs_to(
  "standard_id",
  "BST::Schema::Standard",
  { standard_id => "standard_id" },
);
__PACKAGE__->belongs_to(
  "product_id",
  "BST::Schema::Product",
  { product_id => "product_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-01-28 01:48:12
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:nQGLV31iJRfu70ggAkTkWQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
