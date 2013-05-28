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

#import "DOUAudioPlaybackItem.h"
#import "DOUAudioFileProvider.h"
#import "DOUAudioFilePreprocessor.h"

@interface DOUAudioPlaybackItem () {
@private
  DOUAudioFileProvider *_fileProvider;
  DOUAudioFilePreprocessor *_filePreprocessor;
  AudioFileID _fileID;
  AudioStreamBasicDescription _fileFormat;
  NSUInteger _bitRate;
  NSUInteger _dataOffset;
  NSUInteger _estimatedDuration;
}
@end

@implementation DOUAudioPlaybackItem

@synthesize fileProvider = _fileProvider;
@synthesize filePreprocessor = _filePreprocessor;
@synthesize fileID = _fileID;
@synthesize fileFormat = _fileFormat;
@synthesize bitRate = _bitRate;
@synthesize dataOffset = _dataOffset;
@synthesize estimatedDuration = _estimatedDuration;

- (id <DOUAudioFile>)audioFile
{
  return [_fileProvider audioFile];
}

- (NSURL *)cachedURL
{
  return [_fileProvider cachedURL];
}

- (NSData *)mappedData
{
  return [_fileProvider mappedData];
}

- (BOOL)isOpened
{
  return _fileID != NULL;
}

static OSStatus audio_file_read(void *inClientData,
                                SInt64 inPosition,
                                UInt32 requestCount,
                                void *buffer, 
                                UInt32 *actualCount)
{
  __unsafe_unretained DOUAudioPlaybackItem *item = (__bridge DOUAudioPlaybackItem *)inClientData;
  if ([item filePreprocessor] == nil) {
    memcpy(buffer, (uint8_t *)[[item mappedData] bytes] + inPosition, requestCount);
  }
  else {
    NSData *input = [NSData dataWithBytesNoCopy:(uint8_t *)[[item mappedData] bytes] + inPosition
                                         length:requestCount
                                   freeWhenDone:NO];
    NSData *output = [[item filePreprocessor] handleData:input offset:inPosition];
    memcpy(buffer, [output bytes], [output length]);
  }
  *actualCount = requestCount;
  return noErr;
}

static SInt64 audio_file_get_size(void *inClientData)
{
  __unsafe_unretained DOUAudioPlaybackItem *item = (__bridge DOUAudioPlaybackItem *)inClientData;
  return [[item mappedData] length];
}

- (BOOL)open
{
  if ([self isOpened]) {
    return YES;
  }

  OSStatus status = AudioFileOpenWithCallbacks((__bridge void *)self,
                                               audio_file_read,
                                               NULL,
                                               audio_file_get_size,
                                               NULL,
                                               0,
                                               &_fileID);

  if (status != noErr) {
    _fileID = NULL;
    return NO;
  }

  if (![self _fillFileFormat] ||
      ![self _fillMiscProperties]) {
    AudioFileClose(_fileID);
    _fileID = NULL;
    return NO;
  }

  return YES;
}

- (BOOL)_fillFileFormat
{
  UInt32 size;
  OSStatus status;

  status = AudioFileGetPropertyInfo(_fileID, kAudioFilePropertyFormatList, &size, NULL);
  if (status != noErr) {
    return NO;
  }

  UInt32 numFormats = size / sizeof(AudioFormatListItem);
  AudioFormatListItem *formatList = (AudioFormatListItem *)malloc(size);

  status = AudioFileGetProperty(_fileID, kAudioFilePropertyFormatList, &size, formatList);
  if (status != noErr) {
    free(formatList);
    return NO;
  }

  if (numFormats == 1) {
    _fileFormat = formatList[0].mASBD;
  }
  else {
    status = AudioFormatGetPropertyInfo(kAudioFormatProperty_DecodeFormatIDs, 0, NULL, &size);
    if (status != noErr) {
      free(formatList);
      return NO;
    }

    UInt32 numDecoders = size / sizeof(OSType);
    OSType *decoderIDS = (OSType *)malloc(size);

    status = AudioFormatGetProperty(kAudioFormatProperty_DecodeFormatIDs, 0, NULL, &size, decoderIDS);
    if (status != noErr) {
      free(formatList);
      free(decoderIDS);
      return NO;
    }

    UInt32 i;
    for (i = 0; i < numFormats; ++i) {
      OSType decoderID = formatList[i].mASBD.mFormatID;

      BOOL found = NO;
      for (UInt32 j = 0; j < numDecoders; ++j) {
        if (decoderID == decoderIDS[j]) {
          found = YES;
          break;
        }
      }

      if (found) {
        break;
      }
    }

    free(decoderIDS);

    if (i >= numFormats) {
      free(formatList);
      return NO;
    }

    _fileFormat = formatList[i].mASBD;
  }

  free(formatList);
  return YES;
}

- (BOOL)_fillMiscProperties
{
  UInt32 size;
  OSStatus status;

  UInt32 bitRate = 0;
  size = sizeof(bitRate);
  status = AudioFileGetProperty(_fileID, kAudioFilePropertyBitRate, &size, &bitRate);
  if (status != noErr) {
    return NO;
  }
  _bitRate = bitRate;

  SInt64 dataOffset = 0;
  size = sizeof(dataOffset);
  status = AudioFileGetProperty(_fileID, kAudioFilePropertyDataOffset, &size, &dataOffset);
  if (status != noErr) {
    return NO;
  }
  _dataOffset = dataOffset;

  Float64 estimatedDuration = 0.0;
  size = sizeof(estimatedDuration);
  status = AudioFileGetProperty(_fileID, kAudioFilePropertyEstimatedDuration, &size, &estimatedDuration);
  if (status != noErr) {
    return NO;
  }
  _estimatedDuration = estimatedDuration * 1000.0;

  return YES;
}

- (void)close
{
  if (![self isOpened]) {
    return;
  }

  AudioFileClose(_fileID);
  _fileID = NULL;
}

+ (instancetype)playbackItemWithFileProvider:(DOUAudioFileProvider *)fileProvider
{
  return [[[self class] alloc] initWithFileProvider:fileProvider];
}

- (instancetype)initWithFileProvider:(DOUAudioFileProvider *)fileProvider
{
  self = [super init];
  if (self) {
    _fileProvider = fileProvider;

    if ([[self audioFile] respondsToSelector:@selector(audioFilePreprocessor)]) {
      _filePreprocessor = [[self audioFile] audioFilePreprocessor];
    }
  }

  return self;
}

- (void)dealloc
{
  if ([self isOpened]) {
    [self close];
  }
}

@end
