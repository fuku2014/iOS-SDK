#import "ButtonUtils.h"
#import "DataHolder.h"
#import "Messages.h"
#import "MODEApp.h"
#import "SignUpViewController.h"
#import "Utils.h"

@interface SignUpViewController ()

@property(strong, nonatomic) IBOutlet UILabel* message;
@property(strong, nonatomic) IBOutlet UILabel* note;


@property(strong, nonatomic) IBOutlet UITextField* nameField;
@property(strong, nonatomic) IBOutlet UITextField* phoneNumberField;
@property(strong, nonatomic) PhoneNumberFieldDelegate* phoneNumberDelegate;

@end

@implementation SignUpViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    setupMessage(self.message, MESSAGE_WELCOME);
    setupMessage(self.note, MESSAGE_NOTE);
    
    setupStandardTextField(self.nameField, @"Name", @"Name.png");
    
    self.navigationItem.titleView = setupTitle(@"Sign Up");

     self.phoneNumberDelegate = setupPhoneNumberField(self.phoneNumberField);
}

- (IBAction)handleNext:(id)sender
{
    DataHolder* data = [DataHolder sharedInstance];

    data.members.userName = self.nameField.text;
    data.members.phoneNumber = self.phoneNumberField.text;
    [self performSegueWithIdentifier:@"VerifyAccountSegue" sender:self];

    [MODEAppAPI createUser:data.projectId phoneNumber:self.phoneNumberField.text name:self.nameField.text
                completion:^(MODEUser *user, NSError *err) {
                    if (err != nil) {
                        showAlert(err);
                    }
                }];
}

@end
