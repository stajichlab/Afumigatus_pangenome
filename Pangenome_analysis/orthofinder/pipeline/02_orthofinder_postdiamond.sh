#!/usr/bin/bash -l
#SBATCH --time 5-0:0:0 -p intel -N 1 -n 32 --mem 256gb --out logs/orthofinder_build.%A.log
ulimit -Sn
ulimit -Hn
ulimit -n 67700
CPU=32
mkdir -p logs
module load orthofinder
export TMPDIR=/scratch
orthofinder -b OrthoFinder_diamond/Blast_results -t $CPU -a $CPU -S diamond_ultra_sens 

