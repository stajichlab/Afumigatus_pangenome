#!/usr/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=16 --mem 16gb
#SBATCH --output=logs/annotfunc.%a.log
#SBATCH --time=2-0:00:00
#SBATCH -p intel -J annotfunc
module unload miniconda2
module unload miniconda3
module load funannotate/development
module unload perl
module unload python
source activate funannotate
module load phobius
module load diamond
CPUS=$SLURM_CPUS_ON_NODE
OUTDIR=annotate
SAMPFILE=strains.csv
PREFIXES=samples_prefix.csv
BUSCO=eurotiomycetes_odb9
if [ ! $CPUS ]; then
 CPUS=1
fi
N=${SLURM_ARRAY_TASK_ID}
INDIR=genomes
OUTDIR=annotate

SAMPFILE=samples.csv
N=${SLURM_ARRAY_TASK_ID}

if [ ! $N ]; then
    N=$1
    if [ ! $N ]; then
        echo "need to provide a number by --array or cmdline"
        exit
    fi
fi
MAX=`wc -l $SAMPFILE | awk '{print $1}'`

if [ $N -gt $MAX ]; then
    echo "$N is too big, only $MAX lines in $SAMPFILE"
    exit
fi
IFS=,
cat $SAMPFILE | sed -n ${N}p | while read ProjID JGISample JGIProjName JGIBarcode SubPhyla Species Strain Note
do
	name=$(echo "$Species" | perl -p -e 'chomp; s/\s+/_/g; ')
 	species=$(echo "$Species" | perl -p -e "s/$Strain//")
	MOREFEATURE=""
	TEMPLATE=$(realpath submit_files/${name}.sbt)
	if [ ! -f $TEMPLATE ]; then
		echo "NO TEMPLATE for $name"
		exit
	fi
	# need to add detect for antismash and then add that
	LOCUSTAG=$(python scripts/get_locus.py $name)
	if [ -z $LOCUSTAG ]; then
		echo " no LOCUSTAG for $Species"
		exit
	fi
	if [ -z $LOCUSTAG ]; then
		echo "cannot find locus for $name"
		funannotate annotate --sbt $TEMPLATE --busco_db $BUSCO -i $OUTDIR/$name --species "$species" --strain "$Strain" --cpus $CPUS $MOREFEATURE $EXTRAANNOT
	else
		funannotate annotate --sbt $TEMPLATE --busco_db $BUSCO -i $OUTDIR/$name --species "$species" --strain "$Strain" --rename $LOCUSTAG --cpus $CPUS $MOREFEATURE $EXTRAANNOT
	fi

done
