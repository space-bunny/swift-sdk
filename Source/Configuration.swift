import Foundation
import ObjectMapper

public class Configuration: Mappable {

  var host: String?
  var username: String?
  var password: String?
  var port: UInt?
  var sslport: UInt?
  var vhost: String?

  public required init(host: String, username: String, password: String, port: UInt, vhost: String) {
    self.host = host
    self.username = username
    self.password = password
    self.port = port
    self.sslport = port
    self.vhost = vhost
  }

  public required init?(_ map: Map) {
    mapping(map)
  }

  // MARK: - API Mapping

  public func mapping(map: Map) {
    host <- map["host"]
    username <- map["device_id"]
    password <- map["secret"]
    port <- map["protocols.mqtt.port"]
    sslport <- map["protocols.mqtt.ssl_port"]
    vhost <- map["vhost"]
  }
}
