#!/usr/bin/perl -w

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Data::Dumper;

use Getopt::Long;

use DBI;

use BST;

my ($config, $from_dbh, $to_dbh, $sth);
my ($source_db, $source_db_user, $source_db_pass, $dest_db, $dest_db_user, $dest_db_pass);

$config = BST::configuration();

GetOptions(
    "source-db=s"       => \$source_db,
    "source-db-user=s"  => \$source_db_user,
    "source-db-pass=s"  => \$source_db_pass,
    "dest-db=s"         => \$dest_db,
    "dest-db-user=s"    => \$dest_db_user,
    "dest-db-pass=s"    => \$dest_db_pass,
);

$from_dbh     = DBI->connect(
    "DBI:Pg:dbname=$source_db",
    $source_db_user,
    $source_db_pass,
    {
        PrintWarn       => 1,
        PrintError      => 1,
        RaiseError      => 0,
        AutoCommit      => 1,
        pg_enable_utf8  => 1.
    }
) or die;

$to_dbh     = DBI->connect(
    "DBI:Pg:dbname=$dest_db",
    $dest_db_user,
    $dest_db_pass,
    {
        PrintWarn       => 1,
        PrintError      => 1,
        RaiseError      => 0,
        AutoCommit      => 1,
        pg_enable_utf8  => 1.
    }
) or die;

my $grouping_compliance_id;

get_grouping_compliance();

