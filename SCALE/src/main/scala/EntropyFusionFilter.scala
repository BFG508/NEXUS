import java.security.SecureRandom
import scala.util.Random

/**
 * Experimental scalar Kalman estimator that fuses two independent RNG
 * measurements in normalized [0, 1] space. The output is intentionally a
 * variance-reduced stochastic estimate, not a cryptographically uniform die.
 */
object EntropyFusionFilter {

  private val fastRng = new Random()
  private val secureRng = new SecureRandom()

  private var estimatedNormalized: Double = 0.5
  private var errorCovariance: Double = 1.0
  private var initialized: Boolean = false

  // Covariance tuning parameters (experimental, dimensionless).
  private val processNoise: Double = 0.10
  private val fastRngNoise: Double = 0.50
  private val secureRngNoise: Double = 0.10

  private def update(measurement: Double, measurementNoise: Double): Unit = {
    val kalmanGain = errorCovariance / (errorCovariance + measurementNoise)
    estimatedNormalized = estimatedNormalized + kalmanGain * (measurement - estimatedNormalized)
    errorCovariance = (1.0 - kalmanGain) * errorCovariance
  }

  /**
   * Fuse pseudo-random and SecureRandom measurements for a die with `sides`.
   * The two measurements are normalized before filtering so state remains
   * comparable when expressions switch between dice with different side counts.
   */
  def fuseRoll(sides: Int): Int = synchronized {
    require(sides >= 1, "Dice must have at least one side.")
    if (sides == 1) return 1

    val fastMeasurement = fastRng.nextInt(sides) + 1
    val secureMeasurement = secureRng.nextInt(sides) + 1
    val scale = (sides - 1).toDouble
    val fastNormalized = (fastMeasurement - 1).toDouble / scale
    val secureNormalized = (secureMeasurement - 1).toDouble / scale

    if (!initialized) {
      estimatedNormalized = (fastNormalized + secureNormalized) / 2.0
      initialized = true
    }

    // Prediction step.
    errorCovariance += processNoise

    // Sequential measurement updates.
    update(fastNormalized, fastRngNoise)
    update(secureNormalized, secureRngNoise)

    val bounded = math.max(0.0, math.min(1.0, estimatedNormalized))
    math.round(bounded * scale).toInt + 1
  }

  def reset(): Unit = synchronized {
    estimatedNormalized = 0.5
    errorCovariance = 1.0
    initialized = false
  }
}
