library(dplyr)
library(readr)

seqnames <- read_tsv("PIRATE261.names.tsv",col_names = c("Gene","OrigName","PIRATE_Cluster"))

af293 <- read_tsv("PIRATE261_Rep.best_Af293.tsv", col_names = c("Gene","Af293_name","Af293_Evalue"))
vog   <- read_tsv("db_search/PIRATE261_Rep.vog_search.best", col_names = c("Gene","VOG","VOG_Evalue"))
pfam <- read_tsv("PIRATE261_Rep.Pfam_hits.tsv", col_names = c("Gene","Pfam_hits"))

af293
vog
pfam
combine0 <- full_join(seqnames,af293,by="Gene")
combine1 <- full_join(combine0, vog, by = "Gene") 
combine2 <- full_join(combine1,pfam, by = "Gene")

write_csv(combine2,"PIRATE261_Rep.classification.csv")
