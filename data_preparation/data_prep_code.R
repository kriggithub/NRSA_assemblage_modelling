#### Data Preparation for JSDM Application to O/E Predictive Modeling
#### K. Riggin September 18, 2026
#### This code produces three files from raw 2013-2014 NRSA data:
#### (1) fish_count_table = All fish data (will need to subset out the catostomids)
#### (2) environment_table = The environmental variables unaffected by stress (see sources for description)
#### (3) reference_table = Determines reference condition of sites and indicates
#### whether site should be used in model construction ("C") or validation ("V")
####
#### NOTES: Using UID and SITE_ID as unique sample keys depending on data set.
#### Only including first visit to a site.
#### Reminder: We are only modeling the reference sites in the calibration set


#### Step 1: Load packages and set working directory
library(tidyverse)
library(stringr)

# setwd("~/Academics/R/NRSA_assemblege_modelling/data_preparation/raw_data")


#### Step 2:

# Load in fish taxon data
fish_taxa_data <- read.csv("nrsa1314_fish_taxa.csv", header = T)

# Potential fish trait table
# fish_traits <- fish_taxa_data |>
#   select(TAXA_ID, HABITAT_NRSA, MIGR_NRSA, REPROD_NRSA, TROPHIC_NRSA,
#          TEMP_NRSA, VEL_NRSA, TOLERANCE_NRSA, TOL_VAL_EMAPW)

# Select columns for taxon lookup table
taxon_lookup <- fish_taxa_data |>
  select(TAXA_ID, FINAL_NAME, FAMILY, GENUS, SPECIES, HERP, ITISTSN) |>
  rename(taxa_id = TAXA_ID,
         orig_name = FINAL_NAME,
         family = FAMILY,
         genus = GENUS,
         species = SPECIES,
         herp = HERP,
         itis_tsn = ITISTSN)

# Adjust names
taxon_lookup$orig_name <- str_to_title(taxon_lookup$orig_name)
taxon_lookup$family <- str_to_title(taxon_lookup$family)
taxon_lookup$genus <- str_to_title(taxon_lookup$genus)
taxon_lookup$species <- str_to_lower(taxon_lookup$species)

# Check to see if all eligible fish have species names
taxon_lookup |>
  filter(species == "") |>
  pull(orig_name)

# Exclude non-fish, hybrids, and unknowns
taxon_lookup <- taxon_lookup |>
  mutate(
    decision = case_when(
      herp == "A" ~ "excluded", # Non-fish
      str_detect(orig_name,"Hybrid") ~ "excluded", # Hybrid
      str_detect(orig_name," X ") ~ "excluded", # Hybrid
      str_detect(orig_name,"Unknown") ~ "excluded",
      str_detect(orig_name,"No Fish") ~ "excluded",
      str_detect(orig_name,"Lamprey Ammocoete") ~ "excluded",
      str_detect(species,"cf.") ~ "excluded",
      str_detect(species,"c.f.") ~ "excluded",
      str_detect(species," x ") ~ "excluded",
      taxa_id == 358 ~ "excluded" # Plains Minnow Or Western Silvery Minnow
    ),
    reason = case_when(
      herp == "A" ~ "non_fish", # Non-fish
      str_detect(orig_name,"Hybrid") ~ "hybrid_id",
      str_detect(orig_name," X ") ~ "hybrid_id",
      str_detect(orig_name,"Unknown") ~ "unknown_id",
      str_detect(orig_name,"No Fish") ~ "non_descriptive",
      str_detect(orig_name,"Lamprey Ammocoete") ~ "non_descriptive",
      str_detect(species,"cf.") ~ "unknown_id",
      str_detect(species,"c.f.") ~ "unknown_id",
      str_detect(species," x ") ~ "hybrid_id",
      taxa_id == 358 ~ "non_descriptive" # Plains Minnow Or Western Silvery Minnow
    )
  )

# Check again for species names
taxon_lookup |>
  filter(species == "", !(decision %in% "excluded")) |>
  pull(orig_name)

