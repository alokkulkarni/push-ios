//
// Created by DX181-XL on 15-04-15.
//

#import <CoreLocation/CoreLocation.h>
#import "Kiwi.h"
#import "PCFPushGeofenceData.h"
#import "PCFPushGeofenceHandler.h"
#import "NSObject+PCFJSONizable.h"
#import "PCFPushGeofencePersistentStore.h"
#import "PCFPushGeofenceDataList+Loaders.h"

typedef id (^StubBlock)(NSArray*);
static StubBlock geofenceWithId(int64_t expectedGeofenceId, PCFPushGeofenceData *geofence)
{
    return ^id(NSArray *params) {
        int64_t geofenceId = [params[0] longLongValue];
        if (geofenceId == expectedGeofenceId) {
            return geofence;
        }
        return nil;
    };
}

static PCFPushGeofenceData *loadGeofence(Class testProjectClass, NSString *fileName)
{
    NSData *data = loadTestFile(testProjectClass, fileName);
    NSError *error = nil;
    return [PCFPushGeofenceData pcf_fromJSONData:data error:&error];
}

BOOL isAtLeastiOS8_2()
{
    NSArray *iosVersion = [[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."];
    int versionMajor = [iosVersion[0] intValue];
    int versionMinor = [iosVersion[1] intValue];
    return (versionMajor > 8) || ((versionMajor == 8) && (versionMinor >= 2));
}

SPEC_BEGIN(PCFPushGeofenceHandlerSpec)

    describe(@"PCFPushGeofenceHandler", ^{

        __block PCFPushGeofencePersistentStore *store;
        __block PCFPushGeofenceData *geofence2Enter;
        __block PCFPushGeofenceData *geofence3Exit;
        __block PCFPushGeofenceData *geofence1EnterOrExitWithTags;
        __block UIApplication *application;
        __block CLRegion *region2;
        __block CLRegion *region3;
        __block CLRegion *region1;

        describe(@"handling geofence events", ^{

            beforeEach(^{
                store = [PCFPushGeofencePersistentStore mock];
                application = [UIApplication mock];
                geofence1EnterOrExitWithTags = loadGeofence([self class], @"geofence_one_item_persisted_1");
                [[geofence1EnterOrExitWithTags shouldNot] beNil];
                geofence2Enter = loadGeofence([self class], @"geofence_one_item_persisted_2");
                [[geofence2Enter shouldNot] beNil];
                geofence3Exit = loadGeofence([self class], @"geofence_one_item_persisted_3");
                [[geofence3Exit shouldNot] beNil];
                region1 = [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake(0.0, 0.0) radius:0.0 identifier:@"PCF_1_66"];
                region2 = [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake(0.0, 0.0) radius:0.0 identifier:@"PCF_2_66"];
                region3 = [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake(0.0, 0.0) radius:0.0 identifier:@"PCF_3_66"];
                [UIApplication stub:@selector(sharedApplication) andReturn:application];
            });

            context(@"entering a geofence", ^{

                it(@"should trigger a local notification with the enter_or_exit trigger type", ^{
                    [[application should] receive:@selector(presentLocalNotificationNow:)];
                    [store stub:@selector(objectForKeyedSubscript:) withBlock:geofenceWithId(1L, geofence1EnterOrExitWithTags)];
                    [PCFPushGeofenceHandler processRegion:region1 store:store state:CLRegionStateInside];
                });

                it(@"should trigger a local notification with the enter trigger type", ^{
                    [[application should] receive:@selector(presentLocalNotificationNow:)];
                    [store stub:@selector(objectForKeyedSubscript:) withBlock:geofenceWithId(2L, geofence2Enter)];
                    [PCFPushGeofenceHandler processRegion:region2 store:store state:CLRegionStateInside];
                });

                it(@"should not trigger a local notification with the exit trigger type", ^{
                    [[application shouldNot] receive:@selector(presentLocalNotificationNow:)];
                    [store stub:@selector(objectForKeyedSubscript:) withBlock:geofenceWithId(3L, geofence3Exit)];
                    [PCFPushGeofenceHandler processRegion:region3 store:store state:CLRegionStateInside];
                });

                it(@"should not trigger a local notification at all ever if the state is unknown", ^{
                    [[application shouldNot] receive:@selector(presentLocalNotificationNow:)];
                    [store stub:@selector(objectForKeyedSubscript:) withBlock:geofenceWithId(2L, geofence2Enter)];
                    [PCFPushGeofenceHandler processRegion:region3 store:store state:CLRegionStateUnknown];
                });
            });

            context(@"exiting a geofence", ^{

                it(@"should trigger a local notification with the enter_or_exit trigger type", ^{
                    [[application should] receive:@selector(presentLocalNotificationNow:)];
                    [store stub:@selector(objectForKeyedSubscript:) withBlock:geofenceWithId(1L, geofence1EnterOrExitWithTags)];
                    [PCFPushGeofenceHandler processRegion:region1 store:store state:CLRegionStateOutside];
                });

                it(@"should not trigger a local notification with the enter trigger type", ^{
                    [[application shouldNot] receive:@selector(presentLocalNotificationNow:)];
                    [store stub:@selector(objectForKeyedSubscript:) withBlock:geofenceWithId(2L, geofence2Enter)];
                    [PCFPushGeofenceHandler processRegion:region2 store:store state:CLRegionStateOutside];
                });

                it(@"should trigger a local notification with the exit trigger type", ^{
                    [[application should] receive:@selector(presentLocalNotificationNow:)];
                    [store stub:@selector(objectForKeyedSubscript:) withBlock:geofenceWithId(3L, geofence3Exit)];
                    [PCFPushGeofenceHandler processRegion:region3 store:store state:CLRegionStateOutside];
                });

                it(@"should not trigger a local notification at all ever if the state is unknown", ^{
                    [[application shouldNot] receive:@selector(presentLocalNotificationNow:)];
                    [store stub:@selector(objectForKeyedSubscript:) withBlock:geofenceWithId(3L, geofence3Exit)];
                    [PCFPushGeofenceHandler processRegion:region3 store:store state:CLRegionStateUnknown];
                });
            });

            it(@"should require a persistent store", ^{
                [[theBlock(^{
                    [PCFPushGeofenceHandler processRegion:region1 store:nil state:CLRegionStateInside];
                }) should] raiseWithName:NSInvalidArgumentException];
            });

            it(@"should do nothing if processing an empty event", ^{
                [[application shouldNot] receive:@selector(presentLocalNotificationNow:)];
                [[store shouldNot] receive:@selector(objectForKeyedSubscript:)];
                CLRegion *emptyRegion = [[CLRegion alloc] init];
                [PCFPushGeofenceHandler processRegion:emptyRegion store:store state:CLRegionStateInside];
            });

            it(@"should ignore geofence events with unknown IDs", ^{
                [[application shouldNot] receive:@selector(presentLocalNotificationNow:)];
                [store stub:@selector(objectForKeyedSubscript:) andReturn:nil];
                [PCFPushGeofenceHandler processRegion:region3 store:store state:CLRegionStateInside];
            });

            it(@"should populate only iOS 7.0 fields on location notifications on devices < iOS 8.0", ^{

                [UILocalNotification stub: @selector(instancesRespondToSelector:) andReturn:theValue(NO)];

                UILocalNotification *expectedNotification = [[UILocalNotification alloc] init];
                expectedNotification.alertAction = geofence3Exit.data[@"ios"][@"alertAction"];
                expectedNotification.alertBody = geofence3Exit.data[@"ios"][@"alertBody"];
                expectedNotification.alertLaunchImage = geofence3Exit.data[@"ios"][@"alertLaunchImage"];
                expectedNotification.hasAction = [geofence3Exit.data[@"ios"][@"hasAction"] boolValue];
                expectedNotification.applicationIconBadgeNumber = [geofence3Exit.data[@"ios"][@"applicationIconBadgeNumber"] integerValue];
                expectedNotification.soundName = geofence3Exit.data[@"ios"][@"soundName"];
                expectedNotification.userInfo = geofence3Exit.data[@"ios"][@"userInfo"];

                if (isAtLeastiOS8_2()) {
                    [[expectedNotification.alertTitle should] beNil];
                    [[expectedNotification.category should] beNil];
                }

                [[application should] receive:@selector(presentLocalNotificationNow:) withArguments: expectedNotification, nil];
                [store stub:@selector(objectForKeyedSubscript:) withBlock:geofenceWithId(3L, geofence3Exit)];
                [PCFPushGeofenceHandler processRegion:region3 store:store state:CLRegionStateOutside];
            });

            it(@"should populate all the fields on location notifications on up-to-date devices", ^{

                if (!isAtLeastiOS8_2()) {
                    NSLog(@"Skipping test. iOS < 8.2");
                    return;
                }

                UILocalNotification *expectedNotification = [[UILocalNotification alloc] init];
                expectedNotification.alertTitle = geofence3Exit.data[@"ios"][@"alertTitle"]; // iOS 8.2+
                expectedNotification.category = geofence3Exit.data[@"ios"][@"category"]; // iOS 8.0+
                expectedNotification.alertAction = geofence3Exit.data[@"ios"][@"alertAction"];
                expectedNotification.alertBody = geofence3Exit.data[@"ios"][@"alertBody"];
                expectedNotification.alertLaunchImage = geofence3Exit.data[@"ios"][@"alertLaunchImage"];
                expectedNotification.hasAction = [geofence3Exit.data[@"ios"][@"hasAction"] boolValue];
                expectedNotification.applicationIconBadgeNumber = [geofence3Exit.data[@"ios"][@"applicationIconBadgeNumber"] integerValue];
                expectedNotification.soundName = geofence3Exit.data[@"ios"][@"soundName"];
                expectedNotification.userInfo = geofence3Exit.data[@"ios"][@"userInfo"];

                [[application should] receive:@selector(presentLocalNotificationNow:) withArguments: expectedNotification, nil];
                [store stub:@selector(objectForKeyedSubscript:) withBlock:geofenceWithId(3L, geofence3Exit)];
                [PCFPushGeofenceHandler processRegion:region3 store:store state:CLRegionStateOutside];
            });
        });
    });

SPEC_END