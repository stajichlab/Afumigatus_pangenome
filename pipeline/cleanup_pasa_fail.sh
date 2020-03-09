#!/bin/bash

N=${SLURM_ARRAY_TASK_ID}

if [ -z $N ]; then
    N=$1
    if [ ! $N ]; then
        echo "need to provide a number by --array or cmdline"
        exit
    fi
fi
IFS=,
INDIR=annotate
SAMPLEFILE=samples.csv
tail -n +2 $SAMPLEFILE | sed -n ${N}p | while read BASE LOCUS
do
 if [ -d $INDIR/$BASE/training/pasa ]; then
 	if [[ ! -s $INDIR/$BASE/training/pasa/pasa-transdecoder.log || ! -s $INDIR/$BASE/training/pasa/pasa.gene2transcripts.tsv ]]; then
		rm -rf $INDIR/$BASE/training/pasa
		echo "rm -rf $INDIR/$BASE/training/pasa"
	fi
 fi
 if [[ -d $INDIR/$BASE/training/getBestModel && ! -s $INDIR/$BASE/training/getBestModel/kallisto/abundance.tsv ]]; then
	 echo "rm $INDIR/$BASE/training/getBestModel"
	 rm -rf $INDIR/$BASE/training/getBestModel
 fi
done
