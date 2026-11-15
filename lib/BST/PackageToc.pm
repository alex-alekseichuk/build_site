package BST::PackageToc;

use strict;
use warnings;
use Carp qw(croak);
use Data::Dumper;

use Image::Magick;
use Image::Magick::Thumbnail::PDF 'create_thumbnail';
use File::Basename;

use BST::PackageToc::Types;
use BST::PDF;
use Digest::MD5 qw(md5_hex);
use HTML::Entities;
use Encode qw(encode_utf8 decode_utf8 decode);

use BST qw(schema);

use Params::Validate qw(:all);
use POSIX qw(ceil);

use base qw(BST::Package);
__PACKAGE__->table('file');

__PACKAGE__->inflate_column(
    package_toc_data  => {
        inflate => \&BST::PackageToc::_package_toc_data_inflate,
        deflate => \&BST::PackageToc::_package_toc_data_deflate,
    },
);

sub event_items_order_changed {}

sub _package_toc_data_inflate {
    my $str = shift;
    return unless $str;
    my $self = shift;

    my $VAR1;

    my $needRestore = $str =~ m/<br(\s*\/)?/is;
    if ($needRestore) {
        $str =~ s/<br(\s*\/)?>//gis;
        $self->logger->log({ name => 'package', message => sprintf("%s: broken TOC detected", $self->file_id) });
    }

    # if we stop doing utf8::upgrade for TOC strings, we may try
    # adding "use utf8;" into the begining of the $str here. This may
    # help it recognize the unicode characters in the data correctly.
    eval($str);
    if ($@) { 
        $self->logger->log({ name => 'package', message => sprintf("%s: cannot deserialize TOC\n%s\n\n", $self->file_id, $str) });
        $VAR1 = undef; 
    } else {
        $self->logger->log({ name => 'package', message => sprintf("%s: restored successfully", $self->file_id) }) if $needRestore;
    }

    if ("HASH" ne ref $VAR1 || !scalar keys %$VAR1) {
        if ($self->package_toc_type && $self->creator_user) {
            $self->logger->log({ name => 'package', message => sprintf("%s: re-initializing TOC", $self->file_id) });

            my $toc = $self->init_empty_toc();
            my $oUser = BST::User->load({ user_id => $self->creator_user->user_id });

            $self->init_toc_to_str( \$toc );
            init_toc_meta( \$toc, $self->package_toc_type, $oUser );
            _init_toc_table_items( $toc );

            $VAR1 = $toc;
        } else {
            $VAR1 = undef;
        }
    }

    toc_data_utf8_upgrade( $VAR1 );

    return $VAR1;
}


sub _package_toc_data_deflate {
    my $data = $_[0];

    $data->{last_change} = time;

    toc_data_utf8_upgrade( $data );
    $Data::Dumper::Pad = '';
    my $str = Dumper($data);

    return $str;
}


sub toc_data_utf8_upgrade {
    my $toc_data = $_[0];

    my ($table,$row,$items,$item);
    $table = $toc_data->{table};
    foreach $row ( @$table ) {
        foreach my $k ( keys %$row ) {
            if ($row->{$k} and $k ne 'items') {
                utf8::upgrade( $row->{$k} );
            }
        }
        $items = $row->{items};
        foreach $item (@$items) {
            utf8::upgrade( $item->{title} )
                if $item->{title};
            utf8::upgrade( $item->{shorttitle} )
                if $item->{shorttitle};
        }
    }
    # XXX: should we also upgrade the meta field values?
}


sub _init_toc_table_item {
    my $product_submitted_id = shift;
    my $item = shift;

    if ($item->{type} eq 'document') {
        my $document = BST::Document->load($item->{id});
        if ($document) {

            $item->{shorttitle} = $document->short_title;
            $item->{title} = decode_product_name_input( $document->title(0) );

            $item->{page_count} = $document->derived_pagecount || 0;
            $item->{file_size} = sprintf("%.f", $document->file_size / 1024);
            # we do not need this, rigth?
            #$item->{comments} = $document->comments;
            $item->{doc_type} = $document->doc_type->dt_label;
            if ($document->product) {
                $item->{product_id} = $document->product->product_id;
                $item->{is_product_document} = 1;
            } else {
                $item->{product_id} = 0;
                $item->{is_product_document} = 0;
            }
            $item->{download_url} = $document->download_url;
            
        }
    }
    if ($item->{type} eq 'file') {
        my $file = BST::File->load($item->{id});
        if ($file) {
            $item->{title} = $file->title;
            $item->{page_count} = $file->page_count || 0;
            $item->{file_size} = sprintf("%.f", $file->file_size / 1024);
            $item->{comments} = $file->comments;
            $item->{is_product_document} = 0;
            $item->{product_id} = 0;
        }
    }
    $item->{title} = $item->{id} unless ($item->{title});
}


sub _init_toc_table_items {
    my $toc = shift;

    # fill title (& title, shorttitle, etc.) fields of the rows' items
    # why do we need this?
    foreach my $row (@{$toc->{table}}) {
        my $product_submitted_id = $row->{product_submitted_id};
        foreach my $item (@{$row->{items}}) {
            _init_toc_table_item($product_submitted_id, $item);
        }
    }
}

