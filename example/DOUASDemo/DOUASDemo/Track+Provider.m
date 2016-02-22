/* vim: set ft=objc fenc=utf-8 sw=2 ts=2 et: */
/*
 *  DOUAudioStreamer - A Core Audio based streaming audio player for iOS/Mac:
 *
 *      https://github.com/douban/DOUAudioStreamer
 *
 *  Copyright 2013-2016 Douban Inc.  All rights reserved.
 *
 *  Use and distribution licensed under the BSD license.  See
 *  the LICENSE file for full text.
 *
 *  Authors:
 *      Chongyu Zhu <i@lembacon.com>
 *
 */

#import "Track+Provider.h"
#import <MediaPlayer/MediaPlayer.h>

@implementation Track (Provider)

+ (void)load
{
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
    [self remoteTracks];
  });

  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
    [self musicLibraryTracks];
  });
}

+ (NSArray *)remoteTracks
{
  static NSArray *tracks = nil;
  
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    Track *track = [[Track alloc] init];
    [track setArtist:@"artist"];
    [track setTitle:@"title"];
    [track setAudioFileURL:[NSURL URLWithString:@"http://douban.fm/misc/mp3url?domain=mr7"]];
    tracks = @[track];
  });
  
  return tracks;
}

+ (NSArray *)musicLibraryTracks
{
  static NSArray *tracks = nil;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSMutableArray *allTracks = [NSMutableArray array];
    for (MPMediaItem *item in [[MPMediaQuery songsQuery] items]) {
      if ([[item valueForProperty:MPMediaItemPropertyIsCloudItem] boolValue]) {
        continue;
      }

      Track *track = [[Track alloc] init];
      [track setArtist:[item valueForProperty:MPMediaItemPropertyArtist]];
      [track setTitle:[item valueForProperty:MPMediaItemPropertyTitle]];
      [track setAudioFileURL:[item valueForProperty:MPMediaItemPropertyAssetURL]];
      [allTracks addObject:track];
    }

    for (NSUInteger i = 0; i < [allTracks count]; ++i) {
      NSUInteger j = arc4random_uniform((u_int32_t)[allTracks count]);
      [allTracks exchangeObjectAtIndex:i withObjectAtIndex:j];
    }

    tracks = [allTracks copy];
  });

  return tracks;
}

@end
