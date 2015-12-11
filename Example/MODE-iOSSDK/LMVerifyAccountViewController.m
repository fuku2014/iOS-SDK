#import "LMButtonUtils.h"
#import "LMDataHolder.h"
#import "LMMessages.h"
#import "LMOverlayViewProtocol.h"
#import "LMVerifyAccountViewController.h"
#import "LMUtils.h"
#import "MODEApp.h"

@interface LMVerifyAccountViewController ()

@property(strong, nonatomic) IBOutlet UILabel *message;
@property(strong, nonatomic) IBOutlet UITextField *verificationCodeField;
@property(strong, nonatomic) NumericTextFieldDelegate *numericDelegate;
@property (strong, nonatomic) IBOutlet UIButton *resendButton;
@property (strong, nonatomic) IBOutlet UIView *verifiedButton;

@end

@implementation LMVerifyAccountViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.numericDelegate = setupNumericTextField(self.verificationCodeField,@"Verification Code", @"Authentication.png");
    self.navigationItem.titleView = setupTitle(@"Verify Account");
    
    LMDataHolder *data = [LMDataHolder sharedInstance];
    if (data.isEmailLogin) {
        NSString* msg = MESSAGE_VERIFY_EMAIL1;
        setupMessage(self.message,
                     [[msg stringByAppendingString:data.members.email] stringByAppendingString:MESSAGE_VERIFY_EMAIL2] , 15.0);
        self.verificationCodeField.hidden = TRUE;
        self.resendButton.hidden = TRUE;
    } else {
        self.verifiedButton.hidden = TRUE;
        setupMessage(self.message, MESSAGE_VERIFY_YOU, 15.0);
    }
}

- (IBAction)handleNext:(id)sender
{
    [self performSegueWithIdentifier:@"RegisteredSegue" sender:self];
}

void createMyHome(UIViewController<LMOverlayViewProtocol> *destVC)
{
    LMDataHolder *data = [LMDataHolder sharedInstance];
    
    // Here we just create default "My Home" and set "Los Angeles" timezone.
    // But you have to rewrite according to users' environment.
    [MODEAppAPI createHome:data.clientAuth name:@"My Home" timezone:@"America/Los_Angeles"
        completion:^(MODEHome *home, NSError *err) {
            [destVC removeOverlayViews];
            if (err != nil) {
                showAlert(err);
            } else {
                DLog(@"Created home: %@", home);
                data.members.homeId = home.homeId;
                [data saveData];
            }
        }];

}

- (void) authenticateCallback:(UIViewController<LMOverlayViewProtocol> *) destVC
clientAuth:(MODEClientAuthentication*)clientAuth err:(NSError*)err
{
    LMDataHolder *data = [LMDataHolder sharedInstance];
    if (err != nil) {
        // You need to rollback because auth failed.
        [destVC removeOverlayViews];
        
        [self.navigationController popToViewController:self animated:YES];
        showAlert(err);
    } else {
        DLog(@"Got auth token: %@", clientAuth);
        data.clientAuth = clientAuth;
        [data saveData];
        createMyHome(destVC);
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Need to show overlay until Auth token is taken.
    setupOverlayView(self.navigationController, @"Verifying...");
    UIViewController<LMOverlayViewProtocol> *destVC = [segue destinationViewController];
    
    LMDataHolder *data = [LMDataHolder sharedInstance];
    
    if (data.isEmailLogin) {
        [MODEAppAPI authenticateWithEmail:data.projectId email:data.members.email password:data.members.password appId:data.appId
            completion:^(MODEClientAuthentication *clientAuth, NSError *err) {
                [self authenticateCallback:destVC clientAuth:clientAuth err:err];
            }];
    } else {
        [MODEAppAPI authenticateWithCode:data.projectId phoneNumber:data.members.phoneNumber appId:data.appId code:self.verificationCodeField.text
              completion:^(MODEClientAuthentication *clientAuth, NSError *err) {
                  [self authenticateCallback:destVC clientAuth:clientAuth err:err];
              }];
    }
}


- (IBAction)handleResend:(id)sender
{
    LMDataHolder *data = [LMDataHolder sharedInstance];
    initiateAuth(data.projectId, data.members.phoneNumber);
}

@end
