package BST::Schema::DBCheckReport;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("dbcheck_reports");
__PACKAGE__->add_columns(

  "dbcheck_reports_id",
  {
    data_type => "bigint",
    default_value => "nextval('dbcheck_reports_id_seq'::regclass)",
    is_nullable => 0,
    size => 8,
  },
  "object_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "bsa_class_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "rule_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "info_fields",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "bad_fields",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "expired",
  { data_type => "boolean", default_value => undef, is_nullable => 0, size => 1 },
  "auto_ctime",
  {
    data_type => "timestamp with time zone",
    default_value => "now()",
    is_nullable => 0,
    size => 8,
  },
);
__PACKAGE__->set_primary_key("dbcheck_reports_id");
__PACKAGE__->add_unique_constraint("dbcheck_reports_pkey", ["dbcheck_reports_id"]);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-01-23 07:00:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fiPUlt2tCM9sB7tUEOB7Hg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
