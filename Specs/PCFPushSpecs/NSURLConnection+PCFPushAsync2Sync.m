//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import "NSURLConnection+PCFPushAsync2Sync.h"
#import "PCFPushBackEndRegistrationResponseDataTest.h"
#import "PCFPushSpecsHelper.h"
#import "PCFPushRegistrationData.h"

@implementation NSURLConnection (PCFPushAsync2Sync)

+ (void) successfulRequest:(NSURLRequest *)request
                     queue:(NSOperationQueue *)queue
         completionHandler:(void (^)(NSURLResponse *response, NSData *data, NSError *connectionError)) handler
{
    NSHTTPURLResponse *newResponse = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:200 HTTPVersion:nil headerFields:nil];
    NSDictionary *dict = @{
                           PCFPushRegistrationAttributes.deviceOS           : TEST_OS,
                           PCFPushRegistrationAttributes.deviceOSVersion    : TEST_OS_VERSION,
                           PCFPushRegistrationAttributes.deviceAlias        : TEST_DEVICE_ALIAS,
                           PCFPushRegistrationAttributes.deviceManufacturer : TEST_DEVICE_MANUFACTURER,
                           PCFPushRegistrationAttributes.deviceModel        : TEST_DEVICE_MODEL,
                           PCFPushRegistrationAttributes.variantUUID        : TEST_VARIANT_UUID,
                           PCFPushRegistrationAttributes.registrationToken  : TEST_REGISTRATION_TOKEN,
                           kPCFPushDeviceUUID                               : TEST_DEVICE_UUID,
                           };
    NSError *error;
    NSData *newData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
    handler(newResponse, newData, nil);
}


+ (void) failedRequestRequest:(NSURLRequest *)request
                        queue:(NSOperationQueue *)queue
            completionHandler:(void (^)(NSURLResponse *response, NSData *data, NSError *connectionError)) handler;
{
    NSDictionary *userInfo = @{
                               @"NSLocalizedDescription" : @"bad URL",
                               @"NSUnderlyingError" : [NSError errorWithDomain:(NSString *)kCFErrorDomainCFNetwork code:1000 userInfo:@{@"NSLocalizedDescription" : @"bad URL"}],
                               };
    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:1000 userInfo:userInfo];
    handler(nil, nil, error);
}

+ (void) HTTPErrorResponseRequest:(NSURLRequest *)request
                            queue:(NSOperationQueue *)queue
                completionHandler:(void (^)(NSURLResponse *response, NSData *data, NSError *connectionError)) handler
{
    NSHTTPURLResponse *newResponse = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:400 HTTPVersion:nil headerFields:nil];
    handler(newResponse, nil, nil);
}

+ (void) emptyDataResponseRequest:(NSURLRequest *)request
                            queue:(NSOperationQueue *)queue
                completionHandler:(void (^)(NSURLResponse *response, NSData *data, NSError *connectionError)) handler
{
    NSHTTPURLResponse *newResponse = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:200 HTTPVersion:nil headerFields:nil];
    NSData *newData = [NSData data];
    handler(newResponse, newData, nil);
}

+ (void) nilDataResponseRequest:(NSURLRequest *)request
                          queue:(NSOperationQueue *)queue
              completionHandler:(void (^)(NSURLResponse *response, NSData *data, NSError *connectionError)) handler
{
    NSHTTPURLResponse *newResponse = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:200 HTTPVersion:nil headerFields:nil];
    handler(newResponse, nil, nil);
}

+ (void) zeroLengthDataResponseRequest:(NSURLRequest *)request
                                 queue:(NSOperationQueue *)queue
                     completionHandler:(void (^)(NSURLResponse *response, NSData *data, NSError *connectionError)) handler
{
    NSHTTPURLResponse *newResponse = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:200 HTTPVersion:nil headerFields:nil];
    NSData *newData = [@"" dataUsingEncoding:NSUTF8StringEncoding];
    handler(newResponse, newData, nil);
}

+ (void) unparseableDataResponseRequest:(NSURLRequest *)request
                                  queue:(NSOperationQueue *)queue
                      completionHandler:(void (^)(NSURLResponse *response, NSData *data, NSError *connectionError)) handler
{
    NSHTTPURLResponse *newResponse = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:200 HTTPVersion:nil headerFields:nil];
    NSData *newData = [@"This is not JSON" dataUsingEncoding:NSUTF8StringEncoding];
    handler(newResponse, newData, nil);
}

+ (void) missingUUIDResponseRequest:(NSURLRequest *)request
                              queue:(NSOperationQueue *)queue
                  completionHandler:(void (^)(NSURLResponse *response, NSData *data, NSError *connectionError)) handler
{
    NSHTTPURLResponse *newResponse = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:200 HTTPVersion:nil headerFields:nil];
    NSDictionary *newJSON = @{@"os" : @"AmigaOS"};
    NSError *error;
    NSData *newData = [NSJSONSerialization dataWithJSONObject:newJSON options:NSJSONWritingPrettyPrinted error:&error];
    handler(newResponse, newData, nil);
}

@end
