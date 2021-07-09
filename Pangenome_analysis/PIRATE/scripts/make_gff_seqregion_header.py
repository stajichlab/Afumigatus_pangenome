#!/usr/bin/env python
import sys,itertools

def isheader(line):
    return line[0] == '>'

# this function reads in fasta file and returns pairs of data
# where the first item is the ID and the second is the sequence
# it isn't that efficient as it reads it all into memory
# but this is good enough for our project
def aspairs(f):
    seq_id = ''
    sequence = ''
    for header,group in itertools.groupby(f, isheader):
        if header:
            line = next(group)
            seq_id = line[1:].split()[0]
        else:
            sequence = ''.join(line.strip() for line in group)
            yield seq_id, sequence
filename = sys.argv[1]
with open(filename,"r") as f:
   seqs = aspairs(f)
   for seq in seqs:
       print("##sequence-region %s 1 %d"%(seq[0],len(seq[1])))
