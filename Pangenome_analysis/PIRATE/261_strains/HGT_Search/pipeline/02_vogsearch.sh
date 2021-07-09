#!/usr/bin/bash
#SBATCH -N 1 -n 64 --mem 64gb --out logs/vog_search.log -p short -C xeon

module load hmmer/3.3.2-mpi

DB=/srv/projects/db/DRAM/vog_latest_hmms.txt
Q=rep_seqs.pep
OUT=db_search
mkdir -p $OUT

if [ ! -f $OUT/vog_search.domtbl ]; then
	srun hmmsearch --mpi --domtbl $OUT/vog_search.domtbl $DB $Q > $OUT/vog_search.hmmsearch
fi

python scripts/get_best_hmmtbl_vog.py -i $OUT/vog_search.domtbl > $OUT/PIRATE261_Rep.vog_search.best

