#!/bin/bash -l

#SBATCH -N 1 -c 16
#SBATCH --mem 64gb -p batch
#SBATCH --time=3-00:00:00
#SBATCH --output=logs/train.%a.log
#SBATCH --job-name="TrainFun"

# Define program name
PROGNAME=$(basename $0)

# Load software
module load funannotate

MEM=64G
export AUGUSTUS_CONFIG_PATH=$(realpath lib/augustus/3.3/config)

# Set some vars
export FUNANNOTATE_DB=/bigdata/stajichlab/shared/lib/funannotate_db
export PASACONF=/rhome/jstajich/pasa.CONFIG.template

# Determine CPUS
if [[ -z ${SLURM_CPUS_ON_NODE} ]]; then
  CPUS=$1
else
  CPUS=${SLURM_CPUS_ON_NODE}
fi

# Validate CPUS
if [[ ${CPUS} -gt 64 ]] || [[ ${CPUS} -lt 1 ]]; then
  echo "You cannot run with $CPUS number of CPUS"
  exit 1
fi

N=${SLURM_ARRAY_TASK_ID}

if [ -z $N ]; then
  N=$1
  if [ -z $N ]; then
    echo "need to provide a number by --array or cmdline"
    exit
  fi
fi
ODIR=annotate
INDIR=genomes
RNAFOLDER=lib/RNASeq
SAMPLEFILE=samples.csv
mkdir -p $ODIR
IFS=,
SPECIES="Aspergillus fumigatus"
RNASEQSET=PRJNA376829
TRANSCRIPT=lib/informant/Trinity_30strain.nr
tail -n +2 $SAMPLEFILE | sed -n ${N}p | while read SampID FileBase Strain Patient
do
  BASE=$Strain
  MASKED=$(realpath $INDIR/$BASE.masked.fasta)
  if [ ! -f $MASKED ]; then
    echo "Cannot find $BASE.masked.fasta in $INDIR - may not have been run yet"
    exit
  fi
 # TRAINDIR=$ODIR/$BASE/training
#  echo $TRAINDIR
#  mkdir -p $TRAINDIR
#   for d in $TRINITYRUN/*
#   do
#    dname=$(basename $d)
#    if [ ! -d $TRAINDIR/$dname ]; then
#      mkdir -p $TRAINDIR/$dname
#      ln -s $d/* $TRAINDIR/$dname/
#    fi
#  done
  funannotate train -i $MASKED -o $ODIR/$BASE --trinity $TRANSCRIPT \
	      --jaccard_clip --species "$SPECIES" --isolate $Strain \
	      --cpus $CPUS --memory $MEM  --pasa_db mysql --left $RNAFOLDER/${RNASEQSET}_R1.trim_renamed.fq.gz \
	      --right $RNAFOLDER/${RNASEQSET}_R2.trim_renamed.fq.gz
done
