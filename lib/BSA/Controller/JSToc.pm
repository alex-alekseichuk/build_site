package BSA::Controller::JSToc;

use strict;
use warnings;
use base 'BSA::Controller';
#use base 'Catalyst::Controller::FormBuilder';
use Encode;
use JSON;
use Data::Dumper;

use Image::Magick::Thumbnail::PDF 'create_thumbnail';

use BST qw(schema);
use BST::PackageToc::Types;
use BST::PDF;
use POSIX qw(ceil);

use vars qw($IS_ITEMS_ORDER_CHANGED);

use constant FOR_WRITE => 1;
use constant FOR_READ => 0;

undef &BST::PackageToc::event_items_order_changed;
*BST::PackageToc::event_items_order_changed = sub { 
    my $self = shift;
    $IS_ITEMS_ORDER_CHANGED = shift;
};


=head1

get package id as http parameter, load package and check permisions on it

=cut

sub _get_package() {
    my $self = shift;
    my $c = shift;
    my $for_write = shift || FOR_READ;
    my $locking = shift || '';

    # get package id as http parameter
    my $id = $c->request->params->{id} || $c->request->params->{package_id};
    if (! $id) {
        #die "supply id= param (package id)";
        $c->error404;
        return;
    }

    my $package = BST::Package->load( $id, undef, $locking );
    if ( (! $package) ) {
        #die "can't find such package ($id)";
        $c->error404;
        return;
    }

    # access rights control
    unless ($c->must_read($package))
    {
        $c->error403;
        return;
    }
    if ($for_write) {
        unless ($c->must_write($package))
        {
            $c->error403;
            return;
        }
    }

    return ($id, $package);
}


=head1

init meta fields

=cut

sub _init_meta_fields {
    my ( $form, $package, $toc, $type ) = @_;
    my $meta = $toc->{meta};

    $form->field( type=>'hidden', name => 'package_id', value => $package->package_id );
    my $meta_initialized = 0;
    $meta_initialized = 1 if (keys(%{$meta}) > 0);

    foreach my $field ( @{$type->{meta_fields}} ) {
    my $name = $field->{name};
        $field->{value} = $meta->{$name} if (exists $meta->{$name});
        $form->field(%$field);
    }

    unless ($meta_initialized) {
        foreach my $field ( @{$type->{meta_fields}} ) {
            $meta->{$field->{name}} = $form->field($field->{name});
        }
        $package->package_toc_data($toc);
        $package->save;
    }

}


=head1

shows TOC edit area

=cut

sub toc : Local Form {
    my ( $self, $c ) = @_;

    my $form = $self->formbuilder;
    $form->{id} = "toc_meta";
    $form->{stylesheet} = 1;
    $form->{javascript} = 0;
    $form->{submit} = 0; #"Save";

    # get package from params
    my ($package_id, $package) = $self->_get_package($c);
    return if not $package_id;

    if ($package->package_toc_type) {
        my $type = $BST::PackageToc::Types::TYPES{$package->package_toc_type};
        my $toc = $package->package_toc_data;

        _init_meta_fields($form, $package, $toc, $type);

        my $json = new JSON;
        $c->stash->{column_fields_JSON} = $json->encode(
            $BST::PackageToc::Types::TYPES{$package->package_toc_type}->{column_fields}
            );
        $c->stash->{toc_table_JSON} = $json->encode(
            $package->package_toc_data->{table} || []
            );
    }

    my @types = keys %BST::PackageToc::Types::TYPES;
    $c->stash->{types} = \@types;
    $c->stash->{package} = $package;

    BSA::Controller::Folders::_fill_path($c, $package);
}


=head1

saves TOC meta data

=cut

sub toc_meta_commit : Local Form {
    my ( $self, $c ) = @_;

    my $form = $self->formbuilder;
    $form->{id} = "toc_meta";
    $form->{stylesheet} = 1;
    $form->{javascript} = 0;
    $form->{submit} = 0; #"Save";

    # get package from params
    my ($package_id, $package) = $self->_get_package($c, FOR_WRITE);
    return if not $package_id;

    if ($package->package_toc_type) {
        my $type = $BST::PackageToc::Types::TYPES{$package->package_toc_type};
        my $toc = $package->package_toc_data;

        _init_meta_fields($form, $package, $toc, $type);

        #if ($form->submitted && $form->validate) {
        if ($form->submitted) {
            foreach my $field ( @{$type->{meta_fields}} ) {
                $toc->{meta}->{$field->{name}} = $form->field($field->{name});
            }
            $package->package_toc_data($toc);
            $package->save;
        }
    }

    $c->stash->{"Result"} = {};
    $c->forward( $c->view('JSON') );
}


