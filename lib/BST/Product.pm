package BST::Product;

use strict;
use warnings;

use BST::Company;
use BST::Category;
use BST::Document;
use BST::ProductStandard;
use BST::SearchKeywords;
use BST::LeedCredit;

use Data::Dumper;
use Params::Validate qw(:all);

use base qw/BST::Core BST::Schema::Product/;

__PACKAGE__->table("product");
__PACKAGE__->resultset_class('BST::Product::ResultSet');

=head1 DESCRIPTION
    Product object
=cut

__PACKAGE__->belongs_to(
    "manufacturer" => "BST::Company",
    { company_id => "manufacturer_id" },
    { join_type => 'LEFT' },
);
__PACKAGE__->belongs_to(
    "category" => "BST::Category",
    { category_id => "category_id" },
    { join_type => 'LEFT' },
);
__PACKAGE__->has_many(
    "product_standards" => "BST::ProductStandard",
    { "foreign.product_id" => "self.product_id" },
    { join_type => 'LEFT' },
);

__PACKAGE__->has_many(
  "related_products",
  "BST::ProductRelated",
  { "foreign.product_id" => "self.product_id" },
);

__PACKAGE__->has_many(
  "product_leed_credits",
  "BST::ProductLeedCredit",
  { "foreign.product_id" => "self.product_id" },
);

__PACKAGE__->many_to_many(
  "leed_credits" => "product_leed_credits",
  "leed_credit_id",
);

# __PACKAGE__->might_have(
#     "productmatch_feature",
#     "BST::CompanyFeature",
#     { "foreign.company_id" => "self.manufacturer_id" },
#     {
#         join_type=> 'LEFT',
#         where => {'feature_name' => 'productmatch'}
#     }
# );


# "productmatch" is the advertising feature for products. It is used
# (i.e. displayed) if the product manufacturer has the productmatch
# company feature enabled, and the product has an ad text from the
# manufacturer (mfg_short_text).

sub productmatch_active {
    my $self = shift;
    my ($pm,$text);
    if ( $self->has_column_loaded( "productmatch_status" ) ) {
        $pm = $self->get_column( "productmatch_status" ) || '';
    } else {
        my $f = $self ->productmatch_feature;
        ### XXX need to respect the 'qa' status here:
        if ($f) { $pm = $f->feature_status; }
        else { $pm = ''; }
    }

    $text = $self->get_column( "mfg_short_text" )      || '';
    return ( $pm eq 'live'
             and $text ne '' );
}

sub feature_enabled {
    my $self = shift;
    my $feature = shift || die;
    my $status;
    if ($self->has_column_loaded( $feature . "_status" ) ) {
        $status = $self->get_column( $feature . "_status" ) || '';
    } else {
        my ($feature) = BST::CompanyFeature->search({ feature_name => $feature, company_id => $self->get_column('manufacturer_id') });
        my $user = BST->current_user;
        return unless $feature;
        $status = $feature->feature_status;
        if ($user) {
            my $qa = $user->is_bs_admin;
            $qa ||= $user->account->get_column('company_id') && $user->account->get_column('company_id') eq $feature->company_id;
            return 1 if $qa && $status eq "qa";
        }
    }
    return ($status eq 'live');
}

sub has_afterqa_docs {
    my $self = shift;
    my $has_afterqa_docs;
    if ( $self->has_column_loaded("has_afterqa_docs") ) {
        $has_afterqa_docs = $self->get_column("has_afterqa_docs") || '';
    } else {
        return 0;
    }
    return ($has_afterqa_docs);
}


sub astm_search_filter {
    my $class = shift;
    my ($what) = @_;

    my ($keywords, $composite_keywords) = BST::SearchKeywords::tokenize_astm_search($what);
    return undef unless (@$keywords or @$composite_keywords);

    push @$keywords, @$composite_keywords;
    return {
        'LOWER(standard.standard_document_identifier)' => $keywords,
    };
}

sub astm_search {
    my $class = shift;
    my $what = shift;
    return BST::Product->search($class->astm_search_filter($what));
}

sub standards {
    my $self = shift;
    return BST::ProductStandard->search(
        {
            product_id => $self->product_id,
        }
    )->all;
}

