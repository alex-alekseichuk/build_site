use strict;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Data::Dumper;
use BST;

my $config = BST::configuration();



my $dbh = BST::dbh();

=head1 first run: create schemaversions table, add plpgsql, create main sequence

=cut

unless (grep {'schemaversions'} $dbh->tables('', '', 'schemaversions', 'TABLE')) {
    $dbh->do(<<'');
CREATE TABLE "schemaversions" (
    "version" integer NOT NULL,
    "type" varchar(8) NOT NULL DEFAULT 'data',
    "installed" varchar(20) NOT NULL,
    PRIMARY KEY (version, type)
);

    # let bsadmin update main sequence
    $dbh->do(<<'');
grant update on schemaversions TO bsadmin;

    # create sequence
    $dbh->do(<<'');
create sequence main start 100000;

    # let bsadmin update main sequence
    $dbh->do(<<'');
grant update on main TO bsadmin;

}




my $perl = $config->{perl_command} || 'perl %%script%%';

my $ls;
my $list;
my $st;



##############################################################
# First struct.* queue
##############################################################

# ls files from ../db-upgrade
$ls = qx/ls db-upgrade | grep -v '~'/;
$list = [ grep /^struct\.\d+\./, split('\n', $ls) ];

#print Dumper ($list);

# read last executed script number, stored in db
my $currentStruct = -1;
$st = $dbh->prepare("SELECT max(version) FROM schemaversions WHERE type='struct'");
$st->execute;
($currentStruct) = $st->fetchrow_array;
$st->finish;
$currentStruct = -1 unless defined $currentStruct;

print "Current struct schema version: $currentStruct\n";

# execute all scripts after the current number until end or error
for (my $i = 0; $i < scalar @$list; $i++) {
    my $c = "$Bin/../db-upgrade/" . $list->[$i];
    $list->[$i] =~ /^struct\.(\d+)\./;
    my $n = 0 + $1;
    if ($n > $currentStruct) {
        my $retval;
        if ($c =~ /\.pl$/) {
            my $perl2 = $perl;
            $perl2 =~ s/%%script%%/$c/eg;
            $retval = system "$perl2";
        } elsif ($c =~ /\.sql$/) {
            $retval = BST::run_sql_file($c);
        }
        print "$c: $? (retval: $retval)\n";
        # This check does not work. Even if our script fails, we may still get 0 in $? and in $retval.
        # one of the reasons for that is when an error happens inside a transaction, the transaction 
        # is successfully aborted. Successfully is the key word here.
        # One way to notice the error is to listen to STDERR of psql.
        exit if $?;

        $dbh->do(
            "INSERT INTO schemaversions (version, type, installed) VALUES (" . $n . ",'struct','" . time . "')"
        );

    }
}


##############################################################
# Second data.* queue
##############################################################

# ls files from ../db-upgrade
$ls = qx/ls db-upgrade | grep -v '~'/;
$list = [ grep /^data\.\d+\./, split('\n', $ls) ];

#print Dumper ($list);

# read last executed script number, stored in db
my $currentData = -1;
$st = $dbh->prepare("SELECT max(version) FROM schemaversions WHERE type='data'");
$st->execute;
($currentData) = $st->fetchrow_array;
$st->finish;
$currentData = -1 unless defined $currentData;

print "Current data schema version: $currentData\n";

# execute all scripts after the current number until end or error
for (my $i = 0; $i < scalar @$list; $i++) {
    my $c = "$Bin/../db-upgrade/" . $list->[$i];
    $list->[$i] =~ /^data\.(\d+)\./;
    my $n = 0 + $1;
    if ($n > $currentData) {
        if ($c =~ /\.pl$/) {
            my $perl2 = $perl;
            $perl2 =~ s/%%script%%/$c/eg;
            system "$perl2";
        } elsif ($c =~ /\.sql$/) {
            BST::run_sql_file($c);
        }
        print "$c: $?\n";
        exit if $?;

        $dbh->do(
            "INSERT INTO schemaversions (version, type, installed) VALUES (" . $n . ",'data','" . time . "')"
        );
    }
}

# run deploy script.
#system 'perl', "$Bin/schema-extract.pl";

undef $dbh;

print "$0: success\n";

1;
