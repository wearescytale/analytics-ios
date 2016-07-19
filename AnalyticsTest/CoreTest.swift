//
//  CoreTest.swift
//  Analytics
//
//  Created by Tony Xiao on 6/30/16.
//  Copyright © 2016 Segment. All rights reserved.
//

import Quick
import Nimble
import Mockingjay

class CoreTest: QuickSpec {
  
  class MockDelegate : NSObject, SEGAnalyticsDelegate {
    var lastPayload: [NSString: AnyObject]?
    @objc func analytics(analytics: SEGAnalytics, newPayloadForPayload payload: [String : AnyObject]) -> [String : AnyObject] {
      lastPayload = payload
      return payload
    }
  }

  
  override func spec() {
    var analytics : SEGAnalytics!
    var delegate : MockDelegate!
    beforeEach { 
      analytics = SEGAnalytics(writeKey: SegmentWriteKey)
      delegate = MockDelegate()
      analytics.delegate = delegate
      expect(delegate.lastPayload).to(beNil())
    }
    afterEach { 
      analytics.reset()
    }
    it("initial has anonymousId but not userId") { 
      expect(analytics.user.anonymousId).toNot(beNil())
      expect(analytics.user.userId).to(beNil())
      analytics.identify("tswift")
      expect(analytics.user.userId).toEventually(equal("tswift"))
      analytics.reset()
      expect(analytics.user.userId).to(beNil())
    }
    it("queues payload properly") {
      analytics.track("App Open")
      expect(delegate.lastPayload).toEventuallyNot(beNil())
    }
    it("should be able to set debug mode and auto set flush immediately") {
      var flushed = false
      self.stub({ req in
        flushed = http(.POST, uri: "https://api.segment.io/v1/batch")(request: req)
        return flushed
        }, builder: http(200))
      SEGAnalytics.debug(true)
      analytics.debugMode = true
      analytics.track("Debug Mode Set")
      expect(flushed).toEventually(beTrue(), timeout: 0.1, description: "Expected flush to happen immediately")
      SEGAnalytics.debug(false)
    }
  }
}
