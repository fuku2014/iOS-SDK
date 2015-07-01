#import <Foundation/Foundation.h>
#import "ModeApp.h"
#import "ModeData.h"


// As default, all completion block will be executed in main thread loop to easy to use in UI.
// If you don't want, disable this flag.
#define EXECUTE_BLOCK_IN_MAIN_THERAD 1
#define HTTP_REQUEST_TIMEOUT 10


static NSString *const ModeURL = @"https://api.tinkermode.com";

//static NSString *const ModeURL = @"http://akagi.local:7002";

@implementation MODEAppAPI

// Utitiliy functions

static NSString* getModeURL(NSString* path) {
    return [ModeURL stringByAppendingString:path];
}

typedef void (^completionBlock)(id, NSError*);
typedef void (^completionBlockForArray)(NSArray*, NSError*);
typedef id (^targetBlock)(id resposeObject, Class targetClass, NSError**);

static NSString* encodeDictionary(NSDictionary* dictionary) {
    NSMutableArray *parts = [[NSMutableArray alloc] init];
    for (NSString *key in dictionary) {
        NSString *encodedValue = [[dictionary objectForKey:key] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *encodedKey = [key stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *part = [NSString stringWithFormat: @"%@=%@", encodedKey, encodedValue];
        [parts addObject:part];
    }
    return [parts componentsJoinedByString:@"&"];

}

static NSURLSessionDataTask* callHTTPRequest2(MODEClientAuthentication* clientAuthentication, bool JSONRequest, NSString* selectorString, NSString* path, NSDictionary* parameters, Class targetClasss, completionBlock completion) {

    return callHTTPRequestSub2(clientAuthentication, JSONRequest, selectorString, path, parameters, targetClasss, completion,
                       ^id(id responseObject, Class targetClass, NSError** err){
                           return [MTLJSONAdapter modelOfClass:targetClasss fromJSONDictionary:(NSDictionary*)responseObject error:err];
                       });
}

static NSURLSessionDataTask* callHTTPRequestForArray2(MODEClientAuthentication* clientAuthentication, bool JSONRequest, NSString* selectorString, NSString* path, NSDictionary* parameters, Class targetClasss, completionBlockForArray completion) {
    
    return callHTTPRequestSub2(clientAuthentication, JSONRequest, selectorString, path, parameters, targetClasss, completion,
                       ^id(id responseObject, Class targetClass, NSError** err){
                           NSMutableArray* array = [[NSMutableArray alloc] init];
                           *err = nil;
                           for (id responseItem in (NSArray*)responseObject) {
                               id obj = [MTLJSONAdapter modelOfClass:targetClasss fromJSONDictionary:responseItem error:err];
                               if (*err) {
                                   return nil;
                               }
                               [array addObject:obj];
                           }
                           return array;
                       });
}

static NSURLSessionDataTask* callHTTPRequestSub2(MODEClientAuthentication* clientAuthentication, bool JSONRequest, NSString* method, NSString* path, NSDictionary* parameters, Class targetClasss, completionBlock completion, targetBlock target) {
    
    
#if EXECUTE_BLOCK_IN_MAIN_THERAD
    completion = ^void(id obj, NSError* err) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(obj, err);
        });
    };
