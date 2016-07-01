//
//  NetworkSpec.swift
//  Analytics
//
//  Created by Tony Xiao on 6/30/16.
//  Copyright © 2016 Segment. All rights reserved.
//

import Quick
import Nimble
import Nocilla

class NetworkSpec: QuickSpec {
  override func spec() {
    let urlReq = NSURLRequest(URL: NSURL(string: "http://google.com")!)
    beforeSuite {
      LSNocilla.sharedInstance().start()
    }
    beforeEach {
      LSNocilla.sharedInstance().clearStubs()
    }
    afterSuite {
      LSNocilla.sharedInstance().stop()
    }
    it("inits properly") {
      var req : SEGAnalyticsRequest?
      var responseData: NSData?
      stubRequest("GET", "http://google.com").andReturn(200).withBody("HelloGoogle")
      req = SEGAnalyticsRequest.startWithURLRequest(urlReq) {
          print(req?.responseJSON)
          responseData = req?.responseData
      }
      expect(req) != nil
      expect(responseData).toEventuallyNot(beNil())
      expect(responseData?.length) > 0
    }
    it("parses json") {
      let body = try? NSJSONSerialization.dataWithJSONObject(["hello": "world"], options: [])
      stubRequest("GET", "http://google.com").andReturn(200).withBody(body)
      let req = SEGAnalyticsRequest.startWithURLRequest(urlReq, completion: nil)
      expect(req.responseJSON).toEventuallyNot(beNil())
      expect(req.responseJSON["hello"]) == "world"
    }
  }
}
