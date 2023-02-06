#!/bin/bash -l
#SBATCH -p short -c 48 --nodes 1 --mem 24G --out logs/mask.%a.log

CPU=1
if [ $SLURM_CPUS_ON_NODE ]; then
    CPU=$SLURM_CPUS_ON_NODE
fi

INDIR=genomes
OUTDIR=RepeatMasker_run

LIBRARY=$(realpath lib/Afum95_Fungi_repeats.lib)
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
SPECIES="Aspergillus fumigatus"
# SampID,FileBase,Strain,Patient
tail -n +2 $SAMPLEFILE | sed -n ${N}p | while read SampID FileBase Strain Patient
do
    name=$Strain
    if [ ! -f $INDIR/${name}.sorted.fasta ]; then
	echo "Cannot find $name ($INDIR/${name}.sorted.fasta) in $INDIR - may not have been run yet"
	exit
    fi
    
    if [ ! -s $INDIR/${name}.masked.fasta ]; then
	module load RepeatMasker
	mkdir -p $OUTDIR/${name}
	RepeatMasker -e ncbi -xsmall -s -pa $CPU -lib $LIBRARY -dir $OUTDIR/${name} -gff $INDIR/${name}.sorted.fasta 
	rsync -a $OUTDIR/${name}/${name}.sorted.fasta.masked $INDIR/${name}.masked.fasta
    else
	echo "Skipping ${name} as masked already"
    fi
done
