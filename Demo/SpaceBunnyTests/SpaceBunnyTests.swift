//
//  SpaceBunnyTests.swift
//  SpaceBunnyTests
//
//  Created by Andrea Mazzini on 08/05/16.
//  Copyright © 2016 Andrea Mazzini. All rights reserved.
//

import XCTest
@testable import SpaceBunny
import CocoaMQTT
import Mockingjay

class MockMQTTClient: CocoaMQTT {

  var expectedState = CocoaMQTTConnState.CONNECTED
  internal var didPublish = false

  init(expectedState state: CocoaMQTTConnState) {
    expectedState = state
    super.init(clientId: "")
  }

  override func subscribe(topic: String, qos: CocoaMQTTQOS) -> UInt16 {
    return 0
  }

  override func publish(topic: String, withString string: String, qos: CocoaMQTTQOS, retained: Bool, dup: Bool) -> UInt16 {
    didPublish = true
    return 0
  }

  override var connState: CocoaMQTTConnState {
    get {
      return expectedState
    }
    set { }
  }

}

class MockClient: SpaceBunnyClient {
  var expectedState = CocoaMQTTConnState.CONNECTED

  convenience init(deviceKey: String, expectedState state: CocoaMQTTConnState) {
    self.init(deviceKey: "")
    expectedState = state
  }

  override func mqttConnect(completion: (NSError? -> Void)?) {
    print("override")
    self.mqttClient = MockMQTTClient(expectedState: expectedState)
    completion?(nil)
  }
}

class SpaceBunnyTests: XCTestCase {

  func successMock() {
    let protocols = ["mqtt": ["port": 1883, "ssl_port": 8883]]
    let channels = [[ "id": "12345", "name": "data" ], [ "id": "54321", "name": "alarms" ]]
    let config = ["host": "mock.host", "device_id": "device", "device_name": "Some device", "secret": "s3cr3t", "vhost": "mock.vhost", "protocols": protocols, "channels": channels]
    let body = [ "connection": config ]
    stub(http(.GET, uri: "https://api.spacebunny.io/v1/device_configurations"), builder: json(body))
  }

  func failueMock() {
    let error = NSError(domain: "MockingjayTests", code: 401, userInfo: nil)
    stub(http(.GET, uri: "https://api.spacebunny.io/v1/device_configurations"), builder: failure(error))
  }

  override func setUp() {
    super.setUp()
  }

  override func tearDown() {
    super.tearDown()
  }

  func testConfiguration() {
    successMock()
    let expectation = self.expectationWithDescription("fetch config")

    let client = MockClient(deviceKey: "some-key")
    client.connect() { _ in
      XCTAssertTrue(client.configuration?.host == "mock.host")
      XCTAssertTrue(client.configuration?.vhost == "mock.vhost")
      XCTAssertTrue(client.configuration?.username == "device")
      XCTAssertTrue(client.configuration?.password == "s3cr3t")
      XCTAssertTrue(client.configuration?.name == "Some device")
      XCTAssertTrue(client.configuration?.port == 1883)
      XCTAssertTrue(client.configuration?.sslport == 8883)
      expectation.fulfill()
    }
    self.waitForExpectationsWithTimeout(0.5, handler: nil)
  }

  func testAuthenticationFailure() {
    failueMock()
    let expectation = self.expectationWithDescription("auth error")

    let client = MockClient(deviceKey: "some-wrong-key")
    client.connect() { error in
      XCTAssertNotNil(error)
      expectation.fulfill()
    }
    self.waitForExpectationsWithTimeout(0.5, handler: nil)
  }

  func testPublishOnSuccess() {
    let expectation = self.expectationWithDescription("publish success")

    let client = MockClient(deviceKey: "some-key", expectedState: .CONNECTED)
    successMock()
    client.connect() { _ in
      try! client.publishOn("data", message: "Hello")
      print(client.mqttClient)
      if let mqtt = client.mqttClient as? MockMQTTClient {
        XCTAssertTrue(mqtt.didPublish)
      }
      expectation.fulfill()
    }
    self.waitForExpectationsWithTimeout(0.5, handler: nil)
  }

}
