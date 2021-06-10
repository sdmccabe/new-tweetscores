library(tidyverse)

restructure_data <- function (y) {
  return(tribble(
    ~screen_name, ~user_id,
    y[1, 1], y[1, 2],
    y[1, 3], y[1, 4]
  ))
}

moc_117 <- read_tsv("../data/source_files/moc_117_corrected.tsv", col_types=c("ccc"))
moc_117 <- moc_117 %>% rename(meta_id=id_117, screen_name=handle)

covid_elites <- read_tsv("../data/source_files/political_covid_elites_corrected.tsv", col_types=c("ccccc"))
covid_elites <- covid_elites %>% select(user_id, screen_name)

moc_116 <- read_csv("../data/source_files/moc116_joined_withUserID.csv", col_types=c("cccccccfcccccn"))
moc_116 <- moc_116 %>%
  rename(meta_id=voteview_id, screen_name=handle) %>%
  mutate(source="moc_116") %>%
  select(meta_id, user_id, screen_name)

presidents <- read_csv("../data/source_files/presidents.csv", col_types=c("ccccc"))
presidents <- select(presidents, -X1, -source)

pundits <- read_csv("../data/source_files/pundits.csv", col_types=c("ccc"))
pundits$X1 <- NULL

# initial processing: split primary/secondary handles into two rows
candidates <- read_tsv("../data/source_files/candidates_2020_rehydrated.tsv", col_types=c("ccccccccc"))
candidates <- candidates %>%
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

candidates <- candidates %>%
  select(meta_id, screen_name, user_id)

officials <- read_tsv("../data/source_files/officials_2020_rehydrated.tsv", col_types = c('ccccccccc'))
officials <- officials %>%
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

officials <- officials %>%
  select(meta_id, screen_name, user_id)

governors <- read_tsv("../data/source_files/governors_2020_rehydrated.tsv", col_types = c("cccccccccc"))
governors <- governors %>%
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

governors <- governors %>%
   select(meta_id, screen_name, user_id)

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

# need vectors of IDs so that list membership can be assigned
moc_117_ids <- moc_117$user_id
moc_116_ids <- moc_116$user_id
pundits_ids <- pundits$user_id
covid_elites_ids <- covid_elites$user_id
presidents_ids <- presidents$user_id
media_ids <- media$user_id
candidate_ids <- candidates$user_id
official_ids <- officials$user_id
governors_ids <- governors$user_id

elites <- bind_rows(moc_117, anti_join(moc_116, moc_117, by="user_id")) %>% 
    bind_rows(., anti_join(presidents, ., by="user_id")) %>%
    bind_rows(., anti_join(governors, ., by="user_id")) %>%
    bind_rows(., anti_join(candidates, ., by="user_id")) %>%
    bind_rows(., anti_join(officials, ., by="user_id")) %>%
    bind_rows(., anti_join(media, ., by="user_id")) %>%
    bind_rows(., anti_join(pundits, ., by="user_id")) %>%
    bind_rows(., anti_join(covid_elites, ., by="user_id"))%>% 
    mutate(meta_id = coalesce(meta_id, str_c("meta_", row_number())),
          moc_117 = as.integer(user_id %in% moc_117_ids),
           moc_116 = as.integer(user_id %in% moc_116_ids),
           pundit = as.integer(user_id %in% pundits_ids),
           covid_elite = as.integer(user_id %in% covid_elites_ids),
           president = as.integer(user_id %in% presidents_ids),
           media = as.integer(user_id %in% media_ids),
           candidate = as.integer(user_id %in% candidate_ids),
           governor = as.integer(user_id %in% governors_ids),
           official = as.integer(user_id %in% official_ids)) 

write.table(elites, "../data/elites_combined_v2.tsv", sep="\t", row.names=F)