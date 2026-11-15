package BSA::Controller::Root;

use strict;
use warnings;

use Carp qw(croak);
use BST::User;
use BST qw(error);
use Data::Dumper;

use base 'BSA::Controller';
#use base 'Catalyst::Controller::FormBuilder';
use BST::Scope;

use URI::URL;


#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config->{namespace} = '';

=head1 NAME

BSA::Controller::Root - Root Controller for BSA

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=cut

=head2 default

this method serves root of the site.

=cut

sub default : Private {
    my ( $self, $c ) = @_;
    if ($c->req->path) {
        return $c->error404();
        #&error->page_not_found;
        #$c->res->status(404);
        #$c->detach();
    }
    return $c->response->redirect('/companies/list');
}

sub login : Local {
    my ( $self, $c ) = @_;

    if ($c->req->method eq 'POST') {
        # Get the username and password from form
        my $user = $c->request->params->{login} || "";
        my $pass = $c->request->params->{password} || "";

        my $u = BST::User->load( {user_id => $user} ) || BST::User->load( {login_id => $user} );
        
        &error->bad_username
            unless $u;

        if (!&error->status && $u->authenticate_login($pass)) {
            $c->user($u);
            if (
                (not $u->current_package_id)
                or (not $c->set_current_package($u->current_package_id))
            ) {
                $c->create_blank_package();
            }

            # redirect to the requested page or to the default manufacturers list
            my $url_redirect =
                $c->req->param('goto')
                || '/companies/list';

            return $c->response->redirect($url_redirect);
        }
    }
    $c->response->cookies->{"BuildSiteUser"} = { value => '', path => '/', expires => '+0', domain => BST::config("user_id_cookie_domain")};
    $c->forward( $c->view('TT::UnAuth') );
}

sub logout : Local {
    my ( $self, $c ) = @_;

    $c->delete_session;
    $c->response->cookies->{"BuildSiteUser"} = { value => '', path => '/', expires => '+0', domain => BST::config("user_id_cookie_domain")};
    $c->response->redirect('/');
}

=head2 end

Attempt to render a view, if needed.

=cut 

sub end : ActionClass('RenderView') {
    my ( $self, $c ) = @_;

    if (($c->res->status =~ /^40\d$/) && ($c->res->status != 404)) {
        $c->stash->{template} = 'default.tt';
    }
    
    # memory logging
    if (BST::config("memory_leaks_tracking")) {
        my $memory = $c->process_memory; my $diff = int(($memory->{bytes} - $c->stash->{__MEMORY_START}->{bytes}) / 1024) . ' kB';
        $c->log->debug('Memory at "end": ' . $memory->{string});
        $c->log->debug('Memory diff: ' . $diff);
        
        if (BST::config("memory_log_settings") and ref(BST::config("memory_log_settings")) eq 'HASH') {
            use Log::Dispatch::File::Stamped;
            my $file = Log::Dispatch::File::Stamped->new(%{BST::config("memory_log_settings")});
            $file->log(level => 'debug', message => "[" . (scalar localtime) . "]\n");
            $file->log(level => 'debug', message => "PID: $$\n");
            $file->log(level => 'debug', message => "URL: " . $c->request->uri . "\n");
            $file->log(level => 'debug', message => 'Memory at "auto": ' . $c->stash->{__MEMORY_START}->{string} . "\n");
            $file->log(level => 'debug', message => 'Memory at "end": ' . $memory->{string} . "\n");
            $file->log(level => 'debug', message => "Memory diff: $diff\n");
    
            $file->log(level => 'debug', message => "--------------------------------------\n");
        }
    }
    # /memory logging
}

use vars qw( $C $CRUMBS );

undef &BST::Core::hide_suppressed;
*BST::Core::hide_suppressed = sub { 
    if ($C and $C->user) { return not $C->user->is_bs_admin } 
    else { return 1; }
};

undef &BST::current_user;
*BST::current_user = sub { 
    if ($C and $C->user) { return $C->user; } 
    else { return undef; }
};

