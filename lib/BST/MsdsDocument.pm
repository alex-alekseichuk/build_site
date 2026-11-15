package BST::MsdsDocument;

use strict;
use warnings;

use base qw/BST::Core BST::Schema::MsdsDocument/;

__PACKAGE__->table("msds_document");
__PACKAGE__->belongs_to(
  "document_id",
  "BST::Document",
  { document_id => "document_id" },
);


1;
