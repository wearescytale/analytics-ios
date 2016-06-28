//
//  AnalyticsTest.m
//  AnalyticsTest
//
//  Created by Tony Xiao on 6/27/16.
//  Copyright © 2016 Segment. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SEGIntegrationsManager.h"

@interface SEGIntegrationsManager (Private)

@property (nonatomic) volatile BOOL initialized;
- (void)updateIntegrationsWithSettings:(NSDictionary *)projectSettings callback:(void (^)(void))block;

@end

@interface AnalyticsTest : XCTestCase

@property (nonatomic, strong) SEGIntegrationsManager *integrations;

@end

@implementation AnalyticsTest

- (void)setUp {
    [super setUp];
    self.integrations = [[SEGIntegrationsManager alloc] initWithAnalytics:nil];
}

- (void)tearDown {
    self.integrations = nil;
    [super tearDown];
}

- (void)testIntegrationsInitialization {
    XCTAssertFalse(self.integrations.initialized);
    XCTestExpectation *expectation = [self expectationWithDescription:@"Finished updating setting"];
    [self.integrations updateIntegrationsWithSettings:nil callback:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    XCTAssertTrue(self.integrations.initialized);
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        for (int i=0; i<1000; i++) {
            [self.integrations track:@"Test Event" properties:@{@"Count": @(i)} options:nil];
        }
    }];
}

@end
