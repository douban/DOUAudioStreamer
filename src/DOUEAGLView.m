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

#if TARGET_OS_IPHONE

#import "DOUEAGLView.h"
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>

@interface DOUEAGLView () {
@private
  EAGLContext *_context;
  CAEAGLLayer *_eaglLayer;

  CADisplayLink *_displayLink;
  NSThread *_displayLinkThread;

  GLuint _framebuffer;
  GLuint _renderbufferColor;
}
@end

@implementation DOUEAGLView

@dynamic paused;
@dynamic frameInterval;

+ (Class)layerClass
{
  return [CAEAGLLayer class];
}

+ (EAGLRenderingAPI)eaglRenderingAPI
{
  [self doesNotRecognizeSelector:_cmd];
  return kEAGLRenderingAPIOpenGLES1;
}

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    [self _initialize];
  }

  return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) {
    [self _initialize];
  }

  return self;
}

- (void)dealloc
{
  [self _finalize];
}

- (void)_initialize
{
  [self setOpaque:NO];
  [self setBackgroundColor:[UIColor clearColor]];

  [self _setupEAGLContextAndLayer];
  [self _setupFBO];
  [self _setupDisplayLink];
}

- (void)_finalize
{
  [_displayLink invalidate];

  [EAGLContext setCurrentContext:_context];
  [self cleanup];
  glDeleteFramebuffers(1, &_framebuffer);
  glDeleteRenderbuffers(1, &_renderbufferColor);
  [EAGLContext setCurrentContext:nil];
}

- (void)_setupEAGLContextAndLayer
{
  _context = [[EAGLContext alloc] initWithAPI:[[self class] eaglRenderingAPI]];

  [EAGLContext setCurrentContext:_context];
  [self prepare];

  _eaglLayer = (CAEAGLLayer *)[self layer];
  [_eaglLayer setOpaque:NO];
  [_eaglLayer setContentsScale:[[UIScreen mainScreen] scale]];
  [_eaglLayer setDrawableProperties:@{
                                      kEAGLDrawablePropertyRetainedBacking: @NO,
                                      kEAGLDrawablePropertyColorFormat: kEAGLColorFormatRGBA8
                                      }];
}

- (void)_setupFBO
{
  glGenFramebuffers(1, &_framebuffer);
  glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);

  glGenRenderbuffers(1, &_renderbufferColor);
  glBindRenderbuffer(GL_RENDERBUFFER, _renderbufferColor);

  [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
  glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderbufferColor);

  if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
    abort();
  }
}

- (void)layoutSubviews
{
  [EAGLContext setCurrentContext:_context];

  glBindRenderbuffer(GL_RENDERBUFFER, _renderbufferColor);
  [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];

  [self reshape];
}

- (void)_setupDisplayLink
{
  _displayLink = [CADisplayLink displayLinkWithTarget:self
                                             selector:@selector(_displayLinkCallback:)];
  [_displayLink setPaused:NO];
  [_displayLink setFrameInterval:1];

  [_displayLink addToRunLoop:[NSRunLoop mainRunLoop]
                     forMode:NSDefaultRunLoopMode];
}

- (void)_displayLinkCallback:(CADisplayLink *)displayLink
{
  @autoreleasepool {
    [EAGLContext setCurrentContext:_context];

    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    [self render];

    glBindRenderbuffer(GL_RENDERBUFFER, _renderbufferColor);
    [_context presentRenderbuffer:GL_RENDERBUFFER];
  }
}

- (void)prepare
{
}

- (void)cleanup
{
}

- (void)reshape
{
}

- (void)render
{
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
  if (aSelector == @selector(isPaused) ||
      aSelector == @selector(setPaused:) ||
      aSelector == @selector(frameInterval) ||
      aSelector == @selector(setFrameInterval:)) {
    return _displayLink;
  }
  
  return [super forwardingTargetForSelector:aSelector];
}

@end

#endif /* TARGET_OS_IPHONE */
