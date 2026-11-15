package BST::Schema::LeedCredit;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("leed_credit");
__PACKAGE__->add_columns(
  "leed_credit_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "leed_area_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 10,
  },
  "leed_section_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "leed_title",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 1000,
  },
  "buildsite_description_html",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 30000,
  },
  "leed_version",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "buildsite_template_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "standard_url",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 1000,
  },
  "pdf_file",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 1000,
  },
  "leed_credit_type",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
);
__PACKAGE__->set_primary_key("leed_credit_id");
__PACKAGE__->add_unique_constraint("leed_credit_pkey", ["leed_credit_id"]);
__PACKAGE__->belongs_to(
  "leed_area_id",
  "BST::Schema::LeedArea",
  { leed_area_id => "leed_area_id" },
);
__PACKAGE__->has_many(
  "leed_credit_attributes",
  "BST::Schema::LeedCreditAttribute",
  { "foreign.leed_credit_id" => "self.leed_credit_id" },
);
__PACKAGE__->has_many(
  "product_leed_credits",
  "BST::Schema::ProductLeedCredit",
  { "foreign.leed_credit_id" => "self.leed_credit_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-11-04 02:22:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:9936dklXtSJCdy4ubdLqbw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
