import java.io.{File, FileWriter, PrintWriter}
import java.time.LocalDateTime
import scala.collection.mutable
import scala.io.Source
import scala.util.Using

/**
 * Handles the mutable state of the REPL session, including macros and telemetry history.
 */
object StateManager {
  private val macros: mutable.Map[String, String] = mutable.Map()
  private val historyFile = new File("scale_history.log")
  private val macrosFile = new File("scale_macros.txt")

  // Stores the historical karma signals for telemetry visualization
  var karmaHistory: List[Double] = List()

  def addMacro(name: String, expression: String): Unit = {
    val cleanName = name.trim.toLowerCase
    val cleanExpr = expression.trim.toLowerCase
    macros += (cleanName -> cleanExpr)
    println(s"[System] Macro successfully mapped: '$cleanName' => '$cleanExpr'")
  }

  def expandInput(input: String): String = {
    val cleanInput = input.trim.toLowerCase
    macros.getOrElse(cleanInput, cleanInput)
  }

  def logRoll(result: RollResult): Unit = {
    // Save to file
    val writer = new FileWriter(historyFile, true)
    try {
      val timestamp = LocalDateTime.now().withNano(0).toString
      writer.write(s"[$timestamp] ${result.originalExpression} -> Total: ${result.total} (Karma: ${result.karmaApplied})\n")
    } finally {
      writer.close()
    }

    // Store karma application in memory for telemetry
    karmaHistory = karmaHistory :+ result.karmaApplied.toDouble
    // Keep history manageable (e.g., last 50 rolls)
    if (karmaHistory.size > 50) karmaHistory = karmaHistory.drop(1)
  }

  def saveMacros(): Unit = {
    val writer = new PrintWriter(macrosFile)
    try {
      macros.foreach { case (name, expr) => writer.println(s"$name=$expr") }
      println(s"[System] Saved ${macros.size} macro(s).")
    } finally {
      writer.close()
    }
  }

  def loadMacros(): Unit = {
    if (!macrosFile.exists()) return
    Using(Source.fromFile(macrosFile)) { source =>
      for (line <- source.getLines()) {
        val parts = line.split("=", 2)
        if (parts.length == 2) macros += (parts(0) -> parts(1))
      }
    }
  }
}
