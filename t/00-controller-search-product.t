#!/usr/bin/perl -w

package BSA;

sub path_to {}

1;

package main;

use Data::Dumper;

use strict;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use DBI;
use Test::More qw/no_plan/;
use Test::Differences;

use BST qw/config/;
use BSA::Controller::Search;

my $dbh = DBI->connect('DBI:Pg:dbname=' . config('dbname'), config('dbuser'), config('dbpass')) or die;

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
        sub field {
            my $self = shift;
            if ($_[0]) {
                return $self->{field}->{$_[0]} || '';
            }
            return $self->{field};
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
#{ no warnings; *BST::Core::hide_suppressed = sub { return 0; }; }
$c->param->{mfg_my_all} = 'all';

foreach (
 (map { join '', map { ('a'..'z')[rand(26)] } (1) } (1..5) ),
 (map { join '', map { ('a'..'z')[rand(26)] } (1..2) } (1..10) ),
 @{ [qw/alumni roof hook plastic/] }, 
# @{ [q/f/] }, 
) {

    { no warnings; *FakeFormbuilder::field = sub {
        shift;
        return $_ if $_[0] eq 'q';
        return 'pname' if $_[0] eq 'where';
        return 'and' if $_[0] eq 'term';
    }; }
    
    diag("Test search controller for product name '$_'");
    
    my @array   = @{ get_sql_search_products(1, $_) };
    
    if(0) { # no perl sorting anymore, using order_by instead
    @array  = sort {
        my $pm_a       = $a->{'productmatch_status'} || '';
        my $mfg_text_a = $a->{'mfg_short_text'} || '';
        my $adv_a      = (($pm_a eq 'live') and ($mfg_text_a ne ''));

        my $pm_b       = $b->{'productmatch_status'} || '';
        my $mfg_text_b = $b->{'mfg_short_text'} || '';
        my $adv_b      = (($pm_b eq 'live') and ($mfg_text_b ne ''));
        
        my $name_a     = $a->{"product_name"};
        my $name_b     = $b->{"product_name"};
        return $adv_b <=> $adv_a 
            || $name_a cmp $name_b
#            || $a->{"product_id"} cmp $b->{"product_id"}
        ;
    } @array;
    }

    $true = [ map {$_->{product_id}} @array ];
    $controller->index($c);
    $have = [ map {$_->product_id} @{ $c->stash->{list}->{all} } ];
    
    compare($have, $true, $_);
}

sub get_sql_search_products {
    my $stuff_user  = shift;
    my $key     = shift;
    
    my $request = ($key =~ /^\d+$/)
        ? "~* E'$key'"
        : length($key) < 3
          ? "~* E'\\\\m$key\\\\M'"
          : "~* E'\\\\m$key'";
    my $subreq = $request;
    if (length($key)<3) {
        $subreq = "~* E'\\\\m$key'";
    }
        
    return $dbh->selectall_arrayref(sprintf(
        qq/SELECT me.product_id, me.product_name, productmatch_feature.feature_status as productmatch_status, me.mfg_short_text, / .
        qq/ ABS(CAST(me.product_name $subreq AS INT)) AS inclusion / .
        q/ FROM product me/ .
        q/    LEFT JOIN product_standard product_standard/ .
        q/        ON ( me.product_id = product_standard.product_id AND product_standard.standard_org_id = 'astm' )/ .
        q/    LEFT JOIN company_feature productmatch_feature/ .
        q/        ON ( me.manufacturer_id = productmatch_feature.company_id AND productmatch_feature.feature_name = 'productmatch' )/ .
        q/    LEFT JOIN company_feature systemseller_feature/ .
        q/        ON ( me.manufacturer_id = systemseller_feature.company_id AND systemseller_feature.feature_name = 'systemseller' )/ .
        q/    LEFT JOIN company_feature relatedseller_feature/ .
        q/        ON ( me.manufacturer_id = relatedseller_feature.company_id AND relatedseller_feature.feature_name = 'relatedseller' )/ .
        q/    LEFT JOIN company manufacturer/ .
        q/        ON manufacturer.company_id = me.manufacturer_id/ .
        q/    LEFT JOIN category category/ .
        q/        ON category.category_id = me.category_id/ .
        q/    LEFT JOIN category parent/ .
        q/        ON parent.category_id = category.parent_id/ .
        q/    LEFT JOIN category parent_2/ .
        q/        ON parent_2.category_id = parent.parent_id/ .
        q/    LEFT JOIN category parent_3/ .
        q/        ON parent_3.category_id = parent_2.parent_id/ .
        q/ WHERE / .
        qq/    replace(me.product_id, '_', '') || ' ' || coalesce(me.product_name, '') || ' ' || coalesce(me.mfg_product_id, '') || ' ' || coalesce(product_standard.standard_document_identifier, '') $request/ .
        q/    AND/ .
        q/    (/ .
        q/        (/ .
        qq/            replace(me.product_id, '_', '') || ' ' || coalesce(me.product_name, '') || ' ' || coalesce(me.mfg_product_id, '') || ' ' || coalesce(product_standard.standard_document_identifier, '') || ' ' || coalesce(manufacturer.legal_name, '') || ' ' || coalesce(category.category_title, '') || ' ' || coalesce(parent.category_title, '') || ' ' || coalesce(parent_2.category_title, '') $request/ .
        q/            AND category.category_id ~* '^.{7}$'/ .
        q/        )/ .
        q/        OR/ .
        q/        (/ .
        qq/            replace(me.product_id, '_', '') || ' ' || coalesce(me.product_name, '') || ' ' || coalesce(me.mfg_product_id, '') || ' ' || coalesce(product_standard.standard_document_identifier, '') || ' ' || coalesce(manufacturer.legal_name, '') || ' ' || coalesce(category.category_title, '') || ' ' || coalesce(parent.category_title, '') $request/ .
        q/            AND category.category_id !~* '^.{7}$'/ .
        q/        )/ .
        q/    )/ .
        q/    AND me.public_visible = true AND me.suppress_reason_code = '' / .
                                        
        q/ ORDER BY / .
        q/   (productmatch_feature.feature_status IS NOT NULL 
         AND productmatch_feature.feature_status = 'live' 
         AND me.mfg_short_text IS NOT NULL AND me.mfg_short_text <> '') DESC, 
         inclusion DESC / 
        . q/ ,me.product_name / 
#        . q/ ,me.product_id /
        ,
        $request), { Slice => {} }
    );
}

sub compare {
    my $true    = shift;
    my $have    = shift;
    
    eq_or_diff(scalar @$true, scalar @$have);
    eq_or_diff($true, $have);
}
