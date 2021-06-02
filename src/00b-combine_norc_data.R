library(tidyverse)

restructure_data <- function(y) {
  return(tribble(
    ~screen_name, ~user_id,
    y[1, 1], y[1, 2],
    y[1, 3], y[1, 4]
  ))
}

# initial processing: split primary/secondary handles into two rows
# and assign meta_ids
df1 <- read_tsv("../data/candidates_2020_rehydrated.tsv", col_types=c("ccccccccc"))
df1 <- df1 %>%
    distinct(candidate_id, .keep_all=T) %>%
    nest(data = c(TwitterA, TwitterA_id, TwitterB, TwitterB_id)) %>%
    mutate(dat = map(data, restructure_data)) %>%
    unnest(dat) %>%
    rename(state=STATE) %>%
    select(-data) %>%
    mutate(screen_name = map_chr(screen_name, ~.[[1]]),
           user_id = map_chr(user_id, ~.[[1]])) %>%
    filter(!is.na(user_id))%>%
    mutate(meta_id = str_c("candidate_", candidate_id)) %>%
    select(-X1, -candidate_id) %>%
  select(meta_id, partyfull:user_id)
candidates <- df1 %>%
  select(meta_id, screen_name, user_id) %>%
  mutate(source = "candidates")

df2 <- read_tsv("../data/officials_2020_rehydrated.tsv", col_types = c('ccccccccc'))
df2 <- df2 %>%
    distinct(Name, .keep_all=T) %>%
    nest(data = c(handle, handle_id, handle2, handle2_id)) %>%
    mutate(dat = map(data, restructure_data)) %>%
    unnest(dat) %>%
    select(-data) %>%
    mutate(screen_name = map_chr(screen_name, ~.[[1]]),
           user_id = map_chr(user_id, ~.[[1]])) %>%
    filter(!is.na(user_id))%>%
    mutate(meta_id = str_c("officials_", X1)) %>%
    select(-X1) %>%
  select(meta_id, Name:user_id)
officials <- df2 %>%
  select(meta_id, screen_name, user_id) %>%
  mutate(source="officials")

df3 <- read_tsv("../data/governors_2020_rehydrated.tsv", col_types = c("cccccccccc"))
df3 <- df3 %>%
    distinct(Governor, .keep_all=T) %>%
    nest(data = c(Primary_Handle, Primary_Handle_id, Secondary_Handle, Secondary_Handle_id)) %>%
    mutate(dat = map(data, restructure_data)) %>%
    unnest(dat) %>%
    select(-data) %>%
    mutate(screen_name = map_chr(screen_name, ~.[[1]]),
           user_id = map_chr(user_id, ~.[[1]])) %>%
    filter(!is.na(user_id))%>%
    mutate(meta_id = str_c("governor_", X1)) %>%
    select(-X1) %>%
  select(meta_id, State_or_Territory:user_id)

governors <- df3 %>%
  select(meta_id, screen_name, user_id) %>%
  mutate(source = "governors")

# Use Pablo's 2020 media list (for now?)
media = tribble(
    ~screen_name, ~user_id,
    "EconUS", "32353291",
    "BBCWorld", "742143",
    "NPR", "5392522",
    "NewsHour", "14437914",
    "WSJ", "3108351",
    "ABC", "28785486",
    "CBSNews", "15012486",
    "NBCNews", "14173315",
    "CNN", "759251",
    "USATODAY", "15754281",
    "theblaze", "10774652",
    "nytimes", "807095",
    "washingtonpost", "2467791",
    "msnbc", "2836421",
    "GuardianUS", "16042794",
    "Bloomberg", "104237736",
    "NewYorker", "14677919",
    "politico", "9300262",
    "YahooNews", "7309052",
    "FoxNews", "1367531",
    "MotherJones", "18510860",
    "Slate", "15164565",
    "BreitbartNews", "457984599",
    "HuffPostPol", "15458694",
    "StephenAtHome", "16303106",
    "thinkprogress", "55355654",
    "TheDailyShow", "158414847",
    "dailykos", "20818801",
    "seanhannity", "41634520",
    "FiveThirtyEight", "2303751216",
    "glennbeck", "17454769",
    "BuzzFeedPol", "456806128",
    "voxdotcom", "2347049341",
    "OANN", "1209936918"
)
media <- media %>% mutate(meta_id = str_c("media_", row_number()))
media$source <- "media"

moc_116 <- read_csv("../data/moc116_joined_withUserID.csv", col_types=c("cccccccfcccccn"))
moc_116 <- moc_116 %>%
  rename(meta_id=voteview_id, screen_name=handle) %>%
  mutate(source="moc_116") %>%
  select(source, meta_id, user_id, screen_name)

# assemble everything: load v1 elites file, use anti_join and bind_rows to ensure
# we don't duplicate identities


elites <- read_csv("../data/elites_combined.csv", col_types=c("ccccc"))
elites <- select(elites, -X1)

elites <- bind_rows(elites, anti_join(moc_116, elites, by="user_id"))
elites <- bind_rows(elites, anti_join(media, elites, by="user_id"))
elites <- bind_rows(elites, anti_join(governors, elites, by="user_id"))
elites <- bind_rows(elites, anti_join(officials, elites, by="user_id"))
elites <- bind_rows(elites, anti_join(candidates, elites, by="user_id"))

write_tsv(elites, "../data/elites_combined_v2.tsv")
