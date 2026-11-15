package BSA::Controller::Categories;

use strict;
use warnings;
use base 'BSA::Controller';

use BST::Category;

=head1 NAME

BSA::Controller::Categories - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index 

=cut

sub index : Private {
    my ( $self, $c ) = @_;

    $c->response->redirect($c->uri_for('list'));
}

=head2 list

=cut

sub list : Local {
    my ( $self, $c ) = @_;
    
    my ($query, $manufacturer, $product);

    $manufacturer = $c->req->params->{'manufacturer'};
    $product      = $c->req->params->{'product'};
    
    if ($manufacturer) {
        $query->{'c.company_id'}    = $manufacturer;
        $c->stash->{manufacturer}   = BST::Company->load({ company_id => $manufacturer });
    }
    
    if ($product) {
        $query->{'p.product_id'}    = $product;
        $c->stash->{product}        = BST::Product->load({ product_id => $product });
    }

    $c->stash->{hide_suppressed} = BST::Category->hide_suppressed;

    return if $c->check_html_cache;

    $c->stash->{list} = [ BST::Category->list($query) ];
}

=head2 view

=cut

sub view : Local {
    my ( $self, $c ) = @_;

    my $id = $c->req->params->{id};
    my $obj = $c->get_object_or_404('Category', id => $id);
    $c->stash->{obj} = $obj;

    $c->stash->{hide_suppressed} = BST::Category->hide_suppressed;
}

=head2 edit

=cut

sub edit : Local Form {
    my ( $self, $c ) = @_;
}

=head1 AUTHOR

Yuri Pac <yu.pats@gmail.com>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
