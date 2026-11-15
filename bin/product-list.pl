use strict;

use FindBin qw($Bin);
use lib "$Bin/../lib";
use Data::Dumper;

use BST;
use BST::Product;

my $query = {};
my @rest = ();
my $key;
foreach (@ARGV) {
    if ($key) { 
        $query->{$key} = $_;
        next;
    }
    if ( m/^\-([\w\.]+)/ ) {
        $key = $1;
        next;
    }
    push @rest, $_;
}


#print Dumper($query);
#__END__

my $nameq = join ' ', @rest;

my $rs;
if ($nameq) {
    my ($kw, $ckw) = BST::SearchKeywords::tokenize_product_search( @rest );
    $rs = BST::Product->name_search( $kw, $ckw );
} else {
    $rs = BST::Product->search( $query );
}

use Text::SimpleTable;

my @column_sizes = qw( 35 40 30 10 5 2 2 );
my $tab = Text::SimpleTable->new( @column_sizes );

my $count = 0;
my $count2 = $rs->count;
if ($rs) {
    #print Dumper( $rs ); die;
    foreach ($rs->all) {
#        print Dumper($_);
#        die;
        $count++;
        if (1 and $tab) {
            $tab->row( 
                $_->product_id,
                $_->product_name,
                $_->manufacturer->legal_name,
                ($_->get_column("category_id") || ''),
                ($_->get_column("productmatch_status") || '-'),
                ($_->productmatch_active),
                (eval{$_->get_column('sum1')}),
#                ($_->show_system_flag),

                );

        } elsif(1) {
            print $_->product_id, "\n", 
            "\t", $_->product_name, 
            "\t", $_->manufacturer->legal_name, 
#        "\t", 
#        $_->productmatch_feature->feature_status, 
#        ($_->productmatch_feature)
#            ? $_->productmatch_feature->feature_status
#            : '-',
            '';
            my $fstatus = $_->get_column("productmatch_status");
            print "\t",
            $fstatus ? $fstatus : '-',
            "\n";
        }        
    }
}

print "found: $count2\n";
if( $tab ) {
    print $tab->draw;
}
