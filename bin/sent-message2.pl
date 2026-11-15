use strict;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use Data::Dumper;

use BST qw/schema/;

use BST::Message;
use BST::Contact;
use BST::ContactCompany;
use BST::User;



my $m = BST::Message->load( { message_id => 'message241071' } );
$m->add_recipient(
    "email",
    undef,
    "kikudjiro\@gmail.com");
$m->send();

=c
my $u = BST::User->load( { user_id => 'staff' } ) || die ("can't load user");

my $message = BST::Message->create_message($u, "test_10", "test 10.");
#$message->save(); # ?

$message->add_recipient(
    "email",
    undef,
    "kikudjiro\@gmail.com");
=cut



#my $cc = BST::ContactCompany->load( { private_company_id => 'private195252' } ) || die ("can't load user");
=c
my $query = "al";

        my $rs = &schema->resultset( "BST::Contact" )->search(
        {}, 
        {
            join => 
                {'legacy_account_private_company' => "BST::ContactCompany",}
            
        });
        my $rows= $rs->all;
=cut

=c
        my @cons = BST::Contact->search( {}, {
            alias => 'contact',
            from => [
                {contact => 'legacy_account_private_person'},
                {legacy_account_private_company => 'legacy_account_private_company'}
            ]
        } );
=cut

=c
        my @cons = BST::Contact->search( { -or => [
            {'given_name' => {'like', $query . "%"}},
            {'family_name' => {'like', $query . "%"}},
            {'given_name || family_name', {'like', $query . "%"}},
        ]}, {
            'join' => [qw/ ContactCompany /],
            'select' => [qw/ private_person_id given_name family_name /],
            'as' => [qw/ private_person_id given_name family_name /],
            'order_by' => "given_name, family_name"
        } );
=cut
        #my @json = map({id=>$_->private_person_id, name => $_->given_name . " " . $_->family_name, company_name => $_->company_name, company_id => $_->company_id }, @cons);


=c
# load user (from)
my $u = BST::User->load( { user_id => 'staff' } ) || die ("can't load user");

# load contact (to)
my $contact = BST::Contact->load( { private_person_id => "private19318" } ) || die ("can't load contact");
print $contact->name . "\n";

# create, send and save the message
my $m2 = BST::Message->send_email_to_contact($contact, $u, "test message", "body of the message.");
my $message_id = $m2->message_id;
=cut

=c
my $m2 = BST::Message->create( { body => "test body" } );
my $message_id = "message_" . BST::Message->get_id;
$m2->message_id($message_id),
#print Dumper($m2) . "\n";
$m2->body_file_name(""),
$m2->body(""),
$m2->sender($u),
$m2->owner($u->location),
#$m2->recipient_fkey($contact->private_person_id),
$m2->recipient_fkey($contact),
$m2->recipient_address(""),
$m2->recipient_address_type(""),
$m2->time_sent(time),
$m2->attached_file_ids(""),
#$m2->save;
#$m2->insert; # uncomment this to realy insert new record to db table
#$m2->update;

=cut

print "---\n";

#my $message2 = BST::Message->load( { message_id => $message_id } );
#print $message2->message_id . "\n";

sub to_output {
    my $s = shift;
    $s = '' unless defined $s;
    return $s;
}

