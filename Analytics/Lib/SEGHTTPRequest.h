#import <Foundation/Foundation.h>

typedef void (^SEGHTTPRequestCompletionBlock)(void);

@interface SEGHTTPRequest : NSObject

@property (nonatomic, copy) SEGHTTPRequestCompletionBlock completion;
@property (nonatomic, readonly) NSURLRequest *urlRequest;
@property (nonatomic, readonly) NSHTTPURLResponse *response;
@property (nonatomic, readonly) NSData *responseData;
@property (nonatomic, readonly) id responseJSON;
@property (nonatomic, readonly) NSError *error;

+ (instancetype)startWithURLRequest:(NSURLRequest *)urlRequest
                         completion:(SEGHTTPRequestCompletionBlock)completion;

+ (NSString *)basicAuthHeader:(NSString *)username password:(NSString *)password;

@end