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
#import "DOUAudioBase.h"
#import "DOUAudioFile.h"
#import "DOUAudioFilePreprocessor.h"
#import "DOUAudioAnalyzer+Default.h"

DOUAS_EXTERN NSString *const kDOUAudioStreamerErrorDomain;

typedef NS_ENUM(NSUInteger, DOUAudioStreamerStatus) {
  DOUAudioStreamerPlaying,
  DOUAudioStreamerPaused,
  DOUAudioStreamerIdle,
  DOUAudioStreamerFinished,
  DOUAudioStreamerBuffering,
  DOUAudioStreamerError
};

typedef NS_ENUM(NSInteger, DOUAudioStreamerErrorCode) {
  DOUAudioStreamerNetworkError,
  DOUAudioStreamerDecodingError
};

@interface DOUAudioStreamer : NSObject

+ (instancetype)streamerWithAudioFile:(id <DOUAudioFile>)audioFile;
- (instancetype)initWithAudioFile:(id <DOUAudioFile>)audioFile;

+ (double)volume;
+ (void)setVolume:(double)volume;

+ (NSArray *)analyzers;
+ (void)setAnalyzers:(NSArray *)analyzers;

+ (void)setHintWithAudioFile:(id <DOUAudioFile>)audioFile;

@property (assign, readonly) DOUAudioStreamerStatus status;
@property (strong, readonly) NSError *error;

@property (nonatomic, readonly) id <DOUAudioFile> audioFile;
@property (nonatomic, readonly) NSURL *url;

@property (nonatomic, assign, readonly) NSTimeInterval duration;
@property (nonatomic, assign) NSTimeInterval currentTime;
@property (nonatomic, assign) double volume;

@property (nonatomic, copy) NSArray *analyzers;

@property (nonatomic, readonly) NSString *cachedPath;
@property (nonatomic, readonly) NSURL *cachedURL;

@property (nonatomic, readonly) NSString *sha256;

@property (nonatomic, readonly) NSUInteger expectedLength;
@property (nonatomic, readonly) NSUInteger receivedLength;
@property (nonatomic, readonly) NSUInteger downloadSpeed;
@property (nonatomic, assign, readonly) double bufferingRatio;

- (void)play;
- (void)pause;
- (void)stop;

@end
