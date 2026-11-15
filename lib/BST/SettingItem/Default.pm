package BST::SettingItem::Default;

use strict;
use base qw( BST::SettingItem );


sub get_values_list() {
    return [];
}

sub get_field_params {
    my $self = shift;
    return {
        type => $self->get_type(),
        required => 0,
    };
}

sub validate_value {
    my $self = shift;
    my $value = shift;
    return 1;
}

sub get_type {
    return 'text';
}

1;
