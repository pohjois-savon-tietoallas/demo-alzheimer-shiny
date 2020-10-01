library(tidyverse)
# Load datasets
load(file="./datasets/alzdatasets.RData", verbose=T)

atc_labels <- readr::read_csv2("data/atc_raw.csv")

atc_level <- 3
drugs %>% 
  left_join(persons) %>% 
  # filter(!is.na(alz_age)) %>% 
  mutate(
    atc_code = substr(atc, 1, atc_level),
    gap = otpvm - erko307_pv) %>% 
  filter(gap >= -365, gap <= 0) %>% 
  select(idnum, atc_code) %>% 
  group_by(atc_code) %>% 
  summarise(n=n(),
            uniq=length(unique(idnum)),
            time="before") %>% 
  mutate(
    percentage = 100 * uniq / nrow(persons)
  ) %>% 
  select(atc_code, time, percentage) -> d1

d1 <- d1 %>% left_join(atc_labels)

ggplot(data = d1, aes(x=paste0(atc_code, " ", label), y=percentage, fill=atc_code)) +
  geom_bar( stat="identity") +
  coord_flip() + 
  scale_y_continuous(limits = c(0,100), breaks = c(0,25,50,75,100)) +
  geom_label(aes(label = label, hjust = 0)) +
  labs(title=paste0("Medicine usage between ", 9999, " and ", 9999, " days before diagnose"), 
       x = "ATC class", 
       y = "% of patients")



ggplot(data = d1, aes(x=atc_code, y=percentage, fill=atc_code)) +
  geom_bar( stat="identity") +
  geom_text(aes(label = paste0(atc_code, " ", label), y=0, hjust = 0, vjust=0)) +
  coord_flip() + 
  scale_y_continuous(limits = c(0,100), breaks = c(0,25,50,75,100)) +
  labs(title=paste0("Medicine usage between ", 9999, " and ", 9999, " days before diagnose"), 
       x = "ATC class", 
       y = "% of patients") + guides(fill=FALSE)