sub name_search_kw {
    my $self = shift;
    #my $keywords = shift;
    #my $composite_keywords = shift;
    my $what = shift;
    my $term = shift;
    my $manufacturers = shift;

    my ($keywords, $composite_keywords) = BST::SearchKeywords::tokenize_product_search($what, $term);
    return undef unless (@$keywords or @$composite_keywords);

    my $query = {};

    if ($manufacturers) {
        $query->{'me.manufacturer_id'} = $manufacturers;
    }

    my $log_keywords = [];
    push @$log_keywords, @$keywords;
    push @$log_keywords, @$composite_keywords;
    $self->logger->log({ name => 'search', level => 'debug', message => join(',', @$log_keywords) });

    if ($term && $term eq 'or') {
        my $sql_and = sprintf qq~(
            SELECT product_id, SUM(score) AS scoresum
            FROM product_keyword
            WHERE keyword IN (%s)
            GROUP BY product_id
            HAVING MAX(score) >= 10
        )~
        , join(', ', map { "'$_'" } @$keywords, @$composite_keywords)
        , scalar @$keywords;

        return BST::Product->search($query, {
            from => [
                [
                    {
                        product_and => \$sql_and,
                    },
                    {
                        'me.product_id'     => 'product_and.product_id',
                    },
                ],
            ],
            order_by => [
                'scoresum desc',
                'me.product_name',
            ],
            groupby => ['scoresum'],
        });

=c
        # join 2 keywords arrays
        my $all_keywords = [];
        push @$all_keywords, @$keywords;
        splice @$all_keywords, scalar(@$all_keywords), 0, @$composite_keywords;

        $query = {
            'k.keyword' => $all_keywords,
        };

        return BST::Product->search($query, {
            from => [
                [
                    {
                        k    => 'product_keyword'
                    },
                    {
                        'me.product_id' => 'k.product_id',
                    },
                ],
            ],
            order_by => [
                'sum(k.score) desc',
                'me.product_name',
            ],
        });
=cut
    } else { # and!
        my $sql_and = sprintf qq~
            SELECT product_id, SUM(score) AS scoresum
            FROM product_keyword
            WHERE keyword IN (%s)
            GROUP BY product_id
            HAVING (COUNT(*) >= %d AND MAX(score) >= 10)
        ~
        , join(', ', map { "'$_'" } @$keywords, @$composite_keywords)
        , scalar @$keywords
        ;
        
        $sql_and .= sprintf "OR BOOL_OR(keyword IN (%s))", join(', ', map { "'$_'" } @$composite_keywords)
            if scalar @$composite_keywords;
            
        $sql_and = "($sql_and)";
        
        
        
=c
        # compose custom select to get product_id for complecated AND product name search
        my $sql_and = sprintf("(select distinct
                                k_and1.product_id, %s as scoresum
                                from
                                    product_keyword k_and1
                                    %s
                                where k_and1.keyword='%s'
                                %s)"
                            ,join('+', map "k_and".$_.".score", 1..scalar(@$keywords))
                            ,join('', map "
                                join product_keyword k_and$_ on k_and$_.keyword='".$keywords->[$_-1]."' and k_and$_.product_id=k_and1.product_id"
                                , 2..scalar(@$keywords))
                            ,$keywords->[0]
                            ,(@$composite_keywords ?
                                    sprintf("union
                                        select product_id, COALESCE(sum(score), 0) as scoresum
                                        from product_keyword
                                        where keyword in (%s) group by product_id"
                                    ,join(',', map "'".$_."'", @$composite_keywords))
                                : "")
                            );
=cut
        return BST::Product->search($query, {
            from => [
                [
                    {
                        product_and => \$sql_and,
                    },
                    {
                        'me.product_id'     => 'product_and.product_id',
                    },
                ],
            ],
            order_by => [
                'scoresum desc',
                'me.product_name',
            ],
            groupby => ['scoresum'],
        });


    }

}


sub name_search_terms {
    my $class = shift;
    my ($what, $term) = @_;

    my ($keywords, $composite_keywords) = BST::SearchKeywords::tokenize_product_search($what, $term);
    return (@$keywords, @$composite_keywords);
}

