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
#import "RNDouAudioTrack.h"

#import "RCTConvert.h"
#import "RCTBridge.h"
#import "RCTUtils.h"
#import "RCTEventDispatcher.h"

static void *kStatusKVOKey = &kStatusKVOKey;
static void *kDurationKVOKey = &kDurationKVOKey;
static void *kBufferingRatioKVOKey = &kBufferingRatioKVOKey;

@implementation RADOUAudioStreamer {
@private
  NSTimer * _timer;
  NSMutableDictionary *_sounds;
}

@synthesize bridge = _bridge;

- (instancetype)init {
  [DOUAudioStreamer setOptions:[DOUAudioStreamer options] | DOUAudioStreamerRequireSHA256];
  _sounds = [NSMutableDictionary dictionaryWithDictionary:@{}];
  
  dispatch_async(
    dispatch_get_main_queue(),
    // [self methodQueue],
    //dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
  ^{
    _timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                              target:self
                                            selector: @selector(_whilePlaying:)
                                            userInfo: nil
                                             repeats: YES];
  });
  
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

- (void) _emitEvent:(NSString *) eventName
          withValue: (NSDictionary *) eventValue
         andSoundId: (NSString *) soundId
{
  NSDictionary * body = @{@"name": eventName,
                          @"value": eventValue};
  
  NSString * nativeEventName = [NSString stringWithFormat:@"EventAudio-%@", soundId];
  
  NSLog(@"fire event:%@", nativeEventName);
  
  [self.bridge.eventDispatcher
   sendDeviceEventWithName:nativeEventName
   body:body];
}

- (void) _whilePlaying: (id)timer

{
  [_sounds enumerateKeysAndObjectsUsingBlock:^(NSString * soundId, DOUAudioStreamer * streamer, BOOL *stop) {
    if(streamer.status != DOUAudioStreamerPlaying) {
      return;
    }
    NSString * eventName = @"whileplaying";
    NSDictionary * eventValue = @{
                                  @"position": @([streamer currentTime] * 1000),
                                  @"duration": @([streamer duration] * 1000)
                                };
    [self _emitEvent:eventName withValue:eventValue andSoundId:soundId];
  }];
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
  
  /*
  int oPollingInterval = [[song objectForKey: @"pollingInterval"] doubleValue];
  if(oPollingInterval < 1){
    // set the default value
    oPollingInterval = 1000;
  }
  NSTimeInterval pollingInterval = oPollingInterval / 1000; */
  
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
  
  // @todo add _timer for all playing audios

  
  callback(@[[NSNull null], audioName]);
}

RCT_EXPORT_METHOD(destructSound: (NSString *) name){
  DOUAudioStreamer * streamer = [self getSoundWithName:name];
  if(streamer == nil){
    return;
  }
  [streamer pause];
  [streamer removeObserver:self forKeyPath:@"status"];
  [streamer removeObserver:self forKeyPath:@"duration"];
  [streamer removeObserver:self forKeyPath:@"bufferingRatio"];
  [_sounds removeObjectForKey:name];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
  NSString * eventName;
  NSDictionary * eventValue;
  
  DOUAudioStreamer * streamer = object;
  NSString * soundId;
  NSArray * names = [_sounds allKeysForObject: streamer];
  if(names.count >= 1) {
    soundId = names[0];
  }

  if (context == kStatusKVOKey) {
    switch (streamer.status) {
      case DOUAudioStreamerPlaying:
        eventName = @"play";
        break;
      case DOUAudioStreamerPaused:
        eventName = @"pause";
        break;
      case DOUAudioStreamerIdle:
        eventName = @"idle";
        break;
      case DOUAudioStreamerFinished:
        eventName = @"finish";
        break;
      case DOUAudioStreamerBuffering:
        eventName = @"buffering";
        break;
      case DOUAudioStreamerError:
        eventName = @"error";
        break;
      default:
        break;
    }
    eventValue = @{};
  }
  else if (context == kDurationKVOKey) {
    eventName = @"whileplaying";
    eventValue = @{
      @"position": @([streamer currentTime]),
      @"duration": @([streamer duration])
    };
  }
  else if (context == kBufferingRatioKVOKey) {
    eventName = @"whileloading";
    eventValue = @{
      @"bufferingRatio": @([streamer bufferingRatio]),
      @"bytesLoaded": @([streamer receivedLength]),
      @"bytesTotal": @([streamer expectedLength]),
      @"downloadSpeed": @([streamer downloadSpeed])
    };
  }
  else {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    return;
  }
  
  NSDictionary * body = @{
    @"name": eventName,
    @"value": eventValue
  };
  
  NSString * nativeEventName = [NSString stringWithFormat:@"EventAudio-%@", soundId];
  
  NSLog(@"fire event:%@", nativeEventName);

  [self.bridge.eventDispatcher
   sendDeviceEventWithName:nativeEventName
   body:body];
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
RCT_EXPORT_METHOD(setPosition: (NSString *) name andTime: (NSTimeInterval) time){
  DOUAudioStreamer * streamer = [self getSoundWithName:name];
  if(streamer){
    [streamer setCurrentTime: time];
  }
}
@end
