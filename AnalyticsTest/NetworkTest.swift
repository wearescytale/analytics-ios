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
                var responseData: NSData?
                req = SEGAnalyticsRequest.startWithURLRequest(urlReq) {
                    print(req?.responseJSON)
                    responseData = req?.responseData
                }
                expect(req) != nil
                expect(responseData).toEventuallyNot(beNil())
                expect(responseData?.length) > 0
            }
            
        }
    }
}
