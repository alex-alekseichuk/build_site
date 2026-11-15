package BSA::Controller::Messages;

use strict;
use warnings;

use Carp qw(croak);
use Data::Dumper;

use Email::Valid;
use DateTime;

use BST qw(error);

use BST::User;
use BST::Message;
use BST::MessageRecipient;
use BST::Contact;
use BST::PackageToc;
use POSIX qw(ceil);
use BST::ContactCompany;

use base 'BSA::Controller';

use constant AUTOADD_FAX_NUMBERS => 0;


=head1 NAME

BSA::Controller::Messages - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index 

=cut

sub auto : Private {
    my ( $self, $c ) = @_;
    $c->stash->{limits} = {
        page => BST::config('fax_pagecount_limit'),
        size => BST::config('email_size_limit')
    };
}


sub index : Private {
    my ( $self, $c ) = @_;
#    $c->response->redirect($c->uri_for('list'));
}

sub list : Local Form {
    my ( $self, $c ) = @_;

    my $user = $c->user;

    # get this page parameters
    my $from = $c->req->param('from') || $c->session->{sent_messages_filter}->{from} || 'me';
    my $status = $c->req->param('status') || $c->session->{sent_messages_filter}->{status} || 'all';
    my $date = $c->req->param('date') || $c->session->{sent_messages_filter}->{date} || 'week';

    return $c->deny() if $from eq 'all' && !$c->user->is_bs_admin();

    my $order_by = $c->req->param('order') || 'time_sent desc';
    my $contact_id = $c->req->param('contact_id');
    my $company_id = $c->req->param('company_id');

    my $filter = {from => $from, status => $status, date => $date};
    $filter->{contact_id} = $contact_id if $contact_id;
    $filter->{company_id} = $company_id if $company_id;

    my $query = {};
    if ($from eq 'me') {
        $query->{sender} = $user->id;
    } elsif ($from eq 'location') {
        $query->{owner} = $user->location->account_location_id;
    }

    my $date_filter = undef;
    if ($date eq 'week') {
        $date_filter = { '>', DateTime->now()->subtract( days => 7 ) };
    } elsif ($date eq 'month') {
        $date_filter = { '>', DateTime->now()->subtract( months => 1 ) };
    }

    if ($status eq 'failed') {
        $query->{message_status} = 'failed';
        $query->{time_sent} = $date_filter if $date_filter;
        $order_by = 'time_sent desc' unless $c->req->param('order');
    } elsif ($status eq 'sent') {
        $query->{message_status} = { '!=' => 'not sent' };
        $query->{time_sent} = $date_filter if $date_filter;
        $order_by = 'time_sent desc' unless $c->req->param('order');
    } elsif ($status eq 'drafts') {
        $query->{message_status} = 'not sent';
        $query->{auto_ctime} = $date_filter if $date_filter;
        $order_by = 'auto_ctime desc' unless $c->req->param('order');
    } elsif ($status eq 'all') {
        if ($date_filter) {
            $query->{'-or'} = [
                'time_sent' => $date_filter,
                'auto_ctime' => $date_filter
            ];
        }
        $order_by = 'auto_ctime desc' unless $c->req->param('order');
    }

    if ($contact_id) {
        $query->{contact_id} = $filter->{contact_id} = $contact_id;
        $c->stash->{contact} = BST::Contact->load( $contact_id );
    }

    $query->{'recipients.contact_id'} = $contact_id if $contact_id;

    if ($company_id) {
        my $contacts = BST::Contact->search({addressbook_company_id => $company_id});
        my @contact_ids = map $_->private_person_id, $contacts->all;
        $query->{'recipients.contact_id'} = [ @contact_ids ];
        my $company = BST::ContactCompany->load({ addressbook_company_id => $company_id });
        return unless $c->must_read($company);
        $c->stash->{company} = $company;
    }

    # get the messages as rows for the grid
    $c->stash->{messages} = BST::Message->search($query, {
        order_by => ($order_by =~ /to (a|de)sc/) ? '' : $order_by,
        prefetch => qw/recipients owner sender/,
    });
    $c->session->{sent_messages_filter} = { from => $from, status => $status, date => $date };
    $c->stash->{filter} = $filter;
    $c->stash->{order}  = $order_by;
}



