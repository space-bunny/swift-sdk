<p align="center">
  <img width="480" src="assets/logo.png"/>
</p>

[Space Bunny](http://spacebunny.io) is the IoT platform that makes it easy for you and your devices to send and exchange messages with a server or even with each other. You can store the data, receive timely event notifications, monitor live streams and remotely control your devices. Easy to use, and ready to scale at any time.

##Installation

###CocoaPods
```
use_frameworks!

pod 'SpaceBunny'
```

##Usage

###Connection
Configure the instance of the SpaceBunny's `Client` with a valid Device Key:
```swift
let client = Client(deviceKey: "some-device-key")
```
Set up the client if needed:
```swift
client.useSSL = true
client.delegate = self
```
Connect the client to the platform. You can provide a completion block called when the connection is either successfull or failed (in this case you are provided with the info about the error encountered)
```swift
client.connect() { error in
  if let error == error {
    print(error)
  }
}
```

###Publishing
You can publish a message by providing the channel name. You can retrieve the channels associated with the device via the `channels` property of a client:
```swift
do {
  try client.publishOn("data", message: "test")
} catch {
  print("Unable to publish")
}
```

###Subscribing
You can subscribe to the current device's inbox and receive messages as soon as they are avaialble by either providing a closure to the `subscribe` function or by implementing the `client(_, didReceiveMessage: topic:)` 
```swift
do {
  try client.subscribe() { (message, topic) in
    print("Received message: \(message ?? "No message")")
  }
} catch {
  print("Unable to subscribe")
}
```

###Delegate methods
```swift
// Called when a connection to the platform is established
func client(client: Client, didConnectTo host: String, port: Int)
   
// Called when a connection to the platform is ended or failed
func client(client: Client, didDisconnectWithError error: NSError?)
   
// Called when a new message is received on the device's inbox
func client(client: Client, didReceiveMessage message: String?, topic: String)
   
// Called when a new message is sent
func client(client: Client, didPublishMessage message: String?, topic: String)
   
// Called when a the client subscribes to the device's inbox
func clientDidSubscribe(client: Client)

// Called when a the client unsubscribes from the device's inbox
func clientDidUnsubscribe(client: Client)
```

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
