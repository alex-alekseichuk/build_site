package BSA::Controller::Product;

use strict;
use warnings;
use base 'BSA::Controller';
use Data::Dumper;
use BST qw(error);
use BST::ZIP;

=head1 NAME

BSA::Controller::Product - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 list

lists procuts by params and their unions.
?manufacturer=id
?category=id
...

=cut

sub list : Local Form {
    my ( $self, $c ) = @_;
    my $form = $self->formbuilder;
    my $query = {};
    my $params = {};
    my ($category);

    if ($form->params('manufacturer')) {
        $query->{'me.manufacturer_id'} = $form->params('manufacturer');
        $c->stash->{manufacturer} = BST::Company->load({ company_id => $form->params('manufacturer') });
    }

    if ($form->params('category')) {
        $query->{'me.category_id'} = $form->params('category');
        $category = BST::Category->load({ category_id => $form->params('category') });
        $c->stash->{category} = $category;
    }

    return $c->response->redirect( '/search?where=pname' ) unless keys %$query;

    if ($category) {
        $c->stash->{attributes} = $category->attributes;
        return if $c->check_html_cache;

        my $products = BST::Product->search($query, $params);
        $c->stash->{list} = $products->get_product_attributes($category->attributes);
    } elsif ($form->params('manufacturer')) {
        return if $c->check_html_cache;
        
        $c->stash->{list} = [ BST::Product->search($query, $params)->all_name_sorted ];
    } else {
        return if $c->check_html_cache;
        
        $c->stash->{list} = [ BST::Product->search($query, $params)->all ];
    }
}


sub view : Local {
    my ( $self, $c ) = @_;

    my $id = $c->req->params->{'id'};
    my $product = $c->get_object_or_404('BST::Product', {product_id => $id});
    return unless $c->must_read($product);

    $c->stash->{product} = $product;
    
    unless ($c->check_html_cache) {
        $c->stash->{related_products_package} = $product->related_products_package($c->user);
        $c->stash->{system_package} = $product->system_package($c->user);
        $c->stash->{category_documents} = [ $product->category_documents->all ];
        $c->stash->{company_documents} = [ $product->manufacturer->documents->all ];
    }

    $c->forward( $c->view('TT::Ajax') ) if $c->req->params->{'ajax'};
}


sub add_related_products : Local {
    my ( $self, $c ) = @_;

    my $id = $c->req->params->{'id'};
    my $product = $c->get_object_or_404('BST::Product', product_id => $id);
    return unless $c->must_read($product);

    if ($c->req->param('add_related_products') || $c->req->param('ajax')) {
        my $old_fobj;
        my @related_products_ids = $c->req->param('related_product');
        $c->session->{related_products} = {} unless $c->session->{related_products};
        $c->session->{related_products}->{$id} = [ @related_products_ids ];

        my @related_products = BST::ProductRelated->search({product_related_id => [ @related_products_ids ]});

        my $fobj = $product->generate_related_products_file($c->user, \@related_products);

        if ( my @items = grep { $_->file_id && $_->file_id->is_related_products_file($product) } $c->current_package->items ) {
            $old_fobj = $items[0]->file_id;
            $c->current_package->remove($old_fobj);
            $old_fobj->replaced_by_doc($fobj->file_id);
            $old_fobj->replaced_by_date(time);
            $old_fobj->replaced_by_user($c->user->user_id);
            $old_fobj->save();
        }


        my $package = $c->req->param('package_id') ? BST::Package->load(file_id => $c->req->param('package_id')) : $c->current_package;
        return unless $package && $c->must_write($package);

        my $row_id = $package->find_product($product->product_id);
        $package->add_item($fobj, $row_id);
        $package->save;

        if ($c->req->param('ajax')) {
            my $res = {
                file => {
                    title => $fobj->file_title,
                    id => $fobj->file_id,
                }
            };

            $res->{package} = {
                title => $package->file_title,
                id => $package->package_id
            };

            my $toc_row = $package->find_toc_item($fobj);
            if (defined $toc_row) {
                $res->{row_id} = $toc_row;

                my $fields = $BST::PackageToc::Types::TYPES{$package->package_toc_type}->{column_fields};
                $res->{row} = $c->_json_toc_row( $package->get_toc_row($toc_row), $fields ) ;
            }
            if ($old_fobj) {
                $res->{old_file} = {
                    id => $old_fobj->file_id,
                    url => $old_fobj->download_url
                }
            }
            $c->stash->{Result} = $res;
            return $c->forward( $c->view('JSON') ); 
         } 
    }

    return $c->response->redirect( "/product/view?id=$id" );
}





sub zip_search : Local {
    my ( $self, $c ) = @_;

    return $c->deny() if $c->user->settings->list->{disable_dealer_search};

    my $id = $c->req->params->{'id'};
    my $prod = $c->get_object_or_404('BST::Product', product_id => $id);
    return unless $c->must_read($prod);

    my $zip = $c->req->param('zip');

    if ($zip && $zip !~ /^\d{5}$/) {
        &error->invalid_zipcode;
        return $c->forward($c->view('TT::Popup')) if $c->req->params->{'popup'};
    }

    $c->res->cookies->{zip} = { value => $zip };

    my @companies = BST::search(
        'BST::Company',
        {
            'me.company_type'           => "dealer",
            'me.addr_city'              => {"!=", undef},
            'me.suppress_reason_code'   => "",
            'me.public_visible'         => "true",
        },
        {
            alias    => 'me',
            from     =>
            [
                { me => 'company' },
                [
                    {
                        company_grouping => 'company_grouping',   # table to join
                    },
                    {
                        'me.linecard_grouping_id'         => 'company_grouping.grouping_id',
                        'company_grouping.company_id'     => "'" . $prod->manufacturer->company_id . "'",
                    },
                ],
                [
                    {
                        "features" => "company_feature" 
                    },
                    {
                        'me.company_id'            => 'features.company_id',
                        'features.feature_name'    => "'directory'",
                        'features.feature_status'  => "'live'",
                    }
                ],
            ],
            join => [ "branch", "division" ],
            order_by    => ["(features.feature_level)", 'coalesce(branch.legal_name, division.legal_name, me.company_nickname, me.legal_name)' ],
        }
    );

    $c->stash->{product} = $prod;
    $c->stash->{zip} = $zip;

    if ($zip) {
        my $max_distance = BST::config('zip_search_max_distance');
        $c->stash->{max_distance} = $max_distance;

        my $zipper = BST::ZIP->instance();
        my $sorted = $zipper->proximity_sort_rows(
            \@companies,
            "addr_postal_code",
            $zip,
            "miles",
            $max_distance
        ) || [];

        $c->stash->{found} = scalar @$sorted;

        if ($sorted) {
            $c->stash->{companies} = $sorted;
        }
    } else {
        $c->stash->{found} = scalar @companies;
        $c->stash->{companies} = \@companies;
    }

    $c->forward($c->view('TT::Popup')) if $c->req->params->{'popup'};

}

=head1 AUTHOR

Yuri Pac <yu.pats@gmail.com>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
