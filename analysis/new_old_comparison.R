# checking old vs. new elite ideal points for overlapping MoC
# (plus how much overlap in elites)

library(tidyverse)
library(tweetscores)
library(colorblindr)

old_elites <- data.frame(handle = tolower(tweetscores::refdataCA$colnames),
                         ideal_point = tweetscores::refdataCA$colcoord[,1])

new_elites <- readr::read_tsv("~/Desktop/GitHub/new-tweetscores/data/elites_combined_with_phi.tsv")

new_elites %>%
  mutate(handle = tolower(screen_name)) %>%
  left_join(old_elites, 
            by = "handle") %>%
  mutate(has_old_ideal_point = as.numeric(!is.na(ideal_point))) %>%
  group_by(source, has_old_ideal_point) %>%
  summarise(n = n()) %>%
  group_by(source) %>%
  mutate(prop = n/sum(n))
  
new_elites %>%
  mutate(handle = tolower(screen_name)) %>%
  left_join(old_elites, 
            by = "handle") %>%
  mutate(has_old_ideal_point = as.numeric(!is.na(ideal_point))) %>%
  ggplot(aes(x = phi, y = ideal_point,
             col = (source == "members_of_congress")))+
  geom_point()+
  geom_abline(slope = 1, intercept = 0)+
  scale_color_OkabeIto(name = "Member of Congress?")+
  labs(title = "Ideal point agreement: New estimate vs. tweetScore",
       subtitle = "Among elites with estimates in both samples",
       x = "Phi (2021)",
       y = "tweetScore (2015)")+
  theme_bw()
