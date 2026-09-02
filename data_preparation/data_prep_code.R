#### Data Preparation for NRSA Assemblage Modelling Protocol
#### K. Riggin September 18, 2026
#### This code produces six files from raw 2013-2014 NRSA data:
#### (1) site_taxon_pa.csv = Site-by-taxon presence/absence matrix.
#### (2) site_predictors.csv = Natural environmental predictor matrix.
#### (3) site_metadata.csv = Site metadata including hydrologic spatial identifiers (HUC8), and reference condition classifications.
#### (4) taxon_lookup.csv = Taxonomic metadata of original names, taxon codes, common name, taxonomy, and prevalence in Eastern Highlands (EH).
#### (5) exclusion_log.csv = Log of each excluded site, sample, record, taxon, or variable.
#### (6) variable_dictionary.csv = Description of all variables, with source files, original/final fields, descriptions, and transformations.
####
#### NOTES: Please reference README.md within the data_preparation folder for each exclusion decision and reproduction steps.
#### NOTES: UID was the primary variable used to join data sets.


#### Step 1: Load packages and set working directory
library(tidyverse)
library(stringr)

# Change to file location of raw_data folder
# setwd("~/Academics/R/NRSA_assemblege_modelling/data_preparation/raw_data")




#### Step 2: Build taxon lookup table

# Load in fish taxon data
fish_taxa_data <- read.csv("nrsa1314_fish_taxa.csv", header = T)

# Potential fish trait variables
# trait_cols <- c("HABITAT_NRSA", "MIGR_NRSA", "REPROD_NRSA", "TROPHIC_NRSA",
#                 "TEMP_NRSA", "VEL_NRSA", "TOLERANCE_NRSA", "TOL_VAL_EMAPW")

# Select columns for taxon lookup table
taxon_cols <- c(
  taxa_id   = "TAXA_ID",
  orig_name = "FINAL_NAME",
  family    = "FAMILY",
  genus     = "GENUS",
  species   = "SPECIES",
  herp      = "HERP",
  itis_tsn  = "ITISTSN"
)

taxon_lookup <- fish_taxa_data |>
  select(all_of(taxon_cols))

# Add selected columns into variable dictionary
variable_dictionary <- tribble(
  ~orig_field,  ~final_field,  ~type,        ~units, ~description, ~transformation, ~missing_rule, ~model_eligible,

  "TAXA_ID",    "taxa_id",     "integer",    NA,
  "EPA taxonomic ID number; primary key to fish count records.",
  "None.",
  "Never missing; a missing value is a defect and the row is dropped to the exclusion log.",
  "key_only",

  "FINAL_NAME", "orig_name",   "character",  NA,
  "Final common name assigned to fish count data.",
  "str_to_title().",
  "Never missing; used to detect unusable records ('Unknown', 'No Fish', 'Hybrid', ' X ').",
  "label_only",

  "FAMILY",     "family",      "character",  NA,
  "Taxonomic family.",
  "str_to_title().",
  "Blank ('') treated as missing; retained, flagged for review.",
  "eligible",

  "GENUS",      "genus",       "character",  NA,
  "Genus of taxon, if available.",
  "str_to_title().",
  "Blank ('') treated as missing; taxon cannot form a taxon_code and is excluded.",
  "eligible",

  "SPECIES",    "species",     "character",  NA,
  "Species epithet of taxon, if available.",
  "str_to_lower(); manual fill for taxa_id 5079 (macrolepidotum).",
  "Blank ('') is structural, meaning ID stopped at genus. Not imputed.",
  "eligible",

  "HERP",       "herp",        "character",  NA,
  "Non-fish flag: A = amphibian, R = reptile.",
  "None.",
  "Blank ('') is the normal case and means the taxon is a fish. Not imputed.",
  "filter_only",

  "ITISTSN",    "itis_tsn",    "integer",    NA,
  "ITIS Taxonomic Serial Number.",
  "None.",
  "Missing where no ITIS match exists; retained as NA, used only for external joins.",
  "key_only"
) |>
  mutate(source_file = "nrsa1314_fish_taxa.csv", final_file = "taxon_lookup.csv", .before = 1)

variable_dictionary_dict <- tribble(
  ~orig_field, ~final_field, ~type, ~units, ~description, ~transformation, ~missing_rule, ~model_eligible,

  NA, "source_file", "character", NA,
  "Name of the raw file the variable was read from; 'derived' where the variable is created in the pipeline rather than read in.",
  "Assigned manually when each block of dictionary rows is written.",
  "Never missing; every row must name a source or 'derived'.",
  "metadata",

  NA, "final_file", "character", NA,
  "Name of the output file the documented variable appears in.",
  "Assigned manually.",
  "Never missing.",
  "metadata",

  NA, "orig_field", "character", NA,
  "Column name as it appears in the source file, before renaming.",
  "Copied verbatim from the source header; case preserved.",
  "NA where the variable is derived and has no source column.",
  "metadata",

  NA, "final_field", "character", NA,
  "Column name used in the analysis objects; primary key of the dictionary.",
  "None.",
  "Never missing.",
  "key_only",

  NA, "description", "character", NA,
  "Plain-language definition of what the variable measures or encodes.",
  "Written manually.",
  "Never missing.",
  "metadata",

  NA, "units", "character", NA,
  "Unit of measurement.",
  "None.",
  "NA for unitless variables such as names and identifiers.",
  "metadata",

  NA, "type", "character", NA,
  "Storage type of the final column: character, integer, or numeric.",
  "Recorded to match the class of the column as built, not as read.",
  "Never missing.",
  "metadata",

  NA, "transformation", "character", NA,
  "What was done to the source column to produce the final column, including manual edits to specific records.",
  "Written manually; 'None.' where the column passes through unchanged.",
  "Never missing.",
  "metadata",

  NA, "missing_rule", "character", NA,
  "How missingness is encoded in the source.",
  "Written manually.",
  "Never missing.",
  "metadata",

  NA, "model_eligible", "character", NA,
  "Whether the variable may enter an analysis: eligible, key_only, label_only, filter_only, or metadata.",
  "Assigned manually.",
  "Never missing.",
  "metadata"
) |>
  mutate(source_file = "derived",
         final_file  = "variable_dictionary.csv",
         .before = 1)


