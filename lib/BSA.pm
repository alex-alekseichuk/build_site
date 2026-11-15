package BSA;

use strict;
use warnings;

use YAML;
use BST;
use BST::Message;
use Data::Dumper;
use JSON;
use Digest::MD5 qw(md5_hex);

use Catalyst::Runtime '5.70';
use Config::General qw(ParseConfig);
use Template::Filters;

use constant E_404 => 'Object not found';
use constant E_403 => 'Access denied';
use constant E_500 => 'Wrong parameters list';

# Set flags and add plugins for the application
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a YAML file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root
#                 directory

use Catalyst;

my @PLUGINS = qw/
-Debug
ConfigLoader
Static::Simple
Session
Session::State::Cookie
Log::Dispatch
Unicode
/;

# this doesn't seem to help:
#use Template::Stash::ForceUTF8;

our $VERSION = '0.0999';

# Configure the application.
#
# Note that settings in bsa.yml (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with a external configuration file acting as an override for
# local deployment.

__PACKAGE__->config(
    home => BST::config("home"),
);

#__PACKAGE__->config( YAML::LoadFile('bsa.yml') );


#$Template::Directive::WHILE_MAX = 10_000;
__PACKAGE__->config(
    name => 'BSA',
    root => __PACKAGE__->path_to('root'),
    default_view => 'TT::Default',
    'View::TT::Default' => {
        INCLUDE_PATH => [
            __PACKAGE__->path_to('templates','lib'),
            __PACKAGE__->path_to('templates','pages'),
        ],
        TEMPLATE_EXTENSION => '.tt',
        CATALYST_VAR       => 'c',
        WRAPPER            => 'page.tt',
        WHILE_MAX          => 10000,
#        COMPILE_DIR        => __PACKAGE__->path_to('templates','compiled'),
#        COMPILE_EXT        => '.ttc',
#        CACHE_SIZE         => 10_000,
        FILTERS => {
            'ext_url' => \&tt_filter_ext_url,
            'long_email' => \&tt_filter_long_email,
            'file_size' => \&tt_filter_file_size,
        },
    },
    'View::TT::Popup' => {
        INCLUDE_PATH => [
            __PACKAGE__->path_to('templates','lib'),
            __PACKAGE__->path_to('templates','pages'),
        ],
        TEMPLATE_EXTENSION => '.tt',
        CATALYST_VAR       => 'c',
        WRAPPER            => 'popup.tt',
        WHILE_MAX          => 10000,
        FILTERS => {
            'file_size' => \&tt_filter_file_size,
        },
    },
    'View::TT::Ajax' => {
        INCLUDE_PATH => [
            __PACKAGE__->path_to('templates','lib'),
            __PACKAGE__->path_to('templates','pages'),
        ],
        TEMPLATE_EXTENSION => '.tt',
        CATALYST_VAR       => 'c',
        WRAPPER            => 'ajax.tt',
        WHILE_MAX          => 10000,
        FILTERS => {
            'file_size' => \&tt_filter_file_size,
        },
    },
    'View::TT::UnAuth' => {
        INCLUDE_PATH => [
            __PACKAGE__->path_to('templates','lib'),
            __PACKAGE__->path_to('templates','pages'),
            __PACKAGE__->path_to('templates','pdf'),
        ],
# this doesn't seem to help:
#        STASH => Template::Stash::ForceUTF8->new,
        TEMPLATE_EXTENSION => '.tt',
        CATALYST_VAR       => 'c',
        WRAPPER            => 'layout_unauth.tt',
#        WHILE_MAX          => 10000,
    },
    'View::TT::WithoutWrapper' => {
        INCLUDE_PATH => [
            __PACKAGE__->path_to('templates','pdf'),
            __PACKAGE__->path_to('templates','lib'),
            __PACKAGE__->path_to('templates','pages'),
        ],
        TEMPLATE_EXTENSION => '.tt',
        CATALYST_VAR       => 'c',
        FILTERS => {
            'ext_url' => \&tt_filter_ext_url,
            'long_email' => \&tt_filter_long_email,
            'file_size' => \&tt_filter_file_size,
        },
    },
    'View::PDF' => {
        'outfile' => undef,
        content_type => 'application/pdf'
    },
    'View::JPG' => {
        'outfile' => undef,
        #content_type => 'image/jpeg'
    },
    'View::JSON' => {
    #    allow_callback  => 1,    # defaults to 0
    #    callback_param  => 'cb', # defaults to 'callback'
        expose_stash    => [ qw(Result) ], # defaults to everything
    },
    # at least the form_path below is needed. Not sure about the rest. -- ivan
    'Controller::FormBuilder' => {
        new => {
            debug => 0,
            keepextras => 0,
            lang => 'en_US',
            smartness => 0,
            sticky => 0,
        },
        form_path     => [ __PACKAGE__->path_to('templates', 'forms') ],
    },

    # Log::Dispatch is now configurable through BST::Config
    BST::config("Log::Dispatch") ? (
        "Log::Dispatch" => BST::config("Log::Dispatch")
    ) : (),
    
    #cache => {
    #    servers => [
    #        '127.0.0.1:11211',
    #    ],
    #    namespace => '',
    #},
    BST::config("session_storage_params") ? (
        session => { %{BST::config("session_storage_params")}, expires => (BST::config("session_lifetime_hours") || 2) * 3600 }
    ) : (
        BST::config("session_storage_path") ? (
            session => {
                storage => BST::config("session_storage_path"),
                expires => (BST::config("session_lifetime_hours") || 2) * 3600,
            }
        ) : (),
    ),

    stacktrace => { verbose => 1 },
);

