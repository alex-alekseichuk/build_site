use strict;
use warnings;

use Data::Dumper;

use FindBin qw($Bin);
use lib "$Bin/../lib";
use BST;
use BST::User;

# data model
my $schema = BST->schema;

=comment
# check for mandatory CLI parameter
if ($#ARGV < 0) {
    print "USAGE: list_user_message.pl <user_id>\n";
    exit 0;
}
=cut

my $user_id = $ARGV[0] || "buildsite191196";


my $user = BST::User->load( { id => $user_id } );
my $folder = $user->sent_mail_folder;
my $messages = $folder->list( { rows => 30, page => 1, order_by => [ "time_sent desc" ] } );

foreach my $message (@$messages) {
    print to_output($message->type)
        . "\t" . to_output($message->id)
        . "\t" . to_output($message->time_sent)
        . "\t" . to_output($message->subject)
        . "\n";
}

#print Dumper( $folder);

sub to_output {
    my $s = shift;
    $s = '' unless defined $s;
    return $s;
}

