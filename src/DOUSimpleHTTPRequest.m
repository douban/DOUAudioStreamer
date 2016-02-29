/* vim: set ft=objc fenc=utf-8 sw=2 ts=2 et: */
/*
 *  DOUAudioStreamer - A Core Audio based streaming audio player for iOS/Mac:
 *
 *      https://github.com/douban/DOUAudioStreamer
 *
 *  Copyright 2013-2016 Douban Inc.  All rights reserved.
 *
 *  Use and distribution licensed under the BSD license.  See
 *  the LICENSE file for full text.
 *
 *  Authors:
 *      Chongyu Zhu <i@lembacon.com>
 *
 */

#import "DOUSimpleHTTPRequest.h"
#include <sys/types.h>
#include <sys/sysctl.h>
#include <pthread.h>

static struct {
  pthread_t thread;
  pthread_mutex_t mutex;
  pthread_cond_t cond;
  CFRunLoopRef runloop;
} controller;

static void *controller_main(void *info)
{
  pthread_setname_np("com.douban.simple-http-request.controller");

  pthread_mutex_lock(&controller.mutex);
  controller.runloop = CFRunLoopGetCurrent();
  pthread_mutex_unlock(&controller.mutex);
  pthread_cond_signal(&controller.cond);

  CFRunLoopSourceContext context;
  bzero(&context, sizeof(context));

  CFRunLoopSourceRef source = CFRunLoopSourceCreate(kCFAllocatorDefault, 0, &context);
  CFRunLoopAddSource(controller.runloop, source, kCFRunLoopDefaultMode);

  CFRunLoopRun();

  CFRunLoopRemoveSource(controller.runloop, source, kCFRunLoopDefaultMode);
  CFRelease(source);

  pthread_mutex_destroy(&controller.mutex);
  pthread_cond_destroy(&controller.cond);

  return NULL;
}

static CFRunLoopRef controller_get_runloop()
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    pthread_mutex_init(&controller.mutex, NULL);
    pthread_cond_init(&controller.cond, NULL);
    controller.runloop = NULL;

    pthread_create(&controller.thread, NULL, controller_main, NULL);

    pthread_mutex_lock(&controller.mutex);
    if (controller.runloop == NULL) {
      pthread_cond_wait(&controller.cond, &controller.mutex);
    }
    pthread_mutex_unlock(&controller.mutex);
  });

  return controller.runloop;
}

@interface DOUSimpleHTTPRequest () {
@private
  DOUSimpleHTTPRequestCompletedBlock _completedBlock;
  DOUSimpleHTTPRequestProgressBlock _progressBlock;
  DOUSimpleHTTPRequestDidReceiveResponseBlock _didReceiveResponseBlock;
  DOUSimpleHTTPRequestDidReceiveDataBlock _didReceiveDataBlock;

  NSString *_userAgent;
  NSTimeInterval _timeoutInterval;

  CFHTTPMessageRef _message;
  CFReadStreamRef _responseStream;

  NSDictionary *_responseHeaders;
  NSMutableData *_responseData;
  NSString *_responseString;

  NSInteger _statusCode;
  NSString *_statusMessage;
  BOOL _failed;

  CFAbsoluteTime _startedTime;
  NSUInteger _downloadSpeed;

  NSUInteger _responseContentLength;
  NSUInteger _receivedLength;
}
@end

@implementation DOUSimpleHTTPRequest

@synthesize timeoutInterval = _timeoutInterval;
@synthesize userAgent = _userAgent;

@synthesize responseData = _responseData;

@synthesize responseHeaders = _responseHeaders;
@synthesize responseContentLength = _responseContentLength;
@synthesize statusCode = _statusCode;
@synthesize statusMessage = _statusMessage;

@synthesize downloadSpeed = _downloadSpeed;
@synthesize failed = _failed;

@synthesize completedBlock = _completedBlock;
@synthesize progressBlock = _progressBlock;
@synthesize didReceiveResponseBlock = _didReceiveResponseBlock;
@synthesize didReceiveDataBlock = _didReceiveDataBlock;

+ (instancetype)requestWithURL:(NSURL *)url
{
  if (url == nil) {
    return nil;
  }

  return [[[self class] alloc] initWithURL:url];
}

- (instancetype)initWithURL:(NSURL *)url
{
  self = [super init];
  if (self) {
    _userAgent = [[self class] defaultUserAgent];
    _timeoutInterval = [[self class] defaultTimeoutInterval];

    _message = CFHTTPMessageCreateRequest(kCFAllocatorDefault, CFSTR("GET"), (__bridge CFURLRef)url, kCFHTTPVersion1_1);
  }

  return self;
}

- (void)dealloc
{
  if (_responseStream != NULL) {
    [self _closeResponseStream];
    CFRelease(_responseStream);
  }

  CFRelease(_message);
}

