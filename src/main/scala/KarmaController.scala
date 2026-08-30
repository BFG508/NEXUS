/**
 * A Proportional-Integral (PI) controller designed to track RNG variance
 * and inject compensatory modifiers ("Karma") to balance long-term luck.
 */
object KarmaController {
  private var accumulatedError: Double = 0.0
  private var pendingKarmaModifier: Int = 0

  // Tuning parameters for the controller
  private val kp: Double = 0.15 // Proportional gain
  private val ki: Double = 0.05 // Integral gain

  /**
   * Retrieves and consumes the current karma modifier for the next roll.
   *
   * @return The integer modifier to be added to the roll total.
   */
  def consumeKarma(): Int = {
    val karma = pendingKarmaModifier
    pendingKarmaModifier = 0
    karma
  }

  /**
   * Updates the internal PI state based on the discrepancy between the
   * mathematical expectation and the actual outcome.
   *
   * @param expectedMean The statistical average of the expression rolled.
   * @param actualResult The raw result achieved before any karma was applied.
   */
  def updateState(expectedMean: Double, actualResult: Int): Unit = {
    // Calculate the error: positive error means bad luck (rolled lower than expected)
    val error = expectedMean - actualResult.toDouble

    // Accumulate error over time
    accumulatedError += error

    // Calculate the control signal
    val controlSignal = (kp * error) + (ki * accumulatedError)

    // If the control signal is strong enough, queue a modifier and reset the integral
    if (math.abs(controlSignal) >= 1.0) {
      pendingKarmaModifier = math.round(controlSignal).toInt
      // Anti-windup: reset the accumulator once karma is dispersed
      accumulatedError = 0.0
    }
  }

  /**
   * Resets the controller state entirely.
   */
  def reset(): Unit = {
    accumulatedError = 0.0
    pendingKarmaModifier = 0
  }
}
