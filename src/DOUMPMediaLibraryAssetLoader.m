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

#if TARGET_OS_IPHONE

#import "DOUMPMediaLibraryAssetLoader.h"
#import <AVFoundation/AVFoundation.h>
#include <CommonCrypto/CommonDigest.h>

@interface DOUMPMediaLibraryAssetLoader () {
@private
  NSString *_cachedPath;
  AVAssetExportSession *_exportSession;
}
@end

@implementation DOUMPMediaLibraryAssetLoader

+ (instancetype)loaderWithURL:(NSURL *)url
{
  return [[[self class] alloc] initWithURL:url];
}

- (instancetype)initWithURL:(NSURL *)url
{
  self = [super init];
  if (self) {
    _assetURL = url;
  }

  return self;
}

- (void)start
{
  if (_exportSession != nil) {
    return;
  }

  AVURLAsset *asset = [AVURLAsset assetWithURL:_assetURL];
  if (asset == nil) {
    [self _reportFailure];
    return;
  }

  _exportSession = [AVAssetExportSession exportSessionWithAsset:asset
                                                     presetName:AVAssetExportPresetPassthrough];
  if (_exportSession == nil) {
    [self _reportFailure];
    return;
  }

  [_exportSession setOutputFileType:AVFileTypeCoreAudioFormat];
  [_exportSession setOutputURL:[NSURL fileURLWithPath:[self cachedPath]]];

  __weak typeof(self) weakSelf = self;
  [_exportSession exportAsynchronouslyWithCompletionHandler:^{
    __strong typeof(weakSelf) strongSelf = weakSelf;
    [strongSelf _exportSessionDidComplete];
  }];
}

- (void)cancel
{
  if (_exportSession == nil) {
    return;
  }

  [_exportSession cancelExport];
  _exportSession = nil;
}

- (void)_exportSessionDidComplete
{
  if ([_exportSession status] != AVAssetExportSessionStatusCompleted ||
      [_exportSession error] != nil) {
    [self _reportFailure];
    return;
  }

  [self _invokeCompletedBlock];
}

- (void)_invokeCompletedBlock
{
  @synchronized(self) {
    if (_completedBlock != NULL) {
      _completedBlock();
    }
  }
}

- (void)_reportFailure
{
  _failed = YES;
  [self _invokeCompletedBlock];
}

- (NSString *)cachedPath
{
  if (_cachedPath == nil) {
    NSString *filename = [NSString stringWithFormat:@"douas-mla-%@.%@", [[self class] _sha256ForURL:_assetURL], [self fileExtension]];
    _cachedPath = [NSTemporaryDirectory() stringByAppendingPathComponent:filename];

    if ([[NSFileManager defaultManager] fileExistsAtPath:_cachedPath]) {
      [[NSFileManager defaultManager] removeItemAtPath:_cachedPath error:NULL];
    }
  }

  return _cachedPath;
}

- (NSString *)mimeType
{
  return AVFileTypeCoreAudioFormat;
}

- (NSString *)fileExtension
{
  return @"caf";
}

+ (NSString *)_sha256ForURL:(NSURL *)url
{
  NSString *string = [url absoluteString];
  unsigned char hash[CC_SHA256_DIGEST_LENGTH];
  CC_SHA256([string UTF8String], (CC_LONG)[string lengthOfBytesUsingEncoding:NSUTF8StringEncoding], hash);

  NSMutableString *result = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
  for (size_t i = 0; i < CC_SHA256_DIGEST_LENGTH; ++i) {
    [result appendFormat:@"%02x", hash[i]];
  }

  return result;
}

@end

#endif /* TARGET_OS_IPHONE */
