#!/usr/bin/bash -l
#SBATCH -p short -N 1 -n 2 --mem 2gb

IN=gff
OUT=gene_bed
mkdir -p $OUT
for f in $(ls $IN/*.gff)
do
  CONV=$OUT/$(basename $f .gff).bed
  # will still have tRNA genes...
  grep -P "\tgene\t" $f | cut -f1,4,5,9 | perl -p -e 's/ID=//; s/;$//' > $CONV
done
