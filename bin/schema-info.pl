#!/usr/bin/perl

use strict;
use Data::Dumper;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use BST qw(schema);

=pod USAGE

this is a demo / test script

$ perl bin/schema-info.pl
$ perl bin/schema-info.pl Category
$ perl bin/schema-info.pl PackageItem

=cut

my $s = schema();
my $source = shift;

if ( not $source ) {
    my @sources = $s ->sources;
    print "sources: ", join( ' ', @sources ), "\n";
}

else {
    my $src;
    eval { $src = $s-> source( $source ); };
    if ( not $src ) {
        print "didn't find source $source\n";
        exit;
    }        

    my $table = $src->name;
    print "source: $source\n"
        #, Dumper( $src )
        ;
    print "table: $table\n";
    
    print "primary key: ", join( ' ', $src->primary_columns ), "\n";
    print "columns: ", join( ' ', $src->columns ), "\n";
    print "relationships: ", join( ' ', $src->relationships ), "\n";
    
}
