#!/usr/bin/bash
#SBATCH -p batch -N 1 -n 32 --mem 128gb  --out logs/pirate.run3.log -J PIRATE

module unload miniconda3
module unload miniconda2
module unload python
module unload perl
module unload anaconda2
module load anaconda3
module load cd-hit/4.8.1
module load mcl
module load ncbi-blast/2.9.0+
export TEMPDIR=/scratch
export TMPDIR=/scratch
CPUS=$SLURM_CPUS_ON_NODE
if [ -z $CPUS ]; then
 CPUS=1
fi

source activate pirate

~/projects/PIRATE/bin/PIRATE -f mRNA -i gff -t $CPUS -n -a --rplots -o PIRATE_3 --nucl --align
