package GUPE::TaintUtils;
use strict;

=head1

Untaint.pm has some intermittent bug in not actually
untainting; some problem with $1. Probably a core
Perl bug, not its fault.

Also Untaint has the unfortunate effect of demanding
to be run under -T, because it does this:
  use Taint qw(any_tainted)
And in that case Taint requires that tainting exists,
or it dies.a
This is not ideal for library code, which does not
know how it will ultimately be run.

There are a bunch of modules entitled CGI::Untaint::*,
which typically encapsulate a single regexp per data type.

See also Apache::ModPerl::Util::untaint()
=cut

our $UNTAINT_RES =
{
    path_with_dollar => '[\$\w\_\.\:/]+',
    path => '[\w\_\.\:/]+',
    package => '[\w\_\.\:/]+',
    filename => '[\w\.\_\:]+',
    integer => '[0-9]+',
    # ".2" or "3" or "3.7" - from perl cookbook 2.1
    decimal => '-?(?:\d+(?:\.\d*)?|\.\d+)',
    dbi_uri => '[\w\_\.\:/;=]+',
    any => '.*',
};

sub set_taint_re {
    my ($name, $re) = @_;
    $UNTAINT_RES->{$name} = $re;
}

sub untaint_named {
    my ($what, $tainted) = @_;
    my $re = $UNTAINT_RES->{$what} || die "no regexp to untaint a '$what' with"; 
    return untaint_re($re, $tainted, $what);
}
sub untaint_re {
    my ($re, $tainted, $what) = @_;
    my ($untainted) = ($tainted =~ m/^($re)$/);
    die "can't untaint a '$what' string with value '$tainted'\n" unless defined($untainted);
    return $untainted;
}

sub untaint_any {return untaint_named('any', @_);}
sub untaint_dbi_uri {return untaint_named('dbi_uri', @_);}
sub untaint_dollar_path {return untaint_named('path_with_dollar', @_);}
sub untaint_path {return untaint_named('path', @_);}
sub untaint_package {return untaint_named('package', @_);}
sub untaint_integer {return untaint_named('integer', @_);}
sub untaint_decimal {return untaint_named('decimal', @_);}
sub untaint_filename {
    my ($tainted) = @_;
    die "tainted filename '$tainted' contains / or .." if $tainted =~ m,/, || $tainted =~ m,\.\.,;
    return untaint_named('filename', $tainted);
}

sub testme {
    eval {untaint_path('\\ ')};
    if ($@) {print "expected error: $@";}
    else {die "did not get an exception from bad path";}

    untaint_path('/');
}

1;
