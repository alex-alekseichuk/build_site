# copy sent messages body from files to database

use strict;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use Data::Dumper;
use BST;


#use utf8;
use Encode;

=a
my $m = BST::Message->load("message294848");
#print Dumper $m->body_from_file ."\n";
my $body_file = eval $m->body_from_file;
print Dumper( $body_file->{main_plain}, encode_utf8( $body_file->{main_plain} ) );
$m->body( encode_utf8( $body_file->{main_plain} ) );
$m->save;
exit;
=cut

my @messages = BST::Message->search( {} );

my $totallength = 0;
foreach my $message (@messages) {
    my $body_file = eval $message->body_from_file;
    my $body = encode_utf8( $body_file->{main_plain} );
    $message->body( $body );
    $message->save;
    $totallength += length( $body );
}

print "Messages: " . $#messages . ", characters: $totallength\n";
