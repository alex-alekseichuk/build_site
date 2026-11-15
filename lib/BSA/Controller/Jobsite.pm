package BSA::Controller::Jobsite;

use strict;
use warnings;
use base 'BSA::Controller';
use Data::Dumper;
use BST;
use BST::MsdsGroup;
use BST::MsdsDocument;

=head1 NAME

BSA::Controller::Jobsite - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index 

=cut

sub index : Path('/jobsite/') {
    my ( $self, $c ) = @_;
    $c->stash->{template} = 'jobsite.tt';

    $c->stash->{groups} = [BST::MsdsGroup->search({}, {order_by => 'position'})];
}

=head1 AUTHOR

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
