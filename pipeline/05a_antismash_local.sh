#!/bin/bash
#SBATCH --nodes 1 --ntasks 24 --mem 96G --out logs/antismash.%a.log -J antismash

module load antismash
module unload perl
source activate antismash
which perl

CENTER=UCR
CPU=1
if [ ! -z $SLURM_CPUS_ON_NODE ]; then
    CPU=$SLURM_CPUS_ON_NODE
fi
OUTDIR=annotate
SAMPFILE=samples.csv
N=${SLURM_ARRAY_TASK_ID}
if [ ! $N ]; then
    N=$1
    if [ ! $N ]; then
        echo "need to provide a number by --array or cmdline"
        exit
    fi
fi
MAX=`wc -l $SAMPFILE | awk '{print $1}'`

if [ $N -gt $MAX ]; then
    echo "$N is too big, only $MAX lines in $SAMPFILE"
    exit
fi
IFS=,
tail -n +2 $SAMPFILE | sed -n ${N}p | while read ProjID JGISample JGIProjName JGIBarcode SubPhyla Species Strain Note
do
	name=$(echo "$Species" | perl -p -e 'chomp; s/\s+/_/g; ')
 	species=$(echo "$Species" | perl -p -e "s/$Strain//")


	if [ ! -d $OUTDIR/$name ]; then
		echo "No annotation dir for ${name}"
		exit
 	fi
	mkdir -p $OUTDIR/$name/annotate_misc
	antismash --taxon fungi --outputfolder $OUTDIR/$name/annotate_misc/antismash \
	    --asf --full-hmmer --cassis --clusterblast --smcogs --subclusterblast --knownclusterblast -c $CPU \
	    $OUTDIR/$name/predict_results/*.gbk
done
