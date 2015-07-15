#import "LMDataHolder.h"
#import "LMDeviceManager.h"
#import "ModeEventListener.h"
#import "LMUtils.h"
#import "MODEApp.h"

@interface LMDeviceManager ()

@property(strong, nonatomic)NSMutableArray* deviceEventDelegates;
@property(strong, nonatomic)MODEEventListener* listener;

@end

@implementation LMDeviceManager

+ (LMDeviceManager *)sharedInstance
{
    static LMDeviceManager *_sharedInstance = nil;
    static dispatch_once_t onceSecurePredicate;
    dispatch_once(&onceSecurePredicate,^
                  {
                      _sharedInstance = [[self alloc] init];
                  });
    
    return _sharedInstance;
}

- (id) init
{
    self = [super init];
    self.deviceEventDelegates = [[NSMutableArray alloc]init];
    return self;
}

- (void)addMODEDeviceDelegate:(id<MODEDeviceEventDelegate>) delegate
{
    [self.deviceEventDelegates addObject:delegate];
}

- (void)removeMODEDeviceDelegate:(id<MODEDeviceEventDelegate>)delegate
{
    [self.deviceEventDelegates removeObject:delegate];
}

- (void) callDeviceEventDelegates:(MODEDeviceEvent*) event err:(NSError*) err
{
    for (id<MODEDeviceEventDelegate> delegate in self.deviceEventDelegates) {
        if (err) {
            NSLog(@"Receive event error %@", err);
        }
        
        if (event && [event.eventType isEqualToString:@"light"]) {
            if([event.eventData[@"status"] isEqualToString:@"on"] ) {
                [delegate receivedEvent:event.originDeviceId status:TRUE];
                NSLog(@"Received status deeviceId: %d status TRUE", event.originDeviceId);
            } else if ([event.eventData[@"status"] isEqualToString:@"off"] ) {
                [delegate receivedEvent:event.originDeviceId status:FALSE];
                NSLog(@"Received status deeviceId: %d status FALSE", event.originDeviceId);
            }
        }
    }
}

- (void) startListenToEvents:(MODEClientAuthentication*)clientAuth
{
    self.listener = [[MODEEventListener alloc] initWithClientAuthentication:clientAuth];
    
    [self.listener startListenToEvents:^(MODEDeviceEvent *event, NSError *err) {
        [self callDeviceEventDelegates:event err:err];
    }];
}

-(void)stopListenToEvents
{
    [self.listener stopListenToEvents];
}

- (void)queryDeviceStatus:(NSArray*)devices
{
    // Broadcast query to all devices.
    LMDataHolder* data = [LMDataHolder sharedInstance];
    for (MODEDevice* device in devices) {
        [MODEAppAPI sendCommandToDevice:data.clientAuth deviceId:device.deviceId action:@"light" parameters:@{@"qeury":@"status"}
             completion:^(MODEDevice *device, NSError *err) {
                 if (err != nil) {
                     showAlert(err);
                 } else {
                     NSLog(@"Query event triggered: deviceId: %d", device.deviceId);
                 }
             }];
    }
}

- (void) triggerSwitch:(int)deviceId status:(BOOL)status
{
    LMDataHolder* data = [LMDataHolder sharedInstance];
    NSNumber* value = [NSNumber numberWithInt:status];
    [MODEAppAPI sendCommandToDevice:data.clientAuth deviceId:deviceId action:@"light" parameters:@{@"switch":value}
        completion:^(MODEDevice *device, NSError *err) {
            if (err != nil) {
                showAlert(err);
            } else {
                NSLog(@"Switch event triggered: deviceId: %d, light %@", deviceId, value);
            }
        }];
}

@end
