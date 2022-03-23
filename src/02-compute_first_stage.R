library(tweetscores)
library(tidyverse)
library(Matrix)
library(assertthat)
library(glue)

set.seed(1620752821)
normalize <- function(x) {
  (x - mean(x)) / sd(x)
}

load_mat <- function(dirpath) {
  stem <- tail(str_split(dirpath, "\\/")[[1]], 1)
  mat <- readMM(glue("{dirpath}/{stem}_mat.mtx"))
  rownames(mat) <- readLines(glue("{dirpath}/{stem}_mat_rownames.txt"))
  colnames(mat) <- readLines(glue("{dirpath}/{stem}_mat_colnames.txt"))
  return(mat)
}

run_CA <- function(mat, supcol, colmin=1, rowmin=5, nd=3) {
  mat <- mat[, which(colSums(mat) > colmin)]
  maincol <- which(!(colnames(mat) %in% supcol))

  inform <- which(rowSums(mat[, maincol]) > rowmin)
  mat <- mat[inform, ]

  # TODO: this looks wrong to me. we need to keep both sums != zero
  mat <- mat[, which(colSums(mat) > colmin)]
  maincol <- which(!(colnames(mat) %in% supcol))

  # convert supcol to integer indices, after dropping bad columns
  supcol <- which(colnames(mat) %in% supcol)
  res <- CA(mat, nd=nd, supcol=supcol)
  return(res)
}

CA_to_scores <- function(res, elites, join_col) {
  phi <- scale(res$colcoord[,1])
  phi_2 <- scale(res$colcoord[,2])

  names(phi) <- res$colnames
  names(phi_2) <- res$colnames

  elites$phi <-phi[elites[[join_col]]]
  elites$phi_2 <-phi_2[elites[[join_col]]]

  return(elites)
}

# load all matrices
mat_2018 <- load_mat("../data/matrices/elites_v2_jan2018") %>% as.matrix()
mat_2020 <- load_mat("../data/matrices/elites_v2_sep2020") %>% as.matrix()

mat_2018_ps <- load_mat("../data/matrices/barbera_elites_ps_jan2018") %>% as.matrix()
mat_2020_ps <- load_mat("../data/matrices/barbera_elites_ps_sep2020") %>% as.matrix()


# load elites files and prep supcols
new_elites <- read_tsv("../data/elites_combined_v2.tsv", col_types=c("user_id"="c"))
new_elites_2020_supcol <- colnames(mat_2020)[(colnames(mat_2020) %in% new_elites[new_elites$president + new_elites$moc_117 + new_elites$moc_116 <1,]$meta_id)]
new_elites_2018_supcol <- colnames(mat_2018)[(colnames(mat_2018) %in% new_elites[new_elites$president + new_elites$moc_117 + new_elites$moc_116 <1,]$meta_id)]

barbera_ps_elites <- read_tsv("../data/barbera_ps_elites.tsv", col_types=c("user_id"="c"))
barbera_ps_elites_2018_supcol <- colnames(mat_2018_ps)[which(str_to_lower(colnames(mat_2018_ps)) %in% str_to_lower(barbera_ps_elites[barbera_ps_elites$politician==0,]$screen_name))]
barbera_ps_elites_2020_supcol <- colnames(mat_2020_ps)[which(str_to_lower(colnames(mat_2020_ps)) %in% str_to_lower(barbera_ps_elites[barbera_ps_elites$politician==0,]$screen_name))]

# run CAs, build score files, and write out both
# NOTE: we're rm'ing `res` each time since we're not being memory-efficent in the setup
# TODO: if we put all this into a function, we can avoid some of that
res <- run_CA(mat_2020, new_elites_2020_supcol)
save(res, file="../data/models/elites_v2_sep2020_CA.rdata")
scores <- CA_to_scores(res, new_elites, "meta_id")
write_tsv(scores, "../data/scores/elites_v2_sep2020_scores.tsv")
rm(res)

res <- run_CA(mat_2018, new_elites_2018_supcol)
save(res, file="../data/models/elites_v2_jan2018_CA.rdata")
scores <- CA_to_scores(res, new_elites, "meta_id")
write_tsv(scores, "../data/scores/elites_v2_jan2018_scores.tsv")
rm(res)

res <- run_CA(mat_2018_ps, barbera_ps_elites_2018_supcol)
save(res, file="../data/models/barbera_elites_ps_jan2018_CA.rdata")
scores <- CA_to_scores(res, barbera_ps_elites, "screen_name")
write_tsv(scores, "../data/scores/barbera_elites_ps_jan2018_scores.tsv")
rm(res)

res <- run_CA(mat_2020_ps, barbera_ps_elites_2020_supcol)
save(res, file="../data/models/barbera_elites_ps_sep2020_CA.rdata")
scores <- CA_to_scores(res, barbera_ps_elites, "screen_name")
write_tsv(scores, "../data/scores/barbera_elites_ps_sep2020_scores.tsv")
rm(res)