foreach my $table (qw/
        grouping
        company company_feature company_grouping company_keyword
        category category_grouping category_descendant category_keyword
        product product_related product_standard product_keyword
        publication
        document
        standard
        service
        gateway_payment credit_card
        customer_account customer_order customer_user
    /) {
    my @delete;

    print "\n[+]\tStart checking table $table";

    my @data    = @{ _get_data(
        $table,
        undef,
        undef,
        undef,
        ($table eq 'document') ? 'auto_mtime DESC' :
        ($table !~ /^category_descendant|category_keyword|company_keyword|product_keyword|service$/) ? 'auto_mtime ASC' : undef
    )};

    if ($table eq 'grouping') {
        my ($source, $dest);

        foreach (@{ sql_query($from_dbh, sql_select($table, [qw/grouping_name/])) }) {
            $source->{$_->{grouping_name}}++;
        }

        foreach (@{ sql_query($to_dbh, sql_select($table, [qw/grouping_name/])) }) {
            $dest->{$_->{grouping_name}}++;
        }

        delete $dest->{$_} foreach (keys %$source);

        @delete = map { $_ } keys %$dest if keys %$dest;

        foreach (@delete) {
            my $grouping_id = @{ sql_query($to_dbh, sql_select($table, [qw/grouping_id/], { grouping_name => $_ })) }[0]->{grouping_id};

            print "\n[+]\tDelete data from table $table with primary key $_";

            sql_query($to_dbh, sql_update('company', { linecard_grouping_id => undef }, { linecard_grouping_id => $grouping_id }));

            sql_query($to_dbh, sql_delete($table, { grouping_name => $_ }));
        }
    } elsif ($table eq 'company_grouping') {
        my ($source, $dest);

        foreach (@{ sql_query($from_dbh, sql_select($table, [qw/company_id grouping_id/])) }) {
            $source->{$_->{company_id} . ':' . $grouping_compliance_id->{$_->{grouping_id}}}++;
        }

        foreach (@{ sql_query($to_dbh, sql_select($table, [qw/company_id grouping_id/])) }) {
            $dest->{$_->{company_id} . ':' . $_->{grouping_id}}++;
        }

        delete $dest->{$_} foreach (keys %$source);

        @delete = map { $_ } keys %$dest if keys %$dest;

        foreach (@delete) {
            my ($company_id, $grouping_id) = split(':', $_);
            print "\n[+]\tDelete data from table $table with primary key $company_id, $grouping_id\n";
            sql_query($to_dbh, sql_delete($table, { company_id => $company_id, grouping_id => $grouping_id}));
        }
    } elsif ($table eq 'product_standard') {
        my ($source, $dest);

        foreach (@{ sql_query($from_dbh, sql_select($table, [qw/product_id standard_org_id standard_document_identifier/])) }) {
            $source->{$_->{product_id} . ':' . $_->{standard_org_id} . ':' . ($_->{standard_document_identifier} || 'na')}++;
        }

        foreach (@{ sql_query($to_dbh, sql_select($table, [qw/product_id standard_org_id standard_document_identifier/])) }) {
            $dest->{$_->{product_id} . ':' . $_->{standard_org_id} . ':' . ($_->{standard_document_identifier} || 'na')}++;
        }

        delete $dest->{$_} foreach (keys %$source);

        @delete = map { $_ } keys %$dest if keys %$dest;

        foreach (@delete) {
            my ($product_id, $standard_org_id, $standard_document_identifier) = split(':', $_);
            print "\n[+]\tDelete data from table $table with primary key $product_id, $standard_org_id, $standard_document_identifier\n";
            sql_query($to_dbh, sql_delete($table, { product_id => $product_id, standard_org_id => $standard_org_id, standard_document_identifier => $standard_document_identifier }));
        }
    } elsif ($table eq 'company_feature') {
        my ($source, $dest);

        foreach (@{ sql_query($from_dbh, sql_select($table, [qw/company_id feature_name/])) }) {
            $source->{$_->{company_id} . ':' . $_->{feature_name}}++;
        }

        foreach (@{ sql_query($to_dbh, sql_select($table, [qw/company_id feature_name/])) }) {
            $dest->{$_->{company_id} . ':' . $_->{feature_name}}++;
        }

        delete $dest->{$_} foreach (keys %$source);

        @delete = map { $_ } keys %$dest if keys %$dest;

        foreach (@delete) {
            my ($company_id, $feature_name) = split(':', $_);
            print "\n[+]\tDelete data from table $table with primary key $company_id, $feature_name";
            sql_query($to_dbh, sql_delete($table, { company_id => $company_id, feature_name => $feature_name }));
        }
    } elsif ($table eq 'category') {
        my ($source, $dest);

        foreach (@{ sql_query($from_dbh, sql_select($table, [qw/category_id/])) }) {
            $source->{$_->{category_id}}++;
        }

        foreach (@{ sql_query($to_dbh, sql_select($table, [qw/category_id/])) }) {
            $dest->{$_->{category_id}}++;
        }

        delete $dest->{$_} foreach (keys %$source);

        @delete = map { $_ } keys %$dest if keys %$dest;

        foreach (@delete) {
            print "\n[+]\tDelete data from table $table with primary key $_";
            sql_query($to_dbh, sql_delete('category_keyword', { category_id => $_ }));
            sql_query($to_dbh, sql_delete($table, { category_id => $_ }));
        }
    } elsif ($table eq 'company') {
        my ($source, $dest);

        foreach (@{ sql_query($from_dbh, sql_select($table, [qw/company_id/])) }) {
            $source->{$_->{company_id}}++;
        }

        foreach (@{ sql_query($to_dbh, sql_select($table, [qw/company_id/])) }) {
            $dest->{$_->{company_id}}++;
        }

        delete $dest->{$_} foreach (keys %$source);

        @delete = map { $_ } keys %$dest if keys %$dest;

        foreach (@delete) {
            print "\n[+]\tDelete data from table $table with primary key $_";
            sql_query($to_dbh, sql_delete('company_keyword', { company_id => $_ }));
            sql_query($to_dbh, sql_delete('company_feature', { company_id => $_ }));
            sql_query($to_dbh, sql_delete('publication', { company_id => $_ }));
            sql_query($to_dbh, sql_update('company', { branch_of_id => undef }, { branch_of_id => $_ }));
            sql_query($to_dbh, sql_delete($table, { company_id => $_ }));
        }

    } elsif ($table eq 'product') {
        my ($source, $dest);

        foreach (@{ sql_query($from_dbh, sql_select($table, [qw/product_id/])) }) {
            $source->{$_->{product_id}}++;
        }

        foreach (@{ sql_query($to_dbh, sql_select($table, [qw/product_id/])) }) {
            $dest->{$_->{product_id}}++;
        }

        delete $dest->{$_} foreach (keys %$source);

        @delete = map { $_ } keys %$dest if keys %$dest;

        foreach (@delete) {
            print "\n[+]\tDelete data from table $table with primary key $_";
            sql_query($to_dbh, sql_delete('product_keyword', { product_id => $_ }));
            sql_query($to_dbh, sql_delete('product_standard', { product_id => $_ }));
            sql_query($to_dbh, sql_delete('document', { product_id => $_ }));
            sql_query($to_dbh, sql_delete($table, { product_id => $_ }));
        }
    } elsif ($table eq 'category_descendant') {
        my ($source, $dest);

        foreach (@{ sql_query($from_dbh, sql_select($table, [qw/category_id descendant_id/])) }) {
            $source->{$_->{category_id} . ':' . $_->{descendant_id}}++;
        }

        foreach (@{ sql_query($to_dbh, sql_select($table, [qw/category_id descendant_id/])) }) {
            $dest->{$_->{category_id} . ':' . $_->{descendant_id}}++;
        }

        delete $dest->{$_} foreach (keys %$source);

        @delete = map { $_ } keys %$dest if keys %$dest;

        foreach (@delete) {
            my ($category_id, $descendant_id) = split(':', $_);
            print "\n[+]\tDelete data from table $table with primary key $category_id, $descendant_id";
            sql_query($to_dbh, sql_delete($table, { category_id => $category_id, descendant_id => $descendant_id }));
        }
    } elsif ($table !~ /^(?:category_keyword|company_keyword|product_keyword)$/i) {
        my ($source, $dest, $pk);

        $pk = [ $from_dbh->primary_key(undef, undef, $table) ];

        foreach my $row (@{ sql_query($from_dbh, sql_select($table, $pk)) }) {
            $source->{join(':', map { $row->{$_} } keys %$row )}++;
        }

        foreach my $row (@{ sql_query($to_dbh, sql_select($table, $pk)) }) {
            $dest->{join(':', map { $row->{$_} } keys %$row )}++;
        }

        delete $dest->{$_} foreach (keys %$source);

        @delete = map { $_ } keys %$dest if keys %$dest;

        foreach (@delete) {
            print "\n[+]\tDelete data from table $table with primary key " . join(', ', split(':', $_)) . "\n";
            sql_query($to_dbh, sql_delete($table, { $pk->[0] => $_ }));
        }
    }

    foreach my $data (@data) {
        if ($table eq 'company_feature') {
            import_data($data, $table, undef, [qw/company_id feature_name/]);
        } elsif ($table eq 'grouping') {
            import_data($data, $table, undef, [qw/grouping_name/]);
        } elsif ($table eq 'company_grouping') {
            import_data($data, $table, undef, [qw/company_id grouping_id/]);
        } elsif ($table eq 'product_keyword') {
            import_data($data, $table, undef, [qw/keyword product_id keyword_type/]);
        } elsif ($table eq 'product_standard') {
            import_data($data, $table, undef, [qw/product_id standard_org_id standard_document_identifier/]);
        } elsif ($table eq 'company_keyword') {
            import_data($data, $table, undef, [qw/keyword company_id keyword_type/]);
        } elsif ($table eq 'category_keyword') {
            import_data($data, $table, undef, [qw/keyword category_id keyword_type/]);
        } else {
            import_data($data, $table, undef, undef, undef, \@data);
        }
    }
}

