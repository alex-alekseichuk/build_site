package BS::Search;
use strict;
use base 'Exporter';
our @EXPORT_OK = qw(term_to_keywords set_keywords set_all_keywords);

=head1 DESCRIPTION

Has the functions that do processing of search strings, whether
when processing a runtime search, or when indexing content.

=cut

use GUPE::Debug::Log;
use GUPE::SQL::DBIUtils qw(dbmodify dbselect dbdelete dbopcounts);

# treat as word separator
our $SPACE_CHARS = '_:,!"#%()*+-/;' ;
# our $SPACE_CHARS_RE = quotemeta($SPACE_CHARS);

# ignore everything but these
our $KEEP_CHARS = 'a-z\d';

our $MIN_LEN_SUBSTRING = 3;
our $INDEX_EXPAND_SUBSTRINGS = 1;

our $SDBG = 0;


# return an array of initial substrings, down to a minimum length of $minlen

sub gen_prefixes {
    my ($s, $minlen) = @_;
    my $len = length($s);
    return ($s) if $len <= $minlen;
    my @prefixes = map {substr($s, 0, $_)} ($minlen .. $len);
    debug("from '$s' made prefixes: @prefixes") if $SDBG;
    return @prefixes;
}

=head2 term_to_keywords($term, $phase)

The $phase argument is either 'index' or 'search'.

When $phase is 'index', then we expand all substrings,
if and only if $INDEX_EXPAND_SUBSTRINGS is set below.

When $phase is 'content', then substrings are never expanded,
but the caller better use a LIKE clause if !$INDEX_EXPAND_SUBSTRINGS.

As long as the logical combiner ("AND") is the same for within-word
terms (as in "foo-bar") as for among-word terms (as in "foo bar"),
then it doesn't matter if the caller invokes this function with
a single $term containing no white space for each word,
or if the caller calls us with $term containing the entire
search phrase.

That is how our specification dictates for now.

If in some future date the combiner is different, then
it is up to the caller to call this function multiple times,
and for example find a match to at least one keyword for each term
("OR"), and then find the intersection across multiple words ("AND").

Regardless, when indexing content, it is ok to provide an argument that
contains white space, since all keywords apply to the same object.

=cut

sub term_to_keywords ($$$) {
    my ($term, $phase, $keyword_type) = @_;
    # die "bad term '$term'" unless $term && $term !~ m/\s/;
    my $expand_substrings = ($phase eq 'index' && $INDEX_EXPAND_SUBSTRINGS);

    my $origterm = $term;

    # lower case
    $term = lc($term);

    # remove html entities and replace with space
    $term =~ s/&\#?\w+;/ /g;

    # equivalent to space
    $term =~ s/[$SPACE_CHARS]/ /g;
    debug("after substituting space, '$origterm' => '$term'") if $SDBG;

    # individual keywords
    my @fullkeys = split(' ', $term);

    debug("split '$term' into: '@fullkeys'") if $SDBG;

    my $keywords = [];
    for (@fullkeys) {
        my $os = $_;
        # zero pad a category search string by digit
        $_ = "0$_" if $keyword_type eq 'C' && m/^\d{4}$/;
        s/[^$KEEP_CHARS]//g;
        unless($_ || $_ eq '0') {
            warning("ignoring string '$os' in '$term' that has no kept characters") unless $os eq '&';
            next;
        }
        debug("after removing ignorable chars: '$_'") if $SDBG;
        if ($expand_substrings) {
            push(@$keywords, gen_prefixes($_, $MIN_LEN_SUBSTRING));
            
            # dirty hack :)
            my $saved_min_length = $MIN_LEN_SUBSTRING; $MIN_LEN_SUBSTRING = 1;
            foreach my $digit(/(\d+)/g) {
                push @$keywords, $digit, gen_prefixes($digit, $MIN_LEN_SUBSTRING);
            }
            $MIN_LEN_SUBSTRING = $saved_min_length;
        }
        else {
            push(@$keywords, $_);
            foreach my $digit(/(\d+)/g) {
                push @$keywords, $digit;
            }
        }
    }
    debug("from term '$origterm' made keywords: @$keywords") if $SDBG;
    return $keywords;
}

