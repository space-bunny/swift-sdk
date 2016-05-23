import Foundation
import ObjectMapper

/**
 SpaceBunny Configuration object. It holds the info of a single device and is retrieved during the
 client connection
 */
public class Configuration: Mappable {

  /// Host for the MQTT connection
  public var host: String?
  /// Username for the MQTT connection
  public var username: String?
  /// Password for the MQTT connection
  public var password: String?
  /// The device name
  public var name: String?
  /// Port for the MQTT connection
  public var port: UInt?
  /// Port for the secure MQTT connection
  public var sslport: UInt?
  /// vHost for the MQTT connection
  public var vhost: String?

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
    name <- map["device_name"]
    port <- map["protocols.mqtt.port"]
    sslport <- map["protocols.mqtt.ssl_port"]
    vhost <- map["vhost"]
  }
}
