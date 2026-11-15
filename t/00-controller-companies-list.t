#!/usr/bin/perl -w

package BSA;

sub path_to {}

1;

package main;

use Data::Dumper;

use strict;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Test::More qw/no_plan/;

use DBI;

use BST qw/config/;
use BSA::Controller::Companies;

my $dbh = DBI->connect('DBI:Pg:dbname=' . config('dbname'),
    config('dbuser'),
    config('dbpass')
) or die;

my ($controller, $c);

$controller = new BSA::Controller::Companies;

{
    no warnings;
    *BSA::Controller::Companies::formbuilder = sub {
        package FakeFormbuilder;
        return bless {}, 'FakeFormbuilder';
        sub params {
        }
        1;
    };
}

{
    no warnings;
    *FakeContext::self      = sub {
        return shift;
    };
    *FakeContext::stash     = sub {
        my $self = shift;
        if (@_) {
            my $stash = @_ > 1 ? {@_} : $_[0];
            foreach my $key ( keys %$stash ) {
                $self->{stash}->{$key} = $stash->{$key};
            }
        }
        return $self->{stash};
    };
    *FakeContext::redirect  = sub {
        my $self = shift;
        if (@_) {
            $self->{redirect} = @_;
        }
        return $self->{redirect};
    };
    *FakeContext::params = sub {
        my $self = shift;
        if ($_[0]) {
            return $self->{params}->{$_[0]} || '';
        }
        return $self->{params};
    };
    *FakeContext::list      = sub {
        return {
            default_allow_publishers => $dbh->selectrow_array(
                q{SELECT att_val FROM setting WHERE att_name = 'default_allow_publishers' AND scope = 'account' AND scope_value = 'account4702'}
            )
        };
    };
    *FakeContext::param     = *FakeContext::params;
    *FakeContext::response  = *FakeContext::self;
    *FakeContext::req       = *FakeContext::self;
    *FakeContext::request   = *FakeContext::self;
    *FakeContext::user      = *FakeContext::self;
    *FakeContext::settings  = *FakeContext::self;
}

$c = bless { stash => {}, params => {} } , 'FakeContext';

my ($true, $have);

# Companies list for stuff users
{ no warnings; *BST::Core::hide_suppressed = sub { return 0; }; }
$c->param->{mfg_my_all} = 'all';

$true = get_sql_companies(1);
$controller->list($c);
$have = $c->stash->{list};

