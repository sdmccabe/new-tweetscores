library(tweetscores)
library(tidyverse)
library(Matrix)
library(assertthat)

set.seed(1620752821)
normalize <- function(x) {
  (x - mean(x)) / sd(x)
}

mat <- readMM("../data/panel_elites_mat.mtx")

colnames(mat) <- readLines("../data/panel_elites_mat_colnames.txt")
rownames(mat) <- readLines("../data/panel_elites_mat_rownames.txt")

mat <- as.matrix(mat)
non_politician_columns <- c(525:1558)

mat <- mat[, which(colSums(mat) > 1)]
politicians <- which(str_starts(colnames(mat), "pres|MS|MH"))
non_politicians <- which(!str_starts(colnames(mat), "pres|MS|MH"))

inform <- which(rowSums(mat[, politicians]) > 5)
mat <- mat[inform, ]

print(dim(mat))
print(mean(mat))

res <- CA(mat, nd=3, supcol=non_politicians)
save(res, file="../data/correspondence_analysis.rdata")

## G <- igraph::graph_from_incidence_matrix(mat)

## assert_that(igraph::is_connected(G))
## assert_that(igraph::is_bipartite(G))
## target <- which(colnames(mat) == "MS11741301")
## assert_that(length(target) == 1)

## starts <- list(
##     alpha = matrix(normalize(log(colSums(mat) + 0.0001))),
##     beta = matrix(normalize(log(rowSums(mat) + 0.0001))),
##     w = matrix(rnorm(dim(mat)[2])),
##     theta = matrix(rnorm(dim(mat)[1])),
##     gamma = matrix(c(-1))
## )

## #mat <- ustweet$data
## #starts <- ustweet$starts
## priors <- ustweet$priors

## str(starts)
## str(priors)
## out <- networkIRT(.y = mat,
##                    .starts = starts,
##                    .priors = priors,
##                    .control = {list(verbose = FALSE,
##                                     maxit = 3,
##                                     convtype = 2,
##                                     thresh = 1e-6,
##                                     threads = 1
##                                     )
##                            },
##                    .anchor_item = target
##                    )

## saveRDS(out, file="/net/data/twitter-covid/ideal_points.Rdata")
