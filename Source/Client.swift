import Foundation
import ObjectMapper
import CocoaMQTT

let EndpointScheme = "https"
let EndpointUrl = "api.spacebunny.io"

/// Exception raised by SpaceBunny's `Client`
enum SpaceBunnyError: ErrorType {
  /// The client was unexpectedly not connected
  case NotConnected
}

/** Connection state. Possible values:
 - `Connecting`
 - `Connected`
 - `Disconnected`
 */
@objc public enum SpaceBunnyState: Int {
  /// The client is set up and connecting to the platform
  case Connecting
  /// The client currently connected
  case Connected
  /// The client disconnected
  case Disconnected
}

/// SpaceBunny delegate protocol.
@objc public protocol SpaceBunnyDelegate: NSObjectProtocol {

  /**
 Called when a connection to the platform is established
   
   - parameter client: the SpaceBunnyClient instance
   - parameter host: the connection host
   - parameter host: the connection port
 */
  optional func spaceBunnyClient(client: SpaceBunnyClient, didConnectTo host: String, port: Int)

  /**
   Called when a connection to the platform is ended or failed

   - parameter client: the SpaceBunnyClient instance
   - parameter error: the error
   */
  optional func spaceBunnyClient(client: SpaceBunnyClient, didDisconnectWithError error: NSError?)

  /**
   Called when a new message is received on the device's inbox

   - parameter client: the SpaceBunnyClient instance
   - parameter message: the message
   - parameter topic: the topic
   */
  optional func spaceBunnyClient(client: SpaceBunnyClient, didReceiveMessage message: String?, topic: String)

  /**
   Called when a new message is sent

   - parameter client: the `SpaceBunnyClient` instance
   - parameter message: the message
   - parameter topic: the topic
   */
  optional func spaceBunnyClient(client: SpaceBunnyClient, didPublishMessage message: String?, topic: String)

  /**
   Called when a the client subscribes to the device's inbox

   - parameter client: the SpaceBunnyClient instance
   */
  optional func spaceBunnyClientDidSubscribe(client: SpaceBunnyClient)

  /**
   Called when a the client unsubscribes from the device's inbox

   - parameter client: the SpaceBunnyClient instance
   */
  optional func spaceBunnyClientDidUnsubscribe(client: SpaceBunnyClient)
}

/**
 SpaceBunny Client for device communications. It represents a single device and is used to
 send data on the device channels and subscribe to the device's inbox.
 */
@objc public class SpaceBunnyClient: NSObject {

  private var endpointScheme = ""
  private var endpointURLString = ""
  private var endpointPort: Int?
  internal var mqttClient: CocoaMQTT?
  private var onReceive: ((String?, String) -> Void)? = nil
  private var onConnect: (NSError? -> Void)? = nil

  /// The device key. It must be set in the `SpaceBunnyClient` initializer
  public private(set) var deviceKey: String?

  /// And array of `Channels` associated with the device. The information is retrieved upon connection
  public private(set) var channels: [Channel]? = nil

  /// The configuration parameters for the device, retrieved upon connection
  public private(set) var configuration: Configuration?

  /// Enables the secure connection to the platform
  public var useSSL = false

  /// The SpaceBunnyClient delegate
  public var delegate: SpaceBunnyDelegate?

  /**
   Convenience initializer. A valid device key must be provided. Get a valid device key on your 
   SpaceBunny's dashboard (http://spacebunny.io).
   An optional endpoint can be specified, if it differs from the default one (https://api.spacebunny.io)
   
   - parameter deviceKey: The device key
   - parameter endpointScheme: Optional endpoint URL scheme
   - parameter endpointUrl: Optional endpoint URL
   - parameter endpointPort: Optional endpoint URL port
   */
  public init(deviceKey: String, endpointScheme: String, endpointUrl: String, endpointPort: NSNumber?) {
    self.endpointURLString = endpointUrl
    self.endpointPort = endpointPort?.integerValue
    self.endpointScheme = endpointScheme
    self.deviceKey = deviceKey
  }

  /**
   Convenience initializer. A valid device key must be provided. Get a valid device key on your
   SpaceBunny's dashboard (http://spacebunny.io).

   - parameter deviceKey: The device key
   */
  public init(deviceKey: String) {
    self.endpointURLString = EndpointUrl
    self.endpointScheme = EndpointScheme
    self.deviceKey = deviceKey
  }

