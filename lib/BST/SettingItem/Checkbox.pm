package BST::SettingItem::Checkbox;

use strict;
use lib qw(../../../lib);
use base qw( BST::SettingItem::Default );


sub get_type {
    return 'checkbox';
}

sub get_field_params {
    my $self = shift;
    return {
        type => 'radio',
        options => [ 
            { 'n' => 'Off' },
            { 'y' => 'On' }
        ]
    };
}


=head1 AUTHOR

Nikolai Liohenki <kalyansky@gmail.com>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
