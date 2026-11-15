#!/usr/bin/perl

# list products with some companyfeatures for them, grouped by
# manufacturer and feature. Also display the feature status (live/qa).

# run:
# $ perl bin/product-features-status.pl listproducts 

# or:
# $ perl bin/product-features-status.pl listusers armortile

# prints an amount of data to the stdout, so in many cases it would
# make sense to pipe it through 'less'.



use strict;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Data::Dumper;
use Text::ASCIITable;
use DBI;
use BST;

my $schema = BST::schema;
my $config = BST::config;
my $dbh = DBI->connect('DBI:Pg:dbname=' . $config->{dbname},
       $config->{dbuser},
       $config->{dbpass}
    ) or die;

sub get_rows {
    my $query = shift;
    my @params = @_;
    my $sth = $dbh->prepare( $query ) or die "prepare failed: " . $dbh->errstr . " ($query)";
    $sth -> execute( @params ) or die "execute failed: " . $sth->errstr . " ($query)";
    my $rows = $sth->fetchall_arrayref({});
    #die Dumper( $rows );
    return @$rows;
}

sub p (@) { print @_, "\n"; }

sub print_products ($) {
    my $data = shift;
    return if not scalar @$data;
    my $t = Text::ASCIITable->new();
    $t->setCols( 'id', 'name', 'other' );
    foreach (@$data) {
        $t->addRow( $_->{product_id}, $_->{product_name}, $_->{has_related} || '' );
    }
    print $t;
}



my $op = shift || die 'no command given';
{ no strict; 
  & $op (); }

sub listproducts {
    my $row = {};
    my $mfg = $row->{company_id};

    my @_productfeatures = qw( productmatch systemseller relatedseller );
    my $productfeatures = { map {$_=>1} @_productfeatures };
    
    # companyresource

# we could go through all of the company_feature rows
# and check if the corresponding additional data (like 
# the mfg_short_text) is present in the database

    my $companies = {};
    my @rows = get_rows( "select * from company_feature" );
    for my $row (@rows) {
        my $fname = $row->{feature_name};
        my $mfg = $row->{company_id};
        if ($productfeatures->{$fname}) {
            no strict;
            my $products = &{ 'check_for_' . $fname }( $mfg );
            $companies ->{$mfg} ->{$fname} ->{products} = $products;
            $companies ->{$mfg} ->{$fname} ->{status} = $row->{feature_status};
            if (scalar @$products) {
                p "mfg: $mfg\tfeature: $fname", "\tstatus: ", $row->{feature_status};
                #p "products: ", scalar @$products;
                print_products( $products );
            }

        }
    }
    
}    


sub listusers {
    foreach my $mfg ( @ARGV ) {
        my @accounts = get_rows( "select account_id from account where customer_id like '\%company_id-$mfg'" );
        my $account = $accounts[0]{account_id};
        p "mfg $mfg has account $account";
        my @users = get_rows( 
"select login_id,user_password 
from account_user
 left join account_location on (account_user.primary_location=account_location_id)
where account_id=?
 and account_user.block_access=false
 and account_location.block_access=false", 
            $account );
        foreach (@users) {
            p $_->{login_id}, " : ", $_->{user_password};
        }
        
    }
}



sub check_for_productmatch {
    my $mfg = shift;
    # productmatch
    my @rows = get_rows( 
        "select product_id,product_name from product where manufacturer_id=? and mfg_short_text<>''",
              $mfg );
    return \@rows;
}

sub check_for_systemseller {
    my $mfg = shift;
    my @rows = get_rows( 
"select me.product_id,product_name,
(select count(*) from product_related where product_id=me.product_id and related_type='systemseller') as has_related 
from product me
where manufacturer_id=? 
and 
    (select count(*) from product_related where product_id=me.product_id and related_type='systemseller')
     > 0",
              $mfg );
    return \@rows;
}
sub check_for_relatedseller {
    my $mfg = shift;
    my @rows = get_rows( 
"select me.product_id,product_name,
(select count(*) from product_related where product_id=me.product_id and related_type='relatedseller') as has_related 
from product me
where manufacturer_id=?
 and 
    (select count(*) from product_related where product_id=me.product_id and related_type='relatedseller')
     > 0",
              $mfg );
    return \@rows;
}

__END__

my $features= {};



# systemseller
select product_id,product_name,
(select count(*) from product_related where product_id=me.product_id and related_type='systemseller') as has_related 
from product where manufacturer_id=?

# relatedseller
select product_id,product_name,
(select count(*) from product_related where product_id=me.product_id and related_type='relatedseller') as has_related 
from product where manufacturer_id=?


