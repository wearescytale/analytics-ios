//
//  SEGFileStorage.m
//  Analytics
//
//  Copyright © 2016 Segment. All rights reserved.
//

#import "SEGUtils.h"
#import "SEGFileStorage.h"

@interface SEGFileStorage ()

@property (nonatomic, strong, nonnull) NSURL *folderURL;

@end

@implementation SEGFileStorage

- (instancetype)initWithFolder:(NSURL *)folderURL crypto:(id<SEGCrypto>)crypto {
    if (self = [super init]) {
        _folderURL = folderURL;
        _crypto = crypto;
        [self createDirectoryAtURLIfNeeded:folderURL];
        return self;
    }
    return nil;
}

- (void)setData:(NSData *)data forKey:(NSString *)key {
    NSURL *url = [self urlForKey:key];
    if (self.crypto) {
        NSData *encryptedData = [self.crypto encrypt:data];
        [encryptedData writeToURL:url atomically:YES];
    } else {
        [data writeToURL:url atomically:YES];
    }
}

- (NSData *)dataForKey:(NSString *)key {
    NSURL *url = [self urlForKey:key];
    NSData *data = [NSData dataWithContentsOfURL:url];
    if (!data) {
        SEGLog(@"WARNING: No data file for key %@", key);
        return nil;
    }
    if (self.crypto) {
        return [self.crypto decrypt:data];
    }
    return data;
}

- (void)removeKey:(NSString *)key {
    NSURL *url = [self urlForKey:key];
    NSError *error = nil;
    if (![[NSFileManager defaultManager] removeItemAtURL:url error:&error]) {
        SEGLog(@"Unable to remove key %@ - error removing file at path %@", key, url);
    }
}

+ (NSURL *)applicationSupportDirectoryURL {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *supportPath = [paths firstObject];
    return [NSURL fileURLWithPath:supportPath];
    
}

- (NSURL *)urlForKey:(NSString *)key {
    return [self.folderURL URLByAppendingPathComponent:key];
}

#pragma mark - Helpers


- (void)createDirectoryAtURLIfNeeded:(NSURL *)url {
    if (![[NSFileManager defaultManager] fileExistsAtPath:url.path
                                              isDirectory:NULL]) {
        NSError *error = nil;
        if (![[NSFileManager defaultManager] createDirectoryAtPath:url.path
                                       withIntermediateDirectories:YES
                                                        attributes:nil
                                                             error:&error]) {
            SEGLog(@"error: %@", error.localizedDescription);
        }
    }
}

@end
