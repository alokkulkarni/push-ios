//
// Created by DX173-XL on 15-05-13.
// Copyright (c) 2015 Pivotal. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PCFPushGeofenceData;
@class PCFPushGeofenceLocation;
@class CLRegion;

#define PCF_PUSH_NO_LOCATION_ID -1
#define PCF_PUSH_NO_GEOFENCE_ID -1

extern BOOL pcfPushIsItemExpired(PCFPushGeofenceData *geofence);

extern CLRegion *pcfPushRegionForLocation(NSString *requestId, PCFPushGeofenceData *geofence, PCFPushGeofenceLocation *location);

extern int64_t pcfPushGeofenceIdForRequestId(NSString *requestId);

extern int64_t pcfPushLocationIdForRequestId(NSString *requestId);

extern NSString *pcfPushRequestIdWithGeofenceId(int64_t geofenceId, int64_t locationId);

extern NSString* pcfPushGeofencesPath(NSFileManager *fileManager);

