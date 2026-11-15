package BST::Schema::CompanyFeature;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("company_feature");
__PACKAGE__->add_columns(
  "company_feature_id",
  {
    data_type => "integer",
    default_value => "nextval('company_feature_company_feature_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "company_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "feature_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "feature_level",
  {
    data_type => "character varying",
    default_value => "'economy'::character varying",
    is_nullable => 0,
    size => 250,
  },
  "feature_status",
  {
    data_type => "character varying",
    default_value => "'live'::character varying",
    is_nullable => 0,
    size => 250,
  },
  "feature_params",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
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
__PACKAGE__->set_primary_key("company_feature_id");
__PACKAGE__->add_unique_constraint("company_feature_pkey", ["company_feature_id"]);
__PACKAGE__->add_unique_constraint(
  "company_feature_company_id_key",
  ["company_id", "feature_name"],
);
__PACKAGE__->belongs_to(
  "company_id",
  "BST::Schema::Company",
  { company_id => "company_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-11-04 02:22:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:UJ3kY3u3vqpx36q+raWxAA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
