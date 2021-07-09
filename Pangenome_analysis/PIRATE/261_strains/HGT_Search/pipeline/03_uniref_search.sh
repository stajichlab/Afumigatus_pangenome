#!/usr/bin/bash
#SBATCH -p short -C ryzen -N 1 -n 32 --mem 64gb --out logs/phmmer_sprot_search.%a.log -a 1-16


module load hmmer/3.3.2-mpi
DB=db/uniprot_sprot.fasta
PREF=db_search/PIRATE261_Rep_to_sprot
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
	srun phmmer --mpi --domtbl $PREF.$N.domtbl --noali -E 1e-15 -o $PREF.$N.phmmer $QUERY $DB
fi
python scripts/get_best_hmmtbl.py -i $PREF.$N.domtbl > $PREF.$N.best
