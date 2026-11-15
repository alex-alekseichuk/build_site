use strict;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use Data::Dumper;
use BST;

use Text::Iconv;
my $converter = Text::Iconv->new("", "utf-8");

=c
my $m = BST::Message->load("message201967");
print $m->body_from_file ."\n";
my $body_file = eval $m->body_from_file;
print Dumper($body_file) ."\n";
$m->body($converter->convert($body_file->{main_plain}));
$m->save;
=cut


my @messages = BST::Message->search( {} );

foreach my $message (@messages) {
    my $body_file = eval $message->body_from_file;
    $message->body($converter->convert($body_file->{main_plain}));
    $message->save;
}

print "Messages: " . $#messages . "\n";
