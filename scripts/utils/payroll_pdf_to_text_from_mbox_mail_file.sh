#!/bin/bash

tmpdir="mboxtmp"
password="password"

rm -fr "$tmpdir"
mkdir $tmpdir 
ripmime -i GNFD -d $tmpdir 

#loop until PDFs are extracted
while [ 1 ];do
  for i in  $tmpdir/textfile*;do 
    ripmime -i $i -d  $tmpdir;
  done
  ls  $tmpdir/*.PDF && break || echo "Continuing Scan..."
done

for p in  $tmpdir/*.PDF;do 
  pdftotext -layout "$p" -upw $password - 
done