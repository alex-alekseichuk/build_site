use DBI;

my $dbh = DBI->connect("dbi:Pg:dbname=bsdata", $ENV{BST_DB_USER} || 'bsadmin', $ENV{BST_DB_PASS} or die "set the BST_DB_PASS env var");

#print localtime() . "\n";

for (my $i = 0; $i < 10000; $i++)
{
    my $st = $dbh->prepare("select * from customer_user where login_id='IvanTest4\@buildsite.com'");
    $st->execute;

    while (my $row = $st->fetchrow_hashref) { }
    $st->finish();
}

#print localtime() . "\n";

$dbh->disconnect;

