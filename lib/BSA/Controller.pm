package BSA::Controller;

use strict;

use CGI::FormBuilder;
use Catalyst::Controller::FormBuilder;

use base qw/Catalyst::Controller::FormBuilder/;

use BST::Config;


__PACKAGE__->config(
    'Controller::FormBuilder' => {
        new => {
#            method     => 'post',
            stylesheet => 1,
            debug => BST::config("formbuilder_debug") || 0,
            lang => 'en_US',
            smartness => 1,
            #keepextras => 0,
            #sticky => 0,
	},
        form_path     => [ BSA->path_to('templates', 'forms') ],
    },
);


1;
