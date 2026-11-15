package BST::Scope;

use strict;
use warnings;
use Carp qw (carp croak confess);
require Exporter;

our @EXPORT_OK = qw( ACCOUNT LOCATION USER ALL HIDDEN );
use constant ACCOUNT => 'account';
use constant LOCATION => 'location';
use constant USER => 'user';
use constant ALL => 'all';
use constant HIDDEN => 'hidden';


sub is_account {
    carp if (not defined $_[1]);
    return $_[1] eq ACCOUNT;
}

sub is_location {
    carp if (not defined $_[1]);
    return $_[1] eq LOCATION;
}

sub is_user {
    carp if (not defined $_[1]);
    return $_[1] eq USER;
}

sub is_all {
    carp if (not defined $_[1]);
    return $_[1] eq ALL;
}

sub is_hidden {
    carp if (not defined $_[1]);
    return $_[1] eq HIDDEN;
}

1;
