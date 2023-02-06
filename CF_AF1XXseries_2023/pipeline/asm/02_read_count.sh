#!/bin/bash -l
#SBATCH --nodes 1 --ntasks 24 --mem 24G -p short -J asmCount --out logs/bbcount.%a.log --time 2:00:00
module load BBMap
hostname
MEM=24
CPU=$SLURM_CPUS_ON_NODE
N=${SLURM_ARRAY_TASK_ID}

if [ ! $N ]; then
    N=$1
    if [ ! $N ]; then
        echo "Need an array id or cmdline val for the job"
        exit
    fi
fi

INDIR=$(realpath input)
SAMPLEFILE=samples.csv
ASM=$(realpath genomes)
OUTDIR=$(realpath mapping_report)
mkdir -p $OUTDIR

IFS=,
tail -n +2 $SAMPLEFILE | sed -n ${N}p | while read SampID FileBase Strain Patient
do
	LEFT=$(ls $INDIR/$FileBase | sed -n 1p)
	RIGHT=$(ls $INDIR/$FileBase | sed -n 2p)
	if [[ ! -f $LEFT || ! -f $RIGHT ]]; then
		echo "no $LEFT or $RIGHT"
	fi
	pushd $SCRATCH
	if [[ ! -s $OUTDIR/${Strain}.bbmap_covstats.txt || $SORTED -nt $OUTDIR/${Strain}.bbmap_covstats.txt ]]; then
	if [ ! -e $RIGHT ]; then
		bbmap.sh -Xmx${MEM}g ref=$SORTED in=$LEFT covstats=$OUTDIR/${Strain}.bbmap_covstats.txt  statsfile=$OUTDIR/${Strain}.bbmap_summary.txt
	else
		bbmap.sh -Xmx${MEM}g ref=$SORTED in=$LEFT in2=$RIGHT covstats=$OUTDIR/${Strain}.bbmap_covstats.txt  statsfile=$OUTDIR/${Strain}.bbmap_summary.txt
	fi
fi
