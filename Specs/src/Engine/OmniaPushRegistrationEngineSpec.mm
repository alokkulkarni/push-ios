#import "OmniaPushRegistrationEngine.h"
#import "OmniaSpecHelper.h"
#import "OmniaFakeOperationQueue.h"
#import "OmniaPushAPNSRegistrationRequestOperation.h"
#import "OmniaPushRegistrationCompleteOperation.h"
#import "OmniaPushRegistrationFailedOperation.h"
#import "OmniaRegistrationSpecHelper.h"
#import "OmniaPushPersistentStorage.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(OmniaPushRegistrationEngineSpec)

describe(@"OmniaPushRegistrationEngine", ^{
    
    __block OmniaRegistrationSpecHelper *helper;

    beforeEach(^{
        helper = [[OmniaRegistrationSpecHelper alloc] initWithSpecHelper:[[OmniaSpecHelper alloc] init]];
        [helper setup];
    });
    
    afterEach(^{
        [helper reset];
        helper = nil;
    });
    
    context(@"initialization with bad arguments", ^{
        
        afterEach(^{
            helper.helper.registrationEngine should be_nil;
        });

        it(@"should require an application", ^{
            ^{helper.helper.registrationEngine = [[OmniaPushRegistrationEngine alloc] initWithApplication:nil originalApplicationDelegate:helper.helper.applicationDelegate listener:nil];}
                should raise_exception([NSException class]);
        });
        
        it(@"should require the original application delegate", ^{
            ^{helper.helper.registrationEngine = [[OmniaPushRegistrationEngine alloc] initWithApplication:helper.helper.application originalApplicationDelegate:nil listener:nil];}
            should raise_exception([NSException class]);
        });
    });
    
    context(@"initialization with good arguments", ^{
       
        beforeEach(^{
            helper.helper.registrationEngine = [[OmniaPushRegistrationEngine alloc] initWithApplication:helper.helper.application originalApplicationDelegate:helper.helper.applicationDelegate listener:nil];
        });
        
        it(@"should produce a valid instance", ^{
            helper.helper.registrationEngine should_not be_nil;
        });

        it(@"should retain its arguments in properties", ^{
            helper.helper.registrationEngine.application should be_same_instance_as(helper.helper.application);
        });
        
        it(@"should initialize all the state properties to false", ^{
            
            [helper verifyDidStartRegistration:BE_FALSE
                      didStartAPNSRegistration:BE_FALSE
                     didFinishAPNSRegistration:BE_FALSE
                    didAPNSRegistrationSucceed:BE_FALSE
                       didAPNSRegistrationFail:BE_FALSE
                 didStartBackendUnregistration:BE_FALSE
                didFinishBackendUnregistration:BE_FALSE
               didBackEndUnregistrationSucceed:BE_FALSE
                  didBackEndUnregistrationFail:BE_FALSE
                   didStartBackendRegistration:BE_FALSE
                  didFinishBackendRegistration:BE_FALSE
                 didBackendRegistrationSucceed:BE_FALSE
                    didBackendRegistrationFail:BE_FALSE
                        didRegistrationSucceed:BE_FALSE
                           didRegistrationFail:BE_FALSE
                         resultAPNSDeviceToken:nil
                                   resultError:nil];
        });
        
        context(@"when registering", ^{
            
            __block NSError *testError;
            
            beforeEach(^{
                [helper.helper setupQueues];
                [helper.helper setupAppDelegateProxy];
                testError = [NSError errorWithDomain:@"Some dumb error" code:0 userInfo:nil];
            });
            
            it(@"should require parameters", ^{
                ^{[helper.helper.registrationEngine startRegistration:nil];}
                    should raise_exception([NSException class]);
            });
            
            it(@"should retain its parameters", ^{
                [helper.helper setupApplicationForFailedRegistrationWithNotificationTypes:TEST_NOTIFICATION_TYPES error:testError];
                [helper.helper setupApplicationDelegateForFailedRegistrationWithError:testError];
                [helper startRegistration];
                helper.helper.registrationEngine.parameters should equal(helper.helper.params);
                helper.helper.registrationEngine.parameters should_not be_nil;
            });
            
            context(@"successful registration", ^{
                
                beforeEach(^{
                    [helper.applicationDelegateMessages addObject:@"application:didRegisterForRemoteNotificationsWithDeviceToken:"];
                });
                
                afterEach(^{
                    [helper verifyMessages];
                    [helper verifyQueueCompletedOperations:@[[OmniaPushAPNSRegistrationRequestOperation class], [OmniaPushRegistrationCompleteOperation class]]
                                    notCompletedOperations:@[[OmniaPushRegistrationFailedOperation class]]];
                });
                
                context(@"receiving the regular device token from APNS", ^{
                    
                    beforeEach(^{
                        [helper.helper setupApplicationForSuccessfulRegistrationWithNotificationTypes:TEST_NOTIFICATION_TYPES];
                        [helper.helper setupApplicationDelegateForSuccessfulRegistration];
                    });
                    
                    afterEach(^{
                        [helper verifyPersistentStorageAPNSDeviceToken:helper.helper.apnsDeviceToken
                                                       backEndDeviceId:helper.helper.backEndDeviceId];
                    });
                    
                    context(@"when not already registered with APNS", ^{
                        
                        it(@"should register with APNS and then with the back-end", ^{
                            [helper setupBackEndForSuccessfulRegistration];
                            [helper setupPersistentStorageAPNSDeviceToken:nil
                                                          backEndDeviceId:nil];
                            
                            [helper startRegistration];
                            
                            [helper verifyDidStartRegistration:BE_TRUE
                                      didStartAPNSRegistration:BE_TRUE
                                     didFinishAPNSRegistration:BE_TRUE
                                    didAPNSRegistrationSucceed:BE_TRUE
                                       didAPNSRegistrationFail:BE_FALSE
                                 didStartBackendUnregistration:BE_FALSE
                                didFinishBackendUnregistration:BE_FALSE
                               didBackEndUnregistrationSucceed:BE_FALSE
                                  didBackEndUnregistrationFail:BE_FALSE
                                   didStartBackendRegistration:BE_TRUE
                                  didFinishBackendRegistration:BE_TRUE
                                 didBackendRegistrationSucceed:BE_TRUE
                                    didBackendRegistrationFail:BE_FALSE
                                        didRegistrationSucceed:BE_TRUE
                                           didRegistrationFail:BE_FALSE
                                         resultAPNSDeviceToken:helper.helper.apnsDeviceToken
                                                   resultError:nil];
                        });
                    });
                    
                    context(@"already registered with APNS", ^{
                        
                        context(@"not already registered with the back-end", ^{
                            
                            it(@"should still register with APNS and then the back-end", ^{
                                [helper setupBackEndForSuccessfulRegistration];
                                [helper setupPersistentStorageAPNSDeviceToken:helper.helper.apnsDeviceToken
                                                              backEndDeviceId:nil];
                                
                                [helper startRegistration];
                                
                                [helper verifyDidStartRegistration:BE_TRUE
                                          didStartAPNSRegistration:BE_TRUE
                                         didFinishAPNSRegistration:BE_TRUE
                                        didAPNSRegistrationSucceed:BE_TRUE
                                           didAPNSRegistrationFail:BE_FALSE
                                     didStartBackendUnregistration:BE_FALSE
                                    didFinishBackendUnregistration:BE_FALSE
                                   didBackEndUnregistrationSucceed:BE_FALSE
                                      didBackEndUnregistrationFail:BE_FALSE
                                       didStartBackendRegistration:BE_TRUE
                                      didFinishBackendRegistration:BE_TRUE
                                     didBackendRegistrationSucceed:BE_TRUE
                                        didBackendRegistrationFail:BE_FALSE
                                            didRegistrationSucceed:BE_TRUE
                                               didRegistrationFail:BE_FALSE
                                             resultAPNSDeviceToken:helper.helper.apnsDeviceToken
                                                       resultError:nil];
                            });
                        });

                        context(@"already registered with the back-end", ^{
                            
                            it(@"should still register with APNS but skip the back-end registration", ^{
                                [helper setupPersistentStorageAPNSDeviceToken:helper.helper.apnsDeviceToken
                                                              backEndDeviceId:helper.helper.backEndDeviceId];
                                
                                [helper startRegistration];
                                
                                [helper verifyDidStartRegistration:BE_TRUE
                                          didStartAPNSRegistration:BE_TRUE
                                         didFinishAPNSRegistration:BE_TRUE
                                        didAPNSRegistrationSucceed:BE_TRUE
                                           didAPNSRegistrationFail:BE_FALSE
                                     didStartBackendUnregistration:BE_FALSE
                                    didFinishBackendUnregistration:BE_FALSE
                                   didBackEndUnregistrationSucceed:BE_FALSE
                                      didBackEndUnregistrationFail:BE_FALSE
                                       didStartBackendRegistration:BE_FALSE
                                      didFinishBackendRegistration:BE_FALSE
                                     didBackendRegistrationSucceed:BE_FALSE
                                        didBackendRegistrationFail:BE_FALSE
                                            didRegistrationSucceed:BE_TRUE
                                               didRegistrationFail:BE_FALSE
                                             resultAPNSDeviceToken:helper.helper.apnsDeviceToken
                                                       resultError:nil];
                            });
                        });
                    });
                });
                
                context(@"receiving a different device token from APNS", ^{
                    
                    beforeEach(^{
                        [helper.helper setupApplicationForSuccessfulRegistrationWithNotificationTypes:TEST_NOTIFICATION_TYPES withNewApnsDeviceToken:helper.helper.apnsDeviceToken2];
                        [helper.helper setupApplicationDelegateForSuccessfulRegistrationWithApnsDeviceToken:helper.helper.apnsDeviceToken2];
                        [helper setupBackEndForSuccessfulRegistrationWithNewBackEndDeviceId:helper.helper.backEndDeviceId2];
                    });
                    
                    afterEach(^{
                        [helper verifyPersistentStorageAPNSDeviceToken:helper.helper.apnsDeviceToken2
                                                       backEndDeviceId:helper.helper.backEndDeviceId2];
                    });

                    context(@"not registered with back-end yet", ^{

                        it(@"should skip unregistration with the back-end and then register with the back-end", ^{
                            [helper setupPersistentStorageAPNSDeviceToken:helper.helper.apnsDeviceToken
                                                          backEndDeviceId:nil];
                            
                            [helper startRegistration];
                            
                            [helper verifyDidStartRegistration:BE_TRUE
                                      didStartAPNSRegistration:BE_TRUE
                                     didFinishAPNSRegistration:BE_TRUE
                                    didAPNSRegistrationSucceed:BE_TRUE
                                       didAPNSRegistrationFail:BE_FALSE
                                 didStartBackendUnregistration:BE_FALSE
                                didFinishBackendUnregistration:BE_FALSE
                               didBackEndUnregistrationSucceed:BE_FALSE
                                  didBackEndUnregistrationFail:BE_FALSE
                                   didStartBackendRegistration:BE_TRUE
                                  didFinishBackendRegistration:BE_TRUE
                                 didBackendRegistrationSucceed:BE_TRUE
                                    didBackendRegistrationFail:BE_FALSE
                                        didRegistrationSucceed:BE_TRUE
                                           didRegistrationFail:BE_FALSE
                                         resultAPNSDeviceToken:helper.helper.apnsDeviceToken2
                                                   resultError:nil];
                        });
                    });

                    context(@"already registered with the back-end", ^{
                        
                        beforeEach(^{
                            [helper setupPersistentStorageAPNSDeviceToken:helper.helper.apnsDeviceToken
                                                          backEndDeviceId:helper.helper.backEndDeviceId];
                        });

                        context(@"unregistration is successful", ^{
                            
                            it(@"should unregister with the back-end and then register anew with the back-end", ^{
                                [helper setupBackEndForSuccessfulUnregistration];
                                
                                [helper startRegistration];
                                
                                [helper verifyDidStartRegistration:BE_TRUE
                                          didStartAPNSRegistration:BE_TRUE
                                         didFinishAPNSRegistration:BE_TRUE
                                        didAPNSRegistrationSucceed:BE_TRUE
                                           didAPNSRegistrationFail:BE_FALSE
                                     didStartBackendUnregistration:BE_TRUE
                                    didFinishBackendUnregistration:BE_TRUE
                                   didBackEndUnregistrationSucceed:BE_TRUE
                                      didBackEndUnregistrationFail:BE_FALSE
                                       didStartBackendRegistration:BE_TRUE
                                      didFinishBackendRegistration:BE_TRUE
                                     didBackendRegistrationSucceed:BE_TRUE
                                        didBackendRegistrationFail:BE_FALSE
                                            didRegistrationSucceed:BE_TRUE
                                               didRegistrationFail:BE_FALSE
                                             resultAPNSDeviceToken:helper.helper.apnsDeviceToken2
                                                       resultError:nil];
                                
                            });
                        });
                        
                        context(@"unregistration fails", ^{
                            
                            it(@"should register anew with the back-end even after unregistration fails", ^{
                                [helper setupBackEndForFailedUnregistrationWithError:testError];
                                
                                [helper startRegistration];
                                
                                [helper verifyDidStartRegistration:BE_TRUE
                                          didStartAPNSRegistration:BE_TRUE
                                         didFinishAPNSRegistration:BE_TRUE
                                        didAPNSRegistrationSucceed:BE_TRUE
                                           didAPNSRegistrationFail:BE_FALSE
                                     didStartBackendUnregistration:BE_TRUE
                                    didFinishBackendUnregistration:BE_TRUE
                                   didBackEndUnregistrationSucceed:BE_FALSE
                                      didBackEndUnregistrationFail:BE_TRUE
                                       didStartBackendRegistration:BE_TRUE
                                      didFinishBackendRegistration:BE_TRUE
                                     didBackendRegistrationSucceed:BE_TRUE
                                        didBackendRegistrationFail:BE_FALSE
                                            didRegistrationSucceed:BE_TRUE
                                               didRegistrationFail:BE_FALSE
                                             resultAPNSDeviceToken:helper.helper.apnsDeviceToken2
                                                       resultError:nil];
                            });
                        });
                    });
                });
            });
            
            context(@"failed registration", ^{
                it(@"APNS registration fails after fresh install", ^{
                    [helper.applicationDelegateMessages addObject:@"application:didFailToRegisterForRemoteNotificationsWithError:"];
                    [helper.helper setupApplicationForFailedRegistrationWithNotificationTypes:TEST_NOTIFICATION_TYPES error:testError];
                    [helper.helper setupApplicationDelegateForFailedRegistrationWithError:testError];
                    [helper setupPersistentStorageAPNSDeviceToken:nil
                                                  backEndDeviceId:nil];
                    
                    [helper startRegistration];
                    
                    [helper verifyMessages];
                    
                    [helper verifyQueueCompletedOperations:@[[OmniaPushAPNSRegistrationRequestOperation class], [OmniaPushRegistrationFailedOperation class]]
                                    notCompletedOperations:@[[OmniaPushRegistrationCompleteOperation class]]];
                    
                    [helper verifyDidStartRegistration:BE_TRUE
                              didStartAPNSRegistration:BE_TRUE
                             didFinishAPNSRegistration:BE_TRUE
                            didAPNSRegistrationSucceed:BE_FALSE
                               didAPNSRegistrationFail:BE_TRUE
                         didStartBackendUnregistration:BE_FALSE
                        didFinishBackendUnregistration:BE_FALSE
                       didBackEndUnregistrationSucceed:BE_FALSE
                          didBackEndUnregistrationFail:BE_FALSE
                           didStartBackendRegistration:BE_FALSE
                          didFinishBackendRegistration:BE_FALSE
                         didBackendRegistrationSucceed:BE_FALSE
                            didBackendRegistrationFail:BE_FALSE
                                didRegistrationSucceed:BE_FALSE
                                   didRegistrationFail:BE_TRUE
                                 resultAPNSDeviceToken:nil
                                           resultError:testError];
                    
                    [helper verifyPersistentStorageAPNSDeviceToken:nil
                                                   backEndDeviceId:nil];
                });
                
                it(@"APNS registration fails after already registered", ^{
                    [helper.applicationDelegateMessages addObject:@"application:didFailToRegisterForRemoteNotificationsWithError:"];
                    [helper.helper setupApplicationForFailedRegistrationWithNotificationTypes:TEST_NOTIFICATION_TYPES error:testError];
                    [helper.helper setupApplicationDelegateForFailedRegistrationWithError:testError];
                    [helper setupPersistentStorageAPNSDeviceToken:helper.helper.apnsDeviceToken
                                                  backEndDeviceId:nil];
                    
                    [helper startRegistration];
                    
                    [helper verifyMessages];
                    
                    [helper verifyQueueCompletedOperations:@[[OmniaPushAPNSRegistrationRequestOperation class], [OmniaPushRegistrationFailedOperation class]]
                                    notCompletedOperations:@[[OmniaPushRegistrationCompleteOperation class]]];
                    
                    [helper verifyDidStartRegistration:BE_TRUE
                              didStartAPNSRegistration:BE_TRUE
                             didFinishAPNSRegistration:BE_TRUE
                            didAPNSRegistrationSucceed:BE_FALSE
                               didAPNSRegistrationFail:BE_TRUE
                         didStartBackendUnregistration:BE_FALSE
                        didFinishBackendUnregistration:BE_FALSE
                       didBackEndUnregistrationSucceed:BE_FALSE
                          didBackEndUnregistrationFail:BE_FALSE
                           didStartBackendRegistration:BE_FALSE
                          didFinishBackendRegistration:BE_FALSE
                         didBackendRegistrationSucceed:BE_FALSE
                            didBackendRegistrationFail:BE_FALSE
                                didRegistrationSucceed:BE_FALSE
                                   didRegistrationFail:BE_TRUE
                                 resultAPNSDeviceToken:nil
                                           resultError:testError];
                    
                    [helper verifyPersistentStorageAPNSDeviceToken:nil
                                                   backEndDeviceId:nil];
                });
                
                it(@"APNS registration succeeds and back-end registration fails after fresh install", ^{
                    [helper.applicationDelegateMessages addObject:@"application:didFailToRegisterForRemoteNotificationsWithError:"];
                    [helper.helper setupApplicationForSuccessfulRegistrationWithNotificationTypes:TEST_NOTIFICATION_TYPES];
                    [helper.helper setupApplicationDelegateForFailedRegistrationWithError:testError];
                    [helper setupBackEndForFailedRegistrationWithError:testError];
                    [helper setupPersistentStorageAPNSDeviceToken:nil
                                                  backEndDeviceId:nil];
                    
                    [helper startRegistration];
                    
                    [helper verifyMessages];
                    
                    [helper verifyQueueCompletedOperations:@[[OmniaPushAPNSRegistrationRequestOperation class], [OmniaPushRegistrationFailedOperation class]]
                                    notCompletedOperations:@[[OmniaPushRegistrationCompleteOperation class]]];
                    
                    [helper verifyDidStartRegistration:BE_TRUE
                              didStartAPNSRegistration:BE_TRUE
                             didFinishAPNSRegistration:BE_TRUE
                            didAPNSRegistrationSucceed:BE_TRUE
                               didAPNSRegistrationFail:BE_FALSE
                         didStartBackendUnregistration:BE_FALSE
                        didFinishBackendUnregistration:BE_FALSE
                       didBackEndUnregistrationSucceed:BE_FALSE
                          didBackEndUnregistrationFail:BE_FALSE
                           didStartBackendRegistration:BE_TRUE
                          didFinishBackendRegistration:BE_TRUE
                         didBackendRegistrationSucceed:BE_FALSE
                            didBackendRegistrationFail:BE_TRUE
                                didRegistrationSucceed:BE_FALSE
                                   didRegistrationFail:BE_TRUE
                                 resultAPNSDeviceToken:helper.helper.apnsDeviceToken
                                           resultError:testError];
                    
                    [helper verifyPersistentStorageAPNSDeviceToken:helper.helper.apnsDeviceToken
                                                   backEndDeviceId:nil];
                });
                
                it(@"APNS registration succeeds and back-end registration fails after previously registered", ^{
                    [helper.applicationDelegateMessages addObject:@"application:didFailToRegisterForRemoteNotificationsWithError:"];
                    [helper.helper setupApplicationForSuccessfulRegistrationWithNotificationTypes:TEST_NOTIFICATION_TYPES];
                    [helper.helper setupApplicationDelegateForFailedRegistrationWithError:testError];
                    [helper setupBackEndForFailedRegistrationWithError:testError];
                    [helper setupPersistentStorageAPNSDeviceToken:helper.helper.apnsDeviceToken
                                                  backEndDeviceId:nil];
                    
                    [helper startRegistration];
                    
                    [helper verifyMessages];
                    
                    [helper verifyQueueCompletedOperations:@[[OmniaPushAPNSRegistrationRequestOperation class], [OmniaPushRegistrationFailedOperation class]]
                                    notCompletedOperations:@[[OmniaPushRegistrationCompleteOperation class]]];
                    
                    [helper verifyDidStartRegistration:BE_TRUE
                              didStartAPNSRegistration:BE_TRUE
                             didFinishAPNSRegistration:BE_TRUE
                            didAPNSRegistrationSucceed:BE_TRUE
                               didAPNSRegistrationFail:BE_FALSE
                         didStartBackendUnregistration:BE_FALSE
                        didFinishBackendUnregistration:BE_FALSE
                       didBackEndUnregistrationSucceed:BE_FALSE
                          didBackEndUnregistrationFail:BE_FALSE
                           didStartBackendRegistration:BE_TRUE
                          didFinishBackendRegistration:BE_TRUE
                         didBackendRegistrationSucceed:BE_FALSE
                            didBackendRegistrationFail:BE_TRUE
                                didRegistrationSucceed:BE_FALSE
                                   didRegistrationFail:BE_TRUE
                                 resultAPNSDeviceToken:helper.helper.apnsDeviceToken
                                           resultError:testError];
                    
                    [helper verifyPersistentStorageAPNSDeviceToken:helper.helper.apnsDeviceToken
                                                   backEndDeviceId:nil];
                });
            });

        });
    });
});

SPEC_END
