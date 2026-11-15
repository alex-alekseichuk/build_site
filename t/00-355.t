#!/usr/bin/perl -w
use Data::Dumper;

use strict;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Test::More qw/no_plan/;

use Catalyst::Test 'BSA';

use BST::Config;
use DBI;

*BSA::Controller::Companies::formbuilder = sub {
    package Fake;

    return bless {}, 'Fake';

    sub params {

    }

    1;
};

my $c = BSA->prepare;

my $controller = $c->controller('BSA::Controller::Companies');

$controller->list($c);

my @want;

foreach (@{ $c->stash->{list} }) {
    if ($_->name =~ /^\d+/i) {
        push @want, $_->name;
    }
}

@want = sort @want;

my @have = @{ $c->stash->{list} }[@{ $c->stash->{list} } - @want..$#{ $c->stash->{list} }];

for (0..$#want) {
    ok($want[$_] eq $have[$_]->name);
}
