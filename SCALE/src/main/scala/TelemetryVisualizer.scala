/**
 * Handles the rendering of basic ASCII telemetry charts in the terminal.
 */
object TelemetryVisualizer {

  /**
   * Renders a rudimentary sparkline graph in the console to visualize data variance.
   *
   * @param dataPoints A list of numerical data points (e.g., historical Karma corrections).
   * @param label The title of the telemetry chart.
   */
  def renderSparkline(dataPoints: List[Double], label: String): Unit = {
    val sparks = Seq(" ", "▂", "▃", "▄", "▅", "▆", "▇", "█")

    if (dataPoints.isEmpty) {
      println(s"\n[Telemetry] $label: No data available yet.")
      return
    }

    val min = dataPoints.min
    val max = dataPoints.max
    val range = if (max - min == 0) 1.0 else max - min

    val chart = dataPoints.map { point =>
      val normalizedIndex = math.round(((point - min) / range) * (sparks.length - 1)).toInt
      sparks(normalizedIndex)
    }.mkString("")

    println(s"\n[Telemetry] $label:")
    println(s"Min: $min | Max: $max")
    println(s"Graph: |$chart|")
  }
}
