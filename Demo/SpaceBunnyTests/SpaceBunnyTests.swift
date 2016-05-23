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
  internal var isSubscribed = false

  init(expectedState state: CocoaMQTTConnState) {
    expectedState = state
    super.init(clientId: "")
  }

  override func subscribe(topic: String, qos: CocoaMQTTQOS) -> UInt16 {
    isSubscribed = true
    return 0
  }

  override func unsubscribe(topic: String) -> UInt16 {
    isSubscribed = false
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
    self.mqttClient = MockMQTTClient(expectedState: expectedState)
    completion?(nil)
  }
}

class SpaceBunnyTests: XCTestCase {

  func successMock(url: String = "https://api.spacebunny.io/v1/device_configurations") {
    let protocols = ["mqtt": ["port": 1883, "ssl_port": 8883]]
    let channels = [[ "id": "12345", "name": "data" ], [ "id": "54321", "name": "alarms" ]]
    let config = ["host": "mock.host", "device_id": "device", "device_name": "Some device", "secret": "s3cr3t", "vhost": "mock.vhost", "protocols": protocols]
    let body = [ "connection": config, "channels": channels ]
    stub(http(.GET, uri: url), builder: json(body))
  }

  func failueMock() {
    let error = NSError(domain: "MockingjayTests", code: 401, userInfo: nil)
    stub(http(.GET, uri: "https://api.spacebunny.io/v1/device_configurations"), builder: failure(error))
  }

  func malformedResponseMock() {
    stub(http(.GET, uri: "https://api.spacebunny.io/v1/device_configurations"), builder: http(200, headers: nil, data: NSData()))
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
      XCTAssertTrue(client.channels?.count == 2)
      let channel = client.channels?.first
      XCTAssertTrue(channel?.name == "data")
      XCTAssertTrue(channel?.id == "12345")
      expectation.fulfill()
    }
    self.waitForExpectationsWithTimeout(0.5, handler: nil)
  }

  func testCustomEndpoint() {
    successMock("https://endpoint.com:8080/v1/device_configurations")
    let expectation = self.expectationWithDescription("fetch config")

    let client = MockClient(deviceKey: "some-key", endpointScheme: "https", endpointUrl: "endpoint.com", endpointPort: 8080)
    client.connect() { _ in
      XCTAssertTrue(client.configuration?.host == "mock.host")
      expectation.fulfill()
    }
    self.waitForExpectationsWithTimeout(0.5, handler: nil)
  }

  func testInvalidEndpoint() {
    let expectation = self.expectationWithDescription("fetch config")

    let client = MockClient(deviceKey: "some-key", endpointScheme: "^^^", endpointUrl: "???", endpointPort: nil)
    client.connect() { error in
      XCTAssertNotNil(error)
      expectation.fulfill()
    }
    self.waitForExpectationsWithTimeout(0.5, handler: nil)
  }

  func testMalformedResponse() {
    let expectation = self.expectationWithDescription("fetch config")

    malformedResponseMock()
    let client = MockClient(deviceKey: "some-key")
    client.connect() { error in
      XCTAssertNotNil(error)
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
      if let mqtt = client.mqttClient as? MockMQTTClient {
        XCTAssertTrue(mqtt.didPublish)
      }
      expectation.fulfill()
    }
    self.waitForExpectationsWithTimeout(0.5, handler: nil)
  }

  func testPublishFailure() {
    let client = MockClient(deviceKey: "some-key", expectedState: .DISCONNECTED)
    successMock()
    XCTAssertThrowsError(try client.publishOn("data", message: "Hello"))
  }

  func testSubscribeSuccess() {
    let expectation = self.expectationWithDescription("subscribe success")

    let client = MockClient(deviceKey: "some-key", expectedState: .CONNECTED)
    successMock()
    client.connect() { _ in
      try! client.subscribe(nil)
      if let mqtt = client.mqttClient as? MockMQTTClient {
        XCTAssertTrue(mqtt.isSubscribed)
      }
      expectation.fulfill()
    }
    self.waitForExpectationsWithTimeout(0.5, handler: nil)
  }

  func testSubscribeFailure() {
    let client = MockClient(deviceKey: "some-key", expectedState: .DISCONNECTED)
    successMock()
    XCTAssertThrowsError(try client.subscribe(nil))
  }

  func testUnsubscribeSuccess() {
    let expectation = self.expectationWithDescription("subscribe success")

    let client = MockClient(deviceKey: "some-key", expectedState: .CONNECTED)
    successMock()
    client.connect() { _ in
      try! client.subscribe(nil)
      try! client.unsubscribe()
      if let mqtt = client.mqttClient as? MockMQTTClient {
        XCTAssertFalse(mqtt.isSubscribed)
      }
      expectation.fulfill()
    }
    self.waitForExpectationsWithTimeout(0.5, handler: nil)
  }

  func testUnsubscribeFailure() {
    let client = MockClient(deviceKey: "some-key", expectedState: .DISCONNECTED)
    successMock()
    XCTAssertThrowsError(try client.unsubscribe())
  }

}

class ConfigurationTests: XCTestCase {

  func testCreateManually() {
    let subject = Configuration(host: "host", username: "username", password: "password", name: "name", port: 1883, sslport: 8883, vhost: "vhost")
    XCTAssertTrue(subject.host == "host")
    XCTAssertTrue(subject.vhost == "vhost")
    XCTAssertTrue(subject.username == "username")
    XCTAssertTrue(subject.password == "password")
    XCTAssertTrue(subject.name == "name")
    XCTAssertTrue(subject.port == 1883)
    XCTAssertTrue(subject.sslport == 8883)
  }

}