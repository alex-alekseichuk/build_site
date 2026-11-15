package BSA::Controller::Folders;

use strict;
use warnings;
use base 'BSA::Controller';
#use base 'Catalyst::Controller::FormBuilder';

use Data::Dumper;

use JSON;
use BST qw(error);
use BST::User;
use BST::Location;
use BST::Folder;
use BST::RootFolder;
use BST::PackageToc;
use BST::PackageToc::Types;
use BST::Scope;
use File::Path; # qw(make_path);

=head1 NAME

BSA::Controller::Folders - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub auto : Private {
    my ( $self, $c ) = @_;
    if ($c->req->param('file_id')) {

        $self->{_file} = $c->get_object_or_404('BST::FolderItem', { file_id => $c->req->param('file_id') });
        $c->must_read($self->{_file});
    }
    return 1;
}


sub file  {
    my $self = shift;
    return $self->{_file};
}


=head2 construct the path to show in breadcrumb

=cut

sub _fill_path {
    my $c = shift;
    my $folder = shift;
    my $scope = shift;
    my $crumbs = [];
    $scope = $folder->scope if (!$scope && $folder);

    while ($folder) {
        last if (ref $folder eq "BST::RootFolder");
        unshift @$crumbs, {
            id => $folder->file_id,
            title => $folder->file_title,
            type  => $folder->file_class
        };
        $folder = $folder->parent;
    }

    $c->stash->{path} = {scope => $scope, crumbs => scalar @$crumbs ? $crumbs : undef};
}

=head2 show list of file objects in Document Drawer

=cut

sub list : Local {
    my ( $self, $c ) = @_;
    my $user = $c->user;

    # get this page parameters
    my $order_by = $c->request->params->{order} || 'file_title';
    my $order_dir = 'asc';

    my $folder_id = $c->req->param('id') || undef;
    my $folder;

    if (defined $folder_id) {
        $folder = BST::Folder->load( { file_id => $folder_id } ) || undef;
    }

    my $scope;
    if (not defined $folder) {
        # scope
        $scope = $c->request->params->{scope} || BST::Scope::USER;

        # root folder of this user
        if (BST::Scope->is_location($scope)) {
            $folder = $user->location_folder;
        } elsif (BST::Scope->is_account($scope)) {
            $folder = $user->account_folder;
        } elsif (BST::Scope->is_user($scope)) {
            $folder = $user->private_folder;
        } else {
            $folder = $user->all_folder;
        }

    } else {
        return unless $c->must_read($folder);
        $scope = $folder->scope;
        $c->stash->{folder} = $folder;
    }

    my $files = $folder->list({
        order_by => [ 'file_class DESC', $order_by . " " . $order_dir ],
        rows => 500,
    });
    my $type = $c->req->param('type');
    # alias
    $type = 'archive' if $type && $type eq 'package';

    my @files;
    if ($type) {
        @files = grep {$_->file_class eq $type} $files->all;
    } else {
        @files = $files->all;
    }

    if (!$c->req->param('ajax')) {
        $c->stash->{folder_items} = \@files;
        _fill_path($c, $folder, $scope);
    } else {

        $c->stash->{Result} = { items => [
            map {;
                { id => $_->file_id, title => $_->title, comment => $_->file_comment, scope => $_->scope, owner => $_->owner->account_location_id, parent => $_->parent, type => $_->file_class }
            } @files
        ]};

        $c->forward( $c->view('JSON') );
    }
}

sub get_scope {
    my ( $self, $c, $scope, $items_ids ) = @_;
    my $user = $c->user;

    my @files = BST::search('FolderItem', {
                %{ BST::FolderItem->get_default_search_filter() },
                %{ BST::FolderItem->get_scope_search_filter( $scope, $user ) },
                scope => $scope
    }); 

    my $res = [
        map {;
            { 
                id => $_->file_id, 
                title => $_->title, 
                comment => $_->file_comment, 
                scope => $_->scope, 
                owner => $_->owner->account_location_id, 
                parent => $_->parent ? $_->parent->file_id : undef, 
                type => $_->file_class, 
                added => 0 
            }
        } @files
    ];
    foreach my $item (@$res) {
        foreach my $item_id (@$items_ids) {
            if ($item_id and $item->{id} eq $item_id) {
                $item->{added} = 1;
                last;
            }
        }
    }
    return $res;
}