ok($#{ $true } == $#{ $have }, "companies count for stuff users");
compare_companies(
    $true, $have,
    [qw/company_id feature_level company_nickname legal_name company_summary_text/],
    'companies compare for stuff users',
);

# Companies list for stuff users with my_mfg param
{ no warnings; *BST::Core::hide_suppressed = sub { return 0; }; }
$c->param->{mfg_my_all} = 'my';

$true = get_sql_my_companies(1);
$controller->list($c);
$have = $c->stash->{list};

ok($#{ $true } == $#{ $have }, "companies count for stuff users with my_mfg param");
compare_companies(
    $true, $have,
    [qw/company_id feature_level company_nickname legal_name company_summary_text/],
    'companies compare for stuff users with my_mfg param',
);

# Companies list for non stuff users
{ no warnings; *BST::Core::hide_suppressed = sub { return 1; }; }
$c->param->{mfg_my_all} = 'all';

$true = get_sql_companies(0);
$controller->list($c);
$have = $c->stash->{list};

ok($#{ $true } == $#{ $have }, "count for all companies and non stuff users");
compare_companies(
    $true, $have,
    [qw/company_id feature_level company_nickname legal_name company_summary_text/],
    'companies compare for non stuff users',
);

# Companies list for non stuff users with my_mfg param
{ no warnings; *BST::Core::hide_suppressed = sub { return 1; }; }
$c->param->{mfg_my_all} = 'my';

$true = get_sql_my_companies(0);
$controller->list($c);
$have = $c->stash->{list};

ok($#{ $true } == $#{ $have }, "count for all companies and non stuff users with my_mfg param");
compare_companies(
    $true, $have,
    [qw/company_id feature_level company_nickname legal_name company_summary_text/],
    'companies compare for non stuff users with my_mfg param',
);

# Companies list for category and stuff users
{ no warnings; *BST::Core::hide_suppressed = sub { return 0; }; }
$c->param->{mfg_my_all} = 'all';

foreach (@{ $dbh->selectcol_arrayref('SELECT category_id FROM category ORDER BY RANDOM() LIMIT 100') }) {
    { no warnings; *FakeFormbuilder::params = sub { return $_ }; }

    $true = get_sql_companies_by_category(1, $_);
    $controller->list($c);
    $have = $c->stash->{list};

    ok($#{ $true } == $#{ $have }, "count for $_ category companies and stuff users");
    compare_companies(
        $true, $have,
        [qw/company_id feature_level company_nickname legal_name company_summary_text/],
        "category $_ companies compare for stuff users",
    );
    ok($c->stash->{category}->id eq $_, 'category object');
}

# Companies list for category and stuff users with my_mfg param
{ no warnings; *BST::Core::hide_suppressed = sub { return 0; }; }
$c->param->{mfg_my_all} = 'my';

foreach (@{ $dbh->selectcol_arrayref('SELECT category_id FROM category ORDER BY RANDOM() LIMIT 100') }) {
    { no warnings; *FakeFormbuilder::params = sub { return $_ }; }

    $true = get_sql_my_companies_by_category(1, $_);
    $controller->list($c);
    $have = $c->stash->{list};

    ok($#{ $true } == $#{ $have }, "count for $_ category companies and stuff users with my_mfg param");
    compare_companies(
        $true, $have,
        [qw/company_id feature_level company_nickname legal_name company_summary_text/],
        "category $_ companies compare for stuff users with my_mfg param",
    );
    ok($c->stash->{category}->id eq $_, 'category object');
}

# Companies list for category and non stuff users
{ no warnings; *BST::Core::hide_suppressed = sub { return 1; }; }
$c->param->{mfg_my_all} = 'all';

foreach (@{ $dbh->selectcol_arrayref('SELECT category_id FROM category ORDER BY RANDOM() LIMIT 100') }) {
    { no warnings; *FakeFormbuilder::params = sub { return $_ }; }

    $true = get_sql_companies_by_category(0, $_);
    $controller->list($c);
    $have = $c->stash->{list};

    ok($#{ $true } == $#{ $have }, "count for $_ category companies and non stuff users");
    compare_companies(
        $true, $have,
        [qw/company_id feature_level company_nickname legal_name company_summary_text/],
        "category $_ companies compare for non stuff users",
    );
    ok($c->stash->{category}->id eq $_, 'category object');
}
exit;
# Companies list for category and stuff non users with my_mfg param
{ no warnings; *BST::Core::hide_suppressed = sub { return 1; }; }
$c->param->{mfg_my_all} = 'my';

foreach (@{ $dbh->selectcol_arrayref('SELECT category_id FROM category ORDER BY RANDOM() LIMIT 100') }) {
    { no warnings; *FakeFormbuilder::params = sub { return $_ }; }

    $true = get_sql_my_companies_by_category(0, $_);
    $controller->list($c);
    $have = $c->stash->{list};

    ok($#{ $true } == $#{ $have }, "count for $_ category companies and non stuff users with my_mfg param");
    compare_companies(
        $true, $have,
        [qw/company_id feature_level company_nickname legal_name company_summary_text/],
        "category $_ companies compare for non stuff users with my_mfg param",
    );
    ok($c->stash->{category}->id eq $_, 'category object');
}

sub get_sql_companies_by_category {
    my $stuff_user  = shift;
    my $category    = shift;
    
    return $true = $dbh->selectall_arrayref(
        sprintf(
            q{SELECT company.company_id, legal_name, company_nickname, feature_level, company_summary_text} .
            q{ FROM "company" LEFT JOIN company_feature ON (company.company_id = company_feature.company_id AND feature_name = 'companyresource' AND feature_status = 'live') JOIN product ON (company.company_id = product.manufacturer_id)} .
            qq{ WHERE company_type = 'manufacturer' AND product.category_id = %s} .
            ($stuff_user ? '' : q{ AND company.public_visible AND company.suppress_reason_code = '' AND product.public_visible AND product.suppress_reason_code = ''}) .
            q{ GROUP BY company.company_id, legal_name, company_nickname, feature_level, company_summary_text} .
            q{ ORDER BY feature_level, UPPER(REGEXP_REPLACE(COALESCE(company_nickname,legal_name),E'^(\\\\d)',E'ZZZ\\\\1'))},
            $dbh->quote($category)
        ),
        { Slice => {} }
    );
}

sub get_sql_my_companies_by_category {
    my $stuff_user  = shift;
    my $category    = shift;
    
    my @my_mfg      = split(/;/, $dbh->selectrow_array(q{SELECT att_val FROM setting WHERE att_name = 'default_allow_publishers' AND scope = 'account' AND scope_value = 'account4702'}));
    
    return @my_mfg
        ?   $dbh->selectall_arrayref(
                sprintf(
                    q{SELECT company.company_id, legal_name, company_nickname, feature_level, company_summary_text} .
                    q{ FROM "company" LEFT JOIN company_feature ON (company.company_id = company_feature.company_id AND feature_name = 'companyresource' AND feature_status = 'live') JOIN product ON (company.company_id = product.manufacturer_id)} .
                    qq{ WHERE company_type = 'manufacturer' AND product.category_id = %s} .
                    ($stuff_user ? '' : q{ AND company.public_visible AND company.suppress_reason_code = '' AND product.public_visible AND product.suppress_reason_code = ''}) .
                    q{ AND company.company_id IN (} . join(q{,}, map { $dbh->quote($_) } @my_mfg) . q{)} .
                    q{ GROUP BY company.company_id, legal_name, company_nickname, feature_level, company_summary_text} .
                    q{ ORDER BY feature_level, UPPER(REGEXP_REPLACE(COALESCE(company_nickname,legal_name),E'^(\\\\d)',E'ZZZ\\\\1'))},
                    $dbh->quote($category)
                ),
                { Slice => {} }
            )
        : get_sql_companies_by_category($stuff_user, $category);
}

sub get_sql_companies {
    my $stuff_user  = shift;
    
    return $dbh->selectall_arrayref(
        q{SELECT company.company_id, legal_name, company_nickname, feature_level, company_summary_text} .
        q{ FROM "company" LEFT JOIN company_feature ON (company.company_id = company_feature.company_id AND feature_name = 'companyresource' AND feature_status = 'live')} .
        q{ WHERE company_type = 'manufacturer'} .
        ($stuff_user ? '' : q{ AND company.public_visible AND company.suppress_reason_code = ''}) .
        q{ ORDER BY feature_level, UPPER(REGEXP_REPLACE(COALESCE(company_nickname,legal_name),E'^(\\\\d)',E'ZZZ\\\\1'))},
        { Slice => {} }
    );
}

sub get_sql_my_companies {
    my $stuff_user  = shift;
    
    my @my_mfg      = split(/;/, $dbh->selectrow_array(q{SELECT att_val FROM setting WHERE att_name = 'default_allow_publishers' AND scope = 'account' AND scope_value = 'account4702'}));
    
    return @my_mfg
        ?   $dbh->selectall_arrayref(
                q{SELECT company.company_id, legal_name, company_nickname, feature_level, company_summary_text} .
                q{ FROM "company" LEFT JOIN company_feature ON (company.company_id = company_feature.company_id AND feature_name = 'companyresource' AND feature_status = 'live')} .
                q{ WHERE company_type = 'manufacturer'} .
                ($stuff_user ? '' : q{ AND company.public_visible AND company.suppress_reason_code = ''}) .
                q{ AND company.company_id IN (} . join(q{,}, map { $dbh->quote($_) } @my_mfg) . q{)} .
                q{ ORDER BY feature_level, UPPER(REGEXP_REPLACE(COALESCE(company_nickname,legal_name),E'^(\\\\d)',E'ZZZ\\\\1'))},
                { Slice => {} }
            )
        :   get_sql_companies($stuff_user);
}

sub compare_companies {
    my $true    = shift;
    my $have    = shift;
    my $fields  = shift;
    my $desc    = shift;
    
    my $false = 0;
    for (0..$#{ $have }) {
        no warnings;
        foreach my $param (@$fields) {
            ++$false if $true->[$_]->{$param} ne $have->[$_]->$param;
        }
    }
    ok($false == 0, $desc);
}