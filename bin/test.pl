use strict;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use BST;

use BST::Message;

my $products = BST::Product->search({
		'me.product_id', {'like', 'apoc%'}
	});
print "$products\n";

$products = BST::Product->search({
		'me.manufacturer_id', {'like', 'apoc'}
	});
print "$products\n";

$products = BST::Product->search({
		q{me.product_id || me.manufacturer_id}, {'like', 'apoc%apoc'}
	});
print "$products\n";

=c

#my $id = shift || "message277032";
my $id = shift || "message244432";

my $message = BST::Message -> load( {message_id=>$id} ) || die ("no such message");

sub p (@) { print @_, "\n"; }

p "from:    " , $message->sender->name;
p "date:    " , $message->time_sent;

#print $message->body . "\n";
my $recipients = $message->recipients;
foreach ( $recipients->all ) {
    p "to:      ", $_->address, " -- ", $_->status;
    my $name = '';
    if ($_->contact_id) {
        my $contact = $_->contact_id;
        $name .= $contact->name . " (". $contact. ")";

        if ( $contact->addressbook_company_id ) {
            $name .= ", " .
                $contact->addressbook_company_id->company_fullname . 
            " (" . $contact->addressbook_company_id . ")";
        }
        p "          - ", $name;
    }
}

p "subject: " , $message->subject;

my $package = $message->package;
p "package: ", $package;
if ( $package ) {
    my $list = $package->items;
    foreach( $list->all ) {
        p "          - ", $_->title;
        p "            ", $_->item_type, " ", $_->document_id, $_->file_id;
    }
}

use Data::Dumper;
#print Dumper( $message );

=cut
