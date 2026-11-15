
use strict;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Data::Dumper;
use BST;


my $config = BST::configuration();

my $logger = BST::Logger->instance;
$logger->log({ name => 'dbcheck', level => 'info', message => 'Started' });


# get all dbcheck scripts
my $dbscripts_dir = $config->{home} . '/dbcheck';
my @files;
if (opendir(DIR, $dbscripts_dir))
{
    @files = grep {$_} map {
        if (/^(\d+)_([^.]+)\.(pl|sql|py)$/) {
            {file=>$_, n=>$1, id=>$2, type=>$3};
        } else {
            undef;
        }
    } readdir(DIR);
    closedir DIR;
} else {
    $logger->log({ name => 'dbcheck', level => 'error', message => "Can't open folder " . $dbscripts_dir });
    die "Can't open folder " . $dbscripts_dir . "\n";
}


# tempalte for running perl script
#my $perl = $config->{perl_command} || 'DBIC_TRACE=1 perl %%script%%';
my $perl = $config->{perl_command} || 'perl %%script%%';

my $dbh = BST::dbh();


# process all dbcheck scripts one by one
for my $file (@files) {
    #print Dumper($file) . "\n";
    my $path = $dbscripts_dir . '/' . $file->{file};

    # mark existed records as old ones
    my $sql = sprintf(
            "UPDATE dbcheck_reports SET expired=true WHERE rule_id='%s'",
            , $file->{id}
        );
    $dbh->do($sql);

    my $time_start = time();
    my $retval;
    if ($file->{type} eq 'pl') {
        my $perl2 = $perl;
        $perl2 =~ s/%%script%%/$path/eg;
        $retval = system "$perl2";
    } else {
        $logger->log({ name => 'dbcheck', level => 'warning', message => "Unsupported type: " . $file->{file} });
    }
    my $time_end = time();

    $logger->log({ name => 'dbcheck', level => 'debug', message => "$path: $? (retval: $retval)" });

    # This check does not work. Even if our script fails, we may still get 0 in $? and in $retval.
    # one of the reasons for that is when an error happens inside a transaction, the transaction 
    # is successfully aborted. Successfully is the key word here.
    # One way to notice the error is to listen to STDERR of psql.
    if ($?) {
        # delete new records as this try failed
        my $sql = sprintf(
                "DELETE FROM dbcheck_reports WHERE expired=false AND rule_id='%s'",
                , $file->{id}
            );
        $dbh->do($sql);
        $logger->log({ name => 'dbcheck', level => 'warning', message => "Report " . $file->{n} . '_' . $file->{id} . " failed" });
    } else {
        # delete old records as this generation is ok
        # except of summary report
        if ('summary' ne $file->{id}) {
            my $sql = sprintf(
                    "DELETE FROM dbcheck_reports WHERE expired=true AND rule_id='%s'",
                    , $file->{id}
                );
            $dbh->do($sql);
        }
        $logger->log({ name => 'dbcheck', level => 'info', message => "Report " . $file->{n} . '_' . $file->{id} . " is done in " . ($time_end - $time_start) . " seconds" });
    }
    
}

$logger->log({ name => 'dbcheck', level => 'info', message => 'Finished' });

1;
