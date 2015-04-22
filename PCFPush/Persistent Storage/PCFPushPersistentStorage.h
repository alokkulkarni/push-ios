//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PCFPushPersistentStorage : NSObject

+ (void)setAPNSDeviceToken:(NSData *)apnsDeviceToken;
+ (NSData *)APNSDeviceToken;

+ (void)setVariantUUID:(NSString *)variantUUID;
+ (NSString *)variantUUID;

+ (void)setVariantSecret:(NSString *)variantSecret;
+ (NSString *)variantSecret;

+ (void)setDeviceAlias:(NSString *)deviceAlias;
+ (NSString *)deviceAlias;

+ (void)setServerDeviceID:(NSString *)serverDeviceID;
+ (NSString *)serverDeviceID;

+ (void)setTags:(NSSet *)tags;
+ (NSSet *)tags;

+ (void)setLastModifiedTime:(int64_t)lastModifiedTime;
+ (int64_t)lastModifiedTime;

+ (void)reset;

+ (void)persistValue:(id)value forKey:(id)key;
+ (id)persistedValueForKey:(id)key;
+ (void)removeObjectForKey:(id)key;

@end
