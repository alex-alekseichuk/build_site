package BST::Package;

use strict;
use warnings;
use Carp qw(croak);
use Data::Dumper;

use BST qw(schema);
use BST::File;
use BST::Document;
use BST::PackageToc::Types;
use BST::Scope;
use BST::PackageToc::Types;

use Params::Validate qw(:all);
use Digest::MD5 qw(md5_hex);

use base qw(BST::FolderItem BST::Schema::File);
__PACKAGE__->table('file');

=c
__PACKAGE__->has_many(
  'package_items' => 'BST::PackageItem',
  { "foreign.package_id" => "self.file_id" },
);
=cut

__PACKAGE__->load_components(qw/UTF8Columns/);
__PACKAGE__->utf8_columns( qw( package_toc_data ) );

=c
__PACKAGE__->has_many(
    "items",
    "BST::PackageItem",
    { "foreign.package_id" => "self.file_id" },
    {
        prefetch => [
            {'document' => [ 
                 'product', 
                 {'publication'=> 'company'}, 'doc_type'] 
            },
            'file'
        ],
        order_by => 'position' 
    }
);
=cut

# a wrapper
sub package_id {
    $_[0]->id;
}



=head2 clear_items_cache

Clear cached items set of this package

=cut

sub clear_items_cache {
    delete shift->{_package_items};
}



=head2 items

method to get items of the package in specified order
it uses special cache: %items_cache

there are several methods able to set the items set of the package
they clear the items_cache for that package

=cut

sub items {
    my $self = shift;

    # if items is not cached yet
    unless (exists $self->{_package_items})
    {
        # get items for this package
        my @items =
            BST::PackageItem->search(
                { package_id => $self->id }, 
                { 
                    prefetch => [
                        {'document' => [ 
                             'product', 
                             {'publication'=> 'company'}, 'doc_type'] 
                        },
                        'file'
                    ],
                    order_by => 'position' 
                } 
            );
        
        # cache items
        $self->{_package_items} = \@items;
        
        return @items;
    }

    # return already cached items
    return @{$self->{_package_items}};
}



sub items_can_faxed {
    my $s = shift;
    return [ grep { $_->is_faxable } @{ $s->items_local_files() } ];
}

# return the list of items, which have their respective files present in the file system
sub items_local_files {
    my @items = grep {$_->file_path} shift->items;
    return \@items;
}

sub create {
    my $class = shift;
    my $columns = shift || {}; # optional

    $columns->{file_class} = 'archive';

    return $class->next::method($columns);
}

sub search {
    my ($class, $cond, $attrs) = validate_pos(@_,
                 { type => SCALAR },
                 { type => HASHREF | UNDEF },
                 { type => HASHREF, optional => 1 },
    );
    $cond->{file_class} = "archive";
    return $class->next::method($cond, $attrs);
}

sub contents {
    my $self = shift;

    my $items_line = $self->next::method;
    my $id = $self->id;

    return undef if (! defined $items_line);
    my @items = split(';', $items_line);
    my $result = [];
    foreach my $i (@items) {
        next if not $i;
        my $newitem;
        if ($i =~ /(document[A-Z]?\d+)/) {
            my $docid = $1;
            $newitem = BST::Document->load({ document_id => $docid });
            if (!$newitem) { warn "package $id: can't find document $docid ($i)\n" }
        } elsif ($i =~ /^private/) {
            $newitem = BST::File->load({ file_id => $i });
            if (!$newitem) { warn "package $id: can't find file $i\n" }
        } else {
            warn "package $id: unidentified package item: $i\n";
            next;
        }

        if ( $newitem ) {
            push @$result, $newitem;
        }
    }

    return $result;
}

sub folder {
    my $self = shift;
    return $self->parent->file_id if ($self->parent);
    return "_" . $self->scope;
}



=head2 add_item

Use this method to add items of any file type class you want. And even arrayrefs of files.

