#!/usr/bin/bash
#SBATCH -p short --mem 8gb
module load hmmer/3
INSEQ=gene_seqs
GFF=gff3_only

OUTPEP=rep_seqs.pep
IN=representative_sequences.ffn
INPEP=All_pangenome_annotated.pep

if [ ! -s $INPEP ]; then
    cat ../../../pep/*.proteins.fa > $INPEP
fi

if [ ! -f $INPEP.ssi ]; then
    esl-sfetch --index $INPEP
fi

unlink $OUTPEP

grep "^>" $IN \
    | perl -p -e 's/>([^;]+);representative_genome=([^;]+);locus_tag=([^;]+);.+number_genomes=(\d+)/$1\t$2\t$3\t$4/' \
    | while read GNAME STRAIN LOCUS NUM
do
#    CDS=$INSEQ/$STRAIN.cds
#    PEP=$INSEQ/$STRAIN.pep	
#    if [ ! -f $PEP.ssi ]; then
#	esl-sfetch --index $PEP 1>&2;
#    fi
#
#    if [ ! -f $CDS.ssi ]; then
#	esl-sfetch --index $CDS 1>&2;
#    fi
    #	lookup=$(grep "$LOCUS" $GFF/$STRAIN.map_ids.tsv | cut -f1)
    grep $LOCUS $GFF/$STRAIN.map_ids.tsv | while read NEWID OLDID
    do
#	echo "newid is $NEWID for $OLDID" 1>&2; # echo to stderr
	esl-sfetch $INPEP $NEWID | perl -p -e "s/>(\S+).+/>\$1 $OLDID $GNAME/" | perl -p -e 's/\*$//' >> $OUTPEP
    done

done

# this trims trailing stop codons but if there is a frameshift you need to do something to fix the files before running iprscan
