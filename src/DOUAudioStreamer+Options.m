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

#import "DOUAudioStreamer+Options.h"

NSString *const kDOUAudioStreamerVolumeKey = @"DOUAudioStreamerVolume";
const NSUInteger kDOUAudioStreamerBufferTime = 200;

static DOUAudioStreamerOptions gOptions = DOUAudioStreamerDefaultOptions;

@implementation DOUAudioStreamer (Options)

+ (DOUAudioStreamerOptions)options
{
  return gOptions;
}

+ (void)setOptions:(DOUAudioStreamerOptions)options
{
  if (((gOptions ^ options) & DOUAudioStreamerKeepPersistentVolume) &&
      !(options & DOUAudioStreamerKeepPersistentVolume)) {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kDOUAudioStreamerVolumeKey];
  }

  gOptions = options;
}

@end
