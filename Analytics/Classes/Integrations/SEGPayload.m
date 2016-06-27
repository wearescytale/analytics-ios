#import "SEGPayload.h"


@implementation SEGPayload

- (instancetype)initWithContext:(NSDictionary *)context integrations:(NSDictionary *)integrations {
    if (self = [super init]) {
        _context = [context copy];
        _integrations = [integrations copy];
    }
    return self;
}

@end

@implementation SEGIdentifyPayload

- (instancetype)initWithUserId:(NSString *)userId
                   anonymousId:(NSString *)anonymousId
                        traits:(NSDictionary *)traits
                       context:(NSDictionary *)context
                  integrations:(NSDictionary *)integrations {
    if (self = [super initWithContext:context integrations:integrations]) {
        _userId = [userId copy];
        _anonymousId = [anonymousId copy];
        _traits = [traits copy];
    }
    return self;
}

@end

@implementation SEGAliasPayload

- (instancetype)initWithNewId:(NSString *)newId
                      context:(NSDictionary *)context
                 integrations:(NSDictionary *)integrations {
    if (self = [super initWithContext:context integrations:integrations]) {
        _theNewId = [newId copy];
    }
    return self;
}

@end

@implementation SEGTrackPayload


- (instancetype)initWithEvent:(NSString *)event
                   properties:(NSDictionary *)properties
                      context:(NSDictionary *)context
                 integrations:(NSDictionary *)integrations {
    if (self = [super initWithContext:context integrations:integrations]) {
        _event = [event copy];
        _properties = [properties copy];
    }
    return self;
}

@end

@implementation SEGScreenPayload

- (instancetype)initWithName:(NSString *)name
                  properties:(NSDictionary *)properties
                     context:(NSDictionary *)context
                integrations:(NSDictionary *)integrations {
    if (self = [super initWithContext:context integrations:integrations]) {
        _name = [name copy];
        _properties = [properties copy];
    }
    return self;
}

@end

@implementation SEGGroupPayload

- (instancetype)initWithGroupId:(NSString *)groupId
                         traits:(NSDictionary *)traits
                        context:(NSDictionary *)context
                   integrations:(NSDictionary *)integrations {
    if (self = [super initWithContext:context integrations:integrations]) {
        _groupId = [groupId copy];
        _traits = [traits copy];
    }
    return self;
}

@end