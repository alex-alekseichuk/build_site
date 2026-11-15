#!/usr/bin/perl -w
use Data::Dumper;

use strict;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Test::More qw/no_plan/;

use DBI;

use BST;
use BSA::Controller::Companies;

my $config = BST::configuration();

my $dbh = DBI->connect('DBI:Pg:dbname=' . $config->{dbname},
    $config->{dbuser},
    $config->{dbpass}
) or die;

my $controller = new BSA::Controller::Companies;

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

    *FakeContext::params = sub {
        my $self = shift;
        if (@_) {
            $self->{params} = @_;
        }
        return $self->{params};
    };
}

{ no warnings; *BST::Core::hide_suppressed = sub { return 0; }; }

my $c = bless { stash => {}, params => {} } , 'FakeContext';

$controller->list($c);

my $companies_true = $dbh->selectall_arrayref(
    q{SELECT company.company_id, legal_name, company_nickname, feature_level, company_summary_text} .
    q{ FROM "company" LEFT JOIN company_feature ON (company.company_id = company_feature.company_id AND feature_name = 'companyresource' AND feature_status = 'live')} .
    q{ WHERE company_type = 'manufacturer'} .
    q{ ORDER BY feature_level, UPPER(REGEXP_REPLACE(COALESCE(company_nickname,legal_name),E'^(\\\\d)',E'ZZZ\\\\1'))},
    { Slice => {} }
);

my $companies_have = $c->stash->{list};

ok($#{ $companies_true } == $#{ $companies_have }, "companies count");

for (0..$#{ $companies_have }) {
    ok($companies_true->[$_]->{company_id} eq $companies_have->[$_]->company_id, "company id");
    ok($companies_true->[$_]->{feature_level} eq $companies_have->[$_]->feature_level, "feature level")
        if $companies_true->[$_]->{feature_level};
    ok($companies_true->[$_]->{company_nickname} eq $companies_have->[$_]->company_nickname, "company nickname")
        if $companies_true->[$_]->{company_nickname};
    ok($companies_true->[$_]->{legal_name} eq $companies_have->[$_]->legal_name, "legal name")
        if $companies_true->[$_]->{legal_name};
    ok($companies_true->[$_]->{company_summary_text} eq $companies_have->[$_]->company_summary_text, "company summary text")
        if $companies_true->[$_]->{company_summary_text};
}
