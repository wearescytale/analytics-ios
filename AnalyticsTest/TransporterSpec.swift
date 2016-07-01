//
//  TransporterSpec.swift
//  Analytics
//
//  Created by Tony Xiao on 6/30/16.
//  Copyright © 2016 Segment. All rights reserved.
//

import Quick
import Nimble
import Nocilla

class TransporterSpec : QuickSpec {
  override func spec() {
    var transporter : SEGNetworkTransporter!
    beforeEach {
      let config = SEGAnalyticsConfiguration(writeKey: "XMTBm9QGhfkLKaevI50GYdD4mOcVDD83")
      transporter = SEGNetworkTransporter(configuration: config)
    }
    it("has correct API url") {
      expect(transporter.apiURL.absoluteString) == "https://api.segment.io/v1/import"
    }
    
    it("performs well under load") {
      stubRequest("POST", "https://api.segment.io/v1/import")
      self.measureBlock {
        for i in 1...1000 {
          transporter.queuePayload(["EXPENSIVE": "PAYLOAD" + String(i)])
        }
      }
    }
  }
}
