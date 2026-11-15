package GUPE::FileUtils;
use strict;
use base 'Exporter';
our @EXPORT_OK = qw(slurp unslurp get_suffix file_mtime gen_integer inc_counterfile);

=head1

Exports a variety of file-related utilities.

=cut

use GUPE::Debug::Log;

sub file_mtime {
    my ($f) = @_;
    my @st = stat($f);
    return @st ? $st[9] : undef;
}

sub slurp {
    my ($f) = @_;
    open my $fh, "<", $f or die "can't read $f: $!";
    local $/ = undef;
    my $s = <$fh>;
    close $fh;
    debug("slurp(", $f, ") read ", length($s));
    return $s;
}

sub unslurp {
    my ($f, $s) = @_;
    open my $fh, ">", $f or die "can't write $f: $!";
    binmode $fh;
    print $fh $s or die "can't print $f: $!";
    close $fh or die "can't close $f: $!";
}

sub get_suffix {
    my ($f) = @_;
    my ($suffix) = ($f =~ m,\.([^/\.]+)$,);
    return $suffix || '';
}

=head1 Other Modules

File::CounterFile

=cut

use IO::File;
use GUPE::TaintUtils;

sub gen_integer {
    my ($tablename, $dir, $missing_hook) = @_;

    my $counterfile = GUPE::TaintUtils::untaint_path($dir . "/$tablename\.counter.txt");
    return inc_file($counterfile, $missing_hook);
}

sub inc_counterfile {
    my ($counterfile, $initvalue) = @_; 

    # if no such file, count values in table, and increment
    my $fh;
    my $count;
    if (! -f $counterfile) {
	$count = ref($initvalue) eq 'CODE' ? &$initvalue() : ($initvalue||0);
        open(FH, "> $counterfile") || die "can't open $counterfile for write: $!";
	    # $fh = IO::File->new($counterfile, "w") || die "can't open $counterfile for write: $!";
        flock(FH, 2) || die "can't get exclusive lock on $counterfile after create: $!";
    }
    else {
	open(FH, "+< $counterfile") || die "can't open $counterfile for read: $!";
        # $fh = IO::File->new($counterfile, "r+") || die "can't open $counterfile for read: $!";
        flock(FH, 2) || die "can't get exclusive lock on $counterfile after open: $!";
        $count = <FH>;
    }
    $count++;
    FH->seek(0,0);
    FH->print("$count");
    FH->close();
    return $count;
}

1;
