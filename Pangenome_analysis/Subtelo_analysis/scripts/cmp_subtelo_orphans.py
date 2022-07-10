#!/usr/bin/env python3
# -*- coding: utf-8 -*-

'''
Copyright (c) 2022, Jason Stajich
Licensed under the GPL3 license. See LICENSE file.
'''

import os
import re
import subprocess
import sys
import logging
import argparse
import csv
from pybedtools import BedTool

__version__ = "0.1"

'''
Functions for telomere finding are
Copyright (c) 2021, Markus Hiltunen
Licensed under the GPL3 license. See LICENSE file.
'''


def readFasta(infile):
    fa = {}
    with open(infile, "r") as fasta:
        sequence = None
        for line in fasta:
            line = line.strip()

            if line.startswith(">") and sequence == None:
                header = line[1:]
                sequence = []

            elif line.startswith(">") and sequence != None:
                # If new fasta entry, add old one to dict, pick new header and reset sequence
                fa[header] = "".join(sequence)
                header = line[1:]
                sequence = []

            else:
                sequence.append(line)

        # Last passthrough won't have any new entries, just add the remaining sequence
        fa[header] = "".join(sequence)

    return fa


def revcomp(seq):
    ''' Reverse complement sequence. Also the regex. Kinda.
    '''
    revcomped_seq = []
    for nucl in seq[::-1]:
        if nucl == "A" or nucl == "a":
            revcomped_seq.append("T")
        elif nucl == "T" or nucl == "t":
            revcomped_seq.append("A")
        elif nucl == "C" or nucl == "c":
            revcomped_seq.append("G")
        elif nucl == "G" or nucl == "g":
            revcomped_seq.append("C")
        elif nucl == "[":
            revcomped_seq.append("]+")
        elif nucl == "]":
            revcomped_seq.append("[")
        elif nucl == "+":
            continue
        else:  # At this point we don't care about IUPAC coded bases
            revcomped_seq.append("N")
    return "".join(revcomped_seq)


def findTelomere(seq, monomer, n):
    '''
    Takes nucleotide sequence and checks if the sequence contains telomere repeats.
    '''
    # Look within first and last 200 bp for repeats
    start = seq[:100].upper()
    end = seq[-100:].upper()

    forward, reverse = False, False
    '''
    # Look for TAACCCC... and TTAGGGG...
    if re.search("TAA[C]+TAA[C]+", start):
        forward = True
    if re.search("TTA[G]+TTA[G]+", end):
        reverse = True
    '''

    # Look for the monomer repeat n number of times.
    if re.search(monomer * n, start):
        forward = True
    rev_monomer = revcomp(monomer)
    if re.search(rev_monomer * n, end):
        reverse = True

    return forward, reverse


def main() -> int:
    """parse arguments and setup run"""
    parser = argparse.ArgumentParser(description='Examine Subtelomeric genes')

    parser.add_argument(
        '-s', '--size', help='Subtelomeric window size (50kb)', default=50000)
    parser.add_argument(
        '-i', '--fasta', help='Fasta file to examine', required=True)
    parser.add_argument(
        '-g', '--gff', help='BED/GFF file to find genes', required=True)
    parser.add_argument(
        '-o', '--output', help='Output report table for report', required=False)
    parser.add_argument(
        '-r', '--random', help='Output random windows scoring', required=False)
    parser.add_argument(
        '-rt','--randiters', help='Number of random windows to consider', required=False,default = 500)

    parser.add_argument('--corecutoff', help='Core gene cutoff', default=247)
    parser.add_argument('-of', '--orphans', help='path to Orthofinder (Orthogroups_UnassignedGenes.tsv)',
                        default="Orthogroups_UnassignedGenes.tsv")
    parser.add_argument(
        '-t', '--table', help='Orthofinder orthogroup table (Orthogroups.tsv) format is "OG: GENE1"', default="Orthogroups.tsv")
    parser.add_argument("-tm", "--telomere_monomer",
                    help="Custom telomere monomer to look for. Run separately for reverse telomeres. [TAA[C]+]",
                    type=str, default="TAA[C]+")
    parser.add_argument("-tn", "--telomere_repeats",
                    help="Minimum number of monomer repeats. [2]",
                    type=int, default=2)
    parser.add_argument("-v", "--version", help="Print version and quit.",
                    action="version",
                    version="find_telomeres v.{}".format(__version__))
    parser.add_argument(
        "-V", "--debug", help="debugging messages printed.", action='count', default=0)
    args = parser.parse_args()
    if args.debug > 0:
        logging.basicConfig(filename='run_debug.log',
                            encoding='utf-8', level=logging.DEBUG)
    strainname,rest = os.path.splitext(os.path.basename(args.fasta))
    strainname = re.sub('\.scaffolds','',strainname)

    randomoutfile,outfilename = "",""
    if args.output:
        outfilename = args.output
    else:
        outfilename = strainname + ".observed.tsv"

    if args.random:
        randomoutfile = args.random
    else:
        randomoutfile = strainname + ".random.tsv"

    fasta = readFasta(args.fasta)
    genes = BedTool(args.gff)

