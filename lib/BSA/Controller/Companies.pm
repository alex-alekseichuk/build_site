package BSA::Controller::Companies;

use strict;
use warnings;
use base 'BSA::Controller';

use BST::Company;
use Data::Dumper;

=head1 NAME

BSA::Controller::Manufacturers - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub index : Private {
    my ( $self, $c ) = @_;
    $c->response->redirect($c->uri_for('list'));
}

=head2 list

=cut

sub list : Local Form {
    my ( $self, $c ) = @_;
    
    my $form    = $self->formbuilder;
    my $query   = { company_type => 'manufacturer' };
    
    return if $c->check_html_cache;
    
    my @companies;
    
    if (my $category = $form->params('category')) {
        $c->stash->{category}       = BST::Category->load({ category_id => $category });
        $query->{'p.category_id'}   = $category;
        @companies                  = BST::Company->search_by_category($query, {})->all;
    } else {
        @companies                  = BST::Company->search($query, {})->all;
    }
    
    ## Check my manufacturer filter
    my $my_filter           = $c->request->param('mfg_my_all');
    my $m_list              = $c->user->settings->list->{default_allow_publishers};
    my @my_manufacturers    = $m_list ? split(/;/, $m_list) : ();
    
    $my_filter              = (! defined($my_filter) || (defined($my_filter) && $my_filter eq 'my')) ? 1 : 0;
    
    if (BST::Company->hide_suppressed) {
        if ($my_filter && @my_manufacturers) {
            my $allow;
            $allow->{$_}++
                foreach @my_manufacturers;
            $c->stash->{list} = [ grep { $allow->{$_->company_id} } @companies ];
        } else {
            $c->stash->{list} = \@companies;
        }
    } else {
        if ($my_filter && @my_manufacturers) {
            my $allow;
            $allow->{$_}++
                foreach @my_manufacturers;
            $c->stash->{list} = [ grep { $allow->{$_->company_id} } @companies ];
        } elsif ($my_filter) {
            $c->stash->{list} = [ grep {$_->public_visible and not $_->suppress_reason_code} @companies ];
        } else {
            $c->stash->{list} = \@companies;
        }
    }
}

=head2 view

=cut

sub view : Local {
    my ( $self, $c ) = @_;

    $c->stash->{obj} = BST::Company->load(id => $c->req->params->{id});
}

=head2 edit

=cut

sub edit : Local Form {
    my ( $self, $c ) = @_;
}

=head1 AUTHOR

Yuri Pac <yu.pats@gmail.com>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
