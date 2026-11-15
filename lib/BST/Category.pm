package BST::Category;

use strict;
use warnings;

use Data::Dumper;
use Params::Validate qw(:all);

use BST::Company;
use BST::Product;
use BST::Attribute;

use base qw/BST::Core BST::Schema::Category/;

=head1 DESCRIPTION
    Product Category class
=cut

__PACKAGE__->table("category");

__PACKAGE__->belongs_to(
    "parent" => "BST::Category",
    { category_id => "parent_id" },
    { join_type => 'LEFT' },
);

__PACKAGE__->has_many(
  "children" => "BST::Category",
  { "foreign.parent_id" => "self.category_id" },
);
__PACKAGE__->has_many(
  "documents" => "BST::Document",
  { "foreign.category_id" => "self.category_id" },
);

__PACKAGE__->might_have(
  "category_counts" => "BST::CategoryCounts",
  { "foreign.category_id" => "self.category_id" },
);

__PACKAGE__->has_many(
  "category_attributes",
  "BST::CategoryAttribute",
  { "foreign.category_id" => "self.category_id" },
);

__PACKAGE__->many_to_many(
  "_attributes" => "category_attributes",
  "attribute_id",
);

sub attributes {
    my $self = shift;

    my @attributes = $self->_attributes;

    @attributes = sort {$a->result_display_order cmp $b->result_display_order} @attributes;

    my @results = ();
    my @combined = ();
    for my $attr (@attributes) {
        if ($attr->result_display_type eq "alone") {
            if (@combined) {
                push @results, [ @combined ];
                @combined = ();
            }
            push @results, $attr;
        } elsif ($attr->result_display_type eq "combined") {
            push @combined, $attr;
        }
    }

    if (@combined) {
        push @results, [ @combined ];
    }

    return \@results;
}

sub manufacturers {
    my $self = shift;
    my $q    = shift || {};
    my $attrs = shift;
    return 0 unless $self->products->count();
    return BST::Company->search_by_category( { 'p.category_id' => $self, %$q }, $attrs );
}

sub products { 
    my $id = shift->id;
    return BST::Product->search_by_category( { 'me.category_id' => $id } ); 
}

sub related_categories {
    my $self    = shift;
    
    my (@parents, @related, $parent, $parent_id, $params, $last_id);
    
    $parent     = $self->parent_id;
    $parent_id  = $parent->id;
    
    while ($parent_id ne '00000') {
        last if $parent_id =~ /000$/;
        $parent     = $parent->parent_id;
        push @parents, $parent_id if ($parent_id =~ /00$/ || ($last_id && substr($last_id, 0, 4) ne substr($parent_id, 0, 4)));
        $last_id    = $parent_id;
        $parent_id  = $parent->id;
    }
    
    foreach ($self->see_also_category_ids, $self->mf_see_also_category_ids, $self->see_instead_category_ids, $self->mf_see_instead_category_ids) {
        push @related, split(q{,}, $_) if $_;
    }
    
    $params = {
        -or => [
            -nest => [
                -and => [
                    [
                        'me.parent_id'    => { -in => [ $self->id, $self->parent_id->id ] },
                        'me.category_id'  => $self->parent_id->id,
                        'gc.category_id'  => $self->id
                    ]
                ]
            ]
        ]
    };
    
    unshift @{ $params->{'-or'}->[1]->[1] }, 'SUBSTRING(me.category_id, 1, 3)' => substr($self->id, 0, 3) unless scalar @parents;
    unshift @{ $params->{'-or'} }, 'me.category_id' => { -in => \@parents } if scalar @parents;
    unshift @{ $params->{'-or'} }, 'me.category_id' => { -in => \@related } if scalar @related;
    
    return BST::Category->list($params);
}

sub list {
    my ($class, $query, $params) = @_;

    my $sql;

    # categories of specified company (manufacturer)
    if ($query->{'c.company_id'}) {
        my $columns = [ map { "me.$_" } __PACKAGE__->columns ];
        push @$columns, map { "parent.$_" } __PACKAGE__->columns;
        push @$columns, map { "parent_2.$_" } __PACKAGE__->columns;

        $sql = {
            alias       => 'me',
            from        => [
                { me => 'category' },
                [
                    { p => 'product', -join_type => 'left' },
                    { 'me.category_id' => 'p.category_id' }
                ],
                [
                    { c => 'company', -join_type => 'left' },
                    { 'p.manufacturer_id' => 'c.company_id' }
                ],
                [
                    { pc => 'category', -join_type => 'left' },
                    { 'pc.category_id' => 'me.parent_id' }
                ],
                [
                    { gc => 'category', -join_type => 'left' },
                    { 'gc.category_id' => 'pc.parent_id' }
                ],
            ],
            where       => BST::Category->hide_suppressed ? {
                'me.public_visible'         => 't',
                'me.suppress_reason_code'   => '',
                -nest                       => [
                    -and    => [ 'p.public_visible' => undef ],
                    -and    => [ 'p.public_visible' => 't', 
                                 'p.suppress_reason_code' => '' ]
                ]
            } : undef,
            '+select'   => [ { count => 'DISTINCT p.product_id' }, { sum => "CASE WHEN p.is_green THEN 1 ELSE 0 END" } ],
            '+as'       => [ 'product_count', 'green_product_count' ],
            group_by    => $columns,
            order_by    => 'me.category_id',
            having      => 'count(p.product_id) > 0',
            prefetch => {parent => 'parent'},
            %{ $params || {} },
        };
        
    } else { # general (non-specified-company) list of categories
        
        my $where;
        if (BST::Category->hide_suppressed) {
            $where = { -and => [
                {'category_counts.products' => { '>' => 0 } }
                , {"me.public_visible" => 't'}
                , {"me.suppress_reason_code" => ''}
            ]};
        } else {
            $where = [
                {'category_counts.products_admin' => { '>' => 0 } }
            ];
        }
        
        $sql = {
            alias       => 'me',
            from        => [
                { me => 'category' },
                [
                    { pc => 'category', -join_type => 'left' },
                    { 'pc.category_id' => 'me.parent_id' }
                ],
                [
                    { gc => 'category', -join_type => 'left' },
                    { 'gc.category_id' => 'pc.parent_id' }
                ]
            ],
            where       => $where,
            order_by    => 'me.category_id',
            prefetch    => [
                'category_counts'
                , { 'parent' => 'parent' }
            ],
            %{ $params || {} },
        };
    }
    
    return BST::Category->search($query, $sql);
}

