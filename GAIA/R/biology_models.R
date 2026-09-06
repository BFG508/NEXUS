# R/biology_models.R

library(dplyr)
library(readr)

#' Calculate extremophile survival potential based on thermal limits
#'
#' @param planet_data Processed exoplanet dataset
#' @param limits_path Path to the extremophile limits database
#' @return Dataframe appended with biological viability classifications
evaluate_extremophile_viability <- function(planet_data, limits_path = "data/raw/extremophile_limits.csv") {

  # Load the biological limits database
  bio_limits <- read_csv(limits_path, show_col_types = FALSE)

  # Determine absolute temperature boundaries for known terrestrial biology
  abs_min_temp <- min(bio_limits$min_temp_k)
  abs_max_temp <- max(bio_limits$max_temp_k)

  evaluated_planets <- planet_data %>%
    mutate(
      # Boolean flag indicating if the planet falls within ANY known biological limit
      is_thermally_viable = equilibrium_temp_k >= abs_min_temp &
        equilibrium_temp_k <= abs_max_temp,

      # Categorize the theoretical dominant biosphere based on temperature ranges
      dominant_biosphere_class = case_when(
        equilibrium_temp_k >= 353 & equilibrium_temp_k <= 395 ~ "Hyperthermophile",
        equilibrium_temp_k >= 318 & equilibrium_temp_k < 353 ~ "Thermophile",
        equilibrium_temp_k >= 277 & equilibrium_temp_k < 318 ~ "Mesophile (Earth-like)",
        equilibrium_temp_k >= 258 & equilibrium_temp_k < 277 ~ "Psychrophile",
        # Tardigrades act as the ultimate fallback for extreme cold or heat via cryptobiosis
        (equilibrium_temp_k >= 1 & equilibrium_temp_k < 258) |
          (equilibrium_temp_k > 395 & equilibrium_temp_k <= 423) ~ "Tardigrade (Cryptobiosis)",
        TRUE ~ "Sterile/Inhospitable"
      )
    )

  return(evaluated_planets)
}
