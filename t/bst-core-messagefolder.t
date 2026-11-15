use strict;

#use Test::More qw(no_plan);

use FindBin qw($Bin);
use lib "$Bin/../lib";

#use_ok('BST::MessageFolder');

use BST::User;


my $u = BST::User->new({login => 'ginagraves'});

my $folder = $u->sent_mail_folder;

print $folder->count, "\n";

my $message = $folder->get('message245377');
print $message->{subject}, "\n";

#ok($u->login('neo') eq 'neo', 'login ok');

1;
