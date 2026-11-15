package BST::CategoryAttribute;

use strict;
use warnings;

use BST;
use Data::Dumper;

use base qw/BST::Core BST::Schema::CategoryAttribute/;

__PACKAGE__->table('category_attribute');

__PACKAGE__->belongs_to(
  "attribute_id",
  "BST::Attribute",
  { attribute_id => "attribute_id" },
);
__PACKAGE__->belongs_to(
  "category_id",
  "BST::Category",
  { category_id => "category_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-07-15 02:46:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:0D72wDqTBF7fXVWm4UlkJw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
