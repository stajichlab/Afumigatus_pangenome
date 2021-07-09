#!/usr/bin/bash -l
PREF=PIRATE261
cat db_search/${PREF}_to_Afum293.*.best > ${PREF}_Rep.best_Af293.tsv
cat db_search/${PREF}_Rep_to_sprot.*.best > ${PREF}_Rep.best_Sprot.tsv
cat db_search/${PREF}_to_Pfam.*.pfam_hits.tsv > ${PREF}_Rep.Pfam_hits.tsv
grep ">" rep_seqs.pep | perl -p -e 's/^>//; my @row = split; $_ = join("\t",@row)."\n"' > $PREF.names.tsv

Rscript scripts/combine_besthits_table.R
