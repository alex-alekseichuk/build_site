package StressCategory;

use strict;

use Category qw(get_categories);

use Test::Class;
use Test::More;
use Data::Dumper;

use base qw( lib::Category );

*get_categories = 'lib::Category::get_categories';

my $count = 0;
my $stop = 0;

$SIG{INT} = $SIG{TERM} = sub {
    print "stop carefully\n";
    $stop =1;
};

sub test_stress : Test {
    my $self = shift;

    foreach (get_categories($self->{_config}->{CATEGORIES_FILE})) {
        diag("Check category: $_");
        
        $self->{_new_page}  = $self->get_buildsite_new_category_detail_page($_);
	
	my $cat = $_;
	my $now = {
            products        => $self->get_new_products(),
            manufacturers   => $self->get_new_manufacturers(),
            categories      => $self->get_new_categories()
        };
	if( not %{$now->{products}} 
	    or not %{$now->{manufacturers}} 
	    or not %{$now->{categories}} ) {
	    ok( 0, "empty data: $_" );
	}
	#my $dump = Dumper( $now );

	if( $self->{store}{$cat} ) {
	    is_deeply( $now, $self->{store}{$cat} );
	} else {
	    $self->{store} {$cat} = $now;
	}
	last if $stop;
    }

    $self->test_stress() 
	if $count++ < 15 and not $stop;

}

1;
