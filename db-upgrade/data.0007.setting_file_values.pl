use strict;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Data::Dumper;

use DBI;
use BST;
use BST::Scope;
use File::Copy;

my $dbh = BST::dbh();

my $all = $dbh->selectall_arrayref("SELECT * FROM setting WHERE att_name ~ '_file\$' AND att_val = '(file)'", { Slice => {} });

unless (scalar @$all) {
    print "Nothing to update\n";
    exit;
}

my $sth = $dbh->prepare("UPDATE setting SET att_val = ? WHERE setting_id = ?");
my $upd = 0;

foreach my $set (@$all) {
    my $oldAbsPath = get_abs_path(get_old_namespace($set->{scope}, $set->{scope_value}));
    my $newPath = get_new_namespace($set->{scope}, $set->{scope_value});

    my ($name) = $set->{att_name} =~ m/^(.*)_file$/;
    opendir DIR, $oldAbsPath;
    my ($file) = grep m/^$name\.[\w\d]+$/, readdir DIR;
    closedir DIR;

    if ($file) {
        create_if_nonexists($newPath);
        copy(
            $oldAbsPath . "/" . $file,
            get_abs_path($newPath) . "/" . $file
        ) unless (BST::Scope->is_account($set->{scope}));
        $upd++ if $sth->execute($newPath . "/" . $file, $set->{setting_id});
    }
}

printf "Updated %d of %d settings file values\n", $upd, scalar @$all;

$sth->finish();
$dbh->disconnect;






sub get_old_namespace {
    my $scope = shift;
    my $id = shift;
    
    my $prefix = '';

    if (BST::Scope->is_account($scope)) {
        $prefix = 'account';
    } elsif (BST::Scope->is_location($scope)) {
        $prefix = 'account_location';
    } elsif (BST::Scope->is_user($scope)) {
        $prefix = 'buildsite_user';
    } elsif (BST::Scope->is_all($scope)) {
        return 'world';
    }
    
    return join '-', $prefix, $id;
}

sub get_new_namespace {
    my $scope = shift;
    my $id = shift;
    
    return 'all' if (BST::Scope->is_all($scope));
    return join '-', $scope, $id;
}

sub create_if_nonexists {
    my $abs_path = get_abs_path(shift);
    mkdir $abs_path unless -e $abs_path;
}

sub get_abs_path {
    my $path = shift;
    return BST::config('settings_path') . '/' . $path;
}

1;
