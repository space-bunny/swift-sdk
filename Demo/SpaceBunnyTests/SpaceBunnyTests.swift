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
  }
}

class SpaceBunnyTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testExample() {
      let client = SpaceBunnyClient(deviceKey: "")
      XCTAssertTrue(client == client)
    }

}
