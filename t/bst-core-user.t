use strict;

use Test::More qw(no_plan);

use FindBin qw($Bin);
use lib "$Bin/../lib";

use BST;
use BST::User;

my $u = BST::User->load(login_id => 'hsilverman');
isa_ok($u, 'BST::Core');
ok($u->login_id eq 'hsilverman', 'login ok');
ok($u->authenticate_login('flag3web'), 'auth ok');

$u = BST::User->load(user_id => 'buildsite192523');
isa_ok($u, 'BST::Core');
ok(!$u->authenticate_login('test'), 'auth failed - its ok');
ok(($u->error->messages)[0] eq 'account_is_blocked', 'error message ok');

1;
