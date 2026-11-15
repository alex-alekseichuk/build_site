package BST::Schema::ProductLeedCredit;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("product_leed_credit");
__PACKAGE__->add_columns(
  "product_leed_credit_id",
  {
    data_type => "integer",
    default_value => "nextval('product_leed_credit_product_leed_credit_id_seq'::regclass)",
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
  "leed_credit_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
);
__PACKAGE__->set_primary_key("product_leed_credit_id");
__PACKAGE__->add_unique_constraint("product_leed_credit_pkey", ["product_leed_credit_id"]);
__PACKAGE__->belongs_to(
  "product_id",
  "BST::Schema::Product",
  { product_id => "product_id" },
);
__PACKAGE__->belongs_to(
  "leed_credit_id",
  "BST::Schema::LeedCredit",
  { leed_credit_id => "leed_credit_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-11-04 02:22:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:sbFL/3M/HQGZYES9Hw5WOA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
