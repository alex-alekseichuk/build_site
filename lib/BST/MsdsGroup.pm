package BST::MsdsGroup;

use strict;
use warnings;
use BST::MsdsDocument;

use base qw/BST::Core BST::Schema::MsdsGroup/;

__PACKAGE__->table("msds_group");
__PACKAGE__->has_many(
    "msds_documents",
    "BST::MsdsDocument",
    { "foreign.msds_group_id" => "self.msds_group_id"},
    { order_by => 'position'},
);


sub msds_documents {
    my $self = shift;
    return grep {!$_->document_id->is_suppressed} $self->msds_documents;
}


1;
