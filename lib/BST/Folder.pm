package BST::Folder;

use strict;
use warnings;
use Carp qw(croak);

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

=head1 DESCRIPTION
    Class represents folder in the database.
=cut

sub create {
    my $class = shift;
    my $columns = shift || {}; # optional

	$columns->{file_class} = "folder"; # if (! exists($columns->{file_class}));

	return $class->next::method($columns);
}

sub search {
    my ($class, $cond, $attrs) = validate_pos(@_,
                 { type => SCALAR },
                 { type => HASHREF | UNDEF },
                 { type => HASHREF, optional => 1 },
    );
    $cond->{file_class} = "folder";
    return $class->next::method($cond, $attrs);
}


sub list {
    validate_pos( @_,
		  { type => OBJECT },
		  { type => HASHREF, optional => 1 },
	);
    my ($self, $page_params) = @_;

    $page_params->{prefetch} = ['creator_user'];
    return BST::search('FolderItem',
        {
              %{ BST::FolderItem->get_default_search_filter() },
            parent => $self->file_id,
        },
        $page_params 
    );

}



1;
