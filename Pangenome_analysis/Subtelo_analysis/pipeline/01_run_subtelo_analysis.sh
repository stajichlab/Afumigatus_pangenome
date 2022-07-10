#!/usr/bin/bash -l
#SBATCH -p short -N 1 -n 1 -a 1-309 --out logs/telorun.%a.log

module load miniconda3
conda activate /bigdata/stajichlab/shared/condaenv/pybedtools

N=${SLURM_ARRAY_TASK_ID}

if [ -z $N ]; then
    N=$1
    if [ -z $N ]; then
        echo "Need an array id or cmdline val for the job"
        exit
    fi
fi
OG=Orthogroups.tsv
ORPHANS=Orthogroups_UnassignedGenes.tsv
GENOME=$(ls genomes/*.scaffolds.fa | sed -n ${N}p)
PREFIX=$(basename $GENOME .scaffolds.fa)
BED=gene_bed/$PREFIX.bed

python scripts/cmp_subtelo_orphans.py -t $OG -of $ORPHANS -i $GENOME --gff $BED --output reports/$PREFIX.observed.tsv --random reports/$PREFIX.random.tsv
