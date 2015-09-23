//
//  SSCacheManager.m
//  Pods
//
//  Created by LawLincoln on 15/9/23.
//
//

#import "DOUCacheManager.h"

@interface DOUCacheManager()
@property (nonatomic,assign) NSUInteger maximumCacheFile;
@end
@implementation DOUCacheManager
+ (DOUCacheManager *) shared {
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
@end
