# test for basic BST object cache

use strict;

use Test::More qw(no_plan);
use FindBin qw($Bin);
use lib "$Bin/../lib";

use BST;
use BST::User;
use Data::Dumper;
use Scalar::Util qw( refaddr );

sub p(@) { print @_, "\n"; }

my $rs;
$rs = BST::User->search({});
my $user = $rs->next;

p "user: $user at ", refaddr $user;
die if not $user;

my $user_id = $user->id; # save uid


# get user's location
my $loc = $user->location;
p "user's location: $loc at ", refaddr $loc;

# get the same location by other means
use BST::Location;
my $location = BST::Location->search( {account_location_id=> $user->location->id} )->next;
p "Location: $location at ", refaddr $location;

# get this location's users:
my @userlist = $location->users;
p "Users: " , join( ", ", @userlist );

# find the one we need
my ($user2) = grep {$_->id eq $user_id} @userlist;

# check
p "user (copy1): $user2 at ", refaddr $user2;
ok( refaddr $user == refaddr $user2, "same object returned" );

# retrieve another copy of user, must point to the existing object
my $user3 = BST::User->load( $user_id );
ok( refaddr $user == refaddr $user3, "same object returned" );
p "user (copy2): $user3 at ", refaddr $user3;


# no need to worry about saving changes here.
# we only test that the same object is being returned by BST.