#endif
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    if (clientAuthentication != nil) {
        [config setHTTPAdditionalHeaders:@{@"Authorization": [@"ModeCloud " stringByAppendingString:clientAuthentication.token]}];
    }
    
    NSURLSession* session = [NSURLSession sessionWithConfiguration:config];
    
    if ([method isEqualToString:@"GET"] && parameters != nil) {
        NSString *queryStr = encodeDictionary(parameters);
        queryStr = [@"?" stringByAppendingString:queryStr];
        path = [path stringByAppendingString:queryStr];
    }
    
    NSURL *url = [NSURL URLWithString:getModeURL(path)];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:HTTP_REQUEST_TIMEOUT];
    
    if (parameters != nil) {
        if (JSONRequest) {
            [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
            
            NSData* jsonData = [NSJSONSerialization dataWithJSONObject:parameters options:0 error:nil];
            request.HTTPBody = jsonData;
        } else if ([method isEqualToString:@"POST"]) {
            NSString *postStr = encodeDictionary(parameters);
            NSData *postData = [postStr dataUsingEncoding:NSUTF8StringEncoding];
            [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)postData.length] forHTTPHeaderField:@"Content-Length"];
            [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
            [request setHTTPBody:postData];
        }
    }
    
    [request setHTTPMethod:method];
    
    NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (error) {
            completion(nil, error);
            return;
        }
        
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            
            NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
            
            if (statusCode/100 != 2 ) {
                NSError* err = [[NSError alloc] initWithDomain:NSURLErrorDomain code:statusCode userInfo:nil];
                completion(nil, err);

                return;
            }
        }
        
        if (data == nil || data.length == 0) {
            completion(nil, nil);
            return;
        }
        
        NSDictionary* dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
        
        if (error) {
            completion(nil, error);
            return;
        }
    
        id obj = target(dict, targetClasss, &error);
        
        if (error) {
            completion(nil, error);
            return;
        }
        
        completion(obj, error);
        
    }];
    
    [postDataTask resume];
    
    return postDataTask;
}

// User API

+ (NSURLSessionDataTask*)createUser:(int)projectId phoneNumber:(NSString *)phoneNumber name:(NSString *)name completion:(void(^)(MODEUser*, NSError*))completion
{
    NSDictionary *parameters =@{
                                @"projectId":   [NSNumber numberWithInt:projectId],
                                @"phoneNumber": phoneNumber,
                                @"name": name
                                };
    return callHTTPRequest2(nil, true,  @"POST", @"/users", parameters, MODEUser.class, completion);
}

+ (NSURLSessionDataTask*)getUser:(MODEClientAuthentication *)clientAuthentication userId:(int)userId completion:(void (^)(MODEUser *, NSError *))completion
{
    return callHTTPRequest2(clientAuthentication, false, @"GET", [NSString stringWithFormat:@"/users/%d", userId], nil, MODEUser.class, completion);
}

+ (NSURLSessionDataTask*)deleteUser:(MODEClientAuthentication *)clientAuthentication userId:(int)userId completion:(void (^)(MODEUser *, NSError *))completion
{
    return callHTTPRequest2(clientAuthentication, false, @"DELETE", [NSString stringWithFormat:@"/users/%d", userId], nil, MODEUser.class, completion);
}

+(NSURLSessionDataTask*)updateUserInfo:(MODEClientAuthentication *)clientAuthentication userId:(int)userId name:(NSString *)name completion:(void (^)(MODEUser *, NSError *))completion
{
    return callHTTPRequest2(clientAuthentication, true, @"PATCH", [NSString stringWithFormat:@"/users/%d", userId], @{@"name": name}, MODEUser.class, completion);
}

// Home API

+(NSURLSessionDataTask*)getHomes:(MODEClientAuthentication *)clientAuthentication userId:(int)userId completion:(void (^)(NSArray *, NSError *))completion
{
    return callHTTPRequestForArray2(clientAuthentication, false, @"GET", @"/homes",
                    @{@"userId": [@(userId) stringValue]}, MODEHome.class, completion);
}

+ (NSURLSessionDataTask*)createHome:(MODEClientAuthentication *)clientAuthentication name:(NSString*)name timezone:(NSString*)timezone completion:(void (^)(MODEHome *, NSError *))completion
{
    NSDictionary *parameters =@{
                                @"name": name,
                                @"timezone": timezone
                                };
    
    return callHTTPRequest2(clientAuthentication, true,  @"POST", @"/homes", parameters, MODEHome.class, completion);
}

+(NSURLSessionDataTask*)getHome:(MODEClientAuthentication *)clientAuthentication homeId:(int)homeId completion:(void (^)(MODEHome *, NSError *))completion
{
    return callHTTPRequest2(clientAuthentication, false,  @"GET", [NSString stringWithFormat:@"/homes/%d", homeId], nil, MODEHome.class, completion);
}

