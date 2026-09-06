# app/ui.R
# Frontend layout definition for the G.A.I.A. Simulator

library(shiny)
library(DT)
library(plotly)

ui <- fluidPage(
  # Dark space theme
  theme = "css/styles.css",

  # Load custom JS for the system boot sequence in the console
  tags$head(
    tags$script(src = "js/custom_scripts.js")
  ),

  titlePanel(
    windowTitle = "G.A.I.A. Simulator",
    title = div(
      img(
        src = "img/gaia_logo.png",
        height = "50px",
        style = "margin-right: 15px;"
      ),
      "G.A.I.A. Exoplanet Simulator"
    )
  ),

  sidebarLayout(
    sidebarPanel(
      h3("Mission Parameters"),
      p("Adjust filters to scan for specific planetary conditions."),

      sliderInput(
        inputId = "esi_threshold",
        label = "Minimum Earth Similarity Index (ESI):",
        min = 0, max = 1, value = 0.75, step = 0.05
      ),

      selectInput(
        inputId = "biosphere_filter",
        label = "Target Biosphere Class:",
        choices = c(
          "All",
          "Mesophile (Earth-like)",
          "Thermophile",
          "Hyperthermophile",
          "Psychrophile",
          "Tardigrade (Cryptobiosis)"
        ),
        selected = "All"
      ),

      checkboxInput(
        inputId = "require_biosignature",
        label = "Require Atmospheric Biosignature",
        value = FALSE
      ),

      hr(),

      helpText(
        "Data sourced from NASA Exoplanet Archive and processed ",
        "via G.A.I.A. engines."
      )
    ),

    mainPanel(
      h3("Telemetry Output"),

      tabsetPanel(
        type = "tabs",
        tabPanel(
          title = "Planetary Database",
          br(),
          DTOutput("planet_table")
        ),
        tabPanel(
          title = "Habitability Distribution",
          br(),
          # Increased height to fit all layout elements correctly
          plotlyOutput("habitability_plot", height = "640px")
        ),
        tabPanel(
          title = "Drake Extrapolation",
          br(),
          h4("The Great Filter Simulation"),
          p(
            "Adjust biological and sociological bottlenecks to estimate ",
            "active communicative civilizations."
          ),
          br(),
          sliderInput(
            inputId = "drake_fl",
            label = "Fraction where life emerges (fl):",
            min = 0, max = 1, value = 0.1, step = 0.01
          ),
          sliderInput(
            inputId = "drake_fi",
            label = "Fraction evolving intelligence (fi):",
            min = 0, max = 1, value = 0.01, step = 0.01
          ),
          hr(),
          h3("Estimated Active Civilizations (N):"),
          h2(textOutput("drake_result"), style = "color: #45a29e;")
        )
      )
    )
  )
)
