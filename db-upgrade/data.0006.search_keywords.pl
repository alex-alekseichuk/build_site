use strict;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Data::Dumper;

use DBI;
use BST;
use BST::Product;
use BST::Company;
use BST::Category;

my $products = BST::Product->search({});

#while ( my $i = $products->next ) {
#    $i->product_name_search_keywords(join( ' ', map { $_->keyword if length $_->keyword >= 3 } $i->product_keywords()->all ));
#    $i->save;
#}

undef $products;

my $companies = BST::Company->search({ company_type => 'manufacturer' });

while ( my $i = $companies->next ) {
    $i->company_search_keywords(join( ' ', map { $_->keyword if length $_->keyword >= 3 } $i->company_keywords()->all ));
    $i->save;
#    print Dumper $i->company_search_keywords;
#    last;
}

undef $companies;


my $categories = BST::Category->search({});

while ( my $i = $categories->next ) {
    $i->category_search_keywords(join( ' ', map { $_->keyword if length $_->keyword >= 3 } $i->category_keywords()->all ));
    $i->save;
}

undef $categories;

my $dbh = BST::dbh();

$dbh->do(<<'');
UPDATE product p SET product_name_search_tsvector = to_tsvector('public.buildsite', p.product_name_search_keywords);

$dbh->do(<<'');
UPDATE company SET company_search_tsvector = to_tsvector('public.buildsite', company_search_keywords);

$dbh->do(<<'');
UPDATE category SET category_search_tsvector = to_tsvector('public.buildsite', category_search_keywords);

$dbh->do(<<'');
UPDATE product_standard SET astm_search_tsvector = to_tsvector('public.buildsite', astm_search_keywords);

$dbh->do(<<'');
UPDATE product p
       SET product_name_ext_search_tsvector = product_name_search_tsvector || cc.category_search_tsvector || c.company_search_tsvector
       FROM company c,  category cc
       WHERE c.company_id = p.manufacturer_id AND cc.category_id = p.category_id;

1;
