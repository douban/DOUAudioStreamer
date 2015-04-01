/* vim: set ft=objc fenc=utf-8 sw=2 ts=2 et: */
/*
 *  DOUAudioStreamer - A Core Audio based streaming audio player for iOS/Mac:
 *
 *      https://github.com/douban/DOUAudioStreamer
 *
 *  Copyright 2013-2014 Douban Inc.  All rights reserved.
 *
 *  Use and distribution licensed under the BSD license.  See
 *  the LICENSE file for full text.
 *
 *  Authors:
 *      Chongyu Zhu <i@lembacon.com>
 *
 */

#import <Foundation/Foundation.h>

typedef void (^DOUSimpleHTTPRequestCompletedBlock)(void);
typedef void (^DOUSimpleHTTPRequestProgressBlock)(double downloadProgress);
typedef void (^DOUSimpleHTTPRequestDidReceiveResponseBlock)(void);
typedef void (^DOUSimpleHTTPRequestDidReceiveDataBlock)(NSData *data);

@interface DOUSimpleHTTPRequest : NSObject

+ (instancetype)requestWithURL:(NSURL *)url;
- (instancetype)initWithURL:(NSURL *)url;

+ (NSTimeInterval)defaultTimeoutInterval;
+ (NSString *)defaultUserAgent;

@property (nonatomic, assign) NSTimeInterval timeoutInterval;
@property (nonatomic, strong) NSString *userAgent;

@property (nonatomic, readonly) NSData *responseData;
@property (nonatomic, readonly) NSString *responseString;

@property (nonatomic, readonly) NSDictionary *responseHeaders;
@property (nonatomic, readonly) NSUInteger responseContentLength;
@property (nonatomic, readonly) NSInteger statusCode;
@property (nonatomic, readonly) NSString *statusMessage;

@property (nonatomic, readonly) NSUInteger downloadSpeed;
@property (nonatomic, readonly, getter=isFailed) BOOL failed;

@property (copy) DOUSimpleHTTPRequestCompletedBlock completedBlock;
@property (copy) DOUSimpleHTTPRequestProgressBlock progressBlock;
@property (copy) DOUSimpleHTTPRequestDidReceiveResponseBlock didReceiveResponseBlock;
@property (copy) DOUSimpleHTTPRequestDidReceiveDataBlock didReceiveDataBlock;

- (void)start;
- (void)cancel;

@end
