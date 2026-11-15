use strict;
use warnings;

use FindBin qw~$Bin~;
use lib "$Bin/../lib";
use BST;

# data model
my $schema = BST->schema;

#print localtime() . "\n";

for (my $i = 0; $i < 10000; $i++)
{

	my $o = $schema->resultset('CustomerUser')->find( { "login_id" => "IvanTest4\@buildsite.com" } );
	die if not $o;

}

#print localtime() . "\n";