sub name_search_filter {
    my $class = shift;
    my ($what, $term, $table) = @_;

    my ($keywords, $composite_keywords) = BST::SearchKeywords::tokenize_product_search($what, $term);
    return undef unless (@$keywords or @$composite_keywords);

    # join 2 keywords arrays and convert it to select-regex-keywords
    # it's used in +select special value below
    my $select_re_keywords = [];
    push @$select_re_keywords, @$keywords;
    if ($composite_keywords) {
        push @$select_re_keywords, @$composite_keywords;
    }
    return undef unless (@$select_re_keywords);
    for (@$select_re_keywords) {
        $_ = &BST::Core::_escape_to_regexps($_);
        $_ =~ s/\\/\\\\/g;
    }

    # prepare regexp's for the keywords
    my $re_keywords = [];
    my $re_composite_keywords = [];
    @$re_keywords = @$keywords;
    @$re_composite_keywords = @$composite_keywords;
    &BST::Core::_keywords_to_regexps_without_split(@$re_keywords);
    &BST::Core::_keywords_to_regexps_without_split(@$re_composite_keywords);

    my $search_field = $class->search_field([
        \ "replace(me.product_id, '_', '')"
        , qw(product_name mfg_product_id standard.standard_document_identifier)
    ], $table);

    my $query = {};

    if ($term && $term eq 'or') {

        # join 2 keywords arrays
        #splice @$re_keywords, scalar(@$re_keywords), 0, @$re_composite_keywords;
        push @$re_keywords, @$re_composite_keywords;

        $query = {
            $search_field => [ -or => @$re_keywords ],
        };

    } else { # and!

        my $search_field_cat = $class->search_field([
            \ "replace(me.product_id, '_', '')"
            , qw(product_name mfg_product_id standard.standard_document_identifier manufacturer.legal_name category.category_title parent.category_title parent_2.category_title)
        ], $table);

        my $search_field_no_cat = $class->search_field([
            \ "replace(me.product_id, '_', '')"
            , qw(product_name mfg_product_id standard.standard_document_identifier manufacturer.legal_name category.category_title parent.category_title)
        ], $table);

        # join 2 keywords arrays
        my $re_both_keywords = [];
        push @$re_both_keywords, @$re_keywords;
        if ($re_composite_keywords) {
            push @$re_both_keywords, @$re_composite_keywords;
        }

        # add tokens to the query
        if (scalar(@$keywords)) {
            $_ = &BST::Core::_escape_to_regexps($_) for @$keywords;
        }
        if (1 == scalar(@$keywords)) {
            $keywords = {"~*" => "\\m" . $keywords->[0]};
        } else {
            $keywords = ['-and' => @$re_keywords];
        }

        my $search_cat = {
            $search_field_cat => $keywords
        };
        my $search_no_cat = {
            $search_field_no_cat => $keywords
        };

        # add composite tokens to the query
        if (scalar(@$composite_keywords))
        {
            $_ = &BST::Core::_escape_to_regexps($_) for @$composite_keywords;
            if (1 == scalar(@$composite_keywords)) {
                $composite_keywords = {"~*" => "\\m" . $composite_keywords->[0]};
            } else {
                $composite_keywords = ['-or' => @$re_composite_keywords];
            }

            $search_cat = {
                '-or' => [
                    $search_cat
                    , {
                        $search_field_cat => $composite_keywords
                    }
                ]
            };
            $search_no_cat = {
                '-or' => [
                    $search_no_cat
                    , {
                        $search_field_no_cat => $composite_keywords
                    }
                ]
            };
        }

        $query = {
            $search_field => [ -or => @$re_both_keywords ],
            -or => [
                -and => [
                    { 'category.category_id' => { '~*', '^.{7}$' } }
                    , $search_cat
                ],
                -and => [
                     { 'category.category_id' => { '!~*', '^.{7}$' } },
                    , $search_no_cat
                ]
             ],
        };

    }

    return $query;



}

sub name_search_order {
    my $class = shift;
    my ($what, $term, $table) = @_;

    my ($keywords, $composite_keywords) = BST::SearchKeywords::tokenize_product_search($what, $term);
    return undef unless (@$keywords or @$composite_keywords);

    # join 2 keywords arrays and convert it to select-regex-keywords
    # it's used in +select special value below
    my $select_re_keywords = [];
    push @$select_re_keywords, @$keywords;
    if ($composite_keywords) {
        push @$select_re_keywords, @$composite_keywords;
    }
    return undef unless (@$select_re_keywords);
    for (@$select_re_keywords) {
        $_ = &BST::Core::_escape_to_regexps($_);
        $_ =~ s/\\/\\\\/g;
    }

    return [
            'abs(' . (join ' + ', map { qq/cast (me.product_name ~* E'\\m$_' as int)/ } @$select_re_keywords) . ') desc',
            'me.product_name',
        ];
}

sub name_search {
    my $self = shift;
    return $self->name_search_kw(@_);
    
    my $what = shift;
    my $term = shift;
    my $manufacturers = shift;

    my $query = $self->name_search_filter($what, $term);
    my $order_by = $self->name_search_order($what, $term);

    if ($manufacturers) {
        $query->{'me.manufacturer_id'} = $manufacturers;
    }

    return BST::Product->search($query, {
        order_by => $order_by
    });

}


sub search_by_category {
    my ($class, $query, $params) = @_;

    # this search call uses $query from the call
    # and supplies a simplified $attrs hash,
    # because on category detail pages we do not
    # need:
    #  - astm
    #  - full category titles
    # the from and prefetch given below would override
    # the ones ->search() method uses by default.
    # i assume the only thing $query might contain here
    # is a category_id condition
    return $class->search($query, {
        prefetch => {
            manufacturer => {},
        },
    });
}


