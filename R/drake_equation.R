# R/drake_equation.R

#' Calculate the estimated number of active communicative civilizations
#'
#' @param num_stars Estimated stars in the Milky Way
#' @param fraction_planets Fraction of stars with planetary systems
#' @param planets_per_system Average habitable planets per system
#' @param fraction_life Fraction where life actually emerges
#' @param fraction_intel Fraction where intelligent life evolves
#' @param fraction_comm Fraction that develop communicative technology
#' @param fraction_time Fraction of planetary lifespan civilization exists
#' @return A numeric estimate of active civilizations
calculate_drake_equation <- function(
  num_stars = 100e9,
  fraction_planets = 1.0,
  planets_per_system = 0.2,
  fraction_life = 0.1,
  fraction_intel = 0.01,
  fraction_comm = 0.01,
  fraction_time = 1e-8
) {

  # Classic Drake Equation formulation: N = R* * fp * ne * fl * fi * fc * L
  # Adapted here using continuous fractions for interactive UI binding
  estimate <- num_stars * fraction_planets * planets_per_system * fraction_life * fraction_intel * fraction_comm * fraction_time

  return(round(estimate, 2))
}