  /**
   Connect to the platform. The connection process retrieves the device configurations, the channels list and
   establishes a MQTT connection.

   - parameter completion: A block called when the connection is established. 
   If the connection failed, a non nil error is provided
   */
  public func connect(completion: ((NSError?) -> Void)? = nil) {
    guard let url = endpointURL() else { return }

    let request = NSMutableURLRequest(URL: url)
    request.setValue(deviceKey, forHTTPHeaderField: "Device-Key")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) in
      if let error = error {
        completion?(error)
      }
      if let data = data {
        do {
          let json = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)

          if let json = json as? NSDictionary, connection = json["connection"] as? NSDictionary {
            self.configuration = Mapper<Configuration>().map(connection)
          }
          if let json = json as? NSDictionary, channels = json["channels"] as? Array<NSDictionary> {
            self.channels = channels.flatMap { Mapper<Channel>().map($0) }
          }
          self.mqttConnect(completion)
        } catch let error as NSError {
          completion?(error)
        }
      }
      }.resume()
  }

  /**
   Publish a message on a given channel.

   - parameter channel: The name of the channel
   - parameter message: The message string
   - Throws `NotConnected` exception if no connection is available.
   */
  public func publishOn(channel: String, message: String) throws {
    guard let configuration = configuration, username = configuration.username where mqttClient?.connState == .CONNECTED else {
      throw SpaceBunnyError.NotConnected
    }

    mqttClient?.publish("\(username)/\(channel)", withString: message)
  }

  /**
   Subscribe to the device inbox. It throws an exception if no connection is available.

   - Throws `NotConnected` exception if no connection is available.
   - parameter onReceive: An optional block called when a new message is available.
   - seealso `CocoaMQTTMessage` for the message object returned
   */
  public func subscribe(onReceive: ((message: String?, topic: String) -> Void)?) throws {
    guard let configuration = configuration, username = configuration.username where mqttClient?.connState == .CONNECTED else {
      throw SpaceBunnyError.NotConnected
    }

    self.onReceive = onReceive
    mqttClient?.subscribe("\(username)/inbox")
  }

  /**
   Unsubscribe from the device inbox. It throws an exception if no connection is available.

   - Throws `NotConnected` exception if no connection is available.
   */
  public func unsubscribe() throws {
    guard let configuration = configuration, username = configuration.username where mqttClient?.connState == .CONNECTED else {
      throw SpaceBunnyError.NotConnected
    }

    onReceive = nil
    mqttClient?.unsubscribe("\(username)/inbox")
  }

  /**
   Connection status. Returns a value of type `SpaceBunnyState`

   - returns: SpaceBunnyState
   - seealso:
   SpaceBunnyState
   */
  public func status() -> SpaceBunnyState {
    guard let mqttClient = mqttClient else { return .Disconnected }

    switch mqttClient.connState {
    case CocoaMQTTConnState.INIT:
      return .Disconnected
    case CocoaMQTTConnState.CONNECTING:
      return .Connecting
    case CocoaMQTTConnState.CONNECTED:
      return .Connected
    case CocoaMQTTConnState.DISCONNECTED:
      return .Disconnected
    }
  }

  /**
   Disconnect from the platform
   */
  public func disconnect() {
    mqttClient?.disconnect()
  }

  func endpointURL() -> NSURL? {
    let components = NSURLComponents()
    components.scheme = endpointScheme
    if let port = endpointPort {
      components.port = port
    }
    components.host = endpointURLString
    components.path = "/v1/device_configurations"

    return components.URL
  }

  func mqttConnect(completion: (NSError? -> Void)? = nil) {
    guard let configuration = configuration, username = configuration.username, password = configuration.password, host = configuration.host else { return }
    mqttClient = CocoaMQTT(clientId: username, host: host, port: UInt16((useSSL ? configuration.sslport : configuration.port) ?? 1883))

    if let mqtt = mqttClient {
      onConnect = completion
      mqtt.secureMQTT = useSSL
      mqtt.username = "\(configuration.vhost ?? ""):\(username)"
      mqtt.password = password
      mqtt.keepAlive = 90
      mqtt.delegate = self
      mqtt.connect()
    }
  }

}

extension SpaceBunnyClient: CocoaMQTTDelegate {
  public func mqtt(mqtt: CocoaMQTT, didConnect host: String, port: Int) {
    onConnect?(nil)
    delegate?.spaceBunnyClient?(self, didConnectTo: host, port: port)
  }

  public func mqtt(mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
    delegate?.spaceBunnyClient?(self, didPublishMessage: message.string, topic: message.topic)
  }

  public func mqtt(mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
    onReceive?(message.string, message.topic)
    delegate?.spaceBunnyClient?(self, didReceiveMessage: message.string, topic: message.topic)
  }

  public func mqtt(mqtt: CocoaMQTT, didSubscribeTopic topic: String) {
    delegate?.spaceBunnyClientDidSubscribe?(self)
  }

  public func mqtt(mqtt: CocoaMQTT, didUnsubscribeTopic topic: String) {
    delegate?.spaceBunnyClientDidUnsubscribe?(self)
  }

  public func mqttDidDisconnect(mqtt: CocoaMQTT, withError err: NSError?) {
    delegate?.spaceBunnyClient?(self, didDisconnectWithError: err)
  }

  public func mqtt(mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {}
  public func mqttDidPing(mqtt: CocoaMQTT) {}
  public func mqttDidReceivePong(mqtt: CocoaMQTT) {}
  public func mqtt(mqtt: CocoaMQTT, didPublishAck id: UInt16) {}

}
