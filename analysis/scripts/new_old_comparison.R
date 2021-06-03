# checking old vs. new elite ideal points for overlapping MoC
# (plus how much overlap in elites)

library(tidyverse)
library(tweetscores)
library(colorblindr)

# get old tweetscores
old_elites <- data.frame(handle = tolower(tweetscores::refdataCA$colnames),
                         ideal_point = tweetscores::refdataCA$colcoord[,1])

# read in new ideal points
new_elites <- readr::read_tsv("~/Desktop/GitHub/new-tweetscores/data/elites_combined_with_phi.tsv")

# how many accounts in the new sample are also in the old sample?
new_elites %>%
  mutate(handle = tolower(screen_name)) %>%
  left_join(old_elites, 
            by = "handle") %>%
  mutate(has_old_ideal_point = as.numeric(!is.na(ideal_point))) %>%
  group_by(source, has_old_ideal_point) %>%
  summarise(n = n()) %>%
  group_by(source) %>%
  mutate(prop = n/sum(n))

# how much nominal agreement among elites that overlap?
nominal_agreement <- 
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
ggsave(nominal_agreement, file = "~/Desktop/GitHub/new-tweetscores/analysis/figures/nominal_agreement_overlap.png", width = 8, height = 4)

# how much rank-order agreement among elites who overlap?
rank_agreement <- 
  new_elites %>%
  mutate(handle = tolower(screen_name)) %>%
  left_join(old_elites, 
            by = "handle") %>%
  filter(!is.na(ideal_point)) %>%
  arrange(desc(phi)) %>%
  mutate(phi_rank = 1:n()) %>%
  arrange(desc(ideal_point)) %>%
  mutate(tweetscore_rank = 1:n()) %>%
  ggplot(aes(x = phi_rank, y = tweetscore_rank,
             col = (source == "members_of_congress")))+
  geom_point()+
  geom_abline(slope = 1, intercept = 0)+
  scale_color_OkabeIto(name = "Member of Congress?")+
  labs(title = "Ideal point rank agreement: New estimate vs. tweetScore",
       subtitle = "Among elites with estimates in both samples",
       x = "Phi Rank (2021)",
       y = "tweetScore Rank (2015)",
       caption = "Refernece line represents y = x")+
  theme_bw()
ggsave(rank_agreement, file = "~/Desktop/GitHub/new-tweetscores/analysis/figures/rank_agreement_overlap.png", width = 8, height = 4)

