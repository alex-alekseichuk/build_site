#!/usr/bin/perl
#
# use:
#  $ perl bin/make-thumbnail.pl  /path/to/doc.pdf /path/to/thumb.jpg
# 

use strict;
#use Image::Magick;
use Image::Magick::Thumbnail::PDF;
use Data::Dumper;

my $pdf   = shift || die;
my $thumb = shift || die;
my $size  = shift || die;

#        my $src = new Image::Magick;
#        my $err = $src->Read($pdf);#        warn("92 ++++ $err") if $err;
#        print STDERR "pdf: $pdf\n";
#   print STDERR "err: $err\n";
#   print STDERR Dumper( $src );
#print STDERR "\n";
#if ($src->[0]) {
#   print STDERR "image: ", $src->[0], "\n";
#}

use Image::Magick::Thumbnail::PDF qw(create_thumbnail);
    if (-f $pdf) {

        # create thumb.
        print STDERR "create_thumbnail: ", create_thumbnail(
            $pdf,
            $thumb,
            1,
            {
                #restriction => BST::config("toc_thumb_size"),
                restriction => $size,
                frame => 0,
                normalize => 0
            },
        ), "\n";

    }


