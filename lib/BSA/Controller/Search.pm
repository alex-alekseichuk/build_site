package BSA::Controller::Search;

use strict;
use warnings;
use base 'BSA::Controller';
use Data::Dumper;

use BST::Product;

=head1 NAME

BSA::Controller::Search - Catalyst Controller

=head1 DESCRIPTION

v1 search:
# set_matching_product_ids
# tokenize_search_phrasex
# check if search word NOT in product name IS in manufcturer or category name;
# consider it an ALL match if all words not in product are in mfg or cat name
# sort products


v2 search:
"LEFT JOIN company_feature ON (manufacturer_id = company_feature.company_id AND feature_name = 'productmatch' AND feature_status = 'live')",
sql_order_by => ["(feature_status != 'live' OR mfg_short_text IS NULL)", 'product_name'],

Manufacturer

     table => 'company',
     where => "company_type = 'manufacturer'",
     columns => [qw(company_id legal_name company_nickname)],

Category

     table => 'category',
     # also index the parent title
     from => 'category LEFT JOIN category pc ON (pc.category_id = category.parent_id) LEFT JOIN category gc ON (gc.category_id = pc.parent_id)',
     columns => [qw(category.category_id category.category_title category.mf_includes category.buildsite_description),
                 'pc.category_title as parent_title', 'gc.category_title as grandparent_title'],
     # how they show up in the hash
     # higher scored fields should come first
     colnames => [qw(category_id category_title parent_title buildsite_description mf_includes )],
     # score multiplier for the field
     scored => {mf_includes => .5, buildsite_description => .5},

Product name

     table => 'product',
     columns => [qw(mfg_product_id product_name product_id)],

ASTM

     table => 'product',
     detail_table => 'product_standard',
     where => "standard_org_id = 'astm'",
     columns => [qw(standard_document_identifier)],

=head1 METHODS

=cut


=head2 index

=cut

sub index : Path('/search') Form('search') {
    my ( $self, $c ) = @_;

    my $form = $self->formbuilder;
    $form->submitted('q'); # see http://search.cpan.org/~nwiger/CGI-FormBuilder-3.0501/lib/CGI/FormBuilder.pod#submitted()

    my $q    = $form->field('q');
    my $term = $form->field('term');
    my $where= $form->field('where');

    $c->stash->{template} = 'search.tt';
    return unless $q;

    my $has_and_search;
    my $has_or_search;
    my $show_keywords = [];

    my @all = ();

    if ( $where eq 'astm' ) {

        # hide and-or radiobuttons set
        $form->field('name'=>'term', 'type' => 'hidden');

        my $list_or = BST::Product->astm_search($q);

        my $all_or = _search($c, $where, $list_or);
        @all = @$all_or;
    } else {
        my $search;
        my $class = {pname => 'BST::Product', manufacturer => 'BST::Company', category => 'BST::Category'}->{$where};
        return unless $class;
        $c->stash->{hide_suppressed} = $class->hide_suppressed;

        @$show_keywords = $class->name_search_terms($q, 'or');

        my $list = $class->name_search($q, 'or');
        return unless $list;
        my $count = $list->count;

        if ($count) {
            if (scalar @$show_keywords > 1) {
                my $list_and = $class->name_search($q, 'and');
                my $and_count = $list_and->count;

                if ($and_count) {
                    if ($term eq 'and') {
                        $has_or_search = $count > 250 ? $count : scalar (my @a = _search($c, $where, $list));
                        @all = _search($c, $where, $list_and);
                        @$show_keywords = $class->name_search_terms($q, 'and');
                    } else {
                        $has_and_search = scalar (my @a = _search($c, $where, $list_and));
                    }
                }
            }
            @all = _search($c, $where, $list) unless @all;
        }
    }

    #return if not $list;

    $c->stash->{show_keywords} = join(' ', @$show_keywords);
    $c->stash->{has_and_search} = $has_and_search;
    $c->stash->{has_or_search} = $has_or_search;


    $c->stash->{list} = { all => \@all };
}

