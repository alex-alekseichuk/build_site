package BST::RootFolder;

use strict;
use warnings;
use Carp qw(croak);
use Params::Validate qw(:all);

use BST;
use BST::FolderItem;
use BST::User;
use BST::Location;

=head1 DESCRIPTION
    Class represents one of 3 root folders: User, Location, Account
=cut

sub new {
	my ( $class, $user, $scope ) = @_;
	my $self = bless({}, ref $class || $class);

    $self->{user} = $user;
    $self->{scope} = $scope;

	return $self;
}


sub scope {
    return shift->{scope};
}

=head1 get a part of sorted list of FolderItem's from this Files list
    
=cut

sub list {
    validate_pos( @_,
		  { type => OBJECT },
		  { type => HASHREF },
	);
    my ($self, $page_params) = @_;
    $page_params->{prefetch} = ['creator_user'];

    if (! BST::Scope->is_all($self->{scope})) {
        return BST::search('FolderItem', 
            {
                parent => undef,
                %{ BST::FolderItem->get_default_search_filter() },
                %{ BST::FolderItem->get_scope_search_filter( $self->{scope}, $self->{user} ) },
                scope => $self->{scope},
            },
            $page_params
        );
    } else { # all
        my $ors = [];
        foreach my $scope (BST::Scope::USER, BST::Scope::LOCATION, BST::Scope::ACCOUNT) {
            push @$ors, { -and => [ 
                    %{ BST::FolderItem->get_scope_search_filter( $scope, $self->{user} ) },
                    scope => $scope
                ]
            };
        }
        return BST::search('FolderItem',
            {
                %{ BST::FolderItem->get_default_search_filter() },
                parent => undef,
                -or => $ors,
            },
            $page_params 
        );
    }
}


1;
