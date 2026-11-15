package BST::Contact;

use strict;
use warnings;
use Carp qw (croak);

use Params::Validate qw(:all);

use BST::Message;
use BST::Location;
use BST::Settings;

use Data::Dumper;
use POSIX qw(strftime);

# order of the base classes is significant
use base qw/BST::Core BST::Schema::AddressbookPerson/;
__PACKAGE__->table('addressbook_person');

=head1 DESCRIPTION

Contact object

=cut

__PACKAGE__->inflate_column(
    work_phone  => {
        inflate => \&BST::Core::_phone_inflate,
        deflate => \&BST::Core::_phone_deflate,
    },
);
__PACKAGE__->inflate_column(
    cell_phone  => {
        inflate => \&BST::Core::_phone_inflate,
        deflate => \&BST::Core::_phone_deflate,
    },
);
__PACKAGE__->inflate_column(
    fax_phone   => {
        inflate => \&BST::Core::_phone_inflate,
        deflate => \&BST::Core::_phone_deflate,
    },
);
__PACKAGE__->inflate_column(
    home_phone  => {
        inflate => \&BST::Core::_phone_inflate,
        deflate => \&BST::Core::_phone_deflate,
    },
);
__PACKAGE__->inflate_column(
    pager_phone => {
        inflate => \&BST::Core::_phone_inflate,
        deflate => \&BST::Core::_phone_deflate,
    },
);

__PACKAGE__->belongs_to(
  "addressbook_company_id",
  "BST::ContactCompany",
  { addressbook_company_id => "addressbook_company_id" },
  { join_type => "left" }
);

__PACKAGE__->has_many(
  "messages",
  "BST::MessageRecipient",
  { "foreign.contact_id" => "self.private_person_id" },
);

sub name {
    my $self = shift;
    my $s = "";
    $s .= $self->given_name if $self->given_name;
    $s .= ' ' if $self->given_name && $self->family_name;
    $s .= $self->family_name if $self->family_name;
	return $s;
}

sub address_field {
    my $pkg = shift;
    my $addr = shift;

    my $type = $pkg->detect_type($addr);
    return 'email_address' if $type eq 'email';
    return 'fax_phone' if $type eq 'fax';
    return undef;
}


sub detect_type {
    my $pkg = shift;
    my $address = shift;
    # return 'fax' if $address =~ m/^[\(\)\+\s\d]+$/;
    return 'email' if $address =~ m/@/;
    return 'fax';
    # return 0;
}

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


sub is_nameless {
    my $self = shift;

    my $name = $self->given_name || '';
    my $fax = $self->fax_phone || '';
    my $email = $self->email_address || '';
            
    s/^\s*(.*?)\s*$/$1/ for $name, $fax, $email;
    return 'email' if $name eq $email;
    return '' unless $fax;

    $name =~ s/[^\d]//g;
    $fax  =~ s/[^\d]//g;
    return 'fax' if $name eq $fax;

    return '';
}

sub name_search {
    my $query = shift;
    
    
}

1;
