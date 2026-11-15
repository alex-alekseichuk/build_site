#!/usr/bin/perl

use strict;
use Image::Imlib2;

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
