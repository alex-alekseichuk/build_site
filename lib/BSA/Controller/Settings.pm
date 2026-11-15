package BSA::Controller::Settings;

use strict;
use warnings;
use base 'BSA::Controller';

use BST::SettingItem;
use BST::User;
use BST::Scope;
use Data::Dumper;

=head1 NAME

BSA::Controller::Settings - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index : Private {
    my ( $self, $c ) = @_;
    my $user = BST::User->load( { user_id => $c->session->{user_id} } );    

    $c->response->redirect( '/admin/' );
}


sub _fill_crumbs : Private {
    my $c = shift;
    my $scope = shift;
    my $val = shift;
    
    my $path = shift;
    
    if (BST::Scope->is_account($scope)) {
        $path->{account_id} = $val;

    } elsif (BST::Scope->is_user($scope)) {
        my $oUser = BST::User->load( { user_id => $val } );
        $path->{user_id} = $val;
        $path->{user_name} = $oUser->given_name . ' ' . $oUser->family_name;
        $path->{account_id} = $oUser->primary_location->account->account_id;

    } elsif (BST::Scope->is_location($scope)) {
        my $oLocation = BST::Location->load( { account_location_id => $val } );
        $path->{location_id} = $val;
        $path->{location_name} = $oLocation->location_fullname || $oLocation->location_nickname;
        $path->{account_id} = $oLocation->account->account_id;
    }

    if ($path->{account_id}) {
        my $oAcc = BST::Account->load( { account_id => $path->{account_id} } );
        $path->{account_name} = $oAcc->company ? $oAcc->company->legal_name : '';
    }

    $c->stash->{path} = $path;
}


sub list : Local {
    my ( $self, $c ) = @_;

    # Whose settings are we viewing?
    # If there no request params, we should fill it according to user role
    my ($restrict_type, $restrict_val);
    if ($c->req->param('scope') && $c->req->param('scope_value')) {
        ($restrict_type, $restrict_val) = ($c->req->param('scope'), $c->req->param('scope_value'));
        unless ($c->user->is_bs_admin()) {
            return $c->deny() unless $c->user->settings->can_list($restrict_type, $restrict_val);
        }
    } elsif ($c->user->is_bs_admin()) {
        ($restrict_type, $restrict_val) = (BST::Scope::ALL, '');
    } elsif ($c->user->is_account_admin()) {
        ($restrict_type, $restrict_val) = (BST::Scope::ACCOUNT, $c->user->primary_location->account->account_id);
    } else {
        ($restrict_type, $restrict_val) = (BST::Scope::USER, $c->user->user_id);
    }
    $c->stash->{settings} = $c->user->settings;
    $c->stash->{owner} = $c->user;

    $c->stash->{items} = $c->user->settings->get_viewable($restrict_type);
    $c->stash->{values} = $c->user->settings->get_settings($restrict_type, $restrict_val);
    $c->stash->{scopes} = $c->user->settings->get_scope_set($restrict_type);
    $c->stash->{restrict} = {scope => $restrict_type, value => $restrict_val};

#    $c->forward( $c->view('TT') );
    _fill_crumbs($c, $restrict_type, $restrict_val);
}


sub display : Local {
    my ( $self, $c ) = @_;
    my ($oSetting, $oSI) = $self->_get_setting( {
        att_name => $c->req->param('att_name'), 
        scope => $c->req->param('scope'), 
        scope_value => $c->req->param('scope_value'),
    } );
    
    return unless $c->must_read($oSI);

    my $filename = $oSetting->value;
    $filename =~ s/.*\///;

    my $file = BST::config('settings_path') . '/' . $oSetting->value;
    die "File $file doesn't exists!" unless -e $file;

    $c->serve_static_file($file);
}



sub edit : Local Form {
    my ( $self, $c ) = @_;

    my $form = $self->formbuilder;
    my $action = $form->submitted();
    if ($action && $form->validate) {
        my ($oSetting, $oSI) = $self->_get_setting( {
            att_name => $form->field('att_name'), 
            scope => $form->field('scope'), 
            scope_value => $form->field('scope_value'),
        }, $c->user );
        return unless $c->must_write($oSI);

        if ($action eq "Delete") {
            $oSetting->delete();
            return $c->response->redirect( $c->uri_for('list', { scope => $c->req->param('scope'), scope_value => $c->req->param('scope_value') } ) );
        } else {
            my $value;
            if ($oSI->get_type() eq 'file') {
                my $upload = $c->req->upload('value');

                my ($filename) = $oSetting->name =~ m/(.*)_file/;
                my ($ext) = $upload->filename =~ m/\.(.*?)$/;
                my $path = $oSetting->scope . (
                    $oSetting->scope eq BST::Scope::ALL ? '' : '-' . $oSetting->scope_value
                );

                my $abs_path = BST::config('settings_path') . '/' . $path;
                unless (-e $abs_path) {
                    mkdir $abs_path || die sprintf "Cannot create directory '%s': %s", $abs_path, $!;
                }
                
                $_ .= '/' . $filename . '.' . $ext foreach ($abs_path, $path);

                die( sprintf ("Failed to copy '%s' to '%s': $!", $upload->filename, $abs_path )) unless ( $upload->copy_to($abs_path) );

                $value = $path;
            } else {
                $value = join ";", $form->field('value');
            }

            if ($oSI->validate_value($value)) {

                $oSetting->set_columns( {
                    att_val  => $value,
                } );
                $oSetting->save;
                $c->response->redirect( $c->uri_for('list', { scope => $c->req->param('scope'), scope_value => $c->req->param('scope_value') } ) );
                return;
            } else {
                # Here's something like error reporting
                $c->stash->{error}->setting_value_invalid;
            }
        }
    }

    my $req = $c->req;
    die "something is missing. we need the following params: att_name scope scope_value"
    if not $req->param('att_name') or 
    not $req->param('scope') or
    not $req->param('scope_value');

    my ($oSetting, $oSI, $new) = $self->_get_setting( {
        att_name =>    $req->param('att_name'),  
        scope    =>    $req->param('scope'), 
        scope_value => $req->param('scope_value'),
    }, $c->user );

    return unless $c->must_read($oSI);

    my $params = $oSI->get_field_params();

    $form->field(
       name => 'value',
       label => $oSetting->meta->{label},
       value => $oSetting->value,
       %$params,
    );

    $form->field(
        name => $_,
        value => $c->req->param($_)
    ) foreach qw(att_name scope scope_value);

    my @buttons = $new ? ('Save') : ('Save', 'Delete');
    $c->stash->{form} = $form->render(submit => \@buttons);
    $c->stash->{setting} = $oSetting;
    $c->stash->{setting_type} = $oSI->get_type();
    $c->stash->{read_only} = $oSI->can_write($c->user) ? 0 : 1;

    _fill_crumbs($c, $oSetting->scope, $oSetting->scope_value);
}

sub _get_setting {
    my $self = shift;
    my $data = shift;
    my $viewer = shift;
    my $default = shift;

    my $new = 0;
    my $oSetting = BST::Setting->load($data);

    unless (ref $oSetting) {
        $oSetting = BST::Setting->create($data) ;
        $new = 1;
    }

    my $oSI = new BST::SettingItem( $oSetting, $viewer );

    return ($oSetting, $oSI, $new);
}



=head1 AUTHOR

Nikolai Liohenki <kalyansky@gmail.com>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
