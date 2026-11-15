package BST::Email;

use strict;
use warnings;

use BST;
use Template;
use MIME::Lite;

use Data::Dumper;

our $ERROR;

=head1 DESCRIPTION
    contains methods to create and send email messages
=cut


sub logger { BST::Logger->instance(@_) }



=head1 create_message($template, $stash)

method to generate a message and send it.
returns 1 for success or 0 for fail.
errors are logged automatically

=cut
sub create_message {
    my $self = shift;
    my ($template_name, $stash) = @_;
    my $filename = $template_name. '.tmpl';

    my $template = new Template(
        INCLUDE_PATH => BST::config()->{home} . "/templates/email",
    ) or return $self->error("can't create Template object: $Template::ERROR");

    my $text;
    $template->process($filename, $stash, \$text) or return $self->error($template->error());

    return $self->send($text);
}



=head1 send

usage:
  my $msg = new MIME::Lite;
  ...
  BST::Email->send($msg);

or

  BST::Email->send("To: email@example.com\nSubject: Test\n\nThis is a test message!");

or

  BST::Email->send("This is a test message", to => 'email@example.com', subject => 'Test!')

returns 1 for success or 0 for fail.
errors are logged automatically

=cut
sub send {
    my $self = shift;
    my $msg = shift;

    unless (ref $msg) {
        my ($head_fields, $body);
        if (@_) {
            if (ref $_[0] eq 'HASH') {
                $head_fields = shift;
            } else {
                $head_fields =  {};
                while (@_) {
                    my $k = shift;
                    $head_fields->{$k} = shift;
                }
            }
            $body = $msg;
        } else {
            return $self->error("Cannot send empty message!") unless $msg && length $msg;
            return $self->error("Cannot send message without headers", $msg) unless $msg =~ m/\n{2}/;
            my $head;
            ($head, $body) = split(/\n{2}/, $msg, 2);
            $head_fields = { map { split(/\s*:\s*/, $_, 2) } split(/\n/, $head) };
        }

        $msg = MIME::Lite->new(
            %$head_fields,
            Data => $body
        );
    }

    eval {
        if ( BST::config("smtp_host") ) {
            $msg->send(
                'smtp',
                BST::config("smtp_host"),
                Port => BST::config("smtp_port"),
                Timeout => 60,
                Debug => 0
            );
        } else {
            $msg->send('sendmail', "/usr/lib/sendmail -t -oi -oem");
        }
    };

    return $self->error($@, $msg) if $@;
    return 1;
}



=head1 error()

set/get an error

=cut
sub error {
    my $self = shift;
    return $ERROR unless @_;

    $ERROR = shift;
    my $context = shift;

    $ERROR .= "\n" . Dumper($context) if $context;
    $ERROR .= $self->logger->error_context(__PACKAGE__);

    $self->logger->log({ name => 'bst', level => 'error', message => $ERROR });
    return 0;
}

1;
