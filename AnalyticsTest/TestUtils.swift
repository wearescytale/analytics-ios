//
//  TestUtils.swift
//  Analytics
//
//  Created by Tony Xiao on 7/1/16.
//  Copyright © 2016 Segment. All rights reserved.
//

import Foundation
import Nocilla

extension NSDictionary : LSHTTPBody {
  public func data() -> NSData! {
    return try? NSJSONSerialization.dataWithJSONObject(self, options: [])
  }
}
