use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Getopt::Long;
use Text::Diff;
use Benchmark qw(timethese cmpthese);
use Data::Dumper;

use BST;
use BST::SearchKeywords;
use BST::Product;

my $isAnd = 1;
my $isOr = 0;
my $term = 'and';
GetOptions(
    'and|a'  => \$isAnd,
    'or|o'   => \$isOr
);
$term = 'or' if ($isOr);
#print "$term\n";


sub _search {
    my $list = shift;
    my @all = $list->all;
    return wantarray ? @all : \@all;
}

#print Dumper(@ARGV) . "\n";

#my $tokenize = sub {BST::SearchKeywords::tokenize_product_search(@_);};
my $search = sub {BST::Product->name_search(@_);};
my $search_kw = sub {BST::Product->name_search_kw(@_);};

#my ($keywords, $composite_keywords) = &$tokenize(join(' ', @ARGV));
my $what = join ' ', @ARGV;
unless ($what) {
    print STDERR "No keywords provided\n";
    exit;
}

print "\n-----------------------------------------------\n\n$what: ";

my $list = &$search($what, $term);
my @all = _search($list);
my $list_kw = &$search_kw($what, $term);
my @all_kw = _search($list_kw);

print "search: " . scalar(@all) . ", search_kw: " . scalar(@all_kw) . "\n";

my $diff = diff \@all, \@all_kw;

=c
print "Difference:\n$diff\n";
print "" . $_->product_id . "\n" for (@all);
print "" . $_->product_id . "\n" for (@all_kw);
exit;
=cut

# if there is some difference in results
if ($diff) {
    print "Difference:\n$diff\n";
}

my $r = timethese(100
    ,{
        'name_search'  => sub {
            $list = &$search($what, $term);
            @all = _search($list);
        }
        ,'name_search_kw' => sub {
            $list_kw = &$search_kw($what, $term);
            @all_kw = _search($list_kw);
        }
    });
cmpthese($r);
