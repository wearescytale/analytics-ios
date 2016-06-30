# Analytics

[![Version](https://img.shields.io/cocoapods/v/Analytics.svg?style=flat)](https://cocoapods.org//pods/Analytics)
[![License](https://img.shields.io/cocoapods/l/Analytics.svg?style=flat)](http://cocoapods.org/pods/Analytics)

analytics-ios is an iOS client for Segment.

Special thanks to [Tony Xiao](https://github.com/tonyxiao), [Lee Hasiuk](https://github.com/lhasiuk) and [Cristian Bica](https://github.com/cristianbica) for their contributions to the library!

## Installation

Analytics is available through [CocoaPods](http://cocoapods.org) and [Carthage](https://github.com/Carthage/Carthage).

### CocoaPods

```ruby
pod "Analytics"
```

### Carthage

```
github "segmentio/analytics-ios"
```
* Make sure `-ObjC` is added to if not already `OTHER_LDFLAGS` build setting

### Manual Installation
* Clone this git repo
* add `Analytics.xcodeproj` as a subproject to your project

If you only need to support iOS 8+, 
* Add `Analytics.framework` to *Target Dependencies* and *Embed Framework* build phase

If you need to support iOS 7+
* Add `libAnalytics.a` to *Target Dependencies* and *Link Binary with Libraries* build phase
* Add `${PATH_TO_YOUR_DIRECTORY}/Analytics/**` to `HEADER_SEARCH_PATH` build setting

Finally
* Make sure `-ObjC` is added to if not already `OTHER_LDFLAGS` build setting

As you can see, using either cocoapods / Carthage are quite a bit easier :)

## Quickstart

Refer to the Quickstart documentation at [https://segment.com/docs/libraries/ios/quickstart](https://segment.com/docs/libraries/ios/quickstart/).

## Documentation

More detailed documentation is available at [https://segment.com/docs/libraries/ios](https://segment.com/docs/libraries/ios/).
