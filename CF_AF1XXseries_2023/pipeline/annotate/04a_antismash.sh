#!/bin/bash -l
#SBATCH -N 1 -n 1 -c 6 --mem 24G --out logs/antismash.%a.log -J antismash

module load antismash
CPU=1
if [ ! -z $SLURM_CPUS_ON_NODE ]; then
    CPU=$SLURM_CPUS_ON_NODE
fi
OUTDIR=annotate
SAMPLEFILE=samples.csv
N=${SLURM_ARRAY_TASK_ID}
if [ ! $N ]; then
    N=$1
    if [ ! $N ]; then
        echo "need to provide a number by --array or cmdline"
        exit
    fi
fi
MAX=`wc -l $SAMPLEFILE | awk '{print $1}'`

if [ $N -gt $MAX ]; then
    echo "$N is too big, only $MAX lines in $SAMPLEFILE"
    exit
fi

IFS=,
INPUTFOLDER=predict_results
species='Aspergillus fumigatus'
tail -n +2 $SAMPLEFILE | sed -n ${N}p | while read SampID FileBase Strain Patient
do
    name=$Strain
    
    if [ ! -d $OUTDIR/$name ]; then
	echo "No annotation dir for ${name}"
	exit
    fi
    echo "processing $OUTDIR/$name"
    if [[ ! -d $OUTDIR/$name/antismash_local && ! -s $OUTDIR/$name/antismash_local/index.html ]]; then
	time antismash --taxon fungi --output-dir $OUTDIR/$name/antismash_local \
	     --genefinding-tool none --tigrfam --fullhmmer --clusterhmmer --cb-general --cb-subclusters --cb-knownclusters \
	     --pfam2go -c $CPU --skip-zip-file --output-basename $name $OUTDIR/$name/$INPUTFOLDER/*.gbk
    fi
done
