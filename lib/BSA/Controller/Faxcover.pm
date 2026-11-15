package BSA::Controller::Faxcover;

use strict;
use warnings;
use base 'BSA::Controller';
use Data::Dumper;
use BST;
use BST::User;
use BST::Message;
use BST::Contact;
use BST::MessageRecipient;
use BST::PDF;

=head1 NAME

BSA::Controller::Faxcover - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index 

=cut

sub index : Private  {
    my ( $self, $c ) = @_;
    return $c->deny() unless $c->user->is_bs_admin();
    my $recipient = BST::MessageRecipient->load({ recipient_id => $c->req->param("recipient_id") || "message_recipient_257014" });
    my $path = $recipient->generate_fax_cover();

	my $path_pdf = $path;
	$path_pdf =~ s/\.html/\.pdf/;
    BST::PDF->generate(
        undef,
        $path,
        $path_pdf
    );

	if (-f $path_pdf) {
		open FILE, "<" . $path_pdf;
		my $body = join "", <FILE>;
		close FILE;
		return unless $body;
        $c->response->body($body);
        $c->res->header( 'Content-type' => 'application/pdf' );
        $c->res->header( 'Content-disposition' => 'attachment; filename="' .$path_pdf . '"' );
        $c->forward( $c->view('PDF') );
	}

}

=head1 AUTHOR

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
