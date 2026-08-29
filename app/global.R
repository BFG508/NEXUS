# app/global.R
# This script runs once when the application starts

# Load required core libraries
library(shiny)
library(dplyr)
library(ggplot2)
library(DT)
library(plotly)

# Source core logic and models from the R/ directory
source("../R/astrobiology_models.R")
source("../R/biology_models.R")
source("../R/chemistry_models.R")
source("../R/drake_equation.R")

# Load the pre-processed telemetry dataset into global memory
raw_telemetry <- read.csv(
  "../data/processed/clean_exoplanets.csv",
  stringsAsFactors = FALSE
)

# Execute the master pipeline to generate the full simulation dataset
gaia_dataset <- raw_telemetry %>%
  calculate_esi() %>%
  evaluate_extremophile_viability(
    limits_path = "../data/raw/extremophile_limits.csv"
  ) %>%
  evaluate_biosignatures(
    dict_path = "../data/raw/biosignature_pairs.csv"
  )

print("G.A.I.A. Global Environment and Master Dataset Loaded.")
