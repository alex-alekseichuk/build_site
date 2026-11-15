# BST object cache, test for folder items caching

use strict;

use Test::More qw(no_plan);
use FindBin qw($Bin);
use lib "$Bin/../lib";

use BST;
use BST::FolderItem;
use Data::Dumper;
use Scalar::Util qw( refaddr reftype );

sub p(@) { print @_, "\n"; }

# get a sample file object, through a folder items listing (i.e. search)
my $rs;
$rs = BST::FolderItem->search({owner=>"whitecap_naples_250", scope=>BST::Scope::LOCATION});
p "File items: $rs";

my $file = $rs->next;
p "File: $file at " . refaddr $file;
ok( $file, "we have a file to test against" );

# get the same file via BST::FolderItem->load
my $file2 = BST::FolderItem ->load( $file->id );
p "File: $file2 at " . refaddr $file2;
ok( refaddr $file == refaddr $file2, "same object retrieved" );

# and the same file via BST::File
$file2 = BST::File ->load( $file->id );
p "File: $file2 at " . refaddr $file2;
ok( refaddr $file == refaddr $file2, "same object retrieved" );


1;