sub _search {
    my $c = shift;
    my $where = shift;
    my $list = shift;
    my @all = ();
    if (BST::Company->hide_suppressed) {
        if ($c->user->settings->list->{default_allow_publishers} && $c->request->param('mfg_my_all') ne 'all') {
            my $my_manufacturers = $c->user->settings->list->{default_allow_publishers};
            my $allow = { map { $_ => 1 } split /;/, $my_manufacturers };

            @all =
                ($where eq 'pname' or $where eq 'astm')                               ?
                    grep { $allow->{ $_->get_column('manufacturer_id') } } $list->all :
                ($where eq 'manufacturer')                                            ?
                    grep { $allow->{ $_->company_id } } $list->all                    :
                ($where eq 'category')                                                ?
                    grep { grep { $allow->{ $_->company_id } } $_->manufacturers } $list->all : ();
        } else {
            @all = $list->all;
        }
    } else {
        if ($c->request->param('mfg_my_all') ne 'all') {
            foreach ($list->all) {
                if ($_->public_visible and not $_->suppress_reason_code) {
                    push @all, $_;
                }
            }
        } else {
            @all = $list->all;
        }
    }
    return wantarray ? @all : \@all;
}


sub advanced : Path('/search/advanced') {
    my ( $self, $c ) = @_;

    my $submitted = $c->req->param('submit');

=pod
        product_name
        astm
        manufacturer
        category
=cut

    if ($submitted) {

        my $exists = [];
        foreach $_ qw(sri lumens lumens_nadir flow_gpf flow_gpm pre_consumer post_consumer harvest_loc manuf_loc voc_content no_formaldehyde visible_light) {

            my $attribute = $_;
            $attribute = $attribute . "_min" if $attribute =~ /^(sri|percent_certified|percent_renewable|post_consumer|pre_consumer|r_value)$/;
            $attribute = $attribute . "_max" if $attribute =~ /^(voc_content|flow_gpf|flow_gpm)$/;

            my $conds = [
                sprintf "pav.attribute_id = '%s'", $attribute
            ];
            push @$conds, sprintf "pav.val::float > %d", $c->req->param("att-$_-min") if $c->req->param("att-$_-min");
            push @$conds, sprintf "pav.val::float < %d", $c->req->param("att-$_-max") if $c->req->param("att-$_-max");
            push @$conds, "pav.val like '%" . $c->req->param("att-$_-state") . "%'" if $c->req->param("att-$_-state");
            push @$conds, "pav.val like '%" . $c->req->param("att-$_-city") . "%'" if $c->req->param("att-$_-city");

            next if $#{$conds} == 0;
            my $str = "EXISTS (SELECT * FROM product_attribute_value pav WHERE pav.product_id = me.product_id AND " . join(" AND ", @$conds) . ")";
            push @$exists, \$str;
        }

        my $query = [];
        my $from = [];

        if ($c->req->param('product_name')) {
            push @$query, BST::Product->name_search_filter(
                $c->req->param('product_name'), 'or'
            );
        }

        if ($c->req->param('astm')) {
            push @$query, BST::Product->astm_search_filter(
                $c->req->param('astm')
            );
        }

        if ($c->req->param('manufacturer')) {
            push @$query, BST::Company->name_search_filter(
                $c->req->param('manufacturer'), 'or', 'mnf'
            );
            push @$from, [ { mnf => 'company', -join_type => 'left' }, { 'mnf.company_id' => 'me.manufacturer_id' } ];
        }

        if ($c->req->param('category')) {
            push @$query, BST::Category->name_search_filter(
                $c->req->param('category'), 'or', 'ctg'
            );
            push @$from, [ { ctg => 'category', -join_type => 'left' }, { 'ctg.category_id' => 'me.category_id' } ];
            push @$from, [ { pc => 'category', -join_type => 'left' }, { 'pc.category_id' => 'ctg.parent_id' } ];
            push @$from, [ { gc => 'category', -join_type => 'left' }, { 'gc.category_id' => 'pc.parent_id' } ];
        }

        my $where = [];
        push @$where, @$exists;
        push @$where, @$query;

        if (@$where) {
            my $list = BST::Product->search({}, { from => $from, where => {'-and' => $where} });
            $c->stash->{list} = $list;
        }
    }
}
1;
