use strict;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Benchmark;

use BST;
use BST::Product;

my $t0 = new Benchmark;

foreach my $q ('a000' .. 'e999') { () = BST::Product->astm_search($q); }

my $t1 = new Benchmark;

my $td = timediff($t1, $t0);

print timestr($td, 'all'), "\n";
