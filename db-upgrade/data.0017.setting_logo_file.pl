#!/usr/bin/perl

use strict;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use File::Find;
use Data::Dumper;
use BST::Config;
use BST;
use DBI;

my $config = BST::configuration();
my $dbh = BST::dbh();

# remove scope: all records
my $sql = "delete from setting where scope='all' and att_name='logo_file' and att_val='(file)'";
$dbh->do($sql) or die $dbh->errstr;

# check records of other scopes. if exists then update, otherwise delete.
my $logos = $dbh->selectall_arrayref("SELECT * FROM setting WHERE att_name='logo_file' and att_val='(file)'", { Slice => {} });
foreach my $row (@$logos) {
    my $setting_dir        = "$row->{scope}-$row->{scope_value}";
    my $local_dir          = join("/", $config->{settings_path}, $setting_dir);

    my $att_val;
    if (-d $local_dir) {
        find({
            wanted => sub {
                if ($File::Find::name =~ /([^\/]*(logo))\.(\w+)$/) {
                    $att_val = "$setting_dir/$1.$3";
                    $sql = sprintf "UPDATE setting SET att_val=%s WHERE att_name='logo_file' AND att_val='(file)' AND scope=%s AND scope_value=%s"
                        , $dbh->quote($att_val)
                        , $dbh->quote($row->{scope})
                        , $dbh->quote($row->{scope_value});
                    $dbh->do($sql) or die $dbh->errstr;
                };
            },
        }, $local_dir);
    }
    if (! $att_val) {
        #print "nothing\n";
        $sql = sprintf "DELETE FROM setting WHERE att_name='logo_file' AND att_val='(file)' AND scope=%s AND scope_value=%s"
            , $dbh->quote($row->{scope})
            , $dbh->quote($row->{scope_value});
        $dbh->do($sql) or die $dbh->errstr;
    }

}