# Start the application
__PACKAGE__->setup(
    @PLUGINS,
    BST::config("session_storage_plugin") || 'Session::Store::FastMmap',
    BST::config("email_errors") ? ('StackTrace', 'EmailErrors') : (),
);

sub bst_config { shift; BST::config( @_ ); }

#  use Tie::STDERR sub {
#      # this is an attempt to make STDERR rerouting smarter
#      # didn't work
#      if( __PACKAGE__->log ) { __PACKAGE__->log->debug(@_); }
#      else { die @_; print STDERR @_; }
#  };
#  $SIG{__WARN__} = sub { __PACKAGE__->log->warn(@_) };
#  $SIG{__DIE__} = sub { __PACKAGE__->log->fatal(@_) };

sub user { 
	my $self = shift;
	if (my $user = shift) {
		$self->session->{user_id} = $user->user_id;
		$self->session->{user_obj} = $user;
	}
	return $self->session->{user_obj}; 
}


sub current_package_id {
    my $c = shift; 
    return $c->session->{package_id};
}

sub current_package {
    my $c = shift; 
    my $session = $c->session;

    if ( $session->{current_package} ) { 
        return $session->{current_package}; 
    }

    my $package_id = $session->{package_id};
    if ( $package_id ) { 
        return $session->{current_package} = BST::Package->load( $package_id );
    }
    return undef;
}

# $c->set_current_package( PACKAGE );
# PACKAGE may be a BST::Package object ref, or a package_id string.
sub set_current_package {
    my $self = shift;
    my $package = shift;
    my $package_id;

    unless (ref $package) {
        $package_id = $package;
        $package = BST::Package->load( file_id => $package_id );
    } else {
        $package_id = $package->id;
    }

    if (
        ! $package
        || ! $package->is_package
        || ! $package->can_write($self->user)
    ) {
        return $self->create_blank_package()
    }

    if ($self->user) {
        my $prev_id = $self->user->get_column("current_package_id");
        if( $prev_id ne $package_id ) {
            warn "new current package: $package for user: " . $self->user;
            $self->user->current_package_id($package);
            $self->user->save();
        } 
        else {
            warn "the package is the same: $package for user: " . $self->user;
        }
    }

    $self->session->{package_id} = $package_id;
    $self->session->{current_package} = $package;
    $self->package_update_json();

    return $package;
}


sub create_blank_package {
    my $self = shift;
    my $type = shift;
    $type = '' unless exists $BST::PackageToc::Types::TYPES{$type};

    my $class = $type ? 'BST::PackageToc' : 'BST::Package';
    my $package = $class->create( {
        owner => $self->user->location->account_location_id,
        scope => BST::Scope::HIDDEN,
        creator_user => $self->user
    } );
    $package->save();

    if ($type) {
        $package->init_toc($type, $self->user);
    }

    $self->set_current_package($package);
    return $package;
}


sub dont_cache {
    my $self = shift;
    $self->res->header(
        'Cache-Control' =>
        'no-store, no-cache, must-revalidate, post-check=0, pre-check=0, max-age=0'
    );
    $self->res->header( 'Pragma' => 'no-cache' );
    $self->res->header( 'Expires' => 'Thu, 01 Jan 1970 00:00:00 GMT' );
}


