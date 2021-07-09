#!/usr/bin/env python
import argparse, sys, csv
csv.register_dialect('tsv', delimiter='\t', quoting=csv.QUOTE_NONE)
parser = argparse.ArgumentParser(description="Get top hit from HMM search",
                                 add_help=True)
parser.add_argument('-i','--input',type=argparse.FileType('r'), nargs='?',
                    help="Input domtbl file")
parser.add_argument('-o','--output', nargs='?', type=argparse.FileType('w'),
                    default=sys.stdout,
                    help='output file name or else will write to stdout')

parser.add_argument('-w','--wide',action='store_true',
                    default=False,
                    help='output file name or else will write to stdout')
args = parser.parse_args(sys.argv[1:])

csvout = csv.writer(args.output,dialect="tsv")
#print(args)
#print(args.cutoff)
#print(args.input)
results = {}
for line in args.input:
    if line.startswith("#"):
        continue
    line = line.strip("\n")
    row = line.split()
    q = row[0]
    t = row[3]
    evalue = row[6]
    if q not in results:
        results[q] = []
    results[q].append([t,evalue])
    
for s in results:
    if args.wide:
        pfam_res = []
        for n in results[s]:
            pfam_res.append("%s=%s"%(n[0],n[1]))
        csvout.writerow([s, ";".join(pfam_res)])
    else:
        for n in results[s]:
            csvout.writerow([s,n[0],n[1]])

