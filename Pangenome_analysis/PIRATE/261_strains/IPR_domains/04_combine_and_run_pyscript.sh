#!/usr/bin/bash
#SBATCH -p short --mem 8gb

cat *iprout.tsv > all.pan.genome.iprout.tsv

python3 04_combine_ipr_add_genefamily.py

