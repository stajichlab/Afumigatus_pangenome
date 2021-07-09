#!/usr/bin/bash
cd db
bash download.sh

mkdir -p split
cd split
# get bioperl scripts which are installed in miniconda3 base
module unload miniconda2
module load miniconda3

bp_dbsplit.pl --prefix PIRATE261_rep --size 1000 -i ../rep_seqs.pep
