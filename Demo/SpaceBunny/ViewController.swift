//
//  ViewController.swift
//  SpaceBunny
//
//  Created by Andrea Mazzini on 08/05/16.
//  Copyright © 2016 Andrea Mazzini. All rights reserved.
//

import UIKit
import SpaceBunny

class ViewController: UIViewController {

  // Create a client with a given device key. Get your key from your SpaceBunny's dashboard
  let client = SpaceBunnyClient(deviceKey: "d4aadd1a-a2a1-4e71-a2fa-52c03a1f702b:DSs4KZ7M9yrj74KVksXK8Q")

  override func viewDidLoad() {
    super.viewDidLoad()

    // Set the SpaceBunnyDelegate
    client.delegate = self

    // Enable SSL
    client.useSSL = true

    // Connect to the platform.
    client.connect() { [weak self] error in
      // Completion handler provides an optional error.
      guard error == .None else { print(error); return }
      self?.subscribe()
    }
  }

  func subscribe() {
    // Subscribe to the device's inbox. Can throw
    do {
      try client.subscribe() { (message, topic) in
        print("Received message: \(message ?? "No message")")
      }
    } catch {
      print("no connection")
    }
  }

  @IBAction func buttonAction() {
    // Publish a message on a given topic. Can throw
    do {
      try client.publishOn("data", message: "test")
    } catch {
      print("no connection")
    }
  }

}

// MARK: - SpaceBunnyDelegate

extension ViewController: SpaceBunnyDelegate {

  func spaceBunnyClient(client: SpaceBunnyClient, didConnectTo host: String, port: Int) {
    print("Connection successful")
  }

  func spaceBunnyClient(client: SpaceBunnyClient, didDisconnectWithError error: NSError?) {
    print("Disconnected")
    if let error = error {
      print("With error: \(error)")
    }
  }

}