use Carp qw(confess);

sub deny {
    my $self = shift;
    my $msg = shift || "Access denied!";
    #confess "DENY: $msg";
    $self->error403();

    return 0;
}



=item package_return - private method

Returns a representation of the current package

XXX - move this to BST::PackageToc class, at least the main part of it
XXX - it would be great to optimize this sub or to cache it, as it is 
executed for every user request

=cut

sub package_return {
    my $self = shift;
    my $format = shift || 'JSON';

    $self->dont_cache();
    my $package = $self->package_get() || return (
        $format eq 'JSON' ? $self->forward( $self->view('JSON') ) : 0
    );

    my $json = $package->json();
    $self->stash->{Result} = $json;
    $self->package_update_json($json) if ($package->package_id eq $self->current_package_id);

    return $self->forward( $self->view('JSON') ) if ($format eq 'JSON');
}


sub package_update_json {
    my $self = shift;
    my $json_str = shift;
    unless ($json_str) {
        my $p = $self->current_package();
        return unless $p;
        $json_str = $p->json();
    }

    my $json = new JSON;
    $self->session->{current_package_json} = $json->encode( $json_str );
    $self->session->{current_package_json_time} = scalar time;
}

sub package_check_update {
    my $self = shift;
    my $package = shift;
    
    $self->package_update_json() if ($package->file_id eq $self->current_package_id);
}




=item  package_blank - private method

Creates an empty package

=cut

sub package_blank : Private {
    my $c = shift;

    my $package = BST::Package->create( {
        owner => $c->user->primary_location->account_location_id,
        scope => BST::Scope::HIDDEN,
        creator_user => $c->user,
    } );
    $package->save();

    $c->set_current_package($package);
    return $package;
}


=item  package_get - private method

Returns a package specified by CGI parameter or the current package

=cut

sub package_get : Private {
    my $c = shift;
    my $pkg = $c->req->param('package_id') ?
        BST::PackageToc->load({ file_id => $c->req->param('package_id') }) :
        $c->current_package
    ;
    my $a = ref ($pkg) =~ m/Package/ ? $pkg : undef;
}


=item  package - private method

Returns (or creates) the package for an action, checks if user has access to the package

=cut

sub package : Private {
    my $c = shift;
    my $create = shift || 0;

    my $pkg = $c->package_get();
    unless ($pkg) {
        return $c->package_blank() if ($create);
        return $c->package_action(E_404);
    }

    return $c->package_action(E_403) unless $pkg->can_write($c->user);
    return $pkg;
}



=item  package_action - private method

Returns representation of the taken action

=cut
sub package_action : Private {
    my $c = shift;
    my $error = shift;

    $c->stash->{Result} = {};

    $c->stash->{Result}->{action} = {
        method => $c->action->name,
        result => $error ? 'error' : 'ok',
        error => $error
    };

    $c->package_return();
    return 0;
}






sub _json_toc_row : Private {
    my $c = shift;
    my $row = shift;
    my $column_fields = shift;

    my $json_row = {};

    # move columns data from the row to json structure
    if ($column_fields) {
        foreach my $column (@$column_fields) {
            if ($column->{name} eq "items") {
                my $json_items = [];
                foreach my $item (@{$row->{$column->{name}}}) {
                    my $is_file = 0;
                    my $is_document = 0;
                    if ($item->{type} eq "file") {
                        $is_file = 1;
                    } else { # else document
                        $is_document = 1;
                    }
                    push @$json_items, {
                        'id'                    => $item->{package_item_id}
                        ,'object_id'            => $item->{id}
                        ,'is_file'              => $is_file
                        ,'is_document'          => $is_document
                        ,'is_product_document'  => $item->{is_product_document}
                        ,'title'                => $item->{title}
                        ,'filesize'             => $item->{file_size}
                        ,'file_size'            => $item->{file_size}
                        ,'pages'                => $item->{page_count}
                        ,'pages_count'          => $item->{page_count}
                        ,'product_id'           => $item->{product_id}

                    };
                }
                $json_row->{$column->{name}} = $json_items;
            } else {
                $json_row->{$column->{name}} = $row->{$column->{name}};
            }
        }
    }
    return $json_row;

}