sub item : Local {
    my ( $self, $c ) = @_;

    my $user = $c->user;

    # get message id as http parameter (we actually use "id" param)
    my $id = $c->req->params->{id} || $c->req->params->{message_id};
    return $c->response->redirect($c->uri_for('list')) unless $id;

    # check that there is a message of this user
    my $message = $c->get_object_or_404('BST::Message', { message_id => $id } );
    return unless $message && $c->must_read($message);

    $message->message_status_ack('ack');
    $message->save();
    $c->stash->{package} = $message->package;

    $c->stash->{message} = $message;
    $c->check_undelivered_messages();
}


=head1 JSON method to provide list of posibble contats for autocomplete

=cut

sub contacts : Local {
    my($self, $c) = @_;
    my $query = $c->req->param('q');
    my $user = $c->user;
    if ($query && $user) {
        
        # get all contact records of current user by the query
        my @cons = $user->contact_person_search($query);
        
        # compose output list of contacts
        my @json = ();
        foreach my $con (@cons) {
            if ($con->email_address) {
                my $c_email = {
                    id=>$con->private_person_id,
                    name => $con->name,
                    type => "email",
                    address => $con->email_address,
                    company_name => "",
                };
                if ($con->addressbook_company_id) {
                    $c_email->{company_name} = $con->addressbook_company_id->company_fullname;
                    $c_email->{company_id} = $con->addressbook_company_id->addressbook_company_id;
                }
                push @json, $c_email
            }
            if ($con->fax_phone) {
                my $c_fax = {
                    id=>$con->private_person_id,
                    name => $con->name ,
                    type => "fax",
                    address => $con->fax_phone,
                    company_name => "",
                };
                if ($con->addressbook_company_id) {
                    $c_fax->{company_name} = $con->addressbook_company_id->company_fullname;
                    $c_fax->{company_id} = $con->addressbook_company_id->addressbook_company_id;
                }
                push @json, $c_fax
            }
        }

        $c->stash->{"Result"} = \@json;
    } else {
        $c->stash->{"Result"} = [];
    }    
    $c->forward( $c->view('JSON') );
}


=head2

generate message body footer for attach_as_url message by template from settings

=cut

sub body_footer {
    my ($self, $c, $message_ext_id) = @_;
    my $template = $c->user->settings->list->{post_to_url_text}
                   || "\n-----\n\nOpen this to see the attachments:\n\n%s\n";
    return sprintf $template, $c->req->base . "ext/message/" . $message_ext_id;
}

=head2

send, save or discard (remove) the message

=cut

