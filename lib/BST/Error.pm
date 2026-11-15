package BST::Error;

use strict;

use Carp qw/croak/;
use base qw/Class::Singleton/;
use Data::Dumper;

# define here error methods
my @attr = qw(
user_is_blocked
wrong_password
account_location_is_blocked
account_is_blocked
account_expired
bad_username
bad_contact
cant_send_message
page_not_found
object_not_found
setting_value_invalid
size_limit_exceeded
wrong_recipient
smtp_failed
file_is_too_large
wrong_file_type
bad_account_id
bad_location_nickname
bad_user_login_id
customer_id_is_required
location_exists
account_exists
user_exists
user_exists_simple
save_failed
company_exists
invalid_zipcode
);

=head1 messages
    returns a arrayref with messages, basic defined check called status - do status call before retrieving all messages
=cut
my @messages = ();

sub status { scalar @messages }
sub messages { @messages }

sub DESTROY {
    @messages = ();
}

our $AUTOLOAD;

sub AUTOLOAD {
    my $self = shift;
    my ($m) = ($AUTOLOAD =~ /::([^:]+)$/);
    croak "unknown attribute $m"
        unless grep {$_ eq $m} @attr;
    push @messages, $m;
}

1;
