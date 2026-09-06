import scala.util.parsing.combinator._

/**
 * A lexical parser for the SCALE engine using combinators.
 * Translates text directly into an Abstract Syntax Tree (AST).
 */
object DiceParser extends RegexParsers {

  /** Parses a simple integer number. */
  def number: Parser[Int] = """\d+""".r ^^ { _.toInt }

  /** Parses advantage/disadvantage flags (e.g., 'kh1', 'kl2'). */
  def keepModifier: Parser[(String, Int)] = ("kh" | "kl") ~ number ^^ {
    case kt ~ amt => (kt, amt)
  }

  /** Parses the core dice notation including explosions and keep configurations. */
  def diceOp: Parser[DiceNode] = opt(number) ~ "d" ~ number ~ opt("!") ~ opt(keepModifier) ^^ {
    // We use '_' instead of "d" here to satisfy the exhaustiveness checker,
    // since the combinator structure already guarantees a "d" will be at this position.
    case qtyOpt ~ _ ~ sides ~ expOpt ~ keepOpt =>
      DiceNode(qtyOpt.getOrElse(1), sides, expOpt.isDefined, keepOpt)
  }

  /** A term can be either a dice operation or a static number. */
  def term: Parser[ASTNode] = diceOp | (number ^^ NumberNode)

  /** Parses expressions linked by addition or subtraction, building a binary tree. */
  def expression: Parser[ASTNode] = chainl1(term,
    "+" ^^^ { (left: ASTNode, right: ASTNode) => BinaryOpNode(left, "+", right) } |
    "-" ^^^ { (left: ASTNode, right: ASTNode) => BinaryOpNode(left, "-", right) }
  )

  /**
   * Executes the parser against a given string.
   *
   * @param input The raw dice string.
   * @return The root ASTNode of the parsed expression.
   * @throws IllegalArgumentException If the grammar is invalid.
   */
  def parse(input: String): ASTNode = {
    val sanitized = input.replaceAll("\\s+", "").toLowerCase

    // Explicitly handling all ParseResult subclasses (Success, Failure, Error)
    // to ensure complete pattern matching exhaustiveness.
    parseAll(expression, sanitized) match {
      case Success(result, _) => result
      case Failure(msg, _)    => throw new IllegalArgumentException(s"Syntax error: $msg")
      case Error(msg, _)      => throw new IllegalArgumentException(s"Fatal syntax error: $msg")
    }
  }
}
