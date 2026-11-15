package BST::Schema::LeedCreditAttribute;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("leed_credit_attribute");
__PACKAGE__->add_columns(
  "leed_credit_attribute_id",
  {
    data_type => "integer",
    default_value => "nextval('leed_credit_attribute_leed_credit_attribute_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "leed_credit_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "attribute_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "display_order",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
);
__PACKAGE__->set_primary_key("leed_credit_attribute_id");
__PACKAGE__->add_unique_constraint("leed_credit_attribute_pkey", ["leed_credit_attribute_id"]);
__PACKAGE__->belongs_to(
  "leed_credit_id",
  "BST::Schema::LeedCredit",
  { leed_credit_id => "leed_credit_id" },
);
__PACKAGE__->belongs_to(
  "attribute_id",
  "BST::Schema::Attribute",
  { attribute_id => "attribute_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-11-04 02:22:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:cbWwd3lFSJWYu8hbdF6usg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
