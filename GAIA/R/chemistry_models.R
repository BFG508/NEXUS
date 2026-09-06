# R/chemistry_models.R

library(dplyr)
library(readr)

#' Simulate a hypothetical atmospheric composition based on planetary conditions
#'
#' @param biosphere_class The theoretical biosphere class of the planet
#' @param esi_score The Earth Similarity Index score
#' @return A character vector of simulated atmospheric gases
simulate_atmosphere <- function(biosphere_class, esi_score) {
  base_gases <- c("N2", "CO2", "H2O")

  # Add trace gases based on the environment to simulate astrobiological outgassing
  if (biosphere_class == "Mesophile (Earth-like)" && esi_score > 0.85) {
    return(c(base_gases, "O2", "CH4", "O3")) # Strong biosignature profile
  } else if (biosphere_class %in% c("Thermophile", "Hyperthermophile")) {
    return(c(base_gases, "CH4", "H2S")) # Extremophile methanogenesis and sulfur reduction
  } else if (biosphere_class == "Psychrophile") {
    return(c(base_gases, "CH4")) # Low metabolism, single trace gas
  } else {
    return(c(base_gases, "Ar")) # Sterile or inert environments
  }
}

#' Analyze planetary atmosphere for thermodynamic disequilibrium (Biosignatures)
#'
#' @param planet_data Processed exoplanet dataset with biosphere classifications
#' @param dict_path Path to the biosignature pairs dictionary
#' @return Dataframe appended with atmospheric analysis results
evaluate_biosignatures <- function(planet_data, dict_path = "data/raw/biosignature_pairs.csv") {

  biosignature_dict <- read_csv(dict_path, show_col_types = FALSE)

  analyzed_planets <- planet_data %>%
    # rowwise() allows us to apply the simulation function to each planet individually
    rowwise() %>%
    mutate(
      # 1. Simulate the atmosphere based on prior physics and biology models
      simulated_gases = list(simulate_atmosphere(dominant_biosphere_class, esi_global)),

      # 2. Check against the dictionary for co-occurring gases (thermodynamic disequilibrium)
      detected_process = list(
        biosignature_dict %>%
          filter(gas_1 %in% simulated_gases & gas_2 %in% simulated_gases)
      ),

      # 3. Extract the confidence score and biological process if a match exists
      # Extract the confidence score and biological process if a match exists
      has_biosignature = nrow(detected_process) > 0,
      biosignature_confidence = ifelse(
        has_biosignature,
        max(detected_process$confidence_score),
        0.0
      ),
      biosignature_type = ifelse(
        has_biosignature,
        paste(detected_process$biological_process, collapse = "<br>"),
        "None"
      )
    ) %>%
    ungroup() %>%
    # Clean up the temporary nested dataframe column to keep the main dataset light
    select(-detected_process)

  return(analyzed_planets)
}
