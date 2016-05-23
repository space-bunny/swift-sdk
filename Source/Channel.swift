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

  public required init?(_ map: Map) {
    mapping(map)
  }

  // MARK: - API Mapping

  public func mapping(map: Map) {
    id <- map["id"]
    name <- map["name"]
  }
}
