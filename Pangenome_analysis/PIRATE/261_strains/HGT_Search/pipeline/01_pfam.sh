#!/usr/bin/bash -l
#SBATCH -p short -N 1 -n 24 -C xeon --mem 32gb --out logs/pfam.%a.log -a 1-16

module load hmmer/3.3.2-mpi
module load db-pfam/34.0
PREF=db_search/PIRATE261_to_Pfam
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
	time srun hmmsearch  --noali --mpi --cut_ga --domtbl $PREF.$N.domtbl -o $PREF.$N.hmmer $PFAM_DB/Pfam-A.hmm $QUERY
fi
python scripts/get_pfam_hmmtbl.py --wide -i $PREF.$N.domtbl > $PREF.$N.pfam_hits.tsv
