import Foundation
import ObjectMapper

/**
 SpaceBunny Channel object. It represent a single channel in the SpaceBunny architecture.
 For more info check out the SpaceBunny's documentation: http://www.spacebunny.io/getting-started/
 */
public class Channel: Mappable {

  /// The channel id
  var id: String?
  /// The channel name
  var name: String?

  /**
   ObjectMapper constructor

   - parameter map: The Map object
   */
  public required init?(_ map: Map) {
    mapping(map)
  }

  // MARK: - API Mapping

  /**
   ObjectMapper mapping

   - parameter map: The Map object
   */
  public func mapping(map: Map) {
    id <- map["id"]
    name <- map["name"]
  }
}
