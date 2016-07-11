//
//  CoreSpec.swift
//  Analytics
//
//  Created by Tony Xiao on 6/30/16.
//  Copyright © 2016 Segment. All rights reserved.
//

import Quick
import Nimble
import Mockingjay

class CoreSpec: QuickSpec {
  
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
//    it("initial has anonymousId but not userId") { 
//      
//    }
    it("queues payload properly") {
      analytics.track("App Open")
      expect(delegate.lastPayload).toEventuallyNot(beNil())
    }
  }
}