+(NSURLSessionDataTask*)updateHome:(MODEClientAuthentication *)clientAuthentication homeId:(int)homeId name:(NSString *)name timezone:(NSString *)timezone completion:(void (^)(MODEHome *, NSError *))completion
{
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    if (name) {
        parameters[@"name"] = name;
    }

    if (timezone) {
        parameters[@"timezone"] = timezone;
    }

    return callHTTPRequest2(clientAuthentication, true,  @"PATCH", [NSString stringWithFormat:@"/homes/%d", homeId], parameters, MODEHome.class, completion);
}

+(NSURLSessionDataTask*)deleteHome:(MODEClientAuthentication *)clientAuthentication homeId:(int)homeId completion:(void (^)(MODEHome *, NSError *))completion
{
     return callHTTPRequest2(clientAuthentication, false, @"DELETE", [NSString stringWithFormat:@"/homes/%d", homeId], nil, MODEHome.class, completion);
}

// Home Member API

+(NSURLSessionDataTask*)getHomeMembers:(MODEClientAuthentication *)clientAuthentication homeId:(int)homeId completion:(void (^)(NSArray *, NSError *))completion
{
    return callHTTPRequestForArray2(clientAuthentication, false, @"GET", [NSString stringWithFormat:@"/homes/%d/members", homeId], nil, MODEHomeMember.class, completion);
}

+(NSURLSessionDataTask*)addHomeMember:(MODEClientAuthentication *)clientAuthentication homeId:(int)homeId phoneNumber:(NSString *)phoneNumber completion:(void (^)(MODEHomeMember *, NSError *))completion
{
    NSDictionary *parameters = @{@"phoneNumber": phoneNumber};
    return callHTTPRequest2(clientAuthentication, false, @"POST",  [NSString stringWithFormat:@"/homes/%d/members", homeId], parameters, MODEHomeMember.class, completion);
}

+(NSURLSessionDataTask*)getHomeMember:(MODEClientAuthentication *)clientAuthentication homeId:(int)homeId userId:(int)userId completion:(void (^)(MODEHomeMember *, NSError *))completion
{
    return callHTTPRequest2(clientAuthentication, false, @"GET", [NSString stringWithFormat:@"/homes/%d/members/%d", homeId, userId], nil, MODEHomeMember.class, completion);
}

+(NSURLSessionDataTask*)deleteHomeMember:(MODEClientAuthentication *)clientAuthentication homeId:(int)homeId userId:(int)userId completion:(void (^)(MODEHomeMember *, NSError *))completion
{
    return callHTTPRequest2(clientAuthentication, false, @"DELETE", [NSString stringWithFormat:@"/homes/%d/members/%d", homeId, userId], nil, MODEHomeMember.class, completion);
}

// Smart Module API
+(NSURLSessionDataTask*)getSmartModuleInfo:(MODEClientAuthentication *)clientAuthentication homeId:(int)homeId moduleId:(NSString*)moduleId completion:(void (^)(MODESmartModule *, NSError *))completion
{
    return callHTTPRequest2(clientAuthentication, false, @"GET", [NSString stringWithFormat:@"/homes/%d/smartModules/%@", homeId, moduleId], nil, MODESmartModule.class, completion);
}

+(NSURLSessionDataTask*)sendCommandToSmartModule:(MODEClientAuthentication *)clientAuthentication homeId:(int)homeId moduleId:(NSString *)moduleId action:(NSString *)action parameters:(NSDictionary *)eventParameters completion:(void (^)(MODESmartModule *, NSError *))completion
{
    NSDictionary *parameters = @{@"action": action, @"parameters": eventParameters};
    return callHTTPRequest2(clientAuthentication, true, @"PUT", [NSString stringWithFormat:@"/homes/%d/smartModules/%@/command", homeId, moduleId], parameters, MODESmartModule.class, completion);
}

// Device API

+(NSURLSessionDataTask*)getDevices:(MODEClientAuthentication *)clientAuthentication homeId:(int)homeId completion:(void (^)(NSArray *, NSError *))completion
{
    return callHTTPRequestForArray2(clientAuthentication, false, @"GET", @"/devices", @{@"homeId": [@(homeId) stringValue]}, MODEDevice.class, completion);
}

+ (NSURLSessionDataTask*)getDeviceInfo:(MODEClientAuthentication *)clientAuthentication deviceId:(int)deviceId completion:(void (^)(MODEDevice *, NSError *))completion
{
    return callHTTPRequest2(clientAuthentication, false, @"GET", [NSString stringWithFormat:@"/devices/%d", deviceId], nil, MODEDevice.class, completion);
}

