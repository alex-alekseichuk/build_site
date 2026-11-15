#!/bin/bash

cd "$(dirname $0)"
cdir=$(pwd)
cd ..

PDF_IMAGES_DIR="$cdir/../pdf_images/"
PDF_FILES_DIR="$cdir/../pdf_files/"
PDF_ANNOTATED_DIR="$cdir/../pdf_annotated/"

dir="$PDF_IMAGES_DIR/$1"
mkdir "$dir"
cd $dir
rm *

pdftk "$PDF_FILES_DIR/$1.pdf" burst output "%04d.pdf"

perl $cdir/image_generator.pl

#for f in *.pdf
#do
#    t="${f%.pdf}"
#    t=`expr $t + 0`
#    inkscape -z -b "#ffffff" -d 90 -e "$t.png" $f
#    $cdir/thumbnail.pl $t.png ${t}t.png 193
#done


cd ..