Returns 0 if we were trying to add already existing file or document and that item is already attached to package
or returns 1 in any other case

=cut

sub add_item {
    my $self = shift;
    my $item = shift;

    if (ref $item eq 'BST::Document') {
        unless ($self->has_item($item->id)) {
            my $pi = BST::PackageItem->create( { package_id => $self->id } );
            $pi->document($item);
            $pi->document_id($item->document_id);
            $pi->item_type('document');
            $pi->save();
        } else {
            return 0;
        }
    } elsif (ref $item eq 'BST::File') {
        unless ($self->has_item($item->id)) {
            my $pi = BST::PackageItem->create( { package_id => $self->id } );
            $pi->file($item);
            $pi->file_id($item->file_id);
            $pi->item_type('file');
            $pi->save();
        } else {
            return 0;
        }
    } elsif (ref $item eq 'BST::Folder') {
        map { $self->add_item($_) } ($item->list());
    } elsif (ref $item eq 'BST::Package' || ref $item eq 'BST::PackageToc') {
        my @i = $item->items;
        map {
            if ($_->item_type eq "file") {
                $self->add_item( $_->file );
            } else {
                $self->add_item( $_->document );
            }
        } @i;
    } elsif (ref $item eq 'ARRAY') {
        map { $self->add_item($_) } @$item;
    }
    
    $self->clear_items_cache;
    
    return 1;
}

=head2 find_item (file_id || document_id)

Returns package_item of stored file or document in this package if any.

=cut

sub find_item {
    my $self = shift;
    my $id = shift; # id of file or id of document
    return
            BST::PackageItem->search(
                { -and => [
                    { package_id => $self->id }
                    ,{ -or => [ {"file.file_id" => $id}, {"document.document_id" => $id}, {"package_item_id" => $id} ] }
                ]}
                ,{ 
                    prefetch => [
                        {'document' => [ 
                             'product', 
                             {'publication'=> 'company'}, 'doc_type'] 
                        },
                        'file'
                    ],
                    order_by => 'position' 
                } 
            )->first;

    #return $self->items->search( { -or => [ {"file.file_id" => $id}, {"document.document_id" => $id}, {"package_item_id" => $id} ] })->first;
}

sub has_item {
    my $self = shift;
    my $id = shift; # id of file or id of document

    return BST::PackageItem->search(
        { package_id => $self->id, -or => [ {"file.file_id" => $id}, {"document.document_id" => $id}, {"package_item_id" => $id} ] }, 
        { 
            join => [ qw(document file)],
        } 
    )->count;
}

=head2 remove

Method to remove item from package.

=cut

sub remove {
    my $self = shift;
    my $item = shift;

    if (ref $item eq 'BST::PackageItem') {
        $item->delete;
    } elsif (ref $item eq 'BST::Document') {
        my $package_item = $self->find_item($item->document_id);
        $package_item->delete if $package_item;
    } elsif (ref $item eq 'BST::File') {
        my $package_item = $self->find_item($item->file_id);
        $package_item->delete if $package_item;
    } elsif (ref $item eq 'BST::Folder') {
        map { $self->remove($_) } ($item->list());
    } elsif (ref $item eq 'BST::Package' || ref $item eq 'BST::PackageToc') {
        my @i = $item->items;
        map {
            if ($_->item_type eq "file") {
                my $file = BST::File->load($_->file_id);
                $self->remove($file) if ($file);
            } else {
                my $document = BST::Document->load( {document_id => $_->document_id } );
                $self->remove($document) if ($document);
            }
        } @i;
    }
    
    $self->clear_items_cache;
}

=head2 clone

Method to duplicate a package with all it's attributes and items.
Used in email sending. Returns the new package, which is also
stored as pointer to next version in the original package.

=cut

