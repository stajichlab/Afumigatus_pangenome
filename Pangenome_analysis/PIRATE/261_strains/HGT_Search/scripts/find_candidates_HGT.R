library(readr)
library(tidyverse)

inT <- read_csv("PIRATE261_Rep.classification.csv",col_names=TRUE)
taxocodes <- read_tsv("db/code2taxonomy.tsv",col_names = c("SPROT_taxa","Kingdom","taxon_id","Species"))
summary(inT)
noAfum <- inT %>% filter(is.na(Af293_name)) 

summary(noAfum)
codesAdded <- left_join(noAfum,taxocodes,by="SPROT_taxa")

write_csv(codesAdded,"combined_noAfum_PIRATE.csv")