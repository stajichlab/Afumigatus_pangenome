#!/usr/bin/bash -l
#SBATCH --time 1:0:0 -p short -N 1 -n 1 --mem 10gb 

cat sm_input/Af293_pep_short.fa | sed 's/>.*gene=/>/' > sm_input/temp1.fa
cat sm_input/temp1.fa | sed '/^>/ s/ .*//' > sm_input/Af293_pep_short.fa
rm sm_input/temp1.fa