exclusion_log_dict <- tribble(
  ~orig_field, ~final_field, ~type, ~units, ~description, ~transformation, ~missing_rule, ~model_eligible,

  NA, "source_file", "character", NA,
  "Raw file the excluded record came from.",
  "None.",
  "Never missing.",
  "metadata",

  NA, "level", "character", NA,
  "Granularity of the exclusion: 'site' (a site visit dropped), 'taxon' (a taxon dropped), or 'column' (a source column not carried forward).",
  "None.",
  "Never missing; determines which of uid, site_id, and taxa_id are populated.",
  "metadata",

  NA, "uid", "character", NA,
  "EPA unique site visit ID. Populated for level = 'site' only.",
  "None.",
  "NA for taxon- and column-level rows.",
  "key_only",

  NA, "site_id", "character", NA,
  "EPA site identification code. Populated for level = 'site' only.",
  "None.",
  "NA for taxon- and column-level rows. Structural, not a gap.",
  "key_only",

  NA, "taxa_id", "integer", NA,
  "EPA taxonomic ID number. Populated for level = 'taxon' only.",
  "Copied from TAXA_ID.",
  "NA for site- and column-level rows.",
  "key_only",

  NA, "name", "character", NA,
  "Human-readable label for the excluded record. Content depends on level: aggregated ecoregion name (AG_ECO9_NM) for site rows, taxon common name (FINAL_NAME) for taxon rows, source column name for column rows.",
  "Copied from the level-appropriate source field.",
  "Never missing.",
  "label_only",

  NA, "reason", "character", NA,
  "Why the record was excluded..",
  "None.",
  "Never missing; 'unknown' is the explicit fallback if no condition matches.",
  "metadata"
) |>
  mutate(source_file = "derived",
         final_file  = "exclusion_log.csv",
         .before = 1)



variable_dictionary <- bind_rows(variable_dictionary, variable_dictionary_dict, exclusion_log_dict)

# Add non-selected columns into exclusion log
exclusion_log <- tibble(
  name = setdiff(names(fish_taxa_data), taxon_cols)
) |>
  mutate(
    source_file = "nrsa1314_fish_taxa.csv",
    level = "variable",
    uid = NA_integer_,
    site_id = NA_character_,
    taxa_id = NA_integer_,
    reason = "column_not_used"
  ) |>
  select(source_file, level, uid, site_id, taxa_id, name, reason)


# Check to see if all eligible fish have species names
taxon_lookup |>
  filter(species == "") |>
  pull(orig_name)

taxon_lookup |>
  filter(str_detect(species, "[^A-Za-z]")) |>
  select(taxa_id, orig_name, genus, species)



# Exclude non-fish, hybrids, and unknowns
taxon_lookup <- taxon_lookup |>
  mutate(
    reason = case_when(
      herp == "A"                                  ~ "non_fish",
      str_detect(orig_name, "UNKNOWN")             ~ "unknown_id",
      str_detect(orig_name, "NO FISH")             ~ "non_descriptive",
      str_detect(orig_name, "HYBRID")              ~ "hybrid_id",
      str_detect(orig_name, " X ")                 ~ "hybrid_id",
      str_detect(orig_name, "LAMPREY AMMOCOETE")   ~ "non_descriptive",
      str_detect(species, fixed("CF."))            ~ "unknown_id",
      str_detect(species, fixed("C.F."))           ~ "unknown_id",
      str_detect(species, fixed(" X "))            ~ "hybrid_id",
      taxa_id == 358                               ~ "non_descriptive",
      .default = NA_character_
    ),
    decision = if_else(is.na(reason), "included", "excluded")
  )

# Report in exclusion log
taxon_exclusions <- taxon_lookup |>
  filter(decision == "excluded") |>
  transmute(
    source_file = "nrsa1314_fish_taxa.csv",
    level       = "taxon",
    uid         = NA_integer_,
    site_id     = NA_character_,
    taxa_id     = taxa_id,
    name        = orig_name,
    reason      = reason
  )

exclusion_log <- bind_rows(exclusion_log, taxon_exclusions)




# Check again for species names
taxon_lookup |>
  filter(species == "", !(decision %in% "excluded")) |>
  pull(orig_name)

# Check for non-alphabetic character species names
taxon_lookup |>
  filter(str_detect(species, "[^A-Za-z]"), !(decision %in% "excluded")) |>
  select(taxa_id, orig_name, genus, species, decision)

# Fill in Shorttail Redhorse
taxon_lookup <- taxon_lookup |>
  mutate(species = if_else(taxa_id == 5079, "macrolepidotum", species))


# Adjust names
taxon_lookup$orig_name <- str_to_title(taxon_lookup$orig_name)
taxon_lookup$family <- str_to_title(taxon_lookup$family)
taxon_lookup$genus <- str_to_title(taxon_lookup$genus)
taxon_lookup$species <- str_to_lower(taxon_lookup$species)


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

# Aggregate duplicates together
taxon_lookup <- taxon_lookup |>
  add_count(taxon_code, name = "n_code") |>
  mutate(
    decision = case_when(
      decision %in% "excluded"            ~ "excluded",
      !is.na(taxon_code) & n_code > 1     ~ "aggregated",
      .default = "included"
    ),
    reason = if_else(decision == "aggregated", "duplicate_taxon_code", reason)) |>
  select(-n_code)


# Check duplicate decisions
taxon_lookup |>
  filter(decision == "aggregated") |>
  arrange(taxon_code) |>
  select(taxon_code, taxa_id, orig_name, family, genus, species, itis_tsn)


# Load in fish count data
fish_count_data <- read.csv("nrsa1314_fish_counts.csv", header = T)

# Add native status to Eastern Highlands
taxon_lookup <- taxon_lookup |>
  left_join(
    fish_count_data |>
      filter(VISIT_NO == 1,
             AG_ECO9_NM %in% c("Southern Appalachians", "Northern Appalachians")) |>
      summarise(non_native_status = if_else(any(NON_NATIVE == "Y"), "Y", "N"),
                .by = TAXA_ID) |>
      select(taxa_id = TAXA_ID, non_native_status),
    by = "taxa_id"
  )


