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

  override func subscribe(topic: String, qos: CocoaMQTTQOS) -> UInt16 {
    return 0
  }

  override func publish(topic: String, withString string: String, qos: CocoaMQTTQOS, retained: Bool, dup: Bool) -> UInt16 {
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
  override func mqttConnect(completion: (NSError? -> Void)?) {
    self.mqttClient = MockMQTTClient(clientId: "")
    completion?(nil)
  }
}

class SpaceBunnyTests: XCTestCase {

  override func setUp() {
    super.setUp()

    let protocols = ["mqtt": ["port": 1883, "ssl_port": 8883]]
    let config = ["host": "mock.host", "device_id": "device", "secret": "s3cr3t", "vhost": "mock.vhost", "protocols": protocols]
    let body = [ "connection": config ]
    stub(http(.GET, uri: "https://api.demo.spacebunny.io/v1/device_configurations"), builder: json(body))
  }

  override func tearDown() {
    super.tearDown()
  }

  func testConfiguration() {
    let expectation = self.expectationWithDescription("fetch config")

    let client = MockClient(deviceKey: "some-key")
    client.connect() { _ in
      XCTAssertTrue(client.configuration?.host == "mock.host")
      XCTAssertTrue(client.configuration?.vhost == "mock.vhost")
      XCTAssertTrue(client.configuration?.username == "device")
      XCTAssertTrue(client.configuration?.password == "s3cr3t")
      XCTAssertTrue(client.configuration?.port == 1883)
      XCTAssertTrue(client.configuration?.sslport == 8883)
      expectation.fulfill()
    }
    self.waitForExpectationsWithTimeout(0.5, handler: nil)
  }

}
