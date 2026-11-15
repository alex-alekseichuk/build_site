package Catalyst::Plugin::EmailErrors;

use 5.008001;

use strict;
use warnings;

use HTML::Entities;
use NEXT;
use MIME::Lite;
use Data::Dumper;
use BST::Logger;
use BST::Email;

sub finalize_error {
    my $c = shift;

    my ($message, $email, $mailer);
    # enforce the default Dumper params
    $Data::Dumper::Indent = 1;
    $Data::Dumper::Pad    = '';

    $message = join qq{\n}, map { $_ } @{ $c->error };

    $message .= "\n\nERROR: " . $@ if $@;
    $message .= "\n\nSESSION_ID: " . $c->sessionid;
    if (my $u = $c->user) {
        $message .= "\n\nUSER LOGIN: " . $u->login_id . " PASSW: " . $u->user_password . " (id: $u)";
    }
    $message .= "\n\nREQ METHOD: " . $c->req->method;
    $message .= "\n\nREQ PARAMS: " . Dumper($c->req->params);

    for my $frame ( @{$c->_stacktrace} ) {

        if ( $frame->{file} =~ /../ ) {
            $frame->{file} =~ s{script/../}{};
        }

        my $pkg  = $frame->{pkg};
        my $line = $frame->{line};
        my $file = $frame->{file};

        my $code_preview = BST::Logger::print_context(
            $frame->{file},
            $frame->{line},
            $c->config->{stacktrace}->{context}
        );

        $message .= qq{\nPackage: $pkg Line: $line File: $file\n\n$code_preview};
    }

    $message .= "\n\nSESSION:\n" . Dumper($c->session);
    $message .= "\n\nSTASH:\n" . Dumper($c->stash);

    my $msg = MIME::Lite->new(
        From        => BST::config("email_errors")->{from},
        To          => BST::config("email_errors")->{to},
        Subject     => 'BuildSite error! ' . $c->req->uri->as_string,
        Type        => "multipart/mixed",
    );

    $msg->attach(
        Type     => 'TEXT',
        Data     => $message,
    );

    BST::Email->send($msg);
    
    my $template = BST::config("email_errors")->{error_template};
    if ( not $template ) {
        $c->NEXT::finalize_error;
    } else {
        $c->res->status(BST::config("email_errors")->{response_status});
        $c->res->body($c->view('TT::Default')->render($c, $template));
    }
}

1;
