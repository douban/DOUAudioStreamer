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
+(DOUCacheManager*)shared;
- (void) manualManagerRemoteAudioFileCache:(DOUAudioStreamerOptions)opt maximumFileCount:(NSUInteger)count;
- (void) cleanUselessCache;
- (void) cleanAllCache;
- (void) cleanCacheWithURL:(NSURL*)url;
@end
