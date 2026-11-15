package BST::Attribute;

use strict;
use warnings;

use base qw/BST::Core BST::Schema::Attribute/;


__PACKAGE__->table("attribute");

__PACKAGE__->has_many(
  "category_attributes",
  "BST::CategoryAttribute",
  { "foreign.attribute_id" => "self.attribute_id" },
);
__PACKAGE__->has_many(
  "leed_credit_attributes",
  "BST::LeedCreditAttribute",
  { "foreign.attribute_id" => "self.attribute_id" },
);
__PACKAGE__->has_many(
  "product_attribute_values",
  "BST::ProductAttributeValue",
  { "foreign.attribute_id" => "self.attribute_id" },
);


sub sorttype {

    my $self = shift;

    if ($self->data_type_id =~ /^(angle|distance|float|floatrange|integer|percent)$/) {
        return "number";
    } else {
        return "string";
    }
}

1;