sub pm_count {
    my $self = shift;
    
    my $cc = $self->category_counts;
    return {p => 0, m => 0} unless $cc;
    if (BST::Category->hide_suppressed) {
        return {p => $cc->products, m => $cc->manufacturers};
    } else {
        return {p => $cc->products_admin, m => $cc->manufacturers_admin};
    }
}

=head2

     # also index the parent title
     from => 'category LEFT JOIN category pc ON (pc.category_id = category.parent_id) LEFT JOIN category gc ON (gc.category_id = pc.parent_id)',
     columns => [qw(category.category_id category.category_title category.mf_includes category.buildsite_description), 
                 'pc.category_title as parent_title', 'gc.category_title as grandparent_title'],
     # how they show up in the hash
     # higher scored fields should come first
     colnames => [qw(category_id category_title parent_title buildsite_description mf_includes )],
     # score multiplier for the field
     scored => {mf_includes => .5, buildsite_description => .5},

=cut


sub name_search_terms {
    my $class = shift;

    my ($keywords, $composite_keywords) = BST::SearchKeywords::tokenize_category_search(shift);
    return (@$keywords, @$composite_keywords);
}


sub name_search_filter {
    my $class = shift;
    my ($what, $term, $table) = @_;

    my $field = $class->search_field([qw(category_id category_title buildsite_description mf_includes pc.category_title)], $table);

    my ($keywords, $composite_keywords) = BST::SearchKeywords::tokenize_category_search($what);
    return unless (@$keywords or @$composite_keywords);

    return $class->keywords_filter(
        $field, $keywords, $composite_keywords, $term
    );
}


=head2 name_search

    $what = string
    $term = 'and', 'or'

=cut

sub name_search {
    my $self = shift;

    my $query = $self->name_search_filter(@_);    
    return unless defined $query;

    return BST::Category->list($query);
}


sub top_visible_ancestor {
    my $self = shift;

    return shift @{$self->ancestors};
}

sub first_visible_ancestor {
    my $self = shift;
    
    return pop @{$self->ancestors};
}

sub ancestors {
    my $self = shift;
    
    my $anc = [];
    my $me = $self;

    # to get at least one category included.
    unshift @$anc, $me;
    $me = $me->parent;
    while (1) {
        unshift @$anc, $me
            if ( $me->public_visible && $me->id !~ /^0\d000$/ || (length($anc->[@$anc-1]) < 6 && $me->id !~ /^0\d\d00$/) );
        last if $me->get_column("parent_id") eq '00000';
        $me = $me->parent;
        last if $me->is_root;
    }
        
    return $anc;
}

sub is_root {
    my $self = shift;
    return 1
        if ($self->category_id eq '00000');

    return;
}

# this looks like it was copied from BST::Product without any reasoning
sub ___documents {
    my $self = shift;
    my $query = {
                     document_type  => 'category',
                     publication_id => $self->manufacturer->company_id,
                     descendant_id  => $self->category->category_id,
                };
    $query->{'suppress_reason_code'} = '' if
       (BST::Product->hide_suppressed);
    return $self->_documents(
        $query,
        {
            prefetch => ['doc_type',
                         { category_id => 'category_descendant_category_ids' } ],
            order_by => ['document_role', 'dt_order', 'publisher_document_title', 'auto_ctime desc'],
        });
}

sub is_suppressed { return shift->suppress_reason_code; }

sub title {
    my $self = shift;
    my $name = "";
    if (length($self->id) > 6) {
        $name .= $self->parent->parent->category_title . " - ";
    }
    if (length($self->id) > 5) {
        $name .= $self->parent->category_title . " - ";
    }
    $name .= $self->category_title;
    return $name;
}

sub full_title {
    my $self = shift;
    my $title = "";
    if (length($self->id) > 6) {
        $title = $self->parent->parent->category_title . " - ". $self->parent->category_title . " - " . $self->category_title;
    } elsif (length($self->id) > 5) {
        $title = $self->parent->category_title . " - " . $self->category_title;
    } elsif ($self->id !~ /00$/) {
        $title = $self->parent->category_title . " - " . $self->category_title;
    } else {
        $title = $self->category_title;
    }
    return $title;
}

sub level {
    my $self = shift;
    return 0 if '000' eq substr($self->id, -3, 3);
    return 1 if 5 == length($self->id);
    return 2 if 6 == length($self->id);
    return 3 if 6 < length($self->id);
    return 0;
}

1;
