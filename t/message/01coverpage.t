use strict;
use FindBin qw($Bin);
use lib "$Bin/../../lib";
use Test::More qw(no_plan);

use BST;
use BST::User;
use Data::Dumper;
use BST::Message;
use BST::Contact;
use BST::MessageRecipient;

my $message = BST::Message->load({message_id => 'message43758'});

$message->add_recipient(
            "fax",
            BST::Contact->load({private_person_id => 'private5184'}),
            "(510)+763-4399");

foreach my $recipient ($message->recipients) {
	$recipient->generate_fax_cover();
last;
}

