//
//  NetworkTest.swift
//  Analytics
//
//  Created by Tony Xiao on 6/30/16.
//  Copyright © 2016 Segment. All rights reserved.
//
import Quick
import Nimble

class NetworkTest: QuickSpec {
    override func spec() {
        let urlReq = NSURLRequest(URL: NSURL(string: "http://google.com")!)
        describe("request") {
            it("inits properly") {
                var req : SEGAnalyticsRequest?
                let exp = self.expectationWithDescription("Wait for me")
                req = SEGAnalyticsRequest.startWithURLRequest(urlReq) {
                    print(req?.responseJSON)
                    exp.fulfill()
                }
                expect(req) != nil
                self.waitForExpectationsWithTimeout(1, handler: nil)
            }
        }
    }
}
