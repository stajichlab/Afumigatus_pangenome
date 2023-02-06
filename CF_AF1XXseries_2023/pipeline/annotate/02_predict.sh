#!/bin/bash -l
#SBATCH --time 2-0:00:00 -c 16 -N 1 -n 1 --mem 24G --out logs/predict.%a.log

module load funannotate
export AUGUSTUS_CONFIG_PATH=$(realpath lib/augustus/3.3/config)
export FUNANNOTATE_DB=/bigdata/stajichlab/shared/lib/funannotate_db
GMFOLDER=`dirname $(which gmhmme3)`
#genemark key is needed
if [ ! -f ~/.gm_key ]; then
    ln -s $GMFOLDER/.gm_key ~/.gm_key
fi

CPU=1
if [[ ! -z $SLURM_CPUS_ON_NODE ]]; then
    CPU=$SLURM_CPUS_ON_NODE
fi

INDIR=genomes
OUTDIR=annotate
SAMPLEFILE=samples.csv
species="Aspergillus fumigatus"
BUSCO=$(realpath eurotiales_odb10)
PEP=$(realpath lib/informant.aa)
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

IFS=,  # this species the column split character in $SAMPLEFILE

tail -n +2 $SAMPLEFILE | sed -n ${N}p | while read SampID FileBase Strain Patient
do
    
    MASKED=$(realpath $INDIR/$Strain.masked.fasta)
    if [ ! -f $MASKED ]; then
	echo "Cannot find $Strain.masked.fasta in $INDIR - may not have been run yet"
    fi
    name=$Strain
    SEED_SPECIES="aspergillus_fumigatus"
    LOCUS=$Strain
    OUT=$(realpath $OUTDIR/$name)
    funannotate predict --cpus $CPU --keep_no_stops --SeqCenter UCR --busco_db $BUSCO --strain "$Strain" \
	      -i $MASKED --name $LOCUS --protein_evidence $PEP \
	      -s "$species"  -o $OUT --busco_seed_species $SEED_SPECIES
done
