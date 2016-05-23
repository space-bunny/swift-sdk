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

  /**
   Manually create a new Configuration

   - parameter host: The connection host
   - parameter username: The connection username
   - parameter password: The connection password
   - parameter name: The device name
   - parameter port: The connection port
   - parameter sslport: The secure connection port
   - parameter vhost: The connection vHost
   */
  public required init(host: String, username: String, password: String, name: String, port: UInt, sslport: UInt, vhost: String) {
    self.host = host
    self.username = username
    self.password = password
    self.name = name
    self.port = port
    self.sslport = sslport
    self.vhost = vhost
  }

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
    host <- map["host"]
    username <- map["device_id"]
    password <- map["secret"]
    name <- map["device_name"]
    port <- map["protocols.mqtt.port"]
    sslport <- map["protocols.mqtt.ssl_port"]
    vhost <- map["vhost"]
  }
}
