#!/usr/bin/perl

use strict;

use FindBin qw($Bin);
use lib "$Bin/../lib";
# this is here because of some misbehaving in case of die otherwise
use Carp;
use Carp::Heavy;
use BST;
use DBI;

use GUPE::SQL::DBIUtils qw(dbopcounts);
use Data::Dumper;

sub info(@) { print scalar localtime(), " ", @_, "\n"; }

# fragments from dbsync.pl:

use BS::Search qw(set_keywords set_all_keywords);


# we can do these incremental if desired
# there must be *_keyword_handler functions defined for each of these below
our @KEYWORD_TYPES = qw(A M C P);

sub main {
    my $dbh = shift;
    for my $kt (@KEYWORD_TYPES) {
        info("set_keywords($kt)");
        set_keywords($dbh, $kt);
        info("database operations for set_keywords($kt): ", Dumper(dbopcounts()));
    }
}

#my $dbh = DBI->connect( 'dbi:Pg:dbname=bsdata_v3_dev', $ENV{PGUSER}, $ENV{PGPASSWORD} )
#    or die "can't connect to db: $DBI::errstr";
my $dbh = BST::dbh() or die;
info( "starting" ); 

$dbh->do('DROP TABLE IF EXISTS product_temp_keyword');
$dbh->do(qq~
    CREATE TABLE product_temp_keyword (
        keyword_id serial NOT NULL,
        keyword character varying(250) NOT NULL,
        keyword_type character(1) NOT NULL,
        product_id character varying(250) NOT NULL,
        score integer DEFAULT 10
    )
    WITH (
        OIDS=TRUE
    );
~);

main( $dbh );

$dbh->do(qq~
    ALTER TABLE product_temp_keyword
        ADD CONSTRAINT temp_product_keyword_pkey PRIMARY KEY(keyword_id);
    ALTER TABLE product_temp_keyword
        ADD CONSTRAINT fk_pk_product FOREIGN KEY (product_id)
            REFERENCES product (product_id) MATCH SIMPLE
            ON UPDATE CASCADE ON DELETE NO ACTION DEFERRABLE INITIALLY DEFERRED;
    ALTER TABLE product_temp_keyword
        ADD CONSTRAINT temp_product_keyword_keyword_key UNIQUE(keyword, keyword_type, product_id);

    CREATE INDEX temp_i_pk_keyword ON product_temp_keyword USING btree (keyword);
    CREATE INDEX temp_i_pk_keyword_type ON product_temp_keyword USING btree (keyword_type);
    CREATE INDEX temp_i_pk_product ON product_temp_keyword USING btree (product_id);

    DROP TABLE IF EXISTS product_keyword;

    ALTER TABLE product_temp_keyword RENAME TO product_keyword;

    ALTER SEQUENCE product_temp_keyword_keyword_id_seq RENAME TO product_keyword_keyword_id_seq;
~);

$dbh->do(qq~ALTER INDEX temp_$_ RENAME TO $_~)
    foreach qw(
        product_keyword_pkey
        product_keyword_keyword_key
        i_pk_keyword
        i_pk_keyword_type
        i_pk_product
    );

info( "done" );

1;

=pod

# this is an fragment from dbsync.pl, which we don't need at the moment,
# but we might need it later.

my %OPTS;
my $IS_INCREMENTAL;
################ populate *_keyword tables ################

sub mfg_keyword_handler {
    my ($from_dbh, $to_dbh, $fromh, $toh) = @_;
    return unless $OPTS{keywords};
    set_keywords($to_dbh, 'M', $toh, $IS_INCREMENTAL);
}

sub categ_keyword_handler {
    my ($from_dbh, $to_dbh, $fromh, $toh) = @_;
    return unless $OPTS{keywords};
    set_keywords($to_dbh, 'C', $toh, $IS_INCREMENTAL);
}

sub prodname_keyword_handler {
    my ($from_dbh, $to_dbh, $fromh, $toh) = @_;
    return unless $OPTS{keywords};
    set_keywords($to_dbh, 'P', $toh, $IS_INCREMENTAL);
}

# we do these in batch afterwards unless we are incremental,
# to avoid having to fetch all the detail rows individually.
sub prodastm_keyword_handler {
    my ($from_dbh, $to_dbh, $fromh, $toh) = @_;
    return unless $OPTS{keywords} && $IS_INCREMENTAL;
    set_keywords($to_dbh, 'A', $toh, $IS_INCREMENTAL);
}

=cut
