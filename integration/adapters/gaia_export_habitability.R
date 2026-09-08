#!/usr/bin/env Rscript
# Export GAIA calculate_esi() output as nexus.habitability.v1.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2) stop("Usage: gaia_export_habitability.R <clean_exoplanets.csv> <output.json>")

script_args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", script_args, value = TRUE)
script_path <- normalizePath(sub("^--file=", "", file_arg[[1]]), mustWork = TRUE)
nexus_root <- normalizePath(file.path(dirname(script_path), "..", ".."), mustWork = TRUE)

suppressPackageStartupMessages({
  library(readr)
  library(jsonlite)
})
source(file.path(nexus_root, "GAIA", "R", "astrobiology_models.R"))

input <- read_csv(args[[1]], show_col_types = FALSE)
scored <- calculate_esi(input)
targets <- lapply(seq_len(nrow(scored)), function(i) {
  list(
    planet_id = as.character(scored$planet_name[[i]]),
    esi_proxy = as.numeric(scored$esi_global[[i]]),
    equilibrium_temp_k = as.numeric(scored$equilibrium_temp_k[[i]]),
    radius_earth = as.numeric(scored$planet_radius_earth[[i]])
  )
})
value <- list(
  schema = "nexus.habitability.v1",
  producer = list(project = "GAIA", version = "0.1.0"),
  payload = list(
    system_id = "external-or-astra",
    targets = targets,
    interpretation = "GAIA Earth-similarity proxy using equilibrium-temperature-consistent reference values."
  )
)
write_json(value, args[[2]], pretty = TRUE, auto_unbox = TRUE, na = "null")
cat(normalizePath(args[[2]], mustWork = FALSE), "\n")