$from_dbh->disconnect;
$to_dbh->disconnect;

print "\n";

sub get_grouping_compliance {
    my $from    = _get_data('grouping');
    my $to      = _get_data('grouping', undef, undef, $to_dbh);

    foreach my $grouping (@{ $from }) {
        my ($grouping_to) = grep { $_->{grouping_name} eq $grouping->{grouping_name} } @{ $to };

        $grouping_compliance_id->{$grouping->{grouping_id}} = $grouping_to->{grouping_id};
    }
}

sub import_data {
    my $data        = shift;
    my $from_table  = shift;
    my $to_table    = shift || $from_table;
    my $from_pk     = shift || [ $from_dbh->primary_key(undef, undef, $from_table) ];
    my $to_pk       = shift || $from_pk;
    my $org_data    = shift;

    my $check    =  ($from_table !~ /^category_descendant|category_keyword|company_keyword|product_keyword|service$/) ?
        check(
            $from_table,
            $to_table,
            { map { $_ => $data->{$_} } @{ $from_pk } },
            { map { $_ => ($to_table eq 'company_grouping' && $_ eq 'grouping_id') ? $grouping_compliance_id->{$data->{$_}} : $data->{$_} } @{ $to_pk } },
        )
        :
        4;
        
    if ($to_table eq 'product' && $data->{superseded_by_product_id} && ! scalar @{ sql_query($to_dbh, sql_select('product', [qw/product_id/], { product_id => $data->{superseded_by_product_id} })) }) {
        push @$org_data, $data;
        return;
    }

    if ($check && $check == 1) {
        if ($to_table eq 'company_grouping') {
            $data->{grouping_id} = $grouping_compliance_id->{$data->{grouping_id}};
        }

        if ($to_table eq 'company') {
            $data->{linecard_grouping_id} = (_get_data(
                'grouping',
                {
                    grouping_name => (_get_data('grouping', { grouping_id => $data->{linecard_grouping_id} }, undef, undef, 'auto_mtime ASC'))->[0]->{grouping_name},
                },
                undef,
                $to_dbh,
                'auto_mtime ASC'
            ))->[0]->{grouping_id} if $data->{linecard_grouping_id};
        }

        if ($to_table eq 'document' && $data->{replaced_by_document_id}) {
            unless (@{ _get_data($to_table, { document_id => $data->{replaced_by_document_id} }, undef, $to_dbh) }) {
                insert($to_table, @{ _get_data($to_table, { document_id => $data->{replaced_by_document_id} }) });
            }
        }
        insert($to_table, $data);
    } elsif ($check == 2) {

        if ($to_table eq 'grouping') {
            $data->{grouping_id} = $grouping_compliance_id->{$data->{grouping_id}};
        }

        if ($to_table eq 'company') {
            $data->{linecard_grouping_id} = (_get_data(
                'grouping',
                {
                    grouping_name => (_get_data('grouping', { grouping_id => $data->{linecard_grouping_id} }, undef, undef, 'auto_mtime ASC'))->[0]->{grouping_name},
                },
                undef,
                $to_dbh,
                'auto_mtime ASC'
            ))->[0]->{grouping_id} if $data->{linecard_grouping_id};
        }

        if ($to_table eq 'company_feature') {
            $data->{company_feature_id} = (_get_data(
                'company_feature',
                {
                    feature_level   => $data->{feature_level},
                    company_id      => $data->{company_id},
                    feature_name    => $data->{feature_name},
                },
                undef,
                $to_dbh,
                'auto_mtime ASC'
            ))->[0]->{company_feature_id};
        }

        if ($to_table eq 'company_grouping') {
            $data->{grouping_id} = $grouping_compliance_id->{$data->{grouping_id}};
        }

        if ($to_table eq 'document' && $data->{replaced_by_document_id}) {
            unless (@{ _get_data($to_table, { document_id => $data->{replaced_by_document_id} }, undef, $to_dbh) }) {
                insert($to_table, @{ _get_data($to_table, { document_id => $data->{replaced_by_document_id} }) });
            }
        }

        update($to_table, { map { $_ => $data->{$_} } @{ $to_pk } }, $data);
    } elsif ($check == 4) {
        if ($to_table eq 'category_descendant') {
            push @{ $to_pk }, 'category_id', 'descendant_id';
        }
        if (@{ _get_data($to_table, { map { $_ => $data->{$_} } @{ $to_pk } }, undef, $to_dbh) }) {
            print "\n[+]\tUpdate '$to_table' data for keys:" . join(q{ }, map { $data->{$_} } @{ $to_pk });
            update($to_table, { map { $_ => $data->{$_} } @{ $to_pk } }, $data);
        } else {
            print "\n[+]\tImport data to '$to_table' for keys:" . join(q{ }, map { $data->{$_} } @{ $to_pk });
            insert($to_table, $data);
        }
    }
}

