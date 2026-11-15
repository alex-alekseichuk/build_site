package GUPE::SQL::DBIUtils;
use strict;
use base 'Exporter';
our @EXPORT_OK = qw(dbdo dbopcounts dbmodify dbinsert dbcolnames dbselect dbselect1 dbselectqbe dbselectqbe1 dbdelete dbdelete1 csv_readfile csv_quote csv_array_row csv_hash_row excel_readfile);

=head1 DESCRIPTION

Exports a variety of dbi-related utilities.

=cut


use GUPE::Debug::Log;
use File::Basename qw(dirname basename);

our $DBDBG = $ENV{GUPE_DBI_DEBUG};
our $INLINE_UPDATE = 1;

our %DBCOUNTS;
sub dbopcounts {
    my ($noreset) = @_;
    my $dbcounts = {%DBCOUNTS};
    %DBCOUNTS = () unless $noreset;
    return $dbcounts;
}

=head2 dbdo($dbh, $statement, @values)

Issue a single non-select statement.

=cut 
 
sub dbdo {
  my ($dbh, $statement, @val) = @_;
  my $r;
  eval { $r = $dbh -> do( $statement, {}, @val ); };
  if ( $@ ) {
      require Carp;
      Carp::confess $dbh->errstr;
  }
  return $r;
}

=head2 dbinsert($dbh, $tablename, $hash, $uniquenames, $pkeyname)

If $uniquenames are not provided, acts same as dbmodify with $op 'insert'.
If $uniquenames is specified, then it will do a query after the insert
using the unique field names to fill in the $pkeyname value.
It returns this value and also modifies the $hash.

=cut

sub dbinsert {
    my ($dbh, $tablename, $hash, $uniquenames, $pkeyname) = @_;
    my $ret = dbmodify($dbh, 'insert', $tablename, $hash);
    return $ret unless $uniquenames && @$uniquenames;
    my $inserted;
    if (@$uniquenames == 1) {
	my $u = $uniquenames->[0];
	$inserted = dbselect1($dbh, $tablename, $u, $hash->{$u});
    }
    else {
	$inserted = dbselectqbe1($dbh, $tablename, {map {$_=>$hash->{$_}} @$uniquenames});
    }
    my $pkeyval = $inserted->{$pkeyname} || die("no '$pkeyname' value in inserted: ", Dumper($inserted));
    $hash->{$pkeyname} = $pkeyval;
    return $pkeyval;
}

=head2 dbmodify($dbh, $op, $tablename, $hash, $pkeyname, $pkeyval)

$op can be 'insert', 'update', or 'delete'
$pkeyname and $pkeyval can be undef if $op is 'insert' and the database generates the pkey.
$hash can be undef if $op is delete.

returns the dbi do() return value.

=cut

sub hash_to_pairs {
    my ($h) = @_;
    return join(' ', map {"$_=" . (defined($h->{$_}) ? $h->{$_} : 'NULL') } keys %$h);
}

sub _dbgparams {
    my ($hash, $pkeyname, $pkeyval) = @_;
    return ($hash ? hash_to_pairs($hash) : '') . ($pkeyname ? " $pkeyname=$pkeyval" : ''); 
}

