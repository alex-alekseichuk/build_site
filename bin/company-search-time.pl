use strict;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Benchmark;

use BST;
use BST::Company;

my $t0 = new Benchmark;

foreach my $q ('aa' .. 'zz') {
    () = BST::Company->search({
        company_type => 'manufacturer',
        q{me.legal_name || ' ' || COALESCE(me.company_nickname, '')} => [
            '-and' => map { \"~* E'\\\\m$_'" } &BST::Core::_split_search_keywords($q)
        ]
    })
}

my $t1 = new Benchmark;

my $td = timediff($t1, $t0);

print timestr($td, 'all'), "\n";
