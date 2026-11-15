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
use BSA::Controller::Search;

my $dbh = DBI->connect('DBI:Pg:dbname=' . config('dbname'),
    config('dbuser'),
    config('dbpass')
) or die;

my ($controller, $c);

$controller = new BSA::Controller::Search;

{
    no warnings;

    *BSA::Controller::Search::formbuilder = sub {
        package FakeFormbuilder;

        return bless {}, 'FakeFormbuilder';

        sub params {

        }

        sub submitted {

        }

        1;
    };
}

{
    no warnings;

    *FakeContext::stash = sub {
        my $self = shift;
        if (@_) {
            my $stash = @_ > 1 ? {@_} : $_[0];
            foreach my $key ( keys %$stash ) {
                $self->{stash}->{$key} = $stash->{$key};
            }
        }
        return $self->{stash};
    };

    *FakeContext::req = sub {
        return shift;
    };

    *FakeContext::request = *FakeContext::req;

    *FakeContext::response = sub {
        return shift;
    };

    *FakeContext::redirect = sub {
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

    *FakeContext::param = *FakeContext::params;
}

$c = bless { stash => {}, params => {} } , 'FakeContext';

my ($companies_true, $companies_have, $query, $false);

{ no warnings; *BST::Core::hide_suppressed = sub { return 0; }; }
{
    no warnings;

    *FakeFormbuilder::field = sub {
        shift;
        return ($_[0] eq 'q') ? $_ : ($_[0] eq 'where') ? 'manufacturer' : ($_[0] eq 'term') ? '' : undef;
    };

    *FakeContext::user = sub {
        return BST::User->load('staff');
    };
}

foreach (sub { return map { join '', map { ('a'..'z')[rand(26)] } (1..2) } (1..10) }->(), @{ [qw/prod ltd com Symons dayton/] }) {
    $companies_true = $dbh->selectall_arrayref(
        q{SELECT company.company_id} .
        q{ FROM company LEFT JOIN company_feature ON (company_feature.feature_name = 'companyresource' AND company_feature.feature_status = 'live' AND company.company_id = company_feature.company_id)} .
        qq{ WHERE company_type = 'manufacturer' AND company.legal_name || ' ' || COALESCE(company.company_nickname, '') ~* E'\\\\m$_'} .
        q{ ORDER BY company_feature.feature_level, UPPER(REGEXP_REPLACE(COALESCE(company_nickname,legal_name),E'^(\d)',E'ZZZ\1'))},
        { Slice => {} }
    );
    $controller->index($c);
    $companies_have = $c->stash->{list}->{all};

    ok($#{ $companies_true } == $#{ $companies_have }, qq{companies count for search query [$_] and stuff users});

    $false = 0;

    for (0..$#{ $companies_have }) {
        no warnings;

        ++$false if $companies_true->[$_]->{company_id} ne $companies_have->[$_]->company_id;
    }

    ok($false == 0, qq{companies compare for search query [$_] and stuff users});
}

{ no warnings; *BST::Core::hide_suppressed = sub { return 1; }; }

foreach (sub { return map { join '', map { ('a'..'z')[rand(26)] } (1..2) } (1..10) }->(), @{ [qw/prod ltd com Symons dayton/] }) {
    $companies_true = $dbh->selectall_arrayref(
        q{SELECT company.company_id} .
        q{ FROM company LEFT JOIN company_feature ON (company_feature.feature_name = 'companyresource' AND company_feature.feature_status = 'live' AND company.company_id = company_feature.company_id)} .
        qq{ WHERE company_type = 'manufacturer' AND company.public_visible AND company.suppress_reason_code = '' AND company.legal_name || ' ' || COALESCE(company.company_nickname, '') ~* E'\\\\m$_'} .
        q{ ORDER BY company_feature.feature_level, UPPER(REGEXP_REPLACE(COALESCE(company_nickname,legal_name),E'^(\d)',E'ZZZ\1'))},
        { Slice => {} }
    );
    $controller->index($c);
    $companies_have = $c->stash->{list}->{all};

    ok($#{ $companies_true } == $#{ $companies_have }, qq{companies count for search query [$_] and stuff users});

    $false = 0;

    for (0..$#{ $companies_have }) {
        no warnings;

        ++$false if $companies_true->[$_]->{company_id} ne $companies_have->[$_]->company_id;
    }

    ok($false == 0, qq{companies compare for search query [$_] and stuff users});
}

{ no warnings; *BST::Core::hide_suppressed = sub { return 0; }; }

$c->param->{mfg_my_all} = 'my';

my $my_manufacturers = { map { $_ => 1 } split /;/, ($dbh->selectrow_hashref(q{SELECT att_val FROM setting WHERE scope = 'location' AND scope_value = 'account4703' AND att_name = 'default_allow_publishers'}))->{att_val} };

foreach (sub { return map { join '', map { ('a'..'z')[rand(26)] } (1..2) } (1..10) }->(),@{ [qw/prod ltd com Symons dayton/] }) {
    $companies_true = $dbh->selectall_arrayref(
        q{SELECT company.company_id} .
        q{ FROM company LEFT JOIN company_feature ON (company_feature.feature_name = 'companyresource' AND company_feature.feature_status = 'live' AND company.company_id = company_feature.company_id)} .
        qq{ WHERE company_type = 'manufacturer' AND company.legal_name || ' ' || COALESCE(company.company_nickname, '') ~* E'\\\\m$_'} .
        q{ ORDER BY company_feature.feature_level, UPPER(REGEXP_REPLACE(COALESCE(company_nickname,legal_name),E'^(\d)',E'ZZZ\1'))},
        { Slice => {} }
    );

    $companies_true = [ grep { $my_manufacturers->{$_->{company_id}} } @{ $companies_true } ];

    $controller->index($c);
    $companies_have = $c->stash->{list}->{all};

    ok($#{ $companies_true } == $#{ $companies_have }, qq{companies count for search query [$_] with my manufacturers and stuff users});

    $false = 0;

    for (0..$#{ $companies_have }) {
        no warnings;

        ++$false if $companies_true->[$_]->{company_id} ne $companies_have->[$_]->company_id;
    }

    ok($false == 0, qq{companies compare for search query [$_] with my manufacturers and stuff users});
}

{ no warnings; *BST::Core::hide_suppressed = sub { return 1; }; }

foreach (sub { return map { join '', map { ('a'..'z')[rand(26)] } (1..2) } (1..10) }->(),@{ [qw/prod ltd com Symons dayton/] }) {
    $companies_true = $dbh->selectall_arrayref(
        q{SELECT company.company_id} .
        q{ FROM company LEFT JOIN company_feature ON (company_feature.feature_name = 'companyresource' AND company_feature.feature_status = 'live' AND company.company_id = company_feature.company_id)} .
        qq{ WHERE company_type = 'manufacturer' AND company.public_visible AND company.suppress_reason_code = '' AND company.legal_name || ' ' || COALESCE(company.company_nickname, '') ~* E'\\\\m$_'} .
        q{ ORDER BY company_feature.feature_level, UPPER(REGEXP_REPLACE(COALESCE(company_nickname,legal_name),E'^(\d)',E'ZZZ\1'))},
        { Slice => {} }
    );

    $companies_true = [ grep { $my_manufacturers->{$_->{company_id}} } @{ $companies_true } ];

    $controller->index($c);
    $companies_have = $c->stash->{list}->{all};

    ok($#{ $companies_true } == $#{ $companies_have }, qq{companies count for search query [$_] with my manufacturers and stuff users});

    $false = 0;

    for (0..$#{ $companies_have }) {
        no warnings;

        ++$false if $companies_true->[$_]->{company_id} ne $companies_have->[$_]->company_id;
    }

    ok($false == 0, qq{companies compare for search query [$_] with my manufacturers and stuff users});
}
