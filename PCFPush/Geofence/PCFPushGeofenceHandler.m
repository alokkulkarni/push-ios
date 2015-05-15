//
// Created by DX173-XL on 2015-05-04.
// Copyright (c) 2015 Pivotal. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "PCFPushGeofenceHandler.h"
#import "PCFPushGeofencePersistentStore.h"
#import "PCFPushGeofenceLocationMap.h"
#import "PCFPushGeofenceData.h"
#import "PCFPushPersistentStorage.h"
#import "PCFPushGeofenceEngine.h"
#import "PCFPushDebug.h"
#import "PCFPushGeofenceLocation.h"
#import "PCFPushGeofenceRegistrar.h"
#import "PCFPushGeofenceDataList.h"
#import "PCFPushGeofenceUtil.h"

@interface PCFPushGeofenceHandler()

@property (nonatomic) PCFPushGeofencePersistentStore *store;

@end

static BOOL isUserSubscribedToGeofenceTag(PCFPushGeofenceData *geofence, NSSet *subscribedTags)
{
    if (geofence.tags) {
        BOOL intersects = [subscribedTags intersectsSet:geofence.tags];
        if (!intersects) {
            PCFPushLog(@"Ignoring geofence %lld. Not subscribed to any of its tags.", geofence.id);
        }
        return intersects;
    } else {
        return YES;
    }
}

static BOOL shouldTriggerNotification(PCFPushGeofenceData *geofence, CLRegionState state)
{
    if (state == CLRegionStateUnknown) {
        return NO;
    }

    NSSet *subscribedTags = [PCFPushPersistentStorage tags];
    if (!isUserSubscribedToGeofenceTag(geofence, subscribedTags)) {
        return NO;
    }

    if (geofence.triggerType == PCFPushTriggerTypeEnter) {
        return CLRegionStateInside == state;
    } else if (geofence.triggerType == PCFPushTriggerTypeExit) {
        return CLRegionStateOutside == state;
    } else {
        return NO;
    }
}

static NSDictionary *dictionaryWithTriggerCondition(NSDictionary* dictionary, CLRegionState state)
{
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithDictionary:dictionary];
    switch (state) {
        case CLRegionStateInside:
            result[@"pivotal.push.geofence_trigger_condition"] = @"enter";
            break;
        case CLRegionStateOutside:
            result[@"pivotal.push.geofence_trigger_condition"] = @"exit";
            break;
        default:
            break;
    }
    return result;
}

static UILocalNotification *notificationFromGeofence(PCFPushGeofenceData *geofence, CLRegionState state)
{
    UILocalNotification *notification = [[UILocalNotification alloc] init];

    // < iOS 8.0
    notification.alertAction = geofence.data[@"ios"][@"alertAction"];
    notification.alertBody = geofence.data[@"ios"][@"alertBody"];
    notification.alertLaunchImage = geofence.data[@"ios"][@"alertLaunchImage"];
    notification.hasAction = [geofence.data[@"ios"][@"hasAction"] boolValue];
    notification.applicationIconBadgeNumber = [geofence.data[@"ios"][@"applicationIconBadgeNumber"] integerValue];
    notification.soundName = geofence.data[@"ios"][@"soundName"];
    notification.userInfo = dictionaryWithTriggerCondition(geofence.data[@"ios"][@"userInfo"], state);

    // iOS 8.0+
    if([notification respondsToSelector:@selector(setCategory:)]) {
        notification.category = geofence.data[@"ios"][@"category"];
    }

    // iOS 8.2+
    if([notification respondsToSelector:@selector(setAlertTitle:)]) {
        notification.alertTitle = geofence.data[@"ios"][@"alertTitle"];
    }

    return notification;
}

static void clearGeofence(PCFPushGeofenceData *geofence, PCFPushGeofenceEngine *engine)
{
    PCFPushGeofenceLocationMap *locationsToClear = [PCFPushGeofenceLocationMap map];
    for (PCFPushGeofenceLocation *location in geofence.locations) {
        if (location.id >= 0) {
            PCFPushLog(@"Clearing geofence location from monitor: %@", pcfPushRequestIdWithGeofenceId(geofence.id, location.id));
            [locationsToClear put:geofence location:location];
        }
    }
    [engine clearLocations:locationsToClear];
}

static void clearLocation(NSString *requestId, PCFPushGeofenceData *geofence, PCFPushGeofenceEngine *engine)
{
    int64_t locationId = pcfPushLocationIdForRequestId(requestId);
    if (locationId >= 0) {
        for (PCFPushGeofenceLocation *location in geofence.locations) {
            if (location.id == locationId) {
                PCFPushLog(@"Clearing geofence from monitor: %@", requestId);
                PCFPushGeofenceLocationMap *locationToClear = [PCFPushGeofenceLocationMap map];
                [locationToClear put:geofence location:location];
                [engine clearLocations:locationToClear];
                break;
            }
        }
    }
}

@implementation PCFPushGeofenceHandler

+ (void)processRegion:(CLRegion *)region store:(PCFPushGeofencePersistentStore *)store engine:(PCFPushGeofenceEngine *)engine state:(CLRegionState)state
{
    if (!store) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"store may not be nil" userInfo:nil];
    }

    if (!engine) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"engine may not be nil" userInfo:nil];
    }

    if (!region || !region.identifier || region.identifier.length <= 0) {
        return;
    }
    
    int64_t geofenceId = pcfPushGeofenceIdForRequestId(region.identifier);
    if (geofenceId < 0) {
        return;
    }

    PCFPushGeofenceData *geofence = store[@(geofenceId)];

    if (!geofence) {
        return;
    }

    if (pcfPushIsItemExpired(geofence)) {

        PCFPushLog(@"Geofence '%@' has expired. Clearing geofence.", region.identifier);
        clearGeofence(geofence, engine); // Clears all the locations at the same geofence since they expire at the same time.

    } else if (shouldTriggerNotification(geofence, state)) {

        PCFPushLog(@"Triggering geofence '%@'.", region.identifier);
        UILocalNotification *localNotification = notificationFromGeofence(geofence, state);
        [UIApplication.sharedApplication presentLocalNotificationNow:localNotification];
        clearLocation(region.identifier, geofence, engine); // Clear just this one location.
    }
}

+ (void) checkGeofencesForNewlySubscribedTagsWithStore:(PCFPushGeofencePersistentStore *)store locationManager:(CLLocationManager *)locationManager
{
    PCFPushGeofenceDataList *geofences = [store currentlyRegisteredGeofences];
    NSSet *subscribedTags = [PCFPushPersistentStorage tags];
    [geofences enumerateKeysAndObjectsUsingBlock:^(int64_t geofenceId, PCFPushGeofenceData *geofence, BOOL *stop) {
        if (isUserSubscribedToGeofenceTag(geofence, subscribedTags)) {
            for (PCFPushGeofenceLocation *location in geofence.locations) {
                NSString *requestId = pcfPushRequestIdWithGeofenceId(geofenceId, location.id);
                CLRegion *region = pcfPushRegionForLocation(requestId, geofence, location);
                [locationManager requestStateForRegion:region];
            }
        }
    }];
}
@end