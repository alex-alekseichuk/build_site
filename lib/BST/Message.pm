package BST::Message;


use strict;
use warnings;

use Params::Validate qw(:all);
use IO::File;
use Time::localtime; # ivan: i suspect this module is not needed; alex: I use it for message_ext_id generation;
use MIME::Lite;

use BST::Tools qw(date_now);
use POSIX qw(ceil);

use BST qw(schema);
use BST::Contact;
use BST::Email;

use Data::Dumper;
use Digest::MD5 qw(md5_base64);

use base qw(BST::Core BST::Schema::Message);
use Carp::Assert;

use BST::Fax::Interfax;
our $fax_gate = 'BST::Fax::Interfax';


__PACKAGE__->table('message');

=head1 DESCRIPTION
    Message
=cut

# subject and body are utf8 strings
__PACKAGE__->load_components(qw/UTF8Columns/);
__PACKAGE__->utf8_columns(qw/subject body/);



# each message belongs to specified user
__PACKAGE__->belongs_to(
  "sender",
  "BST::User",
  { "user_id" => "sender" },
);

# each message belongs to specified location
# it's primary location of the user
__PACKAGE__->belongs_to(
  "owner",
  "BST::Location",
  { "account_location_id" => "owner" },
);

# each message may have several (0 or more) recipients (to_contact's)
__PACKAGE__->has_many(
    recipients => "BST::MessageRecipient", {
        "foreign.message_id" => "self.message_id",
    },
);

__PACKAGE__->might_have(
    package => "BST::Package", {
        "foreign.file_id" => "self.package_id",
    },
);

=head1 depricated method

it used just to import existing message bodies from files to database

=cut

sub body_from_file {
    my $self    = shift;

    my ($body, $mp, $bodyfile);

    $mp         = BST::config('sent_messages_path');
    $bodyfile   = join('/', $mp, $self->message_id, $self->body_file_name);
    $bodyfile   = (-e $bodyfile) ?
        $bodyfile :
        join('/', $mp, substr($self->auto_ctime, 0, 4), substr($self->auto_ctime, 5, 2), $self->message_id, $self->body_file_name);

    if (my $f = new IO::File $bodyfile, "r") {
        local $/;
        $body = <$f>;
    }

    return $body;

}

=head1 used internally to create some MessageRecipient under specified Message and save it

=cut

sub _add_recipient {
    my ($self, $type, $contact, $address, $send_type) = @_;

    my $recipient = BST::MessageRecipient->create();

    $recipient->message_id($self->message_id);
    $recipient->type($type);
    $recipient->send_type($send_type);

    if ($contact) {
        $recipient->contact_id($contact->private_person_id);
        if ($type eq "email") {
            $recipient->address(lc($contact->email_address));
        } else {
            $recipient->address(lc($contact->fax_phone));
        }
    } else {
        # do regex checking if this is a fax or email
        my $type = BST::Contact->detect_type($address);
        $recipient->type($type);
        $recipient->address(lc($address));
    }

    return $recipient;
}


=head1 interface to create and add MessageRecipient with default status. it used in regular way

=cut

sub add_recipient {
    my ($self, $type, $contact, $address, $send_type) = @_;
    $send_type ||= "to";

    my $recipient = $self->_add_recipient($type, $contact, $address, $send_type);
    $recipient->save();

    return $recipient;
}



=head1 interface to create and add MessageRecipient with specified status

used in import script only

=cut

sub add_recipient_status {
    my ($self, $type, $contact, $address, $status) = @_;

    my $recipient = $self->_add_recipient($type, $contact, $address);

    $recipient->status($status);

    $recipient->save;

    return $recipient;
}



=head1 class method to create new Message

=cut

sub create_message {
    my ($class, $user, $subject, $body) = @_;

    my $m = BST::Message->create( );

    $m->subject($subject || "");
    $m->body($body || "");
    $m->body_file_name("");
    $m->time_sent(undef);
    $m->package(undef);

    $m->sender($user);
    $m->owner($user->location);

    $m->attached_file_ids("");

    return $m;
}



