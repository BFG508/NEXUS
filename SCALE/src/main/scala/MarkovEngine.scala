import upickle.default._
import scala.io.Source
import java.io.File
import scala.util.Using

/**
 * Evaluates state transitions based on probabilistic dice rolls using a Markov Chain model.
 */
object MarkovEngine {
  private var states: Map[String, EnvironmentState] = Map()
  private var currentStateOpt: Option[EnvironmentState] = None

  /**
   * Loads environment states from a JSON file.
   * Example format: [{"name": "Clear", "transitions": {"Storm": 90, "Cloudy": 60}}]
   *
   * @param filePath Path to the JSON configuration file.
   */
  def loadStates(filePath: String): Unit = {
    val file = new File(filePath)
    if (!file.exists()) {
      println(s"[System] Environment file not found: $filePath")
      return
    }

    Using(Source.fromFile(file)) { source =>
      val jsonString = source.mkString
      val loadedStates = read[List[EnvironmentState]](jsonString)

      states = loadedStates.map(s => s.name.toLowerCase -> s).toMap

      // Initialize state to the first defined state if currently empty
      if (loadedStates.nonEmpty && currentStateOpt.isEmpty) {
        currentStateOpt = Some(loadedStates.head)
        println(s"[System] Initial environment set to: ${loadedStates.head.name}")
      }
    }.fold(
      exception => println(s"[System] Error parsing environments: ${exception.getMessage}"),
      _ => println(s"[System] Successfully loaded ${states.size} environment states.")
    )
  }

  /**
   * Advances the environment by rolling a d100 and checking transition thresholds.
   */
  def tick(): Unit = {
    currentStateOpt match {
      case Some(currentState) =>
        // Roll a d100 to determine if we transition
        val thresholdRoll = DiceEngine.evaluate("1d100").total
        println(s"[Environment] Tick roll (1d100): $thresholdRoll")

        // Sort transitions descending to ensure we check the hardest thresholds first
        val nextStateNameOpt = currentState.transitions
          .toList
          .sortBy(-_._2)
          .find { case (_, threshold) => thresholdRoll >= threshold }
          .map(_._1)

        nextStateNameOpt.flatMap(name => states.get(name.toLowerCase)) match {
          case Some(newState) =>
            if (newState.name != currentState.name) {
              println(s"[Environment] Shifted from ${currentState.name} to ${newState.name}!")
              currentStateOpt = Some(newState)
            } else {
              println(s"[Environment] Conditions remain ${currentState.name}.")
            }
          case None =>
            println(s"[Environment] Conditions remain ${currentState.name}.")
        }

      case None =>
        println("[System] No environment states loaded. Use 'load environment <file>' first.")
    }
  }

  /**
   * Retrieves the name of the current environment state.
   *
   * @return The current state name, or a default string if not initialized.
   */
  def getCurrentStateName: String = {
    currentStateOpt.map(_.name).getOrElse("Unknown (Not Loaded)")
  }
}
