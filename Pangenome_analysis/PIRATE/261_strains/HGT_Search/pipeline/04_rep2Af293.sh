#!/usr/bin/bash
#SBATCH -p short -N 1 -n 16 --mem 32gb --out logs/phmmer_Af293.%a.log -a 1-16


module load hmmer/3.3.2-mpi
DB=db/FungiDB-52_AfumigatusAf293_AnnotatedProteins.fasta
PREF=db_search/PIRATE261_to_Afum293
mkdir -p db_search
# turning off alignments in phmmer output to make output a little smaller
N=${SLURM_ARRAY_TASK_ID}

if [ -z $N ]; then
    N=$1
    if [ -z $N ]; then
        echo "need to provide a number by --array or cmdline"
        exit
    fi
fi
QUERY=split/PIRATE261_rep.$N
if [ ! -f $PREF.$N.domtbl ]; then
	srun phmmer --mpi --domtbl $PREF.$N.domtbl --noali -E 1e-80 -o $PREF.$N.phmmer $QUERY $DB
fi

python scripts/get_best_hmmtbl.py -i $PREF.$N.domtbl > $PREF.$N.best
