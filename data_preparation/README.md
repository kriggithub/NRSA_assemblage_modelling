### NRSA Assemblage Modelling Data Preparation
## K. Riggin September 18, 2026



# Step 1: Download Raw Data


Raw data downloaded from:

https://www.epa.gov/national-aquatic-resource-surveys/data-national-aquatic-resource-surveys

Filter data by survey: "River and Streams 2013-2014"
Obtained 8/18/2026

NRSA 1314 Fish Counts: 2.8 mb, nrsa1314_fish_counts.csv, "NRSA 1314 Fish Counts - Data (CSV) (csv)"
NRSA 1314 Fish Taxa List: 78.6 kb, nrsa1314_fish_taxa.csv, "NRSA 1314 Fish Taxa List - Data (CSV) (csv)"
NRSA 1314 Site Information: 1.4 mb, nrsa1314_site_information.csv, "NRSA 1314 Site Information - Data (CSV) (csv)"
NRSA 1314 Key Variables and Classifcation Categories:  992.1 kb, nrsa1314_variable_category_class.csv, "NRSA 1314 Key Variables and Classification Categories - Data (CSV) (csv)"
NRSA 1314 Landscape Metrics: 2.2 mb, nrsa1314_land_metrics.csv, "NRSA 1314 Landscape Metrics - Data (CSV) (csv)"
NRSA 1314 Water Chemistry: 3.5 mb, nrsa1314_water_chem.csv, "NRSA 1314 Water Chemistry - Data (CSV) (csv)"
NRSA 1314 Physical Habitat Indicator Metrics: 285.1 kb, nrsa1314_phab_indic.csv, "NRSA 1314 Physical Habitat Indicator Metrics - Data (CSV) (csv)"
NRSA 1314 Physical Habitat Most Common Metrics: 1.5 mb, nrsa1314_phab_metrics.csv, "NRSA 1314 Physical Habitat Most Common Metrics - Data (CSV) (csv)"


NRSA 2013-2014 Technical Support Document:

https://www.epa.gov/national-aquatic-resource-surveys/national-rivers-and-streams-assessment-2013-2014-technical
Obtained 8/18/26
nrsa1314_technical_support_doc.pdf, 20.7 mb





# Step 2: Building the taxonomic lookup table


From the original NRSA 2013-2014 Fish Taxa Data set, the following variables were selected to create the taxon lookup table:
- TAXA_ID for unique taxa identification numbers.
- FINAL_NAME for common names of species, also used to link to other datasets.
- FAMILY for taxa family classification.
- GENUS for taxa genus classification.
- SPECIES for taxa species classification.
- ITISTSN for taxonomic serial number.

Each selected variable was renamed to lower case and added to the variable dictionary, while non-selected variables were dropped and added into the exclusion log.

Next, fish taxon were inspected to determine what taxonomic degree were the taxon clearly defined.
Overall, non-fish, hybrids and taxon not defined to the species level were excluded, and added to the exclusion log. 
After exclusions, the Shorttail Redhorse species name was manually filled in, and after exclusions, values were adjusted to either title or lowercase to better reflect common naming standards.

Unique taxon codes were then created by using lowercase genus and species names pasted together, and duplicates were assessed.
Among duplicates, all were the exact same species but juvenile, or extremely closely related species, and were subsequently marked as aggregated.

Finally, the native status column from the NRSA 2013-2014 Fish Counts Dataset was added into the taxonomic lookup table, and recorded in the variable dictionary.






# Step 3: Building the Species Presence/Absence Matrix in Eastern Highlands


Firstly, fish count data was filtered to the Eastern Highlands region, and for the first visit to each site to ensure no sites were re-sampled. Excluded sites were then logged into the exclusion log.

Prevalence for each species among eligible sites was then calculated, and appended to the taxon lookup.

Excluded species were then inspected, and the highest prevalence among unknown and hybrid species IDs was 4.5%, which waas determined as low enough to still exclude.

