package BST::MessageRecipient;

use strict;

use Params::Validate qw(:all);
use IO::File;
use MIME::Lite;
use MIME::Base64;
use Carp::Assert;

use BST qw/config/;
use BST::Message;
use BST::PDF;

use Data::Dumper;

use base qw(BST::Core BST::Schema::MessageRecipient);
__PACKAGE__->table('message_recipient');

=head1 DESCRIPTION
    Message Recipient: sending specified message to: contact-fax, contact-email, fax or email
=cut

__PACKAGE__->belongs_to(
  "message_id",
  "BST::Message",
  { "message_id" => "message_id" },
);

# it may have reference to specified contact
__PACKAGE__->belongs_to(
  "contact_id",
  "BST::Contact",
  { "private_person_id" => "contact_id" },
);


# Fax Gate module must be defined!
use BST::Fax::Interfax;
our $fax_gate = 'BST::Fax::Interfax';

sub generate_pdf_fax_cover {
    my $self = shift;
    my $path_to_pdf = BST::config("temp") . '/' . $self->message_id . "_" . $self->id . ".pdf";

    BST::PDF->generate(
        undef,
        $self->generate_fax_cover(), # path to html
        $path_to_pdf, # path to pdf
        undef
    );

    if (-s $path_to_pdf and -r _) { return $path_to_pdf; }
    return undef;
}

sub generate_fax_cover {
    my $self = shift;

    my $path = BST::config("temp") . '/' . $self->message_id . "_" . $self->id . ".html";

    # generate xhtml
    use Template;
    my $template = Template->new(
        INCLUDE_PATH    => [
            BST::config('home') . "/templates/pdf",
            BST::config('home') . "/templates/lib",
        ]
    );
    unlink $path if -e $path;

    $template->process(
        "faxcover.tt",
        {
            recipient => $self,
            settings_path  => BST::config('settings_path'),
            url_css => "file:///" . BST::config('root_static') . "/css/faxcover.css",
            url_bst_logo => "file:///" . BST::config('root_static') . "/images/logos/logo.gif",
        },
        $path
    ) or warn "generating fax cover: ". $template->error;

    return $path;
}


sub is_bcc {
	my $self = shift;
	return $self->send_type eq 'bcc';
}



1;
