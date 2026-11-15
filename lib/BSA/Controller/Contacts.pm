package BSA::Controller::Contacts;

use strict;
use warnings;

use base 'BSA::Controller';

use BST::Contact;
use Data::Dumper;

=head1 NAME

BSA::Controller::Contacts - Catalyst Controller

=head1 DESCRIPTION

=head1 METHODS

=cut

sub index : Local {
    my ( $self, $c ) = @_;
    return $c->response->redirect('/messages/');
}


1;
