/* vim: set ft=objc fenc=utf-8 sw=2 ts=2 et: */
/*
 *  DOUAudioStreamer - A Core Audio based streaming audio player for iOS/Mac:
 *
 *      http://github.com/douban/DOUAudioStreamer
 *
 *  Copyright 2013 Douban Inc.  All rights reserved.
 *
 *  Use and distribution licensed under the BSD license.  See
 *  the LICENSE file for full text.
 *
 *  Authors:
 *      Chongyu Zhu <lembacon@gmail.com>
 *
 */

#import "DOUAudioFileProvider.h"
#import "DOUSimpleHTTPRequest.h"
#import "NSData+DOUMappedFile.h"
#include <CommonCrypto/CommonDigest.h>

@interface DOUAudioFileProvider () {
@protected
  id <DOUAudioFile> _audioFile;
  DOUAudioFileProviderEventBlock _eventBlock;
  NSString *_cachedPath;
  NSURL *_cachedURL;
  NSData *_mappedData;
  NSUInteger _expectedLength;
  NSUInteger _receivedLength;
  BOOL _failed;
}

- (instancetype)_initWithAudioFile:(id <DOUAudioFile>)audioFile;

@end

@interface _DOUAudioLocalFileProvider : DOUAudioFileProvider
@end

@interface _DOUAudioRemoteFileProvider : DOUAudioFileProvider {
@private
  DOUSimpleHTTPRequest *_request;
  NSURL *_audioFileURL;
}
@end

#pragma mark - Concrete Audio Local File Provider

@implementation _DOUAudioLocalFileProvider

- (instancetype)_initWithAudioFile:(id <DOUAudioFile>)audioFile
{
  self = [super _initWithAudioFile:audioFile];
  if (self) {
    _cachedURL = [audioFile audioFileURL];
    _cachedPath = [_cachedURL path];

    BOOL isDirectory = NO;
    if (![[NSFileManager defaultManager] fileExistsAtPath:_cachedPath
                                              isDirectory:&isDirectory] ||
        isDirectory) {
      return nil;
    }

    _mappedData = [NSData dataWithMappedContentsOfFile:_cachedPath];
    _expectedLength = [_mappedData length];
    _receivedLength = [_mappedData length];
  }

  return self;
}

- (NSUInteger)downloadSpeed
{
  return 0;
}

- (BOOL)isReady
{
  return YES;
}

- (BOOL)isFinished
{
  return YES;
}

@end

#pragma mark - Concrete Audio Remote File Provider

@implementation _DOUAudioRemoteFileProvider

- (instancetype)_initWithAudioFile:(id <DOUAudioFile>)audioFile
{
  self = [super _initWithAudioFile:audioFile];
  if (self) {
    _audioFileURL = [audioFile audioFileURL];
    [self _createRequest];
    [_request start];
  }

  return self;
}

- (void)dealloc
{
  @synchronized(_request) {
    [_request setCompletedBlock:NULL];
    [_request setProgressBlock:NULL];
    [_request setDidReceiveResponseBlock:NULL];
    [_request setDidReceiveDataBlock:NULL];

    [_request cancel];
  }
}

+ (NSString *)_sha256ForAudioFileURL:(NSURL *)audioFileURL
{
  NSString *string = [audioFileURL absoluteString];
  unsigned char hash[CC_SHA256_DIGEST_LENGTH];
  CC_SHA256([string UTF8String], (CC_LONG)[string lengthOfBytesUsingEncoding:NSUTF8StringEncoding], hash);

  NSMutableString *result = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
  for (size_t i = 0; i < CC_SHA256_DIGEST_LENGTH; ++i) {
    [result appendFormat:@"%02x", hash[i]];
  }

  return result;
}

+ (NSString *)_cachedPathForAudioFileURL:(NSURL *)audioFileURL
{
  NSString *filename = [NSString stringWithFormat:@"douas-%@.tmp", [self _sha256ForAudioFileURL:audioFileURL]];
  return [NSTemporaryDirectory() stringByAppendingPathComponent:filename];
}

- (void)_invokeEventBlock
{
  if (_eventBlock != NULL) {
    _eventBlock();
  }
}

