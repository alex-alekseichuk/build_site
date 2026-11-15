#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use Data::Dumper;

my $DJANGO_DIR  = qx[ python -c "import django, os; print os.path.dirname(django.__file__)" ];
chomp $DJANGO_DIR;

my $PATCHES_DIR = do { (my $dir = $FindBin::Bin) =~ s'/[^/]+$''; "$dir/patches" };
-d $PATCHES_DIR or die "Directory $PATCHES_DIR does not exist";

my $STATUS_FILE  = "$PATCHES_DIR/last_applied";
my $PATCHFILE_RE = qr/\d{4}_\w+\.diff/;

{
    open my $fh, '>>', "$PATCHES_DIR/logfile" or die "Can't open $PATCHES_DIR/logfile: $!\n";
    sub tee ($) {
        print $fh $_[0] or die "Can't print to logfile: $!\n";
        print $_[0];
    }
}

main();

sub main {
    chdir $DJANGO_DIR or die "Can't cd to $DJANGO_DIR: $!\n";

    my $aFiles = getPatchesList();
    tee localtime()."  ".@$aFiles." patches to be applied\n";
    for my $file (@$aFiles) {
        applyPatch($file);
    }
    return 1;
}

sub applyPatch {
    my($file) = @_;
    my $command = "patch -p0 < $PATCHES_DIR/$file 2>&1";
    tee localtime()."  Processing file $file, cmd='$command'\n";

    my $output = qx[$command];
    tee $output;

    updateStatusFile($file);
    return 1;
}

sub getPatchesList {
    my $last = getLastAppliedPatch();

    opendir my $dh, $PATCHES_DIR or die "Can't opendir $PATCHES_DIR: $!\n";
    my @diffs = grep { /^${PATCHFILE_RE}$/ } sort readdir($dh);

    if (defined $last) { # filter patches which are already applied
        @diffs = grep { $_ gt $last } @diffs;
    }
    return \@diffs;
}

sub getLastAppliedPatch {
    my $last;

    if (-e $STATUS_FILE) {
        open my $fh, '<', $STATUS_FILE or die "Can't open $STATUS_FILE: $!";
        my $text = do { local $/; <$fh> };
        ($last) = $text =~ /(${PATCHFILE_RE})/;
    }
    return $last;
}

sub updateStatusFile {
    my($file) = @_;
    open my $fh, '>', $STATUS_FILE or die "Can't open $STATUS_FILE: $!";
    print $fh "last applied patch: $file\n";

    return 1;
}





