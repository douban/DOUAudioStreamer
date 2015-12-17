//
//  SSCacheManager.m
//  Pods
//
//  Created by LawLincoln on 15/9/23.
//
//

#import "DOUCacheManager.h"
#include <CommonCrypto/CommonDigest.h>
@implementation VerifyInfo
- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject: _Etag forKey: @"Etag"];
    [coder encodeObject: _ContentLength forKey: @"ContentLenght"];
    
}
- (instancetype)initWithCoder:(NSCoder *)coder
{
    if (self = [super init]) {
        self.Etag = [coder decodeObjectForKey:@"Etag"];
        self.ContentLength = [coder decodeObjectForKey:@"ContentLenght"];
    }
    return self;
}

@end
@interface DOUCacheManager()
@property (nonatomic, assign) NSUInteger maximumCacheFile;
@property (nonatomic, copy) NSMutableArray<NSString*>* cachePaths;
@property (nonatomic, strong) NSMutableDictionary<NSString*, VerifyInfo*>* storeInfo;
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
- (NSMutableArray<NSString *> *)cachePaths {
    if (!_cachePaths) {
        _cachePaths = [NSMutableArray array];
        NSString *path = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, true).firstObject;
        path = [path stringByAppendingPathComponent: @"searchPaths"];
        id array = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
        if ([array isKindOfClass:[NSArray<NSString*> class]]) {
            _cachePaths = array;
        }
    }
    return _cachePaths;
}

- (void)addSearchCachePath:(nullable NSString *)path {
    if (path) {
        if ([self.cachePaths indexOfObject:path] == NSNotFound) {
            [self.cachePaths addObject:path];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSString *path = [self pathForSearchPaths];
                [NSKeyedArchiver archiveRootObject:self.cachePaths toFile:path];
            });
        }
    }
}

- (void)removeCachePath:(nullable NSString*)path {
    if (path) {
        if ([self.cachePaths indexOfObject:path] != NSNotFound) {
            [self.cachePaths removeObject:path];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSString *path = [self pathForSearchPaths];
                [NSKeyedArchiver archiveRootObject:self.cachePaths toFile:path];
            });
        }
    }
}

- (NSString*) pathForSearchPaths {
    NSString *path = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, true).firstObject;
    path = [path stringByAppendingPathComponent: @"searchPaths"];
    return path;
}

- (NSArray<NSString*>*)addtionalCachePaths {
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




#pragma mark -

- (NSMutableDictionary<NSString *,VerifyInfo *> *)storeInfo {
    if (!_storeInfo) {
        _storeInfo = [NSMutableDictionary dictionary];
        id obj = [NSKeyedUnarchiver unarchiveObjectWithFile: [self verifyInfoStorePath]];
        if (obj && [obj isKindOfClass:[NSDictionary class]]) {
            [_storeInfo addEntriesFromDictionary:obj];
        }
    }
    return _storeInfo;
}
- (NSString*) verifyInfoStorePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *path = @"";
    if (paths && paths.count > 0) {
        path = paths[0];
    }
    path = [path stringByAppendingPathComponent:@"douVerifyInfo"];
    return path;
}

- (void) storeInfo:(VerifyInfo*)info forURL:(NSString*)url {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        if (info && url) {
            self.storeInfo[url] = info;
        }
        [NSKeyedArchiver archiveRootObject: self.storeInfo toFile: [self verifyInfoStorePath]];
    });
}
- (void)checkFileCompeletionForURL:(NSURL * _Nonnull)url {
    if (_verifyClosure == nil) {
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSString *filePath = [[self class] _cachedPathForAudioFileURL:url];
        VerifyInfo *info = self.storeInfo[url.absoluteString];
        if (filePath && info) {
            NSData *data = [[NSData alloc]initWithContentsOfFile:filePath];
            BOOL isComplete = _verifyClosure(data, info);
            if (!isComplete) {
                [self cleanCacheWithURL:url];
            }
        }
    });
}
@end
