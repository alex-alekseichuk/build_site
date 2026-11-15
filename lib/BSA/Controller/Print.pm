package BSA::Controller::Print;

use strict;
use warnings;
#use base 'BSA::Controller';
use base 'Catalyst::Controller::FormBuilder';

use Data::Dumper;

use JSON;
use BST qw(error);
use BST::User;
use BST::Location;
use BST::Folder;
use BST::RootFolder;
use BST::PackageToc;
use BST::PackageToc::Types;


sub default : Local {
    my ( $self, $c ) = @_;

    my $file = BST::File->load({ file_id => $c->req->param('package_id') });
    $c->stash->{template} = 'print/default.tt';

    if ($file) {
        return unless $c->must_read($file);
        $c->stash->{item} = $file;
    }

    BSA::Controller::Folders::_fill_path($c, $file);
}

1;
