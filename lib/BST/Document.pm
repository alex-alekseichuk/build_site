package BST::Document;

use strict;
use warnings;
use POSIX qw(ceil);

use base qw/BST::Core BST::Schema::Document/;
use vars qw/%DOC_TYPES/;
use BST::DocTypeInfo;

__PACKAGE__->table("document");

=head1 DESCRIPTION
    Document object
=cut

__PACKAGE__->has_many(
  "documents",
  "BST::Document",
  { "foreign.replaced_by_document_id" => "self.document_id" },
);
__PACKAGE__->belongs_to(
  "product",
  "BST::Product",
  { product_id => "product_id" },
  { join_type => 'left' },  
);
__PACKAGE__->belongs_to(
  "original_publisher",
  "BST::Company",
  { company_id => "original_publisher_id" },
);
__PACKAGE__->belongs_to(
  "category",
  "BST::Category",
  { category_id => "category_id" },
  { join_type => 'left' },  
);
__PACKAGE__->belongs_to(
  "publication",
  "BST::Publication",
  { publication_id => "publication_id" },
  { join_type => 'left' },  
);
__PACKAGE__->belongs_to(
  "about_company",
  "BST::Company",
  { company_id => "about_company_id" },
  { join_type => 'left' },  
);

__PACKAGE__->belongs_to(
  "doc_type",
  "BST::Schema::DocTypeInfo",
  { doc_type => "doc_type" },
  { join_type => 'left' },  
);

sub search {
    my ($class, $query, $params) = @_;
    $query->{'me.suppress_reason_code'} = { '=', ''} if
       (BST::Product->hide_suppressed);

    return $class->next::method($query, $params);
}


sub _doc_type {
    my $self = shift;

    unless (keys %DOC_TYPES) {
        my @all = BST::DocTypeInfo->search({});
        %DOC_TYPES = map {; $_->get_column("doc_type") => $_} @all;
    }
    return $DOC_TYPES{$self->get_column("doc_type")};
}

sub search_product_category {
    my ($class, $query) = @_;
    $query->{'me.document_type'} = 'category';
    return $class->search(
        $query,
        {
            prefetch => ['doc_type'
                         , { category_id => 'category_descendant_category_ids' }
            ],
            '+select' => [ 'category_descendant_category_ids.descendant_id' ],
            '+as' => [ 'descendant_id' ],
            order_by => ['me.document_role', 'dt_order', 'me.publisher_document_title', 'me.auto_ctime desc'],
        });
}

sub title {
    my $s = shift;
    my $is_short_title = shift;

    my $r = '';

    if (!$is_short_title) {
        my $company = $s->publication->company;
        if ($company)
        {
            $r .= $company->company_nickname || $company->legal_name;
        }
        if ($s->product)
        {
            $r .= ' - ' if ($r);
            $r .= $s->product->product_name;
        }
    }

    $r .= ' - ' if ($r);
    $r .= ref $s->_doc_type ? $s->_doc_type->dt_label : '';
    if ($s->publisher_document_title)
    {
        $r .= ' - ' if ($r);
        $r .= $s->publisher_document_title;
    }
    return $r;
}

sub short_title { return shift->title(1); }
sub comments { return shift->title; }

sub local_file_path {
    my $self = shift;
    my $path = BST::config('publishers_path') . '/' . $self->get_column("publication_id") . '/derived_files/' . $self->derived_path;
    #if (!-f $path) {
        #warn "no file at $path for document " . $self->document_id;
    #}
    return $path;
}

sub file_send_name {
    return shift->derived_path;
}

sub download_url {
    my $self = shift;
    my $url = BST::config('document_url');
    
    $url || return undef;
    
    $url =~ s/%%publicationid%%/ $self->get_column("publication_id") || '' /eg;
    $url =~ s/%%derived_path%%/ $self->derived_path || '' /eg;
    
    return $url;
}


=head replacement

Returns a document which replaces the one. 

=cut
sub replacement {
    my $document = shift;
    $document = BST::Document->load( {document_id => $document->replaced_by_document_id} ) while ($document->replaced_by_document_id);    
    return $document;
}


=head is_deleted

Returns if the document was deleted. Should be replaced with field 'is_deleted' in database
    
=cut
sub is_deleted {
    return 0;
}


sub is_discontinued {
    my $self = shift;
    my ($flag) = grep m/disc_doc/, split ";", $self->check_flags;
    return $flag;
}

sub has_suppress_flag {
    my $self = shift;
    return grep m/suppress/, split ";", $self->check_flags
        if $self->check_flags;
}

sub is_suppressed {
    my $self = shift;
    return $self->suppress_reason_code;
}

sub can_read {
    my $self = shift;
    return 1;
#    return !$self->is_suppressed;
}

sub file_size { return shift->derived_filesize; }

sub filesize_kb {
    my $self = shift;
    return ceil($self->derived_filesize / 1024);
}

sub page_count { return shift->derived_pagecount; }

1;
