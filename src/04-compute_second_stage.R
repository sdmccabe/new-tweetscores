library(tidyverse)
library(Matrix)
library(patchwork)

# Pablo's [2020 code](https://github.com/pablobarbera/twitter_ideology/tree/master/2020-update) 
# threw everything onto BigQuery, but instead we'll keep everything in matrix form.

mat <- readMM("../data/panel_elites_mat.mtx")

colnames(mat) <- readLines("../data/panel_elites_mat_colnames.txt")
rownames(mat) <- readLines("../data/panel_elites_mat_rownames.txt")

elites <- read_tsv('../data/elites_combined_with_phi.tsv', col_types="ccciiiiiiiiinnic")
elites <- filter(elites, meta_id %in% colnames(mat))


# We do some pre-processing to take the $\phi$s and align them with the following matrix.
# num_follow <- rowSums(mat)

phi <- elites$phi
names(phi) <- elites$meta_id
phi <- phi[!duplicated(names(phi))]
# re-align phi with column indices
phi <- phi[match(colnames(mat), names(phi))]

phi_2 <- elites$phi_2
names(phi_2) <- elites$meta_id
phi_2 <- phi_2[!duplicated(names(phi_2))]
# re-align phi with column indices
phi_2 <- phi_2[match(colnames(mat), names(phi_2))]


# construct adjacency list representation from
# incidence matrix
adj <- apply(mat, 1, function(x) names(which(x == 1)))

# use adjacency list to compute follow count and thetas
# The $\theta$s are effectively the row means of the adjacency list.
num_follow <- sapply(adj, length)
thetas <- sapply(adj, function(x) mean(phi[x], na.rm=T))
theta_2s <- sapply(adj, function(x) mean(phi_2[x], na.rm=T))

# We bring in side information from the voter file to validate the same way Pablo did.
vf <- read_csv("~/tmp/TSmart-cleaner-Oct2017-rawFormat.csv", col_types = c(twProfileID="c", tsmart_partisan_score="n"), guess_max=500000)
vf <- vf %>% select(twProfileID, tsmart_partisan_score)

vf$party <- case_when(vf$tsmart_partisan_score < 35 ~ "Republican", vf$tsmart_partisan_score > 65 ~ "Democrat", TRUE ~ "Independent")
vf$follows <- num_follow[vf$twProfileID]

vf$theta <- thetas[vf$twProfileID]
vf$scaled_theta <- scale(vf$theta)

vf$theta_2 <- theta_2s[vf$twProfileID]
vf$scaled_theta_2 <- scale(vf$theta_2)

# drop all the NAs
vf <- vf %>% filter(follows > 0)
vf <- vf[!is.nan(vf$theta),]

write_tsv(vf, "../data/thetas.tsv")
