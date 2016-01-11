//
//  PCFPushAnalyticsSpec.m
//  PCFPushPushSpec
//

#import "Kiwi.h"
#import <CoreData/CoreData.h>
#import "PCFPush.h"
#import "PCFPushErrorUtil.h"
#import "PCFPushAnalytics.h"
#import "PCFPushParameters.h"
#import "PCFPushSpecsHelper.h"
#import "PCFPushAnalyticsEvent.h"
#import "PCFPushAnalyticsStorage.h"
#import "PCFPushPersistentStorage.h"

SPEC_BEGIN(PCFPushAnalyticsSpec)

    __block PCFPushSpecsHelper *helper;
    __block PCFPushParameters *parametersWithAnalyticsEnabled;
    __block PCFPushParameters *parametersWithAnalyticsDisabled;
    __block NSString *entityName;

    beforeEach(^{
        helper = [[PCFPushSpecsHelper alloc] init];
        [PCFPushPersistentStorage reset];
        [helper setupAnalyticsStorage];
        [helper setupDefaultPLIST];
        parametersWithAnalyticsDisabled = [PCFPushParameters parametersWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"Pivotal-AnalyticsDisabled" ofType:@"plist"]];
        parametersWithAnalyticsEnabled = [PCFPushParameters defaultParameters];
        [PCFPushAnalytics resetAnalytics];
        entityName = NSStringFromClass(PCFPushAnalyticsEvent.class);
    });

    afterEach(^{
        [helper resetAnalyticsStorage];
        [helper reset];
        helper = nil;
    });

    describe(@"data migration", ^{

        beforeEach(^{
            [helper resetAnalyticsStorage];
            [PCFPushPersistentStorage reset];
            [PCFPushPersistentStorage setServerVersion:@"1.3.2"];
            [PCFPushPersistentStorage setServerDeviceID:@"TEST_DEVICE_UUID"];
        });

        void (^selectDatabaseModelV1)() = ^{
            [PCFPushAnalyticsStorage stub:@selector(newestManagedObjectModel) andReturn:PCFPushAnalyticsStorage.managedObjectModelV1];
            [PCFPushAnalyticsStorage stub:@selector(allManagedObjectModels) andReturn:@[PCFPushAnalyticsStorage.managedObjectModelV1]];
        };

        void (^selectDatabaseModelV2)() = ^{
            [PCFPushAnalyticsStorage stub:@selector(newestManagedObjectModel) andReturn:PCFPushAnalyticsStorage.managedObjectModelV2];
            [PCFPushAnalyticsStorage stub:@selector(allManagedObjectModels) andReturn:@[PCFPushAnalyticsStorage.managedObjectModelV1, PCFPushAnalyticsStorage.managedObjectModelV2]];
        };

        void (^selectDatabaseModelV3)() = ^{
            [PCFPushAnalyticsStorage stub:@selector(newestManagedObjectModel) andReturn:PCFPushAnalyticsStorage.managedObjectModelV3];
            [PCFPushAnalyticsStorage stub:@selector(allManagedObjectModels) andReturn:@[PCFPushAnalyticsStorage.managedObjectModelV1, PCFPushAnalyticsStorage.managedObjectModelV2, PCFPushAnalyticsStorage.managedObjectModelV3]];
        };

        it(@"V1 -> V1 should skip migration", ^{

            selectDatabaseModelV1();

            [PCFPushAnalytics logReceivedRemoteNotification:@"TEST_RECEIPT_ID" parameters:parametersWithAnalyticsEnabled];
            
            NSArray *eventsBeforeMigration = [PCFPushAnalyticsStorage.shared events];
            [[eventsBeforeMigration should] haveCountOf:1];
            PCFPushAnalyticsEvent *eventBeforeMigration = eventsBeforeMigration.lastObject;
            [[eventBeforeMigration should] beKindOfClass:NSClassFromString(entityName)];
            [[eventBeforeMigration.eventType should] equal:PCF_PUSH_EVENT_TYPE_PUSH_NOTIFICATION_RECEIVED];

            [helper resetAnalyticsStorageButKeepDatabaseFile];
            
            [PCFPushPersistentStorage reset];
            
            NSArray *eventsAfterMigration = [PCFPushAnalyticsStorage.shared events];
            [[eventsAfterMigration should] haveCountOf:1];
            PCFPushAnalyticsEvent *eventAfterMigration = eventsAfterMigration.lastObject;
            [[eventAfterMigration should] beKindOfClass:NSClassFromString(entityName)];
            [[eventAfterMigration.eventType should] equal:PCF_PUSH_EVENT_TYPE_PUSH_NOTIFICATION_RECEIVED];
            [[theValue(PCFPushAnalyticsStorage.numberOfMigrationsExecuted) should] equal:theValue(0)];
        });
        
        it(@"V1 -> V2 should do migration", ^{

            selectDatabaseModelV1();

            [PCFPushAnalytics logReceivedRemoteNotification:@"TEST_RECEIPT_ID" parameters:parametersWithAnalyticsEnabled];

            NSArray *eventsBeforeMigration = [PCFPushAnalyticsStorage.shared events];
            [[eventsBeforeMigration should] haveCountOf:1];
            PCFPushAnalyticsEvent *eventBeforeMigration = eventsBeforeMigration.lastObject;
            [[eventBeforeMigration should] beKindOfClass:NSClassFromString(entityName)];
            [[eventBeforeMigration.eventType should] equal:PCF_PUSH_EVENT_TYPE_PUSH_NOTIFICATION_RECEIVED];

            [helper resetAnalyticsStorageButKeepDatabaseFile];

            selectDatabaseModelV2();

            [PCFPushPersistentStorage reset];
            
            NSArray *eventsAfterMigration = [PCFPushAnalyticsStorage.shared events];
            [[eventsAfterMigration should] haveCountOf:1];
            PCFPushAnalyticsEvent *eventAfterMigration = eventsAfterMigration.lastObject;
            [[eventAfterMigration should] beKindOfClass:NSClassFromString(entityName)];
            [[eventAfterMigration.eventType should] equal:PCF_PUSH_EVENT_TYPE_PUSH_NOTIFICATION_RECEIVED];
            [[eventAfterMigration.sdkVersion should] beNil];
            [[theValue(PCFPushAnalyticsStorage.numberOfMigrationsExecuted) should] equal:theValue(1)];
        });
        
        it(@"V2 -> V2 should skip migration", ^{

            selectDatabaseModelV2();

            [PCFPushAnalytics logReceivedRemoteNotification:@"TEST_RECEIPT_ID" parameters:parametersWithAnalyticsEnabled];
            
            NSArray *eventsBeforeMigration = [PCFPushAnalyticsStorage.shared events];
            [[eventsBeforeMigration should] haveCountOf:1];
            PCFPushAnalyticsEvent *eventBeforeMigration = eventsBeforeMigration.lastObject;
            [[eventBeforeMigration should] beKindOfClass:NSClassFromString(entityName)];
            [[eventBeforeMigration.eventType should] equal:PCF_PUSH_EVENT_TYPE_PUSH_NOTIFICATION_RECEIVED];
            [[eventBeforeMigration.sdkVersion should] equal:PCFPushSDKVersion];
            
            [helper resetAnalyticsStorageButKeepDatabaseFile];
            
            [PCFPushPersistentStorage reset];
            
            NSArray *eventsAfterMigration = [PCFPushAnalyticsStorage.shared events];
            [[eventsAfterMigration should] haveCountOf:1];
            PCFPushAnalyticsEvent *eventAfterMigration = eventsAfterMigration.lastObject;
            [[eventAfterMigration should] beKindOfClass:NSClassFromString(entityName)];
            [[eventAfterMigration.eventType should] equal:PCF_PUSH_EVENT_TYPE_PUSH_NOTIFICATION_RECEIVED];
            [[eventAfterMigration.sdkVersion should] equal:PCFPushSDKVersion];
            [[theValue(PCFPushAnalyticsStorage.numberOfMigrationsExecuted) should] equal:theValue(0)];
        });

        it(@"V1 -> V3 should do migration", ^{

            selectDatabaseModelV1();

            [PCFPushAnalytics logReceivedRemoteNotification:@"TEST_RECEIPT_ID" parameters:parametersWithAnalyticsEnabled];

            NSArray *eventsBeforeMigration = [PCFPushAnalyticsStorage.shared events];
            [[eventsBeforeMigration should] haveCountOf:1];
            PCFPushAnalyticsEvent *eventBeforeMigration = eventsBeforeMigration.lastObject;
            [[eventBeforeMigration should] beKindOfClass:NSClassFromString(entityName)];
            [[eventBeforeMigration.eventType should] equal:PCF_PUSH_EVENT_TYPE_PUSH_NOTIFICATION_RECEIVED];

            [helper resetAnalyticsStorageButKeepDatabaseFile];

            selectDatabaseModelV3();

            [PCFPushPersistentStorage reset];

            NSArray *eventsAfterMigration = [PCFPushAnalyticsStorage.shared events];
            [[eventsAfterMigration should] haveCountOf:1];
            PCFPushAnalyticsEvent *eventAfterMigration = eventsAfterMigration.lastObject;
            [[eventAfterMigration should] beKindOfClass:NSClassFromString(entityName)];
            [[eventAfterMigration.eventType should] equal:PCF_PUSH_EVENT_TYPE_PUSH_NOTIFICATION_RECEIVED];
            [[eventAfterMigration.sdkVersion should] beNil];
            [[eventAfterMigration.platformType should] beNil];
            [[eventAfterMigration.platformUuid should] beNil];
            [[theValue(PCFPushAnalyticsStorage.numberOfMigrationsExecuted) should] equal:theValue(1)];
        });

        it(@"V2 -> V3 should do migration", ^{

            selectDatabaseModelV2();

            [PCFPushAnalytics logReceivedRemoteNotification:@"TEST_RECEIPT_ID" parameters:parametersWithAnalyticsEnabled];

            NSArray *eventsBeforeMigration = [PCFPushAnalyticsStorage.shared events];
            [[eventsBeforeMigration should] haveCountOf:1];
            PCFPushAnalyticsEvent *eventBeforeMigration = eventsBeforeMigration.lastObject;
            [[eventBeforeMigration should] beKindOfClass:NSClassFromString(entityName)];
            [[eventBeforeMigration.eventType should] equal:PCF_PUSH_EVENT_TYPE_PUSH_NOTIFICATION_RECEIVED];
            [[eventBeforeMigration.sdkVersion should] equal:PCFPushSDKVersion];

            [helper resetAnalyticsStorageButKeepDatabaseFile];

            selectDatabaseModelV3();

            [PCFPushPersistentStorage reset];

            NSArray *eventsAfterMigration = [PCFPushAnalyticsStorage.shared events];
            [[eventsAfterMigration should] haveCountOf:1];
            PCFPushAnalyticsEvent *eventAfterMigration = eventsAfterMigration.lastObject;
            [[eventAfterMigration should] beKindOfClass:NSClassFromString(entityName)];
            [[eventAfterMigration.eventType should] equal:PCF_PUSH_EVENT_TYPE_PUSH_NOTIFICATION_RECEIVED];
            [[eventAfterMigration.sdkVersion should] equal:PCFPushSDKVersion];
            [[eventAfterMigration.platformType should] beNil];
            [[eventAfterMigration.platformUuid should] beNil];
            [[theValue(PCFPushAnalyticsStorage.numberOfMigrationsExecuted) should] equal:theValue(1)];
        });

        it(@"V3 -> V3 should do migration", ^{

            selectDatabaseModelV3();

            [PCFPushAnalytics logReceivedRemoteNotification:@"TEST_RECEIPT_ID" parameters:parametersWithAnalyticsEnabled];

            NSArray *eventsBeforeMigration = [PCFPushAnalyticsStorage.shared events];
            [[eventsBeforeMigration should] haveCountOf:1];
            PCFPushAnalyticsEvent *eventBeforeMigration = eventsBeforeMigration.lastObject;
            [[eventBeforeMigration should] beKindOfClass:NSClassFromString(entityName)];
            [[eventBeforeMigration.eventType should] equal:PCF_PUSH_EVENT_TYPE_PUSH_NOTIFICATION_RECEIVED];
            [[eventBeforeMigration.sdkVersion should] equal:PCFPushSDKVersion];
            [[eventBeforeMigration.platformType should] equal:@"ios"];
            [[eventBeforeMigration.platformUuid should] equal:@"444-555-666-777"];

            [helper resetAnalyticsStorageButKeepDatabaseFile];

            [PCFPushPersistentStorage reset];

            NSArray *eventsAfterMigration = [PCFPushAnalyticsStorage.shared events];
            [[eventsAfterMigration should] haveCountOf:1];
            PCFPushAnalyticsEvent *eventAfterMigration = eventsAfterMigration.lastObject;
            [[eventAfterMigration should] beKindOfClass:NSClassFromString(entityName)];
            [[eventAfterMigration.eventType should] equal:PCF_PUSH_EVENT_TYPE_PUSH_NOTIFICATION_RECEIVED];
            [[eventAfterMigration.sdkVersion should] equal:PCFPushSDKVersion];
            [[eventAfterMigration.platformType should] equal:@"ios"];
            [[eventBeforeMigration.platformUuid should] equal:@"444-555-666-777"];
            [[theValue(PCFPushAnalyticsStorage.numberOfMigrationsExecuted) should] equal:theValue(0)];
        });
    });

    describe(@"checking polling time", ^{

        it(@"it should never be polling time if analytics are disabled", ^{
           [[theValue([PCFPushAnalytics isAnalyticsPollingTime:parametersWithAnalyticsDisabled]) should] beNo];
        });

        context(@"when analytics are enabled", ^{

            it(@"should be polling time if the server version has not been fetched before", ^{
                [PCFPushPersistentStorage setServerVersionTimePolled:nil];
                [[theValue([PCFPushAnalytics isAnalyticsPollingTime:parametersWithAnalyticsEnabled]) should] beYes];
            });

            it(@"should be polling time if the server version has been fetched more than 1 minute ago (debug mode)", ^{
                [PCFPushPersistentStorage setServerVersionTimePolled:[NSDate dateWithTimeIntervalSince1970:0]];
                [NSDate stub:@selector(date) andReturn:[NSDate dateWithTimeIntervalSince1970:(60 + 1)]];
                [[theValue([PCFPushAnalytics isAnalyticsPollingTime:parametersWithAnalyticsEnabled]) should] beYes];
            });

            it(@"should not be polling time if the server version has been fetched less than 1 minute ago (debug mode)", ^{
                [PCFPushPersistentStorage setServerVersionTimePolled:[NSDate dateWithTimeIntervalSince1970:0]];
                [NSDate stub:@selector(date) andReturn:[NSDate dateWithTimeIntervalSince1970:(60 - 1)]];
                [[theValue([PCFPushAnalytics isAnalyticsPollingTime:parametersWithAnalyticsEnabled]) should] beNo];
            });
        });
    });

    describe(@"logging an event", ^{

        beforeEach(^{
            [PCFPushPersistentStorage setServerVersion:@"1.3.2"];
            [NSDate stub:@selector(date) andReturn:[NSDate dateWithTimeIntervalSince1970:1337.0]];
        });

        describe(@"logging events", ^{

            it(@"should let you log an event successfully", ^{

                [PCFPushAnalytics logEvent:@"TEST_EVENT" parameters:parametersWithAnalyticsEnabled];

                NSArray *events = [PCFPushAnalyticsStorage.shared events];
                [[theValue(events.count) should] equal:theValue(1)];
                PCFPushAnalyticsEvent *event = events.lastObject;
                [[event should] beKindOfClass:NSClassFromString(entityName)];
                [[event.eventType should] equal:@"TEST_EVENT"];
                [[event.eventTime should] equal:@"1337000"];
                [[event.sdkVersion should] equal:PCFPushSDKVersion];
                [[event.status should] equal:@(PCFPushEventStatusNotPosted)];
            });

            it(@"should suppress logging if analytics are disabled", ^{

                [PCFPushAnalytics logEvent:@"TEST_EVENT" parameters:parametersWithAnalyticsDisabled];

                NSArray *events = [PCFPushAnalyticsStorage.shared events];
                [[events should] beEmpty];
            });

            it(@"should let you log several event successfully", ^{

                [PCFPushAnalytics logEvent:@"TEST_EVENT1" parameters:parametersWithAnalyticsEnabled];
                [PCFPushAnalytics logEvent:@"TEST_EVENT2" parameters:parametersWithAnalyticsEnabled];
                [PCFPushAnalytics logEvent:@"TEST_EVENT3" parameters:parametersWithAnalyticsEnabled];

                NSArray *events = [PCFPushAnalyticsStorage.shared events];
                [[theValue(events.count) should] equal:theValue(3)];
            });

            it(@"should let you set the event fields", ^{

                [PCFPushAnalytics logEvent:@"AMAZING_EVENT" fields:@{@"receiptId" : @"TEST_RECEIPT_ID", @"deviceUuid" : @"TEST_DEVICE_UUID", @"geofenceId" : @"TEST_GEOFENCE_ID", @"locationId" : @"TEST_LOCATION_ID"} parameters:parametersWithAnalyticsEnabled];

                NSArray *events = [PCFPushAnalyticsStorage.shared events];
                [[theValue(events.count) should] equal:theValue(1)];
                PCFPushAnalyticsEvent *event = events.lastObject;
                [[event should] beKindOfClass:NSClassFromString(entityName)];
                [[event.eventType should] equal:@"AMAZING_EVENT"];
                [[event.receiptId should] equal:@"TEST_RECEIPT_ID"];
                [[event.deviceUuid should] equal:@"TEST_DEVICE_UUID"];
                [[event.geofenceId should] equal:@"TEST_GEOFENCE_ID"];
                [[event.locationId should] equal:@"TEST_LOCATION_ID"];
                [[event.eventTime should] equal:@"1337000"];
                [[event.sdkVersion should] equal:PCFPushSDKVersion];
                [[event.platformType should] equal:@"ios"];
                [[event.platformUuid should] equal:@"444-555-666-777"];
                [[event.status should] equal:@(PCFPushEventStatusNotPosted)];
            });

            it(@"should let you log when remote notifications are received", ^{

                [PCFPushPersistentStorage setServerDeviceID:@"TEST_DEVICE_UUID"];

                [PCFPushAnalytics logReceivedRemoteNotification:@"TEST_RECEIPT_ID" parameters:parametersWithAnalyticsEnabled];

                NSArray *events = [PCFPushAnalyticsStorage.shared events];
                [[theValue(events.count) should] equal:theValue(1)];
                PCFPushAnalyticsEvent *event = events.lastObject;
                [[event should] beKindOfClass:NSClassFromString(entityName)];
                [[event.eventType should] equal:PCF_PUSH_EVENT_TYPE_PUSH_NOTIFICATION_RECEIVED];
                [[event.receiptId should] equal:@"TEST_RECEIPT_ID"];
                [[event.deviceUuid should] equal:@"TEST_DEVICE_UUID"];
                [[event.geofenceId should] beNil];
                [[event.locationId should] beNil];
                [[event.eventTime should] equal:@"1337000"];
                [[event.sdkVersion should] equal:PCFPushSDKVersion];
                [[event.platformType should] equal:@"ios"];
                [[event.platformUuid should] equal:@"444-555-666-777"];
                [[event.status should] equal:@(PCFPushEventStatusNotPosted)];
            });

            it(@"should let you log when remote notifications are opened", ^{

                [PCFPushPersistentStorage setServerDeviceID:@"TEST_DEVICE_UUID"];

                [PCFPushAnalytics logOpenedRemoteNotification:@"TEST_RECEIPT_ID" parameters:parametersWithAnalyticsEnabled];

                NSArray *events = [PCFPushAnalyticsStorage.shared events];
                [[theValue(events.count) should] equal:theValue(1)];
                PCFPushAnalyticsEvent *event = events.lastObject;
                [[event should] beKindOfClass:NSClassFromString(entityName)];
                [[event.eventType should] equal:PCF_PUSH_EVENT_TYPE_PUSH_NOTIFICATION_OPENED];
                [[event.receiptId should] equal:@"TEST_RECEIPT_ID"];
                [[event.deviceUuid should] equal:@"TEST_DEVICE_UUID"];
                [[event.geofenceId should] beNil];
                [[event.locationId should] beNil];
                [[event.eventTime should] equal:@"1337000"];
                [[event.sdkVersion should] equal:PCFPushSDKVersion];
                [[event.platformType should] equal:@"ios"];
                [[event.platformUuid should] equal:@"444-555-666-777"];
                [[event.status should] equal:@(PCFPushEventStatusNotPosted)];
            });

            it(@"should let you log when geofence is triggered", ^{

                [PCFPushPersistentStorage setServerDeviceID:@"TEST_DEVICE_UUID"];

                [PCFPushAnalytics logTriggeredGeofenceId:57L locationId:923L parameters:parametersWithAnalyticsEnabled];

                NSArray *events = [PCFPushAnalyticsStorage.shared events];
                [[theValue(events.count) should] equal:theValue(1)];
                PCFPushAnalyticsEvent *event = events.lastObject;
                [[event should] beKindOfClass:NSClassFromString(entityName)];
                [[event.eventType should] equal:PCF_PUSH_EVENT_TYPE_PUSH_GEOFENCE_LOCATION_TRIGGER];
                [[event.receiptId should] beNil];
                [[event.deviceUuid should] equal:@"TEST_DEVICE_UUID"];
                [[event.geofenceId should] equal:@"57"];
                [[event.locationId should] equal:@"923"];
                [[event.eventTime should] equal:@"1337000"];
                [[event.sdkVersion should] equal:PCFPushSDKVersion];
                [[event.platformType should] equal:@"ios"];
                [[event.platformUuid should] equal:@"444-555-666-777"];
                [[event.status should] equal:@(PCFPushEventStatusNotPosted)];
            });

            it(@"should let you log when a heartbeat is received", ^{

                [PCFPushPersistentStorage setServerDeviceID:@"TEST_DEVICE_UUID"];

                [PCFPushAnalytics logReceivedHeartbeat:@"TEST_RECEIPT_ID" parameters:parametersWithAnalyticsEnabled];

                NSArray *events = [PCFPushAnalyticsStorage.shared events];
                [[theValue(events.count) should] equal:theValue(1)];
                PCFPushAnalyticsEvent *event = events.lastObject;
                [[event should] beKindOfClass:NSClassFromString(entityName)];
                [[event.eventType should] equal:PCF_PUSH_EVENT_TYPE_PUSH_HEARTBEAT];
                [[event.receiptId should] equal:@"TEST_RECEIPT_ID"];
                [[event.deviceUuid should] equal:@"TEST_DEVICE_UUID"];
                [[event.geofenceId should] beNil];
                [[event.locationId should] beNil];
                [[event.eventTime should] equal:@"1337000"];
                [[event.sdkVersion should] equal:PCFPushSDKVersion];
                [[event.platformType should] equal:@"ios"];
                [[event.platformUuid should] equal:@"444-555-666-777"];
                [[event.status should] equal:@(PCFPushEventStatusNotPosted)];
            });
        });
    });

    describe(@"checking the server version", ^{

        beforeEach(^{
            [PCFPushPersistentStorage setServerVersion:nil];
            [PCFPushPersistentStorage setServerVersionTimePolled:nil];
        });

        it(@"should enable analytics if the version request returns a new version", ^{

            [helper setupVersionRequestWithBlock:^(void (^successBlock)(NSString *), void (^oldVersionBlock)(), void (^errorBlock)(NSError *)) {
                successBlock(@"5.32.80");
            }];

            [[PCFPushAnalytics should] receive:@selector(prepareEventsDatabase:)];

            [PCFPushAnalytics checkAnalytics:parametersWithAnalyticsEnabled];

            [[PCFPushPersistentStorage.serverVersion should] equal:@"5.32.80"];
            [[PCFPushPersistentStorage.serverVersionTimePolled shouldNot] beNil];
            [[theValue(parametersWithAnalyticsEnabled.areAnalyticsEnabledAndAvailable) should] beYes];
        });

        it(@"should disable analytics if the version request returns an old version", ^{

            [helper setupVersionRequestWithBlock:^(void (^successBlock)(NSString *), void (^oldVersionBlock)(), void (^errorBlock)(NSError *)) {
                oldVersionBlock();
            }];

            [[PCFPushAnalytics shouldNot] receive:@selector(prepareEventsDatabase:)];

            [PCFPushAnalytics checkAnalytics:parametersWithAnalyticsEnabled];

            [[PCFPushPersistentStorage.serverVersion should] beNil];
            [[PCFPushPersistentStorage.serverVersionTimePolled shouldNot] beNil];
            [[theValue(parametersWithAnalyticsEnabled.areAnalyticsEnabledAndAvailable) should] beNo];
        });

        it(@"should do nothing if the version request fails", ^{

            [PCFPushPersistentStorage setServerVersion:@"1.0.0"];
            [PCFPushPersistentStorage setServerVersionTimePolled:[NSDate dateWithTimeIntervalSince1970:50]];

            [helper setupVersionRequestWithBlock:^(void (^successBlock)(NSString *), void (^oldVersionBlock)(), void (^errorBlock)(NSError *)) {
                errorBlock([PCFPushErrorUtil errorWithCode:0 localizedDescription:nil]);
            }];

            [[PCFPushAnalytics shouldNot] receive:@selector(prepareEventsDatabase:)];

            [PCFPushAnalytics checkAnalytics:parametersWithAnalyticsEnabled];

            [[PCFPushPersistentStorage.serverVersion should] equal:@"1.0.0"];
            [[PCFPushPersistentStorage.serverVersionTimePolled should] equal:[NSDate dateWithTimeIntervalSince1970:50]];
            [[theValue(parametersWithAnalyticsEnabled.areAnalyticsEnabledAndAvailable) should] beNo];
        });
    });

    describe(@"preparing the events database", ^{

        it(@"should do nothing if the events database is empty", ^{
            [[PCFPushAnalyticsStorage.shared.events should] beEmpty];
            [PCFPushAnalytics prepareEventsDatabase:parametersWithAnalyticsEnabled];
            [[PCFPushAnalyticsStorage.shared.events should] beEmpty];
        });

        it(@"should set events with the 'posting' and 'posting error' statuses to 'not posted'", ^{

            [PCFPushPersistentStorage setServerVersion:@"1.3.2"];

            [PCFPushAnalytics logEvent:@"NOT_POSTED" parameters:parametersWithAnalyticsEnabled];
            [PCFPushAnalytics logEvent:@"POSTING" parameters:parametersWithAnalyticsEnabled];
            [PCFPushAnalytics logEvent:@"POSTED" parameters:parametersWithAnalyticsEnabled];
            [PCFPushAnalytics logEvent:@"POSTING_ERROR" parameters:parametersWithAnalyticsEnabled];

            PCFPushAnalyticsEvent *postingEvent = [PCFPushAnalyticsStorage.shared managedObjectsWithEntityName:entityName predicate:[NSPredicate predicateWithFormat:@"eventType == 'POSTING'"] fetchLimit:0][0];
            [PCFPushAnalyticsStorage.shared setEventsStatus:@[postingEvent] status:PCFPushEventStatusPosting];

            PCFPushAnalyticsEvent *postingErrorEvent = [PCFPushAnalyticsStorage.shared managedObjectsWithEntityName:entityName predicate:[NSPredicate predicateWithFormat:@"eventType == 'POSTING_ERROR'"] fetchLimit:0][0];
            [PCFPushAnalyticsStorage.shared setEventsStatus:@[postingErrorEvent] status:PCFPushEventStatusPostingError];

            PCFPushAnalyticsEvent *postedEvent = [PCFPushAnalyticsStorage.shared managedObjectsWithEntityName:entityName predicate:[NSPredicate predicateWithFormat:@"eventType == 'POSTED'"] fetchLimit:0][0];
            [PCFPushAnalyticsStorage.shared setEventsStatus:@[postedEvent] status:PCFPushEventStatusPosted];

            [[PCFPushAnalyticsStorage.shared.events should] haveCountOf:4];

            [[PCFPushAnalytics shouldNot] receive:@selector(sendEventsWithParameters:)];
            [[PCFPushAnalytics should] receive:@selector(sendEventsFromMainQueueWithParameters:)];

            [PCFPushAnalytics prepareEventsDatabase:parametersWithAnalyticsEnabled];

            [[PCFPushAnalyticsStorage.shared.events should] haveCountOf:4];

            NSArray *notPostedEventsAfter = [PCFPushAnalyticsStorage.shared eventsWithStatus:PCFPushEventStatusNotPosted];
            [[notPostedEventsAfter should] haveCountOf:3];

            NSArray *postingEventsAfter = [PCFPushAnalyticsStorage.shared eventsWithStatus:PCFPushEventStatusPosting];
            [[postingEventsAfter should] beEmpty];

            NSArray *postingErrorEventsAfter = [PCFPushAnalyticsStorage.shared eventsWithStatus:PCFPushEventStatusPostingError];
            [[postingErrorEventsAfter should] beEmpty];

            NSArray *postedEventsAfter = [PCFPushAnalyticsStorage.shared eventsWithStatus:PCFPushEventStatusPosted];
            [[postedEventsAfter should] haveCountOf:1];
        });
    });

    describe(@"sending events", ^{

        beforeEach(^{
            [PCFPushPersistentStorage setServerVersion:@"1.3.2"];
            [PCFPushPersistentStorage setServerDeviceID:TEST_DEVICE_UUID];
        });

        it(@"should do nothing if analytics is disabled", ^{

            [PCFPushAnalytics logEvent:@"TEST_EVENT1" parameters:parametersWithAnalyticsEnabled];

            [helper setupAsyncRequestWithBlock:^(NSURLRequest *request, NSURLResponse **resultResponse, NSData **resultData, NSError **resultError) {
                fail(@"Should not have made request");
            }];

            [PCFPushAnalytics sendEventsWithParameters:parametersWithAnalyticsDisabled];
            [[PCFPushAnalyticsStorage.shared.events should] haveCountOf:1];
        });

        it(@"should do nothing if the events database is empty", ^{

            [helper setupAsyncRequestWithBlock:^(NSURLRequest *request, NSURLResponse **resultResponse, NSData **resultData, NSError **resultError) {
                fail(@"Should not have made request");
            }];

            [PCFPushAnalytics sendEventsWithParameters:parametersWithAnalyticsDisabled];
            [[PCFPushAnalyticsStorage.shared.events should] beEmpty];
        });

        it(@"should send 'notification opened', 'geofence location trigger' and 'heartbeat' events to the server and delete them after they are posted successfully", ^{

            __block BOOL didMakeRequest = NO;

            [helper setupAsyncRequestWithBlock:^(NSURLRequest *request, NSURLResponse **resultResponse, NSData **resultData, NSError **resultError) {
                didMakeRequest = YES;

                [[request.HTTPMethod should] equal:@"POST"];

                [[request.HTTPBody shouldNot] beNil];
                NSError *error;
                id json = [NSJSONSerialization JSONObjectWithData:request.HTTPBody options:0 error:&error];
                [[json shouldNot] beNil];
                [[error should] beNil];

                NSArray *events = PCFPushAnalyticsStorage.shared.events;
                [[events should] haveCountOf:3];
                [[[events[0] status] should] equal:@(PCFPushEventStatusPosting)];
                [[[events[1] status] should] equal:@(PCFPushEventStatusPosting)];
                [[[events[2] status] should] equal:@(PCFPushEventStatusPosting)];

                *resultResponse = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@""]  statusCode:200 HTTPVersion:nil headerFields:nil];
            }];

            [PCFPushAnalytics logTriggeredGeofenceId:22L locationId:33L parameters:parametersWithAnalyticsEnabled];
            [PCFPushAnalytics logReceivedHeartbeat:@"RECEIPT1" parameters:parametersWithAnalyticsEnabled];
            [PCFPushAnalytics logOpenedRemoteNotification:@"RECEIPT2" parameters:parametersWithAnalyticsEnabled];
            [[PCFPushAnalyticsStorage.shared.events should] haveCountOf:3];

            [PCFPushAnalytics sendEventsWithParameters:parametersWithAnalyticsEnabled];

            [[theValue(didMakeRequest) should] beTrue];
            [[PCFPushAnalyticsStorage.shared.events should] beEmpty];
        });

        it(@"should set the status of 'notification received' events to 'posted' after they are sent successfully", ^{

            __block BOOL didMakeRequest = NO;

            [helper setupAsyncRequestWithBlock:^(NSURLRequest *request, NSURLResponse **resultResponse, NSData **resultData, NSError **resultError) {
                didMakeRequest = YES;

                [[request.HTTPMethod should] equal:@"POST"];

                [[request.HTTPBody shouldNot] beNil];
                NSError *error;
                id json = [NSJSONSerialization JSONObjectWithData:request.HTTPBody options:0 error:&error];
                [[json shouldNot] beNil];
                [[error should] beNil];

                NSArray *events = PCFPushAnalyticsStorage.shared.events;
                [[events should] haveCountOf:1];
                [[[events[0] status] should] equal:@(PCFPushEventStatusPosting)];

                *resultResponse = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@""]  statusCode:200 HTTPVersion:nil headerFields:nil];
            }];

            [PCFPushAnalytics logReceivedRemoteNotification:@"RECEIPT1" parameters:parametersWithAnalyticsEnabled];
            [[PCFPushAnalyticsStorage.shared.events should] haveCountOf:1];

            [PCFPushAnalytics sendEventsWithParameters:parametersWithAnalyticsEnabled];

            [[theValue(didMakeRequest) should] beTrue];
            NSArray *events = PCFPushAnalyticsStorage.shared.events;
            [[events should] haveCountOf:1];
            [[[events[0] status] should] equal:@(PCFPushEventStatusPosted)];
        });

        it(@"should clean up 'notification received' events if they are sent at the same times as 'notification opened' events with the same receipt id", ^{

            __block BOOL didMakeRequest = NO;

            [helper setupAsyncRequestWithBlock:^(NSURLRequest *request, NSURLResponse **resultResponse, NSData **resultData, NSError **resultError) {
                didMakeRequest = YES;

                [[request.HTTPMethod should] equal:@"POST"];

                [[request.HTTPBody shouldNot] beNil];
                NSError *error;
                id json = [NSJSONSerialization JSONObjectWithData:request.HTTPBody options:0 error:&error];
                [[json shouldNot] beNil];
                [[error should] beNil];

                NSArray *events = PCFPushAnalyticsStorage.shared.events;
                [[events should] haveCountOf:2];
                [[[events[0] status] should] equal:@(PCFPushEventStatusPosting)];
                [[[events[1] status] should] equal:@(PCFPushEventStatusPosting)];

                *resultResponse = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@""]  statusCode:200 HTTPVersion:nil headerFields:nil];
            }];

            [PCFPushAnalytics logReceivedRemoteNotification:@"RECEIPT1" parameters:parametersWithAnalyticsEnabled];
            [PCFPushAnalytics logOpenedRemoteNotification:@"RECEIPT1" parameters:parametersWithAnalyticsEnabled];
            [[PCFPushAnalyticsStorage.shared.events should] haveCountOf:2];

            [PCFPushAnalytics sendEventsWithParameters:parametersWithAnalyticsEnabled];

            [[theValue(didMakeRequest) should] beTrue];
            [[PCFPushAnalyticsStorage.shared.events should] beEmpty];
        });

        it(@"should keep 'notification received' events if they have a different receipt id from the 'notification opened' events being sent at the same time", ^{

            __block BOOL didMakeRequest = NO;

            [helper setupAsyncRequestWithBlock:^(NSURLRequest *request, NSURLResponse **resultResponse, NSData **resultData, NSError **resultError) {
                didMakeRequest = YES;

                [[request.HTTPMethod should] equal:@"POST"];

                [[request.HTTPBody shouldNot] beNil];
                NSError *error;
                id json = [NSJSONSerialization JSONObjectWithData:request.HTTPBody options:0 error:&error];
                [[json shouldNot] beNil];
                [[error should] beNil];

                NSArray *events = PCFPushAnalyticsStorage.shared.events;
                [[events should] haveCountOf:2];
                [[[events[0] status] should] equal:@(PCFPushEventStatusPosting)];
                [[[events[1] status] should] equal:@(PCFPushEventStatusPosting)];

                *resultResponse = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@""]  statusCode:200 HTTPVersion:nil headerFields:nil];
            }];

            [PCFPushAnalytics logReceivedRemoteNotification:@"RECEIPT2" parameters:parametersWithAnalyticsEnabled];
            [PCFPushAnalytics logOpenedRemoteNotification:@"RECEIPT1" parameters:parametersWithAnalyticsEnabled];
            [[PCFPushAnalyticsStorage.shared.events should] haveCountOf:2];

            [PCFPushAnalytics sendEventsWithParameters:parametersWithAnalyticsEnabled];

            [[theValue(didMakeRequest) should] beTrue];
            [[PCFPushAnalyticsStorage.shared.events should] haveCountOf:1];
            [[PCFPushAnalyticsStorage.shared.events[0].receiptId should] equal:@"RECEIPT2"];
            [[PCFPushAnalyticsStorage.shared.events[0].eventType should] equal:PCF_PUSH_EVENT_TYPE_PUSH_NOTIFICATION_RECEIVED];
        });

        it(@"should delete posted 'notification received' events from the store when it receives a 'notification opened' event with the same receipt id", ^{

            __block BOOL didMakeRequest = NO;

            [helper setupAsyncRequestWithBlock:^(NSURLRequest *request, NSURLResponse **resultResponse, NSData **resultData, NSError **resultError) {
                didMakeRequest = YES;

                [[request.HTTPMethod should] equal:@"POST"];

                [[request.HTTPBody shouldNot] beNil];
                NSError *error;
                id json = [NSJSONSerialization JSONObjectWithData:request.HTTPBody options:0 error:&error];
                [[json shouldNot] beNil];
                [[error should] beNil];

                NSArray *events = PCFPushAnalyticsStorage.shared.events;
                [[events should] haveCountOf:2];
                [[[events[0] status] should] equal:@(PCFPushEventStatusPosted)];
                [[[events[1] status] should] equal:@(PCFPushEventStatusPosting)];

                *resultResponse = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@""]  statusCode:200 HTTPVersion:nil headerFields:nil];
            }];

            [PCFPushAnalytics logReceivedRemoteNotification:@"RECEIPT1" parameters:parametersWithAnalyticsEnabled];
            [PCFPushAnalyticsStorage.shared setEventsStatus:PCFPushAnalyticsStorage.shared.events status:PCFPushEventStatusPosted];

            [PCFPushAnalytics logOpenedRemoteNotification:@"RECEIPT1" parameters:parametersWithAnalyticsEnabled];
            [[PCFPushAnalyticsStorage.shared.events should] haveCountOf:2];

            [PCFPushAnalytics sendEventsWithParameters:parametersWithAnalyticsEnabled];

            [[theValue(didMakeRequest) should] beTrue];
            [[PCFPushAnalyticsStorage.shared.events should] beEmpty];
        });

        it(@"should not delete 'notification received' from storage when it receives a 'notification opened' event with a different receipt id", ^{

            __block BOOL didMakeRequest = NO;

            [helper setupAsyncRequestWithBlock:^(NSURLRequest *request, NSURLResponse **resultResponse, NSData **resultData, NSError **resultError) {
                didMakeRequest = YES;

                [[request.HTTPMethod should] equal:@"POST"];

                [[request.HTTPBody shouldNot] beNil];
                NSError *error;
                id json = [NSJSONSerialization JSONObjectWithData:request.HTTPBody options:0 error:&error];
                [[json shouldNot] beNil];
                [[error should] beNil];

                NSArray *events = PCFPushAnalyticsStorage.shared.events;
                [[events should] haveCountOf:2];
                [[[events[0] status] should] equal:@(PCFPushEventStatusPosted)];
                [[[events[1] status] should] equal:@(PCFPushEventStatusPosting)];

                *resultResponse = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@""]  statusCode:200 HTTPVersion:nil headerFields:nil];
            }];

            [PCFPushAnalytics logReceivedRemoteNotification:@"RECEIPT2" parameters:parametersWithAnalyticsEnabled];
            [PCFPushAnalyticsStorage.shared setEventsStatus:PCFPushAnalyticsStorage.shared.events status:PCFPushEventStatusPosted];

            [PCFPushAnalytics logOpenedRemoteNotification:@"RECEIPT1" parameters:parametersWithAnalyticsEnabled];
            [[PCFPushAnalyticsStorage.shared.events should] haveCountOf:2];

            [PCFPushAnalytics sendEventsWithParameters:parametersWithAnalyticsEnabled];

            [[theValue(didMakeRequest) should] beTrue];
            [[PCFPushAnalyticsStorage.shared.events should] haveCountOf:1];
            [[PCFPushAnalyticsStorage.shared.events[0].receiptId should] equal:@"RECEIPT2"];
            [[PCFPushAnalyticsStorage.shared.events[0].eventType should] equal:PCF_PUSH_EVENT_TYPE_PUSH_NOTIFICATION_RECEIVED];
        });

        it(@"should mark events with an error status if they fail to send", ^{

            __block BOOL didMakeRequest = NO;

            [helper setupAsyncRequestWithBlock:^(NSURLRequest *request, NSURLResponse **resultResponse, NSData **resultData, NSError **resultError) {
                didMakeRequest = YES;

                NSArray *events = PCFPushAnalyticsStorage.shared.events;
                [[events should] haveCountOf:4];
                [[[events[0] status] should] equal:@(PCFPushEventStatusPosting)];
                [[[events[1] status] should] equal:@(PCFPushEventStatusPosting)];
                [[[events[2] status] should] equal:@(PCFPushEventStatusPosting)];
                [[[events[3] status] should] equal:@(PCFPushEventStatusPosting)];

                *resultResponse = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@""]  statusCode:500 HTTPVersion:nil headerFields:nil];
            }];

            [PCFPushAnalytics logEvent:PCF_PUSH_EVENT_TYPE_PUSH_GEOFENCE_LOCATION_TRIGGER parameters:parametersWithAnalyticsEnabled];
            [PCFPushAnalytics logEvent:PCF_PUSH_EVENT_TYPE_PUSH_HEARTBEAT parameters:parametersWithAnalyticsEnabled];
            [PCFPushAnalytics logEvent:PCF_PUSH_EVENT_TYPE_PUSH_NOTIFICATION_RECEIVED parameters:parametersWithAnalyticsEnabled];
            [PCFPushAnalytics logEvent:PCF_PUSH_EVENT_TYPE_PUSH_NOTIFICATION_OPENED parameters:parametersWithAnalyticsEnabled];
            [[PCFPushAnalyticsStorage.shared.events should] haveCountOf:4];

            [PCFPushAnalytics sendEventsWithParameters:parametersWithAnalyticsEnabled];

            [[theValue(didMakeRequest) should] beTrue];
            NSArray *events = PCFPushAnalyticsStorage.shared.events;
            [[events should] haveCountOf:4];
            [[[events[0] status] should] equal:@(PCFPushEventStatusPostingError)];
            [[[events[1] status] should] equal:@(PCFPushEventStatusPostingError)];
            [[[events[2] status] should] equal:@(PCFPushEventStatusPostingError)];
            [[[events[3] status] should] equal:@(PCFPushEventStatusPostingError)];
        });
    });

    describe(@"cleaning up the events database", ^{

        it(@"should remove the one oldest item when adding one new item when the database is at capacity", ^{

            [PCFPushAnalyticsStorage stub:@selector(maximumNumberOfEvents) andReturn:theValue(3)];
            [PCFPushPersistentStorage setServerVersion:@"1.3.2"];

            [PCFPushAnalytics logEvent:@"EVENT1" parameters:parametersWithAnalyticsEnabled];

            [[PCFPushAnalyticsStorage.shared.events should] haveCountOf:1];

            [PCFPushAnalytics logEvent:@"EVENT2" parameters:parametersWithAnalyticsEnabled];

            [[PCFPushAnalyticsStorage.shared.events should] haveCountOf:2];

            [PCFPushAnalytics logEvent:@"EVENT3" parameters:parametersWithAnalyticsEnabled];

            [[PCFPushAnalyticsStorage.shared.events should] haveCountOf:3];

            [PCFPushAnalytics logEvent:@"EVENT4" parameters:parametersWithAnalyticsEnabled];

            [[PCFPushAnalyticsStorage.shared.events should] haveCountOf:3];

            [PCFPushAnalytics logEvent:@"EVENT5" parameters:parametersWithAnalyticsEnabled];

            [[PCFPushAnalyticsStorage.shared.events should] haveCountOf:3];

            NSArray<PCFPushAnalyticsEvent*> *events = PCFPushAnalyticsStorage.shared.events;
            [[events[0].eventType should] equal:@"EVENT3"];
            [[events[1].eventType should] equal:@"EVENT4"];
            [[events[2].eventType should] equal:@"EVENT5"];
        });
    });

SPEC_END