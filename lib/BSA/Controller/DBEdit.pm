package BSA::Controller::DBEdit;

use strict;
use warnings;
use base 'BSA::Controller';
use Data::Dumper;
use BST qw(schema);

=head1 NAME

BSA::Controller::DBEdit - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

my $conf = {
    tables => {
        account_user => {
            display => [ qw( 
                user_id user_role primary_location login_id user_password block_access
            )],
        },
        company => {
            display => [ qw( company_id legal_name company_type ) ],
            textarea => [ qw( buildsite_public_notes buildsite_private_notes )], 
        },
    },
    tablegroups => [
        {
            label => 'Companies, Categories, Products, Documents',
            tables => [qw(category category_counts category_descendant category_grouping category_keyword company company_feature company_grouping company_keyword doc_type_info document document_list document_list_member product product_keyword product_related product_standard publication)],
        },
        {
            label => 'LEED data',
            tables => [qw(attribute category_attribute leed_area leed_credit leed_credit_attribute product_attribute_value product_leed_credit)],
        },
        {
            label => 'Accounts, Locations, Users',
            tables => [qw(account account_location account_private_location account_user)],
        },
        {
            label => 'Messages, Contacts, Packages and Files',
            tables => [qw(addressbook_company addressbook_person file message message_recipient package_item)],
        },
        {
            label => 'v2 Accounts and credit cards',
            tables => [qw(customer_account customer_order customer_user gateway_payment)],
        },
        {
            label => 'Other',
            tables => [],
        },
    ],
};

sub index :Chained('/') :PathPart('dbedit') :Args(0) {
    my ($self, $c) = @_;
    my $tables = {};

    return $c->deny() unless $c->user->is_bs_admin;

    for my $group (@{$conf->{tablegroups}}) {
        $tables->{$_} = 1 for @{ $group->{tables} };
    }

    my $dbh = BST::dbh();
    my $tbls = $dbh->selectall_arrayref("SELECT table_name FROM information_schema.tables where table_schema='public'");
    my @others = ();

    for my $tbl (@$tbls) {
        push @others, $tbl->[0] unless $tables->{$tbl->[0]};
    }

    $conf->{tablegroups}->[$#{$conf->{tablegroups}}]->{tables} = \@others;

    $c->stash->{tablegroups} = $conf->{tablegroups};
    $c->stash->{template} = "dbedit/index.tt";
}

sub base :Chained('/') :PathPart('dbedit') :CaptureArgs(1) {
    my ($self, $c) = @_;
    my ($source) = @{$c->req->args};

    return $c->deny() unless $c->user->is_bs_admin;
    my ($s, $resultset, $src, $sourcetables);

    $s = schema();

    push @{$sourcetables->{$s->resultset($_)->result_source->name}}, $_ for $s->sources;
    my $tablename = $source;
    $source = $sourcetables->{$source}->[0] || $source;

    eval { $resultset = $s->resultset($source);};
    if ( not $resultset ) {
        return $c->error404();
    }

    $c->stash->{resultset} = $resultset;
    $c->stash->{tablename} = $tablename;
    $c->stash->{source} = $source;

}

sub list :Chained('base') :PathPart('list') :Args(0) {
    my ($self, $c) = @_;

    my ($resultset, $src, @columns);
    $resultset = $c->stash->{resultset};
    $src = $resultset->result_source;

    @columns = ();
    if (ref $conf->{tables}->{$c->stash->{tablename}}->{display} eq "ARRAY") {
         @columns = @{$conf->{tables}->{$c->stash->{tablename}}->{display}};
    } else {
         @columns = $src->primary_columns;
    }

   $c->stash->{columns} = \@columns;
    my @select = map ("me.$_", @columns);

    my @list = $resultset->search(undef, {columns => \@select});

    $c->stash->{list} = \@list;
    $c->stash->{name} = $src->name;

    $c->stash->{template} = "dbedit/list.tt";
}

sub edit :Chained('base') :PathPart('') :Args(1) :Form {
    my ($self, $c) = @_;
    my $pkvalue = $c->req->args->[0];

    my (@columns, $obj, $resultset, $src, $form, %request);

    $resultset = $c->stash->{resultset};
    $src = $resultset->result_source;
    $form = $self->formbuilder;

    # load the object
    if ($pkvalue ne "new") {
        $obj = $resultset->find($pkvalue) or return $c->error404();
    }

    # define the form fields
    @columns = $src->columns;
    # display these columns in the record list (#849)
    my $display_columns = $conf->{tables}->{$c->stash->{tablename}}{display} || [$src->primary_columns];

    # sorting: [primary columns], column1, ... $columnN, [auto_ctime], [auto_mtime]
    my %order = map {$_ => "___" . $_} $src->primary_columns;
    $order{$_} = "xxx" . $_ for qw(auto_ctime auto_mtime);
    @columns = sort {($order{$a} || $a) cmp ($order{$b} || $b)} @columns;

    foreach my $column (@columns) {
        #warn "field: $column\n";
        my $type = $src->column_info($column)->{data_type} eq "boolean" ? "select" : "text";
        my $disabled = 0;
        $disabled = 1 if grep {($_ eq $column) && $obj} $src->primary_columns;
        $disabled = 1 if $column =~ /auto/;
        my $field = {
                        name        => $column,
                        label       => $column,
                        required    => !$src->column_info($column)->{is_nullable} && $src->column_info($column)->{default_value} && $src->column_info($column)->{default_value} !~ /^(\'\')/,
                        type        => $type,
                     };
        $field->{required} = 0 if !$obj && grep {$_ eq $column} $src->primary_columns;
        $field->{options} = [ ['1' => 'true'], ['0' => 'false'] ] if $type eq "select";
        $field->{selectname} = 0 if $type eq "select" and !$src->column_info($column)->{is_nullable};
        $field->{value} = $obj ? $obj->get_column($column) : undef;
        $field->{disabled} = $field->{required} = 1 if $disabled;

        $field->{required} = 0 if $column =~ /^(auto_ctime|auto_mtime)$/;

        my $related_rs;
        if ($obj && grep {$column eq $_} $resultset->result_source->relationships) {
            $related_rs = $resultset->related_resultset($column);
            if ($related_rs) {
                my $link;
                $link = "/dbedit/" . $related_rs->result_source->name . "/" . $field->{value};
                if ($link) {
                    $field->{comment} = "<a href=\"$link\">" . $field->{value} . "</a>";
                }
            }
        }

        $form->field(%$field);
    }

    # was the form submitted?
    if ($form->submitted && $form->validate) {
        for my $clmn ($src->columns) {
            next unless $clmn;
            next if $clmn =~ /auto/ && !$obj;
            next if grep {$clmn eq $_ && !$form->field($clmn)} $src->primary_columns;
            $request{$clmn} = ($src->column_info($clmn)->{is_nullable} && $form->field($clmn) eq "") ? undef : $form->field($clmn);
        }
        if ($obj) {
            $obj->update(\%request);
            $c->stash->{updated} = 1;
        } else {
            eval {$obj = BST::create($c->stash->{source}, \%request)};
            if ($@) {
                $c->stash->{errortext} = $@;
            } else {
                $obj->save();
                return $c->response->redirect( "/dbedit/" . $src->name . "/" . $obj->id );
            }
        }
    }

    $form->method('POST');
    $c->stash->{name} = $src->name;
    $c->stash->{pkvalue} = $pkvalue;
    $c->stash->{template} = "dbedit/edit.tt";

}


=head1 AUTHOR

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
