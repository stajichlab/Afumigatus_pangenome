#!/bin/bash -l

#SBATCH --nodes=1
#SBATCH --ntasks=16
#SBATCH --mem 128gb -p intel
#SBATCH --time=7-00:15:00   
#SBATCH --output=logs/train.%a.log
#SBATCH --job-name="TrainFun"
module unload perl
module unload python
module unload miniconda2
module unload miniconda3
module load funannotate/development
source activate funannotate

#PASAHOMEPATH=$(dirname `which Launch_PASA_pipeline.pl`)
#TRINITYHOMEPATH=$(dirname `which Trinity`)
export AUGUSTUS_CONFIG_PATH=$(realpath lib/augustus/3.3/config)
CPUS=$SLURM_CPUS_ON_NODE

MEM=128G

if [ ! $CPUS ]; then
 CPUS=2
fi

ODIR=annotate
INDIR=genomes
RNAFOLDER=lib/RNASeq
SAMPLEFILE=samples.csv
N=${SLURM_ARRAY_TASK_ID}

if [ ! $N ]; then
    N=$1
    if [ ! $N ]; then
        echo "need to provide a number by --array or cmdline"
        exit
    fi
fi
IFS=,
SPECIES="Aspergillus fumigatus"
RNASEQSET=PRJNA376829
TRANSCRIPT=lib/informant/Trinity_30strain.nr
tail -n +2 $SAMPLEFILE | sed -n ${N}p | while read BASE LOCUS
do
    STRAIN=$BASE
    MASKED=$(realpath $INDIR/$BASE.masked.fasta)
    if [ ! -f $MASKED ]; then
     	echo "Cannot find $BASE.masked.fasta in $INDIR - may not have been run yet"
     	exit
    fi
	#funannotate train -i $MASKED -o $ODIR/$BASE \
	#--left $RNAFOLDER/${RNASEQSET}_R1.fq.gz --right $RNAFOLDER/${RNASEQSET}_R1.fq.gz \
   	#--stranded RF --jaccard_clip --species "$SPECIES" --isolate $STRAIN  --cpus $CPUS --memory $MEM
	funannotate train -i $MASKED -o $ODIR/$BASE --trinity $TRANSCRIPT \
   	--jaccard_clip --species "$SPECIES" --isolate $STRAIN  --cpus $CPUS --memory $MEM
done
