package BST::Account;

use strict;
use warnings;

use base qw(BST::Core BST::Schema::Account);
__PACKAGE__->table('account');

use BST::Company;
use BST::Settings;
use Data::Dumper;

=head1 DESCRIPTION
    Account object
=cut


__PACKAGE__->has_many(
  "locations",
  "BST::Location",
  { "foreign.account_id" => "self.account_id" },
);

__PACKAGE__->might_have(
  "company" => "BST::Company",
  { "foreign.company_id" => "self.company_id" },
);


sub sponsor {
    my $self = shift;
    return undef if not $self->sponsor_id;
    $self->{_sponsor} = BST::Company->load( { company_id => $self->sponsor_id } ) unless ref $self->{_sponsor};
    return $self->{_sponsor};
}


sub can_read {
    my $self = shift;
    my $user = shift;

    return 1 if $user->is_bs_admin();
    return $user->primary_location->get_column('account_id') eq $self->account_id;
}


sub can_write {
    my $self = shift;
    my $user = shift;

    return 1 if $user->is_bs_admin();    
    return $user->primary_location->get_column('account_id') eq $self->account_id && $user->is_account_admin();
}

sub get_companies_for_items {
    my $pkg = shift;
    my $items = shift;

    my $ids = [
        map {
            $_->get_column('company_id')
        } @$items
    ];

    my @companies = BST::Company->search( 
        { 'me.company_id' => $ids } 
    );

    my %compById = map {;
        $_->company_id => $_
    } @companies;

    map {
        $_->{_company} = $compById{ $_->get_column('company_id') };
    } @$items;
    
    return $items;
}


sub settings { BST::Settings->new(shift) }

1;
