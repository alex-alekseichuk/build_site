package BSA::Controller::Contacts::Person;

use strict;
use warnings;
use base 'BSA::Controller';
use Data::Dumper;

=head1 NAME

BSA::Controller::Contacts::Person - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


sub create : Local {
    my ( $self, $c ) = @_;
    $c->stash->{template} = "contacts/person/edit.tt";

    return $c->detach('edit');

}


=head2 just loads sorted list of companies for specified user

=cut

sub _list_user_companies {
    my ( $c ) = @_;

    my @companies = 
        sort {
            uc($a->[1]) cmp uc($b->[1])
        }
        map {
            [ $_->addressbook_company_id, $_->company_fullname ]
        } $c->user->contact_company_search('', 'company_fullname')->all;

    return @companies;
}

=head2 ajax load list of companies of the contact

=cut

sub load_companies : Local {
    my ( $self, $c ) = @_;

    my @companies = _list_user_companies($c);

    my $result = {
        result                  => 'ok'
        ,companies              => \@companies
    };

    $c->stash->{"Result"} = $result;
    $c->forward( $c->view('JSON') );
}


=head2 ajax load contact data

=cut

sub load : Local {
    my ( $self, $c ) = @_;

    my $id = $c->request->params->{id};
    my $contact;

    if ($id) {
        $contact = BST::Contact->load({ private_person_id => $id });
        if (! $c->must_read($contact)) {
            $c->stash->{"Result"} = { 'result' => 'error' };
            $c->forward( $c->view('JSON') );
            return;
        }
    }

    if (! defined($contact)) {
        $c->stash->{"Result"} = { 'result' => 'error' };
        $c->forward( $c->view('JSON') );
        return;
    }

    my @companies = _list_user_companies($c);

    my $result = {
        result                  => 'ok'
        ,id                     => $id
        ,given_name             => $contact->given_name
        ,family_name            => $contact->family_name
        ,work_phone             => $contact->work_phone
        ,fax_phone              => $contact->fax_phone
        ,email_address          => $contact->email_address
        ,addressbook_company_id =>
            $contact->addressbook_company_id 
                ? $contact->addressbook_company_id->addressbook_company_id 
                : ''
        ,companies              => \@companies
    };

    $c->stash->{"Result"} = $result;
    $c->forward( $c->view('JSON') );
}


=head2 ajax save contact data

=cut

sub save : Local {
    my ( $self, $c ) = @_;

    # load new values from http params
    my $given_name      = $c->request->params->{given_name};
    my $family_name     = $c->request->params->{family_name};
    my $work_phone      = $c->request->params->{work_phone};
    my $fax_phone       = $c->request->params->{fax_phone};
    my $email_address   = $c->request->params->{email_address};
    my $company_id      = $c->request->params->{company};
    my $new_company     = $c->request->params->{new_company};
    my $company_name    = '';

    if (! $given_name) {
        $c->stash->{"Result"} = {
            'result' => 'error'
            , 'error' => 'Please, provide First Name'
        };
        $c->forward( $c->view('JSON') );
        return;
    }

    if (! ($email_address or $fax_phone)) {
        $c->stash->{"Result"} = {
            'result' => 'error'
            , 'error' => 'Please, Provide Fax or Email Address'
        };
        $c->forward( $c->view('JSON') );
        return;
    }

    # get id of existing contact to update
    my $id = $c->request->params->{id};
    my $contact;

    # load existing contact
    if ($id) {
        $contact = BST::Contact->load({ private_person_id => $id });
        if (! $c->must_write($contact)) {
            $c->stash->{"Result"} = { 'result' => 'error' };
            $c->forward( $c->view('JSON') );
            return;
        }
    }

    # create new contact if there is not existing one
    if (! $contact) {
        $contact = $c->user->create_new_contact_person({given_name => 'New'});
    }

    # create new company if it needs
    if (not $company_id and $new_company) {
        $company_name = $new_company;
        my $company = $c->user->create_new_contact_company({
            company_fullname => $new_company,
        });
        $company->save();
        $company_id = $company->id;
    } elsif ($company_id) {
        my $company = BST::ContactCompany->load( $company_id );
        if ($company) {
            $company_name = $company->company_fullname;
        }
    }

    # save new values in object
    $contact->set_columns({
        given_name    => $given_name,
        family_name   => $family_name,
        work_phone    => $work_phone,
        fax_phone     => $fax_phone,
        email_address => $email_address,
        addressbook_company_id => $company_id || undef,
    });

    $contact->save;

    $c->stash->{"Result"} = {
        result                  => 'ok'
        ,id                     => $contact->id
        ,name                   => $contact->name
        ,company_id             => $company_id || 0
        ,company_name           => $company_name
        ,email_address          => $contact->email_address
        ,fax_phone              => $contact->fax_phone
    };
    $c->forward( $c->view('JSON') );
}