sub send: Local {
    my ($self, $c) = @_;

    return $self->_discard($c) if ($c->req->param('discard')); # discard (delete) this message
    return $c->response->redirect($c->uri_for("/messages/")) if $c->req->method eq "GET";

    # load parameters
    my $attach_type = $c->req->param('attach');
    my $subject = $c->req->param('subject') || "";
    my $body = $c->req->param('body') || "";
    my $saving = $c->req->param('save');    # need just to save (not send) the message

    # user we are going to send message from
    my $sender;
    if ( $c->req->param('sender') && $c->req->param('sender') ne $c->user->user_id ) {
        $sender = BST::User->load( { user_id => $c->req->param('sender') } ) 
    }
    $sender ||= $c->user;

    return $c->deny()
        unless $c->user->primary_location eq $sender->primary_location;

    # get To address from HTTP
    my @addresses = split(/,\s*/, $c->request->params->{to_addresses} || "");
    my @bcc = split(/,\s*/, $c->request->params->{bcc_addresses} || "");
    push @addresses, @bcc;
    my %send_type = map {; $_ => 'bcc'} @bcc;

    # prepare message object
    my $message;
    if ($c->request->params->{message_id}) {   # load existing message by id from params
        $message = BST::Message->load({'id' => $c->request->params->{message_id}});
    } elsif (defined $c->user->current_message_id) { # restore current users message
        $message = $c->user->current_message_id;
    }
    if (defined $message) { # init already saved message by new parameters
        $message->sender($sender);
        $message->subject($subject);
        $message->body($body);
    } else {    # create new message with new parameters
        $message = BST::Message->create_message($sender, $subject, $body);
    }

    # correct message_ext_id; it used for attach as url
    unless ($message->message_ext_id)
    {
        my $param_message_ext_id = $c->req->param('message_ext_id');
        if ($param_message_ext_id and BST::Message->is_ext_id_unique($param_message_ext_id)) {
            $message->message_ext_id($param_message_ext_id);
        } else {
            $message->message_ext_id(BST::Message->new_ext_id($c->user));
        }
    }

    # save the message anyway
    # so we have actual message_id
    $message->attach_type($attach_type);
    $message->save();

    # TODO: comment this
    if (defined $c->user->current_message_id) {
        $message->clear_recipients();
    }

    $message->clear_recipients();
	# add recipients to the message
    foreach my $pair (@addresses) {
        my ($t, $addr) = split(':', $pair);
        my $type;
        my $obj;

        $type = 'email' if ($t eq 'e');
        $type = 'fax' if ($t eq 'f');

        # already existing contact: email or fax
        if ($t eq 'e' or $t eq 'f') {
            # load contact by id
            $obj = $c->user->find_or_create_person({ 
                    'private_person_id' => $addr
                }, 
                0
            );
            # get address (email or fax) and set type
            if ($obj) {
                if ($t eq 'e') {
                    $type = 'email';
                    $addr = $obj->email_address;
                } else {
                    $type = 'fax';
                    $addr = $obj->fax_phone;
                }
            }
            $type = undef unless ($obj);
        }

        # raw addrees (without contact record): fax or email
        if ($t eq 'p') {
            # filter/correct raw address
            my $valid = 0;
            if ($addr =~ /@/) {
                $valid = Email::Valid->address($addr) ? 1 : 0;
            } else {
                my $addr2 = $addr;                          # corrected address
                $addr2 =~ s/[+()\-\s]//g;                   # remove all spec. chars
                $addr2 = '+' . $addr2 if $addr =~ /^\+/;
                $valid = $addr2 =~ m/^\+?[\d]{9,}$/ ? 1 : 0;   # check for correct fax number format
            }

            $addr =~ s/^\s*(.*?)\s*$/$1/;

            # determine the type and find/create contact record
            if ($valid) {
                my $field = BST::Contact->address_field($addr);
                $type = BST::Contact->detect_type($addr);

                if ($type eq 'fax') {
                    # 1. sending a fax to an anonymous fax number SHOULD NOT 
                    # associate that message with an existing contact with 
                    # the same number, IF there are SEVERAL (more than 1) 
                    # contacts with that fax number in the user's address book.

                    # 2. for the new anonymous fax numbers we SHOULD create 
                    # a contact record in the address book. 

                    my @contacts = $c->user->_find_person({ $field => $addr });

                    if (@contacts == 1) {
                        $obj = shift @contacts;
                    } elsif (@contacts == 0) {
                        $obj = $c->user->create_new_contact_person({ 
                            $field => $addr, 
                            given_name => $addr
                        });
                    } else {
                        $obj = undef;
                    }
                } else {
                    $type  = BST::Contact->detect_type($addr);
                    $obj = $c->user->find_or_create_person({ $field => $addr }, 1);
                }
            }
        }

        next unless $type;
        $message->add_recipient($type, $obj, $addr, $send_type{$pair});
    }

    # check: the number of added recipients should be the same as actual number of recipients added to the message object
    unless (scalar $message->recipients == scalar @addresses) {
        &error->wrong_recipient;
    }

    # if there is incorrect recipient
    # then clear the list of recipients and open the message in compose mode
    if (&error->status) {
        # $message->clear_recipients();
        # $c->request->params->{wrong_recipient} = 1;

        # save this message as current one
        #$c->user->current_message_id($message);
        #$c->user->save();

        $self->_compose($c, $message);
        return;
    }

    if ($attach_type eq 'file' or $attach_type eq 'url') {
        if ($c->req->param('package_id')) {
            my $package = BST::Package->load($c->req->param('package_id'));
            $package = undef unless $package && $package->can_read($c->user);
            $message->package($package);
            $message->save();
        } else {
            $message->package($c->current_package->clone());
        }
    }

    if ($attach_type eq 'file' && !$saving) {
        if ($message->is_limit_exceeded()) {
            $c->request->params->{msg} = "Size limit exceeded";

            # save this message as current one
            #$c->user->current_message_id($message);
            #$c->user->save();

            $self->_compose($c, $message);
            return;
        }
    }

    if ($attach_type eq 'url') {
        return unless $message->package;
        unless ($saving || !@addresses) {
            $body .= "\n\n";
            $body .= $self->body_footer($c, $message->message_ext_id);
            $message->body($body);
            $message->save();
        }
    }

    my $params;
    if ($saving || !@addresses) {
        $message->message_status('not sent');
        $message->save();
        $c->user->current_message_id($message);
        $c->user->save();

        $params->{status} = 'not sent';
        $params->{order} = 'auto_ctime DESC';
    } else {
        $message->send($c->user);
        if ($message->message_status eq 'failed') {
             $params->{message_id} = $message->message_id;
             $params->{"smtp_failed"} = 1;
             $c->user->current_message_id($message);
             $c->user->save();
             return $c->response->redirect($c->uri_for("/messages/package", $params)) if $params->{package_id};
             return $c->response->redirect($c->uri_for("/messages/edit", $params));
        }
        if (! &error->status) {
            $c->user->current_message_id(undef);
            $c->user->save();
        }
        $params->{status} = 'success'; 
        $params->{order} = 'time_sent desc';
    }

    if ($saving) {
        $params->{message_id} = $message->message_id;
        $params->{saved} = 1;
        $c->user->save();
        return $c->response->redirect($c->uri_for("/messages/package", $params)) if $params->{package_id};
        return $c->response->redirect($c->uri_for("/messages/edit", $params));
    } elsif (!@addresses) {
        return $c->response->redirect($c->uri_for("/messages/list", {status => 'drafts', from => 'me', date => 'week'}));
    } else {
        return $c->response->redirect($c->uri_for("/messages", {sent => 1, sent_message_id => $message->message_id}));
    }
}


