package BST::ContactCompany;

use strict;
use warnings;
use Carp qw (croak);

use Params::Validate qw(:all);

use BST;
use BST::Contact;

use Data::Dumper;

# order of the base classes is significant
use base qw/BST::Core BST::Schema::AddressbookCompany/;
__PACKAGE__->table('addressbook_company');

=head1 DESCRIPTION

Company of the Contact object

=cut
__PACKAGE__->inflate_column(
    location_phone  => {
        inflate => \&BST::Core::_phone_inflate,
        deflate => \&BST::Core::_phone_deflate,
    },
);
__PACKAGE__->inflate_column(
    location_fax  => {
        inflate => \&BST::Core::_phone_inflate,
        deflate => \&BST::Core::_phone_deflate,
    },
);

__PACKAGE__->has_many(
  "contacts",
  "BST::Contact",
  { "foreign.addressbook_company_id" => "self.addressbook_company_id" },
);

sub can_read {
    my $self = shift;
    my $user = shift;
    return 1 if $user->is_bs_admin();    
    return $self->owner->account_location_id eq $user->_addressbook_location;
}

sub can_write {
    my $self = shift;
    return $self->can_read(@_);
}

1;
