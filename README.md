# NRSA Assemblage Modelling

Analysis code for **modelling stream fish assemblages in the Eastern Highlands (Northern and Southern Appalachians) using EPA National Rivers and Streams Assessment (NRSA) data.**

🚧 **Status:** in progress — data preparation workflow nearly complete; modelling to follow.

## Goals

1. Build a site-by-taxon fish presence/absence matrix for first-visit Eastern Highlands sites.
2. Classify sites as reference or non-reference using the NRSA reference-site criteria (water chemistry, riparian disturbance, fine substrate), and split sites 70/30 into model construction and validation sets.
3. Assemble natural environmental predictors unaffected by stress (basin area, precipitation, air temperature, runoff, base flow index, soil permeability and erodibility, plus latitude, longitude and elevation), following the predictor set of Meador & Carlisle (2009).
4. Compare candidate geographic domains (Northern Appalachians, Southern Appalachians, pooled Eastern Highlands) and summarise candidate native taxa for modelling by prevalence at reference sites.

## Data

Raw data are from the **NRSA 2013–2014** survey ("Rivers and Streams 2013-2014"), downloaded 2026-08-18 from the [EPA National Aquatic Resource Surveys](https://www.epa.gov/national-aquatic-resource-surveys/nrsa). Tables in `data_preparation/raw_data/`:

| File | NRSA 2013–2014 table |
|---|---|
| `nrsa1314_fish_counts.csv` | Fish Counts |
| `nrsa1314_fish_taxa.csv` | Fish Taxa List |
| `nrsa1314_site_information.csv` | Site Information |
| `nrsa1314_water_chem.csv` | Water Chemistry |
| `nrsa1314_phab_indic.csv` | Physical Habitat Indicator Metrics |
| `nrsa1314_phab_metrics.csv` | Physical Habitat Most Common Metrics |
| `nrsa1314_land_metrics.csv` | Landscape Metrics |
| `nrsa1314_variable_category_class.csv` | Key Variables and Classification Categories |
| `nrsa1314_technical_support_doc.pdf` | NRSA 2013–2014 Technical Support Document |

## Repository contents

| File / folder | Description |
|---|---|
| `NRSA_assemblage_modelling.Rproj` | RStudio project file |
| `data_preparation/` | Data preparation workflow |
| `data_preparation/data_prep_code.R` | Builds the taxon lookup, presence/absence matrix, site metadata (incl. reference classification), site predictors, exclusion log and variable dictionary; summarises candidate domains and taxa |
| `data_preparation/README.md` | Step-by-step notes documenting each selection and exclusion decision |
| `data_preparation/data_prep_workspace.RData` | Saved R workspace from the data preparation script |
| `data_preparation/raw_data/` | Raw NRSA 2013–2014 tables and technical support document (see [Data](#data)) |

## Reproducing

Open `NRSA_assemblage_modelling.Rproj` in RStudio, install the packages below, set the working directory to `data_preparation/raw_data/` (the script reads the raw CSVs by file name), then run `data_preparation/data_prep_code.R` top to bottom.

```r
install.packages(c("tidyverse", "stringr"))
```

## Author

**Kurt Riggin**: [GitHub](https://github.com/kriggithub) · [ORCID](https://orcid.org/0009-0004-4700-1251)
