test_that("the dashboard loads its dataset and renders filtered outputs", {
  withr::with_dir(file.path("..", "..", "app"), {
    app <- new.env(parent = globalenv())
    source("global.R", local = app)
    source("ui.R", local = app)
    source("server.R", local = app)

    expect_gt(nrow(app$gaia_dataset), 0)
    expect_s3_class(app$ui, "shiny.tag.list")

    shiny::testServer(app$server, {
      session$setInputs(
        esi_threshold = 0,
        biosphere_filter = "All",
        require_biosignature = FALSE,
        drake_fl = 0.1,
        drake_fi = 0.01
      )
      expected_rows <- sum(!is.na(app$gaia_dataset$esi_global))
      expect_equal(nrow(filtered_data()), expected_rows)
      expect_no_error(output$planet_table)
      expect_no_error(output$habitability_plot)
      expect_no_error(output$drake_result)

      session$setInputs(esi_threshold = 1, require_biosignature = TRUE)
      expect_equal(nrow(filtered_data()), 0)
      expect_no_error(output$planet_table)
      expect_no_error(output$habitability_plot)
    })
  })
})