sub search_by_leed_credit {
    my ($class, $query, $params) = @_;

    return $class->search($query, {
        from     => [
            [
                { product_leed_credit => 'product_leed_credit', -join_type => 'LEFT' },
                { 'product_leed_credit.product_id' => 'me.product_id'}
            ],
        ],
        %{ $params || {} }
    });
}


=head 2 search - the main search method

=cut

sub search {
    my ($class, $query, $params) = @_;

    $query->{'me.suppress_reason_code'} = ''
        if (BST::Product->hide_suppressed);

    my $columns = [map { "me.$_" } __PACKAGE__->columns ];
    if ($params->{'groupby'}) {
        unshift @$columns, @{$params->{'groupby'}};
        delete $params->{'groupby'};
    }

    # compose form
    my $from = [
        { me => 'product' },
        [
            {
                product_standard    => 'product_standard',
                -join_type          => 'LEFT',
            },
            {
                'me.product_id' => 'product_standard.product_id',
            },
        ],
        [
            {
                standard    => 'standard',
                -join_type  => 'LEFT',
            },
            {
                'product_standard.standard_id' => 'standard.standard_id',
                'standard.standard_org_id'     => "'astm'",
            },
        ],
    ];
    if ($params->{'from'}) {
        unshift @{$params->{'from'}}, @$from;
    }

    my $attrs = {
        alias    => 'me',
        from => $from,
        prefetch => {
            category        => {
                'parent'    => {
                    'parent' => 'parent'
                }
            },
            manufacturer => {},
        },
        select => $columns,
        distinct => 1,
        order_by => [
            'me.product_name',
        ],
        %{ $params || {} }
    };

    return $class->next::method($query, $attrs);
}


=head2 autocomplete_search is used to produce the list of items for product autocomplete in TOC editor

=cut

sub autocomplete_search {
    my $self = shift;
    my $what = shift;
    my $rows = shift;
    my $term = shift;

    return undef unless $what;

    my $query = $self->name_search_filter($what, $term);
    my $order_by = $self->name_search_order($what, $term);

    $query->{'me.suppress_reason_code'} = ''
        if (BST::Product->hide_suppressed);

    # compose form
    my $from = [
        { me => 'product' },
        [
            {
                product_standard    => 'product_standard',
                -join_type          => 'LEFT',
            },
            {
                'me.product_id' => 'product_standard.product_id',
            },
        ],
        [
            {
                standard    => 'standard',
                -join_type  => 'LEFT',
            },
            {
                'product_standard.standard_id' => 'standard.standard_id',
                'standard.standard_org_id'     => "'astm'",
            },
        ],
    ];

    my $attrs = {
        alias    => 'me',
        from => $from,
        prefetch => {
            category        => {
                'parent'    => {
                    'parent' => 'parent'
                }
            },
            manufacturer => {},
        },
        select => [
            'me.product_id',
            'me.product_name',
            'me.category_id',
            'me.mfg_short_text',
            'me.manufacturer_id',
        ],
        distinct => 1,
        order_by => $order_by,
        rows => $rows,
    };

    return BST::Core::search('BST::Product', $query, $attrs);
}

sub leed_attributes {
    my $self = shift;
    return $self->product_attribute_values({attribute_type => ['leed_product', 'leed_entry']}, { prefetch => 'attribute_id', order_by => 'result_display_order' },);
}

=pod
sub leed_credits {
    my $self = shift;
    my $query;
    $query->{leed_credit_id} = [map {$_->get_column('leed_credit_id')} $self->product_leed_credits];
    my $credits = BST::LeedCredit->search($query, {});
    return $credits;
}
=cut

sub documents {
    my $query = {document_type => 'product'};
    $query->{'me.suppress_reason_code'} = ''
        if (BST::Product->hide_suppressed);
    return shift->next::method(
        $query,
        {
            prefetch => 'doc_type',
            order_by => ['document_role', 'dt_order', \'publisher_document_title is not NULL', 'publisher_document_title', 'auto_ctime desc'], #'
        });
}

sub category_documents {
    my $self = shift;
    return BST::Document->search_product_category({
        'me.publication_id' => $self->get_column("manufacturer_id")
        , descendant_id  => $self->get_column("category_id")
    });

}