sub dbmodify {
    my ($dbh, $op, $tablename,  $hash, $pkeyname, $pkeyval, $expected_n) = @_;
    die "pkeyval must be set if pkeyname is" if !defined($pkeyval) && defined($pkeyname); 

    $DBCOUNTS{$tablename} ||= {};
    $DBCOUNTS{$tablename}->{$op}++ unless $op eq 'delete';

    my $isdbg = $DBDBG && is_debug();
    my $dbgv = '';
    $dbgv = _dbgparams($hash, $pkeyname, $pkeyval) if is_testonly() || $isdbg;

    if (is_testonly()) {
	testonly("$op $tablename $dbgv");
	return 1;
    }
    if ($op eq 'insert') {
	my @colnames = keys %$hash;
	my @colvals = values %$hash;
	push(@colnames, $pkeyname), push(@colvals, $pkeyval) if defined($pkeyname);
	my $sql = "INSERT INTO $tablename (" . join(', ', @colnames) . ') VALUES (' .
	    join(',', map {'?'} @colnames) . ')';
	debug("dbmodify: $sql with $dbgv") if $isdbg;
	my $n = $dbh->do($sql, {}, @colvals);
	debug("do returned $n") if $isdbg;
	return $n;
    }
    if ($op eq 'update') {
	# exclude the primary key from the update set, if it is supplied and the value hasn't actually changed
	# this doesn't work correctly for the case of a NULL or empty string value as a primary key value
	if (exists $hash->{$pkeyname}) {
	    my $hpkeyval = $hash->{$pkeyname};
	    if ($hpkeyval eq $pkeyval) {
		debug("excluding update of unchanged pkey $pkeyname=$pkeyval");
		$hash = {%$hash};
		delete $hash->{$pkeyname};
	    }
	}
	my @colnames = keys %$hash;
	my @colvals = values %$hash;
	# my @colvals = map {$hash->{$_}} @colnames; # sigh, some perl bug

	my $sql;
	my $n;
	if ($INLINE_UPDATE) {
	    $sql = "UPDATE $tablename SET " . join(', ', map {"$_ = " . $dbh->quote($hash->{$_})} @colnames) . " WHERE $pkeyname = " . $dbh->quote($pkeyval);
	    debug("dbmodify: $sql (with INLINE_UPDATE set)") if $isdbg;
	    $n = $dbh->do($sql, {});
	}
	else {
	    $sql = "UPDATE $tablename SET " . join(', ', map {"$_ = ?"} @colnames) . " WHERE $pkeyname = ?";
	    debug("dbmodify: $sql with $dbgv") if $isdbg;
	    $n = $dbh->do($sql, {}, @colvals, $pkeyval);
	}

	warning("update returned $n: $sql with ", _dbgparams($hash, $pkeyname, $pkeyval)) unless $n == 1;
	debug("do returned $n") if $isdbg;
	return $n;
    }
    if ($op eq 'delete') {
	my $n = dbdelete($dbh, $tablename, "$pkeyname = ?", [$pkeyval], $expected_n);
	return $n;
    }
    die "unsupported op '$op'";
}

sub dbdelete1 {
    my ($dbh, $tablename, $pkeyname, $pkeyval, $expected_n) = @_;
    return dbdelete($dbh, $tablename, "$pkeyname = ?", [$pkeyval], $expected_n);
}

# if $expected_n is 0, then allow any value.
# if 1 (default), then should be exactly that value
# if 2, then allows any value >= 1
sub dbdelete {
    my ($dbh, $tablename, $where, $params, $expected_n) = @_;
    $params = [] unless defined($params);
    $expected_n = 1 unless defined($expected_n);
    $DBCOUNTS{$tablename} ||= {};
    $DBCOUNTS{$tablename}->{delete}++;

    my $sql = "DELETE FROM $tablename";
    $sql .= " WHERE $where" if $where;
    if (is_testonly()) {
	testonly("$sql");
	return 1;
    }
    my $isdbg = $DBDBG && is_debug();
    debug("dbdelete $sql with ", DebugDumper($params)) if $isdbg;
    my $n = $dbh->do($sql, {}, @$params); 
    if ($expected_n) {
	warning("delete returned $n not $expected_n: $sql with ", Dumper($params)) if $expected_n == 1 and $n != $expected_n;
	warning("delete returned $n not $expected_n: $sql with ", Dumper($params)) if $expected_n == 2 and $n < 1;
    }
    debug("do returned $n; last error was code: ", ($DBI::err||''), " message: ", ($DBI::errstr||'')) if $isdbg;
    return $n;
}

sub dbcolnames {
    my ($dbh, $tablename) = @_;
    # TODO: SQL::Abstract::Limit
    debug("getting column names of $tablename");
    my $sth = $dbh->prepare("select * from $tablename");
    $sth->execute();
    $sth->fetchrow_arrayref();
    my @colnames = @{$sth->{NAME_lc}};
    debug("got column names of $tablename: @colnames");
    return @colnames;
}

# a single hash
sub dbselect1 {
    my ($dbh, $table, $pkeyname, $pkeyval, $missing_ok) = @_;
    Carp::confess "dbselect1 insufficient args" unless @_ >= 4;
    my $sql = "SELECT * FROM $table WHERE $pkeyname = ?";
    my $h;
    eval {
	$h = $dbh->selectrow_hashref($sql, {}, $pkeyval);
    };
    Carp::confess "dbselect1($sql) with $pkeyname=$pkeyval failed: $@" if $@;
    die "no such $table with $pkeyname=$pkeyval" if !$h && !$missing_ok;
    return $h;
}

# caller provides hash of column names
sub dbselectqbe {
    my ($dbh, $table, $qbe_hash, $min_inclusive, $max_inclusive) = @_;
    my @colnames = keys %$qbe_hash;
    my $sql = @colnames ? "SELECT * FROM $table WHERE " . join(' AND ', map {"$_ = ?"} @colnames)
	: "SELECT * FROM $table";
    my $rows = dbselect($dbh, $sql, [values %$qbe_hash]);
    my $nrows = scalar(@$rows);
    die "got back $nrows < $min_inclusive $table rows using query hash: ", Dumper($qbe_hash)
	if (defined($min_inclusive) && $nrows < $min_inclusive);
    die "got back $nrows > $max_inclusive $table rows using query hash: ", Dumper($qbe_hash)
	if (defined($max_inclusive) && $nrows > $max_inclusive);
    return $rows;
}

