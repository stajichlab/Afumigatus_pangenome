#!/bin/bash -l
#SBATCH -c 32 -N 1 -n 1 --mem 96G 
#SBATCH --time 72:00:00 --out logs/iprscan.%a.log

module load funannotate
module load iprscan
CPU=1
if [ ! -z $SLURM_CPUS_ON_NODE ]; then
    CPU=$SLURM_CPUS_ON_NODE
fi
OUTDIR=annotate
SAMPLEFILE=samples.csv
N=${SLURM_ARRAY_TASK_ID}
if [ -z $N ]; then
    N=$1
    if [ -z $N ]; then
        echo "need to provide a number by --array or cmdline"
        exit
    fi
fi
MAX=$(wc -l $SAMPLEFILE | awk '{print $1}')

if [ $N -gt $MAX ]; then
    echo "$N is too big, only $MAX lines in $SAMPLEFILE"
    exit
fi
IFS=,
tail -n +2 $SAMPLEFILE | sed -n ${N}p | while read SampID FileBase Strain Patient
do
    name=$Strain
    if [ ! -d $OUTDIR/$name ]; then
	echo "No annotation dir for ${name}"
	exit
    fi
    mkdir -p $OUTDIR/$name/annotate_misc
    XML=$OUTDIR/$name/annotate_misc/iprscan.xml
    IPRPATH=$(which interproscan.sh)
    if [ ! -f $XML ]; then
 	echo "iprscan -i $OUTDIR/$name"
	funannotate iprscan -i $OUTDIR/$name -o $XML -m local -c $CPU --iprscan_path $IPRPATH
    fi
done
