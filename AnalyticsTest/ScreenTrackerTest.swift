//
//  ScreenTrackerTest.swift
//  Analytics
//
//  Created by Tony Xiao on 7/2/16.
//  Copyright © 2016 Segment. All rights reserved.
//

import Quick
import Nimble

class ScreenTrackerTest : QuickSpec {
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
  @objc(Objc2Controller)
  class Objc2Controller: UIViewController {
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
    it("tracks tabbar controller selected tab") {
      let tab = UITabBarController()
      swiftVC.title = "taylor"
      tab.viewControllers = [swiftVC]
//      tab.selectedViewController = swiftVC
      // TODO: Try mocking UIApplication.window topViewController
//      swiftVC.viewDidAppear(true)
      tab.viewDidAppear(true)
      expect(analytics.lastTrackedScreenName) == "taylor"

      swiftVC.title = "swift"
      let nav = UINavigationController(rootViewController: swiftVC)
      nav.viewDidAppear(true)
      expect(analytics.lastTrackedScreenName) == "swift"
    }
    // TODO: should we even track non-top level view controllers at all?
    // Aren't there gonna be multiple viewDidAppear calls?
    it("tracks using inferred screen name") {
      objcVC.viewDidAppear(true)
      expect(analytics.lastTrackedScreenName) == "Objc"
      let objcC2 = Objc2Controller()
      objcC2.viewDidAppear(true)
      expect(analytics.lastTrackedScreenName) == "Objc2"
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