=head2 edit

=cut

sub edit : Local Form {
    my ( $self, $c ) = @_;
    
    my $new;
    my $form = $self->formbuilder;
    my ($obj, $company, $action);

    if ($form->field('id')) {
        $obj = BST::Contact->load({ private_person_id => $form->field('id') });
        return unless $c->must_read($obj);
    }

    if ($form->submitted) {
        if ($form->validate) {
            if ($obj) {
                return unless $c->must_write($obj);
            } else {
                $obj = $c->user->create_new_contact_person({given_name => 'New'});
                $action = 'new';
            }

            my $company_id = $form->field('addressbook_company_id') || undef;
            if (not $company_id and $form->field('new_company_name')) {
                $company = $c->user->create_new_contact_company({
                    company_fullname => $form->field('new_company_name'),
                });
                $company->save();
                $company_id = $company->id;
            }

            $obj->set_columns({
                given_name    => $form->field('given_name'),
                family_name   => $form->field('family_name'),
                work_phone    => $form->field('work_phone'),
                fax_phone     => $form->field('fax'),
                email_address => $form->field('email'),
                addressbook_company_id => $company_id,
            });

            $obj->save;
            return $c->response->redirect($c->uri_for('/contacts/person/edit', {id => $obj->id, saved => 1, action => $action || 'update'}));
        } else { 
            # return 
        }
    }

    if ($obj) {
        $form->field(name => 'given_name', value => $obj->given_name);
        $form->field(name => 'family_name', value => $obj->family_name );
        $form->field(name => 'work_phone', value => $obj->work_phone);
        $form->field(name => 'fax', value => $obj->fax_phone);
        $form->field(name => 'email', value => $obj->email_address);
        $form->field(name => 'addressbook_company_id', value => $obj->addressbook_company_id->addressbook_company_id) if $obj->addressbook_company_id;
    }
    
    my @companies = map { 
        [ $_->addressbook_company_id => $_->company_fullname ]
    } $c->user->contact_company_search('', 'company_fullname')->all;

    $form->field(
        name => 'addressbook_company_id',
        type => 'select',
        options => \@companies
    );

    $c->stash->{item} = $obj;
}

sub list : Local {
    my ( $self, $c ) = @_;

    my $order = $c->req->param('order') || 'family_name';
    my $comp  = $c->req->param('company') || '';
    my $q     = $c->req->param('q') || '';

    my $params = { 'me.addressbook_company_id' => $comp } if $comp;
    $c->stash->{company} = BST::ContactCompany->load({ addressbook_company_id => $comp }) if $comp;

    if ($order eq 'family_name') {
        my $contacts = $c->user->contact_person_search($q, $params, $order);

        my $noname = [];
        my $cnt = [];        
        if ($contacts) {
            while (my $next = $contacts->next) {
                push @{$next->is_nameless eq 'fax' ? $noname : $cnt}, $next;
            }
        }        
        $noname = [ sort {$a->given_name cmp $b->given_name } @$noname ];

        $c->stash->{contacts} = [@$cnt, @$noname];
    } else {
        my @contacts = $c->user->contact_person_search($q, $params, $order);
        $c->stash->{contacts} = \@contacts;
    }
    
    # provide the list of items in contacts cart
    if ($c->session->{contacts}) {
        my @contacts_cart = split ',', $c->session->{contacts};
        @contacts_cart = map sprintf('{"type":"%s","contact_id":"%s"}', split(':', $_)), @contacts_cart;
        $c->stash->{contacts_cart} = join ',', @contacts_cart;
    }
}