The fish counts dataset was then pivoted to create the site by taxon presence/absence matrix, making sure to aggregate species with duplicate taxon codes.

Taxon not in the Eastern Highlands subset was then added into the exclusion log, and variables were added into the dictionary.



# Step 4: Determining Site Reference Conditions in Eastern Highland, and creating site metdata package.

The following variables from the listed datasets were selected to create the site metadata table:


From NRSA 2013-2014 Water Chemistry:
- ANC_RESULT for Acid Neutralizing Capacity.
- DOC_RESULT for Dissolved Organic Carbon.
- CHLORIDE_RESULT for Chloride Ion Concentration.
- NTL_RESULT for Total Nitrogen.
- PTL_RESULT for Total Phosphorus.
- SULFATE_RESULT for Sulfate Ion Concentration.
- TURB_RESULT for Turbidity.


From NRSA 2013-2014 Physical Habitat Indicator Metrics:
- W1_HALL for riparian disturbance index variable.

From NRSA 2013-2014 Physical Habitat Most Common Metrics:
- PCT_FN for percent fine substrate.

These three datasets were joined together by UID.

Chloride Ion Concentration, and Sulfate Ion Concentration were then unit converted from mg/L to ueq/L. Nitrogen was also converted from mg/L to ug/L.
Sites that qualified from the NRSA reference site assessment on the technical support document pp. 35 were then determined, and 70% of sites were labeled for model construction, and 30% for model validation.
Excluded variables were then included into the exclusion log, and new variables were added into the variable dictionary.



From the original NRSA 2013-2014 Site Information Dataset, the following variables were selected to create the site metadata table:
- UID for unique site visit identification number.
- SITE_ID for unique site ID.
- VISIT_NO for for visit number for individual site.
- AG_ECO9_NM for ecoregion classification.
- LAT_DD83 for Latitude coordinates.
- LON_DD83 for Longitude coordinates.
- HUC8 for HUC8 watershed classification code.
- HUC8_NM for HUC8 watershed plain name.
- ELEVATION for site elevation.
- STRAH_CAT for stream size classification.
- RT_NRSA for NRSA reference stream determination.

After filtering to Eastern Highland sites, exclusion and variable logs were updated.


Reference estimates were then compared between the EPA's self classification, our classification, and reported classification.
On the technical support document pp. 31, the North Appalachians had 37 reference sites, while the South Appalachians had 38.
On the EPA's self reported metadata set, the North Appalachians had 32 reference sites, while the South Appalachians had 20.
Finally, in our estimates, the North Appalachians had 38 reference sites, while the South Appalachians had 21.


Notably, site metadata revealed a total of 17 sites with complete metadata, but no entries of fish collection, and were subsequently excluded. None of the excluded sites were reference condition.



# Step 5: Creating Site Abiotic Predictors Unaffected by Stress Matrix based on Meador & Carlisle (2009).

From the original NRSA 2013-2014 Landscape Metrics Data set, the following variables were selected based on Meador & Carlisle (2009):
- UID for unique site visit identification number.
- SITE_ID for unique site ID.
- VISIT_NO for for visit number for individual site.
- DATE_COL for date of collection.
- WSAREASQKM for basin area.
- PRECIP_WS for mean annual precipitation.
- TMEAN_WS for for mean annual air temperature.
- RUNOFF_WS for mean annual runoff.
- BFI_WS for base flow index.
- PERMH_WS for soil permeability.
- KFACT_WS for soil erodibility.

Mean basin slope, a candidate variable in Meador & Carlisle (2009), could not be reproduced from NRSA 2013-2014 data. However, because mean basin slope was not selected by the final northern or southern models, its omission does not affect reproduction of the published predictor sets.
Update: Rose et al. listed as important variable so will have to update.


The landscape data was filtered to matching UIDs with site_taxon_pa and site metadata, and latitude, longitude, and elevation from the site metadata was also appended as site predictors.

Exclusion and variable logs were updated as well.















