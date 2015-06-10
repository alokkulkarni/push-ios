//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSSet *pcfPushLowercaseTags(NSSet *tags);

@interface PCFTagsHelper : NSObject

@property (nonatomic) NSSet *subscribeTags;
@property (nonatomic) NSSet *unsubscribeTags;

+ (instancetype) tagsHelperWithSavedTags:(NSSet*)savedTags newTags:(NSSet*)newTags;

@end