=head1 send (process) specified Message to all its MessageRecipient's
    returns nothing or new package was cloned from attached just sent package of the message
=cut

sub send {
    my ($self, $user) = @_;
    assert( $user );

    # clone the package
    if ($self->package_id) {
        my $package_clone = $self->package->clone( $user, {scope => BST::Scope::HIDDEN} );
        $self->package($package_clone);
    }

    my ($to, $bcc, $single) = ([], [], []);

    # really send the email?
    if (BST::config("send_message")) {

        # wrap it into transaction
        eval {
            &schema->txn_do(
                sub {
                    foreach my $recipient ($self->recipients) {
                        if ($recipient->type eq 'fax') {
                            push @$single, $recipient;
                            next;
                        }
                        push @{$recipient->is_bcc ? $bcc : $to}, $recipient;
                    }

                    my $white_list = BST::config("send_address_whitelist");
                    if ($white_list) {
                        foreach my $arr ($to, $bcc, $single) {
                            $arr = [ grep {$white_list->{$_->address}} @$arr ];
                        }
                    }

                    $self->_send([$_], $user) for @$single;

                    if (@$to || @$bcc) {
                        $self->_send($to, $user, $bcc);
                    }
                }
            );
        };

        # transaction fails because of collision: the same message sent twice
        return 0 if ($@);

    }

    $self->time_sent( date_now() );
    $self->update_status();
    $self->save;

    return 1;
}



sub _send {
    my $self = shift;
    my $recipients = shift;
    my $user = shift;
    assert( $user );
    my $bcc = shift || [];

    my $headers;
    my $recipient = @$recipients ? $recipients->[0] : undef;
    my $type = $recipient ? $recipient->type : 'email';

    if ($type eq 'email') {
        $headers = {
            From => $self->sender->email_address,
            Subject => $self->subject,
            Type => "multipart/mixed",
        };
        # #731: recipient header value building:
        $headers->{To} = join ', ', map { $_->address } @$recipients;
    } elsif ($type eq 'fax') {
        # Recipient is always defined here because $type is set to 'email'
        # if there are no recipients
        $headers = $fax_gate->headers($recipient);
    } else { die "unknown recipient type\n"; }

    my $return_path = BST::config('mail_return_path');
    $headers->{"Return-Path"} = $return_path if $return_path;
    # #731: recipient header value building:
    $headers->{Bcc} = join ', ', map { $_->address } @$bcc;
    # debug messages:
    if( BST::config('send_message_BCC') ) {
        $headers->{Bcc} ||= '';
        $headers->{Bcc} .= ', '
	    if $headers->{Bcc};
	$headers->{Bcc} .= BST::config('send_message_BCC');
    }

    # create the message object
    my $msg = MIME::Lite->new(%$headers);

    if ($type eq 'fax') {
        my $cover = $recipient->generate_pdf_fax_cover;
        if( $cover and -f $cover and -s _ ) {
                $msg->attach(
                   Type => 'application/octet-stream',
                   Path => $cover,
                   Filename => 'coverpage.pdf',
                   Disposition => 'attachment',
                );
        }
    } else { # attach body
        $msg->attach (
            Type => 'TEXT',
            Data => $self->body,
        );
    }

    # attach: coverpage, toc and files
    if ($self->attach_type eq 'file') {
        # attach TOC/Submittal template
        if ($self->package_id &&
            $self->package->package_toc_type) {
            my $package = $self->package;
            $package->generate_toc_pdf($user);

            if (-s $package->path_toc_pdf) {
                $msg->attach(
                    Type => 'application/pdf',
                    Path => $package->path_toc_pdf,
                    Filename => $package->toc_item_label . ".pdf",
                    Disposition => 'attachment',
                );
            }
        }

        # attach files
        my $attachments;
        if ($type eq 'email') {
            if ( $self->package_id ) {
                $attachments = $self->package->items_local_files();
            }
        } elsif ($type eq 'fax') {
            if ( $self->package_id ) {
                $attachments = $self->package->items_can_faxed();
            }
        }
        if ( $attachments ) {
            foreach my $file ( @$attachments ) {
                ($file->{extention}) = $file->file_path =~ /(\.[^\.]+$)/ if $file->file_path;
                # add the attachment
                $msg->attach(
                    Type => "application/octet-stream",
                    Path => $file->file_path,
                    Filename => $file->title . ($file->{extention} || ""),
                    Disposition => "attachment"
                );
            }
        }
    }

    # this is needed because these variables are sometimes mangled by some TT plugin, i think
    $Data::Dumper::Indent = 1;
    $Data::Dumper::Pad = '';
    $self->logger->log({ message => Dumper($msg), name=>'mail' });

    # note the time for profiling, see #747
    my $start = time;
    my $success = BST::Email->send($msg);
    my $status = $success ? "sent" : "failed-smtp";
    my $finish = time;

    $self->logger->log( {message => "message sending took " . ( $finish - $start ) . ' seconds', name=>'mail'} );

    my $fax_status = $status eq 'sent' ? 'pending' : $status;
    map {
        $_->status($_->type eq 'fax' ? $fax_status : $status);
        $_->save();
    } @$recipients, @$bcc;

    return $status;
}


