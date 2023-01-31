#!/bin/bash -l
#SBATCH --nodes 1 --ntasks 8 --mem 64gb -J afumAAFTF --out logs/AAFTF_full.%a.%A.log -p intel --time 48:00:00

hostname
MEM=64
CPU=$SLURM_CPUS_ON_NODE
if [ -z $CPU ]; then
    CPU=1
fi

N=${SLURM_ARRAY_TASK_ID}

if [ -z $N ]; then
    N=$1
    if [ -z $N ]; then
        echo "Need an array id or cmdline val for the job"
        exit
    fi
fi

module load AAFTF

INDIR=input
SAMPLEFILE=samples.csv
ASM=genomes
PHYLUM=Ascomycota
WORKDIR=$SCRATCH
mkdir -p $ASM
mkdir -p $WORKDIR

IFS=,
tail -n +2 $SAMPLEFILE | sed -n ${N}p | while read SampID FileBase Strain Patient
do
    ASMFILE=$ASM/${Strain}.spades.fasta
    VECCLEAN=$ASM/${Strain}.vecscreen.fasta
    PURGE=$ASM/${Strain}.sourpurge.fasta
    CLEANDUP=$ASM/${Strain}.rmdup.fasta
    PILON=$ASM/${Strain}.pilon.fasta
    SORTED=$ASM/${Strain}.sorted.fasta
    STATS=$ASM/${Strain}.sorted.stats.txt
    LEFTTRIM=$WORKDIR/${SampID}_1P.fastq.gz
    RIGHTTRIM=$WORKDIR/${SampID}_2P.fastq.gz
    LEFTIN=$(ls $INDIR/$FileBase | sed -n 1p)
	RIGHTIN=$(ls $INDIR/$FileBase | sed -n 2p)
    LEFT=$WORKDIR/${SampID}_filtered_1.fastq.gz
    RIGHT=$WORKDIR/${SampID}_filtered_2.fastq.gz

    if [ ! -f $ASMFILE ]; then    
	    if [ ! -f $LEFT ]; then
	        echo "$INDIR/${SampID}_R1.fq.gz $INDIR/${SampID}_R2.fq.gz"
	        if [ ! -f $LEFTTRIM ]; then
		        AAFTF trim --method fastp --memory $MEM \
                    --left $LEFTIN --right $RIGHTIN \
                    -c $CPU -o $WORKDIR/${SampID}
	        fi
	    fi
	    echo "$LEFTTRIM $RIGHTTRIM"
	    AAFTF filter -c $CPU --memory $MEM -o $WORKDIR/${SampID} \
            --left $LEFTTRIM --right $RIGHTTRIM --aligner bbduk 
	    echo "$LEFT $RIGHT"
	    if [ -f $LEFT ]; then
	        rm -f $LEFTTRIM
	        rm -f $RIGHTTRIM
	    fi
    fi

    AAFTF assemble -c $CPU --left $LEFT --right $RIGHT  --memory $MEM \
	  -o $ASMFILE -w $WORKDIR/spades_${Strain}
    
    if [ ! -f $ASMFILE ]; then
	    echo "SPADES must have failed, exiting"
	    exit
    fi

    if [ ! -f $VECCLEAN ]; then
	    AAFTF vecscreen -i $ASMFILE -c $CPU -o $VECCLEAN 
    fi
    
    if [ ! -f $PURGE ]; then
    	AAFTF sourpurge -i $VECCLEAN -o $PURGE -c $CPU --phylum $PHYLUM --left $LEFT  --right $RIGHT
    fi
    
    if [ ! -f $CLEANDUP ]; then
	    AAFTF rmdup -i $PURGE -o $CLEANDUP -c $CPU -m 500
    fi
    
    if [ ! -f $PILON ]; then
	    AAFTF pilon -i $CLEANDUP -o $PILON -c $CPU --left $LEFT  --right $RIGHT
    fi
    
    if [ ! -f $PILON ]; then
	    echo "Error running Pilon, did not create file. Exiting"
	    exit
    fi
    
    if [ ! -f $SORTED ]; then
	    AAFTF sort -i $PILON -o $SORTED
    fi
    
    if [ ! -f $STATS ]; then
	    AAFTF assess -i $SORTED -r $STATS
    fi
done
