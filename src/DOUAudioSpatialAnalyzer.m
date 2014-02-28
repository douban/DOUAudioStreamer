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

#import "DOUAudioSpatialAnalyzer.h"
#import "DOUAudioAnalyzer_Private.h"

@implementation DOUAudioSpatialAnalyzer

- (void)processChannelVectors:(const float *)vectors toLevels:(float *)levels
{
  for (size_t i = 0; i < kDOUAudioAnalyzerLevelCount; ++i) {
    levels[i] = vectors[kDOUAudioAnalyzerCount * i / kDOUAudioAnalyzerLevelCount];
  }
}

@end
