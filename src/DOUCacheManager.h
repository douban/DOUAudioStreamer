//
//  SSCacheManager.h
//  Pods
//
//  Created by LawLincoln on 15/9/23.
//
//

#import <Foundation/Foundation.h>
#import "DOUAudioStreamer+Options.h"
@class VerifyInfo;
typedef BOOL(^VerifyClosure)(NSData* _Nullable, VerifyInfo* _Nullable);
@interface DOUCacheManager : NSObject
@property (nonatomic, copy) VerifyClosure _Nullable verifyClosure;
+(nonnull DOUCacheManager*)shared;
- (void) manualManagerRemoteAudioFileCache:(DOUAudioStreamerOptions)opt maximumFileCount:(NSUInteger)count;
- (void) cleanUselessCache;
- (void) cleanAllCache;
- (void) cleanCacheWithURL:(nonnull NSURL*)url;
- (void) addSearchCachePaths:(nullable NSString*)paths;
- (nullable NSString*) addtionalCachePaths;
- (void) moveFileToAddtionalCachePath:(nonnull NSURL*)url;
- (void) checkFileCompeletionForURL:(nonnull NSURL*)url;
@end

@interface VerifyInfo: NSObject
@property (nonatomic, copy) NSString * _Nullable Etag;
@property (nonatomic, copy) NSString * _Nullable ContentLength;
- (void)encodeWithCoder:(NSCoder* _Nullable)coder;
@end
