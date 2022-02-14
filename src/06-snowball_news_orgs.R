# snowball sample news media accounts
library(tidyverse)
library(rtweet)

tw_token <- 
  rtweet::create_token(
    app = "your_app",
    consumer_key = "your_key",
    consumer_secret = "your_secret",
    access_token = "your_token",
    access_secret = "your_secret"
  )

check.limits <- function(){
  rl <- rtweet::rate_limits()
  limits <- rl[rl$limit > rl$remaining,]
  return(limits)
}

seed.orgs <- c("nytimes","foxnews","breitbartnews","washingtonpost",
               "nro","latimes","realdailywire","newrepublic",
               "rollingstone","nymag","voxdotcom",
               "dailycaller","thehill","realclearnews",
               "theeconomist","msnbc","cnn","cnnbrk",
               "cbsnews","abcnews","nbcnews",
               "theblaze","oann")

keystring <- "news|politics|opinion"

snowfunc <- function(seed, keys){
  message("get initial left lists...")
  
  init.list.ids <- lapply(seed, function(x){
    lists <- rtweet::lists_memberships(x)
    list.ids <- lists$list_id[grep(keystring, lists$name, ignore.case = T)]
    return(list.ids)
  })
  
  lists <- unique(unlist(init.list.ids))
  
  message("get snowballed accts...")
  
  list.members <- bind_rows(lapply(lists, function(x){
    rtweet::lists_members(x)
  }))
  
  nlist <- list.members %>% count(screen_name) %>% arrange(desc(n))
  
  list_trunc <- list.members %>% 
    left_join(nlist, by = "screen_name") %>%
    arrange(desc(n)) %>%
    filter(!duplicated(screen_name)) %>%
    mutate(prop = n/length(lists)) %>%
    filter(prop >= .05)

  users_2 <- tolower(unique(list_trunc$screen_name[-which(tolower(list_trunc$screen_name) %in% seed)]))
  
  c <- check.limits() %>%
    filter(grepl('lists/memberships', query))
  
  i <- 0
  
  message("get snowballed list ids 2...")
  
  if(nrow(c) > 0){
    pauses <- seq(from = c$remaining - 1, to = length(users_2), by = 75)
  }else{
    pauses <- seq(from = 74, to = length(users_2), by = 75)
  }
  
  list.ids2 <- lapply(users_2, function(x){
    i <<- i+1
    if(i %in% pauses){
      message(paste0("pausing to re-up rate limit, ", round(i / length(users_2), 3)*100, "% done..."))
      Sys.sleep(1000)
    }
    lists <- rtweet::lists_memberships(x)
    list.ids <- lists$list_id[grep(keys, lists$name, ignore.case = T)]
    return(list.ids)
  })
  
  lists_2 <- unique(unlist(list.ids2))
  
  # checking rate limits
  c <- check.limits() %>%
    filter(query == "lists/members")
  
  i <- 0
  
  if(nrow(c) > 0 & length(lists_2) > 900){
    pauses <- seq(from = c$remaining - 1, to = length(lists_2), by = 900)
  }
  if(nrow(c) == 0  & length(lists_2) > 900) {
    pauses <- seq(from = 900, to = length(lists_2), by = 900)
  }else{
    pauses <- 900
  }
  
  message("get snowballed accts 2...")
  
  list.members2 <- bind_rows(lapply(lists_2, function(x){
    i <<- i+1
    if(i %in% pauses){
      message(paste0("pausing to re-up rate limit, ", round(i / length(lists_2), 3)*100, "% done..."))
      Sys.sleep(920)
    }
    rtweet::lists_members(x)
  }))
  
  nlist2 <- list.members2 %>% count(screen_name) %>% arrange(desc(n))
  
  list_trunc2 <- list.members2 %>% 
    left_join(nlist2, by = "screen_name") %>%
    arrange(desc(n)) %>%
    filter(!duplicated(screen_name)) %>%
    mutate(prop = n / length(lists_2)) %>%
    filter(prop >= .05)
  
  list_stack <- bind_rows(list_trunc, 
                          list_trunc2) %>%
    filter(!duplicated(screen_name))

  return(list_stack)
}

news_snowball <- snowfunc(seed = seed.orgs, keys = keystring)

write.csv(news_snowball, file = "~/Desktop/GitHub/new-tweetscores/data/source_files/snowball_news_orgs_prescrub.csv")

