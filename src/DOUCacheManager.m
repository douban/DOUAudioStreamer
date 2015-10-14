//
//  SSCacheManager.m
//  Pods
//
//  Created by LawLincoln on 15/9/23.
//
//

#import "DOUCacheManager.h"
#include <CommonCrypto/CommonDigest.h>

@interface DOUCacheManager()
@property (nonatomic, assign) NSUInteger maximumCacheFile;
@property (nonatomic, copy) NSString* cachePaths;
@end
@implementation DOUCacheManager
+ (nonnull DOUCacheManager *) shared {
    static DOUCacheManager *sharedMyManager = nil;
    @synchronized(self) {
        if (sharedMyManager == nil)
            sharedMyManager = [[DOUCacheManager alloc] init];
    }
    return sharedMyManager;
}

- (void) manualManagerRemoteAudioFileCache:(DOUAudioStreamerOptions)opt maximumFileCount:(NSUInteger)count {
    [DOUAudioStreamer setOptions:opt];
    _maximumCacheFile = count;
    [self cleanUselessCache];
}
/*
 NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:@"path/to/my/file" error:nil];

 NSDate *date = [attributes fileModificationDate];

 */

- (NSMutableArray* __nullable)cacheFiles {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *path = NSTemporaryDirectory();
    
    NSArray *array = [fm contentsOfDirectoryAtPath:path error:nil];
    if (array == nil) {
        return nil;
    }
    
    NSMutableArray *douArray = [NSMutableArray array];
    for (NSString *file in array) {
        if ([file hasSuffix: @".dou"]) {
            [douArray addObject:file];
        }
    }
    return douArray;
}

+ (NSString *)_sha256ForAudioFileURL:(nonnull NSURL *)audioFileURL
{
    NSString *string = [audioFileURL absoluteString];
    unsigned char hash[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256([string UTF8String], (CC_LONG)[string lengthOfBytesUsingEncoding:NSUTF8StringEncoding], hash);
    
    NSMutableString *result = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for (size_t i = 0; i < CC_SHA256_DIGEST_LENGTH; ++i) {
        [result appendFormat:@"%02x", hash[i]];
    }
    
    return result;
}

+ (NSString *)_cachedPathForAudioFileURL:(NSURL *)audioFileURL
{
    NSString *filename = [NSString stringWithFormat:@"%@.dou", [self _sha256ForAudioFileURL:audioFileURL]];
    return [NSTemporaryDirectory() stringByAppendingPathComponent:filename];
}

- (void)cleanCacheWithURL:(NSURL*)url {
    if (url == nil) {
        return;
    }
    NSString *localPath = [[self class] _cachedPathForAudioFileURL:url];
    [[NSFileManager defaultManager] removeItemAtPath:localPath error:nil];
}

- (void) cleanUselessCache {
    NSMutableArray *douArray = [self cacheFiles];
    if (douArray == nil || douArray.count <= _maximumCacheFile) {
        return;
    }
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *path = NSTemporaryDirectory();
    NSUInteger needToRemove = douArray.count - _maximumCacheFile;

    NSDate*(^lastModificationDate)(NSString *file) = ^NSDate*(NSString* file) {
        NSString *filePath = [path stringByAppendingPathComponent:file];
        NSDictionary *attributes = [fm attributesOfItemAtPath:filePath error:nil];
        NSDate *date = [attributes fileModificationDate];
        return date;
    };
    
    [douArray sortUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        NSDate *d1 = lastModificationDate(obj1);
        NSDate *d2 = lastModificationDate(obj2);
        return [d2 compare:d1];
    }];
    
    for (NSUInteger i = 0; i < needToRemove; i++) {
        NSString *filePath = [path stringByAppendingPathComponent:douArray.lastObject];
        [fm removeItemAtPath:filePath error:nil];
        [douArray removeLastObject];
    }
}

- (void) cleanAllCache {
    NSMutableArray *douArray = [self cacheFiles];
    if (douArray == nil || douArray.count == 0) {
        return;
    }
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *path = NSTemporaryDirectory();
    for (NSString *file in douArray) {
        NSString *filePath = [path stringByAppendingPathComponent:file];
        [fm removeItemAtPath:filePath error:nil];
    }
}

- (void)addSearchCachePaths:(nullable NSString *)paths {
    self.cachePaths = paths;
}

- (NSString *)addtionalCachePaths {
    return self.cachePaths;
}

- (void) moveFileToAddtionalCachePath:(NSURL *)audioFileURL {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *destFilePath = [self pathForMoveFileToAddtionalCachePath: audioFileURL];
        NSFileManager *fm = [NSFileManager defaultManager];
        BOOL isDir = NO;
        BOOL fileExist = [fm fileExistsAtPath:destFilePath isDirectory:&isDir];
        if (fileExist) {
            return;
        }
        NSString *fileName = [NSString stringWithFormat:@"%@.dou", [[self class] _sha256ForAudioFileURL:audioFileURL]];
        NSString *tmpPath = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
        BOOL tmpExist = [fm fileExistsAtPath:tmpPath isDirectory:&isDir];
        if (destFilePath != nil && !fileExist && tmpExist) {
            [fm moveItemAtPath:tmpPath toPath:destFilePath error:nil];
        }
    });
}

- (NSString*) pathForMoveFileToAddtionalCachePath:(nonnull NSURL *)audioFileURL {
    NSString *diretory = [DOUCacheManager shared].addtionalCachePaths;
    if ( diretory != nil ) {
        NSFileManager *fm = [NSFileManager defaultManager];
        BOOL isDir = NO;
        NSString *filename = [NSString stringWithFormat:@"%@.dou", [[self class] _sha256ForAudioFileURL:audioFileURL]];
        NSString *filePath = [diretory stringByAppendingPathComponent:filename];
        if (![fm fileExistsAtPath:filePath isDirectory:&isDir]) {
            return filePath;
        }
    }
    return nil;
}
@end