# Fill in Shorttail Redhorse
taxon_lookup <- taxon_lookup |>
  mutate(species = if_else(taxa_id == 5079, "macrolepidotum", species))

# Check for non-alphabetic character species names
taxon_lookup |>
  filter(str_detect(species, "[^A-Za-z]"), !(decision %in% "excluded")) |>
  select(taxa_id, orig_name, genus, species, decision)












# Create taxon codes
taxon_lookup <- taxon_lookup |>
  mutate(
    taxon_code = if_else(
      !(decision %in% "excluded"),
      str_replace_all(str_to_lower(paste(genus, species)), "[^a-z0-9]+", "_"),
      NA_character_
    )
  )

# Check for duplicates
taxon_lookup |>
  filter(!is.na(taxon_code)) |>
  count(taxon_code) |>
  filter(n > 1)


# !!!!!!!!!!! Kris Review (most likely aggregate, add in note for now)
dupe_ids <- taxon_lookup |>
  filter(!is.na(taxon_code)) |>
  add_count(taxon_code, name = "n") |>
  filter(n > 1) |>
  pull(taxa_id)








taxon_lookup <- taxon_lookup |>
  mutate(note = if_else(taxa_id %in% dupe_ids, "dupe_taxon_code", NA_character_))



########### Need to add native status for each species







# Load in fish count data
fish_count_data <- read.csv("nrsa1314_fish_counts.csv", header = T)





# Filter data to first visit to each site, and to Eastern Highlands (add to exclusion log)
fish_count_exclusion_log <- fish_count_data |>
  distinct(UID, SITE_ID, VISIT_NO, AG_ECO9_NM) |>
  filter(!(VISIT_NO == 1 &
             AG_ECO9_NM %in% c("Southern Appalachians", "Northern Appalachians"))) |>
  mutate(
    level = "site_visit",
    reason = case_when(
      !(AG_ECO9_NM %in% c("Southern Appalachians", "Northern Appalachians")) ~ "wrong_ecoregion",
      !(VISIT_NO %in% 1)                                                    ~ "non_first_visit",
      TRUE                                                                   ~ "unknown"
    )
  ) |>
  select(level, uid = UID, site_id = SITE_ID, name = AG_ECO9_NM, reason)



site_taxon_pa <- fish_count_data |>
  filter(VISIT_NO == 1,
         AG_ECO9_NM %in% c("Southern Appalachians", "Northern Appalachians"))




# Update this
# taxa_exclusion_log <- site_taxon_pa |>
#   left_join(taxon_lookup |> select(taxa_id, taxon_code, reason),
#             by = c("TAXA_ID" = "taxa_id")) |>
#   filter(is.na(taxon_code)) |>
#   count(TAXA_ID, FINAL_NAME, reason, name = "n_records") |>
#   mutate(
#     level = "taxon",
#     reason = coalesce(reason, "not in lookup")
#   ) |>
#   select(level, id = TAXA_ID, name = FINAL_NAME, reason, n_records)
#
# exclusion_log <- bind_rows(fish_count_exclusion_log, taxa_exclusion_log)



# Summarize by irregulars
n_sites_eh <- n_distinct(site_taxon_pa$UID)

flagged <- site_taxon_pa |>
  left_join(taxon_lookup |> select(taxa_id, orig_name, taxon_code, reason),
            by = c("TAXA_ID" = "taxa_id")) |>
  filter(reason %in% c("hybrid_id", "unknown_id"))

# by reason
flagged |>
  distinct(UID, reason) |>
  count(reason, name = "n_sites") |>
  mutate(pct_eh = round(100 * n_sites / n_sites_eh, 1))






# look at incident range, across all sites, for each irregular, whats the proportion that it made across the sites
# such as 0% to 2%, using counts
# for p/a, what % did we see this taxon across our sites for each species





# Pivot into fish count table by UID
site_taxon_pa <- site_taxon_pa |>
  left_join(taxon_lookup |> select(taxa_id, taxon_code),
            by = c("TAXA_ID" = "taxa_id")) |>
  filter(!is.na(taxon_code)) |>
  pivot_wider(id_cols = UID, names_from = taxon_code,
              values_from = TOTAL, values_fill = 0)


