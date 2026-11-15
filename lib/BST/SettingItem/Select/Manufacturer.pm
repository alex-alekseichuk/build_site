package BST::SettingItem::Select::Manufacturer;

use strict;
use Data::Dumper;
use BST::Company;
use BST::Category;
use base qw( BST::SettingItem::Select );

sub get_values_list {
    my $self = shift;
    my $query  = { company_type => 'manufacturer' };
    my @list = BST::Company->search($query, {order_by => 'company_nickname'});

    my $list = [];
    push @$list, [$_->company_id => $_->company_nickname] for @list;

    return $list;
}

sub is_multiple {
    return 1;
}

sub get_field_params {
    my $self = shift;
    my $r = $self->SUPER::get_field_params(@_);
    $r->{value} = [split ";", $self->setting->value];
    return $r;
}


=head1 AUTHOR

Nikolai Liohenki <kalyansky@gmail.com>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
