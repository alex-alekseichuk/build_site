#!/usr/bin/perl -w

use Data::Dumper;

use strict;

use FindBin qw($Bin);
use lib "$Bin/../../lib";

use Getopt::Long;
use LWP::UserAgent;
use HTTP::Message 1.57;
use HTTP::Request;
use HTTP::Async;
use HTTP::Cookies;

use Test::More qw(no_plan);
use Test::Differences;

use BST;

my ($CONFIG, $new_host, $old_host, $fork, $count, $login, $pass, $products, @requests);

GetOptions(
    "new-host=s"            => \$new_host,
    "old-host=s"            => \$old_host,
    "fork=i"                => \$fork,
    "login=s"               => \$login,
    "pass=s"                => \$pass,
    "company-count=s"       => \$count
);

$CONFIG->{_config} = {
    COOKIES_FILE    => $Bin . '/cookies.txt',
    CATEGORIES_FILE => $Bin . '/categories.txt',
    BUILDSITE_NEW   => $new_host || 'http://localhost:3000/',
    BUILDSITE_OLD   => $old_host || 'http://buildsite.com/',
    LOGIN           => $login || 'ieg',
    PASSWORD        => $pass || $ENV{BST_TEST_PASS} or die "set the BST_TEST_PASS env var",
    FORK            => $fork || 1,
    UA_TIMEOUT      => 60,
    COMPANY_COUNT   => $count || 1,
    ZIP_CODES       => [qw/94607 10101 77590 34436/]
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

$CONFIG->{ASYNC}    = new HTTP::Async;

$CONFIG->{UA}->post($CONFIG->{_config}->{BUILDSITE_NEW} . '/login', {
    login       => $CONFIG->{_config}->{LOGIN},
    password    => $CONFIG->{_config}->{PASSWORD}
});

$products->{$_} = get_products($_) foreach (@{ get_manufacturers() });

foreach my $manf (keys %{ $products }) {
    foreach (@{ $products->{$manf} }) {
        push @requests, { id => $_, manufacturer => $manf };
    }
}

while (my @request = splice @requests, 0, $CONFIG->{_config}->{FORK}) {
    my $result;
    
    add_requests(\@request);

    while ( my $response = $CONFIG->{ASYNC}->wait_for_next_response ) {
        my $url = $response->request->url;
        (my $id     = $url) =~ s/.*?(?:product_id|\?id)=(\w+).*/$1/i;
        (my $zip    = $url) =~ s/.*?(\d+)$/$1/i;        
        if($response->is_success()) {
            my $content = $response->content;
            if ($response->request->url =~ /$CONFIG->{_config}->{BUILDSITE_NEW}/i) {
                $result->{new}->{"$id:$zip"} = get_new_data($content);
            } elsif ($response->request->url =~ /$CONFIG->{_config}->{BUILDSITE_OLD}/i) {
                $result->{old}->{"$id:$zip"} = get_old_data($content);
            }
            if (exists($result->{new}->{"$id:$zip"}) && exists($result->{old}->{"$id:$zip"})) {
                next unless keys %{ $result->{old}->{"$id:$zip"} };
                compare(delete $result->{new}->{"$id:$zip"}, delete $result->{old}->{"$id:$zip"}, "$id:$zip");
            }        
        } else {
            diag("Status: " . $response->status_line);
            diag("ID:" . "$id:$zip");
        }
    }
}

sub add_requests {
    foreach (@{ +shift }) {
        my $zip     = @{ $CONFIG->{_config}->{ZIP_CODES} }[rand @{ $CONFIG->{_config}->{ZIP_CODES} }];                                                   
        my $new_url = $CONFIG->{_config}->{BUILDSITE_NEW} . "product/zip_search/?id=$_->{id}&zip=$zip";
        my $old_url = $CONFIG->{_config}->{BUILDSITE_OLD} . "query/list/distributor?manufacturer_id=$_->{manufacturer}&product_id=$_->{id}&zip=$zip";
        
        $CONFIG->{ASYNC}->add(
            $CONFIG->{COOKIE}->add_cookie_header(
                HTTP::Request->new(GET => $_, ['User-Agent' => "Mozilla/4.0 (compatible; MSIE 5.0; Windows 98; DigExt)"])
            )
        ) foreach ($new_url, $old_url);
    }
}

sub compare {
    eq_or_diff($_[0], $_[1], "check data for id:" . $_[2]);
}

sub get_new_data {
    local $_  = shift;
    my $result;
    while (m!<br />\W*<a href="([^"]*)">[^<]*</a>\W*<br />\W*?([0-9\.]+)!gis) {
        push @{ $result->{$1} }, $2;
    }
    
    return $result;
}

sub get_old_data {
    local $_  = shift;
    my $result;
    while (m!<a target="_blank" rel="external" href="([^"]*)">[^<]*</a><br>([0-9\.]+)!gis) {
        push @{ $result->{$1} }, $2;
    }
    
    return $result;
}

sub get_manufacturers {
    my $manf       = [ map { $_->id } (BST::schema()->resultset('BST::Schema::Company')->search({}, { select => [ 'company_id' ] }))->all ];
    return [ map { @{ $manf }[rand @{ $manf }] } 0..$CONFIG->{_config}->{COMPANY_COUNT} ];
}

sub get_products {
    my $products = BST::schema()->resultset('BST::Schema::Product')->search({ manufacturer_id => $_ }, { select => [ 'product_id' ] });
    return [ map { $_->id } $products->all ];
}