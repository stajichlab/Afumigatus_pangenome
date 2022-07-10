#!/usr/bin/bash
#SBATCH --ntasks 32 --mem 32G --time 2:00:00 -p short -C xeon -N 1
module unload miniconda2
module load miniconda3
module load hmmer/3
module load parallel
if [ ! -f config.txt ]; then
	echo "Need config.txt for PHYling"
	exit
fi

source config.txt
if [ ! -z $PREFIX ]; then
	rm -rf aln/$PREFIX
fi
rm prefix.tab
./PHYling_unified/PHYling init
./PHYling_unified/PHYling search -q slurm

#./PHYling_unified/PHYling aln -c -q slurm

#pushd phylo
#sbatch --time 24:00:00 -p batch fast_run.sh
