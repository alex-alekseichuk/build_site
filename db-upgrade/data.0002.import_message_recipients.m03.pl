# import sent messages recipients from sent messages table to new recipients table

use strict;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use Data::Dumper;

use BST qw/schema/;

use BST::Message;
use BST::MessageRecipient;


=c

my $message = BST::Message->load({message_id => "message277032" });
my $status = "failed";
$status = "sent" if ($message->message_status eq "sent" || $message->message_status eq "processed");
$status = "received" if ($message->message_status eq "received");
my $contact = BST::Contact->load( {private_person_id => $message->recipient_fkey});
if ($contact) {
    my $recipient = $message->add_recipient_status(
        $message->recipient_address_type,
        $contact,
        $message->recipient_address,
        $status
    );
}

=cut



my @messages = BST::Message->search( {} );

foreach my $message (@messages) {

    my $status = "failed";
    $status = "sent" if ($message->message_status eq "sent" || $message->message_status eq "processed");
    $status = "received" if ($message->message_status eq "received");
    my $contact = BST::Contact->load( {private_person_id => $message->recipient_fkey});
    if ($contact) {
        my $recipient = $message->add_recipient_status(
            $message->recipient_address_type,
            $contact,
            $message->recipient_address,
            $status
        );
    }
}

print "Messages: " . $#messages . "\n";

