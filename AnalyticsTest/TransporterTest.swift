//
//  TransporterTest.swift
//  Analytics
//
//  Created by Tony Xiao on 6/30/16.
//  Copyright © 2016 Segment. All rights reserved.
//

import Quick
import Nimble
import Mockingjay

class TransporterTest : QuickSpec {
  override func spec() {
    var transporter : SEGNetworkTransporter!
    beforeEach {
      transporter = SEGNetworkTransporter(writeKey: SegmentWriteKey, flushAfter: 30)
    }
    afterEach { 
      transporter.reset()
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
    it("flushes whhen we hit flushAt") {
      var flushed = false
      self.stub({ req in
        flushed = http(.POST, uri: "https://api.segment.io/v1/import")(request: req)
        return flushed
      }, builder: http(200))
      expect(flushed) == false
      
      transporter.flushAt = 3;
      transporter.queuePayload(["EVENT 1": "SOME PAYLOAD"])
      transporter.queuePayload(["EVENT 2": "SOME PAYLOAD"])
      
      var timedOut = false
      let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * Double(NSEC_PER_SEC)))
      dispatch_after(delayTime, dispatch_get_main_queue()) {
        timedOut = true
      }
      expect(timedOut).toEventually(beTrue())
      expect(flushed) == false
      
      transporter.queuePayload(["EVENT 3": "SOME PAYLOAD"])
      expect(flushed).toEventually(beTrue())
    }
    it("flushes after timeout") {
      var flushed = false
      self.stub({ req in
        flushed = http(.POST, uri: "https://api.segment.io/v1/import")(request: req)
        return flushed
        }, builder: http(200))
      transporter = SEGNetworkTransporter(writeKey: SegmentWriteKey, flushAfter: 0.5)
      transporter.queuePayload(["My Payload": "123"])
      expect(flushed).toEventually(beTrue())
    }
    it("persists queue to and load from disk") {
      expect(transporter.cacheURL.checkResourceIsReachableAndReturnError(nil)) == false
      transporter.queuePayload(["Hi": "There"])
      expect(transporter.cacheURL.checkResourceIsReachableAndReturnError(nil)).toEventually(beTrue())
      let transporter2 = SEGNetworkTransporter(writeKey: SegmentWriteKey, flushAfter: 30)
      expect(transporter2.queue) == [["Hi": "There"]]
    }
    it("reset clears queue") {
      transporter.queuePayload(["Hello": "World"])
      expect(transporter.queue).toEventually(equal([["Hello": "World"]]))
      transporter.reset()
      expect(transporter.queue) == []
      let transporter2 = SEGNetworkTransporter(writeKey: SegmentWriteKey, flushAfter: 30)
      expect(transporter2.queue) == []
    }
  }
}
