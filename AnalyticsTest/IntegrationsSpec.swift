//
//  IntegrationsSpec.swift
//  Analytics
//
//  Created by Tony Xiao on 6/30/16.
//  Copyright © 2016 Segment. All rights reserved.
//

import Quick
import Nimble
import Mockingjay

class IntegrationsSpec: QuickSpec {
  
  class MockIntegration : NSObject, SEGIntegration, SEGIntegrationFactory {
    var lastTrackedEvent: String?
    var created = false
    @objc func createWithSettings(settings: [NSObject : AnyObject]!, forAnalytics analytics: SEGAnalytics!) -> SEGIntegration! {
      created = true
      return self
    }
    @objc func key() -> String! {
      return "mock"
    }
    
    @objc func track(payload: SEGTrackPayload!) {
      lastTrackedEvent = payload.event
    }
  }
  
  override func spec() {
    var integrations: SEGIntegrationsManager!
    var mockIntegration: MockIntegration!
    
    beforeEach {
      self.stub(http(.GET, uri: "https://cdn.segment.com/v1/projects/TEST_KEY/settings"),
        builder: json(["integrations": ["mock": [:]]]))
      mockIntegration = MockIntegration()
      let config = SEGAnalyticsConfiguration(writeKey: "TEST_KEY")
      config.use(mockIntegration)
      let analytics = SEGAnalytics(configuration: config)
      integrations = analytics.valueForKey("integrations") as? SEGIntegrationsManager
    }
    
    it("calls track on integration") {
      integrations.track("My Event", properties: nil, options: nil)
      expect(integrations) != nil
      expect(mockIntegration.created).toEventually(beTrue())
      expect(mockIntegration.lastTrackedEvent).toEventually(equal("My Event"))
    }
  }
}
