#import "LMAddDevicesViewController.h"
#import "LMButtonUtils.h"
#import "LMDataHolder.h"
#import "LMMessages.h"
#import "LMOverlayViewProtocol.h"
#import "LMUtils.h"
#import "ModeApp.h"

UIView* setupCommonAddDeviceWidgets(UITextField* verificationCodeField, UITextField* devicenameField, UILabel*message)
{
    setupStandardTextField(verificationCodeField, @"Claim Code", @"ClaimCode.png");
    setupStandardTextField(devicenameField, @"Nickname (e.g. Office Lamp)", @"Nickname.png");
    [verificationCodeField setReturnKeyType:UIReturnKeyDone];
    setupMessage(message, MESSAGE_ADD_DEVICES, 15.0);
    return setupTitle(@"Add device");
}

@interface LMAddDevicesViewController ()

@property(strong, nonatomic) IBOutlet UILabel* message;
@property(strong, nonatomic) IBOutlet UITextField* verificationCodeField;
@property(strong, nonatomic) IBOutlet UITextField* deviceNameField;

@end

@implementation LMAddDevicesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.titleView = setupCommonAddDeviceWidgets(self.verificationCodeField, self.deviceNameField, self.message);
    self.navigationItem.hidesBackButton = YES;
    
    setupMessage(self.message, MESSAGE_ADD_DEVICES, 15.0);
    setupKeyboardDismisser(self, @selector(dismissKeyboard));

}

- (void)dismissKeyboard
{
    [self.verificationCodeField resignFirstResponder];
    [self.deviceNameField resignFirstResponder];
}

- (void)removeOverlayViews
{
    removeOverlayViewSub(self.navigationController, nil);
}

- (IBAction)handleSkip:(id)sender {
    [self performSegueWithIdentifier:@"@console" sender:self];
}

-(void)updateDeviceName:(MODEDevice*)device
{
    NSString* name = self.deviceNameField.text;
    LMDataHolder* data = [LMDataHolder sharedInstance];
    [MODEAppAPI updateDevice:data.clientAuth deviceId:device.deviceId name:self.deviceNameField.text
        completion:^(MODEDevice *device, NSError *err) {
            if (err != nil) {
                showAlert(err);
            } else {
                NSLog(@"Updated device name: %@", name);
            }
        }];
}

- (IBAction)handleNext:(id)sender
{
    [self performSegueWithIdentifier:@"@console" sender:self];

    __weak __typeof__(self) weakSelf = self;
    LMDataHolder* data = [LMDataHolder sharedInstance];
    [MODEAppAPI claimDevice:data.clientAuth claimCode:self.verificationCodeField.text homeId:data.members.homeId
        completion:^(MODEDevice *device, NSError *err) {
            if (err != nil) {
                // You need to rollback because auth failed.
                [weakSelf.navigationController popToViewController:weakSelf animated:YES];
                showAlert(err);
            } else {
                NSLog(@"Attached device: %@ to homeId %d", device, data.members.homeId);
                [weakSelf updateDeviceName:device];
            }
        }];
}

@end
