#!/usr/bin/perl -w

use strict;

use Data::Dumper;

use FindBin qw($Bin);

use Getopt::Long;
use LWP::UserAgent;
use HTTP::Cookies;

use Test::MultiFork qw(stderr dofork);
use Test::More qw(no_plan);
use Test::Differences;

my ($CONFIG, $host, $count, $fork, $login, $pass);

GetOptions(
    "host=s"                => \$host,
    "categories-count=i"    => \$count,
    "fork=i"                => \$fork,
    "login=s"               => \$login,
    "pass=s"                => \$pass
);

$CONFIG->{_config} = {
    COOKIES_FILE    => $Bin . '/cookies.txt',
    COOKIES_EXPIRE  => 0.005,
    CATEGORIES_FILE => $Bin . '/categories.txt',
    BUILDSITE_NEW   => $host || 'http://localhost:3000',
    BUILDSITE_OLD   => 'http://buildsite.com/',
    LOGIN           => $login || 'ieg',
    PASSWORD        => $pass || $ENV{BST_TEST_PASS} or die "set the BST_TEST_PASS env var",
    COMPARE         => [qw/products manufacturers categories/],
    CATEGORIES_NUM  => $count || 1,
    FORK_NUM        => $fork || 1,
    FORK_TIMEOUT    => 60,
    UA_TIMEOUT      => 60
};

$CONFIG->{COOKIE} = new HTTP::Cookies(
    file            => $CONFIG->{_config}->{COOKIES_FILE},
    ignore_discard  => 1,
    autosave        => 1
);

$CONFIG->{UA}     = new LWP::UserAgent(
    timeout     => $CONFIG->{_config}->{UA_TIMEOUT},
    cookie_jar  => $CONFIG->{COOKIE}
);

$CONFIG->{UA}->post($CONFIG->{_config}->{BUILDSITE_NEW} . '/login', {
    login       => $CONFIG->{_config}->{LOGIN},
    password    => $CONFIG->{_config}->{PASSWORD}
});

sub _compare {
    ok((keys %{ $_[0]->{products} } && keys %{ $_[0]->{manufacturers} } && keys %{ $_[0]->{categories} }), "check data");
    eq_or_diff($_[0]->{$_}, $_[1]->{$_}, "compare $_") foreach @{ $CONFIG->{_config}->{COMPARE} };
}

sub get_buildsite_new_category_detail_page {
    $_  = shift; /[^_]+/;
    return $CONFIG->{UA}->get($CONFIG->{_config}->{BUILDSITE_NEW} . '/categories/view?id=' . $&)->content;
}

sub get_buildsite_old_category_detail_page {
    return $CONFIG->{UA}->get($CONFIG->{_config}->{BUILDSITE_OLD} . 'query/detail/category/' . shift)->content;
}

sub get_old_products {
    return { map { $_ => 0 } shift =~ m!query/detail/product/([^"]+)!gis };
}
sub get_old_manufacturers {
    return { map { $_ => 0 } shift =~ m!query/detail/manufacturer/([^"]+)!gis };
}
sub get_old_categories {
    return { map { $_ => 0 } shift =~ m!<td valign="baseline"><a href="[^"]*">\W*([^<]*)</a></td>!gis };
}

sub get_new_products {
    return { map { $_ => 0 } shift =~ m!product/view\?id=([^"]+)!gis };
}
sub get_new_manufacturers {
    return { map { $_ => 0 } shift =~ m!companies/view\?id=([^"]+)!gis };
}
sub get_new_categories {
    local $_  = shift;
    m!<table\sclass="basic">[^<]*<tr>[^<]*<th>Category</th>[^<]*<th>Category\sName</th>[^<]*<th>Products</th>[^<]*</tr>(.*)</tr>[^<]*</table>!is;
    
    my $result;
    while (m!<tr>[^<]*<td>\s*((?:&nbsp;)*)\s*(?:<a[^>]*>)\W*\W*<?([\w\.]*)[^<]*(?:</a>)?[^<]*</td>[^<]*<td>!gis) {
        $result->{$2} = @{ [ $1 =~ /(?:&nbsp;){4}/gi ] };
    }
    
    return $result;
}

sub get_categories {
    my $file    = shift;
    
    die "Categories file does not exists" unless -e $file;
    
    open FILE, $file;
        my @cats = map { chomp; $_ } <FILE>;
    close FILE;
    
    return (scalar @cats) ? \@cats : die "Categories file is empty";
}

sub shuffle {
    my $arr = shift;
    my $num = @$arr;
    while (--$num) {
        srand;
        my $j = int rand ($num + 1);
        @$arr[$num, $j] = @$arr[$j, $num];
    }
    return $arr;
}

$Test::MultiFork::inactivity = $CONFIG->{_config}->{FORK_TIMEOUT};

my ($categories, $pristine);

$categories = get_categories($CONFIG->{_config}->{CATEGORIES_FILE});
$categories = [ map { @{ $categories }[rand @{ $categories }] } 0..$CONFIG->{_config}->{CATEGORIES_NUM} - 1 ];

foreach (@{ $categories }) {
    my $page   = get_buildsite_new_category_detail_page($_);
    
    $pristine->{category}->{$_} = {
        categories      => get_new_products($page),
    	manufacturers   => get_new_manufacturers($page),
        products        => get_new_categories($page)
    };    
}

dofork("b$CONFIG->{_config}->{FORK_NUM}");

a:
foreach (@{ shuffle($categories) }) {
    my $page   = get_buildsite_new_category_detail_page($_);
    diag("Category: $_");
    
    _compare({
        categories      => get_new_products($page),
        manufacturers   => get_new_manufacturers($page),
        products        => get_new_categories($page)
    }, $pristine->{category}->{$_});
}