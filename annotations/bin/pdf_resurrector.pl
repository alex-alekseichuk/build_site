#!/usr/bin/perl

use strict;
use warnings;

use File::Copy;
use File::Path;
use FindBin qw[ $Bin ];
#use Data::Dumper;

my $PDF_IMAGES_DIR    = "$Bin/../pdf_images";
my $PDF_ANNOTATED_DIR = "$Bin/../pdf_annotated";

my $fileID = $ARGV[0];
resurrect($fileID);

sub resurrect {
    my($fileID) = @_;
    chdir $Bin or die "Can't chdir to $Bin: $!";
    unlink "$PDF_ANNOTATED_DIR/$fileID.pdf" or warn "Can't unlink $PDF_ANNOTATED_DIR/$fileID.pdf: $!";
    my $dir = `python ../export_svg.py $fileID`;
    chomp $dir;
    chdir $dir or die "Can't chdir to $dir: $!";
    open my $fh, '<', 'active' or die "Can't open 'active': $!";
    my @flags = split //, <$fh>;

    for (my $i = 0; $i < @flags; $i++) {
        $flags[$i] || next;
        my $fpdf = sprintf '%04d.pdf', $i+1;
        my $fsvg = sprintf "%d.svg", $i+1;
        print "$fsvg\n";
        copy("$PDF_IMAGES_DIR/$fileID/$fpdf", $fpdf) or warn "Copy failed ($PDF_IMAGES_DIR/$fileID/$fpdf => $fpdf): $!";

        if (-f $fsvg) {
            my $fm = sprintf "%dm.pdf", $i+1;
            system("inkscape -d 90 -f $fsvg -y 0.0 -A $fm");
            system("pdftk $fpdf stamp $fm output tmp.pdf");
            move("tmp.pdf", $fpdf) or warn "Move failed: $!";
            unlink($fsvg, $fm);
        }
    }
    system("pdftk *.pdf cat output $fileID.pdf");
    move("$fileID.pdf", $PDF_ANNOTATED_DIR) or warn "Move failed: $!";
    chdir $Bin or die "Can't chdir to $Bin: $!";
    rmtree($dir);
    print "$PDF_ANNOTATED_DIR/$fileID.pdf\n";
    return 1;
}
