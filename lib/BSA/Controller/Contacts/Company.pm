package BSA::Controller::Contacts::Company;

use strict;
use warnings;
use base 'BSA::Controller';

use Locale::US;
use BST::ContactCompany;
use Data::Dumper;

=head1 NAME

BSA::Controller::Contacts::Company - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 create
=cut

sub create : Local {
    my ( $self, $c ) = @_;
    $c->stash->{template} = "contacts/company/edit.tt";
    return $c->detach('edit');
}

=head2 list

=cut
my $oLoc = new Locale::US;
my $state_codes = [ sort $oLoc->all_state_codes ];

sub edit : Local Form {
    my ( $self, $c ) = @_;

    my $form = $self->formbuilder;
    my ($obj, $action);

    $form->field(name => 'state', options => $state_codes);
    if ($form->field('id')) {
        $obj = BST::ContactCompany->load({ addressbook_company_id => $form->field('id') });
        $c->must_read($obj) or return;
    }

    if ($form->submitted) {
        if ($form->validate) {
            unless ($obj) {
                $obj = $c->user->create_new_contact_company({company_fullname => $form->field('name')});
                $action = 'new';
            }
            $obj->set_columns({
                company_fullname => $form->field('name'),
                addr_street      => $form->field('address'),
                addr_city        => $form->field('city'),
                addr_region      => $form->field('state'),
                addr_postal_code => $form->field('zip'),
                location_phone   => $form->field('phone'),
                location_fax     => $form->field('fax'),
            });
            $obj->save();
            $c->response->redirect($c->uri_for('edit',{id => $obj->id, saved => 1, action => $action || "update"}));
        } else { 

        }
    } else {
        # formbuilder init
        if ($obj) {
            # fill list of values we need to show
            $form->field( name => 'name',    value => $obj->company_fullname);
            $form->field( name => 'address', value => $obj->addr_street);
            $form->field( name => 'city',    value => $obj->addr_city);
            $form->field( name => 'state',   value => $obj->addr_region);
            $form->field( name => 'zip',     value => $obj->addr_postal_code);
            $form->field( name => 'phone',   value => $obj->location_phone);
            $form->field( name => 'fax',     value => $obj->location_fax);
            $form->field( name => 'id',      value => $obj->id);
        }
    }
    $c->stash->{item} = $obj;
}

=head2 list

=cut

sub list : Local {
    my ( $self, $c ) = @_;

    my $order = $c->req->param('order') || 'company_fullname';
    my $q     = $c->req->param('q') || '';
    
    $c->stash->{contacts} = $c->user->contact_company_search($q, $order);
}


1;