=head2

discard a message

=cut

sub _discard : Local {
    my ($self, $c) = @_;
    my $message;
    my $package_id = $c->req->params->{package_id};

    if ($c->req->params->{message_id}) {   # load existing message by id from params
        $message = BST::Message->load( $c->req->params->{message_id} );

    } elsif ($package_id) {
        my $query;
        $query->{'package_id'} = $package_id;
        $query->{'sender'} =  $c->user->user_id;
        $query->{'message_status'} = 'not sent';
        my @messages = BST::Message->search($query, {order_by => 'auto_ctime DESC'})->all;
        $message = $messages[0] if @messages;
    }
      
    # XXX what if that was his current message? 
    if( 0 && defined $c->user->current_message_id) {
        $message = $c->user->current_message_id;
        $c->user->current_message_id(undef);
        $c->user->save();
    }

    
    if( $message ) {
        return unless $c->must_write($message);
        $message->delete;
    }

    $c->response->redirect($c->uri_for('list', { msg => "discarded" }));
}


=item * forward

While this is called "forward" the actual operation is labelled "resend" 
for the user. User creates a copy of this existing message to send it 
as a new one, possibly to another recipient, possibly changing some 
of it's details.

The old message attachments are stored as a package and we load that 
package and make it current.

=cut

sub forward : Local {
    my ( $self, $c ) = @_;

    my $message_id = $c->req->params->{message_id};
    my $message = $c->get_object_or_404('BST::Message', { message_id => $message_id });
    return unless $message && $c->must_read($message);

    if ( $c->req->param('saved') ) {
        # see the "send" action above, it redirects here if user clicked on [save] of a message
        # ?
    } else {
        # otherwise this is an old message being re-used
        # we take it's clone. That also creates a new version of the package, if any
        $message = BST::Message->clone($message, $c->user);

        if ($message->package_id) {
            my $pkg = $message->package;
            
            if ($c->req->param('upgrade')) {
                # the old package may need to be upgraded. Otherwise we leave it as it is..
                $pkg = $pkg->upgrade();
                $pkg->save();
                $message->package($pkg); # upgraded package has a new package id
            }

        } else {
            # all radio should be setup in compose only
            #$c->request->params->{attach} = undef; # we need the checkbox to be unchecked in this case. XXX
        }
    }

    $c->user->current_message_id($message);
    $c->user->save();
    $c->request->params->{message_id} = $message->message_id; # ?

    $c->stash->{package} = $c->current_package;

    $self->_compose($c, $message);
}


