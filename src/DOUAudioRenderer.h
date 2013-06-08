/* vim: set ft=objc fenc=utf-8 sw=2 ts=2 et: */
/*
 *  DOUAudioStreamer - A Core Audio based streaming audio player for iOS/Mac:
 *
 *      https://github.com/douban/DOUAudioStreamer
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

@interface DOUAudioRenderer : NSObject

+ (instancetype)rendererWithBufferTime:(NSUInteger)bufferTime;
- (instancetype)initWithBufferTime:(NSUInteger)bufferTime;

- (BOOL)setUp;
- (void)tearDown;

- (void)renderBytes:(const void *)bytes length:(NSUInteger)length;
- (void)stop;
- (void)flush;
- (void)flushShouldResetTiming:(BOOL)shouldResetTiming;

@property (nonatomic, readonly) NSUInteger currentTime;
@property (nonatomic, readonly, getter = isStarted) BOOL started;
@property (nonatomic, assign) double volume;

@end
