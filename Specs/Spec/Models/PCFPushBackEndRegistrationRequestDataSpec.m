//
//  PCFPushBackEndRegistrationRequestDataSpec.mm
//  PCFPushSDK
//
//  Created by Rob Szumlakowski on 2014-02-14.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "Kiwi.h"

#import "PCFPushBackEndRegistrationRequestDataTest.h"
#import "NSObject+PCFPushJsonizable.h"
#import "PCFPushErrors.h"

SPEC_BEGIN(PCFPushBackEndRegistrationRequestDataSpec)

describe(@"PCFPushBackEndRegistrationRequestData", ^{
    
    __block PCFPushRegistrationRequestData *model;
    
    afterEach(^{
        model = nil;
    });
    
    it(@"should be initializable", ^{
        model = [[PCFPushRegistrationRequestData alloc] init];
        [[model shouldNot] beNil];
    });
    
    context(@"fields", ^{
        
        beforeEach(^{
            model = [[PCFPushRegistrationRequestData alloc] init];
        });
        
        it(@"should start as nil", ^{
            [[model.releaseUUID should] beNil];
            [[model.secret should] beNil];
            [[model.deviceAlias should] beNil];
            [[model.deviceManufacturer should] beNil];
            [[model.deviceModel should] beNil];
            [[model.os should] beNil];
            [[model.osVersion should] beNil];
            [[model.registrationToken should] beNil];
        });
        
        it(@"should have a release_uuid", ^{
            model.releaseUUID = TEST_RELEASE_UUID;
            [[model.releaseUUID should] equal:TEST_RELEASE_UUID];
        });
        
        it(@"should have a secret", ^{
            model.secret = TEST_SECRET;
            [[model.secret should] equal:TEST_SECRET];
        });
        
        it(@"should have a device_alias", ^{
            model.deviceAlias = TEST_DEVICE_ALIAS;
            [[model.deviceAlias should] equal:TEST_DEVICE_ALIAS];
        });
        
        it(@"should have a device_manufacturer", ^{
            model.deviceManufacturer = TEST_DEVICE_MANUFACTURER;
            [[model.deviceManufacturer should] equal:TEST_DEVICE_MANUFACTURER];
        });
        
        it(@"should have a device_model", ^{
            model.deviceModel = TEST_DEVICE_MODEL;
            [[model.deviceModel should] equal:TEST_DEVICE_MODEL];
        });
        
        it(@"should have an os", ^{
            model.os = TEST_OS;
            [[model.os should] equal:TEST_OS];
        });
        
        it(@"should have an os_version", ^{
            model.os = TEST_OS_VERSION;
            [[model.os should] equal:TEST_OS_VERSION];
        });
        
        it(@"should have an registration_token", ^{
            model.registrationToken = TEST_REGISTRATION_TOKEN;
            [[model.registrationToken should] equal:TEST_REGISTRATION_TOKEN];
        });
    });
    
    context(@"deserialization", ^{
        
        it(@"should handle a nil input", ^{
            NSError *error;
            model = [PCFPushRegistrationRequestData fromJSONData:nil error:&error];
            [[model  should] beNil];
            [[error shouldNot] beNil];
            [[error.domain should] equal:PCFPushErrorDomain];
            [[theValue(error.code) should] equal:theValue(PCFPushBackEndRegistrationDataUnparseable)];
        });
        
        it(@"should handle empty input", ^{
            NSError *error;
            model = [PCFPushRegistrationRequestData fromJSONData:[NSData data] error:&error];
            [[model should] beNil];
            [[error shouldNot] beNil];
            [[error.domain should] equal:PCFPushErrorDomain];
            [[theValue(error.code) should] equal:theValue(PCFPushBackEndRegistrationDataUnparseable)];
        });
        
        it(@"should handle bad JSON", ^{
            NSError *error;
            NSData *JSONData = [@"I AM NOT JSON" dataUsingEncoding:NSUTF8StringEncoding];
            model = [PCFPushRegistrationRequestData fromJSONData:JSONData error:&error];
            [[model  should] beNil];
            [[error shouldNot] beNil];
        });
        
        it(@"should construct a complete request object", ^{
            NSError *error;
            NSDictionary *dict = @{
                                   RegistrationAttributes.deviceOS : TEST_OS,
                                   RegistrationAttributes.deviceOSVersion : TEST_OS_VERSION,
                                   RegistrationAttributes.deviceAlias : TEST_DEVICE_ALIAS,
                                   RegistrationAttributes.deviceManufacturer : TEST_DEVICE_MANUFACTURER,
                                   RegistrationAttributes.deviceModel : TEST_DEVICE_MODEL,
                                   RegistrationAttributes.releaseUUID : TEST_RELEASE_UUID,
                                   RegistrationAttributes.registrationToken : TEST_REGISTRATION_TOKEN,
                                   kReleaseSecret : TEST_SECRET,
                                   };
            
            NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
            [[error should] beNil];
            [[data shouldNot] beNil];
            
            model = [PCFPushRegistrationRequestData fromJSONData:data error:&error];
            [[error should] beNil];
            [[model.os should] equal:TEST_OS];
            [[model.osVersion should] equal:TEST_OS_VERSION ];
            [[model.deviceAlias should] equal:TEST_DEVICE_ALIAS];
            [[model.deviceManufacturer should] equal:TEST_DEVICE_MANUFACTURER];
            [[model.deviceModel should] equal:TEST_DEVICE_MODEL];
            [[model.releaseUUID should] equal:TEST_RELEASE_UUID];
            [[model.secret should] equal:TEST_SECRET];
            [[model.registrationToken should] equal:TEST_REGISTRATION_TOKEN];
        });
    });

    context(@"serialization", ^{
        
        __block NSDictionary *dict = nil;
        
        beforeEach(^{
            model = [[PCFPushRegistrationRequestData alloc] init];
        });
        
        afterEach(^{
            dict = nil;
        });

        context(@"populated object", ^{
            
            beforeEach(^{
                model.releaseUUID = TEST_RELEASE_UUID;
                model.secret = TEST_SECRET;
                model.deviceAlias = TEST_DEVICE_ALIAS;
                model.deviceManufacturer = TEST_DEVICE_MANUFACTURER;
                model.deviceModel = TEST_DEVICE_MODEL;
                model.os = TEST_OS;
                model.osVersion = TEST_OS_VERSION;
                model.registrationToken = TEST_REGISTRATION_TOKEN;
            });
            
            afterEach(^{
                [[dict shouldNot] beNil];
                [[dict[RegistrationAttributes.releaseUUID] should] equal:TEST_RELEASE_UUID];
                [[dict[kReleaseSecret] should] equal:TEST_SECRET];
                [[dict[RegistrationAttributes.deviceAlias] should] equal:TEST_DEVICE_ALIAS];
                [[dict[RegistrationAttributes.deviceManufacturer] should] equal:TEST_DEVICE_MANUFACTURER];
                [[dict[RegistrationAttributes.deviceModel] should] equal:TEST_DEVICE_MODEL];
                [[dict[RegistrationAttributes.deviceOS] should] equal:TEST_OS];
                [[dict[RegistrationAttributes.deviceOSVersion] should] equal:TEST_OS_VERSION];
                [[dict[RegistrationAttributes.registrationToken] should] equal:TEST_REGISTRATION_TOKEN];
            });

            it(@"should be dictionaryizable", ^{
                dict = [model toFoundationType];
            });
            
            it(@"should be JSONizable", ^{
                NSData *JSONData = [model toJSONData:nil];
                [[JSONData shouldNot] beNil];
                NSError *error = nil;
                dict = [NSJSONSerialization JSONObjectWithData:JSONData options:0 error:&error];
                [[error  should] beNil];
            });
        });
        
        context(@"unpopulated object", ^{
            
            afterEach(^{
                [[dict shouldNot] beNil];
                [[dict[RegistrationAttributes.releaseUUID]  should] beNil];
                [[dict[kReleaseSecret]  should] beNil];
                [[dict[RegistrationAttributes.deviceAlias]  should] beNil];
                [[dict[RegistrationAttributes.deviceManufacturer]  should] beNil];
                [[dict[RegistrationAttributes.deviceModel]  should] beNil];
                [[dict[RegistrationAttributes.deviceOS]  should] beNil];
                [[dict[RegistrationAttributes.deviceOSVersion]  should] beNil];
                [[dict[RegistrationAttributes.registrationToken]  should] beNil];
            });
            
            it(@"should be dictionaryizable", ^{
                dict = [model toFoundationType];
            });
            
            it(@"should be JSONizable", ^{
                NSData *JSONData = [model toJSONData:nil];
                [[JSONData shouldNot] beNil];
                NSError *error = nil;
                dict = [NSJSONSerialization JSONObjectWithData:JSONData options:0 error:&error];
                [[error  should] beNil];
            });
        });
    });
});

SPEC_END
