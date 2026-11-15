package BST::LeedCredit;

use strict;
use warnings;
use BST;
use BST::Product;
use Data::Dumper;

use base qw/BST::Core BST::Schema::LeedCredit/;

__PACKAGE__->table('leed_credit');

__PACKAGE__->belongs_to(
  "leed_area_id",
  "BST::LeedArea",
  { leed_area_id => "leed_area_id" },
);

__PACKAGE__->has_many(
  "leed_credit_attributes",
  "BST::LeedCreditAttribute",
  { "foreign.leed_credit_id" => "self.leed_credit_id" },
);

__PACKAGE__->many_to_many(
  "_attributes" => "leed_credit_attributes",
  "attribute_id",
);

sub shortname {
    my $self = shift;
    my $shortname = $self->leed_credit_id;
    $shortname =~ s/ap/p/g;
    return $shortname;
}

sub products {
    my $self = shift;
    my $products = BST::Product->search_by_leed_credit({'product_leed_credit.leed_credit_id' => $self->get_column('leed_credit_id')});
    return $products;
}

sub has_products {
    my $self = shift;
    my $products = BST::Product->search_by_leed_credit({'product_leed_credit.leed_credit_id' => $self->get_column('leed_credit_id')}, {select => 'me.product_id'});
    return $products->count;
}

sub attributes {
    my $self = shift;

    my @attributes = $self->_attributes;

    @attributes = sort {$a->result_display_order cmp $b->result_display_order} @attributes;

    my @results = ();
    my @combined = ();
    for my $attr (@attributes) {
        if ($attr->result_display_type eq "alone") {
            if (@combined) {
                push @results, [ @combined ];
                @combined = ();
            }
            push @results, $attr;
        } elsif ($attr->result_display_type eq "combined") {
            push @combined, $attr;
        }
    }

    if (@combined) {
        push @results, [ @combined ];
    }

    return \@results;
}

1;
