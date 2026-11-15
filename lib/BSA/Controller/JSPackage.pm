package BSA::Controller::JSPackage;

use strict;
use warnings; 
use BSA::Controller;
use base 'BSA::Controller';
#use base 'Catalyst::Controller::FormBuilder';
use JSON;
use Data::Dumper;
use lib qw(../../);

use BST::Scope;
use BST::Package;

use constant E_404 => 'Object not found';
use constant E_403 => 'Access denied';
use constant E_500 => 'Wrong parameters list';


=head1 NAME

BSA::Controller::JSPackage - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index 

=cut


=item blank method

Creates a blank package and sets it as a current

=cut
sub blank : Local {
    my ( $self, $c ) = @_;
    my $pkg = $c->create_blank_package($c->req->param('type'));

    if ($c->req->param('ajax')) {
            $c->package_action;
    } else {
        my ($goto) = $ENV{HTTP_REFERER} =~ m/http:\/\/.*?(\/.*)/;
        $c->response->redirect($c->uri_for('/folders/edit', { file_id => $pkg->file_id, return => $goto } ));
    }
}


=item make_current method

Sets the package as a current or create blank one

=cut

sub make_current : Local {
    my ( $self, $c ) = @_;

    $c->set_current_package($c->req->param('package_id'));

    $c->package_action();
}


=item current - method

Returns the current package

=cut

sub current : Local {
    my ($self, $c) = @_;

    delete $c->req->params->{package_id};
    $c->package_action();
}


=item show - method

Returns the current package

=cut

sub show : Local {
    my ($self, $c) = @_;
    $c->package_action();
}



=item add_item - method

Adds the item to the package
Parameters:
    [package_id] - package_id (if omitted, the item will be added to the current package)
    file_id || document_id || pkg_id - item id

=cut

sub add_item : Local {
    my ($self, $c) = @_;

    my ($type, $id);    
    $type = 'BST::FolderItem' if ($id = $c->req->param('pkg_id'));
    $type = 'BST::FolderItem' if !$id && ($id = $c->req->param('file_id'));
    $type = 'BST::Document' if !$id && ($id = $c->req->param('document_id'));
    
    return $c->package_action(E_500) unless $type && $id;

    my $package = $c->package(1) || return;
    my $obj = BST::load($type, $id);

    return $c->package_action(E_404) unless $obj;
    return $c->package_action(E_403) unless $c->user->is_bs_admin() || $obj->can_read($c->user);

    $package->add_item($obj);
    $package->save();

    $c->package_action();
}



=item add_items - method

Adds the items to the package
Parameters:
    [package_id] - package_id (if omitted, the item will be added to the current package)
    file_ids - items ids

=cut

sub add_items : Local {
    my ($self, $c) = @_;

	my $ids = decode_json $c->req->param('file_ids');

	return $c->package_action(E_500) unless $ids;


	my $package = $c->package(1) || return;

	my @objs;
	foreach my $id (@$ids) {
	    my $obj = BST::load('BST::FolderItem', $id);
		return $c->package_action(E_404) unless $obj;
	    return $c->package_action(E_403) unless $c->user->is_bs_admin() || $obj->can_read($c->user);
		push @objs, $obj;
	}

	$package->add_item($_) foreach (@objs);

	$package->save();

    $c->package_action();
}



=item remove_item method

Removes the item from the current package
Parameters:
    file_id || document_id || pkg_id - item id
    or package_item_id - id of PackageItem object
    [package_id] - package_id (if omitted, the item will be removed from the current package)

=cut

sub remove_item : Local {
    my($self, $c) = @_;
    my $package = $c->package() || return;

    my $id;
    if ($id = $c->req->param('pkg_id')) {
        my $pkg = BST::FolderItem->load( $id );
        return $c->package_action(E_404) unless $pkg;
        $package->remove($pkg);
    } elsif ($id = $c->req->param('package_item_id')) {
        my $pi = BST::PackageItem->load( $id );
        return $c->package_action(E_404) unless $pi;
        $package->remove($pi);
    } else {
        $id = $c->req->param('file_id') || $c->req->param('document_id');
        return $c->package_action(E_500) unless $id;

        my $pi = $package->find_item($id);
        return $c->package_action(E_404) unless $pi;

        $package->remove($pi);
    }
    $package->save();

    return $c->response->redirect( $c->uri_for("/folders/edit", { file_id => $package->file_id }) ) if ($c->req->param('return'));
    $c->package_action();
}


=item remove_product method

Removes documents of the specified product from the current package
Parameters:
    product_id - id of product
    [package_id] - package_id (if omitted, the documents will be removed from the current package)

=cut

sub remove_product : Local {
    my($self, $c) = @_;
    my $package = $c->package() || return;

    $package->remove_product(
        $c->req->param('product_id')
    );

    $c->package_action();
}




=item clear

Removes all items from the current package
Parameters:
    [package_id] - package_id (if omitted, the current package will be cleared)

