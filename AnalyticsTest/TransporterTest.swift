//
//  TransporterTest.swift
//  Analytics
//
//  Created by Tony Xiao on 6/30/16.
//  Copyright © 2016 Segment. All rights reserved.
//

import Foundation
import XCTest

class TransporterTest : XCTestCase {
    var transporter : SEGNetworkTransporter!

    override func setUp() {
        let config = SEGAnalyticsConfiguration(writeKey: "XMTBm9QGhfkLKaevI50GYdD4mOcVDD83")
        transporter = SEGNetworkTransporter(configuration: config)
    }
    
    override func tearDown() {
        transporter = nil
    }
    
    func testApiURLValid() {
        XCTAssertEqual(transporter.apiURL.absoluteString, "https://api.segment.io/v1/import")
    }
}
