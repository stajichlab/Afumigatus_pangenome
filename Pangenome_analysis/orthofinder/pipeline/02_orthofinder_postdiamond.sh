#!/usr/bin/bash -l
#SBATCH --time 5-0:0:0 -p highmem -N 1 -n 32 --mem 500gb --out logs/orthofinder_build.%A.log
ulimit -Sn
ulimit -Hn
ulimit -n 80000
ulimit -Sn
ulimit -Hn
CPU=32
mkdir -p logs
module load orthofinder
module load workspace/scratch # use HPCC workspace scratch local folder
export TMPDIR=$SCRATCH
orthofinder -b OrthoFinder_diamond/Blast_results -t $CPU -a $CPU -S diamond_ultra_sens 