sub nrca_category_documents {
    my $self = shift;
    my $ancestors = $self->category->ancestors;
    $ancestors = [map { $_->id } @$ancestors];
    my $query = {
                    document_type  => 'category',
                    publication_id => 'nrca',
                    'me.category_id'  => $ancestors,
                };
    $query->{'me.suppress_reason_code'} = ''
        if (BST::Product->hide_suppressed);
    return BST::Document->search(
        $query,
        {
            prefetch => ['doc_type',
                         { category_id => 'category_descendant_category_ids' } ],
            order_by => ['document_role', 'dt_order', 'publisher_document_title', 'me.auto_ctime desc'],
        }
    );
}

sub is_discontinued {
    my $self = shift;
    my ($flag) = grep m/disc_prod/, split ";", $self->check_flags
        if $self->check_flags;
    return $flag;
}

sub has_suppress_flag {
    my $self = shift;
    return $self->check_flags ? grep m/suppress/, split ';', $self->check_flags : undef;
}

sub is_suppressed {
    my $self = shift;
    return $self->suppress_reason_code;
}

sub can_read {
    my $self = shift;
    return !$self->is_suppressed;
}


sub generate_related_products_file {
    my $self = shift;
    my $user = shift;
    my $related_products = shift;
    my $fobj = BST::create('BST::File');
    $fobj->file_original_path('');
    $fobj->file_title(BST::File->get_related_products_filename($self));
    $fobj->creator_user($user->user_id);
    $fobj->owner($user->location);

    $fobj->file_extension('html');
    $fobj->file_class('file');
    $fobj->scope(BST::Scope::HIDDEN);
    $fobj->file_comment($self->product_id);

    # generate xhtml
    use Template;
    my $template = Template->new(
        INCLUDE_PATH    => BST::config('home') . "/templates/pages/product",
    );
    unlink $fobj->local_file_path if -e $fobj->local_file_path;

    $template->process(
        "related_products_file.tt",
        {
            products => $related_products,
        },
        $fobj->local_file_path) || die $template->error;

    $fobj->file_size((stat ($fobj->local_file_path))[7]);
    $fobj->save();
    return $fobj;
}


our %ADFLAGS = (
    'A' => {
        name    => 'caltrans',
        img     => 'caltrans.gif',
        title   => 'Caltrans Approved'
    },
    'C' => {
        name    => 'cri',
        img     => 'CRI.gif',
        title   => 'Carpet and Rug Institute Green Label'
    },
    'D' => {
        name    => 'dot',
        img     => 'dot.gif',
        title   => 'DOT Approvals'
    },
    'E' => {
        name    => 'energystar',
        img     => 'energystar.gif',
        title   => 'ENERGY STAR Rated'
    },
    'F' => {
        name    => 'fm',
        img     => 'FMapproved.gif',
        title   => 'FM Approved'
    },
    'G' => {
        name    => 'green',
        img     => 'greenseal.gif',
        title   => 'Green Seal Certified'
    },
    'I' => {
        name    => 'icbo',
        img     => 'ICBO.gif',
        title   => 'ICBO'
    },
    'L' => {
        name    => 'nsf',
        img     => 'nsf.gif',
        title   => 'NSF Certified/Listed'
    },
    'M' => {
        name    => 'miamidade',
        img     => 'miami_dade.gif',
        title   => 'Miami Dade'
    },
    'N' => {
        name    => 'new',
        img     => 'NEW.gif',
        title   => 'New Product'
    },
    'Q' => {
        name    => 'greenguard',
        img     => 'green-guard.gif',
        title   => 'GreenGuard Certified'
    },
    'R' => {
        name    => 'recycled',
        img     => 'recycled.gif',
        title   => 'Contains Recycled Content'
    },
    'S' => {
        name    => 'fsc',
        img     => 'FSC.gif',
        title   => 'Forest Stewardship Council Rated'
    },
    'T' => {
        name    => 'usamade',
        img     => 'usa_made.gif',
        title   => 'Made in USA'
    },
    'U' => {
        name    => 'ul',
        img     => 'ULapproved.gif',
        title   => 'UL Listed'
    },
    'V' => {
        name    => 'lowvoc',
        img     => 'LowVOC.gif',
        title   => 'Low VOC'
    },
    'Y' => {
        name    => 'regional',
        img     => 'region.gif',
        title   => 'Regionally Manufactured'
    },
    'Z' => {
        name    => 'zerovoc',
        img     => 'ZeroVOC.gif',
        title   => 'Zero VOC'
    },
);

sub adflags {
    my $self = shift;

    return undef unless $self->mfg_flags;

    my @letters = split(';', $self->mfg_flags);
    my $flags = [];
    foreach my $letter (@letters) {
        push @$flags, $ADFLAGS{$letter}
    }
    return $flags;
}