sub package_toc_return_row : Private {
    my $c = shift;
    my $i_row = shift;

    $c->dont_cache();

    my $package = $c->package_get() || return ( $c->forward( $c->view('JSON') ) );

    # get toc
    my $toc = $package->package_toc_extra;

    # check if row index is correct
    return ( $c->forward( $c->view('JSON') ) ) if ($#{$toc->{table}} < $i_row);

    # get row data from the table
    my $row = $toc->{table}->[$i_row];
    my $column_fields = $BST::PackageToc::Types::TYPES{$package->package_toc_type}->{column_fields};

    my $json_row = $c->_json_toc_row($row, $column_fields);

    $c->stash->{Result}->{rows} = [ $json_row ] if $json_row;

    return $c->forward( $c->view('JSON') );
}


sub package_toc_return_table : Private {
    my $c = shift;

    $c->dont_cache();

    my $package = $c->package_get() || return ( $c->forward( $c->view('JSON') ) );

    # get toc
    my $toc = $package->package_toc_extra;

    # get row data from the table
    my $rows = $toc->{table};
    my $column_fields = $BST::PackageToc::Types::TYPES{$package->package_toc_type}->{column_fields};

    $c->stash->{Result}->{rows} = [
        map {
            $c->_json_toc_row($_, $column_fields)
        } @$rows
    ];

    return $c->forward( $c->view('JSON') );
}

=item  package_toc_action - private method

Returns representation of the taken action

=cut

sub package_toc_action : Private {
    my $c = shift;
    my $i_row = shift;
    my $error = shift;

    $c->stash->{Result} = {};

    my $package = $c->package_get();
    $error = E_404 unless $package;
    if ($i_row) {
        # get toc
        my $toc = $package->package_toc_data;

        # check if row index is correct
        $error = E_404 if ($#{$toc->{table}} < $i_row);
    }

    $c->stash->{Result}->{action} = {
        method => $c->action->name,
        result => $error ? 'error' : 'ok',
        error => $error
    };

    unless ($error) {
        if ($i_row) {
            $c->package_toc_return_row($i_row);
        } else {
            $c->package_toc_return_table();
        }
    }

    return 0;
}




=item  extract_contacts_cart - private method

Returns contacts cart items and clean contacts cart in session.

=cut

sub extract_contacts_cart : Private {
    my $c = shift;

    if ($c->session->{contacts}) {
        my $contacts_parts = [ map { [split(':', $_)] } split ',', $c->session->{contacts} ];
        my $contacts = { 
            map 
                { $_->private_person_id => $_ } 
                BST::Contact->search( { 'private_person_id' => [
                    map { $_->[1] } @$contacts_parts 
                ] } )
        };
        $c->session->{contacts} = '';
        return [
            map {
                my $contact = $contacts->{$_->[1]};
                my $type = $_->[0];
                {
                    type => $type
                    ,contact_id => $contact
                    ,address => $type eq 'email' ? $contact->email_address : $contact->fax_phone
                }
            } @$contacts_parts
        ];
    }
}







=item must_read() and must_write()

These methods are called in BSA controllers to check if user has access to an object.
BST::* instance as an argument.

Usage in controller:
my ($self, $c) = shift;
my $obj = BST::File->load( { file_id => $c->req->param('file_id') } );
return unless $c->must_read($obj);

=cut
sub must_read {
    my $self = shift;
    my $obj = shift;

    return 1 if $obj && ($self->user->is_bs_admin() || $obj->can_read($self->user));
    $self->deny();
    return 0;
}

sub must_write {
    my $self = shift;
    my $obj = shift;

    return 1 if $obj && ($self->user->is_bs_admin() || $obj->can_write($self->user));
    $self->deny();
    return 0;
}

=head2 get_object_or_404

It's a proxy object to BST::load method.
Method tries to load requested object. If fails - returns a 404 responce.

$c->get_object_or_404('Classname', any other args as in BST::load)
Note classname w\o BST::

=cut
sub get_object_or_404 {
    my $self = shift;

    my $obj = BST::load(@_);
    my $st = 0;

    if ($obj) {
        $st = 403
            if ($obj->isa('BST::FolderItem') && !$obj->can_read( $self->user ));
    } else { $st = 404 }

    if ($st) {
        $self->res->status(404);
        return $self->error404();
    } else { return $obj }
}


sub get_object_list {}

sub error404 {
    my $c = shift;
    if ($c->req->param('ajax')) {
        $c->response->status(404);
        $c->stash->{"Result"} = { "error" => "Not Found" };
        $c->forward( $c->view('JSON') );
    } else {
        $c->forward('/error/error404');
    }
}

sub error403 {
    my $c = shift;
    if ($c->req->param('ajax')) {
        $c->response->status(403);
        $c->stash->{"Result"} = { "error" => "Access denied" };
        $c->forward( $c->view('JSON') );
    } else {
        $c->forward('/error/error403'); 
    }
}


# override a method defined and used by Catalyst::Plugin::Session
sub finalize_session {
    my $c = shift;

    if ( my $session_data = $c->_session ) {
        # remove these two items from session data to avoid storing
        # whole bunch of related BST::* objects in the session, which
        # is needless and causing problems when Unicode data is in
        # there - iku
        delete $session_data->{user_obj};
        delete $session_data->{current_package};
    }
        
    $c->maybe::next::method(@_);
}


# Update current package JSON if lifetime option wasn't set or cached copy is too old
sub check_updated_package {
    my $c = shift;
    my $lifetime = BST::config('package_json_lifetime');
    return unless (!$lifetime || (scalar time > ($c->session->{current_package_json_time} || 0) + BST::config('package_json_lifetime')));

    $c->package_update_json() ;
}

sub check_undelivered_messages {
    my $c = shift;
    return unless $c->user;
    return unless scalar time > ($c->session->{undelivered_messages_last_check} || 0) + (BST::config('undelivered_messages_list_lifetime') || 10);

    my $undelivered_messages = BST::Message->search(
        {
            'recipients.status' => { '~*', '^failed' },
            'message_status_ack' => 'none',
            sender => $c->user->id,
        },
        {
            join => 'recipients',
            distinct => 1,
        }
    );

    $c->session->{undelivered_messages_list} = [ map $_->message_id, $undelivered_messages->all ];
    $c->session->{undelivered_messages_last_check} = scalar time;
}

sub remove_undelivered_message {
    my $c = shift;
    my $id = shift;
    return unless $c->user;

    my $message = $c->get_object_or_404('BST::Message', { message_id => $id } );
    return unless $c->must_read($message);

    $message->message_status_ack('ack');
    $message->save();

}


=head2 tt_filter_ext_url

TT filter to convert abs. /ext/ urls to appropriate HTML href. tags

=cut

sub tt_filter_ext_url {
    my $text = shift;
    return unless $text;
    $text =~ s~(http://\S+/ext/\S+)~<a href="$1">$1</a>~ig;
    return $text;
}


sub tt_filter_long_email {
    my $text = shift;
    return unless $text;
    $text =~ s/(.+?)\@(.+?)\.(\w{2,6})/$1\@<br \/>$2.$3/;
    return $text;
}

sub tt_filter_file_size {
    my $size = shift;
    my $kb = int ($size / 1000);
    return sprintf "%d Kb", $kb if $kb < 1000;

    $kb = $kb / 1000;
    $kb = int($kb * 10) / 10;
    my $format = (int $kb == $kb) ? "%d" : "%.1f";
    return sprintf $format . " Mb", $kb;
}

=head2 process_memory

return process memory (string presentation, bytes count)

=cut

sub process_memory {
    my $c   = shift;
    my $pid = shift || $$;
	
    my %bytes; @bytes{qw(kb mb gb)} = (1..3);
    
    my ($vmsize) = grep { /^VmSize/ } split "\n", `cat /proc/$pid/status`;
    my (undef, $size) = split "\t", $vmsize; $size =~ s/^\s+//;
    
    $size =~ /(\d+)\s*(\w+)/ or return undef;
    return {
        string => $size,
        bytes  => exists $bytes{lc $2} ? $1 * (1024 ** $bytes{lc $2}) : $1
    };
}

sub cache_key {
	my $c = shift;

	return md5_hex(
		join "\n", (
			$c->request->uri->as_string,
			$c->user->cache_group_id
		)
	);
}

sub check_html_cache {
	my $c = shift;
	
	unless ($c->stash->{__html_cache}) {
		eval 'use Cache::FileCache';
		$c->stash->{__html_cache} = new Cache::FileCache(BST::config('html_cache'));
	}
	
	return $c->stash->{__html_cache}->get($c->cache_key) ? 1 : 0;
}

=head1 NAME

BSA - Catalyst based application

=head1 SYNOPSIS

    script/bsa_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<BSA::Controller::Root>, L<Catalyst>

=head1 AUTHOR

Catalyst developer

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
