#!/usr/bin/perl

use strict;

# for a plain text confirmation message example 
# check out doc/interfax.15107634399

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Data::Dumper;
use BST;
use BST::MessageRecipient;
use BST::Message;
use BST::Fax::Interfax;
use BST::Fax::InterfaxResponse;

my ($line, $m, $counter);
$counter = 0;
$m = "";

while ($line = <STDIN>) {
	$counter++;
	$m .= $line;
	exit if $counter > 700;
}

my $fax = new BST::Fax::InterfaxResponse( $m );

my ($status, $rid, $message_id, $system_id);

$message_id = $fax->message_id || "undefined";
$status = $fax->status;
$rid = $fax->recipient_id;
$system_id = $fax->system_id;


if (defined $system_id && $system_id ne BST::config('system_id')) {
    info( "an incomming message (Message-ID:<$message_id>); unmatched system_id:\'$system_id\'; ignoring" );
    exit;
# it may be "0", so we have to check it for being defined
} elsif (!defined $status || !defined $rid) {
    info( "an incomming message (Message-ID:<$message_id>); couldn't parse it; ignoring" );
    exit;
} else {
    info( "an incomming message (Message-ID:<$message_id>). status: \'$status\' recipient: \'$rid\'" );
}

exit unless (defined $status && defined $rid);

my $robj = BST::MessageRecipient->load(id => $rid);

unless ($robj) {
    error( "Can\'t load message recipient. id: $rid" );
    exit;
}

if ($robj->message_id) {
    debug( "recipient found, message found" );

    my $message = BST::Message->load({message_id => $robj->message_id});
    my $mp      = join('/', BST::config('sent_messages_path'), substr($message->auto_ctime, 0, 4), substr($message->auto_ctime, 5, 2), $message->message_id);

    `mkdir -p $mp` unless (-e $mp);

    my $filename = $mp . '/' . $robj->id . "_" . time;

    if (open FILE, ">$filename") {
        print FILE $m;
        close FILE;
        info( "saved the message to $filename" );
    } else {
        info("Error opening $filename file");
    }
}


my $rec_status = ($status eq '0') ? 'sent' : BST::Fax::Interfax->get_status($status);

$robj->status( $rec_status );
$robj->save;
debug( "set recipient status to: $rec_status" );



if ($status ne '0') {
    my $message = BST::Message->load({message_id => $robj->message_id});
    $message->message_status_ack('none');
    $message->save();
    debug( "set message_status_ack to: none" );
}

if ($robj->message_id) {
    my $message = BST::Message->load({message_id => $robj->message_id});
    $message->update_status();
    $message->save();
}


#debug(qq~status - $status, recipient id - $rid\n~);



sub warning {
    BST::Core->logger->warning(
	'fax-status-responder: ' . shift,
        name => 'messages');
}

sub info {
    BST::Core->logger->info(
	'fax-status-responder: ' . shift,
        name => 'messages');
}

sub debug {
    BST::Core->logger->debug(
	'fax-status-responder: ' . shift,
        name => 'messages');
}

sub error {
    BST::Core->logger->error(
	'fax-status-responder: ' . shift,
        name => 'messages');
}



1;