sub current : Local {
    my ( $self, $c ) = @_;
    my $message;
    if (defined $c->user->current_message_id) {
        $c->stash->{current_message} = 1;
        $self->_compose($c, $c->user->current_message_id);
    } else {
        $self->blank( $c );
    }
}




sub blank : Local {
    my ( $self, $c ) = @_;

    # drop (not delete) current message
    $c->user->current_message_id(undef);
    $c->user->save();

    # it's possile to provide GET params: contact_id and optional type=email|fax
    # to add specified To: to new message
    if ($c->req->param('contact_id')) {
        my $oCont = BST::Contact->load($c->req->param('contact_id'));
        my $type = $c->req->param('type');

        my $address;
        if ($type eq 'email') {
            $address = $oCont->email_address;
        } elsif ($type eq 'fax') {
            $address = $oCont->fax_phone;
        } else {
            $address = $oCont->email_address || $oCont->fax_phone;
        }

        $c->stash->{force_recipients} = [ {
            contact_id => $oCont,
            address    => $address
        } ];
    } elsif ($c->session->{contacts}) {
        $c->stash->{force_recipients} = $c->extract_contacts_cart;
    }

    # no opens existing message. blank only.
    #my $message_id = $c->request->params->{message_id};
    #my $message = BST::Message->load({message_id => $message_id});
    #$message = undef unless $message && $message->can_read($c->user);

    #$c->stash->{package} = $c->current_package;

    $self->_compose($c, undef);
}


=head2

internal method for preparing message compose form

=cut

