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
      objcVC = ObjcViewController()
      swiftVC = SwiftViewController()
      objcVC.viewDidAppear(true)
      // sanity checks
      expect(analytics.lastTrackedScreenName).to(beNil())
      tracker = SEGScreenTracker(analytics: analytics)
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
    it("tracks unknown screens") {
      @objc(CrazyVC)
      class CrazyVC: UIViewController {
      }
      let crazyVC = CrazyVC()
      crazyVC.viewDidAppear(true)
      expect(analytics.screenCalled) == true
      expect(analytics.lastTrackedScreenName) == "Unknown"
    }
    it("works with multiple instances") {
      let analytics2 = MockAnalytics()
      let tracker2 = SEGScreenTracker(analytics: analytics2); tracker2 // surpress unused var warning
      objcVC.beginAppearanceTransition(true, animated: true)
      objcVC.endAppearanceTransition()
      expect(analytics.lastTrackedScreenName) == "Objc"
      expect(analytics2.lastTrackedScreenName) == "Objc"
    }
  }
}
