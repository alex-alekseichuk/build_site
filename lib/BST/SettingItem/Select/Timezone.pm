package BST::SettingItem::Select::Timezone;

use strict;
use base qw( BST::SettingItem::Select );


sub get_values_list {
    my $self = shift;
    my @zones = qw(Hawaii Alaska Pacific Arizona Mountain Central East-Indiana Eastern);
    return { map {;
        "US/" . $_ => $_
    } @zones };
}

=head1 AUTHOR

Nikolai Liohenki <kalyansky@gmail.com>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
