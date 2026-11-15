#!/bin/bash


cd $(dirname $0)
cdir=$(pwd)
cd ..

PDF_IMAGES_DIR="$cdir/../pdf_images/"
PDF_FILES_DIR="$cdir/../pdf_files/"
PDF_ANNOTATED_DIR="$cdir/../pdf_annotated/"

rm "$PDF_ANNOTATED_DIR/$1.pdf"

mdir=$(python export_svg.py $1)
cd $mdir

act=$(cat active)

i=1
while (( i <= ${#act} ))
do
   char=$(expr substr "$act" $i 1)
   if [ $char = '1' ]; then     
       fpdf="`printf '%04d' $i`.pdf"
       cp "${PDF_IMAGES_DIR}${1}/${fpdf}" ./$fpdf
       
       fsvg="${i}.svg"
       if [ -f $fsvg ]; then
	   fm="${i}m.pdf"
	   inkscape -d 90 -f $fsvg -y 0.0 -A $fm
	   pdftk $fpdf stamp $fm output tmp.pdf
	   mv tmp.pdf $fpdf
	   rm $fsvg $fm
       fi
   fi
   (( i += 1 ))
done

pdftk *.pdf cat output $1.pdf

mv $1.pdf "$PDF_ANNOTATED_DIR"
cd "$cdir"
rm -r $mdir

echo "$PDF_ANNOTATED_DIR/$1.pdf"
