import Foundation
import ObjectMapper

public class Channel: Mappable {
  var id: String?
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
