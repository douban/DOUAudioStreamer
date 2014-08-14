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
  glDeleteFramebuffersOES(1, &_framebuffer);
  glDeleteRenderbuffersOES(1, &_renderbufferColor);
  [EAGLContext setCurrentContext:nil];
}

- (void)_setupEAGLContextAndLayer
{
  _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];

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
  glGenFramebuffersOES(1, &_framebuffer);
  glBindFramebufferOES(GL_FRAMEBUFFER_OES, _framebuffer);

  glGenRenderbuffersOES(1, &_renderbufferColor);
  glBindRenderbufferOES(GL_RENDERBUFFER_OES, _renderbufferColor);

  [_context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:_eaglLayer];
  glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, _renderbufferColor);

  if (glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES) {
    abort();
  }
}

- (void)layoutSubviews
{
  [EAGLContext setCurrentContext:_context];

  glBindRenderbufferOES(GL_RENDERBUFFER_OES, _renderbufferColor);
  [_context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:_eaglLayer];

  glBindFramebufferOES(GL_FRAMEBUFFER_OES, _framebuffer);
  if (glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES) {
    abort();
  }

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

    glBindFramebufferOES(GL_FRAMEBUFFER_OES, _framebuffer);
    [self render];

    glBindRenderbufferOES(GL_RENDERBUFFER_OES, _renderbufferColor);
    [_context presentRenderbuffer:GL_RENDERBUFFER_OES];
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
