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
//    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://douban.fm/j/mine/playlist?type=n&channel=1004693&from=mainsite"]];
//    NSData *data = [NSURLConnection sendSynchronousRequest:request
//                                         returningResponse:NULL
//                                                     error:NULL];
//    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[string dataUsingEncoding:NSUTF8StringEncoding] options:0 error:NULL];
//
//    NSMutableArray *allTracks = [NSMutableArray array];
//    for (NSDictionary *song in [dict objectForKey:@"song"]) {
//      Track *track = [[Track alloc] init];
//      [track setArtist:[song objectForKey:@"artist"]];
//      [track setTitle:[song objectForKey:@"title"]];
//      [track setAudioFileURL:[NSURL URLWithString:[song objectForKey:@"url"]]];
//      [allTracks addObject:track];
//    }
//
//    tracks = [allTracks copy];
      
      
      // 重写
      NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:10];
      for (int i=0; i<10; i++) {
          Track *track = [[Track alloc] init];
          track.artist = @"涛哥";
          track.title = @"灵魂之歌";
          track.audioFileURL = [NSURL URLWithString:@"http://music.163.com/song?id=95638"];
          [array addObject:track];
      }
      tracks = [NSArray arrayWithArray:array];
    
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
