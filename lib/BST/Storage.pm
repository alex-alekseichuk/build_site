package BST::Storage;

use strict;
use warnings;

use base qw/DBIx::Class::Storage::DBI::Pg/;

our $_LOCKING = 0;

sub _select {
    my $self = shift;
    $_LOCKING = $_[3]->{locking} eq 'update' ? 1 : 2 if defined $_[3]->{locking};
    $self->SUPER::_select(@_);
}
sub sth {
    my ($self, $sql) = @_;
    # 3 is the if_active parameter which avoids active sth re-use
    if ($_LOCKING) {
        $sql .= $_LOCKING == 1 ? ' FOR UPDATE' : ' FOR SHARE';
        $_LOCKING = 0;
    }
    return $self->dbh->prepare_cached($sql, {}, 3);
}

1;