=head1

switches template for TOC

=cut

sub switch_toc : Local {
    my ( $self, $c ) = @_;

    # get package from params
    my ($package_id, $package) = $self->_get_package($c, FOR_WRITE);
    unless ($package_id) {
        $c->error404;
        return;
    }

    my $type = $c->request->params->{template_name};
    unless (exists $BST::PackageToc::Types::TYPES{$type}) {
        $type = "";
    }

    # check if this TOC type is disabled for this user
    if ($type
        && $c->user->settings->list->{disable_leed_submittals} eq 'y'
        && 'leed' eq $BST::PackageToc::Types::TYPES{$type}->{group}) {

        $c->error403;
        return;
    }

    if ( not $package->package_toc_type
         or $package->package_toc_type ne $type) {
        $package->init_toc($type, $c->user);
    }

    $c->package_update_json();
    my $params = {file_id => $package_id};
    $params->{message} = "items_order_changed" if $IS_ITEMS_ORDER_CHANGED;
    $c->response->redirect($c->uri_for('/folders/edit', $params));
}

=head1

save toc row data (not items)

=cut

sub save_toc_row : Local {
    my($self, $c) = @_;

    # get package from params
    my ($package_id, $package) = $self->_get_package($c, FOR_WRITE);
    return if not $package_id;

    my $row_id = $c->request->params->{row_id};
    my $json_data = $c->request->params->{row};

    # prepare $json_data for from_json()
    $json_data = encode_utf8( $json_data );
    my $row_data = from_json $json_data, { utf8=>1 };

    my $leed_values = $package->toc_row_change( $row_id, $row_data ) || {};
    $package->save;

    $c->stash->{"Result"} = {
        code => "ok"
        , leed_values => $leed_values
    };
    $c->forward( $c->view('JSON') );
}


=head1

move toc row item to another row or to another place in the same row

=cut

sub move_toc_item : Local {
    my($self, $c) = @_;

    # get package from params
    my ($package_id, $package) = $self->_get_package($c, FOR_WRITE);
    return if not $package_id;

    my $i_row = $c->request->params->{row_id}; # index of row in the toc table
    my $i_item = $c->request->params->{item_id}; # index of item in the row in the toc table or -1 if we need to remove whole row
    my $i_dest_row = $c->request->params->{dest_row_id}; # index of item in the row in the toc table or -1 if we need to remove whole row
    my $i_before_item = $c->request->params->{before_item_id}; # index of item in the row in the toc table or -1 if we need to remove whole row

    my $res = "error";
    $res = "ok" if ($package->move_toc_item($i_row, $i_item, $i_dest_row, $i_before_item));
    $c->stash->{"Result"} = $res;
    $c->forward( $c->view('JSON') );
}

sub remove_toc_item : Local {
    my($self, $c) = @_;

    # get package from params
    my ($package_id, $package) = $self->_get_package($c, FOR_WRITE);
    return if not $package_id;

    my $i_row = $c->request->params->{row_id}; # index of row in the toc table
    my $i_item = $c->request->params->{item_id}; # index of item in the row in the toc table or -1 if we need to remove whole row

    my $res = "error";
    $res = "ok" if ($package->remove_toc_item($i_row, $i_item));
    $c->stash->{"Result"} = $res;
    $c->forward( $c->view('JSON') );
}

sub remove_toc_row : Local {
    my($self, $c) = @_;

    # get package from params
    my ($package_id, $package) = $self->_get_package($c, FOR_WRITE);
    return if not $package_id;

    my $i_row = $c->request->params->{row_id}; # index of row in the toc table

    my $res = "error";
    $res = "ok" if ($package->remove_toc_row($i_row));
    $c->stash->{"Result"} = $res;
    $c->forward( $c->view('JSON') );
}


=head1

insert blank toc row

=cut

sub insert_toc_row : Local {
    my($self, $c) = @_;

    # get package from params
    my ($package_id, $package) = $self->_get_package($c, FOR_WRITE);
    return if not $package_id;

    my $i_row = $c->request->params->{row_id}; # index of row in the toc table where we should insert new one blank row before

    my $res = "error";
    $res = "ok" if $package->insert_toc_row($i_row);
    $c->stash->{"Result"} = $res;
    $c->forward( $c->view('JSON') );
}

