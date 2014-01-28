//
//  OmniaRegistrationSpecHelper.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-27.
//  Copyright (c) 2014 Omnia. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OmniaSpecHelper;

typedef enum RegistrationStateResult : NSUInteger {
    BE_NIL,
    BE_FALSE,
    BE_TRUE
} RegistrationStateResult;

@interface OmniaRegistrationSpecHelper : NSObject

@property (nonatomic) OmniaSpecHelper* helper;
@property (nonatomic) NSMutableArray* applicationMessages;
@property (nonatomic) NSMutableArray* applicationDelegateMessages;

// Helper lifecycle

- (instancetype) initWithSpecHelper:(OmniaSpecHelper*)helper;
- (void) setup;
- (void) reset;

// Test setup helpers

- (void) setupBackEndForSuccessfulRegistration;
- (void) setupBackEndForFailedRegistrationWithError:(NSError*)error;

// Test running helpers

- (void) startRegistration;

// Verification helpers

- (void) verifyDidStartRegistration:(RegistrationStateResult)didStartRegistration
           didStartAPNSRegistration:(RegistrationStateResult)didStartAPNSRegistration
          didFinishAPNSRegistration:(RegistrationStateResult)didFinishAPNSRegistration
         didAPNSRegistrationSucceed:(RegistrationStateResult)didAPNSRegistrationSucceed
            didAPNSRegistrationFail:(RegistrationStateResult)didAPNSRegistrationFail
      didStartBackendUnregistration:(RegistrationStateResult)didStartBackendUnregistration
     didFinishBackendUnregistration:(RegistrationStateResult)didFinishBackendUnregistration
        didStartBackendRegistration:(RegistrationStateResult)didStartBackendRegistration
       didFinishBackendRegistration:(RegistrationStateResult)didFinishBackendRegistration
      didBackendRegistrationSucceed:(RegistrationStateResult)didBackendRegistrationSucceed
         didBackendRegistrationFail:(RegistrationStateResult)didBackendRegistrationFail
             didRegistrationSucceed:(RegistrationStateResult)didRegistrationSucceed
                didRegistrationFail:(RegistrationStateResult)didRegistrationFail
              resultAPNSDeviceToken:(NSData*)resultApnsDeviceToken
                        resultError:(NSError*)resultError;

- (void) verifyQueueCompletedOperations:(NSArray*)completedOperations
                 notCompletedOperations:(NSArray*)notCompletedOperations;

- (void) verifyMessages;

- (void) verifyPersistentStorageAPNSDeviceToken:(NSData*)apnsDeviceToken
                                backEndDeviceId:(NSString*)backEndDeviceId;

@end
