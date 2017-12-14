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

#import "NSData+DOUAudioMappedFile.h"
#include <sys/types.h>
#include <sys/mman.h>

static NSMutableDictionary *get_size_map()
{
  static NSMutableDictionary *map = nil;
  
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    map = [[NSMutableDictionary alloc] init];
  });
  
  return map;
}

static void mmap_deallocate(void *ptr, void *info)
{
  NSNumber *key = [NSNumber numberWithUnsignedLongLong:(uintptr_t)ptr];
  NSNumber *fileSize = nil;
  
  NSMutableDictionary *sizeMap = get_size_map();
  @synchronized(sizeMap) {
    fileSize = [sizeMap objectForKey:key];
    [sizeMap removeObjectForKey:key];
  }
  
  size_t size = (size_t)[fileSize unsignedLongLongValue];
  munmap(ptr, size);
}

static CFAllocatorRef get_mmap_deallocator()
{
  static CFAllocatorRef deallocator = NULL;
  
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    CFAllocatorContext context;
    bzero(&context, sizeof(context));
    context.deallocate = mmap_deallocate;
    
    deallocator = CFAllocatorCreate(kCFAllocatorDefault, &context);
  });
  
  return deallocator;
}

@implementation NSData (DOUAudioMappedFile)

+ (instancetype)dou_dataWithMappedContentsOfFile:(NSString *)path
{
  return [[self class] _dou_dataWithMappedContentsOfFile:path modifiable:NO];
}

+ (instancetype)dou_dataWithMappedContentsOfURL:(NSURL *)url
{
  return [[self class] dou_dataWithMappedContentsOfFile:[url path]];
}

+ (instancetype)dou_modifiableDataWithMappedContentsOfFile:(NSString *)path
{
  return [[self class] _dou_dataWithMappedContentsOfFile:path modifiable:YES];
}

+ (instancetype)dou_modifiableDataWithMappedContentsOfURL:(NSURL *)url
{
  return [[self class] dou_modifiableDataWithMappedContentsOfFile:[url path]];
}

+ (instancetype)_dou_dataWithMappedContentsOfFile:(NSString *)path modifiable:(BOOL)modifiable
{
  NSFileHandle *fileHandle = nil;
  if (modifiable) {
    fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:path];
  }
  else {
    fileHandle = [NSFileHandle fileHandleForReadingAtPath:path];
  }
  if (fileHandle == nil) {
    return nil;
  }
  
  int fd = [fileHandle fileDescriptor];
  if (fd < 0) {
    return nil;
  }
  
  off_t size = lseek(fd, 0, SEEK_END);
  if (size < 0) {
    return nil;
  }
  
  int protection = PROT_READ;
  if (modifiable) {
    protection |= PROT_WRITE;
  }
  
  void *address = mmap(NULL, (size_t)size, protection, MAP_FILE | MAP_SHARED, fd, 0);
  if (address == MAP_FAILED) {
    return nil;
  }
  
  NSMutableDictionary *sizeMap = get_size_map();
  @synchronized(sizeMap) {
    [sizeMap setObject:[NSNumber numberWithUnsignedLongLong:(unsigned long long)size]
                forKey:[NSNumber numberWithUnsignedLongLong:(uintptr_t)address]];
  }
  
  return CFBridgingRelease(CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, (const UInt8 *)address, (CFIndex)size, get_mmap_deallocator()));
}

- (void)dou_synchronizeMappedFile
{
  NSNumber *key = [NSNumber numberWithUnsignedLongLong:(uintptr_t)[self bytes]];
  NSNumber *fileSize = nil;
  
  NSMutableDictionary *sizeMap = get_size_map();
  @synchronized(sizeMap) {
    fileSize = [sizeMap objectForKey:key];
  }
  
  if (fileSize == nil) {
    return;
  }
  
  size_t size = (size_t)[fileSize unsignedLongLongValue];
  msync((void *)[self bytes], size, MS_SYNC | MS_INVALIDATE);
}

@end

