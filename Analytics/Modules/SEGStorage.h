//
//  SEGStorage.h
//  Analytics
//
//  Copyright © 2016 Segment. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SEGCrypto.h"

@protocol SEGStorage <NSObject>

@property (nonatomic, strong, nullable) id<SEGCrypto> crypto;

- (void)setData:(NSData * _Nonnull)data forKey:(NSString * _Nonnull)key;
- (NSData * _Nullable)dataForKey:(NSString * _Nonnull)key;


- (void)removeKey:(NSString *_Nonnull)key;

@end
