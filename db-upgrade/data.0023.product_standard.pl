#!/usr/bin/perl

use strict;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Data::Dumper;
use BST::Config;
use BST;
use DBI;

my $config = BST::configuration();
my $dbh = BST::dbh();

my $sth = $dbh->prepare("SELECT * FROM product_standard WHERE standard_document_identifier LIKE '%;%' OR standard_document_identifier LIKE '%,%'");
$sth->execute();

my $all = $sth->fetchall_arrayref({});

my $update = $dbh->prepare("UPDATE product_standard SET standard_parameters = ?, standard_document_identifier = ? WHERE standard_document_identifier = ? AND product_id = ?");
my $insert = $dbh->prepare("INSERT INTO product_standard (standard_parameters, standard_document_identifier, standard_org_id, product_id) VALUES (?, ?, ?, ?)");
my $status = $dbh->prepare("UPDATE product SET buildsite_private_notes = COALESCE(buildsite_private_notes, '') || 'Needs standard verification' WHERE product_id = ?");

foreach (@$all) {
    $_->{standard_document_identifier} =~ s/[;,]+\s*$//;
    my @rows = split /\s*[;,]\s*/, $_->{standard_document_identifier};
    my $params = $_->{standard_parameters} ? [ $_->{standard_parameters} ] : [];
    while (@rows && $rows[@rows - 1] =~ m/^(Type|Class|Grade)/) {
        push @$params, pop @rows;
    }

    $_->{standard_parameters} = @$params ? join(@$params) : undef;

    $update->execute(
        $_->{standard_parameters},
        shift @rows,
        $_->{standard_document_identifier},
        $_->{product_id}
    ) or die $dbh->errstr;

    while (@rows) {
        $insert->execute(
            $_->{standard_parameters},
            shift @rows,
            $_->{standard_org_id},
            $_->{product_id}
        ) or die $dbh->errstr;
    }

    $status->execute($_->{product_id});
}