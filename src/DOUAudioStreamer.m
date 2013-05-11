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

#import "DOUAudioStreamer.h"
#import "DOUAudioStreamer_Private.h"
#import "DOUAudioFileProvider.h"
#import "DOUAudioEventLoop.h"

NSString *const kDOUAudioStreamerErrorDomain = @"com.douban.audio-streamer.error-domain";

@interface DOUAudioStreamer () {
@private
  id <DOUAudioFile> _audioFile;

  DOUAudioStreamerStatus _status;
  NSError *_error;

  NSTimeInterval _duration;

  DOUAudioFileProvider *_fileProvider;
  DOUAudioPlaybackItem *_playbackItem;
  DOUAudioDecoder *_decoder;

#if TARGET_OS_IPHONE
  BOOL _pausedByInterruption;
#endif /* TARGET_OS_IPHONE */
}
@end

@implementation DOUAudioStreamer

@synthesize status = _status;
@synthesize error = _error;

@synthesize duration = _duration;

@synthesize fileProvider = _fileProvider;
@synthesize playbackItem = _playbackItem;
@synthesize decoder = _decoder;

#if TARGET_OS_IPHONE
@synthesize pausedByInterruption = _pausedByInterruption;
#endif /* TARGET_OS_IPHONE */

+ (instancetype)streamerWithAudioFile:(id <DOUAudioFile>)audioFile
{
  return [[[self class] alloc] initWithAudioFile:audioFile];
}

- (instancetype)initWithAudioFile:(id <DOUAudioFile>)audioFile
{
  self = [super init];
  if (self) {
    _audioFile = audioFile;
    _status = DOUAudioStreamerPaused;

    _fileProvider = [DOUAudioFileProvider fileProviderWithAudioFile:_audioFile];
    if (_fileProvider == nil) {
      return nil;
    }
  }

  return self;
}

- (void)dealloc
{
  if (_fileProvider.cachedPath) {
    [[NSFileManager defaultManager] removeItemAtPath:_fileProvider.cachedPath error:NULL];
  }
}

+ (double)volume
{
  return [[DOUAudioEventLoop sharedEventLoop] volume];
}

+ (void)setVolume:(double)volume
{
  [[DOUAudioEventLoop sharedEventLoop] setVolume:volume];
}

- (id <DOUAudioFile>)audioFile
{
  return _audioFile;
}

- (NSURL *)url
{
  return [_audioFile audioFileURL];
}

- (NSTimeInterval)currentTime
{
  if ([[DOUAudioEventLoop sharedEventLoop] currentStreamer] != self) {
    return 0.0;
  }

  return [[DOUAudioEventLoop sharedEventLoop] currentTime];
}

- (double)volume
{
  return [[self class] volume];
}

- (void)setVolume:(double)volume
{
  [[self class] setVolume:volume];
}

- (NSString *)cachedPath
{
  return [_fileProvider cachedPath];
}

- (NSURL *)cachedURL
{
  return [_fileProvider cachedURL];
}

- (NSUInteger)expectedLength
{
  return [_fileProvider expectedLength];
}

- (NSUInteger)receivedLength
{
  return [_fileProvider receivedLength];
}

- (NSUInteger)downloadSpeed
{
  return [_fileProvider downloadSpeed];
}

- (void)play
{
  @synchronized(self) {
    if (_status != DOUAudioStreamerPaused) {
      return;
    }

    if ([[DOUAudioEventLoop sharedEventLoop] currentStreamer] != self) {
      [[DOUAudioEventLoop sharedEventLoop] pause];
      [[DOUAudioEventLoop sharedEventLoop] setCurrentStreamer:self];
    }

    [[DOUAudioEventLoop sharedEventLoop] play];
  }
}

- (void)pause
{
  @synchronized(self) {
    if (_status == DOUAudioStreamerPaused) {
      return;
    }

    if ([[DOUAudioEventLoop sharedEventLoop] currentStreamer] != self) {
      return;
    }

    [[DOUAudioEventLoop sharedEventLoop] pause];
  }
}

- (void)stop
{
  @synchronized(self) {
    if (_status == DOUAudioStreamerPaused) {
      return;
    }

    if ([[DOUAudioEventLoop sharedEventLoop] currentStreamer] != self) {
      return;
    }

    [[DOUAudioEventLoop sharedEventLoop] pause];
    [[DOUAudioEventLoop sharedEventLoop] setCurrentStreamer:nil];
  }
}

@end
