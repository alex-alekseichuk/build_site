use strict;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Carp qw/croak/;
$SIG{__DIE__} = sub { croak @_ };

use Data::Dumper;
use BST;
use BST::User;

my $location = BST::search('Location', undef, { rows => 1 })->next;
my $user = BST::schema()->resultset('BST::User')->new_result(
    {
        user_id       => 'mefalse1231212341',
        user_password => ($ENV{BST_TEST_PASS} or die "set the BST_TEST_PASS env var"),
        family_name   => 'pats',
        login_id      => 'awdawdawdaw1243d1',
        given_name    => 'yuri',
        
    },
#    { schema => BST::schema }
);
$user->location($location);

#my $rst = BST::search('User', undef)->next->result_source;

#$user->result_source($rst);

$user->insert;

print Dumper $user;
