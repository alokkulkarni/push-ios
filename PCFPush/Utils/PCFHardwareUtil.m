//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PCFHardwareUtil.h"
#include <sys/sysctl.h>

#define STATIC_VARIABLE(VARIABLENAME, VARIABLEVALUE)       \
static NSString *VARIABLENAME;                             \
static dispatch_once_t onceToken;                          \
dispatch_once(&onceToken, ^{                               \
    VARIABLENAME = VARIABLEVALUE;                          \
});                                                        \
return VARIABLENAME;                                       \

@implementation PCFHardwareUtil

+ (NSString *)operatingSystem
{
    STATIC_VARIABLE(operatingSystem, @"ios");
}

+ (NSString *)operatingSystemVersion
{
    STATIC_VARIABLE(operatingSystemVersion, [[UIDevice currentDevice] systemVersion]);
}

+ (NSString *)deviceModel
{
    STATIC_VARIABLE(deviceModel, [PCFHardwareUtil hardwareSimpleDescription]);
}

+ (NSString *)deviceManufacturer
{
    STATIC_VARIABLE(deviceManufacturer, @"Apple");
}

+ (NSString *)hardwareString
{
    size_t size = 100;
    char *hw_machine = malloc(size);
    int name[] = {CTL_HW,HW_MACHINE};
    sysctl(name, 2, hw_machine, &size, NULL, 0);
    NSString *hardware = [NSString stringWithUTF8String:hw_machine];
    free(hw_machine);
    return hardware;
}

+ (BOOL) isSimulator
{
    NSString *hardware = [self hardwareString];
    return [hardware isEqualToString:@"i386"] || [hardware isEqualToString:@"x86_64"];
}

+ (NSString *)hardwareSimpleDescription
{
    static NSDictionary *hardwareDescriptionDictionary = nil;
    
    if (!hardwareDescriptionDictionary) {
        hardwareDescriptionDictionary = @{
                                          @"iPhone1,1" : @"iPhone 2G",
                                          @"iPhone1,2" : @"iPhone 3G",
                                          @"iPhone2,1" : @"iPhone 3GS",
                                          @"iPhone3,1" : @"iPhone 4",
                                          @"iPhone3,2" : @"iPhone 4",
                                          @"iPhone3,3" : @"iPhone 4",
                                          @"iPhone4,1" : @"iPhone 4S",
                                          @"iPhone5,1" : @"iPhone 5",
                                          @"iPhone5,2" : @"iPhone 5",
                                          @"iPhone5,3" : @"iPhone 5C",
                                          @"iPhone5,4" : @"iPhone 5C",
                                          @"iPhone6,1" : @"iPhone 5S",
                                          @"iPhone6,2" : @"iPhone 5S",
                                          @"iPhone7,1" : @"iPhone 6 Plus",
                                          @"iPhone7,2" : @"iPhone 6",
                                          @"iPhone8,1" : @"iPhone 6",
                                          @"iPhone8,2" : @"iPhone 6 Plus",
                                          @"iPhone8,4" : @"iPhone SE",
                                          @"iPhone9,1" : @"iPhone 7",
                                          @"iPhone9,2" : @"iPhone 7 Plus",
                                          @"iPhone9,3" : @"iPhone 7",
                                          @"iPhone9,4" : @"iPhone 7 Plus",
                                          @"iPod1,1" : @"iPod Touch (1 Gen)",
                                          @"iPod2,1" : @"iPod Touch (2 Gen)",
                                          @"iPod3,1" : @"iPod Touch (3 Gen)",
                                          @"iPod4,1" : @"iPod Touch (4 Gen)",
                                          @"iPod5,1" : @"iPod Touch (5 Gen)",
                                          @"iPad1,1" : @"iPad",
                                          @"iPad1,2" : @"iPad",
                                          @"iPad2,1" : @"iPad 2",
                                          @"iPad2,2" : @"iPad 2",
                                          @"iPad2,3" : @"iPad 2",
                                          @"iPad2,4" : @"iPad 2",
                                          @"iPad2,5" : @"iPad Mini",
                                          @"iPad2,6" : @"iPad Mini",
                                          @"iPad2,7" : @"iPad Mini",
                                          @"iPad3,1" : @"iPad 3",
                                          @"iPad3,2" : @"iPad 3",
                                          @"iPad3,3" : @"iPad 3",
                                          @"iPad3,4" : @"iPad 4",
                                          @"iPad3,5" : @"iPad 4",
                                          @"iPad3,6" : @"iPad 4",
                                          @"iPad4,1" : @"iPad Air",
                                          @"iPad4,2" : @"iPad Air",
                                          @"iPad4,3" : @"iPad Air",
                                          @"iPad4,4" : @"iPad Mini 2",
                                          @"iPad4,5" : @"iPad Mini 2",
                                          @"iPad4,6" : @"iPad Mini 2",
                                          @"iPad4,7" : @"iPad Mini 3",
                                          @"iPad4,8" : @"iPad Mini 3",
                                          @"iPad4,9" : @"iPad Mini 3",
                                          @"iPad5,1" : @"iPad Mini 4",
                                          @"iPad5,2" : @"iPad Mini 4",
                                          @"iPad5,3" : @"iPad Air 2",
                                          @"iPad5,4" : @"iPad Air 2",
                                          @"iPad6,3" : @"iPad Pro 9.7-inch",
                                          @"iPad6,4" : @"iPad Pro 9.7-inch",
                                          @"iPad6,7" : @"iPad Pro 12-inch",
                                          @"iPad6,8" : @"iPad Pro 12-inch",
                                          @"i386" : @"Simulator",
                                          @"x86_64" : @"Simulator",
                                          };
    }
    
    NSString *hardware = [self hardwareString];
    NSString *description = hardwareDescriptionDictionary[hardware];
    
    if (description) {
        return description;
    }
    
    NSLog(@"Your device hardware string is: %@", hardware);
    
    if ([hardware hasPrefix:@"iPhone"]) {
        return @"iPhone";
    }
    if ([hardware hasPrefix:@"iPod"]) {
        return @"iPod";
    }
    if ([hardware hasPrefix:@"iPad"]) {
        return @"iPad";
    }

    return nil;
}

@end