# Add to variable dictionary
native_status_dictionary <- tribble(
  ~orig_field,  ~final_field,  ~type,        ~units, ~description, ~transformation, ~missing_rule, ~model_eligible,

  "NON_NATIVE", "non_native_status",  "character",  "Y/N",
  "Non-native to the HUC where the sample was collected.",
  "Joined into taxa_lookup on taxa_id via distinct().",
  "NA where the taxon was never collected in Eastern Highland sites.",
  "eligible"
) |>
  mutate(source_file = "nrsa1314_fish_counts.csv", final_file = "taxon_lookup.csv", .before = 1)

variable_dictionary <- bind_rows(variable_dictionary, native_status_dictionary)

taxon_lookup_dictionary <- tribble(
  ~orig_field,  ~final_field,  ~type,        ~units, ~description, ~transformation, ~missing_rule, ~model_eligible,

  NA, "reason",  "character",  NA,
  "Reason code for decision column.",
  "None.",
  "NA where decision was to include taxon.",
  "filter_only",

  NA, "decision",  "character",  NA,
  "Decision on how taxon was handled.",
  "None.",
  "Never missing",
  "filter_only",

  NA, "taxon_code",  "character",  NA,
  "Unique taxon code identifiers.",
  "str_to_lower() on genus and species names, with _ in between.",
  "NA for excluded taxon.",
  "filter_only"
) |>
  mutate(source_file = "derived", final_file = "taxon_lookup.csv", .before = 1)

variable_dictionary <- bind_rows(variable_dictionary, taxon_lookup_dictionary)




### Step 3: Build Species Presence/Absence Matrix in Eastern Highlands.


# Filter data to first visit to each site, and to Eastern Highlands (add to exclusion log)
fish_count_site_exclusion_log <- fish_count_data |>
  distinct(UID, SITE_ID, VISIT_NO, AG_ECO9_NM) |>
  filter(!(VISIT_NO == 1 &
             AG_ECO9_NM %in% c("Southern Appalachians", "Northern Appalachians"))) |>
  mutate(
    source_file = "nrsa1314_fish_counts.csv",
    level = "site",
    taxa_id = NA,
    reason = case_when(
      !(AG_ECO9_NM %in% c("Southern Appalachians", "Northern Appalachians")) ~ "wrong_ecoregion",
      !(VISIT_NO %in% 1)                                                    ~ "non_first_visit",
      TRUE                                                                   ~ "unknown"
    )
  ) |>
  select(source_file, level, uid = UID, site_id = SITE_ID, taxa_id, name = AG_ECO9_NM, reason)

exclusion_log <- bind_rows(exclusion_log, fish_count_site_exclusion_log)

# Filter sites in Eastern Highlands (eh)
fish_count_eh <- fish_count_data |>
  filter(VISIT_NO == 1,
         AG_ECO9_NM %in% c("Southern Appalachians", "Northern Appalachians"))

# Store number of total visited sites
n_sites_eh <- n_distinct(fish_count_eh$UID)

# Calculate prevalence among sites for each species and store in taxon look-up
prevalence <- fish_count_eh |>
  filter(TOTAL > 0) |>
  distinct(UID, TAXA_ID) |>
  count(TAXA_ID, name = "n_sites") |>
  mutate(pct_sites = round(100 * n_sites / n_sites_eh, 1))

taxon_lookup <- taxon_lookup |>
  left_join(prevalence |>
              select(taxa_id = TAXA_ID, n_sites, pct_sites),
            by = "taxa_id")

# Check for each excluded type the incident range and prevalence across sites in Eastern Highlands
taxon_lookup |>
  filter(decision == "excluded", !is.na(pct_sites)) |>
  summarise(n_taxa = n(),
            min = min(pct_sites), median = median(pct_sites), max = max(pct_sites),
            .by = reason)


# Pivot into fish count table by UID and aggregate duplicate taxon_codes
site_taxon_counts <- fish_count_eh |>
  left_join(taxon_lookup |> select(taxa_id, taxon_code),
            by = c("TAXA_ID" = "taxa_id")) |>
  filter(!is.na(taxon_code)) |>
  pivot_wider(id_cols = UID, names_from = taxon_code,
              values_from = TOTAL, values_fill = 0,
              values_fn = sum)


# Change to presence absence
site_taxon_pa <- site_taxon_counts |>
  mutate(across(-UID, ~ as.integer(.x > 0))) |>
  rename(
    uid = UID
  )

# Add taxa not in EH to exclusion log
eh_absent_exclusion_log <- taxon_lookup |>
  filter(!is.na(taxon_code), is.na(pct_sites)) |>
  transmute(
    source_file = "nrsa1314_fish_counts.csv",
    level       = "taxon",
    uid         = NA_integer_,
    site_id     = NA_character_,
    taxa_id     = taxa_id,
    name        = orig_name,
    reason      = "not_observed_in_eh"
  )

exclusion_log <- bind_rows(exclusion_log, eh_absent_exclusion_log)


# Add new variables to variable dictionary

taxon_prevalence_dictionary <- tribble(
  ~orig_field,  ~final_field,  ~type,        ~units, ~description, ~transformation, ~missing_rule, ~model_eligible,

  NA, "n_sites", "integer", "count of sites",
  "Number of distinct site visits (UID) at which the taxon was recorded with a positive count.",
  "filter(TOTAL > 0), then distinct(UID, TAXA_ID) to collapse abundance to occurrence, then count(TAXA_ID).",
  "Never missing within this table. After the join into taxon_lookup, NA means the taxon was not observed in the Eastern Highlands subset.",
  "eligible",

  NA, "pct_sites", "numeric", "% of sites",
  "Occupancy: n_sites as a percentage of all retained Eastern Highlands site visits. Denominator is n_sites_eh, the count of distinct UIDs in fish_count_eh (first visits only, Southern and Northern Appalachians only), including sites where no fish were caught if such sites appear in the source counts.",
  "round(100 * n_sites / n_sites_eh, 1).",
  "Never missing within this table. NA after the join carries the same meaning as for n_sites.",
  "eligible"
) |>
  mutate(source_file = "derived", final_file = "taxon_lookup.csv", .before = 1)

