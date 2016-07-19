#define AssertMainThread() NSCParameterAssert([NSThread isMainThread])

#import "SEGHTTPRequest.h"


@interface SEGHTTPRequest () <NSURLConnectionDataDelegate>

@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSURLRequest *urlRequest;
@property (nonatomic, strong) NSHTTPURLResponse *response;
@property (nonatomic, strong) NSMutableData *responseData;
@property (nonatomic, strong) id responseJSON;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, strong) NSIndexSet *acceptableStatusCodes;

@end


@implementation SEGHTTPRequest

- (id)initWithURLRequest:(NSURLRequest *)urlRequest {
    if (self = [super init]) {
        _urlRequest = urlRequest;
    }
    return self;
}

- (void)start {
    self.connection = [[NSURLConnection alloc] initWithRequest:self.urlRequest
                                                      delegate:self
                                              startImmediately:NO];
    [self.connection setDelegateQueue:[[self class] networkQueue]];
    [self.connection start];
}

- (void)finish {
    if (self.completion)
        self.completion();
}

#pragma mark NSURLConnection Delegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    self.response = (NSHTTPURLResponse *)response;
    self.responseData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [(NSMutableData *)self.responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSInteger statusCode = self.response.statusCode;
    if ([self.acceptableStatusCodes containsIndex:statusCode]) {
        NSError *error = nil;
        if (self.responseData.length > 0) {
            self.responseJSON = [NSJSONSerialization JSONObjectWithData:self.responseData
                                                                options:0
                                                                  error:&error];
            self.error = error;
        }
    } else {
        self.error = [NSError errorWithDomain:@"HTTP"
                                         code:statusCode
                                     userInfo:@{ NSLocalizedDescriptionKey :
                                                     [NSString stringWithFormat:@"HTTP Error %ld", (long)statusCode] }];
    }
    [self finish];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    self.error = error;
    [self finish];
}

#pragma mark - Class Methods

+ (instancetype)startWithURLRequest:(NSURLRequest *)urlRequest
                         completion:(SEGHTTPRequestCompletionBlock)completion {
    SEGHTTPRequest *request = [[self alloc] initWithURLRequest:urlRequest];
    request.completion = completion;
    [request start];
    return request;
}

+ (NSString *)basicAuthHeader:(NSString *)username password:(NSString *)password {
    // Courtesy of http://stackoverflow.com/questions/1973325/nsurlconnection-and-basic-http-authentication-in-ios
    NSString *authenticationString = [NSString stringWithFormat:@"%@:%@", username, password];
    NSData *authenticationData = [authenticationString dataUsingEncoding:NSASCIIStringEncoding];
    NSString *authenticationValue = [authenticationData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    return [NSString stringWithFormat:@"Basic %@", authenticationValue];
}

+ (NSOperationQueue *)networkQueue {
    static dispatch_once_t onceToken;
    static NSOperationQueue *networkQueue;
    dispatch_once(&onceToken, ^{
        networkQueue = [[NSOperationQueue alloc] init];
    });
    return networkQueue;
}

#pragma mark - Private

- (NSIndexSet *)acceptableStatusCodes {
    if (!_acceptableStatusCodes) {
        _acceptableStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 100)];
    }
    return _acceptableStatusCodes;
}

@end