sub insert {
    my $table   = shift;
    my $values  = shift;

    if ($table eq 'product_standard') {
        delete $values->{product_standard_id};
    }

    my $rows = $to_dbh->do(
        "INSERT INTO $table (" .
            lc(join(q{, }, sort keys %{ $values })) .
            ") VALUES (" .
            '?, ' x ((keys %{ $values }) - 1) .
            "?)",
        undef,
        map { $values->{$_} } sort keys %{ $values },
    ) or die "Can't insert data into table $table: " . $to_dbh->errstr . "\n\n" . Dumper($table) . Dumper($values);

    return $rows;
}

sub update {
    my $table   = shift;
    my $pk      = shift;
    my $values  = shift;

    delete $values->{$_} foreach keys %{ $pk };

    if ($table eq 'product_standard') {
        delete $values->{product_standard_id};
    }

    my $rows = $to_dbh->do(
        "UPDATE $table SET " .
            join(q{, }, map { lc($_) .
            ' = ?'} sort keys %{ $values }) .
            " WHERE " .
            join(q{ AND }, map { lc($_) . ' = ?'} sort keys %{ $pk }),
        undef,
        (map { $values->{$_} } sort keys %{ $values }), map { $pk->{$_} } sort keys %{ $pk },
    ) or die "Can't update data into table $table: " . $to_dbh->errstr . "\n\n" . Dumper($table) . Dumper($pk) . Dumper($values);

    return $rows;
}

