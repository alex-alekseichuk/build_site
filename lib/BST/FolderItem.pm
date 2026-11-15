package BST::FolderItem;

use strict;
use warnings;

use Params::Validate qw(:all);
use IO::File;
use Carp;

use BST;

use Data::Dumper;
use BST::Folder;
use BST::File;
use BST::Package;
use BST::Scope;


use base qw(BST::Core BST::Schema::File);
__PACKAGE__->table('file');


=head1 DESCRIPTION
    Base class for 3 files classes File, Folder and Package
    It's abstract. We should use its children.
=cut


__PACKAGE__->belongs_to(
  "parent",
  "BST::Folder",
  { file_id => "parent" },
);
__PACKAGE__->belongs_to(
  "owner",
  "BST::Location",
  { account_location_id => "owner" },
);
__PACKAGE__->belongs_to(
  "creator_user",
  "BST::User",
  { user_id => "creator_user" },
);


sub create {
    my $class = shift;
    my $columns = shift || {}; # optional

    $columns->{file_original_path} = "" if (! exists($columns->{file_original_path}));
    $columns->{file_title} = "" if (! exists($columns->{file_title}));
    $columns->{scope} = BST::Scope::HIDDEN if (! exists($columns->{scope}));

    return $class->next::method($columns);
}


sub inflate_result {
    my $class = shift;
    my ($source, $me, $prefetch) = @_;

    my $obj = $class->next::method(@_);

    if ( $me->{file_class} eq 'archive' ) {
        bless $obj, 'BST::PackageToc';
    } elsif ( $me->{file_class} eq 'folder' ) {
        bless $obj, 'BST::Folder';
    } else {
        bless $obj, 'BST::File';
    }

    return $obj;
}


# calculates the actual file path in the filesystem storage
# NOTE: this is a private method. application developer need no to know file path.
sub local_file_path {
    my $self = shift;
    #                                                    $self->owner->account_location_id
    return BST::config('account_locations_path') . '/' . $self->get_column('owner') . '/account_private_files/' . $self->file_id . "." . $self->file_extension;
}

sub title {
    my $self = shift;
    my $name = $self->file_title;
    $name = "Unknown" unless ($name);
    return $name;
}

sub comments {
    my $self = shift;
    if ($self->file_comment) {
        return $self->file_comment;
    } else {
        return $self->title;
    }
}

sub file_send_name {
    my $self = shift;
    return $self->title() . "." . $self->file_extension;
}

sub download_url {
    my $self = shift;
    return "/folders/download?file_id=" . $self->file_id;
}

# returns dirty selfcontents
sub contents {
    my $self = shift;
    my $res = undef;

    my $f = new IO::File $self->local_file_path, "r";
    if (defined $f) {
        local $/;
        $res = <$f>;
        undef $f;
    }

    return $res;
}

sub delete {
    my $self = shift;
    my $user = shift;

    $self->is_deleted(1);
    $self->deleted_by_user($user->user_id) if ref $user;
    $self->deleted_date(time);

    $self->save();
}


sub can_read {
    my $self = shift;
    my $user = shift;

    return 1 if $user->is_bs_admin();
    return 1 if BST::Scope->is_user($self->scope) && $self->get_column('creator_user') eq $user->user_id;
    return 1 if BST::Scope->is_location($self->scope) && $self->get_column('owner') eq $user->get_column("primary_location");
    return 1 if BST::Scope->is_account($self->scope) && $self->owner->get_column('account_id') eq $user->account->account_id;
    
    return 1 if BST::Scope->is_hidden($self->scope) && $self->owner->account_location_id eq $user->get_column('primary_location');
    
    return 0;
}

sub can_write {
    my $self = shift;
    my $user = shift;

    return 1 if $user->is_bs_admin();    
    return $self->can_read($user) unless ( BST::Scope->is_account($self->scope) );
    return $user->is_account_admin() ? 1 : 0;
}


=head1 get_default_search_filter - static class method

Returns default params for FolderItem search.
Add parameters to the function to re-define defaults
    
=cut

sub get_default_search_filter {
    my $pkg = shift;
    my %h = @_ ? @_ : ();
    my $res = {
        file_class => ["file", "archive", "folder"],
        scope => { "!=" , BST::Scope::HIDDEN },
        is_deleted => ['false', undef],
        replaced_by_doc => ['', undef]
    };

    $res->{$_} = $h{$_} for keys %h;

    return $res;
}


=head1 get_scope_search_filter - static class method

returns filter params for FolderItem search for given scope and user
    
=cut

sub get_scope_search_filter {
    my $pkg = shift;
    my $scope = shift || BST::Scope::USER;
    my $user = shift;

    return { creator_user => $user->user_id } if (BST::Scope->is_user($scope));
    return { owner => $user->location->account_location_id } if (BST::Scope->is_location($scope));
    if (BST::Scope->is_account($scope)) {
        my @locations = $user->location->account->locations;
        return  { owner => [ map $_->account_location_id, @locations ] };
    }
    return {};
}


# create a copy of this file/folder/package:

sub clone {
    my $self = shift;
    my $user = shift;
    my $override = shift || {};
    
    my ($columns, $type, $clone);
        
    $columns = { $self->get_columns(), %$override };
        
    delete $columns->{file_id};
        
    if ($user) {
        $columns->{creator_user} = $user->id;
        $columns->{owner}        = $user->get_column('primary_location');
    }
    
    $clone = 
        $columns->{file_class} eq 'archive'   ? BST::PackageToc->create($columns) :
        $columns->{file_class} eq 'folder'    ? BST::Folder->create($columns) :
        BST::File->create($columns);      
    
    $clone->save;
    return $clone;
}


sub is_folder {
    my $self = shift;
    return $self->file_class eq 'folder';
}

sub is_package {
    my $self = shift;
    return $self->file_class eq 'archive';
}

sub is_file {
    my $self = shift;
    return $self->file_class eq 'file';
}

1;
