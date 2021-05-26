library(tidyverse)
library(Matrix)
library(patchwork)

# Pablo's [2020 code](https://github.com/pablobarbera/twitter_ideology/tree/master/2020-update) 
# threw everything onto BigQuery, but instead we'll keep everything in matrix form.


mat <- readMM("../data/panel_elites_mat.mtx")

colnames(mat) <- readLines("../data/panel_elites_mat_colnames.txt")
rownames(mat) <- readLines("../data/panel_elites_mat_rownames.txt")

elites <- read_tsv('../data/elites_combined_with_phi.tsv', col_types="ifcccdddddddc")
elites <- filter(elites, meta_id %in% colnames(mat))


# We do some pre-processing to take the $\phi$s and align them with the following matrix.
num_follow <- rowSums(mat)

phi <- elites$phi
names(phi) <- elites$meta_id
phi <- phi[!duplicated(names(phi))]
# re-align phi with column indices
phi <- phi[match(colnames(mat), names(phi))]

phi_2 <- elites$phi_2
names(phi_2) <- elites$meta_id
phi_2 <- phi_2[!duplicated(names(phi_2))]
# re-align phi with column indices
phi_2 <- phi[match(colnames(mat), names(phi_2))]

# We keep the binary following matrix but also generate a weighted version, 
# replacing the 1s in the binary matrix with the appropriate $\phi$. 
phi_mat <- t(t(mat) * phi)
phi_2_mat <- t(t(mat) * phi_2)

# Once we've done that, the $\theta$s are effectively the row means 
# (ignoring the non-zero elements) of this matrix.
thetas <- rowSums(phi_mat) / num_follow
theta_2s <- rowSums(phi_2_mat) / num_follow

# We bring in side information from the voter file to validate the same way Pablo did.
vf <- read_csv("~/tmp/TSmart-cleaner-Oct2017-rawFormat.csv", col_types = c(twProfileID="c", tsmart_partisan_score="n"))
vf <- vf %>% select(twProfileID, tsmart_partisan_score)

vf$party <- case_when(vf$tsmart_partisan_score < 35 ~ "Republican", vf$tsmart_partisan_score > 65 ~ "Democrat", TRUE ~ "Independent")
vf$follows <- num_follow[vf$twProfileID]

vf$theta <- thetas[vf$twProfileID]
vf$scaled_theta <- scale(vf$theta)

vf$theta_2 <- theta_2s[vf$twProfileID]
vf$scaled_theta_2 <- scale(vf$theta_2)

# drop all the NAs
vf <- vf %>% filter(follows > 0)

write_tsv(vf, "../data/thetas.tsv")
