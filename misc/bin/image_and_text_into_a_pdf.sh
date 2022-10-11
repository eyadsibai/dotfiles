#!/bin/bash

#Copyright Kris Occhipinti
#Feb 23th 2018
#https://filmsbykris.com
# Licensed under the AGPLv3 https://www.gnu.org/licenses/agpl-3.0.txt
#Finds text in an image and puts
#both the image and the text into a PDF file

#requirements
#apt-get install xpdf tesseract enscript ghostscript poppler-utils

img="$1"
base="$(echo "$img"|cut -d\. -f1)"

echo "Working with $base..."

#image to pdf
convert "$img" "${base}_1.pdf"

#find text in img
tesseract "$img" -|sed '/^\s*$/d' > "$base.txt"
#pandoc "$base.txt" -o "${base}_2.pdf"
enscript -p "${base}.ps" "${base}.txt"
ps2pdf "${base}.ps" "${base}_2.pdf"

#create final PDF
pdfunite "${base}_1.pdf" "${base}_2.pdf" "${base}.pdf"


#clean up
rm "${base}.ps" "${base}.txt" "${base}_1.pdf" "${base}_2.pdf"

#display output
xpdf "${base}.pdf"