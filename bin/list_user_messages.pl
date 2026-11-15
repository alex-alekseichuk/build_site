use strict;
use warnings;


use FindBin qw($Bin);
use lib "$Bin/../lib";
use BST;

# data model
my $schema = BST->schema;

# check for mandatory CLI parameter
if ($#ARGV < 0) {
    print "USAGE: list_user_message.pl <user_id>\n";
    exit 0;
}

my $user_id = $ARGV[0];

# get all messages sent by specified user_id
my $rs = $schema->resultset('LegacySentMessage')->search( { "sender" => $user_id } );

# output info of sent messages
while (my $message = $rs->next) {
    print to_output($message->recipient_address_type)
        . "\t" . to_output($message->message_id)
        . "\t" . to_output($message->time_sent)
        . "\t" . to_output($message->subject)
        . "\n";
}


sub to_output {
    my $s = shift;
    $s = '' unless defined $s;
    return $s;
}

