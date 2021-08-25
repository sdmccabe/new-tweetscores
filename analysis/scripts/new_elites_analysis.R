# new elite ideal points
library(tidyverse)
library(tweetscores)
library(colorblindr)
theme_jg <-function(){
  theme_bw()+
    theme(text = element_text(family = "serif", size = 16),
          strip.text = element_text(face = "bold"),
          plot.title = element_text(face = "bold", size = 20))
}

new_tweetscores <- readr::read_tsv("~/Desktop/GitHub/new-tweetscores/data/elites_combined_with_phi.tsv")

new_tweetscores$phi_std <- with(new_tweetscores,
                               ( phi - mean(phi, na.rm = T))/sd(phi, na.rm = T))


elites_dist <- 
  new_tweetscores %>%
  mutate(elite_type = case_when(moc_117 == 1 ~ "Current Member of Congress",
                                moc_116 == 1 ~ "Recent Member of Congress",
                                pundit == 1 ~ "Pundit (Green and Masket 2021)",
                                covid_elite == 1 ~ "Covid Elite (Gallagher et al 2021)",
                                president == 1 ~ "Current or Former President",
                                media == 1 ~ "Media Organization",
                                candidate == 1 ~ "Political Candidate",
                                governor == 1 ~ "Governor",
                                official == 1 ~ "Government Official",
                                media == 1 ~ "Media Organization")) %>%
  filter(!is.na(phi)) %>%
  arrange(phi) %>%
  mutate(rank = 1:n()) %>%
  mutate(labname = ifelse(tolower(screen_name) %in% 
                            c("joebiden","aoc","realdonaldtrump",
                              "nytimes","foxnews","msnbc",
                              "benshapiro","jimjusticewv","coribush",
                              "reverendwarnock","replipinski","rashidatlaib",
                              "repgosar","cbsnews",
                              "repdlesko","mzhemingway","jonfavs",
                              "mmflint","markos","clairecmc",
                              "ronwyden","thedailybeast","SenAngusKing",
                              "kimreynolds","ronjohnson","mike_pence",
                              "geraldorivera","realdailywire","SidneyPowell1"),
                          screen_name, NA)) %>%
  ggplot()+
  geom_point(aes(x = phi_std, y = rank))+
  geom_text(aes(x = phi_std + .5, y = rank, label = labname))+
  scale_color_OkabeIto(name = "Elite Type")+
  labs(title = "Elite Ideal Points, 2021",
       y = "Rank (Left-Right)", x = "Phi (Standardized)")+
  theme_jg()
ggsave(elites_dist, file = "~/Desktop/GitHub/new-tweetscores/analysis/figures/new_elites_dist.png", width = 8, height = 10)