site_pa_dictionary <- tribble(
  ~orig_field, ~final_field, ~type, ~units, ~description, ~transformation, ~missing_rule, ~model_eligible,

  "UID", "uid", "integer", NA,
  "EPA unique site visit ID; one row per retained Eastern Highlands site visit. Primary key of site_taxon_pa.",
  "Carried through pivot_wider() as id_cols.",
  "Never missing.",
  "key_only",

  NA, "<taxon_code>", "integer", "0/1",
  "One column per retained taxon, named by taxon_code (lowercase genus_species). Cell value is either presence or absence of taxon at site, where 0 encodes absence and 1 encodes presence.",
  "left_join taxon_code onto counts, drop rows where taxon_code is NA (excluded taxa), then pivot_wider(values_from = TOTAL, values_fn = sum). values_fn = sum performs the deliberate aggregation of taxa sharing a taxon_code.",
  "No NAs by construction. Absent site-taxon combinations are filled with 0 by values_fill, which encodes 'not detected at this site visit', not 'missing measurement'. Zero is a non-detection and does not distinguish true absence from failed detection.",
  "eligible"
) |>
  mutate(source_file = "nrsa1314_fish_counts.csv",
         final_file  = "site_taxon_pa.csv",
         .before = 1)




variable_dictionary <- bind_rows(variable_dictionary, taxon_prevalence_dictionary, site_pa_dictionary)






### Step 4: Create site_metadata.csv and determine reference streams

# NRSA reference site assessment https://www.epa.gov/national-aquatic-resource-surveys/national-rivers-and-streams-assessment-2013-2014-technical pp.35
set.seed(123)

# Load in dataset
chemical_data <- read.csv("nrsa1314_water_chem.csv") # Has ANC_RESULT, DOC_RESULT, NTL_RESULT, PTL_RESULT, CHLORIDE_RESULT,  SULFATE_RESULT, TURB_RESULT
habitat_indicator_data <- read.csv("nrsa1314_phab_indic.csv") # Has riparian disturbance index W1_HALL
habitat_data <- read.csv("nrsa1314_phab_metrics.csv") # Has PCT_FN


# Grab conditions for each site
reference_table <- chemical_data |>
  filter(VISIT_NO == 1, AG_ECO9_NM %in% c("Southern Appalachians", "Northern Appalachians")) |>
  inner_join(habitat_data, by = c("UID")) |>
  inner_join(habitat_indicator_data, by = c("UID")) |>
  select(
    uid = UID,
    site_id = SITE_ID.x,
    ecoregion_nm = AG_ECO9_NM.x,
    total_P = PTL_RESULT,
    total_N = NTL_RESULT,
    chloride = CHLORIDE_RESULT,
    sulfate = SULFATE_RESULT,
    ANC = ANC_RESULT,
    DOC = DOC_RESULT,
    turbidity = TURB_RESULT,
    RDI = W1_HALL.x,
    pct_fine = PCT_FN
  )




# Select reference sites and transform variables.
site_metadata <- reference_table |>
  mutate(chloride = chloride*1000/35.45,
         sulfate = sulfate*1000/(96.06/2),
         total_N = total_N*1000) |>
  mutate(pass_nap = (total_P <= 20) +
           (total_N <= 750) +
           (chloride <= 250) +
           (sulfate <= 250) +
           (ANC >= 50 | DOC >= 5) +
           (turbidity <=5) +
           (RDI <= 2) +
           (pct_fine <= 25),
         pass_sap = (total_P <= 20) +
           (total_N <= 750) +
           (chloride <= 200) +
           (sulfate <= 400) +
           (ANC >= 50 | DOC >= 5) +
           (turbidity <=5) +
           (RDI <= 2) +
           (pct_fine <= 25)) |>
  mutate(
    ref_cond = case_when(
    ecoregion_nm == "Northern Appalachians" & pass_nap == 8 ~ "REF",
    ecoregion_nm == "Southern Appalachians" & pass_sap == 8 ~ "REF",
    .default = "NON-REF"), val_cond = sample(x=c("C","V"),size=n(), replace="TRUE",prob=c(0.70,0.30)))


# total_P in ug/L, total_N in ug/L (adjusted from mg/L), chloride in ueq/L (adjusted from mg/L), sulfate in ueq/L (adjusted from mg/L), ANC in ueq/L, DOC in mg/L, turbidity in NTU

# Document incomplete cases
site_metadata <- site_metadata |>
  mutate(
    n_criteria_na = rowSums(is.na(across(c(total_P, total_N, chloride, sulfate,
                                           turbidity, RDI, pct_fine)))) +
      as.integer(is.na(ANC) & is.na(DOC)),
    ref_cond = case_when(
      n_criteria_na > 0 ~ "INSUFFICIENT_DATA",
      ecoregion_nm == "Northern Appalachians" & pass_nap == 8 ~ "REF",
      ecoregion_nm == "Southern Appalachians" & pass_sap == 8 ~ "REF",
      .default = "NON-REF"
    )
  ) |> select(
    -n_criteria_na
  )














