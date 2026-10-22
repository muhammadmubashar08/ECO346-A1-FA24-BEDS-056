# ECO346-A1-FA24-BEDS-056

**Course:** ECO346 Data Visualization Techniques for Economists, Assignment 1, Fall 2026
**Name:** YOUR NAME
**Registration no.:** FA24-BEDS-056
**Section:** B

## Variant

Registration number ends in 56, and 56 = 7 × 8 + 0, so **variant 0: Punjab rural**
(`prov_code == 2` and `urban_rural == 1`).

## Repository structure

```
README.md    this file
data/        pslm_person_subset.csv, pslm_hh_subset.csv
scripts/     one script per figure, numbered in the order they run
figures/     every figure, saved as SVG by the scripts
slides/      FA24-BEDS-056.pptx
```

## How to reproduce

Clone the repository and run the scripts in order from the repository root.
No internet connection is needed; the scripts read the local CSVs in `data/`.

1. `scripts/01_default.R` creates `figures/default.svg`
2. `scripts/02_distribution.R` creates `figures/distribution.svg`
3. `scripts/03_literacy.R` creates `figures/literacy_by_age.svg` and the band table
4. `scripts/04_second_language.py` (or `.do`) creates the second-language table and figure

R packages needed: tidyverse, svglite.

## Figure 1: Distribution of education spending (Question 2)

![Distribution of education spending](figures/distribution.svg)

**Key numbers:** TO BE FILLED FROM SCRIPT OUTPUT
(students, weighted and unweighted medians, weighted P10 and P90 and their ratio, number excluded)

**Interpretation (max 80 words):** TO BE WRITTEN

## Figure 2: Literacy by age and sex (Question 3)

![Literacy by age and sex](figures/literacy_by_age.svg)

### Band table

| Age band | Women: n | Women: weighted literacy (%) | Men: n | Men: weighted literacy (%) |
|----------|----------|------------------------------|--------|----------------------------|
| 10–14    |          |                              |        |                            |
| 15–19    |          |                              |        |                            |
| 20–24    |          |                              |        |                            |
| 25–29    |          |                              |        |                            |
| 30–34    |          |                              |        |                            |
| 35–39    |          |                              |        |                            |
| 40–44    |          |                              |        |                            |
| 45–49    |          |                              |        |                            |
| 50–54    |          |                              |        |                            |
| 55–59    |          |                              |        |                            |
| 60–64    |          |                              |        |                            |

**Key numbers:** TO BE FILLED FROM SCRIPT OUTPUT
(women and men aged 15–19 and 55–59, band with the largest gap)

**Interpretation (max 100 words):** TO BE WRITTEN, including one thing the figure cannot tell us.

## Makeover (Question 4)

Default: `figures/default.svg` | Redesign: `figures/literacy_by_age.svg`

**Explanation (max 150 words):** TO BE WRITTEN (three changes, each tied to a principle,
plus one thing the default shows that the redesign hides)

## Second language (Question 5)

Language used: Python / Stata (delete one)

![Second-language figure](figures/literacy_by_age_python.svg)

**Literacy rate of women aged 15–19:** R = __ , second language = __

**Difference in defaults (max 80 words):** TO BE WRITTEN

## Data source

PSLM 2019–20 person and household files (course repository: github.com/rafi-amiruddin/DVTE).
All statistics are weighted by `hhweight` unless stated otherwise.