sub new_version {
    my $self = shift;

    # XXX: WTF?
    # cannot add new version for already copied item (clones only new versions)
    #return $self
    #    if $self->replaced_by_doc;

    my $new = $self->clone();

    # set link to new package (version record)
    $self->replaced_by_doc($new->id);
    $self->save;

    return $new;
}

#
sub clone {
    my $self = shift;

    my $clone = $self->SUPER::clone(@_);

    my $st = &schema->storage->dbh->do(sprintf("SELECT f_copy_package_items('%s', '%s')", $self->package_id, $clone->package_id));
    return BST::Package->load($clone->package_id);
}


=head2 save_as_file

Saves package in our file system. Makes package available to vieving and editing from document drawer (file viewer).

ATT!: need input params check

=cut

sub save_as {
    my $self = shift;
    my $user = shift || undef;
    my $scope = shift || BST::Scope::HIDDEN;
    my $folder_id = shift || "";
    my $title = shift || "";
    my $comment = shift || "";

    return if (! $user);

    # TODO: check $scope value
    # commented to test changing of the object via obj. cache
    #my $package = (BST::Scope->is_hidden($self->scope)) ? $self : $self->clone;
    my $package = $self;


    $package->scope($scope);
    $package->file_title($title);
    $package->file_comment($comment);
    $package->creator_user($user);
    $package->file_size(0);
    $package->parent(
        $folder_id ?
            BST::Folder->load( { file_id => $folder_id } ) :
            undef
    );

    $package->save;

    return $package;
}


=head has_upgrades

Checks if some package items were updated or deleted

=cut
sub has_upgrades {
    my $self = shift;
    my @items = $self->items;

    return ( grep { $_->is_upgraded } @items ) ? 1 : 0;
}



=head upgrade

Replaces package items which were updated with new versions of files (documents) and deletes deleted files

=cut
sub upgrade {
    my $self = shift;

    return unless $self->has_upgrades();

    my $new_pkg = $self->clone();
    my @items = $new_pkg->items;

    foreach (@items) {
        next unless $_->is_upgraded;
        my $rep = $_->replacement;
        $rep->is_deleted ? $_->delete() : $_->upgrade($rep);
    }

    return $new_pkg;
}


=head clear

Clears package items list

=cut

sub clear {
    my $self = shift;
    $_->delete() for $self->items;
    
    $self->clear_items_cache;
}


sub remove_product {
    my $self = shift;
    my $product_id = shift;

    foreach ($self->items) {
        if ($_->is_document) {
            $self->remove( $_ ) if ($_->document->product && $_->document->product->product_id eq $product_id);
        } elsif ($_->is_file) {
            my $pr = $_->file->is_related_products_file;
            $self->remove( $_ ) if ($pr && $pr eq $product_id);
        }
    }

    $self->save();
}

sub display_pathname {
    my $self = shift;
    my $scope = "";
    if (BST::Scope->is_account($self->scope)) {
        $scope = "Company:\\";
    } elsif (BST::Scope->is_location($self->scope)) {
        $scope = "Location:\\";
    } elsif (BST::Scope->is_user($self->scope)) {
        $scope = "Private:\\";
    }
    my @path = ();
    push @path, $self->file_title;

    my $parent = $self;
    while ($parent = $parent->parent) {
        push @path, $parent->file_title;
    }

    my $pathstring = join "\\", reverse @path;
    return $scope . $pathstring;
}

sub toc_type_label {
    my $type = shift->package_toc_type;
    if( $type ) { return $TYPES{$type}->{type_label}; }
    else { return "Basic Package"; }
}

sub toc_item_label {
    my $type = shift->package_toc_type;
    if( $type ) { return $TYPES{$type}->{toc_item_label}; }
}


