#!/usr/bin/perl

use strict;
use LWP::Simple;
use LWP::UserAgent;
use HTTP::Cookies;
use URI::Escape;
use Data::Dumper;

use FindBin qw($Bin);
use lib "$Bin/../../lib";
# use Test::More qw(no_plan);

use constant COOKIES_FILE    => 'cookies.txt';
use constant COOKIES_EXPIRE  => 0.005;
use constant CATEGORIES_FILE => "$Bin/categories.txt";

use constant BUILDSITE_NEW   => 'http://crunch.ahinea.com:3000/';


die "Categories file does not exists" unless -e CATEGORIES_FILE;
open FILE, CATEGORIES_FILE;
my @cats = map { chomp; $_ } <FILE>;
close FILE;

my $oCookies = new HTTP::Cookies(
    file => COOKIES_FILE,
    ignore_discard => 1,
    autosave => 1
);

my $oNew = new LWP::UserAgent;
$oNew->cookie_jar($oCookies);

$oNew->post(BUILDSITE_NEW . '/login', {
    login => 'ieg',
    password => ($ENV{BST_TEST_PASS} or die "set the BST_TEST_PASS env var")
})->content;

$| = 1;

foreach my $category (@cats) {
    my $html = get(sprintf 'http://buildsite.com/query/detail/category/%s', $category);

    my $oldProd = get_items_hash(\$html, '/product/', 'prodlist');
    my $oldManuf = get_items_hash(\$html, '/manufacturer/', 'mfglist');

    my ($id) = $category =~ m/^([\w\d]+?)_/;
    $html = $oNew->get(sprintf '%s/categories/view?id=%s', BUILDSITE_NEW, $id)->content;
    my $newProd = get_items_hash(\$html, '/product/view\?id=', 'category-product-list', 'adv');
    my $newManuf = get_items_hash(\$html, '/companies/view\?id=', 'category-manufacturer-list', 'adv');
    
    warn "CATEGORY:$category\n";
    warn "OLD:\n" . Dumper($oldProd);
    warn "NEW:\n" . Dumper($newProd);

    my $p_errors = {};
    foreach (keys %$oldProd) {
        unless (defined $newProd->{$_}) {
           $p_errors->{$_} = 'not found';
           next;
        }
        $p_errors->{$_} = 'highlighted wrongly' unless $newProd->{$_} eq $oldProd->{$_};
    }

    my $m_errors = {};
    foreach (keys %$oldManuf) {
        $m_errors->{$_} = 'not found' unless (defined $newManuf->{$_});
    }


    printf "\nCategory %s ", $category;
    unless (keys %$p_errors || keys %$m_errors) {
        print "ok";
    } else {
        print "has errors:";
        printf "\n\tProduct %s %s", $_, $p_errors->{$_} foreach keys %$p_errors;
        printf "\n\tManufacturer %s %s", $_, $m_errors->{$_} foreach keys %$m_errors;
    }
    print "\n";
}




sub get_items_hash {
    my $html = shift;
    my $idRegexp = shift;
    my $class = shift;
    my $adved = shift || 'row-highlight';
    
    my ($t) = $$html =~ m/$class(.*?)<\/ol>/gis;
    my @m = $t =~ m/<li.*?<\/li>/gis;
    return {
        map {
            my ($id) = m/$idRegexp([\w\d_]+)/gis;
            $id => m/$adved/ ? 1 : 0
        }  $t =~ m/<li.*?<\/li>/gis
    }
}
