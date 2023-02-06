#!/usr/bin/bash -l
#SBATCH -N 1 -c 16 -n 1 --mem 32gb
#SBATCH --output=logs/annotfunc.%a.log
#SBATCH --time=2-0:00:00
#SBATCH -p intel -J annotfunc

module load funannotate
module load phobius

export FUNANNOTATE_DB=/bigdata/stajichlab/shared/lib/funannotate_db
CPUS=$SLURM_CPUS_ON_NODE
OUTDIR=annotate
INDIR=genomes
SAMPLEFILE=samples.csv
BUSCO=eurotiales_odb10
species="Aspergillus fumigatus"
if [ -z $CPUS ]; then
 CPUS=1
fi

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
SPECIES="Aspergillus_fumigatus"
IFS=,  # this species the column split character in $SAMPLEFILE

tail -n +2 $SAMPLEFILE | sed -n ${N}p | while read SampID FileBase Strain Patient
do
	name=$Strain
	Strain=$Strain
	MOREFEATURE=""
	TEMPLATE=$(realpath lib/pangenome.sbt)
	if [ ! -f $TEMPLATE ]; then
		echo "NO TEMPLATE for $name"
		exit
	fi
	ANTISMASHRESULT=$OUTDIR/$name/annotate_misc/antiSMASH.results.gbk
	echo "$name $species"
	if [[ ! -f $ANTISMASHRESULT && -d $OUTDIR/$name/antismash_local ]]; then
		ANTISMASH=$OUTDIR/$name/antismash_local/${SPECIES}_$name.gbk
		if [ ! -f $ANTISMASH ]; then
			echo "CANNOT FIND $ANTISMASH in $OUTDIR/$name/antismash_local"
		else
			rsync -a $ANTISMASH $ANTISMASHRESULT
		fi
	fi
	# need to add detect for antismash and then add that
	funannotate annotate --sbt $TEMPLATE --busco_db $BUSCO -i $OUTDIR/$name --species "$species" --strain "$Strain" --cpus $CPUS $MOREFEATURE $EXTRAANNOT
done