sub get : Local {
    my ( $self, $c ) = @_;
    my $user = $c->user;

    # get this page parameters
    #my $order_by = $c->request->params->{order} || 'file_title';
    #my $order_dir = 'asc';

    # get current package or the one specified by id
    my $package = $c->current_package;
    my $package_id = $c->request->params->{package_id} || '';
    if ($package_id)
    {
        $package = BST::FolderItem->load({ file_id => $package_id });
    }
    
    # package items id's
    my $items_ids = [];
    if ($package)
    {
        $items_ids = [ map $_->file_id, $package->items ];
    }

    $c->stash->{Result} = {
        items_user => $self->get_scope($c, BST::Scope::USER, $items_ids),
        items_location => $self->get_scope($c, BST::Scope::LOCATION, $items_ids),
        items_account => $self->get_scope($c, BST::Scope::ACCOUNT, $items_ids)
    };

    $c->forward( $c->view('JSON') );
}


=head2 remove file object of the package

=cut

sub removefile : Path('delete') {
    my ( $self, $c ) = @_;
    my $parent;
    
    my $obj = $self->file;
    return unless $c->must_write($obj);

    my $scope = $obj->scope;

    $parent = $obj->parent if ($obj->parent);

    if ($obj->is_folder) {
        return $c->response->redirect($c->uri_for('list', {id => $obj->id})) if ($c->req->param('cancel'));

        my $files = $obj->list({
            order_by => [ 'file_class DESC'],
            rows => 1,
        });

        # Display confirmation dialog for non-empty folders
        if ($files->count && !$c->req->param('confirm')) {
            _fill_path($c, $obj, $scope);
            $c->stash->{folder} = $obj;
            return;
        }

        my $folders = [$obj];
        while (@$folders) {
            my $folder = shift @$folders;
            map {
                push @$folders, $_ if ($_->is_folder);
                $_->delete($c->user);
            } $folder->list();
        }
    }
    
    if ($obj->is_package && $obj->file_id eq $c->current_package->file_id) {
        $c->create_blank_package();
    }
    $obj->delete($c->user);

    my $params = {scope => $scope, success => 'remove'};
    $params->{id} = $parent if ($parent);
    $c->response->redirect($c->uri_for('list', $params));
}

=head2 create new folder

=cut

sub createdir : Path('mkdir') Form {
    my ($self, $c) = @_;

    my $form = $self->formbuilder;
    my $scope = $c->req->param('scope');
    my $parent;
    my $folder;

    if ($c->req->param('file_id')) {
        $folder = $self->file;
        return unless $c->must_write($folder);
        $scope = $folder->scope;
    }

    if ($form->submitted && $form->validate) {
        if ($scope =~ m/^_.*[^\d]$/) {
            $scope = substr($scope, 1);
        } else {
            $parent = $scope;
            $folder = BST::Folder->load( { file_id => $parent } );
            $scope = $folder->scope;

            return unless $c->must_write($folder);
        }

        return $c->deny() unless $self->can_write_to_scope($c->user, $scope);

        my $owner;
        my $obj = BST::FolderItem->create({
            creator_user => $c->user->user_id,
            file_title   => $c->req->param('title'),
            file_comment => $c->req->param('comment'),
            owner        => $c->user->primary_location->account_location_id,
            scope        => $scope,
            parent       => $parent,
            file_class   => 'folder'
        });
        $obj->save();
        $c->response->redirect($c->uri_for('list', {scope => $scope, id => $parent}));
    }


    my $scopes = [BST::Scope::USER, BST::Scope::LOCATION];
    push @$scopes, BST::Scope::ACCOUNT if $c->user->is_account_admin() || $c->user->is_bs_admin();

    my $folders = [];
    push @$folders, { $_->{id} => $_->{path} } foreach $c->user->get_all_folders($scopes);

    $form->field(
        name => 'scope',
        options => $folders,
        default => '_' . BST::Scope::USER,
        value => $c->req->param('file_id') ? $c->req->param('file_id') : '_' . $scope,
        selectname => 0
    );

    _fill_path($c, $folder, $scope);
}