# Write in variable dictionary.
site_metadata_dict <- tribble(
  ~source_file, ~orig_field, ~final_field, ~type, ~units, ~description, ~transformation, ~missing_rule, ~model_eligible,

  "nrsa1314_water_chem.csv", "UID", "uid", "integer", NA_character_,
  "EPA unique site visit ID.",
  "Renamed.", "Never missing.", "key_only",

  "nrsa1314_water_chem.csv", "SITE_ID", "site_id", "character", NA_character_,
  "EPA site identification code. Multiple visits share a site_id; only first visits are retained.",
  "Renamed.",
  "Never missing.", "label_only",

  "nrsa1314_water_chem.csv", "AG_ECO9_NM", "ecoregion_nm", "character", NA_character_,
  "NARS 9-level aggregated Omernik ecoregion. Restricted to Southern and Northern Appalachians.",
  "Renamed.",
  "Never missing.",
  "eligible",

  "nrsa1314_water_chem.csv", "PTL_RESULT", "total_P", "numeric", "ug/L",
  "Total phosphorus. Reference threshold <= 20.",
  "None.",
  "NA where not measured.",
  "eligible",

  "nrsa1314_water_chem.csv", "NTL_RESULT", "total_N", "numeric", "ug/L",
  "Total nitrogen. Reference threshold <= 750.",
  "* 1000 to convert mg/L to ug/L.",
  "NA where not measured. Not imputed; site is classed INSUFFICIENT_DATA.",
  "eligible",

  "nrsa1314_water_chem.csv", "CHLORIDE_RESULT", "chloride", "numeric", "ueq/L",
  "Chloride ion concentration. Reference threshold <= 250 (NAP) or <= 200 (SAP).",
  "* 1000 / 35.45 to convert mg/L to ueq/L; Cl- is monovalent so equivalent weight equals molar mass.",
  "NA where not measured. Not imputed; site is classed INSUFFICIENT_DATA.",
  "eligible",

  "nrsa1314_water_chem.csv", "SULFATE_RESULT", "sulfate", "numeric", "ueq/L",
  "Sulfate ion concentration. Reference threshold <= 250 (NAP) or <= 400 (SAP).",
  "* 1000 / (96.06/2) to convert mg/L to ueq/L; SO4(2-) is divalent so equivalent weight is half the molar mass.",
  "NA where not measured. Not imputed; site is classed INSUFFICIENT_DATA.",
  "eligible",

  "nrsa1314_water_chem.csv", "ANC_RESULT", "ANC", "numeric", "ueq/L",
  "Acid neutralizing capacity. Paired with DOC in a single OR criterion: ANC >= 50 OR DOC >= 5.",
  "None.",
  "NA tolerated if DOC satisfies the paired criterion, since NA | TRUE evaluates TRUE. Site is INSUFFICIENT_DATA only when both ANC and DOC are missing.",
  "eligible",

  "nrsa1314_water_chem.csv", "DOC_RESULT", "DOC", "numeric", "mg/L",
  "Dissolved organic carbon. Paired with ANC as above; high DOC indicates naturally acidic organic waters rather than acid impairment.",
  "None.",
  "NA tolerated if ANC satisfies the paired criterion. See ANC.",
  "eligible",

  "nrsa1314_water_chem.csv", "TURB_RESULT", "turbidity", "numeric", "NTU",
  "Turbidity. Reference threshold <= 5.",
  "None.",
  "NA where not measured. Not imputed; site is classed INSUFFICIENT_DATA.",
  "eligible",

  "nrsa1314_phab_metrics.csv", "W1_HALL", "RDI", "numeric", "index",
  "Riparian disturbance index (W1_HALL), a weighted sum of human influence types observed in riparian plots. Reference threshold <= 2.",
  "None.",
  "NA where riparian plots were not assessed. Not imputed; site is classed INSUFFICIENT_DATA.",
  "eligible",

  "nrsa1314_phab_metrics.csv", "PCT_FN", "pct_fine", "numeric", "% of reach",
  "Percent fine substrate (silt/clay/muck) in the sampled reach. Reference threshold <= 25.",
  "None.",
  "NA where substrate was not characterized. Not imputed; site is classed INSUFFICIENT_DATA.",
  "eligible",

  "derived", NA_character_, "pass_nap", "integer", "count of 8",
  "Number of Northern Appalachians reference criteria met, out of 8. Intermediate.",
  "Sum of eight logical tests.",
  "NA if any component criterion is NA, which propagates through the sum.",
  "label_only",

  "derived", NA_character_, "pass_sap", "integer", "count of 8",
  "Number of Southern Appalachians reference criteria met, out of 8. Differs from pass_nap only in the chloride and sulfate thresholds.",
  "As pass_nap, with chloride <= 200 and sulfate <= 400.",
  "NA if any component criterion is NA.",
  "label_only",

  "derived", NA_character_, "ref_cond", "character", NA_character_,
  "Reference condition class: REF, NON-REF, or INSUFFICIENT_DATA. A site is REF only if it meets all 8 criteria for its own ecoregion.",
  "case_when() on ecoregion_nm and the matching pass_* score, with an explicit missing-data branch evaluated first.",
  "Never missing.",
  "eligible",

  "derived", NA_character_, "val_cond", "character", NA_character_,
  "Calibration/validation split: C or V, drawn independently of ref_cond at a nominal 70/30 rate.",
  "sample() with replacement, prob = c(0.70, 0.30), under set.seed(123) at the top of the script.",
  "Never missing.",
  "eligible"
) |>
  mutate(final_file = "site_metadata.csv", .after = source_file)


variable_dictionary <- bind_rows(variable_dictionary, site_metadata_dict)


# Write excluded variables to exclusion log

kept_chem <- c("UID", "SITE_ID", "AG_ECO9_NM", "VISIT_NO",
               "PTL_RESULT", "NTL_RESULT", "CHLORIDE_RESULT",
               "SULFATE_RESULT", "ANC_RESULT", "DOC_RESULT", "TURB_RESULT")
kept_indic   <- c("UID", "W1_HALL")
kept_metrics <- c("UID", "W1_HALL", "PCT_FN")

col_exclusions <- bind_rows(
  tibble(source_file = "nrsa1314_water_chem.csv",
         name = setdiff(names(chemical_data), kept_chem)),
  tibble(source_file = "nrsa1314_phab_indic.csv",
         name = setdiff(names(habitat_indicator_data), kept_indic)),
  tibble(source_file = "nrsa1314_phab_metrics.csv",
         name = setdiff(names(habitat_data), kept_metrics))
) |>
  mutate(
    level     = "column",
    uid       = NA_integer_,
    site_id   = NA_character_,
    taxa_id   = NA_integer_,
    reason    = "column_not_used"
  ) |>
  select(source_file, level, uid, site_id, taxa_id, name, reason)

exclusion_log <- bind_rows(exclusion_log, col_exclusions)



# Load in data
site_data <- read.csv("nrsa1314_site_information.csv")
colnames(site_data)

# Select columns
site_data <- site_data |>
  select(
    uid           = UID,
    site_id       = SITE_ID,
    visit_no      = VISIT_NO,
    ecoregion_nm  = AG_ECO9_NM,
    lat           = LAT_DD83,
    lon           = LON_DD83,
    huc8          = HUC8,
    huc8_nm       = HUC8_NM,
    elevation_m   = ELEVATION,
    size_class   = STRAH_CAT,
    ref_class     = RT_NRSA
  )

