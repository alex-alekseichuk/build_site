#!/usr/bin/perl

# this is a stress-test script for BST.

# it gets BST::Category objects, one after another, 
# remembers their contents, and then repeats.  And
# then we start comparing the data with their 
# previous copies.

use strict;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Carp qw/croak/;
$SIG{__DIE__} = sub { croak @_ };

use Data::Dumper;
use BST;

sub p (@) { print @_, "\n"; }

my $dumps = {};
my $counter = 0;

my @categories = qw(  );

my $list = shift || "t/categories/categories.txt";

if(open CATLIST, $list) {
    while($_ = <CATLIST>) {
	s/_.*\n?//g;
	push @categories, $_;
    }
}


total: 
while(1) {
foreach ( @categories ) {
    my $o = BST::load( 'Category', $_ );
    if (not $o) {p "no cat: $_"; next;}
    my @related = map {$_->id} $o->related_categories;

    my $dump = Dumper( $o );
    $dump .= ' rel: ' . Dumper( [@related] );

    if ( $dumps->{$_} ) {
	# compare
	if ( $dump eq $dumps->{$_} ) {
	    print "ok $_ ";
	    $counter ++;
	} else {
	    p "nok $_";
	    p "original: ", $dumps->{$_};
	    p "new     : $dump";
	    last total;
	}
    } else {
	$dumps->{$_} = $dump;
    }
}
p $counter;
}

p "iterations: $counter";


 
