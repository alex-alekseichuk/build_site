package BST::SettingItem::AreaCode;

use strict;
use base qw( BST::SettingItem::Default );


sub validate_value {
    my $self = shift;
    my $value = shift;

    return length $value =~ m/^\d{3}$/ ? 1 : 0;
}

sub get_field_params() {
    my $self = shift;
    return {
        type => $self->get_type(),
        maxlength => 3
    };
}

=head1 AUTHOR

Nikolai Liohenki <kalyansky@gmail.com>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
