#!/usr/bin/perl -w

use strict;

use FindBin qw($Bin);

use Getopt::Long;
use LWP::UserAgent;
use HTTP::Message 1.57;
use HTTP::Request;
use HTTP::Async;
use HTTP::Cookies;

use Test::More qw(no_plan);
use Test::Differences;

my ($CONFIG, $new_host, $old_host, $fork, $login, $pass);

GetOptions(
    "new-host=s"            => \$new_host,
    "old-host=s"            => \$old_host,
    "fork=i"                => \$fork,
    "login=s"               => \$login,
    "pass=s"                => \$pass
);

$CONFIG->{_config} = {
    COOKIES_FILE    => $Bin . '/cookies.txt',
    CATEGORIES_FILE => $Bin . '/categories.txt',
    BUILDSITE_NEW   => $new_host || 'http://localhost:3000/',
    BUILDSITE_OLD   => $old_host || 'http://buildsite.com/',
    LOGIN           => $login || 'ieg',
    PASSWORD        => $pass || $ENV{BST_TEST_PASS} or die "set the BST_TEST_PASS env var",
    COMPARE         => [qw/products manufacturers categories/],
    FORK            => $fork || 1,
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

$CONFIG->{ASYNC}    = new HTTP::Async;

$CONFIG->{UA}->post($CONFIG->{_config}->{BUILDSITE_NEW} . '/login', {
    login       => $CONFIG->{_config}->{LOGIN},
    password    => $CONFIG->{_config}->{PASSWORD}
});

$CONFIG->{CATEGORIES}   = get_categories($CONFIG->{_config}->{CATEGORIES_FILE});

while (my @categories = splice @{ $CONFIG->{CATEGORIES} }, 0, $CONFIG->{_config}->{FORK}) {
    my $result;

    add_requests(\@categories);

    while ( my $response = $CONFIG->{ASYNC}->wait_for_next_response ) {
        (my $id     = $response->request->url) =~ s!.*(?:=|/)([a-zA-Z0-9]+).*$!$1!i;
        if($response->is_success()) {
            my $content = $response->content;
            if ($response->request->url =~ /$CONFIG->{_config}->{BUILDSITE_NEW}/i) {
                $result->{new}->{$id} = {
                    products        => get_new_products($content),
                    manufacturers   => get_new_manufacturers($content),
                    categories      => get_new_categories($content)
                };
            } elsif ($response->request->url =~ /$CONFIG->{_config}->{BUILDSITE_OLD}/i) {
                $result->{old}->{$id} = {
                    products        => get_old_products($content),
                    manufacturers   => get_old_manufacturers($content),
                    categories      => get_old_categories($content)
                };
            }
            if (exists($result->{new}->{$id}) && exists($result->{old}->{$id})) {
                compare(delete $result->{new}->{$id}, delete $result->{old}->{$id}, $id);
            }        
        } else {
            diag("Category id:$id status: " . $response->status_line);
        }
    }
}

sub add_requests {
    foreach (@{ +shift }) {
        /[^_]+/;
        my $new_url = $CONFIG->{_config}->{BUILDSITE_NEW} . '/categories/view?id=' . $&;
        my $old_url = $CONFIG->{_config}->{BUILDSITE_OLD} . 'query/detail/category/' . $_;
        
        $CONFIG->{ASYNC}->add(
            $CONFIG->{COOKIE}->add_cookie_header(
                HTTP::Request->new(GET => $_, ['User-Agent' => "Mozilla/4.0 (compatible; MSIE 5.0; Windows 98; DigExt)"])
            )
        ) foreach ($new_url, $old_url);
    }
}

sub compare {
    ok((keys %{ $_[0]->{products} } && keys %{ $_[0]->{manufacturers} } && keys %{ $_[0]->{categories} }), "check data for category id:" . $_[2]);
    eq_or_diff($_[0]->{$_}, $_[1]->{$_}, "compare " . (keys %{ $_[0]->{$_} }) . " $_") foreach @{ $CONFIG->{_config}->{COMPARE} };
}

sub get_old_products {
    return { map { $_ => 0 } shift =~ m!query/detail/product/([^"]+)!gis };
}

sub get_old_manufacturers {
    return { map { $_ => 0 } shift =~ m!query/detail/manufacturer/([^"]+)!gis };
}

sub get_old_categories {
    local $_  = shift;
    
    my $result;
    while (m!<td valign="baseline">(?:<a[^>]*>)?(\W*)([\w\.]*)[^<]*(?:</a>)?</td>!gis) {
        $result->{$2} = @{ [ $1 =~ /\W{2}/gi ] };
    }
    
    return $result;
}

sub get_new_products {
    return { map { $_ => 0 } shift =~ m!product/view\?id=([^"]+)!gis } || undef;
}

sub get_new_manufacturers {
    return { map { $_ => 0 } shift =~ m!companies/view\?id=([^"]+)!gis };
}

sub get_new_categories {
    local $_  = shift;
    m!<table\sclass="basic">[^<]*<tr>[^<]*<th>Category</th>[^<]*<th>Category\sName</th>[^<]*<th>Products</th>[^<]*</tr>(.*)</tr>[^<]*</table>!is;
    
    my $result;
    while (m!<tr>[^<]*<td>\s*((?:&nbsp;)*)\s*(?:<a[^>]*>)*\W*<?([\w\.]*)[^<]*(?:</a>)?[^<]*</td>[^<]*<td>!gis) {
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