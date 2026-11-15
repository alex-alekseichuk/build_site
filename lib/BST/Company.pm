package BST::Company;

use strict;
use warnings;

use Params::Validate qw/:all/;

use base qw/BST::Core BST::Schema::Company/;
use BST::CompanyFeature;
require BST::SearchKeywords;
use Data::Dumper;

__PACKAGE__->table("company");
# BST::Company::ResultSet is defined at the end of this file
__PACKAGE__->resultset_class('BST::Company::ResultSet');

=head1 DESCRIPTION
    Company (Manufacturer) class
=cut


__PACKAGE__->has_many(
    _documents => "BST::Document", {
        "foreign.publication_id" => "self.company_id",
    },
);
__PACKAGE__->has_many(
    "features" => "BST::CompanyFeature", {
        "foreign.company_id"     => "self.company_id",
    },
    { join_type => 'LEFT' },
);

__PACKAGE__->has_many(
  "products" => "BST::Product",
  { "foreign.manufacturer_id" => "self.company_id" },
);

__PACKAGE__->belongs_to(
  "division",
  "BST::Company",
  { company_id => "division_of_id" },
  { join_type => 'LEFT' },
);
__PACKAGE__->belongs_to(
  "branch",
  "BST::Company",
  { company_id => "branch_of_id" },
  { join_type => 'LEFT' },
);

=head
        sql_from => ["company",
                     "LEFT JOIN company_feature ON (company.company_id = company_feature.company_id AND feature_name = 'companyresource' AND feature_status = 'live')"],
        sql_where => [# "(feature_level IS NULL OR (feature_name = 'companyresource' AND feature_status = 'live'))",
                      "company_type = 'manufacturer'"],
        sql_order_by => ['feature_level', 'UPPER(COALESCE(company_nickname,legal_name))'],

=cut

sub companyresource_active {
    # a placeholder for companyresource company_feature test
    my $self = shift;
    return ( defined $self->get_column( "companyresource_status" )
             and $self->get_column( "companyresource_status" ) eq 'live' );
}

=head 2 search - class method

=cut

sub search_by_category {
    my ($class, $query, $params) = @_;

    return $class->search($query, {
        alias       => 'me',
        from        => [
            { me => 'company' },
            [
                { p => 'product' },
                { 'me.company_id' => 'p.manufacturer_id' }
            ],
        ],
        where       => BST::Company->hide_suppressed ? {
            'p.public_visible'          => 't',
            'p.suppress_reason_code'    => '',
            'me.public_visible'         => 't',
            'me.suppress_reason_code'   => '',
        } : undef,
        select      => [ qw/me.company_id company_nickname legal_name me.public_visible me.suppress_reason_code/ ],
        group_by    => [ qw/me.company_id company_nickname legal_name me.public_visible me.suppress_reason_code companyresource_feature.feature_status me.count_green me.count_product me.count_green_admin me.count_product_admin/ ],
#        group_by    => [ qw/me.company_id company_nickname legal_name me.public_visible me.suppress_reason_code/ ],
        order_by    => [ q{UPPER(REGEXP_REPLACE(COALESCE(company_nickname,legal_name),E'^(\\\\d)',E'ZZZ\\\\1'))} ],
        %{ $params || {} },
    });
}


sub name_search_terms {
    my $class = shift;

    my ($keywords, $composite_keywords) = BST::SearchKeywords::tokenize_manufacturer_search(shift);
    return (@$keywords, @$composite_keywords);
}

sub name_search_filter {
    my $class = shift;
    my ($what, $term, $table) = @_;

    my $field = $class->search_field([qw(legal_name company_nickname)], $table);

    my ($keywords, $composite_keywords) = BST::SearchKeywords::tokenize_manufacturer_search($what);
    return unless (@$keywords or @$composite_keywords);

    my $filter = $class->keywords_filter(
        $field, $keywords, $composite_keywords, $term
    );

    $table ||= "me";
    return {
        '-and' => [
            "${table}.company_type" => 'manufacturer',
            %$filter
        ]
    };
}


sub name_search {
    my $class = shift;

    my $query = $class->name_search_filter(@_);
    return unless defined $query;

    return BST::Company->search($query);
}

sub search {
    my ($class, $query, $params) = @_;

    return $class->next::method($query, {
        alias       => 'me',
#        from        => [
#            { me => 'company' },
#        ],
        where       => BST::Company->hide_suppressed ? {
            'me.public_visible'         => 't',
            'me.suppress_reason_code'   => '',
        } : undef,
        order_by    => [q{UPPER(REGEXP_REPLACE(COALESCE(company_nickname,legal_name),E'^(\\\\d)',E'ZZZ\\\\1'))} ],

        %{ $params || {} }
    });
}

