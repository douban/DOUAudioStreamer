/* vim: set ft=objc fenc=utf-8 sw=2 ts=2 et: */
/*
 *  DOUAudioStreamer - A Core Audio based streaming audio player for iOS/Mac:
 *
 *      https://github.com/douban/DOUAudioStreamer
 *
 *  Copyright 2013 Douban Inc.  All rights reserved.
 *
 *  Use and distribution licensed under the BSD license.  See
 *  the LICENSE file for full text.
 *
 *  Authors:
 *      Chongyu Zhu <lembacon@gmail.com>
 *
 */

#import "ViewController.h"
#import "DOUAudioStreamer.h"

static void *kStatusKVOKey = &kStatusKVOKey;
static void *kDurationKVOKey = &kDurationKVOKey;
static void *kBufferingRatioKVOKey = &kBufferingRatioKVOKey;

@interface Track : NSObject <DOUAudioFile>
@property (nonatomic, strong) NSString *artist;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSURL *url;
@end

@implementation Track
- (NSURL *)audioFileURL
{
  return [self url];
}
@end

@interface ViewController () {
@private
  DOUAudioStreamer *_streamer;
  NSArray *_tracks;
  NSUInteger _currentIndex;
}

@end

@implementation ViewController

+ (void)load
{
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
    [self _tracks];
  });
}

+ (NSArray *)_tracks
{
  static NSArray *tracks = nil;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://douban.fm/j/mine/playlist?type=n&channel=0&context=channel:0%7Cmusician_id:103658&from=mainsite"]];
    NSData *data = [NSURLConnection sendSynchronousRequest:request
                                         returningResponse:NULL
                                                     error:NULL];
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[string dataUsingEncoding:NSUTF8StringEncoding] options:0 error:NULL];

    NSMutableArray *allTracks = [NSMutableArray array];
    for (NSDictionary *song in [dict objectForKey:@"song"]) {
      Track *track = [[Track alloc] init];
      [track setArtist:[song objectForKey:@"artist"]];
      [track setTitle:[song objectForKey:@"title"]];
      [track setUrl:[NSURL URLWithString:[song objectForKey:@"url"]]];
      [allTracks addObject:track];
    }

    tracks = [allTracks copy];
  });

  return tracks;
}

- (void)_resetStreamer
{
  if (_streamer != nil) {
    [_streamer pause];
    [_streamer removeObserver:self forKeyPath:@"status"];
    [_streamer removeObserver:self forKeyPath:@"duration"];
    [_streamer removeObserver:self forKeyPath:@"bufferingRatio"];
    _streamer = nil;
  }

  Track *track = [_tracks objectAtIndex:_currentIndex];
  NSString *title = [NSString stringWithFormat:@"%@ - %@", track.artist, track.title];
  [_labelTitle setText:title];

  _streamer = [DOUAudioStreamer streamerWithAudioFile:track];
  [_streamer addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:kStatusKVOKey];
  [_streamer addObserver:self forKeyPath:@"duration" options:NSKeyValueObservingOptionNew context:kDurationKVOKey];
  [_streamer addObserver:self forKeyPath:@"bufferingRatio" options:NSKeyValueObservingOptionNew context:kBufferingRatioKVOKey];

  [_streamer play];

  [self _setupHintForStreamer];
}

- (void)_setupHintForStreamer
{
  NSUInteger nextIndex = _currentIndex + 1;
  if (nextIndex >= [_tracks count]) {
    nextIndex = 0;
  }

  [DOUAudioStreamer setHintWithAudioFile:[_tracks objectAtIndex:nextIndex]];
}

- (void)_timerAction:(id)timer
{
  if ([_streamer duration] == 0.0) {
    [_sliderProgress setValue:0.0f animated:NO];
  }
  else {
    [_sliderProgress setValue:[_streamer currentTime] / [_streamer duration] animated:YES];
  }
}

- (void)_updateStatus
{
  switch ([_streamer status]) {
  case DOUAudioStreamerPlaying:
    [_labelInfo setText:@"playing"];
    [_buttonPlayPause setTitle:@"Pause" forState:UIControlStateNormal];
    break;

  case DOUAudioStreamerPaused:
    [_labelInfo setText:@"paused"];
    [_buttonPlayPause setTitle:@"Play" forState:UIControlStateNormal];
    break;

  case DOUAudioStreamerIdle:
    [_labelInfo setText:@"idle"];
    [_buttonPlayPause setTitle:@"Play" forState:UIControlStateNormal];
    break;

  case DOUAudioStreamerFinished:
    [_labelInfo setText:@"finished"];
    [self actionNext:nil];
    break;

  case DOUAudioStreamerBuffering:
    [_labelInfo setText:@"buffering"];
    break;

  case DOUAudioStreamerError:
    [_labelInfo setText:@"error"];
    break;
  }
}

- (void)_updateBufferingStatus
{
    [_labelMisc setText:[NSString stringWithFormat:@"Received %.2f/%.2f MB (%.2f %%), Speed %.2f MB/s", (double)[_streamer receivedLength] / 1024 / 1024, (double)[_streamer expectedLength] / 1024 / 1024, [_streamer bufferingRatio] * 100.0, (double)[_streamer downloadSpeed] / 1024 / 1024]];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
  if (context == kStatusKVOKey) {
    [self performSelector:@selector(_updateStatus)
                 onThread:[NSThread mainThread]
               withObject:nil
            waitUntilDone:NO];
  }
  else if (context == kDurationKVOKey) {
    [self performSelector:@selector(_timerAction:)
                 onThread:[NSThread mainThread]
               withObject:nil
            waitUntilDone:NO];
  }
  else if (context == kBufferingRatioKVOKey) {
    [self performSelector:@selector(_updateBufferingStatus)
                 onThread:[NSThread mainThread]
               withObject:nil
            waitUntilDone:NO];
  }
  else {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  }
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  _tracks = [[self class] _tracks];
  _currentIndex = 0;
  [self _resetStreamer];

  [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(_timerAction:) userInfo:nil repeats:YES];
  [_sliderVolume setValue:[DOUAudioStreamer volume]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)actionPlayPause:(id)sender
{
  if ([_streamer status] == DOUAudioStreamerPaused ||
      [_streamer status] == DOUAudioStreamerIdle) {
    [_streamer play];
  }
  else {
    [_streamer pause];
  }
}

- (IBAction)actionNext:(id)sender
{
  if (++_currentIndex >= [_tracks count]) {
    _currentIndex = 0;
  }

  [self _resetStreamer];
}

- (IBAction)actionStop:(id)sender
{
  [_streamer stop];
}

- (IBAction)actionSliderProgress:(id)sender
{
  [_streamer setCurrentTime:[_streamer duration] * [_sliderProgress value]];
}

- (IBAction)actionSliderVolume:(id)sender
{
  [DOUAudioStreamer setVolume:[_sliderVolume value]];
}

@end
