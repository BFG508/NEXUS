# Download a compact, reproducible column subset from the NASA Exoplanet Archive.
dir.create("data/raw", recursive = TRUE, showWarnings = FALSE)
query <- paste0(
  "select+pl_name,hostname,discoverymethod,disc_year,pl_orbper,pl_rade,pl_bmasse,",
  "pl_eqt,st_teff,sy_dist+from+pscomppars"
)
url <- paste0("https://exoplanetarchive.ipac.caltech.edu/TAP/sync?query=", query, "&format=csv")
dest <- "data/raw/nasa_exoplanets.csv"
download.file(url, dest, mode = "wb")
message("Downloaded NASA Exoplanet Archive data to ", dest)
