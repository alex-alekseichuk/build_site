use strict;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Data::Dumper;
use DBI;
use BST;

my $scripts = [
    'db-upgrade/struct.0053.update_category_counts.sql'
    ,'db-upgrade/data.0013.category_full_title.pl'
    ,'db-upgrade/data.0016.set_is_green_column.pl'
    ,'db-upgrade/data.0018.company_counts.sql'
];

my $config = BST::configuration();

my $perl = $config->{perl_command} || 'perl %%script%%';
my $psql = $config->{psql_command} || 'psql -f %%script%% %%dbuser%% %%dbname%%';

my $dbuser_arg;
if( $config->{dbuser} ) {
    $dbuser_arg = "-U " . $config->{dbuser};
} else {
    $dbuser_arg = '';  
}

$psql =~ s/%%dbname%%/$config->{dbname}/eg;
$psql =~ s/%%dbuser%%/$dbuser_arg/eg;
$psql =~ s/%%dbpass%%/$config->{dbpass}/eg;


for (my $i = 0; $i < scalar @$scripts; $i++) {
    my $script = $scripts->[$i];
    my $retval;

    if ($script =~ /\.pl$/) {
        my $perl2 = $perl;
        $perl2 =~ s/%%script%%/$script/eg;
        $retval = system "$perl2";
    } elsif ($script =~ /\.sql$/) {
        BST::run_sql_file($script);
    } else {
        print STDERR sprintf("Unknown script type: %s\n", $script);
        next;
    }

    print "$script: $? (retval: $retval)\n";
    # This check does not work. Even if our script fails, we may still get 0 in $? and in $retval.
    # one of the reasons for that is when an error happens inside a transaction, the transaction 
    # is successfully aborted. Successfully is the key word here.
    # One way to notice the error is to listen to STDERR of psql.
    exit if $?;

}

print "$0: success\n";

1;