# parse out ortholog groups
    orthogroupgenes = {}
    with open(args.orphans, "r") as orphans:
        rdr = csv.reader(orphans, delimiter='\t')
        for row in rdr:
            i = 0
            for col in row:
                if i > 0 and len(col) > 0:
                    col = re.sub("-T\d+", "", col)
                    orthogroupgenes[col] = 'singleton'
                i += 1

    with open(args.table, "r") as ogroups:
        rdr = csv.reader(ogroups, delimiter='\t')
        header = next(ogroups)
        for row in rdr:
            seen = 0
            OG_classification = ""
            genenames = []
            for i in range(len(row)):
                # i==0 is the OG name col
                # len(row[i)) == 0 means this isn't an empty col
                if i > 0 and len(row[i]) > 0:
                    seen += 1
                if i > 0:
                    for locus in row[i].split(", "):
                        genenames.append(locus)

            if seen >= args.corecutoff:
                OG_classification = 'core'
            else:
                OG_classification = 'accessory'
            # orthogroups[row[0]] = [OG_classification]
            for g in genenames:
                g = re.sub("-T\d+", "", g)
                orthogroupgenes[g] = OG_classification

    n_f, n_r = 0, 0
    ctgs_with_telomere = {}
    observedwindows = []
    genomeDB = {} # this will the genome dictionary bedtools uses for randome below
    for header, seq in fasta.items():
        intervals = []
        forward, reverse = findTelomere(
            seq, args.telomere_monomer, args.telomere_repeats)
        ctglen = len(seq)
        if ctglen > 4*args.size: # only use chroms at least 4x as big as the window size
            #genomeDB[header] = (1+args.size,ctglen-args.size)
            genomeDB[header] = (0,ctglen)
        if forward or reverse:
            ctgs_with_telomere[header] = {
                'left': forward, 'right': reverse, 'length': ctglen}
            # now create intervals to query
        if forward == True:
            logging.info("{}\tforward\t{}".format(header, seq[:100]))
            n_f += 1
            if args.size > ctglen:
                logging.debug("Skipping chrom {}, it is shorter ({}) than subtelomeric window ({})".format(
                    header, ctglen, args.size))
            else:
                intervals.append((header, 1, args.size))

        if reverse == True:
            logging.debug("{}\treverse\t{}".format(header, seq[-100:]))
            n_r += 1
            if args.size > ctglen:
                logging.debug("Skipping chrom {}, it is shorter ({}) than subtelomeric window ({})".format(
                    header, ctglen, args.size))
            else:
                intervals.append((header, ctglen - args.size, ctglen))

        if len(intervals) > 0:
            for interval in intervals:
                subtelomeres = BedTool([interval])
                genesInSubTel = genes.intersect(subtelomeres, u=True)
                count = {'core': 0, 'singleton': 0, 'accessory': 0}
                totalgenes = 0
                for generow in genesInSubTel:
                    genename = re.sub(';\S+$', '', generow.name)
                    if genename in orthogroupgenes: # tRNA genes won't have an ortholog so needs to be skipped
                        count[orthogroupgenes[genename]] += 1
                        totalgenes += 1
                if totalgenes > 0:
                    observedwindows.append([strainname,totalgenes,count['core'],count['accessory'],count['singleton'],interval[0],interval[1],interval[2]])

    if len(observedwindows) > 0:
        with open(outfilename,"w") as ofile:
            outcsv = csv.writer(ofile,lineterminator=os.linesep,delimiter='\t')
            outcsv.writerow(['STRAIN','TOTAL','CORE','ACCESSORY','SINGLETON','CHROM','START','END'])
            for window in observedwindows:
                outcsv.writerow(window)

    if len(genomeDB):
        r = BedTool()
        randwindows = r.random(l=args.size,n=args.randiters,genome=genomeDB)
        with open(randomoutfile,"w") as randofile:
            outrand = csv.writer(randofile,lineterminator=os.linesep,delimiter='\t')
            outrand = csv.writer(randofile,lineterminator=os.linesep,delimiter='\t')
            outrand.writerow(['STRAIN','TOTAL','CORE','ACCESSORY','SINGLETON','CHROM','START','END'])
            for window in randwindows:
                rwindow = BedTool([[window.chrom, window.start, window.end]])
                r_genesInSubTel = genes.intersect(rwindow, u=True)
                r_count = {'core': 0, 'singleton': 0, 'accessory': 0}
                r_totalgenes = 0
                for generow in r_genesInSubTel:
                    genename = re.sub(';\S+$', '', generow.name)
                    if genename in orthogroupgenes: # tRNA genes won't have an ortholog so needs to be skipped
                        r_count[orthogroupgenes[genename]] += 1
                        r_totalgenes += 1
                outrand.writerow([strainname,r_totalgenes,r_count['core'],r_count['accessory'],r_count['singleton'],window.chrom, window.start, window.end])
    #print("{} total   {} ({:.2f}%) core   {} ({:.2f}%) accessory   {} ({:.2f}%) singleton".format(
    #totalgenes, totalcount['core'], 100 * totalcount['core'] / totalgenes,
    #    totalcount['accessory'], 100 * totalcount['accessory'] / totalgenes,
    #    totalcount['singleton'], 100 * totalcount['singleton'] / totalgenes))

    return 0

if __name__ == '__main__':
    sys.exit(main())