- (void)_requestDidComplete
{
  if ([_request isFailed] ||
      !([_request statusCode] >= 200 && [_request statusCode] < 300)) {
    _failed = YES;
  }
  else {
    [_mappedData synchronizeMappedFile];
  }

  [self _invokeEventBlock];
}

- (void)_requestDidReportProgress:(double)progress
{
  [self _invokeEventBlock];
}

- (void)_requestDidReceiveResponse
{
  _expectedLength = [_request responseContentLength];

  _cachedPath = [[self class] _cachedPathForAudioFileURL:_audioFileURL];
  _cachedURL = [NSURL fileURLWithPath:_cachedPath];

  [[NSFileManager defaultManager] createFileAtPath:_cachedPath contents:nil attributes:nil];
  [[NSFileHandle fileHandleForWritingAtPath:_cachedPath] truncateFileAtOffset:_expectedLength];

  _mappedData = [NSData modifiableDataWithMappedContentsOfFile:_cachedPath];
}

- (void)_requestDidReceiveData:(NSData *)data
{
  if (_mappedData == nil) {
    return;
  }

  NSUInteger availableSpace = _expectedLength - _receivedLength;
  NSUInteger bytesToWrite = MIN(availableSpace, [data length]);

  memcpy((uint8_t *)[_mappedData bytes] + _receivedLength, [data bytes], bytesToWrite);
  _receivedLength += bytesToWrite;
}

- (void)_createRequest
{
  _request = [DOUSimpleHTTPRequest requestWithURL:_audioFileURL];
  __unsafe_unretained _DOUAudioRemoteFileProvider *_self = self;

  [_request setCompletedBlock:^{
    [_self _requestDidComplete];
  }];

  [_request setProgressBlock:^(double downloadProgress) {
    [_self _requestDidReportProgress:downloadProgress];
  }];

  [_request setDidReceiveResponseBlock:^{
    [_self _requestDidReceiveResponse];
  }];

  [_request setDidReceiveDataBlock:^(NSData *data) {
    [_self _requestDidReceiveData:data];
  }];
}

- (NSUInteger)downloadSpeed
{
  return [_request downloadSpeed];
}

- (BOOL)isReady
{
  static const NSUInteger threshold = 4096 * 4;

  if (_expectedLength > 0) {
    if (_expectedLength <= threshold) {
      if (_receivedLength > _expectedLength) {
        return YES;
      }
    }
    else if (_receivedLength > threshold) {
      return YES;
    }
  }

  return NO;
}

- (BOOL)isFinished
{
  return _receivedLength >= _expectedLength;
}

@end

#pragma mark - Abstract Audio File Provider

@implementation DOUAudioFileProvider

@synthesize audioFile = _audioFile;
@synthesize eventBlock = _eventBlock;
@synthesize cachedPath = _cachedPath;
@synthesize cachedURL = _cachedURL;
@synthesize mappedData = _mappedData;
@synthesize expectedLength = _expectedLength;
@synthesize receivedLength = _receivedLength;
@synthesize failed = _failed;

+ (instancetype)fileProviderWithAudioFile:(id <DOUAudioFile>)audioFile
{
  if (audioFile == nil) {
    return nil;
  }

  NSURL *audioFileURL = [audioFile audioFileURL];
  if (audioFileURL == nil) {
    return nil;
  }

  if ([audioFileURL isFileURL]) {
    return [[_DOUAudioLocalFileProvider alloc] _initWithAudioFile:audioFile];
  }
  else {
    return [[_DOUAudioRemoteFileProvider alloc] _initWithAudioFile:audioFile];
  }
}

- (instancetype)_initWithAudioFile:(id <DOUAudioFile>)audioFile
{
  self = [super init];
  if (self) {
    _audioFile = audioFile;
  }

  return self;
}

- (NSUInteger)downloadSpeed
{
  [self doesNotRecognizeSelector:_cmd];
  return 0;
}

- (BOOL)isReady
{
  [self doesNotRecognizeSelector:_cmd];
  return NO;
}

- (BOOL)isFinished
{
  [self doesNotRecognizeSelector:_cmd];
  return NO;
}

@end