sub check {
    my $from_table  = shift;
    my $to_table    = shift || $from_table;
    my $from_pk     = shift;
    my $to_pk       = shift || $from_pk;

    my (@from_cmtime, @to_cmtime);

    @from_cmtime    = _get_cmtime($from_dbh, $from_table, $from_pk);
    @to_cmtime      = _get_cmtime($to_dbh, $to_table, $to_pk);

    if (scalar @to_cmtime == 0) {
        print "\n[+]\tCheck data '$to_table' keys:" . join(q{ }, map { "$_=$from_pk->{$_}" } sort keys %{ $from_pk }) . "\n";
        print "[-]\t\t- data for " . join(q{ }, map { "$from_pk->{$_}" } sort keys %{ $from_pk }) . " does not exist\n";
        print "[+]\tImport data to '$to_table' for keys:" . join(q{ }, map { "$to_pk->{$_}" } sort keys %{ $to_pk });
        return 1;

    } elsif ((defined($from_cmtime[0]) && defined($to_cmtime[0]) && $from_cmtime[0] ne $to_cmtime[0])
            ||
            (defined($from_cmtime[1]) && defined($to_cmtime[1]) && $from_cmtime[1] ne $to_cmtime[1])
            ||
            (defined($from_cmtime[0]) && ! defined($to_cmtime[0]) || ! defined($from_cmtime[0]) && defined($to_cmtime[0]))
            ||
            (defined($from_cmtime[1]) && ! defined($to_cmtime[1]) || ! defined($from_cmtime[1]) && defined($to_cmtime[1]))
            ) {

        print "\n[+]\tCheck data '$to_table' keys:" . join(q{ }, map { "$_=$from_pk->{$_}" } sort keys %{ $from_pk }) . "\n";
        print "[-]\t\t- data for " . join(q{ }, map { "$from_pk->{$_}" } sort keys %{ $from_pk }) . " is not equivalent\n";
        print "[+]\tUpdate '$to_table' data for keys:" . join(q{ }, map { "$to_pk->{$_}" } sort keys %{ $to_pk });
        return 2;

    } elsif ((defined($from_cmtime[0]) && defined($to_cmtime[0]) && $from_cmtime[0] eq $to_cmtime[0])
            ||
            (defined($from_cmtime[1]) && defined($to_cmtime[1]) && $from_cmtime[1] eq $to_cmtime[1])) {
        return 3;
    }
}

sub _get_cmtime {
    my $dbh     = shift;
    my $table   = shift;
    my $pk      = shift;

    return $dbh->selectrow_array(
        "SELECT auto_ctime, auto_mtime FROM $table WHERE " .
            join(q{ AND }, map { lc($_) .
            ' = ?'} sort keys %{ $pk }),
        undef,
        map { $pk->{$_} } sort keys %{ $pk }
    );
}

sub _get_data {
    my $table       = lc(shift);
    my $pk          = shift;
    my $additional  = shift;
    my $dbh         = shift || $from_dbh;
    my $order       = shift;

    my ($result, $query);

    $query  = "SELECT * FROM $table" .
        ($pk ?
            " WHERE " .
            join(q{ AND },
                map {
                    ref $pk->{$_} eq 'SCALAR' ?
                        lc($_) . ' IN (' . ${ $pk->{$_} }. ')' :
                    ref $pk->{$_} eq 'ARRAY' ?
                        lc($_) . ' IN (' . '?, ' x (scalar @{ $pk->{$_} } - 1) . '?)' :
                        lc($_) . ' = ?'
                } sort keys %{ $pk }
            )
            :
            ''
        )
        #. ($order ? " ORDER BY auto_mtime ASC");
        . ($order ? " ORDER BY $order" : '');

    $sth    = $dbh->prepare($query);

    grep { delete $pk->{$_} if ref $pk->{$_} eq 'SCALAR' } keys %{ $pk };

    $sth->execute(
        (map {
            ref $pk->{$_} ne 'ARRAY' ?
            $pk->{$_}                :
            @{ $pk->{$_} }
        } sort keys %{ $pk }),
        @{ $additional }
    ) or die $from_dbh->errstr;

    if ($sth->rows) {
        while (my $row = $sth->fetchrow_hashref) {
            push @{ $result }, $row;
        }
    }

    $sth->finish;

    return $result ? $result : [];
}