sub move_toc_row : Local {
    my($self, $c) = @_;

    # get package from params
    my ($package_id, $package) = $self->_get_package($c, FOR_WRITE);
    return if not $package_id;

    my $i_row = $c->request->params->{row_id}; # index of row in the toc table to move
    my $i_before_row = $c->request->params->{before_row_id}; # index of row in the toc table to move before

    my $res = "error";
    $res = "ok" if $package->move_toc_row($i_row, $i_before_row);
    $c->stash->{"Result"} = $res;
    $c->forward( $c->view('JSON') );
}

=head1

generate toc html,pdf and thumb. to files on disk, then output pdf

=cut

sub toc_pdf : Local {
    my($self, $c) = @_;

    # get package id as http parameter
    my ($id, $package) = $self->_get_package($c);
    return if not $id;

    my $user = $c->user;
    if ($package->generate_toc_pdf($user)) {
        # pass the file to the user
        my $f = $package->path_toc_pdf;
        if (-f $f) {
            $c->res->header( 'Content-disposition' => 'attachment; filename="' . $package->toc_item_label . '.pdf"' );
            $c->serve_static_file( $f );
        } else {
            die "no PDF file";
        }
    } else {
        # nothing to return. For example, if the package has no TOC.
        $c->error404;
    }

}


=head1

generate toc html,pdf and thumb. to files on disk, then output thumb.

=cut

sub toc_thumb : Local {
    my($self, $c) = @_;

    # get package from params
    my ($id, $package) = $self->_get_package($c);
    return if not $id;

    my $user = $c->user;
    if ($package->generate_toc_pdf($user)) {
        return $c->serve_static_file($package->path_toc_thumb) if -e $package->path_toc_thumb;
    }
    $c->res->status(404);
    $c->res->body('NOT FOUND');
    $c->detach();
}


sub add_toc_item : Local {
    my($self, $c) = @_;

    my $package_id;
    my $package;
    my @i_rows = ();

    # wrap it into transaction
    eval {
        &schema->txn_do(
            sub {
                # get package from params
                ($package_id, $package) = $self->_get_package($c, FOR_WRITE, 'update');
                return if not $package_id;

                my $i_row  = $c->req->param('row_id');  # index of row in the toc table
                my $i_item = $c->req->param('item_id'); # id of item: document_id, file_id
                my $type   = $c->req->param('type');    # type: "document" or "file"

                my $item;

                $item = BST::Document->load( $i_item ) if ($type eq 'document');
                $item = BST::FolderItem->load( $i_item ) if ($type eq 'file');

                unless ($item) {
                    $c->stash->{"Result"} = "error";
                    $c->stash->{"Error"} = "Can't load " . $type . " #" . $i_item;
                    $c->forward( $c->view('JSON') );
                }

                @i_rows = $package->add_item( $item, $i_row );
                if (@i_rows) {
                    $package->save();
                }
            }
        );
    };

    if ($@) {
        $c->stash->{"Result"} = { "code" => "error" };
    } elsif (@i_rows) {
        $c->stash->{"Result"} = {
            "code" => "ok"
            ,"rows" => $package->toc_rows(\@i_rows)
        };
    } else { # $res == 0
        $c->stash->{"Result"} = { "code" => "exist" };
    }
    $c->forward( $c->view('JSON') );
}


=head2 product_autocomplete used to get list of product items as result of product autocomplete in TOC editor

=cut

sub product_autocomplete : Local {
    my($self, $c) = @_;

    my $product_name = $c->req->param('q');
    my $count = $c->req->param('limit') || 20;

    my @json_products = ();

    if ($product_name) {
        my $products = BST::Product->autocomplete_search($product_name, $count);
        if ((! $products) || 0 == $products->count) {
            $products = BST::Product->autocomplete_search($product_name, $count, 'or' ) 
        }
        if ($products) {
            my $pr;
            while (($pr = $products->next)) {
                push @json_products, {
                    id => $pr->product_id,
                    title => $pr->product_name,
                    category => $pr->category->category_title,
                    category_id => $pr->category->category_id,
                    manufacturer => $pr->manufacturer->name
                };
            }
        }
    }

    $c->stash->{"Result"} = \@json_products;
    $c->forward( $c->view('JSON') );
}

1;
