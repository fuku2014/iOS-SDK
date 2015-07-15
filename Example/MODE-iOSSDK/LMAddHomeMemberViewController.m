#import "LMAddHomeMemberViewController.h"
#import "LMDataHolder.h"
#import "LMHomeDetailableViewController.h"
#import "LMMessages.h"
#import "MODEApp.h"
#import "LMUtils.h"
#import "LMButtonUtils.h"

@interface LMAddHomeMemberViewController ()

@property(strong, nonatomic) IBOutlet UILabel* message;
@property(strong, nonatomic) IBOutlet UITextField* phoneNumberField;
@property(strong, nonatomic) PhoneNumberFieldDelegate* phoneNumberDelegate;

@end

@implementation LMAddHomeMemberViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    
    self.phoneNumberDelegate = setupPhoneNumberField(self.phoneNumberField);
    setupMessage(self.message, MESSAGE_INVITE);
    
    setupRightBarButtonItem(self.navigationItem, @"Add", self, @selector(handleAdd));
    
    self.navigationItem.titleView = setupTitle(@"Add Member");
}

-(void)handleAdd
{
    LMDataHolder* data = [LMDataHolder sharedInstance];
    
    [MODEAppAPI addHomeMember:data.clientAuth homeId:self.sourceVC.targetHome.homeId phoneNumber:self.phoneNumberField.text
        completion:^(MODEHomeMember *member, NSError *err) {
            if (err != nil) {
                showAlert(err);
            }
            NSLog(@"added %@", member);
            [self.sourceVC fetchMembers];
        }];
    
    [self.navigationController popToViewController:self.sourceVC animated:YES];
}


@end
