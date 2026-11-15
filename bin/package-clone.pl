use strict;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Data::Dumper;
use BST;
use BST::Package;

my $p = BST::Package->load( id => @ARGV[0] );


my $n = $p->clone();

$n->scope(BST::Scope::HIDDEN);
$n->save();


#system('perl', "$Bin/package-details.pl", $p->id);
#system('perl', "$Bin/package-details.pl", $n->id);
