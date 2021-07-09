#!/usr/bin/env python3

import csv, sys, os, re

# cluster PIRATE.gene_families.tsv
inputfile = "PIRATE.gene_families.tsv"
#sys.argv[1]

outdir = 'per-strain-pangenome'
if not os.path.exists(outdir):
    os.mkdir(outdir)

gff_folder  = 'modified_gffs'

strain_col_start = 20
gene2pos = {}
gene2strain = {}
pangene2count = {}
gene2pangene = {}

fusionmatch = re.compile(r'\(([^:]+):([^:]+)\)')
# read in pirate result
with open(inputfile,"rU") as pirate:
    piratecsv = csv.reader(pirate,delimiter="\t")
    # parse header and read in in modified GFF files
    header = next(piratecsv)
    colcount = len(header)
    for n in range(strain_col_start,colcount):
        # each genome matches a modified_gff/gfffile
        strain_gff = os.path.join(gff_folder,header[n]+".gff")
        gene2pos[header[n]] = {} # initialize strain - gene dictionary
        print("parsing {}.gff".format(header[n]))
        if os.path.exists(strain_gff):
            with open(strain_gff,"rU") as gff_fh:
                gff = csv.reader(gff_fh,delimiter="\t")
                for row in gff:
                    if row[0].startswith("##FASTA"):
                        break
                    elif row[0][0] == "#" or row[2] != "mRNA":
                        continue

                    col9=row[8].split(";")
                    ID = re.sub("ID=","",col9[0])
                    oldID = re.sub("prev_ID=","",col9[-1])
                    product = ""
                    for i in range(2,len(col9)-1):
                        if col9[i].startswith("product="):
                            if col9[i] != "product=hypothetical protein":
                                product = re.sub("product=","",col9[i])
                            break
                    gene2strain[ID] = header[n]
                    gene2pos[header[n]][ID] = [ row[0],row[3],row[4],row[6],oldID,product]

    print("done parsing GFF")
    for row in piratecsv:
        family_allele= row[0]
        family       = row[1]
        pid          = row[4]
        genome_count = row[6]
        pangene2count[family] = [genome_count, 0]
        for col in range(strain_col_start,colcount):
            gene = row[col]
            if gene:
                for g in gene.split(";"):
                    if ":" in g:
                        m = fusionmatch.search(g)
                        while ( m ) :
                            gene1 = m.group(1)
                            gene2 = m.group(2)
                            gene2pangene[gene1] = [family,pid]
                            gene2pangene[gene2] = [family,pid]
                            pangene2count[family][1] += 2
                            nextstart = m.end() + 1
                            m = fusionmatch.search(g,nextstart)
                    else:
                        gene2pangene[g] = [family,pid]
                        pangene2count[family][1] += 1

for strain in gene2pos:
    ofile = os.path.join(outdir,"%s.pangene_depth.tab"%(strain))
    with open(ofile,"w") as ofh:
        line = csv.writer(ofh,delimiter="\t")
        line.writerow(['CHROM','START','END','STRAND','MRNAID',
                       'PROTEIN_PRODUCT',
                       'FAMILY','CLUSTER_PID','GENOME_COUNT','TOTAL_GENE_COUNT'])
        for gene in gene2pos[strain]:
            if gene in gene2pangene:
                (family,pid) = gene2pangene[gene]
                row = []
                row.extend(gene2pos[strain][gene])
                row.extend([family,pid])
                row.extend(pangene2count[family])
                line.writerow(row)
