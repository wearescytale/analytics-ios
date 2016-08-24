//
//  StorageTest.swift
//  Analytics
//
//  Created by Tony Xiao on 8/24/16.
//  Copyright © 2016 Segment. All rights reserved.
//

import Quick
import Nimble

class StorageTest : QuickSpec {
  override func spec() {
    var storage : SEGFileStorage!
    beforeEach {
      let url = SEGFileStorage.applicationSupportDirectoryURL()
      expect(url).toNot(beNil())
      expect(url?.lastPathComponent) == "Application Support"
      storage = SEGFileStorage(folder: url!, crypto: nil)
    }
    
    it("saves file to disk and reads back from it") {
//      let input = [
//        "key": "value",
//        "peter": "reinhardt",
//      ]
      let key = "input.plist"
      let url = storage.urlForKey(key)
      expect(url.checkResourceIsReachableAndReturnError(nil)) == false
      
      let dataIn = "segment".dataUsingEncoding(NSUTF8StringEncoding)!
      storage.setData(dataIn, forKey: key)
      let dataOut = storage.dataForKey(key)
      expect(dataOut).toNot(beNil())
      
      let strOut = String(data: dataOut!, encoding: NSUTF8StringEncoding)
      expect(strOut) == "segment"
    }
    
    afterEach {
      storage.removeKey("input.plist")
    }
  }
}