sub can_write_to_scope {
    my ( $self, $user, $scope ) = @_;
    if ($user->is_bs_admin) { return 1; }
    if ($user->is_account_admin
        and $scope eq BST::Scope::ACCOUNT) { return 1; }
    if ($scope eq BST::Scope::USER
        or $scope eq BST::Scope::LOCATION) { return 1; }
    return 0;
}




=head2 copy or move specified file object in DD

=cut

sub copy : Local {
    my ( $self, $c ) = @_;

    my $file = $self->file;
    my $parent_id = $c->req->param('parent_id');
    my $action = $c->req->param('action') || 'copy';
    my $is_ajax = $c->req->param('ajax'); # boolean


    if ($action eq 'move') {
        # does the user have a right to move the original file?
        return $c->deny("You can't move this file") unless $c->must_write($file);
    }

    # get and check the destination
    my ($new_scope, $new_parent_id, $new_parent);
    if ( $parent_id =~ m/^_([a-z]+)/ ) {
        # just scope is given; destination is the root of the scope
        $new_scope = $1;
    } else {
        $new_parent = BST::FolderItem->load( { file_id => $parent_id } );
        # XXX check the object type of $new_parent? must be a folder
        $new_parent_id = $new_parent->file_id;
        $new_scope     = $new_parent->scope;
    }

    # just in case: check copying/moving to itself
    die if $new_parent_id && $new_parent_id eq $file->id;

    # XXX are we copying/moving the file to its current location, actually?
    # if we are moving it, the whole operation just makes no sense.
    # if we are copying, we probably need to add something to its name, like "Copy of $original_name"

    # check the rights (access control)
    if (not $self->can_write_to_scope( $c->user, $new_scope ) ) { return $c->deny(); }
    if ($new_parent) {
        return $c->deny() unless $c->must_write($new_parent);
    }

    # move and copy
    if ($action eq 'move') {
        $file->scope($new_scope);
        $file->parent($new_parent_id);
        if (BST::Scope->is_user($new_scope)) {
            $file->creator_user($c->user->user_id);
        }
    } else {
        $file = $file->clone($c->user);
        $file->scope($new_scope);
        $file->parent($new_parent_id);
    }        

    # apply the form value changes? XXX
    #$file->file_title($c->req->param('name'));
    #$file->file_comment($c->req->param('description'));

    $file->save;
    $c->package_check_update( $file );


    if ($is_ajax)
    {
        my $scope_titles = {
            BST::Scope::USER => 'Private',
            BST::Scope::LOCATION => 'Location',
            BST::Scope::ACCOUNT => 'Company'
        };

        my $path = $scope_titles->{$new_scope} . ":\\" . "TODO";
        
        $c->stash->{Result} = {
            action => $action,
            scope => $new_scope,
            folder => {
                path => $path,
                title => ($new_parent ? $new_parent->title : ''),
                id => $new_parent_id || 0
            }
        };
        $c->forward( $c->view('JSON') );
    } else {
        $c->response->redirect(
            $c->uri_for('edit', { file_id => $file->file_id, success => $action } )
        );
    }

}


=head2 edit

show and save file & package edit form.
edit only file attributes, package content data are edited elsewhere.
get's the GET request, form file is stored in forms/folders/edit.fb

=cut

sub edit : Local Form {
    my ( $self, $c ) = @_;
    my $submitted = $_[2];

    if (my $error = $c->req->param('error')) {
        &error->$error;
    }

    my $file = $self->file;

    $c->stash->{template} = 'folders/view.tt';

    # save if the form was submitted
    $c->stash->{msg} = $c->req->param('msg') || '';
    $c->stash->{item} = $file;

    $self->json_file($c, $file);

    if ($file->is_package) {
        unless ($file->creator_user) {
            $file->creator_user($c->user);
            $file->save();
        }

        # compose switch_toc select-box options list; filter it if it needs by disabling leed options
        my $cur_toc_type = $file->package_toc_type;
        my @toc_types_ids;
        if ($c->user->settings->list->{disable_leed_submittals} eq 'y') {
            @toc_types_ids = grep {
                'leed' ne $BST::PackageToc::Types::TYPES{$_}->{group}
                ||
                $cur_toc_type eq $_
            } @BST::PackageToc::Types::TYPES_ORDER;
        } else {
            @toc_types_ids = @BST::PackageToc::Types::TYPES_ORDER;
        }
        my @toc_types = map { key => $_, value => $BST::PackageToc::Types::TYPES{$_}->{type_label} }, @toc_types_ids;
        $c->stash->{toc_types} = \@toc_types;

        # set TOC footer text if it exists
        if ($cur_toc_type) {
            $c->stash->{toc_footer_html} = $BST::PackageToc::Types::TYPES{$cur_toc_type}->{footer_html};
            $self->view_toc($c, $file);
        }
    }
        
    if ($file->is_folder) {
        my @list = $file->list({ rows => 2 });
        $c->stash->{has_items} = scalar @list;
    }

    _fill_path($c, $file);
}