sub merge : Local {
    my ( $self, $c ) = @_;
    my $obj;

    if ($c->req->param('person_id')) {
        $obj = BST::Contact->load({ private_person_id => $c->req->param('person_id') });
        return unless $c->must_write($obj);
    }

    if ($c->req->param('is_submitted') && $c->req->param('merge_with')) {
        my $merge_with_obj = BST::Contact->load({ private_person_id => $c->req->param('merge_with') });
        return unless $c->must_read($merge_with_obj);
        die "Can't merge contact with itself!" if $merge_with_obj->private_person_id eq $obj->private_person_id;

        # there may be contact with fake given_name filled as email or fax_number
        my $name_as_address_type = BST::Contact->detect_type($obj->given_name);
        $obj->given_name($merge_with_obj->given_name)
            if (not $obj->given_name)
                or ($name_as_address_type eq 'email' and $obj->given_name eq $obj->email_address)
                or ($name_as_address_type eq 'fax' and $obj->given_name eq $obj->fax_phone);

        $obj->family_name($merge_with_obj->family_name) unless $obj->family_name;
        $obj->work_phone($merge_with_obj->work_phone) unless $obj->work_phone;
        $obj->fax_phone($merge_with_obj->fax_phone) unless $obj->fax_phone;
        $obj->email_address($merge_with_obj->email_address) unless $obj->email_address;
        $obj->save();

        # Replace recipients
        my @recipients = BST::MessageRecipient->search({ contact_id => $merge_with_obj->private_person_id });
        map {
            $_->contact_id( $obj->private_person_id );
            $_->save();
        } @recipients;
        $merge_with_obj->delete();
        return $c->response->redirect($c->uri_for("/contacts/person/list", { company => $obj->addressbook_company_id }));
    }
    $c->stash->{item} = $obj;
    my @contacts = ();
    if ($obj->addressbook_company_id) {
        @contacts = $c->user->contact_person_search('', { addressbook_company_id => [$obj->addressbook_company_id, undef] }, 'family_name');
     } else {
        @contacts = $c->user->contact_person_search('', {}, 'family_name');
    }

    my @allsorted = ();
    # sort options
    if ($obj->email_address) {
        my @contacts_email_address = grep { $_->get_column('email_address') eq $obj->email_address } @contacts;
        @contacts = grep { $_->get_column('email_address') ne $obj->email_address } @contacts;
        push @allsorted, @contacts_email_address;
    }
    if ($obj->fax_phone) {
        my @contacts_fax_phone = grep { $_->get_column('fax_phone') eq $obj->fax_phone } @contacts;
        @contacts = grep { $_->get_column('fax_phone') ne $obj->fax_phone } @contacts;
        push @allsorted, @contacts_fax_phone;
    }
    if ($obj->family_name && $obj->given_name) {
        my @contacts_name = grep { $_->get_column('family_name') eq $obj->family_name && $_->get_column('given_name') eq $obj->given_name } @contacts;
        @contacts = grep { !($_->get_column('family_name') eq $obj->family_name && $_->get_column('given_name') eq $obj->given_name) } @contacts;
        push @allsorted, @contacts_name;
    }
    if ($obj->family_name) {
        my @contacts_family_name = grep { $_->get_column('family_name') eq $obj->family_name } @contacts;
        @contacts = grep { $_->get_column('family_name') ne $obj->family_name } @contacts;
        push @allsorted, @contacts_family_name;
    }
    if ($obj->given_name) {
        my @contacts_given_name = grep { $_->get_column('given_name') eq $obj->given_name } @contacts;
        @contacts = grep { $_->get_column('given_name') ne $obj->given_name } @contacts;
        push @allsorted, @contacts_given_name;
    }
    if ($obj->addressbook_company_id) {
        my @contacts_addressbook_company_id = grep { $_->get_column('addressbook_company_id') eq $obj->addressbook_company_id } @contacts;
        @contacts = grep { $_->get_column('addressbook_company_id') ne $obj->addressbook_company_id } @contacts;
        @contacts_addressbook_company_id = sort {$a->family_name . $a->given_name cmp $b->family_name . $b->given_name} @contacts_addressbook_company_id;
        push @allsorted, @contacts_addressbook_company_id;
    } else {
        my @contacts_addressbook_company_id = grep { $_->get_column('addressbook_company_id') } @contacts;
        @contacts = grep { !$_->get_column('addressbook_company_id') } @contacts;
        @contacts_addressbook_company_id = sort {$a->addressbook_company_id->company_fullname . $a->family_name cmp $b->addressbook_company_id->company_fullname . $b->family_name } @contacts_addressbook_company_id;
        push @allsorted, @contacts_addressbook_company_id;
    }

    @contacts = sort { $a->family_name . $a->email_address . $a->fax_phone cmp $b->family_name . $b->email_address . $b->fax_phone } @contacts;
    push @allsorted, @contacts;

    $c->stash->{contacts} = \@allsorted;
}