=head2 feture

returns appropriate feature row

=cut

sub feature_level {
    my $self    = shift;

    return ($self->has_column_loaded("feature_level")) ? $self->get_column("feature_level") : undef;
}

sub feature {
    my $self = shift;
    my $name = shift || warn( "no feature name") && return undef;
    my @features = grep {$_->feature_name eq $name} $self->features->all;
    return @features ? $features[0] : undef;
}

sub feature_enabled {
    my $self    = shift;
    my $user    = shift;
    my $name    = shift;

    my $feature = $self->feature($name);

    return undef unless $feature;
    return $feature->feature_status eq 'live' || ($feature->feature_status eq 'qa' && ($user->is_bs_admin || $user->primary_location->account->get_column('company_id') eq $feature->company_id));
}

sub documents {
    my $self = shift;
    my $query = {
                    'me.document_type'  => 'company',
                };
    $query->{'suppress_reason_code'} = '' if
       (BST::Product->hide_suppressed);
    return $self->_documents(
        $query,
        {
            prefetch => ['doc_type'],
            join     => 'doc_type',
            order_by => ['me.document_role', 'dt_order', 'me.publisher_document_title', 'me.auto_ctime desc'],
        });
}

sub category_documents {
    my $self = shift;
    my $query = {
                    document_type  => 'category',
                };
    $query->{'suppress_reason_code'} = '' if
       (BST::Product->hide_suppressed);
    return $self->_documents(
        $query,
        {
            prefetch => 'doc_type',
            join     => 'doc_type',
            order_by => ['document_role', 'dt_order', 'publisher_document_title', 'auto_ctime desc'],
        });
}

sub name {
    my $self = shift;
    return $self->company_nickname || $self->legal_name;
}

sub country {
    my $self = shift;
    my $countries = {ca => "Canada", ru => "Russia", eg => "Egypt", gb => "United Kingdom"};
    return $countries->{$self->addr_country} || undef;
}

package BST::Company::ResultSet;

=head
        sql_from => ["company",
                     "LEFT JOIN company_feature ON (company.company_id = company_feature.company_id AND feature_name = 'companyresource' AND feature_status = 'live')"],
        sql_where => [# "(feature_level IS NULL OR (feature_name = 'companyresource' AND feature_status = 'live'))",
                      "company_type = 'manufacturer'"],
        sql_order_by => ['feature_level', 'UPPER(COALESCE(company_nickname,legal_name))'],

=cut

use strict;
use Data::Dumper;
use base qw(DBIx::Class::ResultSet);
use Carp qw(confess);


