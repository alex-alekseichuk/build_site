package BST::File;

use strict;
use warnings;
use Carp qw(croak);
use Data::Dumper;
use File::Copy;
use BST::Product;
use POSIX qw(ceil);

use BST;

use Params::Validate qw(:all);

use base qw(BST::FolderItem BST::Schema::File);
__PACKAGE__->table('file');

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


my @DISALLOWED_FILE_UPLOAD_EXT = qw/exe com scr/;
my %EXTENSION_TO_FORMAT = (
    'bmp' => 'bmp',
    'doc' => 'word',
    'docx' => 'word',
    'eps' => 'eps',
    'gif' => 'gif',
    'htm'  => 'html',
    'html' => 'html',
    'jpg' => 'jpeg',
    'jpeg' => 'jpeg',
    'mht' => 'html',
    'pdf' => 'pdf',
    'ppt' => 'powerpoint',
    'pps' => 'powerpoint',
    'pot' => 'powerpoint',
    'pptx' => 'powerpoint',
    'rtf' => 'rtf',
    'tif' => 'tiff',
    'tiff' => 'tiff', 
    'txt' => 'text',
    'xls' => 'excel',
    'xlsx' => 'excel',
);

sub is_allowed_file_to_upload {
    #my $class = shift;
	my $fname = shift;

	my ($ext) = ($fname =~ /\.(\w+)$/);
	$ext = lc($ext);

    return 0 unless $ext; # ignore files without extension

	foreach my $ext2 (@DISALLOWED_FILE_UPLOAD_EXT) {
		return 0 if ($ext eq $ext2);
	}
	return 1;
}


sub title { shift->file_title(@_) };

sub create {
    my $class = shift;
    my $columns = shift || {}; # optional

    $columns->{file_class} = "file"; # if (! exists($columns->{file_class}));

    return $class->next::method($columns);
}

sub search {
    my ($class, $cond, $attrs) = validate_pos(@_,
                 { type => SCALAR },
                 { type => HASHREF | UNDEF },
                 { type => HASHREF, optional => 1 },
    );
    $cond->{file_class} = "file";
    return $class->next::method($cond, $attrs);
}

=head replacement

Returns a file which replaces the one. 

=cut
sub replacement {
    my $file = shift;
    $file = BST::File->load( {file_id => $file->replaced_by_doc} ) while ($file->replaced_by_doc);
    return $file;
}

sub set_page_count {
    my $self = shift;
    my $count = $self->file_page_count();
    $self->page_count($count);
}

sub file_page_count {
    my $self = shift;
    my $f = $self->local_file_path;
    my $cmd;
    if ($self->file_format_type eq 'pdf') {
        $cmd = sprintf BST::config('page_count_command')->{pdf}, $f;
    }
    elsif ($self->file_format_type eq 'word') {
        $cmd = sprintf BST::config('page_count_command')->{word}, $f;
    }
    elsif ($self->file_format_type eq 'text') {
        $cmd = sprintf BST::config('page_count_command')->{enscript}, $f;
    }
    else {
        return 0;
    }
    my $line = `$cmd`;
    my ($page_count) = ($line =~ m/(\d+)/);
    return $page_count;
}

sub download_url {
    my $self = shift;
    return sprintf '/folders/download?file_id=%s', $self->file_id;
}


sub get_related_products_shortname {
    return "Related Products";
}


sub get_related_products_filename {
    my $self = shift;
    my $product = shift;
    return $product->product_name . " - " . $self->get_related_products_shortname();
}

sub is_related_products_file {
    my $self = shift;
    return unless BST::Scope->is_hidden($self->scope); 
    my $product = shift;
    unless ($product) {
        return unless $self->file_comment;
        $product = BST::Product->load($self->file_comment) || return;
    }

    return $product->product_id if $self->file_title eq $self->get_related_products_filename($product);
    return 0;
}

=c
sub file_size {
    my $self = shift;
    return $self->file_size;
}
=cut

sub filesize_kb {
    my $self = shift;
    return ceil($self->file_size / 1024);
}


sub file_extension {
    my $self = shift;
    return $self->get_column('file_extension') unless @_;

    my $ext = shift;
    my $fmt = $EXTENSION_TO_FORMAT{$ext};
    $self->set_column('file_extension', $ext);
    $self->file_format_type($fmt) if $fmt;
}



# when cloning a file, copy it in the storage too.
sub clone {
    my $self = shift;

    my $clone = $self->SUPER::clone(@_);
    
    # copy the file
    my $original_file = $self ->local_file_path;
    my $copy_file     = $clone->local_file_path;
    if (-f $original_file) {
        copy $original_file, $copy_file;
    }
    return $clone;
}

=head1 DESCRIPTION
    Class represents files.
=cut

1;
