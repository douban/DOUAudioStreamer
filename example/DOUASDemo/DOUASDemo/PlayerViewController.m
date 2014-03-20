/* vim: set ft=objc fenc=utf-8 sw=2 ts=2 et: */
/*
 *  DOUAudioStreamer - A Core Audio based streaming audio player for iOS/Mac:
 *
 *      https://github.com/douban/DOUAudioStreamer
 *
 *  Copyright 2013-2014 Douban Inc.  All rights reserved.
 *
 *  Use and distribution licensed under the BSD license.  See
 *  the LICENSE file for full text.
 *
 *  Authors:
 *      Chongyu Zhu <i@lembacon.com>
 *
 */

#import "PlayerViewController.h"
#import "Track.h"
#import "DOUAudioStreamer.h"
#import "DOUAudioVisualizer.h"

static void *kStatusKVOKey = &kStatusKVOKey;
static void *kDurationKVOKey = &kDurationKVOKey;
static void *kBufferingRatioKVOKey = &kBufferingRatioKVOKey;

@interface PlayerViewController () {
@private
  UILabel *_titleLabel;
  UILabel *_statusLabel;
  UILabel *_miscLabel;

  UIButton *_buttonPlayPause;
  UIButton *_buttonNext;
  UIButton *_buttonStop;

  UISlider *_progressSlider;

  UILabel *_volumeLabel;
  UISlider *_volumeSlider;

  NSUInteger _currentTrackIndex;
  NSTimer *_timer;

  DOUAudioStreamer *_streamer;
  DOUAudioVisualizer *_audioVisualizer;
}
@end

@implementation PlayerViewController

- (void)loadView
{
  UIView *view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  [view setBackgroundColor:[UIColor whiteColor]];

  _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 64.0, CGRectGetWidth([view bounds]), 30.0)];
  [_titleLabel setFont:[UIFont systemFontOfSize:20.0]];
  [_titleLabel setTextColor:[UIColor blackColor]];
  [_titleLabel setTextAlignment:NSTextAlignmentCenter];
  [_titleLabel setLineBreakMode:NSLineBreakByTruncatingTail];
  [view addSubview:_titleLabel];

  _statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, CGRectGetMaxY([_titleLabel frame]) + 10.0, CGRectGetWidth([view bounds]), 30.0)];
  [_statusLabel setFont:[UIFont systemFontOfSize:16.0]];
  [_statusLabel setTextColor:[UIColor colorWithWhite:0.4 alpha:1.0]];
  [_statusLabel setTextAlignment:NSTextAlignmentCenter];
  [_statusLabel setLineBreakMode:NSLineBreakByTruncatingTail];
  [view addSubview:_statusLabel];

  _miscLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, CGRectGetMaxY([_statusLabel frame]) + 10.0, CGRectGetWidth([view bounds]), 20.0)];
  [_miscLabel setFont:[UIFont systemFontOfSize:10.0]];
  [_miscLabel setTextColor:[UIColor colorWithWhite:0.5 alpha:1.0]];
  [_miscLabel setTextAlignment:NSTextAlignmentCenter];
  [_miscLabel setLineBreakMode:NSLineBreakByTruncatingTail];
  [view addSubview:_miscLabel];

  _buttonPlayPause = [UIButton buttonWithType:UIButtonTypeSystem];
  [_buttonPlayPause setFrame:CGRectMake(80.0, CGRectGetMaxY([_miscLabel frame]) + 20.0, 60.0, 20.0)];
  [_buttonPlayPause setTitle:@"Play" forState:UIControlStateNormal];
  [_buttonPlayPause addTarget:self action:@selector(_actionPlayPause:) forControlEvents:UIControlEventTouchDown];
  [view addSubview:_buttonPlayPause];

  _buttonNext = [UIButton buttonWithType:UIButtonTypeSystem];
  [_buttonNext setFrame:CGRectMake(CGRectGetWidth([view bounds]) - 80.0 - 60.0, CGRectGetMinY([_buttonPlayPause frame]), 60.0, 20.0)];
  [_buttonNext setTitle:@"Next" forState:UIControlStateNormal];
  [_buttonNext addTarget:self action:@selector(_actionNext:) forControlEvents:UIControlEventTouchDown];
  [view addSubview:_buttonNext];

  _buttonStop = [UIButton buttonWithType:UIButtonTypeSystem];
  [_buttonStop setFrame:CGRectMake(round((CGRectGetWidth([view bounds]) - 60.0) / 2.0), CGRectGetMaxY([_buttonNext frame]) + 20.0, 60.0, 20.0)];
  [_buttonStop setTitle:@"Stop" forState:UIControlStateNormal];
  [_buttonStop addTarget:self action:@selector(_actionStop:) forControlEvents:UIControlEventTouchDown];
  [view addSubview:_buttonStop];

  _progressSlider = [[UISlider alloc] initWithFrame:CGRectMake(20.0, CGRectGetMaxY([_buttonStop frame]) + 20.0, CGRectGetWidth([view bounds]) - 20.0 * 2.0, 40.0)];
  [_progressSlider addTarget:self action:@selector(_actionSliderProgress:) forControlEvents:UIControlEventValueChanged];
  [view addSubview:_progressSlider];

  _volumeLabel = [[UILabel alloc] initWithFrame:CGRectMake(20.0, CGRectGetMaxY([_progressSlider frame]) + 20.0, 80.0, 40.0)];
  [_volumeLabel setText:@"Volume:"];
  [view addSubview:_volumeLabel];

  _volumeSlider = [[UISlider alloc] initWithFrame:CGRectMake(CGRectGetMaxX([_volumeLabel frame]) + 10.0, CGRectGetMinY([_volumeLabel frame]), CGRectGetWidth([view bounds]) - CGRectGetMaxX([_volumeLabel frame]) - 10.0 - 20.0, 40.0)];
  [_volumeSlider addTarget:self action:@selector(_actionSliderVolume:) forControlEvents:UIControlEventValueChanged];
  [view addSubview:_volumeSlider];

  _audioVisualizer = [[DOUAudioVisualizer alloc] initWithFrame:CGRectMake(0.0, CGRectGetMaxY([_volumeSlider frame]), CGRectGetWidth([view bounds]), CGRectGetHeight([view bounds]) - CGRectGetMaxY([_volumeSlider frame]))];
  [_audioVisualizer setBackgroundColor:[UIColor colorWithRed:239.0 / 255.0 green:244.0 / 255.0 blue:240.0 / 255.0 alpha:1.0]];
  [view addSubview:_audioVisualizer];

  [self setView:view];
}

