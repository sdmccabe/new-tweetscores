library(tidyverse)
library(tweetscores)

set.seed(1620752821)

PANEL_FOLLOW_DIR <- "/net/data-backedup/twitter-voters/friends_collect/friends_data/"
get_tweetscore <- function(user, dirname) {
  tryCatch({
    follows <- readLines(paste0(dirname, "/", user))

    num_followed <- sum(matrix((tweetscores::refdataCA$id %in% follows)*1, nrow=1))
    num_followed_orig <- sum(tweetscores::posterior_samples$id %in% follows)

    pa_theta <- NA
    ps_theta <- NA
    if (num_followed_orig > 0) {
        results <- estimateIdeology(user, follows, method="MLE")
        pa_theta <- summary(results)[2,1]
    }

    if (num_followed > 0) {
        ps_theta <- estimateIdeology2(user, follows)
    }


    return(c(userid=user,
             barbera_score=ps_theta,
             barbera_score_orig=pa_theta,
             num_barbera_follow=num_followed,
             num_barbera_follow_orig=num_followed_orig))
  },
  error=function(cond) {
    message(paste("error for user ", user))
    return(c(
      userid=user,
      barbera_score=NA,
      barbera_score_orig=NA,
      num_barbera_follow=NA,
      num_barbera_follow_orig=NA
    ))
  }
  )
}

panelists <- list.files(PANEL_FOLLOW_DIR)
barbera_df <- map_dfr(panelists, ~quietly(get_tweetscore)(., PANEL_FOLLOW_DIR) %>% pluck("result"))

write_tsv(barbera_df, "../data/barbera_scores.tsv")
