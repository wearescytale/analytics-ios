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
    var screenCalled = false
    var lastTrackedScreenName: String?
    @objc override func screen(screenName: String, properties: [String : AnyObject]?, options: [String : AnyObject]?) {
      screenCalled = true
      lastTrackedScreenName = screenName
    }
  }
  @objc(ObjcViewController)
  class ObjcViewController: UIViewController {
  }
  class SwiftViewController: UIViewController {
  }
  
  override func spec() {
    var tracker : SEGScreenTracker!
    var analytics : MockAnalytics!
    var objcVC: ObjcViewController!
    var swiftVC: SwiftViewController!
    beforeEach {
      analytics = MockAnalytics()
      tracker = SEGScreenTracker(analytics: analytics)
      objcVC = ObjcViewController()
      swiftVC = SwiftViewController()
      expect(tracker) != nil
      expect(analytics.lastTrackedScreenName).to(beNil())
    }
    it("tracks using screen title") {
      swiftVC.title = "Shopping"
      swiftVC.viewDidAppear(true)
      expect(analytics.lastTrackedScreenName) == "Shopping"
    }
    it("tracks using inferred screen name") {
      objcVC.viewDidAppear(true)
      expect(analytics.lastTrackedScreenName) == "Objc"
    }
    it("tracks unknown screens as well") {
      @objc(CrazyVC)
      class CrazyVC: UIViewController {
      }
      let crazyVC = CrazyVC()
      crazyVC.viewDidAppear(true)
      expect(analytics.screenCalled) == true
      expect(analytics.lastTrackedScreenName) == "Unknown"
    }
  }
}
