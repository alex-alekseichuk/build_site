package GUPE::Debug::Log;
use strict;

use Data::Dumper;
use Carp qw(confess);

use vars qw(@ISA @EXPORT @EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT = qw(debug set_debug_level 
             set_debug_string get_debug_string unset_debug_string
             set_info set_log_file
             is_debug testonly is_testonly info warning unimplemented Dumper DebugDumper gupe_die);
@EXPORT_OK = qw(confess);

our $LOGFH = *STDERR;

our $LOGFILENAME;


sub set_log_file {
    my ($f) = @_;
    close($LOGFH) if $LOGFH && $LOGFILENAME;
    $LOGFILENAME = undef;
    if ( open LOGFILE, ">>:utf8", $f) {
	$LOGFILENAME = $f;
	$LOGFH = *LOGFILE;
	print $LOGFH "\n" , "-" x 60, "\n";
    } else {
	warn "can't open log file $f: $!";
    }
}

set_log_file($ENV{GUPEDEBUFILE}) if $ENV{GUPEDEBUFILE};

our $DEBUG = $ENV{GUPEDEBUG};
use vars qw( $DEBUGSTRING );
# sub confess {Carp::confess(@_);}

# confess (with a stack trace) if we are not going to be caught.
$SIG{__DIE__} = sub {
    die @_ if $^S; 
    die @_ if "@_" =~ m/__DIE__/;
    require Carp; 
    my $mess = ref($_[0]) ? Dumper([@_]) : join('',@_);
    Carp::confess("[GUPE::Debug::Log::__DIE__] $mess");
};

use sigtrap qw(INT QUIT TERM);

our $TESTONLY;

sub set_debug_level {
    $DEBUG = shift;
}

sub is_debug {return $DEBUG;}

sub testonly {
    print $LOGFH 'TESTONLY: ', @_, "\n";
}
sub is_testonly {
    $TESTONLY = shift if @_;
    return $TESTONLY;
}

sub _where {
    my ($steps_up) = @_;
    $steps_up ||= 2;
    my ($package, $filename, $line, $subroutine) = caller($steps_up);
    # might be like "GUPE::IO::IOUtil::__ANON__"
    return "[$subroutine] ";
}

sub debug {
    my $where = _where();
    my $undef = '';
    foreach ( @_ ) {
      if ( not defined $_ ) { Carp::cluck( "undefined value" ); $undef = '*'; }
    }
    my $what  = ensure_eol(@_);
    print $LOGFH "DEBUG$undef: ", $where, $what   if $DEBUG;
    if ( defined $DEBUGSTRING ) {
        $DEBUGSTRING .= join( '', $where, $undef, $what );
    }
}

sub get_debug_string()   { return $DEBUGSTRING; }
sub set_debug_string($)  { $DEBUGSTRING = $_[0]; }
sub unset_debug_string() { undef $DEBUGSTRING; }

sub DebugDumper {
    return $DEBUG ? Dumper(@_) : '';
}
sub testme {
    my $l = GUPE::Debug::Log->new("/tmp/log_testme.txt");
    $l->logline("testing", "123");
    $l->close();
}

our $PRINT_WARNING = 1;
our $PRINT_INFO = 0;
our $PRINT_UNIMPLEMENTED = 1;

use vars qw($WARN_HANDLER);

use Carp qw(cluck);

sub set_info {
    my ($should_print) = @_;
    $PRINT_INFO = $should_print;
}

sub ensure_eol {
    my $mess = join('',@_);
    $mess .= "\n" unless $mess =~ m/\n$/; 
    return $mess;
}

sub info {
    print $LOGFH 'INFO: ', _where(), ensure_eol(@_) if $PRINT_INFO;
    if ( defined $DEBUGSTRING ) {
        $DEBUGSTRING .= join( '',  'INFO: ', _where, ensure_eol(@_) );
    }
}

sub warning {
    print $LOGFH 'WARNING: ', _where(), ensure_eol(@_) if $PRINT_WARNING;
    if ( defined $DEBUGSTRING ) {
        $DEBUGSTRING .= join( '',  'WARNING: ', _where, ensure_eol(@_) );
    }
    &$WARN_HANDLER(@_) if $WARN_HANDLER;
    # cluck("from:");
}

our $WARN_UNIMPLEMENTED = 1;
sub unimplemented {
    print $LOGFH 'UNIMPLEMENTED: ', _where(), ensure_eol(@_) if $PRINT_UNIMPLEMENTED;
}

use FileHandle;

sub new {
    my($classname, $destfile) = @_;
    die "no destfile" unless $destfile;
    bless {destfile => $destfile}, $classname;
}
sub maybeinit {
    my ($log) = @_;
    return $log->{fh} if $log->{fh};

    my $destfile = $log->{destfile};
    $log->{fh} = new FileHandle(">>$destfile");
    die "can't open $destfile: $!" unless $log->{fh};
    return $log->{fh};
}
sub logline {
    my ($log, $mess, @rest) = @_;
    my $fh = $log->maybeinit();
    my $now = scalar(localtime());
    print $fh $now, ": ";
    print $fh $mess, @rest, "\n";
}
sub close {
    my ($log) = @_;
    $log->{fh}->close() if $log->{fh};
}

# http://perlmonks.thepen.com/51097.html
# use Carp qw(confess);
sub CallStack {
    my ($steps_up) = @_;
    local $@;
    eval { Carp::confess( '' ) };
    my @stack = split m/\n/, $@;
    shift @stack for 1..$steps_up; # Cover our tracks.
    return wantarray ? @stack : join "\n", @stack;
}

sub gupe_die {
    my ($code, $subcode, $text, $details) = @_;
    require GUPE::Error;
    my $error_obj = new GUPE::Error({Code => $code, Subcode => $subcode, Text => $text, Details => $details});
    die $error_obj;
}

1;
