library(tidyverse)
library(svglite)

# 1. Load data
hh     <- read_csv("data/pslm_hh_subset.csv", show_col_types = FALSE)
person <- read_csv("data/pslm_person_subset.csv", show_col_types = FALSE)

# 2. Merge and subset variant 0 (Punjab rural)
df <- person %>%
  left_join(select(hh, hhid, hhweight, prov_code, urban_rural), by = "hhid") %>%
  filter(prov_code == 2, urban_rural == 1) %>%
  filter(age >= 10, age <= 64, !is.na(literate))

# 3. Create 11 5-year age bands and assign midpoints (12, 17, ..., 62)
breaks <- seq(10, 65, by = 5)
labels <- c("10–14", "15–19", "20–24", "25–29", "30–34", 
            "35–39", "40–44", "45–49", "50–54", "55–59", "60–64")
midpoints <- seq(12, 62, by = 5)

df <- df %>%
  mutate(
    band_idx = findInterval(age, breaks, rightmost.closed = FALSE),
    band = factor(labels[band_idx], levels = labels),
    midpoint = midpoints[band_idx],
    sex_label = if_else(sex == 1, "Men", "Women")
  )

# 4. Compute unweighted n and weighted literacy rate (%)
band_summary <- df %>%
  group_by(midpoint, band, sex_label) %>%
  summarise(
    n = n(),
    lit_rate = (sum(literate * hhweight) / sum(hhweight)) * 100,
    .groups = "drop"
  ) %>%
  mutate(thin = n < 30)

# Display band table for README
band_table <- band_summary %>%
  select(band, sex_label, n, lit_rate) %>%
  pivot_wider(names_from = sex_label, values_from = c(n, lit_rate))
print(as.data.frame(band_table))

# 5. Identify the band with the maximum gender gap
gap_df <- band_summary %>%
  select(midpoint, band, sex_label, lit_rate) %>%
  pivot_wider(names_from = sex_label, values_from = lit_rate) %>%
  mutate(gap = abs(Men - Women)) %>%
  arrange(desc(gap))

max_gap_row <- gap_df[1, ]
cat(paste0("\nLargest gap is in band ", max_gap_row$band, 
           " (", round(max_gap_row$gap, 1), " pp gap)\n"))

# 6. Plot Question 3
p_lit <- ggplot(band_summary, aes(x = midpoint, y = lit_rate, color = sex_label, group = sex_label)) +
  geom_line(linewidth = 0.9) +
  geom_point(aes(shape = thin, fill = after_scale(color)), size = 2.8, stroke = 1.1) +
  scale_shape_manual(values = c("FALSE" = 19, "TRUE" = 21), guide = "none") +
  # Direct labeling at series end
  geom_text(
    data = band_summary %>% filter(midpoint == 62),
    aes(label = sex_label),
    hjust = -0.25, vjust = 0.5, fontface = "bold", size = 4
  ) +
  # Gap vertical marker line and annotation
  annotate(
    "segment",
    x = max_gap_row$midpoint, xend = max_gap_row$midpoint,
    y = min(max_gap_row$Men, max_gap_row$Women) + 1.5,
    yend = max(max_gap_row$Men, max_gap_row$Women) - 1.5,
    linetype = "dashed", color = "grey35"
  ) +
  annotate(
    "text",
    x = max_gap_row$midpoint,
    y = (max_gap_row$Men + max_gap_row$Women) / 2,
    label = paste0("Largest gap: ", round(max_gap_row$gap, 1), " pp\n(", max_gap_row$band, ")"),
    hjust = 1.1, size = 3.3, fontface = "italic"
  ) +
  scale_x_continuous(
    breaks = midpoints,
    labels = labels,
    limits = c(10, 68) # padding on right for direct text labels
  ) +
  scale_y_continuous(limits = c(0, 100), breaks = seq(0, 100, by = 20)) +
  scale_color_manual(values = c("Men" = "#1f78b4", "Women" = "#e31a1c"), guide = "none") +
  labs(
    title = "Rural literacy improves across cohorts, but older cohorts face large gender gaps",
    x = "Age band (years)",
    y = "Weighted literacy rate (%)",
    caption = paste0(
      "Source: PSLM 2019–20 person and household files.\n",
      "Sample: Persons aged 10–64, Punjab rural. Weighted by hhweight.\n",
      "Hollow markers denote thin cells with fewer than 30 unweighted observations."
    )
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.caption = element_text(hjust = 0, size = 8.5),
    plot.caption.position = "plot",
    panel.grid.minor = element_blank()
  )

print(p_lit)
ggsave("figures/literacy.svg", p_lit, width = 8, height = 5.2)
