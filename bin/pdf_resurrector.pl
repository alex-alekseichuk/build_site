#!/usr/bin/perl

use strict;
use warnings;

use FindBin qw[ $Bin ];
use lib "$Bin/../lib";

use BST::Config;
use BST::File;
use BST::Document;
use BST::FileMarkup;
use BST::PackageItem;

use File::Copy;
use File::Path;
use Data::Dumper;
use File::Temp qw[ tempdir ];


main();

sub main {
    my $config = BST::configuration;
    my $package_item_id = $ARGV[0];

    mkpath([$config->{pdf_files_dir}, $config->{pdf_annotated}, $config->{pdf_images_dir}]);
    resurrect($config, $package_item_id);
}

sub resurrect {
    my($config, $package_item_id) = @_;
    my $fileName = "$config->{pdf_annotated}/$package_item_id.pdf";

    unlink $fileName or warn "Can't unlink $fileName: $!";

    chdir $config->{pdf_files_dir} or die "Can't chdir to $config->{pdf_files_dir}: $!";

    #my $dir = `python ../export_svg.py $package_item_id`;
    #chomp $dir;
    my $dir = export_svg( $package_item_id);

    chdir $dir or die "Can't chdir to $dir: $!";
    open my $active_fh, '<', 'active' or die "Can't open 'active': $!";
    my @flags = split //, <$active_fh>;
    close $active_fh;

    open INKSCAPE, "|inkscape --shell" or die $!;
    my(@tmp, %tmp);

    for (my $i = 0; $i < @flags; $i++) {
        $flags[$i] || next;
        my $fpdf = sprintf '%04d.pdf', $i+1;
        my $fsvg = sprintf "%d.svg", $i+1;

        copy("$config->{pdf_images_dir}/$package_item_id/$fpdf", $fpdf)
            or warn "Copy failed ($config->{pdf_images_dir}/$package_item_id/$fpdf => $fpdf): $!";

        if (-f $fsvg) {
            my $fm = sprintf "%dm.pdf", $i+1;
            print INKSCAPE "-d 90 -f $fsvg -y 0.0 -A $fm\n";

            push @tmp, $fsvg, $fm; # delete them afterwards
            $tmp{$fpdf} = $fm;     # run pdftk afterwards
        }
    }
    print INKSCAPE "quit\n";
    close INKSCAPE;

    while (my($fpdf, $fm) = each %tmp) {
        system("pdftk $fpdf stamp $fm output tmp.pdf");
        move("tmp.pdf", $fpdf) or warn "Move failed: $!";
    }
    unlink(@tmp) == @tmp or warn "Unlink @tmp failed: $!";

    system("pdftk *.pdf cat output $package_item_id.pdf");
    move("$package_item_id.pdf", $fileName) or warn "Move failed: $!";

    chdir '..' or die "Can't chdir to ./../: $!";
    rmtree($dir);
    print "$fileName\n";
    return 1;
}

sub export_svg { # former export_svg.py
    my($package_item_id) = @_;
    my $tempdir = tempdir(DIR => '.'); # temporary dir

    my $package_item = BST::PackageItem->load({ package_item_id => $package_item_id });
    my $item_type    = $package_item->item_type;
    my $page_count   = $package_item->page_count;
    my $item_id;

    my $criteria = { package_id => $package_item->package_id };

    if ($item_type eq 'document') {
        $item_id = $package_item->document_id;
        $criteria->{document_id} = $item_id;
    }
    else { # file
        $item_id = $package_item->file_id;
        $criteria->{file_id} = $item_id;
    }

    open my $active_fh, '>', "$tempdir/active" or die "Can't open $tempdir/active: $!";

    for my $page (1..$page_count) {
        $criteria->{page} = $page;
        my($markup) = BST::FileMarkup->search($criteria);
        unless ($markup) {
            print $active_fh 1;
            next;
        }
        print $active_fh $markup->is_active;

        if ($markup->is_active) {
            open my $svg_fh, '>', "$page.svg" or die "Can't open $page.svg: $!";
            print $svg_fh $markup->svg_markup;
        }
    }
    return $tempdir;
}

=pod
import sys
import tempfile
import os
import settings

from django.core.management import setup_environ
setup_environ(settings)

from annotations.models import *

file_id = sys.argv[1]
file = File.objects.get(pk=file_id)
dir = tempfile.mkdtemp()
active = open(os.path.join(dir, 'active'), 'w')
for i in xrange(1, file.num_pages+1):
    try:
        fm = FileMarkup.objects.get(file=file, page=i)
        active.write(str(int(fm.is_active)))
        if fm.is_active:
            f = open(os.path.join(dir, '%s.svg' % i), 'w')
            f.write(fm.svg_markup.encode('utf-8'))
            f.close()
    except FileMarkup.DoesNotExist:
        active.write('1')
active.close()

print dir
=cut
