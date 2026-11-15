package lib::Category;

use strict;
use warnings;

use Exporter;
use base qw(Test::Class Exporter);
use Test::More qw(no_plan);

use FindBin qw($Bin);

use HTTP::Cookies;
use LWP::UserAgent;

use Test::Differences;
 
sub setup : Test(setup) {
    my $self    = shift;
   
    $self->{_config} = {
        COOKIES_FILE    => 'cookies.txt',
        COOKIES_EXPIRE  => 0.005,
        CATEGORIES_FILE => $ENV{CATLIST} || $Bin . '/categories.txt',
        #BUILDSITE_NEW   => 'http://crunch.ahinea.com:3000/',
        BUILDSITE_NEW   => 'http://localhost:3000/',
        BUILDSITE_OLD   => 'http://buildsite.com/',
        LOGIN           => 'ieg',
        PASSWORD        => ($ENV{BST_TEST_PASS} or die "set the BST_TEST_PASS env var"),
        #COMPARE         => [qw/products manufacturers categories/]
        COMPARE         => [qw/categories/]
    };
    
    $self->{COOKIE} = new HTTP::Cookies(
        file            => $self->{_config}->{COOKIES_FILE},
        ignore_discard  => 1,
        autosave        => 1
    );
    
    $self->{UA}     = new LWP::UserAgent(
        timeout     => 10,
        cookie_jar  => $self->{COOKIE}
    );
    
    $self->{UA}->post($self->{_config}->{BUILDSITE_NEW} . '/login', {
        login       => $self->{_config}->{LOGIN},
        password    => $self->{_config}->{PASSWORD}
    });
};

sub test_buildsite : Test {
    my $self    = shift;
    
    foreach (get_categories($self->{_config}->{CATEGORIES_FILE})) {
        diag("Check category: $_");
        
        $self->{_new_page}  = $self->get_buildsite_new_category_detail_page($_);
        $self->{_old_page}  = $self->get_buildsite_old_category_detail_page($_);
        
        $self->_compare({
            products        => $self->get_new_products(),
            manufacturers   => $self->get_new_manufacturers(),
            categories      => $self->get_new_categories()
        }, {
            products        => $self->get_old_products(),
            manufacturers   => $self->get_old_manufacturers(),
            categories      => $self->get_old_categories()
        });
    }
    
}

sub _compare {
    eq_or_diff($_[0]->{$_}, $_[1]->{$_}, "compare $_") foreach @{ shift->{_config}->{COMPARE} };
}

sub get_buildsite_new_category_detail_page {
    my $self    = shift;
    $_          = shift; /[^_]+/;
    
    return $self->{UA}->get($self->{_config}->{BUILDSITE_NEW} . '/categories/view?id=' . $&)->content;
}

sub get_buildsite_old_category_detail_page {
    my $self    = shift;
    
    return $self->{UA}->get($self->{_config}->{BUILDSITE_OLD} . 'query/detail/category/' . shift)->content;
}

sub get_new_products {
    return { map { $_ => 0 } shift->{_new_page} =~ m!product/view\?id=([^"]+)!gis };
}

sub get_old_products {    
    return { map { $_ => 0 } shift->{_old_page} =~ m!query/detail/product/([^"]+)!gis };
}

sub get_new_manufacturers {
    return { map { $_ => 0 } shift->{_new_page} =~ m!companies/view\?id=([^"]+)!gis };
}

sub get_old_manufacturers {    
    return { map { $_ => 0 } shift->{_old_page} =~ m!query/detail/manufacturer/([^"]+)!gis };
}

sub get_new_categories {
    return { map { $_ => 0; } shift->{_new_page} =~ m!<tr>[^<]*<td>[^<]*<a href="/categories/view\?id=[^"]*">\W*([\w\.]*)\W*</a>!gis };
}

sub get_old_categories {
    return { map { $_ => 0 } shift->{_old_page} =~ m!<td valign="baseline"><a href="[^"]*">\W*([^<]*)</a></td>!gis };
}

sub get_categories {
    my $file    = shift;
    
    die "Categories file does not exists" unless -e $file;
    
    open FILE, $file;
        my @cats = map { chomp; $_ } <FILE>;
    close FILE;
    
    return (scalar @cats) ? @cats : die "Categories file is empty";
}

1;