# indexed by tablename
our @KEYWORD_INDEXES =
(
 {
     keyword_type => 'M',
     table => 'company',
     where => "company_type = 'manufacturer'",
     columns => [qw(company_id legal_name company_nickname)],
 },

 {
     keyword_type => 'C',
     table => 'category',
     # also index the parent title
     from => 'category LEFT JOIN category pc ON (pc.category_id = category.parent_id) LEFT JOIN category gc ON (gc.category_id = pc.parent_id)',
     columns => [qw(category.category_id category.category_title category.mf_includes category.buildsite_description),
                 'pc.category_title as parent_title', 'gc.category_title as grandparent_title'],
     # how they show up in the hash
     # higher scored fields should come first
     colnames => [qw(category_id category_title parent_title buildsite_description mf_includes )],
     # score multiplier for the field
     scored => {mf_includes => .5, buildsite_description => .5},
 },
 {
     keyword_type => 'P',
     table => 'product',
     temp_table => 'product_temp',
     from => 'product'
        . ' LEFT JOIN product_standard ps ON (product.product_id = ps.product_id)'
        . ' LEFT JOIN company co ON (product.manufacturer_id = co.company_id)'
        . ' LEFT JOIN category c ON (product.category_id = c.category_id)'
        . ' LEFT JOIN category pc ON (pc.category_id = c.parent_id)'
        . ' LEFT JOIN category gc ON (gc.category_id = pc.parent_id)',
     columns => [
        "replace(product.product_id, '_', '') as product_id2"
        , "c.category_title as c_title1"
        , "pc.category_title as c_title2"
        , "CASE WHEN c.category_id ~* '^.{7}\$' THEN gc.category_title ELSE '' END as c_title3"
        , qw(product.product_id product.product_name product.mfg_product_id ps.standard_document_identifier co.legal_name)
     ],
     colnames => [qw(product_id product_id2 product_name mfg_product_id standard_document_identifier legal_name c_title1 c_title2 c_title3)],
     scored   => { map { $_ => .1 } qw(c_title1 c_title2 c_title3 legal_name) },
 },
 {
     keyword_type => 'A',
     table => 'product',
     temp_table => 'product_temp',
     detail_table => 'product_standard LEFT JOIN standard s USING (standard_id)',
     where => "s.standard_org_id = 'astm'",
     columns => [qw(s.standard_document_identifier)],
 },
 );
our $KINFO_BY_TYPE = {map {$_->{keyword_type} => $_} @KEYWORD_INDEXES};
our $NORMAL_SCORE = 10; # there is also a default value in ddl_pg_v2.sql (the same)

# insert for a single row, which is from the detail table if master/detail
sub _insert_keywords {
    my ($to_dbh, $pkeyval, $keyword_type, $keyword_table, $terms, $pkeyname, $delete_first, $score) = @_;
    
     # exclude empty/undef ones
    my @colvals = grep {$_} @$terms;

    my @keywords = map {@{term_to_keywords($_, 'index', $keyword_type)}} @colvals;

    # we need to avoid duplicates from repeated words across these columns
    my %seen = ();
    @keywords = grep { !$seen{$_}++} @keywords;

    debug("inserting $keyword_table $pkeyname=$pkeyval : @keywords");
    if ($delete_first) {
        dbmodify($to_dbh, 'delete', $keyword_table, undef, $pkeyname, $pkeyval, 0);
        # dbdelete($to_dbh, $keyword_table, "$pkeyname = ?", [$pkeyval], 0);
    }
    for my $keyword (@keywords) {
        dbmodify($to_dbh, 'insert', $keyword_table, {
                                                     keyword => $keyword,
                                                     keyword_type => $keyword_type,
                                                     $pkeyname => $pkeyval,
                                                     (defined $score) ? (score => $score) : (),
                                                    });
    }
}


# make and insert keywords with respective score
sub _insert_keywords_with_score {
    my ($to_dbh, $pkeyval, $keyword_type, $keyword_table, $scoredterms, $pkeyname, $delete_first) = @_;

    my $keyscore = {};
    for my $t (keys %$scoredterms) {
        next if not $t;
        my $s = $scoredterms->{$t};
        my $k = term_to_keywords($t, 'index', $keyword_type);
        # TODO: filter stopwords out?
        # repeated keywords score calculation:
        # additive:
#       grep { $keyscore->{$_} += $s } @$k;
        # more flexible:
        foreach ( @$k ) {
            if ( not $keyscore->{$_} )  { $keyscore->{$_} = $s; }
            elsif ( $keyscore->{$_} < $s ) { $keyscore->{$_} += $s; }
            else { $keyscore->{$_} += 1; }  # a silly hack
        }
    }

    my @keywords = keys %$keyscore;
    debug("inserting $keyword_table $pkeyname=$pkeyval : @keywords");
    if ($delete_first) {
        dbmodify($to_dbh, 'delete', $keyword_table, undef, $pkeyname, $pkeyval, 0);
        # dbdelete($to_dbh, $keyword_table, "$pkeyname = ?", [$pkeyval], 0);
    }
    
    for my $keyword (@keywords) {
        dbmodify($to_dbh, 'insert', $keyword_table, {
                                                     keyword => $keyword,
                                                     keyword_type => $keyword_type,
                                                     $pkeyname => $pkeyval,
                                                     score => $keyscore->{$keyword},
                                                    });
    }
}

