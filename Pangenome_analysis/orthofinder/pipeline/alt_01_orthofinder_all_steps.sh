#!/usr/bin/bash -l
#SBATCH --time 10:0:0 -p highmem -N 1 -n 32 --mem 150gb --out logs/orthofinder_all_steps.%A.log
ulimit -Sn
ulimit -Hn
ulimit -n 80000
ulimit -Sn
ulimit -Hn
CPU=32
mkdir -p logs
module load orthofinder/2.5.2
export TMPDIR=/scratch
orthofinder -f sm_input -t $CPU -a $CPU -S diamond_ultra_sens