=head2 internal method puts JSON data of specified file object to the stash

=cut

sub json_file : Private {
    my $self = shift;
    my $c = shift;
    my $file = shift;
    
    my $data = {
        id => $file->file_id
        ,title => $file->file_title
        ,scope => $file->scope
        ,parent => $file->parent ? $file->parent->file_id : undef
        ,comment => $file->file_comment
        ,is_same_user => $file->get_column('creator_user') eq $c->user->user_id
        ,is_same_location => $file->get_column('owner') eq $c->user->get_column('primary_location')
    };
    
    my $json = new JSON;
    $c->stash->{file_json} = $json->encode( $data ); 
}


sub save : Local {
    my ( $self, $c ) = @_;

    my $file = $self->file;
    return unless $c->must_write($file);

    my $action = 'save';
    # TODO: validation!
    if ($c->req->upload('file')) {
        $file = $self->reupload($c, $file);
        $action = 'reupload';
    }

    if (ref ($file) =~ /BST/) {
        $file->file_title($c->req->param('file_title'));
        $file->file_comment($c->req->param('file_comment'));
        $file->save();
    } else {
        # reupload failed
        $file = $self->file;
        $action = "error";
    }

    file_details($c, $action, $file);
}


sub saveall : Local {
    my ( $self, $c ) = @_;

    my $file = $self->file;
    return unless $c->must_write($file);

    foreach (qw(file_comment file_title)) {
        $file->$_( $c->req->param($_) ) 
    }

    if (exists  $BST::PackageToc::Types::TYPES{$file->package_toc_type}) {
        my $type = $BST::PackageToc::Types::TYPES{$file->package_toc_type};
        my $toc = $file->package_toc_data;

        my $meta_fields = { map {;
            $_->{name} => 1
            } @{ $type->{meta_fields} }
        };

        foreach ($c->req->param()) {
            next unless $meta_fields->{$_};
            $toc->{meta}->{$_} = $c->req->param( $_ );
        }
        $file->package_toc_data($toc);
    }

    $file->save();

    file_details($c, 'save', $file);
}



sub file_details {
    my $c = shift;
    my $action = shift;
    my $file = shift;
    my $parent = @_ ? shift : ($file->parent ? BST::FolderItem->load({ file_id => $file->parent }) : undef);

    $c->stash->{Result} = {
        action => $action,
        scope => $file->scope,
        file  => {
            id => $file->id,
            title => $file->file_title,
            comment => $file->file_comment
        }
    };
    
    if ($parent) {
        $c->stash->{Result}->{folder} = {
            title => $parent->title,
            id => $parent->file_id
        };
    }

    $c->package_check_update( $file );
    return $c->forward( $c->view('JSON') ) if ($c->req->param('ajax'));

    my $params = { file_id => $file->id  };
    unless ($action eq "error") {
        $params->{success} = $action;
    } else {
        $params->{error} = [&error->messages]->[0];
    }

    $c->response->redirect(
        $c->uri_for('edit', $params)
    );
}


=head2 put JSON data of TOC to the stash

=cut

sub view_toc : Private {
    my $self = shift;
    my $c = shift;
    my $package = shift;

    my $form = $self->formbuilder;
    $form->{id} = "toc_meta";
    $form->{stylesheet} = 1;
    $form->{javascript} = 0;
    $form->{submit} = 0; #"Save";

    my $type = $BST::PackageToc::Types::TYPES{$package->package_toc_type} || die "wrong type: " . $package->package_toc_type;
    my $toc = $package->package_toc_data;
    die if not ref $type;

    _init_meta_fields($c, $package, $toc, $type);

    my $json = new JSON;
    $c->stash->{column_fields_JSON} = $json->encode(
        $BST::PackageToc::Types::TYPES{$package->package_toc_type}->{column_fields}
    );
    $c->stash->{toc_table_JSON} = $json->encode(
        $package->package_toc_data->{table} || []
    );
}


