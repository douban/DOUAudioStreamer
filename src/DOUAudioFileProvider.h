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

typedef void (^DOUAudioFileProviderEventBlock)(void);

@interface DOUAudioFileProvider : NSObject

+ (instancetype)fileProviderWithAudioFile:(id <DOUAudioFile>)audioFile;

@property (nonatomic, readonly) id <DOUAudioFile> audioFile;
@property (nonatomic, copy) DOUAudioFileProviderEventBlock eventBlock;

@property (nonatomic, readonly) NSString *cachedPath;
@property (nonatomic, readonly) NSURL *cachedURL;

@property (nonatomic, readonly) NSData *mappedData;

@property (nonatomic, readonly) NSUInteger expectedLength;
@property (nonatomic, readonly) NSUInteger receivedLength;
@property (nonatomic, readonly) NSUInteger downloadSpeed;

@property (nonatomic, readonly, getter = isFailed) BOOL failed;
@property (nonatomic, readonly, getter = isReady) BOOL ready;
@property (nonatomic, readonly, getter = isFinished) BOOL finished;

@end
