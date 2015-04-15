//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef PCF_STR_PROP
#define PCF_STR_PROP( prop ) NSStringFromSelector(@selector(prop))
#define PCF_STRUCT_STRING __unsafe_unretained NSString
#endif

@protocol PCFMapping <NSObject>

+ (NSDictionary *)localToRemoteMapping;

@optional

- (BOOL)handleDeserializingProperty:(NSString *)propertyName value:(id)value;
- (BOOL)handleSerializingProperty:(NSString *)propertyName value:(id)value destination:(NSMutableDictionary *)destination;

@end
