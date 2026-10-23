library(tidyverse)
library(svglite)

person <- read_csv("data/pslm_person_subset.csv", show_col_types = FALSE)
hh     <- read_csv("data/pslm_hh_subset.csv", show_col_types = FALSE)

df <- person |>
  left_join(select(hh, hhid, hhweight, prov_code, urban_rural), by = "hhid") |>
  filter(prov_code == 2, urban_rural == 1)

lit <- df |> filter(age >= 10, age <= 64, !is.na(literate))
nrow(lit)

p <- ggplot(lit, aes(age, literate)) + geom_point()

dir.create("figures", showWarnings = FALSE)
ggsave("figures/default.svg", p)
