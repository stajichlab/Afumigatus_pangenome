#!/usr/bin/bash

module unload miniconda2
module load miniconda3


bp_dbsplit.pl --prefix rep_seqs_split --size 1000 -i rep_seqs.pep