sub _init_meta_fields {
    my ($c, $package, $toc, $type ) = @_;
    my $meta = $toc->{meta};

    my $meta_initialized = 0;
    $meta_initialized = 1 if (keys(%{$meta}) > 0);

    my $fields = [];
    my $values = {};
    foreach my $field ( @{$type->{meta_fields}} ) {
        my $name = $field->{name};

        $values->{$name} = $meta->{$name} if (exists $meta->{$name});
        push @$fields, $field;
        $meta->{$name} = $values->{$name} unless $meta_initialized;
    }

    $c->stash->{meta_fields} = $fields;
    $c->stash->{meta_values} = $values;

    unless ($meta_initialized) {
        $package->package_toc_data($toc);
        $package->save();
    }
}


sub download : Local {
    my ( $self, $c ) = @_;

    my $file = $self->file || return;

    return $c->error404() unless (-s $file->local_file_path);

    my $filename = $file->file_title . '.' . $file->file_extension;

    # for filenames with non-US-ASCII characters in them:
    # the following works well for IE 6 and IE 7, 
    # not well for FF.
    # see also:
    # http://moinmo.in/MoinMoinBugs/Non-ASCII%20attachment%20names%20corrupted%20on%20download
    # http://search.cpan.org/perldoc?URI::Escape
    use URI::Escape qw(uri_escape_utf8);
    $filename = uri_escape_utf8( $filename );

    $c->res->header('Content-Disposition', qq[attachment; filename="$filename"]);
    $c->serve_static_file($file->local_file_path);
}

sub check_upload : Local {
    my ( $self, $c, $upload ) = @_;
    my $json = new JSON;
    # check if some file was uploaded
    unless ($upload) {
		$c->response->body($json->encode({error => "No file to upload"})) ;
		return 0;
    }

    # check uploaded file size
    my $limit = BST::config('max_file_upload_size') || 5;
    if ($upload->size > $limit * 1048576) {
		$c->req->param('ajax') ? $c->response->body($json->encode({error => "File is too large. Max size is " . $limit . "M."})) : &error->file_is_too_large;
		return 0;
    }

    # check uploaded file extension
	unless (BST::File::is_allowed_file_to_upload($upload->filename)) {
		$c->req->param('ajax') ? $c->response->body($json->encode({error => "Sorry, you cannot upload a file of this type"})) : &error->wrong_file_type;
		return 0;
	}

    return 1;
}

