#!/usr/bin/perl

use strict;
use warnings;

use FindBin qw[ $Bin ];
use lib "$Bin/../lib";

use BST::Config;
use File::Path;
use Image::Imlib2;

my $hConfig = BST::configuration;
mkpath([$hConfig->{pdf_images_dir}, $hConfig->{pdf_files_dir}]);

my $itemID = $ARGV[0];

my $dir = "$hConfig->{pdf_images_dir}/$itemID";
mkpath([$dir]);
chdir $dir or die "Can't chdir to $dir: $!";

system("rm *");
# TODO: use package_item's file_path() method to get path
system("pdftk $hConfig->{pdf_files_dir}/$itemID.pdf burst output '%04d.pdf'");

generate();

sub generate { # former image_generator.pl
    my $dir = shift || './'; $dir =~ /\/$/ or $dir .= '/';

    opendir DIR, $dir or die $!;
    open PIPE, "|inkscape --shell" or die $!;

    foreach (grep { /\.pdf$/ } readdir DIR) {
        printf PIPE qq~-z -b "#ffffff" -d 90 -e %s%d.png %s%s\n~, $dir, $_ + 0, $dir, $_;
    }

    closedir DIR;

    print PIPE "quit\n";
    close PIPE;

    opendir DIR, $dir or die $!;

    foreach (grep { /\.png$/ } readdir DIR) {
        my $img = Image::Imlib2->load($dir . ($_ + 0) . ".png");
        $img = $img->create_scaled_image(193, 0);
        $img->save($dir . ($_ + 0) . "t.png");
    }

    closedir DIR;
}
