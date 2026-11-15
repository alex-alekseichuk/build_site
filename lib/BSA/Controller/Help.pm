package BSA::Controller::Help;

use strict;
use warnings;
use parent 'Catalyst::Controller';

=head1 NAME

BSA::Controller::Help - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index 

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
}


sub guide : Local :Args(0) {
    my ( $self, $c ) = @_;

}

sub faq : Local :Args(0) {
    my ( $self, $c ) = @_;

}
sub setup : Local :Args(0) {
    my ( $self, $c ) = @_;

}

sub printing : Local :Args(0) {
    my ( $self, $c ) = @_;

}

sub greenfeatures : Path('/help/green-features') {
    my ( $self, $c ) = @_;
}

sub demo : Local {
    my ($self, $c) = @_;
    $c->forward( $c->view('TT::WithoutWrapper') );

}
=head1 AUTHOR

Nikolai Liohenki, kalyansky@gmail.com

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
