import org.scalatest.funsuite.AnyFunSuite

class DiceEngineTest extends AnyFunSuite {

  test("parser supports keep-high notation") {
    DiceParser.parse("4d6kh3+2") match {
      case BinaryOpNode(DiceNode(4, 6, false, Some(("kh", 3))), "+", NumberNode(2)) => succeed
      case other => fail(s"Unexpected AST: $other")
    }
  }

  test("keep-high actually keeps three dice") {
    EntropyFusionFilter.reset()
    val result = DiceEngine.evaluate("4d6kh3+2")
    assert(result.individualRolls.size == 4)
    assert(result.keptRolls.size == 3)
    assert(result.total >= 5 && result.total <= 20)
  }

  test("invalid dice are rejected") {
    assertThrows[IllegalArgumentException] {
      DiceEngine.evaluate("1d0")
    }
  }

  test("entropy fusion stays inside die bounds") {
    EntropyFusionFilter.reset()
    val rolls = (1 to 500).map(_ => EntropyFusionFilter.fuseRoll(20))
    assert(rolls.forall(r => r >= 1 && r <= 20))
  }

  test("ASTRA entity fixture is loadable by SCALE") {
    EntityManager.loadEntities("data/astra_entities.json")
    assert(EntityManager.getContextualRoll("The arians", "conflict_modifier").contains("1d1-6"))
    assert(EntityManager.getContextualRoll("The arans", "tech_rank").contains("2"))
  }

  test("PI karma controller produces and consumes compensation") {
    KarmaController.reset()
    KarmaController.updateState(expectedMean = 10.0, actualResult = 0)
    assert(KarmaController.consumeKarma() > 0)
    assert(KarmaController.consumeKarma() == 0)
  }
}
