use strict;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use BST;

use BST::Message;

#my $id = shift || "message277032";
my $id = shift || "message244432";

my $message = BST::Message -> load( {message_id=>$id} ) || die ("no such message");

#print $message->body . "\n";

use Data::Dumper;
print Dumper( $message );
#print "Subject: " . $message->subject . "\n";