sub _compose {
    my ( $self, $c, $message, $package) = @_;
    $c->stash->{senders} = BST::User->search( { primary_location => $c->user->primary_location } );
    $c->stash->{message} = $message;
    $c->stash->{quirk} = time;
    $c->stash->{nosidebar} = 1;

    # if there is no force_recipients to push right in the To: without confirmattion
    # then add the number of contacts in the contacts-cart to raise confirm popup for adding them
    if ((! exists $c->stash->{force_recipients}) && $c->session->{contacts}) {
        $c->stash->{n_contacts_cart} = scalar (my @a = split ',', $c->session->{contacts});
    }

    # ?
    &error->size_limit_exceeded if $c->req->param('msg') &&  $c->req->param('msg') eq "Size limit exceeded";

    # there is incorrect recipient in send() method
    &error->wrong_recipient if $c->req->param('wrong_recipient');

    # there is something wrong with smtp server
    &error->smtp_failed if $c->req->param('smtp_failed');

    # ?
    $c->stash->{template} = "messages/compose.tt";

    my $enable_no_attach = 1;   # flag to hide/show no_attach radio button
    my $already_sent = 1;       # flag to see if the message is already sent

    # if no specified package but there is some message
    # then try to use that package attached to the message
    if ((! $package) and $message)
    {
        $package = $message->package; # use package already attached to message

        if ($package)
        {
            # setup attach type and message_ext_id
            $c->stash->{attach_type} = $message->attach_type;
            if ($message->message_ext_id) {
                $c->stash->{message_ext_id} = $message->message_ext_id;
            } else {
                $message->message_ext_id(BST::Message->new_ext_id($c->user));
                $message->save();
                $c->stash->{message_ext_id} = $message->message_ext_id;
            }
            $c->stash->{body_footer} = $self->body_footer($c, $message->message_ext_id);

            $enable_no_attach = 0 if ($message->attach_type eq 'file' or $message->attach_type eq 'url');
        }

    }

    # if no specified package and no package of the message
    # then use current_package
    if (! $package)
    {
        $package = $c->current_package;
    }

    # if there is some package but no attach type yet
    if ($package and (! $c->stash->{attach_type}))
    {
        $c->stash->{attach_type} = 'file';
        $c->stash->{message_ext_id} = BST::Message->new_ext_id($c->user);
        $c->stash->{body_footer} = $self->body_footer($c, $c->stash->{message_ext_id});
    }

    # so, we have package to use on compose form
    if ($package)
    {
        $c->stash->{package} = $package; # put package to the page
        $c->stash->{current_package_flag} = 'current' if ($package eq $c->current_package);
        
=c
        # calculate number of items, their sizes and limits flags
        my @limits = $package->check_message_limits;
        my $is_size_limit_exceeded = grep $_ eq 'size', @limits;
        my $is_pages_limit_exceeded = grep $_ eq 'pages', @limits;
        my $size = ceil($package->total_size_bytes / 1024);
        my $tocsize = ceil($package->toc_size_bytes / 1024);
        my $pages = $package->total_pages;
        my $tocpages = $package->toc_pages;
        my $count = scalar $package->items;

=cut
        my ($is_size_limit_exceeded, $is_pages_limit_exceeded, $pages, $size, $count);
        $pages = $size = $count = 0;
        for my $item ($package->items) {
            if ($item->is_file) {
                $pages += $item->file->page_count || 0 ;
                $size += $item->file->file_size || 0;
            }
            elsif ($item->is_document) {
                $pages += $item->document->derived_pagecount || 0;
                $size += $item->document->derived_filesize || 0;
            }
            $count++;
        }
        
        # bring it to kilobytes
        $size = ceil($size / 1024);

        # calculate size of toc
        my ($tocsize, $tocpages);
        if ($package->package_toc_type) {
            if ($package->generate_toc_pdf($c->user)) {
                $tocsize = ceil((stat $package->path_toc_pdf)[7] / 1024);
                $tocpages = $package->toc_page_count;
            }
        }

        # check size limits
        $is_pages_limit_exceeded = 1 if BST::config('fax_pagecount_limit') && ($pages + ($tocpages || 0) > BST::config('fax_pagecount_limit'));
        $is_size_limit_exceeded = 1 if BST::config('email_size_limit') && ($size + ($tocsize || 0) > BST::config('email_size_limit'));


        # flag to show/hide send_as_url attachment option
        if (defined $c->user->settings->list->{disable_send_package_url}) {
            $c->stash->{disable_send_package_url} = $c->user->settings->list->{disable_send_package_url} eq 'y' ? 1 : 0;
        }

        # flag to show/hide send_as_url attachment option
        $c->stash->{enable_no_attach} = $enable_no_attach;

        # params of attached package
        $c->stash->{attached} = {
            tocsize => $tocsize,
            tocpages => $tocpages,
            page => $pages,
            size => $size,
            is_pages_limit_exceeded => $is_pages_limit_exceeded,
            is_size_limit_exceeded => $is_size_limit_exceeded,
            count => $count,
            sizelimit => BST::config('email_size_limit'),
            pagelimit => BST::config('fax_pagecount_limit')
        };

    }
}

sub package : Local {
    my ( $self, $c ) = @_;
    my $package_id = $c->req->params->{package_id};

    my $query;
    $query->{'package_id'} = $package_id;
    $query->{'sender'} =  $c->user->user_id;
    $query->{'message_status'} = 'not sent';

    my @messages = BST::Message->search($query, {order_by => 'auto_ctime DESC'})->all;
    my $message = $messages[0] if @messages;
    $message = undef unless $message && $message->can_read($c->user);

    $c->stash->{send_package} = 1;

    my $package = BST::Package->load({id => $package_id});
    return $c->error404 unless $package;

    if ($message) {
        $c->user->current_message_id($message);
        $c->user->save();
        $c->request->params->{message_id} = $message->message_id;
    }

    if ($c->session->{contacts}) {
        $c->stash->{force_recipients} = $c->extract_contacts_cart;
    }

    $self->_compose($c, $message, $package);
}


sub edit : Local {
    my ( $self, $c ) = @_;

    my $message_id = $c->req->params->{message_id} || return $c->error404;
    my $message = $c->get_object_or_404('BST::Message', {message_id => $message_id});

    return unless $c->must_read($message);
    return unless $c->must_write($message);

    return $c->deny() if $message->time_sent;
    
    # maybe it is already his current message?
    $c->user->current_message_id($message);
    $c->user->save();

    $self->_compose($c, $message);
}


=head1 AUTHOR

A clever guy

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
