#!/usr/bin/bash
#SBATCH -p short -N 1 -n 48 --mem 8gb

module load parallel

CPU=${SLURM_CPUS_ON_NODE}
if [ -z $CPU ]; then
    CPU=2
fi

OUTGFF=gff3_only
OUTCDS=gene_seqs
OUTFASTA=genome_only
mkdir -p $OUTGFF $OUTFASTA $OUTCDS

INFOLDER=modified_gffs

make_fixed_gff() {
    OUTGFF=gff3_only
    OUTFASTA=genome_only

    gffin=$1

    fname=$(basename $gffin .gff)
    N=$(grep -n "##FASTA" $gffin | cut -d: -f1)
    
#    echo "fname=$fname OUT=$OUTGFF OUTF=$OUTFASTA N=$N"
    echo "##gff-version 3" > $OUTGFF/${fname}.gff3
    N=$(expr $N - 1)
    head -n $N $gffin | grep -v -P "\texon\t" \
	| perl -p -e 'if (/\tmRNA\t/) { s/ID=([^;]+);(Parent=[^;]+);(.+;)?prev_ID=(\S+)/ID=$4;AltID=$1;$2;$3/}' >>  $OUTGFF/${fname}.gff3
    grep -P "\tmRNA\t" $OUTGFF/${fname}.gff3 | cut -f9 | cut -d\; -f1,2 | perl -p -e 's/ID=([^;]+);AltID=(\S+)/$1\t$2/' >  $OUTGFF/${fname}.map_ids.tsv
    N=$(expr $N + 2)
    tail -n +$N $gffin > $OUTFASTA/${fname}.fasta
}

make_fixed_cds() {
    gffin=$1
    OUTGFF=$(dirname $gffin)
    OUTFASTA=genome_only
    OUTCDS=gene_seqs

    fname=$(basename $gffin .gff3)
    module unload parallel
    module load GAL
    gal_dump_CDS_sequence $gffin $OUTFASTA/${fname}.fasta > $OUTCDS/${fname}.cds
    bp_translate_seq.pl $OUTCDS/${fname}.cds > $OUTCDS/${fname}.pep
    module unload GAL
}

export -f make_fixed_gff
export -f make_fixed_cds

parallel -j $CPU make_fixed_gff ::: $(ls $INFOLDER/*.gff)
#parallel -j $CPU make_fixed_cds ::: $(ls $OUTGFF/*.gff3)


