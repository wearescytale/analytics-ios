#import <Foundation/Foundation.h>


@interface SEGPayload : NSObject

@property (nonatomic, readonly) NSDictionary *context;
@property (nonatomic, readonly) NSDictionary *integrations;

- (instancetype)initWithContext:(NSDictionary *)context integrations:(NSDictionary *)integrations;

@end

@interface SEGIdentifyPayload : SEGPayload

@property (nonatomic, readonly) NSString *userId;

@property (nonatomic, readonly) NSString *anonymousId;

@property (nonatomic, readonly) NSDictionary *traits;

- (instancetype)initWithUserId:(NSString *)userId
                   anonymousId:(NSString *)anonymousId
                        traits:(NSDictionary *)traits
                       context:(NSDictionary *)context
                  integrations:(NSDictionary *)integrations;

@end

@interface SEGAliasPayload : SEGPayload

@property (nonatomic, readonly) NSString *theNewId;

- (instancetype)initWithNewId:(NSString *)newId
                      context:(NSDictionary *)context
                 integrations:(NSDictionary *)integrations;

@end

@interface SEGTrackPayload : SEGPayload

@property (nonatomic, readonly) NSString *event;

@property (nonatomic, readonly) NSDictionary *properties;

- (instancetype)initWithEvent:(NSString *)event
                   properties:(NSDictionary *)properties
                      context:(NSDictionary *)context
                 integrations:(NSDictionary *)integrations;

@end

@interface SEGScreenPayload : SEGPayload

@property (nonatomic, readonly) NSString *name;

@property (nonatomic, readonly) NSString *category;

@property (nonatomic, readonly) NSDictionary *properties;

- (instancetype)initWithName:(NSString *)name
                  properties:(NSDictionary *)properties
                     context:(NSDictionary *)context
                integrations:(NSDictionary *)integrations;

@end

@interface SEGGroupPayload : SEGPayload

@property (nonatomic, readonly) NSString *groupId;

@property (nonatomic, readonly) NSDictionary *traits;

- (instancetype)initWithGroupId:(NSString *)groupId
                         traits:(NSDictionary *)traits
                        context:(NSDictionary *)context
                   integrations:(NSDictionary *)integrations;

@end