library(tidyverse)
library(svglite)

person <- read_csv("data/pslm_person_subset.csv", show_col_types = FALSE)
hh     <- read_csv("data/pslm_hh_subset.csv", show_col_types = FALSE)

df <- person |>
  left_join(select(hh, hhid, hhweight, prov_code, urban_rural), by = "hhid") |>
  filter(prov_code == 2, urban_rural == 1)

# Students: annual education spending greater than zero
students <- df |> filter(!is.na(ed_total), ed_total > 0)
nrow(students)

wquantile <- function(x, w, p) {
  o  <- order(x)
  x  <- x[o]
  w  <- w[o]
  cs <- cumsum(w) / sum(w)
  x[which(cs >= p)[1]]
}

w <- students$hhweight
x <- students$ed_total

wquantile(x, w, 0.5)                      # weighted median
wquantile(x, rep(1, length(x)), 0.5)      # unweighted median, same definition
wquantile(x, w, 0.1)                      # weighted P10
wquantile(x, w, 0.9)                      # weighted P90
wquantile(x, w, 0.9) / wquantile(x, w, 0.1)   # ratio, report to 2 decimals

# Excluded: log10 spending outside [2, 6]
sum(log10(x) < 2 | log10(x) > 6)

students <- students |> mutate(logx = log10(ed_total))

n_excl <- sum(students$logx < 2 | students$logx > 6)
inrange <- students |> filter(logx >= 2, logx <= 6)

med <- wquantile(x, w, 0.5)
p90 <- wquantile(x, w, 0.9)

n_students <- nrow(students)

base <- ggplot(inrange, aes(x = logx, weight = hhweight)) +
  geom_histogram(aes(y = after_stat(density)),
                 binwidth = 0.1, boundary = 2, closed = "left")

top <- max(ggplot_build(base)$data[[1]]$density)
print(top)   # should be a number around 1.3, not -Inf

p <- base +
  geom_vline(xintercept = log10(c(med, p90)), linetype = "dashed") +
  annotate("text", x = log10(med), y = top * 1.12,
           label = paste0("Median: Rs ", format(med, big.mark = ",")),
           hjust = 1.05) +
  annotate("text", x = log10(p90), y = top * 1.12,
           label = paste0("90th percentile: Rs ", format(p90, big.mark = ",")),
           hjust = -0.05) +
  scale_x_continuous(
    breaks = 2:6,
    labels = c("Rs 100", "Rs 1,000", "Rs 10,000", "Rs 100,000", "Rs 1,000,000")) +
  coord_cartesian(xlim = c(1.85, 6.3), ylim = c(0, top * 1.2), expand = FALSE) +
  labs(
    title = "Spending varies widely",
    x = "Annual education spending per student (Rs)",
    y = "Density per log10 unit",
    caption = paste0(
      "Source: PSLM 2019–20 person and household files.\n",
      "Sample: ", format(n_students, big.mark = ","),
      " students (ed_total > 0), Punjab rural. Weighted by hhweight.\n",
      n_excl, " students outside Rs 100 to Rs 1,000,000 are excluded.")
  ) +
  theme(plot.caption = element_text(hjust = 0),
        plot.caption.position = "plot")

p
ggsave("figures/distribution.svg", p, width = 8, height = 5)