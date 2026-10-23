library(tidyverse)

person <- read_csv("data/pslm_person_subset.csv")
hh     <- read_csv("data/pslm_hh_subset.csv")

glimpse(person)
glimpse(hh)

nrow(person)
nrow(hh)
anyDuplicated(hh$hhid)      # 0 means hhid is unique in the household file
count(person, literate)
count(person, sex)
summary(person$age)
summary(person$ed_total)

hh_small <- hh |> select(hhid, hhweight, prov_code, urban_rural)

df <- person |> left_join(hh_small, by = "hhid")

nrow(df)                      # should equal 107367
sum(is.na(df$hhweight))       # should be 0
count(df, prov_code, urban_rural)

v0 <- df |> filter(prov_code == 2, urban_rural == 1)
nrow(v0)