sub search_rs {
    my( $self, $source, $attrs ) = @_;

    warn "search_rs(): enter" if($ENV{DBIC_TRACE_COMPANY});
    if ($attrs->{_no_features}) {
        warn "search_rs(): bypassing companyfeatures for company" if($ENV{DBIC_TRACE_COMPANY});
        return $self->next::method( $source, $attrs )
    }

    if ( not scalar keys %$attrs ) {
        warn "search_rs(): empty attrs, quitting" if($ENV{DBIC_TRACE_COMPANY});
        return $self->next::method( $source, $attrs );
    }

#    warn "incomming class: $self\n" if($ENV{DBIC_TRACE_COMPANY});
#    warn "incomming source: $source\n" if($ENV{DBIC_TRACE_COMPANY});
    warn "incomming attrs: " . Dumper($attrs) if($ENV{DBIC_TRACE_COMPANY});

    my $user = BST->current_user;
    my $user_bs_admin = ($user) ? $user->is_bs_admin : undef;
    my $user_company = ($user) ? $user->account->get_column('company_id') : undef;

    my $alias      = $attrs->{alias} ||= 'me';
    my $from       = $attrs->{from} ||= [ {$alias => 'company'} ];
    my $order      = $attrs->{order_by} ||= [];
    # my $group      = $attrs->{group_by} ||= [];

    # $where already defined later in code
    my $orig_where = $attrs->{where} || {};

    # lets go through the ->{from} list and extract the names of
    # tables joined in there. add them to the $fromt hash
    my $fromt = {};
    foreach (@$from) {
        if ( ref $_ eq 'ARRAY' ) {
            my $j1 = $_->[0];
            my $k = (reverse sort keys %$j1)[0];
            $fromt->{$k}=1;
            warn "from table: $k\n" if($ENV{DBIC_TRACE_COMPANY});
        } elsif ( ref $_ eq 'HASH' ) {
        } else {
            warn "from item: " . Dumper($_) if($ENV{DBIC_TRACE_COMPANY});
        }
    }

    # get a set (hash) of all +as items
    my $addselect = $attrs->{'+select'} ||= [];
    my $addas     = $attrs->{'+as'}     ||= [];
    my $addas_set = {};
    foreach( @$addas ) {
        $addas_set->{$_} = 1;
    }

    my $companyresource_status_expression;
    if ( 1 ) {

        # join each of these features
        foreach( qw( companyresource ) ) {
            # join company_feature
            if ( not $fromt->{$_.'_feature'} ) {
                push @$from, [
                    {
                        $_ . '_feature' => 'company_feature',
                        -join_type    => 'LEFT',
                    },
                    {
                        $alias . '.company_id'  => $_ . '_feature.company_id',
                        $_ . '_feature.feature_name' => "'$_'",
                    },
                ];
            }

            # now let it appear in the SELECT clause and make it
            # accessible in the result via ->get_column()
            # in case of a simple user, we simply take the feature_status value
            my $status_expression = $_ . '_feature.feature_status';

            if ($user_bs_admin) {
                # in case of a bs_admin user, we look at 'qa' status
                # of any feature as the 'live' status
                $status_expression =
"CASE WHEN $status_expression = 'qa' THEN 'live'
WHEN $status_expression = 'live' THEN 'live'
ELSE '' END";

            } elsif ($user_company) {
                # if the user is not bs_admin, but belongs to an
                # account of the manufacturer, actually, then 'qa'
                # status may be accounted as 'live'
                $status_expression =
"CASE WHEN $status_expression = 'qa' and me.company_id='$user_company' THEN 'live'
WHEN $status_expression = 'live' THEN 'live'
ELSE '' END";
            }

            # add the expression to the SELECT
            if ( not $addas_set->{ $_ . '_status' } ) {
                push @$addselect, $status_expression;
                push @$addas,     $_ . '_status';
                # if( ref $group ) {
                #    push @$group, $status_expression;
                #}
            }

            # we do tweak the order by below
            # and that is why we need
            # $companyresource_status_expression.
            # there is only one feature at the moment, so this if will always work:
            if ($_ eq 'companyresource') {
                $companyresource_status_expression = $status_expression;
            }
        }

    } else {
        warn "companyresource_feature already joined. "
            #. Dumper($attrs)
            if($ENV{DBIC_TRACE_COMPANY});
    }


    # ticket #736
    # check if hasproducts is already in the query
    if ( not $addas_set->{hasproducts} ) {
        push @$addselect, $user_bs_admin ? 'count_product_admin' : 'count_product';
        push @$addas, 'hasproducts';
    }

    if ( not $addas_set->{hasgreenproducts} ) {
        push @$addselect, $user_bs_admin ? 'count_green_admin' : 'count_green';
        push @$addas, 'hasgreenproducts';
    }

    my $first_o;
    if( $order and ref $order eq 'ARRAY' ) { $first_o = $order->[0]; }
    elsif( $order ) {
        $order = [$order];
        $first_o = $order->[0];
    }
    if( $first_o
        and ref $first_o eq 'SCALAR'
        and $$first_o =~ m/'live'/ ) {
        # there is already
    } elsif ($companyresource_status_expression) {
        my $pms = $companyresource_status_expression;
        unshift @$order,
        \ qq~( ($pms) IS NOT NULL
                    AND ($pms) = 'live' ) DESC~;
        # the $companyresource_status_expression might be
        # tricky... see above.
    } else {
        warn "can't add sorting" if($ENV{DBIC_TRACE_COMPANY});;
    }

    warn "search_rs(): final attrs: " . Dumper($attrs) if($ENV{DBIC_TRACE_COMPANY});

    my $res = $self->next::method( $source, $attrs );

    warn "search_rs(): exit" if($ENV{DBIC_TRACE_COMPANY});
    return $res;
}


sub __search_rs {
    my ($self, $cond, $attr) = @_;
    warn "Company resultset->search_rs( $cond, $attr ); enter";
    my $rs = $self->next::method( $cond, $attr );
    warn "Company resultset->search_rs( $cond, $attr ); exit";
    return $rs;
}

sub count {
    my $self = shift;
    $self ->{attrs}->{_no_features} = 1;
    my $res = $self->next::method( @_ );
    return $res;
}

1;