+(NSURLSessionDataTask*)claimDevice:(MODEClientAuthentication *)clientAuthentication claimCode:(NSString *)claimCode homeId:(int)homeId completion:(void (^)(MODEDevice *, NSError *))completion
{
    NSDictionary *parameters = @{@"claimCode": claimCode, @"homeId": [@(homeId) stringValue]};
    return callHTTPRequest2(clientAuthentication, false, @"POST", @"/devices", parameters, MODEDevice.class, completion);
}

+(NSURLSessionDataTask*)updateDevice:(MODEClientAuthentication *)clientAuthentication deviceId:(int)deviceId name:(NSString *)name completion:(void (^)(MODEDevice *, NSError *))completion
{
    return callHTTPRequest2(clientAuthentication, true, @"PATCH", [NSString stringWithFormat:@"/devices/%d", deviceId], @{@"name": name}, MODEDevice.class, completion);
}

+(NSURLSessionDataTask*)deleteDevice:(MODEClientAuthentication *)clientAuthentication deviceId:(int)deviceId completion:(void (^)(MODEDevice *, NSError *))completion
{
    return callHTTPRequest2(clientAuthentication, false, @"DELETE", [NSString stringWithFormat:@"/devices/%d", deviceId], nil, MODEDevice.class, completion);
}

+(NSURLSessionDataTask*)sendCommandToDevice:(MODEClientAuthentication *)clientAuthentication deviceId:(int)deviceId action:(NSString *)action parameters:(NSDictionary *)eventParameters completion:(void (^)(MODEDevice *, NSError *))completion
{
    NSDictionary *parameters = @{@"action": action, @"parameters": eventParameters};
    return callHTTPRequest2(clientAuthentication, true, @"PUT", [NSString stringWithFormat:@"/devices/%d/command", deviceId], parameters, MODEDevice.class, completion);
}

// User Session API

+ (NSURLSessionDataTask*)getUserSessionInfo:(MODEClientAuthentication *)clientAuthentication completion:(void (^)(MODEUserSessionInfo *, NSError *))completion
{
    return callHTTPRequest2(clientAuthentication, false, @"GET", @"/userSession", nil, MODEUserSessionInfo.class, completion);
}

+(NSURLSessionDataTask*)terminateUserSessionInfo:(MODEClientAuthentication *)clientAuthentication completion:(void (^)(MODEUserSessionInfo *, NSError *))completion
{
    return callHTTPRequest2(clientAuthentication, false, @"DELETE", @"/userSession", nil, MODEUserSessionInfo.class, completion);
}

// Authentication API
+ (NSURLSessionDataTask*)initiateAuthenticationWithSMS:(int)projectId phoneNumber:(NSString*)phoneNumber
                                   completion:(void(^)(MODESMSMessageReceipt*, NSError*))completion
{
    NSDictionary *parameters = @{@"projectId": [@(projectId) stringValue], @"phoneNumber": phoneNumber};
    return callHTTPRequest2(nil, false, @"POST", @"/auth/user/sms", parameters, MODESMSMessageReceipt.class, completion);
}

+ (NSURLSessionDataTask*)authenticateWithCode:(int)projectId phoneNumber:(NSString*)phoneNumber appId:(NSString*)appId code:(NSString*)code
                            completion:(void(^)(MODEClientAuthentication*, NSError*))completion;
{
    NSDictionary *parameters = @{@"code": code, @"projectId": [@(projectId) stringValue], @"phoneNumber": phoneNumber, @"appId": appId};
    return callHTTPRequest2(nil, false, @"POST", @"/auth/user", parameters, MODEClientAuthentication.class, completion);
}

+ (NSURLSessionDataTask*)getCurrentAuthenticationState:(MODEClientAuthentication*)clientAuthentication completion:(void(^)(MODEAuthenticationInfo*, NSError*))completion
{
    return callHTTPRequest2(clientAuthentication, false, @"GET", @"/auth", nil, MODEAuthenticationInfo.class, completion);
}

@end
