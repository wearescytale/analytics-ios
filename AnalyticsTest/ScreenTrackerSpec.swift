//
//  ScreenTrackerSpec.swift
//  Analytics
//
//  Created by Tony Xiao on 7/2/16.
//  Copyright © 2016 Segment. All rights reserved.
//

import Quick
import Nimble

class ScreenTrackerSpec : QuickSpec {
  class MockAnalytics : SEGAnalytics {
    var lastTrackedScreenName: String?
    @objc override func screen(screenName: String, properties: [String : AnyObject]?, options: [String : AnyObject]?) {
      lastTrackedScreenName = screenName
    }
  }
  @objc(ObjcViewController)
  class ObjcViewController: UIViewController {
  }
  
  override func spec() {
    var tracker : SEGScreenTracker!
    var analytics : MockAnalytics!
    var objcVC: ObjcViewController!
    beforeEach {
      analytics = MockAnalytics()
      tracker = SEGScreenTracker(analytics: analytics)
      objcVC = ObjcViewController()
      expect(tracker) != nil
    }
    fit("tracks when viewDidAppear") {
      expect(analytics.lastTrackedScreenName).to(beNil())
      objcVC.viewDidAppear(true)
      expect(analytics.lastTrackedScreenName) == "Objc"
    }
  }
}
