//
//  KSCrashReportSinkStandard.m
//
//  Created by Karl Stenerud on 2012-02-18.
//
//  Copyright (c) 2012 Karl Stenerud. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall remain in place
// in this source code.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//


#import "KSCrashReportSinkStandard.h"

#import "KSHTTPMultipartPostBody.h"
#import "KSHTTPRequestSender.h"
#import "NSData+GZip.h"
#import "KSJSONCodecObjC.h"
#import "KSReachabilityKSCrash.h"
#import "NSError+SimpleConstructor.h"

#import "KSCrashReportFilterAppleFmt.h"
#import "KSCrashReportFilterBasic.h"
#import "KSSystemCapabilities.h"


//#define KSLogger_LocalLevel TRACE
#import "KSLogger.h"


@interface KSCrashReportSinkStandard ()

@property(nonatomic,readwrite,retain) NSURL* url;

@property(nonatomic,readwrite,retain) KSReachableOperationKSCrash* reachableOperation;


@end


@implementation KSCrashReportSinkStandard

@synthesize url = _url;
@synthesize reachableOperation = _reachableOperation;

+ (KSCrashReportSinkStandard*) sinkWithURL:(NSURL*) url
{
    return [[self alloc] initWithURL:url];
}

- (id) initWithURL:(NSURL*) url
{
    if((self = [super init]))
    {
        self.url = url;
    }
    return self;
}


- (id <KSCrashReportFilter>) defaultCrashReportFilterSet
{
//    return self;
    return [KSCrashReportFilterPipeline filterWithFilters:
            [KSCrashReportFilterAppleFmt filterWithReportStyle:KSAppleReportStyleSymbolicatedSideBySide],
            self,
            nil];
}

// if no crash log found, this func would not get called
- (void) filterReports:(NSArray*) reports
          onCompletion:(KSCrashReportFilterCompletion) onCompletion
{
    NSError* error = nil;
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:self.url
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:15];
    KSHTTPMultipartPostBody* body = [KSHTTPMultipartPostBody body];

    // add each log to the request data
    for(NSString* report in reports)
    {
        NSData* textData = [report dataUsingEncoding:NSUTF8StringEncoding];

        if(textData == nil)
        {
            continue;
        }

        [body appendData:textData
                    name:@"logfile"
             contentType:@"text/plain"   // application/octet-stream
                filename:@"crash.log"];
    }

    request.HTTPMethod = @"POST";
    request.HTTPBody = [body data];
    [request setValue:body.contentType forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"KSCrashReporter" forHTTPHeaderField:@"User-Agent"];

    self.reachableOperation = [KSReachableOperationKSCrash operationWithHost:[self.url host]
                                                                   allowWWAN:YES
                                                                       block:^
    {
        [[KSHTTPRequestSender sender] sendRequest:request
                                        onSuccess:^(__unused NSHTTPURLResponse* response, __unused NSData* data)
         {
             kscrash_callCompletion(onCompletion, reports, YES, nil);
         } onFailure:^(NSHTTPURLResponse* response, NSData* data)
         {
             NSString* text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
             kscrash_callCompletion(onCompletion, reports, NO,
                                      [NSError errorWithDomain:[[self class] description]
                                                          code:response.statusCode
                                                   description:text]);
         } onError:^(NSError* error2)
         {
             kscrash_callCompletion(onCompletion, reports, NO, error2);
         }];
    }];
}

@end
