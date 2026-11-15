#!/usr/bin/perl

use strict;
use LWP::UserAgent;
use HTTP::Cookies;
use URI::Escape;
use Data::Dumper;

use FindBin qw($Bin);
use lib "$Bin/../../lib";
# use Test::More qw(no_plan);

use BST;
use BST::Product;

use constant COOKIES_FILE    => 'cookies.txt';
use constant COOKIES_EXPIRE  => 0.005;
use constant OUTPUT_FILES    => 0;

die "No args specified!" unless @ARGV;
my $what = shift @ARGV;
my $term = @ARGV && shift @ARGV eq 'or' ? 'or' : 'and';
my $type   = @ARGV ? 're' : 'fts';

my $oCookies = new HTTP::Cookies(
    file => COOKIES_FILE,
    ignore_discard => 1,
    autosave => 1
);

my $oUA = new LWP::UserAgent;
$oUA->cookie_jar($oCookies);

$oUA->post(
    'http://bs4.buildsite.com:82/enduser/login/dologin.mas',
    {
        login => 'staff',
        password => ($ENV{BST_TEST_PASS} or die "set the BST_TEST_PASS env var"),
        submit => 'login',
        destination => '/enduser/index.html',
        expires => '+1y'
    }
) unless (-e COOKIES_FILE && -M COOKIES_FILE < COOKIES_EXPIRE);


$oUA->get('http://bs4.buildsite.com:82/enduser/product/product_search.mas?mfg_my_all=all');
my $res = $oUA->get(sprintf 'http://bs4.buildsite.com:82/enduser/product/product_search.mas?from_form=1&Submit=Search&all_any=%s&product_search=%s', $term eq 'or' ? 'any' : 'all', uri_escape($what));
my @old_ids = $res->content =~ m/prod_id=([^'"]+)["']/gs;

# $oUA->get('http://bs4.buildsite.com:82/enduser/utils/logout.mas');

# my @new_ids = map {$_->product_id} ($type eq 're' ? BST::Product->name_search_re($what, $term) : BST::Product->name_search($what, $term) );
my @new_ids = map {$_->product_id} BST::Product->name_search($what, $term);
my %diff = map {; $_ => 1} @old_ids;
my @diff = map {'extra: ' . $_} grep {!delete $diff{$_}} @new_ids;
push @diff, map {'not found: ' . $_} keys %diff;

if (OUTPUT_FILES) {
    my $fname = lc $what;
    $fname =~ s/[^a-z0-9_]//g;

    open FILE, ">$fname.old.txt";
    print FILE join "\n", @old_ids;
    close FILE;

    open FILE, ">$fname.new.txt";
    print FILE join "\n", @new_ids;
    close FILE;

    open FILE, ">$fname.diff.txt";
    print FILE join "\n", @diff;
    close FILE;
}

# is(scalar @diff, 0, 'No differencies');


printf "%s", $what;
if (%diff) {
    printf "\n%d items not found:", scalar keys %diff;
    print join "\n\t", '', keys %diff;
    print "\n";
} else {
    print "... ok\n";
}
