//
//  TransporterSpec.swift
//  Analytics
//
//  Created by Tony Xiao on 6/30/16.
//  Copyright © 2016 Segment. All rights reserved.
//

import Quick
import Nimble
import Mockingjay

class TransporterSpec : QuickSpec {
  override func spec() {
    var transporter : SEGNetworkTransporter!
    beforeEach {
      transporter = SEGNetworkTransporter(writeKey: "XMTBm9QGhfkLKaevI50GYdD4mOcVDD83", flushAfter: 30)
    }
    it("has correct API url") {
      expect(transporter.apiURL.absoluteString) == "https://api.segment.io/v1/import"
    }
    
    it("performs well under load") {
      self.stub(http(.POST, uri: "https://api.segment.io/v1/import"), builder: http(200))
      self.measureBlock {
        for i in 1...1000 {
          transporter.queuePayload(["EXPENSIVE": "PAYLOAD" + String(i)])
        }
      }
    }
  }
}
