import scala.io.StdIn.readLine
import scala.util.matching.Regex

/**
 * The main entry point for the SCALE application.
 */
object Main {

  val definePattern: Regex = """^define\s+([a-zA-Z0-9_]+)\s*=\s*(.+)$""".r
  val loadEntityPattern: Regex = """^load\s+entities\s+(.+)$""".r
  val loadEnvPattern: Regex = """^load\s+environment\s+(.+)$""".r
  val entityRollPattern: Regex = """^roll\s+([a-zA-Z0-9_]+)\s+with\s+([a-zA-Z0-9_]+)$""".r

  def main(args: Array[String]): Unit = {
    println("=======================================================")
    println(" Welcome to S.C.A.L.E. (Kalman + Markov Edition) ")
    println("=======================================================")
    println("Commands:")
    println("  <expression>            : e.g., '2d6', '1d20+2d4'")
    println("  define X = Y            : e.g., 'define strike = 1d20+4'")
    println("  load entities <file>    : Loads entity JSON")
    println("  load environment <file> : Loads Markov chain JSON")
    println("  env tick                : Advances environment state")
    println("  env status              : Shows current environment")
    println("  roll <attr> with <id>   : e.g., 'roll strike with hero'")
    println("  telemetry show          : Displays PI Karma sparkline")
    println("  exit/quit               : Terminates the engine")
    println("-------------------------------------------------------")

    var isRunning = true

    while (isRunning) {
      val input = readLine("\nscale> ")
      val command = Option(input).map(_.trim.toLowerCase).getOrElse("exit")

      command match {
        case "exit" | "quit" =>
          println("[System] Shutting down the engine. Goodbye!")
          isRunning = false

        case "save macros" => StateManager.saveMacros()
        case "load macros" => StateManager.loadMacros()
        case "reset karma" =>
          KarmaController.reset()
          println("[System] Karma controller state has been wiped.")

        case "telemetry show" =>
          TelemetryVisualizer.renderSparkline(StateManager.karmaHistory, "PI Karma Corrections")

        case "env tick" =>
          MarkovEngine.tick()

        case "env status" =>
          println(s"[Environment] Current State: ${MarkovEngine.getCurrentStateName}")

        case definePattern(macroName, diceExpression) =>
          StateManager.addMacro(macroName, diceExpression)

        case loadEntityPattern(filePath) =>
          EntityManager.loadEntities(filePath)

        case loadEnvPattern(filePath) =>
          MarkovEngine.loadStates(filePath)

        case entityRollPattern(attribute, entityName) =>
          EntityManager.getContextualRoll(entityName, attribute) match {
            case Some(expression) =>
              println(s"[System] $entityName uses $attribute -> Rolling: $expression")
              executeRoll(expression)
            case None =>
              println(s"[Error] Could not find attribute '$attribute' for entity '$entityName'.")
          }

        case "" => // Ignore

        case validCommand =>
          executeRoll(StateManager.expandInput(validCommand))
      }
    }
  }

  /**
   * Helper method to encapsulate the roll execution and PI update cycle.
   *
   * @param expression The expanded dice notation string.
   */
  private def executeRoll(expression: String): Unit = {
    try {
      val currentKarma = KarmaController.consumeKarma()
      val result = DiceEngine.evaluate(expression, currentKarma)

      println(result.toString)

      val rawOutcome = result.total - result.karmaApplied
      KarmaController.updateState(result.expectedMean, rawOutcome)
      StateManager.logRoll(result)

    } catch {
      case e: IllegalArgumentException => println(s"[Error] ${e.getMessage}")
      case e: Exception => println(s"[Fatal Error] ${e.getMessage}")
    }
  }
}
