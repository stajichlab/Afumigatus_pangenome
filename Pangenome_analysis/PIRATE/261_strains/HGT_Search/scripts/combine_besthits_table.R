library(dplyr)
library(readr)
library(stringr)

seqnames <- read_tsv("PIRATE261.names.tsv",col_names = c("Gene","OrigName","PIRATE_Cluster"))

af293 <- read_tsv("PIRATE261_Rep.best_Af293.tsv", col_names = c("Gene","Af293_name","Af293_Evalue"))
sprot <- read_tsv("PIRATE261_Rep.best_Sprot.tsv",col_names = c("Gene","SPROT_name","SPROT_Evalue"))
vog   <- read_tsv("db_search/PIRATE261_Rep.vog_search.best", col_names = c("Gene","VOG","VOG_Evalue"))
pfam <- read_tsv("PIRATE261_Rep.Pfam_hits.tsv", col_names = c("Gene","Pfam_hits"))

af293
vog
pfam
sprot

sprot <- sprot %>% mutate(SPROT_gene = str_split_n(SPROT_name,'\\|',3),
      SPROT_taxa = str_split_n(SPROT_gene,"_",2))

combine0 <- full_join(seqnames,af293,by="Gene")
combine1 <- full_join(combine0, vog, by = "Gene") 
combine2 <- full_join(combine1,pfam, by = "Gene")
combine3 <- full_join(combine2,sprot, by = "Gene")

write_csv(combine3,"PIRATE261_Rep.classification.csv")
