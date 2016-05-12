//
//  SpaceBunnyTests.swift
//  SpaceBunnyTests
//
//  Created by Andrea Mazzini on 08/05/16.
//  Copyright © 2016 Andrea Mazzini. All rights reserved.
//

import XCTest
@testable import SpaceBunny

class SpaceBunnyTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testExample() {
      let client = SpaceBunnyClient(deviceKey: "")
      assert(client == client)
    }

}