sub set_all_keywords {
    my ($to_dbh, $delete_first) = @_;
    for (keys %$KINFO_BY_TYPE) {
        set_keywords($to_dbh, $_, undef, $delete_first);
    }
}

# $master_row restricts update to just that row, if specified
# $master_row is a record {field=>value,...} hash, if specified
sub set_keywords {
    my ($to_dbh, $keyword_type, $master_row, $delete_first) = @_;
    my $info = $KINFO_BY_TYPE->{$keyword_type} || die "unknown keyword type '$keyword_type'";
    my ($table, $temp_table, $detail_table, $colnames, $where) = @$info{qw(table temp_table detail_table columns where)};
    my $pkeyname = "$table\_id";
    my $keyword_table = $temp_table ? "$temp_table\_keyword" : "$table\_keyword";
    debug("processing keywords for table $table, keyword type '$keyword_type'" . ($master_row ? " record " . $master_row->{$pkeyname} : ''));
    my $selcols = join(', ', @$colnames);

    # always delete all existing rows if no $master_row
    # won't cost much if redundant
    if (!$master_row) {
        debug("deleting existing $keyword_table rows");
        dbdelete($to_dbh, $keyword_table, "keyword_type='$keyword_type'", undef, 0);
        $delete_first = 0;
    }

    if ($detail_table) {
        my $sql = "SELECT $pkeyname, $selcols FROM $detail_table"  . ($where ? " WHERE $where" : '');
        if ($master_row) {
            my $pkeyval = $master_row->{$pkeyname} || die("no pkeyval in master row: ", Dumper($master_row));
            $sql .= ($where ? " AND " : " WHERE ") . "$pkeyname = '$pkeyval'";
        }

        my $detail_rows = dbselect($to_dbh, $sql);
        # combine by $pkeyname so can index all at once without duplicates, in case multiple detail rows have same keys
        my $terms_by_pkey = {};
        for my $dr (@$detail_rows) {
            my $pk = $dr->{$pkeyname} || die("bad detail row: ", Dumper($dr));
            my $a = ($terms_by_pkey->{$pk} ||= []);
            my @colvals = @$dr{map { s/^.*\.//; $_; } @$colnames};
            push(@$a, @colvals);
            debug "\@a: ". join(' ', @$a );
        }
        # now index each one
        while(my($pkeyval, $terms) = each %$terms_by_pkey) {
            debug("doing all terms from all $detail_table rows for $table record '$pkeyval': @$terms");
            _insert_keywords($to_dbh, $pkeyval, $keyword_type, $keyword_table, $terms, $pkeyname, $delete_first);
        }
        return;
    }

    my $rows;
    if ($master_row) {
        $rows = [$master_row];
    }
    else {
        my $from_tables = $info->{from} || $table;
        my $sql = "SELECT $table\.$pkeyname, $selcols FROM $from_tables" . ($where ? " WHERE $where" : '') . " ORDER BY $table\.$pkeyname";
        #print Dumper($sql);
        $rows = dbselect($to_dbh, $sql);
        
    }

    my $scored = $info->{scored};
    my $key_names = $info->{colnames} || $colnames;

    push @$rows, { $pkeyname => '__FINISH__' };

    my $count = 0;
    my $prev_pkeyv;
    my %colvals = ();
    for my $row (@$rows) {
        my $pkeyv = $row->{$pkeyname} || die("no value for pkey '$pkeyname': ", Dumper($row));
        if ( $prev_pkeyv && $prev_pkeyv ne $pkeyv) { #&& $pkeyv ne '__FINISH__' ) {
            if ( $scored ) {
                _insert_keywords_with_score($to_dbh, $prev_pkeyv, $keyword_type, $keyword_table, { %colvals }, $pkeyname, $delete_first);
            } else {
                _insert_keywords($to_dbh, $prev_pkeyv, $keyword_type, $keyword_table, [keys %colvals], $pkeyname, $delete_first);
            }
            %colvals = ();
                unless (++$count % 1000) {
                info("have processed $count $table rows, with ", (dbopcounts(1)->{$keyword_table}->{insert}||0), " inserts");
            }
        }
        last if $pkeyv eq '__FINISH__';
        $prev_pkeyv = $pkeyv;
        if ( $scored ) {
            map {
                if ($row->{$_}) {
                    $colvals{$row->{$_}} = ((defined $scored and defined $scored->{$_}) ? $scored->{$_} : 1) * $NORMAL_SCORE;
                }
            } @$key_names;
        } else {
            map { $colvals{$_}++ } @$row{@$key_names};
        }
    }
}

sub testme {
    print Dumper(term_to_keywords("a'a//bbb111", 'index', 'P'));
    print Dumper(term_to_keywords("a(1)", 'index', 'P'));
    print Dumper(term_to_keywords("a&#160;&quot;b", 'index', 'P'));
}

1;
