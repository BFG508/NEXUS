library(dplyr)
library(readr)
library(tidyr)

args <- commandArgs(trailingOnly = TRUE)
input_arg <- grep("^--input=", args, value = TRUE)
if (length(input_arg)) {
  raw_exo_path <- sub("^--input=", "", input_arg[[1]])
} else if (file.exists("data/raw/nasa_exoplanets.csv")) {
  raw_exo_path <- "data/raw/nasa_exoplanets.csv"
} else {
  raw_exo_path <- "data/raw/nasa_exoplanets_sample.csv"
}
processed_exo_path <- "data/processed/clean_exoplanets.csv"
dir.create(dirname(processed_exo_path), recursive = TRUE, showWarnings = FALSE)

message("GAIA ETL input: ", raw_exo_path)
raw_data <- read_csv(raw_exo_path, comment = "#", show_col_types = FALSE)

# ASTRA compatibility payloads omit observational fields that do not exist in
# a generated sector. Add them explicitly as NA instead of inventing values.
required <- c("pl_name", "hostname", "discoverymethod", "disc_year", "pl_orbper",
              "pl_rade", "pl_bmasse", "pl_eqt", "st_teff", "sy_dist")
for (column in required) {
  if (!column %in% names(raw_data)) raw_data[[column]] <- NA
}

clean_data <- raw_data %>%
  transmute(
    planet_name = pl_name,
    star_name = hostname,
    discovery_method = discoverymethod,
    discovery_year = disc_year,
    orbital_period_days = pl_orbper,
    planet_radius_earth = pl_rade,
    planet_mass_earth = pl_bmasse,
    equilibrium_temp_k = pl_eqt,
    stellar_temp_k = st_teff,
    distance_parsecs = sy_dist
  ) %>%
  drop_na(equilibrium_temp_k, planet_radius_earth) %>%
  filter(planet_radius_earth > 0, equilibrium_temp_k > 0) %>%
  mutate(distance_light_years = round(distance_parsecs * 3.26156, 2)) %>%
  arrange(distance_light_years)

write_csv(clean_data, processed_exo_path)
message("GAIA ETL complete: ", nrow(clean_data), " rows -> ", processed_exo_path)
