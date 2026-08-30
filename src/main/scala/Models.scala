import upickle.default._

/**
 * Represents the complete, detailed result of a dice roll operation.
 *
 * @param originalExpression The raw string input provided by the user.
 * @param individualRolls A list containing the raw results of every die rolled.
 * @param keptRolls A list containing only the rolls that were kept for the calculation.
 * @param karmaApplied The external modifier injected by the PI controller.
 * @param expectedMean The statistical average expected for this roll formulation.
 * @param total The final calculated integer result.
 */
case class RollResult(
  originalExpression: String,
  individualRolls: List[Int],
  keptRolls: List[Int],
  karmaApplied: Int,
  expectedMean: Double,
  total: Int
) {
  override def toString: String = {
    val rollsStr = keptRolls.mkString(" + ")
    val karmaStr = if (karmaApplied != 0) s" [Karma: ${if (karmaApplied > 0) "+" else ""}$karmaApplied]" else ""
    s"Result: $total  [Rolls: ($rollsStr)]$karmaStr"
  }
}

// --- AST (Abstract Syntax Tree) Nodes for Parser Combinators ---

sealed trait ASTNode
case class NumberNode(value: Int) extends ASTNode
case class DiceNode(quantity: Int, sides: Int, explode: Boolean, keepConfig: Option[(String, Int)]) extends ASTNode
case class BinaryOpNode(left: ASTNode, op: String, right: ASTNode) extends ASTNode

// --- Entity Models ---

case class GameEntity(name: String, attributes: Map[String, String])

object GameEntity {
  implicit val rw: ReadWriter[GameEntity] = macroRW
}

// --- Environment Models (Markov Chain) ---

/**
 * Defines a discrete state within a Markov Chain environmental model.
 *
 * @param name The human-readable identifier for the state (e.g., "Clear", "Storm").
 * @param transitions A map of target state names to the d100 threshold required to transition.
 */
case class EnvironmentState(name: String, transitions: Map[String, Int])

object EnvironmentState {
  implicit val rw: ReadWriter[EnvironmentState] = macroRW
}