site_data <- site_data |>
  filter(visit_no == 1,
         ecoregion_nm %in% c("Southern Appalachians", "Northern Appalachians"))

# Record dropped columns in exclusion log
kept_site <- c("UID", "SITE_ID", "VISIT_NO", "AG_ECO9_NM",
               "LAT_DD83", "LON_DD83", "HUC8", "HUC8_NM",
               "ELEVATION", "STRAH_CAT", "RT_NRSA")

site_col_exclusions <- tibble(
  name = setdiff(names(read.csv("nrsa1314_site_information.csv", nrows = 0)), kept_site)
) |>
  mutate(
    source_file = "nrsa1314_site_information.csv",
    level       = "column",
    uid         = NA_integer_,
    site_id     = NA_character_,
    taxa_id     = NA_integer_,
    reason      = "column_not_used"
  ) |>
  select(source_file, level, uid, site_id, taxa_id, name, reason)

# Record dropped sites in exclusion log
site_visit_exclusions <- site_data |>
  filter(!(visit_no == 1 &
             ecoregion_nm %in% c("Southern Appalachians", "Northern Appalachians"))) |>
  transmute(
    source_file = "nrsa1314_site_information.csv",
    level       = "site",
    uid         = uid,
    site_id     = as.character(site_id),
    taxa_id     = NA_integer_,
    name        = ecoregion_nm,
    reason      = if_else(
      !(ecoregion_nm %in% c("Southern Appalachians", "Northern Appalachians")),
      "wrong_ecoregion", "non_first_visit")
  )

exclusion_log <- bind_rows(exclusion_log, site_col_exclusions, site_visit_exclusions)

# Write variables into dictionary

site_data_dict <- tribble(
  ~orig_field, ~final_field, ~type, ~units, ~description, ~transformation, ~missing_rule, ~model_eligible,

  "UID", "uid", "integer", NA_character_,
  "Unique site visit identification number.",
  "Renamed.", "Never missing.", "key_only",

  "SITE_ID", "site_id", "character", NA_character_,
  "Unique site ID.",
  "Renamed.", "Never missing.", "label_only",

  "VISIT_NO", "visit_no", "integer", NA_character_,
  "Visit number for an individual site. Retained set is visit_no == 1 only.",
  "Renamed.", "Never missing.", "filter_only",

  "AG_ECO9_NM", "ecoregion_nm", "character", NA_character_,
  "NARS 9-level aggregated Omernik ecoregion name. Retained set is Southern and Northern Appalachians only.",
  "Renamed.",
  "Never missing.",
  "label_only",

  "LAT_DD83", "lat", "numeric", "decimal degrees",
  "Site latitude, NAD83 datum.",
  "Renamed.",
  "Never missing.", "eligible",

  "LON_DD83", "lon", "numeric", "decimal degrees",
  "Site longitude, NAD83 datum. Negative in the study area.",
  "Renamed.",
  "Never missing.", "eligible",

  "HUC8", "huc8", "character", NA_character_,
  "8-digit hydrologic unit code for the containing watershed. Also the spatial unit on which NON_NATIVE status is defined in the fish count data.",
  "Renamed.",
  "Never missing.", "eligible",

  "HUC8_NM", "huc8_nm", "character", NA_character_,
  "Plain-language name of the HUC8 watershed.",
  "Renamed.", "Never missing.", "label_only",

  "ELEVATION", "elevation_m", "numeric", "meters",
  "Site elevation above sea level.",
  "Renamed",
  "NA where not determined; not imputed.",
  "eligible",

  "STRAH_CAT", "size_class", "character", NA_character_,
  "Stream size classification based on Strahler stream order.",
  "Renamed.",
  "NA where stream order could not be assigned; not imputed.",
  "eligible",

  "RT_NRSA", "ref_class", "character", NA_character_,
  "EPA's own NRSA reference stream determination. Independent of the ref_cond variable derived in site_predictors from raw criteria.",
  "Renamed.",
  "NA where EPA made no determination; not imputed.",
  "label_only"
) |>
  mutate(source_file = "nrsa1314_site_information.csv",
         final_file  = "site_metadata.csv",
         .before = 1)

variable_dictionary <- bind_rows(variable_dictionary, site_data_dict)




# Compare estimated reference sites vs. EPA estimates.
table(site_metadata$ref_cond,  site_metadata$ecoregion_nm) # 38 Ref for North, 21 for South
table(site_data$ref_class,  site_data$ecoregion_nm) # On site metadata set, North with 32 reference sites and south with 20 reference sites.
# check technical support documents to see if number of reference sites was similar
# pp. 31
# North, 37 reference sites
# South, 38 sites



nrow(site_metadata) # 550



taxa_codes <- setdiff(colnames(site_taxon_pa), "uid")

# Sites with metadata but no usable fish collection
sampled_uids <- unique(site_taxon_pa$uid)

sites_no_fish <- site_metadata |>
  filter(!(uid %in% sampled_uids))

fish_missing_exclusions <- sites_no_fish |>
  transmute(
    source_file = "nrsa1314_fish_counts.csv",
    level       = "site",
    uid         = uid,
    site_id     = as.character(site_id),
    taxa_id     = NA_integer_,
    name        = ecoregion_nm,
    reason      = if_else(uid %in% sampled_uids,
                          "fished_no_usable_taxa",
                          "not_fished")
  )

exclusion_log <- bind_rows(exclusion_log, fish_missing_exclusions)


# Combine metadata
site_metadata <- site_metadata |>
  left_join(site_data, by = c("uid", "site_id", "ecoregion_nm"),
            relationship = "one-to-one") |>
  filter(uid %in% sampled_uids)










### Step 5: Create site predictor dataset based on Meador & Carlisle (2009)

# Read in dataset
landscape_data <- read.csv("nrsa1314_land_metrics.csv")


# Select variables, missing basin_slope
landscape_data <- landscape_data |>
  select(
    uid = UID,
    site_id = SITE_ID,
    visit_no = VISIT_NO,
    date_col = DATE_COL,
    ws_area = WSAREASQKM,
    ws_precip = PRECIP_WS,
    ws_temp = TMEAN_WS,
    ws_runoff = RUNOFF_WS,
    ws_bfi = BFI_WS,
    ws_perm = PERMH_WS,
    ws_erod = KFACT_WS
    )

