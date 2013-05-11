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

#import <Foundation/Foundation.h>
#import "DOUAudioFile.h"
#import "DOUAudioFilePreprocessor.h"

#ifdef __cplusplus
#define DOUAS_EXTERN extern "C"
#else /* __cplusplus */
#define DOUAS_EXTERN extern
#endif /* __cplusplus */

DOUAS_EXTERN NSString *const kDOUAudioStreamerErrorDomain;

typedef NS_ENUM(NSUInteger, DOUAudioStreamerStatus) {
  DOUAudioStreamerPlaying,
  DOUAudioStreamerPaused,
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

@property (assign, readonly) DOUAudioStreamerStatus status;
@property (strong, readonly) NSError *error;

@property (nonatomic, readonly) id <DOUAudioFile> audioFile;
@property (nonatomic, readonly) NSURL *url;

@property (nonatomic, assign, readonly) NSTimeInterval duration;
@property (nonatomic, readonly) NSTimeInterval currentTime;
@property (nonatomic, assign) double volume;

@property (nonatomic, readonly) NSString *cachedPath;
@property (nonatomic, readonly) NSURL *cachedURL;

@property (nonatomic, readonly) NSUInteger expectedLength;
@property (nonatomic, readonly) NSUInteger receivedLength;
@property (nonatomic, readonly) NSUInteger downloadSpeed;

- (void)play;
- (void)pause;
- (void)stop;

@end
