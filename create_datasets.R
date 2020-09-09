# Create datasets for ShinyApp

library(tidyverse)
library(lubridate)
library(dplyr)
# Load datasets -----
load(file="/dbfs/mnt/demodata/norpen.RData", verbose=T)


## Persons dataset joined with mortality ----
persons <- persons %>% 
  left_join(mort) %>% 
  mutate(diagnosed=erko307_pv,
         alz_age=as.numeric((diagnosed-syntpv)/365.25),
         alz_age_yrs=as.numeric(round(alz_age)),
         erko_yr=year(diagnosed),  #  or =format(erko307_pv,"%Y")  # year of AD diagnosis
         survived = kuolpv - diagnosed,
         event = ifelse(is.na(kuolpv), 0, 1)
  ) 
persons$sp <- factor(persons$sp, labels=c("Male", "Female"))

# ## Care register first G30 diagnose date from care_reg
# care_reg %>% # calculate 
#   mutate(diag = substr(pdgo, 1, 3)) %>% 
#   filter(diag == "G30") %>% 
#   group_by(idnum, diag) %>% 
#   filter(adm_date == min(adm_date)) %>% 
#   slice(1) %>% 
#   ungroup() %>% 
#   select(idnum, adm_date) %>% 
#   rename(carereg_G30 = adm_date) %>% 
#   right_join(persons) -> persons

# ICD10 labels ------
icd10 <- readRDS("./data/icd10_classes.rds")


## ATC codes data -------------
# unique(substr(drugs$atc, 1, 3))

## L01 ANTINEOPLASTIC AGENTS
## L02 ENDOCRINE THERAPY
## L03 IMMUNOSTIMULANTS
## L04 IMMUNOSUPPRESSANTS
## N02 ANALGESICS
## N05 PSYCHOLEPTICS
## N06 PSYCHOANALEPTICS

atc_codes <- data.frame(
  atc = c("L01", "L02", "L03", "L04", "N02", "N05", "N06"),
  label = c("ANTINEOPLASTIC AGENTS",
            "ENDOCRINE THERAPY",
            "IMMUNOSTIMULANTS",
            "IMMUNOSUPPRESSANTS",
            "ANALGESICS",
            "PSYCHOLEPTICS",
            "PSYCHOANALEPTICS")
)


# Care reg correction ----- 

# there are few rows with short dates, adding century to those
care_reg %>% 
  filter(substr(adm_date, 1, 1) == 7 | substr(adm_date, 1, 1) == 8) %>% 
  mutate(
    adm_date = as.Date(paste0("19", adm_date)),
    disch_date = as.Date(paste0("19", disch_date)), 
  ) -> temp1

care_reg %>% 
  filter(substr(adm_date, 1, 1) != 7 & substr(adm_date, 1, 1) != 8) -> temp2

care_reg <- rbind(temp1, temp2)

rm(list = c("temp1", "temp2"))

## one date problem found
# max(care_reg$adm_date) ## 
# care_reg[care_reg$adm_date == as.Date("2058-12-10"), ] 
# Set this adm_date same as disch_date
care_reg$adm_date[care_reg$adm_date == as.Date("2058-12-10")] <- care_reg$disch_date[care_reg$adm_date == as.Date("2058-12-10")]


### CREATE DATASET FOR TIMELINE -----
### inst_reg + car_reg + mort ---> hospitalizations and mortality timeline


# INSTITUINALIZED DAYS
# hierarchy: care_reg > inst_reg
d1 <- care_reg %>%
  filter(adm_date >= as.Date("1996-01-01")) %>% 
  select(idnum, adm_date, disch_date, pdgo, pdge) %>% 
  mutate(source="care_reg") %>% 
  rename(lhjalkpv=adm_date, lhjlakpv=disch_date) %>% 
  rbind(inst_reg %>% 
          filter(lhjalkpv >= as.Date("1996-01-01")) %>% 
          mutate(source="inst_reg",
                 pdgo = NA,
                 pdge = NA)
  )
## remove duplicates
d1 <- d1[!duplicated(d1),]

## if died mark this to end the hospitilization, dead > care_reg > inst_reg
d1 <- d1 %>% 
  rbind(
    mort %>% 
      rename(lhjalkpv= kuolpv) %>% 
      mutate(lhjlakpv = as.Date("9999-01-01"), ## ADDED THIS
             source="died",
             pdgo = NA,
             pdge = NA)
  )

## New row (censored) for id's who didn't die during the interval
d1 %>% 
  arrange(idnum, lhjalkpv) %>% 
  group_by(idnum) %>% 
  slice_tail(n=1) %>% 
  filter(source != "died" ) -> temp_newrows
## new row by previous data gathered
temp_newrows %>% 
  mutate(
    lhjalkpv = lhjlakpv + 1, 
    lhjlakpv = as.Date("9999-01-01"), 
    pdgo = "",
    pdge = "",
    # day_start = as.integer(lhjalkpv - erko307_pv),
    # day_end = as.integer(lhjlakpv  - erko307_pv), # ADDED THIS
    source = "censored"
  ) -> temp_newrows
## general censored from date ==  "2012-12-31"
temp_newrows$lhjalkpv[temp_newrows$lhjalkpv < as.Date("2012-12-31") | is.na(temp_newrows$lhjalkpv)] <- as.Date("2012-12-31")


## bind with original timeline data
timeline_init <- bind_rows(d1, temp_newrows)
timeline_init$source <- factor(timeline_init$source, levels = c("censored", "died",  "care_reg", "inst_reg"))

# hospitalization harmonization by diagnosed date; start and end dates
timeline_init <- timeline_init %>% 
  left_join(persons %>% select(idnum, erko307_pv)) %>% 
  mutate(day_start = as.integer(lhjalkpv- erko307_pv),
         day_end = as.integer(lhjlakpv - erko307_pv),
         year_start = time_length(lhjalkpv - erko307_pv, "year"),
         year_end = time_length(lhjlakpv - erko307_pv, "year")
  )  

# help source var, hierarchy
timeline_init$source_int[timeline_init$source == "died"] <- 1
timeline_init$source_int[timeline_init$source == "censored"] <- 2
timeline_init$source_int[timeline_init$source == "care_reg"] <- 3
timeline_init$source_int[timeline_init$source == "inst_reg"] <- 4

rm(list = c("d1"))


## Save datasets locally and clean environment ------
if(!dir.exists("./datasets/")) dir.create("./datasets/")
save.image(file="./datasets/alzdatasets.RData") 
# load(file="./datasets/alzdatasets.RData", verbose=T)

## Saving to dbfs folder, NO PERMISSION! -----
# save.image(file="/dbfs/mnt/demodata/shiny-alzdatasets.RData") 
# load(file="/dbfs/mnt/demodata/norpen.RData", verbose=T)

rm(list = ls())
