package BST::Schema::CompanyGrouping;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("company_grouping");
__PACKAGE__->add_columns(
  "company_grouping_id",
  {
    data_type => "integer",
    default_value => "nextval('company_grouping_company_grouping_id_seq'::regclass)",
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
  "grouping_id",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
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
__PACKAGE__->set_primary_key("company_grouping_id");
__PACKAGE__->add_unique_constraint("company_grouping_pkey", ["company_grouping_id"]);
__PACKAGE__->add_unique_constraint(
  "company_grouping_company_id_key",
  ["company_id", "grouping_id"],
);
__PACKAGE__->belongs_to(
  "grouping_id",
  "BST::Schema::Grouping",
  { grouping_id => "grouping_id" },
);
__PACKAGE__->belongs_to(
  "company_id",
  "BST::Schema::Company",
  { company_id => "company_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-11-04 02:22:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:7riDUQIj/sBfThpCXnKvuw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
