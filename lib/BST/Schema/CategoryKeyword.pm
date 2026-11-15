package BST::Schema::CategoryKeyword;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("category_keyword");
__PACKAGE__->add_columns(
  "keyword_id",
  {
    data_type => "integer",
    default_value => "nextval('category_keyword_keyword_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "keyword",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "keyword_type",
  {
    data_type => "character",
    default_value => undef,
    is_nullable => 0,
    size => 1,
  },
  "category_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 250,
  },
  "score",
  { data_type => "integer", default_value => 10, is_nullable => 1, size => 4 },
);
__PACKAGE__->set_primary_key("keyword_id");
__PACKAGE__->add_unique_constraint("category_keyword_pkey", ["keyword_id"]);
__PACKAGE__->add_unique_constraint(
  "category_keyword_keyword_key",
  ["keyword", "keyword_type", "category_id"],
);
__PACKAGE__->belongs_to(
  "category_id",
  "BST::Schema::Category",
  { category_id => "category_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-11-04 02:22:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:4vuHM/ILeD1OKMdfFIgZBg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
