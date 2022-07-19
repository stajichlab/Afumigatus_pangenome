library(tidyverse)
library(fs)

data_dir = "reports"
obs_tsv_files <- fs::dir_ls(data_dir, regexp = "\\.observed_100k.tsv$")
obsdata <- obs_tsv_files %>% map_dfr(read_tsv,show_col_types = FALSE)

obsAdd <- obsdata %>% mutate(SOURCE = "SubTelomere")

rand_tsv_files <- fs::dir_ls(data_dir, regexp = "\\.random_100k.tsv$")
rand_data <- rand_tsv_files %>% map_dfr(read_tsv,show_col_types = FALSE)

randAdd <- rand_data %>% mutate(SOURCE="Random")

teloGeneType <- bind_rows(obsAdd,randAdd) %>% filter (TOTAL >0) %>% mutate(ratio = CORE / ACCESSORY,
                                                     COREP = CORE / TOTAL,
                                                     ACCESSORYP = ACCESSORY / TOTAL,
                                                     SINGLEP = SINGLETON / TOTAL,
                                                     DISPENSABLE=ACCESSORY+SINGLETON,
                                                     DISPENSABLEP=(ACCESSORY+SINGLETON)/TOTAL)
teloGeneType %>% filter(CORE== 0)
# Density plots with semi-transparent fill
pdf("Subtelo_windows_plots_100k.pdf")
p <- ggplot(teloGeneType, aes(x=CORE, fill=SOURCE)) + geom_density(alpha=.3) + scale_fill_brewer(palette="Set1") + xlab("Number of Core genes in 100kb windows")
p
p <- ggplot(teloGeneType, aes(x=TOTAL, fill=SOURCE)) + geom_density(alpha=.3) + scale_fill_brewer(palette="Set1") + xlab("Total genes in 100kb windows")

p
p <- ggplot(teloGeneType, aes(x=DISPENSABLE, fill=SOURCE)) + geom_density(alpha=.3) + scale_fill_brewer(palette="Set1") + xlab("Number of Dispensable genes in 100kb windows")
p

p <- ggplot(teloGeneType, aes(x=COREP, fill=SOURCE)) + geom_density(alpha=.3) + scale_fill_brewer(palette="Set1") + xlab("% of Core genes in 100kb windows")
p

p <- ggplot(teloGeneType,aes(x=SOURCE,y=COREP,fill=SOURCE)) + geom_boxplot(outlier.colour="black", outlier.shape=16,
             outlier.size=2, notch=FALSE) + scale_fill_brewer(palette="Set1") + ylab("% Core genes in 100kb window") + xlab("Window type") 
p

p <- ggplot(teloGeneType,aes(x=SOURCE,y=DISPENSABLEP,fill=SOURCE)) + geom_boxplot(outlier.colour="black", outlier.shape=16,
                                                               outlier.size=2, notch=FALSE) + scale_fill_brewer(palette="Set1") +
  ylab("% Dispensable genes in 100kb windows") + xlab("Window type") 
p
