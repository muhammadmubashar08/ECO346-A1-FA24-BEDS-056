import os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from pathlib import Path
# Move to the repo root (the folder above scripts/) so the relative
# paths below work no matter where the script is launched from.
os.chdir(Path(__file__).resolve().parent.parent)

# --- Load and merge (relative paths, no internet) ---
person = pd.read_csv("data/pslm_person_subset.csv")
hh = pd.read_csv("data/pslm_hh_subset.csv")

df = person.merge(hh[["hhid", "hhweight", "prov_code", "urban_rural"]],
                  on="hhid", how="left", validate="m:1")
df = df[(df.prov_code == 2) & (df.urban_rural == 1)]   # variant 0: Punjab rural

# --- Literacy sample ---
lit = df[(df.age >= 10) & (df.age <= 64) & df.literate.notna()].copy()
print("Literacy sample:", len(lit))

# --- Bands: left-closed, [10,15), [15,20), ... ---
edges = list(range(10, 70, 5))
labels = [f"{a}–{a + 4}" for a in range(10, 65, 5)]
lit["band"] = pd.cut(lit.age, bins=edges, right=False, labels=labels)
lit["mid"] = (lit.age // 5) * 5 + 2
lit["sex_lab"] = np.where(lit.sex == 1, "Men", "Women")

# --- Weighted literacy rate = sum(w*x) / sum(w) ---
lit["wl"] = lit.hhweight * lit.literate
tab = (lit.groupby(["band", "mid", "sex_lab"], observed=True)
          .agg(n=("age", "size"), wl=("wl", "sum"), w=("hhweight", "sum"))
          .reset_index())
tab["rate"] = (100 * tab.wl / tab.w).round(1)
tab["thin"] = tab.n < 30
tab = tab[["band", "mid", "sex_lab", "n", "rate", "thin"]]
print(tab.to_string())

# --- Compare with R's table ---
r = pd.read_csv("tables/band_table_R.csv")
chk = tab.merge(r, on=["mid", "sex_lab"], suffixes=("_py", "_R"))
print("Max absolute difference in rate:", (chk.rate_py - chk.rate_R).abs().max())

# --- Figure ---
cols = {"Men": "#1f77b4", "Women": "#d62728"}
fig, ax = plt.subplots(figsize=(8, 5))

for sex, g in tab.groupby("sex_lab"):
    g = g.sort_values("mid")
    ax.plot(g.mid, g.rate, color=cols[sex], linewidth=1.8)
    face = ["white" if t else cols[sex] for t in g.thin]
    ax.scatter(g.mid, g.rate, s=45, facecolors=face,
               edgecolors=cols[sex], linewidths=1.5, zorder=3)
    last = g.iloc[-1]
    ax.text(last.mid + 0.8, last.rate, sex, color=cols[sex],
            fontweight="bold", va="center")

wide = tab.pivot(index="mid", columns="sex_lab", values="rate")
wide["gap"] = (wide.Men - wide.Women).abs()
m = wide.gap.idxmax()
ax.plot([m, m], [wide.loc[m, "Women"], wide.loc[m, "Men"]], color="grey")
ax.text(m - 0.7, (wide.loc[m, "Men"] + wide.loc[m, "Women"]) / 2,
        f"Largest gap: {wide.loc[m, 'gap']:.1f} points", ha="right",
        va="center", color="dimgrey")

ax.set_xticks(range(12, 63, 5))
ax.set_xticklabels(labels, fontsize=8)
ax.set_xlim(10, 68)
ax.set_ylim(0, 100)
ax.set_yticks(range(0, 101, 20))
ax.set_yticklabels([f"{v}%" for v in range(0, 101, 20)])
ax.set_xlabel("Age band (plotted at band midpoints)")
ax.set_ylabel("Literacy rate (weighted)")
ax.set_title("Women fall behind with age", loc="left")
for side in ("top", "right"):
    ax.spines[side].set_visible(False)

fig.text(0.01, 0.01,
         "Source: PSLM 2019–20 person and household files.\n"
         f"Sample: {len(lit):,} persons aged 10–64 with literate not missing, "
         "Punjab rural. Weighted by hhweight.\n"
         "Hollow markers mark bands with fewer than 30 observations (none occur here).",
         ha="left", va="bottom", fontsize=7)
fig.tight_layout(rect=(0, 0.08, 1, 1))

os.makedirs("figures", exist_ok=True)
plt.savefig("figures/literacy_by_age_python.svg")