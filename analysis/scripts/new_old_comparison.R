# checking old vs. new elite ideal points for overlapping elites
library(tidyverse)
library(tweetscores)
theme_jg <-function(){
  theme_bw()+
    theme(text = element_text(family = "serif", size = 16),
          strip.text = element_text(face = "bold"),
          plot.title = element_text(face = "bold", size = 20))
}

new_tweetscores <- readr::read_tsv("~/Desktop/GitHub/new-tweetscores/data/elites_combined_with_phi.tsv")

data(refdataCA)
head(refdataCA)

old_tweetscores <- data.frame(handle = tolower(refdataCA$colnames),
                              tweetscore = refdataCA$colcoord[,1])

old_tweetscores %>% 
  arrange(desc(tweetscore)) %>%
  mutate(index = 1:n()) %>%
  mutate(lab = ifelse(index %in% seq(from = 1, to = nrow(old_tweetscores), by = 20),
                      handle, NA)) %>%
  ggplot()+
  geom_point(aes(x = tweetscore, y = index))+
  geom_text(aes(x = tweetscore + .25,
                y = index, label = lab))+
  #scale_color_OkabeIto(name = "Community")+
  labs(x = "TweetScore",
       y = "Rank",
       title = "TweetScores (2015)",
       subtitle = "Every 20th elite labeled",
       caption = "From Barbera, et al (2015)")+
  theme_jg()

nominal_agreement <- 
  new_tweetscores %>%
  mutate(handle = tolower(screen_name),
         elite_type = case_when(moc_117 == 1 ~ "Current Member of Congress",
                                moc_116 == 1 ~ "Recent Member of Congress",
                                pundit == 1 ~ "Pundit (Green and Masket 2021)",
                                covid_elite == 1 ~ "Covid Elite (Gallagher et al 2021)",
                                president == 1 ~ "Current or Former President",
                                media == 1 ~ "Media Organization",
                                candidate == 1 ~ "Political Candidate",
                                governor == 1 ~ "Governor",
                                official == 1 ~ "Government Official",
                                media == 1 ~ "Media Organization")) %>%
  left_join(old_tweetscores, by = "handle") %>%
  ggplot(aes(x = phi, y = tweetscore, col = elite_type))+
  geom_point()+
  geom_abline(slope = 1, intercept = 0)+
  scale_color_OkabeIto(name = "Elite Type")+
  labs(title = "Ideal point agreement: New estimate vs. tweetScore",
       subtitle = "Among elites with estimates in both samples",
       x = "Phi (2021)",
       y = "tweetScore (2015)",
       caption = "Reference line represents y = x")+
  theme_jg()
ggsave(nominal_agreement, file = "~/Desktop/GitHub/new-tweetscores/analysis/figures/nominal_agreement_overlap.png", width = 8, height = 4)

# how much overlap?
new_tweetscores %>%
  mutate(handle = tolower(screen_name),
         elite_type = case_when(moc_117 == 1 ~ "Current Member of Congress",
                                moc_116 == 1 ~ "Recent Member of Congress",
                                pundit == 1 ~ "Pundit (Green and Masket 2021)",
                                covid_elite == 1 ~ "Covid Elite (Gallagher et al 2021)",
                                president == 1 ~ "Current or Former President",
                                media == 1 ~ "Media Organization",
                                candidate == 1 ~ "Political Candidate",
                                governor == 1 ~ "Governor",
                                official == 1 ~ "Government Official",
                                media == 1 ~ "Media Organization")) %>%
  left_join(old_tweetscores, by = "handle") %>%
  filter(!is.na(tweetscore)) %>% nrow()

# how much rank-order agreement among elites who overlap?
rank_agreement <- 
  new_tweetscores %>%
  mutate(handle = tolower(screen_name),
         elite_type = case_when(moc_117 == 1 ~ "Current Member of Congress",
                                moc_116 == 1 ~ "Recent Member of Congress",
                                pundit == 1 ~ "Pundit (Green and Masket 2021)",
                                covid_elite == 1 ~ "Covid Elite (Gallagher et al 2021)",
                                president == 1 ~ "Current or Former President",
                                media == 1 ~ "Media Organization",
                                candidate == 1 ~ "Political Candidate",
                                governor == 1 ~ "Governor",
                                official == 1 ~ "Government Official",
                                media == 1 ~ "Media Organization")) %>%
  left_join(old_tweetscores, by = "handle") %>%
  filter(!is.na(tweetscore)) %>%
  arrange(desc(phi)) %>%
  mutate(phi_rank = 1:n()) %>%
  arrange(desc(tweetscore)) %>%
  mutate(tweetscore_rank = 1:n()) %>%
  ggplot(aes(x = phi_rank, y = tweetscore_rank,
             col = elite_type))+
  geom_point()+
  geom_abline(slope = 1, intercept = 0)+
  scale_color_OkabeIto(name = "Elite Type")+
  labs(title = "Ideal point rank agreement: New estimate vs. tweetScore",
       subtitle = "Among elites with estimates in both samples",
       x = "Phi Rank (2021)",
       y = "tweetScore Rank (2015)",
       caption = "Reference line represents y = x")+
  theme_jg()
ggsave(rank_agreement, file = "~/Desktop/GitHub/new-tweetscores/analysis/figures/rank_agreement_overlap.png", width = 8, height = 4)


