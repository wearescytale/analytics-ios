//
//  DispatchQueueTest.swift
//  Analytics
//
//  Created by Tony Xiao on 6/30/16.
//  Copyright © 2016 Segment. All rights reserved.
//

import Foundation
import XCTest
import Nimble

class DispatchQueueTest : XCTestCase {
    var queue : SEGDispatchQueue!

    override func setUp() {
        queue = SEGDispatchQueue(label: "com.segment.test")
    }
    
    override func tearDown() {
        queue = nil
    }
    
    func testIsCurrentQueue() {
        expect(self.queue.isCurrentQueue()) == false
        queue.sync {
            expect(self.queue.isCurrentQueue()) == true
        }
    }
    
    func testShouldNotDeadlock() {
        let expectation = expectationWithDescription("Dispatch complete")
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) { 
            expect(self.queue.isCurrentQueue()) == false
            self.queue.sync {
                expect(self.queue.isCurrentQueue()) == true
                self.queue.async {
                    expect(self.queue.isCurrentQueue()) == true
                    self.queue.sync {
                        expect(self.queue.isCurrentQueue()) == true
                        dispatch_async(dispatch_get_main_queue()) {
                            expect(self.queue.isCurrentQueue()) == false
                            expectation.fulfill()
                        }
                    }
                }
            }
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }
}