sub package_toc_extra {
    my $self = shift;

    my $toc = $self->package_toc_data;

    unless ($toc->{"extra"}) {
        $toc->{"extra"} = 1;
        foreach my $row (@{$toc->{table}}) {
            foreach my $item (@{$row->{items}}) {
                $item->{package_item_id} = 0;
                my $package_item = $self->find_item($item->{id});
                if ($package_item) {
                    $item->{package_item_id} = $package_item->package_item_id;
                }
            }
        }
    }

    return $toc
}


=head2 change package items position (order) by toc rows/items

=cut

sub _correct_package_items_order {
    my $self = shift;
    my $toc = shift || $self->package_toc_data;

    return unless $self->package_toc_type;
    return unless $toc;

    my $position = 1;
    my $is_order_changed = 0;

    # wrap it into transaction
    eval {
        &schema->txn_do(
            sub {
                foreach my $row (@{$toc->{table}}) {
                    foreach my $item (@{$row->{items}}) {
                        my $package_item = $self->find_item($item->{id});
                        if ($package_item) {
                            my $old_position = $package_item->position;
                            $package_item->position($position);
                            $is_order_changed = 1 if $old_position != $position;
                            $position++;
                            $package_item->save;
                        }
                    }
                }
           }
        );
    };

    $self->event_items_order_changed( $is_order_changed );
}


# decode product name input -- html entities, if any

