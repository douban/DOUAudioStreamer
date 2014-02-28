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
#include <CoreAudio/CoreAudioTypes.h>

typedef NS_ENUM(NSUInteger, DOUAudioDecoderStatus) {
  DOUAudioDecoderSucceeded,
  DOUAudioDecoderFailed,
  DOUAudioDecoderEndEncountered,
  DOUAudioDecoderWaiting
};

@class DOUAudioPlaybackItem;
@class DOUAudioLPCM;

@interface DOUAudioDecoder : NSObject

+ (AudioStreamBasicDescription)defaultOutputFormat;

+ (instancetype)decoderWithPlaybackItem:(DOUAudioPlaybackItem *)playbackItem
                             bufferSize:(NSUInteger)bufferSize;

- (instancetype)initWithPlaybackItem:(DOUAudioPlaybackItem *)playbackItem
                          bufferSize:(NSUInteger)bufferSize;

- (BOOL)setUp;
- (void)tearDown;

- (DOUAudioDecoderStatus)decodeOnce;
- (void)seekToTime:(NSUInteger)milliseconds;

@property (nonatomic, readonly) DOUAudioPlaybackItem *playbackItem;
@property (nonatomic, readonly) DOUAudioLPCM *lpcm;

@end
