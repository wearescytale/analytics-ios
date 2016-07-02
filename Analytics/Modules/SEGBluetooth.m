#import <CoreBluetooth/CoreBluetooth.h>
#import "SEGBluetooth.h"

static const NSString *SEGCentralManagerClass = @"CBCentralManager";

@interface SEGBluetooth () <CBCentralManagerDelegate>

@property (nonatomic, strong) CBCentralManager *manager;
@property (nonatomic, strong) dispatch_queue_t queue;

@end


@implementation SEGBluetooth

- (id)init {
    if (self = [super init]) {
        _queue = dispatch_queue_create("io.segment.bluetooth.queue", NULL);
        _manager = [[CBCentralManager alloc] initWithDelegate:self
                                                        queue:_queue
                                                      options:@{CBCentralManagerOptionShowPowerAlertKey : @NO}];
    }
    return self;
}

- (BOOL)hasKnownState {
    return self.manager && (self.manager.state != CBCentralManagerStateUnknown);
}

- (BOOL)isEnabled {
    return self.manager.state == CBCentralManagerStatePoweredOn;
}

- (void)centralManagerDidUpdateState:(id)central {}

@end