//
//  SSCacheManager.h
//  Pods
//
//  Created by LawLincoln on 15/9/23.
//
//

#import <Foundation/Foundation.h>
#import "DOUAudioStreamer+Options.h"
@interface DOUCacheManager : NSObject
+(nonnull DOUCacheManager*)shared;
- (void) manualManagerRemoteAudioFileCache:(DOUAudioStreamerOptions)opt maximumFileCount:(NSUInteger)count;
- (void) cleanUselessCache;
- (void) cleanAllCache;
- (void) cleanCacheWithURL:(nonnull NSURL*)url;
- (void) addSearchCachePaths:(nullable NSString*)paths;
- (nullable NSString*) addtionalCachePaths;
- (void) moveFileToAddtionalCachePath:(nonnull NSURL*)url;
@end