# Exclude sites with non-matching UIDs
landscape_scope_exclusions <- landscape_data |>
  filter(!(uid %in% site_metadata$uid)) |>
  transmute(
    source_file = "nrsa1314_land_metrics.csv",
    level       = "site",
    uid         = uid,
    site_id     = site_id,
    taxa_id     = NA_integer_,
    name        = "landscape_metrics",
    reason      = "not_in_eastern_highlands_set"
  )

exclusion_log <- bind_rows(exclusion_log, landscape_scope_exclusions)

# Build predictor set, and get lat, lon, elevation from site metadata
site_predictors <- site_metadata |>
  select(uid, site_id, ecoregion_nm, lat, lon, elevation_m) |>
  left_join(landscape_data |> select(-site_id, -visit_no),
            by = "uid",
            relationship = "one-to-one")


# Record column exclusions
kept_landscape <- c("UID", "SITE_ID", "VISIT_NO", "DATE_COL", "WSAREASQKM",
                    "PRECIP_WS", "TMEAN_WS", "RUNOFF_WS", "BFI_WS",
                    "PERMH_WS", "KFACT_WS")

landscape_col_exclusions <- tibble(
  name = setdiff(names(read.csv("nrsa1314_land_metrics.csv", nrows = 0)),
                 kept_landscape)
) |>
  mutate(
    source_file = "nrsa1314_land_metrics.csv",
    level       = "column",
    uid         = NA_integer_,
    site_id     = NA_character_,
    taxa_id     = NA_integer_,
    reason      = "column_not_used"
  ) |>
  select(source_file, level, uid, site_id, taxa_id, name, reason)

exclusion_log <- bind_rows(exclusion_log, landscape_col_exclusions)

# Update variable dictionary
site_predictors_dict <- tribble(
  ~source_file, ~orig_field, ~final_field, ~type, ~units,
  ~description, ~transformation, ~missing_rule, ~model_eligible,

  "nrsa1314_land_metrics.csv", "UID", "uid", "integer", NA_character_,
  "Unique site visit ID.",
  "Renamed.", "Never missing.", "key_only",

  "nrsa1314_land_metrics.csv", "DATE_COL", "date_col", "character", "date",
  "Date of field collection.",
  "Renamed.",
  "Never missing.",
  "eligible",

  "nrsa1314_land_metrics.csv", "WSAREASQKM", "ws_area", "numeric", "km2",
  "Watershed area.",
  "Renamed.",
  "NA where unavailable from original data.",
  "eligible",

  "nrsa1314_land_metrics.csv", "PRECIP_WS", "ws_precip", "numeric", "cm",
  "Mean annual precipitation for the watershed.",
  "Renamed.",
  "NA where unavailable from original data.",
  "eligible",

  "nrsa1314_land_metrics.csv", "TMEAN_WS", "ws_temp", "numeric", "degrees C",
  "Average annual air temperature for the watershed.",
  "Renamed.",
  "NA where unavailable from original data.",
  "eligible",

  "nrsa1314_land_metrics.csv", "RUNOFF_WS", "ws_runoff", "numeric", "mm/year",
  "Estimated watershed annual runoff.",
  "Renamed.",
  "NA where unavailable from original data.",
  "eligible",

  "nrsa1314_land_metrics.csv", "BFI_WS", "ws_bfi", "numeric", "% (0-100)",
  "Base flow index.",
  "Renamed.",
  "NA where unavailable from original data.",
  "eligible",

  "nrsa1314_land_metrics.csv", "PERMH_WS", "ws_perm", "numeric", "inches/hour",
  "Watershed mean of the high values of soil permeability..",
  "Renamed.",
  "NA where unavailable from original data.",
  "eligible",

  "nrsa1314_land_metrics.csv", "KFACT_WS", "ws_erod", "numeric", NA_character_,
  "Watershed mean soil erodibility factor (K), unitless.",
  "Renamed.",
  "NA where unavailable from original data.",
  "eligible"
) |>
  mutate(final_file = "site_predictors.csv", .after = source_file)

variable_dictionary <- bind_rows(variable_dictionary, site_predictors_dict)


# Step 6: Evaluate candidate geographic domains

# Combine site predictors and metadata
site_domains <- site_predictors |>
  select(uid, site_id, ecoregion_nm, lat, lon, elevation_m,
         ws_area, ws_precip, ws_temp, ws_runoff, ws_bfi, ws_perm, ws_erod) |>
  left_join(site_metadata |> select(uid, huc8, huc8_nm, size_class,
                                    ref_cond, ref_class, val_cond),
            by = "uid")

# Duplicate rows for pooled analysis
domain_frame <- bind_rows(
  site_domains |> mutate(domain = if_else(
    ecoregion_nm == "Northern Appalachians", "NAP", "SAP")),
  site_domains |> mutate(domain = "EH_pooled")
) |>
  mutate(domain = factor(domain, levels = c("NAP", "SAP", "EH_pooled")))


# Summarize reference condition and number of sites
site_counts <- domain_frame |>
  summarise(
    n_sites      = n_distinct(uid),
    n_ref        = sum(ref_cond == "REF", na.rm = TRUE),
    n_nonref     = sum(ref_cond == "NON-REF", na.rm = TRUE),
    n_insuff     = sum(ref_cond == "INSUFFICIENT_DATA", na.rm = TRUE),
    pct_ref      = round(100 * n_ref / n_sites, 1),
    n_ref_epa    = sum(ref_class == "R", na.rm = TRUE),
    .by = domain
  )

View(site_counts)

# Summarize HUC8 distribution
huc_summary <- domain_frame |>
  summarise(
    n_huc8       = n_distinct(huc8),
    sites_per_huc8_median = median(table(huc8)),
    sites_per_huc8_max    = max(table(huc8)),
    n_huc8_single = sum(table(huc8) == 1),
    .by = domain
  )

View(huc_summary)

huc_detail <- domain_frame |>
  filter(domain != "EH_pooled") |>
  count(domain, huc8, huc8_nm, sort = TRUE)


# Summarize richness
richness <- site_taxon_pa |>
  transmute(uid, richness = rowSums(across(-uid)))

