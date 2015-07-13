#import "RegisteredViewController.h"
#import "ModeApp.h"
#import "DataHolder.h"
#import "Utils.h"
#import "Messages.h"
#import "OverlayViewProtocol.h"

@interface RegisteredViewController ()

@property(strong, nonatomic) IBOutlet UILabel* message;

@end

@implementation RegisteredViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.hidesBackButton = YES;
    setupMessage(self.message, MESSAGE_REGISTERED);
    
}

-(void) removeOverlayViews{
    removeOverlayViewSub(self.navigationController, nil);
}

- (IBAction)handleNext:(id)sender
{
    [self performSegueWithIdentifier:@"AddDevicesSegue" sender:self];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"AddDevicesSegue"]) {
//    
//        DataHolder* data = [DataHolder sharedInstance];
//        
//        //setupOverlayView(self.navigationController, @"Setting up home...");
//        
//        UIViewController<OverlayViewProtocol> *destVC = [segue destinationViewController];
//        
//        // Here we just create default "My Home" and set "Los Angeles" timezone.
//        // But you have to rewrite according to users' environment.
//        [MODEAppAPI createHome:data.clientAuth name:@"My Home" timezone:@"America/Los_Angeles" completion:^(MODEHome *home, NSError *err) {
//            [destVC removeOverlayViews];
//            if (err == nil) {
//                data.members.homeId = home.homeId;
//                
//                [data saveData];
//            } else {
//                // You need to rollback because auth failed.
//                [self.navigationController popToViewController:self animated:YES];
//                
//                showAlert(err);
//            }
//        }];
    }

}
@end
