package BST::Location;

use strict;
use warnings;

use BST::Account;
use BST::Settings;

use base qw(BST::Core BST::Schema::AccountLocation);
__PACKAGE__->table('account_location');

=head1 DESCRIPTION

Account location object

=cut

__PACKAGE__->belongs_to(
  "account",
  "BST::Account",
  { "account_id" => "account_id" },
);

__PACKAGE__->has_many(
  "folder_items",
  "BST::Message",
  { "foreign.owner" => "self.account_location_id" },
);

__PACKAGE__->has_many(
  "users",
  "BST::User",
  { "foreign.primary_location" => "self.account_location_id" },
);

__PACKAGE__->has_many(
  "messages",
  "BST::Message",
  { "foreign.owner" => "self.account_location_id" },
);


sub can_read {
    my $self = shift;
    return 1;
}

sub can_write {
    my $self = shift;
    my $user = shift;

    return 1 if $user->is_bs_admin();
    return 1 if $self->account->account_id eq $user->primary_location->account->account_id;
    return 0;
}

sub settings {
    BST::Settings->new(shift)
}

1;