sub cart_add : Local {
    my ( $self, $c ) = @_;

    my @contacts = ();
    @contacts = split ',', $c->session->{contacts} if $c->session->{contacts};
    
    my $contact_id = $c->req->params->{contact_id} || return $c->error404;
    my $type = $c->req->params->{type} || return $c->error404;
    my $contact = $c->get_object_or_404('BST::Contact', {private_person_id => $contact_id}) || return $c->error404;
    return $c->error403 unless $c->must_read($contact);
    my $contact_str = $type . ':' . $contact_id;

    if (! grep {$_ eq $contact_str} @contacts) {
        push @contacts, $contact_str;
        $c->session->{contacts} = join ',', @contacts;
    }

    $c->stash->{"Result"} = 'ok';
    $c->forward( $c->view('JSON') );    
}
sub cart_remove : Local {
    my ( $self, $c ) = @_;

    my $contact_id = $c->req->params->{contact_id} || return $c->error404;
    my $type = $c->req->params->{type} || return $c->error404;
    my $contact_str = $type . ':' . $contact_id;
    
    if ($c->session->{contacts}) {
        $c->session->{contacts} = 
            join ',', 
                grep {$_ ne $contact_str} 
                    split ',', $c->session->{contacts};
    }

    $c->stash->{"Result"} = 'ok';
    $c->forward( $c->view('JSON') );    
}


sub load_contacts_cart : Local {
    my ( $self, $c ) = @_;

    $c->stash->{"Result"} = [
        map {
            id => $_->{contact_id}->private_person_id
            ,name => $_->{contact_id}->name
            ,company_id => ($_->{contact_id}->addressbook_company_id ? $_->{contact_id}->addressbook_company_id->addressbook_company_id : undef)
            ,company_name => ($_->{contact_id}->addressbook_company_id ? $_->{contact_id}->addressbook_company_id->company_fullname : undef)
            ,address => $_->{address}
            ,type => $_->{type}
        }, @{$c->extract_contacts_cart}
    ];
    $c->forward( $c->view('JSON') );    
}


=head1 AUTHOR

Yuri Pac <yu.pats@gmail.com>

=cut

1;
