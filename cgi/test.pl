#!/usr/bin/perl

print "Content-Type: text/plain

";

use lib qw(../lib);
use BSA::Test;

print "ok\n\n";
print "id: ", `id`, "\n";

my $path_info = $ENV{PATH_INFO} || '';

my ($action) = ($path_info =~ m!^/(.+)!);
print "action: $action\n\n";

if ($action eq 'env') {
  foreach my $key ( keys %ENV ) {
    print $key , " = ", $ENV{$key}, "\n";
  }

} elsif( $action eq 'pg' ) {
    my $dbh;
    eval {
      require DBI;
      $dbh = DBI->connect( "dbi:Pg:dbname=bsdata", 'bsadmin' ) 
        or print $DBI::errstr;
    };
    print $dbh, "\n";
    print "errstr: $DBI::errstr";

} else {
    print "no action\n";
}
 
