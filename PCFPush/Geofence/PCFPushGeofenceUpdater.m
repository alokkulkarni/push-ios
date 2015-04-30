//
// Created by DX173-XL on 2015-04-21.
// Copyright (c) 2015 Pivotal. All rights reserved.
//

#import "PCFPushGeofenceUpdater.h"
#import "PCFPushGeofenceEngine.h"
#import "PCFPushURLConnection.h"
#import "PCFPushParameters.h"
#import "PCFPushGeofenceResponseData.h"
#import "NSObject+PCFJSONizable.h"
#import "PCFPushPersistentStorage.h"
#import "PCFPushDebug.h"

static NSString *const GEOFENCE_UPDATE_JSON = @"pivotal.push.geofence_update_json";

BOOL hasGeofencesInRequest(NSDictionary *userInfo) {
    return userInfo != nil && userInfo[GEOFENCE_UPDATE_JSON] != nil;
}

@implementation PCFPushGeofenceUpdater

+ (void) startGeofenceUpdate:(PCFPushGeofenceEngine *)engine
                    userInfo:(NSDictionary *)userInfo
                   timestamp:(int64_t)timestamp
                     success:(void (^)(void))successBlock
                     failure:(void( ^)(NSError *error))failureBlock
{
    if (engine == nil) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"engine may not be nil" userInfo:nil];
    }

    PCFPushParameters *parameters = [PCFPushParameters defaultParameters];

    void (^requestSuccessBlock)(NSURLResponse *, NSData *) = ^(NSURLResponse *response, NSData *data) {

        NSError *error;
        PCFPushGeofenceResponseData *responseData = [PCFPushGeofenceResponseData pcf_fromJSONData:data error:&error];

        if (error) {
            PCFPushLog(@"Error parsing geofence response data: %@", error);
            failureBlock(error);
            return;
        }

        [engine processResponseData:responseData withTimestamp:timestamp];

        [PCFPushPersistentStorage setGeofenceLastModifiedTime:responseData.lastModified];

        if (successBlock) {
            successBlock();
        }
    };

    void (^requestFailureBlock)(NSError *) = ^(NSError *error) {

        // TODO - update the GeofenceStatus
        PCFPushLog(@"Fetching geofences request failed: %@", error);
        if (failureBlock) {
            failureBlock(error);
        }
    };

    if (hasGeofencesInRequest(userInfo) && isAPNSSandbox()) {
        NSString *geofencesInRequest = userInfo[GEOFENCE_UPDATE_JSON];

        requestSuccessBlock(nil, [geofencesInRequest dataUsingEncoding:NSUTF8StringEncoding]);

    } else {
        PCFPushLog(@"Fetching geofence updates from server with timestamp %lld", timestamp);

        [PCFPushURLConnection geofenceRequestWithParameters:parameters
                                                  timestamp:timestamp
                                                    success:requestSuccessBlock
                                                    failure:requestFailureBlock];
    }
};

+ (BOOL) clearGeofences:(PCFPushGeofenceEngine *)engine
                  error:(NSError **)error
{
    [engine processResponseData:nil withTimestamp:0L];
    [PCFPushPersistentStorage setGeofenceLastModifiedTime:PCF_NEVER_UPDATED_GEOFENCES];
    return YES;
}

@end