# Change to presence absence
site_taxon_pa <- site_taxon_pa |>
  mutate(across(-UID, ~ as.integer(.x > 0)))










# NRSA reference site assessment https://www.epa.gov/national-aquatic-resource-surveys/national-rivers-and-streams-assessment-2013-2014-technical pp.35
set.seed(123)

chemical_indicator_data <- read.csv("nrsa1314_chem_indic.csv")

# Has ANC + DOC, PTL, NTL

chemical_data <- read.csv("nrsa1314_water_chem.csv")

# Has CHLORIDE_RESULT,  SULFATE_RESULT, TURB_RESULT,

habitat_indicator_data <- read.csv("nrsa1314_phab_indic.csv")

# Has riparian disturbance index W1_HALL


habitat_data <- read.csv("nrsa1314_phab_metrics.csv")
# Has PCT_FN


# Grab conditions for each site
reference_table <- chemical_indicator_data |>
  inner_join(chemical_data, by = c("UID")) |>
  filter(VISIT_NO.x == 1, AG_ECO9_NM.x %in% c("Southern Appalachians", "Northern Appalachians")) |>
  inner_join(habitat_data, by = c("UID")) |>
  inner_join(habitat_indicator_data, by = c("UID")) |>
  select(
    UID,
    SITE_ID = SITE_ID.x,
    AG_ECO9_NM = AG_ECO9_NM.x,
    total_P = PTL,
    total_N = NTL_UG_L,
    chloride = CHLORIDE_RESULT,
    sulfate = SULFATE_RESULT,
    ANC,
    DOC,
    turbidity = TURB_RESULT,
    RDI = W1_HALL.x,
    pct_fine = PCT_FN
  )



mean(reference_table$ANC)


# Select reference sites  !!!!!!!!!!!!!!!!!!!!!!!!! What to do about cl criterion not being applied in northeastern coastal zone (chloride_ueq <= 250 | ecoregion_3 %in% c(1,59)) for north
reference_sites <- reference_table |>
  mutate(chloride_ueq = chloride*1000/35.45,
         sulfate_ueq = sulfate*1000/96.06*2) |>
  mutate(pass_nap = (total_P <= 20) +
           (total_N <= 750) +
           (chloride_ueq <= 250) +
           (sulfate_ueq <= 250) +
           (ANC >= 50 | DOC >= 5) +
           (turbidity <=5) +
           (RDI <= 2) +
           (pct_fine <= 25),
         pass_sap = (total_P <= 20) +
           (total_N <= 750) +
           (chloride_ueq <= 200) +
           (sulfate_ueq <= 400) +
           (ANC >= 50 | DOC >= 5) +
           (turbidity <=5) +
           (RDI <= 2) +
           (pct_fine <= 25)) |>
  mutate(
    ref_cond = case_when(
    AG_ECO9_NM == "Northern Appalachians" & pass_nap == 8 ~ "REF",
    AG_ECO9_NM == "Southern Appalachians" & pass_sap == 8 ~ "REF",
    .default = "NON-REF"), val_cond = sample(x=c("C","V"),size=n(), replace="TRUE",prob=c(0.70,0.30)))



# ????????????????????? ask
# total_P in ug/L, total_N in ug/L, chloride in mg/L (adjusted), sulfate in mg/L (adjusted), ANC in mg N/L?????, DOC in mg/L, turbidity in NTU

sum(reference_sites$ref_cond == "REF") # 59 total reference sites


sum(reference_sites$ref_cond == "REF" & reference_sites$AG_ECO9_NM == "Northern Appalachians") # 38
sum(reference_sites$ref_cond == "REF" & reference_sites$AG_ECO9_NM == "Southern Appalachians") # 21

table(reference_sites$ref_cond, reference_sites$val_cond, reference_sites$AG_ECO9_NM)




# check technical support documents to see if number of reference sites was similar



site_data <- read.csv("nrsa1314_site_information.csv")








