#!/usr/bin/perl

use strict;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Data::Dumper;
use BST::Config;
use BST;
use DBI;

my $dbh = BST::dbh();

my $owners = $dbh->selectall_arrayref("SELECT DISTINCT owner FROM addressbook_company", { Slice => {} });

foreach (@$owners) {
    my $sql = sprintf 'UPDATE addressbook_person SET owner = %1$s WHERE addressbook_company_id IN (SELECT addressbook_company_id FROM addressbook_company WHERE owner = %1$s)', $dbh->quote( $_->{owner} );
    $dbh->do($sql) or die $dbh->errstr;
}

my $empty_owner = $dbh->selectall_arrayref("SELECT * FROM addressbook_person WHERE owner IS NULL", { Slice => {} });

foreach (@{ $empty_owner }) {
    my $owner = $dbh->selectrow_array("SELECT owner FROM addressbook_company WHERE addressbook_company_id = ?", undef, $_->{addressbook_company_id});

    $dbh->do('UPDATE addressbook_person SET owner = ? WHERE private_person_id = ?', undef, $owner, $_->{private_person_id}) or die $dbh->errstr;
}

$dbh->do('ALTER TABLE addressbook_person ALTER COLUMN owner DROP DEFAULT') or die $dbh->errstr;
$dbh->do('ALTER TABLE addressbook_person ALTER COLUMN owner SET NOT NULL') or die $dbh->errstr;