sub clear_recipients {
    my ($self) = @_;
    $self->recipients->delete;
}


sub is_limit_exceeded {
    my $self = shift;
	return if not $self->package;
    my %types;
    $types{$_->type} = 1 for $self->recipients;
    if (exists($types{'fax'})) {
        return 1 if grep $_ eq 'pages', $self->package->check_message_limits;
    }
    if (exists($types{'email'})) {
        return 1 if grep $_ eq 'size', $self->package->check_message_limits;
    }
    return 0;
}

sub clone {
    my $self = shift;
    my $message = shift || die;
    my $user = shift || die;

    my $clone = $self->create_message( $user, $message->subject, $message->body);
    if ($message->package_id and $message->package) {
        my $p = $message->package->clone( $user, {scope => BST::Scope::HIDDEN} );
        $clone->package($p);
        assert( $message->package ne $clone->package )       if DEBUG;
        assert( $message->package_id ne $clone->package_id ) if DEBUG;
    }
    $clone->attach_type( $message->attach_type );
    $clone->save();
    $clone->add_recipient($_->type, $_->contact_id, $_->address, $_->send_type) for $message->recipients;
    return $clone;
}

sub can_read {
    my $self = shift;
    my $user = shift;
    return 1 if $user->is_bs_admin();
    return $user->primary_location->account_location_id eq $self->owner->account_location_id;
}

sub can_write {
    my $self = shift;
    my $user = shift;
    return $self->can_read($user);
}

=head2

static method of class
returns generated id string based on:
    user_id, current time, PID, some rand
    it try to generate not more than 10 times (actually, it should be ok one time)
=cut

sub new_ext_id {
    my $class = shift;
    my $user = shift;
    my $ext_id;
    my $count = 0;
    do {
        $count ++;
        $ext_id = md5_base64($user->user_id . localtime() . $$ . rand);
        $ext_id =~ s!/!.!g; # avoid slashes in the ext_id
    } until ($count > 10 || BST::Message->is_ext_id_unique($ext_id));
    return $ext_id;
}

sub is_ext_id_unique {
    my $class = shift;
    my $ext_id = shift;
    return 0 == BST::Message->search({message_ext_id => $ext_id})->count;
}

sub is_send_as_file { return shift->attach_type eq 'file'; }
sub is_send_as_url { return shift->attach_type eq 'url'; }

sub update_status {
    my $self = shift;
    my @recipients = $self->recipients;
    if (grep {$_->status =~ /failed/} @recipients) {
        $self->message_status("failed");
    } elsif (grep {$_->status =~ /pending/} @recipients) {
        $self->message_status("pending");
    } else {
        $self->message_status("sent");
    }
    return $self->save();
}



1;
