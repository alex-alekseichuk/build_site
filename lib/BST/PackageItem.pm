package BST::PackageItem;

use strict;
use warnings;
use Carp qw(croak);

use BST;
use BST::File;
use BST::Document;
use BST::Package;

use Params::Validate qw(:all);
use Data::Dumper;

use base qw(BST::Core BST::Schema::PackageItem);
__PACKAGE__->table('package_item');

use BST::Fax::Interfax;
our $fax_gate = 'BST::Fax::Interfax';


=head1 DESCRIPTION

Class represents package item.

=cut


__PACKAGE__->belongs_to(
  "package",
  "BST::Package",
  { file_id => "package_id" },
);
__PACKAGE__->belongs_to(
  "file",
  "BST::File",
  { file_id => "file_id" },
  { join_type => 'left' },
);
__PACKAGE__->belongs_to(
  "document",
  "BST::Document",
  { document_id => "document_id" },
  { join_type => 'left' },
);

sub relatives { shift->package->items }

# use this to move package item on +/- N positions
sub move {
    my ($self, $pos) = validate_pos(@_,
                 { type => HASHREF },
                 { type => SCALAR, regex => qr/^[+-]?\d+$/, default => 1, optional => 1 },
    );

    my $rel = [ $self->relatives->all ];

    my $old = 0;
    foreach (@$rel) {
        last if ($_->id eq $self->id);
        $old++;
    }
    my $new = $old + $pos;

    if    ($new > scalar @$rel - 1) { $new = scalar @$rel - 1 }
    elsif ($new < 0) { $new = 0 }

    for (
        my $i = $old < $new ? $old : $new;
        ($i < $new && $old < $new) || ($i < $old && $old > $new);
        $i++
        ) {
        $rel->[$i]->_move_1( $rel->[$i+1] );
    }
}


# package item position exchange
sub _move_1 {
    my ($s, $i) = @_;
    my $t1 = $s->position;
    my $t2 = $i->position;

    $i->position($t1);
    $i->save;

    $s->position($t2);
    $s->save;    
}

sub product {
    my $self = shift;
    if ($self->is_document && $self->document) {
        return $self->document->product;
    }
}

sub title {
    my $self = shift;
    if ($self->file) {
        return $self->file->title;
    } elsif ($self->document) {
        return $self->document->title;
    }
}    


sub is_file {
    return shift->item_type eq 'file';
}

sub is_document {
    return shift->item_type eq 'document';
}



sub is_upgraded {
    my $self = shift;
    return 1 if $self->is_file ? $self->file->replaced_by_doc || $self->is_deleted : $self->document->replaced_by_document_id;
    return 0;
}

sub is_deleted {
    my $self = shift;
    return $self->is_file ? $self->file->is_deleted : $self->document->is_deleted;
}


sub replacement {
    my $self = shift;
    return $self->is_file ? $self->file->replacement : $self->document->replacement;
}

sub upgrade {
    my $self = shift;
    my $replacement = shift || $self->replacement;
    if ($self->is_file) {
        $self->file($replacement);
    } else {
        $self->document($replacement);
    }
    $self->save();
}

sub is_faxable {
    my $self = shift;
    my $format = shift || $self->file_type;
    return $fax_gate->is_format_accepted( $format );
}

sub file_path {
    my $self = shift;
	
    my $path;
    if ($self->file) {
        $path = $self->file->local_file_path();
    } elsif ($self->document) {
        $path = $self->document->local_file_path();
    } else {
        croak "PackageItem has neither file nor document";
    }
	
    if (not -r $path) {
        $self->logger->warning( "package item $self file " . $path . " is unreadable" );
        return undef;
    }
    return $path;
}

sub file_size {
    my $self = shift;
	
    if ($self->file) {
        return $self->file->file_size;
    } elsif ($self->document) {
        return $self->document->file_size;
    }
    
    croak "PackageItem has neither file nor document";
}

sub page_count {
    my $self = shift;

    if ($self->file) {
        return $self->file->page_count;
    } elsif ($self->document) {
        return $self->document->derived_pagecount;
    }

    croak "PackageItem has neither file nor document";
}

sub file_send_name {
    my $self = shift;
    if ($self->file) {
        return $self->file->file_send_name();
    } elsif ($self->document) {
        return $self->document->file_send_name();
    }
    croak "PackageItem has neither file nor document";
}

sub file_type {
    my $self = shift;
    if ($self->is_file) {
        return $self->file->file_format_type;
    } elsif ($self->document) {
        return $self->document->derived_format;
    }
    croak "PackageItem has neither file nor document";
}

1;
