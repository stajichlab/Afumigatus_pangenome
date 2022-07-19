#!/usr/bin/bash -l
#SBATCH -p short --mem 8gb --out logs/rplot.log

Rscript scripts/compare_subtelo_observations_100k.R
Rscript scripts/compare_subtelo_observations_50k.R