+ (NSTimeInterval)defaultTimeoutInterval
{
  return 20.0;
}

+ (NSString *)defaultUserAgent
{
  static NSString *defaultUserAgent = nil;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString *appName = [infoDict objectForKey:@"CFBundleName"];
    NSString *shortVersion = [infoDict objectForKey:@"CFBundleShortVersionString"];
    NSString *bundleVersion = [infoDict objectForKey:@"CFBundleVersion"];

    NSString *deviceName = nil;
    NSString *systemName = nil;
    NSString *systemVersion = nil;

#if TARGET_OS_IPHONE

    UIDevice *device = [UIDevice currentDevice];
    deviceName = [device model];
    systemName = [device systemName];
    systemVersion = [device systemVersion];

#else /* TARGET_OS_IPHONE */

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
    SInt32 versionMajor, versionMinor, versionBugFix;
    Gestalt(gestaltSystemVersionMajor, &versionMajor);
    Gestalt(gestaltSystemVersionMinor, &versionMinor);
    Gestalt(gestaltSystemVersionBugFix, &versionBugFix);
#pragma clang diagnostic pop

    int mib[2] = { CTL_HW, HW_MODEL };
    size_t len = 0;
    sysctl(mib, 2, NULL, &len, NULL, 0);
    char *hw_model = malloc(len);
    sysctl(mib, 2, hw_model, &len, NULL, 0);
    deviceName = [NSString stringWithFormat:@"Macintosh %s", hw_model];
    free(hw_model);

    systemName = @"Mac OS X";
    systemVersion = [NSString stringWithFormat:@"%u.%u.%u", versionMajor, versionMinor, versionBugFix];

#endif /* TARGET_OS_IPHONE */

    NSString *locale = [[NSLocale currentLocale] localeIdentifier];
    defaultUserAgent = [NSString stringWithFormat:@"%@ %@ build %@ (%@; %@ %@; %@)", appName, shortVersion, bundleVersion, deviceName, systemName, systemVersion, locale];
  });

  return defaultUserAgent;
}

- (void)_invokeCompletedBlock
{
  @synchronized(self) {
    if (_completedBlock != NULL) {
      _completedBlock();
    }
  }
}

- (void)_invokeProgressBlockWithDownloadProgress:(double)downloadProgress
{
  @synchronized(self) {
    if (_progressBlock != NULL) {
      _progressBlock(downloadProgress);
    }
  }
}

- (void)_invokeDidReceiveResponseBlock
{
  @synchronized(self) {
    if (_didReceiveResponseBlock != NULL) {
      _didReceiveResponseBlock();
    }
  }
}

- (void)_invokeDidReceiveDataBlockWithData:(NSData *)data
{
  @synchronized(self) {
    if (_didReceiveDataBlock != NULL) {
      _didReceiveDataBlock(data);
    }
  }
}

- (void)_checkResponseContentLength
{
  if (_responseHeaders == nil) {
    return;
  }

  NSString *string = [_responseHeaders objectForKey:@"Content-Length"];
  if (string == nil) {
    return;
  }

  _responseContentLength = (NSUInteger)[string integerValue];
}

- (void)_readResponseHeaders
{
  if (_responseHeaders != nil) {
    return;
  }

  CFHTTPMessageRef message = (CFHTTPMessageRef)CFReadStreamCopyProperty(_responseStream, kCFStreamPropertyHTTPResponseHeader);
  if (message == NULL) {
    return;
  }

  if (!CFHTTPMessageIsHeaderComplete(message)) {
    CFRelease(message);
    return;
  }

  _responseHeaders = CFBridgingRelease(CFHTTPMessageCopyAllHeaderFields(message));
  _statusCode = CFHTTPMessageGetResponseStatusCode(message);
  _statusMessage = CFBridgingRelease(CFHTTPMessageCopyResponseStatusLine(message));
  CFRelease(message);

  [self _checkResponseContentLength];
  [self _invokeDidReceiveResponseBlock];
}

- (void)_updateProgress
{
  double downloadProgress;
  if (_responseContentLength == 0) {
    if (_responseHeaders != nil) {
      downloadProgress = 1.0;
    }
    else {
      downloadProgress = 0.0;
    }
  }
  else {
    downloadProgress = (double)_receivedLength / _responseContentLength;
  }

  [self _invokeProgressBlockWithDownloadProgress:downloadProgress];
}

- (void)_updateDownloadSpeed
{
  _downloadSpeed = _receivedLength / (CFAbsoluteTimeGetCurrent() - _startedTime);
}

- (void)_closeResponseStream
{
  CFReadStreamClose(_responseStream);
  CFReadStreamUnscheduleFromRunLoop(_responseStream, controller_get_runloop(), kCFRunLoopDefaultMode);
  CFReadStreamSetClient(_responseStream, kCFStreamEventNone, NULL, NULL);
}

