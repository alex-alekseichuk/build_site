package BST::ProductRelated;

use strict;
use warnings;

use BST::Company;
use BST::Category;
use BST::Document;
use BST::ProductStandard;

use Data::Dumper;
use Params::Validate qw(:all);

use base qw/BST::Core BST::Schema::ProductRelated/;

__PACKAGE__->table("product_related");

=head1 DESCRIPTION
    Product related record object
=cut

__PACKAGE__->belongs_to(
  "related_product",
  "BST::Product",
  { product_id => "related_product_id" },
);
__PACKAGE__->belongs_to(
  "product",
  "BST::Product",
  { product_id => "product_id" },
);
__PACKAGE__->belongs_to(
  "section_document",
  "BST::Document",
  { document_id => "section_document_id" },
);


=head 2 search - class method

=cut

sub search {
    my ($class, $query, $params) = @_;

    return $class->next::method($query, {
        alias    => 'me',
        order_by => [ 'me.display_order' ],
        %{$params || {}}
    });
}

1;