richness_summary <- domain_frame |>
  left_join(richness, by = "uid") |>
  summarise(
    mean_richness = round(mean(richness, na.rm = TRUE), 1),
    sd_richness   = round(sd(richness, na.rm = TRUE), 1),
    min_richness  = min(richness, na.rm = TRUE),
    max_richness  = max(richness, na.rm = TRUE),
    .by = domain
  )

View(richness_summary)

# Summarize richness for reference sites only
richness_ref <- domain_frame |>
  left_join(richness, by = "uid") |>
  filter(ref_cond == "REF") |>
  summarise(mean_richness = round(mean(richness, na.rm = TRUE), 1),
            sd_richness   = round(sd(richness, na.rm = TRUE), 1),
            .by = domain)

View(richness_ref)

# Summarize distribution of taxon prevalence
prevalence_base <- fish_count_eh |>
  filter(TOTAL > 0) |>
  inner_join(taxon_lookup |>
               filter(!is.na(taxon_code)) |>
               select(taxa_id, taxon_code),
             by = c("TAXA_ID" = "taxa_id")) |>
  inner_join(site_domains |>
               select(uid, ecoregion_nm),
             by = c("UID" = "uid")) |>
  mutate(domain = if_else(ecoregion_nm == "Northern Appalachians", "NAP", "SAP"))

prevalence_domain <- bind_rows(
  prevalence_base,
  prevalence_base |> mutate(domain = "EH_pooled")
) |>
  distinct(domain, UID, taxon_code) |>
  count(domain, taxon_code, name = "n_sites") |>
  left_join(site_counts |> select(domain, domain_n = n_sites), by = "domain") |>
  mutate(pct_sites = round(100 * n_sites / domain_n, 1))

prevalence_dist <- prevalence_domain |>
  summarise(
    n_taxa       = n(),
    n_singleton  = sum(n_sites == 1),
    n_under_5pct = sum(pct_sites < 5),
    n_over_40pct = sum(pct_sites >= 40),
    median_pct   = median(pct_sites),
    .by = domain
  )

View(prevalence_dist)


# Summarize taxa shared between and restricted to NAP and SAP
taxa_by_region <- prevalence_domain |>
  filter(domain != "EH_pooled") |>
  select(domain, taxon_code, n_sites) |>
  pivot_wider(names_from = domain, values_from = n_sites, values_fill = 0) |>
  mutate(status = case_when(
    NAP > 0 & SAP > 0 ~ "shared",
    NAP > 0           ~ "NAP_only",
    SAP > 0           ~ "SAP_only"
  ))

taxa_by_region |> count(status)


# Summarize predictor completeness
predictor_vars <- c("lat", "lon", "elevation_m", "ws_area", "ws_precip",
                    "ws_temp", "ws_runoff", "ws_bfi", "ws_perm", "ws_erod")


# Everything complete besides some of the elevation
completeness <- domain_frame |>
  summarise(across(all_of(predictor_vars),
                   ~ round(100 * mean(!is.na(.x)), 1)),
            .by = domain) |>
  pivot_longer(-domain, names_to = "variable", values_to = "pct_complete")



# Summarize environmental coverage of natural predictor variables
coverage <- domain_frame |>
  summarise(across(all_of(predictor_vars),
                   list(min = ~ min(.x, na.rm = TRUE),
                        q25 = ~ quantile(.x, .25, na.rm = TRUE),
                        med = ~ median(.x, na.rm = TRUE),
                        q75 = ~ quantile(.x, .75, na.rm = TRUE),
                        max = ~ max(.x, na.rm = TRUE)),
                   .names = "{.col}__{.fn}"),
            .by = domain) |>
  pivot_longer(-domain, names_to = c("variable", "stat"), names_sep = "__") |>
  mutate(value = round(value, 3)) |>
  pivot_wider(names_from = stat, values_from = value)



### Step 7: Summarize candidate taxa for modeling

# Select reference sites
ref_uids <- site_metadata |>
  filter(ref_cond == "REF") |>
  pull(uid)

native_codes <- taxon_lookup |>
  filter(!is.na(taxon_code), non_native_status %in% "N") |>
  distinct(taxon_code)

n_ref <- length(ref_uids)

taxa_candidates <- site_taxon_pa |>
  filter(uid %in% ref_uids) |>
  pivot_longer(-uid, names_to = "taxon_code", values_to = "present") |>
  semi_join(native_codes, by = "taxon_code") |>
  summarise(n_ref_sites = sum(present), .by = taxon_code) |>
  mutate(pct_ref = round(100 * n_ref_sites / n_ref, 1)) |>
  arrange(desc(pct_ref))




plot_prevalence_labelled <- function(dat = taxa_candidates,
                                     threshold = 10,
                                     label_floor = 1,
                                     use_common_names = TRUE) {

  d <- dat |> filter(n_ref_sites >= label_floor)

  if (use_common_names && exists("taxon_lookup")) {
    d <- d |>
      left_join(taxon_lookup |> distinct(taxon_code, orig_name),
                by = "taxon_code") |>
      mutate(label = coalesce(orig_name, taxon_code))
  } else {
    d <- d |> mutate(label = taxon_code)
  }

  d |>
    mutate(band = if_else(pct_ref >= threshold, "Common", "Uncommon"),
           band = factor(band, levels = c("Common", "Uncommon"))) |>
    ggplot(aes(x = reorder(label, pct_ref), y = pct_ref, fill = band)) +
    geom_col(width = 0.75) +
    geom_hline(yintercept = threshold, linetype = "dashed",
               colour = "grey30", linewidth = 0.4) +
    scale_fill_manual(values = c("Common" = "#1f78b4",
                                 "Uncommon" = "#a6cee3")) +
    coord_flip() +
    labs(x = NULL,
         y = "Prevalence among reference sites (%)",
         fill = NULL,
         title = "Native taxon prevalence at reference sites",
         subtitle = paste0("taxa at >= ", label_floor,
                           " reference sites; threshold = ", threshold, "%")) +
    theme_minimal(base_size = 9) +
    theme(legend.position = "bottom",
          panel.grid.major.y = element_blank())
}

# Adjust plotting threshold
plot_prevalence_labelled(threshold = 10)

# Save workspace
save.image(file = "data_prep_workspace.RData")