sub upload : Local Form {
    my ( $self, $c ) = @_;

    my $form = $self->formbuilder;

    if ($c->req->param('ajax') || ($form->submitted && $form->validate)) {
        my $comment = $form->field('comment');
        my $title   = $form->field('title');
        my $pid     = $form->field('pid');
        my $upload  = $c->req->upload('file');

        return unless $self->check_upload( $c, $upload );

        my $level;

        if ($pid =~ m/^_(user|account|location)$/) {
            $level = $1;
            $pid = undef;
        } else {
            my $oFolder = $c->get_object_or_404('BST::FolderItem', { file_id => $pid } );
            return unless $c->must_write($oFolder);
            $level = $oFolder->scope;
        }

        my $oPackage;
        if ($c->req->param('package_id')) {
            $oPackage = BST::PackageToc->load( $c->req->param('package_id') );
            return unless $c->must_read($oPackage);
        }
        
        if ($c->req->param('ajax')) {
            $level = BST::Scope::USER;
            $title = $upload->filename;
            $title =~ s/^.*[\/\\]//;
        }

        my $fname = $upload->filename;
        my ($ext) = ($fname =~ /\.(\w+)$/);
        $title =~ s/\.$ext$//;
        my $fobj = BST::create('BST::File');

        $fobj->creator_user($c->user);
        $fobj->owner($c->user->location);
        $fobj->file_original_path($upload->basename);
        $fobj->file_extension($ext);
        $fobj->file_title($title);
        $fobj->file_comment($comment);
        $fobj->file_size($upload->size);
        $fobj->file_class('file');
        $fobj->parent($pid) if ($pid);
        $fobj->scope($level);

        my ($local_file_dir) = $fobj->local_file_path =~ /(.*\/)[^\/]+$/;
        mkpath($local_file_dir) unless -d $local_file_dir;

        unless ( $upload->link_to($fobj->local_file_path) || $upload->copy_to($fobj->local_file_path) ) {
            die( sprintf "Failed to copy '%s' to '%s': %s", $fname,  $fobj->local_file_path, $!);
        }
        $fobj->set_page_count();
        $fobj->save();
        
        if ($oPackage) {
            $oPackage->add_item($fobj);
            $oPackage->save();
            $c->package_check_update( $oPackage );
        }

        
        if ($c->req->param('ajax')) {
            my $res = {
                file => {
                    title => $fobj->file_title,
                    id => $fobj->file_id,
                    scope => $fobj->scope
                }
            };

            if ($oPackage) {
                $res->{package} = {
                    title => $oPackage->file_title,
                    id => $oPackage->package_id
                };

                my $toc_row = $oPackage->find_toc_item($fobj);
                if (defined $toc_row) {
                    $res->{row_id} = $toc_row;

                    my $fields;
                    if ($oPackage->package_toc_type) {
                        $fields = $BST::PackageToc::Types::TYPES{$oPackage->package_toc_type}->{column_fields};
                    }                        
                    $res->{row} = $c->_json_toc_row( $oPackage->get_toc_row($toc_row), $fields ) ;
                }
            }
            
            my $json = new JSON;
            return $c->response->body( $json->encode($res) );
        }

        if ($pid or $level) {
            return $c->response->redirect($pid ?
                $c->uri_for('list', { id => $pid, success => $fobj->file_id }) : 
                $c->uri_for('list', { scope => $level, success => $fobj->file_id })
            );
        }
    }
    
    my $file;
    my $scope = $c->req->param('scope');
    my $pid = $c->req->param('pid');
    if ($pid && !$form->submitted) {
        $file = BST::File->load($pid);
        $scope = $file->scope;
        $form->field(
            name => 'pid',
            value => $pid
        );
    }

    if ($c->req->param('scope')) {
        $form->field(
            name => 'pid',
            value => '_' . $c->req->param('scope')
        );
    } elsif ($c->req->param('pid')) {
        $form->field(
            name => 'pid',
            value => $c->req->param('pid')
        );
    } else {
        $form->field(
            name => 'pid',
            type => 'select',
            options => [ map {; [ $_->{id}, $_->{path} ] } $c->user->get_all_folders ]
        );
    }

    _fill_path($c, $file, $file ? undef : $c->req->param("scope") || BST::Scope::ALL );
}


sub reupload : Local {
    my ( $self, $c ) = @_;
    my $old_file = $_[2];

    my $upload  = $c->req->upload('file');
    return unless $self->check_upload( $c, $upload );

    my $fobj = $self->create_file_copy($c, $old_file);
    my $fname = $upload->filename;
    my ($ext) = ($fname =~ /\.(\w+)$/);

    $fobj->file_original_path($upload->basename);
    $fobj->file_extension($ext);

    $fobj->file_size($upload->size);

    unless ( $upload->link_to($fobj->local_file_path) || $upload->copy_to($fobj->local_file_path) ) {
        die( sprintf "Failed to copy '%s' to '%s': %s", $fname,  $fobj->local_file_path, $!);
    }
    $fobj->set_page_count();
    $fobj->save();

    $old_file->replaced_by_doc($fobj->file_id);
    $old_file->replaced_by_date(time);
    $old_file->replaced_by_user($c->user->user_id);
    $old_file->save();

    return $fobj;
}

sub create_file_copy : Local {
    my $self = shift;
    my $c = shift;
    my $old_file = shift;

    my $fobj = BST::create('BST::File');
    $fobj->creator_user($c->user);
    $fobj->owner($c->user->primary_location);
    $fobj->file_original_path($old_file->file_original_path);
    $fobj->file_extension($old_file->file_extension);
    $fobj->file_format_type($old_file->file_format_type);

    $fobj->is_public(1);
    $fobj->file_title($old_file->file_title);
    $fobj->file_comment($old_file->file_comment);
    $fobj->file_class($old_file->file_class);
    $fobj->scope($old_file->scope);
    $fobj->parent($old_file->parent);

    return $fobj;
}



=head1 AUTHOR

Buildsite

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
