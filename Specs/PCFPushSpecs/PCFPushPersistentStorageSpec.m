//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import "Kiwi.h"

#import "PCFPushPersistentStorage.h"
#import "PCFPushSpecsHelper.h"

SPEC_BEGIN(PCFPushPersistentStorageSpec)

describe(@"PCFPushPersistentStorage", ^{

    __block PCFPushSpecsHelper *helper;

    beforeEach(^{
        helper = [[PCFPushSpecsHelper alloc] init];
        [PCFPushPersistentStorage reset];
    });
                   
    it(@"should start empty", ^{
        [[[PCFPushPersistentStorage APNSDeviceToken] should] beNil];
        [[[PCFPushPersistentStorage serverDeviceID] should] beNil];
        [[[PCFPushPersistentStorage variantUUID] should] beNil];
        [[[PCFPushPersistentStorage variantSecret] should] beNil];
        [[[PCFPushPersistentStorage deviceAlias] should] beNil];
        [[[PCFPushPersistentStorage tags] should] beNil];
        [[[PCFPushPersistentStorage requestHeaders] should] beNil];
        [[theValue([PCFPushPersistentStorage lastGeofencesModifiedTime]) should] equal:theValue(PCF_NEVER_UPDATED_GEOFENCES)];
        [[theValue([PCFPushPersistentStorage areGeofencesEnabled]) should] beFalse];
    });
    
    it(@"should be able to save the APNS device token", ^{
        [PCFPushPersistentStorage setAPNSDeviceToken:helper.apnsDeviceToken];
        [[[PCFPushPersistentStorage APNSDeviceToken] should] equal:helper.apnsDeviceToken];
    });
    
    it(@"should be able to save the back-end device ID", ^{
        [PCFPushPersistentStorage setServerDeviceID:helper.backEndDeviceId];
        [[[PCFPushPersistentStorage serverDeviceID] should] equal:helper.backEndDeviceId];
    });
    
    it(@"should be able to save the variant UUID", ^{
        [PCFPushPersistentStorage setVariantUUID:TEST_VARIANT_UUID_1];
        [[[PCFPushPersistentStorage variantUUID] should] equal:TEST_VARIANT_UUID_1];
    });
    
    it(@"should be able to save the variant secret", ^{
        [PCFPushPersistentStorage setVariantSecret:TEST_VARIANT_SECRET_1];
        [[[PCFPushPersistentStorage variantSecret] should] equal:(TEST_VARIANT_SECRET_1)];
    });
    
    it(@"should be able to save the device alias", ^{
        [PCFPushPersistentStorage setDeviceAlias:TEST_DEVICE_ALIAS_1];
        [[[PCFPushPersistentStorage deviceAlias] should] equal:TEST_DEVICE_ALIAS_1];
    });
    
    it(@"should be able to save populated tags", ^{
        [PCFPushPersistentStorage setTags:helper.tags1];
        [[[PCFPushPersistentStorage tags] should] equal:helper.tags1];
    });
    
    it(@"should be able to save nil tags", ^{
        [PCFPushPersistentStorage setTags:nil];
        [[[PCFPushPersistentStorage tags] should] beNil];
    });

    it(@"should be able to save last modified times", ^{
        [PCFPushPersistentStorage setGeofenceLastModifiedTime:7777L];
        [[theValue([PCFPushPersistentStorage lastGeofencesModifiedTime]) should] equal:theValue(7777L)];
    });

    it(@"should be able to save are geofences enabled", ^{
        [PCFPushPersistentStorage setAreGeofencesEnabled:YES];
        [[theValue([PCFPushPersistentStorage areGeofencesEnabled]) should] beTrue];
    });

    it(@"should be able to save request heades", ^{
        [PCFPushPersistentStorage setRequestHeaders:@{ @"CATS":@"FUZZY", @"FISH":@"SWIMMY" }];
        [[[PCFPushPersistentStorage requestHeaders] should] equal:@{ @"CATS":@"FUZZY", @"FISH":@"SWIMMY" }];
    });

    it(@"should clear values after being reset", ^{
        [PCFPushPersistentStorage setAPNSDeviceToken:helper.apnsDeviceToken];
        [PCFPushPersistentStorage setServerDeviceID:helper.backEndDeviceId];
        [PCFPushPersistentStorage setDeviceAlias:TEST_DEVICE_ALIAS_1];
        [PCFPushPersistentStorage setVariantUUID:TEST_VARIANT_UUID_1];
        [PCFPushPersistentStorage setVariantSecret:TEST_VARIANT_SECRET_1];
        [PCFPushPersistentStorage setTags:helper.tags2];
        [PCFPushPersistentStorage setGeofenceLastModifiedTime:888L];
        [PCFPushPersistentStorage setAreGeofencesEnabled:YES];
        [PCFPushPersistentStorage setRequestHeaders:@{ @"CATS":@"FUZZY", @"FISH":@"SWIMMY" }];
        [PCFPushPersistentStorage reset];
        [[[PCFPushPersistentStorage APNSDeviceToken] should] beNil];
        [[[PCFPushPersistentStorage serverDeviceID] should] beNil];
        [[[PCFPushPersistentStorage deviceAlias] should] beNil];
        [[[PCFPushPersistentStorage variantUUID] should] beNil];
        [[[PCFPushPersistentStorage variantSecret] should] beNil];
        [[[PCFPushPersistentStorage tags] should] beNil];
        [[[PCFPushPersistentStorage requestHeaders] should] beNil];
        [[theValue([PCFPushPersistentStorage lastGeofencesModifiedTime]) should] equal:theValue(PCF_NEVER_UPDATED_GEOFENCES)];
        [[theValue([PCFPushPersistentStorage areGeofencesEnabled]) should] beFalse];
    });
});

SPEC_END
