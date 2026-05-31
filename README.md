# DOUAudioStreamer

[![CocoaPods](https://img.shields.io/cocoapods/v/DOUAudioStreamer.svg)](https://cocoapods.org/pods/DOUAudioStreamer)
[![Platform](https://img.shields.io/cocoapods/p/DOUAudioStreamer.svg)](https://cocoapods.org/pods/DOUAudioStreamer)
[![License](https://img.shields.io/cocoapods/l/DOUAudioStreamer.svg)](https://github.com/douban/DOUAudioStreamer/blob/master/LICENSE)

English | [中文](README_ZH.md)

DOUAudioStreamer is a Core Audio based streaming audio player for iOS and macOS. It supports remote URLs, local files, and media library items through a small `DOUAudioFile` protocol.

## Features

- Streams and plays audio with Core Audio.
- Supports iOS and macOS.
- Provides playback status, duration, current time, buffering progress, cache path, and download speed.
- Supports playback control with `play`, `pause`, and `stop`.
- Includes optional audio analyzers and visualization helpers.

## Installation

### CocoaPods

Add DOUAudioStreamer to your `Podfile`:

```ruby
pod 'DOUAudioStreamer'
```

Then run:

```sh
pod install
```

### Manual

[Download](https://github.com/douban/DOUAudioStreamer/archive/master.zip) DOUAudioStreamer, then drag everything in the `src` folder into your Xcode project.

## Usage

Create an object that conforms to `DOUAudioFile`:

```objc
#import "DOUAudioFile.h"

@interface Track : NSObject <DOUAudioFile>

@property (nonatomic, strong) NSURL *audioFileURL;

@end
```

Create a streamer and start playback:

```objc
#import "DOUAudioStreamer.h"

Track *track = [[Track alloc] init];
track.audioFileURL = [NSURL URLWithString:@"https://example.com/audio.mp3"];

DOUAudioStreamer *streamer = [DOUAudioStreamer streamerWithAudioFile:track];
[streamer play];
```

You can observe the streamer's `status` property with KVO and inspect properties such as `duration`, `currentTime`, `bufferingRatio`, `expectedLength`, `receivedLength`, and `downloadSpeed`.

## Example

A working demonstration is included in the [example](https://github.com/douban/DOUAudioStreamer/tree/master/example) folder.

## Requirements

- iOS 5.0+
- macOS 10.7+
- ARC

## License

Use and distribution are licensed under the BSD license. See the [LICENSE](https://github.com/douban/DOUAudioStreamer/blob/master/LICENSE) file for the full text.
