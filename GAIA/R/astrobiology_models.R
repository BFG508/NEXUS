# R/astrobiology_models.R

library(dplyr)

#' Calculate the Earth Similarity Index (ESI) for a dataset of exoplanets
#'
#' @param planet_data A dataframe containing cleaned exoplanet telemetry
#' @return A dataframe with calculated physics parameters and ESI scores
calculate_esi <- function(planet_data) {

  # Earth-reference values. Temperature uses Earth equilibrium temperature
  # because the input field is equilibrium_temp_k (not surface temperature).
  earth_temp_k <- 255
  earth_radius <- 1
  earth_mass <- 1

  # Empirical weight exponents for ESI calculation (Schulze-Makuch et al., 2011)
  weight_radius <- 0.57
  weight_density <- 1.07
  weight_esc_vel <- 0.70
  weight_temp <- 5.58

  processed_data <- planet_data %>%
    # Calculate derived planetary physics parameters
    mutate(
      relative_density = planet_mass_earth / (planet_radius_earth^3),
      relative_esc_vel = sqrt(planet_mass_earth / planet_radius_earth)
    ) %>%
    # Calculate individual ESI components
    mutate(
      esi_radius = (1 - abs((planet_radius_earth - earth_radius) /
                              (planet_radius_earth + earth_radius)))^weight_radius,
      esi_density = (1 - abs((relative_density - 1) /
                               (relative_density + 1)))^weight_density,
      esi_esc_vel = (1 - abs((relative_esc_vel - 1) /
                               (relative_esc_vel + 1)))^weight_esc_vel,
      esi_temp = (1 - abs((equilibrium_temp_k - earth_temp_k) /
                            (equilibrium_temp_k + earth_temp_k)))^weight_temp
    ) %>%
    # Combine components into the global Earth Similarity Index
    mutate(
      esi_global = esi_radius * esi_density * esi_esc_vel * esi_temp,
      # Round to 3 decimal places for cleaner UI presentation later
      esi_global = round(esi_global, 3)
    ) %>%
    # Sort the catalog, placing the most Earth-like planets at the top
    arrange(desc(esi_global))

  return(processed_data)
}
