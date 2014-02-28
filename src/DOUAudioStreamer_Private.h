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

#import "DOUAudioStreamer.h"

@class DOUAudioFileProvider;
@class DOUAudioPlaybackItem;
@class DOUAudioDecoder;

@interface DOUAudioStreamer ()

@property (assign) DOUAudioStreamerStatus status;
@property (strong) NSError *error;

@property (nonatomic, assign) NSTimeInterval duration;
@property (nonatomic, assign) NSInteger timingOffset;

@property (nonatomic, readonly) DOUAudioFileProvider *fileProvider;
@property (nonatomic, strong) DOUAudioPlaybackItem *playbackItem;
@property (nonatomic, strong) DOUAudioDecoder *decoder;

@property (nonatomic, assign) double bufferingRatio;

#if TARGET_OS_IPHONE
@property (nonatomic, assign, getter = isPausedByInterruption) BOOL pausedByInterruption;
#endif /* TARGET_OS_IPHONE */

@end