sub decode_product_name_input($) {
    my $string = shift;
    return $string if not $string;
    my $res = $string;
    if ( $string =~ m/&([a-z]{2,5}|#x[\da-f]+|#\d+);/i ) {

        # there are products, whose name contain real UTF-8 characters (not latin1)
        # e.g.:
        #    LITHOCHROME® Chemstain Classic™
        # in addition to the well-known
        #    CHROMIX® ML Admixtures for Color-Conditioned® Concrete
        #
        # and this breaks for them:
        #$res = decode("iso-8859-1", decode_entities( $string ) ); 
        # so, we do this instead:
        $res = decode_entities( $string );
        utf8::upgrade( $res );
    }
    return $res;
}

sub _init_toc_row_data {
    my $row = shift;
    my $product_submitted = shift || '';
    my $product_submitted_id = shift || 0;
    my $manufacturer = shift || '';
    my $items = shift || [];
    
    $row->{'product_submitted'} = decode_product_name_input($product_submitted);
    $row->{'product_submitted_id'} = $product_submitted_id;
    $row->{'manufacturer'} = decode_product_name_input($manufacturer);
    $row->{'items'} = _decode_row_items($items);

    return $row;
}
sub _init_toc_row {
    my $product_submitted = shift || '';
    my $product_submitted_id = shift || 0;
    my $manufacturer = shift || '';
    my $items = shift || [];

    my $row = {};
    _init_toc_row_data(
        $row,
        $product_submitted,
        $product_submitted_id,
        $manufacturer,
        $items);
    return $row;
}

sub _decode_row_items {
    my $items = shift;
    for my $j (0..$#{$items}) {
        for my $key (keys %{$items->[$j]}) {
            my $val = $items->[$j]->{$key};
            $items->[$j]->{$key} = decode_product_name_input($val) if $val;
        }
    }
    return $items;
}


sub init_toc {
    my $self = shift;
    my $type_name = shift;
    my $current_user = shift;

    my $is_switch_plain_2_toc = $type_name && ! $self->package_toc_type;
    my $is_new_toc = $type_name && ($type_name ne $self->package_toc_type);

    $self->package_toc_type($type_name);
    unless ($self->package_toc_type)
    {
        $self->save;
        return;
    }

    # check for supported toc type
    return unless (exists $BST::PackageToc::Types::TYPES{$self->package_toc_type});

    # toc struct
    my $toc = $self->package_toc_data; # try to update existing toc

    my $create_new_toc = 0; # use existing toc by default
    if ($toc)
    {
        $create_new_toc = 1 unless ($toc->{meta} && $toc->{table});
        $self->check_toc_data() if $is_switch_plain_2_toc;
    } else {
        $create_new_toc = 1;
    }

    if ($create_new_toc) # if there is no existing correct toc
    {
        # create new toc
        $toc = $self->init_empty_toc();
    }

    init_toc_meta(\$toc, $type_name, $current_user);

    # create toc table for new toc only
    if ($create_new_toc) {
        $self->init_toc_to_str(\$toc);
    }

    # if there is some new toc (swith to some toc from plain or another toc)
    # then we need to initialize all leed_columns that are not exists yet
    if ($is_new_toc) {
        foreach my $row (@{$toc->{table}}) {
            $self->init_leed_columns($row, 0); # don't overwrite existed values
        }
    }

    _init_toc_table_items($toc);

    $self->package_toc_data($toc);
    $self->save();
}


sub init_empty_toc {
    return { meta => {}, table => [] };
}

sub init_toc_meta {
    my $toc = ${ +shift };
    my $type_name = shift;
    my $user = shift;

    my $type = $BST::PackageToc::Types::TYPES{$type_name};

    my $meta = $toc->{meta};
    foreach my $meta_field (@{$type->{meta_fields}}) {
        my $name = $meta_field->{name};
        unless ($meta->{$name}) {
            if ($meta_field->{default}) {
                $meta->{$name} = &{$meta_field->{default}}($user);
            } elsif ($meta_field->{value}) {
                $meta->{$name} = $meta_field->{value};
            }
        }
    }

}

sub init_toc_to_str {
    my $self = shift;
    my $toc = ${ +shift };

        # construct product-documents hash
        my $products = {};
        my $product_ids = [];
        foreach my $item ($self->items) {
            my $product = $item->product;
            if ($product) {
                unless ($products->{$product->product_id} ) {
                    $products->{ $product->product_id } = { items => [], product => $product };
                    push @$product_ids, $product->product_id;
                }
                push @{$products->{$product->product_id}->{items}}, $item;
            }
        }

        my $package_item_order = 0;

        # add product related documents
        foreach my $product_id (@$product_ids) {
            my $documents = [];
            foreach my $item2 (@{$products->{$product_id}->{items}}) {
                push @$documents, {type=>'document', id=>$item2->document->document_id};
                if ($item2->position != ++$package_item_order) {
                    $self->event_items_order_changed(1);
                }
                $item2->position($package_item_order);
                $item2->save;
            }
            my $product = $products->{$product_id}->{product};
            my $row = _init_toc_row(
                $product->product_name,
                $product->product_id,
                $product->manufacturer->name,
                $documents);
            push @{$toc->{table}}, $row;
            
        }

        # add non-product files and documents
        foreach my $item3 ($self->items) {
            unless ($item3->product) {
                my $row_item = {};

                if ($item3->file) {
                    $row_item = {type=>'file', id=>$item3->file->file_id};
                } else {
                    $row_item = {type=>'document', id=>$item3->document->document_id};
                }
                if ($item3->position != ++$package_item_order) {
                    $self->event_items_order_changed(1);
                }
                $item3->position($package_item_order);
                $item3->save;
                my $row2 = _init_toc_row('', 0, '', [ $row_item ]);
                push @{$toc->{table}}, $row2;
            }
        }

    return $toc;
}


=head2 toc_is_table_column_empty

It returns 0 if exists at least one non-empty (any space char means empty) value for the column in any row.
and it returns 1 if the column is empty in all rows.

@param $column is the name of the toc table column to check

=cut

sub toc_is_table_column_empty
{
    my $self = shift;
    my $column = shift;
    
    foreach my $row ( @{$self->package_toc_data->{table}} ) {
        return 0 if $row->{$column} && $row->{$column} =~ /\S/;
    }
    return 1;
}

sub toc_rows_number { return scalar @{shift->package_toc_data->{table}}; }

sub add_toc_row
{
    my $self = shift;
    my $product_submitted = shift || '';
    my $product_submitted_id = shift || 0;
    my $manufacturer_name = shift || '';
    my $items = shift || [];

    my $toc = $self->package_toc_data;
    my $row = _init_toc_row($product_submitted, $product_submitted_id, $manufacturer_name, $items); 
    push @{$toc->{table}}, $row;

    $self->_correct_package_items_order;

    $self->package_toc_data($toc);
}



=head2 toc_rows

Returns toc_rows by ID's

=cut

sub toc_rows {
    my $self = shift;
    my $irows = shift;

    return unless $irows;

    my $toc = $self->package_toc_data;
    return unless $toc;
    my $toctable = $toc->{table};
    return unless $toctable;

    my $rows = [];
    foreach my $i_row (@$irows) {
        next unless defined $i_row;
        if ($i_row <= $#$toctable) {
            my $row = $toctable->[$i_row];
            $row->{row_id} = $i_row;
            push @$rows, $row;
        }
    }
    return $rows;
}


=head2 add_item

Use this method to add items of any file type class you want. And even arrayrefs of files.

Returns 0 if we were trying to add an already existing 
file or document (that is already in the package)
or returns a toc_item hash in case of success

=cut

sub add_item {
    my $self = shift;
    my $item = shift;
    my $i_row = shift;

    $i_row = -1 unless defined $i_row;

    # it's a package
    if (ref $item eq 'BST::Package' || ref $item eq 'BST::PackageToc') {
        my @rows = ();
        my @i = $item->items;
        map {

            my $id_ = $_->is_file ? $_->get_column('file_id') : $_->get_column('document_id');
            my $type_ = $_->item_type;
            my $item_;
            $item_ = BST::Document->load( $id_ ) if ($type_ eq 'document');
            $item_ = BST::FolderItem->load( $id_ ) if ($type_ eq 'file');

            my $row_id = $self->add_item($item_);
            if (defined $row_id) {
                unless (grep {$_ eq $row_id} @rows) {
                    splice(@rows, scalar @rows, 0, $row_id);
                }
            }
        } @i;

        return @rows;
    }

    # add item to package
    return undef unless $self->next::method($item);

    # existing toc
    return undef unless $self->package_toc_type;
    my $toc = $self->package_toc_data;
    return undef unless $toc;
    my $toctable = $toc->{table} ||= [];

    # update toc: add file or document to toc
    # what should we add?
    my $type = "";
    my $id = "";
    if (ref $item eq 'BST::Document') {
        $id = $item->document_id;
        $type = "document";
    } elsif (ref $item eq 'BST::File') {
        $id = $item->file_id;
        $type = "file";
    } elsif (ref $item eq 'BST::PackageItem') {
        $id = $item->is_file ? $item->get_column('file_id') : $item->get_column('document_id');
        $type = $item->item_type;
    }

    # if there is something to add
    if ($id) {
        # new row table item to add
        my $toc_item = { id => $id, type => $type };
        _init_toc_table_item(0, $toc_item);

        if (-1 == (0 + $i_row) || $#$toctable < $i_row) {

            if ($type eq 'document') {
                my $product_id = 0;
                my $product_submitted = '';
                my $manufacturer_id = 0;
                my $manufacturer_name = '';
                if ($item->product) {
                    $product_id = $item->product->product_id;
                    $product_submitted = decode_product_name_input( $item->product->product_name );
                    my $manufacturer = $item->product->manufacturer;
                    $manufacturer_name = decode_product_name_input( $manufacturer->name );
                    for (my $i = 0; $i <= $#$toctable; ++$i) {
                    #foreach my $row (@$toctable) {
                        my $row = $toctable->[$i];
                        if ($row->{product_submitted_id} eq $product_id) {
                            push @{$row->{items}}, $toc_item;
                            $self->package_toc_data($toc);
                            $self->save();

                            #return $toc_item;
                            return $i;

                        }
                    }

                    # there is a product document and this
                    # product/document is not added yet.  if the last
                    # toc row does not have a product yet and contains
                    # no items, then add the product/the document into
                    # it, instead of creating a new row (#536)
                    if (scalar(@{$toctable}) > 0) # toc table has some rows
                    {
                        my $row = $toctable->[-1]; # last row
                        if ( (! $row->{product_submitted_id}) and 0 == scalar(@{$row->{items}}) ) {
                            _init_toc_row_data(
                                $row,
                                $product_submitted,
                                $product_id,
                                $manufacturer_name,
                                [ $toc_item ]);

                            $self->init_leed_columns($row, 1); # overwrite existed values

                            # save changes and return item
                            $self->package_toc_data($toc);
                            $self->save();

                            #return $toc_item;
                            return $#$toctable;
                        }
                    }

                }
                my $row = _init_toc_row($product_submitted, $product_id, $manufacturer_name, [ $toc_item ]);
                $self->init_leed_columns($row, 0); # don't overwrite existed values
                push @$toctable, $row;
                $i_row = $#$toctable;

            } else { # file

                # there is a file
                # if the last toc row does not have a product yet and contains
                # no items, then add the file into
                # it, instead of creating a new row (#577)
                if (scalar(@{$toctable}) > 0) # toc table has some rows
                {
                    my $row = $toctable->[-1]; # last row
                    if ( (! $row->{product_submitted_id}) and 0 == scalar(@{$row->{items}}) ) {
                        _init_toc_row_data(
                            $row,
                            '',
                            0,
                            '',
                            [ $toc_item ]);

                        # save changes and return item
                        $self->package_toc_data($toc);
                        $self->save();

                        #return $toc_item;
                        return $#$toctable;
                    }
                }

                my $row = _init_toc_row('', 0, '', [ $toc_item ]);
                push @$toctable, $row;
                $i_row = $#$toctable;
            }
        } else { # add item to an existing row specified by index
            push @{$toctable->[$i_row]->{items}}, $toc_item;
        }

        $self->_correct_package_items_order();
        $self->package_toc_data($toc);
        $self->save();

        #return $toc_item;
        return $i_row;
    }

    return undef;
}


sub init_leed_columns {
	my $self = shift || die;
    my $row = shift || die;
    my $overwrite = shift || 0;

    # get product and its leed_attributes
	my $product_id = $row->{'product_submitted_id'} || return;
	my $product = BST::Product->load(product_id=>$product_id) || return;
	my @product_attributes = $product->leed_attributes;
	my $product_leed_attributes = { 
		map {$_->attribute_id => $_->val}
		@product_attributes
	};
    return unless %$product_leed_attributes;

    # get toc_type and its leed columns definitions
	my $type = $BST::PackageToc::Types::TYPES{$self->package_toc_type};
	my $column_fields = [ 
        grep {
            $_->{attribute_id} 
            &&
            exists $product_leed_attributes->{$_->{attribute_id}}
            &&
            (
                $overwrite
                ||
                ! exists $row->{$_->{name}}
            )
        }
        @{$type->{column_fields}}
    ];
    return unless @$column_fields;

    # copy product leed attr's to toc as initial values
    my $leed_values = {};	
	foreach my $column (@$column_fields) {
        $leed_values->{$column->{name}}
            = $row->{$column->{name}}
            = $product_leed_attributes->{$column->{attribute_id}};
	}
    return $leed_values;
}

sub toc_row_change {
    my $self  = shift || die;
    my $i_row = shift;
    my $data  = shift || die;

    my $toc_data = $self->package_toc_data;
    my $table = $toc_data->{table};
    my $row = $table->[$i_row];

    if( not $row ) {
        $self->add_toc_row;
        $i_row = $#$table;
        $row = $table->[$i_row];        
    }

    die "Can't edit row $i_row -- it does not exists" if not $row;

	my $prev_product_submitted_id = $row->{'product_submitted_id'};
	$data->{product_submitted_id} = 0 unless $data->{product_submitted_id};
    foreach my $key (keys %$data) {
    
        if ($key eq 'product_submitted') {
            if ($prev_product_submitted_id
				&& ($row->{'product_submitted'} ne $data->{'product_submitted'})) {
                $row->{'product_submitted_id'} = '';
            }
        }

        # XXX apply decode_product_name_input() here?
        $row->{$key} = $data->{$key};
        utf8::upgrade( $row->{$key} );
    }

    my $leed_values = {};

	# if there is some product_id was set/changed
	if ($row->{'product_submitted_id'} 
        && $row->{'product_submitted_id'} ne $prev_product_submitted_id) {

		# copy manufacturer to the toc
		my $product_id = $row->{'product_submitted_id'};
		my $product = BST::Product->load(product_id=>$product_id);
		if ($product) {
			$row->{'manufacturer'} = decode_product_name_input( $product->manufacturer->name );
		}

		# copy initial values for leed columns
		$leed_values = $self->init_leed_columns($row, 1); # overwrite existed values
	}

    $self->package_toc_data( $toc_data );

    return $leed_values;
}


sub remove_toc_row {
    my $self = shift;
    my $i_row = shift;

    my $toc = $self->package_toc_data;
    return 0 if $i_row > $#{$toc->{table}};

    my $row = $toc->{table}->[$i_row];
    my @items = @{$row->{items}};
    foreach my $row_item (@items) {
        if ($row_item->{type} eq "document") {
            my $document = BST::Document->load($row_item->{id});
            $self->remove($document, 0);
        }
        if ($row_item->{type} eq "file") {
            my $file = BST::File->load($row_item->{id});
            $self->remove($file, 0);
        }
    }
    splice @{$toc->{table}}, $i_row, 1;
    
    $self->_correct_package_items_order;

    $self->package_toc_data($toc);
    $self->save;
    return 1;
}

sub remove_toc_item {
    my $self = shift;
    my $i_row = shift;
    my $i_item = shift;

    my $toc = $self->package_toc_data;
    my $result = "";

    return 0 if ($#{$toc->{table}} < $i_row);
    
    my $row = $toc->{table}->[$i_row];

    return 0 if ($#{$row->{items}} < $i_item);

    my $type = $row->{items}->[$i_item]->{type};
    my $id = $row->{items}->[$i_item]->{id};
    if ($type eq "document") {
        my $document = BST::Document->load($id);
        $self->remove($document) if $document;
    }
    if ($type eq "file") {
        my $file = BST::File->load($id);
        $self->remove($file) if $file;
    }

    $self->_correct_package_items_order;

    return 1;
}


=head2 insert_toc_row

Method to insert blank TOC row before specified existed one

=cut

sub insert_toc_row {
    my $self = shift;
    my $i_before_row = shift;
    
    my $toc = $self->package_toc_data;

    if (-1 == $i_before_row) {
        $i_before_row = $#{$toc->{table}} + 1;
    }

    return 0 if $i_before_row > $#{$toc->{table}} + 1;
    splice @{$toc->{table}}, $i_before_row, 0, _init_toc_row;
    
    $self->package_toc_data($toc);
    $self->save;
    return 1;
}


=head2

Method to move existed TOC row in place before specified existed one

=cut

sub move_toc_row {
    my $self = shift;
    my $i_row = shift;
    my $i_before_row = shift;

    my $toc = $self->package_toc_data;

    return 0 if 
        $i_before_row > $#{$toc->{table}} + 1
        || $i_row == $i_before_row
        || $i_row == $i_before_row - 1;

    my $row = delete $toc->{table}->[$i_row];

    if ($i_row < $i_before_row) {
        for (my $j = $i_row; $j < $i_before_row - 1; $j++) {
            $toc->{table}->[$j] = $toc->{table}->[$j + 1];
        }
        $toc->{table}->[$i_before_row - 1] = $row;
    } else {
        for (my $j = $i_row; $j > $i_before_row; $j--) {
            $toc->{table}->[$j] = $toc->{table}->[$j - 1];
        }
        $toc->{table}->[$i_before_row] = $row;
    }

    $self->_correct_package_items_order;
    
    $self->package_toc_data($toc);
    $self->save;
    return 1;
}


=head2 move_toc_item

Method to move one item to other row or to the same but to another place

=cut

sub move_toc_item {
    my $self = shift;
    my $i_row = shift;
    my $i_item = shift;
    my $i_dest_row = shift;
    my $i_before_item = shift;

    my $toc = $self->package_toc_data;

    return 0 if 
        $i_row > $#{$toc->{table}}                # row exists
        || $i_dest_row > $#{$toc->{table}}        # destination row exists
        
        # we are not moving item to the same place
        || ($i_row == $i_dest_row && ($i_item == $i_before_item))
        ;

    my $row = $toc->{table}->[$i_row];
    my $dest_row = $toc->{table}->[$i_dest_row];
    
    return 0 if 
        $i_item > $#{$row->{items}}                       # item exists
        || $i_before_item > $#{$dest_row->{items}} + 1    # before item exists
    ;

    my @removed = splice @{$row->{items}}, $i_item, 1;
    if ($i_row == $i_dest_row)
    {
        splice @{$dest_row->{items}}, $i_before_item, 0, @removed;
    } else {
        splice @{$dest_row->{items}}, $#{$dest_row->{items}} + 1, 0, @removed;
    }

    $self->_correct_package_items_order;
    
    $self->package_toc_data($toc);
    $self->save;
    return 1;
}




=head2 remove

Method to remove item from package + sync with toc if it needs.

=cut

sub remove {
    my $self = shift;
    my $item = shift;
    my $remove_from_toc = shift || 1; # by default it removes the item from package and from toc

    
    if ($remove_from_toc) {
        my $toc = $self->package_toc_data;
        if ($toc) {
            # get info about the item to remove from the toc of the package
            my $type = "";
            my $id = "";
            if (ref $item eq 'BST::Document') {
                $type = "document";
                $id = $item->document_id;
            }
            if (ref $item eq 'BST::File') {
                $type = "file";
                $id = $item->file_id;
            }
            if (ref $item eq 'BST::PackageItem') {
                $type = $item->item_type;
                if ($type eq "document") {
                    $id = $item->document->document_id;
                }
                if ($type eq "file") {
                    $id = $item->file->file_id;
                }
            }

            # if there is something to remove then remove it from toc
            if ($id) {
                loop_rows:
                foreach my $i_row (0 .. $#{$toc->{table}}) {
                    my $row = $toc->{table}->[$i_row];
                    foreach my $i (0 .. $#{$row->{items}}) {
                        if ($row->{items}->[$i]->{id} eq $id && $row->{items}->[$i]->{type} eq $type) {
                            splice @{$row->{items}}, $i, 1;

                            # no items in this row now
=c commented for now: remove whole row if there is last item removed
                            if ($#{$row->{items}} == -1) {
                                my $type = $BST::PackageToc::Types::TYPES{$self->package_toc_type};

                                my $modified = 0;
                                foreach my $field (@{$type->{column_fields}}) {
                                    if ($field->{type} eq 'text') {
                                        if ($row->{$field->{name}}) {
                                            $modified = 1;
                                            last;
                                        }
                                    }
                                    if ($field->{type} eq 'product_submitted' && (! $row->{product_submitted_id})) {
                                        if ($row->{product_submitted}) {
                                            $modified = 1;
                                            last;
                                        }
                                    }
                                }
                                if (! $modified) {
                                    splice @{$toc->{table}}, $i_row, 1;
                                }
                            }
=cut
                            last loop_rows;
                        }
                    }
                }

                $self->_correct_package_items_order();

                $self->package_toc_data($toc);
                $self->save;
            }

        }

    }

    # remove the item from the package
    $self->next::method($item);

}

sub path_toc_pdf   { BST::config('toc') . "/" . shift->id . ".pdf"; }
sub path_toc_html  { BST::config('toc') . "/" . shift->id . ".html"; }
sub path_toc_thumb { BST::config('toc') . "/" . shift->id . ".jpg"; }
sub path_toc_logo_small { BST::config('toc') . "/" . shift->id . ".logo" . (fileparse(shift, qr{\..*}))[2]; }


=head2 toc_pdf_columns

Rreturns the array of the columns to show in the toc pdf

=cut

sub toc_pdf_columns {
    my $self = shift;
    my @table_columns;
    my $types = \%BST::PackageToc::Types::TYPES;
    foreach my $column (@{$types->{$self->package_toc_type}->{column_fields}}) {
        push @table_columns, $column
            unless $column->{ignore_if_empty} && $self->toc_is_table_column_empty($column->{name});
    }
    return @table_columns;
}

=head2

Method to generate TOC xhtml, pdf and thumbnail for 1-st page

=cut

sub generate_toc_pdf {
    my $self = shift;
    my $user = shift;

    return undef unless $self->package_toc_type;
    # get data for the toc
    my $toc = $self->package_toc_data;
    my $types = \%BST::PackageToc::Types::TYPES;
    my $type = $types->{$self->package_toc_type};

    # path to company logo and to small copy of it for special header
    my $url_logo = $user->settings->list->{logo_file} || '';
    if ($url_logo) {
        $url_logo = BST::config('settings_path') . "/" . $url_logo;
    }
    my $url_logo_small = $self->path_toc_logo_small($url_logo);

    my $path_html  = $self->path_toc_html;
    my $path_pdf   = $self->path_toc_pdf;
    my $path_thumb = $self->path_toc_thumb;
    my @table_columns = $self->toc_pdf_columns;

    # check: if it's possible to use already generated "cached" files xhtml+pdf+thumb.
    my $use_generated = 0;
    if (-f $path_html and -s _ and $toc->{last_change}) {
        my @stat_xhtml = stat($path_html);
        my $mtime_xhtml = $stat_xhtml[9];
        $use_generated =
            $mtime_xhtml >= $toc->{last_change}                          # there is actual copy already generated
            && (
                (! BST::config('package_toc_output_cache_min')) # period limit not set set
                ||
                BST::config('package_toc_output_cache_min') * 60 >= time() - $mtime_xhtml # cache time limit is not exceeded
                );    
    }
    
    my @type_column1 = grep {$_->{name} ne 'title' && $_->{name} ne 'footer_comment' && ($_->{required} || $self->package_toc_data->{meta}->{$_->{name}})} @{$type->{meta_fields}};
    my @type_column2 = splice (@type_column1, ceil (($#type_column1 + 1) / 2), ceil ($#type_column1 / 2));

    if( not $use_generated or not (-f $path_pdf and -s _) or not (-f $path_html and -s _)) {
        
        # resize the logo of the company to generate small copy for the header
        if ($url_logo and -f $url_logo and -s _)
        {
            my $im = Image::Magick->new;
            $im->Read($url_logo);
            my $w = $im->Get('columns');
            my $h = $im->Get('rows');
            my $height_limit = BST::config('toc_pdf_2nd_page_header_logo_height_max') || 50;
            if ($h > $height_limit) {
                $im->Resize(height => $height_limit, width => int($w * $height_limit / $h));
                $im->Write($url_logo_small);
            } else {
                $url_logo_small = $url_logo;
            }
        }
        
        # generate xhtml & pdf
        my $generated = BST::PDF->generate(
            BST::config('templates') . "/pdf/toc.tt",
            $path_html,
            $path_pdf,
            {
                package => $self
                ,toc    => $toc
                ,type   => $type
                ,table_columns => \@table_columns
                ,type_column1=> \@type_column1
                ,type_column2=> \@type_column2
                ,url_logo => "file:///" . $url_logo
                ,url_logo_small => "file:///" . $url_logo_small
                ,url_bst_logo => "file:///" . BST::config('root_static') . "/images/logos/logo.gif"
                ,url_css => "file:///" . BST::config('root_static') . "/css/pdf_toc.css"
                ,css_media => 'print'
            },
        );

        # add PDF file size to the toc
        if ($generated) {
            my $size = -f $path_pdf;
            if ($toc) {
                $toc->{file_size} = $size;
                
                my $cmd = sprintf BST::config('page_count_command')->{pdf}, $path_pdf;
                my $line = `$cmd`;
                my ($page_count) = ($line =~ m/(\d+)/);
                $toc->{page_count} = $page_count;
                
                $self->package_toc_data($toc);
            }
        }

    }

    #$Image::Magick::Thumbnail::PDF::DEBUG = 1; 
    #warn "pdf: $path_pdf thumb: $path_thumb"; 
    if (not $use_generated or not (-f $path_thumb and -s _)) {
        if (-f $path_pdf and -s _) { 
=c
            if( 0 ) { 
                # create thumb. 
                create_thumbnail( 
                    $path_pdf, 
                    $path_thumb,
                    1, 
                    {  
                        restriction => BST::config("toc_thumb_size"),  
                        frame => 0,  
                        normalize => 0  
                    }, 
                ) or return undef; 
            } 
=cut
            my $home = BST::config("home") || die;
            #`cp -f $path_pdf .`;
            #my @rpath_pdf = split /\//, $path_pdf;
            #my $pdf = pop @rpath_pdf;
            #`/usr/bin/convert -verbose -scale 250x324 $pdf $path_thumb &2>1`;
            #system( "perl $home/bin/make-thumbnail.pl $path_pdf $path_thumb " . BST::config("toc_thumb_size") ); 

            if (-f $path_pdf) {
                create_thumbnail(
                    $path_pdf,
                    $path_thumb,
                    1,
                    {
                        restriction => BST::config("toc_thumb_size"),
                        frame => 0,
                        normalize => 0
                    },
                );
            }

        }
    }

    return 1;
}


=head clear

Returns the row containing specified items 

=cut

sub find_toc_item {
    my $self = shift;
    my $item = shift;    

    my $toc = $self->package_toc_data;
    if ($toc) {
        # get info about the item to remove from the toc of the package
        my $type = "";
        my $id = "";
        if (ref $item eq 'BST::Document') {
            $type = "document";
            $id = $item->document_id;
        }
        if (ref $item eq 'BST::File') {
            $type = "file";
            $id = $item->file_id;
        }
        if (ref $item eq 'BST::PackageItem') {
            $type = $item->item_type;
            if ($type eq "document") {
                $id = $item->document->document_id;
            }
            if ($type eq "file") {
                $id = $item->file->file_id;
            }
        }

        # looking for the first row contained that item
        if ($id) {
            foreach my $i (0 .. @{$toc->{table}} - 1 ) {
                my $row = $toc->{table}->[$i];
                foreach my $_item ( @{$row->{items}} ) {
                    return $i if $_item->{id} eq $id && $_item->{type} eq $type;
                }
            }
        }
    }
    return undef;
}

sub get_toc_row {
    my $self = shift;
    my $row_num = shift;

    my $toc = $self->package_toc_data;
    return $toc->{table}->[$row_num] if ($toc);
    return undef;
}

sub find_product {
    my $self = shift;
    my $product_id = shift;

    my $toc = $self->package_toc_data;

    return -1 unless $toc;
    
    foreach my $i (0 .. @{$toc->{table}} - 1 ) {
        my $row = $toc->{table}->[$i];
        return $i if $row->{product_submitted_id} eq $product_id;
    }
    
    return -1;
}


=head clear

Clears package items and TOC data

=cut

sub clear {
    my $self = shift;
    $self->SUPER::clear();

    $self->package_toc_data(undef);
    $self->package_toc_type(undef);
    $self->save();
}


sub post_to_url {
    my $self = shift;
    my $package_ext_id = md5_hex($self->package_id);
    $self->package_ext_id($package_ext_id);
    $self->save();
    return $self->package_toc_type ? "ext/toc/$package_ext_id/" : "ext/package/$package_ext_id/";
}

sub toc_page_count {
    my $self = shift;
    my $cmd = sprintf BST::config('page_count_command')->{pdf}, $self->path_toc_pdf;
    my $line = `$cmd`;
    my ($page_count) = ($line =~ m/(\d+)/);
    return $page_count;
}



=head2

Remove product and product row from toc by product_id

=cut

sub remove_product {
    my $self = shift;
    my $product_id = shift;

    # remove the product row from the toc
    my $toc = $self->package_toc_data;
    if ($toc) {
        my $changed = 0;
        for (my $i_row = 0; $i_row <= $#{$toc->{table}}; $i_row++) {
            my $row = $toc->{table}->[$i_row];
            if ($row->{product_submitted_id} eq $product_id) {
                splice @{$toc->{table}}, $i_row, 1;
                $i_row--;
                $changed = 1;
            }
        }        
        if ($changed) {
            $self->package_toc_data($toc);
            $self->save;
        }
    }

    # remove the product from the package
    $self->next::method($product_id);
}


=head2

Sync. already existing TOC with some potential changes in package items set
during plain to TOC switch

=cut

sub check_toc_data {
    my $self = shift;

    my $toc = $self->package_toc_data;

    # add to TOC items are in package but not in TOC
    my ($item, $row);
    for $item ($self->items) {
        unless (defined $self->find_toc_item($item)) {
            $self->add_item($item, -1);
        }
    }

    # collect for removing items are in toc but not in package
    my @items_to_remove = ();
    for $row (@{$toc->{table}}) {
        for my $item (@{$row->{items}}) {
            unless ($self->find_item($item->{id})) {
                push @items_to_remove, $item;
            }
        }
    }

	# remove items are in the TOC but not in the package
    for $item (@items_to_remove) {
        my $type = $item->{type};
        my $id = $item->{id};
        if ($type eq "document") {
            my $document = BST::Document->load($id);
            $self->remove($document) if $document;
        }
        if ($type eq "file") {
            my $file = BST::File->load($id);
            $self->remove($file) if $file;
        }
    }

    # remove rows without items
    # and with all text columns (for this toc type) are empty 
    $toc = $self->package_toc_data;
    for (my $i = 0; $i < @{ $toc->{table} }; ++$i) {
		if (
			(! $toc->{table}->[$i]->{items})
			|| 
			(! @{ $toc->{table}->[$i]->{items} } )
		) {
			my $type_columns = $BST::PackageToc::Types::TYPES{$self->package_toc_type}->{column_fields};
			unless (grep { $toc->{table}->[$i]->{$_->{name}} } grep {$_->{type} ne 'items'} @$type_columns) {
				delete $toc->{table}->[$i];
			}
		}
    }
    @{ $toc->{table} } = grep {$_} @{ $toc->{table} };

    $self->package_toc_data($toc);
    $self->save();
    # correct items order
    $self->_correct_package_items_order;

    return 1;
}

sub toc_size_bytes {
    my $self = shift;

    my $toc = $self->package_toc_data;
    if ($toc) {
        return ($toc->{file_size} or 0);
    }
    
    return 0;
}
sub toc_pages {
    my $self = shift;

    my $toc = $self->package_toc_data;
    if ($toc) {
        return ($toc->{page_count} or 0);
    }

    return 0;
}

sub total_size_bytes {
    my $self = shift;
    my $total_size = $self->next::method();

    $total_size += ($self->toc_size_bytes or 0);
    
    return $total_size;
}
sub total_pages {
    my $self = shift;
    my $total = $self->next::method();

    $total += ($self->toc_pages or 0);

    return $total;
}

=head1 DESCRIPTION
    Class represents package + methods for work with TOC.
=cut

1;
