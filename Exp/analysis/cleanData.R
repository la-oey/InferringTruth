setwd("/Users/loey/Desktop/Research/FakeNews/WhatIsReality/Exp1_2/analysis/")

library(tidyverse)
raw <- read_csv("raw.csv")

glimpse(raw)
catch <- raw %>%
  filter(catchKey != -1) %>%
  mutate(trialNumber = ifelse(exptPart == "practice", trialNumber - 3, trialNumber)) %>%
  select(subjID, trialNumber, catchQuestion, catchKey, catchResponse) %>%
  mutate(catchQuestion = ifelse(catchQuestion == "How many <b class=\"r\">red</b> marbles did you actually draw (before any changes)?",
                                "How many red marbles did you actually draw (before any changes)?",
                                "How many red marbles did your opponent report drawing?"),
         catchQ = ifelse(catchQuestion == "How many <b class=\"r\">red</b> marbles did you actually draw (before any changes)?",
                         "actually drawn", "opponent report"))

count(catch, subjID) %>% 
  arrange(n)

catchdf <- catch %>%
  group_by(subjID) %>%
  summarise(accuracy = sum(abs(catchResponse-catchKey) <= 5) / n())
  
catchdf %>%
  count(accuracy < .75)
  

trials <- raw %>%
  filter(exptPart == "trial") %>%
  rename(k = drawnRed,
         ksay = reportedRed,
         kest = inferredRed)
length(unique(trials$subjID))

# receiver data out of bounds (0 <= x <= 100)
r.error <- trials %>%
  filter(roleCurrent=="receiver", (kest < 0 | kest > 100)) %>%
  group_by(subjID) %>%
  summarise(n = n()) %>%
  filter(n > 1) %>%
  distinct(subjID) %>%
  pull(subjID)

# sender data out of bounds (0 <= x <= 100)
s.error <- trials %>%
  filter(roleCurrent=="sender", (ksay < 0 | ksay > 100)) %>%
  group_by(subjID) %>%
  summarise(n = n()) %>%
  filter(n > 1) %>% # remove subjects with multiple out of bound trials, remove individual trials for other subjects
  distinct(subjID) %>%
  pull(subjID)

trials <- trials %>%
  left_join(catchdf) %>%
  filter(accuracy >= 0.75,
         !subjID %in% r.error,
         !subjID %in% s.error,
         ksay >= 0, ksay <= 100,
         kest >= 0, kest <= 100)
length(unique(trials$subjID))

trials %>%
  distinct(subjID, cost, goal) %>%
  count(cost, goal)

sender <- filter(trials, roleCurrent=="sender")
write_csv(sender, "sender.csv")
receiver <- filter(trials, roleCurrent=="receiver")
write_csv(receiver, "receiver.csv")
write_csv(trials, "trials.csv")

