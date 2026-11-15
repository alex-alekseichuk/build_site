package BST::SettingItem::Select;

use strict;
use base qw( BST::SettingItem::Default );


sub get_type {
    return 'select';
}

sub get_field_params {
    my $self = shift;
    return {
        type => $self->get_type(),
        options => $self->get_values_list(),
        multiple => $self->is_multiple,
    };
}

sub is_multiple {
    return 0;
}

sub validate_value {
    my $self = shift;
    my $value = shift;
 
    my $values = $self->get_values_list();
    if ($self->is_multiple()){
        my @values = split ";", $value;
        for my $v (@values) {
            return 0 unless grep {$_->[0] eq $v} @$values;
        }
        return 1;
    }
    else {
        return grep {$_ eq $value} keys %$values;
    }
}

1;
