//
//  SocketBridge.h
//  DouAudioStreamer
//
//  Created by Keith Yao on 29/05/2015.
//  Copyright (c) 2015 Douban. All rights reserved.
//
#import "RNDouAudioStreamer.h"
#import "DOUAudioStreamer.h"
#import "DOUAudioStreamer+Options.h"
#import "Track.h"

#import "RCTConvert.h"
#import "RCTBridge.h"
#import "RCTUtils.h"
#import "RCTEventDispatcher.h"

static void *kStatusKVOKey = &kStatusKVOKey;
static void *kDurationKVOKey = &kDurationKVOKey;
static void *kBufferingRatioKVOKey = &kBufferingRatioKVOKey;

@implementation RADOUAudioStreamer {
  NSMutableDictionary *_sounds ;
}

@synthesize bridge = _bridge;

- (instancetype)init {
  [DOUAudioStreamer setOptions:[DOUAudioStreamer options] | DOUAudioStreamerRequireSHA256];
  _sounds = [NSMutableDictionary dictionaryWithDictionary:@{}];
  return self;
}

- (DOUAudioStreamer *) getSoundWithName: (NSString *) name
{
  return [_sounds objectForKey:name];
}

- (void) createSoundWithName: (NSString *) name andValue: (DOUAudioStreamer *) audio {
  [_sounds setObject:audio forKey:name];
}

- (NSString *) uniqueId {
  CFUUIDRef uuidRef = CFUUIDCreate(NULL);
  CFStringRef uuidStringRef = CFUUIDCreateString(NULL, uuidRef);
  CFRelease(uuidRef);
  return (__bridge_transfer NSString *)uuidStringRef;
}

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(createSound: (NSDictionary *) song
                         done: (RCTResponseSenderBlock) callback)
{
  Track *track = [[Track alloc] init];
  [track setArtist:[song objectForKey:@"artist"]];
  [track setTitle:[song objectForKey:@"title"]];
  [track setAudioFileURL:[NSURL URLWithString:[song objectForKey:@"url"]]];
  id streamer = [DOUAudioStreamer streamerWithAudioFile:track];

  NSString * audioName = [self uniqueId];
  [self createSoundWithName:audioName andValue: streamer];

  // add observers
  [streamer addObserver:self
              forKeyPath:@"status"
                 options:NSKeyValueObservingOptionNew
                 context:kStatusKVOKey];

  [streamer addObserver:self
              forKeyPath:@"duration"
                 options:NSKeyValueObservingOptionNew
                 context:kDurationKVOKey];

  [streamer addObserver:self
              forKeyPath:@"bufferingRatio"
                 options:NSKeyValueObservingOptionNew
                 context:kBufferingRatioKVOKey];
  // end observers

  callback(@[[NSNull null], audioName]);
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
  // NSString * eventName = @"what";
  DOUAudioStreamer * streamer = object;
  NSString * soundId;
  NSArray * names = [_sounds allKeysForObject: streamer];
  if(names.count >= 1) {
    soundId = names[0];
  }

  if (context == kStatusKVOKey) {
    //[self performSelector:@selector(_updateStatus)
                 //onThread:[NSThread mainThread]
               //withObject:nil
            //waitUntilDone:NO];
  }
  else if (context == kDurationKVOKey) {
    //[self performSelector:@selector(_timerAction:)
                 //onThread:[NSThread mainThread]
               //withObject:nil
            //waitUntilDone:NO];
  }
  else if (context == kBufferingRatioKVOKey) {
    //[self performSelector:@selector(_updateBufferingStatus)
                 //onThread:[NSThread mainThread]
               //withObject:nil
            //waitUntilDone:NO];
  }
  else {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  }

  [[[self bridge] eventDispatcher] sendAppEventWithName:@"EventAudio"
                                                  body:@{@"name": eventName}];
}

RCT_EXPORT_METHOD(pause: (NSString *) name){
  DOUAudioStreamer * streamer = [self getSoundWithName:name];
  if(streamer){
    [streamer pause];
  }
}

RCT_EXPORT_METHOD(play: (NSString *) name){
  DOUAudioStreamer * streamer = [self getSoundWithName:name];
  if(streamer){
    [streamer play];
  }
}

RCT_EXPORT_METHOD(stop: (NSString *) name){
  DOUAudioStreamer * streamer = [self getSoundWithName:name];
  if(streamer){
    [streamer play];
  }
}

// NSTimeInterval is double
RCT_EXPORT_METHOD(setCurrentTime: (NSTimeInterval) time){
  // return [_audioStreamer setCurrentTime: time];
}

RCT_EXPORT_METHOD(duration){
  // return [_audioStreamer duration];
}

RCT_EXPORT_METHOD(currentTime){
}

RCT_EXPORT_METHOD(status){}

@end
