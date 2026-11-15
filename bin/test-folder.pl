use strict;
use warnings;

use Carp qw(croak confess);
use Data::Dumper;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use BST;
use BST::User;
use BST::Folder;


=comment
# check for mandatory CLI parameter
if ($#ARGV < 0) {
    print "USAGE: list_user_message.pl <user_id>\n";
    exit 0;
}
=cut

#my $user_id = $ARGV[0] || "buildsite191196";
my $user_id = $ARGV[0] || "staff";

my $user = BST::User->load( { login_id => $user_id } ) || confess "Can't load user";
#my $location = $user->location;

#my $schema = BST::schema();
#my $user = $schema->resultset( 'BST::Schema::LegacyBuildsiteUser' )->find( { login_id => $user_id } );
#my $location = $user->location;

#print Dumper($schema);
#print Dumper($user);
#print Dumper($location);

=comment
print to_output($user->login_id)
    . "\t" . $location->account_location_id
    . "\t" . $user->location->account_location_id
    . "\t" . Dumper($location)
    . "\n";
=cut



#my $folder = $user->private_folder;
my $folder = $user->location_folder;
#my $folder = $user->account_folder;
#my $folder = $user->all_folder;

#my @files = $folder->list( { rows => 30, page => 1, order_by => [ "auto_ctime desc" ] } );
my @files = $folder->list( { } );
print "count: " . ($#files + 1) . "\n";
foreach my $file (@files) {
    print to_output($file->file_id)
        . "\t" . to_output($file->file_class)
        . "\t" . to_output($file->file_title)
        . "\t" . to_output($file->page_count)
        . "\n";
}

print "-----\n";


my $f = BST::Folder->load( { file_id => "private98784" } );
print "folder load: " . $f->file_title . "\n";
@files = $f->list( { rows => 30, page => 1, order_by => [ "auto_ctime desc" ] } );
print "count: " . ($#files + 1) . "\n";
foreach my $file (@files) {
    print to_output($file->file_id)
        . "\t" . to_output($file->file_class)
        . "\n";
}




sub to_output {
    my $s = shift;
    $s = '' unless defined $s;
    return $s;
}

