//
//  DispatchQueueTest.swift
//  Analytics
//
//  Created by Tony Xiao on 6/30/16.
//  Copyright © 2016 Segment. All rights reserved.
//

import Foundation
import XCTest

class DispatchQueueTest : XCTestCase {
    var queue : SEGDispatchQueue!

    override func setUp() {
        queue = SEGDispatchQueue(label: "com.segment.test")
    }
    
    override func tearDown() {
        queue = nil
    }
    
    func testIsCurrentQueue() {
        XCTAssertFalse(queue.isCurrentQueue(), "Should not be on dispatch queue")
        queue.sync { 
            XCTAssertTrue(self.queue.isCurrentQueue(), "Should be on dispatch queue")
        }
    }
    
    func testShouldNotDeadlock() {
        let expectation = expectationWithDescription("Dispatch complete")
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) { 
            XCTAssertFalse(self.queue.isCurrentQueue(), "Should not be on dispatch queue")
            self.queue.sync {
                XCTAssertTrue(self.queue.isCurrentQueue())
                self.queue.async {
                    XCTAssertTrue(self.queue.isCurrentQueue())
                    self.queue.sync {
                        XCTAssertTrue(self.queue.isCurrentQueue())
                        dispatch_async(dispatch_get_main_queue()) {
                            XCTAssertFalse(self.queue.isCurrentQueue())
                            expectation.fulfill()
                        }
                    }
                }
            }
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }
}