=cut
sub clear : Local {
    my ( $self, $c ) = @_;
    my $package = $c->package() || return;

    $package->clear();
    $c->package_action();
}



=item list

Returns all packages, available to switch to

=cut
sub list : Local {
    my ( $self, $c ) = @_;
    my $filter = BST::FolderItem->get_default_search_filter();
    $filter->{owner} = $c->user->primary_location->account_location_id;

    my @pkgs = BST::Package->search( $filter );


    @pkgs = grep {$_->scope ne BST::Scope::USER || $_->creator_user->user_id eq $c->user->user_id } @pkgs;

    $c->stash->{Result} = {
        items => [map {;
            {
                id => $_->file_id,
                title => $_->display_pathname,
                type => $_->file_class,
            }
        } sort {$b->display_pathname cmp $a->display_pathname} @pkgs]
    };

    $c->forward( $c->view('JSON') );
}


sub set_items_order : Local {
    my ( $self, $c) = @_;
    my $package = $c->package() || return;
    my @item_ids = $c->req->param();

    foreach (@item_ids) {
        next if $_ eq 'package_id';
        my $oItem = BST::PackageItem->load( $_ );
        die "no such package item: $_" if not $oItem;
        next unless $oItem->package->id eq $package->id;

        my $pos = $c->req->param($_);
        next unless $pos =~ m/^\d+$/;
        next if $oItem->position == $pos;

        $oItem->position($pos);
        $oItem->save();
    }

    $c->stash->{Result} = { items => [
        map {;
            { id => $_->package_item_id, position => $_->position }
        } $package->items
    ]};

    $package->clear_items_cache;

    $c->package_update_json();
    $c->forward( $c->view('JSON') );
}

sub folders : Local {
    my($self, $c) = @_;

    my $scopes = [BST::Scope::USER, BST::Scope::LOCATION];
    push @$scopes, BST::Scope::ACCOUNT if $c->user->is_bs_admin() || $c->user->is_account_admin();
    my @folders = $c->user->get_all_folders($scopes);

    my $result = {
        n => (1 + $#folders),
        items => \@folders
    };
    $c->stash->{"Result"} = $result;

#    $c->stash->{"Result"} = [];
    $c->forward( $c->view('JSON') );

}

sub save : Local {
    my($self, $c) = @_;

    if (! $c->current_package) {
        my $package = BST::Package->create();
        $c->session->{package_id} = $package->package_id;
    }

    my $title = $c->request->params->{cp_title};
    my $comment = $c->request->params->{cp_comment};
    my $folder_id = $c->request->params->{cp_folder};
    my $scope;
    if ($folder_id eq "_" . BST::Scope::ACCOUNT) {
        $folder_id = "";
        $scope = BST::Scope::ACCOUNT;
    } elsif ($folder_id eq "_" . BST::Scope::LOCATION) {
        $folder_id = "";
        $scope = BST::Scope::LOCATION;
    } elsif ($folder_id eq "_" . BST::Scope::USER) {
        $folder_id = "";
        $scope = BST::Scope::USER;
    } else {
        $scope = BST::Scope::HIDDEN;
        if ($folder_id) {
            my $folder = BST::Folder->load( { file_id => $folder_id } );
            if ($folder) {
                $scope = $folder->scope;
            }
        }
    }

    my $package = $c->current_package->save_as($c->user, $scope, $folder_id, $title, $comment);
    $c->package_action();
#    $c->session->{package_id} = $package->id if ($package);

#    $c->stash->{"Result"} = {};
#    $c->forward( $c->view('JSON') );
}


# /jspackage/add_package_items?source_id=private60489&target_id=private75749&q=0.47237675635520426
# returns the items of the source package
# that we a going to add to the target package
# it's for confiramtion dialog as package_to_package adding process
sub add_package_items : Local {
    my($self, $c) = @_;

    # get source package id and destination package id
    my $source_id = $c->request->params->{source_id};
    my $target_id = $c->request->params->{target_id};

    if (!$source_id || !$target_id) {
        $c->stash->{"Result"} = {error=>1};
        $c->forward( $c->view('JSON') );
        return;
    }

    my $source = BST::Package->load($source_id);
    my $target = BST::Package->load($target_id);

    if (!$source || !$target) {
        $c->stash->{"Result"} = {error=>2};
        $c->forward( $c->view('JSON') );
        return;
    }

    my @package_items = $source->items;

    my @items = map {
        title => $_->is_file ? $_->file->title : $_->document->short_title
        ,download_url => $_->is_file ? $_->file->download_url : $_->document->download_url
        ,filesize_kb => $_->is_file ? $_->file->filesize_kb : $_->document->filesize_kb
        ,page_count => $_->is_file ? $_->file->file_page_count : $_->document->page_count
    }, @package_items;

    $c->stash->{"Result"} = {
        package_title => $source->file_title . ($source->file_comment ? ' - ' . $source->file_comment : '')
        ,items => \@items
    };
    $c->forward( $c->view('JSON') );
}


=head1 AUTHOR

Nikolai Liohenki <kalyansky@gmail.com>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
