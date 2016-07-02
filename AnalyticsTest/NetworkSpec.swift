//
//  NetworkSpec.swift
//  Analytics
//
//  Created by Tony Xiao on 6/30/16.
//  Copyright © 2016 Segment. All rights reserved.
//

import Quick
import Nimble
import Mockingjay

class NetworkSpec: QuickSpec {
  override func spec() {
    let urlReq = NSURLRequest(URL: NSURL(string: "http://google.com")!)
    it("inits properly") {
      var req : SEGHTTPRequest?
      var responseData: NSData?
      self.stub(http(.GET, uri: "http://google.com"), builder: json([:]))
      req = SEGHTTPRequest.startWithURLRequest(urlReq) {
          print(req?.responseJSON)
          responseData = req?.responseData
      }
      expect(req) != nil
      expect(responseData).toEventuallyNot(beNil())
      expect(responseData?.length) > 0
    }
    it("parses json") {
      self.stub(http(.GET, uri: "http://google.com"), builder: json(["hello": "world"]))
      let req = SEGHTTPRequest.startWithURLRequest(urlReq, completion: nil)
      expect(req.responseJSON).toEventuallyNot(beNil())
      expect(req.responseJSON?["hello"]) == "world"
    }
  }
}
