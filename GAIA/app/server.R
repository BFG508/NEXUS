# app/server.R
# Backend application logic and reactive rendering

library(shiny)
library(dplyr)
library(ggplot2)
library(DT)
library(plotly)

server <- function(input, output, session) {

  # Reactive expression to filter the master dataset based on UI inputs
  filtered_data <- reactive({
    data <- gaia_dataset %>%
      filter(esi_global >= input$esi_threshold)

    if (input$biosphere_filter != "All") {
      data <- data %>%
        filter(dominant_biosphere_class == input$biosphere_filter)
    }

    if (input$require_biosignature) {
      data <- data %>%
        filter(has_biosignature == TRUE)
    }

    return(data)
  })

  # Render the interactive data table for the UI
  output$planet_table <- renderDT({
    display_data <- filtered_data() %>%
      select(
        Planet = planet_name,
        Star = star_name,
        "Distance (LY)" = distance_light_years,
        ESI = esi_global,
        Biosphere = dominant_biosphere_class,
        Biosignatures = biosignature_type
      )

    datatable(
      display_data,
      escape = FALSE,
      options = list(
        pageLength = 10,
        scrollX = TRUE,
        dom = 'tip'
      ),
      rownames = FALSE
    )
  })

  # Render the interactive habitability distribution plot using Plotly
  output$habitability_plot <- renderPlotly({

    # Prepare data with rich tooltips
    plot_data <- filtered_data() %>%
      mutate(
        hover_info = paste(
          "<b>Planet:</b>", planet_name, "<br>",
          "<b>ESI:</b>", esi_global, "<br>",
          "<b>Distance:</b>", distance_light_years, "LY<br>",
          "<b>Class:</b>", dominant_biosphere_class
        )
      )

    # Create base ggplot
    base_plot <- ggplot(
      plot_data,
      aes(
        x = distance_light_years,
        y = esi_global,
        color = dominant_biosphere_class,
        text = hover_info
      )
    ) +
      geom_point(size = 3, alpha = 0.8) +
      theme_dark(base_size = 14) +
      labs(
        x = "Distance from Earth (Light Years)",
        y = "Earth Similarity Index (ESI)",
        color = ""
      ) +
      theme(
        plot.title = element_blank(),
        plot.background = element_rect(fill = "#1f2833", color = NA),
        panel.background = element_rect(fill = "#0b0c10", color = NA),
        text = element_text(color = "#c5c6c7"),
        axis.text = element_text(color = "#c5c6c7")
      )

    # Convert to plotly and apply fine-tuned layout adjustments
    interactive_plot <- ggplotly(base_plot, tooltip = "text") %>%
      layout(
        margin = list(t = 80, b = 160, l = 60, r = 40),

        showlegend = TRUE,

        title = list(
          text = "Exoplanet Distribution: Distance vs. Habitability",
          font = list(color = "#66fcf1", size = 18),
          y = 0.96,
          x = 0.5,
          xanchor = "center",
          yanchor = "top"
        ),

        # Legend positioned with a fully transparent background to fix the white box issue
        legend = list(
          orientation = "h",
          x = 0.5,
          xanchor = "center",
          y = -0.22,
          font = list(size = 13, color = "#c5c6c7"),
          bgcolor = "rgba(0,0,0,0)" # Forces Plotly to use a transparent background
        ),

        yaxis = list(
          title = list(
            text = "Earth Similarity Index (ESI)",
            standoff = 20
          )
        ),

        xaxis = list(
          title = list(
            text = "Distance from Earth (Light Years)",
            standoff = 25
          )
        ),

        plot_bgcolor = "#0b0c10",
        paper_bgcolor = "#1f2833",
        font = list(color = "#c5c6c7")
      ) %>%
      config(
        displaylogo = FALSE,
        modeBarButtonsToRemove = c("select2d", "lasso2d", "autoScale2d")
      )

    return(interactive_plot)
  })

  # Render the dynamic Drake Equation calculation
  output$drake_result <- renderText({
    result <- calculate_drake_equation(
      fraction_life = input$drake_fl,
      fraction_intel = input$drake_fi
    )

    format(result, big.mark = ",", scientific = FALSE)
  })
}