# this method is a light replacement to expensive calls to
# related_products_package() & system_seller_package() in
# templates/pages/inc/product_systemflag.tt (which were there in the
# past)
sub show_system_flag {
    my $self = shift;
    die if not $self->has_column_loaded( "has_related" );
    if( $self->get_column( "has_related" ) > 0
        and ($self->feature_enabled( "systemseller" )
             or $self->feature_enabled( "relatedseller" ))
        ) { return 1; }
    else { return ''; }
}


sub related_products_package {
    my ($self, $user) = @_;

    if (exists $self->{_related_products_package}) {
        return $self->{_related_products_package};
    }

    $self->{_related_products_package} = undef;

    if ($self->feature_enabled('relatedseller')) {

        my @r_products = $self->related_products->search(
            {
                'related_type' => 'relatedseller'
            }, {
                order_by => [ 'me.display_order' ]
            }
        )->all;
        if (scalar @r_products) {
            my $sections = [];
            my $section = undef;
            foreach my $r_product (@r_products) {
                if (
                    (! $section)
                    || ($r_product->section_title
                        && $r_product->section_title ne $section->{title})
                ) {
                    $section = {
                        title => $r_product->section_title
                        , document => $r_product->section_document || undef
                        , products => []
                    };
                    push @$sections, $section;
                }

                my $product = {
                    name => $r_product->related_product_name,
                    product_related_id => $r_product->product_related_id,
                };
                push @{$section->{products}}, $product;

            }
            $self->{_related_products_package} = $sections;
        }

    }

    return $self->{_related_products_package};

}



=head2 Get list of related products and docs

Get list of related products by sections 
and their docs: primary, secondary, categories
in 3 DB requests.
Then compose all that data into structure to HTML rendering.

=cut

sub system_package {
    my ($self, $user) = @_;

    if (exists $self->{_system_package}) {
        return $self->{_system_package};
    }

    $self->{_system_package} = undef;

    if ($self->feature_enabled('systemseller')) {

        # default params
        my $params = {
            default_doc_types => [qw(product_data msds)],
            offer_additional  => 'true',
        };

        # add feature to params
        my $feature = $self->manufacturer->feature('systemseller');
        if ($feature->feature_params) {
            my @param_pairs = split('&', $feature->feature_params);
            foreach ( @param_pairs ) {
                my ($n,$v) = split '=', $_;
                if ($v =~ /,/ || $n eq 'default_doc_types') {
                    my @v = split ',', $v;
                    $v = \@v;
                }
                $params->{$n} = $v;
            }
        }

        # get related products
        my @r_products = $self->related_products->search(
            {
                'related_product.suppress_reason_code' => ''
                ,'related_type' => 'systemseller'
            }
            ,{
                order_by => [ 'me.display_order' ]
                ,prefetch => 'related_product'
            }
        )->all;


        if (@r_products) {

            # get the list of product id's
            my $related_product_ids = [];
            foreach (@r_products) {
                if ($_->related_product) {
                    push @$related_product_ids, $_->related_product->product_id;
                }
            }

            # getting documents of all related products by one request
            my @docs = BST::Document->search(
                {
                   'me.document_type' => 'product'
                    , 'me.product_id' => $related_product_ids
                }
                ,{
                    prefetch => [ 'doc_type' ],
                    join     => 'doc_type',
                    order_by => ['me.document_role', 'dt_order', \'me.publisher_document_title is not NULL', 'me.publisher_document_title', 'me.auto_ctime desc'], #'
                }
            );

            my $docs_by_product = {};
            
            # compose the documents into special structure by product
            foreach my $doc (@docs) {
                my $product_id = $doc->get_column('product_id');
                if (! exists $docs_by_product->{$product_id}) {
                    $docs_by_product->{$product_id} = { primary_docs => [], secondary_docs => [] };
                }
                my $product_docs = $docs_by_product->{$product_id};
                
                my $is_primary = 0;
                foreach my $type (@{$params->{default_doc_types}}) {
                    if ($type eq $doc->doc_type->doc_type) {
                        $is_primary = 1;
                        last;
                    }
                }
                if ($is_primary) {
                    push @{$product_docs->{primary_docs}}, $doc;
                } else {
                    if ($params->{offer_additional} eq 'true') {
                        push @{$product_docs->{secondary_docs}}, $doc;
                    }
                }
            }



            # get categories documents by single request

            my $cat_docs_by_product = {};
            my $query_cat_docs = [];

            # compose sql_query_-or structure and by_product structure
            foreach my $r_product (@r_products) {
                my $related_product = $r_product->related_product;
                my $product_cat = $related_product->get_column("manufacturer_id") . ':' . $related_product->get_column("category_id");
                if (! exists $cat_docs_by_product->{$product_cat}) {
                    $cat_docs_by_product->{$product_cat} = {
                        manufacturer_id => $related_product->get_column("manufacturer_id")
                        , category_id => $related_product->get_column("category_id")
                        , docs => []
                    };
                    push @{$query_cat_docs}, {
                        '-and' => [
                            { 'me.publication_id' => $related_product->get_column("manufacturer_id") }
                            , { descendant_id  => $related_product->get_column("category_id") }
                        ]
                    };
                }
            }

            # get category docs from DB
            my @category_docs = BST::Document->search_product_category({
                    '-or' => $query_cat_docs
                })->all;

            # re-compose the docs items into by_product structure
            foreach my $doc (@category_docs) {
                foreach my $i (keys %{$cat_docs_by_product}) {
                    my $cat_docs = $cat_docs_by_product->{$i};
                    if ($cat_docs->{manufacturer_id} eq $doc->get_column('publication_id')
                        && $cat_docs->{category_id} eq $doc->get_column('descendant_id')
                    ) {
                        push @{$cat_docs->{docs}}, $doc;
                    }
                }
            }



            # compose the documents and products together
            my $sections = [];
            my $section = undef;
            foreach my $r_product (@r_products) {
                if (
                    (! $section)
                    || ($r_product->section_title
                        && $r_product->section_title ne $section->{title})
                ) {
                    $section = {title => $r_product->section_title, products => []};
                    push @$sections, $section;
                }

                my $product = {
                    id => $r_product->get_column('related_product_id')
                    , name => $r_product->get_column('related_product_name')
                    , primary_docs => []
                    , secondary_docs => []
                    , category_docs => []
                };
                push @{$section->{products}}, $product;

                if (exists $docs_by_product->{$product->{id}}) {
                    $product->{primary_docs} = $docs_by_product->{$product->{id}}->{primary_docs};
                    $product->{secondary_docs} = $docs_by_product->{$product->{id}}->{secondary_docs};
                }

                #push @{$product->{category_docs}}, $r_product->related_product->category_documents->all;

                my $related_product = $r_product->related_product;
                my $product_cat = $related_product->get_column("manufacturer_id") . ':' . $related_product->get_column("category_id");
                $product->{category_docs} = $cat_docs_by_product->{$product_cat}->{docs};

            }
            $self->{_system_package} = $sections;
        }

    }

    return $self->{_system_package};

}