undef &BST::current;
*BST::current = sub {
    unless ($C) { return undef; }
    
    my $data = {};
    
    $data->{req}       = $C->req       if $C->req;
    $data->{user}      = $C->user      if $C->user;
    $data->{stash}     = $C->stash     if $C->stash;
    $data->{session}   = $C->session   if $C->session;
    $data->{sessionid} = $C->sessionid if $C->sessionid;
    
    return $data;
};

=head2 breadcrumbs_crumb

=cut

sub breadcrumbs_crumb {
        my $name = shift;
        my $href = shift || '';
        my $highlight = shift;
        my $root = shift;

        my $current = $C->request->uri;
        $current =~ s/^http:\/\/.*?(\/)/$1/i;
        
        if ($root) {
            shift @{$CRUMBS};
            undef $href;
        }

        my $crumbs = $CRUMBS;
        push @$crumbs, { name => $name, href => $href, active => $current eq $href, highlight => $highlight };
        return '';
}

=head2 auto

see <http://dev.catalyst.perl.org/wiki/FlowChart>

=cut


sub auto : Private {
    my ( $self, $c ) = @_;
    
    # set the global var
    $C = $c;
    
    # memory logging
    if (BST::config("memory_leaks_tracking")) {
        my $memory = $c->process_memory;
        $c->log->debug('Memory at "auto": ' . $memory->{string});
        $c->stash->{__MEMORY_START} = $memory;
    }
    # /memory logging

    my $str = $c->request->uri;
    my $stash = $c->stash;

    $stash->{error} = &error;

    $stash->{SCOPE_ALL} = BST::Scope::ALL;
    $stash->{SCOPE_USER} = BST::Scope::USER;
    $stash->{SCOPE_LOCATION} = BST::Scope::LOCATION;
    $stash->{SCOPE_ACCOUNT} = BST::Scope::ACCOUNT;
    $stash->{SCOPE_HIDDEN} = BST::Scope::HIDDEN;

    # for breadcrumbs trail
    $stash->{crumbs} = $CRUMBS = [ {name=>"BuildSite", href=>"/"} ];

    # Call crumbs with extra true parameter
    # to preserve highlighting even if it's href matches to requested URI
    $stash->{crumb} = \&breadcrumbs_crumb;

    &error->DESTROY(); # clean errors

    # load user object into session
    $c->session->{user_obj} = BST::User->load( id => $c->session->{user_id} )
        if ($c->session->{user_id});


    if ($c->user) {
        # do not forget, that you can access user information directly from view! change next lines according to this feature.
        $stash->{has_current_message} = defined $c->user->get_column( "current_message_id" );
        # this can be replaced by c.current_package! XXX
        $stash->{current_package} = $c->current_package;

        $c->check_undelivered_messages();
        $c->check_updated_package();

        my $expires = sprintf "+%dh", BST::config("session_lifetime_hours") || 2;
        $c->response->cookies->{"BuildSiteUser"} = { value => $c->user->id, path => '/', expires => $expires, domain => BST::config("user_id_cookie_domain") };
    } elsif ($c->req->action eq 'login') {

        # can the following condition be replaced with a $c->req->action check?
    } elsif ($c->req->uri =~ m!/ext/.*?$!) {

    } else {
        my $params = {};
        if ($c->req->path) {
            $params->{goto} = $c->req->uri;
        }
        # redirect to the login screen
        $c->response->redirect($c->uri_for('/login', $params));
        return 0;
    }
    
    if ($c->action->name =~ /^(?:view|edit)$/) {
        unless (scalar @{ $c->req->args } || scalar keys %{ $c->req->params }) {
            return $c->error404();
        }
    }

    if ($c->user && $c->req->uri =~ /autocrud/) {
        return $c->deny() unless $c->user->is_bs_admin;
    }

    return 1;
}


sub exit : Local {
    my ($self, $c) = @_;
    if( $c->user && $c->user->is_bs_admin ) { exit; }
}

=head1 AUTHOR

buildsite.com / play.ahinea.com

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
