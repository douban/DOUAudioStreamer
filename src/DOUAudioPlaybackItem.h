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
#include <AudioToolbox/AudioToolbox.h>

@class DOUAudioFileProvider;
@class DOUAudioFilePreprocessor;
@protocol DOUAudioFile;

@interface DOUAudioPlaybackItem : NSObject

+ (instancetype)playbackItemWithFileProvider:(DOUAudioFileProvider *)fileProvider;
- (instancetype)initWithFileProvider:(DOUAudioFileProvider *)fileProvider;

@property (nonatomic, readonly) DOUAudioFileProvider *fileProvider;
@property (nonatomic, readonly) DOUAudioFilePreprocessor *filePreprocessor;
@property (nonatomic, readonly) id <DOUAudioFile> audioFile;

@property (nonatomic, readonly) NSURL *cachedURL;
@property (nonatomic, readonly) NSData *mappedData;

@property (nonatomic, readonly) AudioFileID fileID;
@property (nonatomic, readonly) AudioStreamBasicDescription fileFormat;
@property (nonatomic, readonly) NSUInteger bitRate;
@property (nonatomic, readonly) NSUInteger dataOffset;
@property (nonatomic, readonly) NSUInteger estimatedDuration;

@property (nonatomic, readonly, getter = isOpened) BOOL opened;

- (BOOL)open;
- (void)close;

@end