sub attribute_value {
    my ($self, $attribute_id) = @_;
    return $self->{leed_attribute_values}->{$attribute_id};
}

1;



package BST::Product::ResultSet;

# this class would now be used for product searches always, with help
# of __PACKAGE__->resultset_class('BST::Product::ResultSet'); earlier
# in this file.

use strict;
use base qw(DBIx::Class::ResultSet);
use BST::ProductAttributeValue;

# we override the new() to add the needed company_feature joins to the
# rs attributes.
sub new {
    my( $class, $source, $attrs ) = @_;

    if($ENV{DBIC_TRACE_PRODUCT}) {
        use Data::Dumper;
        print STDERR "BST::Product::ResultSet->NEW($source,$attrs)\n";
        print STDERR "new() attrs: ", Dumper($attrs);
    }

    if( $attrs->{_no_features} ) {
        delete $attrs->{'+select'};
        delete $attrs->{'+as'};
        delete $attrs->{'order_by'};
        if($ENV{DBIC_TRACE_PRODUCT}) {
            print STDERR "bypassing auto features joining (_no_features in the attributes)\n";
        }
        return $class->next::method( $source, $attrs );
    }

    my $user = BST->current_user;
    my $user_bs_admin = ($user) ? $user->is_bs_admin : undef;
    my $user_company = ($user) ? $user->account->get_column('company_id') : undef;

    my $alias = $attrs->{alias} ||= 'me';
    my $from  = $attrs->{from} ||= [ {$alias => 'product'} ];

    # lets go through the ->{from} list and extract the names of
    # tables joined in there. add them to the $fromt hash
    my $fromt = {};
    foreach (@$from) {
        if ( ref $_ eq 'ARRAY' ) {
            my $j1 = $_->[0];
            my $k = (reverse sort keys %$j1)[0];
            $fromt->{$k}=1;
            warn "from table: $k\n"
                if($ENV{DBIC_TRACE_PRODUCT});
        } else {
            warn "from item: " . Dumper($_)
                if($ENV{DBIC_TRACE_PRODUCT});
        }
    }
    my $addselect = $attrs->{'+select'} ||= [];
    my $addas     = $attrs->{'+as'}     ||= [];
    my $addas_set = {};
    foreach( @$addas ) {
        $addas_set->{$_} = 1;
    }


    # if productmatch_feature is not joined there yet...
    if(not $fromt->{productmatch_feature}) {

        # now join the company features into the query
        # see http://trac.ahinea.com/bs-app/wiki/CompanyFeature
        # and ticket #571 for more details

        my $productmatch_status_expression;
        # join each of these features
        foreach( qw( productmatch systemseller relatedseller ) ) {
            # join company_feature
            push @$from, [
                {
                    $_ . '_feature' => 'company_feature',
                    -join_type    => 'LEFT',
                },
                {
                    $alias . '.manufacturer_id'  => $_ . '_feature.company_id',
                    $_ . '_feature.feature_name' => "'$_'",
                },
            ];

            # now let it appear in the SELECT clause and make it
            # accessible in the result via ->get_column()

            # in case of a simple user, we simply take the feature_status value
            my $status_expression = $_ . '_feature.feature_status';

            if($user_bs_admin) {
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
"CASE WHEN $status_expression = 'qa' and me.manufacturer_id='$user_company' THEN 'live'
WHEN $status_expression = 'live' THEN 'live'
ELSE '' END";
            }

            if ( not $addas_set->{ $_ . '_status' } ) {
                push @$addselect, $status_expression;
                push @$addas,     $_ . '_status';
            }

            # we do tweak the order by below
            # and that is why we need
            # $productmatch_status_expression
            if ($_ eq 'productmatch') {
                $productmatch_status_expression = $status_expression;
            }
        }

        if (not $addas_set->{has_related}) {
            # XXX this does not take the product_related.related_type
            # column values into account, but it SHOULD
            push @$addselect, \ '(select count(*) from product_related where product_id=me.product_id)';
            push @$addas, "has_related";
        }

        if($user_bs_admin) {
            if (not $addas_set->{has_afterqa_docs}) {
            push @$addselect, \ "(select count(*) from document where document.product_id = me.product_id and document.suppress_reason_code = 'afterqa')";
            push @$addas, "has_afterqa_docs";
            }
        }

        if ( my $o = $attrs->{order_by} ) {
            my $pms = $productmatch_status_expression;
            unshift @$o,
              \ qq~( ($pms) IS NOT NULL
                    AND ($pms) = 'live'
                    AND me.mfg_short_text IS NOT NULL
                    AND me.mfg_short_text <> '' ) DESC~;
            # the $productmatch_status_expression depends on the
            # user performing the query... see above.
        }
    }

    my $self = $class->next::method( $source, $attrs );
    return $self;
}

