//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import "Kiwi.h"
#import "PCFPush.h"
#import "PCFPushAnalytics.h"
#import "PCFPushErrorUtil.h"
#import "PCFPushParameters.h"
#import "PCFPushClientTest.h"
#import "PCFPushSpecsHelper.h"
#import "NSObject+PCFJSONizable.h"
#import "PCFPushGeofenceUpdater.h"
#import "PCFPushGeofenceHandler.h"
#import "PCFPushApplicationUtil.h"
#import "PCFPushPersistentStorage.h"
#import "PCFPushGeofenceStatusUtil.h"
#import "PCFPushRegistrationPutRequestData.h"
#import "PCFPushRegistrationPostRequestData.h"
#import "NSURLConnection+PCFBackEndConnection.h"

SPEC_BEGIN(PCFPushSpecs)

describe(@"PCFPush", ^{
    __block PCFPushSpecsHelper *helper = nil;

    beforeEach(^{
        [PCFPushClient resetSharedClient];
        helper = [[PCFPushSpecsHelper alloc] init];
        [helper setupParameters];
        [PCFPushAnalytics resetAnalytics];
    });

    afterEach(^{
        [helper reset];
    });
    
    describe(@"getting the version", ^{
       
        // Compare the version number to the one in the "PCFPush.podspec" file.
        // Note that you must run "pod update" after changing the version number in "PCFPush.podspec".
        it(@"should return the current SDK version", ^{
            [[[PCFPush sdkVersion] shouldNot] beNil];
            [[[PCFPush sdkVersion] shouldNot] equal:@"0.0.0"];
        });
    });

    describe(@"setting parameters", ^{

        beforeEach(^{
            [PCFPushAnalytics stub:@selector(isAnalyticsPollingTime:) andReturn:theValue(NO)];
        });

        describe(@"empty and nillable parameters", ^{

            __block BOOL succeeded = NO;
            __block void (^successBlock)() = ^{
                succeeded = YES;
            };
            __block void (^failureBlock)(NSError *) = ^(NSError *error) {
                fail(@"should have succeeded");
            };

            beforeEach(^{
                [helper setupDefaultPLIST];
                [helper setupSuccessfulAsyncRegistrationRequest];
                [PCFPushGeofenceStatusUtil stub:@selector(updateGeofenceStatusWithError:errorReason:number:fileManager:)];
            });

            afterEach(^{
                [[theValue(succeeded) should] equal:theValue(YES)];
            });

            it(@"should accept a nil custom user ID", ^{
                [PCFPush registerForPCFPushNotificationsWithDeviceToken:helper.apnsDeviceToken tags:helper.tags1 deviceAlias:@"NOT EMPTY" customUserId:nil areGeofencesEnabled:NO success:successBlock failure:failureBlock];
            });

            it(@"should accept an empty custom user ID", ^{
                [PCFPush registerForPCFPushNotificationsWithDeviceToken:helper.apnsDeviceToken tags:helper.tags1 deviceAlias:@"NOT EMPTY" customUserId:@"" areGeofencesEnabled:NO success:successBlock failure:failureBlock];
            });

            it(@"should accept a nil deviceAlias", ^{
                [PCFPush registerForPCFPushNotificationsWithDeviceToken:helper.apnsDeviceToken tags:helper.tags1 deviceAlias:nil customUserId:@"MY AWESOME ID" areGeofencesEnabled:NO success:successBlock failure:failureBlock];
            });

            it(@"should accept an empty deviceAlias", ^{
                [PCFPush registerForPCFPushNotificationsWithDeviceToken:helper.apnsDeviceToken tags:helper.tags1 deviceAlias:@"" customUserId:@"MY AWESOME ID" areGeofencesEnabled:NO success:successBlock failure:failureBlock];
            });

            it(@"should accept a non-empty deviceAlias and tags", ^{
                [PCFPush registerForPCFPushNotificationsWithDeviceToken:helper.apnsDeviceToken tags:helper.tags1 deviceAlias:@"NOT EMPTY" customUserId:@"MY AWESOME ID" areGeofencesEnabled:NO success:successBlock failure:failureBlock];
            });

            it(@"should accept a nil tags", ^{
                [PCFPush registerForPCFPushNotificationsWithDeviceToken:helper.apnsDeviceToken tags:nil deviceAlias:@"NOT EMPTY" customUserId:@"MY AWESOME ID" areGeofencesEnabled:NO success:successBlock failure:failureBlock];
            });

            it(@"should accept an empty tags", ^{
                [PCFPush registerForPCFPushNotificationsWithDeviceToken:helper.apnsDeviceToken tags:[NSSet<NSString*> set] deviceAlias:@"NOT EMPTY" customUserId:@"MY AWESOME ID" areGeofencesEnabled:NO success:successBlock failure:failureBlock];
            });

            it(@"should accept a nil deviceAlias and nil tags", ^{
                [PCFPush registerForPCFPushNotificationsWithDeviceToken:helper.apnsDeviceToken tags:nil deviceAlias:nil customUserId:@"MY AWESOME ID" areGeofencesEnabled:NO success:successBlock failure:failureBlock];
            });

            it(@"should accept an empty deviceAlias and empty tags", ^{
                [PCFPush registerForPCFPushNotificationsWithDeviceToken:helper.apnsDeviceToken tags:[NSSet<NSString*> set] deviceAlias:@"" customUserId:@"MY AWESOME ID" areGeofencesEnabled:NO success:successBlock failure:failureBlock];
            });
        });

        describe(@"nil callbacks", ^{

            void (^successBlock)() = ^{};
            void (^failureBlock)(NSError *) = ^(NSError *error) {};

            beforeEach(^{
                [helper setupDefaultPLIST];
                [helper setupSuccessfulAsyncRegistrationRequest];
                [PCFPushGeofenceStatusUtil stub:@selector(updateGeofenceStatusWithError:errorReason:number:fileManager:)];
            });

            it(@"should accept a nil failureBlock", ^{
                [PCFPush registerForPCFPushNotificationsWithDeviceToken:helper.apnsDeviceToken tags:[NSSet<NSString*> set] deviceAlias:@"NOT EMPTY" areGeofencesEnabled:NO success:successBlock failure:nil];
            });

            it(@"should accept a nil successBlock", ^{
                [PCFPush registerForPCFPushNotificationsWithDeviceToken:helper.apnsDeviceToken tags:[NSSet<NSString*> set] deviceAlias:@"NOT EMPTY" areGeofencesEnabled:NO success:nil failure:failureBlock];
            });
        });

        it(@"should raise an exception if parameters are nil", ^{
            [[theBlock(^{
                [helper setupDefaultPLISTWithFile:@"PCFPushParameters-Empty"];
                [PCFPush registerForPCFPushNotificationsWithDeviceToken:helper.apnsDeviceToken tags:nil deviceAlias:nil areGeofencesEnabled:NO success:nil failure:nil];
            }) should] raiseWithName:NSInvalidArgumentException];
        });

        it(@"should raise an exception if parameters are invalid", ^{
            [[theBlock(^{
                [helper setupDefaultPLISTWithFile:@"PCFPushParameters-Invalid"];
                [PCFPush registerForPCFPushNotificationsWithDeviceToken:helper.apnsDeviceToken tags:nil deviceAlias:nil areGeofencesEnabled:NO success:nil failure:nil];
            }) should] raiseWithName:NSInvalidArgumentException];
        });

        it(@"should raise an exception if startRegistration is called without parameters being set", ^{
            [[theBlock(^{
                [PCFPush registerForPCFPushNotificationsWithDeviceToken:helper.apnsDeviceToken tags:nil deviceAlias:nil areGeofencesEnabled:NO success:nil failure:nil];
            }) should] raiseWithName:NSInvalidArgumentException];
        });

        it(@"should raise an exception if the APNS device token is nil", ^{
            [[theBlock(^{
                [PCFPush registerForPCFPushNotificationsWithDeviceToken:nil tags:[NSSet<NSString*> set] deviceAlias:@"NOT EMPTY" areGeofencesEnabled:NO success:nil failure:nil];
            }) should] raiseWithName:NSInvalidArgumentException];
        });

        it(@"should raise an exception if the APNS device token is empty", ^{
            [[theBlock(^{
                [PCFPush registerForPCFPushNotificationsWithDeviceToken:helper.apnsDeviceToken tags:[NSSet<NSString*> set] deviceAlias:@"NOT EMPTY" areGeofencesEnabled:NO success:nil failure:nil];
            }) should] raiseWithName:NSInvalidArgumentException];
        });

        it(@"should let you set request headers", ^{
            [PCFPush setRequestHeaders:@{ @"TACOS":@"SPICY", @"CANDY":@"HAPPY" }];
            [[[PCFPushPersistentStorage requestHeaders] should] equal:@{ @"TACOS":@"SPICY", @"CANDY":@"HAPPY" }];
        });
    });

    describe(@"a push registration with an existing registration", ^{

        __block NSInteger successCount;
        __block NSInteger updateRegistrationCount;
        __block void (^testBlock)(SEL, id, NSString*, BOOL);
        __block NSSet<NSString*> *expectedSubscribeTags;
        __block NSSet<NSString*> *expectedUnsubscribeTags;

        beforeEach(^{
            successCount = 0;
            updateRegistrationCount = 0;
            expectedSubscribeTags = nil;
            expectedUnsubscribeTags = nil;

            testBlock = ^(SEL sel, id newPersistedValue, NSString *expectedHttpMethod, BOOL areGeofencesEnabled) {

                [helper setupSuccessfulAsyncRegistrationRequestWithBlock:^(NSURLRequest *request) {

                    [[request.HTTPMethod should] equal:expectedHttpMethod];

                    updateRegistrationCount++;

                    NSError *error;

                    PCFPushRegistrationData *requestBody;

                    if ([expectedHttpMethod isEqualToString:@"PUT"]) {

                        PCFPushRegistrationPutRequestData *requestPutBody = [PCFPushRegistrationPutRequestData pcfPushFromJSONData:request.HTTPBody error:&error];
                        requestBody = requestPutBody;

                        [[error should] beNil];
                        [[requestPutBody shouldNot] beNil];

                        if (expectedSubscribeTags) {
                            [[[NSSet<NSString*> setWithArray:requestPutBody.subscribeTags] should] equal:expectedSubscribeTags];
                        } else {
                            [[requestPutBody.subscribeTags should] beNil];
                        }

                        if (expectedUnsubscribeTags) {
                            [[[NSSet<NSString*> setWithArray:requestPutBody.unsubscribeTags] should] equal:expectedUnsubscribeTags];
                        } else {
                            [[requestPutBody.unsubscribeTags should] beNil];
                        }

                    } else if ([expectedHttpMethod isEqualToString:@"POST"]) {

                        PCFPushRegistrationPostRequestData *requestPostBody = [PCFPushRegistrationPostRequestData pcfPushFromJSONData:request.HTTPBody error:&error];
                        requestBody = requestPostBody;

                        [[error should] beNil];
                        [[requestPostBody shouldNot] beNil];

                        if (expectedSubscribeTags) {
                            [[[NSSet<NSString*> setWithArray:requestPostBody.tags] should] equal:expectedSubscribeTags];
                        } else {
                            [[requestPostBody.tags should] beNil];
                        }
                    }

                    [[requestBody shouldNot] beNil];
                    [[requestBody.variantUUID should] beNil];
                    [[requestBody.deviceAlias should] equal:TEST_DEVICE_ALIAS_1];
                    [[requestBody.customUserId should] equal:TEST_CUSTOM_USER_ID_1];
                }];

                [[NSURLConnection should] receive:@selector(pcfPushSendAsynchronousRequestWrapper:queue:completionHandler:)];

                [PCFPushAnalytics stub:@selector(isAnalyticsPollingTime:) andReturn:theValue(NO)];
                [helper setupDefaultPersistedParameters];
                [helper setupDefaultPLIST];

                [PCFPushPersistentStorage performSelector:sel withObject:newPersistedValue];

                void (^successBlock)() = ^{
                    [[[PCFPush deviceUuid] should] equal:TEST_DEVICE_UUID];
                    successCount++;
                };

                void (^failureBlock)(NSError *) = ^(NSError *error) {
                    fail(@"registration failure block executed");
                };

                [PCFPush registerForPCFPushNotificationsWithDeviceToken:helper.apnsDeviceToken tags:helper.params.pushTags deviceAlias:helper.params.pushDeviceAlias customUserId:helper.params.pushCustomUserId areGeofencesEnabled:areGeofencesEnabled success:successBlock failure:failureBlock];

                [[theValue([PCFPushPersistentStorage areGeofencesEnabled]) should] equal:theValue(areGeofencesEnabled)];
            };
        });

        afterEach(^{
            [[theValue(successCount) should] equal:theValue(1)];
            [[theValue(updateRegistrationCount) should] equal:theValue(1)];
        });

        context(@"with no geofence update in the past (i.e.: geofences have been disabled)", ^{

            context(@"geofences are enabled (and so will update geofences this time)", ^{

                beforeEach(^{
                    [helper setupGeofencesForSuccessfulUpdateWithLastModifiedTime:1337L];
                    [PCFPushPersistentStorage setAreGeofencesEnabled:NO];
                    [[PCFPushGeofenceUpdater should] receive:@selector(startGeofenceUpdate:userInfo:timestamp:tags:success:failure:) withCount:1];
                    [[PCFPushGeofenceUpdater shouldNot] receive:@selector(clearAllGeofences:)];
                    [[PCFPushGeofenceHandler shouldNot] receive:@selector(reregisterGeofencesWithEngine:subscribedTags:)];
                });

                afterEach(^{
                    [[theValue([PCFPushPersistentStorage lastGeofencesModifiedTime]) should] equal:theValue(1337L)];
                    [[[PCFPushPersistentStorage customUserId] should] equal:helper.params.pushCustomUserId];
                    [[[PCFPushPersistentStorage deviceAlias] should] equal:helper.params.pushDeviceAlias];
                });

                it(@"should do a new push registration and geofences after the variantUuid changes", ^{
                    expectedSubscribeTags = helper.tags1;
                    testBlock(@selector(setVariantUUID:), @"DIFFERENT STRING", @"POST", YES);
                });

                it(@"should do a new push registration and geofences after the variantUuid is initially set", ^{
                    expectedSubscribeTags = helper.tags1;
                    testBlock(@selector(setVariantUUID:), nil, @"POST", YES);
                });

                it(@"should do a new push registration and geofences after the variantSecret changes", ^{
                    expectedSubscribeTags = helper.tags1;
                    testBlock(@selector(setVariantSecret:), @"DIFFERENT STRING", @"POST", YES);
                });

                it(@"should do a new push registration and geofences after the variantSecret is initially set", ^{
                    expectedSubscribeTags = helper.tags1;
                    testBlock(@selector(setVariantSecret:), nil, @"POST", YES);
                });

                it(@"should update the push registration and geofences after the customUserId changes (with geofence update)", ^{
                    testBlock(@selector(setCustomUserId:), @"DIFFERENT STRING", @"PUT", YES);
                });

                it(@"should update the push registration and geofences after the customUserId is initially set (with geofence update)", ^{
                    testBlock(@selector(setCustomUserId:), nil, @"PUT", YES);
                });

                it(@"should update the push registration and geofences after the deviceAlias changes (with geofence update)", ^{
                    testBlock(@selector(setDeviceAlias:), @"DIFFERENT STRING", @"PUT", YES);
                });

                it(@"should update the push registration and geofences after the deviceAlias is initially set (with geofence update)", ^{
                    testBlock(@selector(setDeviceAlias:), nil, @"PUT", YES);
                });

                it(@"should update the push registration and geofences after the APNSDeviceToken changes", ^{
                    testBlock(@selector(setAPNSDeviceToken:), [@"DIFFERENT TOKEN" dataUsingEncoding:NSUTF8StringEncoding], @"PUT", YES);
                });

                it(@"should update the push registration and geofences after the tags change to a different value", ^{
                    expectedSubscribeTags = helper.tags1;
                    expectedUnsubscribeTags = [NSSet<NSString*> setWithArray:@[@"DIFFERENT TAG"]];
                    testBlock(@selector(setTags:), expectedUnsubscribeTags, @"PUT", YES);
                });

                it(@"should update the push registration and geofences after tags initially set from nil", ^{
                    expectedSubscribeTags = helper.tags1;
                    testBlock(@selector(setTags:), nil, @"PUT", YES);
                });

                it(@"should update the push registration and geofences after tags initially set from empty", ^{
                    expectedSubscribeTags = helper.tags1;
                    testBlock(@selector(setTags:), [NSSet<NSString*> set], @"PUT", YES);
                });

                it(@"should update the push registration and geofences after tags change to nil", ^{
                    helper.params.pushTags = nil;
                    expectedUnsubscribeTags = helper.tags1;
                    testBlock(@selector(setTags:), helper.tags1, @"PUT", YES);
                });

                it(@"should update the push registration and geofences after tags change to empty", ^{
                    helper.params.pushTags = [NSSet<NSString*> set];
                    expectedUnsubscribeTags = helper.tags1;
                    testBlock(@selector(setTags:), helper.tags1, @"PUT", YES);
                });
            });

            context(@"geofences are disabled (neither clear nor update geofences)", ^{

                beforeEach(^{
                    [PCFPushPersistentStorage setAreGeofencesEnabled:NO];
                    [[PCFPushGeofenceUpdater shouldNot] receive:@selector(startGeofenceUpdate:userInfo:timestamp:tags:success:failure:)];
                    [[PCFPushGeofenceUpdater shouldNot] receive:@selector(clearAllGeofences:)];
                    [[PCFPushGeofenceHandler shouldNot] receive:@selector(reregisterGeofencesWithEngine:subscribedTags:)];
                });

                afterEach(^{
                    [[theValue([PCFPushPersistentStorage lastGeofencesModifiedTime]) should] equal:theValue(PCF_NEVER_UPDATED_GEOFENCES)];
                    [[[PCFPushPersistentStorage customUserId] should] equal:helper.params.pushCustomUserId];
                    [[[PCFPushPersistentStorage deviceAlias] should] equal:helper.params.pushDeviceAlias];
                });

                it(@"should do a new push registration and geofences after the variantUuid changes", ^{
                    expectedSubscribeTags = helper.tags1;
                    testBlock(@selector(setVariantUUID:), @"DIFFERENT STRING", @"POST", NO);
                });

                it(@"should do a new push registration and geofences after the variantUuid is initially set", ^{
                    expectedSubscribeTags = helper.tags1;
                    testBlock(@selector(setVariantUUID:), nil, @"POST", NO);
                });

                it(@"should do a new push registration and geofences after the variantSecret changes", ^{
                    expectedSubscribeTags = helper.tags1;
                    testBlock(@selector(setVariantSecret:), @"DIFFERENT STRING", @"POST", NO);
                });

                it(@"should do a new push registration and geofences after the variantSecret is initially set", ^{
                    expectedSubscribeTags = helper.tags1;
                    testBlock(@selector(setVariantSecret:), nil, @"POST", NO);
                });

                it(@"should update the push registration and geofences after the customUserId changes (with geofence update)", ^{
                    testBlock(@selector(setCustomUserId:), @"DIFFERENT STRING", @"PUT", NO);
                });

                it(@"should update the push registration and geofences after the customUserId is initially set (with geofence update)", ^{
                    testBlock(@selector(setCustomUserId:), nil, @"PUT", NO);
                });

                it(@"should update the push registration and geofences after the deviceAlias changes (with geofence update)", ^{
                    testBlock(@selector(setDeviceAlias:), @"DIFFERENT STRING", @"PUT", NO);
                });

                it(@"should update the push registration and geofences after the deviceAlias is initially set (with geofence update)", ^{
                    testBlock(@selector(setDeviceAlias:), nil, @"PUT", NO);
                });

                it(@"should update the push registration and geofences after the APNSDeviceToken changes", ^{
                    testBlock(@selector(setAPNSDeviceToken:), [@"DIFFERENT TOKEN" dataUsingEncoding:NSUTF8StringEncoding], @"PUT", NO);
                });

                it(@"should update the push registration and geofences after the tags change to a different value", ^{
                    expectedSubscribeTags = helper.tags1;
                    expectedUnsubscribeTags = [NSSet<NSString*> setWithArray:@[@"DIFFERENT TAG"]];
                    testBlock(@selector(setTags:), expectedUnsubscribeTags, @"PUT", NO);
                });

                it(@"should update the push registration and geofences after tags initially set from nil", ^{
                    expectedSubscribeTags = helper.tags1;
                    testBlock(@selector(setTags:), nil, @"PUT", NO);
                });

                it(@"should update the push registration and geofences after tags initially set from empty", ^{
                    expectedSubscribeTags = helper.tags1;
                    testBlock(@selector(setTags:), [NSSet<NSString*> set], @"PUT", NO);
                });

                it(@"should update the push registration and geofences after tags change to nil", ^{
                    helper.params.pushTags = nil;
                    expectedUnsubscribeTags = helper.tags1;
                    testBlock(@selector(setTags:), helper.tags1, @"PUT", NO);
                });

                it(@"should update the push registration and geofences after tags change to empty", ^{
                    helper.params.pushTags = [NSSet<NSString*> set];
                    expectedUnsubscribeTags = helper.tags1;
                    testBlock(@selector(setTags:), helper.tags1, @"PUT", NO);
                });
            });
        });

        context(@"with geofences updated in the past (same variant)", ^{

            context(@"geofences are enabled (and so will skip a geofence update this time)", ^{

                beforeEach(^{
                    [PCFPushPersistentStorage setGeofenceLastModifiedTime:1337L];
                    [PCFPushPersistentStorage setAreGeofencesEnabled:YES];
                    [[PCFPushGeofenceUpdater shouldNot] receive:@selector(startGeofenceUpdate:userInfo:timestamp:tags:success:failure:)];
                    [[PCFPushGeofenceUpdater shouldNot] receive:@selector(clearAllGeofences:)];
                });

                afterEach(^{
                    [[theValue([PCFPushPersistentStorage lastGeofencesModifiedTime]) should] equal:theValue(1337L)];
                    [[[PCFPushPersistentStorage customUserId] should] equal:helper.params.pushCustomUserId];
                    [[[PCFPushPersistentStorage deviceAlias] should] equal:helper.params.pushDeviceAlias];
                });

                context(@"tags the same", ^{

                    beforeEach(^{
                        [[PCFPushGeofenceHandler shouldNot] receive:@selector(reregisterGeofencesWithEngine:subscribedTags:)];
                    });

                    it(@"should update the push registration after the customUserId changes (without geofence update)", ^{
                        testBlock(@selector(setCustomUserId:), @"DIFFERENT STRING", @"PUT", YES);
                    });

                    it(@"should update the push registration after the customUserId is initially set (without geofence update)", ^{
                        testBlock(@selector(setCustomUserId:), nil, @"PUT", YES);
                    });

                    it(@"should update the push registration after the deviceAlias changes (without geofence update)", ^{
                        testBlock(@selector(setDeviceAlias:), @"DIFFERENT STRING", @"PUT", YES);
                    });

                    it(@"should update the push registration after the deviceAlias is initially set (without geofence update)", ^{
                        testBlock(@selector(setDeviceAlias:), nil, @"PUT", YES);
                    });

                    it(@"should update the push registration after the APNSDeviceToken changes", ^{
                        testBlock(@selector(setAPNSDeviceToken:), [@"DIFFERENT TOKEN" dataUsingEncoding:NSUTF8StringEncoding], @"PUT", YES);
                    });
                });

                context(@"tags different", ^{

                    beforeEach(^{
                        [[PCFPushGeofenceHandler should] receive:@selector(reregisterGeofencesWithEngine:subscribedTags:)];
                    });

                    it(@"should update the push registration after the tags change to a different value", ^{
                        expectedSubscribeTags = helper.tags1;
                        expectedUnsubscribeTags = [NSSet<NSString*> setWithArray:@[@"DIFFERENT TAG"]];
                        testBlock(@selector(setTags:), expectedUnsubscribeTags, @"PUT", YES);
                    });

                    it(@"should update the push registration after tags initially set from nil", ^{
                        expectedSubscribeTags = helper.tags1;
                        testBlock(@selector(setTags:), nil, @"PUT", YES);
                    });

                    it(@"should update the push registration after tags initially set from empty", ^{
                        expectedSubscribeTags = helper.tags1;
                        testBlock(@selector(setTags:), [NSSet<NSString*> set], @"PUT", YES);
                    });

                    it(@"should update the push registration after tags change to nil", ^{
                        helper.params.pushTags = nil;
                        expectedUnsubscribeTags = helper.tags1;
                        testBlock(@selector(setTags:), helper.tags1, @"PUT", YES);
                    });

                    it(@"should update the push registration after tags change to empty", ^{
                        helper.params.pushTags = [NSSet<NSString*> set];
                        expectedUnsubscribeTags = helper.tags1;
                        testBlock(@selector(setTags:), helper.tags1, @"PUT", YES);
                    });
                });
            });

            context(@"geofences are disabled (so it should clear geofences this time)", ^{

                beforeEach(^{
                    [PCFPushPersistentStorage setAreGeofencesEnabled:YES];
                    [PCFPushPersistentStorage setGeofenceLastModifiedTime:1337L];
                    [[PCFPushGeofenceHandler shouldNot] receive:@selector(reregisterGeofencesWithEngine:subscribedTags:)];
                    [[PCFPushGeofenceUpdater shouldNot] receive:@selector(startGeofenceUpdate:userInfo:timestamp:tags:success:failure:)];
                    [[PCFPushGeofenceUpdater should] receive:@selector(clearAllGeofences:)];
                    [PCFPushGeofenceUpdater stub:@selector(clearAllGeofences:) withBlock:^id(NSArray *params) {
                        [PCFPushPersistentStorage setGeofenceLastModifiedTime:PCF_NEVER_UPDATED_GEOFENCES];
                        return nil;
                    }];
                });

                afterEach(^{
                    [[theValue([PCFPushPersistentStorage lastGeofencesModifiedTime]) should] equal:theValue(PCF_NEVER_UPDATED_GEOFENCES)];
                    [[[PCFPushPersistentStorage customUserId] should] equal:helper.params.pushCustomUserId];
                    [[[PCFPushPersistentStorage deviceAlias] should] equal:helper.params.pushDeviceAlias];
                });

                it(@"should update the push registration after the customUserId changes (without geofence update)", ^{
                    testBlock(@selector(setCustomUserId:), @"DIFFERENT STRING", @"PUT", NO);
                });

                it(@"should update the push registration after the customUserId is initially set (without geofence update)", ^{
                    testBlock(@selector(setCustomUserId:), nil, @"PUT", NO);
                });

                it(@"should update the push registration after the deviceAlias changes (without geofence update)", ^{
                    testBlock(@selector(setDeviceAlias:), @"DIFFERENT STRING", @"PUT", NO);
                });

                it(@"should update the push registration after the deviceAlias is initially set (without geofence update)", ^{
                    testBlock(@selector(setDeviceAlias:), nil, @"PUT", NO);
                });

                it(@"should update the push registration after the APNSDeviceToken changes", ^{
                    testBlock(@selector(setAPNSDeviceToken:), [@"DIFFERENT TOKEN" dataUsingEncoding:NSUTF8StringEncoding], @"PUT", NO);
                });

                it(@"should update the push registration after the tags change to a different value", ^{
                    expectedSubscribeTags = helper.tags1;
                    expectedUnsubscribeTags = [NSSet<NSString*> setWithArray:@[@"DIFFERENT TAG"]];
                    testBlock(@selector(setTags:), expectedUnsubscribeTags, @"PUT", NO);
                });

                it(@"should update the push registration after tags initially set from nil", ^{
                    expectedSubscribeTags = helper.tags1;
                    testBlock(@selector(setTags:), nil, @"PUT", NO);
                });

                it(@"should update the push registration after tags initially set from empty", ^{
                    expectedSubscribeTags = helper.tags1;
                    testBlock(@selector(setTags:), [NSSet<NSString*> set], @"PUT", NO);
                });

                it(@"should update the push registration after tags change to nil", ^{
                    helper.params.pushTags = nil;
                    expectedUnsubscribeTags = helper.tags1;
                    testBlock(@selector(setTags:), helper.tags1, @"PUT", NO);
                });

                it(@"should update the push registration after tags change to empty", ^{
                    helper.params.pushTags = [NSSet<NSString*> set];
                    expectedUnsubscribeTags = helper.tags1;
                    testBlock(@selector(setTags:), helper.tags1, @"PUT", NO);
                });
            });
        });

        context(@"with geofences updated in the past (different variant)", ^{

            context(@"with geofences enabled (and will still do a geofence reset and update this time)", ^{

                beforeEach(^{
                    expectedSubscribeTags = helper.tags1;
                    [PCFPushPersistentStorage setAreGeofencesEnabled:YES];
                    [PCFPushPersistentStorage setGeofenceLastModifiedTime:1337L];
                    [helper setupClearGeofencesForSuccess];
                    [helper setupGeofencesForSuccessfulUpdateWithLastModifiedTime:2784L];
                    [[PCFPushGeofenceUpdater should] receive:@selector(clearAllGeofences:) withCount:1];
                    [[PCFPushGeofenceUpdater should] receive:@selector(startGeofenceUpdate:userInfo:timestamp:tags:success:failure:) withCount:1];
                    [[PCFPushGeofenceHandler shouldNot] receive:@selector(reregisterGeofencesWithEngine:subscribedTags:)];
                });

                afterEach(^{
                    [[theValue([PCFPushPersistentStorage lastGeofencesModifiedTime]) should] equal:theValue(2784L)];
                });

                it(@"should do a new push registration and geofences after the variantUuid changes", ^{
                    testBlock(@selector(setVariantUUID:), @"DIFFERENT STRING", @"POST", YES);
                });

                it(@"should do a new push registration and geofences after the variantUuid is initially set", ^{
                    testBlock(@selector(setVariantUUID:), nil, @"POST", YES);
                });

                it(@"should do a new push registration and geofences after the variantSecret changes", ^{
                    testBlock(@selector(setVariantSecret:), @"DIFFERENT STRING", @"POST", YES);
                });

                it(@"should do a new push registration and geofences after the variantSecret is initially set", ^{
                    testBlock(@selector(setVariantSecret:), nil, @"POST", YES);
                });
            });

            context(@"with geofences disabled (and will just do a geofence reset - with no update)", ^{

                beforeEach(^{
                    expectedSubscribeTags = helper.tags1;
                    [PCFPushPersistentStorage setAreGeofencesEnabled:YES];
                    [PCFPushPersistentStorage setGeofenceLastModifiedTime:1337L];
                    [helper setupClearGeofencesForSuccess];
                    [[PCFPushGeofenceHandler shouldNot] receive:@selector(reregisterGeofencesWithEngine:subscribedTags:)];
                    [[PCFPushGeofenceUpdater should] receive:@selector(clearAllGeofences:) withCount:1];
                    [[PCFPushGeofenceUpdater shouldNot] receive:@selector(startGeofenceUpdate:userInfo:timestamp:tags:success:failure:)];
                    [PCFPushGeofenceUpdater stub:@selector(clearAllGeofences:) withBlock:^id(NSArray *params) {
                        [PCFPushPersistentStorage setGeofenceLastModifiedTime:PCF_NEVER_UPDATED_GEOFENCES];
                        return nil;
                    }];
                });

                afterEach(^{
                    [[theValue([PCFPushPersistentStorage lastGeofencesModifiedTime]) should] equal:theValue(PCF_NEVER_UPDATED_GEOFENCES)];
                });

                it(@"should do a new push registration and geofences after the variantUuid changes", ^{
                    testBlock(@selector(setVariantUUID:), @"DIFFERENT STRING", @"POST", NO);
                });

                it(@"should do a new push registration and geofences after the variantUuid is initially set", ^{
                    testBlock(@selector(setVariantUUID:), nil, @"POST", NO);
                });

                it(@"should do a new push registration and geofences after the variantSecret changes", ^{
                    testBlock(@selector(setVariantSecret:), @"DIFFERENT STRING", @"POST", NO);
                });

                it(@"should do a new push registration and geofences after the variantSecret is initially set", ^{
                    testBlock(@selector(setVariantSecret:), nil, @"POST", NO);
                });
            });
        });
    });

    describe(@"successful push registration", ^{

        beforeEach(^{
            [PCFPushAnalytics stub:@selector(isAnalyticsPollingTime:) andReturn:theValue(NO)];
        });

        context(@"geofences enabled", ^{
            it(@"should make a POST request to the server and update geofences on a new registration", ^{

                __block BOOL wasSuccessBlockExecuted = NO;
                __block NSSet<NSString*> *expectedTags = helper.tags1;

                [helper setupGeofencesForSuccessfulUpdateWithLastModifiedTime:999L withBlock:^void(NSArray *params) {
                    int64_t timestamp = [params[2] longLongValue];
                    [[theValue(timestamp) should] beZero];
                }];
                [[PCFPushGeofenceUpdater should] receive:@selector(startGeofenceUpdate:userInfo:timestamp:tags:success:failure:) withCount:1];

                [[NSURLConnection should] receive:@selector(pcfPushSendAsynchronousRequestWrapper:queue:completionHandler:) withCount:1];

                [helper setupSuccessfulAsyncRegistrationRequestWithBlock:^(NSURLRequest *request) {

                    [[request.HTTPMethod should] equal:@"POST"];

                    NSError *error;
                    PCFPushRegistrationPostRequestData *requestBody = [PCFPushRegistrationPostRequestData pcfPushFromJSONData:request.HTTPBody error:&error];
                    [[error should] beNil];
                    [[requestBody shouldNot] beNil];
                    [[[NSSet<NSString*> setWithArray:requestBody.tags] should] equal:expectedTags];
                }];

                [helper setupDefaultPLIST];

                void (^successBlock)() = ^{
                    wasSuccessBlockExecuted = YES;
                };

                void (^failureBlock)(NSError *) = ^(NSError *error) {
                    fail(@"registration failure block executed");
                };

                [PCFPush registerForPCFPushNotificationsWithDeviceToken:helper.apnsDeviceToken tags:helper.tags1 deviceAlias:TEST_DEVICE_ALIAS customUserId:TEST_CUSTOM_USER_ID areGeofencesEnabled:YES success:successBlock failure:failureBlock];

                [[theValue(wasSuccessBlockExecuted) should] beTrue];

                [[[PCFPush deviceUuid] should] equal:TEST_DEVICE_UUID];
                [[theValue([PCFPushPersistentStorage areGeofencesEnabled]) should] beYes];
            });

            context(@"should bypass registering against Remote Push Server if Device Token matches the stored token.", ^{

                __block NSInteger registrationRequestCount;
                __block NSInteger geofenceUpdateCount;
                __block BOOL wasSuccessBlockExecuted;
                __block BOOL wasFailBlockExecuted;
                __block void (^successBlock)() = ^{
                    wasSuccessBlockExecuted = YES;
                };
                __block void (^failureBlock)(NSError *) = ^(NSError *error) {
                    wasFailBlockExecuted = YES;
                };

                beforeEach(^{
                    registrationRequestCount = 0;
                    geofenceUpdateCount = 0;
                    wasSuccessBlockExecuted = NO;
                    wasFailBlockExecuted = NO;
                });

                afterEach(^{
                    [[NSURLConnection should] receive:@selector(sendAsynchronousRequest:queue:completionHandler:) withCount:1];
                    [[[PCFPush deviceUuid] should] equal:TEST_DEVICE_UUID];
                    [[theValue([PCFPushPersistentStorage areGeofencesEnabled]) should] beYes];
                });

                it(@"when geofences were never updated (and the geofence update passes)", ^{

                    [helper setupSuccessfulAsyncRegistrationRequestWithBlock:^(NSURLRequest *request) {
                        registrationRequestCount += 1;
                    }];

                    [helper setupGeofencesForSuccessfulUpdateWithLastModifiedTime:1337L withBlock:^(NSArray *array) {
                        geofenceUpdateCount += 1;
                    }];

                    [PCFPush load];
                    [helper setupDefaultPLIST];

                    [PCFPush registerForPCFPushNotificationsWithDeviceToken:helper.apnsDeviceToken tags:helper.tags1 deviceAlias:TEST_DEVICE_ALIAS areGeofencesEnabled:YES success:nil failure:failureBlock];
                    [[theValue(registrationRequestCount) should] equal:theValue(1)];
                    [[theValue(geofenceUpdateCount) should] equal:theValue(1)];
                    [PCFPush load]; // Reset the state in the state engine

                    [PCFPush registerForPCFPushNotificationsWithDeviceToken:helper.apnsDeviceToken tags:helper.tags1 deviceAlias:TEST_DEVICE_ALIAS areGeofencesEnabled:YES success:successBlock failure:failureBlock];
                    [[theValue(registrationRequestCount) should] equal:theValue(1)]; // Shows that the second registration request was a no-op
                    [[theValue(geofenceUpdateCount) should] equal:theValue(1)];
                    [[theValue(wasSuccessBlockExecuted) should] beYes];
                    [[theValue(wasFailBlockExecuted) should] beNo];
                });

                it(@"when geofences were never updated (and the geofence update fails)", ^{

                    [helper setupSuccessfulAsyncRegistrationRequestWithBlock:^(NSURLRequest *request) {
                        registrationRequestCount += 1;
                    }];

                    [helper setupGeofencesForFailedUpdateWithBlock:^(NSArray *array) {
                        geofenceUpdateCount += 1;
                    }];

                    [PCFPush load];
                    [helper setupDefaultPLIST];

                    [PCFPush registerForPCFPushNotificationsWithDeviceToken:helper.apnsDeviceToken tags:helper.tags1 deviceAlias:TEST_DEVICE_ALIAS areGeofencesEnabled:YES success:nil failure:failureBlock];
                    [[theValue(wasFailBlockExecuted) should] beYes];
                    [[theValue(registrationRequestCount) should] equal:theValue(1)];
                    [[theValue(geofenceUpdateCount) should] equal:theValue(1)];
                    wasFailBlockExecuted = NO;
                    [PCFPush load]; // Reset the state in the state engine

                    [PCFPush registerForPCFPushNotificationsWithDeviceToken:helper.apnsDeviceToken tags:helper.tags1 deviceAlias:TEST_DEVICE_ALIAS areGeofencesEnabled:YES success:nil failure:failureBlock];
                    [[theValue(wasFailBlockExecuted) should] beYes];
                    [[theValue(registrationRequestCount) should] equal:theValue(1)]; // Shows that the second registration request was a no-op
                    [[theValue(geofenceUpdateCount) should] equal:theValue(2)];

                    [PCFPush load]; // Reset the state in the state engine
                    [helper setupGeofencesForSuccessfulUpdateWithLastModifiedTime:777L withBlock:^(NSArray *array) {
                        geofenceUpdateCount += 1;
                    }];
                    [PCFPush registerForPCFPushNotificationsWithDeviceToken:helper.apnsDeviceToken tags:helper.tags1 deviceAlias:TEST_DEVICE_ALIAS areGeofencesEnabled:YES success:successBlock failure:nil];
                    [[theValue(wasSuccessBlockExecuted) should] beYes];
                    [[theValue(registrationRequestCount) should] equal:theValue(1)]; // Shows that the third registration request was a no-op
                    [[theValue(geofenceUpdateCount) should] equal:theValue(3)];
                });
            });
        });

        context(@"geofences disabled", ^{

            it(@"should make a POST request to the server", ^{

                __block BOOL wasSuccessBlockExecuted = NO;
                __block NSSet<NSString*> *expectedTags = helper.tags1;

                [helper setupGeofencesForSuccessfulUpdateWithLastModifiedTime:999L withBlock:^void(NSArray *params) {
                    int64_t timestamp = [params[2] longLongValue];
                    [[theValue(timestamp) should] beZero];
                }];

                [[PCFPushGeofenceUpdater shouldNot] receive:@selector(startGeofenceUpdate:userInfo:timestamp:tags:success:failure:)];
                [[PCFPushGeofenceUpdater shouldNot] receive:@selector(clearAllGeofences:)];

                [[NSURLConnection should] receive:@selector(pcfPushSendAsynchronousRequestWrapper:queue:completionHandler:) withCount:1];

                [helper setupSuccessfulAsyncRegistrationRequestWithBlock:^(NSURLRequest *request) {

                    [[request.HTTPMethod should] equal:@"POST"];

                    NSError *error;
                    PCFPushRegistrationPostRequestData *requestBody = [PCFPushRegistrationPostRequestData pcfPushFromJSONData:request.HTTPBody error:&error];
                    [[error should] beNil];
                    [[requestBody shouldNot] beNil];
                    [[[NSSet<NSString*> setWithArray:requestBody.tags] should] equal:expectedTags];
                }];

                [helper setupDefaultPLIST];

                void (^successBlock)() = ^{
                    wasSuccessBlockExecuted = YES;
                };

                void (^failureBlock)(NSError *) = ^(NSError *error) {
                    fail(@"registration failure block executed");
                };

                [PCFPush registerForPCFPushNotificationsWithDeviceToken:helper.apnsDeviceToken tags:helper.tags1 deviceAlias:TEST_DEVICE_ALIAS areGeofencesEnabled:NO success:successBlock failure:failureBlock];

                [[theValue(wasSuccessBlockExecuted) should] beTrue];

                [[[PCFPush deviceUuid] should] equal:TEST_DEVICE_UUID];
                [[theValue([PCFPushPersistentStorage areGeofencesEnabled]) should] beNo];
            });

            it(@"should bypass registering against Remote Push Server if Device Token matches the stored token.", ^{

                __block NSInteger registrationRequestCount = 0;
                __block BOOL wasSuccessBlockExecuted = NO;

                void (^successBlock)() = ^{
                    wasSuccessBlockExecuted = YES;
                };

                void (^failureBlock)(NSError *) = ^(NSError *error) {
                    fail(@"should not have failed");
                };

                [helper setupSuccessfulAsyncRegistrationRequestWithBlock:^(NSURLRequest *request) {
                    registrationRequestCount += 1;
                }];

                [[PCFPushGeofenceUpdater shouldNot] receive:@selector(startGeofenceUpdate:userInfo:timestamp:tags:success:failure:)];
                [[PCFPushGeofenceUpdater shouldNot] receive:@selector(clearAllGeofences:)];

                [PCFPush load];

                [helper setupDefaultPLIST];

                [PCFPush registerForPCFPushNotificationsWithDeviceToken:helper.apnsDeviceToken tags:helper.tags1 deviceAlias:TEST_DEVICE_ALIAS areGeofencesEnabled:NO success:nil failure:failureBlock];
                [[theValue(registrationRequestCount) should] equal:theValue(1)];
                [[[PCFPush deviceUuid] should] equal:TEST_DEVICE_UUID];
                [PCFPush load]; // Reset the state in the state engine

                [PCFPush registerForPCFPushNotificationsWithDeviceToken:helper.apnsDeviceToken tags:helper.tags1 deviceAlias:TEST_DEVICE_ALIAS areGeofencesEnabled:NO success:successBlock failure:failureBlock];

                [[theValue(registrationRequestCount) should] equal:theValue(1)];
                [[theValue(wasSuccessBlockExecuted) should] beYes];
                [[[PCFPush deviceUuid] should] equal:TEST_DEVICE_UUID];
                [[theValue([PCFPushPersistentStorage areGeofencesEnabled]) should] beNo];
            });
        });
    });

    describe(@"handling various server responses", ^{
        __block BOOL wasExpectedResult = NO;

        beforeEach(^{
            wasExpectedResult = NO;
            [PCFPushAnalytics stub:@selector(isAnalyticsPollingTime:) andReturn:theValue(NO)];
        });

        afterEach(^{
            [[theValue(wasExpectedResult) should] beTrue];
        });

        it(@"should handle an HTTP status error", ^{
            [NSURLConnection stub:@selector(pcfPushSendAsynchronousRequestWrapper:queue:completionHandler:) withBlock:^id(NSArray *params) {
                NSHTTPURLResponse *newResponse = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@""]  statusCode:400 HTTPVersion:nil headerFields:nil];
                CompletionHandler handler = params[2];
                handler(newResponse, nil, nil);
                return nil;
            }];

            [PCFPushClient sendRegisterRequestWithParameters:helper.params
                                                 deviceToken:helper.apnsDeviceToken
                                                     success:^{
                                                         wasExpectedResult = NO;
                                                     }
                                                     failure:^(NSError *error) {
                                                         [[error.domain should] equal:PCFPushErrorDomain];
                                                         [[theValue(error.code) should] equal:theValue(PCFPushBackEndConnectionFailedHTTPStatusCode)];
                                                         [[[PCFPush deviceUuid] should] beNil];
                                                         wasExpectedResult = YES;
                                                     }];
        });

        it(@"should handle a successful response with empty data", ^{
            [NSURLConnection stub:@selector(pcfPushSendAsynchronousRequestWrapper:queue:completionHandler:) withBlock:^id(NSArray *params) {
                NSHTTPURLResponse *newResponse = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@""]  statusCode:200 HTTPVersion:nil headerFields:nil];
                NSData *newData = [NSData data];
                CompletionHandler handler = params[2];
                handler(newResponse, newData, nil);
                return nil;
            }];

            [PCFPushClient sendRegisterRequestWithParameters:helper.params
                                                 deviceToken:helper.apnsDeviceToken
                                                     success:^{
                                                         wasExpectedResult = NO;
                                                     }
                                                     failure:^(NSError *error) {
                                                         [[error.domain should] equal:PCFPushErrorDomain];
                                                         [[theValue(error.code) should] equal:theValue(PCFPushBackEndRegistrationEmptyResponseData)];
                                                         [[[PCFPush deviceUuid] should] beNil];
                                                         wasExpectedResult = YES;
                                                     }];
        });

        it(@"should handle a successful response with nil data", ^{
            [NSURLConnection stub:@selector(pcfPushSendAsynchronousRequestWrapper:queue:completionHandler:) withBlock:^id(NSArray *params) {
                NSHTTPURLResponse *newResponse = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@""]  statusCode:200 HTTPVersion:nil headerFields:nil];
                CompletionHandler handler = params[2];
                handler(newResponse, nil, nil);
                return nil;
            }];

            [PCFPushClient sendRegisterRequestWithParameters:helper.params
                                                 deviceToken:helper.apnsDeviceToken
                                                     success:^{
                                                         wasExpectedResult = NO;
                                                     }
                                                     failure:^(NSError *error) {
                                                         [[error.domain should] equal:PCFPushErrorDomain];
                                                         [[theValue(error.code) should] equal:theValue(PCFPushBackEndRegistrationEmptyResponseData)];
                                                         [[[PCFPush deviceUuid] should] beNil];
                                                         wasExpectedResult = YES;
                                                     }];
        });

        it(@"should handle a successful response with zero-length", ^{
            [NSURLConnection stub:@selector(pcfPushSendAsynchronousRequestWrapper:queue:completionHandler:) withBlock:^id(NSArray *params) {
                NSHTTPURLResponse *newResponse = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@""]  statusCode:200 HTTPVersion:nil headerFields:nil];
                NSData *newData = [@"" dataUsingEncoding:NSUTF8StringEncoding];
                CompletionHandler handler = params[2];
                handler(newResponse, newData, nil);
                return nil;
            }];

            [PCFPushClient sendRegisterRequestWithParameters:helper.params
                                                 deviceToken:helper.apnsDeviceToken
                                                     success:^{
                                                         wasExpectedResult = NO;
                                                     }
                                                     failure:^(NSError *error) {
                                                         [[error.domain should] equal:PCFPushErrorDomain];
                                                         [[theValue(error.code) should] equal:theValue(PCFPushBackEndRegistrationEmptyResponseData)];
                                                         [[[PCFPush deviceUuid] should] beNil];
                                                         wasExpectedResult = YES;
                                                     }];
        });

        it(@"should handle a successful response that contains unparseable text", ^{
            [NSURLConnection stub:@selector(pcfPushSendAsynchronousRequestWrapper:queue:completionHandler:) withBlock:^id(NSArray *params) {
                NSHTTPURLResponse *newResponse = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@""]  statusCode:200 HTTPVersion:nil headerFields:nil];
                NSData *newData = [@"This is not JSON" dataUsingEncoding:NSUTF8StringEncoding];
                CompletionHandler handler = params[2];
                handler(newResponse, newData, nil);
                return nil;
            }];

            [PCFPushClient sendRegisterRequestWithParameters:helper.params
                                                 deviceToken:helper.apnsDeviceToken
                                                     success:^{
                                                         wasExpectedResult = NO;
                                                     }
                                                     failure:^(NSError *error) {
                                                         [[error shouldNot] beNil];
                                                         [[[PCFPush deviceUuid] should] beNil];
                                                         wasExpectedResult = YES;
                                                     }];
        });

        it(@"should require a device_uuid in the server response", ^{
            [NSURLConnection stub:@selector(pcfPushSendAsynchronousRequestWrapper:queue:completionHandler:) withBlock:^id(NSArray *params) {
                NSHTTPURLResponse *newResponse = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@""]  statusCode:200 HTTPVersion:nil headerFields:nil];
                NSDictionary *newJSON = @{@"os" : @"AmigaOS"};
                NSError *error;
                NSData *newData = [NSJSONSerialization dataWithJSONObject:newJSON options:NSJSONWritingPrettyPrinted error:&error];
                CompletionHandler handler = params[2];
                handler(newResponse, newData, nil);
                return nil;
            }];

            [PCFPushClient sendRegisterRequestWithParameters:helper.params
                                                 deviceToken:helper.apnsDeviceToken
                                                     success:^{
                                                         wasExpectedResult = NO;
                                                     }
                                                     failure:^(NSError *error) {
                                                         wasExpectedResult = YES;
                                                         [[error.domain should] equal:PCFPushErrorDomain];
                                                         [[theValue(error.code) should] equal:theValue(PCFPushBackEndRegistrationResponseDataNoDeviceUuid)];
                                                         [[[PCFPush deviceUuid] should] beNil];
                                                     }];
        });
    });

    describe(@"unregistration", ^{

        beforeEach(^{
            [PCFPushAnalytics stub:@selector(isAnalyticsPollingTime:) andReturn:theValue(NO)];
        });

        describe(@"successful unregistration from push server", ^{

            __block BOOL successBlockExecuted = NO;

            beforeEach(^{
                successBlockExecuted = NO;
                [helper setupDefaultPersistedParameters];
                [PCFPushPersistentStorage setAreGeofencesEnabled:YES];
                [PCFPushPersistentStorage setGeofenceLastModifiedTime:1337L];
            });

            afterEach(^{
                [[[PCFPushPersistentStorage APNSDeviceToken] should] beNil];
                [[[PCFPushPersistentStorage serverDeviceID] should] beNil];
                [[[PCFPushPersistentStorage variantUUID] should] beNil];
                [[[PCFPushPersistentStorage deviceAlias] should] beNil];
                [[[PCFPush deviceUuid] should] beNil];
            });

            context(@"when not already registered", ^{

                beforeEach(^{
                    [PCFPushPersistentStorage setServerDeviceID:nil];
                });

                it(@"should be considered a success if the device isn't currently registered", ^{
                    [[PCFPushGeofenceUpdater should] receive:@selector(clearAllGeofences:)];

                    [[[PCFPushPersistentStorage serverDeviceID] should] beNil];
                    [[NSURLConnection shouldNot] receive:@selector(sendAsynchronousRequest:queue:completionHandler:)];

                    [PCFPush unregisterFromPCFPushNotificationsWithSuccess:^{
                        successBlockExecuted = YES;

                    }                                              failure:^(NSError *error) {
                        fail(@"unregistration failure block executed");
                    }];

                    [[theValue(successBlockExecuted) should] beTrue];
                    [[theValue([PCFPushPersistentStorage areGeofencesEnabled]) should] beNo];
                });
            });

            context(@"when already registered", ^{

                it(@"should succesfully unregister if the device has a persisted backEndDeviceUUID and should remove all persisted parameters when unregister is successful", ^{

                    [helper setupSuccessfulDeleteAsyncRequestAndReturnStatus:204];

                    [[PCFPushGeofenceUpdater should] receive:@selector(clearAllGeofences:)];
                    [[[PCFPushPersistentStorage serverDeviceID] shouldNot] beNil];
                    [[NSURLConnection should] receive:@selector(pcfPushSendAsynchronousRequestWrapper:queue:completionHandler:)];

                    [PCFPush unregisterFromPCFPushNotificationsWithSuccess:^{
                        successBlockExecuted = YES;

                    }                                              failure:^(NSError *error) {
                        fail(@"unregistration failure block executed");
                    }];

                    [[theValue(successBlockExecuted) should] beTrue];
                    [[theValue([PCFPushPersistentStorage areGeofencesEnabled]) should] beNo];
                });
            });
        });

        describe(@"unsuccessful unregistration when device not registered on push server", ^{

            __block BOOL failureBlockExecuted = NO;

            beforeEach(^{
                [PCFPushPersistentStorage setAreGeofencesEnabled:YES];
                [PCFPushPersistentStorage setGeofenceLastModifiedTime:1337L];
            });

            it(@"should perform failure block if server responds with a 404 (DeviceUUID not registered on server) ", ^{

                [helper setupDefaultPersistedParameters];
                [helper setupSuccessfulDeleteAsyncRequestAndReturnStatus:404];

                [[PCFPushGeofenceUpdater should] receive:@selector(clearAllGeofences:)];
                [[[PCFPushPersistentStorage serverDeviceID] shouldNot] beNil];
                [[[PCFPush deviceUuid] shouldNot] beNil];
                [[NSURLConnection should] receive:@selector(pcfPushSendAsynchronousRequestWrapper:queue:completionHandler:)];

                [PCFPush unregisterFromPCFPushNotificationsWithSuccess:^{
                    fail(@"unregistration success block executed");

                } failure:^(NSError *error) {
                    // TODO - should we consider a 404 from the server to be a success and continue to delete the registration from the location device anyways?
                    failureBlockExecuted = YES;
                    [[[PCFPush deviceUuid] shouldNot] beNil];
                }];

                [[theValue(failureBlockExecuted) should] beTrue];
                [[theValue([PCFPushPersistentStorage areGeofencesEnabled]) should] beNo];
            });
        });

        describe(@"unsuccessful unregistration", ^{

            __block BOOL failureBlockExecuted = NO;

            beforeEach(^{
                [PCFPushPersistentStorage setAreGeofencesEnabled:YES];
                [PCFPushPersistentStorage setGeofenceLastModifiedTime:1337L];
            });

            it(@"should perform failure block if server request returns error", ^{
                [helper setupDefaultPersistedParameters];
                failureBlockExecuted = NO;

                [[[PCFPush deviceUuid] shouldNot] beNil];
                [[PCFPushGeofenceUpdater should] receive:@selector(clearAllGeofences:)];
                [NSURLConnection stub:@selector(pcfPushSendAsynchronousRequestWrapper:queue:completionHandler:) withBlock:^id(NSArray *params) {
                    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:nil];
                    CompletionHandler handler = params[2];
                    handler(nil, nil, error);
                    return nil;
                }];

                [[NSURLConnection should] receive:@selector(pcfPushSendAsynchronousRequestWrapper:queue:completionHandler:)];

                [PCFPush unregisterFromPCFPushNotificationsWithSuccess:^{
                    fail(@"unregistration success block executed incorrectly");

                } failure:^(NSError *error) {
                    failureBlockExecuted = YES;
                    [[[PCFPush deviceUuid] shouldNot] beNil];
                }];

                [[theValue(failureBlockExecuted) should] beTrue];
                [[theValue([PCFPushPersistentStorage areGeofencesEnabled]) should] beNo];
            });
        });

        describe(@"no geofences in the system during successful unregistration", ^{

            __block BOOL successBlockExecuted = NO;

            it(@"should not clear geofences during a unregistration", ^{
                [helper setupDefaultPersistedParameters];
                [helper setupSuccessfulDeleteAsyncRequestAndReturnStatus:204];

                [[NSURLConnection should] receive:@selector(pcfPushSendAsynchronousRequestWrapper:queue:completionHandler:)];

                [[[PCFPush deviceUuid] shouldNot] beNil];
                [[PCFPushGeofenceUpdater shouldNot] receive:@selector(clearAllGeofences:)];
                [[[PCFPushPersistentStorage serverDeviceID] shouldNot] beNil];

                [PCFPush unregisterFromPCFPushNotificationsWithSuccess:^{
                    successBlockExecuted = YES;
                    [[[PCFPush deviceUuid] should] beNil];
                } failure:^(NSError *error) {
                    fail(@"unregistration failure block executed");
                }];

                [[theValue(successBlockExecuted) should] beTrue];
                [[theValue([PCFPushPersistentStorage areGeofencesEnabled]) should] beNo];
            });
        });
    });

    describe(@"subscribing to tags", ^{

        beforeEach(^{
            [PCFPushAnalytics stub:@selector(isAnalyticsPollingTime:) andReturn:theValue(NO)];
        });

        describe(@"ensuring the device is registered", ^{

            beforeEach(^{
                [helper setupDefaultPersistedParameters];
            });

            it(@"should fail if not already registered at all", ^{
                [PCFPushPersistentStorage setAPNSDeviceToken:nil];
                [PCFPushPersistentStorage setServerDeviceID:nil];
            });

            it(@"should fail if not already registered with APNS", ^{
                [PCFPushPersistentStorage setAPNSDeviceToken:nil];
            });

            it(@"should fail if not already registered with CF", ^{
                [PCFPushPersistentStorage setServerDeviceID:nil];
            });

            afterEach(^{
                __block BOOL wasFailureBlockCalled = NO;
                [PCFPush subscribeToTags:helper.tags1 success:^{
                    fail(@"Should not have succeeded");
                }                failure:^(NSError *error) {
                    wasFailureBlockCalled = YES;
                }];

                [[theValue(wasFailureBlockCalled) should] beTrue];
            });
        });

        describe(@"successful attempts", ^{

            __block NSInteger updateRegistrationCount;
            __block NSSet<NSString*> *expectedSubscribeTags;
            __block NSSet<NSString*> *expectedUnsubscribeTags;
            __block BOOL wasExpectedBlockCalled;

            beforeEach(^{
                updateRegistrationCount = 0;
                expectedSubscribeTags = nil;
                expectedUnsubscribeTags = nil;
                wasExpectedBlockCalled = NO;

                [helper setupDefaultPersistedParameters];

                [helper setupSuccessfulAsyncRegistrationRequestWithBlock:^(NSURLRequest *request) {

                    [[request.HTTPMethod should] equal:@"PUT"];

                    updateRegistrationCount++;

                    NSError *error;
                    PCFPushRegistrationPutRequestData *requestBody = [PCFPushRegistrationPutRequestData pcfPushFromJSONData:request.HTTPBody error:&error];

                    [[error should] beNil];
                    [[requestBody shouldNot] beNil];

                    if (expectedSubscribeTags) {
                        [[[NSSet<NSString*> setWithArray:requestBody.subscribeTags] should] equal:expectedSubscribeTags];
                    } else {
                        [[requestBody.subscribeTags should] beNil];
                    }
                    if (expectedUnsubscribeTags) {
                        [[[NSSet<NSString*> setWithArray:requestBody.unsubscribeTags] should] equal:expectedUnsubscribeTags];
                    } else {
                        [[requestBody.unsubscribeTags should] beNil];
                    }
                }];
            });

            afterEach(^{
                [[theValue(wasExpectedBlockCalled) should] beTrue];
            });

            context(@"geofences enabled", ^{

                beforeEach(^{
                    [helper setupDefaultPLIST];
                });

                it(@"should be able to register to some new tags and then fetch geofences if there have been no geofence updates", ^{
                    expectedSubscribeTags = helper.tags2;
                    expectedUnsubscribeTags = helper.tags1;

                    [helper setupGeofencesForSuccessfulUpdateWithLastModifiedTime:1337L];
                    [PCFPushPersistentStorage setAreGeofencesEnabled:YES];
                    [[PCFPushGeofenceHandler shouldNot] receive:@selector(reregisterGeofencesWithEngine:subscribedTags:)];
                    [[PCFPushGeofenceUpdater should] receive:@selector(startGeofenceUpdate:userInfo:timestamp:tags:success:failure:) withCount:1];

                    [PCFPush subscribeToTags:helper.tags2 success:^{
                        wasExpectedBlockCalled = YES;
                    }                failure:^(NSError *error) {
                        fail(@"Should not have failed");
                    }];

                    [[[PCFPushPersistentStorage tags] should] equal:helper.tags2];
                    [[theValue(updateRegistrationCount) should] equal:theValue(1)];
                });

                it(@"should be able to register to some new tags and then stop if there have been some geofence updates in the past", ^{
                    expectedSubscribeTags = helper.tags2;
                    expectedUnsubscribeTags = helper.tags1;

                    [PCFPushPersistentStorage setGeofenceLastModifiedTime:8888L];
                    [PCFPushPersistentStorage setAreGeofencesEnabled:YES];
                    [[PCFPushGeofenceHandler should] receive:@selector(reregisterGeofencesWithEngine:subscribedTags:)];
                    [[PCFPushGeofenceUpdater shouldNot] receive:@selector(startGeofenceUpdate:userInfo:timestamp:tags:success:failure:)];

                    [PCFPush subscribeToTags:helper.tags2 success:^{
                        wasExpectedBlockCalled = YES;
                    }                failure:^(NSError *error) {
                        fail(@"Should not have failed");
                    }];

                    [[[PCFPushPersistentStorage tags] should] equal:helper.tags2];
                    [[theValue(updateRegistrationCount) should] equal:theValue(1)];
                });

                it(@"should not call the update API if provided the same tags (but then do a geofence update if required - but the geofence update fails)", ^{
                    [helper setupGeofencesForFailedUpdate];

                    [PCFPushPersistentStorage setAreGeofencesEnabled:YES];
                    [[PCFPushGeofenceHandler shouldNot] receive:@selector(reregisterGeofencesWithEngine:subscribedTags:)];
                    [[PCFPushGeofenceUpdater should] receive:@selector(startGeofenceUpdate:userInfo:timestamp:tags:success:failure:) withCount:1];

                    [PCFPush subscribeToTags:helper.tags1 success:^{
                        fail(@"Should not have succeeded");
                    }                failure:^(NSError *error) {
                        wasExpectedBlockCalled = YES;
                    }];

                    [[[PCFPushPersistentStorage tags] should] equal:helper.tags1];
                    [[theValue(updateRegistrationCount) should] equal:theValue(0)];
                });

                it(@"should be able to register to some new tags and then fetch geofences if there have been no geofence updates (but fail to fetch geofences)", ^{
                    expectedSubscribeTags = helper.tags2;
                    expectedUnsubscribeTags = helper.tags1;

                    [helper setupGeofencesForFailedUpdate];
                    [PCFPushPersistentStorage setAreGeofencesEnabled:YES];
                    [[PCFPushGeofenceHandler shouldNot] receive:@selector(reregisterGeofencesWithEngine:subscribedTags:)];
                    [[PCFPushGeofenceUpdater should] receive:@selector(startGeofenceUpdate:userInfo:timestamp:tags:success:failure:) withCount:1];

                    [PCFPush subscribeToTags:helper.tags2 success:^{
                        fail(@"should not have succedeed");
                    }                failure:^(NSError *error) {
                        wasExpectedBlockCalled = YES;
                    }];

                    [[[PCFPushPersistentStorage tags] should] equal:helper.tags2];
                    [[theValue(updateRegistrationCount) should] equal:theValue(1)];
                    [[theValue([PCFPushPersistentStorage areGeofencesEnabled]) should] beYes];
                });

                it(@"should not call the update API if provided the same tags (but then do a geofence update if required)", ^{
                    [helper setupGeofencesForSuccessfulUpdateWithLastModifiedTime:1337L];

                    [PCFPushPersistentStorage setAreGeofencesEnabled:YES];
                    [[PCFPushGeofenceHandler shouldNot] receive:@selector(reregisterGeofencesWithEngine:subscribedTags:)];
                    [[PCFPushGeofenceUpdater should] receive:@selector(startGeofenceUpdate:userInfo:timestamp:tags:success:failure:) withCount:1];

                    [PCFPush subscribeToTags:helper.tags1 success:^{
                        wasExpectedBlockCalled = YES;
                    }                failure:^(NSError *error) {
                        fail(@"Should not have failed");
                    }];

                    [[[PCFPushPersistentStorage tags] should] equal:helper.tags1];
                    [[theValue(updateRegistrationCount) should] equal:theValue(0)];
                });

                it(@"should not call the update API if provided the same tags (and then skip the geofence update if not required)", ^{
                    [PCFPushPersistentStorage setGeofenceLastModifiedTime:999L];

                    [[PCFPushGeofenceHandler shouldNot] receive:@selector(reregisterGeofencesWithEngine:subscribedTags:)];
                    [[PCFPushGeofenceUpdater shouldNot] receive:@selector(startGeofenceUpdate:userInfo:timestamp:tags:success:failure:)];

                    [PCFPush subscribeToTags:helper.tags1 success:^{
                        wasExpectedBlockCalled = YES;
                    }                failure:^(NSError *error) {
                        fail(@"Should not have failed");
                    }];

                    [[[PCFPushPersistentStorage tags] should] equal:helper.tags1];
                    [[theValue(updateRegistrationCount) should] equal:theValue(0)];
                });
            });

            context(@"geofences disabled", ^{

                beforeEach(^{
                    [PCFPushPersistentStorage setAreGeofencesEnabled:NO];
                    [helper setupDefaultPLIST];
                });

                afterEach(^{
                    [[theValue([PCFPushPersistentStorage lastGeofencesModifiedTime]) should] equal:theValue(PCF_NEVER_UPDATED_GEOFENCES)];
                });

                it(@"should be able to register to some new tags", ^{
                    expectedSubscribeTags = helper.tags2;
                    expectedUnsubscribeTags = helper.tags1;

                    [[PCFPushGeofenceHandler shouldNot] receive:@selector(reregisterGeofencesWithEngine:subscribedTags:)];
                    [[PCFPushGeofenceUpdater shouldNot] receive:@selector(startGeofenceUpdate:userInfo:timestamp:tags:success:failure:)];
                    [[PCFPushGeofenceUpdater shouldNot] receive:@selector(clearAllGeofences:)];

                    [PCFPush subscribeToTags:helper.tags2 success:^{
                        wasExpectedBlockCalled = YES;
                    }                failure:^(NSError *error) {
                        fail(@"Should not have failed");
                    }];

                    [[[PCFPushPersistentStorage tags] should] equal:helper.tags2];
                    [[theValue(updateRegistrationCount) should] equal:theValue(1)];
                });

                it(@"should be able to register to some new tags and then clear the currently monitored geofences", ^{
                    expectedSubscribeTags = helper.tags2;
                    expectedUnsubscribeTags = helper.tags1;

                    [PCFPushPersistentStorage setGeofenceLastModifiedTime:8888L];
                    [[PCFPushGeofenceHandler shouldNot] receive:@selector(reregisterGeofencesWithEngine:subscribedTags:)];
                    [[PCFPushGeofenceUpdater shouldNot] receive:@selector(startGeofenceUpdate:userInfo:timestamp:tags:success:failure:)];
                    [[PCFPushGeofenceUpdater should] receive:@selector(clearAllGeofences:)];
                    [PCFPushGeofenceUpdater stub:@selector(clearAllGeofences:) withBlock:^id(NSArray *params) {
                        [PCFPushPersistentStorage setGeofenceLastModifiedTime:PCF_NEVER_UPDATED_GEOFENCES];
                        return nil;
                    }];

                    [PCFPush subscribeToTags:helper.tags2 success:^{
                        wasExpectedBlockCalled = YES;
                    }                failure:^(NSError *error) {
                        fail(@"Should not have failed");
                    }];

                    [[[PCFPushPersistentStorage tags] should] equal:helper.tags2];
                    [[theValue(updateRegistrationCount) should] equal:theValue(1)];
                });

                it(@"should not call the update API if provided the same tags (i.e.: no-op)", ^{
                    [[PCFPushGeofenceHandler shouldNot] receive:@selector(reregisterGeofencesWithEngine:subscribedTags:)];
                    [[PCFPushGeofenceUpdater shouldNot] receive:@selector(startGeofenceUpdate:userInfo:timestamp:tags:success:failure:) withCount:1];
                    [[PCFPushGeofenceUpdater shouldNot] receive:@selector(clearAllGeofences:)];

                    [PCFPush subscribeToTags:helper.tags1 success:^{
                        wasExpectedBlockCalled = YES;
                    }                failure:^(NSError *error) {
                        fail(@"Should not have failed");
                    }];

                    [[[PCFPushPersistentStorage tags] should] equal:helper.tags1];
                    [[theValue(updateRegistrationCount) should] equal:theValue(0)];
                });

                it(@"should not call the update API if provided tags that differ only by case (i.e.: no-op)", ^{
                    [[PCFPushGeofenceHandler shouldNot] receive:@selector(reregisterGeofencesWithEngine:subscribedTags:)];
                    [[PCFPushGeofenceUpdater shouldNot] receive:@selector(startGeofenceUpdate:userInfo:timestamp:tags:success:failure:) withCount:1];
                    [[PCFPushGeofenceUpdater shouldNot] receive:@selector(clearAllGeofences:)];

                    NSMutableSet<NSString*> *uppercaseTags = [NSMutableSet<NSString*> setWithCapacity:helper.tags1.count];
                    for (NSString *tag in helper.tags1) {
                        [uppercaseTags addObject:[tag uppercaseString]];
                    }

                    [PCFPush subscribeToTags:uppercaseTags success:^{
                        wasExpectedBlockCalled = YES;
                    }                failure:^(NSError *error) {
                        fail(@"Should not have failed");
                    }];

                    [[[PCFPushPersistentStorage tags] should] equal:helper.tags1];
                    [[theValue(updateRegistrationCount) should] equal:theValue(0)];
                });

                it(@"should not call the update API if provided the same tags (and then clear the geofences)", ^{
                    [PCFPushPersistentStorage setGeofenceLastModifiedTime:999L];

                    [[PCFPushGeofenceHandler shouldNot] receive:@selector(reregisterGeofencesWithEngine:subscribedTags:)];
                    [[PCFPushGeofenceUpdater shouldNot] receive:@selector(startGeofenceUpdate:userInfo:timestamp:tags:success:failure:)];
                    [[PCFPushGeofenceUpdater should] receive:@selector(clearAllGeofences:)];
                    [PCFPushGeofenceUpdater stub:@selector(clearAllGeofences:) withBlock:^id(NSArray *params) {
                        [PCFPushPersistentStorage setGeofenceLastModifiedTime:PCF_NEVER_UPDATED_GEOFENCES];
                        return nil;
                    }];

                    [PCFPush subscribeToTags:helper.tags1 success:^{
                        wasExpectedBlockCalled = YES;
                    }                failure:^(NSError *error) {
                        fail(@"Should not have failed");
                    }];

                    [[[PCFPushPersistentStorage tags] should] equal:helper.tags1];
                    [[theValue(updateRegistrationCount) should] equal:theValue(0)];
                });
            });
        });

        describe(@"unsuccessful attempts", ^{

            __block BOOL wasFailBlockCalled;
            __block BOOL wasRequestCalled;

            beforeEach(^{
                [helper setupDefaultPersistedParameters];
                [helper setupDefaultPLIST];
                wasFailBlockCalled = NO;
                wasRequestCalled = NO;
            });

            afterEach(^{
                [[theValue(wasFailBlockCalled) should] beTrue];
                [[theValue(wasRequestCalled) should] beTrue];
            });

            it(@"Should fail correctly if there is a network error", ^{
                [helper setupAsyncRequestWithBlock:^(NSURLRequest *request, NSURLResponse **resultResponse, NSData **resultData, NSError **resultError) {

                    *resultResponse = nil;
                    *resultError = [[NSError alloc] initWithDomain:NSURLErrorDomain code:NSURLErrorSecureConnectionFailed userInfo:nil];
                    *resultData = nil;
                    wasRequestCalled = YES;
                }];

                [[PCFPushGeofenceHandler shouldNot] receive:@selector(reregisterGeofencesWithEngine:subscribedTags:)];
                [[PCFPushGeofenceUpdater shouldNot] receive:@selector(startGeofenceUpdate:userInfo:timestamp:tags:success:failure:)];

                [PCFPush subscribeToTags:helper.tags2 success:^{
                    fail(@"should not have succeeded");
                }                failure:^(NSError *error) {
                    [[error.domain should] equal:NSURLErrorDomain];
                    wasFailBlockCalled = YES;
                }];
            });

            it(@"Should fail correctly if the response data is bad", ^{
                [helper setupAsyncRequestWithBlock:^(NSURLRequest *request, NSURLResponse **resultResponse, NSData **resultData, NSError **resultError) {

                    *resultResponse = [[NSHTTPURLResponse alloc] initWithURL:request.URL statusCode:200 HTTPVersion:@"1.1" headerFields:nil];
                    *resultError = nil;
                    *resultData = [NSData data];
                    wasRequestCalled = YES;
                }];

                [[PCFPushGeofenceHandler shouldNot] receive:@selector(reregisterGeofencesWithEngine:subscribedTags:)];
                [[PCFPushGeofenceUpdater shouldNot] receive:@selector(startGeofenceUpdate:userInfo:timestamp:tags:success:failure:)];

                [PCFPush subscribeToTags:helper.tags2 success:^{
                    fail(@"should not have succeeded");
                }                failure:^(NSError *error) {
                    [[error.domain should] equal:PCFPushErrorDomain];
                    wasFailBlockCalled = YES;
                }];
            });
        });
    });

    describe(@"handling remote notifications", ^{

        __block BOOL wasCompletionHandlerCalled;

        NSDictionary *const userInfo = @{ @"aps" : @{ @"content-available" : @1 }, @"pivotal.push.geofence_update_available" : @"true" };

        beforeEach(^{
            wasCompletionHandlerCalled = NO;
        });

        context(@"processing geofence updates", ^{

            beforeEach(^{
                [PCFPushPersistentStorage setAreGeofencesEnabled:YES];
                [helper setupDefaultPLIST];
            });

            afterEach(^{
                [[theValue(wasCompletionHandlerCalled) should] beYes];
            });

            it(@"should process geofence updates with some data available on server", ^{

                [PCFPushGeofenceUpdater stub:@selector(startGeofenceUpdate:userInfo:timestamp:tags:success:failure:) withBlock:^id(NSArray *params) {
                    NSDictionary *actualUserInfo = params[1];
                    [[actualUserInfo should] equal:userInfo];
                    void (^successBlock)(void) = params[4];
                    if (successBlock) {
                        successBlock();
                    }
                    return nil;
                }];

                [PCFPush didReceiveRemoteNotification:userInfo completionHandler:^(BOOL wasIgnored, UIBackgroundFetchResult fetchResult, NSError *error) {
                    [[theValue(wasIgnored) should] beNo];
                    [[theValue(fetchResult) should] equal:theValue(UIBackgroundFetchResultNewData)];
                    [[error should] beNil];
                    wasCompletionHandlerCalled = YES;
                }];
            });

            it(@"should handle server errors in geofence updates", ^{

                [PCFPushGeofenceUpdater stub:@selector(startGeofenceUpdate:userInfo:timestamp:tags:success:failure:) withBlock:^id(NSArray *params) {
                    NSDictionary *actualUserInfo = params[1];
                    [[actualUserInfo should] equal:userInfo];
                    void (^failureBlock)(NSError *) = params[5];
                    if (failureBlock) {
                        failureBlock([NSError errorWithDomain:@"FAKE ERROR" code:0 userInfo:nil]);
                    }
                    return nil;
                }];

                [PCFPush didReceiveRemoteNotification:userInfo completionHandler:^(BOOL wasIgnored, UIBackgroundFetchResult fetchResult, NSError *error) {
                    [[theValue(wasIgnored) should] beNo];
                    [[theValue(fetchResult) should] equal:theValue(UIBackgroundFetchResultFailed)];
                    [[error shouldNot] beNil];
                    wasCompletionHandlerCalled = YES;
                }];
            });
        });

        context(@"geofences are disabled", ^{

            afterEach(^{
                [[theValue(wasCompletionHandlerCalled) should] beYes];
            });

            it(@"should process geofence updates with some data available on server", ^{

                [PCFPushPersistentStorage setAreGeofencesEnabled:NO];
                [helper setupDefaultPLIST];

                [[PCFPushGeofenceUpdater shouldNot] receive:@selector(startGeofenceUpdate:userInfo:timestamp:tags:success:failure:)];

                [PCFPush didReceiveRemoteNotification:userInfo completionHandler:^(BOOL wasIgnored, UIBackgroundFetchResult fetchResult, NSError *error) {
                    [[theValue(wasIgnored) should] beYes];
                    [[theValue(fetchResult) should] equal:theValue(UIBackgroundFetchResultNoData)];
                    [[error should] beNil];
                    wasCompletionHandlerCalled = YES;
                }];
            });
        });

        context(@"other kinds of messages", ^{

            beforeEach(^{
                [helper setupDefaultPLIST];
            });

            afterEach(^{
                [[theValue(wasCompletionHandlerCalled) should] beYes];
            });

            it(@"should ignore notifications with nil data", ^{
                [[PCFPushAnalytics shouldNot] receive:@selector(logReceivedRemoteNotification:parameters:)];
                [[PCFPushAnalytics shouldNot] receive:@selector(sendEventsWithParameters:)];
                [PCFPush didReceiveRemoteNotification:nil completionHandler:^(BOOL wasIgnored, UIBackgroundFetchResult fetchResult, NSError *error) {
                    [[theValue(wasIgnored) should] beYes];
                    [[theValue(fetchResult) should] equal:theValue(UIBackgroundFetchResultNoData)];
                    [[error should] beNil];
                    wasCompletionHandlerCalled = YES;
                }];
            });

            it(@"should ignore notification when the user data is empty", ^{
                [[PCFPushAnalytics shouldNot] receive:@selector(logReceivedRemoteNotification:parameters:)];
                [[PCFPushAnalytics shouldNot] receive:@selector(sendEventsWithParameters:)];
                [PCFPush didReceiveRemoteNotification:@{} completionHandler:^(BOOL wasIgnored, UIBackgroundFetchResult fetchResult, NSError *error) {
                    [[theValue(wasIgnored) should] beYes];
                    [[theValue(fetchResult) should] equal:theValue(UIBackgroundFetchResultNoData)];
                    [[error should] beNil];
                    wasCompletionHandlerCalled = YES;
                }];
            });

            it(@"should ignore notification when it's some regular push message (not a background fetch)", ^{
                [[PCFPushAnalytics shouldNot] receive:@selector(logReceivedRemoteNotification:parameters:)];
                [[PCFPushAnalytics shouldNot] receive:@selector(sendEventsWithParameters:)];
                [PCFPush didReceiveRemoteNotification:@{ @"aps" : @{ @"alert" : @"some message" } }  completionHandler:^(BOOL wasIgnored, UIBackgroundFetchResult fetchResult, NSError *error) {
                    [[theValue(wasIgnored) should] beYes];
                    [[theValue(fetchResult) should] equal:theValue(UIBackgroundFetchResultNoData)];
                    [[error should] beNil];
                    wasCompletionHandlerCalled = YES;
                }];
            });

            it(@"should ignore background notifications that are not for us", ^{
                [[PCFPushAnalytics shouldNot] receive:@selector(logReceivedRemoteNotification:parameters:)];
                [[PCFPushAnalytics shouldNot] receive:@selector(sendEventsWithParameters:)];
                [PCFPush didReceiveRemoteNotification:@{ @"aps" : @{ @"content-available" : @1 } }  completionHandler:^(BOOL wasIgnored, UIBackgroundFetchResult fetchResult, NSError *error) {
                    [[theValue(wasIgnored) should] beYes];
                    [[theValue(fetchResult) should] equal:theValue(UIBackgroundFetchResultNoData)];
                    [[error should] beNil];
                    wasCompletionHandlerCalled = YES;
                }];
            });

            context(@"analytics", ^{

                beforeEach(^{
                    [helper setupAnalyticsStorage];
                });

                afterEach(^{
                    [helper resetAnalyticsStorage];
                });

                it(@"should log analytics events for receiving notifications in the background", ^{
                    [PCFPushApplicationUtil stub:@selector(applicationState) andReturn:theValue(UIApplicationStateBackground)];
                    [[PCFPushAnalytics should] receive:@selector(logReceivedRemoteNotification:parameters:)];
                    [[PCFPushAnalytics should] receive:@selector(sendEventsWithParameters:)];
                    [PCFPush didReceiveRemoteNotification:@{ @"aps" : @{ @"content-available" : @1 }, @"receiptId":@"TEST_RECEIPT_ID" }  completionHandler:^(BOOL wasIgnored, UIBackgroundFetchResult fetchResult, NSError *error) {
                        [[theValue(wasIgnored) should] beYes];
                        [[theValue(fetchResult) should] equal:theValue(UIBackgroundFetchResultNoData)];
                        [[error should] beNil];
                        wasCompletionHandlerCalled = YES;
                    }];
                });

                it(@"should log analytics events for receiving notifications in the foreground", ^{
                    [PCFPushApplicationUtil stub:@selector(applicationState) andReturn:theValue(UIApplicationStateActive)];
                    [[PCFPushAnalytics should] receive:@selector(logReceivedRemoteNotification:parameters:)];
                    [[PCFPushAnalytics should] receive:@selector(sendEventsWithParameters:)];
                    [PCFPush didReceiveRemoteNotification:@{ @"aps" : @{ @"content-available" : @1 }, @"receiptId":@"TEST_RECEIPT_ID" }  completionHandler:^(BOOL wasIgnored, UIBackgroundFetchResult fetchResult, NSError *error) {
                        [[theValue(wasIgnored) should] beYes];
                        [[theValue(fetchResult) should] equal:theValue(UIBackgroundFetchResultNoData)];
                        [[error should] beNil];
                        wasCompletionHandlerCalled = YES;
                    }];
                });

                it(@"should log analytics events for opening notifications that have been previously received", ^{
                    [PCFPushPersistentStorage setServerDeviceID:@"MY_DEVICE_UUID"];
                    [PCFPushPersistentStorage setServerVersion:@"1.3.2"];
                    [PCFPushApplicationUtil stub:@selector(applicationState) andReturn:theValue(UIApplicationStateInactive)];
                    [PCFPushAnalytics logReceivedRemoteNotification:@"TEST_RECEIPT_ID" parameters:helper.params];
                    [[PCFPushAnalytics should] receive:@selector(logOpenedRemoteNotification:parameters:)];
                    [[PCFPushAnalytics shouldNot] receive:@selector(logReceivedRemoteNotification:parameters:)];
                    [[PCFPushAnalytics should] receive:@selector(sendEventsWithParameters:)];
                    [PCFPush didReceiveRemoteNotification:@{ @"aps" : @{ @"content-available" : @1 }, @"receiptId":@"TEST_RECEIPT_ID" }  completionHandler:^(BOOL wasIgnored, UIBackgroundFetchResult fetchResult, NSError *error) {
                        [[theValue(wasIgnored) should] beYes];
                        [[theValue(fetchResult) should] equal:theValue(UIBackgroundFetchResultNoData)];
                        [[error should] beNil];
                        wasCompletionHandlerCalled = YES;
                    }];
                });

                it(@"should log analytics events for opening notifications that have not been previously received", ^{
                    [PCFPushApplicationUtil stub:@selector(applicationState) andReturn:theValue(UIApplicationStateInactive)];
                    [[PCFPushAnalytics should] receive:@selector(logReceivedRemoteNotification:parameters:)];
                    [[PCFPushAnalytics should] receive:@selector(logOpenedRemoteNotification:parameters:)];
                    [[PCFPushAnalytics should] receive:@selector(sendEventsWithParameters:)];
                    [PCFPush didReceiveRemoteNotification:@{ @"aps" : @{ @"content-available" : @1 }, @"receiptId":@"TEST_RECEIPT_ID" }  completionHandler:^(BOOL wasIgnored, UIBackgroundFetchResult fetchResult, NSError *error) {
                        [[theValue(wasIgnored) should] beYes];
                        [[theValue(fetchResult) should] equal:theValue(UIBackgroundFetchResultNoData)];
                        [[error should] beNil];
                        wasCompletionHandlerCalled = YES;
                    }];
                });

                it(@"should log a heartbeat analytics event when a heartbeat notification is received", ^{
                    [[PCFPushAnalytics should] receive:@selector(logReceivedHeartbeat:parameters:)];
                    [[PCFPushAnalytics should] receive:@selector(sendEventsWithParameters:)];
                    [PCFPush didReceiveRemoteNotification:@{ @"aps" : @{ @"content-available" : @1}, @"receiptId":@"TEST_RECEIPT_ID", @"pcf.push.heartbeat.sentToDeviceAt":@123456789 } completionHandler:^(BOOL wasIgnored, UIBackgroundFetchResult fetchResult, NSError *error) {
                        [[theValue(wasIgnored) should] beYes];
                        [[theValue(fetchResult) should] equal:theValue(UIBackgroundFetchResultNoData)];
                        [[error should] beNil];
                        wasCompletionHandlerCalled = YES;
                    }];
                });

            });
        });

        context(@"failed completion handler", ^{
            it(@"should throw an exception if a handler is not provided", ^{
                [[theBlock(^{
                    [PCFPush didReceiveRemoteNotification:@{} completionHandler:nil];
                }) should] raiseWithName:NSInvalidArgumentException];
            });
        });
    });

    describe(@"geofence events", ^{

        __block CLRegion *region;
        __block CLLocationManager *locationManager;

        beforeEach(^{
            region = [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake(33.0, 44.0) radius:100.0 identifier:@"PCF_3_66"];
            locationManager = [CLLocationManager mock];
            NSSet *monitoredRegions = [NSSet setWithObject:region];
            [locationManager stub:@selector(monitoredRegions) andReturn:monitoredRegions];
        });

        context(@"geofences enabled", ^{

            beforeEach(^{
                [PCFPushPersistentStorage setAreGeofencesEnabled:YES];
                [helper setupDefaultPLIST];
            });

            it(@"should process geofence on exiting region", ^{
                [[PCFPushGeofenceHandler should] receive:@selector(processRegion:store:engine:state:parameters:)];
                [[PCFPushClient shared] locationManager:locationManager didExitRegion:region];
            });

            it(@"should process geofence inside region", ^{
                [[PCFPushGeofenceHandler should] receive:@selector(processRegion:store:engine:state:parameters:)];
                [[PCFPushClient shared] locationManager:locationManager didDetermineState:CLRegionStateInside forRegion:region];
            });

            it(@"should not process geofence", ^{
                [[PCFPushGeofenceHandler shouldNot] receive:@selector(processRegion:store:engine:state:parameters:)];
                [[PCFPushClient shared] locationManager:locationManager didDetermineState:CLRegionStateOutside forRegion:region];
                [[PCFPushClient shared] locationManager:locationManager didDetermineState:CLRegionStateUnknown forRegion:region];
            });
        });

        context(@"geofences disabled", ^{

            beforeEach(^{
                [PCFPushPersistentStorage setAreGeofencesEnabled:NO];
                [helper setupDefaultPLIST];
            });

            it(@"should process geofence on exiting region", ^{
                [[PCFPushGeofenceHandler shouldNot] receive:@selector(processRegion:store:engine:state:parameters:)];
                [[PCFPushClient shared] locationManager:locationManager didExitRegion:region];
            });

            it(@"should process geofence inside region", ^{
                [[PCFPushGeofenceHandler shouldNot] receive:@selector(processRegion:store:engine:state:parameters:)];
                [[PCFPushClient shared] locationManager:locationManager didDetermineState:CLRegionStateInside forRegion:region];
            });

            it(@"should not process geofence", ^{
                [[PCFPushGeofenceHandler shouldNot] receive:@selector(processRegion:store:engine:state:parameters:)];
                [[PCFPushClient shared] locationManager:locationManager didDetermineState:CLRegionStateOutside forRegion:region];
                [[PCFPushClient shared] locationManager:locationManager didDetermineState:CLRegionStateUnknown forRegion:region];
            });
        });
    });

    describe(@"set areGeofencesEnabled", ^{

        beforeEach(^{
            [helper setupDefaultPLIST];
            [helper setupDefaultPersistedParameters];
            [PCFPushAnalytics stub:@selector(isAnalyticsPollingTime:) andReturn:theValue(NO)];
        });

        it(@"should return an error if not already registered", ^{
            [PCFPushPersistentStorage setAPNSDeviceToken:nil];
            [PCFPushPersistentStorage setAreGeofencesEnabled:NO];
            [[NSURLConnection shouldNot] receive:@selector(pcfPushSendAsynchronousRequestWrapper:queue:completionHandler:)];
            [[PCFPushGeofenceUpdater shouldNot] receive:@selector(clearAllGeofences:)];
            [[PCFPushGeofenceHandler shouldNot] receive:@selector(reregisterGeofencesWithEngine:subscribedTags:)];
            [[PCFPushGeofenceUpdater shouldNot] receive:@selector(startGeofenceUpdate:userInfo:timestamp:tags:success:failure:) withCount:1];

            __block BOOL wasFailureBlockCalled = NO;
            [PCFPush setAreGeofencesEnabled:YES success:^{
                fail(@"Should not have succeeded");
            } failure:^(NSError *error) {
                wasFailureBlockCalled = YES;
            }];

            [[theValue(wasFailureBlockCalled) should] beTrue];
        });

        context(@"set areGeofencesEnabled to true", ^{

            __block BOOL wasBlockCalled;

            beforeEach(^{
                wasBlockCalled = NO;
                [PCFPushPersistentStorage setAreGeofencesEnabled:NO];
                [[NSURLConnection shouldNot] receive:@selector(pcfPushSendAsynchronousRequestWrapper:queue:completionHandler:)];
                [[PCFPushGeofenceUpdater shouldNot] receive:@selector(clearAllGeofences:)];
                [[PCFPushGeofenceHandler shouldNot] receive:@selector(reregisterGeofencesWithEngine:subscribedTags:)];
                [[PCFPushGeofenceUpdater should] receive:@selector(startGeofenceUpdate:userInfo:timestamp:tags:success:failure:) withCount:1];
            });

            afterEach(^{
                [[theValue(wasBlockCalled) should] beYes];
            });

            it(@"should succeed", ^{
                [helper setupGeofencesForSuccessfulUpdateWithLastModifiedTime:1337L];
                [PCFPush setAreGeofencesEnabled:YES success:^{
                    wasBlockCalled = YES;
                    [[theValue([PCFPushPersistentStorage areGeofencesEnabled]) should] beYes];
                } failure:^(NSError *error) {
                    fail(@"Should not have failed.");
                }];
            });

            it(@"should fail", ^{
                [helper setupGeofencesForFailedUpdate];
                [PCFPush setAreGeofencesEnabled:YES success:^{
                    fail(@"Should not have succeeded.");
                } failure:^(NSError *error) {
                    wasBlockCalled = YES;
                    [[theValue([PCFPushPersistentStorage areGeofencesEnabled]) should] beNo];
                }];
            });
        });

        context(@"set areGeofencesEnabled to false", ^{

            __block BOOL wasBlockCalled;

            beforeEach(^{
                wasBlockCalled = NO;
                [PCFPushPersistentStorage setAreGeofencesEnabled:YES];
                [PCFPushPersistentStorage setGeofenceLastModifiedTime:1337L];
                [[NSURLConnection shouldNot] receive:@selector(pcfPushSendAsynchronousRequestWrapper:queue:completionHandler:)];
                [[PCFPushGeofenceUpdater should] receive:@selector(clearAllGeofences:)];
                [[PCFPushGeofenceHandler shouldNot] receive:@selector(reregisterGeofencesWithEngine:subscribedTags:)];
                [[PCFPushGeofenceUpdater shouldNot] receive:@selector(startGeofenceUpdate:userInfo:timestamp:tags:success:failure:) withCount:1];
            });

            afterEach(^{
                [[theValue(wasBlockCalled) should] beYes];
            });

            it(@"should succeed", ^{
                [helper setupClearGeofencesForSuccess];
                [PCFPush setAreGeofencesEnabled:NO success:^{
                    wasBlockCalled = YES;
                    [[theValue([PCFPushPersistentStorage areGeofencesEnabled]) should] beNo];
                } failure:^(NSError *error) {
                    fail(@"Should not have failed.");
                }];
            });
        });
    });
});

SPEC_END
