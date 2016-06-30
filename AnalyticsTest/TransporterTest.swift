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
    
    func testAddition() {
        let analytics = SEGAnalytics(writeKey: "")
        XCTAssertNotNil(analytics)
    }
}