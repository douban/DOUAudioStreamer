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

#if TARGET_OS_IPHONE

#import <Foundation/Foundation.h>

typedef void (^DOUMPMediaLibraryAssetLoaderCompletedBlock)(void);

@interface DOUMPMediaLibraryAssetLoader : NSObject

+ (instancetype)loaderWithURL:(NSURL *)url;
- (instancetype)initWithURL:(NSURL *)url;

@property (nonatomic, strong, readonly) NSURL *assetURL;
@property (nonatomic, strong, readonly) NSString *cachedPath;
@property (nonatomic, strong, readonly) NSString *mimeType;
@property (nonatomic, strong, readonly) NSString *fileExtension;

@property (nonatomic, assign, readonly, getter = isFailed) BOOL failed;

@property (copy) DOUMPMediaLibraryAssetLoaderCompletedBlock completedBlock;

- (void)start;
- (void)cancel;

@end

#endif /* TARGET_OS_IPHONE */
