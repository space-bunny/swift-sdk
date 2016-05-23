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
  let client = SpaceBunnyClient(deviceKey: "1377cd37-dae6-4a44-b1b9-478c32df2f23:xT6JysSZsMWyVM5EtU8_nw")

  override func viewDidLoad() {
    super.viewDidLoad()
  }

  func connectAndSubscribe() {
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

  @IBAction func connectAction() {
    connectAndSubscribe()
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

