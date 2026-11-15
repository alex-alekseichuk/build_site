package BSA::Controller::Ext;

use strict;
use warnings;
use parent 'BSA::Controller';
use Data::Dumper;
use BST::PackageToc;
use BST::PackageToc::Types;
use BST::FolderItem;
use BST qw(error);
use BST::SettingItem;
use BST::Config;
use POSIX qw(ceil);

=head1 NAME

BSA::Controller::Ext - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index 

=cut
sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
    return $self->_error404($c);
}

sub message :Local :Args(1) {
    my ($self, $c) = @_;

    my $message_ext_id = $c->req->args->[0];
    my $message = BST::Message->load({message_ext_id => $message_ext_id});
    return $self->_error404($c) unless $message;

    my $package = $message->package;
    if ($package) {
        $c->stash->{css} = [{ 
            url => "/css/ext.css" 
        }, {
            url => "/css/ext.print.css",
            media => "print"
        }];

        if ($package->package_toc_type) {
            my $type = $BST::PackageToc::Types::TYPES{$package->package_toc_type};
            my $toc = $package->package_toc_data;
            my @table_columns = $package->toc_pdf_columns;
            $c->stash->{package} = $package;
            $c->stash->{toc} = $toc;
            $c->stash->{type} = $type;
            my @type_column1 = grep {$_->{name} ne 'title' && $_->{name} ne 'footer_comment' && ($_->{required} || $package->package_toc_data->{meta}->{$_->{name}})} @{$type->{meta_fields}};
            my @type_column2 = splice (@type_column1, ceil (($#type_column1 + 1) / 2), ceil ($#type_column1 / 2));
            $c->stash->{type_column1} = \@type_column1;
            $c->stash->{type_column2} = \@type_column2;
            $c->stash->{table_columns} = \@table_columns;

            my $user = BST::User->load({user_id => $package->creator_user->user_id});
            if ($user) {
                    if ($user->settings->list->{logo_file}) {
                        $c->stash->{url_logo} = "/ext/logo/$message_ext_id/";
                    }
                    #if ($user->primary_location->account->settings->list->{default_submittal_footer_comment}) {
                    #    $c->stash->{footer_note} = $user->primary_location->account->settings->list->{default_submittal_footer_comment};
                    #}
            }

            $c->stash->{template} = "toc.tt";
            $c->stash->{ext} = 1;
            $c->forward( $c->view('TT::UnAuth') );
        } else {

            $c->stash->{package} = $package;

            $c->stash->{message} = $message;

            $c->stash->{template} = "ext/package.tt";
            $c->forward( $c->view('TT::UnAuth') );
        }
    } else {
        return $self->_error404($c);
    }
}

sub logo :Local :Args(1) {
    my ($self, $c) = @_;
    my ($message_ext_id) = @{ $c->req->args };

    my $message = BST::Message->load({message_ext_id => $message_ext_id});
    return $self->_error404($c) unless $message;

    my $package = $message->package;
    return $self->_error404($c) unless ($package);

    my $user = BST::User->load({user_id => $package->creator_user->user_id});
    if ($user) {
        if ($user->settings->list->{logo_file}) {
            $c->serve_static_file(BST::config('settings_path') . '/' . $user->settings->list->{logo_file});
        }
    }
}

sub file :Local :Args(2) {
    my ($self, $c) = @_;
    my ($message_ext_id, $package_item_id) = @{ $c->req->args };

    my $message = BST::Message->load({message_ext_id => $message_ext_id});
    return $self->_error404($c) unless $message;

    my $package = $message->package;
    return $self->_error404($c) unless ($package);

    my $package_item = $package->find_item($package_item_id);
    my $file;
    if ($package_item) {
        $file = BST::FolderItem->load($package_item->file_id->file_id);
    }

    return $self->_error404($c) unless ($file);

    my $filename = $file->file_title . '.' . $file->file_extension;
    $c->res->header('Content-Disposition', qq[attachment; filename="$filename"]);
    $c->serve_static_file($file->local_file_path);

}


sub _error404 : Private {
    my ( $self, $c ) = @_;
    $c->stash->{template} = "404.tt";
    $c->res->status(404);
    $c->forward( $c->view('TT::UnAuth') );
}


=head1 AUTHOR

,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
