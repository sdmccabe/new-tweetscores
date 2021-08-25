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

# for subsetting on active users
active_users <- readLines("../data/list_of_active_users.txt")
active_users_parsed <- unlist(strsplit(active_users, split = " "))

# should be just under 600k rows 
mat <- mat[which(rownames(mat) %in% active_users_parsed), which(colSums(mat) > 1)]
politicians <- which(str_starts(colnames(mat), "pres|MS|MH"))
non_politicians <- which(!str_starts(colnames(mat), "pres|MS|MH"))

inform <- which(rowSums(mat[, politicians]) > 5)
mat <- mat[inform, ]

print(dim(mat))
print(mean(mat))

res <- CA(mat, nd=3, supcol=non_politicians)
save(res, file="../data/correspondence_analysis.rdata")