sub json {
    my $self = shift;

    my @js_items = ();
    my @items = $self->items;
    my $used_products = {};
    my $products = [];

    foreach my $item (@items) {
        my $object = {
            id => $item->package_item_id, 
            object_id => 0, 
            is_file => 0, 
            is_document => 0, 
            is_product_document => 0, 
            title => '', 
            size => 0, 
            pages => 0, 
            product_id => 0
        };

        my $product;
        my $product_id;
        if ($item->is_file) {
            my $file = $item->file;
            $object->{object_id} = $file->file_id;
            $object->{title}     = $file->title;
            $object->{is_file}   = 1;
            $object->{filesize}  = $file->file_size;
            $object->{pages}     = $file->page_count;
            $object->{url}       = $file->download_url;
            # XXX this is to be improved: we should get the product
            # object from there, not just the product_id
            $product_id = $file->is_related_products_file;
            if ($product_id) {
                $object->{product_id} = $product_id;
                $object->{shortname} = $file->get_related_products_shortname;
            }

        } elsif ($item->is_document) {
            my $document = $item->document;
            $product = $document->product;
            if ($product) { $product_id = $product->id; }
            $object->{object_id} = $document->document_id;
            $object->{title}     = $document->title;
            $object->{shortname} = $document->short_title;
            $object->{filesize}  = $document->derived_filesize;
            $object->{pages}     = $document->derived_pagecount;
            $object->{product_id} = $product_id || 0;
            $object->{is_document} = 1;
            $object->{url}       = $document->download_url;
            $object->{is_product_document} = $object->{product_id} ? 1 : 0;
        }

        if ($product_id && not $used_products->{$product_id}) {
            $used_products->{$product_id} = 1;
            if(not $product) { $product = BST::Product->load(product_id=>$product_id); }
            push @$products, $product;
        }

        push @js_items, $object;
    }

    my $package = {
       id => $self->package_id,
       n  => scalar @js_items,
       items => \@js_items,
       is_saved => BST::Scope->is_hidden($self->scope) ? 0 : 1,
       toc_type  =>  $self->package_toc_type || 0,
       toc_type_label => $self->toc_item_label,

       title => $self->file_title || '',
       description => $self->file_comment || '',
       pid => $self->get_column("parent") || "_" . $self->scope,
    };

    my $_products = [
        map {;
            {
                id => $_->product_id,
                title => $_->product_name
            }
        } @$products
    ];
    
    return { package => $package, products => $_products };
}

sub total_size_bytes {
    my $total_size = 0;
    foreach (shift->items()) {
        $total_size += ($_->file_size or 0);
    }
    return $total_size;
}

sub total_pages {
    my $total = 0;
    foreach (shift->items()) {
        $total += ($_->page_count || 1);
    }
    return $total;
}

sub total_pages_can_faxed {
    my $total = 0;
    foreach (@{shift->items_can_faxed()}) {
        $total += ($_->page_count || 1);
    }
    return $total;
}

sub check_message_limits {
    my $self = shift;
    
    my @result = ();
    # email_size_limit is in kilobytes
    if (BST::config('email_size_limit')
        and BST::config('email_size_limit') < ($self->total_size_bytes/1024) )
    {
        push @result, 'size';
    }
    
    if (BST::config('fax_pagecount_limit')
        and BST::config('fax_pagecount_limit') < $self->total_pages)
    {
        push @result, 'pages';
    }
    return @result;
}

sub get_page_stats {
    my $self = shift;
    my ($stat, @pdf, @uncountable, @icf);

    @icf = @{$self->items_can_faxed};

    $stat->{items} = scalar $self->items;
    $stat->{faxable} = scalar @icf;
    $stat->{unfaxable} = $stat->{items} - $stat->{faxable};
    $stat->{pages} = $self->total_pages;
    $stat->{faxable_pages} = $self->total_pages_can_faxed;

    # @pdf = grep { ($_->file_type || "") eq "pdf"} @{$self->items_local_files};
    # $stat->{pdfs} = @pdf;

    @uncountable = grep {!$_->file_type || $_->file_type ne "pdf"} @icf;
    $stat->{uncountable} = @uncountable;

    return $stat;
}

1;
