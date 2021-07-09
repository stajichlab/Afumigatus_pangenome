#!/usr/bin/bash
#SBATCH -p short --out logs/make_gff3.log

for file in input/*.fa; 
do 
	b=$(basename $file .scaffolds.fa); 
	python scripts/make_gff_seqregion_header.py $file > gff/$b.gff;
	grep -v "^##gff" ../GFF/$b.gff3 >> gff/$b.gff
	echo "##FASTA" >> gff/$b.gff
	cat $file >> gff/$b.gff
done
