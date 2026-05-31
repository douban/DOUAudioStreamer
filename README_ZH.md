# DOUAudioStreamer

[![CocoaPods](https://img.shields.io/cocoapods/v/DOUAudioStreamer.svg)](https://cocoapods.org/pods/DOUAudioStreamer)
[![Platform](https://img.shields.io/cocoapods/p/DOUAudioStreamer.svg)](https://cocoapods.org/pods/DOUAudioStreamer)
[![License](https://img.shields.io/cocoapods/l/DOUAudioStreamer.svg)](https://github.com/douban/DOUAudioStreamer/blob/master/LICENSE)

[English](README.md) | 中文

DOUAudioStreamer 是一个基于 Core Audio 的 iOS 和 macOS 流式音频播放器。它通过简洁的 `DOUAudioFile` 协议支持远程 URL、本地文件和媒体资料库音频。

## 功能

- 基于 Core Audio 进行音频流式加载与播放。
- 支持 iOS 和 macOS。
- 提供播放状态、总时长、当前播放时间、缓冲进度、缓存路径和下载速度等信息。
- 支持 `play`、`pause` 和 `stop` 播放控制。
- 包含可选的音频分析器和可视化辅助组件。

## 安装

### CocoaPods

在 `Podfile` 中添加：

```ruby
pod 'DOUAudioStreamer'
```

然后运行：

```sh
pod install
```

### 手动集成

[下载](https://github.com/douban/DOUAudioStreamer/archive/master.zip) DOUAudioStreamer，然后将 `src` 目录中的所有文件拖入你的 Xcode 项目。

## 使用方法

创建一个遵循 `DOUAudioFile` 协议的对象：

```objc
#import "DOUAudioFile.h"

@interface Track : NSObject <DOUAudioFile>

@property (nonatomic, strong) NSURL *audioFileURL;

@end
```

创建 streamer 并开始播放：

```objc
#import "DOUAudioStreamer.h"

Track *track = [[Track alloc] init];
track.audioFileURL = [NSURL URLWithString:@"https://example.com/audio.mp3"];

DOUAudioStreamer *streamer = [DOUAudioStreamer streamerWithAudioFile:track];
[streamer play];
```

你可以通过 KVO 观察 streamer 的 `status` 属性，也可以读取 `duration`、`currentTime`、`bufferingRatio`、`expectedLength`、`receivedLength` 和 `downloadSpeed` 等属性。

## 示例

可运行的示例工程位于 [example](https://github.com/douban/DOUAudioStreamer/tree/master/example) 目录。

## 系统要求

- iOS 5.0+
- macOS 10.7+
- ARC

## 许可证

本项目使用 BSD 许可证发布。完整内容请查看 [LICENSE](https://github.com/douban/DOUAudioStreamer/blob/master/LICENSE) 文件。
