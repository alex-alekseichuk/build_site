package BSA::Controller::Error;

use strict;
use warnings;
use parent 'BSA::Controller';
use Data::Dumper;
use BST qw(error);


=head1 NAME

BSA::Controller::Error - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub error404 : Local Path('/error/404') {
    my ( $self, $c ) = @_;
    $c->res->status(404);
    $c->stash->{template} = "error/404.tt";
    $c->detach($c->view('TT::Default'));
}

sub error403 : Local Path('/error/403') {
    my ( $self, $c ) = @_;
    $c->res->status(403);
    $c->stash->{template} = "error/403.tt";
    $c->detach($c->view('TT::Default'));
}


=head1 AUTHOR

,,,

=cut

1;
