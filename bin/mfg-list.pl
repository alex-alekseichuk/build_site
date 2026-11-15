use strict;

# list manufacturers
#  - search by name
#  - search by a criteria
#
# $ perl bin/mfg-list.pl tite
# $ perl bin/mfg-list.pl -or tite bond
# $ perl bin/mfg-list.pl roadware


use FindBin qw($Bin);
use lib "$Bin/../lib";
use Data::Dumper;

use BST;
use BST::Company;

my $query = {};
my @rest = ();
my $key;
my $term = 'and';
my $category;
foreach (@ARGV) {
    if ($key) { 
        $query->{$key} = $_;
        next;
    }
    if ($category eq '?') {
        $category = $_;
        next;
    }
    if ( m!^-or$! ) {
        $term = 'or';
        next;
    }
    if ( m!^-category! ) {
        $category = '?';
        next;
    }
    if ( m/^\-([\w\.]+)/ ) {
        $key = $1;
        next;
    }
    push @rest, $_;
}

my $nameq = join ' ', @rest;

my $rs;
if ($nameq) {
    $rs = BST::Company->mfg_name_search( $nameq, $term );
} elsif ($category) {
    $rs = BST::Company->search_by_category( {'p.category_id' => $category} );
} else {
    $rs = BST::Company->search( $query );
}

use Text::SimpleTable;

my @column_sizes = qw( 35 40 30 10 5 );
my $tab = Text::SimpleTable->new( @column_sizes );

my $count = 0;
if ($rs) {
    foreach ($rs->all) {
        $count++;
        if (1 and $tab) {
            $tab->row( 
                $_->company_id,
                $_->name,
                $_->legal_name,
                ($_->companyresource_active || ''),
                );

        } elsif(1) {
            print $_->company_id, 
            "\t", $_->name, 
            "\n";
        }        
    }
}

print "found: $count\n";
if( $tab ) {
    print $tab->draw;
}