- (void)_cancelStreamer
{
  if (_streamer != nil) {
    [_streamer pause];
    [_streamer removeObserver:self forKeyPath:@"status"];
    [_streamer removeObserver:self forKeyPath:@"duration"];
    [_streamer removeObserver:self forKeyPath:@"bufferingRatio"];
    _streamer = nil;
  }
}

- (void)_resetStreamer
{
  [self _cancelStreamer];

    if (0 == [_tracks count])
    {
        [_miscLabel setText:@"(No tracks available)"];
    }
    else
    {
        Track *track = [_tracks objectAtIndex:_currentTrackIndex];
        NSString *title = [NSString stringWithFormat:@"%@ - %@", track.artist, track.title];
        [_titleLabel setText:title];
        
        _streamer = [DOUAudioStreamer streamerWithAudioFile:track];
        [_streamer addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:kStatusKVOKey];
        [_streamer addObserver:self forKeyPath:@"duration" options:NSKeyValueObservingOptionNew context:kDurationKVOKey];
        [_streamer addObserver:self forKeyPath:@"bufferingRatio" options:NSKeyValueObservingOptionNew context:kBufferingRatioKVOKey];
        
        [_streamer play];
        
        [self _updateBufferingStatus];
        [self _setupHintForStreamer];
    }
}

- (void)_setupHintForStreamer
{
  NSUInteger nextIndex = _currentTrackIndex + 1;
  if (nextIndex >= [_tracks count]) {
    nextIndex = 0;
  }

  [DOUAudioStreamer setHintWithAudioFile:[_tracks objectAtIndex:nextIndex]];
}

- (void)_timerAction:(id)timer
{
  if ([_streamer duration] == 0.0) {
    [_progressSlider setValue:0.0f animated:NO];
  }
  else {
    [_progressSlider setValue:[_streamer currentTime] / [_streamer duration] animated:YES];
  }
}

- (void)_updateStatus
{
  switch ([_streamer status]) {
  case DOUAudioStreamerPlaying:
    [_statusLabel setText:@"playing"];
    [_buttonPlayPause setTitle:@"Pause" forState:UIControlStateNormal];
    break;

  case DOUAudioStreamerPaused:
    [_statusLabel setText:@"paused"];
    [_buttonPlayPause setTitle:@"Play" forState:UIControlStateNormal];
    break;

  case DOUAudioStreamerIdle:
    [_statusLabel setText:@"idle"];
    [_buttonPlayPause setTitle:@"Play" forState:UIControlStateNormal];
    break;

  case DOUAudioStreamerFinished:
    [_statusLabel setText:@"finished"];
    [self _actionNext:nil];
    break;

  case DOUAudioStreamerBuffering:
    [_statusLabel setText:@"buffering"];
    break;

  case DOUAudioStreamerError:
    [_statusLabel setText:@"error"];
    break;
  }
}

- (void)_updateBufferingStatus
{
  [_miscLabel setText:[NSString stringWithFormat:@"Received %.2f/%.2f MB (%.2f %%), Speed %.2f MB/s", (double)[_streamer receivedLength] / 1024 / 1024, (double)[_streamer expectedLength] / 1024 / 1024, [_streamer bufferingRatio] * 100.0, (double)[_streamer downloadSpeed] / 1024 / 1024]];

  if ([_streamer bufferingRatio] >= 1.0) {
    NSLog(@"sha256: %@", [_streamer sha256]);
  }
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

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];

  [self _resetStreamer];

  _timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(_timerAction:) userInfo:nil repeats:YES];
  [_volumeSlider setValue:[DOUAudioStreamer volume]];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [_timer invalidate];
  [_streamer stop];
  [self _cancelStreamer];

  [super viewWillDisappear:animated];
}

- (void)_actionPlayPause:(id)sender
{
  if ([_streamer status] == DOUAudioStreamerPaused ||
      [_streamer status] == DOUAudioStreamerIdle) {
    [_streamer play];
  }
  else {
    [_streamer pause];
  }
}

- (void)_actionNext:(id)sender
{
  if (++_currentTrackIndex >= [_tracks count]) {
    _currentTrackIndex = 0;
  }

  [self _resetStreamer];
}

- (void)_actionStop:(id)sender
{
  [_streamer stop];
}

- (void)_actionSliderProgress:(id)sender
{
  [_streamer setCurrentTime:[_streamer duration] * [_progressSlider value]];
}

- (void)_actionSliderVolume:(id)sender
{
  [DOUAudioStreamer setVolume:[_volumeSlider value]];
}

@end