- (void)_responseStreamHasBytesAvailable
{
  [self _readResponseHeaders];

  if (!CFReadStreamHasBytesAvailable(_responseStream)) {
    return;
  }

  CFIndex bufferSize;
  if (_responseContentLength > 262144) {
    bufferSize = 262144;
  }
  else if (_responseContentLength > 65536) {
    bufferSize = 65536;
  }
  else {
    bufferSize = 16384;
  }

  UInt8 buffer[bufferSize];
  CFIndex bytesRead = CFReadStreamRead(_responseStream, buffer, bufferSize);
  if (bytesRead < 0) {
    [self _responseStreamErrorOccurred];
    return;
  }

  if (bytesRead > 0) {
    NSData *data = [NSData dataWithBytesNoCopy:buffer length:(NSUInteger)bytesRead freeWhenDone:NO];

    @synchronized(self) {
      if (_didReceiveDataBlock == NULL) {
        if (_responseData == nil) {
          _responseData = [NSMutableData data];
        }

        [_responseData appendData:data];
      }
      else {
        [self _invokeDidReceiveDataBlockWithData:data];
      }
    }

    _receivedLength += (unsigned long)bytesRead;
    [self _updateProgress];
    [self _updateDownloadSpeed];
  }
}

- (void)_responseStrameEndEncountered
{
  [self _readResponseHeaders];
  [self _invokeProgressBlockWithDownloadProgress:1.0];
  [self _invokeCompletedBlock];
}

- (void)_responseStreamErrorOccurred
{
  [self _readResponseHeaders];

  _failed = YES;
  [self _closeResponseStream];
  [self _invokeCompletedBlock];
}

static void response_stream_client_callback(CFReadStreamRef stream, CFStreamEventType type, void *clientCallBackInfo)
{
  @autoreleasepool {
    __unsafe_unretained DOUSimpleHTTPRequest *request = (__bridge DOUSimpleHTTPRequest *)clientCallBackInfo;

    @synchronized(request) {
      switch (type) {
      case kCFStreamEventHasBytesAvailable:
        [request _responseStreamHasBytesAvailable];
        break;

      case kCFStreamEventEndEncountered:
        [request _responseStrameEndEncountered];
        break;

      case kCFStreamEventErrorOccurred:
        [request _responseStreamErrorOccurred];
        break;

      default:
        break;
      }
    }
  }
}

- (void)start
{
  if (_responseStream != NULL) {
    return;
  }

  CFHTTPMessageSetHeaderFieldValue(_message, CFSTR("User-Agent"), (__bridge CFStringRef)_userAgent);
  if (_host != nil) {
    CFHTTPMessageSetHeaderFieldValue(_message, CFSTR("Host"), (__bridge CFStringRef)_host);
  }

  _responseStream = CFReadStreamCreateForHTTPRequest(kCFAllocatorDefault, _message);
  CFReadStreamSetProperty(_responseStream, kCFStreamPropertyHTTPShouldAutoredirect, kCFBooleanTrue);
  CFReadStreamSetProperty(_responseStream, CFSTR("_kCFStreamPropertyReadTimeout"), (__bridge CFNumberRef)[NSNumber numberWithDouble:_timeoutInterval]);
  CFReadStreamSetProperty(_responseStream, CFSTR("_kCFStreamPropertyWriteTimeout"), (__bridge CFNumberRef)[NSNumber numberWithDouble:_timeoutInterval]);

  CFStreamClientContext context;
  bzero(&context, sizeof(context));
  context.info = (__bridge void *)self;
  CFReadStreamSetClient(_responseStream, kCFStreamEventHasBytesAvailable | kCFStreamEventEndEncountered | kCFStreamEventErrorOccurred, response_stream_client_callback, &context);

  CFReadStreamScheduleWithRunLoop(_responseStream, controller_get_runloop(), kCFRunLoopDefaultMode);
  CFReadStreamOpen(_responseStream);

  _startedTime = CFAbsoluteTimeGetCurrent();
  _downloadSpeed = 0;
}

- (void)cancel
{
  if (_responseStream == NULL || _failed) {
    return;
  }

  __block CFTypeRef __request = CFBridgingRetain(self);
  CFRunLoopPerformBlock(controller_get_runloop(), kCFRunLoopDefaultMode, ^{
    @autoreleasepool {
      [(__bridge DOUSimpleHTTPRequest *)__request _closeResponseStream];
      CFBridgingRelease(__request);
    }
  });
}

- (NSString *)responseString
{
  if (_responseData == nil) {
    return nil;
  }

  if (_responseString == nil) {
    _responseString = [[NSString alloc] initWithData:_responseData encoding:NSUTF8StringEncoding];
  }

  return _responseString;
}

@end