sub _get_select {
    my $table   = uc(shift);
    my $values  = shift || '*';
    my $pk      = shift;

    return "SELECT $values FROM $table WHERE " .
        join(q{ AND },
            map {
                ref $pk->{$_} ne 'ARRAY' ?
                    lc($_) . ' = ?'      :
                    lc($_) . ' IN (' . '?, ' x (scalar @{ $pk->{$_} } - 1) . '?)'
            } sort keys %{ $pk }
        );
}

sub total {
    return $_[0] ? scalar @{ $_[0] } : 0
}

sub sql_query {
    my $dbh     = shift;
    my $query   = shift;

    my $sth     = $dbh->prepare(shift(@$query));

    $sth->execute(@{ shift(@$query) }) or die $dbh->errstr;

    return $sth->{Statement} =~ /^\s*SELECT\s/i ? $sth->fetchall_arrayref({}||[]) : $sth->rows;
}

sub sql_select {
    my $table   = shift;
    my $select  = shift;
    my $where   = shift;

    my $sql = "SELECT " . ($select ? join(q{, }, @{ $select }) : '*') . " FROM $table";

    if ($where) {
        $sql .= " WHERE " .
            join(q{ AND },
                map {
                    ref $where->{$_} eq 'CODE'                         ?
                        lc($_) . ' IN (' . ($where->{$_}->())[0] . ")" :
                    ref $where->{$_} ne 'ARRAY'                        ?
                        lc($_) . ' = ?'                                :
                        lc($_) . ' IN (' . '?, ' x (scalar @{ $where->{$_} } - 1) . '?)'
                } sort keys %{ $where }
            );
    }

    return [ $sql, [ map {
        ref $where->{$_} eq 'CODE'  ?
            @{ ($where->{$_}->())[1] }  :
        ref $where->{$_} ne 'ARRAY' ?
            $where->{$_}            :
            @{ $where->{$_} }
    } sort keys %{ $where } ] ];
}

sub sql_delete {
    my $table   = shift;
    my $where   = shift;

    my $sql = "DELETE FROM $table";

    if ($where) {
        $sql .= " WHERE " .
            join(q{ AND },
                map {
                    ref $where->{$_} eq 'CODE'                         ?
                        lc($_) . ' IN (' . ($where->{$_}->())[0] . ")" :
                    ref $where->{$_} ne 'ARRAY'                        ?
                        lc($_) . ' = ?'                                :
                        lc($_) . ' IN (' . '?, ' x (scalar @{ $where->{$_} } - 1) . '?)'
                } sort keys %{ $where }
            );
    }

    return [ $sql, [ map {
        ref $where->{$_} eq 'CODE'  ?
            @{ ($where->{$_}->())[1] }  :
        ref $where->{$_} ne 'ARRAY' ?
            $where->{$_}            :
            @{ $where->{$_} }
    } sort keys %{ $where } ] ];
}

sub sql_update {
    my $table   = shift;
    my $update  = shift;
    my $where   = shift;

    my $sql = "UPDATE $table SET ";

    $sql .= join(', ',  map { $_ . ' = ?' } sort keys %$update);

    if ($where) {
        $sql .= " WHERE " .
            join(q{ AND },
                map {
                    ref $where->{$_} eq 'CODE'                         ?
                        lc($_) . ' IN (' . ($where->{$_}->())[0] . ")" :
                    ref $where->{$_} ne 'ARRAY'                        ?
                        lc($_) . ' = ?'                                :
                        lc($_) . ' IN (' . '?, ' x (scalar @{ $where->{$_} } - 1) . '?)'
                } sort keys %{ $where }
            );
    }

    return [ $sql, [ sort(values %$update), map {
        ref $where->{$_} eq 'CODE'  ?
            @{ ($where->{$_}->())[1] }  :
        ref $where->{$_} ne 'ARRAY' ?
            $where->{$_}            :
            @{ $where->{$_} }
    } sort keys %{ $where } ] ];
}
