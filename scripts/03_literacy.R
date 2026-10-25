library(tidyverse)
library(svglite)

person <- read_csv("data/pslm_person_subset.csv", show_col_types = FALSE)
hh     <- read_csv("data/pslm_hh_subset.csv", show_col_types = FALSE)

df <- person |>
  left_join(select(hh, hhid, hhweight, prov_code, urban_rural), by = "hhid") |>
  filter(prov_code == 2, urban_rural == 1)

lit <- df |> filter(age >= 10, age <= 64, !is.na(literate))
nrow(lit)

lit <- lit |>
  mutate(
    band = cut(age, breaks = seq(10, 65, by = 5), right = FALSE,
               labels = paste(seq(10, 60, by = 5), seq(14, 64, by = 5), sep = "–")),
    mid  = seq(12, 62, by = 5)[as.integer(band)],
    sex_lab = if_else(sex == 1, "Men", "Women")
  )

tab <- lit |>
  group_by(band, mid, sex_lab) |>
  summarise(n = n(),
            rate = round(100 * sum(hhweight * literate) / sum(hhweight), 1),
            .groups = "drop") |>
  mutate(thin = n < 30)

print(tab, n = Inf)

wide <- tab |>
  select(band, sex_lab, rate) |>
  pivot_wider(names_from = sex_lab, values_from = rate) |>
  mutate(gap = abs(Men - Women))

print(wide, n = Inf)
wide |> slice_max(gap, n = 1)

cols <- c(Men = "#1f77b4", Women = "#d62728")

ends <- tab |> filter(mid == max(mid))
big  <- wide |> slice_max(gap, n = 1) |>
  mutate(mid = 57, ymid = (Men + Women) / 2)

p <- ggplot(tab, aes(mid, rate, colour = sex_lab, group = sex_lab)) +
  geom_line(linewidth = 0.8) +
  geom_point(aes(fill = if_else(thin, "white", unname(cols[sex_lab]))),
             shape = 21, size = 3, stroke = 1) +
  scale_fill_identity() +
  scale_colour_manual(values = cols, guide = "none") +
  geom_text(data = ends, aes(label = sex_lab), hjust = -0.2,
            fontface = "bold", show.legend = FALSE) +
  annotate("segment", x = big$mid, xend = big$mid,
           y = big$Women, yend = big$Men, colour = "grey30") +
  annotate("text", x = big$mid - 0.7, y = big$ymid, hjust = 1,
           label = paste0("Largest gap: ", big$gap, " points\n(ages ", big$band, ")"),
           colour = "grey30") +
  scale_x_continuous(breaks = seq(12, 62, by = 5), labels = levels(lit$band)) +
  scale_y_continuous(limits = c(0, 100), breaks = seq(0, 100, 20),
                     labels = function(v) paste0(v, "%")) +
  coord_cartesian(xlim = c(10, 68)) +
  labs(
    title = "Women fall behind with age",
    x = "Age band (plotted at band midpoints)",
    y = "Literacy rate (weighted)",
    caption = paste0(
      "Source: PSLM 2019–20 person and household files.\n",
      "Sample: ", format(nrow(lit), big.mark = ","),
      " persons aged 10–64 with literate not missing, Punjab rural. Weighted by hhweight.\n",
      "Hollow markers mark bands with fewer than 30 observations (none occur here).")
  ) +
  theme(plot.caption = element_text(hjust = 0),
        plot.caption.position = "plot")

p
dir.create("figures", showWarnings = FALSE)
ggsave("figures/literacy_by_age.svg", p, width = 8, height = 5)

dir.create("tables", showWarnings = FALSE)
write_csv(tab, "tables/band_table_R.csv")
