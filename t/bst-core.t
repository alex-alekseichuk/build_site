use strict;

use Test::More qw(no_plan);

use FindBin qw($Bin);
use lib "$Bin/../lib";

use BST;
use BST::User;
use Data::Dumper;

my $rs;
$rs = BST::User->search(undef);
my $user = $rs->next;

my $val = 'changed value';
my $user_id = $user->user_id; # save uid
my $sval = $user->location->location_fullname; # save value to restore it at the end

ok( $user->location->location_fullname($val) eq $val, 'vaue changed' );

$rs = BST::User->search({ user_id => $user_id}); # retrieve another copy of user, must point to existing one
ok( $rs->next->location->location_fullname eq $val, 'chaged value retrieved from another rs' );

# save test
$user->save();
undef $user;

# clear cache
my $c = BST::obj_cache();
$c = {};
undef $c;

$rs = BST::User->search({ user_id => $user_id}); # retrieve another copy of user
my $user = $rs->next;
ok( $user->location->location_fullname eq $val, 'chaged value retrieved from another rs, after saving and cache flush' );

$user->location->location_fullname($sval);
$user->save();

1;
