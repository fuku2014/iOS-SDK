#import "Mantle.h"
#import "MODEData.h"

@interface LMDataHolderMembers : MTLModel<MTLJSONSerializing>

@property (strong, nonatomic) NSString *phoneNumber;
@property (assign, nonatomic) int homeId;

@end


/**
  *This is a very simple persistent class.
  *In your real app, you would need to use Core Data to cache locally.
 */
@interface LMDataHolder : NSObject

+ (LMDataHolder *)sharedInstance;

@property (assign, nonatomic) int projectId;
@property (strong, nonatomic) NSString *appId;

@property (strong, nonatomic) MODEClientAuthentication *clientAuth;
@property (strong, nonatomic) LMDataHolderMembers *members;

- (void)saveData;
- (void)loadData;

@end