sub dbselectqbe1 {
    my ($dbh, $table, $qbe_hash, $missing_ok) = @_;
    my $rows = dbselectqbe($dbh, $table, $qbe_hash, ($missing_ok ? 0 : 1), 1);
    return (scalar(@$rows) ? $rows->[0] : undef);
}

# an array of hashes
sub dbselect {
    my ($dbh, $sql, $paramvals) = @_;
    confess("no sql") unless $sql;
    my $rows = [];
    debug("about to fetch: $sql\nwith params: ", DebugDumper($paramvals));
    my $sth = $dbh->prepare($sql);
    $paramvals ||= [];
    $sth->execute(@$paramvals);
    while (my $h = $sth->fetchrow_hashref()) {
	push(@$rows, $h);
    }
    debug("got back ", scalar(@$rows), " rows");
    return $rows;
}

sub excel_readfile {
    my ($f) = @_;
    require Spreadsheet::ParseExcel;
    require DBD::Excel;
    my $dbh = DBI->connect("DBI:Excel:file=$f", undef, undef, 
			   {
			       RaiseError => 1,
			       # xl_ignorecase => 1,
			   }) or die "Cannot connect: " . $DBI::errstr;
    my @tables = $dbh->func('list_tables');
    info("got excel tables: ", Dumper([@tables]));
    my $tablename = $tables[0];
    my $rows = dbselect($dbh, "SELECT * FROM $tablename");
    return $rows;
}

sub csv_readfile {
    my ($f, $must_col_names) = @_;
    my $dbh = DBI->connect("DBI:CSV:f_dir=" . dirname($f)); #, undef, undef, {RaiseError => 1});
    my $tablename = 'csv';
    $dbh->{csv_tables}->{$tablename} = {file => basename($f), sep_char => ',', eol => "\r\n" }; 
    my $sth = $dbh->prepare("SELECT * FROM $tablename");
    $sth->execute();
    my $count = 0;
    my $skipped = 0;
    my @rows = ();
    while(my $row = $sth->fetchrow_hashref()) {
	# skip an empty row, as determined by not having any of the $must_col_names
	$skipped++, next unless !$must_col_names || grep {$row->{$_}} @$must_col_names;
	# debug("csv row $count $f ", Dumper($row));
	push(@rows, $row);
	$count++;
    }
    debug("returning $count, skipped $skipped");
    warning("skipped $skipped apparently empty lines in csv file $f") if $skipped;
    return [@rows];
}

# we send unquoted empty values to indicate null (that is how Pg import does it)
sub csv_quote {
    my ($v, $multiline_escape) = @_;
    return '' if !defined($v) or lc($v) eq 'null';
    # Pg wants two-character "\n", not literal returns
    $v =~ s/\r?\n/\\n/g if $multiline_escape;
    # everyone wants doubling for quote escaping
    $v =~ s/\"/\"\"/g;
    return "\"$v\"";
}

# my $csv = Text::CSV_XS->new(sep_char => "\t"); $csv->combine(@{$report->{heads}}); print $csv->string(), "\n";
# see also CGI::Application::Plugin::Output::XSV
    # "application/vnd.ms-excel" or "text/csv" or "application/x-csv" or text/tab-separated-values or application/x-msexcel
    # RFC4180 registers text/csv with IANA and specifies a comma separator and CRLF line separator
    # there is also IANA text/tab-separated-values http://www.iana.org/assignments/media-types/text/tab-separated-values
    # out of the box Excel doesn't figure out commas, only tabs (the wizard can help, but people want to click on files) 
    # There is no default file association for a .tsv file on Windows.
    # Also, TSV files don't quote values (and embedded tabs are simply illegal), while CSV does.
    # See:
    #   http://www.cs.tut.fi/~jkorpela/TSV.html
    #   http://members.chello.at/robert.graf/CSV/
#   http://www.rfc-editor.org/rfc/rfc4180.txt
#   http://www.iana.org/assignments/media-types/text/tab-separated-values

sub csv_array_row {
    my ($a, $sep) = @_;
    $sep ||= ',';
    if ($sep eq "\t") {return join($sep, map {m/\t/ ? (die "data contains a tab") : $_} @$a) . "\n";}
    return join($sep, map{csv_quote($_)} @$a) . "\n"; 
}

sub csv_hash_row {
    my ($h, $keys, $sep) = @_;
    return csv_array_row([$h->{@$keys}], $sep);
}

1;
