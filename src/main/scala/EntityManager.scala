import upickle.default._
import scala.io.Source
import java.io.File
import scala.util.Using

/**
 * Handles the loading and resolution of GameEntities from JSON files.
 */
object EntityManager {
  private var activeEntities: Map[String, GameEntity] = Map()

  /**
   * Loads a JSON array of entities into memory.
   * Example JSON format: [{"name": "hero", "attributes": {"strike": "1d20+4"}}]
   *
   * @param filePath Path to the JSON file.
   */
  def loadEntities(filePath: String): Unit = {
    val file = new File(filePath)
    if (!file.exists()) {
      println(s"[System] Entity file not found: $filePath")
      return
    }

    Using(Source.fromFile(file)) { source =>
      val jsonString = source.mkString
      // Deserialize the JSON array into a List of GameEntity objects
      val entities = read[List[GameEntity]](jsonString)

      // Populate the map for quick lookup by name
      entities.foreach { entity =>
        activeEntities += (entity.name.toLowerCase -> entity)
      }
    }.fold(
      exception => println(s"[System] Error parsing entities: ${exception.getMessage}"),
      _ => println(s"[System] Successfully loaded ${activeEntities.size} entities.")
    )
  }

  /**
   * Retrieves the specific dice formula associated with an entity's attribute.
   *
   * @param entityName The character performing the action.
   * @param attribute The action being performed (e.g., "strike").
   * @return An option containing the dice formula string.
   */
  def getContextualRoll(entityName: String, attribute: String): Option[String] = {
    activeEntities.get(entityName.toLowerCase).flatMap(_.attributes.get(attribute.toLowerCase))
  }
}
