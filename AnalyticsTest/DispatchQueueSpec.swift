//
//  DispatchQueueSpec.swift
//  Analytics
//
//  Created by Tony Xiao on 6/30/16.
//  Copyright © 2016 Segment. All rights reserved.
//

import Quick
import Nimble

class DispatchQueueSpec : QuickSpec {
  override func spec() {
    var queue : SEGDispatchQueue!
    beforeEach { 
      queue = SEGDispatchQueue(label: "com.segment.test")
    }
    
    it("reports isCurrentQueue correctly") {
      expect(queue.isCurrentQueue()) == false
      
      var isCurrentSync = false
      queue.sync {
        isCurrentSync = queue.isCurrentQueue()
      }
      expect(isCurrentSync) == true
      
      var isCurrentAsync = false
      queue.async {
        isCurrentAsync = queue.isCurrentQueue()
      }
      expect(isCurrentAsync) == false
      expect(isCurrentAsync).toEventually(beTrue())
    }
    it("should never deadlock") {
      var done = false
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
        expect(queue.isCurrentQueue()) == false
        queue.sync {
          expect(queue.isCurrentQueue()) == true
          queue.async {
            expect(queue.isCurrentQueue()) == true
            queue.sync {
              expect(queue.isCurrentQueue()) == true
              dispatch_async(dispatch_get_main_queue()) {
                expect(queue.isCurrentQueue()) == false
                done = true
              }
            }
          }
        }
      }
      expect(done).toEventually(beTrue())
    }
    it("should run sync synchronously") {
      var blockDidRun = false
      queue.sync { blockDidRun = true }
      expect(blockDidRun) == true
    }
    xit("should run async asynchronously") {
      expect(queue.isCurrentQueue()) == false
      var didBlockRun = false
      queue.async {
        didBlockRun = true
      }
      expect(didBlockRun) == false
      expect(didBlockRun).toEventually(beTrue())
    }
    it("should always run synchronously if already on queue") {
      queue.sync {
        expect(queue.isCurrentQueue()) == true
        var didAsyncBlockRun = false
        queue.async { didAsyncBlockRun = true }
        expect(didAsyncBlockRun) == true
      }
    }
  }
}
