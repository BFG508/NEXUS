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
