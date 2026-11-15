package BST::Logger;

use strict;
use warnings;

use Data::Dumper;
use Log::Dispatch;
use Log::Dispatch::File;
use BST::Tools qw(date_now);
use Devel::StackTrace;
use MIME::Lite;
use BST::Email;

use base qw/Class::Singleton/;

my $config = BST::config('logger') || {};
sub CONFIG {
    die "Install log config (now it is $config)\n"
        unless $config =~ /^HASH/;

    return $config;
}

our @loglevels = qw/debug info notice warning error critical alert emergency/;
our @catpkgs   = keys   %{ CONFIG->{categories} };
our @catnames  = ('common', values %{ CONFIG->{categories} });

# execute on object create
sub _new_instance {
    my $self = bless {}, shift;

    my $logger =  new Log::Dispatch;
    $self->{logger} = $logger;

    # init appenders
    foreach (@catnames) {
        $logger->add(Log::Dispatch::File->new(
                      name      => $_,
                      min_level => 'debug',
                      filename  => CONFIG->{prefix} .'/'. $_,
                      mode      => CONFIG->{mode},
                  ));
    }

    return $self;
}

sub log { shift; __PACKAGE__->_log(@_) }

sub _log {
    shift;
    my $params = shift;

    my $self = __PACKAGE__->instance();

    my $name = $params->{name} || '';
    if ( not $name or
        ( $name and not grep /^$name/, @catnames)) {
	# find the most-suitable log for $name

	# get package name of where this was called from
        my $pkg = [caller(1)]->[0];

	# i'm not sure this even works (iku). this needs debugging & rewriting
        my $bestsuitable = shift @{[( sort {length $b <=> length $a} grep {$pkg =~ $_} @catpkgs )]};
        if ($bestsuitable) {
            $params->{name} = CONFIG->{categories}->{$bestsuitable};
        } else { $params->{name} = 'common' }
    }

    # default log level:
    $params->{level} = 'info'
        unless defined $params->{level};

	__PACKAGE__->mail($params) if ($params->{email});

    my $ts = date_now();
    $params->{message} = '[' . $ts . '] ' . $params->{message} . "\n";

    return $self->{logger}->log_to(%$params);
}

sub mail {
	shift; my $params = shift;

    my ($message, $email, $mailer);
    # enforce the default Dumper params
    $Data::Dumper::Indent = 1;
    $Data::Dumper::Pad    = '';

    $message = "LOG LEVEL: " . $params->{level} . " MESSAGE: " . $params->{message};

    $message .= "\n\nERROR: " . $@ if $@;
    $message .= "\n\nSESSION_ID: " . BST->current->{sessionid} if BST->current && BST->current->{sessionid};
    if (my $u = BST->current_user) {
        $message .= "\n\nUSER LOGIN: " . $u->login_id . " PASSW: " . $u->user_password . " (id: $u)";
    }
    $message .= "\n\nREQ METHOD: " . BST->current->{req}->method if BST->current && BST->current->{req};
    $message .= "\n\nREQ PARAMS: " . Dumper(BST->current->{req}->params) if BST->current && BST->current->{req};

	my $trace = Devel::StackTrace->new;

	# skip useless top frames
	$trace->next_frame foreach (1..3);

	while (my $frame = $trace->next_frame) {
        my $file = $frame->filename;
		if ($file =~ /../) {
            $file =~ s{script/../}{};
        }

        my $pkg  = $frame->package;
        my $line = $frame->line;

        my $code_preview = print_context(
            $frame->filename,
            $frame->line,
            3
        );

        $code_preview ||= "";
        $message .= qq{\nPackage: $pkg Line: $line File: $file\n\n$code_preview};
	}

    #$message .= "\n\nSESSION:\n" . Dumper(BST->current->{session}) if BST->current->{session};
    #$message .= "\n\nSTASH:\n" . Dumper(BST->current->{stash}) if BST->current->{stash};

    return unless ref BST::config("email_errors");
    my $msg = MIME::Lite->new(
        From        => BST::config("email_errors")->{from},
        To          => BST::config("email_errors")->{to},
        Subject     => 'BuildSite error! ' . ( BST->current ? BST->current->{req}->uri->as_string : "" ),
        Type        => "multipart/mixed",
    );

    $msg->attach(
        Type     => 'TEXT',
        Data     => $message,
    );

    BST::Email->send($msg);
}


=head error_context()

returns the code which produced the error

=cut
sub error_context {
    my $self = shift;
    my $pkg = shift;

    my $trace = Devel::StackTrace->new;
    while (my $frame = $trace->next_frame) {
        next if $frame->package eq $pkg || $frame->package eq __PACKAGE__;
        my $file = $frame->filename;
        if ($file =~ /../) {
            $file =~ s{script/../}{};
        }

        my $pkg  = $frame->package;
        my $line = $frame->line;

        my $code_preview = $self->print_context(
            $frame->filename,
            $frame->line,
            3
        );
        return sprintf("\n in %s on line %d\n%s\n\n", $frame->filename, $frame->line, $code_preview);
    }
}


sub print_context {
    my $self = shift;
    my ( $file, $linenum, $context ) = @_;

    my $code;
    if ( -f $file ) {
        my $start = $linenum - $context;
        my $end   = $linenum + $context;
        $start = $start < 1 ? 1 : $start;
        if ( my $fh = IO::File->new( $file, 'r' ) ) {
            my $cur_line = 0;
            while ( my $line = <$fh> ) {
                ++$cur_line;
                last if $cur_line > $end;
                next if $cur_line < $start;
                my @tag = $cur_line == $linenum ? ('>>', '') : (q{}, q{});
                $code .= sprintf(
                    '%s%5d: %s%s',
                        $tag[0],
                        $cur_line,
                        $line ? $line : q{},
                        $tag[1],
                );
            }
        }
    }
    return $code;
}

our $AUTOLOAD;
sub AUTOLOAD {
    shift;
    $AUTOLOAD =~ s/^BST::Logger:://;

    if (grep {$_ eq $AUTOLOAD} @loglevels) {
        __PACKAGE__->_log({level => $AUTOLOAD, message => @_});
    } elsif (grep {$_ eq $AUTOLOAD} @catnames) {
        __PACKAGE__->_log({name => $AUTOLOAD, @_});
    } else { die "Unknown method $AUTOLOAD called on __PACKAGE__\n" }
}

sub DESTROY {}

1;
