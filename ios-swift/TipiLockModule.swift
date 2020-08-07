//
//  RNTipilockModule.swift
//  RNTipiLockModule
//
//  Created by Ahmad on 7/18/19.
//  Copyright © 2019 Facebook. All rights reserved.
//

import Foundation

@objc(TipiLockModule)
class TipiLockModule: RCTEventEmitter  {

  override init() {
    super.init()
  }
  // we need to override this method and
  // return an array of event names that we can listen to
  override func supportedEvents() -> [String]! {
    return ["ScanLockDeviceEvent"]
  }

  override static func requiresMainQueueSetup() -> Bool {
    return true
  }


  // export constants
  override func constantsToExport() -> [AnyHashable : Any]! {
    return [
      "test_constant":111
    ]
  }

  @objc
  func initialise() {
    print("ios:react-native-tipilock > initialise()")
  }

  @objc
  func lockInitialize(_ lockMac:NSString, callback: RCTResponseSenderBlock) {
    callback([[
      "testValue":lockMac
    ]])
  }
//
//  @objc
//  func testPromise(
//    _ resolve: RCTPromiseResolveBlock,
//    rejecter reject: RCTPromiseRejectBlock
//    ) -> Void {
//    let error = NSError(domain: "", code: 200, userInfo: nil)
//    //reject("E_COUNT", "count cannot be negative", error)
//    resolve("count was decremented")
//  }


}
