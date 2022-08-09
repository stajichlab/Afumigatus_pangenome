#!/bin/bash -l
#SBATCH -p short -N 1 -n 128 --mem 128gb --out logs/mmseqs_orthogroup_consensi.%a.log

module load mmseqs2
module load KronaTools
module load workspace/scratch
OUTSEARCH=mmseqs_taxonomy
mkdir -p $OUTSEARCH
DB=/srv/projects/db/ncbi/mmseqs/uniref50

CPU=2
if [ $SLURM_CPUS_ON_NODE ]; then
  CPU=$SLURM_CPUS_ON_NODE
fi
if [ ! -f  $OUTSEARCH/orthogroups_mmseqs_uniref50_report ]; then
	mmseqs easy-taxonomy $DB $OUTSEARCH/orthogroups_mmseqs_uniref50 $SCRATCH --threads $CPU --lca-ranks kingdom,phylum,family  --tax-lineage 1
fi
ktImportTaxonomy -o $OUTSEARCH/orthogroups_mmseqs_uniref50.krona.html $OUTSEARCH/orthogroups_mmseqs_uniref50_report