sub get_product_attributes {
    my $self = shift;
    my $attributelist = shift;

    my @products = $self->all_name_sorted;
    my @attributes = ();

    return \@products if ref $attributelist ne "ARRAY";
    return \@products if not scalar @$attributelist;
    for my $attribute (@$attributelist) {
        if (ref $attribute eq "ARRAY") {
            my @list = map {$_->get_column('attribute_id')} @$attribute;
            push @attributes, $_ for @list;
        } else {
            push @attributes, $attribute->get_column('attribute_id');
        }
    }

    my @attrvalues = BST::ProductAttributeValue->search({attribute_id => [ @attributes ] });

    for my $product (@products) {
        %{$product->{leed_attribute_values}} = map {$_->get_column('attribute_id') => $_->val} grep {$_->get_column('product_id') eq $product->get_column('product_id')} @attrvalues;
    }

    return \@products;
}

sub count {
    my $self = shift;
    #my $attrs_orig = { %{$self->{attrs}} };
    $self ->{attrs}->{_no_features} = 1;
    my $res = $self->next::method( @_ );
    #$self ->{attrs} = $attrs_orig;
    return $res;
}

# **** NOTE: THE FOLLOWING METHOD IS NO LONGER NEEDED since the same
# is now done in SQL, see above; it is left here for historical
# reasons. ****

# this overrides the 'all' ResultSet method and adds sorting based on
# the productmatch feature and mfg_short_text
# SQL equivalent:
#   ORDER BY (company_feature.feature_status = 'live' AND me.mfg_short_text <> '')
# assuming that company_feature.feature_name is 'productmatch' here
sub all_name_sorted {
    my $self = shift;
    my @array = $self->all();
    #warn "got an array of " . scalar @array . ' products' . "\n";
    @array = sort {
        my $adv_a      = $a->productmatch_active;
        my $adv_b      = $b->productmatch_active;
        my $name_a     = $a->get_column("product_name");
        my $name_b     = $b->get_column("product_name");
        return $adv_b <=> $adv_a
            || $name_a cmp $name_b
            || $a->id cmp $b->id;
    } @array;
    return @array;
}

1;
