test_that("Earth-equilibrium proxy gives ESI 1 for Earth-normalized inputs", {
  d <- data.frame(
    planet_radius_earth = 1,
    planet_mass_earth = 1,
    equilibrium_temp_k = 255
  )
  expect_equal(calculate_esi(d)$esi_global, 1)
})

test_that("Drake equation multiplies factors", {
  expect_equal(calculate_drake_equation(100, 1, 1, 1, 1, 1, 1), 100)
})

test_that("missing ESI does not invent a strong biosignature or crash", {
  source(file.path("..", "..", "R", "chemistry_models.R"), local = TRUE)
  gases <- simulate_atmosphere("Mesophile (Earth-like)", NA_real_)
  expect_false("O2" %in% gases)
  expect_true("Ar" %in% gases)
})

test_that("repository biological dictionaries work with their padded headers", {
  source(file.path("..", "..", "R", "biology_models.R"), local = TRUE)
  source(file.path("..", "..", "R", "chemistry_models.R"), local = TRUE)
  planet <- data.frame(equilibrium_temp_k = 288, esi_global = 1)
  viable <- evaluate_extremophile_viability(
    planet, file.path("..", "..", "data", "raw", "extremophile_limits.csv")
  )
  expect_true(viable$is_thermally_viable)
  analyzed <- evaluate_biosignatures(
    viable, file.path("..", "..", "data", "raw", "biosignature_pairs.csv")
  )
  expect_true(analyzed$has_biosignature)
  expect_equal(analyzed$biosignature_confidence, 0.95)
})