# correlation within type
rank_type_df <- 
  new_tweetscores %>%
  mutate(handle = tolower(screen_name),
         elite_type = case_when(moc_117 == 1 ~ "Current Member of Congress",
                                moc_116 == 1 ~ "Recent Member of Congress",
                                pundit == 1 ~ "Pundit (Green and Masket 2021)",
                                covid_elite == 1 ~ "Covid Elite (Gallagher et al 2021)",
                                president == 1 ~ "Current or Former President",
                                media == 1 ~ "Media Organization",
                                candidate == 1 ~ "Political Candidate",
                                governor == 1 ~ "Governor",
                                official == 1 ~ "Government Official",
                                media == 1 ~ "Media Organization")) %>%
  left_join(old_tweetscores, by = "handle") %>%
  filter(!is.na(tweetscore)) %>%
  arrange(desc(phi)) %>%
  mutate(phi_rank = 1:n()) %>%
  arrange(desc(tweetscore)) %>%
  mutate(tweetscore_rank = 1:n())

bind_rows(lapply(unique(rank_type_df$elite_type), function(x){
  rank_type_df %>% 
    filter(elite_type == x & !is.na(phi_rank) & !is.na(tweetscore_rank)) %>%
    summarise(rank_spearman_cor = cor(phi_rank, tweetscore_rank, method = "spearman"),
              n = n()) %>%
    mutate(elite_type = x)
})) %>%
  #filter(!is.na(rank_spearman_cor)) %>%
  arrange(desc(rank_spearman_cor))

# for whom is there disagreement?
diff_df <- new_tweetscores %>%
  mutate(handle = tolower(screen_name),
         elite_type = case_when(moc_117 == 1 ~ "Current Member of Congress",
                                moc_116 == 1 ~ "Recent Member of Congress",
                                pundit == 1 ~ "Pundit (Green and Masket 2021)",
                                covid_elite == 1 ~ "Covid Elite (Gallagher et al 2021)",
                                president == 1 ~ "Current or Former President",
                                media == 1 ~ "Media Organization",
                                candidate == 1 ~ "Political Candidate",
                                governor == 1 ~ "Governor",
                                official == 1 ~ "Government Official",
                                media == 1 ~ "Media Organization")) %>%
  left_join(old_tweetscores, by = "handle") %>%
  filter(!is.na(tweetscore) & !is.na(phi)) %>%
  arrange(phi) %>%
  mutate(phi_rank = 1:n()) %>%
  arrange(tweetscore) %>%
  mutate(tweetscore_rank = 1:n()) %>%
  mutate(diffrank = abs(tweetscore_rank - phi_rank)) %>%
  arrange(diffrank)

movement_plot <-diff_df %>%
  arrange(desc(diffrank)) %>%
  slice(1:100) %>%
  dplyr::select(handle, elite_type, phi, tweetscore, phi_rank, tweetscore_rank, diffrank) %>%
  ggplot(aes(x = fct_rev(fct_inorder(handle)),
             xend = fct_rev(fct_inorder(handle)),
             y = tweetscore_rank,
             yend = phi_rank,
             col = elite_type))+
  geom_segment(arrow = arrow(length = unit(.05, "inches")))+
  coord_flip()+
  scale_color_OkabeIto(name = "Elite Type")+
  labs(x = "Elite", y = "Rank\nRight = More Conservative",
       title = "Rank order movement among overlapping elites",
       subtitle = "Arrows from tweetScore (2015) rank to phi (2021) rank\nTop 100 of 335 overlapping elites with largest movement shown")+
  theme_jg()
ggsave(movement_plot, file = "~/Desktop/GitHub/new-tweetscores/analysis/figures/movement_plot.png", width = 10, height = 20)


stability_plot <- 
  diff_df %>%
  arrange(diffrank) %>%
  slice(1:100) %>%
  dplyr::select(handle, elite_type, phi, tweetscore, phi_rank, tweetscore_rank, diffrank) %>%
  ggplot(aes(x = fct_rev(fct_inorder(handle)),
             xend = fct_rev(fct_inorder(handle)),
             y = tweetscore_rank,
             yend = phi_rank,
             col = elite_type))+
  geom_segment(arrow = arrow(length = unit(.05, "inches")))+
  coord_flip()+
  scale_color_OkabeIto(name = "Elite Type")+
  labs(x = "Elite", y = "Rank\nRight = More Conservative",
       title = "Rank order movement among overlapping elites",
       subtitle = "Arrows from tweetScore (2015) rank to phi (2021) rank\nBottom 100 of 335 overlapping elites with smallest movement shown")+
  theme_jg()
ggsave(stability_plot, file = "~/Desktop/GitHub/new-tweetscores/analysis/figures/stability_plot.png", width = 10, height = 20)


diff_df %>%
  arrange(diffrank) %>%
  summarise(mean_movement = mean(diffrank),
            median_movement = median(diffrank),
            sd_movement = sd(diffrank))


diff_dist <- 
  diff_df %>%
  ggplot(aes(x = diffrank))+
  geom_histogram()+
  geom_vline(xintercept = median(diff_df$diffrank), lty = "solid", col = "red")+
  geom_vline(xintercept = mean(diff_df$diffrank), lty = "dashed", col = "red")+
  labs(title = "Distribution of Rank Movement",
       subtitle = "Mean (dashed) and median (solid) shown with red refernce lines",
       x = "Absolute Value Movement in Rank (of 351 Overlapping Elites)\n2015-2021",
       y = "Count")+
  theme_jg()
ggsave(diff_dist, file = "~/Desktop/GitHub/new-tweetscores/analysis/figures/diff_dist.png", width = 10, height = 6)


