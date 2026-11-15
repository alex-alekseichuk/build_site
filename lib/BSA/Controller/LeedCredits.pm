package BSA::Controller::LeedCredits;

use strict;
use warnings;
use parent 'BSA::Controller';
use Data::Dumper;
use BST qw(error);
use BST::Config;
use POSIX qw(ceil);
use BST::LeedArea;
use BST::LeedCredit;

=head1 NAME

BSA::Controller::LeedCredits - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index 

=cut
sub index : Path('/leed-credits') {
    my ( $self, $c ) = @_;
    return $c->response->redirect( '/leed-credits/list' );
}


sub list : Path('/leed-credits/list') {
    my ( $self, $c ) = @_;
    $c->{stash}->{areas} = BST::LeedArea->search({}, {order_by => 'me.leed_area_display_order'});
}


sub view : Path('/leed-credits/view') {
    my ( $self, $c ) = @_;

    my $id = $c->req->params->{leed_credit_id};
    my $obj = $c->get_object_or_404('LeedCredit', id => $id);
    $c->stash->{obj} = $obj;
}


=head1 AUTHOR

,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
