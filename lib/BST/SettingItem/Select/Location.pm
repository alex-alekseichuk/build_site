package BST::SettingItem::Select::Location;

use strict;
use base qw( BST::SettingItem::Select );


sub get_values_list {
  my $self = shift;

  my @locations;

  my $ref = ref $self->owner;

  if ($ref =~ m/::User/) {
    @locations = $self->owner->account->locations;
  } elsif ($ref =~ m/::Account/) {
    @locations = $self->owner->locations;
  } elsif ($ref =~ m/::Location/) {
    @locations = $self->owner->account->locations;
  } else {
    die("Invalid owner: needed User|Location|Account and got $ref");
  }

  my %locations = map {;
    {$_->account_location_id => $_->location_nickname}
  } @locations;
  return \%locations;
}


1;
